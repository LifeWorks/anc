######################################################################################
# File:     Registered.pm
# Author:   Julien F. Ollivier
#
# Copyright (C) 2005-2010 Julien Ollivier.
#
# This program comes with ABSOLUTELY NO WARRANTY.
# This is free software, and you are welcome to redistribute it
# under certain conditions. See file LICENSE.TXT for details.
#
# Synopsys: This inheritable class implements a class registry and provides routines
#           for managing class data as a bonus.  Inherits in turn from Named class.
######################################################################################
# Detailed Description:
# ---------------------
# !!! Much in common with Instantiable class --> possible to factor out some code ???
# !!! Separate out class data function, so that it can be used independently ???
#
######################################################################################

use strict;
use diagnostics;		# equivalent to -w command-line switch
use warnings;

package Registered;
use Class::Std::Storable;
# Registered objects must be Named, enabling by-name lookup etc.
use base qw(ClassData Named);
{

    use Carp;
    use Utils;

    use Globals;

    #######################################################################################
    # CLASS ATTRIBUTES
    #######################################################################################
    # registry keyed by class name, includes instances registry
#    my %registry;

    #######################################################################################
    # ATTRIBUTES
    #######################################################################################
    my %is_registered_flag_of :ATTR(get => 'is_registered_flag', set => 'is_registered_flag', default => 0);

    #######################################################################################
    # FUNCTIONS
    #######################################################################################

    ###########################################
    # CLASS METHODS
    ###########################################
    sub get_instances {
	my $class = shift;

	my $class_data_ref = $class->get_class_data_ref();

	if (exists $class_data_ref->{instances}) {
	    return @{$class_data_ref->{instances}};
	} else {
	    return ();
	}
    }

    sub report_registry {
	my $class = shift;

	my $class_data_ref = $class->get_class_data_ref();
	my $instances_ref = $class_data_ref->{instances};
	my $index_of = $class_data_ref->{index_of};

	printn "========= REGISTRY REPORT ($class) ===========";
	return if (!defined $instances_ref);
	$class->check_registry();

	for (my $i=0; $i < @$instances_ref; $i++) {
	    my $obj_ref = $instances_ref->[$i];
	    my $name = (defined $obj_ref) ? $obj_ref->get_name() : "UNDEFINED";
	    printn "$i\t$name ".(ref $obj_ref);
	}

	printn "=====================================";
    }

    sub check_registry {
	my $class = shift;

	my $class_data_ref = $class->get_class_data_ref();
	my $instances_ref = $class_data_ref->{instances};
	my $index_of = $class_data_ref->{index_of};

	printn "WARNING: don't have same # of elements in instances and index list" if (@$instances_ref != (keys %$index_of));


	for (my $i=0; $i < @$instances_ref; $i++) {
	    my $obj_ref = $instances_ref->[$i];
	    printn "WARNING: undefined element in registry index $i" if (!defined $obj_ref);
	}

	my @names = sort keys %$index_of;

	for (my $i=0; $i < @names; $i++) {
	    my $name = $names[$i];
	    my $index = $index_of->{$name};

	    printn "WARNING: undefined index in lookup table for element $name" if (!defined $index);
	    my $obj_ref = $instances_ref->[$index];
	    printn "WARNING: undefined element in registry index $i given by $name lookup" if (!defined $obj_ref);
	    my $obj_name = defined $obj_ref ? $obj_ref->get_name() : undef;
	    printn "WARNING: looked up $name but got $obj_name" if (defined $obj_name && ($obj_name ne $name));
	}
    }

    sub dump_instances {
	my $class = shift;

	my $class_data_ref = $class->get_class_data_ref();
	my $instances_ref = $class_data_ref->{instances};

	my $dump;
	$dump .= "============BEGIN DUMP of class $class\n";
	$dump .= $_->_DUMP() foreach (@{$instances_ref});
	$dump .= "============END DUMP\n";
	return $dump;
    }

    sub get_names {
	my $class = shift;

	my $class_data_ref = $class->get_class_data_ref();
	my $instances_ref = $class_data_ref->{instances};

	return map($_->get_name(), @{$instances_ref});
    }

    sub get_count {
	my $class = shift;

	my $class_data_ref = $class->get_class_data_ref();
	my $instances_ref = $class_data_ref->{instances};

	return scalar @{$instances_ref};
    }

    sub lookup_by_name {
	my $class = shift;
	my $name = shift;

	my $class_data_ref = $class->get_class_data_ref();
	my $instances_ref = $class_data_ref->{instances};
	my $index_of = $class_data_ref->{index_of};

	my $index = $index_of->{$name};
	return (defined $index) ? $instances_ref->[$index] : undef;
    }

    sub grep_by_name {
	my $class = shift;
	my $pattern = shift;

	return grep ($_->get_name() =~ /$pattern/, $class->get_instances());
    }

    sub clear_instances {
	my $class = shift;

	my $class_data_ref = $class->get_class_data_ref();
	my $instances_ref = $class_data_ref->{instances};
	my $index_of = $class_data_ref->{index_of};

	@{$instances_ref} = ();
	%{$index_of} = ();
    }

    ###########################################
    # INSTANCE METHODS
    ###########################################
    # sub-classes will call these methods cumulatively
    sub BUILD {
        my ($self, $obj_ID, $arg_ref) = @_;
	my $class =  ref $self;  # ref returns name of class

	my $class_data_ref = $class->get_class_data_ref();

	# if this is first object in class ever to be created, then init class data
	if (!defined $class_data_ref->{instances}) {
	    $class->set_class_data("instances", []);
	}
	if (!defined $class_data_ref->{index_of}) {
	    $class->set_class_data("index_of", {});
	}
    }

    sub START {
        my ($self, $obj_ID, $arg_ref) = @_;
	my $class =  ref $self;  # ref returns name of class

	# calling with form 'XXX->new({UNREGISTERED => 1});' will create object
	# without registering it
	if ((!exists $arg_ref->{UNREGISTERED}) || (!$arg_ref->{UNREGISTERED})) {
	    $self->register(UNIQUIFY => $arg_ref->{UNIQUIFY});
	}
    }

    # just to know when it's called
    sub DEMOLISH {
        my ($self, $obj_ID) = @_;
	my $class = ref $self;

	printn "called DEMOLISH on Registered object ".($self->get_name())." of class $class" if ($verbosity >= 3);

	# n.b. the only way to get here is
	#  i) the object was deregistered and reference count is down to zero
	# ii) the program in terminating
	# Either way, we do not want to deregister
    }

    sub get_index {
	my $self = shift;

	my $class =  ref $self;  # ref returns name of class
	my $class_data_ref = $class->get_class_data_ref();
	my $index_of = $class_data_ref->{index_of};

	my $name = $self->get_name();
	my $index = $index_of->{$name};
	return $index;
    }

    sub register {
        my ($self, %args) = @_;

	my $name = $self->get_name();
	my $class = ref $self;  # ref returns name of class

	confess "ERROR: internal error -- already registered $name" if ($is_registered_flag_of{ident $self});

	if (exists $args{UNIQUIFY} && $args{UNIQUIFY}) {
	    $self->set_name(uniquify($name));
	    $name = $self->get_name();
	}

	printn "Registering object   ".sprintf("%-25s",$name)." of class $class" if ($verbosity >= 2);

	my $class_data_ref = $class->get_class_data_ref();
	my $instances_ref = $class_data_ref->{instances};
	my $index_of = $class_data_ref->{index_of};

	# check that no instance already exists with the same name
	if (defined $index_of->{$name}) {
	    confess "ERROR: can't register object $name of class $class because there already exists instance with the same name\n";
	}

	# push on class instance list
	push @{$instances_ref}, $self;

	# store index in name map for quick lookup
	$index_of->{$name} = int $#{$instances_ref};

	# set the registered flag
	$is_registered_flag_of{ident $self} = 1;
    }

    sub deregister :CUMULATIVE {
        my $self = shift;
	my $class = ref $self;
	my $name = $self->get_name();

	croak "ERROR: internal error -- deregistering object $name which is not registered" if (!$is_registered_flag_of{ident $self});

	printn "Deregistering object $name of class $class" if ($verbosity >= 1);
	
	my $class_data_ref = $class->get_class_data_ref();
	my $instances_ref = $class_data_ref->{instances};
	my $index_of = $class_data_ref->{index_of};

	# splice out of registry list
	my $index = $index_of->{$name};

	croak "ERROR: internal error (index wasn't defined) on $name ($self)\n" if (!defined $index_of->{$name});
	croak "ERROR: internal error (index didn't point to correct element) on $name ($self)\n" if (
	    $instances_ref->[$index]->get_name() ne $name
	);

	splice(@{$instances_ref}, $index, 1);
	# since we splice out an element, index cache of elements after splice must be updated
	for (my $i=$index; $i < @{$instances_ref}; $i++) {
	    $index_of->{$instances_ref->[$i]->get_name()} = $i;
	}

	# delete the key out of index lookup
	delete $index_of->{$name};

	# reset the registered flag
	$is_registered_flag_of{ident $self} = 0;
    }

    sub change_name {
        my ($self, $new_name) = @_;
	my $name = $self->get_name();
	my $class = ref $self;  # ref returns name of class

	printn "change_name: renaming $name to $new_name in class $class\n";

	my $class_data_ref = $class->get_class_data_ref();
	my $instances_ref = $class_data_ref->{instances};
	my $index_of = $class_data_ref->{index_of};

	# check that no instance already exists with the new name
	if (defined $index_of->{$new_name}) {
	    croak "ERROR: can't rename object $name of class $class to $new_name because there already exists instance with the same name\n";
	}

	# change the name
	$self->set_name($new_name);

	# store index in name map for quick lookup and delete old key
	$index_of->{$new_name} = $index_of->{$name};
	delete $index_of->{$name};
    }

    # hook provided by Class::Std::Storable
    sub STORABLE_thaw_post: CUMULATIVE {
 	my ($self, $clone_flag) = @_;
	$self->set_is_registered_flag(0);
    }

    sub unfreeze {
        my ($serialized) = @_;
	my $obj = Storable::thaw($serialized);
	$obj->register();
	return $obj;
    }

}

