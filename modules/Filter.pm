######################################################################################
# File:     Filter.pm
# Author:   Julien F. Ollivier
#
# Copyright (C) 2005-2010 Julien Ollivier.
#
# This program comes with ABSOLUTELY NO WARRANTY.
# This is free software, and you are welcome to redistribute it
# under certain conditions. See file LICENSE.TXT for details.
#
# Synopsys: Filter objects in given class(es) based on a list of criteria.
######################################################################################
# Detailed Description:
# ---------------------
######################################################################################

use strict;
use diagnostics;		# equivalent to -w command-line switch
use warnings;

package Filter;
use Class::Std::Storable;
use base qw(Registered);
{
    use Carp;
    use Utils;

    use Globals;

    #######################################################################################
    # CLASS ATTRIBUTES
    #######################################################################################
    Filter->set_class_data("AUTONAME", "Flt");

    #######################################################################################
    # ATTRIBUTES
    #######################################################################################
    # filter inputs
    my %classes_of :ATTR(get => 'classes', set => 'classes');
    my %filters_of :ATTR(get => 'filters', set => 'filters',);

    # filter results
    my %instances_ref_of :ATTR(get => 'instances_ref', set => 'instances_ref');
    my %toplvl_instances_ref_of :ATTR(get => 'toplvl_instances_ref', set => 'toplvl_instances_ref');

    #######################################################################################
    # FUNCTIONS
    #######################################################################################

    #######################################################################################
    # CLASS METHODS
    #######################################################################################
    #--------------------------------------------------------------------------------------
    # Function: XXX
    # Synopsys: 
    #--------------------------------------------------------------------------------------
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

	# this allows derived classes to supply initialization in BUILD()
	$classes_of{$obj_ID} = $arg_ref->{classes} if exists $arg_ref->{classes};
	$filters_of{$obj_ID} = $arg_ref->{filters} if exists $arg_ref->{filters};
    }

    #--------------------------------------------------------------------------------------
    # Function: START
    # Synopsys: 
    #--------------------------------------------------------------------------------------
    sub START {
        my ($self, $obj_ID, $arg_ref) = @_;

	my $name = $self->get_name();
	my $class = ref $self;
	croak "ERROR: classes attribute not defined for $class object ".$self->get_name() if !defined $classes_of{$obj_ID};
	croak "ERROR: filters attribute not defined for $class object ".$self->get_name() if !defined $filters_of{$obj_ID};
    }

    #--------------------------------------------------------------------------------------
    # Function: filter
    # Synopsys: Filter instances given in argument list with filter criteria.  Also find
    #           unique top-lvl set for each instance.
    #--------------------------------------------------------------------------------------
    sub filter {
	my $self = shift;
	my $obj_ID = ident $self;
	my @instances = @_;

	my @filters = @{$filters_of{$obj_ID}};
	foreach my $filter (@filters) {
	    my $eval_str = "grep ($filter, \@instances)";
	    no warnings; @instances = eval $eval_str; use warnings;
	    if ($@) {
		print "ERROR: something wrong with filter expression\nFILTER:\n$eval_str\nMESSAGE:\n$@";
		exit(1);
	    }
	}

	my @toplvl_instances = map {$_->isa('SetElement') ? $_->get_in_toplvl_set() : $_} @instances;

	return (\@instances, \@toplvl_instances);
    }

    #--------------------------------------------------------------------------------------
    # Function: compile
    # Synopsys: Get all instances in class and use filter() to fill instance lists
    #           with instances matching filter criteria.
    #--------------------------------------------------------------------------------------
    sub compile {
	my $self = shift;

	if (!ref $self) {  # class method?
	    my $class = $self;
	    map {$_->compile()} $class->get_instances();
	} else {           # instance method
	    my $obj_ID = ident $self;
	    my $classes = $self->get_classes();
	    my @instances = map {$_->get_instances()} split(",",$classes);
	    my ($instances_ref, $toplvl_instances_ref) = $self->filter(@instances);
	    if (!@$instances_ref) {
		my $class = ref $self;
		printn "WARNING: failed to find objects matching criteria for $class ".$self->get_name();
	    }
	    $instances_ref_of{$obj_ID} = $instances_ref;
	    $toplvl_instances_ref_of{$obj_ID} = $toplvl_instances_ref;
	}
    }

    #--------------------------------------------------------------------------------------
    # Function: report
    # Synopsys: Report result of filter compilation.
    #--------------------------------------------------------------------------------------
    sub report {
	my $self = shift; my $obj_ID = ident $self;
	my $toplvl_flag = 0 || shift;

	if (!ref $self) {  # class method?
	    my $class = $self;
	    map {$_->report($toplvl_flag)} $class->get_instances();
	} else {           # instance method
	    my $obj_ID = ident $self;
	    my $class = ref $self;

	    my $instances_ref = $toplvl_flag ? $toplvl_instances_ref_of{$obj_ID} : $instances_ref_of{$obj_ID} || [];

	    my $name = $self->get_name();
	    my $num_instances = scalar @$instances_ref;
	    printn "$class $name comprises $num_instances objects:";
	    foreach my $instance_ref (@$instances_ref) {
		printn "\t".$instance_ref->get_exported_name() if $verbosity >= 1;
	    }
	    printn "(none)" if !@$instances_ref;
	}
    }

    #--------------------------------------------------------------------------------------
    # Function: get_exported_name
    # Synopsys: Strip out nasty chars.
    #--------------------------------------------------------------------------------------
    sub get_exported_name {
	my $self = shift;
	my $name = $self->get_name();
	$name =~ s/[!]/_/g;
	return $name;
    }
}


sub run_testcases {
    printn "NO TESTCASES!!!!";
}


# Package BEGIN must return true value
return 1;

