######################################################################################
# File:     BinaryReaction.pm
# Author:   Julien F. Ollivier
#
# Copyright (C) 2005-2010 Julien Ollivier.
#
# This program comes with ABSOLUTELY NO WARRANTY.
# This is free software, and you are welcome to redistribute it
# under certain conditions. See file LICENSE.TXT for details.
#
# Synopsys: A BinaryReaction involves two substrate ReactionSites.  These
#           may or may not be on the same species (i.e. internal, 1st order versus
#           2nd order, external reactions).
#
#
######################################################################################
# Detailed Description:
# ---------------------
######################################################################################

use strict;
use diagnostics;		# equivalent to -w command-line switch
use warnings;

package BinaryReaction;
use Class::Std::Storable;
use base qw(Reaction);
{
    use Carp;
    use Utils;

    use Globals;

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
    #--------------------------------------------------------------------------------------
    # Function: compute_unique_reaction_name
    # Synopsys: Uniquely identify a component elementary reaction given its substrates.
    #--------------------------------------------------------------------------------------
    sub compute_unique_reaction_name {
	my $class = shift;
	my %args = (
	    internal_flag => undef,
#	    L_info_ref => undef,
#	    R_info_ref => undef,
	    L_name => undef,
	    L_address_ref => undef,
	    R_name => undef,
	    R_address_ref => undef,
	    @_,
	   );
	check_args(\%args, 5) if $debug;  # very expensive -- gets called many times
	
	my $internal_flag = $args{internal_flag};

#	my $L_info_ref = $args{L_info_ref};
	my $L_address_ref = $args{L_address_ref};
	my $L_name = $args{L_name};
#	my $R_info_ref = $args{R_info_ref};
	my $R_address_ref = $args{R_address_ref};
	my $R_name = $args{R_name};

	my $unique_name = (($internal_flag) ?
			   "$L_name(".join(",", sort("@$L_address_ref","@$R_address_ref")).")" :
			   (($L_name eq $R_name) ? # same ligand?
			    "$L_name(@$L_address_ref),$R_name(@$R_address_ref)" :  # no sort: X(0)+X(1) is distinct from X(1)+X(0)
			    join(",", sort("$L_name(@$L_address_ref)","$R_name(@$R_address_ref)")))
			  );
	return $unique_name;
    }

    #######################################################################################
    # INSTANCE METHODS
    #######################################################################################
#     #--------------------------------------------------------------------------------------
#     # Function: xxx
#     # Synopsys: 
#     #--------------------------------------------------------------------------------------
#     sub xxx {
# 	my $self = shift;
#     }

}


sub run_testcases {
    printn "NO TESTCASES!!!";
}


# Package BEGIN must return true value
return 1;

