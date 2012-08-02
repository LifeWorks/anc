######################################################################################
# File:     SiteInfo class
# Author:   Julien F. Ollivier
#
# Copyright (C) 2005-2010 Julien Ollivier.
#
# This program comes with ABSOLUTELY NO WARRANTY.
# This is free software, and you are welcome to redistribute it
# under certain conditions. See file LICENSE.TXT for details.
#
# Synopsys: This object encapsulates information about a ReactionSite in the context
#           of a containing Species.  It contains a weak reference to the containing
#           Species and the address of the reaction site within said species.
######################################################################################
# Detailed Description:
# ---------------------
######################################################################################

use strict;
use diagnostics;		# equivalent to -w command-line switch
use warnings;

package SiteInfo;
use Class::Std::Storable;
use base qw();
{
    use Carp;
    use WeakRef;

    use Utils;

    #######################################################################################
    # CLASS ATTRIBUTES
    #######################################################################################

    #######################################################################################
    # ATTRIBUTES
    #######################################################################################
    my %species_ref_of   :ATTR(get => 'species_ref', set => 'species_ref', init_arg => 'species_ref');
    my %site_address_ref_of  :ATTR(get => 'site_address_ref', set => 'site_address_ref', init_arg => 'site_address_ref');
    my %site_ref_of      :ATTR(get => 'site_ref', set => 'site_ref', init_arg => 'site_ref');

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
    sub START {
        my ($self, $obj_ID, $arg_ref) = @_;

	# check and process initializers
	croak "ERROR: species must be of the Species class" if (!$species_ref_of{$obj_ID}->isa("Species"));
	weaken($species_ref_of{ident $self});
	
	croak "ERROR: site_address must be an array reference" if (ref $site_address_ref_of{$obj_ID} ne "ARRAY");

	if (!($site_ref_of{$obj_ID}->isa('Node') || $site_ref_of{$obj_ID}->isa('NodeInstance'))) {
	    my $site_ref_class = ref $site_ref_of{$obj_ID};
	    croak "ERROR: site_ref (class $site_ref_class) must be derived from Node/NodeInstance class";
	}
	
	# ...
	# !!! may want to create a class that site_ref must be member of, for checking purposes ???
   }

    #--------------------------------------------------------------------------------------
    # Function: xxx
    # Synopsys: 
    #--------------------------------------------------------------------------------------
#    sub xxx {
#	my $self = shift;
#    }

}


sub run_testcases {
    printn "No testcases....";
}


# Package BEGIN must return true value
return 1;

