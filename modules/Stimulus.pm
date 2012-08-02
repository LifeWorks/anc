######################################################################################
# File:     Stimulus.pm
# Author:   Julien F. Ollivier
#
# Copyright (C) 2005-2010 Julien Ollivier.
#
# This program comes with ABSOLUTELY NO WARRANTY.
# This is free software, and you are welcome to redistribute it
# under certain conditions. See file LICENSE.TXT for details.
#
# Synopsys: This class consists of a variety of functions applying stimuli
#           to specified network nodes.
######################################################################################
# Detailed Description:
# ---------------------
######################################################################################

use strict;
use diagnostics;		# equivalent to -w command-line switch
use warnings;

package Stimulus;
use Class::Std::Storable;
use base qw(Selector);
{
    use Carp;
    use IO::Handle;

    use Globals;
    use Utils;

    #######################################################################################
    # CLASS ATTRIBUTES
    #######################################################################################
    Stimulus->set_class_data("AUTONAME", "Stm");
    Stimulus->set_class_data("append_ss_event", 0);
#    Stimulus->set_class_data("INSTANCE_CLASS", "StimulusInstance");

    my %functions_map = (
	source => "source_equation",
	impulse => "source_equation",
	sink => "sink_equation",
	wash => "sink_equation",
	clamp => "clamp_equation",
	staircase => "staircase_equation",
	ramp => "ramp_equation",
	dose_response => "dose_response_equation",
       );

    #######################################################################################
    # ATTRIBUTES
    #######################################################################################
    # user-supplied attributes
    my %type_of :ATTR(get => 'type', set => 'type', init_arg => 'type');
    my %params_ref_of :ATTR(get => 'params_ref', set => 'params_ref');

    # compiled attributes
    my %equations_of :ATTR(get => 'equations', set => 'equations');
    my %events_of :ATTR(set => 'events');
    my %t_end_of :ATTR(set => 't_end');

    # user-supplied or compiled
    my %node_of :ATTR(get => 'node', set => 'node');

    #######################################################################################
    # FUNCTIONS
    #######################################################################################
    #--------------------------------------------------------------------------------------
    # Function: source_equation
    # Synopsys: 
    #--------------------------------------------------------------------------------------
    sub source_equation {
	my %args = (
	    # default values
	    uniquifier => "",
	    node => undef,
	    period => "UNDEF",
	    cycles => "UNDEF",
	    delay => "UNDEF",
	    concentration => "UNDEF",
	    length    => "UNDEF",
	    strength => "UNDEF",
	    @_,			# argument pair list overwrites defaults
	   );

	check_args(\%args, 8);

	my $node = $args{node};
	my $period = $args{period};
	my $cycles = $args{cycles};
	my $delay = $args{delay};
	my $concentration = $args{concentration};
	my $length = $args{length};
	my $strength = $args{strength};

	my $rate_k_name = "k_source_".$args{uniquifier}."_$node";

	if ($concentration ne "UNDEF") {
	    croak "ERROR: length must be given if concentration is defined" if $length eq "UNDEF";
	    croak "ERROR: cannot specify both concentration and strength" if $strength ne "UNDEF";
	    $strength = $concentration/$length;
	} else {
	    croak "ERROR: must specify either strength or concentration and length" if $strength eq "UNDEF";
	}

	if ($period ne "UNDEF") {
	    # if a period is given, length & cycles must be given too
	    croak "ERROR: no. of cycles is required with a periodic source" if ($cycles eq "UNDEF");
	    croak "ERROR: length is required with a periodic source" if ($length eq "UNDEF");
	    $delay = 0 if $delay eq "UNDEF";
	    if ($delay + $length > $period) {
		printn "source_equation: ERROR -- (delay + length) cannot exceed period";
		exit(1);
	    }

	    my $duty = $length/$period*100;
	    my @events = map {($_*$period+$delay,$_*$period+$delay+$length)} (0..$cycles-1);
	    @events = grep {$_ != 0} @events;
	    my $t_end = $cycles * $period;

	    return {
		equations => [
		    "null -> $node; $rate_k_name=\"0.5*$strength*(square(2*pi*(t-$delay)/$period, $duty)+1)\"",
		   ],
		events => \@events,
		t_end => $cycles * $period,
	    };
	} elsif ($length ne "UNDEF") {  # finite length?
	    $delay = 0 if $delay eq "UNDEF";
	    my @events = ($delay, $delay+$length);
	    @events = grep {$_ != 0} @events;
	    return {
		equations => [
		    "null -> $node; $rate_k_name=(t>=$delay && t<($delay+$length))*$strength",
		   ],
		events => \@events,
		t_end => $delay+$length,
	    };
	} elsif ($delay ne "UNDEF") {  # finite delay?
	    my @events = ($delay);
	    @events = grep {$_ != 0} @events;
	    return {
		equations => [
		    "null -> $node; $rate_k_name=(t>=$delay)*$strength",
		   ],
		events => \@events,
		t_end => -1,
	    };
	} else {
	    return {
		equations => [
		    "null -> $node; $rate_k_name=$strength",
		   ],
		events => [],
		t_end => -1,
	    };
	}
    }

    #--------------------------------------------------------------------------------------
    # Function: sink_equation
    # Synopsys: 
    #--------------------------------------------------------------------------------------
    sub sink_equation {
	my %args = (
	    # default values
	    uniquifier => "",
	    node => undef,
	    period => "UNDEF",
	    cycles => "UNDEF",
	    delay => "UNDEF",
	    length    => "UNDEF",
	    strength => undef,
	    sink_node => "null",
	    @_,			# argument pair list overwrites defaults
	   );

	check_args(\%args, 8);

	my $node = $args{node};
	my $period = $args{period};
	my $cycles = $args{cycles};
	my $delay = $args{delay};
	my $length = $args{length};
	my $strength = $args{strength};
	my $sink_node = $args{sink_node};

	my $rate_k_name = "k_sink_".$args{uniquifier}."_$node";

	if ($period ne "UNDEF") {  # finite period?
	    # if a period is given, length & cycles must be given too
	    croak "ERROR: no. of cycles is required with a periodic sink" if ($cycles eq "UNDEF");
	    croak "ERROR: length is required with a periodic sink" if ($length eq "UNDEF");
	    $delay = 0 if $delay eq "UNDEF";
	    if ($delay + $length > $period) {
		printn "sink_equation: ERROR -- (delay + length) cannot exceed period";
		exit(1);
	    }

	    my $duty = $length/$period*100;
	    my @events = map {($_*$period+$delay,$_*$period+$delay+$length)} (0..$cycles-1);
	    @events = grep {$_ != 0} @events;
	    my $t_end = $cycles * $period;
	    return {
		equations => [
		    "$node -> $sink_node; $rate_k_name=\"0.5*$strength*(square(2*pi*(t-$delay)/$period, $duty)+1)\"",
		   ],
		events => \@events,
		t_end => $cycles * $period,
	    };
	} elsif ($length ne "UNDEF") {  # finite length?
	    $delay = 0 if $delay eq "UNDEF";
	    my @events = ($delay, $delay+$length);
	    @events = grep {$_ != 0} @events;
	    return {
		equations => [
		    "$node -> $sink_node; $rate_k_name=(t>=$delay && t<($delay+$length))*$strength",
		   ],
		events => \@events,
		t_end => $delay+$length,
	    };
	} elsif ($delay ne "UNDEF") {  # finite delay?
	    my @events = ($delay);
	    @events = grep {$_ != 0} @events;
	    return {
		equations => [
		    "$node -> $sink_node; $rate_k_name=(t>=$delay)*$strength",
		   ],
		events => \@events,
		t_end => -1,
	    };
	} else {
	    return {
		equations => [
		    "$node -> $sink_node; $rate_k_name=$strength",
		   ],
		events => [],
		t_end => -1,
	    };
	}
    }

    #--------------------------------------------------------------------------------------
    # Function: clamp_equation
    # Synopsys: Generate a source/sink equation pair to clamp a node at a given concentration
    #--------------------------------------------------------------------------------------
    sub clamp_equation {
	my %args = @_;

	# need to filter out undefined values before calling source equation
	my %source_args = (
	    uniquifier => $args{uniquifier},
	    node => $args{node},
	    period => $args{period},
	    cycles => $args{cycles},
	    delay => $args{delay},
	    strength => "$args{concentration}*$args{strength}",
	    length => $args{length},
	   );
	map {delete $source_args{$_} if !defined $source_args{$_}} (keys %source_args);
	my $source_ref = source_equation(
	    %source_args,
	);

	my %sink_args = (
	    uniquifier => $args{uniquifier},
	    node => $args{node},
	    period => $args{period},
	    cycles => $args{cycles},
	    delay => $args{delay},
	    strength => $args{strength},
	    length => $args{length},
	    sink_node => $args{sink_node} || "null",
	);
	map {delete $sink_args{$_} if !defined $sink_args{$_}} (keys %sink_args);
	my $sink_ref = sink_equation(
	    %sink_args,
	);

	my @equations = (@{$source_ref->{equations}},
			 @{$sink_ref->{equations}});
	my @events = @{$source_ref->{events}};
	my $t_end = $source_ref->{t_end};
	return {
	    equations => \@equations,
	    events => \@events,
	    t_end => $t_end,
	};
    }

    #--------------------------------------------------------------------------------------
    # Function: staircase_equation
    # Synopsys: Generate a waveform which ramps up and down periodically, using discrete
    #           steps which give a staircase-shaped result.
    #--------------------------------------------------------------------------------------
    # The following parameters are used:
    #  period:  period of the waveform
    #  cycles:  number of periods to generate waveform
    #   delay:  delay to first rising step
    # strength: strength of clamping
    # concentration: desired concentration when waveform is at maximum
    #    duty:  indicates time spent at high level (incl. rise/fall times),
    #  rftime:  gives the nominal rise/fall time
    #   steps:  gives how many steps used when changing
    #
    # The function returns the following in a hash:
    #  events: a list of event times where step function changes(first period only)
    #  values: expected steady-state value of the function right BEFORE the event.
    #
    # The actual rise/fall time realized will depend on the values of other parameters
    # and whther there are other sinks an sources in the system that influence the given
    # node.  Rise/fall times will approach the nominal value as the no. of steps and
    # the strength increases.
    #
    # The ramp_equation will touch at the bottom/top corners of the corresponding
    # staircase function when rising/falling.
    #--------------------------------------------------------------------------------------
    sub staircase_equation {
	my %args = (
	    # default values
	    uniquifier => "",
	    node => undef,
	    period => undef,
	    cycles => 1,
	    delay => 0,
	    strength => undef,
	    concentration => undef,
	    duty => 50,
	    rftime => undef,
	    steps => undef,	# of steps in each direction
	    @_,			# argument pair list overwrites defaults
	   );

	check_args(\%args, 10);

	my $node = $args{node};
	my $period = $args{period};
	my $cycles = $args{cycles};
	my $delay = $args{delay};
	my $strength = $args{strength};
	my $concentration = $args{concentration};
	my $duty = $args{duty};
	my $rftime = $args{rftime};
	my $steps = $args{steps};

	my $pulse_width = $duty * $period / 100.0;
	my $square_width = $pulse_width - $rftime;
	my $square_duty = ($square_width) / $period * 100.0;

	my $t_end = $period * $cycles;

	if ($steps < 1) {
	    printn "ERROR: staircase_equation -- step parameter must be >= 1";
	    exit(1);
	}

	if ($pulse_width < 2 * $rftime) {
	    printn "ERROR: staircase_equation -- parameters are inconsistent (rise/fall time exceeds computed pulse width)";
	    exit(1);
	}

	if ($square_duty <= 0) {
	    printn "ERROR: staircase_equation -- parameters are inconsistent (rise/fall time too large?)";
	    exit(1);
	}

	if (($steps < 2) && ($rftime > 0)) {
	    printn "ERROR: staircase_equation -- parameters are inconsistent (cannot implement non-zero rise/fall time with indicated # of steps)";
	    exit(1);
	}
	
	my $square_delay = ($steps < 2) ? 0 : $rftime / ($steps);

	my @source_terms;
	my @leading_edge_events;
	my @trailing_edge_events;
	my @leading_edge_values;
	my @trailing_edge_values;
	for (my $i=0; $i < $steps; $i++) {
	    my $shift = $i * $square_delay + $delay;
	    push @leading_edge_events, $shift;
	    push @leading_edge_values, $i / $steps * $concentration;
	    push @trailing_edge_events, $shift + $square_width;
	    push @trailing_edge_values, $concentration * ($steps - $i) / $steps;
	    # to prevent roundoff error, multiply by pi as very last step, else
	    # we may get **old** value at event time instead of the new value
	    push @source_terms, "0.5*$concentration*$strength*(1 + square((t-$shift)/$period*2*pi, $square_duty))";
	}
	my $source_rate_expression = "(".join(" + ", @source_terms).")/$steps";

	my @events = (@leading_edge_events, @trailing_edge_events);
	# only events in the first period are included here. also, if the delay offset
	# is too large, some events will fall outside the period, so we must use
	# a modulus operator to fix this.  we also use Utils::fmod which can handle
	# fractional dividends
	@events = map {fmod($_,$period)} @events;
	my @order = sort {$events[$a] <=> $events[$b]} (0..$#events);
	@order = grep {$events[$_] != 0} @order; # don't include 0.0 as an event
	@events = map {$events[$_]} @order;
	my @values = (@leading_edge_values, @trailing_edge_values);
	@values = map {$values[$_]} @order;

	# now add events in remaining periods
	my @more_events;
	my @more_values;
	for (my $i=1; $i < $cycles; $i++) {
	    push @more_events, (map {$_+$period*$i} @events);
	    push @more_values, @values;
	}
	push @events, @more_events;
	push @values, @more_values;

	printn "staircase_equation: event list is @events" if $verbosity >= 3;
	printn "staircase_equation: value list is @values" if $verbosity >= 3;

	my $source_rate_k_name = "k_source_".$args{uniquifier}."_$node";
	my $sink_rate_k_name = "k_sink_".$args{uniquifier}."_$node";

	if ($duty < 100) {
	    # final value is value at last event +/- one step
	    my $final_value = $values[@values-1];
	    $final_value += (
		fmod(($period - $delay),$period) <= ($pulse_width - $rftime) &&
		fmod(($period - $delay), $period) > 0 ?
		($concentration/$steps) :
		(-$concentration/$steps)
	       );
	    return {
		equations => [
		    "null -> $node; $source_rate_k_name=\"(t < $t_end)*$source_rate_expression\"",
		    "$node -> null; $sink_rate_k_name=$strength",
		   ],
		events => \@events,
		values => \@values,
		final_value => $final_value,
		t_end => $t_end,
	    };
	} else {
	    return {
		equations => [
		    "null -> $node; $source_rate_k_name=".$concentration*$strength,
		    "$node -> null; $sink_rate_k_name=$strength",
		   ],
		events => [],
		values => [],
		final_value => $concentration,
		t_end => $t_end,
	    };
	}
    }

#    #--------------------------------------------------------------------------------------
#    # Function: staircase_sample
#    # Synopsys: Call staircase_equation with dummy values
#    #--------------------------------------------------------------------------------------
#    sub staircase_sample {
#	my %args = (
#	    # default values
#	    CONCENTRATION => undef,
#	    PERIOD => undef,
#	    DELAY => 0,
#	    DUTY => 50,
#	    RFTIME => undef,
#	    STEPS => undef,	# of steps in each direction
#	    @_,			# argument pair list overwrites defaults
#	   );

#	check_args(\%args, 6);

#	my $staircase_ref = staircase_equation(
#	    NODE => "DUMMY",
#	    STRENGTH => 1.0,
#	    %args,
#	   );
#	return {
#	    events => $staircase_ref->{events},
#	    values => $staircase_ref->{values},
#	    final_value => $staircase_ref->{final_value},
#	}
#    }

    #--------------------------------------------------------------------------------------
    # Function: ramp_equation
    # Synopsys: Generate a linear waveform which ramps up and down periodically.
    #           Arguments and return values are identical to staircase_equation
    #           for compatibility, even though some arguments are not applicable.
    #--------------------------------------------------------------------------------------
    sub ramp_equation {
	my %args = (
	    # default values
	    uniquifier => "",
	    node => undef,
	    period => undef,
	    cycles => 1,
	    delay => 0,
	    strength => undef,
	    concentration    => undef,
	    duty => 50,
	    rftime => undef,
	    steps => "UNDEF",	# N/A
	    @_,			# argument pair list overwrites defaults
	   );

	check_args(\%args, 10);

	my $node = $args{node};
	my $period = $args{period};
	my $cycles = $args{cycles};
	my $delay = $args{delay};
	my $strength = $args{strength};
	my $concentration = $args{concentration};
	my $duty = $args{duty};
	my $rftime = $args{rftime};
	my $steps = $args{steps};

	my $pulse_width = $duty * $period / 100.0;
	my $ramp_duty = ($rftime) / $period * 100.0;
	my $square_duty = ($pulse_width - 2*$rftime) / $period * 100.0;

	my $t_end = $period * $cycles;

	if ($pulse_width < 2 * $rftime) {
	    printn "ERROR: ramp_equation -- parameters are inconsistent (rise/fall time exceeds computed pulse width)";
	    exit(1);
	}

	# n.b. in the square() function, very important to *(pi) as very last step, else roundoff error introduced messes up the square()
	# function interval, such that square(falling edge time) = +1 instead of -1 --> this introduces an extra discontinuity!!
	# i.e. at event time, we will add old value of leading square with new value of lagging square, and this gives a spike with twice
	# the intended value at (and only at) the event time!!!
	my $source_rate_expression = "(";
	my $rise_ramp_delay = $delay;
	my $fall_ramp_delay = $delay + $pulse_width - $rftime;
	$source_rate_expression .= "0.5*(mod(t,$period)-$rise_ramp_delay)/$rftime*$concentration*$strength*(1 + square((t-$rise_ramp_delay)/$period*2*pi, $ramp_duty))";
	$source_rate_expression .= "+ 0.5*$concentration*$strength*(1 + square((t-$rise_ramp_delay-$rftime)/$period*2*pi, $square_duty))";
	$source_rate_expression .= "+ 0.5*(-mod(t,$period)+$fall_ramp_delay+$rftime)/$rftime*$concentration*$strength*(1 + square((t-$fall_ramp_delay)/$period*2*pi, $ramp_duty))";
	$source_rate_expression .= ")";

	my @events;
	if ($delay + $rftime != $fall_ramp_delay) {
	    @events= ($delay, $delay + $rftime, $fall_ramp_delay, $fall_ramp_delay + $rftime);
	} else {
	    @events= ($delay, $delay + $rftime, $fall_ramp_delay + $rftime);
	}
	# only events in the first period are included here. also, if the delay offset
	# is too large, some events will fall outside the period, so we must use
	# a modulus operator to fix this.  we also use Utils::fmod which can handle
	# fractional dividends
	@events = map {fmod($_, $period)} @events;
	my @order = sort {$events[$a] <=> $events[$b]} (0..$#events);
	@order = grep {$events[$_] != 0} @order; # don't include 0.0 as an event
	@events = map {$events[$_]} @order;
	my @values = (0, $concentration, $concentration, 0);
	@values = map {$values[$_]} @order;

	# now add events in remaining periods
	my @more_events;
	my @more_values;
	for (my $i=1; $i < $cycles; $i++) {
	    push @more_events, (map {$_+$period*$i} @events);
	    push @more_values, @values;
	}
	push @events, @more_events;
	push @values, @more_values;

	printn "ramp_equation: event list is @events" if $verbosity >= 3;
	printn "ramp_equation: value list is @values" if $verbosity >= 3;

	my $source_rate_k_name = "k_source_".$args{uniquifier}."_$node";
	my $sink_rate_k_name = "k_sink_".$args{uniquifier}."_$node";

	if ($duty < 100) {
	    return {
		equations => [
		    "null -> $node; $source_rate_k_name=\"(t < $t_end) * $source_rate_expression\"",
		    "$node -> null; $sink_rate_k_name=$strength",
		   ],
		events => \@events,
		values => \@values,
		t_end => $t_end,
	    }
	} else {
	    return {
		equations => [
		    "null -> $node; $source_rate_k_name=".$concentration*$strength,
		    "$node -> null; $sink_rate_k_name=$strength"
		   ],
		events => [],
		values => [],
		t_end => $t_end,
	    };
	}
    }


    #--------------------------------------------------------------------------------------
    # Function: dose_response_equation
    # Synopsys: Generate a non-periodic source/sink equation pair to force target node
    #           to take on a range of values (increasing, then decreasing) in a staircase-like
    #           fashion. The system is brought to steady-state at each step.
    #           Alternatively, if impulse_length is non-zero, then at each step a given amount of
    #           the target node will be dumped into the system over a time impulse_length,
    #           such that the cumulative amount of target injected into the system varies
    #           according to the given range.
    #--------------------------------------------------------------------------------------
    sub dose_response_equation {
	my %args = (
	    # default values
	    uniquifier => "",
	    node => undef,
	    strength => undef,     # clamping strength
	    range    => undef,     # range min and max (if scalar, min is 0 and max is argument)
	    steps => undef,        # no. of steps in dose-response
	    log_steps => 0,        # indicates whether range steps are equal in linear vs log space
	    impulse_length => 0,   # if set, given amount is dumped into system during impulse
	    @_,			   # argument pair list overwrites defaults
	   );

	check_args(\%args, 7);

	my $node = $args{node};
	my $strength = $args{strength};
	my $range_ref = $args{range};
	$range_ref = ref $range_ref ? $range_ref : [0,$range_ref];
	my $range_min = $range_ref->[0];
	my $range_max = $range_ref->[1];
	my $steps = $args{steps};
	my $log_steps = $args{log_steps};
	my $impulse_length = $args{impulse_length};

	my @values = ($range_min);
	my @step_sizes = ();
	if (!$log_steps) {
	    my $step_size = ($range_max - $range_min) / $steps;
	    push @step_sizes, map {$step_size} (1..$steps);
	    push @values, map {$range_min+$_*$step_size} (1..$steps);
	    push @values, map {$range_min+($steps-$_)*$step_size} (1..$steps);
	} else {
	    # compute values first
	    my $fold_change = ($range_max/$range_min)**(1/$steps);
	    push @values, map {$range_min*($fold_change**$_)} (1..$steps);
	    push @values, map {$range_min*($fold_change**($steps-$_))} (1..$steps);
	    # now step sizes
	    @step_sizes = map {$values[$_]-$values[$_-1]} (1..$steps);
	}

	my @events;
	if ($impulse_length == 0) {
	    @events = ("~", map {"~"} (1..2*$steps));
	} else {
	    @events = ("$impulse_length", "~", map {("-$impulse_length","~")} (1..$steps));
	}

	# waveform:
	#                |--------------|
	#             +     |--------|
	#             +        |--|
	#        ------------------------------------
	#             =  |--|--|--|--|--|
	my $source_rate_expression;
	if ($impulse_length == 0) {
	    $source_rate_expression = "($range_min*$strength ";
	    for (my $i=0; $i < $steps; $i++) {
		my $ii = $i + 1;
		my $jj = 2*$steps - $i;
		$source_rate_expression .= "+(event_flags($ii) && ~event_flags($jj))*$step_sizes[$i]*$strength";
	    }
	    $source_rate_expression .= ")";
	} else {
	    $source_rate_expression = "((~event_flags(1))*$range_min/$impulse_length ";
	    for (my $i=0; $i < $steps; $i++) {
		my $ii = 2*$i + 2;
		my $jj = $ii + 1;
		$source_rate_expression .= "+(event_flags($ii) && ~event_flags($jj))*$step_sizes[$i]/$impulse_length";
	    }
	    $source_rate_expression .= ")";
	}


	printn "dose_response_equation: event list is @events" if $verbosity >= 2;
	printn "dose_response_equation: value list is @values" if $verbosity >= 2;
	printn "dose_response_equation: step sizes are @step_sizes" if $verbosity >= 2;

	my $source_rate_k_name = "k_source_".$args{uniquifier}."_$node";
	my $sink_rate_k_name = "k_sink_".$args{uniquifier}."_$node";

	my $equations_ref;
	if ($impulse_length == 0 ) {
	    $equations_ref = [
		"null -> $node; $source_rate_k_name=\"$source_rate_expression\"",
		"$node -> null; $sink_rate_k_name=$strength",
	       ];
	} else {
	    # no sink!!!!
	    $equations_ref = [
		"null -> $node; $source_rate_k_name=\"$source_rate_expression\"",
	       ];
	}
	return {
	    equations => $equations_ref,
	    events => \@events,
	    values => \@values,
	    t_end => 0,
	}
    }

    #######################################################################################
    # CLASS METHODS
    #######################################################################################
    #--------------------------------------------------------------------------------------
    # Function: get_events
    # Synopsys: Get sorted list of event times for all succesfully compiled Stimulus
    #           objects.
    #--------------------------------------------------------------------------------------
    sub get_events {
	my $self = shift;

	if (!ref $self) { # class method?
	    my $class = $self;
	    my @events = ();
	    my @instances = grep {defined $_->get_node()} $class->get_instances();

	    # the stimulus dose_response has steady-state events, which cannot be sorted
 	    my @no_ss_instances = grep {$_->get_type() ne "dose_response"} @instances;
 	    my @ss_instances = grep {$_->get_type eq "dose_response"} @instances;

	    map {push @events, @{$_->get_events()}} @no_ss_instances;
	    @events = sort {$a <=> $b} @events;
	    @events = simple_difference(\@events, []); # remove dups

	    # now append any event lists with steady-state events
	    map {push @events, @{$_->get_events()}} @ss_instances;

	    push @events, '~' if Stimulus->get_class_data("append_ss_event");

	    return @events;
	} else {
	    return $events_of{ident $self};
	}
    }

    #--------------------------------------------------------------------------------------
    # Function: get_t_end
    # Synopsys: Get t_end times for all successfully compiled Stimulus
    #           objects, and return the largest one.
    #--------------------------------------------------------------------------------------
    sub get_t_end {
	my $self = shift;

	if (!ref $self) { # class method?
	    my $class = $self;
	    my @end_times = ();

	    my @instances = grep {defined $_->get_node()} $class->get_instances();
	    map {push @end_times, $_->get_t_end()} @instances;
	    @end_times = sort {$a <=> $b} @end_times;
	    my $t_end = $end_times[$#end_times];
	    return $t_end;
	} else {
	    return $t_end_of{ident $self};
	}
    }

    #--------------------------------------------------------------------------------------
    # Function: export_facile
    # Synopsys: Export all successfully compiled Stimulus objects.
    #--------------------------------------------------------------------------------------
    sub export_facile {
	my $class = shift;

	my @export = ();

	my @stimuli = grep {defined $_->get_node()} $class->get_instances();

	if (@stimuli) {
	    push @export,  "\n\n";
	    push @export,  "# STIMULI (from Stimulus objects)\n";
	    push @export,  "# ------------------------------------\n";
	    push @export,  "EQN:\n";

	    foreach my $stimulus_ref (@stimuli) {
		push @export,  $stimulus_ref->sprint_equations();
		push @export,  "\n";
	    }

	    push @export,  "\nCONFIG:\n";

	    # merge t_end and t_final from CONFIG section
	    my $config_t_final = Facile->get_config_variables()->{t_final} || 0;
	    my $largest_t_end = Stimulus->get_t_end();
	    my $t_final = ($config_t_final > $largest_t_end) ? $config_t_final : $largest_t_end;

	    # make sure last event is < t_final
	    my @events = Stimulus->get_events();
	    pop @events while (@events && ($events[$#events] ne '~') && ($events[$#events] >= $t_final));

	    push @export,  "ode_event_times = ".join " ",@events,"\n" if @events;
	    $t_final = 10 if $t_final <= 0;
	    push @export,  "t_final = ".$t_final."\n";
	}
	return \@export;
    }

#    #--------------------------------------------------------------------------------------
#    # Function: XXX
#    # Synopsys: 
#    #--------------------------------------------------------------------------------------
#    sub XXX {
#	my $class = shift;
#    }

    #######################################################################################
    # INSTANCE METHODS
    #######################################################################################
    #--------------------------------------------------------------------------------------
    # Function: BUILD
    # Synopsys: 
    #--------------------------------------------------------------------------------------
    sub BUILD {
        my ($self, $obj_ID, $arg_ref) = @_;

	$node_of{$obj_ID} = $arg_ref->{node} if exists $arg_ref->{node};

	# populate params_ref
	my $params_ref = $params_ref_of{$obj_ID} = {};

	%{$params_ref} = %$arg_ref;
	delete $$params_ref{structure};
	delete $$params_ref{state};
	delete $$params_ref{name};
	delete $$params_ref{node};
	delete $$params_ref{type};
    }

    #--------------------------------------------------------------------------------------
    # Function: START
    # Synopsys: 
    #--------------------------------------------------------------------------------------
    sub START {
        my ($self, $obj_ID, $arg_ref) = @_;

	# check initializers
	my $type = $type_of{$obj_ID};
	my @valid_types = keys %functions_map;
	
	if (grep {$_ eq $type} @valid_types != 1) {
	    croak "ERROR: unknown Stimulus type ($type)";
	}
    }


    #--------------------------------------------------------------------------------------
    # Function: compile
    # Synopsys: Compile the object's Facile equations and event times.
    #--------------------------------------------------------------------------------------
    sub compile {
	my $self = shift;

	if (!ref $self) {  # class method?
	    my $class = $self;
	    map {$_->compile()} $class->get_instances();
	} else {           # instance method
	    my $obj_ID = ident $self;
	    my $node = $node_of{$obj_ID};
	    my $type = $type_of{$obj_ID};
	    my $params_ref = $params_ref_of{$obj_ID};

	    # first compile Selector if required
	    if (!defined $node) {
		$self->Selector::compile(@_);
		my $selected_ref = $self->get_selected_ref();
		if (!defined $selected_ref) {
		    return;
		}
		$node = $node_of{$obj_ID} = $selected_ref->get_exported_name();
	    }

	    # now compile equations
	    my $name = $self->get_name();
	    my $uniquifier = strip($name, "!");
	    my $function = $functions_map{$type};
	    if (!defined $function) {
		printn "ERROR: unknown stimulus type --> $type";
		exit(1);
	    }

	    my $result_ref = eval("$function(uniquifier => \$uniquifier, node => \$node, \%\$params_ref)");
	    if ($@) {
		my $name = $self->get_name();
		printn "ERROR: problem compiling Stimulus object $name";
		printn $@;
		exit(1);
	    }

	    $equations_of{$obj_ID} = $result_ref->{equations};
	    $events_of{$obj_ID} = $result_ref->{events};
	    $t_end_of{$obj_ID} = $result_ref->{t_end};
	}
    }

    #--------------------------------------------------------------------------------------
    # Function: sprint_equations
    # Synopsys: 
    #--------------------------------------------------------------------------------------
    sub sprint_equations {
	my $self = shift;
	my $equations_ref = $self->get_equations();
	return join "\n",@{$equations_ref};
    }
}


sub run_testcases {
    use Null;

    use Globals;
    $verbosity = 2;

    printn "run_testcases: Stimulus package";

    Stimulus->new({
	node => "X10",
	type => "impulse",
	period => 10,
	cycles => 3,
	delay => 1,
	concentration => 2,
	length => 0.1,
    });
    Stimulus->new({
	node => "X11",
	type => "impulse",
	delay => 1.5,
	concentration => 3,
	length => 0.4,
    });
    Stimulus->new({
	node => "X12",
	type => "source",
	delay => 2,
	strength => 5,
    });
    Stimulus->new({
	node => "X13",
	type => "source",
	strength => 1,
    });

    Stimulus->new({
	node => "X13",
	type => "sink",
	period => 10,
	cycles => 2,
	delay => 1,
	strength => 4,
	length => 2,
    });
    Stimulus->new({
	node => "X13",
	type => "wash",
	delay => 4,
	strength => 20,
	length => 0.5,
    });
    Stimulus->new({
	node => "X13",
	type => "wash",
	strength => 2,
	delay => 5,
    });
    Stimulus->new({
	node => "X12",
	type => "wash",
	strength => 0.1,
    });

    Stimulus->new({
	node => "X20",
	type => "clamp",
	period => 10,
	cycles => 1,
	delay => 1,
	concentration => 2,
	length => 3,
	strength => 4,
    });

    Stimulus->new({
	node => "X30",
	type => "staircase",
	period => 10,
	cycles => 2,
	delay => 1,
	strength => 10,
	concentration => 2,
	duty => 80,
	rftime => 3,
	steps => 3,
    });


    Stimulus->new({
	node => "X40",
	type => "ramp",
	period => 10,
	cycles => 2,
	delay => 1,
	strength => 10,
	concentration => 2,
	duty => 80,
	rftime => 3,
    });

    Stimulus->new({
	node => "X50",
	type => "ramp",
	period => 20,
	delay => 1,
	strength => 4,
	concentration => 2,
	rftime => 4,
    });

#    Stimulus->new({
#	node => "X60",
#	type => "dose_response",
#	strength => 4,
#	range => 2,
#	steps => 3,
#    });

    printn "COMPILING STIMULUS OBJECTS";
    Stimulus->compile();

    printn "DUMPING STIMULUS OBJECTS";
    printn $_->_DUMP() foreach Stimulus->get_instances();

    printn "EXPORTING STIMULUS EQUATIONS";
    use Facile;
    my $facile_export_ref = Stimulus->export_facile();

    # tack on a tv definition
    push @$facile_export_ref, "t_vector = [t0:0.1:tf]\n";
    push @$facile_export_ref, "t_final = 10000.0\n";

    burp_file("test/modules/Stimulus.eqn", @$facile_export_ref);
    printn slurp_file("test/modules/Stimulus.eqn");
}
# Incorporate these into testcase, or put in test/models/stimulus.mod

## clamp free X at 1 from t=10 to 20s
#Stimulus : {
#	structure => 'X',
#	type => "clamp",
#	length => 20,
#	delay => 10,
#	strength => 10,
#	concentration => 1,
#}

## ramp up at 50s for 10s
#Stimulus : {
#	structure => 'X',
#	type => "clamp",
#	length => 10,
#	cycles => 1,	
#	delay => 50,
#	strength => 100,
#	concentration => "(t-50+1)",
#}

## drop in a total of X0=0.005*200=1 units at t=100 over 50s
#Stimulus : {
#	structure => 'X',
#	type => "source",
#	length => 50,
#	cycles => -1,	
#	delay => 100,
#	concentration => 1,
#}




# Package BEGIN must return true value
return 1;
