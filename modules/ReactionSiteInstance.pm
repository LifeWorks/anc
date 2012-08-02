######################################################################################
# File:     ReactionSiteInstance.pm
# Author:   Julien F. Ollivier
#
# Copyright (C) 2005-2010 Julien Ollivier.
#
# This program comes with ABSOLUTELY NO WARRANTY.
# This is free software, and you are welcome to redistribute it
# under certain conditions. See file LICENSE.TXT for details.
#
# Synopsys: Instance of ReactionSite
######################################################################################
# Detailed Description:
# ---------------------
######################################################################################

use strict;
use diagnostics;		# equivalent to -w command-line switch
use warnings;

package ReactionSiteInstance;
use Class::Std::Storable;
use base qw(NodeInstance);
{
    use Carp;

    use Utils;
    use Globals;

    #######################################################################################
    # ATTRIBUTES
    #######################################################################################
    my %csite_bound_to_msite_flag_of :ATTR(get => 'csite_bound_to_msite_flag', default => 0);
    my %msite_state_of          :ATTR(get => 'msite_state');

    ###################################
    # ALLOWED ATTRIBUTE VALUES
    ###################################
    my @allowed_msite_states = (1, 0);

    #######################################################################################
    # FUNCTIONS
    #######################################################################################

    #######################################################################################
    # CLASS METHODS
    #######################################################################################

    #--------------------------------------------------------------------------------------
    # Function: can_bind
    # Synopsys: Given two ligands, determine if they bind.  This is determined by
    #           finding if a matching rule exists.
    #--------------------------------------------------------------------------------------
    sub can_bind {
	my $class = shift;
	my $L_site_ref = shift;
	my $R_site_ref = shift;
	my $internal_flag = shift;

	confess "ERROR: L_site_ref is not a ReactionSiteInstance" if !$L_site_ref->isa('ReactionSiteInstance');
	confess "ERROR: R_site_ref is not a ReactionSiteInstance" if !$R_site_ref->isa('ReactionSiteInstance');

	#--------------------------------------------
	# lookup binding rule
	#--------------------------------------------
	my $rule_ref = CanBindRule->lookup(
	    $L_site_ref,
	    $R_site_ref,
	    1,                # association_flag
	    $internal_flag,
	    0,                # use association_constraints
	   );
	return (0, undef) if (!defined $rule_ref);

	#--------------------------------------------
	# if both sites are of the same derived class
	# provide hook for this class to impose
	# additional conditions on binding
	#--------------------------------------------
	my $common_site_class = ref $L_site_ref;
	$common_site_class = $common_site_class eq ref $R_site_ref ? $common_site_class : undef;
	if (defined $common_site_class && $common_site_class ne "ReactionSiteInstance") {
	    return (0, undef) if !$common_site_class->can_bind(
		$L_site_ref,
		$R_site_ref,
		$internal_flag,
	       );
	}

	my $kf = $rule_ref->get_kf();
	my $steric_factor = $rule_ref->get_steric_factor();
	if ($internal_flag && ($steric_factor eq "UNDEF")) {
	    printn "ERROR: steric_factor is needed but undefined in CanBindRule with the attributes : ".$rule_ref->get_parent_ref()->_DUMP();
	    exit(1);
	}
	return  (1, $kf, $steric_factor);
    }

    #--------------------------------------------------------------------------------------
    # Function: can_unbind
    # Synopsys: Given two ligands, determine if they unbind.  This is determined by
    #           finding if a matching rule exists.
    #--------------------------------------------------------------------------------------
    sub can_unbind {
	my $class = shift;
	my $L_site_ref = shift;
	my $R_site_ref = shift;

	#--------------------------------------------
	# lookup binding rule
	#--------------------------------------------
	my $rule_ref = CanBindRule->lookup(
	    $L_site_ref,
	    $R_site_ref,
	    0,  # association_flag
	    1,  # internal_flag
	    1,  # use dissociation_constraints
	   );

	return (defined $rule_ref) ? (1, $rule_ref->get_kb()) : (0, undef);
    }

    #--------------------------------------------------------------------------------------
    # Function: can_modify
    # Synopsys: Given enzyme and substrate, determine if modification possible.
    #           RULES:
    #              i) E must be a csite, S must be an msite
    #             ii) A CanBindRule must exist giving a kp
    #--------------------------------------------------------------------------------------
    sub can_modify {
	my $class = shift;
	my $E_site_ref = shift;
	my $S_site_ref = shift;

	my $E_is_csite_and_S_is_msite_flag = (
	    ($E_site_ref->get_parent_ref()->get_type() eq "csite") &&
	    ($S_site_ref->get_parent_ref()->get_type() eq "msite")) ? 1 : 0;

	return (0, undef) if !$E_is_csite_and_S_is_msite_flag;

	my $rule_ref = CanBindRule->lookup(
	    $E_site_ref,
	    $S_site_ref,
	    0,  # association_flag
	    1,  # internal_flag
	    0,  # use association_constraints
	   );
	if (!defined $rule_ref) {
	    my $C_name = $E_site_ref->get_in_toplvl_object()->get_exported_name(); # always internal
	    croak "ERROR: internal error" if $C_name ne $S_site_ref->get_in_toplvl_object()->get_exported_name();
	    my $E_name = $E_site_ref->get_parent_ref()->get_name();
	    my $S_name = $S_site_ref->get_parent_ref()->get_name();
	    my $E_address = $E_site_ref->get_address_ref();
	    my $S_address = $S_site_ref->get_address_ref();
	    # N.b. Warning below can happen when enzyme is inactivated after binding substrate
	    printn "WARNING: can't find a CanBindRule allowing $E_name(@$E_address) to modify $S_name(@$S_address) in $C_name";
	    return (0, undef);
	}

	my $kp = $rule_ref->get_kp();
	if (!defined $kp) {
	    my $C_name = $E_site_ref->get_in_toplvl_object()->get_exported_name();
	    my $E_name = $E_site_ref->get_parent_ref()->get_name();
	    my $S_name = $S_site_ref->get_parent_ref()->get_name();
	    my $E_address = $E_site_ref->get_address_ref();
	    my $S_address = $S_site_ref->get_address_ref();
	    printn "WARNING: CanBindRule does not give kp rate for $E_name(@$E_address) modifying $S_name(@$S_address) in $C_name";
	    return (0, undef);
	}

	return (1, $kp);
    }

    #--------------------------------------------------------------------------------------
    # Function: compute_association_rate
    # Synopsys: Compute association rate given two ReactionSites by looking up
    #           appropriate rule.  If none exists, it is an error.
    #--------------------------------------------------------------------------------------
    sub compute_association_rate {
	my $class = shift;
	my $L_site_ref = shift;
	my $R_site_ref = shift;
	my $internal_flag = shift;

	if (!defined $L_site_ref || !defined $R_site_ref) {
	    croak "ERROR: arguments not defined\n";
	}

	#--------------------------------------------
	# lookup binding rule and if exists return rate
	#--------------------------------------------
	my $rule_ref = CanBindRule->lookup(
	    $L_site_ref,
	    $R_site_ref,
	    1,                 # association_flag
	    $internal_flag,
	    0,                 # use association_constraints
	   );
	if (defined $rule_ref) {
	    return ($rule_ref->get_kf(), $rule_ref->get_steric_factor());
	}

	#--------------------------------------------
	# can't find a rate, so ERROR
	#--------------------------------------------
	my $L_name = $L_site_ref->get_parent_ref->get_name();
	my $R_name = $R_site_ref->get_parent_ref->get_name();
	confess "ERROR: can't find a rule to compute forward rate between $L_name and $R_name";
    }

    #--------------------------------------------------------------------------------------
    # Function: compute_dissociation_rate
    # Synopsys: Compute dissociation rate given two ReactionSites by looking up
    #           appropriate rule.  If none exists, it is an error.
    #--------------------------------------------------------------------------------------
    sub compute_dissociation_rate {
	my $class = shift;
	my $L_site_ref = shift;
	my $R_site_ref = shift;

	if (!defined $L_site_ref || !defined $R_site_ref) {
	    croak "ERROR: arguments not defined\n";
	}

	#--------------------------------------------
	# lookup binding rule and if exists return rate
	#--------------------------------------------
	my $rule_ref = CanBindRule->lookup(
	    $L_site_ref,
	    $R_site_ref,
	    0,             # association_flag
	    1,             # internal_flag
	    1,             # use dissociation_constraints
	   );
	if (defined $rule_ref) {
	    return $rule_ref->get_kb();
	}

	#--------------------------------------------
	# can't find a rate, so ERROR
	#--------------------------------------------
	my $L_name = $L_site_ref->get_parent_ref->get_name();
	my $R_name = $R_site_ref->get_parent_ref->get_name();
	confess "ERROR: can't find a rule to compute forward rate between $L_name and $R_name";
    }

    #--------------------------------------------------------------------------------------
    # Function: compute_catalytic_rate
    # Synopsys: Compute product formation reaction rate given two ReactionSites by looking
    #           up the appropriate rule.  If none exists, it is an error.
    #--------------------------------------------------------------------------------------
    sub compute_catalytic_rate {
	my $class = shift;
	my $E_site_ref = shift;
	my $S_site_ref = shift;

	if (!defined $E_site_ref || !defined $S_site_ref) {
	    croak "ERROR: arguments not defined\n";
	}

	#--------------------------------------------
	# lookup binding rule and if exists return rate
	#--------------------------------------------
	my $rule_ref = CanBindRule->lookup(
	    $E_site_ref,
	    $S_site_ref,
	    0,             # association_flag
	    1,             # internal_flag
	    0,             # use association_constraints
	   );
	if (defined $rule_ref) {
	    return $rule_ref->get_kp();
	}

	#--------------------------------------------
	# can't find a rate, so ERROR
	#--------------------------------------------
	my $E_name = $E_site_ref->get_parent_ref->get_name();
	my $S_name = $S_site_ref->get_parent_ref->get_name();
	confess "ERROR: can't find a rule allowing $E_name to modify $S_name";
    }

    #--------------------------------------------------------------------------------------
    # Function: compute_binding_energy
    # Synopsys: Compute binding reaction energy given two ReactionSites by looking up
    #           appropriate rule.  If none exists, it is an error.
    #--------------------------------------------------------------------------------------
    sub compute_binding_energy {
	my $class = shift;
	my $L_site_ref = shift;
	my $R_site_ref = shift;

	if (!defined $L_site_ref || !defined $R_site_ref) {
	    croak "ERROR: arguments not defined\n";
	}

	#--------------------------------------------
	# lookup binding rule and if exists return rate
	#--------------------------------------------
	my $rule_ref = CanBindRule->lookup(
	    $L_site_ref,
	    $R_site_ref,
	    0,              # association_flag
	    1,              # internal_flag
	    -1,             # don't apply ad-hoc constraints
	   );
	if (defined $rule_ref) {
	    my $kf = $rule_ref->get_kf();
	    my $kb = $rule_ref->get_kb();
	    #my $sf = $rule_ref->get_steric_factor(),

	    my $Keq = (
		Variable->new({name => "KF", value => $kf}) /
		Variable->new({name => "KB", value => $kb})
	       );
	    return $Keq;
	}

	#--------------------------------------------
	# can't find a rate, so ERROR
	#--------------------------------------------
	my $L_name = $L_site_ref->get_parent_ref->get_name();
	my $L_state = $L_site_ref->get_allosteric_label();
	$L_state .= ",".$L_site_ref->get_msite_state() if $L_site_ref->get_type eq "msite";
	my $R_name = $R_site_ref->get_parent_ref->get_name();
	my $R_state = $R_site_ref->get_allosteric_label();
	$R_state .= ",".$R_site_ref->get_msite_state() if $R_site_ref->get_type eq "msite";
	issue_error "can't find a rule to compute binding energy between reaction sites $L_name($L_state) and $R_name($R_state)";
    }

    #######################################################################################
    # INSTANCE METHODS
    #######################################################################################
    #--------------------------------------------------------------------------------------
    # Function: BUILD
    # Synopsys:
    #--------------------------------------------------------------------------------------
    sub BUILD {
        my ($self, $obj_ID, $arg_ref) = @_;

	# default values
	if ($self->get_parent_ref()->get_type eq "msite") {
	    $self->set_msite_state(0);           # default to state 0
	} else {
	    $msite_state_of{ident $self} = 'x';  # if it's not an msite, set to X
	}
    }

    #--------------------------------------------------------------------------------------
    # Function: is_self_binding
    # Synopsys: Determine if ReactionSiteInstance is self-binding
    #--------------------------------------------------------------------------------------
    sub is_self_binding {
	my $self = shift;

	return ReactionSiteInstance->can_bind(
	    $self,
	    $self,
	    0,       # internal_flag
	   ) ? 1 : 0;
    }

    #--------------------------------------------------------------------------------------
    # Function: set_csite_bound_to_msite_flag
    # Synopsys: Method checks that type is msite before setting
    #--------------------------------------------------------------------------------------
    sub set_csite_bound_to_msite_flag {
	my $self = shift;
	my $flag = shift;
	
	confess "ERROR: you can only call this function on csite" if $self->get_type ne "csite";
	
	return $csite_bound_to_msite_flag_of{ident $self} = $flag;
    }

    #--------------------------------------------------------------------------------------
    # Function: set_msite_state
    # Synopsys: 
    #--------------------------------------------------------------------------------------
    sub set_msite_state {
	my $self = shift;
	my $msite_state = shift;
	
	croak "Can't set msite_state to $msite_state\n" if ((grep /$msite_state/, @allowed_msite_states) != 1);
	if ($self->get_parent_ref->get_type() eq "msite") {
	    $msite_state_of{ident $self} = $msite_state;
	}
    }

    #--------------------------------------------------------------------------------------
    # Function: flip_msite_state
    # Synopsys: 
    #--------------------------------------------------------------------------------------
    sub flip_msite_state {
	my $self = shift;

	my $state = $self->get_msite_state();
	$state = ($state eq "0") ? "1" : "0";
	$self->set_msite_state($state);
    }

    #--------------------------------------------------------------------------------------
    # Function: get_allosteric_state
    # Synopsys: Inherit allosteric label from allosterically coupled nodes.
    #--------------------------------------------------------------------------------------
    sub get_allosteric_state {
	my $self = shift;

	my @coupled_site_refs = ();

	# get address of node
	my @address = @{$self->get_address_ref()};
	my $complex_instance_ref = $self->get_in_toplvl_object();
	my $ungrouped_address = $complex_instance_ref->get_node_ungrouped_address(@address);

	# get allosteric fanout of node
	# n.b. important to get this from "ungrouped" graph, to ensure order is defined by order of elements
	#      in the structure definition and not by the order after canonical re-arrangements
	my ($fanout_addresses_ref, $fanout_edges_ref) = $complex_instance_ref->get_node_fanout("ungrouped",'~',$ungrouped_address);
	my $fanout_nodes_ref = [map {$complex_instance_ref->get_nodes_ref()->{ungrouped}->[$_->[0]]} @$fanout_addresses_ref];

	push @coupled_site_refs, @$fanout_nodes_ref;

	my $allosteric_state = "";
	for (my $i=0; $i < @coupled_site_refs; $i++) {
	    # site ref
	    my $site_ref = $coupled_site_refs[$i];
	    confess "ERROR: internal error -- coupled site should be an allosteric node" if (!$site_ref->isa('AllostericSiteInstance'));

	    # label
	    $allosteric_state .= $site_ref->get_allosteric_state();

	}
	return $allosteric_state;
    }
    #--------------------------------------------------------------------------------------
    # Function: get_allosteric_label
    # Synopsys: Inherit allosteric label from allosterically coupled nodes.
    #--------------------------------------------------------------------------------------
    sub get_allosteric_label {
	my $self = shift;

	my @coupled_site_refs = ();

	# get address of node
	my @address = @{$self->get_address_ref()};
	my $complex_instance_ref = $self->get_in_toplvl_object();
	my $ungrouped_address = $complex_instance_ref->get_node_ungrouped_address(@address);

	# get allosteric fanout of node
	# n.b. important to get this from "ungrouped" graph, to ensure order is defined by order of elements
	#      in the structure definition and not by the order after canonical re-arrangements
	my ($fanout_addresses_ref, $fanout_edges_ref) = $complex_instance_ref->get_node_fanout("ungrouped",'~',$ungrouped_address);
	my $fanout_nodes_ref = [map {$complex_instance_ref->get_nodes_ref()->{ungrouped}->[$_->[0]]} @$fanout_addresses_ref];

	push @coupled_site_refs, @$fanout_nodes_ref;

	my $allosteric_label = "";
	for (my $i=0; $i < @coupled_site_refs; $i++) {
	    # site ref
	    my $site_ref = $coupled_site_refs[$i];
	    confess "ERROR: internal error -- coupled site should be an allosteric node" if (!$site_ref->isa('AllostericSiteInstance'));

	    # label
	    $allosteric_label .= $site_ref->get_allosteric_label();

	}
	return $allosteric_label;
    }

    #--------------------------------------------------------------------------------------
    # Function: get_ligand
    # Synopsys: 
    #--------------------------------------------------------------------------------------
    sub get_ligand {
	my $self = shift;

	my $address_ref = $self->get_address_ref();
	my $top_ref = $self->get_in_toplvl_object();
	my $ligand_address_ref = ($top_ref->get_node_fanout("primary", ':', $address_ref))[0]->[0];
	my $ligand_ref = defined $ligand_address_ref ? $top_ref->get_node_by_address($ligand_address_ref) : undef;
	return $ligand_ref;
    }

    #--------------------------------------------------------------------------------------
    # Function: is_bound
    # Synopsys: 
    #--------------------------------------------------------------------------------------
    sub is_bound {
	my $self = shift;

	my $ligand_ref = $self->get_ligand();
	return defined $ligand_ref ? 1 : 0;
    }

    #--------------------------------------------------------------------------------------
    # Function: clone_state
    # Synopsys: Clone ReactionSiteInstance attributes of argument.
    #--------------------------------------------------------------------------------------
    sub clone_state : CUMULATIVE(BASE FIRST) {
	my ($self, $src_ref) = @_;

	confess "ERROR: internal error -- $src_ref must be a derived class of $self" if !$src_ref->isa(ref $self);
	# this error probably means the mapping used for cloning is messed up
	confess "ERROR: internal error -- parent refs are not the same" if ($self->get_parent_ref() != $src_ref->get_parent_ref());

	$self->set_msite_state($src_ref->get_msite_state()) if ($self->get_type() eq 'msite');

	# !!!!  this is a hack, should not have to check this !!!
	if ($self->isa('ReactionSiteInstance')) {
	    $self->set_csite_bound_to_msite_flag($src_ref->get_csite_bound_to_msite_flag()) if ($self->get_type() eq 'csite');
	}
    }

    #--------------------------------------------------------------------------------------
    # Function: sprint_state
    # Synopsys: 
    #--------------------------------------------------------------------------------------
    sub sprint_state {
	my $self = shift;

	return $self->get_msite_state();
    }
}


sub run_testcases {
    printn "NO TESTCASES!!!";
}


# Package BEGIN must return true value
return 1;

