######################################################################################
# File:     CmdLineOptions.pm
# Author:   Julien F. Ollivier
#
# Copyright (C) 2005-2010 Julien Ollivier.
#
# This program comes with ABSOLUTELY NO WARRANTY.
# This is free software, and you are welcome to redistribute it
# under certain conditions. See file LICENSE.TXT for details.
#
# Synopsys: Grab command line options and dump in hash table.
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
package CmdLineOptions;

use strict;

use Exporter;
use vars qw(@ISA @EXPORT);
@ISA = qw(Exporter);
@EXPORT = qw(
	     %opt
	     get_command_line_options
);


#######################################################################################
# Modules used
#######################################################################################
use Getopt::Long;

#######################################################################################
# Function: get_command_line_options
# Synopsys: 
#######################################################################################
sub get_command_line_options {
    $getoptions_arg = "\\%opt, ";
    foreach (@ARGV) {
	if (/--(.*)=(.*)/) {
	    $getoptions_arg .= "'$1=s', ";
	} elsif (/--(.*)/) {
	    $getoptions_arg .= "'$1', ";
	}
    }
#    print "Argument to GetOptions: $getoptions_arg\n";
    eval("GetOptions($getoptions_arg);");
}
