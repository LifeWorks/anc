######################################################################################
# File:     Facile.pm
# Author:   Julien F. Ollivier
#
# Copyright (C) 2005-2010 Julien Ollivier.
#
# This program comes with ABSOLUTELY NO WARRANTY.
# This is free software, and you are welcome to redistribute it
# under certain conditions. See file LICENSE.TXT for details.
#
# Synopsys: Export facilities for Facile network compiler.
######################################################################################
# Detailed Description:
# ---------------------
######################################################################################

use strict;
use diagnostics;		# equivalent to -w command-line switch
use warnings;

package Facile;
use Class::Std::Storable;
use base qw();
{
    use Carp;
    use Utils;

    use ModelParser;

    #######################################################################################
    # CLASS ATTRIBUTES
    #######################################################################################

    #######################################################################################
    # ATTRIBUTES
    #######################################################################################
#    my %A_of :ATTR(get => 'A', set => 'A', init_arg => 'A');  # constructor must supply initialization
#    my %B_of :ATTR(get => 'B', set => 'B', default => 'yyy'); # default value is yyy

    #######################################################################################
    # FUNCTIONS
    #######################################################################################

    #######################################################################################
    # CLASS METHODS
    #######################################################################################
    #--------------------------------------------------------------------------------------
    # Function: export
    # Synopsys: 
    #--------------------------------------------------------------------------------------
    sub export {
	my $class = shift;
	my %args = (
	    NETWORK_REF => undef,
	    REACTION_TYPES => undef,
	    EQN_FILE => undef,
	    APPEND => 0,
	    @_
	);

	check_args(\%args, 4);

	my $network_ref = $args{NETWORK_REF};

	my $mode = ($args{APPEND} ? ">>" : ">");

	# Equation file for Facile tool
	open(EQN, "$mode $args{EQN_FILE}") or die "ERROR: export_facile -- Couldn't open $args{EQN_FILE} for writing.\n";
	# Don't buffer output
	EQN->autoflush(1);

	printn "Facile->export(): generating Facile equation file";

	# HEADER
	print EQN "# Facile model created by Allosteric Network Compiler (ANC)\n";
	print EQN "# ANC version $main::VERSION released $main::RELEASE_DATE\n";
	print EQN "# ".`date`;
	print EQN "\n";

	# PARAMETERS
	my @param_refs = Parameter->get_instances();
	if (@param_refs) {
	    print EQN "\n\n";
	    print EQN "# PARAMETERS\n";
	    print EQN "# ----------\n";
	    foreach my $param_ref (@param_refs) {
		my $name = $param_ref->get_name();
		my $value = $param_ref->get_value();
		print EQN "parameter $name = $value\n";
	    }
	    print EQN "\n";
	}

	# EQUATIONS
	print EQN @{$network_ref->export_facile(
	    REACTION_TYPES => [@{$args{REACTION_TYPES}}],
	   )};
	
	my $eqn_section = ModelParser::sprint_section("EQN");
	if ($eqn_section) {
	    print EQN "\n\n";
	    print EQN "# CUSTOM REACTIONS (from EQN section)\n";
	    print EQN "# -----------------------------------\n";
	    print EQN $eqn_section;
	    print EQN "\n";
	}

	# INIT section
	print EQN @{Init->export_facile($network_ref)};

	print EQN @{Stimulus->export_facile()};	

	print EQN @{Probe->export_facile()};

	# MOIETY section
	my $moiety_section = ModelParser::sprint_section("MOIETY");
	if ($moiety_section) {
	    print EQN "\n\n";
	    print EQN "# MOIETY (from MOIETY section)\n";
	    print EQN "# ----------------------------\n";
	    print EQN "MOIETY:\n";
	    print EQN $moiety_section;
	    print EQN "\n";
	}

	# CONFIG section
	my $config_section = ModelParser::sprint_section("CONFIG");
	if ($config_section) {
	    print EQN "\n\n";
	    print EQN "# CONFIG (from CONFIG section)\n";
	    print EQN "# ----------------------------\n";
	    print EQN "CONFIG:\n";
	    print EQN ModelParser::sprint_section("CONFIG");
	    print EQN "\n";
	}

	close(EQN);
    }

    #--------------------------------------------------------------------------------------
    # Function: get_config_variables
    # Synopsys: 
    #--------------------------------------------------------------------------------------
    sub get_config_variables {
	my $class = shift;

	my $return_ref = {};

	my @config_section = ModelParser::get_section("CONFIG");
	foreach my $line (@config_section) {
	    if ($line =~ /(\S+)\s*=\s*(\S+)/) {
		$return_ref->{$1} = $2;
	    }
	}
	return $return_ref;
    }

    #######################################################################################
    # INSTANCE METHODS
    #######################################################################################

}


sub run_testcases {
    printn "NO TESTCASES!!!";
}


# Package BEGIN must return true value
return 1;