# TESTING
sub run_testcases {
    use Data::Dumper;

    $verbosity = 3;

    printn "run_testcases: Registered package";
    my $instance1 = Registered->new({name => "aaa"});
    print "aaa index ".$instance1->get_index()."\n";
    print "count: ".Registered->get_count()."\n";
    my $instance2 = Registered->new({name => "bbb"});
    print "bbb index ".$instance2->get_index()."\n";
    print "count: ".Registered->get_count()."\n";
    my $instance3 = Registered->new({name => "ccc"});
    print "ccc index ".$instance3->get_index()."\n";
    print "count: ".Registered->get_count()."\n";

    printn "index_of: ".Dumper(Registered->get_class_data("index_of"));

    foreach my $obj_ref (Registered->get_instances()) {
	print "ref: class=".(ref $obj_ref)." name=".$obj_ref->get_name()." index=".$obj_ref->get_index()."\n"; 
    }
    print "count: ".Registered->get_count()."\n";

    $instance2->deregister();
    undef $instance2;
    print "count: ".Registered->get_count()."\n";
    printn "index_of: ".Dumper(Registered->get_class_data("index_of"));


    foreach my $obj_ref (Registered->get_instances()) {
	print "ref: class=".(ref $obj_ref)." name=".$obj_ref->get_name()." index=".$obj_ref->get_index()."\n"; 
    }

    print Registered->dump_instances();

    $instance3->change_name("zzz");
    foreach my $obj_ref (Registered->get_instances()) {
	print "ref: class=".(ref $obj_ref)." name=".$obj_ref->get_name()." index=".$obj_ref->get_index()."\n"; 
    }
    print Registered->dump_instances();
    printn "index_of: ".Dumper(Registered->get_class_data("index_of"));

    my $noexist = Registered->lookup_by_name("noexist");
    if (defined $noexist) {print "ERROR!!!\n"};

    printn "STORABLE TEST";
    printn "freezing: ".$instance1->_DUMP();
    use Storable;
    my $ice_ref = Storable::freeze($instance1);
    my $water_ref = Storable::thaw($ice_ref);
    $water_ref->set_name("water");
    printn "unfrozen: ".$water_ref->_DUMP();
    $water_ref->register();
    print Registered->dump_instances();
    print "done testing Registered\n";

}

# Package BEGIN must return true value
return 1;

