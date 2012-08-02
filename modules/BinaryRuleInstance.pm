######################################################################################
# File:     BinaryRuleInstance.pm
# Author:   Julien F. Ollivier
#
# Copyright (C) 2005-2010 Julien Ollivier.
#
# This program comes with ABSOLUTELY NO WARRANTY.
# This is free software, and you are welcome to redistribute it
# under certain conditions. See file LICENSE.TXT for details.
#
# Synopsys: Instance of BinaryRule
######################################################################################
# Detailed Description:
# ---------------------
######################################################################################

use strict;
use diagnostics;		# equivalent to -w command-line switch
use warnings;

package BinaryRuleInstance;
use Class::Std::Storable;
use base qw(Instance);
{
    use Carp;

    use Utils;

    #######################################################################################
    # Attributes
    #######################################################################################
    my %commuted_flag_of :ATTR(get => 'commuted_flag', set => 'commuted_flag', init_arg => 'commuted_flag');

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
    # Function: get_ligand_names
    # Synopsys: Get attribute value from parent and swap order if commuted.
    #--------------------------------------------------------------------------------------
    sub get_ligand_names {
	my $self = shift;

	my $ligand_names_ref = $self->get_ligand_names();

	if ($self->get_commuted_flag()) {
	    return [$ligand_names_ref->[1], $ligand_names_ref->[0]];
	} else {
	    return [$ligand_names_ref->[0], $ligand_names_ref->[1]];
	}
    }
}


sub run_testcases {

}


# Package BEGIN must return true value
return 1;

