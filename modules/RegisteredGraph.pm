######################################################################################
# File:     RegisteredGraph.pm
# Author:   Julien F. Ollivier
#
# Copyright (C) 2005-2010 Julien Ollivier.
#
# This program comes with ABSOLUTELY NO WARRANTY.
# This is free software, and you are welcome to redistribute it
# under certain conditions. See file LICENSE.TXT for details.
#
# Synopsys: This Graph sub-class maintains a registry and a list of putative isomorphs,
#           such that isomorphs of a particular graph can be found quickly.
######################################################################################
# Detailed Description:
# ---------------------
######################################################################################

use strict;
use diagnostics;		# equivalent to -w command-line switch
use warnings;

package RegisteredGraph;
use Class::Std::Storable;
use base qw(Registered Graph);
{
    use Carp;
    use Data::Dumper;               # Supports many formats to dump data structures into text

    use Utils;
    use Globals;

    #######################################################################################
    # ATTRIBUTES
    #######################################################################################
    # index where stored in putative isomorph list,
    # also indicating whether object has been stored in this list
    my %putative_isomorph_list_index_of :ATTR(get => 'putative_isomorph_list_index');

    # ordered, stringified node labels of canonical form of graph
    my %ordered_node_labels_of :ATTR(get => 'ordered_node_labels', set => 'ordered_node_labels');

    #######################################################################################
    # FUNCTIONS
    #######################################################################################

    #######################################################################################
    # CLASS METHODS
    #######################################################################################

    sub sprint_putative_isomorph_table {
	my $class = shift;
	my $hash_ref = $class->get_class_data("ISOMORPH_HASH_REF");
	return Dumper($hash_ref);
    }

    #--------------------------------------------------------------------------------------
    # Function: refresh_isomorph_index_hash
    # Synopsys: Completely rebuild the isomorph hash from scratch.
    #--------------------------------------------------------------------------------------
    sub refresh_putative_isomorph_hash {
	my $class = shift;

	printn "refreshing_isomorph_index_hash..." if $verbosity >= 1;

	# reset the hash, and reset attributes that were related to hash
	my $hash_ref = {};
	$class->set_class_data("ISOMORPH_HASH_REF", $hash_ref);
	foreach my $obj_ref ($class->get_instances()) {
	    delete $putative_isomorph_list_index_of{ident $obj_ref};
	    delete $ordered_node_labels_of{ident $obj_ref};
	}
	# now rebuild the hash
	foreach my $obj_ref ($class->get_instances()) {
	    $obj_ref->update_putative_isomorph_hash();
	}
    }

    #--------------------------------------------------------------------------------------
    # Function: check_isomorph_index_hash
    # Synopsys: Make sure all registered RegisteredGraph objects are in the hash.
    #--------------------------------------------------------------------------------------
    sub check_putative_isomorph_hash {
	my $class = shift;

	my $num_instances_in_class = $class->get_instances();

	my $num_instances_in_hash = 0;
	my $hash_ref = $class->get_class_data("ISOMORPH_HASH_REF");
	foreach my $key (keys %$hash_ref) {
	    $num_instances_in_hash += @{$hash_ref->{$key}}
	}
	if ($num_instances_in_class != $num_instances_in_hash) {
	    confess "ERROR: internal error -- not all registered objects of class $class are in ISOMORPH_HASH_REF ($num_instances_in_class in class vs $num_instances_in_hash in hash)";
	}
    }

    #--------------------------------------------------------------------------------------
    # Function: get_putative_isomorph_list
    # Synopsys: Use isomorph index to return a list of putative (possible) isomorphs.
    #--------------------------------------------------------------------------------------
    sub get_putative_isomorph_list {
	my $class = shift;
	my $arg_ref = shift;


	# make sure canonical form is ready
	my $ordered_node_labels = $arg_ref->GET_ordered_node_labels();    # this canonizes if necessary

	printn "get_putative_isomorph_list: finding potential isomorphs for $ordered_node_labels" if $verbosity >= 3;

	my $hash_ref = $class->get_class_data("ISOMORPH_HASH_REF");

	my $return_ref;
	if (defined $hash_ref->{$ordered_node_labels}) {
	    $return_ref = $hash_ref->{$ordered_node_labels};
	    printn "get_putative_isomorph_list: returning (@{$return_ref})" if $verbosity >= 3;
	    return $return_ref;
	} else {
	    printn "get_putative_isomorph_list: found nothing" if $verbosity >= 3;
	    return [];
	}
    }

    #--------------------------------------------------------------------------------------
    # Function: find_isomorph   (either class OR instance method)
    # Synopsys: Returns first registered object that is isomorphic to argument (other than
    #           argument itself), and a list ref of the isomorphic mapping from argument to
    #           isomorph (i.e. maps an index of the argument to the corresponding index
    #           of the isomorph in the database).  If none found, return undef.
    #--------------------------------------------------------------------------------------
    sub find_isomorph {
	my ($class, $self);
	if (ref $_[0]) {
	    # called as instance method
	    $self = shift;
	    $class = ref $self;
	} else {
	    # called as class method, object to match will be next argument
	    $class = shift;
	    $self = shift;
	}

	# check to see if isomorph hash was updated with all registered objects
	$class->check_putative_isomorph_hash();

	if ($verbosity >= 3) {
	    my $ordered_node_labels = $self->GET_ordered_node_labels();  # this canonizes and generates node labels
	    printn "find_isomorph: searching for isomorphs of $ordered_node_labels in class $class";
	}

	my $putative_isomorph_list_ref = $class->get_putative_isomorph_list($self);  # this canonizes and generates node labels

	foreach my $putative_isomorph_name (sort @{$putative_isomorph_list_ref}) {
	    my $putative_isomorph_ref = $class->lookup_by_name($putative_isomorph_name);

	    ############################ # DON'T RETURN YOURSELF AS AN ISOMORPH!!!!  ######################
	    next if ($putative_isomorph_ref == $self);
	    ###############################################################################################

	    printn "find_isomorph: checking $putative_isomorph_name" if ($verbosity >= 3);
	    # self to isomorph mapping
	    my $S2I_mapping_ref = Graph->compare_isomorphic($self, $putative_isomorph_ref);
	    if ($S2I_mapping_ref) {
		return [$putative_isomorph_ref, $S2I_mapping_ref];
	    }
	}
	return undef;
    }

    #--------------------------------------------------------------------------------------
    # Function: split_mapping
    # Synopsys: Splits a mapping returned by find_isomorph into two lists of given sizes
    #--------------------------------------------------------------------------------------
    sub split_mapping {
	my $class = shift; # unused
	my $LcR2I_mapping_ref = shift;  # (L concat R) to isomorph mapping
	my $L_size = shift;
	my $R_size = shift;

	confess "ERROR: L/R sizes don't add up to concat size" if ($#{$LcR2I_mapping_ref} != $L_size + $R_size - 1);

	my @L2I_mapping = @{$LcR2I_mapping_ref}[0..$L_size-1];
	my @R2I_mapping = @{$LcR2I_mapping_ref}[$L_size..$L_size+$R_size-1];

	return (\@L2I_mapping, \@R2I_mapping);
    }

    #--------------------------------------------------------------------------------------
    # Function: align_or_register
    # Synopsys: Given an object, search its class for isomorph.  If not found, register
    #           object and return undefined mapping, else return the isomorph and mapping.
    #           ASSUMES THE OBJECT WAS NOT YET REGISTERED!!
    #--------------------------------------------------------------------------------------
    sub align_or_register {
	my $class = shift;
	my $graph_ref = shift;

	confess "ERROR: not a RegisteredGraph" if (!$graph_ref->isa("RegisteredGraph"));
	
	my $find_isomorph_ref = $class->find_isomorph($graph_ref);

	my $new_ref;
	my $A2I_mapping_ref; # argument to isomorph mapping

	if (defined $find_isomorph_ref) {   # if there is an isomorph of this complex
	    printn "Isomorph found for ".$graph_ref->get_name()." -> ".$find_isomorph_ref->[0]->get_name() if ($verbosity >= 2);
	    $A2I_mapping_ref = $find_isomorph_ref->[1];
	    $new_ref = $find_isomorph_ref->[0];
	} else {
	    $A2I_mapping_ref = undef;  # since we have no idea how this graph was formed...
	    if (!$class->isa("Instance")) {
		printn "No isomorph found for ".$graph_ref->get_name() if ($verbosity >= 2);
		$new_ref = $graph_ref;
		# this not an object instance, so we just need to register the object
		$graph_ref->register(UNIQUIFY => 1);
	    } else {
		printn "No instance isomorph found for ".$graph_ref->get_name() if ($verbosity >= 2);
		$new_ref = $graph_ref;
		# the object being aligned is an unregistered object-instance,
		# registering with parent it will ensure proper naming
		$graph_ref->get_parent_ref()->register_instance($graph_ref);
	    }
	}

	return ($new_ref, $A2I_mapping_ref);
    }

    #######################################################################################
    # INSTANCE METHODS
    #######################################################################################
    #--------------------------------------------------------------------------------------
    # Function: START
    # Synopsys: 
    #--------------------------------------------------------------------------------------
#    sub START {
#        my ($self, $obj_ID, $arg_ref) = @_;
	
#	# check initializers
#	# ...
#    }

    sub DEMOLISH {
        my ($self, $obj_ID) = @_;
	my $class = ref $self;

	printn "called DEMOLISH on RegisteredGraph object ".($self->get_name())." of class $class" if ($verbosity >= 3);
    }

    sub deregister :CUMULATIVE {
        my $self = shift;
	my $class = ref $self;

	my $name = $self->get_name();
	printn "RegisteredGraph\:\:deregistered object $name of class $class";

	# remove entry from tables
	$self->delete_isomorph_hash_entry();
    }

    #--------------------------------------------------------------------------------------
    # Function: GET_ordered_node_labels
    # Synopsys: Generate (if necessary) and return scalarized, ordered node labels.
    #--------------------------------------------------------------------------------------
    sub GET_ordered_node_labels {
	my $self = shift;
	my $obj_ID = ident $self;

	my $ordered_node_labels = $ordered_node_labels_of{$obj_ID};
	return $ordered_node_labels if (defined $ordered_node_labels);

	$self->canonize() if (!$self->get_valid_flags_ref()->{canonical});
	return $ordered_node_labels_of{$obj_ID} = join " ", @{$self->get_node_colours_ref()->{canonical}};
    }

    #--------------------------------------------------------------------------------------
    # Function: delete_isomorph_hash_entry
    # Synopsys: 
    #--------------------------------------------------------------------------------------
    sub delete_isomorph_hash_entry {
	my $self = shift;
	my $class = ref $self;
	my $name = $self->get_name();
	my $obj_ID = ident $self;

	printn "delete_isomorph_hash_entry: deleting entry for $name of class $class" if ($verbosity >= 3);

	my $hash_ref = $class->get_class_data("ISOMORPH_HASH_REF");
	if (defined $hash_ref) {
	    if (defined $putative_isomorph_list_index_of{$obj_ID}) {
		my $index = $putative_isomorph_list_index_of{$obj_ID};
		my $ordered_node_labels = $ordered_node_labels_of{$obj_ID};
		confess "ERROR: internal error (index didn't point to correct element) on $name ($self)\n" if (
 		    $hash_ref->{$ordered_node_labels}[$index] ne $name
		   );
		splice(@{$hash_ref->{$ordered_node_labels}}, $index, 1);
		# since we splice out an element, index cache of elements after splice must be updated
		for (my $i=$index; $i < @{$hash_ref->{$ordered_node_labels}}; $i++) {
		    my $obj_name = $hash_ref->{$ordered_node_labels}[$i];
		    my $obj_ref = $class->lookup_by_name($obj_name);
		    confess "ERROR: internal error -- $obj_name registry lookup failed" if (!defined $obj_ref);
		    $putative_isomorph_list_index_of{ident $obj_ref} = $i;
		}
	    }
	}
	delete $putative_isomorph_list_index_of{$obj_ID};
	delete $ordered_node_labels_of{$obj_ID};
    }

    #--------------------------------------------------------------------------------------
    # Function: update_putative_isomorph_hash
    # Synopsys: Maintain lists of putative isomorphs which have identical node labels
    #--------------------------------------------------------------------------------------
    sub update_putative_isomorph_hash {
	my $self = shift;
	my $class = ref $self;
	my $obj_ID = ident $self;

	my $name = $self->get_name();

	confess "ERROR: internal error -- can't update isomorph hash without registering first" if (!$self->get_is_registered_flag());

	printn "update_putative_isomorph_hash: updating index of ".(ref $self)." class with $name" if ($verbosity >= 3);

	my $hash_ref = $class->get_class_data("ISOMORPH_HASH_REF");

	# first time init?
	if (!defined $hash_ref) {
	    $hash_ref = {};
	    $class->set_class_data("ISOMORPH_HASH_REF", $hash_ref);
	}

	# remove stale entry from table
	$self->delete_isomorph_hash_entry();

	# add updated entry to table
	my $ordered_node_labels = $self->GET_ordered_node_labels();   # will canonize if necessary
	push @{$hash_ref->{$ordered_node_labels}}, $name;
	$putative_isomorph_list_index_of{$obj_ID} = $#{$hash_ref->{$ordered_node_labels}};
    }
}

sub run_testcases {
    printn "run_testcases: RegisteredGraph package";
    $verbosity = 2;

    # turn off shading
    $Graph::graph_shading_iterations = 0;

    # now exercise isomorphic mapping w/ rearrangement
    my $bm5_ref = RegisteredGraph->new({name => "BM5"});
    $bm5_ref->add_node("A");
    $bm5_ref->add_node("A");
    $bm5_ref->add_node("B");
    $bm5_ref->add_bi_edge(0, 1, 1);
    $bm5_ref->add_uni_edge(1, 2, "a");
    printn "BM5 = \n".$bm5_ref->sprint_graph_matrix();
    my $bm6_ref = RegisteredGraph->new({name => "BM6"});
    $bm6_ref->add_node("B");
    $bm6_ref->add_node("A");
    $bm6_ref->add_node("B");
    $bm6_ref->add_bi_edge(0, 1, 1);
    $bm6_ref->add_uni_edge(0, 2, "a");
    printn "BM6 = \n".$bm6_ref->sprint_graph_matrix();

    my $bm7_ref = RegisteredGraph->new({name => "BM7"});
    $bm7_ref->add_node("A");
    $bm7_ref->add_node("A");
    $bm7_ref->add_node("B");
    $bm7_ref->add_bi_edge(0, 1, 1);
    $bm7_ref->add_uni_edge(0, 2, "a");
    printn "BM7 = \n".$bm7_ref->sprint_graph_matrix();

    $bm5_ref->update_putative_isomorph_hash();
    $bm6_ref->update_putative_isomorph_hash();
    $bm7_ref->update_putative_isomorph_hash();

    $verbosity = 3;
    my $find_isomorph_ref = $bm6_ref->find_isomorph();
    if (defined $find_isomorph_ref) {
	printn "BM6 find_isomorph returned: ".join(", ", "class = ".(ref $find_isomorph_ref->[0]), 
						   "name = ".$find_isomorph_ref->[0]->get_name(),
						   "mapping = @{$find_isomorph_ref->[1]}");
    } else {
	printn "no isomorph found for BM6";
    }

    $find_isomorph_ref = $bm7_ref->find_isomorph();
    if (defined $find_isomorph_ref) {
	printn "BM7 find_isomorph returned: ".join(", ", "class = ".(ref $find_isomorph_ref->[0]), 
						   "name = ".$find_isomorph_ref->[0]->get_name(),
						   "mapping = @{$find_isomorph_ref->[1]}");
    } else {
	printn "no isomorph found for BM7";
    }

    printn Dumper(RegisteredGraph->get_class_data("ISOMORPH_HASH_REF"));
    printn $bm7_ref->_DUMP();

    $verbosity = 2; # prevent DEMOLISH messages
}


# Package BEGIN must return true value
return 1;

