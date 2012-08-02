######################################################################################
# File:     AllostericStructure.pm
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

use strict;
use diagnostics;		# equivalent to -w command-line switch
use warnings;

package AllostericStructure;

use Class::Std::Storable;
use base qw(Structure);
{
    use Carp;
    use Data::Dumper;

    use Utils;
    use Globals;

    use AllostericSite;
    use AllostericStructureInstance;

    #######################################################################################
    # CLASS ATTRIBUTES
    #######################################################################################
    AllostericStructure->set_class_data("INSTANCE_CLASS", "AllostericStructureInstance");
    AllostericStructure->set_class_data("ELEMENT_CLASS", "Structure,AllostericStructure,ReactionSite,AllostericSite,Node");
    AllostericStructure->set_class_data("DEFAULT_GROUP_NODE", "Node");
    AllostericStructure->set_class_data("GROUP_NODE_PREFIX", "a");

    #######################################################################################
    # ATTRIBUTES
    #######################################################################################
    my %allosteric_flag_of :ATTR(get => 'allosteric_flag', set => 'allosteric_flag');
    my %reg_factors_of     :ATTR(get => 'reg_factors', set => 'reg_factors');
    my %Phi_of             :ATTR(get => 'Phi', set => 'Phi');

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
    # Function: BUILD
    # Synopsys: 
    #--------------------------------------------------------------------------------------
    sub BUILD {
        my ($self, $obj_ID, $arg_ref) = @_;

	if (exists $arg_ref->{Keq_ratios}) {
	    printn "ERROR: 'Keq_ratios' attribute is obsolete, was renamed to 'reg_factors'";
	    exit(1);
	}
	if (exists $arg_ref->{RT_phi}) {
	    printn "ERROR: 'RT_phi' attribute is obsolete, was renamed to 'Phi' (with uppercase P) instead";
	    exit(1);
	}

	my $allosteric_flag = defined $arg_ref->{allosteric_flag} ? $arg_ref->{allosteric_flag} : 1;
	$allosteric_flag_of{$obj_ID} = $allosteric_flag;

	if ($allosteric_flag) {
	    # if allosteric, create an allosteric group node
	    $self->set_group_node_ref("AllostericSite");

	    my @elements = $self->get_elements();
	    my $num_elements = @elements;

	    if (defined $arg_ref->{reg_factors}) {
		$reg_factors_of{$obj_ID} =  $arg_ref->{reg_factors};
		if (!ref $reg_factors_of{$obj_ID}) {
		    my $val = $reg_factors_of{$obj_ID};
		    $reg_factors_of{$obj_ID} = [map {$val} (1..$num_elements)];
		}
	    } else {
		$reg_factors_of{$obj_ID} = [map {1} (1..$num_elements)];
	    }
	    if ($num_elements != @{$reg_factors_of{$obj_ID}}) {
		confess "ERROR: size of reg_factors array should be equal to number of elements in Structure";
	    }

	    if (defined $arg_ref->{Phi}) {
		$Phi_of{$obj_ID} =  $arg_ref->{Phi};
		if (!ref $Phi_of{$obj_ID}) {
		    my $val = $Phi_of{$obj_ID};
		    $Phi_of{$obj_ID} = [map {$val} (1..$num_elements)];
		}
	    } else {
		$Phi_of{$obj_ID} = [map {0.5} (1..$num_elements)];
	    }
	    if ($num_elements != @{$Phi_of{$obj_ID}}) {
		confess "ERROR: size of Phi array should be equal to number of elements in Structure";
	    }

	    # make sure that bsites do not have a reg_factor
	    my $reg_factors_ref = $reg_factors_of{$obj_ID};
	    for (my $i=0; $i < @elements; $i++) {
		my $element_ref = $elements[$i];
		if ($element_ref->isa('ReactionSite') && $element_ref->get_type() ne "msite") {
		    # if user defined a reg_factor for a binding or catalytic site, issue warning
		    if (defined $arg_ref->{reg_factors} && (defined $reg_factors_ref->[$i] && $reg_factors_ref->[$i] ne "")) {
			my $name = $self->get_name();
			my $element_name = $element_ref->get_name();
			printn "\nWARNING: ignoring user-assigned reg_factor on binding site $element_name in structure $name (index $i)\n";
		    }
		    $reg_factors_ref->[$i] = undef;
		}
	    }

#	# set Node reaction_type attribute
#	$self->set_reaction_type('U');

	    # add allosteric coupling edges to ReactionSite or AllostericStructure elements
	    my $bi_edges_ref = $self->get_bi_edges_ref();
	    my $uni_edges_ref = $self->get_uni_edges_ref();
	    my $phi_values_ref = $Phi_of{$obj_ID};
	    for (my $j=0; $j < $num_elements; $j++) {
		my $element_ref = $elements[$j];
		if ($element_ref->isa('ReactionSite')) {
		    my $colour = '~{';
		    # the colour is only defined for msites
		    $colour .= $reg_factors_ref->[$j] if defined $reg_factors_ref->[$j];
		    if (ref $phi_values_ref->[$j]) {
			printn "ERROR: a reference was supplied as the phi-value of element $j";
			exit(1);
		    }
		    $colour .= "|".$phi_values_ref->[$j];
		    $colour .= "}"; 
		    push @{$bi_edges_ref}, [-1,$j,$colour];
		}
		if ($element_ref->isa('AllostericStructure') && $element_ref->get_allosteric_flag()) {
		    if (defined $reg_factors_ref->[$j]) {
			my ($group_node_phi, $element_node_phi);
			if (ref $phi_values_ref->[$j]) {
			    $group_node_phi = $phi_values_ref->[$j][0];
			    $element_node_phi = $phi_values_ref->[$j][1];
			} else {
			    $group_node_phi = $element_node_phi = $phi_values_ref->[$j];
			}
			my $reg_factor = $reg_factors_ref->[$j];

			# n.b. edges point to modifiers, which are in the fanout of an allosteric site
			# uni-edge from allosteric group node to allosteric element
			my $group_node_colour = '~{';
			$group_node_colour .= $reg_factors_ref->[$j];
			$group_node_colour .= "|".$group_node_phi;
			$group_node_colour .= "}";
			push @{$uni_edges_ref}, [-1,$j,$group_node_colour];
			# uni-edge from allosteric element to allosteric group node
			my $element_node_colour = '~{';
			$element_node_colour .= $reg_factors_ref->[$j];
			$element_node_colour .= "|".$element_node_phi;
			$element_node_colour .= "}";
			push @{$uni_edges_ref}, [$j,-1,$element_node_colour];
		    }
		}
	    }
	}
    }

#    #--------------------------------------------------------------------------------------
#    # Function: START
#    # Synopsys: 
#    #--------------------------------------------------------------------------------------
#    sub START {
#        my ($self, $obj_ID, $arg_ref) = @_;

##	# reset the ungroup flag if there are no duplicate protodomains
##	if ($self->get_ungroup_flag()) {
##	    my %duplicates;
##	    my @elements = $self->get_elements();
##	    foreach my $node_ref (@elements) {
##		$duplicates{$node_ref->get_name()} = 1;
##	    }
##	    $self->set_ungroup_flag(0) if (scalar(keys %duplicates) == @elements);
##	}
#    }

#    #--------------------------------------------------------------------------------------
#    # Function: xxx
#    # Synopsys: 
#    #--------------------------------------------------------------------------------------
#    sub xxx {
#	my $self = shift;
#    }
}

