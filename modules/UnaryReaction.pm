#-#####################################################################################
# File:     UnaryReaction.pm
# Author:   Julien F. Ollivier
#
# Copyright (C) 2005-2010 Julien Ollivier.
#
# This program comes with ABSOLUTELY NO WARRANTY.
# This is free software, and you are welcome to redistribute it
# under certain conditions. See file LICENSE.TXT for details.
#
# Synopsys: A UnaryReaction involves one substrate ReactionSite and produces
#           a modified substrate whose ReactionSite has a different state.  The
#           reaction is reversible and therefore consists of two ElementaryReactions.
######################################################################################
# Detailed Description:
# ---------------------
# The substrate class must be derived from ComplexInstance and provide the following methods:
#     compute_modified_substrate()
#     compute_unary_reaction_forward_rate()
#     compute_unary_reaction_backward_rate()
#     can_change_state()   (in ComplexInstance derived class)
#     can_change_state()   (in ReactionSite derived class)
#
# Convention for naming of Species participating in UnaryReactions:
#  i) reaction naming convention
#        S <-> P
#
######################################################################################

use strict;
use diagnostics;		# equivalent to -w command-line switch
use warnings;

package UnaryReaction;
use Class::Std::Storable;
use base qw(Reaction);
{
    use Carp;

    use Utils;
    use Globals;

    #######################################################################################
    # ATTRIBUTES
    #######################################################################################
    my %S_info_ref_of :ATTR(get => "S_info_ref", init_arg => "S_info_ref", );
    my %P_info_ref_of :ATTR(get => "P_info_ref");

    my %forward_reaction_of :ATTR(get => 'forward_reaction');   # reactants are pre-association ligands
    my %backward_reaction_of :ATTR(get => 'backward_reaction'); # reactant is post-association complex

    my %is_duplicate_forward_reaction_flag_of :ATTR(get => "is_duplicate_forward_reaction_flag", set => "is_duplicate_forward_reaction_flag", default => 0);
    my %is_duplicate_backward_reaction_flag_of :ATTR(get => "is_duplicate_backward_reaction_flag", set => "is_duplicate_backward_reactiony_flag", default => 0);

    #######################################################################################
    # FUNCTIONS
    #######################################################################################

    #######################################################################################
    # CLASS METHODS
    #######################################################################################
    #--------------------------------------------------------------------------------------
    # Function: NEW
    # Synopsys: A wrapper for new() that performs the following:
    #--------------------------------------------------------------------------------------
    sub NEW {
	my $class = shift;
	my $arg_ref = shift;

	# GET AND CHECK ARGUMENTS
	my $S_info_ref = $arg_ref->{S_info_ref};

	croak "ERROR: missing argument S_info_ref" if (!defined $S_info_ref);
	croak "ERROR: S_info_ref must inherit from SiteInfo class" if (!$S_info_ref->isa("SiteInfo"));

	my $S_species_ref = $S_info_ref->get_species_ref();
	my $S_address_ref = $S_info_ref->get_site_address_ref();
	my $S_name = $S_species_ref->get_name();

	# GENERATE A NAME FOR THE ELEMENTARY REACTION SPECIFIED BY ARGUMENTS
	my $elementary_reaction_name = "$S_name(@$S_address_ref)";

	printn "${class}::NEW -- called for reaction $elementary_reaction_name" if ($verbosity >= 2);

	# CHECK IF WE HAVE ALREADY ATTEMPTED TO COMPUTE THIS EXACT REACTION
	if (defined ElementaryReaction->lookup_by_name("UR $elementary_reaction_name")) {
	    printn "${class}::NEW -- already computed elementary reaction $elementary_reaction_name" if ($verbosity >= 2);
	    return undef;
	}

	# figure out whether a UnaryReaction is possible
	my $can_change_state_flag = UnaryReaction->can_change_state(
	    S_info_ref => $S_info_ref,
	   );

	# if this is not the case, return
	if (!$can_change_state_flag) {
	    printn "${class}::NEW -- can't change state" if ($verbosity >= 2);
	    return undef;
	} else {
	    return $class->new({
		%$arg_ref,
		name => uniquify($arg_ref->{name}),
	    });
	}
    }

    #--------------------------------------------------------------------------------------
    # Function: can_change_state
    # Synopsys: 
    #--------------------------------------------------------------------------------------
    sub can_change_state {
	my $class = shift;
	my %args = (
	    S_info_ref => undef,
	    @_,
	   );

	check_args(\%args, 1);

	my $S_info_ref = $args{S_info_ref};

	#-------------------------------------------------------------------------------
	# Call the NodeInstance's can_change_state() class method which will determine
	# whether the site can change state.
	#-------------------------------------------------------------------------------
	my $S_site_ref = $S_info_ref->get_site_ref();
	my $site_class = ref $S_site_ref;
	my $site_can_change_state_flag = $site_class->can_change_state($S_site_ref);

	return 0 if (!$site_can_change_state_flag);

	return 1;
    }

    #######################################################################################
    # INSTANCE METHODS
    #######################################################################################
#    sub BUILD {
#        my ($self, $obj_ID, $arg_ref) = @_;
#	
#    }

    #--------------------------------------------------------------------------------------
    # Function: START
    # Synopsys: Compute and align the modified substrate, computes the forward/backward rates.
    #--------------------------------------------------------------------------------------
    sub START {
        my ($self, $obj_ID, $arg_ref) = @_;
	my $class = ref $self;

	# get S
	my $S_info_ref = $S_info_ref_of{$obj_ID};
	my $S_species_ref = $S_info_ref->get_species_ref();
	my $S_address_ref = $S_info_ref->get_site_address_ref();
	my $S_site_ref = $S_info_ref->get_site_ref();
	my $S_name = $S_species_ref->get_name();
	my $S_class = ref $S_species_ref;

	# compute the modified species
	my $compute_modified_substrate_ref = $S_class->compute_modified_substrate(
	    reaction_class => $class,
	    dS_info_ref => $S_info_ref,
	   );
	my $P_info_ref = $P_info_ref_of{$obj_ID} = $compute_modified_substrate_ref->{qP_info_ref};
	my $P_species_ref = $P_info_ref->get_species_ref();
	my $P_address_ref = $P_info_ref->get_site_address_ref();
	my $P_site_ref = $P_info_ref->get_site_ref();
	my $P_name = $P_species_ref->get_name();
	my $S2P_instance_mapping_ref = $compute_modified_substrate_ref->{S2P_instance_mapping};

	# compute the rates
	my $S_site_class = ref $S_site_ref;
	my ($kf, $kb) = $S_site_class->compute_unary_rates(
	    $S_site_ref,
	    $P_site_ref,
	    $S2P_instance_mapping_ref,
	   );

	# create the forward/backward reactions
	my $fr_name = "$S_name(@$S_address_ref)";
	my $br_name = "$P_name(@$P_address_ref)";

	my $fr_lookup_ref = ElementaryReaction->lookup_by_name("UR $fr_name");  # UR stands for UnaryReaction
	my $br_lookup_ref = ElementaryReaction->lookup_by_name("UR $br_name");  # UR stands for UnaryReaction

	confess "ERROR: internal error -- both reactions can't be defined" if (defined $fr_lookup_ref && defined $br_lookup_ref);

	if (!defined $fr_lookup_ref) {
	    $forward_reaction_of{$obj_ID} = ElementaryReaction->new({
		container_ref => $self,
		name => "UR $fr_name",
		type => "MASS-ACTION",
		reactants_ref => [$S_species_ref],
		products_ref => [$P_species_ref],
		rate_constant => $kf,
	    });
	} else {
	    $forward_reaction_of{$obj_ID} = $fr_lookup_ref;
	    $is_duplicate_forward_reaction_flag_of{ident $self} = 1;
	}
	if (!defined $br_lookup_ref) {
	    $backward_reaction_of{$obj_ID} = ElementaryReaction->new({
		container_ref => $self,
		name => "UR $br_name",
		type => "MASS-ACTION",
		reactants_ref => [$P_species_ref],
		products_ref => [$S_species_ref],
		rate_constant => $kb,
	    });
	} else {
	    $backward_reaction_of{$obj_ID} = $br_lookup_ref;
	    $is_duplicate_backward_reaction_flag_of{ident $self} = 1;
	}
    }

    #--------------------------------------------------------------------------------------
    # Function: get_new_species
    # Synopsys: 
    #--------------------------------------------------------------------------------------
    sub get_new_species {
	my $self = shift;
	my $obj_ID = ident($self);

	my @new_species = ();

	my $P_species_ref = $P_info_ref_of{$obj_ID}->get_species_ref();

	if ($P_species_ref->get_is_new_flag()) {
	    push @new_species, $P_species_ref;
	}

	return (@new_species);
    }

    #--------------------------------------------------------------------------------------
    # Function: export_equations
    # Synopsys: 
    #--------------------------------------------------------------------------------------
    sub export_equations {
	my $self = shift;
	my $no_uniquify_flag = shift || 0;

	my $S = $self->get_S_info_ref()->get_species_ref()->get_exported_name();
	my $P = $self->get_P_info_ref()->get_species_ref()->get_exported_name();

	my $name = $self->get_name();

	my $kf = $self->get_forward_reaction()->get_rate_constant();
	my $kb = $self->get_backward_reaction()->get_rate_constant();
	my $kf_ref = Variable->new({name => "TEMP", value => $kf});
	my $kb_ref = Variable->new({name => "TEMP", value => $kb});
	my $Keq = $kf_ref / $kb_ref;  # overloaded operator call

	my ($frate_str, $brate_str);
	if (!$no_uniquify_flag) {
	    $frate_str = uniquify("fu","",$kf)."=$kf";
	    $brate_str = uniquify("bu","",$kb)."=$kb";
	} else {
	    $frate_str = "fu=$kf";
	    $brate_str = "bu=$kb";
	}

	if ($kf eq "NAN" || $kb eq "NAN") {
	    return sprintf("%-43s <-> %-32s; %-30s # ($name) Keq = $Keq\n", $S, $P, "$frate_str; $brate_str");
	} else {
	    if ($self->get_is_duplicate_backward_reaction_flag()) {
		return sprintf("%-43s  -> %-32s; %-30s # ($name) Keq = $Keq\n", $S, $P, $frate_str);
	    } elsif ($self->get_is_duplicate_forward_reaction_flag()) {
		return sprintf("%-43s <-  %-32s; %-30s # ($name) Keq = $Keq\n", $S, $P, $brate_str);
	    } elsif (is_numeric($kb) && $kb == 0.0 && is_numeric($kf) && $kf != 0.0) {
		return sprintf("%-43s  -> %-32s; %-30s # ($name) Keq = $Keq (zero backward rate)\n", $S, $P, $frate_str);
	    } elsif (is_numeric($kf) && $kf == 0.0 && is_numeric($kb) && $kb != 0.0) {
		return sprintf("%-43s <-  %-32s; %-30s # ($name) Keq = $Keq (zero forward rate)\n", $S, $P, $brate_str);
	    } else {
		return sprintf("%-43s <-> %-32s; %-30s # ($name) Keq = $Keq\n", $S, $P, "$frate_str; $brate_str");
	    }
	}
    }

    #--------------------------------------------------------------------------------------
    # Function: cmp
    # Synopsys: A compare routine to order two UnaryReactions.
    #--------------------------------------------------------------------------------------
    sub cmp {
	my $class = shift;
	my $a = shift;
	my $b = shift;

	my ($a_S_ref, $b_S_ref) = ($a->get_S_info_ref()->get_species_ref(), $b->get_S_info_ref()->get_species_ref());
	my ($a_S_num, $b_S_num) = ($a_S_ref->get_num_elements(), $b_S_ref->get_num_elements());
#	my ($a_P_ref, $b_P_ref) = ($a->get_P_info_ref()->get_species_ref(), $b->get_P_info_ref()->get_species_ref());
#	my ($a_P_num, $b_P_num) = ($a_P_ref->get_num_elements(), $b_P_ref->get_num_elements());

	if ($a_S_num < $b_S_num) {
	    return -1;
	} elsif ($a_S_num > $b_S_num) {
	    return 1;
	} else {
	    # can't order on substrate size, so order on substrate and product names
	    my ($a_P_ref, $b_P_ref) = ($a->get_P_info_ref()->get_species_ref(), $b->get_P_info_ref()->get_species_ref());

	    my $a_substrate = $a_S_ref->get_exported_name();
	    my $a_product = $a_P_ref->get_exported_name();
	    my $b_substrate = $b_S_ref->get_exported_name();
	    my $b_product = $b_P_ref->get_exported_name();

	    if ($a_substrate lt $b_substrate) {
		return -1;
	    } elsif ($a_substrate gt $b_substrate) {
		return 1;
	    } elsif ($a_product lt $b_product) {
		return -1;
	    } elsif ($a_product gt $b_product) {
		return 1;
	    } else {
		# same substrates and products, so order as <->, then ->, then <-

		# in export_equations(), a '<->' may appear as '<-' or '->'
		my $a_export = $a->export_equations(1);  # prevent uniquification during sort
		$a_export =~ /(<->|<-|->)/;
		my $a_rtype = $1;
		my $b_export = $b->export_equations(1);  # prevent uniquification during sort
		$b_export =~ /(<->|<-|->)/;
		my $b_rtype = $1;

		if ($a_rtype eq '<->' || $b_rtype eq '<->') {
		    return $a_rtype eq '<->' ? -1 : 1;
		} elsif ($a_rtype eq '->' || $b_rtype eq '->') {
		    return $a_rtype eq '->' ? -1 : 1;
		} else {
		    # equations are the same
		    return 0;
		}
	    }
	}
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
    printn "NO TESTCASES!!!";
}


# Package BEGIN must return true value
return 1;

