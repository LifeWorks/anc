######################################################################################
# File:     Probe.pm
# Author:   Julien F. Ollivier
#
# Copyright (C) 2005-2010 Julien Ollivier.
#
# This program comes with ABSOLUTELY NO WARRANTY.
# This is free software, and you are welcome to redistribute it
# under certain conditions. See file LICENSE.TXT for details.
#
# Synopsys: A Probe is a list of species matching filtering criteria, which can
#           be exported as a Facile probe.
######################################################################################
# Detailed Description:
# ---------------------
######################################################################################

use strict;
use diagnostics;		# equivalent to -w command-line switch
use warnings;

package Probe;
use Class::Std::Storable;
use base qw(Selector);
{
    use Carp;
    use IO::Handle;

    use Utils;
    use Globals;

    #######################################################################################
    # CLASS ATTRIBUTES
    #######################################################################################
    Probe->set_class_data("AUTONAME", "Prb");

    #######################################################################################
    # ATTRIBUTES
    #######################################################################################

    #######################################################################################
    # FUNCTIONS
    #######################################################################################

    #######################################################################################
    # CLASS METHODS
    #######################################################################################
    #--------------------------------------------------------------------------------------
    # Function: export_facile
    # Synopsys: 
    #--------------------------------------------------------------------------------------
    sub export_facile {
	my $class = shift;

	my @export = ();

	# get all non-empty probes
	my @probes = $class->get_instances();
	@probes = grep {@{$_->get_toplvl_instances_ref()}} @probes;
	if (@probes) {
	    push @export, "\n\n";
	    push @export, "# COMPILED PROBES (from Probe objects)\n";
	    push @export, "# ------------------------------------\n";
	    push @export, "PROBE:\n";

	    foreach my $probe_ref (@probes) {
		if (defined $probe_ref->get_structure()) {
		    push @export, "probe ".$probe_ref->get_selected_ref()->get_exported_name()."\n";
		} else {
		    push @export, "probe ".$probe_ref->get_exported_name()." = \"";
		    push @export, join(" + ", map ($_->get_exported_name(), @{$probe_ref->get_toplvl_instances_ref()}))."\"\n";
		}
	    }
	}

	my $custom_probes = ModelParser::sprint_section("PROBE");
	if ($custom_probes) {
	    push @export, "\n\n";
	    push @export, "# CUSTOM PROBES (from PROBE section)\n";
	    push @export, "# ----------------------------------\n";
	    push @export, "PROBE:\n";
	    push @export, $custom_probes;
	    push @export, "\n";
	}
	return \@export;
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

}


sub run_testcases {
    printn "NO TESTCASES!!!!";
}


# Package BEGIN must return true value
return 1;

