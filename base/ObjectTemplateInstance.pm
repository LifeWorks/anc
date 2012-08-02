######################################################################################
# File:     ObjectTemplateInstance.pm
# Author:   Julien F. Ollivier
#
# Copyright (C) 2005-2010 Julien Ollivier.
#
# This program comes with ABSOLUTELY NO WARRANTY.
# This is free software, and you are welcome to redistribute it
# under certain conditions. See file LICENSE.TXT for details.
#
# Synopsys: Instance of ObjectTemplate
######################################################################################
# Detailed Description:
# ---------------------
#
#
######################################################################################

use strict;
use diagnostics;		# equivalent to -w command-line switch
use warnings;

package ObjectTemplateInstance;
use Class::Std::Storable;
use base qw(SetInstance);
{
    use Carp;

    use Utils;

    #######################################################################################
    # ATTRIBUTES
    #######################################################################################
    my %obj_inst_data_of :ATTR(get => 'obj_inst_data', set => 'obj_inst_data', default => 'value_xxx');

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
    sub BUILD {
#    sub START {
        my ($self, $obj_ID, $arg_ref) = @_;
	
    }

    sub START {
        my ($self, $obj_ID, $arg_ref) = @_;
	
	# check initializers
	# ...
    }

    # just to know when it's called
    sub DEMOLISH {
        my ($self, $obj_ID) = @_;

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

}


# Package BEGIN must return true value
return 1;

