######################################################################################
# File:     HiGraphInstance.pm
# Author:   Julien F. Ollivier
#
# Copyright (C) 2005-2010 Julien Ollivier.
#
# This program comes with ABSOLUTELY NO WARRANTY.
# This is free software, and you are welcome to redistribute it
# under certain conditions. See file LICENSE.TXT for details.
#
# Synopsys: Instance of HiGraph
######################################################################################
# Detailed Description:
# ---------------------
######################################################################################

use strict;
use diagnostics;		# equivalent to -w command-line switch
use warnings;

package HiGraphInstance;
use Class::Std::Storable;
use base qw(HiGraph GraphInstance);
{
    use Carp;

    use Utils;
    use Globals;

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
    # Function: BUILD
    # Synopsys: 
    #--------------------------------------------------------------------------------------
    sub BUILD {
        my ($self, $obj_ID, $arg_ref) = @_;

	# default value of ungroup flag is based on parent's
	$self->set_ungroup_flag($self->get_parent_ref()->get_ungroup_flag());
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
    printn "NO TESTCASES!!!!";
}


# Package BEGIN must return true value
return 1;

