######################################################################################
# File:     Species.pm
# Author:   Julien F. Ollivier
#
# Copyright (C) 2005-2010 Julien Ollivier.
#
# This program comes with ABSOLUTELY NO WARRANTY.
# This is free software, and you are welcome to redistribute it
# under certain conditions. See file LICENSE.TXT for details.
#
# Synopsys: Provide IC and is_new_flag attributes to ComplexInstance class.
#
######################################################################################
# Detailed Description:
# ---------------------
#
######################################################################################

use strict;
use diagnostics;		# equivalent to -w command-line switch
use warnings;

package Species;
use Class::Std;
use base qw(Registered);
{
    use Carp;
    use Utils;

    use SiteInfo;

    #######################################################################################
    # CLASS ATTRIBUTES
    #######################################################################################

    #######################################################################################
    # ATTRIBUTES
    #######################################################################################
    # this attribute is used by ReactionNetwork class to keep track of which species
    # are newly generated during the compilation process
    my %is_new_flag_of :ATTR(get => 'is_new_flag', set => 'is_new_flag', default => 1);

    # this is the initial concentration of the species
    my %IC_of :ATTR(get => 'IC', set => 'IC');

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

	$IC_of{$obj_ID} = $arg_ref->{IC} if exists $arg_ref->{IC};
    }
}


sub run_testcases {
    printn "NO TESTCASES!!!!";
}


# Package BEGIN must return true value
return 1;

