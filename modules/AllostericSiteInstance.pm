######################################################################################
# File:     AllostericSiteInstance.pm
# Author:   Julien F. Ollivier
#
# Copyright (C) 2005-2010 Julien Ollivier.
#
# This program comes with ABSOLUTELY NO WARRANTY.
# This is free software, and you are welcome to redistribute it
# under certain conditions. See file LICENSE.TXT for details.
#
# Synopsys: Instance of AllostericSite
######################################################################################
# Detailed Description:
# ---------------------
######################################################################################

use strict;
use diagnostics;		# equivalent to -w command-line switch
use warnings;

package AllostericSiteInstance;
use Class::Std::Storable;
use base qw(NodeInstance);
{
    use Carp;

    use Utils;
    use Globals;

    #######################################################################################
    # ATTRIBUTES
    #######################################################################################
    my %allosteric_state_of          :ATTR(get => 'allosteric_state', default => "R");

    # The configuration consists of several lists of length equal to the number of
    # sites coupled to the allosteric node and giving information about the coupled sites.
    # The configuration can be used to look up cached transition rates in the parent's
    # allosteric_transition_rate_table.
    my %configuration_ref_of          :ATTR(set => 'configuration_ref');

    ###################################
    # ALLOWED ATTRIBUTE VALUES
    ###################################
    my @allowed_allosteric_states = ('R', 'T');

    #######################################################################################
    # FUNCTIONS
    #######################################################################################

    #######################################################################################
    # METHODS
    #######################################################################################

    #######################################################################################
    # CLASS METHODS
    #######################################################################################

    #--------------------------------------------------------------------------------------
    # Function: compute_unary_rates
    # Synopsys: Compute forward/backward rates for R/T<->T/R transition
    #--------------------------------------------------------------------------------------
    sub compute_unary_rates {
	my $class = shift;
	my $S_site_ref = shift;
	my $P_site_ref = shift;
	my $S2P_instance_mapping_ref = shift;

	my ($forward_rate, $backward_rate) = $S_site_ref->compute_allosteric_transition_rates(
	    $P_site_ref,
	    $S2P_instance_mapping_ref,
	   );

	confess "ERROR: internal error -- forward rate not defined" if !defined $forward_rate;
	confess "ERROR: internal error -- backward rate not defined" if !defined $backward_rate;

	return ($forward_rate, $backward_rate);
    }

    #######################################################################################
    # INSTANCE METHODS
    #######################################################################################
    #--------------------------------------------------------------------------------------
    # Function: can_change_state
    # Synopsys: Determine if an allosteric state change is possible.  RULES:
    #              i) always possible
    #--------------------------------------------------------------------------------------
    sub can_change_state {
	my $class = shift;
	my $S_site_ref = shift;

	return 1;
    }

    #--------------------------------------------------------------------------------------
    # Function: get_allosteric_label
    # Synopsys: Map allosteric state to corresponding label.
    #--------------------------------------------------------------------------------------
    sub get_allosteric_label {
	my $self = shift;
	my $obj_ID = ident $self;

	my $state = $allosteric_state_of{$obj_ID};
	if ($state eq 'R') {
	    return $self->get_parent_ref()->get_allosteric_state_labels()->[0];
	} elsif ($state eq 'T') {
	    return $self->get_parent_ref()->get_allosteric_state_labels()->[1];
	} else {
	    croak "ERROR: internal error -- allosteric state must be R or T";
	}
    }

    #--------------------------------------------------------------------------------------
    # Function: set_allosteric_state
    # Synopsys: Check that state being set is allowed.
    #--------------------------------------------------------------------------------------
    sub set_allosteric_state {
	my $self = shift;
	my $allosteric_state = shift;
	
	croak "Can't set allosteric_state to $allosteric_state\n" if ((grep /$allosteric_state/, @allowed_allosteric_states) != 1);

	$allosteric_state_of{ident $self} = $allosteric_state;
    }

    #--------------------------------------------------------------------------------------
    # Function: flip_allosteric_state
    # Synopsys: R <-> T
    #--------------------------------------------------------------------------------------
    sub flip_allosteric_state {
	my $self = shift;

	my $state = $self->get_allosteric_state();
	$state = ($state eq "R") ? "T" : "R";
	$self->set_allosteric_state($state);
    }

    #--------------------------------------------------------------------------------------
    # Function: clone_state
    # Synopsys: Clone AllostericSiteInstance attributes of argument.
    #--------------------------------------------------------------------------------------
    sub clone_state : CUMULATIVE(BASE FIRST) {
	my ($self, $src_ref) = @_;

	$self->set_allosteric_state($src_ref->get_allosteric_state());
    }

    #--------------------------------------------------------------------------------------
    # Function: get_configuration_ref
    # Synopsys: Generate (if necessary), store and return configuration.
    #--------------------------------------------------------------------------------------
    # The configuration consists of several lists of length equal to the number of
    # sites coupled to the allosteric node.  The lists are:
    #    coupled_site_refs:        ref of coupled site
    #    coupled_site_states:      state of coupled site
    #    coupled_site_ligands      ligand of coupled site
    #    coupled_site_reg_factors  reg_factor of coupled site (if an allosteric site or msite)
    #    coupled_site_phi_values   phi-values of coupled site
    #    coupled_site_index_map    maps grouped address into index of coupled_site arrays
    #--------------------------------------------------------------------------------------
    sub get_configuration_ref {
	my $self = shift;
	my $obj_ID = ident $self;

	if (!exists $configuration_ref_of{$obj_ID}) {
	    # compute the configuration
	    my @coupled_site_refs = ();
	    my @coupled_site_states = ();
	    my @coupled_site_ligands = ();
	    my @coupled_site_reg_factors = ();
	    my @coupled_site_phi_values = ();
	    my %coupled_site_index_map = (); # maps an address to an index

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
	    for (my $i=0; $i < @coupled_site_refs; $i++) {
		# site ref
		my $site_ref = $coupled_site_refs[$i];

		# state
		push @coupled_site_states, $site_ref->sprint_state();

		if ($site_ref->isa('AllostericSiteInstance')) {
		    # no ligands
		    push @coupled_site_ligands, undef;
		    # reg_factor & phi_value
		    my $edge = $fanout_edges_ref->[$i];
		    $edge =~ /.*{(.*)\|(.*)}/;
		    my $reg_factor = $1;
		    my $phi_value = $2;
		    confess "ERROR: internal error -- failed to extract reg_factor" if !defined $reg_factor;
		    confess "ERROR: internal error -- failed to extract phi-value" if !defined $phi_value;
		    push @coupled_site_reg_factors, $reg_factor;
		    push @coupled_site_phi_values, $phi_value;
		    # index map
		    $coupled_site_index_map{join ",", @{$site_ref->get_address_ref()}} = $i;
		} elsif ($site_ref->isa('ReactionSiteInstance')) {
		    # find all ligands bound to coupled site
		    my $site_address_ref = $site_ref->get_address_ref();
		    my $fanout_addresses_ref = ($complex_instance_ref->get_node_fanout("primary",':',$site_address_ref))[0];
		    if (@$fanout_addresses_ref > 0) {
			confess "ERROR: expected only one fanout" if (@$fanout_addresses_ref > 1);
			my $ligand_ref = $complex_instance_ref->get_node_by_address($fanout_addresses_ref->[0]);
			push @coupled_site_ligands, $ligand_ref;
		    } else {
			push @coupled_site_ligands, undef;
		    }
		    # reg_factor & phi_value
		    my $edge = $fanout_edges_ref->[$i];
		    $edge =~ /.*{(.*)\|(.*)}/;
		    my $reg_factor = $1;
		    my $phi_value = $2;
		    if ($site_ref->get_type() eq "msite") {
			confess "ERROR: internal error -- failed to extract reg_factor for msite" if !defined $reg_factor;
			push @coupled_site_reg_factors, $reg_factor;
		    } else {
			push @coupled_site_reg_factors, undef;
		    }
		    confess "ERROR: internal error -- failed to extract phi-value" if !defined $phi_value;
		    push @coupled_site_phi_values, $phi_value;
		    # index map
		    $coupled_site_index_map{join ",", @{$site_ref->get_address_ref()}} = $i;
		} else {
		    my $site_class = ref $site_ref;
		    confess "ERROR: internal error -- don't know what to do with coupled site of class $site_class";
		}
	    }

	    # store the configuration
	    my $num_coupled_sites = @coupled_site_refs;
	    confess "ERROR: internal error (not enough states)" if $num_coupled_sites != @coupled_site_states;
	    confess "ERROR: internal error (not enough ligands)" if $num_coupled_sites != @coupled_site_ligands;
	    confess "ERROR: internal error (not enough reg_factors)" if $num_coupled_sites != @coupled_site_reg_factors;
	    confess "ERROR: internal error (not enough phi values)" if $num_coupled_sites != @coupled_site_phi_values;
	    # if a coupled site has multiple links then the index map will contain fewer entries
	    $configuration_ref_of{$obj_ID}{coupled_site_refs} = \@coupled_site_refs;
	    $configuration_ref_of{$obj_ID}{coupled_site_states} = \@coupled_site_states;
	    $configuration_ref_of{$obj_ID}{coupled_site_ligands} = \@coupled_site_ligands;
	    $configuration_ref_of{$obj_ID}{coupled_site_reg_factors} = \@coupled_site_reg_factors;
	    $configuration_ref_of{$obj_ID}{coupled_site_phi_values} = \@coupled_site_phi_values;
	    $configuration_ref_of{$obj_ID}{coupled_site_index_map} = \%coupled_site_index_map;
	}

	# return
	return $configuration_ref_of{$obj_ID};
    }

    #--------------------------------------------------------------------------------------
    # Function: sprint_configuration
    # Synopsys: Returns allosteric context in the form
    #                         "(HEMO.R)x.x{}[L.x]y.x{5|0.2}[]z.x{10}[]",
    #           This gives the parent name and state, then for each coupled site, its name,
    #           state, reg_factor and phi-value as name.state{gamma|phi}, then the
    #           name/state of the coupled site's ligand in []s.
    #--------------------------------------------------------------------------------------
    sub sprint_configuration {
	my $self = shift; my $obj_ID = ident $self;

	my $configuration_ref = $self->get_configuration_ref();

	my @coupled_site_refs = @{$configuration_ref->{coupled_site_refs}};
	my $coupled_site_states_ref = $configuration_ref->{coupled_site_states};
	my $coupled_site_ligands_ref = $configuration_ref->{coupled_site_ligands};
	my @coupled_site_reg_factors = @{$configuration_ref->{coupled_site_reg_factors}};
	my @coupled_site_phi_values = @{$configuration_ref->{coupled_site_phi_values}};

	my $parent_name = $self->get_parent_ref()->get_name();
	my $sprint="(${parent_name}:".$self->sprint_state().")";
	for (my $i=0; $i < @coupled_site_refs; $i++) {
	    my $coupled_site_ref = $coupled_site_refs[$i];
	    my $coupled_site_name = $coupled_site_ref->get_parent_ref()->get_name();
	    my $coupled_site_state = $coupled_site_states_ref->[$i];
	    my $coupled_site_ligand_ref = $coupled_site_ligands_ref->[$i];
	    my $coupled_site_reg_factor = $coupled_site_reg_factors[$i];
	    my $coupled_site_phi_value = $coupled_site_phi_values[$i];

	    if (defined $coupled_site_reg_factor) {
 		$sprint .= "$coupled_site_name.$coupled_site_state\{$coupled_site_reg_factor|$coupled_site_phi_value\}";
	    } else {
 		$sprint .= "$coupled_site_name.$coupled_site_state\{|$coupled_site_phi_value\}";
	    }

	    if (defined $coupled_site_ligand_ref) {
		my $allosteric_state = $coupled_site_ligand_ref->get_allosteric_state();
		my $allosteric_state_string = defined $allosteric_state ? "/$allosteric_state" : "";
		# this gives e.g. "[HEMO.1/R] or [HEMO.0]
		$sprint .= ('['.$coupled_site_ligand_ref->get_parent_ref()->get_name().
			    '.'.$coupled_site_ligand_ref->sprint_state().
			    $allosteric_state_string.
			    ']');
	    } else {
		$sprint .= '[]';
	    }
	}
	return $sprint;
    }

    #--------------------------------------------------------------------------------------
    # Function: compute_allosteric_transition_rates
    # Synopsys: 
    #--------------------------------------------------------------------------------------
    sub compute_allosteric_transition_rates {
	my $self = shift;
	my $S_site_ref = $self;  my $S_obj_ID = ident $S_site_ref;
	my $P_site_ref = shift;  my $P_obj_ID = ident $P_site_ref;

	# N.b. you cannot assume here that the mapping between S and P is 1-to-1, both for
	# the allosteric site and coupled sites.
	my $S2P_instance_mapping_ref = shift;

	# DO SOME ERROR CHECKING ON ARGUMENTS
	my $S_in_object_parent_ref = $S_site_ref->get_in_object()->get_parent_ref();
	my $P_in_object_parent_ref = $P_site_ref->get_in_object()->get_parent_ref();
	if ($S_in_object_parent_ref != $P_in_object_parent_ref) {
	    confess "ERROR: internal error -- S and P not components of the same structure";
	}

#my $S_config_string = $S_site_ref->sprint_configuration();
#my $P_config_string = $P_site_ref->sprint_configuration();
#use Data::Dumper;
#printn $S_config_string;
#printn $P_config_string;
#printn $S_site_ref->get_in_toplvl_object()->get_exported_name() ." -> ".$P_site_ref->get_in_toplvl_object()->get_exported_name();
#printn join(",",@{$S_site_ref->get_address_ref()}) . " -> " . join(",",@{$P_site_ref->get_address_ref()});

	my $S_is_R_flag = $S_site_ref->get_allosteric_state() eq 'R' ? 1 : 0;
	my $P_is_R_flag = $P_site_ref->get_allosteric_state() eq 'R' ? 1 : 0;
	confess "ERROR: internal error -- both domains are in R state" if ($S_is_R_flag && $P_is_R_flag);
	confess "ERROR: internal error -- both domains are in T state" if (!$S_is_R_flag && !$P_is_R_flag);

	my $S_configuration_ref = $S_site_ref->get_configuration_ref();
	my $P_configuration_ref = $P_site_ref->get_configuration_ref();

	# n.b. kinetic regulatory factors for R<->T, not S<->P
	my $RT_reg_factor_product = 1;
	my $TR_reg_factor_product = 1;

	my @S_coupled_site_refs = @{$S_configuration_ref->{coupled_site_refs}};
	my @P_coupled_site_refs = @{$P_configuration_ref->{coupled_site_refs}};
	for (my $i = 0; $i < @S_coupled_site_refs; $i++) {
	    my $S_coupled_site_ref = $S_coupled_site_refs[$i];
	    # contribution of msite state or allosteric state to R<->T equilibrium
	    if (($S_coupled_site_ref->isa("ReactionSiteInstance") &&
		 $S_coupled_site_ref->get_type() eq "msite" &&
		 $S_coupled_site_ref->get_msite_state() == 1) ||
		 ($S_coupled_site_ref->isa("AllostericSiteInstance") &&
		  $S_coupled_site_ref->get_allosteric_state() eq 'T')) {
		my $reg_factor = $S_configuration_ref->{coupled_site_reg_factors}->[$i];
		my $RT_phi = $S_configuration_ref->{coupled_site_phi_values}->[$i];
		my $RT_phi_minus_one = Variable->new({name => "RT_phi", value => $RT_phi}) - Variable->new({name => "ONE", value => 1});
		my $RT_reg_factor = (
		    Variable->new({name => "REG_FACTOR", value => $reg_factor}) **
		    Variable->new({name => "RTx_PHI", value => $RT_phi})
		   );
		my $TR_reg_factor = (
		    Variable->new({name => "REG_FACTOR", value => $reg_factor}) **
		    Variable->new({name => "RT_PHI_MINUS_ONE", value => $RT_phi_minus_one})
		   );
		$RT_reg_factor_product = (
		    Variable->new({name => "RT_REG_FACTOR_PRODUCT", value => $RT_reg_factor_product}) *
		    Variable->new({name => "RT_REG_FACTOR", value => $RT_reg_factor})
		   );
		$TR_reg_factor_product = (
		    Variable->new({name => "TR_REG_FACTOR_PRODUCT", value => $TR_reg_factor_product}) *
		    Variable->new({name => "TR_REG_FACTOR", value => $TR_reg_factor})
		   );
	    }

	    # contribution of binding to R<->T equilibrium
	    # (n.b. here the S to P mapping is important)
	    my $S_ligand_ref = $S_configuration_ref->{coupled_site_ligands}->[$i];
	    if (defined $S_ligand_ref) {
		my $S_coupled_site_address_ref = $S_coupled_site_ref->get_address_ref();
		my $P_coupled_site_address_ref = HiGraph->remap_node_address($S2P_instance_mapping_ref, $S_coupled_site_address_ref);
		my $ii = $P_configuration_ref->{coupled_site_index_map}{join ",",@$P_coupled_site_address_ref};
		
		my $P_ligand_ref = $P_configuration_ref->{coupled_site_ligands}->[$ii];
		my $P_coupled_site_ref = $P_coupled_site_refs[$ii];
		
		# sanity check on coupled site
		confess "ERROR: internal error -- different site names" if ($S_coupled_site_ref->get_parent_ref->get_name() ne
									    $P_coupled_site_ref->get_parent_ref->get_name());
		confess "ERROR: internal error -- different site states" if ($S_coupled_site_ref->sprint_state() ne
									     $P_coupled_site_ref->sprint_state());
		# sanity check on coupled site
		confess "ERROR: internal error -- different ligand names" if ($S_ligand_ref->get_parent_ref->get_name() ne
									      $P_ligand_ref->get_parent_ref->get_name());
		confess "ERROR: internal error -- different ligand states" if ($S_ligand_ref->sprint_state() ne
									       $P_ligand_ref->sprint_state());

		my $KeqS = ReactionSiteInstance->compute_binding_energy($S_coupled_site_ref, $S_ligand_ref);
		my $KeqP = ReactionSiteInstance->compute_binding_energy($P_coupled_site_ref, $P_ligand_ref);

		my $reg_factor;
		if ($S_is_R_flag) {
		    $reg_factor = (
			Variable->new({name => "KEQP", value => $KeqP}) /
			Variable->new({name => "KEQS", value => $KeqS})
		       );
		} else {
		    $reg_factor = (
			Variable->new({name => "KEQS", value => $KeqS}) /
			Variable->new({name => "KEQP", value => $KeqP})
		       );
		}
		my $RT_phi = $S_configuration_ref->{coupled_site_phi_values}->[$i];
		my $RT_phi_minus_one = Variable->new({name => "RT_phi", value => $RT_phi}) - Variable->new({name => "ONE", value => 1});
		my $RT_reg_factor = (
		    Variable->new({name => "REG_FACTOR", value => $reg_factor}) **
		    Variable->new({name => "RTx_PHI", value => $RT_phi})
		   );
		my $TR_reg_factor = (
		    Variable->new({name => "REG_FACTOR", value => $reg_factor}) **
		    Variable->new({name => "RT_PHI_MINUS_ONE", value => $RT_phi_minus_one})
		   );
		$RT_reg_factor_product = (
		    Variable->new({name => "RT_REG_FACTOR_PRODUCT", value => $RT_reg_factor_product}) *
		    Variable->new({name => "RT_REG_FACTOR", value => $RT_reg_factor})
		   );
		$TR_reg_factor_product = (
		    Variable->new({name => "TR_REG_FACTOR_PRODUCT", value => $TR_reg_factor_product}) *
		    Variable->new({name => "TR_REG_FACTOR", value => $TR_reg_factor})
		   );
	    }
	}

	my ($base_RT_rate, $base_TR_rate) = @{$self->get_allosteric_transition_rates()};
	my $base_SP_rate = $S_is_R_flag ? $base_RT_rate : $base_TR_rate;
	my $base_PS_rate = $S_is_R_flag ? $base_TR_rate : $base_RT_rate;
	my ($SP_rate_factor, $PS_rate_factor) = ($S_is_R_flag ?
						 ($RT_reg_factor_product, $TR_reg_factor_product) :
						 ($TR_reg_factor_product, $RT_reg_factor_product));
	
	my ($SP_rate, $PS_rate);
	# $base_SP_rate * ($reg_factor_product ** $SP_phi)
	$SP_rate = (
	    Variable->new({name => "BASE_SP_RATE", value => $base_SP_rate}) *
	    Variable->new({name => "SP_RATE_FACTOR", value => $SP_rate_factor})
	   );
	# $base_PS_rate * ($reg_factor_product ** $SP_phi_minus_one)
	$PS_rate = (
	    Variable->new({name => "BASE_PS_RATE", value => $base_PS_rate}) *
	    Variable->new({name => "PS_RATE_FACTOR", value => $PS_rate_factor})
	   );

	confess "ERROR: internal error -- SP_rate not defined" if !defined $SP_rate;
	confess "ERROR: internal error -- PS_rate not defined" if !defined $PS_rate;

	return ($SP_rate, $PS_rate);
    }

    #--------------------------------------------------------------------------------------
    # Function: sprint_state
    # Synopsys: 
    #--------------------------------------------------------------------------------------
    sub sprint_state {
	my $self = shift;

	my $state = $self->get_allosteric_state();
	my @labels = @{$self->get_parent_ref()->get_allosteric_state_labels()};

	return $state eq 'R' ? $labels[0] : $labels[1];
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

}


# Package BEGIN must return true value
return 1;

