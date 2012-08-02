######################################################################################
# File:     BindingReaction.pm
# Author:   Julien F. Ollivier
#
# Copyright (C) 2005-2010 Julien Ollivier.
#
# This program comes with ABSOLUTELY NO WARRANTY.
# This is free software, and you are welcome to redistribute it
# under certain conditions. See file LICENSE.TXT for details.
#
# Synopsys: A reversible binding reaction contains two elementary reactions,
#           with two substrates and one complex product.  A ligand pair is
#           specified when reaction is created, which are assumed to exist and bind.
#           The product complex and the reaction rate constants are computed
#           when the help of functions provided by the ligand class.
#
######################################################################################
# Detailed Description:
# ---------------------
# The ligand class must be derived from ComplexInstance and provide the following methods:
#     compute_binding_reaction_forward_rate()
#     compute_binding_reaction_backward_rate()
#     compute_association_complex()
#     compute_dissociation_products()
#     can_bind(), can_unbind() (in ComplexInstance derived class)
#     can_bind(), can_unbind() (in ReactionSite derived class)
#
# The ReactionSite-derived object class must also provide the following methods:
#     can_bind(), can_unbind()
#
# Convention for naming of Species participating in BindingReactions:
#  i) 2nd order (external) reaction naming convention
#    LL + LR <-> C   (CL and CR refer to the associated sites on C)
# ii) 1st order (internal) reaction naming convention
#          D <-> C   (DL and DR refer to the associating sites on D)
#
# When there is any uncertainty, use of L/R can refer to [LL|CL|DL]/[LR|CR|DR],
# i.e. anything.  Use of dL/dR can refer to [LL|DL]/[LR/DR], i.e. the ligands.
#
#
######################################################################################

use strict;
use diagnostics;		# equivalent to -w command-line switch
use warnings;

