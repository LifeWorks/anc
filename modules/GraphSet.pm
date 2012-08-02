######################################################################################
# File:     GraphSet.pm
# Author:   Julien F. Ollivier
#
# Copyright (C) 2005-2010 Julien Ollivier.
#
# This program comes with ABSOLUTELY NO WARRANTY.
# This is free software, and you are welcome to redistribute it
# under certain conditions. See file LICENSE.TXT for details.
#
# Synopsys: The main purpose of this class is to create a node in Graph for
#           each element of the Set at initialization.
######################################################################################
# Detailed Description:
# ---------------------
######################################################################################

use strict;
use diagnostics;		# equivalent to -w command-line switch
use warnings;

package GraphSet;
use Class::Std::Storable;
use base qw(Graph Set);
{
    use Carp;
    use Utils;

    #######################################################################################
    # CLASS ATTRIBUTES
    #######################################################################################

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
}


sub run_testcases {
    printn "NO TESTCASES!!!!";
}


# Package BEGIN must return true value
return 1;

