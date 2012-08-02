######################################################################################
# File:     HiGraph.pm (Hierarchical Graph)
# Author:   Julien F. Ollivier
#
# Copyright (C) 2005-2010 Julien Ollivier.
#
# This program comes with ABSOLUTELY NO WARRANTY.
# This is free software, and you are welcome to redistribute it
# under certain conditions. See file LICENSE.TXT for details.
#
# Synopsys: A HiGraph is a Graph whose nodes may themselves be HiGraphs.
#
#           If a node of the HiGraph is itself HiGraph, then it can be ungrouped
#           into the HiGraph, meaning that the sub-graph represented by the node is
#           inserted into the HiGraph, and that any edges connecting to nodes within
#           sub-graph (indicated by hierarchical addresses) are appropriately re-wired.
#           If the sub-graph had no grouping node, one is always created.
#
#           The addressing of nodes in a HiGraph is slightly different than in a Graph
#           because of the optional presence of a grouping node.  The grouping node is
#           always the first node in a HiGraph and has an index of (-1) if present.
#           The other nodes are indexed starting at 0.  Therefore, the presence of a
#           grouping node requires an address adjustment when adding and deleting edges,
#           since the Graph class is agnostic to the grouping node and indexes it as 0.
#
######################################################################################
# Detailed Description:
# ---------------------
######################################################################################

use strict;
use diagnostics;		# equivalent to -w command-line switch
use warnings;