package BindingReaction;
use Class::Std::Storable;
use base qw(BinaryReaction);
{
    use Carp;

    use Utils;
    use Globals qw(
		   $verbosity
		   $debug
		   $max_csite_bound_to_msite_number
		   $kf_1st_order_rate_cutoff
		   $kf_2nd_order_rate_cutoff
		   $kb_rate_cutoff
		  );

    use ElementaryReaction;

    #######################################################################################
    # ATTRIBUTES
    #######################################################################################
    my %dL_info_ref_of :ATTR(get => "dL_info_ref", set => "dL_info_ref");  # pre-association ligand reaction sites
    my %dR_info_ref_of :ATTR(get => "dR_info_ref", set => "dR_info_ref");

    my %CL_info_ref_of :ATTR(get => "CL_info_ref", set => "CL_info_ref");  # post-association complex reaction sites
    my %CR_info_ref_of :ATTR(get => "CR_info_ref", set => "CR_info_ref");

    my %C_species_ref_of :ATTR(get => "C_species_ref");  # association complex species

    my %forward_reaction_of :ATTR(get => 'forward_reaction');   # reactants are pre-association ligands
    my %backward_reaction_of :ATTR(get => 'backward_reaction'); # reactant is post-association complex

    # indicates whether forward reaction is a internal (1st-order)
    my %internal_association_flag_of :ATTR(get => 'internal_association_flag', set => 'internal_association_flag', init_arg => 'internal_association_flag');

    # duplicate binding reactions can be generated when there is symmetry in the ligands
    # such that they can assemble and generate the same complex in multiple ways (see below)
    my %is_duplicate_association_flag_of :ATTR(get => "is_duplicate_association_flag", set => "is_duplicate_association_flag", default => 0);
    my %is_duplicate_dissociation_flag_of :ATTR(get => "is_duplicate_dissociation_flag", set => "is_duplicate_dissociation_flag", default => 0);

    #######################################################################################
    # FUNCTIONS
    #######################################################################################

    #######################################################################################
    # CLASS METHODS
    #######################################################################################
    #--------------------------------------------------------------------------------------
    # Function: NEW
    # Synopsys: A wrapper for new() that performs the following:
    #              i) get and check arguments
    #             ii) determine whether specified sites are already associated and set flags
    #            iii) determine if the binding reaction has already been computed, if so returns undef
    #             iv) if not associated, determine whether they can and if so, create new reaction
    #              v) if associated, determine whether they can dissociate and if so, create new reaction
    #--------------------------------------------------------------------------------------
    sub NEW {
	my $class = shift;

	my $name = shift;

	my $L_info_ref = shift;
	my $L_species_ref = shift;
	my $L_species_name = shift;
	my $L_site_address_ref = shift;
	my $L_site_ref = shift;              # here L can be LL, CL, DL
	my $R_info_ref = shift;
	my $R_species_ref = shift;
	my $R_species_name = shift;
	my $R_site_address_ref = shift;
	my $R_site_ref = shift;              # here R can be LR, CR, DR

	my $internal_flag = shift;
	my $association_flag = shift;
	my $internal_association_flag = shift;   # undef if dissociation
	my $max_complex_size = shift;
#	my $last_reaction_ref = shift;

	$max_complex_size = defined $max_complex_size ? $max_complex_size : -1;

	if ($debug) {
	    croak "ERROR: argument L_info_ref is not defined" if !defined $L_info_ref;
	    croak "ERROR: argument L_species_ref is not defined" if !defined $L_species_ref;
	    croak "ERROR: argument L_species_name is not defined" if !defined $L_species_name;
	    croak "ERROR: argument L_site_address_ref is not defined" if !defined $L_site_address_ref;
	    croak "ERROR: argument L_site_ref is not defined" if !defined $L_site_ref;
	    croak "ERROR: argument R_info_ref is not defined" if !defined $R_info_ref;
	    croak "ERROR: argument R_species_ref is not defined" if !defined $R_species_ref;
	    croak "ERROR: argument R_species_name is not defined" if !defined $R_species_name;
	    croak "ERROR: argument R_site_address_ref is not defined" if !defined $R_site_address_ref;
	    croak "ERROR: argument R_site_ref is not defined" if !defined $R_site_ref;

	    croak "ERROR: argument internal_flag is not defined" if !defined $internal_flag;
	    croak "ERROR: argument association_flag is not defined" if !defined $association_flag;
	    croak "ERROR: argument max_complex_size is not defined" if !defined $max_complex_size;
	}


	# GET AND CHECK ARGUMENTS
	croak "ERROR: must specify internal_flag" if (!defined $internal_flag);

	croak "ERROR: internal_flag is set, but arguments do not point to the same species" if ($debug && $internal_flag && ($L_species_ref != $R_species_ref));
	croak "ERROR: internal_flag is set, but arguments do not give same L and R species names" if ($debug && $internal_flag && ($L_species_name ne $R_species_name));
	
	# GENERATE A NAME FOR THE ELEMENTARY REACTION SPECIFIED BY ARGUMENTS
	# if reaction is internal, then it is either an association or dissociation, either way it is 1st-order
	# and so one of the elementary reaction names (either forward or backward, depending) is encoded using
	# the name of the reacting complex
	# if the reaction is external, then it is an association, and reaction name is encoded using ligand names
	my $elementary_reaction_name = $class->compute_unique_reaction_name(
	    internal_flag => $internal_flag,
	    L_name => $L_species_name,
	    L_address_ref => $L_site_address_ref,
	    R_name => $R_species_name,
	    R_address_ref => $R_site_address_ref,
	   );
	printn "${class}::NEW -- called for " . ($internal_flag ? "(internal) " : "(external) ") . ($association_flag ? "association" : "dissociation") . " reaction $elementary_reaction_name" if ($verbosity >= 2);

	# CHECK IF WE HAVE ALREADY ATTEMPTED TO COMPUTE THIS EXACT REACTION
	# (THIS CHECK IS CRUCIAL FOR PROPER FUNCTION OF START() ROUTINE BELOW):
	# if the elementary reaction already exists corresponding to these reaction sites,
	# then we have already computed the associated binding reaction, so return undef
	# (n.b. this works regardless of whether it's a 1st or 2nd order association, or dissociation)
	# n.b. this can happen when compiling internal interactions on a new species, since one of the bonds
	# lead to the creation of the species by association and so the corresponding dissociation will exists already;
	# this can theoretically happen on a new species first created by dissociation of a bond also
	# n.b. this can also happen for external interactions, when the corresponding association is found
	# first during the internal interaction pass as a dissociation, and the association is found in the next
	# external iteration e.g.  S-S-S-S -> S + S-S-S (dissociation found in internal iteration #2) is followed
	# by S + S-S-S -> S-S-S-S (association found in external iteration #3).
	if (defined ElementaryReaction->lookup_by_name("BR $elementary_reaction_name")) {
	    printn "${class}::NEW -- already computed elementary reaction $elementary_reaction_name" if ($verbosity >= 2);
	    return undef;
	}

	if ($association_flag) {
	    # IF NOT ASSOCIATED, DETERMINE WHETHER THEY CAN AND IF SO, CREATE NEW REACTION
	    croak "ERROR: internal_association_flag sanity check failed" if ($internal_association_flag && !$internal_flag);
	    croak "ERROR: internal_flag sanity check failed" if ($internal_flag && !$internal_association_flag);
	    # NOT BOUND TO EACH OTHER, NOW CHECK IF BINDING SITES ARE ALREADY BOUND TO ANYTHING ELSE
	    if ($L_species_ref->get_out_degree("primary", ':', $L_site_address_ref) ||
		$R_species_ref->get_out_degree("primary", ':', $R_site_address_ref)) {
		printn "${class}::NEW -- reaction site(s) already bound for reaction $elementary_reaction_name" if ($verbosity >= 2);
		return undef;
	    }

	    if (!$internal_association_flag) {
		# complex size will grow, so check for limits
		if ($max_complex_size != -1 && ($L_species_ref->get_num_elements() + $R_species_ref->get_num_elements() > $max_complex_size)) {
		    printn "${class}::NEW -- complex too large in $elementary_reaction_name" if ($verbosity >= 2);
		    return undef;
		}

		# check proteins in parent complex to see if max no. is reached
		my $L_parent_ref = $L_species_ref->get_parent_ref();
		my $R_parent_ref = $R_species_ref->get_parent_ref();
		foreach my $element_ref ($L_parent_ref->get_elements()) {
		    my $max_count = $element_ref->get_max_count();
		    next if ($max_count == -1);
		    if ($L_parent_ref->get_element_count($element_ref) +
			$R_parent_ref->get_element_count($element_ref) >
			$max_count) {
			printn "${class}::NEW -- element ".$L_parent_ref->get_name()." max_count exceeded in $elementary_reaction_name" if ($verbosity >= 2);
			return undef;
		    }
		}
	    }

	    # either two distinct ligands, or two reaction sites on same species
	    my $can_bind_flag = BindingReaction->can_bind(
		dL_info_ref => $L_info_ref,
		dR_info_ref => $R_info_ref,
		internal_flag => $internal_flag,
	       );

	    # return if binding not possible
	    if (!$can_bind_flag) {
		printn "${class}::NEW -- can't associate in reaction $elementary_reaction_name" if ($verbosity >= 2);
		return undef;
	    }

	    # csite_bound_to_msite_number
 	    my $L_csite_bound_to_msite_number = $L_species_ref->get_csite_bound_to_msite_number();
 	    my $R_csite_bound_to_msite_number = $R_species_ref->get_csite_bound_to_msite_number();
 	    my $C_csite_bound_to_msite_number = ($internal_association_flag ? 
						 $R_csite_bound_to_msite_number :
						 $L_csite_bound_to_msite_number + $R_csite_bound_to_msite_number);
	    my $L_site_type = $L_site_ref->get_type();
	    my $R_site_type = $R_site_ref->get_type();
	    my $csite_bound_to_msite_flag = (($L_site_type eq 'csite' && $R_site_type eq 'msite') ? 'L' :
					     ($R_site_type eq 'csite' && $L_site_type eq 'msite') ? 'R' : 0);

	    $C_csite_bound_to_msite_number++ if $csite_bound_to_msite_flag;

	    if (($max_csite_bound_to_msite_number != -1) && ($C_csite_bound_to_msite_number > $max_csite_bound_to_msite_number)) {
		printn "${class}::NEW -- csite_bound_to_msite_number of complex ($C_csite_bound_to_msite_number) exceeds maximum ($max_csite_bound_to_msite_number) in $elementary_reaction_name" if $verbosity >= 2;
		return undef;
	    }

	    return $class->new({
		name => uniquify($name),
		L_info_ref => $L_info_ref,
		R_info_ref => $R_info_ref,
		internal_flag => $internal_flag,
		association_flag => 1,
		internal_association_flag => $internal_association_flag,
		csite_bound_to_msite_flag => $csite_bound_to_msite_flag,
		C_csite_bound_to_msite_number => $C_csite_bound_to_msite_number,
	    });

	} else {
	    # THE TWO REACTION SITES ARE ALREADY ASSOCIATED, DETERMINE WHETHER THEY
	    # CAN DISSOCIATE AND IF SO, CREATE NEW REACTION
	    croak "ERROR: internal_association_flag sanity check failed" if (defined $internal_association_flag);
	    croak "ERROR: internal_flag sanity check failed" if (!$internal_flag);
	    my $can_unbind_flag = BindingReaction->can_unbind(
		CL_info_ref => $L_info_ref,
		CR_info_ref => $R_info_ref
	       );

	    if (!$can_unbind_flag) {
		printn "${class}::NEW -- can't dissociate in reaction $elementary_reaction_name" if ($verbosity >= 2);
		return undef;
	    }

	    # csite_bound_to_msite_number
	    my $C_csite_bound_to_msite_number = $L_species_ref->get_csite_bound_to_msite_number();
	    my $L_site_type = $L_site_ref->get_type();
	    my $R_site_type = $R_site_ref->get_type();
	    my $csite_bound_to_msite_flag = (($L_site_type eq 'csite' && $R_site_type eq 'msite') ? 'L' :
					     ($R_site_type eq 'csite' && $L_site_type eq 'msite') ? 'R' : 0);

	    return $class->new({
		name => uniquify($name),
		L_info_ref => $L_info_ref,
		R_info_ref => $R_info_ref,
		internal_flag => $internal_flag,
		association_flag => 0,
		internal_association_flag => $internal_association_flag,
		csite_bound_to_msite_flag => $csite_bound_to_msite_flag,
		C_csite_bound_to_msite_number => $C_csite_bound_to_msite_number,
	    });
	}
    }

    #--------------------------------------------------------------------------------------
    # Function: can_bind
    # Synopsys: Given two unbound ligands, determine if they can participate in an association
    #           reaction -- true if BindingProfiles can bind, and if each ligand site
    #           is allowed to bind individually (e.g. is it on or off?).
    #           N.B. can_bind() is a function of the dissociated ligands (dL/dR).
    #--------------------------------------------------------------------------------------
    sub can_bind {
	my $class = shift;
	my %args = (
	    dL_info_ref => undef,
	    dR_info_ref => undef,
	    internal_flag => undef,
	    @_,
	   );

	check_args(\%args, 3);

	my $dL_info_ref = $args{dL_info_ref};
	my $dR_info_ref = $args{dR_info_ref};
	my $internal_flag = $args{internal_flag};

	#-------------------------------------------------------------------------------
	# Call the ReactionSiteInstance can_bind() class method which will determine
	# whether the two ligands can bind.
	#-------------------------------------------------------------------------------
	my ($reaction_sites_can_bind_flag, $kf, $steric_factor) = ReactionSiteInstance->can_bind(
	    $dL_info_ref->get_site_ref(),
	    $dR_info_ref->get_site_ref(),
	    $internal_flag,
	   );

	return 0 if (!$reaction_sites_can_bind_flag);

	# steric_factor for internal binding reactions
	if ($internal_flag) {
	    if (is_numeric($kf) && is_numeric($steric_factor)) {
		$kf = $kf * $steric_factor;
		return 0 if is_numeric($kf) && is_numeric($kf_1st_order_rate_cutoff) && ($kf <= $kf_1st_order_rate_cutoff);
	    } else {
		$kf = "$kf * $steric_factor";
	    }
	} else {
	    return 0 if is_numeric($kf) && is_numeric($kf_2nd_order_rate_cutoff) && ($kf <= $kf_2nd_order_rate_cutoff);
	}

	return 1;
    }

    #--------------------------------------------------------------------------------------
    # Function: can_unbind
    # Synopsys: ???  NOT TRUE ANYMORE: It is always possible to dissociate, so return true. !!!
    #           N.B. can_unbind() is a function of the associated ligands (CL/CR).
    #--------------------------------------------------------------------------------------
    sub can_unbind {
	my $class = shift;

	my %args = (
	    CL_info_ref => undef,
	    CR_info_ref => undef,
	    @_,
	   );

	check_args(\%args, 2);

	my $CL_info_ref = $args{CL_info_ref};
	my $CR_info_ref = $args{CR_info_ref};

	#-------------------------------------------------------------------------------
	# Call the ReactionSiteInstance can_unbind() class method which will determine
	# whether the two ligands can unbind.
	#-------------------------------------------------------------------------------
	my ($reaction_sites_can_unbind_flag, $kb) = ReactionSiteInstance->can_unbind(
	    $CL_info_ref->get_site_ref(),
	    $CR_info_ref->get_site_ref(),
	   );
	confess "ERROR: internal error -- kb undefined" if ($reaction_sites_can_unbind_flag && !defined $kb);

	return 0 if !$reaction_sites_can_unbind_flag;
	return 0 if is_numeric($kb) && is_numeric($kb_rate_cutoff) && ($kb <= $kb_rate_cutoff);

	return 1;
    }

    #######################################################################################
    # INSTANCE METHODS
    #######################################################################################
    #--------------------------------------------------------------------------------------
    # Function: START
    # Synopsys: 
    #--------------------------------------------------------------------------------------
    sub START {
        my ($self, $obj_ID, $arg_ref) = @_;
	my $class = ref $self;

	my $association_flag = $arg_ref->{association_flag};
	my $internal_association_flag = $internal_association_flag_of{$obj_ID};

	my $L_info_ref = $arg_ref->{L_info_ref};
	my $R_info_ref = $arg_ref->{R_info_ref};

	my $L_species_ref = $L_info_ref->get_species_ref();
	my $R_species_ref = $R_info_ref->get_species_ref();

	my $L_address_ref = $L_info_ref->get_site_address_ref();
	my $R_address_ref = $R_info_ref->get_site_address_ref();

	my $L_site_ref = $L_info_ref->get_site_ref();
	my $R_site_ref = $R_info_ref->get_site_ref();

	# check that ligands are same object class
	croak "BinaryReaction must have reactant species objects of same class\n" if ((ref $L_species_ref) ne (ref $R_species_ref));

	my $species_class = ref $L_species_ref;

	my ($dL_info_ref,    $dR_info_ref);      # dL/dR can be LL/LR or DL/DR
	my ($dL_address_ref, $dR_address_ref);
	my ($dL_species_ref, $dR_species_ref);

	my ($CL_info_ref,    $CR_info_ref);
	my ($CL_address_ref, $CR_address_ref);
	my ($C_species_ref);

	my ($can_bind_flag, $can_unbind_flag);

	if ($association_flag) {
	    # n.b. this must be first time we compute this particular association reaction, else NEW() would have returned undef above
	    # (so there is no point in looking up whether it exists already, NEW() has already done so)

	    # arguments L_info_ref/R_info_ref refer to ligand sites LL/LR or DL/DR
	    $dL_info_ref = $dL_info_ref_of{$obj_ID} = $L_info_ref;
	    $dR_info_ref = $dR_info_ref_of{$obj_ID} = $R_info_ref;

	    $dL_species_ref = $L_species_ref;
	    $dR_species_ref = $R_species_ref;

	    $dL_address_ref = $L_address_ref;
	    $dR_address_ref = $R_address_ref;

	    # compute the association complex and mapping
	    my $compute_association_ref = $species_class->compute_association_complex(
		reaction_class => $class,
		dL_info_ref => $dL_info_ref,
		dR_info_ref => $dR_info_ref,
		internal_association_flag => $internal_association_flag,
	    );

	    # store complex attribute
	    $C_species_ref = $C_species_ref_of{$obj_ID} = $compute_association_ref->{C_ref};

	    # extract and store complex SiteInfo attributes
	    $CL_info_ref = $CL_info_ref_of{$obj_ID} = $compute_association_ref->{CL_info_ref};
	    $CL_address_ref = $CL_info_ref->get_site_address_ref();
	    $CR_info_ref = $CR_info_ref_of{$obj_ID} = $compute_association_ref->{CR_info_ref};
	    $CR_address_ref = $CR_info_ref->get_site_address_ref();

	    # compute de(association) flags
	    $can_bind_flag = 1;
	    $can_unbind_flag = BindingReaction->can_unbind(
		CL_info_ref => $CL_info_ref,
		CR_info_ref => $CR_info_ref,
	       );

	    # set csite_bound_to_msite_flag if appropriate
	    if ($arg_ref->{csite_bound_to_msite_flag}) {
		if ($arg_ref->{csite_bound_to_msite_flag} eq 'L') {
		    $CL_info_ref->get_site_ref()->set_csite_bound_to_msite_flag(1);
		} else {
		    $CR_info_ref->get_site_ref()->set_csite_bound_to_msite_flag(1);
		}
	    }
	    # check if the csite_bound_to_msite_number of the complex is the same as that computed by NEW() above
	    confess "ERROR: csite_bound_to_msite_number is messed up" if ($C_species_ref->get_csite_bound_to_msite_number() != $arg_ref->{C_csite_bound_to_msite_number});
	} else {		# it's a dissociation
	    # n.b. this must be first time we compute this particular dissociation reaction, else NEW() would have returned undef above
	    # (so there is no point in looking up whether it exists already, NEW() has already done so)

	    # arguments L_info_ref/R_info_ref refer to complex sites CL and CR
	    $CL_info_ref = $CL_info_ref_of{$obj_ID} = $L_info_ref;
	    $CR_info_ref = $CR_info_ref_of{$obj_ID} = $R_info_ref;

	    $C_species_ref = $C_species_ref_of{$obj_ID} = $L_species_ref;

	    $CL_address_ref = $L_address_ref;
	    $CR_address_ref = $R_address_ref;

	    # compute the dissociation products and mapping, this will also set the internal_association_flag
	    # attribute if it is undefined at this point
	    my $compute_dissociation_ref = $species_class->compute_dissociation_products(
		reaction_class => $class,
		CL_info_ref => $CL_info_ref,
		CR_info_ref => $CR_info_ref,
	       );

	    # compute_dissociation_products has determined if association is internal (1st-order) or not
	    $internal_association_flag = $internal_association_flag_of{$obj_ID} = $compute_dissociation_ref->{internal_association_flag};

	    # extract and store ligand SiteInfo attributes
	    $dL_info_ref = $dL_info_ref_of{$obj_ID} = $compute_dissociation_ref->{dL_info_ref};
	    $dL_address_ref = $dL_info_ref->get_site_address_ref();
	    $dL_species_ref = $dL_info_ref->get_species_ref();

	    $dR_info_ref = $dR_info_ref_of{$obj_ID} = $compute_dissociation_ref->{dR_info_ref};
	    $dR_address_ref = $dR_info_ref->get_site_address_ref();
	    $dR_species_ref = $dR_info_ref->get_species_ref();

	    # compute de(association) flags
	    $can_unbind_flag = 1;
	    # need to check if re-association is allowed
	    $can_bind_flag = BindingReaction->can_bind(
		dL_info_ref => $dL_info_ref,
		dR_info_ref => $dR_info_ref,
		internal_flag => $internal_association_flag,
	       );

	    # reset csite_bound_to_msite_flag if appropriate
	    my $LplusR_csite_bound_to_msite_number = $arg_ref->{C_csite_bound_to_msite_number};
	    if ($arg_ref->{csite_bound_to_msite_flag}) {
		if ($arg_ref->{csite_bound_to_msite_flag} eq 'L') {
		    $dL_info_ref->get_site_ref()->set_csite_bound_to_msite_flag(0);
		} else {
		    $dR_info_ref->get_site_ref()->set_csite_bound_to_msite_flag(0);
		}
		$LplusR_csite_bound_to_msite_number--;
	    }
	    # check if the csite_bound_to_msite_number of the dissociated ligands corresponds to that of the complex reported by NEW() above
	    my $dL_csite_bound_to_msite_number = $dL_species_ref->get_csite_bound_to_msite_number();
	    my $dR_csite_bound_to_msite_number = $dR_species_ref->get_csite_bound_to_msite_number();
	    if ($internal_association_flag) {
		confess "ERROR: csite_bound_to_msite_number is messed up" if ($internal_association_flag ?
									      ($dL_csite_bound_to_msite_number != $LplusR_csite_bound_to_msite_number) :
									      ($dL_csite_bound_to_msite_number + $dR_csite_bound_to_msite_number != $LplusR_csite_bound_to_msite_number));
	    }
	}
	
	# create the individual forward and backward reactions
	my $dL_name = $dL_species_ref->get_name();
	my $dR_name = $dR_species_ref->get_name();
	my $C_name = $C_species_ref->get_name();
	
	# compute the rates
	my ($kf, $steric_factor) = $can_bind_flag ? ReactionSiteInstance->compute_association_rate(
	    $dL_info_ref->get_site_ref(),
	    $dR_info_ref->get_site_ref(),
	    $internal_association_flag,
	   ) : (undef, undef);
	my $kb = $can_unbind_flag ? ReactionSiteInstance->compute_dissociation_rate(
	    $CL_info_ref->get_site_ref(),
	    $CR_info_ref->get_site_ref(),
	   ) : undef;

	if ($can_bind_flag) {
	    # rate adjustment for homo-dimerization, must be performed once
	    # internal_association_flag value is known for dissociations
	    if (!$internal_association_flag && ($dL_species_ref == $dR_species_ref)) {
		if (is_numeric($kf)) {
		    $kf = $kf / 2;
		} else {
		    $kf = "$kf / 2";
		}
	    }

	    # apply steric_factor to internal binding reactions
	    if ($internal_association_flag) {
		if (is_numeric($kf) && is_numeric($steric_factor)) {
		    $kf = $kf * $steric_factor;
		} else {
		    $kf = "$kf * $steric_factor";
		}
	    }
	}

	# N.B.  An **external** association reaction existing already can be due to
	#         i) one or both of the reactants having symmetry, e.g. A-A + X <-> A-A-X
	#        ii) a species binding to itself thru distinct non self-binding sites e.g. X-Y + X-Y <-> X-Y-X-Y
	# Either way, this means there are several alternative ways the same reactants can associate
	# to produce the same product.  Each of those ways involves a distinct reaction site
	# on the L/R hand side species.  In these cases we must generate the distinct forward reactions
	# multiple times, however the unique reverse reaction must be generated only once.  Hence,
	# we must recognize that the reverse reaction occurs only one way.
	# E.g.  for the reaction A-A + X <-> A-A-X, we should generate the forward reaction twice
	# since there are two ways the association can occur, but the reverse reaction once
	# since there is only one way for the dissociation to occur.

	# Here, we encode the reaction names in such a way that we can recognize
	# duplicate reactions arising from multiple calls to this function.  This is done by
	# encoding the ligand reaction sites involved for the forward reaction,
	# and the dissociating sites in the backward reaction, into the name of the reaction.
	# If the association reaction is an internal_association, we must sort the addresses of the sites
	# involved, since a different order does not specify a distinct reaction in this case.
	# Similarly for dissociations since the same dissociation is occuring regardless of
	# the order in which the sites are specified.

	# For external associations, order does matter in cases where a species can bind to itself,
	# using distinct (i.e. non self-binding) sites.  In this case order matters because there
	# are really two ways for 2 instances of such a species to associate with itself, and these
	# should generate two distinct association reactions.  (e.g. the SELF-BINDING testcase).

	# Note that because of the way compilation for external associations is performed, 
	# we don't try both orderings for each pair of distinct species, and so we don't really need
	# to sort in this case either.  If we did, we would need to sort to reject duplicates.

	# We want to make sure we can reject duplicates in all cases, so we sort
	# external associations involving distinct ligands, but not those involving identical
	# ligands.  E.g.   X(0) + Y(3) is be sorted, but not X(0) + X(1) (where parenthesis
	# refer to an internal binding site), since X(1) + X(0) is a distinct association.

	my $fr_name = $class->compute_unique_reaction_name(
	    internal_flag => $internal_association_flag,
	    L_name => $dL_name,
	    L_address_ref => $dL_address_ref,
	    R_name => $dR_name,
	    R_address_ref => $dR_address_ref,
	   );

	# the backward dissociation reaction is always internal, so we sort the reaction name
	my $br_name = $class->compute_unique_reaction_name(
	    internal_flag => 1,
	    L_name => $C_name,
	    L_address_ref => $CL_address_ref,
	    R_name => $C_name,
	    R_address_ref => $CR_address_ref,
	   );

	printn "BindingReaction -- looking for reaction $fr_name" if $verbosity >= 2;
	my $fr_lookup_ref = ElementaryReaction->lookup_by_name("BR $fr_name");  # BR stands for binding reaction, not backward
	if (!defined $fr_lookup_ref) {
	    # This is the first time this binding reaction has been seen
	    $forward_reaction_of{$obj_ID} = ElementaryReaction->new({
		container_ref => $self,
		name => "BR $fr_name",
		type => "MASS-ACTION",
		reactants_ref => [$dL_info_ref, $dR_info_ref],  # store all info  (!!! WHY ???)
		products_ref => [$C_species_ref],     # don't store address
		rate_constant => $kf,
	    });
	} else {
	    # this happens in a case where there are 2 ways to dissociate but only one way to associate
	    # e.g. A-A  <-> A=A  (i.e. double-bond and with symmetrical A)
	    #      A-A  <-  A=A  (i.e. double-bond and with symmetrical A)
	    $forward_reaction_of{$obj_ID} = $fr_lookup_ref;
	    $is_duplicate_association_flag_of{$obj_ID} = 1;	# flag this as a duplicate reaction
	    if ($association_flag) {
		croak "ERROR: internal error -- NEW association ($fr_name) should have returned undef (not called new()) after checking for existence of elementary reaction";
	    }
	}
	
	printn "BindingReaction -- looking for reaction $br_name" if $verbosity >= 2;
	my $br_lookup_ref = ElementaryReaction->lookup_by_name("BR $br_name");  # BR stands for binding reaction, not backward
	if (!defined $br_lookup_ref) {
	    $backward_reaction_of{$obj_ID} = ElementaryReaction->new({
		container_ref => $self,
		name => "BR $br_name",
		type => "MASS-ACTION",
		reactants_ref => [$CL_info_ref, $CR_info_ref], # store all info
		products_ref => [$dL_species_ref, $dR_species_ref], # don't store address
		rate_constant => $kb,
	    });
	} else {
	    # this happens in a case where there are 2 ways to associate but only one way to dissociate
	    # e.g. A-A + X <->   A-A-X
	    #      A-A + X  -> X-A-A
	    $backward_reaction_of{$obj_ID} = $br_lookup_ref;
	    $is_duplicate_dissociation_flag_of{$obj_ID} = 1; # flag this as a duplicate reaction
	    if (!$association_flag) {
		confess "ERROR: internal error -- NEW dissociation ($br_name) should have returned undef (not called new()) after checking for existence of elementary reaction";
	    }
	}
    }

    #--------------------------------------------------------------------------------------
    # Function: get_dL_species_ref
    # Synopsys: 
    #--------------------------------------------------------------------------------------
    sub get_dL_species_ref {
	my $self = shift;

	return $dL_info_ref_of{ident $self}->get_species_ref();
    }

    #--------------------------------------------------------------------------------------
    # Function: get_dR_species_ref
    # Synopsys: 
    #--------------------------------------------------------------------------------------
    sub get_dR_species_ref {
	my $self = shift;

	return $dR_info_ref_of{ident $self}->get_species_ref();
    }

    #--------------------------------------------------------------------------------------
    # Function: get_new_species
    # Synopsys: 
    #--------------------------------------------------------------------------------------
    sub get_new_species {
	my $self = shift;
	my $obj_ID = ident($self);

	my @species = ();
	if ($internal_association_flag_of{$obj_ID}) {
	    @species = (
		$dL_info_ref_of{$obj_ID}->get_species_ref(),
		$C_species_ref_of{$obj_ID},
	       );
	} else {
	    @species = (
		$dL_info_ref_of{$obj_ID}->get_species_ref(),
		$dR_info_ref_of{$obj_ID}->get_species_ref(),
		$C_species_ref_of{$obj_ID},
	       );
	}
	my @new_species = grep($_->get_is_new_flag(), @species);

	return (@new_species);
    }

    #--------------------------------------------------------------------------------------
    # Function: get_LR_export_swap_flag
    # Synopsys: Order L/R ligands according to size, or alphabetical if same size.
    #--------------------------------------------------------------------------------------
    sub get_LR_export_swap_flag {
	my $self = shift;
	my $L_species_ref = shift;   # if defined, indicates which species to place L

	my $L_ref = $self->get_dL_info_ref()->get_species_ref();
	my $R_ref = $self->get_dR_info_ref()->get_species_ref();

	# swap if necessary
	if (defined $L_species_ref) {
	    confess "ERROR: internal error -- species is not part of the reaction" if ($L_species_ref != $L_ref &&
										       $L_species_ref != $R_ref);
	    return ($L_ref == $L_species_ref) ? 0 : 1;
	}

	if ($R_ref->get_num_elements() < $L_ref->get_num_elements()) {
	    return 1;
	} elsif ($R_ref->get_num_elements() > $L_ref->get_num_elements()) {
	    return 0;
	} else {
	    # same no. of elements, so use alphabetical order on exported name
	    return ($R_ref->get_exported_name() lt $L_ref->get_exported_name()) ? 1 : 0;
	}
    }

    #--------------------------------------------------------------------------------------
    # Function: export_equations
    # Synopsys: 
    #--------------------------------------------------------------------------------------
    sub export_equations {
	my $self = shift;
	# if defined, indicates which species to place L
	# (useful to force placement of E in catalytic reactions)
	my $L_species_ref = shift;
	my $no_uniquify_flag = shift || 0;

	my $L_ref = $self->get_dL_info_ref()->get_species_ref();
	my $R_ref = $self->get_dR_info_ref()->get_species_ref();
	my $C_ref = $self->get_C_species_ref();

	my $L = $L_ref->get_exported_name();
	my $R = $R_ref->get_exported_name();
	my $C = $C_ref->get_exported_name();

	my $kf = $self->get_forward_reaction()->get_rate_constant();
	my $kb = $self->get_backward_reaction()->get_rate_constant();

	my $internal_association_flag = $self->get_internal_association_flag();

	# order ligands according to size and generate string
	my $LR_export_swap_flag = $self->get_LR_export_swap_flag($L_species_ref);

	my $ligands = ($internal_association_flag) ? "$L" : ($LR_export_swap_flag ? sprintf("%-20s + $L", $R) : sprintf("%-20s + $R",$L));

	my $name = ("(".$self->get_name().")");

	# n.b. when a rate is not defined, this means that the reaction does not exist:
	#         i) no enabling rule was found, or
	#        ii) the numerical rate was below the cutoff rate and it was filtered out
	# n.b. if the cutoff is negative, zero rates are still possible and corresponding reaction will be output
	my ($frate_str, $brate_str);
	if (!$no_uniquify_flag) {
	    $frate_str = ($internal_association_flag) ? (uniquify("fbu","",$kf)."=$kf") : (uniquify("fb","",$kf)."=$kf") if defined $kf;
	    $brate_str = uniquify("bb","",$kb)."=$kb" if defined $kb;
	} else {
	    $frate_str = ($internal_association_flag) ? ("fbu=$kf") : ("fb=$kf") if defined $kf;
	    $brate_str = "bb=$kb" if defined $kb;
	}

	if ($self->get_is_duplicate_dissociation_flag()) {
	    return sprintf("%-43s  -> %-32s; %-30s # $name Kd = UNDEFINED\n", $ligands, $C, $frate_str);
	} elsif ($self->get_is_duplicate_association_flag()) {
	    return sprintf("%-43s <-  %-32s; %-30s # $name Kd = UNDEFINED\n", $ligands, $C, $brate_str);
	} elsif ((!defined $kb) && (defined $kf)) {
	    return sprintf("%-43s  -> %-32s; %-30s # $name Kd = UNDEFINED (can't dissociate)\n", $ligands, $C, $frate_str);
	} elsif ((!defined $kf) && (defined $kb)) {
	    return sprintf("%-43s <-  %-32s; %-30s # $name Kd = UNDEFINED (release reaction)\n", $ligands, $C, $brate_str);
	} else {
	    confess "ERROR: unexpected condition" if !defined $kf || !defined $kb;
	    my $Kd;
	    if (!is_numeric($kf) || !is_numeric($kb)) {
		$Kd = "$kb/$kf";
	    } elsif (($kf == 0) && ($kb == 0)) {
		$Kd = "UNDEFINED";
	    } elsif ($kf == 0) {
		$Kd = "INFINITY";
	    } else {
		$Kd = $kb/$kf;
	    }
	    return sprintf("%-43s <-> %-32s; %-30s # $name Kd = $Kd\n", $ligands, $C, "$frate_str; $brate_str");
	}
    }

    #--------------------------------------------------------------------------------------
    # Function: get_export_ordered_ligands
    # Synopsys: Get ligands in same order as output by export_equations().
    #--------------------------------------------------------------------------------------
    sub get_export_ordered_ligands {
	my $self = shift;

	my $L_ref = $self->get_dL_info_ref()->get_species_ref();
	my $R_ref = $self->get_dR_info_ref()->get_species_ref();

	my $swap_flag =$self->get_LR_export_swap_flag();

	if ($swap_flag) {
	    return ($R_ref, $L_ref);
	} else {
	    return ($L_ref, $R_ref);
	}
    }

    #--------------------------------------------------------------------------------------
    # Function: cmp
    # Synopsys: A compare routine to order two BindingReactions.
    #--------------------------------------------------------------------------------------
    sub cmp {
	my $class = shift;
	my $a = shift;
	my $b = shift;

	my ($a_L_ref, $a_R_ref) = $a->get_export_ordered_ligands();
	my ($b_L_ref, $b_R_ref) = $b->get_export_ordered_ligands();

	# internal reactions go last
	my ($a_internal, $b_internal) = ($a->get_internal_association_flag(), $b->get_internal_association_flag());
	return -1 if (!$a_internal &&  $b_internal);
	return  1 if ( $a_internal && !$b_internal);

	# at this point, always comparing internal with internal, or external with external, which
	# simplifies comparison below...

	my ($a_L_num, $b_L_num) = ($a_L_ref->get_num_elements(), $b_L_ref->get_num_elements());
	my ($a_R_num, $b_R_num) = ($a_R_ref->get_num_elements(), $b_R_ref->get_num_elements());

	my $a_min = $a_L_num < $a_R_num ? $a_L_num : $a_R_num;
	my $a_max = $a_L_num > $a_R_num ? $a_L_num : $a_R_num;
	my $b_min = $b_L_num < $b_R_num ? $b_L_num : $b_R_num;
	my $b_max = $b_L_num > $b_R_num ? $b_L_num : $b_R_num;

	# order on ligand size
	# (but not on complex size, since this is a function of ligand sizes and adds nothing new)
	if ($a_min < $b_min) {
	    return -1;
	} elsif ($a_min > $b_min) {
	    return 1;
	} elsif ($a_max < $b_max) {
	    return -1;
	} elsif ($a_max > $b_max) {
	    return 1;
	} else {
	    # can't order on ligand size, so order on ligand and complex exported names
	    my $a_ligands = join(" ", ($a_L_ref->get_exported_name(), $a_R_ref->get_exported_name()));
	    my $a_complex = $a->get_C_species_ref->get_exported_name();
	    
	    my $b_ligands = join(" ", ($b_L_ref->get_exported_name(), $b_R_ref->get_exported_name()));
	    my $b_complex = $b->get_C_species_ref->get_exported_name();

	    if ($a_ligands lt $b_ligands) {
		return -1;
	    } elsif ($a_ligands gt $b_ligands) {
		return 1;
	    } elsif ($a_complex lt $b_complex) {
		return -1;
	    } elsif ($a_complex gt $b_complex) {
		return 1;
	    } else {
		# same ligands and complex, so order as <->, then ->, then <-

		# in export_equations(), a '<->' may appear as '<-' or '->'
		my $a_export = $a->export_equations(undef, 1);  # prevent uniquification during sort
		$a_export =~ /(<->|<-|->)/;
		my $a_rtype = $1;
		my $b_export = $b->export_equations(undef, 1);  # prevent uniquification during sort
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
}


sub run_testcases {

    printn "NO TESTCASES!!!";

}

#run_testcases();

# Package BEGIN must return true value
return 1;

