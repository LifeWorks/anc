######################################################################################
# File:     Variable.pm
# Author:   Julien F. Ollivier
#
# Copyright (C) 2005-2010 Julien Ollivier.
#
# This program comes with ABSOLUTELY NO WARRANTY.
# This is free software, and you are welcome to redistribute it
# under certain conditions. See file LICENSE.TXT for details.
#
# Synopsys: Package to handle parameters and expressions involved in rate constant
#           calculations.  Arithmetic operators are overloaded.  Values may be
#           numerical constants, symbolic expressions such as "x+y" or the
#           special values INF and NAN. The value -INF is not allowed or handled
#           except as a the 2nd argument of (**) operator.
######################################################################################
# Detailed Description:
# ---------------------
#
# Variables are either numerical values, symbolic expressions, or the
# special values INF and NAN. In the case of phi-values, negative values
# including -INF are allowed.
#
# For the operators (+,-,*,/), the calculations are assumed to involve non-negative
# regulatory factors, whether numeric or symbolic. As such, arguments may be numbers,
# INF, or symbolic expressions which are assumed to evaluate to a non-negative value.
# Because the arguments are regulatory factors which theoretically have a positive
# and finite value, handling of the special value INF during these arithmetic operations
# is done with the assumption that INF means an arbitrarily large value taken to the
# limit, while 0 means a positive value approaching the limit of 0. Any operations such
# as (x - INF) which yield -INF are not supported and will return NAN instead.
# Any symbolic expressions are assumed to evaluate to a positive, non-zero value.
#
# For the operator (**), the first argument is again assumed to be a non-negative
# regulatory factor and treated the same way as above. The second argument is assumed to
# be a phi-value, which may have any symbolic or numeric value including +-INF. A
# phi-value of 0 and 1 is treated as exact and not as the result of taking a limit.
#
# If either Variable involved in a binary operation is an expression, so is the result.
#
# If the user does not supply a variable's value, it is treated as an expression
# whose value is the name of the variable, and initialized as such.
#
#
######################################################################################

use strict;
use diagnostics;		# equivalent to -w command-line switch
use warnings;