package HiGraph;
use Class::Std::Storable;
use base qw(Graph);
{
    use Carp;
    use Utils;
    use Globals;

    #######################################################################################
    # ATTRIBUTES
    #######################################################################################
    # specifies whether this graph is to be ungrouped when a node in a HiGraph
    my %ungroup_flag_of :ATTR(get => 'ungroup_flag', set => 'ungroup_flag', init_arg => 'ungroup_flag', default => 1);
    # specifies whether the first node in the primary graph is a grouping node
    my %group_node_flag_of :ATTR(get => 'group_node_flag', set => 'group_node_flag', init_arg => 'group_node_flag', default => 0);

    # maps the index of a sub-graph node into corresponding node index in the ungrouped graph
    my %node_ungroup_map_ref_of :ATTR(get => 'node_ungroup_map_ref', set => 'node_ungroup_map_ref');
    # maps the index in the ungrouped graph of a primary node into its index in the primary graph
    my %node_group_map_ref_of :ATTR(get => 'node_group_map_ref', set => 'node_group_map_ref');

    #######################################################################################
    # FUNCTIONS
    #######################################################################################

    #######################################################################################
    # CLASS METHODS
    #######################################################################################
    #--------------------------------------------------------------------------------------
    # Function: regroup_mapping
    # Synopsys: The Graph method compare_isomorphic returns a mapping based on the nodes
    #           of the ungrouped graph.  This method transforms the ungrouped mapping into
    #           a corresponding grouped one.  The group mapping is hierarchical 2-element
    #           list.  The first element gives the mapped index, and if this element was
    #           ungrouped, then the second element is defined and is a ref
    #           into another group mapping giving the sub-element mappings.
    #--------------------------------------------------------------------------------------
    sub regroup_mapping {
	my $class = shift;
	my $X_ref = shift;  my $X_ID = ident $X_ref;
	my $Y_ref = shift;  my $Y_ID = ident $Y_ref;
	my $X2Y_mapping_ref = shift;

	confess "ERROR: internal error -- X_ref is not ungrouped " if (!defined $node_group_map_ref_of{$X_ID});
	confess "ERROR: internal error -- Y_ref is not ungrouped " if (!defined $node_group_map_ref_of{$Y_ID});

   	my $X2Y_grouped_mapping_ref = [];
	for (my $i=0; $i < @{$X2Y_mapping_ref}; $i++) {
	    my $X_ungrouped_index = $i;
	    my $Y_ungrouped_index = $X2Y_mapping_ref->[$i];
	    my @X_address = @{$node_group_map_ref_of{$X_ID}->[$X_ungrouped_index]};
	    my @Y_address = @{$node_group_map_ref_of{$Y_ID}->[$Y_ungrouped_index]};

	    my $temp_ref = $X2Y_grouped_mapping_ref;
	    while (@X_address > 1) {
		$temp_ref = $temp_ref->[shift @X_address];
		$temp_ref->[1] = [] if (!defined $temp_ref->[1]);
		$temp_ref = $temp_ref->[1];
		shift @Y_address;
	    }
	    $temp_ref->[shift @X_address][0] = shift @Y_address;
	}
	return $X2Y_grouped_mapping_ref;
    }

    #--------------------------------------------------------------------------------------
    # Function: remap_node_address
    # Synopsys: Given an address in X and GROUPED mapping to Y, want corresponding address in Y.
    #--------------------------------------------------------------------------------------
    sub remap_node_address {
	my $class = shift;
	my $X2Y_grouped_mapping_ref = shift;
	my @X_address = @{shift()};

	my @Y_address = ();
	my $temp_ref = $X2Y_grouped_mapping_ref;
	while (@X_address) {
	    $temp_ref = $temp_ref->[shift @X_address];
	    push @Y_address, $temp_ref->[0];
	    last if (!defined $temp_ref->[1]);
	    $temp_ref = $temp_ref->[1];
	}
	push @Y_address, @X_address;  # push remaining address bits that were not ungrouped
	return \@Y_address;
    }

#    #--------------------------------------------------------------------------------------
#    # Function: XXX
#    # Synopsys: 
#    #--------------------------------------------------------------------------------------
#    sub XXX {
#	my $class = shift;
#    }

    #######################################################################################
    # INSTANCE METHODS
    #######################################################################################

    #--------------------------------------------------------------------------------------
    # PRIMARY GRAPH MANIPULATION
    #--------------------------------------------------------------------------------------

    #--------------------------------------------------------------------------------------
    # Function: add_uni_edge/del_uni_edge, add_bi_edge/del_bi_edge
    # Synopsys: Wrappers call corresponding Graph method, while
    #           offsetting address to account for group node.
    #--------------------------------------------------------------------------------------
    sub add_uni_edge {
	my $self = shift; my $obj_ID = ident $self;
	my @args = @_;

	my $group_node_flag = $group_node_flag_of{$obj_ID};
	if ($group_node_flag) {
	    if (ref $args[0]) {
		$args[0] = [@{$args[0]}]; # make copy before incrementing
		$args[0][0]++;
	    } else {
		$args[0]++;
	    }
	    if (ref $args[1]) {
		$args[1] = [@{$args[1]}]; # make copy before incrementing
		$args[1][0]++;
	    } else {
		$args[1]++;
	    }
	}
	return $self->Graph::add_uni_edge(@args);
    }
    sub del_uni_edge {
	my $self = shift; my $obj_ID = ident $self;
	my @args = @_;

	my $group_node_flag = $group_node_flag_of{$obj_ID};
	if ($group_node_flag) {
	    if (ref $args[0]) {
		$args[0] = [@{$args[0]}]; # make copy before incrementing
		$args[0][0]++;
	    } else {
		$args[0]++;
	    }
	    if (ref $args[1]) {
		$args[1] = [@{$args[1]}]; # make copy before incrementing
		$args[1][0]++;
	    } else {
		$args[1]++;
	    }
	}
	return $self->Graph::del_uni_edge(@args);
    }
    sub add_bi_edge {
	my $self = shift; my $obj_ID = ident $self;
	my @args = @_;

	my $group_node_flag = $group_node_flag_of{$obj_ID};
	if ($group_node_flag) {
	    if (ref $args[0]) {
		$args[0] = [@{$args[0]}]; # make copy before incrementing
		$args[0][0]++;
	    } else {
		$args[0]++;
	    }
	    if (ref $args[1]) {
		$args[1] = [@{$args[1]}]; # make copy before incrementing
		$args[1][0]++;
	    } else {
		$args[1]++;
	    }
	}
	return $self->Graph::add_bi_edge(@args);
    }
    sub del_bi_edge {
	my $self = shift; my $obj_ID = ident $self;
	my @args = @_;

	my $group_node_flag = $group_node_flag_of{$obj_ID};
	if ($group_node_flag) {
	    if (ref $args[0]) {
		$args[0] = [@{$args[0]}]; # make copy before incrementing
		$args[0][0]++;
	    } else {
		$args[0]++;
	    }
	    if (ref $args[1]) {
		$args[1] = [@{$args[1]}]; # make copy before incrementing
		$args[1][0]++;
	    } else {
		$args[1]++;
	    }
	}
	return $self->Graph::del_bi_edge(@args);
    }

    #--------------------------------------------------------------------------------------
    # Function: ungroup
    # Synopsys: Recursively ungroups a HiGraph. Returns:
    #           * node_group_map: maps the index of a sub-graph node into corresponding
    #             node index in the ungrouped graph
    #           * node_ungroup_map: maps the index in the ungrouped graph of a primary
    #             node into its index in the primary graph
    #--------------------------------------------------------------------------------------
    sub ungroup {
	my $self = shift;
	my $obj_ID = ident $self;
	my %args = (
	    src => "primary",
	    dst => "ungrouped",
	    @_,
	   );
	check_args(\%args, 2);

	my $src = $args{src};
	my $dst = $args{dst};

	printn "HiGraph::ungroup -- ungroup called for ".$self->get_name() if ($verbosity >=3);

	# If already called, return previous result
	my $valid_flags_ref = $self->get_valid_flags_ref();
	if (defined $valid_flags_ref->{$dst} && $valid_flags_ref->{$dst}) {
	    return ($node_ungroup_map_ref_of{$obj_ID}, $node_group_map_ref_of{$obj_ID});
	}

	printn "HiGraph::ungroup -- ungrouping ".$self->get_name() if ($verbosity >=3);

	confess "ERROR: internal error -- src ($src) and dst ($dst) cannot be the same" if ($src eq $dst);
	my $src_graph_ref = $self->get_graph_matrix_ref()->{$src};
	my $src_node_colours_ref = $self->get_node_colours_ref()->{$src};
	my $src_nodes_ref = $self->get_nodes_ref()->{$src};

	my $src_graph_size = @{$src_graph_ref};

	my $dst_graph_ref = $self->get_graph_matrix_ref()->{$dst} = [];
	my $dst_node_colours_ref = $self->get_node_colours_ref()->{$dst} = [];
	my $dst_nodes_ref = $self->get_nodes_ref()->{$dst} = [];

	my $group_node_flag = $group_node_flag_of{$obj_ID} ? 1 : 0;

	# For @node_ungroup_map:
	#   element [$i][0] contains offsets,
	#   element [$i][1] contains ref to offsets of sub-elements
	my @node_ungroup_map;
	my @node_group_map;
	for (my $i = 0; $i < $src_graph_size; $i++) {
	    my $ii = $group_node_flag ? ($i - 1) : $i;   # adjusted index taking into account presence of group node
	    # record current dst size
	    my $offset = @{$dst_graph_ref};
	    my $src_node_ref = $src_nodes_ref->[$i];
	    if ($ii != -1 && (ref $src_node_ref) &&
		$src_node_ref->isa('HiGraph') &&
		$src_node_ref->get_ungroup_flag()) {
		$node_ungroup_map[$ii][0] = $offset;
		# concat a grouping node if necessary, same colour as element...
		my $subgraph_group_node_flag = $group_node_flag_of{ident $src_node_ref} ? 1 : 0;
		my $add_group_node = $subgraph_group_node_flag ? 0 : 1;
		if ($add_group_node) {
		    my $group_node_colour = $src_node_colours_ref->[$i];
		    if ($src_node_ref->isa('Instance')) {
			# ...but substituting top-lvl state for full state if it's an instance
			my $toplvl_state = $src_node_ref->sprint_state(0);  # top-lvl node state only
			$group_node_colour =~ s/\:.*/\:$toplvl_state/;
		    }
		    Graph::concat_matrix_subset(
			$dst_graph_ref, $dst_node_colours_ref, $dst_nodes_ref,
			[[[]]], [$group_node_colour], [undef]  # !!! group node ref is undefined for now ???
		       );
		}
		# concat dst element matrix
		my $sub_graph_size = $src_node_ref->get_graph_size();
		my ($ungroup_map_ref, $group_map_ref) = $src_node_ref->ungroup();
		Graph::concat_matrix_subset(
		    $dst_graph_ref, $dst_node_colours_ref, $dst_nodes_ref,
		    $src_node_ref->get_graph_matrix_ref()->{ungrouped},
		    $src_node_ref->get_node_colours_ref()->{ungrouped},
		    $src_node_ref->get_nodes_ref()->{ungrouped},
		   );

		$node_group_map[$offset] = [$ii];   # for group node, whether inserted above or not
		my $num_subgraph_nongroup_nodes = @{$group_map_ref} - $subgraph_group_node_flag;
		foreach (1..$num_subgraph_nongroup_nodes) {   # for subgraph non-group nodes only
		    $node_group_map[$offset + $_] = [$ii, @{$group_map_ref->[$_ - $add_group_node]}];
		}
		$node_ungroup_map[$ii][1] = $ungroup_map_ref;  # store node offsets returned by sub-graph ungroup

		# create edges from grouping node to each element (or its head node)
		if ($add_group_node) {
		    for (my $j=0; $j < $sub_graph_size; $j++) {
			push @{$dst_graph_ref->[$offset][$offset + $ungroup_map_ref->[$j][0] + 1]}, 'g';
		    }
		}
	    } else {
		# concat current element
		Graph::concat_matrix_subset(
		    $dst_graph_ref, $dst_node_colours_ref, $dst_nodes_ref,
		    [[[]]], [$src_node_colours_ref->[$i]], [$src_node_ref],
		   );
		$node_group_map[$offset] = [$ii];
		$node_ungroup_map[$ii][0] = $offset if ($ii != -1);
	    }
	}

	# wire external edges to elements
	for (my $i = 0; $i < $src_graph_size; $i++) {
	    my $I = $group_node_flag ? ($i - 1) : $i;   # adjusted index taking account presence of group node
	    for (my $j = 0; $j < $src_graph_size; $j++) {
		my $J = $group_node_flag ? ($j - 1) : $j;   # adjusted index taking account presence of group node
		my $edge_list_ref = $src_graph_ref->[$i][$j];
		foreach my $edge_ref (@$edge_list_ref) {
		    $edge_ref = [$edge_ref, [], []] if !ref $edge_ref;
		    my $ii = 0;
		    my @src_address = @{$edge_ref->[1]};
		    my $src_node_offset_ref = ($I == -1) ? [0] : $node_ungroup_map[$I];
		    while (defined $src_node_offset_ref->[0]) {
			$ii += $src_node_offset_ref->[0];  # point to element or its group node
			if (defined $src_node_offset_ref->[1] && @src_address) {  # element was ungrouped and we are addressing a sub-node
			    if ($src_node_offset_ref->[1][0][0] == 0) { # sub-graph did not have group node?
				$ii++;  # +1 accounts for grouping node inserted above
			    }
			    my $sub_index = shift @src_address;
			    my $next_node_offset_ref = $src_node_offset_ref->[1][$sub_index];
			    if (!defined $next_node_offset_ref) {
				$ii += $sub_index;
			    }
			    $src_node_offset_ref = $next_node_offset_ref;
			} else {
			    $src_node_offset_ref = undef;
			}
		    }

		    my $jj = 0;
		    my @dst_address = @{$edge_ref->[2]};
		    my $dst_node_offset_ref = ($J == -1) ? [0] : $node_ungroup_map[$J];
		    while (defined $dst_node_offset_ref->[0]) {
			$jj += $dst_node_offset_ref->[0];  # point to element or its group node
			if (defined $dst_node_offset_ref->[1] && @dst_address) {  # element was ungrouped and we are addressing a sub-node
			    if ($dst_node_offset_ref->[1][0][0] == 0) { # sub-graph did not have group node?
				$jj++;  # +1 accounts for grouping node inserted above
			    }
			    my $sub_index = shift @dst_address;
			    my $next_node_offset_ref = $dst_node_offset_ref->[1][$sub_index];
			    if (!defined $next_node_offset_ref) {
				$jj += $sub_index;
			    }
			    $dst_node_offset_ref = $next_node_offset_ref;
			} else {
			    $dst_node_offset_ref = undef;
			}
		    }
		    push @{$dst_graph_ref->[$ii][$jj]}, [$edge_ref->[0], \@src_address, \@dst_address];
		}
	    }
	}

	$valid_flags_ref->{$dst} = 1;

	$node_group_map_ref_of{$obj_ID} = \@node_group_map;
	$node_ungroup_map_ref_of{$obj_ID} = \@node_ungroup_map;

	return (\@node_ungroup_map, \@node_group_map);
    }

    #--------------------------------------------------------------------------------------
    # Function: canonize
    # Synopsys: Ungroup, scalarize and sort edges, order nodes.
    #--------------------------------------------------------------------------------------
    sub canonize {
	my $self = shift;

	$self->ungroup();
	$self->scalarize_and_sort_edges("ungrouped", "scalar");
	$self->order_nodes("scalar", "canonical");
    }

    #--------------------------------------------------------------------------------------
    # ADDRESS MAPPING METHODS
    #--------------------------------------------------------------------------------------

    #--------------------------------------------------------------------------------------
    # Function: get_node_grouped_address  !!!NEVER TESTED!!!
    # Synopsys: Translates an index into ungrouped graph to the address into primary graph.
    #--------------------------------------------------------------------------------------
    sub get_node_grouped_address {
	my $self = shift; my $obj_ID = ident $self;
	my $ungrouped_index = shift;
	return $node_group_map_ref_of{$obj_ID}->[$ungrouped_index];
    }
    #--------------------------------------------------------------------------------------
    # Function: get_node_ungrouped_address
    # Synopsys: Translates an address into the primary graph to the index into the
    #           ungrouped graph.
    #--------------------------------------------------------------------------------------
    sub get_node_ungrouped_address {
	my $self = shift; my $obj_ID = ident $self;

	my $node_ungroup_map_ref = $node_ungroup_map_ref_of{$obj_ID};

#	use Data::Dumper;
#	printn Dumper($node_ungroup_map_ref);

	my $ungrouped_index = 0;
	foreach my $index (@_) {
	    #printn "aaa $index -> ".$node_ungroup_map_ref->[$index]->[0];
	    $ungrouped_index += $node_ungroup_map_ref->[$index]->[0];
	    $node_ungroup_map_ref = $node_ungroup_map_ref->[$index]->[1];
	}
	return $ungrouped_index;
    }

#    #--------------------------------------------------------------------------------------
#    # Function: xxx
#    # Synopsys: 
#    #--------------------------------------------------------------------------------------
#    sub xxx {
#	my $class = shift;
#    }
}


