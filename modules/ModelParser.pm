######################################################################################
# File:     ModelParser.pm
# Author:   Julien F. Ollivier
#
# Copyright (C) 2005-2010 Julien Ollivier.
#
# This program comes with ABSOLUTELY NO WARRANTY.
# This is free software, and you are welcome to redistribute it
# under certain conditions. See file LICENSE.TXT for details.
#
# Synopsys: Read an ANC model file section by section and do pre-processing.
######################################################################################
# Detailed Description:
# ---------------------
######################################################################################


#######################################################################################
# Package interface
#######################################################################################
package ModelParser;

use strict;

use Exporter;
use vars qw(@ISA @EXPORT);
@ISA = qw(Exporter);
@EXPORT = qw(
	     read_model
);

#######################################################################################
# Modules used
#######################################################################################
use Data::Dumper;

use Carp;

use Utils;
use Globals;

use Species;

# the section that the input file is assumed to begin with should be first element of array
my @section_names = ("MODEL", "EQN", "INIT", "MOIETY", "BIFURC_PARAM", "CONFIG", "PROMOTER", "PROBE");
my $file_buffer_ref;
map {$file_buffer_ref->{"$_"} = []} @section_names;

sub read_model {
    my $model_filename = shift;

    read_and_preprocess_model_file($model_filename);
    parse_init_section();   # parse the init section first, we'll need the info in model section
    parse_model_section();
}

sub read_and_preprocess_model_file {
    my $model_filename = shift;

    if (!open (MODEL, "< $model_filename")) {
	printn "ERROR: no such model file $model_filename";
	exit (1);
    }

    # since file is assumed to start with MODEL section,
    # it should be first in section_names array
    my $current_section = $section_names[0];

    my $statement_buffer = "";
    LINES: while (<MODEL>) {
        $_ =~ s/^\s+//;         # Strip out leading whitespace
        $_ =~ s/\s+$//;         # Strip out trailing whitespace (including \n)
        $_ =~ s/\s*\#.*//;      # Strip out trailing comment and whitespace
        $_ =~ s/\s*\/\/.*//;    # Strip out trailing comment and whitespace
        next if($_ =~ /^$/);    # Skip empty lines
	my $line = $_;

	# check if new section
	foreach my $section (@section_names) {
	    if ($line =~ /$section\:?/) {
		$current_section = $section;
		next LINES;
	    }
	}

	# if previous line ends with any char in ",{[("  assume we are in middle of a statement, and
	# in this case we want to treat the entire statement as one array element
	if ($line =~ /[,{\[\(]$/) {
	    $statement_buffer .= "$line\n";  # add \n since closing part will always follow
	} else {
	    push @{$file_buffer_ref->{$current_section}}, "$statement_buffer$line";
	    push @{$file_buffer_ref->{ALL_SECTIONS}}, "$statement_buffer$line";
	    $statement_buffer = "";
	}
    }

    close(MODEL);
#print join "XXX\n", @{$file_buffer_ref->{ALL_SECTIONS}};exit;
}

#######################################################################################
# Function: parse_init_section
# Synopsys: Check INIT section, if problems found then exit.
#######################################################################################
sub parse_init_section {
    foreach (@{$file_buffer_ref->{INIT}}) {
	my $line = $_;
	if ($line =~ /(\S+)\s*=\s*(\S+)/) {
	    my $name = $1;
	    my $IC = $2;
	    if (!is_numeric($IC)) {
		issue_error("(in INIT section) you must give an numerical value to the IC for $name");
	    }
	} else {
	    issue_error("(in INIT section) can't parse line:\n--> $line");
	}
    }
}


#######################################################################################
# Function: parse_model_section
# Synopsys: 
#######################################################################################
sub parse_model_section {
    foreach (@{$file_buffer_ref->{MODEL}}) {
	my $line = $_;

	if ($line =~ /^(\S+)\s*:\s*({.*})$/s) {
	    # object creation

	    my $class = $1;
	    my $attrib_ref = $2;

	    # load class
	    eval "use $class";   # need the eval else syntax error

	    # grab attributes
	    my $object_attributes = eval("no strict; $attrib_ref; use strict;");
	    if ($@) {
		printn "ERROR: can't eval this string in model file --> $attrib_ref";
		die $@;
	    }
	    # translate element names into references if class is a Set
	    if ($class->isa('Set')) {
		my @element_classes = split ",", $class->get_class_data("ELEMENT_CLASS");
		foreach my $element_name (@{$object_attributes->{elements}}) {
		    my @element_refs = map $_->lookup_by_name($element_name), @element_classes;
		    @element_refs = grep ($_, @element_refs);
		    issue_error("cannot find element $element_name in class(es) @element_classes") if (@element_refs < 1);
		    issue_error("cannot resolve element $element_name to a unique class in [@element_classes]") if (@element_refs > 1);
		    push @{$object_attributes->{elements_ref}}, $element_refs[0];
		}
	    }
	    $class->new($object_attributes);
	} elsif ($line =~ /^(\S+)\s*:\s*(\S+)\s*\-\>\s*(\w+)\s*(\((.*)\))?\s*;?\s*$/s) {
	    # class method call e.g.
	    #   Stimulus : Stimulus->foo(bar)
	    # ... or object method call e.g.
	    #   ObjClass : ObjName->foo(bar)

	    my $class = $1;
	    my $name = $2;
	    my $method = $3;
	    my $args = $5;

	    eval "use $class";   # need the eval else syntax error

	    if ($class ne $name) { # object method?
		my $ref = $class->lookup_by_name($name);
		eval "\$ref->$method($args);";
		die $@ if $@;
	    } else {
		# class method
		eval "$class->$method($args);";
		die $@ if $@;
	    }
	} elsif ($line =~ /^(\$\S+)\s*=\s*(\S+)$/s) {
	    # matched a variable assignement
	    # import global variables so that eval will plug them right in
	    use Globals qw(
			   $max_external_iterations
			   $max_internal_iterations
			   $max_species
			   $max_complex_size
			   $max_csite_bound_to_msite_number
			   $kf_1st_order_rate_cutoff
			   $kf_2nd_order_rate_cutoff
			   $kb_rate_cutoff
			   $kp_rate_cutoff
			   $default_steric_factor
			   $export_graphviz
			   $compact_names
			   $protein_separator
			  );

	    eval("no strict; $line; use strict;");
	    die $@ if $@;
	} else {
	    issue_error("(in MODEL section) can't parse line\n --> $line");
	}
    }
}

#######################################################################################
# Function: get_section
# Synopsys: Return a section as array of lines.
#######################################################################################
sub get_section {
    my $section = shift;

    if (!grep($section, @section_names)) {
	return ();
    } else {
	return @{$file_buffer_ref->{$section}};
    }
}

#######################################################################################
# Function: sprint_section
# Synopsys: Print section to string.
#######################################################################################
sub sprint_section {
    my $section = shift;

    if (!grep($section, @section_names)) {
	return "";
    } else {
	return join "\n", @{$file_buffer_ref->{$section}};
    }
}

1;
