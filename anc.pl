#!/usr/bin/perl -w
###############################################################################
#  File:     anc.pl   (Allosteric Network Compiler)
#- Synopsys: A systems biology tool for the rule-based modelling of
#-           allosteric proteins and biochemical networks.
#-#############################################################################
#
# Copyright (C) 2005-2011 Julien Ollivier.
#
# Allosteric Network Compiler (ANC) is free software: you can redistribute
# it and/or modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation, either version 3 of the License,
# or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program (file LICENSE.TXT included with the distribution).
# If not, see <http://www.gnu.org/licenses/>.
#
#- Detailed Description:
#- ---------------------
#-
#- INVOCATION:
#-
#- anc.pl [option]... model
#-
#- OPTIONS:
#-
#- --help            This help page.
#- --version         Print version/release info and quit.
#-
#- --verbosity=i     Verbosity level.  Defaults to 1.
#-
#- --out=(file)      Name of output file.  Default is file with same dir and
#-                   name as model but with .eqn extension.
#- --outdir=(dir)    Name of output directory for auxiliary files generated.
#-                   Default is directory of output file.
#-
#- --maxext=i        Maximum number of external iterations.
#- --maxint=i        Maximum number of internal iterations.
#- --maxspecies=i    Maximum number of species to generate.
#- --maxsize=i       Maximum number of proteins in generated complexes.
#-
#- --graphviz=s      Generate graphviz output.  The supplied string specifies
#-                   a set of graphs to generate.
#-                   To show structure of generated complexes, specify one or
#-                   more forms of the complex's graph which are to be output (
#-                   primary, ungrouped, scalar, or canonical).
#-                   E.g. --graphviz='primary,canonical'
#-                   To show the reaction network, specify 'network'.  Other
#-                   options are 'collapse_states' and 'collapse_complexes'.
#-                   E.g. --graphviz='network,collapse_states'
#- --report=s        Generate reports.  E.g. --report='species,structure,all'
#- --clean           Clean graphviz and report files from previous runs.
#- --shell           Runs an interactive shell after compilation.
#-
#-#############################################################################
use strict;

######################################################################################
# COMPILE-TIME ACTIONS
######################################################################################
# Supports many formats to dump data structures into text
#use Data::Dumper;
#$Data::Dumper::Indent = 1;    # !!!!! this option is incompatible with Class::Std::_DUMP()
use Getopt::Long;
use English;       # Use english names for global system variables

use Carp;

use FindBin qw($Bin);
use lib "$Bin/base";
use lib "$Bin/modules";

use LoadModules;
use CompileModel;

use Utils;
use Globals;

# PROCESS OPTIONS AND ARGUMENTS
use vars qw($HELP $VERBOSITY $DEBUG $MODEL $OUT $OUTDIR);
use vars qw($SHELL $SCRIPT $COMMAND);
use vars qw($MAXEXT $MAXINT $MAXSPECIES $MAXSIZE);
use vars qw($REPORT $GRAPHVIZ $COMPACT_NAMES $CLEAN);
use vars qw($version_flag);

GetOptions("help"            => \$HELP,
	   "verbosity=i"     => \$VERBOSITY,
	   "debug"           => \$DEBUG,

	   "out=s"           => \$OUT,
	   "outdir=s"        => \$OUTDIR,

	   "shell"           => \$SHELL,
	   "script=s"        => \$SCRIPT,
	   "command=s"       => \$COMMAND,

	   "maxext=i"        => \$MAXEXT,
	   "maxint=i"        => \$MAXINT,
	   "maxspecies=s"    => \$MAXSPECIES,
	   "maxsize=s"       => \$MAXSIZE,

	   "report=s"        => \$REPORT,
	   "graphviz=s"      => \$GRAPHVIZ,
	   "compact_names"   => \$COMPACT_NAMES,
	   "clean"           => \$CLEAN,
	   "version"         => \$version_flag,
	  );

#######################################################################################
# FUNCTIONS
#######################################################################################

