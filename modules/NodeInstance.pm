######################################################################################
# File:     NodeInstance.pm
# Author:   Julien F. Ollivier
#
# Copyright (C) 2005-2010 Julien Ollivier.
#
# This program comes with ABSOLUTELY NO WARRANTY.
# This is free software, and you are welcome to redistribute it
# under certain conditions. See file LICENSE.TXT for details.
#
# Synopsys: Instance of Node
######################################################################################
# Detailed Description:
# ---------------------
######################################################################################

use strict;
use diagnostics;		# equivalent to -w command-line switch
use warnings;

package NodeInstance;
use Class::Std::Storable;
use base qw(ComponentInstance SetElement);
{
    use Carp;

    use Utils;

    #######################################################################################
    # ATTRIBUTES
    #######################################################################################
#    my %obj_inst_data_of :ATTR(get => 'obj_inst_data', set => 'obj_inst_data', default => 'value_xxx');

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
    # Function: START
    # Synopsys: 
    #--------------------------------------------------------------------------------------
#    sub BUILD {
##    sub START {
#        my ($self, $obj_ID, $arg_ref) = @_;
	
#    }

    #--------------------------------------------------------------------------------------
    # Function: get_right_node
    # Synopsys: 
    #--------------------------------------------------------------------------------------
    sub get_right_node {
	my $self = shift;

	my $index = $self->get_in_set_index();
	my $upper_ref = $self->get_in_object();
	my $right_index = $index+1;
	croak "ERROR: get_right_node -- index too large" if $right_index > $upper_ref->get_last_element_index();
	return $upper_ref->get_element($right_index);
    }
    #--------------------------------------------------------------------------------------
    # Function: get_left_node
    # Synopsys: 
    #--------------------------------------------------------------------------------------
    sub get_left_node {
	my $self = shift;

	my $index = $self->get_in_set_index();
	my $upper_ref = $self->get_in_object();
	my $left_index = $index - 1;
	croak "ERROR: get_left_node -- negative index" if $left_index < 0;
	return $upper_ref->get_element($left_index);
    }

    #--------------------------------------------------------------------------------------
    # Function: sprint_state
    # Synopsys: 
    #--------------------------------------------------------------------------------------
    sub sprint_state {
	return "";
    }

    #--------------------------------------------------------------------------------------
    # Function: clone_state
    # Synopsys: Dummy function.
    #--------------------------------------------------------------------------------------
    sub clone_state { }

    #--------------------------------------------------------------------------------------
    # Function: set_msite_state
    # Synopsys: Dummy function to allow wildcard setting of msite_state.
    #--------------------------------------------------------------------------------------
    sub set_msite_state { }

    #--------------------------------------------------------------------------------------
    # Function: get_csite_bound_to_msite_flag
    # Synopsys: Dummy function to allow ComplexInstance::get_catalytic_activity_number()
    #           function to work.
    #--------------------------------------------------------------------------------------
    sub get_csite_bound_to_msite_flag {return 0;}

    #--------------------------------------------------------------------------------------
    # Function: set_allosteric_state
    # Synopsys: Dummy function to allow wildcard setting of allosteric_state.
    #--------------------------------------------------------------------------------------
    sub set_allosteric_state { }

    #--------------------------------------------------------------------------------------
    # Function: xxx
    # Synopsys: 
    #--------------------------------------------------------------------------------------
#    sub xxx {
#	my $self = shift;
#    }
}


sub run_testcases {
    printn "NO TESTCASES!!!";
}


# Package BEGIN must return true value
return 1;

