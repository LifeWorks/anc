######################################################################################
# File:      ReactionSite.pm
# Author:   Julien F. Ollivier
#
# Copyright (C) 2005-2010 Julien Ollivier.
#
# This program comes with ABSOLUTELY NO WARRANTY.
# This is free software, and you are welcome to redistribute it
# under certain conditions. See file LICENSE.TXT for details.
#
# Synopsys:  This class defines the common behaviour of atomic reaction sites
#            within the model.  Behaviours specific to various classes
#            of species within the model should not be contained here, but rather
#            in a separate class specific to that species (e.g. protein reaction
#            site versus a DNA or 2nd messenger site, modulation properties, etc.).
#
#            Various reaction classes require certain methods to be defined
#            in subclasses of this ReactionSite:
#
#                 BindingReaction     can_bind()
#                 CatalyticReaction   can_modify()
#
######################################################################################
# Detailed Description:
# ---------------------
######################################################################################

use strict;
use diagnostics;		# equivalent to -w command-line switch
use warnings;

package ReactionSite;
use Class::Std::Storable;
use base qw(Node);
{
    use Carp;

    use Utils;
    use Globals;

    use ReactionSiteInstance;
    use CanBindRule;

    #######################################################################################
    # CLASS ATTRIBUTES
    #######################################################################################
    ReactionSite->set_class_data("INSTANCE_CLASS", "ReactionSiteInstance");

    #######################################################################################
    # ATTRIBUTES
    #######################################################################################
    my %type_of	                :ATTR(get => 'type', set => 'type', init_arg => 'type');

    ###################################
    # ALLOWED ATTRIBUTE VALUES
    ###################################
    my @allowed_types = ("bsite", "csite", "msite");

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

	# check for obsolete args
	if (exists $arg_ref->{bsite_default_state}) {
	    printn "WARNING: obsolete attribute bsite_default_state in object ".$self->get_name();
	}
	if (exists $arg_ref->{csite_default_state}) {
	    printn "WARNING: obsolete attribute csite_default_state in object ".$self->get_name();
	}
	if (exists $arg_ref->{ms_R}) {
	    printn "WARNING: obsolete attribute ms_R in object ".$self->get_name();
	}
	if (exists $arg_ref->{bs_R}) {
	    printn "WARNING: obsolete attribute bs_R in object ".$self->get_name();
	}
	if (exists $arg_ref->{cs_R}) {
	    printn "WARNING: obsolete attribute cs_R in object ".$self->get_name();
	}

	# report creation
	if ($Globals::verbosity >= 2) {
	    my $class = ref $self;
	    printn "ReactionSite->new(): creating $class ".$self->get_name();
	}

	# set Node reaction_type attribute
	$self->set_reaction_type('B');

    }

    #--------------------------------------------------------------------------------------
    # Function: START
    # Synopsys:
    #--------------------------------------------------------------------------------------
    sub START {
        my ($self, $obj_ID, $arg_ref) = @_;

	# check initializers
	my $class = ref $self;
	my $type = $self->get_type(); croak "Initializer $type not valid for attribute type of in class $class\n" if ((grep /$type/, @allowed_types) != 1);
    }
}


sub run_testcases {
    $verbosity = 3;

    printn "run_testcases: RUNNING REACTIONSITE TESTCASES...";

    my $pd0_ref = ReactionSite->new({
	name => "PD0",
	type => "msite",
    });

    my $I0_ref = $pd0_ref->new_object_instance({});
    my $I1_ref = $pd0_ref->new_object_instance({});

    print "I0 is_self_binding -> ".$I0_ref->is_self_binding()."\n";
    my $rule1_ref = CanBindRule->new({
	name => "R1", 
	ligand_names => ['PD0', 'PD0'],
	kf => 8.0,
	kb => 2.0,
    });
    $rule1_ref->compile(ligand_classes => ["ReactionSite"]);
    print "I0 is_self_binding -> ".$I0_ref->is_self_binding()."\n";

    $I1_ref->set_msite_state("1");
    my $I0_state = $I0_ref->get_msite_state();
    my $I1_state = $I1_ref->get_msite_state();
    print "I0 state is $I0_state\n";
    print "I1 state is $I1_state\n";

    printn "PD0 = ".$pd0_ref->_DUMP();
    printn "I0 = ".$I0_ref->_DUMP();
    printn "I1 = ".$I1_ref->_DUMP();

    $verbosity = 2; # prevent DEMOLISH messages
}


# Package BEGIN must return true value
return 1;

