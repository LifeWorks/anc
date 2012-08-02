######################################################################################
# File:     SetElement.pm
# Author:   Julien F. Ollivier
#
# Copyright (C) 2005-2010 Julien Ollivier.
#
# This program comes with ABSOLUTELY NO WARRANTY.
# This is free software, and you are welcome to redistribute it
# under certain conditions. See file LICENSE.TXT for details.
#
# Synopsys: Inherit this class if objects are members of a set (Set Class), and it is
#           desired to keep track of which set they are members of.  The containing
#           set will register itself as the containing set when adding object as an
#           element.
######################################################################################
# Detailed Description:
# ---------------------
# !!! TO-DO: once added to set, cannot be removed.  ???
#
######################################################################################

use strict;
use diagnostics;		# equivalent to -w command-line switch
use warnings;

package SetElement;
use Class::Std::Storable;
use base qw(Component);
{
    use Carp;
    use Utils;

    #######################################################################################
    # CLASS ATTRIBUTES
    #######################################################################################

    #######################################################################################
    # ATTRIBUTES
    #######################################################################################
    my %in_set_index_list_ref_of  :ATTR(get => 'in_set_index_list_ref');   # corresponding indices
    my %max_count_of              :ATTR(get => 'max_count', default => -1, init_arg => 'max_count');   # max no. of times element can occur in a Set

    #######################################################################################
    # FUNCTIONS
    #######################################################################################

    #######################################################################################
    # CLASS METHODS
    #######################################################################################

    #######################################################################################
    # INSTANCE METHODS
    #######################################################################################
    #--------------------------------------------------------------------------------------
    # Function: START
    # Synopsys: 
    #--------------------------------------------------------------------------------------
    sub BUILD {
        my ($self, $obj_ID, $arg_ref) = @_;

	$in_set_index_list_ref_of{$obj_ID} = [];

	# check initializers
	# ...
    }

    #--------------------------------------------------------------------------------------
    # Function: get_in_set_list
    # Synopsys: Get list of Set objects which self is a sub-element of.
    #--------------------------------------------------------------------------------------
    sub get_in_set_list {
	my $self = shift;

	return @{$self->Component::get_in_object_list_ref()};
    }

    #--------------------------------------------------------------------------------------
    # Function: added_to_set
    # Synopsys: Register containing Set.
    #--------------------------------------------------------------------------------------
    sub added_to_set {
	my $self = shift; my $obj_ID = ident $self;
	my $set_ref = shift;
	my $index = shift;

	$self->Component::added_to_object($set_ref);
	push @{$in_set_index_list_ref_of{$obj_ID}}, $index;
    }

    #--------------------------------------------------------------------------------------
    # Function: get_in_set
    # Synopsys: Get unique object which self is a sub-element of.
    #           If self is a sub-element of more than one Set, an error is returned.
    #--------------------------------------------------------------------------------------
    sub get_in_set {
	my $self = shift;

	return $self->get_in_object();
    }

    #--------------------------------------------------------------------------------------
    # Function: get_in_set_index
    # Synopsys: Get element index of self within unique object which self is an element of.
    #           If self is a element of more than one Set, an error is returned.
    #--------------------------------------------------------------------------------------
    sub get_in_set_index {
	my $self = shift;

	my @in_set_index_list = @{$in_set_index_list_ref_of{ident $self}};
	if (@in_set_index_list > 1) {
	    croak "ERROR: element is not in a unique set";
	    exit(1);
	} elsif (@in_set_index_list == 1) {
	    return $in_set_index_list[0];
	} else {
	    return undef;
	}
    }

    #--------------------------------------------------------------------------------------
    # Function: get_in_toplvl_set_list
    # Synopsys: Get list of top-lvl objects which self is a sub-element of.
    #--------------------------------------------------------------------------------------
    sub get_in_toplvl_set_list {
	my $self = shift;

	return $self->get_in_toplvl_object_list();
    }

    #--------------------------------------------------------------------------------------
    # Function: get_in_toplvl_set
    # Synopsys: Get unique top-lvl object which self is a sub-element of.
    #           Returns self if not in another Set.
    #--------------------------------------------------------------------------------------
    sub get_in_toplvl_set {
	my $self = shift;

	return $self->get_in_toplvl_object();
    }

    #--------------------------------------------------------------------------------------
    # Function: STORABLE_freeze_pre, STORABLE_freeze_post, etc.
    # Synopsys: Hooks provided by Class::Std::Storable.
    #--------------------------------------------------------------------------------------
#    sub STORABLE_freeze_pre: CUMULATIVE {
#  	my ($self, $clone_flag) = @_;
#    };
    sub STORABLE_freeze_post: CUMULATIVE {
  	my ($self, $clone_flag, $ref) = @_;
 	$ref->{SetElement}{in_set_index_list_ref} = undef;
    };
#    sub STORABLE_thaw_pre: CUMULATIVE {
#  	my ($self, $clone_flag, $ref) = @_;
#    };
#    sub STORABLE_thaw_post: CUMULATIVE {
#  	my ($self, $clone_flag) = @_;
#    };
}


sub run_testcases {
    use Set;

    # quick and dirty class for testing purposes
    package TestElement;
    use Class::Std::Storable;
    use base qw(Named Set SetElement);
    package SetElement;  # switch back to current class

    my $t010_ref = TestElement->new({
			name => "T0.1.0", 
			element_class => "TestElement"});
    my $t011_ref = TestElement->new({
			name => "T0.1.1", 
			element_class => "TestElement"});

    my $set = TestElement->new({
	name => "T0",
	elements_ref => [
	    TestElement->new({
		name => "T0.1", 
		elements_ref => [
		    $t010_ref,
		    $t011_ref,
		   ],
		element_class => "TestElement"}),
	    TestElement->new({
		name => "T0.2", 
		elements_ref => [
		   ],
		element_class => "TestElement"})
	   ],
	element_class => "TestElement",
       });

    my $t03_ref = TestElement->new({
	name => "T0.3", 
	element_class => "TestElement"});

    $set->add_element($t03_ref);

    printn $set->_DUMP();
    printn [$set->get_elements()]->[0]->_DUMP();
    printn [$set->get_elements()]->[1]->_DUMP();
    printn [$set->get_elements()]->[2]->_DUMP();
    printn [$t010_ref->get_in_set_list()]->[0]->get_name();  # returns T0.1
    printn $t010_ref->get_in_set->get_name();  # returns T0.1
    printn [$t010_ref->get_in_toplvl_set_list()]->[0]->get_name();  # returns T0
    printn $t010_ref->get_in_toplvl_set->get_name();  # returns T0


    printn "STORABLE TEST";
    use Storable;
    my $ice_ref = Storable::freeze($set);
    my $water_ref = Storable::thaw($ice_ref);
    printn "ice: ".$set->_DUMP();
    printn "water: ".$water_ref->_DUMP();
    map {printn $_->_DUMP()} ($water_ref->get_elements());
    map {printn $_->_DUMP()} ($water_ref->get_element(0)->get_elements());
}


# Package BEGIN must return true value
return 1;

