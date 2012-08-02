######################################################################################
# File:     CatalyticReaction.pm
# Author:   Julien F. Ollivier
#
# Copyright (C) 2005-2010 Julien Ollivier.
#
# This program comes with ABSOLUTELY NO WARRANTY.
# This is free software, and you are welcome to redistribute it
# under certain conditions. See file LICENSE.TXT for details.
#
# Synopsys: A catalytic reaction is a binding reaction plus a product producing reaction.
######################################################################################
# Detailed Description:
# ---------------------
# The ligand class must be derived from ComplexInstance and provide the following methods:
#     compute_catalytic_reaction_product_rate()
#     compute_catalytic_reaction_product()
#     can_modify()   (in ComplexInstance derived class)
#     can_modify()   (in ReactionSite derived class)
#
# Convention for naming of Species participating in CatalyticReactions:
#  i) external reaction naming convention
#    C -> E + P  (CE and CS refer to the sites on C)
# ii) internal reaction naming convention
#    C -> Q     (DE and DS refer to the sites on D, ditto QE and QP on Q)
#
# Where there is uncertainty, qE/qP can refer to [E|QE]/[P|QP], also
# same idea for dE and dS.
#
######################################################################################

use strict;
use diagnostics;		# equivalent to -w command-line switch
use warnings;

