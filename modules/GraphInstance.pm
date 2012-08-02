######################################################################################
# File:     GraphInstance.pm    (!!!  change name to RegisteredGraphInstance???)
# Author:   Julien F. Ollivier
#
# Copyright (C) 2005-2010 Julien Ollivier.
#
# This program comes with ABSOLUTELY NO WARRANTY.
# This is free software, and you are welcome to redistribute it
# under certain conditions. See file LICENSE.TXT for details.
#
# Synopsys: Object instance graph.  Each object instance has a state therefore
#           two object instances are not necessarily isomorphic even though their
#           parent objects are.  Hence we need to encode the element states in the
#           node colours of each instance Graph.
######################################################################################
# Detailed Description:
# ---------------------
######################################################################################

use strict;
use diagnostics;		# equivalent to -w command-line switch
use warnings;

package GraphInstance;
use Class::Std::Storable;
use base qw(RegisteredGraph Instance);
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

#    #--------------------------------------------------------------------------------------
#    # Function: xxx
#    # Synopsys: 
#    #--------------------------------------------------------------------------------------
#    sub xxx {
#	my $self = shift;
#    }

}


sub run_testcases {
    printn "run_testcases: GraphInstance package";

    printn "NEED TO ADD TESTCASES!!!";
}


# Package BEGIN must return true value
return 1;

