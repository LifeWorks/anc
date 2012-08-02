######################################################################################
# File:     ClassData.pm
# Author:   Julien F. Ollivier
#
# Copyright (C) 2005-2010 Julien Ollivier.
#
# This program comes with ABSOLUTELY NO WARRANTY.
# This is free software, and you are welcome to redistribute it
# under certain conditions. See file LICENSE.TXT for details.
#
# Synopsys: This class implements a facility for storing/retrieving class data.
######################################################################################
# Detailed Description:
# ---------------------
#
######################################################################################

use strict;
use diagnostics;		# equivalent to -w command-line switch
use warnings;

package ClassData;
use Class::Std::Storable;
use base qw();
{
    use Carp;
    use Utils;

    #######################################################################################
    # CLASS ATTRIBUTES
    #######################################################################################
    # class data indexed by class name, includes instances registry and count
    my %class_data;

    #######################################################################################
    # ATTRIBUTES
    #######################################################################################

    #######################################################################################
    # FUNCTIONS
    #######################################################################################

    #######################################################################################
    # CLASS METHODS
    #######################################################################################
    sub get_class_data_ref {
	my $self = shift;
	my $class = ref $self ? ref $self : $self;  # class or instance method

	if (exists $class_data{$class}) {
	    return $class_data{$class};
	} else {
	    return $class_data{$class} = {};
	}
    }

    sub get_class_data {
	my $self = shift;
	my $class = ref $self ? ref $self : $self;  # class or instance method
	my $key = shift;

	if (exists $class_data{$class}{$key}) {
	    return $class_data{$class}{$key};
	} else {
	    return undef;
	}
    }

    sub set_class_data {
	my $self = shift;
	my $class = ref $self ? ref $self : $self; # class or instance method
	my $key = shift;
	my $value = shift;

	$class_data{$class}{$key} = $value;
    }

    #######################################################################################
    # INSTANCE METHODS
    #######################################################################################

}


sub run_testcases {
    use Utils;

    ClassData->set_class_data("data1", 2.0);
    printn (ClassData->get_class_data("data1"));
    my $x_ref = ClassData->new({});
    $x_ref->set_class_data("data1", 3.0);
    printn (ClassData->get_class_data("data1"));
}


# Package BEGIN must return true value
return 1;