package CatalyticReaction;
use Class::Std::Storable;
use base qw(BinaryReaction);  # n.b. does NOT inherit from BindingReaction
{
    use Carp;

    use Utils;
    use Globals qw(
		   $verbosity
		   $kp_rate_cutoff
		  );

    #######################################################################################
    # ATTRIBUTES
    #######################################################################################
    my %CL_info_ref_of :ATTR(get => "CL_info_ref", set => "CL_info_ref", init_arg => "CL_info_ref");  # catalytic complex reaction sites
    my %CR_info_ref_of :ATTR(get => "CR_info_ref", set => "CR_info_ref", init_arg => "CR_info_ref");
    my %L_is_enzyme_flag_of :ATTR(get => 'L_is_enzyme_flag', set => 'L_is_enzyme_flag', init_arg => 'L_is_enzyme_flag');
    my %C_species_ref_of :ATTR(get => "C_species_ref");

    my %qE_info_ref_of :ATTR(get => "qE_info_ref");
    my %qP_info_ref_of :ATTR(get => "qP_info_ref");

    my %internal_dissociation_flag_of :ATTR(get => "internal_dissociation_flag", set => "internal_dissociation_flag");

    my %product_reaction_of :ATTR(get => 'product_reaction');

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
	my $internal_association_flag = shift;
	my $max_complex_size = shift;
	my $last_reaction_ref = shift;

	# try to find an associated binding reaction on which we can piggyback to speed computations
	my $binding_reaction_ref = $last_reaction_ref;

	# return undef if it's an association and no binding reaction resulted
	# (since there was no complex formed, no need to try and generate a product reaction)
	return undef if ($association_flag &&
			 !(defined $binding_reaction_ref && (ref $binding_reaction_ref eq "BindingReaction")));

	if (!defined $binding_reaction_ref) {
	    # here, if no binding reaction was found, then L/R must be associated ligands
	    confess "ERROR: internal inconsistency (association_flag)" if $association_flag;
	    confess "ERROR: internal inconsistency (internal_flag)" if !$internal_flag;

	    # try to find a dissociation reaction computed in a previous iteration of the compilation
	    my $elementary_reaction_name = $class->compute_unique_reaction_name(
		internal_flag => 1,
		L_name => $L_species_name,
		L_address_ref => $L_site_address_ref,
		R_name => $R_species_name,
		R_address_ref => $R_site_address_ref,
	       );

	    my $elementary_reaction_ref = ElementaryReaction->lookup_by_name("BR $elementary_reaction_name");
	    $binding_reaction_ref = defined $elementary_reaction_ref ? $elementary_reaction_ref->get_container_ref() : undef;
	}

	# at this point we have 3 cases:
	#   i) L/R refer to dissociated ligands but a BindingReaction was computed in this iteration,
	#      so we need to determine whether the complex is catalytic
	#  ii) L/R refer to associated ligands, and a BindingReaction was computed in this iteration
	#      (from last_reaction_ref) or in a previous iteration (from lookup)
	# iii) L/R refer to associated ligands, but no BindingReaction was computed in this iteration
	#      (from last_reaction_ref) or in a previous iteration (from lookup)
	
	my ($CL_info_ref, $CR_info_ref);
	if (defined $binding_reaction_ref) {  # case i) and ii)
	    # get the reaction sites involved in the catalytic reaction
	    $CL_info_ref = $binding_reaction_ref->get_CL_info_ref();
	    $CR_info_ref = $binding_reaction_ref->get_CR_info_ref();
	} else {  # case iii)
	    $CL_info_ref = $L_info_ref;
	    $CR_info_ref = $R_info_ref;
	}
	
	# check that we haven't already computed the product reaction
	my $elementary_reaction_name = $class->compute_unique_reaction_name(
	    internal_flag => 1,
	    L_name => $CL_info_ref->get_species_ref()->get_name(),
	    L_address_ref => $CL_info_ref->get_site_address_ref(),
	    R_name => $CR_info_ref->get_species_ref()->get_name(),
	    R_address_ref => $CR_info_ref->get_site_address_ref(),
	   );
	if (defined ElementaryReaction->lookup_by_name("CR $elementary_reaction_name")) {
	    printn "${class}::NEW -- already computed elementary reaction $elementary_reaction_name" if ($verbosity >= 2);
	    return undef;
	}

	# CAN L MODIFY R OR VICE-VERSA
	my $L_is_enzyme_flag = CatalyticReaction->can_modify(
	    CL_info_ref => $CL_info_ref,
	    CR_info_ref => $CR_info_ref,
	   );

	# if this is not the case, return
	if (!defined $L_is_enzyme_flag) {
	    printn "${class}::NEW -- can't modify" if ($verbosity >= 2);
	    return undef;
	}

	# YES, and we have determined which of L and R is the enzyme

	# create the CatalyticReaction
	return $class->new({
	    name => uniquify($name),
	    CL_info_ref => $CL_info_ref,
	    CR_info_ref => $CR_info_ref,
	    L_is_enzyme_flag => $L_is_enzyme_flag,
	    binding_reaction_ref => $binding_reaction_ref,  # n.b. not an attribute
	});
    }

    #--------------------------------------------------------------------------------------
    # Function: can_modify
    # Synopsys: Determines whether arguments are a enzyme/substrate pair.
    #           Returns L_is_enzyme_flag:
    #               undef:  not a substrate pair
    #                   1:  L is an enzyme and R is substrate
    #                   0:  R is an enzyme and L is substrate
    #--------------------------------------------------------------------------------------
    sub can_modify {
	my $class = shift;
	my %args = (
	    CL_info_ref => undef,
	    CR_info_ref => undef,
	    @_,
	   );
	check_args(\%args,2);

	my $CL_info_ref = $args{CL_info_ref};
	my $CR_info_ref = $args{CR_info_ref};

	my $L_is_enzyme_flag = CatalyticReaction->E_can_modify_S(
	    CE_info_ref => $CL_info_ref,
	    CS_info_ref => $CR_info_ref,
	   );
	$L_is_enzyme_flag = $L_is_enzyme_flag ? 1 : (CatalyticReaction->E_can_modify_S(
	    CE_info_ref => $CR_info_ref,
	    CS_info_ref => $CL_info_ref,
	   ) ? 0 : undef);

	return $L_is_enzyme_flag;
    }

    #--------------------------------------------------------------------------------------
    # Function: E_can_modify_S
    # Synopsys: Determine whether putative E can modify putative S.
    #--------------------------------------------------------------------------------------
    sub E_can_modify_S {
	my $class = shift;
	my %args = (
	    CE_info_ref => undef,
	    CS_info_ref => undef,
	    @_,
	   );

	check_args(\%args, 2);

	my $CE_info_ref = $args{CE_info_ref};
	my $CS_info_ref = $args{CS_info_ref};

	#-------------------------------------------------------------------------------
	# Call the ReactionSiteInstance can_modify() class method which will determine
	# whether E can modify S.
	#-------------------------------------------------------------------------------
	my ($reaction_sites_E_can_modify_S_flag, $kp) = ReactionSiteInstance->can_modify(
	    $CE_info_ref->get_site_ref(),
	    $CS_info_ref->get_site_ref(),
	   );

	return 0 if (!$reaction_sites_E_can_modify_S_flag);

	return 0 if is_numeric($kp) && is_numeric($kp_rate_cutoff) && ($kp <= $kp_rate_cutoff);

 	return 1;
    }

    #######################################################################################
    # INSTANCE METHODS
    #######################################################################################

    #--------------------------------------------------------------------------------------
    # Function: START
    # Synopsys: Piggybacks on the BindingReaction::START() routine, using the results to
    #           compute and align the modified substrate.  Also computes the product rate.
    #--------------------------------------------------------------------------------------
    sub START {
        my ($self, $obj_ID, $arg_ref) = @_;
	my $class = ref $self;

	# get BindingReaction
	my $binding_reaction_ref = $arg_ref->{binding_reaction_ref};
	if (!defined $binding_reaction_ref) {
	    # this case will happen if the initial starting species
	    # contained activated catalytic complexes
	    # (to support this the START() routine must compute dissociation products
	    # and modified substrate de novo instead of piggybacking on previously computed
	    # BindingReaction results)
	    confess "ERROR: NOT IMPLEMENTED -- did your initial species contain activated catalytic complexes?";
	}

	# get CE and CS
	my $CE_info_ref = $self->get_CE_info_ref();
	my $CS_info_ref = $self->get_CS_info_ref();
	my $C_species_ref = $C_species_ref_of{$obj_ID} = $CE_info_ref->get_species_ref();
	confess "ERROR: internal error, CE/CS are not the same species" if $C_species_ref != $CS_info_ref->get_species_ref();

	# get dE and dS
	my $dE_info_ref = ($L_is_enzyme_flag_of{$obj_ID} ?
			   $binding_reaction_ref->get_dL_info_ref() :
			   $binding_reaction_ref->get_dR_info_ref());
	my $dS_info_ref = ($L_is_enzyme_flag_of{$obj_ID} ?
			   $binding_reaction_ref->get_dR_info_ref() :
			   $binding_reaction_ref->get_dL_info_ref());

	# internal_dissociation_flag is found by looking at the binding reaction's internal_association_flag
	$internal_dissociation_flag_of{$obj_ID} = $binding_reaction_ref->get_internal_association_flag();

	# compute the product rate
	my $kp = ReactionSiteInstance->compute_catalytic_rate(
	    $CE_info_ref->get_site_ref(),
	    $CS_info_ref->get_site_ref(),
	   );

	# compute the modified species
	my $dS_species_ref = $dS_info_ref->get_species_ref();
	my $dS_class = ref $dS_species_ref;
	my $compute_modified_state_ref = $dS_class->compute_modified_substrate(
	    reaction_class => $class,
	    dS_info_ref => $dS_info_ref,
	   );

	my $qE_info_ref = $qE_info_ref_of{$obj_ID} = $dE_info_ref;
	my $qP_info_ref = $qP_info_ref_of{$obj_ID} = $compute_modified_state_ref->{qP_info_ref};

	my $qE_species_ref = $qE_info_ref->get_species_ref();
	my $qP_species_ref = $qP_info_ref->get_species_ref();

	# create the product reaction
	my $CL_info_ref = $CL_info_ref_of{$obj_ID};
	my $CR_info_ref = $CR_info_ref_of{$obj_ID};
	my $elementary_reaction_name = $class->compute_unique_reaction_name(
	    internal_flag => 1,
	    L_name => $CL_info_ref->get_species_ref()->get_name(),
	    L_address_ref => $CL_info_ref->get_site_address_ref(),
	    R_name => $CR_info_ref->get_species_ref()->get_name(),
	    R_address_ref => $CR_info_ref->get_site_address_ref(),

	   );
	my $pr_lookup_ref = ElementaryReaction->lookup_by_name("CR $elementary_reaction_name");  # CR stands for catalytic reaction
	if (!defined $pr_lookup_ref) {
	    # first time we have this product reaction
	    $product_reaction_of{$obj_ID} = ElementaryReaction->new({
		container_ref => $self,
		name => "CR $elementary_reaction_name",
		type => "MASS-ACTION",
		reactants_ref => [$C_species_ref],
		products_ref => [$qE_species_ref, $qP_species_ref],
		rate_constant => $kp,
	       });
	} else {
	    confess "ERROR: internal error, START() should not have run after reaction lookup in NEW()";
	}
    }

    sub get_CE_info_ref {
	my $self = shift;
	return ($L_is_enzyme_flag_of{ident $self} ?
		$self->get_CL_info_ref() :
		$self->get_CR_info_ref()
	       );
    }

    sub get_CS_info_ref {
	my $self = shift;
	return ($L_is_enzyme_flag_of{ident $self} ?
		$self->get_CR_info_ref() :
		$self->get_CL_info_ref()
	       );
    }

    #--------------------------------------------------------------------------------------
    # Function: get_new_species
    # Synopsys: 
    #--------------------------------------------------------------------------------------
    sub get_new_species {
	my $self = shift;
	my $obj_ID = ident($self);

	my @new_species = ();

	my $qP_species_ref = $qP_info_ref_of{$obj_ID}->get_species_ref();

	if ($qP_species_ref->get_is_new_flag()) {
	    push @new_species, $qP_species_ref;
	}

	return (@new_species);
    }

    #--------------------------------------------------------------------------------------
    # Function: export_equations
    # Synopsys: 
    #--------------------------------------------------------------------------------------
    sub export_equations {
	my $self = shift;
	my $class = ref $self;
	my $obj_ID = ident $self;

	my $CL_info_ref = $CL_info_ref_of{$obj_ID};
	my $CR_info_ref = $CR_info_ref_of{$obj_ID};

	my $C = $CL_info_ref->get_species_ref()->get_exported_name();
	my $E_species_ref = $qE_info_ref_of{$obj_ID}->get_species_ref();
	my $E = $E_species_ref->get_exported_name();
	my $P = $qP_info_ref_of{$obj_ID}->get_species_ref()->get_exported_name();

	my $kp = $self->get_product_reaction()->get_rate_constant();

	my $products = ($internal_dissociation_flag_of{$obj_ID}) ? "$P" : "$E + $P";

	my $result;
	my $L_is_enzyme_flag = $L_is_enzyme_flag_of{$obj_ID};

	# compile a list of all binding reactions associated with the complex
	my $elementary_reaction_name = $class->compute_unique_reaction_name(
	    internal_flag => 1,
	    L_name => $CL_info_ref->get_species_ref()->get_name(),
	    L_address_ref => $CL_info_ref->get_site_address_ref(),
	    R_name => $CR_info_ref->get_species_ref()->get_name(),
	    R_address_ref => $CR_info_ref->get_site_address_ref(),

	   );
	my @br_list = BindingReaction->get_instances();
	@br_list = grep {!$_->get_exported_flag() && $_->get_backward_reaction()->get_name() eq "BR $elementary_reaction_name"} @br_list;

	foreach my $br_ref (@br_list) {
	    $result .= $br_ref->export_equations($E_species_ref);
	    $br_ref->set_exported_flag(1);
	}

	my $prate_str = uniquify("kp","",$kp)."=$kp";

	my $name = ("(".$self->get_name().")");
	$result .= sprintf("%-43s  -> %-32s; %-30s # $name\n", $C, $products, $prate_str);

	return $result;
    }

    #--------------------------------------------------------------------------------------
    # Function: cmp
    # Synopsys: A compare routine to order two CatalyticReactions.
    #--------------------------------------------------------------------------------------
    sub cmp {
	my $class = shift;
	my $a = shift;
	my $b = shift;

	my ($a_E_ref, $b_E_ref) = ($a->get_qE_info_ref()->get_species_ref(), $b->get_qE_info_ref()->get_species_ref());
	my ($a_P_ref, $b_P_ref) = ($a->get_qP_info_ref()->get_species_ref(), $b->get_qP_info_ref()->get_species_ref());

	# internal reactions go last
	my ($a_internal, $b_internal) = ($a->get_internal_dissociation_flag(), $b->get_internal_dissociation_flag());
	return -1 if (!$a_internal &&  $b_internal);
	return  1 if ( $a_internal && !$b_internal);

	# at this point, always comparing internal with internal, or external with external, which
	# simplifies comparison below...

	my ($a_E_num, $b_E_num) = ($a_E_ref->get_num_elements(), $b_E_ref->get_num_elements());
	my ($a_P_num, $b_P_num) = ($a_P_ref->get_num_elements(), $b_P_ref->get_num_elements());

	my $a_min = $a_E_num < $a_P_num ? $a_E_num : $a_P_num;
	my $a_max = $a_E_num > $a_P_num ? $a_E_num : $a_P_num;
	my $b_min = $b_E_num < $b_P_num ? $b_E_num : $b_P_num;
	my $b_max = $b_E_num > $b_P_num ? $b_E_num : $b_P_num;

	# order on products size
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
	    # can't order on enzyme/product sizes, so order on enzyme/product and complex exported names
	    my $a_products = join(" ", ($a_E_ref->get_exported_name(), $a_P_ref->get_exported_name()));
	    my $a_complex = $a->get_C_species_ref->get_exported_name();
	    
	    my $b_products = join(" ", ($b_E_ref->get_exported_name(), $b_P_ref->get_exported_name()));
	    my $b_complex = $b->get_C_species_ref->get_exported_name();

	    if ($a_products lt $b_products) {
		return -1;
	    } elsif ($a_products gt $b_products) {
		return 1;
	    } elsif ($a_complex lt $b_complex) {
		return -1;
	    } elsif ($a_complex gt $b_complex) {
		return 1;
	    } else {
		# equations are the same
		return 0;
	    }
	}
    }

#    #--------------------------------------------------------------------------------------
#    # Function: xxx
#    # Synopsys: 
#    #--------------------------------------------------------------------------------------
#    sub xxx {
#	my $self = shift;
#    }
}


sub run_testcases {
    printn "NO TESTCASES!!!";
}


# Package BEGIN must return true value
return 1;

