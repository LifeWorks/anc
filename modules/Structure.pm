######################################################################################
# File:     Structure.pm
# Author:   Julien F. Ollivier
#
# Copyright (C) 2005-2010 Julien Ollivier.
#
# This program comes with ABSOLUTELY NO WARRANTY.
# This is free software, and you are welcome to redistribute it
# under certain conditions. See file LICENSE.TXT for details.
#
# Synopsys: The class for ANC-structures.
######################################################################################
# Detailed Description:
# ---------------------
######################################################################################

use strict;
use diagnostics;		# equivalent to -w command-line switch
use warnings;

package Structure;
use Class::Std::Storable;
use base qw(Set HiGraph RegisteredGraph Instantiable SetElement);
{
    use Carp;
    use Utils;
    use Globals;

    use StructureInstance;

    #######################################################################################
    # CLASS ATTRIBUTES
    #######################################################################################
    Structure->set_class_data("INSTANCE_CLASS", "StructureInstance");
    Structure->set_class_data("ELEMENT_CLASS", "Structure,AllostericStructure,ReactionSite,AllostericSite,Node");
    Structure->set_class_data("DEFAULT_GROUP_NODE", "Node");
    Structure->set_class_data("GROUP_NODE_PREFIX", "g");

    #######################################################################################
    # ATTRIBUTES
    #######################################################################################
    # group node of the structure
    my %group_node_ref_of :ATTR(get => 'group_node_ref', set => 'group_node_ref');

    # determines whether the Structure will get imported as a Complex during initialization
    my %import_flag_of  :ATTR(get => 'import_flag', set => 'import_flag');

    # list of edges in the structure
    my %uni_edges_ref_of :ATTR(get => 'uni_edges_ref', set => 'uni_edges_ref');
    my %bi_edges_ref_of :ATTR(get => 'bi_edges_ref', set => 'bi_edges_ref');

    #######################################################################################
    # FUNCTIONS
    #######################################################################################

    #######################################################################################
    # CLASS METHODS
    #######################################################################################

    #--------------------------------------------------------------------------------------
    # Function: XXX
    # Synopsys: 
    #--------------------------------------------------------------------------------------
#    sub XXX {
#	my $class = shift;
#    }

    #######################################################################################
    # INSTANCE METHODS
    #######################################################################################
    #--------------------------------------------------------------------------------------
    # Function: BUILD
    # Synopsys: 
    #--------------------------------------------------------------------------------------
    sub BUILD {
        my ($self, $obj_ID, $arg_ref) = @_;

	# report creation
	my $class = ref $self;
	printn "$class->new(): creating structure ".($self->get_name())." with components ".(join " ", map {$_->get_name()} $self->get_elements()) if $verbosity >= 2;

	# init import_flag
	$import_flag_of{$obj_ID} = $arg_ref->{import_flag} if exists $arg_ref->{import_flag};

	# use exists to allow undef value for group_node_ref
	if (exists $arg_ref->{group_node_ref}) {
	    $group_node_ref_of{$obj_ID} = $arg_ref->{group_node_ref};
	} elsif (defined $arg_ref->{group_node_class}) {
	    $group_node_ref_of{$obj_ID} = $arg_ref->{group_node_class};
	} else {
	    # add default group node defined by class
	    my $default_group_node = $class->get_class_data("DEFAULT_GROUP_NODE");
	    $group_node_ref_of{$obj_ID} = $default_group_node if defined $default_group_node;
	}

	$uni_edges_ref_of{$obj_ID} = defined $arg_ref->{uni_edges_ref} ? $arg_ref->{uni_edges_ref} : [];
	$bi_edges_ref_of{$obj_ID} = defined $arg_ref->{bi_edges_ref} ? $arg_ref->{bi_edges_ref} : [];

	if (defined $group_node_ref_of{$obj_ID}) {
	    # prefix edges from grouping node to each element (or its head node)
	    my @group_edges = ();
	    for (my $j=0; $j < $self->get_num_elements(); $j++) {
		push @group_edges, [-1,$j,'g'];
	    }
	    unshift @{$uni_edges_ref_of{$obj_ID}}, @group_edges;
	}
	
	if (defined $arg_ref->{add_edges}) {
	    printn "ERROR: Initialization parameter 'add_edges' is obsolete, use 'add_allosteric_couplings' instead";
	    printn "       The format of the argument to be passed has also changed.  Please refer to the user";
	    printn "       manual for more details";
	    exit(1);
	}
	if (defined $arg_ref->{add_allosteric_couplings}) {
	    foreach my $coupling_ref (@{$arg_ref->{add_allosteric_couplings}}) {
		my $reg_factor = $coupling_ref->[2];
		$reg_factor = "" if !defined $reg_factor;
		my $f_phi = $coupling_ref->[3];
		my $b_phi = defined $coupling_ref->[4] ? $coupling_ref->[4] : $coupling_ref->[3];
		my $f_edge = [$coupling_ref->[0], $coupling_ref->[1], "~{$reg_factor|$f_phi}"];
		my $b_edge = [$coupling_ref->[1], $coupling_ref->[0], "~{$reg_factor|$b_phi}"];
		push @{$uni_edges_ref_of{$obj_ID}}, ($f_edge, $b_edge);
	    }
	}
    }

    #--------------------------------------------------------------------------------------
    # Function: START
    # Synopsys: Create nodes for all elements in the Set.
    #--------------------------------------------------------------------------------------
    sub START {
        my ($self, $obj_ID, $arg_ref) = @_;

	my $group_node_ref = $group_node_ref_of{$obj_ID};
	if (defined $group_node_ref) {
	    if (!ref $group_node_ref) { # class given?
		my $group_node_class = $group_node_ref;
		my $class = ref $self;
		my $group_node_prefix = $class->get_class_data("GROUP_NODE_PREFIX");
		$group_node_ref = $group_node_ref_of{$obj_ID} = $group_node_class->new({
		    %$arg_ref,
		    # group node name is g_XXX
		    name => "${group_node_prefix}_".$self->get_name(),
		    group_node_flag => 1,
		});
	    }
	    croak "ERROR: group node must derive from the Node class" if !$group_node_ref->isa('Node');

	    # tell group node which object it has been added to
	    $group_node_ref->added_to_object($self);

	    # in the Graph, create the nodes corresponding to grouping node
	    $self->add_node($group_node_ref->get_name(), $group_node_ref);
	    $self->set_group_node_flag(1);
	}
	
	my @elements = $self->get_elements();
	foreach my $element_ref (@elements) {
	    # in the Graph, create the nodes corresponding to each Set element
	    $self->add_node($element_ref->get_name(), $element_ref);
	}

	my $uni_edges_ref = $uni_edges_ref_of{$obj_ID};
	if (defined $uni_edges_ref) {
	    foreach my $uni_edge_ref (@$uni_edges_ref) {
		$self->add_uni_edge(
		    $uni_edge_ref->[0],
		    $uni_edge_ref->[1],
		    $uni_edge_ref->[2],
		   );
	    }
	}
	my $bi_edges_ref = $bi_edges_ref_of{$obj_ID};
	if (defined $bi_edges_ref) {
	    foreach my $bi_edge_ref (@$bi_edges_ref) {
		$self->add_bi_edge(
		    $bi_edge_ref->[0],
		    $bi_edge_ref->[1],
		    $bi_edge_ref->[2],
		   );
	    }
	}
    }

    #--------------------------------------------------------------------------------------
    # Function: get_allosteric_flag
    # Synopsys: Dummy function always returns 0.
    #--------------------------------------------------------------------------------------
    sub get_allosteric_flag {
	return 0;
    }

    #--------------------------------------------------------------------------------------
    # Function: add_element
    # Synopsys: Add argument to Set, also creating a Node as necessary.
    #--------------------------------------------------------------------------------------
    sub add_element {
	my $self = shift; my $obj_ID = ident $self;
	my $element_ref = shift;

	if (!ref $element_ref) {
	    $element_ref = Node->new({name => $element_ref});
	}
	$self->Set::add_element($element_ref);
	$self->add_node($element_ref->get_name(), $element_ref);
	my $group_node_ref = $group_node_ref_of{$obj_ID};
	if (defined $group_node_ref) {
	    my $graph_matrix_ref = $self->get_graph_matrix_ref()->{primary};
	    push @{$graph_matrix_ref->[0][$#{$graph_matrix_ref}]}, 'g';
	}
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
    # Function: sprint
    # Synopsys: 
    #--------------------------------------------------------------------------------------
    sub sprint {
	my $self = shift;

	my $sprint = $self->get_name();
	return $sprint;
    }

    #--------------------------------------------------------------------------------------
    # Function: get_exported_name
    # Synopsys: 
    #--------------------------------------------------------------------------------------
    sub get_exported_name {
	my $self = shift;

	my $exported_name = $self->get_name();
	return $exported_name;
    }

    #-------------------------------------------------------------------------------------
    # Function: xxx
    # Synopsys: 
    #--------------------------------------------------------------------------------------
#    sub xxx {
#	my $self = shift;
#    }

}


sub run_testcases {
    use Node;
    use Data::Dumper;

    my $export_dir = "test/modules/Structure";
    `mkdir -p $export_dir`;

    my $n1_ref = Node->new({name => "n1"});
    my $n2_ref = Node->new({name => "n2"});
    my $n3_ref = Node->new({name => "n3"});

    my $d1_ref = Structure->new({
	name => "D1",
	group_node_ref => Node->new({name => "D1"}),
	elements_ref => [$n1_ref, $n2_ref],
    });
    $d1_ref->add_uni_edge(-1, 1, 'p');
    printn $d1_ref->_DUMP();
    printn "d1 (primary) = \n".$d1_ref->sprint_graph_matrix();
    $d1_ref->export_graphviz(filename => "$export_dir/d1.primary.png");
    my $d2_ref = Structure->new({
	name => "D2",
	# no grouping node!!
	group_node_ref => undef,
	elements_ref => [$n1_ref, $n3_ref, $n1_ref],
    });
    $d2_ref->add_bi_edge(0, 1, 'p');
    printn $d2_ref->_DUMP();
    printn "d2 (primary) = \n".$d2_ref->sprint_graph_matrix();
    $d2_ref->export_graphviz(filename => "$export_dir/d2.primary.png");

    my $p1_ref = Structure->new({
	name => "P1",
	group_node_class => "Node",
	elements_ref => [$d1_ref, $n2_ref, $d2_ref],
    });
    $p1_ref->add_uni_edge(-1, 0, 'x');
    $p1_ref->add_bi_edge([2,1], -1, 'y');
    $p1_ref->add_uni_edge(1, 2, 'z');
    $p1_ref->add_uni_edge([0,1], [2,0], 'w');
    $p1_ref->add_bi_edge([-1], [-1], 'v');
    printn $p1_ref->_DUMP();
    printn "p1 (primary) = \n".$p1_ref->sprint_graph_matrix();
    $p1_ref->export_graphviz(filename => "$export_dir/p1.primary.png");

    $d1_ref->set_ungroup_flag(1);
    $d2_ref->set_ungroup_flag(1);
    $p1_ref->ungroup();
    printn "p1 (ungrouped) = \n".$p1_ref->sprint_graph_matrix("ungrouped");
    printn Dumper($p1_ref->get_node_group_map_ref());
    $p1_ref->export_graphviz(src => "ungrouped",
			     filename => "$export_dir/p1.ungrouped1.png");

}


# Package BEGIN must return true value
return 1;
