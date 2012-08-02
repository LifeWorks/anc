######################################################################################
# File:     Component.pm
# Author:   Julien F. Ollivier
#
# Copyright (C) 2005-2010 Julien Ollivier.
#
# This program comes with ABSOLUTELY NO WARRANTY.
# This is free software, and you are welcome to redistribute it
# under certain conditions. See file LICENSE.TXT for details.
#
# Synopsys:
######################################################################################
# Detailed Description:
# ---------------------
######################################################################################

use strict;
use diagnostics;		# equivalent to -w command-line switch
use warnings;

package Component;
use Class::Std::Storable;
use base qw();
{
    use Carp;
    use WeakRef;

    use Utils;

    #######################################################################################
    # CLASS ATTRIBUTES
    #######################################################################################

    #######################################################################################
    # ATTRIBUTES
    #######################################################################################
    # which component(s) is object member of
    my %in_object_list_ref_of        :ATTR(get => 'in_object_list_ref');

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

	$in_object_list_ref_of{$obj_ID} = [];

	# check initializers
	# ...
    }

    #--------------------------------------------------------------------------------------
    # Function: added_to_object
    # Synopsys: Register containing object.
    #--------------------------------------------------------------------------------------
    sub added_to_object {
	my $self = shift; my $obj_ID = ident $self;
	my $object_ref = shift;

	croak "ERROR: containing object reference not defined\n" if (!defined $object_ref);
	push @{$in_object_list_ref_of{$obj_ID}}, $object_ref;

	# weaken the ref to containing object so that it will get garbage-collected
	# even if elements still exist
	weaken($in_object_list_ref_of{$obj_ID}->[$#{$in_object_list_ref_of{$obj_ID}}]);
    }

    #--------------------------------------------------------------------------------------
    # Function: get_in_object
    # Synopsys: Get unique object which self is a component of.
    #           If self is a component of more than one object, an error is returned.
    #--------------------------------------------------------------------------------------
    sub get_in_object {
	my $self = shift;

	my $in_object_list_ref = $in_object_list_ref_of{ident $self};
	if (@$in_object_list_ref > 1) {
	    croak "ERROR: component is not in a unique object";
	    exit(1);
	} elsif (@$in_object_list_ref == 1) {
	    return $in_object_list_ref->[0];
	} else {
	    return undef;
	}
    }

    #--------------------------------------------------------------------------------------
    # Function: get_in_toplvl_object_list
    # Synopsys: Get list of top-lvl objects which self is a component of.
    #--------------------------------------------------------------------------------------
    sub get_in_toplvl_object_list {
	my $self = shift;  my $obj_ID = ident $self;

	my $in_object_list_ref = $in_object_list_ref_of{ident $self};
	my @in_toplvl_object_list = ();

	foreach my $object_ref (@$in_object_list_ref) {
	    if ($object_ref->isa("Component")) {
		my @temp_list = $object_ref->get_in_toplvl_object_list();
		if (@temp_list != 0) {
		    push @in_toplvl_object_list, @temp_list;
		} else {
		    push @in_toplvl_object_list, $object_ref;
		}
	    } else {
		push @in_toplvl_object_list, $object_ref;
	    }
	}
	return @in_toplvl_object_list;
    }

    #--------------------------------------------------------------------------------------
    # Function: get_in_toplvl_object
    # Synopsys: Get unique top-lvl object which self is a component of.
    #           Returns self if not contained in any other object.
    #--------------------------------------------------------------------------------------
    sub get_in_toplvl_object {
	my $self = shift;

	my @in_toplvl_object_list = $self->get_in_toplvl_object_list();
	if (@in_toplvl_object_list > 1) {
	    croak "ERROR: element is not in a unique top-lvl set";
	    exit(1);
	} elsif (@in_toplvl_object_list == 1) {
	    return $in_toplvl_object_list[0];
	} else {
	    return $self;
	}
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
 	# delete the weakref to parent object list
 	$ref->{Component}{in_object_list_ref} = undef;
    };
#    sub STORABLE_thaw_pre: CUMULATIVE {
#  	my ($self, $clone_flag, $ref) = @_;
#    };
#    sub STORABLE_thaw_post: CUMULATIVE {
#  	my ($self, $clone_flag) = @_;
#    };
}


sub run_testcases {
    printn "NO TESTCASES!!!";
}


# Package BEGIN must return true value
return 1;

