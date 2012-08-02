######################################################################################
# File:     Rule.pm
# Author:   Julien F. Ollivier
#
# Copyright (C) 2005-2010 Julien Ollivier.
#
# This program comes with ABSOLUTELY NO WARRANTY.
# This is free software, and you are welcome to redistribute it
# under certain conditions. See file LICENSE.TXT for details.
#
# Synopsys: Base class for CanBindRule and CanModifyRule.
######################################################################################
# Detailed Description:
# ---------------------
######################################################################################

use strict;
use diagnostics;		# equivalent to -w command-line switch
use warnings;

package Rule;
use Class::Std::Storable;
use base qw(Registered);
{
    use Carp;
    use Utils;

    #######################################################################################
    # CLASS ATTRIBUTES
    #######################################################################################
    Rule->set_class_data("LOOKUP_TABLE", {});

    #######################################################################################
    # ATTRIBUTES
    #######################################################################################

    #######################################################################################
    # FUNCTIONS
    #######################################################################################

    #######################################################################################
    # CLASS METHODS
    #######################################################################################

    #--------------------------------------------------------------------------------------
    # Function: report_lookup_table
    # Synopsys: Dump the compiled lookup table for given class.
    #--------------------------------------------------------------------------------------
    sub report_lookup_table {
	my $class = shift;

	my $lookup_table_ref = $class->get_class_data("LOOKUP_TABLE");

	use Data::Dumper;

	printn Dumper($lookup_table_ref);
    }


#    #--------------------------------------------------------------------------------------
#    # Function: XXX
#    # Synopsys: 
#    #--------------------------------------------------------------------------------------
#    sub XXX {
#	my $class = shift;
#    }

    #######################################################################################
    # INSTANCE METHODS
    #######################################################################################
    #--------------------------------------------------------------------------------------
    # Function: START
    # Synopsys: 
    #--------------------------------------------------------------------------------------
#    sub BUILD {
#    sub START {
#        my ($self, $obj_ID, $arg_ref) = @_;

#	# check initializers
#	# ...
#    }

    #--------------------------------------------------------------------------------------
    # Function: compile
    # Synopsys: Stub for compile() method which must be supplied by derived classes.
    #--------------------------------------------------------------------------------------
    sub compile {
	my $self = shift;

	croak "ERROR:  internal error -- a derived class must supply a compile() method";
    }


}


sub run_testcases {

    printn "NO TESTCASES!!!";
}


# Package BEGIN must return true value
return 1;

