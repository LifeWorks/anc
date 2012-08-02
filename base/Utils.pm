######################################################################################
# File:     Utils.pm
# Author:   Julien F. Ollivier
#
# Copyright (C) 2005-2010 Julien Ollivier.
#
# This program comes with ABSOLUTELY NO WARRANTY.
# This is free software, and you are welcome to redistribute it
# under certain conditions. See file LICENSE.TXT for details.
#
# Synopsys: Miscellaneous routines
######################################################################################
# Detailed Description:
# ---------------------
#
######################################################################################

#######################################################################################
# TO-DO LIST
#######################################################################################

#######################################################################################
# Package interface
#######################################################################################
package Utils;

use strict;

use Carp;

use Exporter;
use vars qw(@ISA @EXPORT);
@ISA = qw(Exporter);
@EXPORT = qw(
	     printn
	     issue_message
	     issue_note
	     issue_warning
	     issue_error
	     issue_failure
	     message
	     slurp_file
	     burp_file
	     check_args
	     print_args
	     uniquify
	     uniquify_lookahead
	     uniquify_confirm
	     print_list
	     print_2d_array
	     simplify
	     strip
	     min_ascii
	     max_ascii
	     max_numeric
	     min_numeric
	     normalize_on_maximum
	     normalize_on_magnitude
	     magnitude
	     average
	     variance
	     median
	     correlation
	     dot_product
	     norm_projection
	     union
	     intersection
	     symmetric_difference
	     simple_difference
	     find_element
	     round2int
	     round2sig
	     read_config
	     mean_squared_error
	     repeat
	     log_10
	     p_hill
	     n_hill
	     linear
	     linear_inv
	     loglinear
	     loglinear_inv
	     getnum
	     is_numeric
	     fmod
	     interpreter
	     sprint_class_hierarchy
	    );

#######################################################################################
# Modules used
#######################################################################################
#use Data::Dumper;

#######################################################################################
# Function: printn
# Synopsys: Wrapper for print function that adds a newline.
#######################################################################################
sub printn {
    print @_;
    print "\n";
}

#######################################################################################
# Function: message
# Synopsys: Issue Notes, Warnings, Errors and Failure messages to user and quit.
#######################################################################################
# Type argument is a string.
#
# First character, S|N|W|E|F indicating message gravity
# M:       bla bla (ordinary message to user, no prefix)
# N:       Note: bla bla...
# W:       Warning: bla bla...
# Error:   Error: bla ....
# Failure: FAILURE: internal error -- bla bla ...  stack backtrace via confess()
#
# Second character, 0|1 indicating whether to incorporate calling routine name
# (NOT IMPLEMENTED)
use vars qw ($force_backtrace); $force_backtrace = 0;
sub message {
    my $type = shift;
    my $message = shift;

    my @type = split //, $type;

    if ($type[0] eq 'M') {
	printn "$message";
    } elsif ($type[0] eq 'N') {
	printn "Note: $message";
    } elsif ($type[0] eq 'W') {
	printn "\nWARNING: $message\n";
    } elsif ($type[0] eq 'E') {
	printn "\nERROR: $message\n";
	exit(1);
    } elsif ($type[0] eq 'F') {
	confess "\nFAILURE: internal error -- $message\n";
    } else {
	message('F', "Bad message format");
    }
}
sub issue_message {
    message('S', @_);
}
sub issue_note {
    message('N', @_);
}
sub issue_warning {
    message('W', @_);
}
sub issue_error {
    message('E', @_);
}
sub issue_failure {
    message('F', @_);
}

#######################################################################################
# Function: slurp_file/burp_file
# Synopsys: Return array of lines in the file.
#           If the file cannot be opened, the first element of the
#           returned array will exist but be undef.
#           If the file is simply empty, the first element will not exist.
#######################################################################################
sub slurp_file {
    my $filename = shift;
    open (SLURP, "< $filename") || return undef;
    my @file = <SLURP>;
    close SLURP;
    return @file;
}

sub burp_file {
    my $filename = shift;
    open (BURP, "> $filename") || return undef;
    foreach (@_) {
	print BURP $_;
    }
    close BURP;
}

