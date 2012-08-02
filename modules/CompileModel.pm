######################################################################################
# File:     CompileModel.pm
# Author:   Julien F. Ollivier
#
# Copyright (C) 2005-2010 Julien Ollivier.
#
# This program comes with ABSOLUTELY NO WARRANTY.
# This is free software, and you are welcome to redistribute it
# under certain conditions. See file LICENSE.TXT for details.
#
# Synopsys: Create/compile the reaction network.
######################################################################################
# Detailed Description:
# ---------------------
######################################################################################

use strict;
use diagnostics;		# equivalent to -w command-line switch
use warnings;

package CompileModel;

use Exporter;
use vars qw(@ISA @EXPORT);
@ISA = qw(Exporter);
@EXPORT = qw(
	     compile_model
	    );

use Utils;

use Globals qw(
	       $verbosity
	       $max_external_iterations
	       $max_internal_iterations
	       $max_species
	       $max_complex_size
	       $max_csite_bound_to_msite_number
	       $default_steric_factor
	       $kf_1st_order_rate_cutoff
	       $kf_2nd_order_rate_cutoff
	       $kb_rate_cutoff
	       $kp_rate_cutoff
	       $report
	       $export_graphviz
	       $compact_names
	       $protein_separator
	      );

use ModelParser;

sub compile_model {
    my %args = (
	MODEL => undef,
	MODEL_ROOT => undef,
	OUT => undef,
	OUTDIR => undef,
	MAXEXT => undef,
	MAXINT => undef,
	MAXSPECIES => undef,
	MAXSIZE => undef,
	REPORT => undef,
	GRAPHVIZ => undef,
	COMPACT_NAMES => undef,
	CLEAN => 0,
	@_,
       );

    my $MODEL = $args{MODEL};
    my $OUT = $args{OUT};
    my $OUTDIR = $args{OUTDIR};

    #######################################################
    printn "CLEANING UP";
    #######################################################
    if ($args{CLEAN}) {
	`rm -f $OUT`;  # eqn file
	`rm -f $OUTDIR/$args{MODEL_ROOT}.species.rpt`;
	`rm -f $OUTDIR/$args{MODEL_ROOT}.structures.rpt`;
	`find $OUTDIR/graphviz -nowarn -name '*.png' | xargs rm -f` if -e "$OUTDIR/graphviz";
	`find $OUTDIR/graphviz -nowarn -name '*.svg' | xargs rm -f` if -e "$OUTDIR/graphviz";
    }

    #######################################################
    printn "CREATING OUTPUT DIRECTORY";
    #######################################################
    `mkdir -p $OUTDIR`;

    ##############################################
    printn "READING MODEL $MODEL";
    #######################################################
    read_model($args{MODEL});

    #######################################################
    printn "REPORTING COMPILE PARAMETERS";
    #######################################################
    # parameters are already at their default values or
    # the value defined in the model file.
    # here, only for parameters that do not affect object
    # creation and initialization (e.g. not those
    # such as default_steric_factor that may be used during
    # object creation when reading model file), we override
    # any parameter values in the model file with those given
    # at the cmd-line.
    $max_external_iterations = $args{MAXEXT} if defined $args{MAXEXT};
    $max_internal_iterations = $args{MAXINT} if defined $args{MAXINT};
    $max_species = $args{MAXSPECIES} if defined $args{MAXSPECIES};
    $max_complex_size = $args{MAXSIZE} if defined $args{MAXSIZE};
    $report = $args{REPORT} if defined $args{REPORT};
    $export_graphviz = $args{GRAPHVIZ} if defined $args{GRAPHVIZ};
    $compact_names = $args{COMPACT_NAMES} if defined $args{COMPACT_NAMES};

    # now report value used
    printn "max_external_iterations = $max_external_iterations";
    printn "max_internal_iterations = $max_internal_iterations";
    printn "max_species = $max_species";
    printn "max_complex_size = $max_complex_size";
    printn "max_csite_bound_to_msite_number = $max_csite_bound_to_msite_number";
    printn "kf_1st_order_rate_cutoff = $kf_1st_order_rate_cutoff";
    printn "kf_2nd_order_rate_cutoff = $kf_2nd_order_rate_cutoff";
    printn "kb_rate_cutoff = $kb_rate_cutoff";
    printn "kp_rate_cutoff = $kp_rate_cutoff";
    printn "default_steric_factor = $default_steric_factor";
    printn "report = $report";
    printn "export_graphviz = $export_graphviz";
    printn "compact_names = $compact_names";
    printn "protein_separator = $protein_separator";

    #######################################################
    printn "IMPORTING COMPLEXES";
    #######################################################
    Complex->import_structures();
    print Complex->sprint_structure_report() if ($verbosity >= 2);

    #######################################################
    printn "COMPILING RULES";
    #######################################################
    CanBindRule->compile(
       ligand_classes => ["ReactionSite"]
      );

    #######################################################
    printn "INSTANTIATING COMPLEXES";
    #######################################################
    my @complex_instance_refs = Complex->instantiate_all_objects();

    #######################################################
    printn "INITIALIZING INSTANCES";
    #######################################################
    foreach my $complex_instance_ref (@complex_instance_refs) {
	printn "Species ".$complex_instance_ref->get_name(). ":" if ($verbosity >= 2);
	printn "Default state: ".$complex_instance_ref->sprint_state() if ($verbosity >= 2);
	my @node_instances = @{$complex_instance_ref->get_node_instances()};
	map {$_->get_site_ref()->set_msite_state(0)} @node_instances;
	map {$_->get_site_ref()->set_allosteric_state('R')} @node_instances;
	$complex_instance_ref->refresh_instance_graph_matrix();
	$complex_instance_ref->update_putative_isomorph_hash();
	printn "Initialized state: ".$complex_instance_ref->sprint_state() if ($verbosity >= 2);
	printn "Initialized graph:\n".$complex_instance_ref->sprint_graph_matrix() if ($verbosity >= 2);
    }

    #######################################################
    printn "COMPILING REACTION NETWORK";
    #######################################################
    my $RN_ref = ReactionNetwork->new({
	species => [Complex->get_object_instances()],
    });

    my @binary_reaction_types = ("BindingReaction", "CatalyticReaction");
    my @unary_reaction_types = ("AllostericReaction");

    $RN_ref->compile_network(
	BINARY_REACTION_TYPES => [@binary_reaction_types],
	UNARY_REACTION_TYPES => [@unary_reaction_types],
	MAX_EXTERNAL_ITERATIONS => $max_external_iterations,
	MAX_INTERNAL_ITERATIONS => $max_internal_iterations,
	MAX_SPECIES => $max_species,
	MAX_COMPLEX_SIZE => $max_complex_size,
       );

    #######################################################
    printn "COMPILING ICs and STIMULI";
    #######################################################
    Init->compile();
    Init->report();
    Stimulus->compile();
    Stimulus->report();

    #######################################################
    printn "COMPILING PROBES";
    #######################################################
    Probe->compile();
    Probe->report(1);

    #######################################################
    printn "EXPORTING NETWORK";
    #######################################################
    my @export_reaction_types = ("CatalyticReaction", "BindingReaction", "AllostericReaction");
    Facile->export(
	NETWORK_REF => $RN_ref,
	REACTION_TYPES => [@export_reaction_types],
	EQN_FILE => "$OUT",
	APPEND => 0,
       );

    if ($report) {
	if ($report =~ /structure/ || $report =~ /all/) {
	    #######################################################
	    printn "REPORTING SPECIES STRUCTURE IN: $OUTDIR/$args{MODEL_ROOT}.structures.rpt";
	    #######################################################
	    open (STRUCTURE_RPT, "> $OUTDIR/$args{MODEL_ROOT}.structures.rpt");
	    my $report = Complex->sprint_structure_report();
	    $report .= ComplexInstance->Complex::sprint_structure_report();
	    print STRUCTURE_RPT $report;
	    close(STRUCTURE_RPT);
	    printn $report if $verbosity >= 2;
	}
	if ($report =~ /species/ || $report =~ /all/) {
	    #######################################################
	    printn "REPORTING SPECIES IN: $OUTDIR/$args{MODEL_ROOT}.species.rpt";
	    #######################################################
	    open (SPECIES_RPT, "> $OUTDIR/$args{MODEL_ROOT}.species.rpt");
	    my $report = Complex->sprint_report();
	    print SPECIES_RPT $report;
	    close(SPECIES_RPT);
	    printn $report if $verbosity >= 2;
	}
    }

    if ($export_graphviz =~ /network/) {
	printn "EXPORTING NETWORK TO GRAPHVIZ";
	`mkdir -p $OUTDIR/graphviz`;
	$RN_ref->export_graphviz(
	    REACTION_TYPES => [@export_reaction_types],
	    COLLAPSE_COMPLEXES => ($export_graphviz =~ /collapse_complexes/ ? 1 : 0),
	    COLLAPSE_STATES => ($export_graphviz =~ /collapse_states/ ? 1 : 0),
	    HIGHLIGHT_ALLOSTERY => 1,
	    FILENAME => "$OUTDIR/graphviz/$args{MODEL_ROOT}.network.svg"
	   );
    }

    foreach my $graph_type (split /,/, $export_graphviz) {
	next if !(($graph_type =~ /primary/) || ($graph_type =~ /scalar/) ||
		  ($graph_type =~ /ungrouped/) || ($graph_type =~ /canonical/));
	#######################################################
	printn "EXPORTING SPECIES TO GRAPHVIZ ($graph_type form)";
	#######################################################
	`mkdir -p $OUTDIR/graphviz/$graph_type`;
	foreach my $complex_ref (Complex->get_instances()) {
	    $complex_ref->export_graphviz(
		filename => "$OUTDIR/graphviz/$graph_type/".$complex_ref->get_exported_name().".png",
		src => $graph_type,
	       );
	}
	
	`mkdir -p $OUTDIR/graphviz/$graph_type/instances`;
	foreach my $complex_instance_ref (ComplexInstance->get_instances()) {
	    $complex_instance_ref->export_graphviz(
		filename => "$OUTDIR/graphviz/$graph_type/instances/".$complex_instance_ref->get_exported_name().".png",
		src => $graph_type,
	       );
	}
    }
}


# Package BEGIN must return true value
return 1;

