######################################################################################
# File:     CanBindRuleInstance.pm
# Author:   Julien F. Ollivier
#
# Copyright (C) 2005-2010 Julien Ollivier.
#
# This program comes with ABSOLUTELY NO WARRANTY.
# This is free software, and you are welcome to redistribute it
# under certain conditions. See file LICENSE.TXT for details.
#
# Synopsys: Instance of CanBindRule
######################################################################################
# Detailed Description:
# ---------------------
######################################################################################

use strict;
use diagnostics;		# equivalent to -w command-line switch
use warnings;

package CanBindRuleInstance;
use Class::Std::Storable;
use base qw(BinaryRuleInstance);
{
    use Carp;

    use Utils;

    #######################################################################################
    # Attributes
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
    # Function: get_ligand_msite_states
    # Synopsys: Get attribute value from parent and swap order if commuted.
    #--------------------------------------------------------------------------------------
    sub get_ligand_msite_states {
	my $self = shift;

	my $ligand_msite_states_ref = $self->get_parent_ref()->get_ligand_msite_states();

	if ($self->get_commuted_flag()) {
	    return [$ligand_msite_states_ref->[1], $ligand_msite_states_ref->[0]];
	} else {
	    return [$ligand_msite_states_ref->[0], $ligand_msite_states_ref->[1]];
	}
    }

    #--------------------------------------------------------------------------------------
    # Function: get_ligand_allosteric_labels
    # Synopsys: Get attribute value from parent and swap order if commuted.
    #--------------------------------------------------------------------------------------
    sub get_ligand_allosteric_labels {
	my $self = shift;

	my $ligand_allosteric_labels_ref = $self->get_parent_ref()->get_ligand_allosteric_labels();

	if ($self->get_commuted_flag()) {
	    return [$ligand_allosteric_labels_ref->[1], $ligand_allosteric_labels_ref->[0]];
	} else {
	    return [$ligand_allosteric_labels_ref->[0], $ligand_allosteric_labels_ref->[1]];
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
    printn "NO TESTCASES!!!";
}


# Package BEGIN must return true value
return 1;

