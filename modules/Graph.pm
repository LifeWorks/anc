######################################################################################
# File:     Graph.pm
# Author:   Julien F. Ollivier
#
# Copyright (C) 2005-2010 Julien Ollivier.
#
# This program comes with ABSOLUTELY NO WARRANTY.
# This is free software, and you are welcome to redistribute it
# under certain conditions. See file LICENSE.TXT for details.
#
# Synopsys: A coloured node/edge directed graph.
######################################################################################
# Detailed Description:
# ---------------------
#
# Supports hierarchical graphs (or graphs with ports) and non-hierarchical graphs.
#
# Each Graph object has several associated matrices, each with their own node colour
# information and associated mappings.  The 'primary' matrix is the principal matrix
# on which nodes and edges are added or deleted.  Other matrices represent the same
# graph but after various operations such as scalarizing, sorting (edges and nodes)
# and ungrouping (see HiGraph class).  Adding/deleting nodes or edges invalidates
# the derived graphs and causes them to be deleted.
#
# The format of each matrix is as follows:
#
# [ [ [edge_list] [...] ]
#   [ [...]       []    ]
# ]               ^--  empty listref means no edge from node 1 to node 1
#
# Multiple edges are possible between pairs of nodes, so the associated matrix
# elements are in fact listrefs of edges.  An empty list means no connection.
#
# An edge is either a scalar giving the edge colour or a listref, whose elements
# are the colour (scalar) and the nested node addresses.  I.e.
#    edge_list = (edge, edge, ......)
#    edge = unnested_edge | nested_edge
#    src/dst_address = (index list, possibly empty)
#
# A nested edge is equivalently
#    nested_edge = [colour, [src_address], [dst_address]] | scalar_nested_edge
#    scalar_nested_edge = colour<!sx.sy.sz...><!dx.dy.dz...>   !!! this is not true ???
# where sx.sy.sz are the relevant indices joined by periods.
#
# An unnested edge is equivalently
#    unnested_edge = scalar_edge | [colour, [], []]
#    scalar_edge   = colour
#
# Isomophic comparisons require sorted, scalarized (and ungrouped for HiGraphs) versions
# of the graph matrix.
#
# Several routines use mapping variables which map the index of one object to another.
# By convention, @X2Y_mapping maps an index of X to the corresponding index of Y, such that
# $X2Y_mapping[$i]  gives the index in Y of the protein having index $i in X.
#
# Hence, X[$i] == Y[$X2Y_mapping[$i]].
#
######################################################################################

use strict;
use diagnostics;		# equivalent to -w command-line switch
use warnings;

