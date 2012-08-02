######################################################################################
# File:     AllostericSite.pm
# Author:   Julien F. Ollivier
#
# Copyright (C) 2005-2010 Julien Ollivier.
#
# This program comes with ABSOLUTELY NO WARRANTY.
# This is free software, and you are welcome to redistribute it
# under certain conditions. See file LICENSE.TXT for details.
#
# Synopsys: An AllostericSite is a ReactionSite which optionally has an
#           allosteric state.
######################################################################################
# Detailed Description:
# ---------------------
######################################################################################

#######################################################################################
# TO-DO LIST
#######################################################################################

use strict;
use diagnostics;		# equivalent to -w command-line switch
use warnings;

package AllostericSite;
use Class::Std::Storable;
use base qw(Node);
{
    use Carp;

    use Utils;

    use Globals;

    use CanBindRule;

    use AllostericSiteInstance;

    #######################################################################################
    # Class Attributes
    #######################################################################################
    AllostericSite->set_class_data("INSTANCE_CLASS", "AllostericSiteInstance");

    ###################################
    # ATTRIBUTES
    ###################################
    my %allosteric_transition_rates_of	:ATTR(get => 'allosteric_transition_rates', set => 'allosteric_transition_rates');
    my %allosteric_state_labels_of      :ATTR(get => 'allosteric_state_labels', set => 'allosteric_state_labels');

    #######################################################################################
    # FUNCTIONS
    #######################################################################################

    #######################################################################################
    # CLASS METHODS
    #######################################################################################

    #######################################################################################
    # INSTANCE METHODS
    #######################################################################################

    sub BUILD {
        my ($self, $obj_ID, $arg_ref) = @_;

	# report creation
	printn "AllostericSite->new(): creating site ".$self->get_name() if $Globals::verbosity >= 2;

	# set Node type attribute
	$self->set_reaction_type('U');

	if (exists $arg_ref->{RT_transition_rate} || exists $arg_ref->{TR_transition_rate}) {
	    printn "ERROR: RT_transition_rate and TR_transition_rate attributes are obsolete, use allosteric_transition_rates instead";
	    exit(1);
	}

	if (defined $arg_ref->{allosteric_transition_rates}) {
	    $allosteric_transition_rates_of{$obj_ID} = $arg_ref->{allosteric_transition_rates};
	} else {
	    $allosteric_transition_rates_of{$obj_ID} = [0.0, 0.0];
	}
	if (defined $arg_ref->{allosteric_state_labels}) {
	    my $labels_ref = $allosteric_state_labels_of{$obj_ID} = $arg_ref->{allosteric_state_labels};
	    if ($labels_ref->[0] ne '.' && ($labels_ref->[0] eq $labels_ref->[1])) {
		my $name = $self->get_name();
		printn "ERROR: allosteric state labels cannot be identical in object $name";
		exit(1);
	    }
	} else {
	    $allosteric_state_labels_of{$obj_ID} = ['R', 'T'];
	}
    }

    sub START {
        my ($self, $obj_ID, $arg_ref) = @_;

	# check initializers
	# ...
    }
}

sub run_testcases {
    printn "NO TESTCASES!!!!";
}

# Package BEGIN must return true value
return 1;

