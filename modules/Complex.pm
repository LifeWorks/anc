######################################################################################
# File:     Complex.pm
# Author:   Julien F. Ollivier
#
# Copyright (C) 2005-2010 Julien Ollivier.
#
# This program comes with ABSOLUTELY NO WARRANTY.
# This is free software, and you are welcome to redistribute it
# under certain conditions. See file LICENSE.TXT for details.
#
# Synopsys:
######################################################################################
# Detailed Description:
# ---------------------
######################################################################################

#######################################################################################
# TO-DO LIST
#######################################################################################

use strict;
use diagnostics;		# equivalent to -w command-line switch
use warnings;

package Complex;
use Class::Std::Storable;
use base qw(Structure);
{
    use Carp;

    use Utils;
    use Globals;

    use ComplexInstance;

    #######################################################################################
    # CLASS ATTRIBUTES
    #######################################################################################
    Complex->set_class_data("INSTANCE_CLASS", "ComplexInstance");
    Complex->set_class_data("ELEMENT_CLASS", "Structure,AllostericStructure");
    Complex->set_class_data("DEFAULT_GROUP_NODE", undef);

    #######################################################################################
    # ATTRIBUTES
    #######################################################################################

    #######################################################################################
    # FUNCTIONS
    #######################################################################################

    #######################################################################################
    # CLASS METHODS
    #######################################################################################
    sub import_structures : {   # !!! this method really belong in Set class ???
	my $class = shift;

	my @structure_classes = split /,/, $class->get_class_data("ELEMENT_CLASS");
	my @structure_refs = map {$_->get_instances()} @structure_classes;

	# figure out which complexes to import...

	# for undef import_flags, make a decision based on
	# whether structure is in another structure
	foreach my $structure_ref (grep {!defined $_->get_import_flag()} @structure_refs) {
	    my $import_flag = $structure_ref->get_in_set_list() ? 0 : 1;
	    $structure_ref->set_import_flag($import_flag);
	}

	# now filter out structures with import_flag reset,
	# some of which were reset by user indicating not to import
	@structure_refs = grep {$_->get_import_flag() == 1} @structure_refs;

	# now import complexes
	my @complexes_ref = ();
	foreach my $structure_ref (@structure_refs) {
	    my $complex_ref = $class->new({
		name => $structure_ref->get_name(),
		elements_ref => [$structure_ref]
	       });
	    $complex_ref->update_putative_isomorph_hash(); # don't forget to update the isomorph hash
	    push @complexes_ref, $complex_ref;
	}
	return @complexes_ref;
    }

    #--------------------------------------------------------------------------------------
    # Function: sprint_structure_report
    # Synopsys: Report elements and graph matrix.
    #--------------------------------------------------------------------------------------
    sub sprint_structure_report {
	my $class = shift;

	my $report = "";
	foreach my $instance_ref ($class->get_instances()) {
	    $report .= "$class: ".$instance_ref->get_name()."\n";
	    $report .= $instance_ref->sprint_graph_matrix("scalar")."\n";
	    $report .= $instance_ref->sprint_elements()."\n";
	}
	return $report;
    }

    #--------------------------------------------------------------------------------------
    # Function: sprint_report
    # Synopsys: 
    #--------------------------------------------------------------------------------------
    sub sprint_report {
	my $class = shift;

#	my $report = sprintf("%-30s %-30s\n","complex","states");
	my $report = "";
	my @instance_refs = $class->get_instances();
	my $num_species = 0;
	foreach my $instance_ref (@instance_refs) {
	    my $instance_name = $instance_ref->get_exported_name();
	    my @object_instance_refs = map {$_->get_exported_name} $instance_ref->get_object_instances();
	    $num_species += @object_instance_refs;
	    $report .= sprintf("%-30s %-30s\n", $instance_name, join " ", @object_instance_refs);
	}
	$report = sprintf("%-30s %-30s\n", scalar(@instance_refs), $num_species) . $report;
	return $report;
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

	if ($verbosity >= 2) {
	    # report creation
	    my $class = ref $self;
	    my $element_names = (join " ", map {$_->get_name()} $self->get_elements());
	    printn "$class->new(): creating ".$self->get_name().($element_names ? " with structure(s) $element_names" : "");
	}
    }

    #--------------------------------------------------------------------------------------
    # Function: check (CUMULATIVE)
    # Synopsys: Check the Graph for consistency with the SetElements
    #--------------------------------------------------------------------------------------
    sub check : CUMULATIVE(BASE FIRST) {
	my $self = $_[0];

	printn "CHECKING COMPLEX ".$self->get_name() if ($verbosity >= 3);

	my $graph_size = $self->get_graph_size();
	my $num_elements = $self->get_num_elements();
	if ($num_elements != $graph_size) {
	    my $name = $self->get_name();
	    confess "ERROR: internal error -- graph size of $name not consistent with no. of elements";
	}

	my @node_labels = $self->get_node_colours();
	for (my $i = 0; $i < $graph_size; $i++) {
	    my $element_ref = $self->get_element($i);
	    my $element_name = $element_ref->get_name();
	    if ($element_name ne $node_labels[$i]) {
		my $name = $self->get_name();
		confess "ERROR: internal error -- $name graph and elements of $name not in same order";
	    }
	}
    }

    #--------------------------------------------------------------------------------------
    # Function: get_exported_name
    # Synopsys: 
    #--------------------------------------------------------------------------------------
    sub get_exported_name {
	my $self = shift;

	my $sprint = $self->get_name();
	$sprint =~ s/\!/_i/;
	return simplify($sprint, "-");
    }
}