package Graph;
use Class::Std::Storable;
use base qw(Named);
{
    use Carp;
    use Data::Dumper;
    use Storable qw(dclone);

    use Utils;
    use Globals;

    use Matrix;

    #######################################################################################
    # ATTRIBUTES
    #######################################################################################
    # These attributes are further keyed by {primary, ungrouped, scalar, canonical}.
    my %graph_matrix_ref_of :ATTR(get => 'graph_matrix_ref', set => 'graph_matrix_ref');
    my %node_colours_ref_of :ATTR(get => 'node_colours_ref', set => 'node_colours_ref');
    my %nodes_ref_of        :ATTR(get => 'nodes_ref', set => 'nodes_ref');
    # mapping of canonical matrix relative to scalar (both possibly ungrouped)
    my %mappings_ref_of :ATTR(get => 'mappings_ref', set => 'mappings_ref');

    # specifies whether derived graphs are up-to-date
    my %valid_flags_ref_of :ATTR(get => 'valid_flags_ref', set => 'valid_flags_ref', default => 0);

    # list whose size gives number of groups of indistinguishable nodes in the canonized
    # graph and whose elements gives the number of nodes in each group
    my %group_sizes_ref_of :ATTR(get => 'group_sizes_ref', set => 'group_sizes_ref');

    #######################################################################################
    # FUNCTIONS
    #######################################################################################

    #######################################################################################
    # The following functions are used to compute graph isomorphism.  They are not class
    # methods since they don't operate on Graph objects, but directly on the matrix and
    # node list.  They assume that they are operating on an ungrouped matrix such that
    # matrix elements are just lists of edge colours.
    #######################################################################################
    BEGIN {			# need BEGIN for static %argument_cache hash else compile error

	#--------------------------------------------------------------------------------------
	# Function: generate_permutations
	# Synopsys: Argument consists of a list of group sizes.  A group size corresponds to
	#           the number of identical nodes within a group, which must be re-arranged
	#           for isomorphic comparisons.  Returns a list of all necessary node
	#           re-arrangements to determine if two graphs are isomorphic.  The size of
	#           the list is the product of the factorials of the group sizes.
	#--------------------------------------------------------------------------------------
	sub generate_permutations {
	    my @group_sizes = @{shift()};  # this copies the list argument

	    # short circuit for case where all nodes same colour
	    return generate_arrangements([0..($group_sizes[0]-1)]) if (@group_sizes == 1);

	    my (@group_arrangements, @arrangements_last_index, @group_offsets);
	    my $total_permutations = 1;
	    for (my $i = 0; $i < @group_sizes; $i++) {
		my $group_size = $group_sizes[$i];
		$group_offsets[$i] = ($i == 0) ? 0 : $group_offsets[$i-1] + $group_sizes[$i-1];
		croak "ERROR: list elements can't be references\n" if (ref $group_size);
		push @group_arrangements, generate_arrangements([0..$group_size-1]);
		push @arrangements_last_index, $#{$group_arrangements[$#group_arrangements]};
		$total_permutations *= @{$group_arrangements[$#group_arrangements]}
	    }

	    my @permutations = ();

	    my @indexes = map {0} @group_sizes;

	    while ($total_permutations--) {
		# concatenate each arrangement with appropriate group_offsets
		push @permutations, [map {my $i=$_; map {$_+$group_offsets[$i]}
					  @{$group_arrangements[$_][$indexes[$_]]}}
				     (0..$#group_sizes)];
		# increment appropriate index
		INC: for (my $i=$#indexes; $i >= 0; $i--) {
		    if ($indexes[$i] >= $arrangements_last_index[$i]) {
			$indexes[$i] = 0;
		    } else {
			$indexes[$i]++;
			last INC;
		    }
		}
	    }
	    return \@permutations;
	}

	#--------------------------------------------------------------------------------------
	# Function: generate_arrangements
	# Synopsys: Given a list, generates and returns a 2-D list with all possible
	#           permuations of the elements in the list.
	#--------------------------------------------------------------------------------------
	# Detailed Description:
	# ---------------------
	# Implemented using a recursive-swap algorithm.  Should return n! size list given
	# a list of size n.  Each element of this list is a reference to permuted list.
	#--------------------------------------------------------------------------------------
	my %argument_cache;
	sub generate_arrangements {
	    my @list = @{shift()};  # this copies the list argument

	    foreach my $item (@list) {
		# because argument caching depends on stringifying arguments
		croak "ERROR: list elements can't be references\n" if (ref $item);
	    }

	    # use argument cache to speed up
	    my $key;
	    $key = join ",", @list;
	    if (exists $argument_cache{"$key"}) {
#		printn "cache hit @list";
		return $argument_cache{"$key"};
	    }

#	    printn "cache miss @list";
	    if (@list > 9) {
		die "FATAL: too many arrangements (".scalar(@list)."!) arrangements required...";
	    }

	    my @return_value;
	
	    if (@list > 1) {
		# avoid repeated automatic variables in for loop
		my ($i, $temp);
		my (@permuted_list, @sub_list, $sub_arrangement_ref);
		my ($list_ptr);
		for ($i=0; $i < @list; $i++) {
		    # this copies
		    @permuted_list = @list;
		    # swap first element with each other one (incl. itself)
		    $temp = $permuted_list[0];
		    $permuted_list[0] = $list[$i];
		    $permuted_list[$i] = $temp;
		    # get sub-arrangements
		    @sub_list = @permuted_list[1..(@list-1)];
		    $sub_arrangement_ref = generate_arrangements(\@sub_list);
		    foreach $list_ptr (@{$sub_arrangement_ref}) {
			push @return_value, [$permuted_list[0], @$list_ptr];  # this copies
		    }
		}
	    } else {
		push @return_value, \@list;
	    }
	
	    # copy and cache the value
	    $argument_cache{"$key"} = \@return_value;

	    #	print "generate_arrangements: RETURNING ". Dumper(\@return_value) . "\n";
	    return \@return_value;
	}

	sub report_arrangement_cache {
	    printn Dumper(\%argument_cache);
	}
    }
    
    #--------------------------------------------------------------------------------------
    # Function: rearrange_graph_matrix
    # Synopsys: Re-arrange matrix according to new row/col order given by a list.
    #           Ordering list elements must contain 0, 1,... (n-1) in desired order.
    #           B2A_mapping of (1,2,0) means that rows 0,1,2 of B correspond to
    #           rows 1,2,0 of A.
    #           N.B. edge lists are aliased to original array (but this is harmless if
    #           working with scalar/canonical version of graph, which will not change)
    #--------------------------------------------------------------------------------------
    sub rearrange_graph_matrix {
	my $A_matrix_ref = shift;
	my @A_node_colours = @{shift()};
	my @B2A_mapping = @{shift()};
	
	if (@$A_matrix_ref != @B2A_mapping) {
	    confess "ERROR: rearrange_matrix -- unequal sizes or incomplete mapping\n";
	}

	my ($i, $j, $B_matrix_ref);
	for ($i=0; $i < @B2A_mapping; $i++) {
	    for ($j=0; $j < @B2A_mapping; $j++) {
		# this line aliases the edge list of the original array (more efficient!)
		$B_matrix_ref->[$i][$j] = $A_matrix_ref->[$B2A_mapping[$i]][$B2A_mapping[$j]];
	    }
	}

	my @B_node_colours = map {$A_node_colours[$_]} @B2A_mapping;

	return ($B_matrix_ref, \@B_node_colours);
    }

    #--------------------------------------------------------------------------------------
    # Function: concat_matrix_subset
    # Synopsys: Concatenate a subset of source matrix onto a destination matrix.
    #           Destination edges are NOT aliased to original.
    #--------------------------------------------------------------------------------------
    sub concat_matrix_subset {
	my $dst_matrix_ref = shift;
	my $dst_node_colours_ref = shift;
	my $dst_nodes_ref = shift;
	my $src_matrix_ref = shift;
	my $src_node_colours_ref = shift;
	my $src_nodes_ref = shift;
	my $subset_ref = shift;

	my $offset = @{$dst_matrix_ref};  # i.e. offset is index of first new element
	my $src_size = @{$src_matrix_ref};

	my @subset = (defined $subset_ref) ? @{$subset_ref} : (0..($src_size-1));

	my ($ii, $jj);

	$ii = $offset;
	for (my $i = 0; $i < @subset; $i++) {
	    croak "ERROR: subset index out of range" if ($subset[$i] >= $src_size);
	    # copy node colours and refs
	    push @$dst_node_colours_ref, $src_node_colours_ref->[$subset[$i]];
	    push @$dst_nodes_ref, $src_nodes_ref->[$subset[$i]];
	    # fill row/col elements with empty references, up to offset
	    for (my $jj = 0; $jj < $offset; $jj++) {
		$dst_matrix_ref->[$ii][$jj] = [];
		$dst_matrix_ref->[$jj][$ii] = [];
	    }
	    $ii++;
	}

	# copy elements from dst matrix
	($ii, $jj) = ($offset, $offset);
	foreach my $i (@subset) {
	    foreach my $j (@subset) {
		@{$dst_matrix_ref->[$ii][$jj++]} = (map
						    {ref $_ ? [$_->[0], [@{$_->[1]}], [@{$_->[2]}]] : $_}  # this copies everything
						    @{$src_matrix_ref->[$i][$j]}
						   );
	    }
	    $ii++;  $jj = $offset;
	}
    }

    #--------------------------------------------------------------------------------------
    # Function: sort_graph_matrix
    # Synopsys: Re-arrange graph matrix by sorting according to node colour.
    #           Returns re-arranged matrix and mapping.
    #--------------------------------------------------------------------------------------
    sub sort_graph_matrix {
	my $X_matrix_ref = shift;          # graph matrix
	my $X_node_colours_ref = shift;    # node colours
	my $X_nodes_ref = shift;           # node refs

	confess "ERROR: internal error -- no. of colours doesn't match matrix size" if (@$X_matrix_ref != @$X_node_colours_ref);
	confess "ERROR: internal error -- no. of refs doesn't match matrix size" if (@$X_matrix_ref != @$X_nodes_ref);

	my @S2X_mapping = sort {$X_node_colours_ref->[$a] cmp $X_node_colours_ref->[$b]} (0..$#{$X_node_colours_ref});

	my ($S_ref, $S_node_colours_ref) = rearrange_graph_matrix($X_matrix_ref, $X_node_colours_ref, \@S2X_mapping);
	my $S_nodes_ref = [map {$X_nodes_ref->[$_]} @S2X_mapping];

	return ($S_ref, $S_node_colours_ref, $S_nodes_ref, \@S2X_mapping);
    }

    #--------------------------------------------------------------------------------------
    # Function: compare_identical
    # Synopsys: Given two graph matrices, determine if they are identical.
    #--------------------------------------------------------------------------------------
    # Detailed Description:
    # ---------------------
    # Assumptions are that graph edges are scalarized, and that these scalar edges have
    # been previously sorted.  Returns 0 if nodes are different, undef if nodes are
    # the same but edges are different.
    #--------------------------------------------------------------------------------------
    sub compare_identical {
	my $A_matrix_ref = shift;
	my $A_node_colours_ref = shift;
	my $B_matrix_ref = shift;
	my $B_node_colours_ref = shift;

	my $size = @$A_matrix_ref;
	my $size_B = @$B_matrix_ref;

	if ($size != $size_B) {
	    confess "ERROR: internal error -- different sizes ($size and $size_B)\n";
	}

	# compare node colours
	for (my $i=0; $i < $size; $i++) {
	    if ($A_node_colours_ref->[$i] ne $B_node_colours_ref->[$i]) {
		printn "compare_identical: NOT IDENTICAL (different nodes)" if $verbosity >= 3;
		return 0;
	    }
	}

	# compare the edges
	for (my $i=0; $i < $size; $i++) {
	    my $A_row_ref = $A_matrix_ref->[$i];
	    my $B_row_ref = $B_matrix_ref->[$i];

	    # here we assume scalarized edges and compare an entire row at once,
	    # joining columns with ';' and edges with a ',', producing a string
	    # "colour,colour...;colour,colour;..."
	    # n.b. don't need to sort since the ungroup() will do it
	    my $A_row_edges = join(";", map {join(",", @$_)} @$A_row_ref);  
	    my $B_row_edges = join(";", map {join(",", @$_)} @$B_row_ref);

	    if ($A_row_edges ne $B_row_edges) {
		printn "compare_identical: NOT IDENTICAL (different edges)" if $verbosity >= 3;
		return undef;
	    }
	}

	printn "compare_identical: IDENTICAL" if $verbosity >= 3;
	return 1;
    }

    #######################################################################################
    # CLASS METHODS
    #######################################################################################
    #--------------------------------------------------------------------------------------
    # Function: compare_isomorphic
    # Synopsys: Determine whether two Graph objects are isomorphic, canonizing them before
    #           the comparison if not already done.  If the graphs are not isomorphic,
    #           returns 0 (false).
    #           Otherwise, returns a list reference (true), giving the mapping of an index of
    #           the 1st argument (A) to the corresponding index of 2nd argument (B).
    #--------------------------------------------------------------------------------------
    # Detailed Description:
    # ---------------------
    # Use brute-force method by comparing first argument with all possible rearrangements
    # of the second.
    #--------------------------------------------------------------------------------------
    sub compare_isomorphic {
	my ($class, $A_ref, $B_ref) = @_;
	my $return_value;

	my $A_ID = ident $A_ref;
	my $B_ID = ident $B_ref;

	$A_ref->canonize() if (!$valid_flags_ref_of{$A_ID}{canonical});
	$B_ref->canonize() if (!$valid_flags_ref_of{$B_ID}{canonical});

	my $A_matrix_ref = $graph_matrix_ref_of{$A_ID}{canonical};
	my $B_matrix_ref = $graph_matrix_ref_of{$B_ID}{canonical};
	my $A_node_colours_ref = $node_colours_ref_of{$A_ID}{canonical};
	my $B_node_colours_ref = $node_colours_ref_of{$B_ID}{canonical};

	my $last_A = $#{$A_matrix_ref};
	my $last_B = $#{$B_matrix_ref};

	my $S2A_mapping = $mappings_ref_of{$A_ID}{canonical};
	my $S2B_mapping = $mappings_ref_of{$B_ID}{canonical};

	if ($verbosity >= 3) {
	    printn "compare_isomorphic: A =";
	    print $A_ref->sprint_graph_matrix("scalar");
	    printn "compare_isomorphic: B =";
	    print $B_ref->sprint_graph_matrix("scalar");
	}

	# Here we do an initial comparison of the canonized graphs.
	# The compare_identical() routine will quickly reject graphs that don't have the same
	# set of nodes (returning 0).  Also, we will identify identical graphs without
	# re-arrangement when
	#    i) there are no duplicate nodes
	#   ii) there are duplicate nodes but they happen to be in the correct order by chance
	my $cmp_result = compare_identical($A_matrix_ref, $A_node_colours_ref, $B_matrix_ref, $B_node_colours_ref);
	if (defined $cmp_result) {
	    if ($cmp_result) {
		################## compute mapping
		my @A2B_mapping;
		for (my $i=0; $i<(@$S2B_mapping); $i++) { # think of $i as index of sorted A and sorted B
		    $A2B_mapping[$S2A_mapping->[$i]] = $S2B_mapping->[$i];
		}
		################## report mapping
		printn "compare_isomorphic: ISOMORPHIC (identical without re-arrangement)" if $verbosity >= 2;
		if ($verbosity >= 3) {
		    printn "compare_isomorphic: mappings are sorted->A: @$S2A_mapping, sorted->B: @$S2B_mapping, B->A: @A2B_mapping";
		    my $A_scalar_colours_ref = $node_colours_ref_of{$A_ID}{scalar};
		    my $B_scalar_colours_ref = $node_colours_ref_of{$B_ID}{scalar};
		    for (my $i=0; $i<(@A2B_mapping); $i++) {
			printn "compare_isomorphic: A2B_mapping[$i]:  ".$B_scalar_colours_ref->[$A2B_mapping[$i]]." <-> ".$A_scalar_colours_ref->[$i];
		    }
		}
		################## return mapping
		return \@A2B_mapping;
	    } else {
		printn "compare_isomorphic: NOT ISOMORPHIC (different nodes)" if $verbosity >= 3;
		return 0;
	    }
	} else {
		printn "compare_isomorphic: POSSIBLY ISOMORPHIC (same nodes)" if $verbosity >= 3;
	}

	# straight compare of ordered graph did not yield an answer, so we need to do a brute-force
	# isomorphic comparison -- comparing (sorted) A to all arrangements of (sorted) B
	printn "compare_isomorphic: INCONCLUSIVE -- trying permutations" if $verbosity >= 3;

	printn "compare_isomorphic: (generating arrangements....)" if $verbosity >= 3;
	# brute force version
#	my $permutation_list_ref = generate_arrangements([(0..$last_A)]);
	# smart version only re-arranges nodes of the same colour
	my $permutation_list_ref = generate_permutations($B_ref->get_group_sizes_ref());
	my $permutation_count = 0;
	# we use a slice to skip over 0th permutation, since it involves no re-arrangement
	foreach my $R2B_mapping (@{$permutation_list_ref}[1..$#{$permutation_list_ref}]) {
	    $permutation_count++;
	    my ($R_matrix_ref, $R_node_colours_ref) = rearrange_graph_matrix($B_matrix_ref, $B_node_colours_ref, $R2B_mapping);
	    if (compare_identical($A_matrix_ref, $A_node_colours_ref, $R_matrix_ref, $R_node_colours_ref)) {
		my @A2B_mapping;
		################## compute mapping
		for (my $i=0; $i<(@$S2B_mapping); $i++) { # think of $i as index of sorted_A and rearranged_B
		    $A2B_mapping[$S2A_mapping->[$i]] = $S2B_mapping->[$R2B_mapping->[$i]];
		}
		################## report mapping
		if ($verbosity >= 3) {
		    printn "compare_isomorphic: successful permutation was @$R2B_mapping";
		    printn "compare_isomorphic: mappings are sorted->A: @$S2A_mapping, sorted->B: @$S2B_mapping, sB->sA: @$R2B_mapping, A->B: @A2B_mapping";
		    my $A_scalar_colours_ref = $node_colours_ref_of{$A_ID}{scalar};
		    my $B_scalar_colours_ref = $node_colours_ref_of{$B_ID}{scalar};
		    for (my $i=0; $i<(@A2B_mapping); $i++) {
			printn "compare_isomorphic: A2B_mapping[$i]:  ".$B_scalar_colours_ref->[$A2B_mapping[$i]]." <-> ".$A_scalar_colours_ref->[$i];
			
		    }
		}
		################## report no. permutations and return mapping
		printn "compare_isomorphic: ISOMORPHIC (identical after $permutation_count permutations)" if $verbosity >= 2;
		return \@A2B_mapping;
	    }
	}

	printn "compare_isomorphic: NOT ISOMORPHIC (but same set of nodes)" if $verbosity >= 3;
	return 0;
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

	$graph_matrix_ref_of{$obj_ID} = {primary => []};
	$node_colours_ref_of{$obj_ID} = {primary => []};
	$nodes_ref_of{$obj_ID} = {primary => []};
	$valid_flags_ref_of{$obj_ID} = {};

	if (defined $arg_ref->{nodes}) {
	    my @nodes = @{$arg_ref->{nodes}};
	    map {
		if (ref $_) {
		    $self->add_node($_->get_name(), $_);
		} else {
		    $self->add_node($_);
		}
	    } @nodes;
	}
    }


    #--------------------------------------------------------------------------------------
    # Function: clear_graphs
    # Synopsys: Delete derived graphs and mark as invalid.
    #--------------------------------------------------------------------------------------
    sub clear_graphs {
	my $self = shift;
	my $obj_ID = ident $self;
	
	$valid_flags_ref_of{$obj_ID} = {};  # derived graphs are out of date

	foreach my $key (keys %{$graph_matrix_ref_of{$obj_ID}}) {
	    next if ($key eq "primary");
	    delete $graph_matrix_ref_of{$obj_ID}{$key};
	    delete $node_colours_ref_of{$obj_ID}{$key};
	    delete $nodes_ref_of{$obj_ID}{$key};
	    delete $mappings_ref_of{$obj_ID}{$key};
	}
	delete $group_sizes_ref_of{$obj_ID};
    }

    #--------------------------------------------------------------------------------------
    # FUNCTIONS FOR GENERATING CANONICAL FORM
    #--------------------------------------------------------------------------------------

    #--------------------------------------------------------------------------------------
    # Function: scalarize_and_sort_edges
    # Synopsys: Scalarize all nested edges and sort them alphabetically.
    #--------------------------------------------------------------------------------------
    sub scalarize_and_sort_edges {
	my $self = shift;
	my $src = shift || "ungrouped";
	my $dst = shift || "scalar";
	my $obj_ID = ident $self;

	my $valid_flags_ref = $valid_flags_ref_of{$obj_ID};
	return if (defined $valid_flags_ref->{$dst} && $valid_flags_ref->{$dst});

	my $src_graph_matrix_ref = $graph_matrix_ref_of{$obj_ID}{$src};
	my $src_node_colours_ref = $node_colours_ref_of{$obj_ID}{$src};
	my $src_nodes_ref = $nodes_ref_of{$obj_ID}{$src};
	my $graph_size = @{$src_graph_matrix_ref};

	if ($src ne $dst) {
	    $self->get_graph_matrix_ref()->{$dst} = [];
	    @{$self->get_node_colours_ref()->{$dst}} = @$src_node_colours_ref;
	    @{$self->get_nodes_ref()->{$dst}} = @$src_nodes_ref;
	}
	my $dst_graph_matrix_ref = $self->get_graph_matrix_ref()->{$dst};

	for (my $i = 0; $i < $graph_size; $i++) {
	    for (my $j = 0; $j < $graph_size; $j++) {
		my $src_edge_list_ref = $src_graph_matrix_ref->[$i][$j];
		my $dst_edge_list_ref = [sort map {
		    ref $_ ? join(".",@{$_->[1]}).$_->[0].join(".",@{$_->[2]}) : $_
		} @$src_edge_list_ref];
		$dst_graph_matrix_ref->[$i][$j] = $dst_edge_list_ref;
	    }
	}

	$valid_flags_ref_of{$obj_ID}{$dst} = 1;
    }
	
    #--------------------------------------------------------------------------------------
    # Function: get_node_shading
    # Synopsys: Generate node shading according to the colour of fanout and fanin nodes.
    #           More precisely, "shading" consists of a CRC32 over the concatenation
    #           of the colours of connected nodes.  The edge colour does not affect shading.
    #--------------------------------------------------------------------------------------
    use String::CRC32;
    sub get_node_shading {
	my $matrix_ref = shift;
	my $shades_ref = shift;

	# !!! should also use edge colour ???
	# (this could reduce number of necessary shading iterations)

	my $new_shades_ref = [];
	for (my $i=0; $i < @{$matrix_ref}; $i++) {
	    my $row_ref = $matrix_ref->[$i];
	    my $col_ref = [map {$matrix_ref->[$_][$i]} (0..$#{$row_ref})];
	    my $row_shade = join ",", sort {$a cmp $b} grep {defined $_} (map {@{$row_ref->[$_]} ? $shades_ref->[$_] : undef} (0..$#{$row_ref}));
	    my $col_shade = join ",", sort {$a cmp $b} grep {defined $_} (map {@{$col_ref->[$_]} ? $shades_ref->[$_] : undef} (0..$#{$col_ref}));
	    my $shade_crc = crc32("$row_shade|$col_shade");
# use this line for hex shading
#	    $new_shades_ref->[$i] = sprintf($shades_ref->[$i]."\[%04X\]", $shade_crc);
	    $new_shades_ref->[$i] = $shades_ref->[$i]."{$shade_crc}";
	}

	return $new_shades_ref;
    }

    #--------------------------------------------------------------------------------------
    # Function: order_nodes
    # Synopsys: Generate canonical node labels and re-order graph matrix accordingly.
    #           The canonical node labels (colours) are generated based on the actual
    #           node's colour, but "shaded" with information about which nodes it is
    #           connected to.
    #--------------------------------------------------------------------------------------
    # This configuration variable sets the number of shading iterations
    # when deriving canonical node colour.
    use vars qw($graph_shading_iterations);
    $graph_shading_iterations = 3;
    sub order_nodes {
	my $self = shift;
	my $src = shift || "scalar";
	my $dst = shift || "canonical";
	my $obj_ID = ident $self;

	my $valid_flags_ref = $valid_flags_ref_of{$obj_ID};
	return if (defined $valid_flags_ref->{$dst} && $valid_flags_ref->{$dst});

	my $src_graph_matrix_ref = $graph_matrix_ref_of{$obj_ID}{$src};
	my $src_node_colours_ref = $node_colours_ref_of{$obj_ID}{$src};
	my $src_nodes_ref = $nodes_ref_of{$obj_ID}{$src};
	my $graph_size = @{$src_graph_matrix_ref};

	# call shading routine 3 times (!!! can we be smarter here ???)
	my $src_node_shades_ref = $src_node_colours_ref;
	for (my $i = 0; $i < $graph_shading_iterations; $i++) {
	    $src_node_shades_ref = get_node_shading($src_graph_matrix_ref, $src_node_shades_ref);
	}

	my ($dst_graph_matrix_ref, $dst_node_colours_ref, $dst_nodes_ref, $D2S_mapping_ref) =
	sort_graph_matrix($src_graph_matrix_ref, $src_node_shades_ref, $src_nodes_ref);

	my @group_sizes = ();
	my $group_index = -1;
	my $last_colour = "";
	foreach my $colour (@$dst_node_colours_ref) {
	    if ($colour ne $last_colour) {
		$group_index++;
	    }
	    $group_sizes[$group_index]++;
	    $last_colour = $colour;
	}
	$group_sizes_ref_of{$obj_ID} = \@group_sizes;

	$graph_matrix_ref_of{$obj_ID}{$dst} = $dst_graph_matrix_ref;
	$node_colours_ref_of{$obj_ID}{$dst} = $dst_node_colours_ref;
	$nodes_ref_of{$obj_ID}{$dst} = $dst_nodes_ref;
	$mappings_ref_of{$obj_ID}{$dst} = $D2S_mapping_ref;

	$valid_flags_ref_of{$obj_ID}{$dst} = 1;
    }

    #--------------------------------------------------------------------------------------
    # Function: canonize
    # Synopsys: Scalarize and sort edges, order nodes.
    #--------------------------------------------------------------------------------------
    sub canonize {
	my $self = shift;
	my $obj_ID = shift;

	$self->scalarize_and_sort_edges("primary");
	$self->order_nodes();
    }

    #--------------------------------------------------------------------------------------
    # PRIMARY GRAPH MANIPULATION
    #--------------------------------------------------------------------------------------

    #--------------------------------------------------------------------------------------
    # Function: add_node
    # Synopsys: Adds a node to the primary graph.
    #--------------------------------------------------------------------------------------
    sub add_node {
	my $self = shift;
	my $colour = shift;
	my $node_ref = shift;
	my $obj_ID = ident $self;

	$self->clear_graphs();

	my $graph_matrix_ref = $graph_matrix_ref_of{$obj_ID}{primary};
	my $node_colours_ref = $node_colours_ref_of{$obj_ID}{primary};
	my $nodes_ref = $nodes_ref_of{$obj_ID}{primary};

	my $current_size = $self->get_graph_size();
	push @{$node_colours_ref}, $colour;
	push @{$nodes_ref}, $node_ref;
	for (my $i = 0; $i < $current_size; $i++) {
	    push @{$graph_matrix_ref->[$current_size]}, [];  # creates new row
	}
	for (my $i = 0; $i < ($current_size + 1); $i++) {
	    push @{$graph_matrix_ref->[$i]}, []; # creates new column
	}
    }

    #--------------------------------------------------------------------------------------
    # Function: add_uni_edge/del_uni_edge(x_address, y_address, colour)
    # Synopsys: Add/delete an edge from node x to node y.  Each address is a single
    #           scalar node index, or a reference to a list of nested indexes.
    #--------------------------------------------------------------------------------------
    sub add_uni_edge {
	my ($self, $x_address_ref, $y_address_ref, $colour) = @_;
	my $obj_ID = ident $self;

	$self->clear_graphs();

	confess "ERROR: colour not specified" if !defined $colour;

	# deal with scalars and copy address
	my @x_address = ref $x_address_ref ? @$x_address_ref : ($x_address_ref);
	my @y_address = ref $y_address_ref ? @$y_address_ref : ($y_address_ref);

	my $x_top = shift @x_address;
	my $y_top = shift @y_address;

	confess "ERROR: src node index ($x_top) is too large\n" if ($x_top >= $self->get_graph_size());
	confess "ERROR: dst node index ($y_top) is too large\n" if ($y_top >= $self->get_graph_size());
	
	my $graph_matrix_ref = $graph_matrix_ref_of{$obj_ID}{primary};

	push @{$graph_matrix_ref->[$x_top][$y_top]}, [$colour, \@x_address, \@y_address];
    }

    sub del_uni_edge {
	my ($self, $x_address_ref, $y_address_ref, $colour) = @_;
	my $obj_ID = ident $self;

	$self->clear_graphs();

	# deal with scalars and copy address
	my @x_address = ref $x_address_ref ? @$x_address_ref : ($x_address_ref);
	my @y_address = ref $y_address_ref ? @$y_address_ref : ($y_address_ref);

	my $x_top = shift @x_address;
	my $y_top = shift @y_address;

	confess "ERROR: src node index ($x_top) is too large\n" if ($x_top >= $self->get_graph_size());
	confess "ERROR: dst node index ($y_top) is too large\n" if ($y_top >= $self->get_graph_size());
	
	my $graph_matrix_ref = $graph_matrix_ref_of{$obj_ID}{primary};
	my $edge_list_ref = $graph_matrix_ref->[$x_top][$y_top];
	for (my $i=0; $i < @{$edge_list_ref}; $i++) {
	    my $edge_ref = $edge_list_ref->[$i];  # edge_ref is in the nested format
	    if (join(";",($colour,"@x_address","@y_address")) eq
		join(";",($edge_ref->[0],"@{$edge_ref->[1]}","@{$edge_ref->[2]}"))) {
		splice @{$edge_list_ref}, $i, 1;
		# return true since edge removed successfully
		return 1;
	    }
	}
	confess "ERROR: internal error -- tried to remove non-existent edge";
	return undef;
    }

    #--------------------------------------------------------------------------------------
    # Function: add_bi_edge/del_bi_edge
    # Synopsys: Add an edge from node x to node y.
    #--------------------------------------------------------------------------------------
    sub add_bi_edge {
	my ($self, $x_address_ref, $y_address_ref, $forward_edge_colour, $backward_edge_colour) = @_;
	$backward_edge_colour = $forward_edge_colour if (!defined $backward_edge_colour);
	$self->Graph::add_uni_edge($x_address_ref, $y_address_ref, $forward_edge_colour);
	$self->Graph::add_uni_edge($y_address_ref, $x_address_ref, $backward_edge_colour);
    }

    sub del_bi_edge {
	my ($self, $x_address_ref, $y_address_ref, $forward_edge_colour, $backward_edge_colour) = @_;
	$backward_edge_colour = $forward_edge_colour if (!defined $backward_edge_colour);

	# return 1 if both edges removed successfully
	return ($self->Graph::del_uni_edge($x_address_ref, $y_address_ref, $forward_edge_colour) &&
		$self->Graph::del_uni_edge($y_address_ref, $x_address_ref, $backward_edge_colour));
    }

    #--------------------------------------------------------------------------------------
    # Function: concat_subset(refs =>[], subsets =>[], Graph => 0|1) (CUMULATIVE)
    # Synopsys: Concatenate given subsets of each the argument object (in ref) into self.
    #           Order of elements in subset is significant, so this routine can also be
    #           used to re-arrange a Graph.  Operates on primary graph.
    #--------------------------------------------------------------------------------------
    sub concat_subset : CUMULATIVE {
	my $self = shift;
	my %args = @_;

	my $obj_ID = ident $self;

	$self->clear_graphs();

	confess "ERROR: invalid argument -- use 'subsets' not 'subset'" if (exists $args{subset});
	confess "ERROR: subsets must contain a list of refs" if (exists $args{subsets} && !(ref $args{subsets}->[0]));

	if (!(exists $args{Graph}) || $args{Graph}) {

	    my $dst_matrix_ref = $graph_matrix_ref_of{$obj_ID}{primary};
	    my $dst_node_colours_ref = $node_colours_ref_of{$obj_ID}{primary};
	    my $dst_nodes_ref = $nodes_ref_of{$obj_ID}{primary};

	    my @refs = @{$args{refs}};

	    for (my $k=0; $k < @refs; $k++) {
		my $ref = $refs[$k];
		my $ref_ID = ident $ref;

		my $subset_ref = (exists $args{subsets}) ? $args{subsets}->[$k] : undef;

		my $src_matrix_ref = $graph_matrix_ref_of{$ref_ID}{primary};
		my $src_node_colours_ref = $node_colours_ref_of{$ref_ID}{primary};
		my $src_nodes_ref = $nodes_ref_of{$ref_ID}{primary};

		concat_matrix_subset($dst_matrix_ref, $dst_node_colours_ref, $dst_nodes_ref,
				     $src_matrix_ref, $src_node_colours_ref, $src_nodes_ref,
				     $subset_ref);
	    }
	}
    }

    #--------------------------------------------------------------------------------------
    # Function: concat
    # Synopsys: An alias for concat_subset (which is CUMULATIVE).
    #--------------------------------------------------------------------------------------
    sub concat {
	my $self = shift;

	$self->concat_subset(@_);
    }

    #--------------------------------------------------------------------------------------
    # Function: offset_bi_edge_join
    # Synopsys: Join given graphs with the given bidirectional edge.
    #           The address of second node is offset by given amount.
    #           This routine is useful to add an edge after a concatenation of graphs,
    #           using the original addresses.
    #--------------------------------------------------------------------------------------
    sub offset_bi_edge_join {
	my $self = shift;
	my ($x_address_ref, $y_address_ref, $colour, $offset) = @_;

	# deal with scalars and copy address
	my @x_address = ref $x_address_ref ? @$x_address_ref : ($x_address_ref);
	my @y_address = ref $y_address_ref ? @$y_address_ref : ($y_address_ref);

	$y_address[0] += $offset;  # to account for concatenation

	$self->Graph::add_bi_edge(\@x_address, \@y_address, $colour);
    }

    #--------------------------------------------------------------------------------------
    # Function: get_edges
    # Synopsys: Get edges from given tail node to given head node, return a list.
    #--------------------------------------------------------------------------------------
    sub get_edges {
	my $self = shift;
	my $colour = shift;
	my $tail_node = shift;  # number or nested address
	my $head_node = shift;  # number or nested address

	my ($tail_node_row, @tail_node_nested) = ref $tail_node ? @$tail_node : ($tail_node);
	my ($head_node_col, @head_node_nested) = ref $head_node ? @$head_node : ($head_node);

	my @edges = ();

	my $edge_list_ref = $graph_matrix_ref_of{ident $self}{primary}[$tail_node_row][$head_node_col];

	EDGE: foreach my $edge_ref (@$edge_list_ref) {
	      next if (($edge_ref->[0] ne $colour) && ($colour ne "*"));
	      my $edge_tail_ref = $edge_ref->[1];
	      my $edge_head_ref = $edge_ref->[2];

	      # sub-indices must match if they exist
	      for (my $j = 0; $j < @tail_node_nested; $j++) {
		  next EDGE if !defined $edge_tail_ref->[$j];
		  next EDGE if $tail_node_nested[$j] != $edge_tail_ref->[$j];
	      }
	      # sub-indices must match if they exist
	      for (my $j = 0; $j < @head_node_nested; $j++) {
		  next EDGE if !defined $edge_head_ref->[$j];
		  next EDGE if $head_node_nested[$j] != $edge_head_ref->[$j];
	      }

	      push @edges, $edge_ref;
	  }
	return \@edges;
    }

    #--------------------------------------------------------------------------------------
    # Function: get_connected_component
    # Synopsys: Get all top-lvl node indexes which fanin/fanout to given top-lvl node,
    #           regardless of edge nesting.
    #--------------------------------------------------------------------------------------
    sub get_connected_component {
	my $self = shift;
	my $colour = shift;
	my $node = shift;

	my @new_nodes = ($node);
	my @connected = ($node);

	while (@new_nodes > 0) {
	    # add nesting wildcard to fanin/fanout address
	    @new_nodes = map {[$_,'*']} @new_nodes;
	    # remove nesting in addresses returned by fanin/fanout
	    my @fanin = map {(ref $_) ? $_->[0] : $_} @{($self->get_node_fanin("primary",$colour, @new_nodes))[0]};
	    my @fanout = map {(ref $_) ? $_->[0] : $_} @{($self->get_node_fanout("primary",$colour, @new_nodes))[0]};

	    @new_nodes = simple_difference([@fanin, @fanout], \@connected);
	    @connected = union(\@connected, [@new_nodes]);
	}
	return \@connected;
    }

    #--------------------------------------------------------------------------------------
    # KEYED GRAPH METHODS
    #--------------------------------------------------------------------------------------

    #--------------------------------------------------------------------------------------
    # Function: get_graph_size
    # Synopsys: Returns the number of nodes in primary (or given) graph.
    #--------------------------------------------------------------------------------------
    sub get_graph_size {
	my $self = shift;
	my $key = shift || "primary";

	return scalar @{$graph_matrix_ref_of{ident $self}{$key}};
    }

    #--------------------------------------------------------------------------------------
    # Function: get_node_colours
    # Synopsys: Gets node colours vector of primary (or given) graph.
    #--------------------------------------------------------------------------------------
    sub get_node_colours {
	my $self = shift;
	my $key = shift || "primary";

	return @{$node_colours_ref_of{ident $self}{$key}};
    }

    #--------------------------------------------------------------------------------------
    # Function: get_node_refs
    # Synopsys: Gets node refs vector of primary (or given) graph.
    #--------------------------------------------------------------------------------------
    sub get_node_refs {
	my $self = shift;
	my $key = shift || "primary";

	return @{$nodes_ref_of{ident $self}{$key}};
    }

    #--------------------------------------------------------------------------------------
    # Function: sprint_graph_matrix
    # Synopsys: Print graph matrix to string.
    #--------------------------------------------------------------------------------------
    sub sprint_graph_matrix {
	my $self = shift;
	my $key = shift || "primary";
	my $obj_ID = ident $self;

	my $graph_matrix_ref = $graph_matrix_ref_of{$obj_ID}{$key};
	my @node_colours = @{$node_colours_ref_of{$obj_ID}{$key}};

	if (!@node_colours) {
	    printn "WARNING: empty graph matrix";
	    return "";
	}

	# remove shading
	map {$node_colours[$_] =~ s/\{.*\}//} (0..$#node_colours);

	my $graph_size = @node_colours;

	my @column_width = ();

	for (my $j = 0; $j < $graph_size; $j ++) {
	    $column_width[$j] = length($node_colours[$j]);
	}
	my $longest_colour = max_numeric(@column_width);

	my $str;

	# first line with labels
	$str .= sprintf(" | %-${longest_colour}s", " ");
	$str .= join "", (map {sprintf(" | %-$column_width[$_]s", $node_colours[$_])} (0..$#node_colours));
	$str .= "\n";

	for (my $i = 0; $i < $graph_size; $i ++) {
	    # first column with labels
	    $str .= sprintf(" | %-${longest_colour}s", $node_colours[$i]);
	    for (my $j = 0; $j < $graph_size; $j ++) {
		# if some elements are undefined, make it obvious
		my $temp_ref = !defined $graph_matrix_ref->[$i][$j] ? ["UNDEF"] : $graph_matrix_ref->[$i][$j];
		# some edges are lists (because nested), some are scalars
		my $edges = join(",", map {ref $_ ? (join(".", @{$_->[1]}).$_->[0].join(".", @{$_->[2]})) : $_ } @$temp_ref);
		# if no edges, substitute a placeholder
		$edges = ($edges eq "" ? "-" : $edges);
		$str .= sprintf(" | %-$column_width[$j]s", $edges);
	    }
	    $str .= "\n";
	}
	return $str;
    }

    #--------------------------------------------------------------------------------------
    # Function: get_node_fanout(colour, tail_nodes....)
    # Synopsys: Returns the head node indices bound to given tail nodes by edges of the
    #           given colour.  The given address of the tail nodes may include sub-indices,
    #           in which case the edge must depart from that node, or any nested node
    #           if the last tail node sub-index is '*'.
    #           In all cases, the head node addresses are returned with all
    #           relevant indices.
    # Example:  get_node_fanout(':',1,[0,1,1]) returns fanout of node 1 and fanout of nested
    #           node (0,1,1) to nodes joined by edges of colour ':'.
    #           get_node_fanout(':',[2,1,'*']) returns fanout of node (2,1) and also of any
    #           nested nodes.
    #--------------------------------------------------------------------------------------
    sub get_node_fanout {
	my $self = shift;
	my $key = shift;
	my $colour = shift;
	my @tail_nodes = @_;

	my $graph_matrix_ref = $graph_matrix_ref_of{ident $self}{$key};
	my $graph_size = @$graph_matrix_ref;

	my @fanout_addresses = ();
	my @fanout_edges = ();
	foreach my $tail_node (@tail_nodes) {
	    my ($tail_node_row, @tail_node_nested) = ref $tail_node ? @$tail_node : ($tail_node);
	    my $any_subindex_flag = defined $tail_node_nested[$#tail_node_nested] && $tail_node_nested[$#tail_node_nested] eq '*';
	    pop @tail_node_nested if $any_subindex_flag;  # remove the '*'
	    my $graph_matrix_row_ref = $graph_matrix_ref->[$tail_node_row];
	    for (my $i = 0; $i < $graph_size; $i++) {  # for each column....
		my $edge_list_ref = $graph_matrix_row_ref->[$i];
		EDGE : foreach my $edge_ref (@$edge_list_ref) {
		    my $edge = $edge_ref->[0];
		    my $edge_colour = substr($edge,0,1);
		    next if (($edge_colour ne $colour) && ($colour ne "*"));
		    my $edge_tail_ref = $edge_ref->[1];
		    # sub-indices must match if they exist
		    next EDGE if (@tail_node_nested < @{$edge_tail_ref}) && (!$any_subindex_flag);
		    INDEX : for (my $j = 0; $j < @tail_node_nested; $j++) {
			next EDGE if !defined $edge_tail_ref->[$j];
			next EDGE if $tail_node_nested[$j] != $edge_tail_ref->[$j];
		    }
		    push @fanout_addresses, [$i, @{$edge_ref->[2]}];
		    push @fanout_edges, $edge;
		}
	    }
	}
	return \@fanout_addresses, \@fanout_edges;
    }

    my %out_degree_cache;
    sub get_out_degree {
	my $self = shift; my $obj_ID = ident $self;
	my $key = shift;
	my $colour = shift;
	my $tail_node = shift;

	my $tail_node_key = ref $tail_node ? (join " ", @$tail_node) : "$tail_node";
	my $cache_key = $obj_ID.$colour.$tail_node_key;
	my $cached_value = $out_degree_cache{$cache_key};
	return $cached_value if defined $cached_value;

	my $fanout_addresses_ref = ($self->get_node_fanout($key, $colour, $tail_node))[0];
	return $out_degree_cache{$cache_key} = scalar(@$fanout_addresses_ref);
    }

    #--------------------------------------------------------------------------------------
    # Function: get_node_fanin(colour, head_nodes....)
    # Synopsys: Same idea/interface as get_node_fanout.
    #--------------------------------------------------------------------------------------
    sub get_node_fanin {
	my $self = shift;
	my $key = shift;
	my $colour = shift;
	my @head_nodes = @_;

	my $graph_matrix_ref = $graph_matrix_ref_of{ident $self}{$key};
	my $graph_size = @$graph_matrix_ref;

	my @fanin_address = ();
	my @fanin_edges = ();
	foreach my $head_node (@head_nodes) {
	    my ($head_node_col, @head_node_nested) = ref $head_node ? @$head_node : ($head_node);
	    my $any_subindex_flag = defined $head_node_nested[$#head_node_nested] && $head_node_nested[$#head_node_nested] eq '*';
	    pop @head_node_nested if $any_subindex_flag;  # remove the '*'
	    for (my $i = 0; $i < $graph_size; $i++) {  # for each row....
		my $edge_list_ref = $graph_matrix_ref->[$i][$head_node_col];
		EDGE : foreach my $edge_ref (@$edge_list_ref) {
		    my $edge = $edge_ref->[0];
		    my $edge_colour = substr($edge,0,1);
		    next if (($edge_colour ne $colour) && ($colour ne "*"));
		    my $edge_head_ref = $edge_ref->[2];
		    # sub-indices must match if they exist
		    next EDGE if (@head_node_nested < @{$edge_head_ref}) && (!$any_subindex_flag);
		    INDEX : for (my $j = 0; $j < @head_node_nested; $j++) {
			next EDGE if !defined $edge_head_ref->[$j];
			next EDGE if $head_node_nested[$j] != $edge_head_ref->[$j];
		    }
		    push @fanin_address, [$i, @{$edge_ref->[1]}];
		    push @fanin_edges, $edge;
		}
	    }
	}
	return \@fanin_address, \@fanin_edges;
    }

    #--------------------------------------------------------------------------------------
    # Function: get_adjacency_matrix
    # Synopsys: Construct and return an adjacency matrix from the graph matrix.
    #--------------------------------------------------------------------------------------
    sub get_adjacency_matrix {
	my $self = shift;
	my $key = shift || "primary";

	my $graph_matrix_ref = $graph_matrix_ref_of{ident $self}{$key};
	my $last_index = $#{$graph_matrix_ref->[0]};

	my $m1_ref = Matrix->new();
	my $m1_matrix_ref = $m1_ref->get_matrix_ref();

	for (my $i = 0; $i < @{$graph_matrix_ref}; $i++) {  # 1st to last row
	    @{$m1_matrix_ref->[$i]} = map {scalar(@$_)} @{$graph_matrix_ref->[$i]}[0..$last_index];
	}

	$m1_ref = Matrix->mnonzero($m1_ref);
	return $m1_ref;
    }

    #--------------------------------------------------------------------------------------
    # Function: export_graphviz
    # Synopsys: Exports the nested Graph to graphviz.  Supports mixed directed/undirected.
    #           Detects pairs of directed edges, collapsing them into an undirected edge.
    #--------------------------------------------------------------------------------------
    sub export_graphviz {
	my $self = shift; my $obj_ID = ident $self;
	my %args = (
	    filename => "Graph.png",
	    src => "primary",
	    @_,
	   );
	check_args(\%args, 2);

	eval "use GraphViz";
	if ($@) {    # in case GraphViz is not present
	    printn "WARNING: GraphViz is not properly installed, cannot export Graph objects...";
	    print $@ if $verbosity >= 2;
	    return;
	}

	my $filename = $args{filename};
	my $src = $args{src};

	my $gv_ref = GraphViz->new(directed => 1);

	my $graph_matrix_ref = dclone($graph_matrix_ref_of{$obj_ID}{$src});  # clone it first
	my @node_labels = @{$node_colours_ref_of{$obj_ID}{$src}};
	my @node_refs = @{$nodes_ref_of{$obj_ID}{$src}};
	my $graph_size = @$graph_matrix_ref;

	my @node_names = ();

	for (my $i = 0; $i < @node_labels; $i++) {
	    $node_names[$i] = "N$i";
	    my $label = $node_labels[$i];
	    $label =~ s/\{.*\}//;  # remove shading
	    my $shape = (defined $node_refs[$i] &&
			 ($node_refs[$i]->isa('Node') || $node_refs[$i]->isa('NodeInstance')) &&
			 $node_refs[$i]->get_group_node_flag()) ? "triangle" : "";
	    my $allosteric_flag = (defined $node_refs[$i] && (
		$node_refs[$i]->isa('AllostericSite') ||
		$node_refs[$i]->isa('AllostericSiteInstance'))) ? 1 : 0;
	    my $color = $allosteric_flag ? "green" : "";
	    my $style = $allosteric_flag ? "filled" : "";
	    $gv_ref->add_node("$node_names[$i]",
			      label => $label,
			      shape => $shape,
			      fillcolor => $color,
			      style => $style,
			     );
	}

	# first pass to find all edges and index them
	my $edges_ref;
	for (my $i = 0; $i < $graph_size; $i ++) {
	    for (my $j = 0; $j < $graph_size; $j ++) {
		foreach (my $k = 0; $k < @{$graph_matrix_ref->[$i][$j]}; $k++) {
		    my $edge_ref = $graph_matrix_ref->[$i][$j][$k];
		    if (ref $edge_ref) {
			my $edge_colour = $edge_ref->[0];
			my $tail_label = join ".",@{$edge_ref->[1]};
			my $head_label = join ".",@{$edge_ref->[2]};
			$edges_ref->[$i][$j]{"$edge_colour,$tail_label,$head_label"}++;
		    } else {
			# edge has been scalarized, need to separate colour from src/dst address
			# e.g.  "3.4:1.0"
			# e.g.  "3.4g1.0"
			# e.g.  "3.4~{9.1}1.0"
			#printn "XXX1 $edge_ref";
			if ($edge_ref =~ /(^[0-9.]*)([^0-9.{]+(\{.*\})?)([0-9.]*)/) {
			    my $tail_label = $1;
			    my $edge_colour = $2;
			    my $head_label = $4;
			    #printn "XXX2 $tail_label XXX $edge_colour XXX $head_label";
			    $edges_ref->[$i][$j]{"$edge_colour,$tail_label,$head_label"}++;
			} else {
			    confess "ERROR: internal error, couldn't figure out colour";
			}
		    }
		}
	    }
	}

	# second pass uses index to figure out which edges are directed and not:
	# two uni-edges of the same colour and opposite direction can be
	# collapsed into one un-directed edge
	for (my $i = 0; $i < $graph_size; $i ++) {
	    for (my $j = 0; $j < $graph_size; $j ++) {
		foreach my $key (keys %{$edges_ref->[$i][$j]}) {
		    my ($edge_colour, $tail_label, $head_label) = split(",", $key);
		    while ($edges_ref->[$i][$j]{$key}--) {
			my $directed_edge = 1;
			if ((defined $edges_ref->[$j][$i]{"$edge_colour,$head_label,$tail_label"}) &&
			    ($edges_ref->[$j][$i]{"$edge_colour,$head_label,$tail_label"}) > 0) {
			    $directed_edge = 0;
			    $edges_ref->[$j][$i]{"$edge_colour,$head_label,$tail_label"}--;
			}
			my $style;
			my $colour;
			if (substr ($edge_colour,0,1) eq '~') {
			    $colour = "green";
			    $style = "dotted";
			} else {
			    $colour = "black";
			    $style = "solid";
			}
			$gv_ref->add_edge($node_names[$i] => $node_names[$j],
					  labeldistance => 1.0, labelangle => 45, labelfontsize => 6,
					  color => $colour, style => $style,
					  taillabel => $tail_label, headlabel => $head_label,
					  dir => $directed_edge ? "forward" : "none", label => "$edge_colour");
		    }
		}
	    }
	}

	my $basename = $filename;
	my $ext = "svg";
	if ($basename =~ /(.*)\.(\w+)$/) {
	    $basename = $1;
	    $ext = $2;
	}
	my $type = $ext eq "jpg" ? "jpeg" : $ext;

	eval "\$gv_ref->as_$type(\"${basename}.$ext\")";
	if ($@) {
	    printn $@;
	    die "ERROR: unsupported format -- $type" ;
	}
    }

    #--------------------------------------------------------------------------------------
    # Function: check (CUMULATIVE)
    # Synopsys: Check that row and column labels are the same, and that graph is
    #           connected.
    #--------------------------------------------------------------------------------------
    sub check : CUMULATIVE(BASE FIRST) {
	my $self = $_[0]; my $obj_ID = ident $self;
	my $key = $_[1] || "primary";

	printn "CHECKING GRAPH ".$self->get_name() if ($verbosity >= 3);

	# check that node colours and the matrix have same size
	my $graph_matrix_ref = $graph_matrix_ref_of{$obj_ID}{$key};
	my $node_colours_ref = $node_colours_ref_of{$obj_ID}{$key};
	my $nodes_ref = $nodes_ref_of{$obj_ID}{$key};
	confess "ERROR: internal error -- in ".$self->get_name()." graph colours and matrix are not consistent" if (@$graph_matrix_ref != @$node_colours_ref);
	confess "ERROR: internal error -- in ".$self->get_name()." graph nodes and matrix are not consistent" if (@$graph_matrix_ref != @$nodes_ref);

	# check that graph is connected
	my $num_connected = @{$self->get_connected_component('*', 0)};
	my $graph_size = $self->get_graph_size();
	if ($num_connected != $graph_size) {
	    my $name = $self->get_name();
	    my $class = ref $self;
	    printn "ERROR: Graph of $class $name is disjoint";
	    printn $self->sprint_graph_matrix();
	    exit(1);
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
    printn "run_testcases: Graph package";
    $verbosity = 2;

    $graph_shading_iterations = 0;

    printn "ARRANGEMENTS TEST....";
    map {print "@$_\n"} @{generate_arrangements([0,10,100])};
    printn "PERMUTATIONS TEST....";
    map {print "@$_\n"} @{generate_permutations([2,3,2])};

    printn "CREATION, ADD EDGES TEST....";
    my $bm1_ref = Graph->new({
	name => "BM1",
	nodes => ["A"],
    });
#    $bm1_ref->add_node("A");
    $bm1_ref->add_node("B");
    $bm1_ref->add_bi_edge(0, 1, 1, 2);
    $bm1_ref->add_uni_edge(0, 1, 3);
    $bm1_ref->scalarize_and_sort_edges("primary", "primary");
    printn "BM1 = \n".$bm1_ref->sprint_graph_matrix();
    my $m1_ref = $bm1_ref->get_adjacency_matrix();
    printn $m1_ref->sprint_matrix();

    # same edges, different labels
    my $bm2_ref = Graph->new({name => "BM2"});
    $bm2_ref->add_node("A");
    $bm2_ref->add_node("C");
    $bm2_ref->add_bi_edge(0, 1, 1, 2);
    $bm2_ref->add_uni_edge(0, 1, 3);
    $bm2_ref->scalarize_and_sort_edges("primary", "scalar");
    printn "BM2 = \n".$bm2_ref->sprint_graph_matrix("scalar");

    # same as BM1, but edges created in different order
    my $bm3_ref = Graph->new({name => "BM3"});
    $bm3_ref->add_node("A");
    $bm3_ref->add_node("B");
    $bm3_ref->add_uni_edge(0, 1, 3);
    $bm3_ref->add_bi_edge(0, 1, 1, 2);
    $bm3_ref->scalarize_and_sort_edges("primary", "scalar");
    printn "BM3 = \n".$bm3_ref->sprint_graph_matrix("scalar");

    # same as BM1, but nodes are in different order
    my $bm4_ref = Graph->new({name => "BM4"});
    $bm4_ref->add_node("B");
    $bm4_ref->add_node("A");
    $bm4_ref->add_uni_edge(1, 0, 3);
    $bm4_ref->add_bi_edge(1, 0, 1, 2);
    $bm4_ref->scalarize_and_sort_edges("primary", "primary");
    printn "BM4 = \n".$bm4_ref->sprint_graph_matrix();

    # BM5, BM6, BM66 used to exercise isomorphic mapping w/ rearrangement
    my $bm5_ref = Graph->new({name => "BM5"});
    $bm5_ref->add_node("A");
    $bm5_ref->add_node("A");
    $bm5_ref->add_node("B");
    $bm5_ref->add_bi_edge(0, 1, 1);
    $bm5_ref->add_uni_edge(1, 2, "a");
    printn "BM5 = \n".$bm5_ref->sprint_graph_matrix();
    my $m5_ref = $bm5_ref->get_adjacency_matrix();
    printn $m5_ref->sprint_matrix();

    # now swap the two As
    my $bm6_ref = Graph->new({name => "BM6"});
    $bm6_ref->add_node("A");
    $bm6_ref->add_node("A");
    $bm6_ref->add_node("B");
    $bm6_ref->add_bi_edge(0, 1, 1);
    $bm6_ref->add_uni_edge(0, 2, "a");
    printn "BM6 = \n".$bm6_ref->sprint_graph_matrix();

    # now swap B with 2nd A
    my $bm66_ref = Graph->new({name => "BM66"});
    $bm66_ref->add_node("A");
    $bm66_ref->add_node("B");
    $bm66_ref->add_node("A");
    $bm66_ref->add_bi_edge(0, 2, 1);
    $bm66_ref->add_uni_edge(0, 1, "a");
    printn "BM66 = \n".$bm66_ref->sprint_graph_matrix();

    $verbosity = 3;
    printn "ISOMORPHIC COMPARISON TEST...";
    print Graph->compare_isomorphic($bm1_ref, $bm1_ref) ? "OK\n" : "ERROR!!!\n"; # identical
    print Graph->compare_isomorphic($bm1_ref, $bm2_ref) ? "ERROR!!!\n" : "OK\n"; # different nodes
    print Graph->compare_isomorphic($bm1_ref, $bm3_ref) ? "OK\n" : "ERROR!!!\n"; # identical

    # BM4 is not isomorphic at first glance, but is upon sorting
    print Graph->compare_isomorphic($bm1_ref, $bm4_ref) ? "OK\n" : "ERROR!!!\n"; # identical after sort

    # BM5 vs BM6 compare requires re-arrangement (of A proteins only) because two identical proteins
    print Graph->compare_isomorphic($bm5_ref, $bm6_ref) ? "OK\n" : "ERROR!!!\n"; # identical after rearrangement

    # BM5 vs BM66 compare requires re-arrangement (of A and B proteins) because two identical proteins
    print Graph->compare_isomorphic($bm5_ref, $bm66_ref) ? "OK\n" : "ERROR!!!\n"; # identical after rearrangement

    printn "NODE LABELS TEST...";
    printn join ",", $bm6_ref->get_node_colours();

    # now test the nested addressing and fanin/fanout functions
    printn "NODE FANOUT/FANIN test...";
    ## add some edges to graph
    $bm6_ref->add_uni_edge([0,0,1],[1,0,0],":");
#    $bm6_ref->add_uni_edge(1,0,"*");
#    $bm6_ref->add_bi_edge([1,0,1],[1,0,0],"::");
#    $bm6_ref->add_bi_edge(0,0,"+");
    $bm6_ref->scalarize_and_sort_edges("primary", "scalar");
    print $bm6_ref->sprint_graph_matrix("primary");
    printn Dumper($bm6_ref->get_node_fanout("primary",'*',0));
    printn Dumper($bm6_ref->get_node_fanout("primary",'*',[0,0,1]));
    printn Dumper($bm6_ref->get_node_fanout("primary",'*',1,[0,0,1]));
    printn Dumper($bm6_ref->get_node_fanin("primary",'*',1,[1,0,0]));
    printn Dumper($bm6_ref->get_node_fanout("primary",'*',[0,'*']));
#    printn Dumper($bm6_ref->get_node_fanin("primary",'*',[1,'*']));

    printn "EDGE FANOUT/FANIN test...";
    printn Dumper($bm6_ref->get_edges('*',0,1));
    printn Dumper($bm6_ref->get_edges('*',0,2));
    printn Dumper($bm6_ref->get_edges('*',2,0));
    printn Dumper($bm6_ref->get_edges('*',0,0));
    printn Dumper($bm6_ref->get_edges('*',[0,0,1],[1,0,0]));
    printn Dumper($bm6_ref->get_edges('*',[0,0,1],[1,0,0]));

    printn "CONNECTIVITY test...";
    my $bm7_ref = Graph->new({name => "BM7"});
    $bm7_ref->add_node("A");
    $bm7_ref->add_node("B");
    $bm7_ref->add_node("C");
    $bm7_ref->add_node("D");
    $bm7_ref->add_node("E");
    $bm7_ref->add_bi_edge(1, 2, 2, 1);
    $bm7_ref->add_uni_edge(3, 2, "X");
    $bm7_ref->add_uni_edge(0, 4, "X");
    $bm7_ref->add_uni_edge(4, 0, "Y");
    printn "BM7 = \n".$bm7_ref->sprint_graph_matrix();
    my $m7_ref = $bm7_ref->get_adjacency_matrix();
    printn $m7_ref->sprint_matrix();
    for (my $i = 0; $i < 5; $i++) {
	printn "Connected to BM7 node $i: " . join ",", @{$bm7_ref->get_connected_component('*',$i)};
    }

    printn "GRAPHVIZ test...";
    my $export_dir = "test/modules/Graph";
    system("mkdir -p $export_dir");
    $bm7_ref->export_graphviz(filename => "$export_dir/Graph.bm7.png");

    printn "CONCAT test...";
    my $bm8_ref = Graph->new({name => "BM8"});
    $bm8_ref->concat(refs => [$bm7_ref], subsets => [[0, 1, 4, 2]]);
    printn "BM8 = \n".$bm8_ref->sprint_graph_matrix();

    my $bm9_ref = Graph->new({name => "BM9"});
    $bm9_ref->concat(refs => [$bm7_ref, $bm8_ref], subsets => [[0,1,2,3], [0,1,3,2]]);
    printn "BM9 = \n".$bm9_ref->sprint_graph_matrix();
}

# Package BEGIN must return true value
return 1;

