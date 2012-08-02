######################################################################################
# File:     SetInstance.pm
# Author:   Julien F. Ollivier
#
# Copyright (C) 2005-2010 Julien Ollivier.
#
# This program comes with ABSOLUTELY NO WARRANTY.
# This is free software, and you are welcome to redistribute it
# under certain conditions. See file LICENSE.TXT for details.
#
# Synopsys: Inheritable class for instance classes whose parents are sets.
######################################################################################
# Detailed Description:
# ---------------------
# If the parent class is a set, then when instantiated, all elements of the parent's
# set must be instantiated as well.  This is done by the present class when inherited
# by the appropriate instance class.
#
######################################################################################

use strict;
use diagnostics;		# equivalent to -w command-line switch
use warnings;

package SetInstance;
use Class::Std::Storable;
use base qw(Set Instance);
{
    use Carp;

    use Utils;

    #######################################################################################
    # ATTRIBUTES
    #######################################################################################

    #######################################################################################
    # FUNCTIONS
    #######################################################################################

    #######################################################################################
    # CLASS METHODS
    #######################################################################################

    #######################################################################################
    # INSTANCE METHODS
    #######################################################################################
#    sub START {
#        my ($self, $obj_ID, $arg_ref) = @_;
#
#    }

    #--------------------------------------------------------------------------------------
    # Function: instantiate_components
    # Synopsys: Instantiate set elements.
    #--------------------------------------------------------------------------------------
    sub instantiate_components : CUMULATIVE(BASE FIRST) {
	my ($self, $arg_ref) = @_;

	confess "ERROR: arg_ref not defined" if (!defined $arg_ref);

	# clear anything that existed before
	$self->set_elements_ref([]);

	my $address_ref = defined $arg_ref->{address_ref} ? $arg_ref->{address_ref} : [];

	# create unregistered element instances
	my @elements = $self->get_parent_ref()->get_elements();
	for (my $i=0; $i < @elements; $i++) {
	    my $element_ref = $elements[$i];
	    # can't register instances before they have been added to set,
	    # since instance name is prefixed with name of containing instance
	    my $element_instance_ref = $element_ref->new_object_instance({
		UNREGISTERED => 1, # don't register elements
		%$arg_ref,
		address_ref => [@$address_ref, $i],
	    });
	    $self->add_element($element_instance_ref);
	}
    }

    #--------------------------------------------------------------------------------------
    # Function: register_components
    # Synopsys: Register set elements.
    #--------------------------------------------------------------------------------------
    sub register_components : CUMULATIVE(BASE FIRST) {
	my $self = $_[0];
	foreach my $element_ref ($self->get_elements()) {
	    $element_ref->get_parent_ref()->register_instance($element_ref);
	    # recursively register sub-elements
	    if ($element_ref->isa('Instance')) {
		$element_ref->register_components();
	    }
	}
    }

    #--------------------------------------------------------------------------------------
    # Function: set_element_instance_attrib
    # Synopsys: Sets a subset (or all) element instance attributes to specified value(s).
    # Details:  Arguments are the attribute followed by a list of address/value pairs.
    #           Address is a comma-separated string of (sub)indexes.  A wildcard
    #           character "*" instead of an integer is accepted for an index, in which
    #           case all corresponding elements are set.  Multiple addresses to be set
    #           to the same value may be grouped into anonymous lists followed by the
    #           desired value.
    # Example:
    #          set_state("*", 0, [1,3,2], 1)           # sets all bits to 0, then bits 1, 3, and 2 to 1)
    #          set_state("*,*", 0, ["1,*", "0,1"], 1)  # sets all bits to 0, then (1,*) and (0,1) to 1
    #--------------------------------------------------------------------------------------
    sub set_element_instance_attrib {
	my $self = shift;
	my $attrib_name = shift;

	while (@_) {
	    my $address_ref = shift;
	    my $value = shift;

	    if (ref $address_ref) {
		# address is a reference, so expect a list of addresses and unroll by recursion
		foreach my $address (@$address_ref) {
		    $self->set_element_instance_attrib($attrib_name, $address, $value);
		}
	    } else {
		# get the nested elements and call the required routine
		my @instances = $self->get_nested_elements([split ",", $address_ref]);
		my $method = "set_${attrib_name}";
		foreach my $instance_ref (@instances) {
		    $instance_ref->$method($value);
		}
	    }
	}
    }

    #--------------------------------------------------------------------------------------
    # Function: xxx
    # Synopsys: 
    #--------------------------------------------------------------------------------------
    sub xxx {
	my $self = shift;
    }
}


sub run_testcases {
    printn "run_testcases: SetInstance package";
    printn "NO TESTCASES YET!!!!";
}


# Package BEGIN must return true value
return 1;

