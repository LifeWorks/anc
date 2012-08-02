######################################################################################
# File:     AllostericStructureInstance.pm
# Author:   Julien F. Ollivier
# Copyright (c) 2005-2009. All rights reserved.
#
# Synopsys: Instance of AllostericStructure
######################################################################################
# Detailed Description:
# ---------------------
######################################################################################

use strict;
use diagnostics;		# equivalent to -w command-line switch
use warnings;

package AllostericStructureInstance;
use Class::Std::Storable;
use base qw(StructureInstance);
{
    use Carp;

    use Utils;

    #######################################################################################
    # CLASS ATTRIBUTES
    #######################################################################################
    AllostericStructureInstance->set_class_data("ELEMENT_CLASS", "StructureInstance,AllostericStructureInstance,ReactionSiteInstance,AllostericSiteInstance,NodeInstance");

    #######################################################################################
    # ATTRIBUTES
    #######################################################################################

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
    # Function: get_allosteric_state
    # Synopsys: Get the allosteric state from the group node.
    #--------------------------------------------------------------------------------------
    sub get_allosteric_state {
	my $self = shift;

	if ($self->get_parent_ref()->get_allosteric_flag()) {
	    return $self->get_group_node_ref()->get_allosteric_state();
	} else {
	    return undef;
	}
    }

    #--------------------------------------------------------------------------------------
    # Function: get_allosteric_label
    # Synopsys: Get the allosteric label from the group node.
    #--------------------------------------------------------------------------------------
    sub get_allosteric_label {
	my $self = shift;

	if ($self->get_parent_ref()->get_allosteric_flag()) {
	    return $self->get_group_node_ref()->get_allosteric_label();
	} else {
	    return undef;
	}
    }

#    #--------------------------------------------------------------------------------------
#    # Function: xxx
#    # Synopsys: 
#    #--------------------------------------------------------------------------------------
#    sub xxx {
#	my $self = shift;
#    }
}


sub run_testcases {

}


# Package BEGIN must return true value
return 1;

