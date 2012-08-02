######################################################################################
# File:     Null.pm
# Author:   Julien F. Ollivier
#
# Copyright (C) 2005-2010 Julien Ollivier.
#
# This program comes with ABSOLUTELY NO WARRANTY.
# This is free software, and you are welcome to redistribute it
# under certain conditions. See file LICENSE.TXT for details.
#
# Synopsys: An empty, instantiable object.
######################################################################################
# Detailed Description:
# ---------------------
######################################################################################

use strict;
use diagnostics;		# equivalent to -w command-line switch
use warnings;

package Null;
use Class::Std::Storable;
use base qw(Instantiable);
{
    use Carp;

    use Utils;

    #######################################################################################
    # CLASS ATTRIBUTES
    #######################################################################################
    Null->set_class_data("INSTANCE_CLASS", "Instance");

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
    # Function: xxx
    # Synopsys: 
    #--------------------------------------------------------------------------------------
    sub xxx {
	my $self = shift;
    }
}


sub run_testcases {
    use Globals;
    $verbosity = 3;

    printn "run_testcases: Null package";
    my $null_ref = Null->new({
	name => "NULL1",
       });

    printn $null_ref->_DUMP();
}


# Package BEGIN must return true value
return 1;

