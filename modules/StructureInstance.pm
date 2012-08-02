######################################################################################
# File:     StructureInstance.pm
# Author:   Julien F. Ollivier
#
# Copyright (C) 2005-2010 Julien Ollivier.
#
# This program comes with ABSOLUTELY NO WARRANTY.
# This is free software, and you are welcome to redistribute it
# under certain conditions. See file LICENSE.TXT for details.
#
# Synopsys: Instance of Structure
######################################################################################
# Detailed Description:
# ---------------------
######################################################################################

use strict;
use diagnostics;		# equivalent to -w command-line switch
use warnings;

package StructureInstance;
use Class::Std::Storable;
use base qw(ComponentInstance SetInstance HiGraphInstance SetElement);
{
    use Carp;
    use Storable qw(dclone);

    use Utils;
    use Globals;


    #######################################################################################
    # CLASS ATTRIBUTES
    #######################################################################################
    StructureInstance->set_class_data("ELEMENT_CLASS", "StructureInstance,AllostericStructureInstance,ReactionSiteInstance,AllostericSiteInstance,NodeInstance");

    #######################################################################################
    # ATTRIBUTES
    #######################################################################################
    my %group_node_ref_of :ATTR(get => 'group_node_ref', set => 'group_node_ref');

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
#    sub BUILD {
##    sub START {
#        my ($self, $obj_ID, $arg_ref) = @_;
	
#    }

    #--------------------------------------------------------------------------------------
    # Function: instantiate_components
    # Synopsys: Dummy.
    #--------------------------------------------------------------------------------------
    sub instantiate_components : CUMULATIVE(BASE FIRST) {
	my ($self, $arg_ref) = @_;
	my $obj_ID = ident $self;
	my $group_node_ref = $self->get_parent_ref()->get_group_node_ref();
	if (defined $group_node_ref) {
	    my $address_ref = defined $arg_ref->{address_ref} ? $arg_ref->{address_ref} : [];
	    my $instance_group_node_ref = $group_node_ref->new_object_instance({
		UNREGISTERED => 1, # don't register components
		%$arg_ref,
		address_ref => [@$address_ref],  # give group node same address as structure
	    });
	    $group_node_ref_of{$obj_ID} = $instance_group_node_ref;
	    # tell group node which object it has been added to
	    $instance_group_node_ref->added_to_object($self);
	}
    }

    #--------------------------------------------------------------------------------------
    # Function: register_components
    # Synopsys: Dummy.
    #--------------------------------------------------------------------------------------
    sub register_components : CUMULATIVE(BASE FIRST) {
	my $self = $_[0];
	my $obj_ID = ident $self;

	my $parent_ref = $self->get_parent_ref();
	my $group_node_ref = $parent_ref->get_group_node_ref();
	if (defined $group_node_ref) {
	    my $instance_group_node_ref = $group_node_ref_of{$obj_ID};
	    croak "ERROR: instance not defined" if !defined $instance_group_node_ref;
	    $group_node_ref->register_instance($instance_group_node_ref);
	}
    }

    #--------------------------------------------------------------------------------------
    # Function: refresh_instance_graph_matrix
    # Synopsys: When the state of an instance changes, call this function to rebuild the
    #           primary Graph of the instance reflecting the new state.  Any subgraphs
    #           that are to be ungrouped will also have their primary Graph rebuilt.
    #           The primary graph node colours include the top-lvl state and the sub-element
    #           states.
    #--------------------------------------------------------------------------------------
    sub refresh_instance_graph_matrix {
	my $self = shift; my $obj_ID = ident $self;

	printn "refresh_instance_graph_matrix: refreshing hierarchical instance ".$self->get_name() if ($verbosity >= 2);

	# clone the parent primary graph, which tosses out old
	$self->get_graph_matrix_ref()->{primary} = dclone($self->get_parent_ref()->get_graph_matrix_ref()->{primary});

	# clear derived graphs
	$self->clear_graphs();

	# re-label nodes
	my $node_colours_ref = $self->get_node_colours_ref()->{primary} = [];
	my $nodes_ref = $self->get_nodes_ref()->{primary} = [];
	my $parent_node_colours_ref = $self->get_parent_ref()->get_node_colours_ref()->{primary};

	my $group_node_ref = $group_node_ref_of{$obj_ID};
	if (defined $group_node_ref) {
	    push @{$nodes_ref}, $group_node_ref;
	    $self->set_group_node_flag(1);
	}
	push @{$nodes_ref}, $self->get_elements();

	for (my $i=0; $i < @{$nodes_ref}; $i++) {
	    my $node_ref = $nodes_ref->[$i];
 	    if ($node_ref->isa('StructureInstance') && $node_ref->get_ungroup_flag()) {
 		$node_ref->refresh_instance_graph_matrix();
	    }
	    my $node_state = $node_ref->sprint_state(1);  # full-state
	    push @{$node_colours_ref}, $parent_node_colours_ref->[$i].":$node_state";
	}
    }

    #--------------------------------------------------------------------------------------
    # The get_node_instances method traverses a StructureInstance
    # to find all of its nodes.  These are not stored in
    # an attribute to prevent returning stale data.  The nodes
    # are returned as SiteInfo objects (which contain
    # a weak reference to the containing species and the site address).
    #--------------------------------------------------------------------------------------
    # Function: get_node_instances
    # Synopsys: Get all (variably-nested) reaction sites in a given species including
    #           group nodes.
    #--------------------------------------------------------------------------------------
    sub get_node_instances {
	my $self = shift;  my $obj_ID = ident $self;
	my $species_ref = shift || $self;

	my @node_instances = ();

	my $group_node_ref = $group_node_ref_of{$obj_ID};
	if (defined $group_node_ref) {
	    push @node_instances, SiteInfo->new({
		species_ref => $species_ref,
		site_address_ref => $group_node_ref->get_address_ref(),
		site_ref => $group_node_ref,
	    });
	}
	
	my @elements = $self->get_elements();
	for (my $i = 0; $i < @elements; $i++) {
	    my $element_ref = $elements[$i];
	    if ($element_ref->isa('StructureInstance')) {
		push @node_instances, @{$element_ref->get_node_instances($species_ref)};
	    } else {
		# it's just a Node
		push @node_instances, SiteInfo->new({
		    species_ref => $species_ref,
		    site_address_ref => $element_ref->get_address_ref(),
		    site_ref => $element_ref,
		});
	    }
	}

	return \@node_instances;
    }

    #--------------------------------------------------------------------------------------
    # Function: get_node_by_address
    # Synopsys: Get a nested node in the structure by address.  If the node is
    #           itself a StructureInstance, return its group node.
    #--------------------------------------------------------------------------------------
    sub get_node_by_address {
	my $self = shift; my $obj_ID = ident $self;
	my $address_ref = shift;

	croak "ERROR: internal error -- ref expected" if !ref $address_ref;

	my $node_ref = $self->get_nested_element(@$address_ref);
	
	$node_ref = $node_ref->get_group_node_ref() if $node_ref->isa('StructureInstance');

	return $node_ref;
    }


    #--------------------------------------------------------------------------------------
    # Function: get_msite_state
    # Synopsys: 
    #--------------------------------------------------------------------------------------
    sub get_msite_state {
	my $self = shift;

	return [map($_->get_msite_state(), $self->get_elements())];
    }

    #--------------------------------------------------------------------------------------
    # Function: set_msite_state
    # Synopsys: 
    #--------------------------------------------------------------------------------------
    sub set_msite_state {
	my $self = shift;
	my $address_ref = shift;
	my $msite_state = shift;

	croak "ERROR: internal error -- undefined address" if (!defined $address_ref);

	$address_ref = [$address_ref] if (!ref $address_ref);

	$self->get_node_by_address($address_ref)->set_msite_state($msite_state);
    }

    #--------------------------------------------------------------------------------------
    # Function: get_allosteric_state
    # Synopsys: Dummy.
    #--------------------------------------------------------------------------------------
    sub get_allosteric_state {
	return undef;
    }

    #--------------------------------------------------------------------------------------
    # Function: get_allosteric_label
    # Synopsys: Dummy.
    #--------------------------------------------------------------------------------------
    sub get_allosteric_label {
	return undef;
    }

    #--------------------------------------------------------------------------------------
    # Function: match_state
    # Synopsys: Returns true if the state of the structure matches argument.
    #--------------------------------------------------------------------------------------
    sub match_state {
	my $self = shift;
	my $required_state = shift;
	
	# state string format: group node state, element states
	# [R, [,x,x], [T,x,x]]
	return $self->sprint_state() eq $required_state ? 1 : 0;
    }

    #--------------------------------------------------------------------------------------
    # Function: get_state
    # Synopsys: Returns group and element node states both as a hierarchical list and in
    #           a stringified form.  The format is as follows:
    #              [G, x, x, x]        <-- a structure with a group node and 3 leaf nodes
    #              [,x,x]              <-- a structure with no group node and 2 leaf nodes
    #              [,[G,x,x],[G,x,x]]  <-- a hierarchical structure w/ no top-lvl group node
    #              [G,[G,x],[G,x,x]]   <-- a hierachical structure w/ top-lvl group node
    #--------------------------------------------------------------------------------------
    sub get_state {
	my $self = shift;
	my $full_state_flag = shift;

	$full_state_flag = 1 if (!defined $full_state_flag);

	my @state = ();
	my $state = "[";

	# group node state
	my $group_node_ref = $self->get_group_node_ref();
	my $group_node_state = defined $group_node_ref ? $group_node_ref->sprint_state() : undef;
	push @state, $group_node_state;
	$state .= $group_node_state if defined $group_node_ref;

	# elements state
	if ($full_state_flag) {
	    my @element_refs = $self->get_elements();
	    if (@element_refs) {
		foreach my $element_ref (@element_refs) {
		    if ($element_ref->isa('NodeInstance')) {
			my $node_state = $element_ref->sprint_state();
			push @state, $node_state;
			$state .= ",".$node_state;
		    } else {
			my $sprint_state_result_ref = $element_ref->get_state($full_state_flag);
			push @state, $sprint_state_result_ref->[0];
			$state .=  ",".$sprint_state_result_ref->[1];
		    }
		}
	    }
	}

	$state .= "]";
	return [\@state, $state];
    }

    #--------------------------------------------------------------------------------------
    # Function: sprint_state
    # Synopsys: Returns group and element node states in string form.
    #--------------------------------------------------------------------------------------
    sub sprint_state {
	my $self = shift;
	my $full_state_flag = shift;

	my $state = $self->get_state($full_state_flag)->[1];
	return $state;
    }

    #--------------------------------------------------------------------------------------
    # Function: sprint
    # Synopsys: Returns name of the StructureInstance in the form PARENT_NAME:x,x;x,x,x
    #--------------------------------------------------------------------------------------
    sub sprint {
	my $self = shift;

	my $parent_name = $self->get_parent_ref->get_name();
	my $state = $self->sprint_state();

	my $sprint = "${parent_name}:$state";

	return $sprint;
    }

    #--------------------------------------------------------------------------------------
    # Function: get_exported_name
    # Synopsys: Exports the name in the form P_xx_xxx
    #--------------------------------------------------------------------------------------
    sub get_exported_name {
	my $self = shift;

	my $sprint = $self->sprint();
	$sprint =~ s/\:/_/g;  # replace state separator with underscore
	$sprint = strip($sprint, " [,]");  # strip out state hierarchy separators

	return $sprint;
    }

    #--------------------------------------------------------------------------------------
    # Function: STORABLE_freeze_pre, STORABLE_freeze_post, etc.
    # Synopsys: Hooks provided by Class::Std::Storable.
    #--------------------------------------------------------------------------------------
    sub STORABLE_thaw_post: CUMULATIVE {
 	my ($self, $clone_flag) = @_;
	my $obj_ID = ident $self;

	my $group_node_ref = $group_node_ref_of{$obj_ID};

	if (defined $group_node_ref) {
	    # tell group node which Structure it is in
	    $group_node_ref->added_to_object($self);
	}
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
    printn "NO TESTCASES!!!";
}


# Package BEGIN must return true value
return 1;