######################################################################################
# MAIN PROGRAM
######################################################################################

# Don't buffer STDOUT
use IO::Handle;
STDOUT->autoflush(1);

#======================================================================================
# VERSION AND COPYRIGHT
#======================================================================================
use 5.008_000;            # require perl version 5.8.0 or higher
use Class::Std 0.0.8;     # require Class::Std version 0.0.8 or higher

# ANC version
use vars qw($VERSION $RELEASE_DATE);
$VERSION = "1.01";
$RELEASE_DATE = "2011/08/26";

print << "HEADER";
##############################################################################
# Allosteric Network Compiler (ANC)
# Copyright (C) 2005-2011 Julien Ollivier
# Author:       Julien F. Ollivier
# Version:      $VERSION
# Release Date: $RELEASE_DATE
# This program comes with ABSOLUTELY NO WARRANTY.
# This is free software, and you are welcome to redistribute it
# under certain conditions. See file LICENSE.TXT for details.
##############################################################################
HEADER

exit if ($version_flag);

#======================================================================================
# PROCESS ARGUMENTS
#======================================================================================

# --help
# Print out the header; this also serves as help
if (defined $HELP) {
    my $help_tag = "#-";
    my $OUT = `grep -E '^$help_tag' $PROGRAM_NAME`;
    $OUT =~ s/#-/#/g;
    printn $OUT;
    exit;
}

# --verbosity
#############
$verbosity = (defined $VERBOSITY) ? $VERBOSITY : 1;
$debug = (defined $DEBUG) ? $DEBUG : 0;

# --model
#############
$MODEL = shift @ARGV;
if (!defined $MODEL) {
    printn "ERROR: no model file...";
    exit(1);
}
my $model_dir = ($MODEL =~ /(.*)\/(.*)/) ? $1 : ".";
my $model_file = ($MODEL =~ /(.*\/)?(.*)/) ? $2 : "INTERNAL ERROR!!!";
my $model_root = ($model_file =~ /(.*)\.(.*)/) ? $1 : $model_file;

# --out
#############
$OUT = (defined $OUT ? $OUT : "${model_dir}/${model_root}.eqn");

# --outdir
#############
my $out_dir = ($OUT =~ /(.*)\/(.*)/) ? $1 : ".";
$OUTDIR = (defined $OUTDIR ? $OUTDIR : $out_dir);

system("mkdir -p $out_dir");
system("mkdir -p $OUTDIR");

# check and report args
#############
printn "\nMODEL \t= $MODEL\nOUT \t= $OUT\nOUTDIR \t= $OUTDIR";
printn;

if (@ARGV != 0) {
  print "\nERROR: Missing/bad arguments, use --help for information.\n";
  exit(1);
}

#======================================================================================
# START TIME
#======================================================================================
my $start_time = `date`;
chomp($start_time);
printn "Start time: $start_time";

#======================================================================================
# RUN SCRIPTS, COMMANDS, INTERPRETER
#======================================================================================
if (defined $COMMAND) {
    eval("$COMMAND");
} else {
    compile_model(
	MODEL => $MODEL,
	MODEL_ROOT => $model_root,
	OUT => $OUT,
	OUTDIR => $OUTDIR,
	MAXEXT => $MAXEXT,
	MAXINT => $MAXINT,
	MAXSPECIES => $MAXSPECIES,
	MAXSIZE => $MAXSIZE,
	REPORT => $REPORT,
	GRAPHVIZ => $GRAPHVIZ,
	COMPACT_NAMES => $COMPACT_NAMES,
	CLEAN => $CLEAN,
       );
}

if (defined $SCRIPT) {
  interpreter("ANC", $SCRIPT);
}

if (defined $SHELL) {
  interpreter("ANC");
}

#======================================================================================
# REPORT START/END TIME
#======================================================================================
my $end_time = `date`;
chomp($end_time);
print "Start time: $start_time\n";
print "End time:   $end_time\n";
exit;