#######################################################################################
# Function: check_args
# Synopsys: Check named parameters in a function call.
#######################################################################################
sub check_args {
    my $args_ref = shift;
    my $num_args = shift;

    my $calling_sub = (caller(1))[3];

    if (keys %$args_ref != $num_args) {
	confess "ERROR: $calling_sub -- unknown argument in ". join ", ", sort keys %$args_ref;
    }

    foreach my $key (keys %$args_ref) {
	if (!defined $args_ref->{$key}) {
	    confess "ERROR: $calling_sub -- must specify $key";
	}
    }
}

#######################################################################################
# Function: print_args
# Synopsys: Print named parameters in a function call.
#######################################################################################
sub print_args {
    my $args_ref = shift;

    my $calling_sub = (caller(1))[3];
    $calling_sub = (caller(2))[3] if ($calling_sub =~ /check_args/);

    print "$calling_sub: "; printn (map {"$_ -> $args_ref->{$_} "} sort keys %$args_ref);
}

#######################################################################################
# Function: uniquify
# Synopsys: Uniquify a name using 4-digit decimal sequence.  If an associated value is
#           provided, then map names with identical values to the same identifier.
#######################################################################################
# Detailed Description:
# ---------------------
#######################################################################################
BEGIN {   # need BEGIN for static %counter hash else compile error
    my %counter;
    my %val2count;
    sub uniquify {
	my $name = shift;
	my $separator = shift;
	my $val = shift;

	my $unique_name;
	
	if ($name eq "RESET") {
	    %counter = ();
	    %val2count = ();
	    return;
	}
	
	if (!defined $separator) {
	    $separator = "!";
	}
	if (!(exists $counter{$name})) {
	    $counter{$name} = 0;
	}

	if ((!defined $val) || (!exists $val2count{$name}{"$val"})) {
	    $unique_name = sprintf("%s$separator%02d",$name,$counter{$name});
	    $val2count{$name}{"$val"} = $counter{$name} if defined $val;
	    $counter{$name}++;
	} else {
	    $unique_name = sprintf("%s$separator%02d",$name,$val2count{$name}{"$val"});
	}
	return $unique_name;
    }

    my $lookahead_name;

    sub uniquify_lookahead {
	my $name = shift;
	my $separator = shift;
	my $val = shift;

	my $unique_name;
	
	if ($name eq "RESET") {
	    %counter = ();
	    %val2count = ();
	    return;
	}
	
	if (!defined $separator) {
	    $separator = "!";
	}
	if (!(exists $counter{$name})) {
	    $counter{$name} = 0;
	}

	if ((!defined $val) || (!exists $val2count{$name}{"$val"})) {
	    $unique_name = sprintf("%s$separator%02d",$name,$counter{$name});
	    $val2count{$name}{"$val"} = $counter{$name} if defined $val;
	    # for lookahead, we don't increment, just store name
	    $lookahead_name = $name;
	} else {
	    $unique_name = sprintf("%s$separator%02d",$name,$val2count{$name}{"$val"});
	}
	return $unique_name;
    }

    sub uniquify_confirm {
	# !!!! no check is made that this is the counter that user intended to increment ???
	$counter{$lookahead_name}++;
    }
}

#######################################################################################
# Function: print_list
# Synopsys: Prints out rows of given 2-D array.
#######################################################################################
sub print_list {
    printn join ",", @_;
}

#######################################################################################
# Function: print_2d_array
# Synopsys: Prints out rows of given 2-D array.
#######################################################################################
sub print_2d_array {
    my $A = $_[0];

    my $list_ptr;
    foreach $list_ptr (@$A) {
	printn "@$list_ptr";
    }
}

#######################################################################################
# Function: simplify
# Synopsys: Substitute specified unusual characters with underscore.
#######################################################################################
sub simplify {
    my $arg = shift;
    my $chars = shift;

    # substitute specified characters
    foreach my $char (split "", $chars) {
	my $ss = "\\$char";
	$arg =~ s/$ss/_/g;
    }
    return $arg;
}

