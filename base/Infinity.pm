######################################################################################
# File:     Infinity.pm
# Author:   Julien F. Ollivier
#
# Copyright (C) 2005-2010 Julien Ollivier.
#
# This program comes with ABSOLUTELY NO WARRANTY.
# This is free software, and you are welcome to redistribute it
# under certain conditions. See file LICENSE.TXT for details.
#
# Synopsys: Miscellaneous routines to deal with arithmetic involving infinities
######################################################################################
# Detailed Description:
# ---------------------
# Handles INF, NAN....
######################################################################################

#######################################################################################
# TO-DO LIST
#######################################################################################

#######################################################################################
# Package interface
#######################################################################################
package Infinity;

use strict;

use Carp;

use Exporter;
use vars qw(@ISA @EXPORT);
@ISA = qw(Exporter);
@EXPORT = qw(
	     i_mult
	     i_div
	    );

#######################################################################################
# Modules used
#######################################################################################
#use Data::Dumper;

#######################################################################################
# Function: i_mult
# Synopsys: Compute x * y.
#######################################################################################
sub i_mult {
    my $x = shift;
    my $y = shift;

    return "NAN" if (($x eq "NAN") || ($y eq "NAN"));  # return Not A Number (NAN) if either arg is NAN

    return (($y ne "INF") && ($y == 0)) ? "NAN" : "INF" if ($x eq "INF");  # Not A Number (NAN) if zero * infinity
    return (($x ne "INF") && ($x == 0)) ? "NAN" : "INF" if ($y eq "INF");  # Not A Number (NAN) if zero * infinity

    return ($x * $y);
}

#######################################################################################
# Function: i_div
# Synopsys: 
#######################################################################################
sub i_div {
    my $x = shift;
    my $y = shift;

    return "NAN" if (($x eq "NAN") || ($y eq "NAN"));     # return Not A Number (NAN) if either arg is NAN

    return ($x eq "INF") ? "NAN" : 0 if ($y eq "INF");  # return Not A Number (NAN) if INF/INF
    return "INF" if ($x eq "INF");                      # $y is finite here

    # both are finite
    return ($x == 0 && $y == 0) ? "NAN" : (($y == 0) ? "INF" : $x/$y);
}


1;  # BEGIN must return true