sub run_testcases {
    printn "run_testcases: RUNNING COMPLEX TESTCASES...";

    use AllostericStructure;
    AllostericStructure::run_testcases();

    $Globals::compact_names = 0;
    $verbosity = 3;

    my $export_dir = "test/modules/Complex";
    `mkdir -p $export_dir`;

    my $p1_ref = AllostericStructure->lookup_by_name("P1");
    my $p2_ref = AllostericStructure->lookup_by_name("P2");

    printn "CREATING COMPLEXES...";
    my $c1_ref = Complex->new({
	name => "C1",
	elements_ref => [$p1_ref, $p2_ref],
    });
    printn "C1 (primary) = \n".$c1_ref->sprint_graph_matrix();
    $c1_ref->export_graphviz(filename => "$export_dir/C1.primary.png");

    my $c2_ref = Complex->new({
	name => "C2",
	elements_ref => [$p1_ref, $p2_ref, $p2_ref],
    });
    printn "C2 (primary) = \n".$c2_ref->sprint_graph_matrix();
    $c2_ref->export_graphviz(filename => "$export_dir/C2.primary.png");

    printn "INSTANTIATING COMPLEXES...";
    my $C1I0_ref = $c1_ref->new_object_instance({});
    my $C1I1_ref = $c1_ref->new_object_instance({});
    my $C2I0_ref = $c2_ref->new_object_instance({});

    print "State of C1I0 is: ".$C1I0_ref->sprint_state()."\n";
    print "State of C1I1 is: ".$C1I1_ref->sprint_state()."\n";
    print "State of C2I0 is: ".$C2I0_ref->sprint_state()."\n";

    printn "COMPLEX INSTANCE INITIALIZATION TEST...";
    $C1I0_ref->set_msite_state([1,1,1],"1");
    $C1I1_ref->set_msite_state([0,0,1],"1");
    $C2I0_ref->set_msite_state([2,1,0],"1");
    print "State of C1I0 is: ".$C1I0_ref->sprint_state()."\n";
    print "State of C1I1 is: ".$C1I1_ref->sprint_state()."\n";
    print "State of C2I0 is: ".$C2I0_ref->sprint_state()."\n";

    printn "COMPLEX INSTANCE WILDCARD INITIALIZATION TEST...";
    $C2I0_ref->set_element_instance_attrib("msite_state", "0,*,*", 0);
    printn "State of C2I0 is: ".$C2I0_ref->sprint_state();
    $C2I0_ref->set_element_instance_attrib("msite_state", "1,*,*", 1);
    printn "State of C2I0 is: ".$C2I0_ref->sprint_state();
    $C2I0_ref->set_element_instance_attrib("msite_state", ["2,1,1","2,2,*"], 0);
    printn "State of C2I0 is: ".$C2I0_ref->sprint_state();

    printn "COMPLEX INSTANCE GRAPH REFRESH...";
    $C1I0_ref->refresh_instance_graph_matrix();
    $C1I0_ref->update_putative_isomorph_hash();
    printn "C1I0 (primary) = \n".$C1I0_ref->sprint_graph_matrix();
    $C1I0_ref->export_graphviz(filename => "$export_dir/C1I0.primary.png");
    printn "C1I0 (canonical) = \n".$C1I0_ref->sprint_graph_matrix("canonical");
    $C1I0_ref->export_graphviz(src => "canonical", filename => "$export_dir/C1I0.canonical.png");

    $C1I1_ref->refresh_instance_graph_matrix();
    $C1I1_ref->update_putative_isomorph_hash();
    printn "C1I1 (primary) = \n".$C1I1_ref->sprint_graph_matrix();

    $C2I0_ref->refresh_instance_graph_matrix();
    $C2I0_ref->update_putative_isomorph_hash();
    printn "C2I0 (primary) = \n".$C2I0_ref->sprint_graph_matrix();

    printn "COMPLEX / COMPLEX INSTANCE DUMP...";
    printn $c1_ref->_DUMP();
    printn $c2_ref->_DUMP();

    printn $C1I0_ref->_DUMP();
    printn $C1I1_ref->_DUMP();
    printn $C2I0_ref->_DUMP();

    printn "LOOK UP PROTODOMAINS & INSTANCES AND FIND CONTAINING SETS";
    foreach my $pd_ref (ReactionSite->get_instances()) {
	printn "PROTODOMAIN ".$pd_ref->get_name()." IN SET:". join ",",(map($_->get_name(), $pd_ref->get_in_set_list));
	printn "PROTODOMAIN ".$pd_ref->get_name()." IN TOP-LVL SET:". join ",",(map($_->get_name(), $pd_ref->get_in_toplvl_set_list));
	my @instance_list = $pd_ref->get_object_instances();
	foreach my $instance_ref (@instance_list) {
#	    printn "PROTODOMAIN INSTANCE ".$instance_ref->get_name()." IN SET:". join ",",(map($_->get_name(), $instance_ref->get_in_set_list));
	    if (defined $instance_ref->get_in_set()) {
		printn "PROTODOMAIN INSTANCE ".$instance_ref->get_name()." IN SET:". $instance_ref->get_in_set()->get_name();
		printn "PROTODOMAIN INSTANCE ".$instance_ref->get_name()." IN TOP-LVL SET:". $instance_ref->get_in_toplvl_set()->get_name();
	    } else {
		printn "PROTODOMAIN INSTANCE ".$instance_ref->get_name()." NOT MEMBER OF ANY SET";
	    }
	}
    }

    printn $C1I0_ref->sprint();
    printn $C1I1_ref->sprint();
    printn $C2I0_ref->sprint();
    printn $C1I0_ref->get_exported_name();
    printn $C1I1_ref->get_exported_name();
    printn $C2I0_ref->get_exported_name();

    $verbosity = 2; # prevent DEMOLISH messages
}


# Package BEGIN must return true value
return 1;

