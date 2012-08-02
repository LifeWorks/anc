######################################################################################
# File:     Selector.pm
# Author:   Julien F. Ollivier
#
# Copyright (C) 2005-2010 Julien Ollivier.
#
# This program comes with ABSOLUTELY NO WARRANTY.
# This is free software, and you are welcome to redistribute it
# under certain conditions. See file LICENSE.TXT for details.
#
# Synopsys: Select an individual StructureInstance based on its state.  The reference
#           state is used if no state is specified.
######################################################################################
# Detailed Description:
# ---------------------
# As long as the user specifies a structure (name), the START() method will initialize
# the appropriate filters to find a structure of the specified state (or the first
# instance if no state is specified.
######################################################################################

use strict;
use diagnostics;		# equivalent to -w command-line switch
use warnings;

package Selector;
use Class::Std::Storable;
use base qw(Filter);
{
    use Carp;
    use Utils;

    #######################################################################################
    # CLASS ATTRIBUTES
    #######################################################################################
    Selector->set_class_data("AUTONAME", "Slt");

    #######################################################################################
    # ATTRIBUTES
    #######################################################################################
    my %structure_of :ATTR(get => 'structure', set => 'structure');
    my %state_of :ATTR(get => 'state', set => 'state');

    #######################################################################################
    # FUNCTIONS
    #######################################################################################

    #######################################################################################
    # CLASS METHODS
    #######################################################################################

    #######################################################################################
    # INSTANCE METHODS
    #######################################################################################
    #--------------------------------------------------------------------------------------
    # Function: BUILD
    # Synopsys: 
    #--------------------------------------------------------------------------------------
    sub BUILD {
        my ($self, $obj_ID, $arg_ref) = @_;

	$structure_of{$obj_ID} = $arg_ref->{structure} if exists $arg_ref->{structure};
	$state_of{$obj_ID} = $arg_ref->{state} if exists $arg_ref->{state};

	$self->set_classes('ComplexInstance') if !defined $self->get_classes();
	$self->set_filters([]) if !defined $self->get_filters();
    }

    #--------------------------------------------------------------------------------------
    # Function: START
    # Synopsys: 
    #--------------------------------------------------------------------------------------
    sub START {
        my ($self, $obj_ID, $arg_ref) = @_;

	$self->set_classes('ComplexInstance') if !defined $self->get_classes();

	if (defined $self->get_structure) {
	    my $state  = $self->get_state();
	    my $filters_ref = $self->get_filters();
	    push @{$filters_ref}, '$_->get_parent_ref()->get_name() eq $self->get_structure()';

	    if (defined $state) {
		# user has specified state
		if (ref $state) {
		    my $class = ref $self;
		    my $name = $self->get_name();
		    printn "ERROR: $class $name state attribute must be a string (enclose in quotes)";
		    exit(1);
		}

		# strip whitespace out of state specification
		$state =~ s/\s+//g;
		# since user specifies state of structure, but we scan ComplexInstances,
		# need to add extra level in state spec.
		$state = "[,$state]";
		# save
		$self->set_state($state);

		push @{$filters_ref}, '$_->match_state($self->get_state()) == 1';
	    } else {
		# user has not specified state, so use first instance
		push @{$filters_ref}, 'ident($_) == ident($_->get_parent_ref()->get_object_instance_by_index(0))'
	    }
	}
    }

    #--------------------------------------------------------------------------------------
    # Function: get_selected_ref
    # Synopsys: 
    #--------------------------------------------------------------------------------------
    sub get_selected_ref {
	my $self = shift;

	my $instances_ref = $self->get_instances_ref();
	return (defined $instances_ref) && @$instances_ref ? $instances_ref->[0] : undef;
    }

    #--------------------------------------------------------------------------------------
    # Function: get_toplvl_selected_ref
    # Synopsys: 
    #--------------------------------------------------------------------------------------
    sub get_toplvl_selected_ref {
	my $self = shift;


	my $toplvl_instances_ref = $self->get_toplvl_instances_ref();
	return (defined $toplvl_instances_ref) && @$toplvl_instances_ref ? $toplvl_instances_ref->[0] : undef;
    }

}


sub run_testcases {

    my $ref = Selector->new({
	structure => 'X',
	state => '[0,1,1]',
    });

    printn $ref->_DUMP();
}


# Package BEGIN must return true value
return 1;

