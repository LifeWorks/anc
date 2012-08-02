######################################################################################
# File:     ComplexInstance.pm
# Author:   Julien F. Ollivier
#
# Copyright (C) 2005-2010 Julien Ollivier.
#
# This program comes with ABSOLUTELY NO WARRANTY.
# This is free software, and you are welcome to redistribute it
# under certain conditions. See file LICENSE.TXT for details.
#
# Synopsys: Instance of Complex
######################################################################################
# Detailed Description:
# ---------------------
######################################################################################

use strict;
use diagnostics;		# equivalent to -w command-line switch
use warnings;

package ComplexInstance;
use Class::Std::Storable;
use base qw(StructureInstance Species);
{
    use Carp;

    use Utils;
    use Globals qw($verbosity $compact_names $protein_separator);

    #######################################################################################
    # CLASS ATTRIBUTES
    #######################################################################################
    ComplexInstance->set_class_data("ELEMENT_CLASS", "StructureInstance,AllostericStructureInstance");

    #######################################################################################
    # ATTRIBUTES
    #######################################################################################
    my %csite_bound_to_msite_number_of :ATTR(set => 'csite_bound_to_msite_number');

    #######################################################################################
    # FUNCTIONS
    #######################################################################################

    #######################################################################################
    # CLASS METHODS
    #######################################################################################
    #--------------------------------------------------------------------------------------
    # Function: compute_association_complex
    # Synopsys: Compute the ComplexInstance resulting from an association
    #--------------------------------------------------------------------------------------
    sub compute_association_complex {
	my $class = shift;

	my $parent_class = $class;
	$parent_class =~ s/Instance$//;

	my %args = (
	    reaction_class => undef,
	    dL_info_ref => undef,   # L could be LL or DL depending on internal_association_flag
	    dR_info_ref => undef,   # R could be LR or DR
	    internal_association_flag => undef,
	    @_,
	   );
	check_args(\%args, 4);

	# my $reaction_class = $args{reaction_class};
	my $dL_info_ref = $args{dL_info_ref};  # L/R SiteInfo objects
	my $dR_info_ref = $args{dR_info_ref};
	my $internal_association_flag = $args{internal_association_flag};

	my $dL_species_ref = $dL_info_ref->get_species_ref();
	my $dR_species_ref = $dR_info_ref->get_species_ref();
	my $dL_addr_ref = $dL_info_ref->get_site_address_ref();
	my $dR_addr_ref = $dR_info_ref->get_site_address_ref();

	######################################################################
	printn "COMPUTE OBJECT GRAPH AND FIND ISOMORPH" if ($verbosity >=3);
	######################################################################
	# name of parent complex is sorted list of its elements
	my $temp_name = (($internal_association_flag) ?
			 join("-", sort map($_->get_name(), ($dL_species_ref->get_parent_ref()->get_elements()))) :
			 join("-", sort map($_->get_name(), ($dL_species_ref->get_parent_ref()->get_elements(), $dR_species_ref->get_parent_ref()->get_elements())))
			);

	my $temp_ref = $parent_class->new({name => $temp_name, UNREGISTERED => 1});

	# n.b. the complex has no group node, therefore we don't need
	#      to call HiGraph wrapper when adding edges
	if (!$internal_association_flag) {
	    $temp_ref->concat(refs => [$dL_species_ref->get_parent_ref(), $dR_species_ref->get_parent_ref()]);
	    $temp_ref->Graph::offset_bi_edge_join($dL_addr_ref, $dR_addr_ref,
						  ":",  # !!! edge type, hard-coded ???
						  $dL_species_ref->get_parent_ref()->get_graph_size(),
						 );
	} else {
	    $temp_ref->concat(refs => [$dL_species_ref->get_parent_ref()]);
	    $temp_ref->Graph::add_bi_edge($dL_addr_ref,
				   $dR_addr_ref,
				   ":",  # !!! edge type, hard-coded ???
				  );
	}

	printn $temp_ref->sprint_graph_matrix() if ($verbosity >=3);

	my $dL_size = $dL_species_ref->get_graph_size();
	my $dR_size = $dR_species_ref->get_graph_size();

	my ($C_ref, $C2I_mapping_ref) = $parent_class->align_or_register($temp_ref);
	my $C_isomorph_exists_flag = (defined $C2I_mapping_ref) ? 1 : 0;

	if ($C_isomorph_exists_flag) {
	    # Isomorph found
	    $C2I_mapping_ref = HiGraph->regroup_mapping($temp_ref, $C_ref, $C2I_mapping_ref)
	} else {
	    # No isomorph found
	    $C_ref->update_putative_isomorph_hash();
	    # one-one mapping if no isomorph
	    $C2I_mapping_ref = [map {[$_]} (0..$C_ref->get_graph_size()-1)];
	    # do sanity check on the new complex
	    $C_ref->check();
	}

	# now compute mapping of ligands to complex   (!!! necessary ???)
	my ($dL2C_mapping_ref, $dR2C_mapping_ref) = (($internal_association_flag) ?
						     ($C2I_mapping_ref, $C2I_mapping_ref) :
						     RegisteredGraph->split_mapping($C2I_mapping_ref, $dL_size, $dR_size)
						    );

	
	if ($verbosity >= 3) {
	    printn "new complex graph and mapping:";
	    printn "name = ".$C_ref->get_name();
	    printn $C_ref->sprint_graph_matrix();
	    printn "dL2C_mapping = @$dL2C_mapping_ref";
	    printn "dR2C_mapping = @$dR2C_mapping_ref";
	    printn "new complex elements: ". join ",",(map($_->get_name(), $C_ref->get_elements));
	}

	#######################################################
	printn "COMPUTE OBJECT-INSTANCE GRAPH AND FIND ISOMORPH" if ($verbosity >=3);
	#######################################################
	my $temp_instance_ref = $C_ref->new_object_instance({
	    UNREGISTERED => 1,
	    DONT_INSTANTIATE_COMPONENTS => 1,
	});
	my $temp_instance_name = $temp_instance_ref->get_name();

	if (!$internal_association_flag) {
	    $temp_instance_ref->concat(refs => [$dL_species_ref,
						$dR_species_ref],
				       Set => 1);   # need to clone element instances for ungrouping
	    $temp_instance_ref->offset_bi_edge_join($dL_addr_ref, $dR_addr_ref,
						    ":",  # !!! edge type, hard-coded ???
						    $dL_species_ref->get_graph_size()
						   );
	} else {
	    $temp_instance_ref->concat(refs => [$dL_species_ref],
				       Set => 1);   # need to clone element instances for ungrouping
	    $temp_instance_ref->add_bi_edge($dL_addr_ref,
					    $dR_addr_ref,
					    ":",           # !!! edge type, hard-coded ???
					   );
	}
	printn $temp_instance_ref->sprint_graph_matrix() if ($verbosity >=3);

	# align or register the complex
	my ($C_instance_ref, $C2I_instance_mapping_ref) = $class->align_or_register($temp_instance_ref);
	my $C_instance_isomorph_exists_flag = (defined $C2I_instance_mapping_ref) ? 1 : 0;

	if ($C_instance_isomorph_exists_flag) {
	    # Isomorph found
	    $C2I_instance_mapping_ref = HiGraph->regroup_mapping($temp_instance_ref,
								     $C_instance_ref,
								     $C2I_instance_mapping_ref);
	} else {
	    # No isomorph found
	    # didn't align, so need to instantiate and register elements
	    $C_instance_ref->instantiate_components({});
	    $C_instance_ref->register_components();
	    # use parent mapping if no instance isomorph
	    $C2I_instance_mapping_ref = $C2I_mapping_ref;
	}

	# now compute mapping of ligands to complex
	my ($dL2C_instance_mapping_ref, $dR2C_instance_mapping_ref) = (($internal_association_flag) ?
								       ($C2I_instance_mapping_ref, $C2I_instance_mapping_ref) :
								       RegisteredGraph->split_mapping($C2I_instance_mapping_ref, $dL_size, $dR_size)
								      );

	if (!$C_instance_isomorph_exists_flag) { # was there an instance isomorph?
	    # NO, so new elements were instantiated --> clone state of ligand instances to the new complex
	    if (!$internal_association_flag) {
		$C_instance_ref->clone_state($dL_species_ref, $dL2C_instance_mapping_ref, $dR_species_ref, $dR2C_instance_mapping_ref);
	    } else {
		$C_instance_ref->clone_state($dL_species_ref, $dL2C_instance_mapping_ref);
	    }

	    # re-generate the graph matrix because
	    #   i) if an isomorph was found for the parent, the graph concatenation
	    #      of instances may be in a different order that for the parent
	    #  ii) we ungrouped the ligand instance graphs into the complex instance graph
	    #      (!!! can we optimize this ???)
	    $C_instance_ref->refresh_instance_graph_matrix();
	    $C_instance_ref->update_putative_isomorph_hash();  # will canonize if necessary

	    # do sanity check on the new complex
	    $C_instance_ref->check();
	}

	if ($verbosity >= 3) {
	    printn "new complex instance graph, state and mapping:";
	    printn "name = ".$C_instance_ref->get_name();
	    printn $C_instance_ref->sprint_graph_matrix();
	    printn $C_instance_ref->sprint_state();
	    printn "dL2C_instance_mapping = @$dL2C_instance_mapping_ref";
	    printn "dR2C_instance_mapping = @$dR2C_instance_mapping_ref";
	    printn "new complex instance elements: ". join ",",(map($_->get_name(), $C_instance_ref->get_elements));
	}

	# package species, remapped address and site into SiteInfo objects
	my $CL_address_ref = HiGraph->remap_node_address($dL2C_instance_mapping_ref, $dL_addr_ref);
	my $CL_info_ref = SiteInfo->new({
	    species_ref => $C_instance_ref,
	    site_address_ref => $CL_address_ref,
	    site_ref => $C_instance_ref->get_nested_element(@$CL_address_ref),
	});
	my $CR_address_ref = HiGraph->remap_node_address($dR2C_instance_mapping_ref, $dR_addr_ref);
	my $CR_info_ref = SiteInfo->new({
	    species_ref => $C_instance_ref,
	    site_address_ref => $CR_address_ref,
	    site_ref => $C_instance_ref->get_nested_element(@$CR_address_ref),
	});

	return {
	    C_ref => $C_instance_ref,
	    dL2C_mapping_ref => $dL2C_instance_mapping_ref,
	    dR2C_mapping_ref => $dR2C_instance_mapping_ref,
	    CL_info_ref => $CL_info_ref,
	    CR_info_ref => $CR_info_ref,
	   };
    }

    #--------------------------------------------------------------------------------------
    # Function: compute_dissociation_products
    # Synopsys: Compute the ComplexInstance(s) resulting from a dissociation
    #--------------------------------------------------------------------------------------
    sub compute_dissociation_products {
	my $class = shift;

	my $parent_class = $class;
	$parent_class =~ s/Instance$//;

	my %args = (
	    reaction_class => undef,
	    CL_info_ref => undef,
	    CR_info_ref => undef,
	    @_,
	   );
	check_args(\%args, 3);

	# my $reaction_class = $args{reaction_class};
	my $CL_info_ref = $args{CL_info_ref};  # L/R SiteInfo objects
	my $CR_info_ref = $args{CR_info_ref};

	my $C_species_ref = $CL_info_ref->get_species_ref();

	croak "ERROR: internal error, species should be the same" if ($C_species_ref != $CL_info_ref->get_species_ref());

	my $CL_addr_ref = $CL_info_ref->get_site_address_ref();
	my $CR_addr_ref = $CR_info_ref->get_site_address_ref();

	######################################################################
	printn "COMPUTE OBJECT GRAPH AND FIND ISOMORPH" if ($verbosity >=3);
	######################################################################
	# name of parent complex is sorted list of its elements
	my $temp_name = join("-", sort map($_->get_name(), $C_species_ref->get_parent_ref()->get_elements()));
	my $temp_ref = $parent_class->new({name => $temp_name, UNREGISTERED => 1});
	$temp_ref->concat(refs => [$C_species_ref->get_parent_ref()]);   # clone parent graph
	$temp_ref->del_bi_edge($CL_addr_ref,
			       $CR_addr_ref,
			       ":",  # !!! edge type, hard-coded ???
			      );
	printn $temp_ref->sprint_graph_matrix() if ($verbosity >=3);

	# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	# !!!!  Here we are checking whether resulting graph is disjoint:
	# !!!!  this can occur under certain modulation scenarios
	# !!!!  where we can encounter dissociation products that
	# !!!   did not exist before.
	# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	my @dL_connected = @{$temp_ref->get_connected_component(':',$CL_info_ref->get_site_address_ref()->[0])};
	my @dR_connected = @{$temp_ref->get_connected_component(':',$CR_info_ref->get_site_address_ref()->[0])};
	my $dL_size = scalar(@dL_connected);
	my $dR_size = scalar(@dR_connected);
	my $C_size = $C_species_ref->get_graph_size();

	my $internal_association_flag;
	my ($temp_LL_ref, $temp_LL_name);                                # for external case (LL + LR <-> C)
	my ($temp_LR_ref, $temp_LR_name);
	my ($LL_ref, $LL2I_mapping_ref, $C2ILL_mapping_ref, $LL_isomorph_exists_flag);
	my ($LR_ref, $LR2I_mapping_ref, $C2ILR_mapping_ref, $LR_isomorph_exists_flag);

	my ($temp_D_ref, $temp_D_name);                                  # for internal case  (D <-> C)
	my ($D_ref, $D2I_mapping_ref, $D_isomorph_exists_flag);

	if (($dL_size != $C_size) || ($dR_size != $C_size)) { 
	    confess "ERROR: internal error -- sizes messed up" if ($dL_size + $dR_size != $C_size);
	    confess "ERROR: internal error -- LL has zero size" if ($dL_size == 0);
	    confess "ERROR: internal error -- LR has zero size" if ($dR_size == 0);

	    $internal_association_flag = 0;

	    # dissociates into disjoint products, so clone appropriate subsets of association complex
	    $temp_LL_name = join("-", sort map($_->get_name(), @{[$temp_ref->get_elements()]}[@dL_connected]));
	    $temp_LL_ref = $parent_class->new({name => $temp_LL_name, UNREGISTERED => 1});

	    $temp_LR_name = join("-", sort map($_->get_name(), @{[$temp_ref->get_elements()]}[@dR_connected]));
	    $temp_LR_ref = $parent_class->new({name => $temp_LR_name, UNREGISTERED => 1});

	    $temp_LL_ref->concat_subset(refs => [$temp_ref], subsets => [\@dL_connected]);
	    $temp_LR_ref->concat_subset(refs => [$temp_ref], subsets => [\@dR_connected]);

	    ($LL_ref, $LL2I_mapping_ref) = $parent_class->align_or_register($temp_LL_ref);
	    $LL_isomorph_exists_flag = (defined $LL2I_mapping_ref) ? 1 : 0;
	    if ($LL_isomorph_exists_flag) {
		# Isomorph found
		$LL2I_mapping_ref = HiGraph->regroup_mapping($temp_LL_ref, $LL_ref, $LL2I_mapping_ref)
	    } else {
		# No isomorph found
		$LL_ref->update_putative_isomorph_hash();
		# one-one mapping if no isomorph
		$LL2I_mapping_ref = [map {[$_]} (0..$LL_ref->get_graph_size()-1)];
		$LL_ref->check();  # do sanity check on the new complex
	    }

	    ($LR_ref, $LR2I_mapping_ref) = $parent_class->align_or_register($temp_LR_ref);
	    $LR_isomorph_exists_flag = (defined $LR2I_mapping_ref) ? 1 : 0;
	    if ($LR_isomorph_exists_flag) {
		# Isomorph found
		$LR2I_mapping_ref = HiGraph->regroup_mapping($temp_LR_ref, $LR_ref, $LR2I_mapping_ref)
	    } else {
		# No isomorph found
		$LR_ref->update_putative_isomorph_hash();
		# one-one mapping if no isomorph
		$LR2I_mapping_ref = [map {[$_]} (0..$LR_ref->get_graph_size()-1)];
		$LR_ref->check(); # do sanity check on the new complex
	    }

	    # now compute mapping of complex to dissociated products (!!!not used, is this necessary???)
	    $C2ILL_mapping_ref = [map {[undef]} (1..$C_size)];
	    map {$C2ILL_mapping_ref->[$dL_connected[$_]] = $LL2I_mapping_ref->[$_]} (0..$#dL_connected);
	    $C2ILR_mapping_ref = [map {[undef]} (1..$C_size)];
	    map {$C2ILR_mapping_ref->[$dR_connected[$_]] = $LR2I_mapping_ref->[$_]} (0..$#dR_connected);
	} else {
	    $internal_association_flag = 1;

	    $temp_D_ref = $temp_ref;
	    $temp_D_name = $temp_name;

	    ($D_ref, $D2I_mapping_ref) = $parent_class->align_or_register($temp_D_ref);
	    $D_isomorph_exists_flag = (defined $D2I_mapping_ref) ? 1 : 0;

	    # do sanity check on the new complex
	    if ($D_isomorph_exists_flag) {
		# Isomorph found
		$D2I_mapping_ref = HiGraph->regroup_mapping($temp_D_ref, $D_ref, $D2I_mapping_ref)
	    } else {
		# No isomorph found
		$D_ref->update_putative_isomorph_hash();
		# one-one mapping if no isomorph
		$D2I_mapping_ref = [map {[$_]} (0..$D_ref->get_graph_size()-1)];
		$D_ref->check();
	    }
	}

	if ($verbosity >= 3) {
	    printn (($internal_association_flag) ? "new complex graph and mapping:" : "new L/R complex graphs and mapping:");
	    if ($internal_association_flag) {
		printn "name = ".$D_ref->get_name();
		printn $D_ref->sprint_graph_matrix();
		printn "D2I_mapping = @$D2I_mapping_ref";
		printn "new complex elements: ". join ",",(map($_->get_name(), $D_ref->get_elements));
	    } else {
		printn "LL_name = ".$LL_ref->get_name();
		printn $LL_ref->sprint_graph_matrix();
		printn "LL2I_mapping = @$LL2I_mapping_ref";
		printn "new complex elements: ". join ",",(map($_->get_name(), $LL_ref->get_elements));
		printn "LR_name = ".$LR_ref->get_name();
		printn $LR_ref->sprint_graph_matrix();
		printn "LR2I_mapping = @$LR2I_mapping_ref";
		printn "new complex elements: ". join ",",(map($_->get_name(), $LR_ref->get_elements));
	    }
	}

	#######################################################
	printn "COMPUTE OBJECT-INSTANCE GRAPH AND FIND ISOMORPH" if ($verbosity >=3);
	#######################################################
	my ($LL_instance_ref, $LR_instance_ref);  # for external association case
	my ($LL2I_instance_mapping_ref, $LR2I_instance_mapping_ref);
	my ($C2ILL_instance_mapping_ref, $C2ILR_instance_mapping_ref);

	my ($D_instance_ref);    # for internal association case
	my ($D2I_instance_mapping_ref);
	my ($C2ID_instance_mapping_ref);

	if (!$internal_association_flag) {
	    my $temp_LL_instance_ref = $LL_ref->new_object_instance({UNREGISTERED => 1, DONT_INSTANTIATE_COMPONENTS => 1});
	    my $temp_LL_instance_name = $temp_LL_instance_ref->get_name();

	    $temp_LL_instance_ref->concat_subset(refs => [$C_species_ref],
						 Set => 1,                       # need to clone element instances for ungrouping
						 subsets => [\@dL_connected]);   # clone instance graph
	    printn $temp_LL_instance_ref->sprint_graph_matrix() if ($verbosity >=3);

	    my $temp_LR_instance_ref = $LR_ref->new_object_instance({UNREGISTERED => 1, DONT_INSTANTIATE_COMPONENTS => 1});
	    my $temp_LR_instance_name = $temp_LR_instance_ref->get_name();
	    # don't clone the set elements of an instance so only the graph is cloned here
	    $temp_LR_instance_ref->concat_subset(refs => [$C_species_ref],
						 Set => 1,                       # need to clone element instances for ungrouping
						 subsets => [\@dR_connected]);   # clone instance graph
	    printn $temp_LR_instance_ref->sprint_graph_matrix() if ($verbosity >=3);

	    # align or register the ligand instances
	    ($LL_instance_ref, $LL2I_instance_mapping_ref) = $class->align_or_register($temp_LL_instance_ref);
	    my $LL_instance_isomorph_exists_flag = (defined $LL2I_instance_mapping_ref) ? 1 : 0;
	    if ($LL_instance_isomorph_exists_flag) {
		# Isomorph found
		$LL2I_instance_mapping_ref = HiGraph->regroup_mapping(
		    $temp_LL_instance_ref,
		    $LL_instance_ref,
		    $LL2I_instance_mapping_ref);
	    } else {
		# No isomorph found
		# didn't align, so need to instantiate and register elements
		$LL_instance_ref->instantiate_components({});
		$LL_instance_ref->register_components();
		# use parent mapping if no instance isomorph
		$LL2I_instance_mapping_ref = $LL2I_mapping_ref;
	    }

	    # compute mapping of complex to dissociated products
	    $C2ILL_instance_mapping_ref = [map {[undef]} (1..$C_size)];
	    map {$C2ILL_instance_mapping_ref->[$dL_connected[$_]] = $LL2I_instance_mapping_ref->[$_]} (0..$#dL_connected);

	    if (!$LL_instance_isomorph_exists_flag) { # was there an instance isomorph?
		# NO, so new elements were instantiated --> clone state of dissociating instance to the new complex
		$LL_instance_ref->clone_state($C_species_ref, $C2ILL_instance_mapping_ref);
		# re-generate the graph matrix
		$LL_instance_ref->refresh_instance_graph_matrix();
		$LL_instance_ref->update_putative_isomorph_hash();
		# do sanity check on the new complex
		$LL_instance_ref->check();
	    }

	    ($LR_instance_ref, $LR2I_instance_mapping_ref) = $class->align_or_register($temp_LR_instance_ref);
	    my $LR_instance_isomorph_exists_flag = (defined $LR2I_instance_mapping_ref) ? 1 : 0;
	    if ($LR_instance_isomorph_exists_flag) {
		# Isomorph found
		$LR2I_instance_mapping_ref = HiGraph->regroup_mapping(
		    $temp_LR_instance_ref,
		    $LR_instance_ref,
		    $LR2I_instance_mapping_ref);
	    } else {
		# No isomorph found
		# didn't align, so need to instantiate and register elements
		$LR_instance_ref->instantiate_components({});
		$LR_instance_ref->register_components();
		# use parent mapping if no instance isomorph
		$LR2I_instance_mapping_ref = $LR2I_mapping_ref;
	    }

	    # compute mapping of complex to dissociated products
	    $C2ILR_instance_mapping_ref = [map {[undef]} (1..$C_size)];
	    map {$C2ILR_instance_mapping_ref->[$dR_connected[$_]] = $LR2I_instance_mapping_ref->[$_]} (0..$#dR_connected);

	    if (!$LR_instance_isomorph_exists_flag) { # was there an instance isomorph?
		# NO, so new elements were instantiated --> clone state of dissociating instance to the new complex
		$LR_instance_ref->clone_state($C_species_ref, $C2ILR_instance_mapping_ref);
		# re-generate the graph matrix
		$LR_instance_ref->refresh_instance_graph_matrix();
		$LR_instance_ref->update_putative_isomorph_hash();
		# do sanity check on the new complex
		$LR_instance_ref->check();
	    }
	} else {
	    my $temp_D_instance_ref = $D_ref->new_object_instance({UNREGISTERED => 1, DONT_INSTANTIATE_COMPONENTS => 1});
	    my $temp_D_instance_name = $temp_D_instance_ref->get_name();
	    # n.b. Set::clone() won't clone the set elements of an instance so only the graph is cloned here
	    $temp_D_instance_ref->concat(refs => [$C_species_ref],
					 Set => 1);   # need to clone element instances for ungrouping
	    $temp_D_instance_ref->del_bi_edge($CL_addr_ref,
					       $CR_addr_ref,
					       ":",           # !!! edge type, hard-coded ???
					      );
	    printn $temp_D_instance_ref->sprint_graph_matrix() if ($verbosity >=3);

	    # align or register the complex instance
	    ($D_instance_ref, $D2I_instance_mapping_ref) = $class->align_or_register($temp_D_instance_ref);
	    my $D_instance_isomorph_exists_flag = (defined $D2I_instance_mapping_ref) ? 1 : 0;

	    if ($D_instance_isomorph_exists_flag) {
		# Isomorph found
		$D2I_instance_mapping_ref = HiGraph->regroup_mapping(
		    $temp_D_instance_ref,
		    $D_instance_ref,
		    $D2I_instance_mapping_ref);
	    } else {
		# No isomorph found
		# didn't align, so need to instantiate and register elements
		$D_instance_ref->instantiate_components({});
		$D_instance_ref->register_components();
		# use parent mapping if no instance isomorph
		$D2I_instance_mapping_ref = $D2I_mapping_ref;
	    }

	    # now compute mapping of complex to dissociated product
	    $C2ID_instance_mapping_ref = $D2I_instance_mapping_ref;

	    if (!$D_instance_isomorph_exists_flag) { # was there an instance isomorph?
		# NO, so new elements were instantiated --> clone state of dissociating instance to the new complex
		$D_instance_ref->clone_state($C_species_ref, $C2ID_instance_mapping_ref);
		# re-generate the graph matrix
		$D_instance_ref->refresh_instance_graph_matrix();
		$D_instance_ref->update_putative_isomorph_hash();
		# do sanity check on the new complex
		$D_instance_ref->check();
	    }
	}

	if ($verbosity >= 3) {
	    printn (($internal_association_flag) ? "new complex instance graph, state and mapping:" : "new L/R complex instance graphs, state and mapping:");
	    if ($internal_association_flag) {
		printn "D name = ".$D_instance_ref->get_name();
		printn $D_instance_ref->sprint_graph_matrix();
		printn $D_instance_ref->sprint_state();
		printn "D2I_instance_mapping = @$D2I_instance_mapping_ref";
		printn "new D complex instance elements: ". join ",",(map($_->get_name(), $D_instance_ref->get_elements));
	    } else {
		printn "LL name = ".$LL_instance_ref->get_name();
		printn $LL_instance_ref->sprint_graph_matrix();
		printn $LL_instance_ref->sprint_state();
		printn "LL2I_instance_mapping = @$LL2I_instance_mapping_ref";
		printn "new LL complex instance elements: ". join ",",(map($_->get_name(), $LL_instance_ref->get_elements));
		printn "LR name = ".$LR_instance_ref->get_name();
		printn $LR_instance_ref->sprint_graph_matrix();
		printn $LR_instance_ref->sprint_state();
		printn "LR2I_instance_mapping = @$LR2I_instance_mapping_ref";
		printn "new LR complex instance elements: ". join ",",(map($_->get_name(), $LR_instance_ref->get_elements));

	    }
	}

	# package ligand species, remapped addresses and sites into SiteInfo objects
	my $C2dL_mapping_ref = $C2ID_instance_mapping_ref || $C2ILL_instance_mapping_ref;
	my $C2dR_mapping_ref = $C2ID_instance_mapping_ref || $C2ILR_instance_mapping_ref;

	my $dL_species_ref = $D_instance_ref || $LL_instance_ref;
	my $dR_species_ref = $D_instance_ref || $LR_instance_ref;

	my $dL_address_ref = HiGraph->remap_node_address($C2dL_mapping_ref, $CL_addr_ref);	
	my $dR_address_ref = HiGraph->remap_node_address($C2dR_mapping_ref, $CR_addr_ref);

	my $dL_info_ref = SiteInfo->new({
	    species_ref => $dL_species_ref,
	    site_address_ref => $dL_address_ref,
	    site_ref => $dL_species_ref->get_nested_element(@$dL_address_ref),
	});
	my $dR_info_ref = SiteInfo->new({
	    species_ref => $dR_species_ref,
	    site_address_ref => $dR_address_ref,
	    site_ref => $dR_species_ref->get_nested_element(@$dR_address_ref),
	});

	return {
	    dL_info_ref => $dL_info_ref,
	    dR_info_ref => $dR_info_ref,
	    C2dL_mapping_ref => $C2dL_mapping_ref,
	    C2dR_mapping_ref => $C2dR_mapping_ref,
	    internal_association_flag => $internal_association_flag,
	};
    }

    #--------------------------------------------------------------------------------------
    # Function: compute_modified_substrate
    # Synopsys: Compute the ComplexInstance(s) resulting from a modification
    #--------------------------------------------------------------------------------------
    sub compute_modified_substrate {
	my $class = shift;

	my %args = (
	    reaction_class => undef,
	    dS_info_ref => undef,
	    @_,
	   );
	check_args(\%args, 2);

	my $reaction_class = $args{reaction_class};
	my $dS_info_ref = $args{dS_info_ref};
	my $dS_species_ref = $dS_info_ref->get_species_ref();
	my $dS_addr_ref = $dS_info_ref->get_site_address_ref();

	#######################################################
	printn "COMPUTE OBJECT-INSTANCE GRAPH AND FIND ISOMORPH" if ($verbosity >=3);
	#######################################################
	my $qP_parent_ref = $dS_species_ref->get_parent_ref();
	my $qP2I_mapping_ref = [map {[$_]} (0..$qP_parent_ref->get_graph_size()-1)]; # one-to-one mapping
	my $temp_qP_instance_ref = $qP_parent_ref->new_object_instance({
	    UNREGISTERED => 1,
	    # here we DO want to instantiate set elements
	   });
	my $temp_qP_instance_name = $temp_qP_instance_ref->get_name();

	# just need to clone the state
	$temp_qP_instance_ref->clone_state($dS_species_ref, $qP2I_mapping_ref);
	$temp_qP_instance_ref->modify_substrate(
	    reaction_class => $reaction_class,
	    address_ref => $dS_addr_ref,
	   );
	$temp_qP_instance_ref->refresh_instance_graph_matrix();

	printn $temp_qP_instance_ref->sprint_graph_matrix() if ($verbosity >=3);

	# align or register the product instance
	my ($qP_instance_ref, $qP2I_instance_mapping_ref) = $class->align_or_register($temp_qP_instance_ref);
	my $qP_instance_isomorph_exists_flag = (defined $qP2I_instance_mapping_ref) ? 1 : 0;

	if ($qP_instance_isomorph_exists_flag) {
	    # Isomorph found
	    $qP2I_instance_mapping_ref = HiGraph->regroup_mapping(
		$temp_qP_instance_ref,
		$qP_instance_ref,
		$qP2I_instance_mapping_ref);
	} else {
	    # No isomorph found
	    # didn't align, so need to register elements
	    $qP_instance_ref->register_components();
	    # use parent mapping if no instance isomorph
	    $qP2I_instance_mapping_ref = $qP2I_mapping_ref;
	}
	
	# do sanity check on the new complex
	if (!$qP_instance_isomorph_exists_flag) {
	    # register new complex in isomorph hash
	    $qP_instance_ref->update_putative_isomorph_hash();
	    # do sanity check on the new complex
	    $qP_instance_ref->check();
	}

	if ($verbosity >= 3) {
	    printn "qP name = ".$qP_instance_ref->get_name();
	    printn $qP_instance_ref->sprint_graph_matrix();
	    printn $qP_instance_ref->sprint_state();
	    printn "qP2I_instance_mapping = @$qP2I_instance_mapping_ref";
	    printn "new qP complex instance elements: ". join ",",(map($_->get_name(), $qP_instance_ref->get_elements));
	}	

	# package species, remapped address and site into SiteInfo object
	my $qP_address_ref = HiGraph->remap_node_address($qP2I_instance_mapping_ref, $dS_addr_ref);
	my $qP_info_ref = SiteInfo->new({
	    species_ref => $qP_instance_ref,
	    site_address_ref => $qP_address_ref,
	    site_ref => $qP_instance_ref->get_node_by_address($qP_address_ref),
	});

	return {
	    qP_info_ref => $qP_info_ref,
	    S2P_instance_mapping => $qP2I_instance_mapping_ref
	};
    }

    #######################################################################################
    # INSTANCE METHODS
    #######################################################################################
    #--------------------------------------------------------------------------------------
    # Function: START
    # Synopsys: 
    #--------------------------------------------------------------------------------------
#    sub BUILD {
#        my ($self, $obj_ID, $arg_ref) = @_;
	
#    }

    #--------------------------------------------------------------------------------------
    # Function: clone_state
    # Synopsys: Copy the state of given complex instances X using given X2S mapping.
    #--------------------------------------------------------------------------------------
    sub clone_state {
	my $self = shift;
	my $parent_ref = $self->get_parent_ref();

	while (@_) {
	    my $X_ref = shift;
	    my $X_parent_ref = $X_ref->get_parent_ref();
	    my $X2S_mapping_ref = shift;  # X to self mapping

	    my $X_node_instances_ref = $X_ref->get_node_instances();
	    my @X_site_refs = map {$_->get_site_ref()} @{$X_node_instances_ref};
	    my @X_address_refs = map {$_->get_site_address_ref()} @{$X_node_instances_ref};

	    for (my $i=0; $i < @X_site_refs; $i++) {
		my $X_address_ref = $X_address_refs[$i];
		# if target clone is smaller than template, the mapping has undefined values
		next if (!defined $X2S_mapping_ref->[$X_address_ref->[0]][0]);
		my $X_site_ref = $X_site_refs[$i];
		my $S_address_ref = HiGraph->remap_node_address($X2S_mapping_ref, $X_address_ref);
		my $S_site_ref = $self->get_node_by_address($S_address_ref);

		# call CUMULATIVE clone_state() method
		$S_site_ref->clone_state($X_site_ref);
	    }
	}
    }

    #--------------------------------------------------------------------------------------
    # Function: check (CUMULATIVE)
    # Synopsys: Check the Graph for consistency with the SetElements
    #--------------------------------------------------------------------------------------
    sub check : CUMULATIVE(BASE FIRST) {
	my $self = $_[0];

	printn "CHECKING COMPLEX INSTANCE ".$self->get_name() if ($verbosity >= 3);

	my $graph_size = $self->get_graph_size();
	my $num_elements = $self->get_num_elements();

	if ($num_elements != $graph_size) {
	    my $name = $self->get_name();
	    confess "ERROR: internal error -- graph size ($graph_size) of $name not consistent with no. of elements ($num_elements)";
	}

	my @node_labels = $self->get_node_colours();
	for (my $i = 0; $i < $graph_size; $i++) {
	    my $label = $node_labels[$i];
	    my $element_ref = $self->get_element($i);

	    my $parent_name = $element_ref->get_parent_ref()->get_name();
	    my $state = $element_ref->sprint_state();

	    if ("$parent_name:$state" ne $label) {
		printn "parent_name = $parent_name, state=$state, label=$label";
		printn "element names: ".join " ", map($_->get_name, $self->get_elements());
		printn "node labels: @node_labels";
		printn "matrix :\n".$self->sprint_graph_matrix();
		my $name = $self->get_name();
		confess "ERROR: internal error -- $name graph and elements of $name not the same";
	    }
	}

    }

    #######################################################################################
    # Function: modify_substrate
    # Synopsys: Given complex, indices and state, flip state of appropriate Node.
    #######################################################################################
    sub modify_substrate {
	my $self = shift;

	my %args = (
	    reaction_class => undef,
	    address_ref => undef,
	    @_,
	   );
	check_args(\%args, 2);

	my $address_ref = $args{address_ref};
	my $node_ref = $self->get_node_by_address($address_ref);

	# flip the state
	if ($args{reaction_class} eq "CatalyticReaction") {
	    $node_ref->flip_msite_state();
	} elsif ($args{reaction_class} eq "AllostericReaction") {
	    $node_ref->flip_allosteric_state();
	} else {
	    croak "ERROR: don't know what to do with reaction class $args{reaction_class}";
	}
    }

    #--------------------------------------------------------------------------------------
    # Function: get_csite_bound_to_msite_number
    # Synopsys: Compute and cache csite_bound_to_msite_number.
    #--------------------------------------------------------------------------------------
    sub get_csite_bound_to_msite_number {
	my $self = shift;
	my $obj_ID = ident $self;

	my $csite_bound_to_msite_number = $csite_bound_to_msite_number_of{$obj_ID};
	if (!defined $csite_bound_to_msite_number_of{$obj_ID}) {
	    my $instances_ref = $self->get_nested_elements_and_addresses("ALL")->{instances};
	    $csite_bound_to_msite_number = 0;
	    map {$csite_bound_to_msite_number++ if $_->get_csite_bound_to_msite_flag()} @$instances_ref;
	}
	return $csite_bound_to_msite_number_of{$obj_ID} = $csite_bound_to_msite_number;
    }

    #--------------------------------------------------------------------------------------
    # Function: sprint
    # Synopsys: Prints out the complex a form where each protein and its state are
    #           concatenated.  E.g.   A:[...]|B:[...]...N[...]!i99
    #--------------------------------------------------------------------------------------
    #  sprint() can be called within another sort, so to avoid nested sort bug,
    # (see http://www.nntp.perl.org/group/perl.perl5.porters/2001/05/msg37481.html)
    #  we need to have comparison routine explicit with ($$) prototype so that
    #  $a/$b are passed in @_ instead
    sub CMP ($$) {my $a = shift;my $b = shift; return $a->[0] cmp $b->[0];}
    sub sprint {
	my $self = shift;

	my $toplvl_state = $self->sprint_state(0);  # top-lvl state only
	confess "ERROR: (NOT IMPLEMENTED) don't know what to do with complex state info $toplvl_state" if $toplvl_state ne "[]";

	my @elements = map([$_->get_parent_ref()->get_name(), $_->sprint_state()], $self->get_elements());

	my @sorted_elements = sort CMP @elements;  # sort on name

	my $parent_name = $self->get_parent_ref->get_name();
	my $uniquifier;
	if ($parent_name =~ /\!(.*)/) {
	    $uniquifier = "!i$1";
	} else {
	    $uniquifier = "";
	}

	# state bits interleaved with proteins (e.g. gives A:x,x;x,x|B|C:x!i00)
	my $sprint = join("|", map {$_->[0].($_->[1] ne "" ? ":".$_->[1] : "")} @sorted_elements)."$uniquifier";
	return $sprint;
    }

    #--------------------------------------------------------------------------------------
    # Function: get_exported_name
    # Synopsys: Exports the name in the form
    #                  A_x1_B_T10_C_x_i99     or,
    #                  A1_BT10_Ci99           if $compact_names is set.
    #--------------------------------------------------------------------------------------
    sub get_exported_name {
	my $self = shift;

	my $sprint = $self->sprint();

	# rip out x's if compact_names
	if ($compact_names) {
	    # strip out any x's preceded by ',' or '['
	    $sprint =~ s/(\[|,)[xX]/$1/g;
	}

	# always strip out state hierarchy separators
	$sprint = strip($sprint, "[,]");

	# always replace protein separator '|' with user-desired separator
	$sprint =~ s/\|/$protein_separator/g;

	# strip out or replace state and isomorph separators
	if ($compact_names) {
	    $sprint =~ s/\://g;  # strip out state separator
	    $sprint =~ s/\!//g;  # strip out isomorph separator
	} else {
	    $sprint =~ s/\:/_/g;  # replace state separator with underscore
	    $sprint =~ s/\!/_/g;  # replace isomorph separator with underscore
	}

	return $sprint;
    }
}

sub run_testcases {

}


# Package BEGIN must return true value
return 1;