sub run_testcases {
    printn "run_testcases: HiGraph package";
    $verbosity = 3;

    # turn off shading
    $Graph::graph_shading_iterations = 0;

    use Null;
    use Graph;
    use Data::Dumper;

    my $export_dir = "test/modules/HiGraph";
    `mkdir -p $export_dir`;

    printn "NESTING/UNGROUPING TEST...";

    my $L0g0_ref = HiGraph->new({
	name => "L0g0",
	ungroup_flag => 0,
    });
    $L0g0_ref->add_node("X");
    $L0g0_ref->add_node("Y");
    $L0g0_ref->add_bi_edge(0, 1, ':');
    $L0g0_ref->add_uni_edge(0, 1, ':');
    printn "L0g0 (primary) = \n".$L0g0_ref->sprint_graph_matrix();
    $L0g0_ref->export_graphviz(filename => "$export_dir/L0g0.primary.png");

    my $L0g1_ref = HiGraph->new({
	name => "L0g1",
	ungroup_flag => 0,
	nodes => [Null->new({name=>"W"}), Null->new({name=>"Z"})]
    });
    $L0g1_ref->add_uni_edge(1, 0, ':');
    printn "L0g1 (primary) = \n".$L0g1_ref->sprint_graph_matrix();
    $L0g1_ref->export_graphviz(filename => "$export_dir/L0g1.primary.png");

    my $L1g0_ref = HiGraph->new({
	name => "L1g0",
	ungroup_flag => 0,
	nodes=> [$L0g0_ref, $L0g1_ref, $L0g0_ref],
    });
    $L1g0_ref->add_uni_edge(0, 2, 'x');
    $L1g0_ref->add_bi_edge(1, [0,0], 'y');
    $L1g0_ref->add_uni_edge([1,1], [2,1], 'z');
    $L1g0_ref->add_bi_edge([2,0], 1, 'w');
    printn "L1g0 (primary) = \n".$L1g0_ref->sprint_graph_matrix();
    $L1g0_ref->export_graphviz(filename => "$export_dir/L1g0.primary.png");

    $L0g0_ref->set_ungroup_flag(1);
    $L0g1_ref->set_ungroup_flag(0);
    $L1g0_ref->clear_graphs();
    $L1g0_ref->ungroup();
    printn "L1g0 (ungrouped) = \n".$L1g0_ref->sprint_graph_matrix("ungrouped");
    printn Dumper($L1g0_ref->get_node_group_map_ref());
    $L1g0_ref->export_graphviz(src => "ungrouped",
			       filename => "$export_dir/L1g0.ungrouped1.png");

    $L0g0_ref->set_ungroup_flag(0);
    $L0g1_ref->set_ungroup_flag(1);
    $L1g0_ref->clear_graphs();
    $L1g0_ref->ungroup();
    printn "L1g0 (ungrouped) = \n".$L1g0_ref->sprint_graph_matrix("ungrouped");
    printn Dumper($L1g0_ref->get_node_group_map_ref());
    $L1g0_ref->export_graphviz(src => "ungrouped",
			       filename => "$export_dir/L1g0.ungrouped2.png");

    $L0g0_ref->set_ungroup_flag(1);
    $L0g1_ref->set_ungroup_flag(1);
    $L1g0_ref->clear_graphs();
    $L1g0_ref->ungroup();
    printn "L1g0 (ungrouped) = \n".$L1g0_ref->sprint_graph_matrix("ungrouped");
    printn Dumper($L1g0_ref->get_node_group_map_ref());
    $L1g0_ref->export_graphviz(src => "ungrouped",
			       filename => "$export_dir/L1g0.ungrouped3.png");

    my $L2g0_ref = HiGraph->new({
	name => "L2g0",
	ungroup_flag => 0,
	nodes=> [$L1g0_ref, $L1g0_ref],
    });
    $L2g0_ref->add_uni_edge([1,1,1], [0,1,0], 'ZtoW');

    printn "L2g0 (primary) = \n".$L2g0_ref->sprint_graph_matrix();
    $L2g0_ref->export_graphviz(filename => "$export_dir/L2g0.primary.png");

    $L1g0_ref->clear_graphs();  # to test recursive ungrouping
    $L1g0_ref->set_ungroup_flag(1);
    $L2g0_ref->clear_graphs();
    $L2g0_ref->ungroup();
    printn "L2g0 (ungrouped) = \n".$L2g0_ref->sprint_graph_matrix("ungrouped");
    printn Dumper($L2g0_ref->get_node_group_map_ref());
    $L2g0_ref->export_graphviz(src => "ungrouped",
			       filename => "$export_dir/L2g0.ungrouped.png");


    printn "ISOMORPHISM TEST...";

    my $compare_isomorphic_ref;
    my $grouped_mapping_ref;

    # build a clone L1g1 of L1g0 but with components in a different order (swap 1 and 2)
    my $L1g1_ref = HiGraph->new({
	name => "L1g0",   # if it's a clone, we must cheat and give it the same name
	ungroup_flag => 0,
	nodes=> [$L0g0_ref, $L0g0_ref, $L0g1_ref],
    });
    $L1g1_ref->add_uni_edge(0, 1, 'x');
    $L1g1_ref->add_bi_edge(2, [0,0], 'y');
    $L1g1_ref->add_uni_edge([2,1], [1,1], 'z');
    $L1g1_ref->add_bi_edge([1,0], 2, 'w');
    printn "L1g1 (primary) = \n".$L1g1_ref->sprint_graph_matrix();
    $L1g1_ref->export_graphviz(filename => "$export_dir/L1g1.primary.png");

    # now build a clone L2g1 of L2g0 using L1g1
    my $L2g1_ref = HiGraph->new({
	name => "L2g1",
	ungroup_flag => 0,
	nodes=> [$L1g1_ref, $L1g1_ref],
    });
    $L2g1_ref->add_uni_edge([1,2,1], [0,2,0], 'ZtoW');
    printn "L2g1 (primary) = \n".$L2g1_ref->sprint_graph_matrix();
    $L2g1_ref->export_graphviz(filename => "$export_dir/L2g1.primary.png");

    $L0g0_ref->set_ungroup_flag(0);
    $L0g1_ref->set_ungroup_flag(0);
    $L1g0_ref->set_ungroup_flag(0);
    $L1g1_ref->set_ungroup_flag(0);

    $L0g0_ref->clear_graphs();
    $L0g1_ref->clear_graphs();
    $L1g0_ref->clear_graphs();
    $L1g1_ref->clear_graphs();
    $L2g0_ref->clear_graphs();
    $L2g1_ref->clear_graphs();

    $compare_isomorphic_ref = Graph->compare_isomorphic($L2g0_ref, $L2g1_ref);
    print $compare_isomorphic_ref ? "ERROR\n" : "OK!!!\n"; # not identical because doesn't ungroup!
    printn Dumper($compare_isomorphic_ref);

    $L1g0_ref->clear_graphs();
    $L1g1_ref->clear_graphs();
    $L2g0_ref->clear_graphs();
    $L2g1_ref->clear_graphs();

    $L1g0_ref->set_ungroup_flag(1);
    $L1g1_ref->set_ungroup_flag(1);

    $compare_isomorphic_ref = HiGraph->compare_isomorphic($L2g0_ref, $L2g1_ref);
    print $compare_isomorphic_ref ? "OK\n" : "ERROR!!!\n"; # ungrouped once, so identical
    printn Dumper($compare_isomorphic_ref);
    $grouped_mapping_ref = HiGraph->regroup_mapping($L2g0_ref, $L2g1_ref, $compare_isomorphic_ref);
    printn Dumper($grouped_mapping_ref);
    printn join ",", @{HiGraph->remap_node_address($grouped_mapping_ref, [0])};
    printn join ",", @{HiGraph->remap_node_address($grouped_mapping_ref, [0,0])};
    printn join ",", @{HiGraph->remap_node_address($grouped_mapping_ref, [0,0,0])};
    printn join ",", @{HiGraph->remap_node_address($grouped_mapping_ref, [0,0,1])};
    printn join ",", @{HiGraph->remap_node_address($grouped_mapping_ref, [0,1])};
    printn join ",", @{HiGraph->remap_node_address($grouped_mapping_ref, [0,1,0])};
    printn join ",", @{HiGraph->remap_node_address($grouped_mapping_ref, [0,1,1])};
    printn join ",", @{HiGraph->remap_node_address($grouped_mapping_ref, [0,2])};
    printn join ",", @{HiGraph->remap_node_address($grouped_mapping_ref, [0,2,0])};
    printn join ",", @{HiGraph->remap_node_address($grouped_mapping_ref, [0,2,1])};


    $L0g0_ref->set_ungroup_flag(1);
    $L0g1_ref->set_ungroup_flag(1);

    $L0g0_ref->clear_graphs();
    $L0g1_ref->clear_graphs();
    $L1g0_ref->clear_graphs();
    $L1g1_ref->clear_graphs();
    $L2g0_ref->clear_graphs();
    $L2g1_ref->clear_graphs();

    $compare_isomorphic_ref = Graph->compare_isomorphic($L2g0_ref, $L2g1_ref);
    print $compare_isomorphic_ref ? "OK\n" : "ERROR!!!\n"; # ungrouped twice, so identical
    printn Dumper($compare_isomorphic_ref);
    $grouped_mapping_ref = HiGraph->regroup_mapping($L2g0_ref, $L2g1_ref, $compare_isomorphic_ref);
    printn Dumper($grouped_mapping_ref);
    printn join ",", @{HiGraph->remap_node_address($grouped_mapping_ref, [0])};
    printn join ",", @{HiGraph->remap_node_address($grouped_mapping_ref, [0,0])};
    printn join ",", @{HiGraph->remap_node_address($grouped_mapping_ref, [0,0,0])};
    printn join ",", @{HiGraph->remap_node_address($grouped_mapping_ref, [0,0,1])};
    printn join ",", @{HiGraph->remap_node_address($grouped_mapping_ref, [0,1])};
    printn join ",", @{HiGraph->remap_node_address($grouped_mapping_ref, [0,1,0])};
    printn join ",", @{HiGraph->remap_node_address($grouped_mapping_ref, [0,1,1])};
    printn join ",", @{HiGraph->remap_node_address($grouped_mapping_ref, [0,2])};
    printn join ",", @{HiGraph->remap_node_address($grouped_mapping_ref, [0,2,0])};
    printn join ",", @{HiGraph->remap_node_address($grouped_mapping_ref, [0,2,1])};
}

# Package BEGIN must return true value
return 1;

