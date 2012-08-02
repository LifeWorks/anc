######################################################################################
# File:     Init.pm
# Author:   Julien F. Ollivier
#
# Copyright (C) 2005-2010 Julien Ollivier.
#
# This program comes with ABSOLUTELY NO WARRANTY.
# This is free software, and you are welcome to redistribute it
# under certain conditions. See file LICENSE.TXT for details.
#
# Synopsys: Specify initial conditions for a single structure.
######################################################################################
# Detailed Description:
# ---------------------
#
#
######################################################################################

use strict;
use diagnostics;		# equivalent to -w command-line switch
use warnings;

package Init;
use Class::Std::Storable;
use base qw(Selector);
{
    use Carp;
    use Utils;

    #######################################################################################
    # CLASS ATTRIBUTES
    #######################################################################################
    Init->set_class_data("AUTONAME", "Ic");

    #######################################################################################
    # ATTRIBUTES
    #######################################################################################
    my %IC_of :ATTR(get => 'IC', set => 'IC', init_arg => 'IC');

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
	my $network_ref = shift;

	my @export = ();

	my @ICs = $class->get_instances();
	my @species = grep {defined $_->get_IC()} @{$network_ref->get_species()};

	if (@ICs || @species) {
	    push @export, "\n\n";
	    push @export, "# INITIAL CONCENTRATIONS (compiled from MODEL section)\n";
	    push @export, "# ----------------------------------------------------\n";
	    push @export, "INIT:\n";

	    # from Init objects
	    foreach my $init_ref (@ICs) {
		my $instance_ref = $init_ref->get_toplvl_selected_ref();
		if (!defined $instance_ref) {
		    printn "WARNING: can't export initial conditions for ".$init_ref->get_name();
		    next;
		}
		push @export, $instance_ref->get_exported_name()." = ".$init_ref->get_IC()."\n";
	    }

	    # from IC attribute of Species
	    foreach my $species_ref (@species) {
		my $IC = $species_ref->get_IC();
		my $species_name = $species_ref->get_exported_name();
		push @export, "$species_name = $IC\n"
	    }
	}

	my @init_section = ModelParser::sprint_section("INIT");

	if ("@init_section" ne "") {
	    push @export, "\n\n";
	    push @export, "# INITIAL CONCENTRATIONS (from INIT section)\n";
	    push @export, "# ------------------------------------------\n";
	    push @export, "INIT:\n";
	    push @export, @init_section;
	}

	return \@export;
    }

    #######################################################################################
    # INSTANCE METHODS
    #######################################################################################

    #--------------------------------------------------------------------------------------
    # Function: xxx
    # Synopsys: 
    #--------------------------------------------------------------------------------------
    sub xxx {
	my $self = shift;
    }

}


sub run_testcases {

    printn "NO TESTCASES!!!";

}



# Package BEGIN must return true value
return 1;

