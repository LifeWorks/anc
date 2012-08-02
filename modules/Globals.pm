######################################################################################
# File:     Globals.pm
# Author:   Julien F. Ollivier
#
# Copyright (C) 2005-2010 Julien Ollivier.
#
# This program comes with ABSOLUTELY NO WARRANTY.
# This is free software, and you are welcome to redistribute it
# under certain conditions. See file LICENSE.TXT for details.
#
# Synopsys: Miscellaneous configuration parameters affecting compilation, verbosity
#           and other behaviours of ANC.
######################################################################################
# Detailed Description:
# ---------------------
######################################################################################

#######################################################################################
# TO-DO LIST
#######################################################################################

#######################################################################################
# Package interface
#######################################################################################
package Globals;

use strict;

use Exporter;
use vars qw(@ISA @EXPORT @EXPORT_OK);
@ISA = qw(Exporter);
@EXPORT = qw($verbosity $debug);
@EXPORT_OK = qw(
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
		$sort_reactions_by_number
		$merge_degenerate_reactions
);

#######################################################################################
# Modules used
#######################################################################################
#use Utils;

#######################################################################################
# Package globals
#######################################################################################
use vars qw(
	    $verbosity
	    $debug

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

	    $sort_reactions_by_number
	    $merge_degenerate_reactions
	   );

#######################################################################################
# Function: globals_init
# Synopsys: Initialize package's exported variables to default values.
#######################################################################################
sub globals_init {
    $verbosity = 0;
    $debug = 0;

    $max_external_iterations = -1;
    $max_internal_iterations = -1;
    $max_species = -1;
    $max_complex_size = -1;
    $max_csite_bound_to_msite_number = -1;

    $default_steric_factor = "UNDEF";

    $kf_1st_order_rate_cutoff = 0.0;
    $kf_2nd_order_rate_cutoff = 0.0;
    $kb_rate_cutoff = 0.0;
    $kp_rate_cutoff = 0.0;

    $report = 0;
    $export_graphviz = 0;
    $compact_names = 1;
    $protein_separator = "_";

    $sort_reactions_by_number = 0;
    $merge_degenerate_reactions = 0;
}

#######################################################################################
# Package initialization
#######################################################################################
globals_init();

# Package BEGIN must return true value
return 1;