#######################################################################################
# Function: strip
# Synopsys: Remove specified unusual characters and whitespaces
#######################################################################################
sub strip {
    my $arg = shift;
    my $chars = shift;

    # remove specified characters
    foreach my $char (split "", $chars) {
	my $ss = "\\$char";
	$arg =~ s/$ss//g;
    }
    # remove whitespace
    $arg =~ s/\s//g;
    return $arg;
}

#######################################################################################
# Function: max_ascii
# Synopsys: Gets maximimum element in list based on asciibetical sort.
#######################################################################################
sub max_ascii {
    my @sorted_list = sort @_;
    return $sorted_list[$#sorted_list];
}

#######################################################################################
# Function: max_numeric
# Synopsys: Gets maximimum element in list based on numeric sort.
#######################################################################################
sub max_numeric {
    my @sorted_list = sort {$a <=> $b} @_;
    return $sorted_list[$#sorted_list];
}

#######################################################################################
# Function: min_ascii
# Synopsys: Gets minimum element in list (ascii sort)
#######################################################################################
sub min_ascii {
    my @sorted_list = sort @_;
    return $sorted_list[0];
}

#######################################################################################
# Function: min_numeric
# Synopsys: Gets minimum element in list based on numeric sort.
#######################################################################################
sub min_numeric {
    my @sorted_list = sort {$a <=> $b} @_;
    return $sorted_list[0];
}

#######################################################################################
# Function: magnitude
# Synopsys: Computes magnitude of vector
#######################################################################################
sub magnitude {
    my $magnitude_sqr = 0;
    foreach (@_) {
	$magnitude_sqr += ($_)**2;
    }
    return sqrt($magnitude_sqr);
}

#######################################################################################
# Function: average
# Synopsys: Computes average value of vector elements
#######################################################################################
sub average {
    my $sum = 0;
    foreach (@_) {
	$sum += $_;
    }
    return (@_ == 0) ? undef : ($sum)/@_;
}

#######################################################################################
# Function: variance
# Synopsys: Compute variance of vector
#######################################################################################
sub variance {
    my $average = average(@_);
    my $sum_sqr = 0;
    foreach (@_) {
	$sum_sqr += ($_ - $average)**2;
    }
    return ($sum_sqr)/@_;
}

#######################################################################################
# Function: median
# Synopsys: Computes median value of elements
#######################################################################################
sub median {
    my @list = @_;
    my @sorted_list_indices = sort {$list[$a] <=> $list[$b]} (0..$#list);  # ascending
    my @sorted_list = map {$list[$_]} @sorted_list_indices;

    if (@sorted_list == 0) {
	return undef;
    } else {
	return ((@sorted_list % 2) == 1 ?  # odd?
		$sorted_list[$#sorted_list/2] :
		average($sorted_list[@sorted_list/2 - 1], $sorted_list[@sorted_list/2])
	       );
    }
}

#######################################################################################
# Function: normalize_on_maximum
# Synopsys: Normalizes elements in a list based on maximum value
#######################################################################################
sub normalize_on_maximum {
    my $maximum = max_numeric(@_);
    
    my @normalized_list;
    foreach (@_) {
	push @normalized_list, ($_/$maximum);
    }
    return @normalized_list;
}

#######################################################################################
# Function: normalize_on_magnitude
# Synopsys: Normalizes elements in a list based on magnitude
#######################################################################################
sub normalize_on_magnitude {
    my $magnitude = magnitude(@_);
    
    my @normalized_list;
    foreach (@_) {
	push @normalized_list, ($_/$magnitude);
    }
    return @normalized_list;
}

#######################################################################################
# Function: correlation
# Synopsys: Computes correlation between two vectors (of same size), returns zero
#           if the variance of either vector is zero.
#######################################################################################
sub correlation {
    my @vec1 = @_[0..($#_ + 1)/2 - 1];
    my @vec2 = @_[($#_ + 1)/2..$#_];
    
    my $size;
    if (@vec1 != @vec2) {
	printn "ERROR: correlation -- need same size arguments";
	exit;
    } else {
	$size = @vec1;
    }
    
    my $mean1 = 0;
    my $mean2 = 0;
    for (my $i=0; $i < $size; $i++) {
	$mean1 += $vec1[$i];
    }
    $mean1 = $mean1 / $size;
    for (my $i=0; $i < $size; $i++) {
	$mean2 += $vec2[$i];
    }
    $mean2 = $mean2 / $size;
    
    my ($ss_x, $ss_y, $ss_xy);
    for (my $i=0; $i < $size; $i++) {
	$ss_x += ($vec1[$i] - $mean1)**2;
	$ss_y += ($vec2[$i] - $mean2)**2;
	$ss_xy += ($vec1[$i] - $mean1) * ($vec2[$i] - $mean2);
    }
    
    return (($ss_x == 0.0) || ($ss_y == 0)) ? 0 : $ss_xy/sqrt($ss_x * $ss_y);
}

#######################################################################################
# Function: dot_product
# Synopsys: Computes dot product of two vectors (of same size).
#######################################################################################
sub dot_product {
    my @vec1 = @_[0..($#_ + 1)/2 - 1];
    my @vec2 = @_[($#_ + 1)/2..$#_];
    
    my $size;
    if (@vec1 != @vec2) {
	printn "ERROR: dot_product -- need same size arguments";
	exit;
    } else {
	$size = @vec1;
    }
    
    my $product = 0;
    my $i;
    for ($i=0; $i < $size; $i++) {
	$product += $vec1[$i]*$vec2[$i];
    }
    return $product;
}

#######################################################################################
# Function: norm_projection
# Synopsys: Computes normalized projection of two vectors (cosine of angle).
#######################################################################################
sub norm_projection {
# printn "aaa ".join ",", @_;
    my @vec1 = @_[0..($#_ + 1)/2 - 1];
    my @vec2 = @_[($#_ + 1)/2..$#_];
    
    my $size;
    if (@vec1 != @vec2) {
	printn "ERROR: norm_projection -- need same size arguments";
	exit;
    } else {
	$size = @vec1;
    }
    
    my $mag1 = magnitude(@vec1);
    my $mag2 = magnitude(@vec2);
    my $i;
    if (($mag1 == 0) || ($mag2 == 0)) {
	return undef;
    } else {
#printn "vec1 ". join ",", @vec1;
#printn "vec2 ". join ",", @vec2;
#printn "xxx ". dot_product(@vec1, @vec2);
#printn "yyy ". magnitude(@vec1);
#printn "yyy ". magnitude(@vec2);
	return dot_product(@vec1, @vec2)/(magnitude(@vec1)*magnitude(@vec2));
    }
}

#######################################################################################
# Function: union (From Perl Cookbood, R4.8)
# Synopsys: Returns the union list of arguments.  Removes duplicates.
#######################################################################################
sub union {
    my ($a, $b) = ($_[0], $_[1]);
    my (%union, @union);

    foreach my $e (@$a, @$b) {
	push @union, $e if !$union{$e};
	$union{$e} = 1;
    }

    return @union;
}

#######################################################################################
# Function: intersection (From Perl Cookbood, R4.8)
# Synopsys: Returns the intersection list of arguments. Removes duplicates.
#######################################################################################
sub intersection {
    my ($a, $b) = ($_[0], $_[1]);
    my %seen;
    my %isect;
    my @isect;

    foreach my $e (@$a) { $seen{$e} = 1 }

    foreach my $e (@$b) {
	if ($seen{$e}) {
	    push @isect, $e if !$isect{$e};
	    $isect{$e} = 1;
	}
    }
    return @isect;
}

#######################################################################################
# Function: symmetric_difference (Adapted from Perl Cookbood, R4.8)
# Synopsys: Returns the symmetric difference of the argument lists, i.e.
#           all elements in one set but not the other.
#            **** ASSUMES NO DUPLICATES IN ARGUMENTS. ****
#######################################################################################
sub symmetric_difference {
    my ($a, $b) = ($_[0], $_[1]);
    my @diff;
    my %count;

    foreach my $e (@$a, @$b) { $count{$e}++ }

    foreach my $e (@$a, @$b) {
	if ($count{$e} == 1) {   # i.e. return elements in A or B but not both
	    push @diff, $e;
	}
    }
    return @diff;
}

#######################################################################################
# Function: simple_difference (Adapted from Perl Cookbood, R4.7)
# Synopsys: Returns elements in array in A that aren't in B (A - B).
#           **** REMOVES DUPLICATES. ****
#######################################################################################
sub simple_difference {
    my ($a, $b) = ($_[0], $_[1]);
    my @diff;
    my %seen;

    foreach my $e (@$b) { $seen{$e} = 1 }

    foreach my $e (@$a) {
	if (!$seen{$e}) {   # i.e. return elements in A but not in B
	    push @diff, $e;
	    $seen{$e} = 1;   # remove duplicates
	}
    }
    return @diff;
}

#######################################################################################
# Function: find_element
# Synopsys: Find indexes of matching elements in a list
#######################################################################################
sub find_element {
    my ($match, $array) = ($_[0], $_[1]);

    my @return_list = ();
    my $i;
    for ($i=0; $i < @$array; $i++) {
	if ($array->[$i] =~ /$match/) {
	    push @return_list, $i;
	}
    }
    return @return_list;
}

#######################################################################################
# Function: round2int
# Synopsys: Round argument to nearest integer
#######################################################################################
sub round2int {
    return (sprintf("%.0f", $_[0])) + 0;
}

#######################################################################################
# Function: round2sig
# Synopsys: Round argument to given number of significant digits.
#######################################################################################
sub round2sig {
    my $arg = shift;
    my $sig = shift;
    confess "ERROR: can't have negative number of significant digits" if $sig < 0;
    $sig = round2int($sig);
    my $rounded = sprintf("%.${sig}g", $arg) + 0.0;
    return $rounded;
}

#######################################################################################
# Function: read_config
# Synopsys: Read configuration from a file into hash.
#
# EXAMPLE CONFIG FILE:
#           xxx = yyy             # parameter xxx takes on value yyy
#           source myconfig.cfg   # read a nested configuration file
#######################################################################################
sub read_config {
    my $hash_Ref = shift;
    my $filename = shift;
    my $noclobber = shift;  # protect previously defined keys

    confess "ERROR: you have to pass a defined hash_ref as 1st argument" if !defined $hash_Ref;

    printn "read_config: reading $filename";

    my @config_file = slurp_file("$filename");
    if (exists $config_file[0] && !defined $config_file[0]) {
	die "ERROR: read_config -- can't open $filename for reading\n";
    }

    my $split_line_buffer = "";
    for (my $i=0; $i < @config_file; $i++) {
	my $line = $config_file[$i];
	$line =~ s/^\s+//;         # Strip out leading whitespace
	$line =~ s/\s+$//;         # Strip out trailing whitespace (including \n)
	$line =~ s/\s*\#.*//;      # Strip out trailing comment and whitespace
	$line =~ s/\s*\/\/.*//;    # Strip out trailing comment and whitespace
	next if($line =~ /^$/ && !$split_line_buffer);    # Ignore empty lines
	chomp $line;

	if ($line =~ /\\$/) {  # backslash at end?
	    chop $line;
	    $split_line_buffer .= $line;
	    next if ($i != $#config_file);
	    # last line of file
	    $line = $split_line_buffer;
	    $split_line_buffer = "";
	} else {
	    $line = $split_line_buffer . $line;
	    $split_line_buffer = "";
	}

	if ($line =~ /(\S+)\s*=\s*(.+?)\s*$/) {
	    my $name = $1;
	    my $value = $2;
	    if ((!defined $hash_Ref->{$name}) || (!$noclobber)) {
		if ($value =~ /,/) {
		    # it's a list
		    my @values = split(/\s*,\s*/, $value);
		    $hash_Ref->{$name} = \@values;
		    printn "read_config: $name = [".join(",",@values)."]";
		} else {
		    $hash_Ref->{$name} = $value;
		    printn "read_config: $name = $value";
		}
	    } else {
		printn "read_config: (ignoring $name = $value because noclobber set)";
	    }
	    next;
	} elsif ($line =~ /source\s+(\S+)/) {
	    my $nested_config = $1;
	    read_config($hash_Ref, $nested_config, $noclobber);
	    next;
	}
	printn "ERROR: read_config -- bad line '$line'";
	exit(1);
    }
}

#######################################################################################
# Function: mean_squared_error
# Synopsys: Computes the mean squared error between arguments.
#######################################################################################
sub mean_squared_error {
    my $vec1 = shift;
    my $vec2 = shift;

    if (@$vec1 != @$vec2) {
	printn "ERROR: mean_squared_error -- vectors must be same size";
	exit(1);
    }

    my $sum = 0;
    for (my $i = 0; $i < @$vec1; $i++) {
	$sum += ($vec1->[$i] - $vec2->[$i])**2;
    }

    return $sum/@$vec1;
}

#######################################################################################
# Function: repeat
# Synopsys: Implements repeat operator that returns a list.
#######################################################################################
sub repeat {
    my $element = shift;
    my $repeat = shift;
    my @return_list = ();
    for (my $i = 0; $i < $repeat; $i++) {
	push @return_list, $element
    }
    return \@return_list;
}

# stolen from "perldoc log"
sub log_10 {
    my $n = shift;
    return log($n)/log(10);
}

#######################################################################################
# Function: p_hill
# Synopsys: positive-slope hill function
#######################################################################################
sub p_hill {
    my $x = shift;  # argument
    my $r = shift;  # critical point
    my $n = shift;  # order

    my $kn = ($x / $r) ** $n;
    return $kn / (1 + $kn);
}

#######################################################################################
# Function: n_hill
# Synopsys: negative-slope hill function
#######################################################################################
sub n_hill {
    my $x = shift;  # argument
    my $r = shift;  # critical point
    my $n = shift;  # order

    my $kn = ($x / $r) ** $n;
    return 1.0 / (1 + $kn);
}

#######################################################################################
# Function: linear/inv_linear
# Synopsys: Rescale a real number x which represents a proportional change from initial
#           value of y (when x=0) to final value of y (when x=xf).
#######################################################################################
# Formula: y
sub linear {
    my $y0 = shift;
    my $yf = shift;
    my $xf = shift;
    my $x = shift;

    my $y = $y0 + ($yf - $y0)*($x/$xf);
    return $y;
}
sub linear_inv {
    my $y0 = shift;
    my $yf = shift;
    my $xf = shift;
    my $y = shift;

    my $x = ($y-$y0)/($yf - $y0)*$xf;
    return $x;
}

#######################################################################################
# Function: loglinear/loglinear_inv
# Synopsys: Rescale a real number x which represents a fold change from initial
#           value of y (when x=0) to final value of y (when x=xf).
#######################################################################################
# Formula to map x to an exponentially decreasing (xf<x0) or increasing (xf>x0) curve y(x):
# y(x) = y0*exp(log(yf/y0)*(x/xf)) = y0 * (yf/y0)**(x/xf),
# where xf = 2**n-1
sub loglinear {
    my $y0 = shift;
    my $yf = shift;
    my $xf = shift;
    my $x = shift;

#    printn "XXX $y0, $yf, $xf, $x";

    # using exp/log form results in less roundoff error
    my $y = $y0 * (exp(log($yf/$y0)*($x/$xf)));
    return $y;
}
sub loglinear_inv {
    my $y0 = shift;
    my $yf = shift;
    my $xf = shift;
    my $y = shift;

#    printn "XXX $y0, $yf, $xf, $x";

    # using exp/log form results in less roundoff error
    my $x = $xf*log($y/$y0)/log($yf/$y0);
    return $x;
}

#######################################################################################
# Function: getnum/is_numeric
# Synopsys: From Perl Cookbook recipie 2.1.  Function getnum takes string and converts
#           to number or returns undef if not C float.  Function is_numeric just
#           checks that a string is a number.
#
#           N.b. For function strtod, the strings INF, NAN, -Infinity, etc. count
#           as numeric values!  So is_numeric will return true in that case.
#######################################################################################
sub getnum {
    use POSIX qw(strtod);
    my $str = shift;

    confess "ERROR: argument str not defined in getnum()" if !defined $str;

    $str =~ s/^\s+//;
    $str =~ s/\s+$//;
    $! = 0;
    my($num, $unparsed) = strtod($str);
    if (($str eq '') || ($unparsed != 0) || $!) {
        return;
    } else {
        return $num;
    }
}
sub is_numeric { return defined (scalar getnum(shift)) ? 1 : 0 }

#--------------------------------------------------------------------------------------
# Function: fmod
# Synopsys: Fractional modulus.  Perl's modulus only works on integers such that
#           11.5 % 2 returns 1 instead of 1.5.
#--------------------------------------------------------------------------------------
sub fmod {
    my $a = shift;
    my $b = shift;

    my $fa = $a - int $a;
    my $mod = ($a % $b) + $fa;
    return $mod;
}


#--------------------------------------------------------------------------------------
# Function: interpreter
# Synopsys: A Perlish interpreter.  Executes commands in main:: context.
#--------------------------------------------------------------------------------------
sub interpreter {
    package main; # !!! execute using main context, not Utils -- valid until end-of-block
    my $prompt = shift;
    my $script = shift;
    if (!defined $prompt) {
	print "ERROR: specify prompt\n";
	return;
    }
    my $time = `date`;
    print "Current time: $time\n";
    if (defined $script) {
	$script = `cat $script`;
	print $script;
	no strict;  # turn off strict checking
	eval $script; warn if $@;
	use strict;
    } else {
	no strict;  # turn off strict checking
	print "$prompt SHELL > ";
	my @lines = ();
	while (<STDIN>) {
	    my $line = $_;
	    push @lines, $line;
#	    print "$line";
	    if ((@lines == 1) && $line =~ /^\s*exit;?\s*$/) {
		last;  # graceful exit
	    }
	    if ($line =~ /.*;\s*$/ || (@lines == 1 && $line =~ /^\s*$/)) { # if line ends w/ semicolon
		eval "@lines"; warn if $@;
		print "$prompt SHELL > ";
		@lines = ();
	    }
	}
	use strict;
    }
}

#######################################################################################
# Function: sprint_class_hierarchy
# Synopsys: Prints the class hierarchy of all modules given as arguments.
#           First argument is the filename, all other arguments are classes.
#######################################################################################
{
    my %nodes;
    my %edges;
    my $nesting = 0;

    my $id = 0;

    sub sprint_class_hierarchy {
	my $first = ($nesting == 0) ? 1 : 0;
	$nesting++;

	my $filename = shift if ($first);

	my $sprint = "";
	foreach my $child (@_) {
	    eval "use $child";
	    my @parents = eval"\@${child}::ISA";
	    $sprint .= ("  " x $nesting) . "$child ISA ". join(",", @parents)."\n";
	    foreach my $parent (@parents) {
		$nodes{$child} = $id++ if (!exists $nodes{$child});
		$nodes{$parent} = $id++ if (!exists $nodes{$parent});
		$edges{"$child ISA $parent"} = undef;
		$sprint .= $parent->sprint_class_hierarchy();
	    }
	}
	if ($first == 1) {
	    # export to graphviz
	    eval "use GraphViz";  # in case GraphViz is not present
	    if ($@) {    # in case GraphViz is not present
		printn "WARNING: GraphViz is not properly installed, cannot export Graph objects...";
		print $@;
		return;
	    }

	    my $gv_ref = GraphViz->new();
	    foreach my $node (keys %nodes) {
		my $id = $nodes{$node};
		$gv_ref->add_node("node$id", label => "$node");
	    }
	    foreach my $edge (keys %edges) {
		$edge =~ /(\S+) ISA (\S+)/;
		my $child = $1;
		my $child_id = $nodes{$child};
		my $parent = $2;
		my $parent_id = $nodes{$parent};
		$gv_ref->add_edge("node$child_id" => "node$parent_id");
	    }
	    $gv_ref->as_png("$filename");
	}

	$nesting--;
	return $sprint;
    }
}

1;  # BEGIN must return true