package Variable;
use Class::Std::Storable;
use base qw(Named);
{
    use Carp;
    use Utils;

    use overload
    '+' => \&i_add,
    '-' => \&i_sub,
    '*' => \&i_mult,
    '/' => \&i_div,
    '**' => \&i_pow;

    #######################################################################################
    # CLASS ATTRIBUTES
    #######################################################################################

    #######################################################################################
    # ATTRIBUTES
    #######################################################################################
    # this flag will be false if value is an expression, and true if a numeric value
    # including +-INF and NAN
    my %is_numeric_flag_of :ATTR(get => 'is_numeric_flag', set => 'is_numeric_flag', default => 1);
    my %value_of :ATTR(get => 'value', set => 'value');

    #######################################################################################
    # FUNCTIONS
    #######################################################################################

    #######################################################################################
    # CLASS METHODS
    #######################################################################################

    #######################################################################################
    # INSTANCE METHODS
    #######################################################################################
    sub BUILD {
        my ($self, $obj_ID, $arg_ref) = @_;

	# if no value is given, value is set to param name and
	# this will cause numeric_flag to be reset
	$value_of{$obj_ID} = defined $arg_ref->{value} ? $arg_ref->{value} : $arg_ref->{name};
    }

    sub START {
        my ($self, $obj_ID, $arg_ref) = @_;

	# !!! N.b. keep in mind that is_numeric() returns TRUE for INF and NAN values
	my $is_numeric_flag = $is_numeric_flag_of{$obj_ID} = (
	    defined $value_of{$obj_ID} &&
	    is_numeric($value_of{$obj_ID})) ? 1 : 0;
    }

    #--------------------------------------------------------------------------------------
    # Function: i_mult
    # Synopsys: Compute x * y.
    #--------------------------------------------------------------------------------------
    sub i_mult {
	my $x_ref = shift;
	my $y_ref = shift;
	my $flipped = shift;  # see Prog. Perl p. 464 for explanation of flipped
	confess "ERROR: args must be references" if !ref $x_ref || !ref $y_ref;
	($x_ref, $y_ref) = $flipped ? ($y_ref, $x_ref) : ($x_ref, $y_ref);
	my $x_ID = ident $x_ref;
	my $y_ID = ident $y_ref;

	my $x = $value_of{$x_ID};
	my $y = $value_of{$y_ID};

	return "NAN" if (($x eq "NAN") || ($y eq "NAN")); # return Not A Number (NAN) if either arg is NAN

	my $x_is_numeric_flag = $is_numeric_flag_of{$x_ID};
	my $y_is_numeric_flag = $is_numeric_flag_of{$y_ID};

	# return NAN rather than -INF
	return "NAN" if ($x_is_numeric_flag && $x < 0 && $y eq "INF");
	return "NAN" if ($y_is_numeric_flag && $y < 0 && $x eq "INF");

	# treat as product of opposing limits
	return "NAN" if ($x_is_numeric_flag && $x == 0 && $y eq "INF");
	return "NAN" if ($y_is_numeric_flag && $y == 0 && $x eq "INF");

	# arguments are now symbolic, positive numbers or INF
	return "INF" if ($x eq "INF" || $y eq "INF");
	
	return 0 if ($x_is_numeric_flag && $x == 0);
	return 0 if ($y_is_numeric_flag && $y == 0);

	return $y if ($x_is_numeric_flag && $x == 1);  # identity
	return $x if ($y_is_numeric_flag && $y == 1);  # identity

	if (!$x_is_numeric_flag || !$y_is_numeric_flag) {
	    $x = "($x)" if !$x_is_numeric_flag && ($x =~ /[+-]|\*|\//) && ($x !~ /^\([^)]*\)$/);  # add paren if operation in expression
	    $y = "($y)" if !$y_is_numeric_flag && ($y =~ /[+-]|\*|\//) && ($y !~ /^\([^)]*\)$/);  # add paren if operation in expression
	    return "$x * $y";
	} else {
	    return $x * $y;
	}
    }

    #--------------------------------------------------------------------------------------
    # Function: i_div
    # Synopsys: Compute x / y.
    #--------------------------------------------------------------------------------------
    sub i_div {
	my $x_ref = shift;
	my $y_ref = shift;
	my $flipped = shift;
	confess "ERROR: args must be references" if !ref $x_ref || !ref $y_ref;
	($x_ref, $y_ref) = $flipped ? ($y_ref, $x_ref) : ($x_ref, $y_ref);
	my $x_ID = ident $x_ref;
	my $y_ID = ident $y_ref;

	my $x = $value_of{$x_ID};
	my $y = $value_of{$y_ID};

	return "NAN" if (($x eq "NAN") || ($y eq "NAN")); # return Not A Number (NAN) if either arg is NAN

	my $x_is_numeric_flag = $is_numeric_flag_of{$x_ID};
	my $y_is_numeric_flag = $is_numeric_flag_of{$y_ID};

	# INF/INF
	return "NAN" if ($x eq "INF" && $y eq "INF");
	# 0/0
	return "NAN" if ($x_is_numeric_flag && $x == 0 && $y_is_numeric_flag && $y == 0);

	# number/(same number)
	return 1 if ($x_is_numeric_flag && $y_is_numeric_flag && $x == $y);
	# expression/(same expression)
	return 1 if (!$x_is_numeric_flag && !$y_is_numeric_flag && $x eq $y);

	# return NAN rather than -INF
	return "NAN" if ($y_is_numeric_flag && $y < 0 && $x eq "INF");

	return "INF" if ($x eq "INF");
	return 0 if ($y eq "INF");

	return 0 if ($x_is_numeric_flag && $x == 0);
	return "INF" if ($y_is_numeric_flag && $y == 0);

	return $x if ($y_is_numeric_flag && $y == 1);

	if (!$x_is_numeric_flag || !$y_is_numeric_flag) {
	    $x = "($x)" if !$x_is_numeric_flag && ($x =~ /[+-]|\*|\//) && ($x !~ /^\([^)]*\)$/);  # add paren if operation in expression
	    $y = "($y)" if !$y_is_numeric_flag && ($y =~ /[+-]|\*|\//) && ($y !~ /^\([^)]*\)$/);  # add paren if operation in expression
	    return "$x / $y";
	} else {
	    return $x/$y;
	}
    }

    #--------------------------------------------------------------------------------------
    # Function: i_add
    # Synopsys: Compute x + y.
    #--------------------------------------------------------------------------------------
    sub i_add {
	my $x_ref = shift;
	my $y_ref = shift;
	my $flipped = shift;
	confess "ERROR: args must be references" if !ref $x_ref || !ref $y_ref;
	($x_ref, $y_ref) = $flipped ? ($y_ref, $x_ref) : ($x_ref, $y_ref);
	my $x_ID = ident $x_ref;
	my $y_ID = ident $y_ref;

	my $x = $value_of{$x_ID};
	my $y = $value_of{$y_ID};

	return "NAN" if (($x eq "NAN") || ($y eq "NAN")); # return Not A Number (NAN) if either arg is NAN

	return "INF" if ($x eq "INF");
	return "INF" if ($y eq "INF");

	my $x_is_numeric_flag = $is_numeric_flag_of{$x_ID};
	my $y_is_numeric_flag = $is_numeric_flag_of{$y_ID};

	return $y if ($x_is_numeric_flag && $x == 0);  # identity
	return $x if ($y_is_numeric_flag && $y == 0);  # identity

	if (!$x_is_numeric_flag || !$y_is_numeric_flag) {
	    return "($x + $y)";
	} else {
	    return ($x + $y);
	}
    }

    #--------------------------------------------------------------------------------------
    # Function: i_sub
    # Synopsys: Compute x - y.
    #--------------------------------------------------------------------------------------
    sub i_sub {
	my $x_ref = shift;
	my $y_ref = shift;
	my $flipped = shift;
	confess "ERROR: args must be references" if !ref $x_ref || !ref $y_ref;
	($x_ref, $y_ref) = $flipped ? ($y_ref, $x_ref) : ($x_ref, $y_ref);
	my $x_ID = ident $x_ref;
	my $y_ID = ident $y_ref;

	my $x = $value_of{$x_ID};
	my $y = $value_of{$y_ID};

	return "NAN" if (($x eq "NAN") || ($y eq "NAN")); # return Not A Number (NAN) if either arg is NAN

	return "NAN" if ($y eq "INF");
	return "INF" if ($x eq "INF");

	my $x_is_numeric_flag = $is_numeric_flag_of{$x_ID};
	my $y_is_numeric_flag = $is_numeric_flag_of{$y_ID};

	return $x if ($y_is_numeric_flag && $y == 0); # identity

	if ($x_is_numeric_flag && $x == 0 && !$y_is_numeric_flag) {
	    $y = "($y)" if !$y_is_numeric_flag && ($y =~ /[+-]|\*|\//) && ($y !~ /^\([^)]*\)$/);  # add paren if operation in expression
	    return "-$y";
	}

	if (!$x_is_numeric_flag || !$y_is_numeric_flag) {
	    # both are finite
	    $y = "($y)" if !$y_is_numeric_flag && ($y =~ /[+-]|\*|\//) && ($y !~ /^\([^)]*\)$/);  # add paren if operation in expression
	    return "($x - $y)";
	} else {
	    # both are finite
	    return $x - $y;
	}
    }

    #--------------------------------------------------------------------------------------
    # Function: i_pow
    # Synopsys: Compute x ** y.
    #--------------------------------------------------------------------------------------
    sub i_pow {
	my $x_ref = shift;
	my $y_ref = shift;
	my $flipped = shift;
	confess "ERROR: args must be references" if !ref $x_ref || !ref $y_ref;
	($x_ref, $y_ref) = $flipped ? ($y_ref, $x_ref) : ($x_ref, $y_ref);
	my $x_ID = ident $x_ref;
	my $y_ID = ident $y_ref;

	my $x = $value_of{$x_ID};
	my $y = $value_of{$y_ID};
	my $x_is_numeric_flag = $is_numeric_flag_of{$x_ID};
	my $y_is_numeric_flag = $is_numeric_flag_of{$y_ID};

	# n.b. since x is a reg_factor and y is a phi-value,
	# assume that x in [0,inf) , but y in (-inf, +inf)

	# return Not A Number (NAN) if either arg is NAN
	return "NAN" if (($x eq "NAN") || ($y eq "NAN"));

	# x shouldn't be negative or -INF
	return "NAN" if ($x_is_numeric_flag && $x < 0);

	# return INF for INF**INF
	return "INF" if ($x eq "INF") && ($y eq "INF");
	# return 0 for INF**(-INF)
	return 0 if ($x eq "INF") && ($y eq "-INF");

	# can't evaluate symbolic**(+-INF)
	return "NAN" if (!$x_is_numeric_flag && $y eq "INF");
	return "NAN" if (!$x_is_numeric_flag && $y eq "-INF");
	# can't evaluate INF**symbolic
	return "NAN" if (!$y_is_numeric_flag && $x eq "INF");

	# return 1 for anything**0, since even if x=0 it is really lim(x->0)
	return 1  if $y_is_numeric_flag && $y == 0;
	# return x for anything**1 (identity)
	return $x if $y_is_numeric_flag && $y == 1;

	# return INF for INF^y if y is positive
	return "INF" if ($x eq "INF" && $y_is_numeric_flag && $y > 0);
	# return 0 for INF^y if y is negative
	return 0 if ($x eq "INF" && $y_is_numeric_flag && $y < 0);

	return 1 if $x_is_numeric_flag && $x == 1;

	return 0     if $y eq "INF" && $x < 1;
	return 0     if $y eq "INF" && $x == 0;
	return "INF" if $y eq "INF" && $x > 1;

	return "INF"  if $y eq "-INF" && $x < 1;
	return "INF"  if $y eq "-INF" && $x == 0;
	return 0      if $y eq "-INF" && $x > 1;

	# return INF for 0**(negative)
	return "INF" if $x_is_numeric_flag && $x == 0 && $y_is_numeric_flag && $y < 0;

	if (!$x_is_numeric_flag || !$y_is_numeric_flag) {
	    $x = "($x)" if !$x_is_numeric_flag && ($x =~ /[+-]|\*|\//) && ($x !~ /^\([^)]*\)$/);  # add paren if any ops in expression
	    $y = "($y)" if !$y_is_numeric_flag && ($y =~ /[+-]|\*|\//) && ($y !~ /^\([^)]*\)$/);  # add paren if any ops in expression
	    return "$x ^ $y";  # matlab notation
	} else {
	    return ($x ** $y);
	}
    }

    #--------------------------------------------------------------------------------------
    # Function: xxx
    # Synopsys: 
    #--------------------------------------------------------------------------------------
    sub xxx {
	my $self = shift;
    }

}


sub run_testcases {
    my $p1_ref = Variable->new({name => "p1"});
    my $p2_ref = Variable->new({name => "p2"});
    my $zero_ref = Variable->new({name => "zero", value => 0});
    my $one_ref = Variable->new({name => "one", value => 1});
    my $inf_ref = Variable->new({name => "inf", value => "INF"});
    my $nan_ref = Variable->new({name => "nan", value => "NAN"});
    my $q1_ref = Variable->new({name => "q1", value => "0.2"});
    my $q2_ref = Variable->new({name => "q2", value => "3.0"});
    my $e1_ref = Variable->new({name => "e1", value => "x + y"});
    my $e2_ref = Variable->new({name => "e2", value => "x - y"});
    my $e3_ref = Variable->new({name => "e3", value => "x * y"});
    my $e4_ref = Variable->new({name => "e4", value => "x / y"});

    my @params = ($p1_ref, $p2_ref, $zero_ref, $one_ref, $inf_ref,
		  $nan_ref, $q1_ref, $q2_ref, $e1_ref, $e2_ref, $e3_ref, $e4_ref);

    for (my $i=0; $i < @params; $i++) {
	for (my $j=0; $j < @params; $j++) {
	    printn $params[$i]->get_name." * ".$params[$j]->get_name." = ".($params[$i] * $params[$j]);
	}
    }

     for (my $i=0; $i < @params; $i++) {
 	for (my $j=0; $j < @params; $j++) {
 	    printn $params[$i]->get_name." / ".$params[$j]->get_name." = ".($params[$i] / $params[$j]);
 	}
     }

    for (my $i=0; $i < @params; $i++) {
	for (my $j=0; $j < @params; $j++) {
	    printn $params[$i]->get_name." + ".$params[$j]->get_name." = ".($params[$i] + $params[$j]);
	}
    }

    for (my $i=0; $i < @params; $i++) {
 	for (my $j=0; $j < @params; $j++) {
 	    printn $params[$i]->get_name." - ".$params[$j]->get_name." = ".($params[$i] - $params[$j]);
 	}
    }

    # add negative phi-values to params
    my $neg_one_ref = Variable->new({name => "neg_one", value => -1});
    my $neg_half_ref = Variable->new({name => "neg_half", value => -0.5});
    my $neg_ten_ref = Variable->new({name => "neg_ten", value => -10});
    my $neg_inf_ref = Variable->new({name => "neg_inf", value => "-INF"});
    my @phi_params = (@params, $neg_one_ref, $neg_half_ref, $neg_ten_ref, $neg_inf_ref);

    for (my $i=0; $i < @params; $i++) {
 	for (my $j=0; $j < @phi_params; $j++) {
 	    printn $params[$i]->get_name." ** ".$phi_params[$j]->get_name." = ".($params[$i] ** $phi_params[$j]);
 	}
    }

#    my $c1 = 10.0;
#    printn "c1 + p1"." = ".($c1 + $p1_ref);
}


# Package BEGIN must return true value
return 1;