sub run_testcases {

    # N.B. The following testcases were copied/modified from Domain and
    # Protein modules which are now obsolete but nevertheless covered
    # a significant amount of functionality.

    printn "run_testcases: RUNNING DOMAIN TESTCASES...";

    use ReactionSite;

    ReactionSite::run_testcases();
    my $pd0_ref = ReactionSite->lookup_by_name("PD0");

    use Globals;
    $verbosity = 3;

    my $export_dir = "test/modules/AllostericStructure";
    `mkdir -p $export_dir`;

    printn "CREATING DOMAINS...";
    my $d1_ref = AllostericStructure->new({
	name => "D1",
	allosteric_transition_rates => [1.5, 3.5],
	elements_ref => [$pd0_ref, $pd0_ref],
	ungroup_flag => 1,
	allosteric_flag => 0,
    });

    my $d2_ref = AllostericStructure->new({
	name => "D2",
	allosteric_transition_rates => [2.5, 4.5],
	elements_ref => [$pd0_ref, $pd0_ref, $pd0_ref],
	ungroup_flag => 1,
	allosteric_flag => 1,
    });

    printn "CREATING DOMAIN INSTANCES...";
    my $D1I0_ref = $d1_ref->new_object_instance({});
    my $D1I1_ref = $d1_ref->new_object_instance({});
    my $D2I0_ref = $d2_ref->new_object_instance({});

    printn "DOMAIN INSTANCE STATE BEFORE INITIALIZATION...";
    printn "State of D1I0 is: ".$D1I0_ref->sprint_state();
    printn "State of D1I1 is: ".$D1I1_ref->sprint_state();
    printn "State of D2I0 is: ".$D2I0_ref->sprint_state();

    printn "DOMAIN INSTANCE INITIALIZATION TEST...";
    $D1I0_ref->set_msite_state(0, "1");
    $D1I1_ref->set_msite_state(1, "1");
    $D2I0_ref->set_msite_state(1, "1");

    printn "State of D1I0 is: ".$D1I0_ref->sprint_state();
    printn "State of D1I1 is: ".$D1I1_ref->sprint_state();
    printn "State of D2I0 is: ".$D2I0_ref->sprint_state();

    printn "DOMAIN INSTANCE WILDCARD INITIALIZATION TEST...";
    $D2I0_ref->set_element_instance_attrib("msite_state", "*",1);
    printn "State of D1I0 is: ".$D1I0_ref->sprint_state();
    printn "State of D1I1 is: ".$D1I1_ref->sprint_state();
    printn "State of D2I0 is: ".$D2I0_ref->sprint_state();
    $D2I0_ref->set_element_instance_attrib("msite_state", [1,2],0);
    printn "State of D1I0 is: ".$D1I0_ref->sprint_state();
    printn "State of D1I1 is: ".$D1I1_ref->sprint_state();
    printn "State of D2I0 is: ".$D2I0_ref->sprint_state();

    printn "DOMAIN GRAPHS...";
    printn "D1 (primary) = \n".$d1_ref->sprint_graph_matrix();
    $d1_ref->export_graphviz(filename => "$export_dir/D1.primary.png");
    printn "D1 = ".$d1_ref->_DUMP();
    printn "D2 (primary) = \n".$d2_ref->sprint_graph_matrix();
    $d2_ref->export_graphviz(filename => "$export_dir/D2.primary.png");
    printn "D2 = ".$d2_ref->_DUMP();

    printn "DOMAIN INSTANCE REFRESH...";
    $D1I0_ref->refresh_instance_graph_matrix();
    $D1I0_ref->canonize();
    printn "D1I0 (primary) = \n".$D1I0_ref->sprint_graph_matrix("primary");
    $D1I0_ref->export_graphviz(filename => "$export_dir/D1I0.primary.png");
    printn "D1I0 (canonical) = \n".$D1I0_ref->sprint_graph_matrix("canonical");
    $D1I0_ref->export_graphviz(filename => "$export_dir/D1I0.canonical.png", src => "canonical");

    $D1I1_ref->refresh_instance_graph_matrix();
    $D1I1_ref->canonize();
    printn "D1I1 (primary) = \n".$D1I1_ref->sprint_graph_matrix("primary");
    $D1I1_ref->export_graphviz(filename => "$export_dir/D1I1.primary.png");
    printn "D1I1 (canonical) = \n".$D1I1_ref->sprint_graph_matrix("canonical");
    $D1I1_ref->export_graphviz(filename => "$export_dir/D1I1.canonical.png", src => "canonical");

    $D2I0_ref->refresh_instance_graph_matrix();
    $D2I0_ref->canonize();
    printn "D2I0 (primary) = \n".$D2I0_ref->sprint_graph_matrix("primary");
    $D2I0_ref->export_graphviz(filename => "$export_dir/D2I0.primary.png");
    printn "D2I0 (canonical) = \n".$D2I0_ref->sprint_graph_matrix("canonical");
    $D2I0_ref->export_graphviz(filename => "$export_dir/D2I0.canonical.png", src => "canonical");

    printn "DOMAIN DUMPS...";
    printn "D1I0 = ".$D1I0_ref->_DUMP();
    printn "D1I1 = ".$D1I1_ref->_DUMP();
    printn "D2I0 = ".$D2I0_ref->_DUMP();

    printn "D2I0.I0 = ".$D2I0_ref->get_element(0)->_DUMP();
    printn "D2I0.I1 = ".$D2I0_ref->get_element(1)->_DUMP();

    printn $D1I0_ref->sprint();
    printn $D1I1_ref->sprint();
    printn $D2I0_ref->sprint();
    printn $D1I0_ref->get_exported_name();
    printn $D1I1_ref->get_exported_name();
    printn $D2I0_ref->get_exported_name();

    $verbosity = 2; # prevent DEMOLISH messages

#############################

    $verbosity = 3;

#    my $export_dir = "test/modules/AllostericStructure";
#    `mkdir -p $export_dir`;

#    my $d1_ref = AllostericStructure->lookup_by_name("D1");
#    my $d2_ref = AllostericStructure->lookup_by_name("D2");

    printn "CREATING PROTEINS...";
    my $p1_ref = AllostericStructure->new({
	name => "P1",
	elements_ref => [$d1_ref, $d2_ref],
	ungroup_flag => 1,
	allosteric_flag => 0,
    });
    my $p2_ref = AllostericStructure->new({
	name => "P2",
	elements_ref => [$d1_ref, $d2_ref, $d2_ref, $d1_ref],
	ungroup_flag => 1,
	allosteric_flag => 0,
    });

    printn "INSTANTIATING PROTEINS...";
    my $P1I0_ref = $p1_ref->new_object_instance({});
    my $P1I1_ref = $p1_ref->new_object_instance({});
    my $P2I0_ref = $p2_ref->new_object_instance({});

    print "State of P1I0 is: ".$P1I0_ref->sprint_state()."\n";
    print "State of P1I1 is: ".$P1I1_ref->sprint_state()."\n";
    print "State of P2I0 is: ".$P2I0_ref->sprint_state()."\n";

    printn "PROTEIN INSTANCE INITIALIZATION TEST...";
    $P1I0_ref->set_msite_state([0,0],"1");
    $P1I1_ref->set_msite_state([1,1],"1");
    $P2I0_ref->set_msite_state([3,0],"1");

    print "State of P1I0 is: ".$P1I0_ref->sprint_state()."\n";
    print "State of P1I1 is: ".$P1I1_ref->sprint_state()."\n";
    print "State of P2I0 is: ".$P2I0_ref->sprint_state()."\n";

    printn "PROTEIN INSTANCE WILDCARD INITIALIZATION TEST...";
    $P2I0_ref->set_element_instance_attrib("msite_state", "*,*", 0);
    printn "State of P2I0 is: ".$P2I0_ref->sprint_state();
    $P2I0_ref->set_element_instance_attrib("msite_state", ["1,1","2,*"], 1);
    printn "State of P2I0 is: ".$P2I0_ref->sprint_state();

    printn "PROTEIN GRAPHS...";
    printn "P1 (primary) = \n".$p1_ref->sprint_graph_matrix();
    $p1_ref->export_graphviz(filename => "$export_dir/P1.primary.png");
    printn "P1 = ".$p1_ref->_DUMP();
    printn "P2 (primary) = \n".$p2_ref->sprint_graph_matrix();
    $p2_ref->export_graphviz(filename => "$export_dir/P2.primary.png");
    printn "P2 = ".$p2_ref->_DUMP();

    printn "PROTEIN INSTANCE REFRESH...";
    $P1I0_ref->refresh_instance_graph_matrix();
    $P1I0_ref->canonize();
    printn "P1I0 (primary) = \n".$P1I0_ref->sprint_graph_matrix("primary");
    $P1I0_ref->export_graphviz(filename => "$export_dir/P1I0.primary.png");
    printn "P1I0 (canonical) = \n".$P1I0_ref->sprint_graph_matrix("canonical");
    $P1I0_ref->export_graphviz(filename => "$export_dir/P1I0.canonical.png", src => "canonical");

    $P1I1_ref->refresh_instance_graph_matrix();
    $P1I1_ref->canonize();
    printn "P1I1 (primary) = \n".$P1I1_ref->sprint_graph_matrix("primary");
    $P1I1_ref->export_graphviz(filename => "$export_dir/P1I1.primary.png");
    printn "P1I1 (canonical) = \n".$P1I1_ref->sprint_graph_matrix("canonical");
    $P1I1_ref->export_graphviz(filename => "$export_dir/P1I1.canonical.png", src => "canonical");

    $P2I0_ref->refresh_instance_graph_matrix();
    $P2I0_ref->get_element(1)->set_ungroup_flag(0);  # test partial ungrouping
    $P2I0_ref->canonize();
    printn "P2I0 (primary) = \n".$P2I0_ref->sprint_graph_matrix("primary");
    $P2I0_ref->export_graphviz(filename => "$export_dir/P2I0.primary.png");
    printn "P2I0 (canonical) = \n".$P2I0_ref->sprint_graph_matrix("canonical");
    $P2I0_ref->export_graphviz(filename => "$export_dir/P2I0.canonical.png", src => "canonical");

    printn "PROTEIN / PROTEIN INSTANCE DUMP...";
    printn "P1 = ".$p1_ref->_DUMP();
    printn "P2 = ".$p2_ref->_DUMP();

    printn "P1I0 = ".$P1I0_ref->_DUMP();
    printn "P1I1 = ".$P1I1_ref->_DUMP();
    printn "P2I0 = ".$P2I0_ref->_DUMP();

    printn $P1I0_ref->sprint();
    printn $P1I1_ref->sprint();
    printn $P2I0_ref->sprint();
    printn $P1I0_ref->get_exported_name();
    printn $P1I1_ref->get_exported_name();
    printn $P2I0_ref->get_exported_name();

    $verbosity = 2; # prevent DEMOLISH messages
}


# Package BEGIN must return true value
return 1;

