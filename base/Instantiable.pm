######################################################################################
# File:     Instantiable.pm
# Author:   Julien F. Ollivier
#
# Copyright (C) 2005-2010 Julien Ollivier.
#
# This program comes with ABSOLUTELY NO WARRANTY.
# This is free software, and you are welcome to redistribute it
# under certain conditions. See file LICENSE.TXT for details.
#
# Synopsys: Allows creation of object instances (as opposed to class
#           instances, i.e. objects).
######################################################################################
# Detailed Description:
# ---------------------
# If the object instances are to contain object instance data, a separate class must
# be created for them, this class must inherit from the Instance class, and
# and the object instance class must be specified in the class data of the parent object.
# E.g.  if Car is instantiable, then create a CarInstance class inheriting from Instance,
# which can specify speed, colour, etc attributes.  Also specify in the Car class data
# that object instances are of class CarInstance.
#
# Any sub-class must implement the instance_init method, and any other necessary
# object instance methods that will be found via AUTOMETHOD.
#
# An Instantiable object must be Registered because we store the Instance class as
# class data.  It also must be Named because the Instance name is derived from
# from the parent's name.
#
# !!! N.B. This class is very similar to the Registered class and could probably be
# !!! merged with it ???
#
######################################################################################

use strict;
use diagnostics;		# equivalent to -w command-line switch
use warnings;

package Instantiable;
use Class::Std::Storable;
use base qw(ClassData Named);
{
    use Carp;

    use Utils;
    use Globals;

    use Instance;

    #######################################################################################
    # CLASS ATTRIBUTES
    #######################################################################################
    Instantiable->set_class_data("INSTANCE_CLASS", "Instance"); # default

    #######################################################################################
    # ATTRIBUTES
    #######################################################################################
    my %instances_of        :ATTR(get => 'instances');
    my %instances_index_of  :ATTR(get => 'instances_index');

    #######################################################################################
    # FUNCTIONS
    #######################################################################################

    #######################################################################################
    # CLASS METHODS
    #######################################################################################
    #--------------------------------------------------------------------------------------
    # Function: instantiate_all_objects
    # Synopsys: Get all objects of in class and instantiate them.
    #--------------------------------------------------------------------------------------
    sub instantiate_all_objects : {
	my $class = shift;

	my @objects_ref = $class->get_instances();
	my @object_instances_ref = ();
	foreach my $object_ref (@objects_ref) {
	    push @object_instances_ref, $object_ref->new_object_instance({});
	}
	return @object_instances_ref;
    }

    #######################################################################################
    # INSTANCE METHODS
    #######################################################################################
    #--------------------------------------------------------------------------------------
    # Function: START
    # Synopsys: 
    #--------------------------------------------------------------------------------------
    sub BUILD {
        my ($self, $obj_ID, $arg_ref) = @_;
	
	$instances_of{$obj_ID} = [];
	$instances_index_of{$obj_ID} = {};
    }

    sub new_object_instance {
	my ($self, $arg_ref) = @_;
	my $class = ref $self;

	my $instance_class = $class->get_class_data("INSTANCE_CLASS");

	confess "ERROR: you need to define INSTANCE_CLASS for Instantiable class $class" if (!defined $instance_class);

	# compute and set instance name
	my $parent_name = $self->get_name();
	my $prefix = (defined $arg_ref->{prefix}) ? $arg_ref->{prefix} : "";

	# if arg_ref specifies a name, prefix it with underscore to signal register_instance() that
	# it should keep it as is and NOT uniquify
	my $new_object_instance_name = defined $arg_ref->{name} ? "__$arg_ref->{name}" : "${prefix}${parent_name}#";
	delete $arg_ref->{name}; # else it will clobber name in new() call

	printn "Creating NEW ".sprintf("%-25s",$instance_class)." of object $parent_name, class $class"  if ($verbosity >= 2);
	my $new_object_instance_ref = $instance_class->new({
	    name => $new_object_instance_name,
	    parent_ref => $self,
	    UNREGISTERED => 1,  # want to create all sub-elements before registering
	    %$arg_ref,
	});

	croak "ERROR: instance class must inherit from Instance" if (!$new_object_instance_ref->isa("Instance"));

	# instantiate components
	my $instantiate_components_flag = (
	    (!exists $arg_ref->{DONT_INSTANTIATE_COMPONENTS}) ||
	    (!$arg_ref->{DONT_INSTANTIATE_COMPONENTS}));
	if ($instantiate_components_flag) {
	    $new_object_instance_ref->instantiate_components($arg_ref); # doesn't register elements
	}

	# register instance with object, and with class (if necessary)
	my $register_flag = (!exists $arg_ref->{UNREGISTERED}) || (!$arg_ref->{UNREGISTERED});
	if ($register_flag) {
	    # this computes uniquified name and registers instance with object, and object with class as required
	    $self->register_instance($new_object_instance_ref);
	    # register the elements if they were instantiated
	    $new_object_instance_ref->register_components() if ($instantiate_components_flag);
	}

	return $new_object_instance_ref;
    }

    sub register_instance {
	my ($self, $new_object_instance_ref) = @_;
	my $obj_ID = ident $self;

	# prefix the name with that of containing instance if appropriate
	my $prefix = "";
	if ($new_object_instance_ref->isa("Component")) {
	    my $in_object_ref = $new_object_instance_ref->get_in_object();
	    if ($in_object_ref) {
		$prefix = $in_object_ref->get_name()."/";
	    }
	}

	# since we are registering this object, need to uniquify the name
	my $new_object_instance_name = $new_object_instance_ref->get_name();
	if (substr($new_object_instance_name, 0, 2) eq "__") {  # was named by user
	    $new_object_instance_name =~ s/^..//;  # remove double underscore
	} else {  # auto name by uniquifying parent name
	    $new_object_instance_name = $prefix.$new_object_instance_ref->get_name();
	    $new_object_instance_name = uniquify($new_object_instance_name, "");
	}
	$new_object_instance_ref->set_name($new_object_instance_name);

	croak "ERROR: registering instance $new_object_instance_name under wrong parent object" if ($new_object_instance_ref->get_parent_ref() != $self);

	my $parent_name = $self->get_name();
	printn "Registering instance ".sprintf("%-25s",$new_object_instance_name)." of object $parent_name" if ($verbosity >= 2);

	# check that no instance already exists with the same name
	if (defined $self->lookup_object_instance_by_name($new_object_instance_name)) {
	    my $parent_class = ref $self;
	    confess "ERROR: can't create object instance $new_object_instance_name of object $parent_name of class $parent_class because there already exists instance with the same name\n";
	}
	
	# push on object instance list
	push @{$instances_of{$obj_ID}}, $new_object_instance_ref;

	# store index in name map for quick lookup
	my $instance_index = $#{$instances_of{$obj_ID}};
	$instances_index_of{$obj_ID}{$new_object_instance_name} = $instance_index;

	# if Instance is also Registered, then register the object with uniquified name
	if ($new_object_instance_ref->isa("Registered")) {
	    $new_object_instance_ref->register();
	}
    }

    # callable as class or instance method
    sub get_object_instances {
	if (ref $_[0]) {	# called as instance method
	    my $self = shift;
	    return @{$instances_of{ident $self}};
	} else {		# called as class method
	    my $class = shift;
	    # get all instances of class
	    my @instances = $class->get_instances;
	    # then get object instances of each class instance (i.e. object)
	    return map ($_->get_object_instances(), @instances);
	}
    }

    sub get_object_instance_count {
	if (ref $_[0]) {	# called as instance method
	    my $self = shift;
	    return scalar@{$instances_of{ident $self}};
	} else {		# called as class method
	    my $class = shift;
	    # get all instances of class
	    my @instances = $class->get_instances;
	    # then get object instances of each class instance (i.e. object)
	    return scalar(map ($_->get_object_instances(), @instances));
	}
    }

    sub get_object_instance_by_index {
	my $self = shift;
	my $index = shift;

	my $instances_ref = $instances_of{ident $self};
	confess "ERROR: index out of range" if $index >= @{$instances_ref};

	return $instances_ref->[$index];
    }

    sub get_object_instance_names {
	my $self = shift;
	return map($_->get_name(), @{$instances_of{ident $self}});
    }

    sub lookup_object_instance_by_name {
	my $self = shift;
	my $name = shift;

	my $instance_index = $instances_index_of{ident $self}{$name};
	return (defined $instance_index) ? $instances_of{ident $self}[$instance_index] : undef;
    }

    sub grep_instances_by_name {
	my $self = shift;
	my $pattern = shift;

	return grep ($_->get_name() =~ /$pattern/, $self->get_object_instances());
    }

    sub clear_object_instances {
	my $self = shift;
	@{$instances_of{ident $self}} = ();
	%{$instances_index_of{ident $self}} = ();
    }

     sub STORABLE_thaw_post: CUMULATIVE {
 	my ($self, $clone_flag) = @_;
	my $obj_ID = ident $self;

	for (my $i=0; $i < @{$instances_of{$obj_ID}}; $i++) {
	    my $instance_ref = $instances_of{$obj_ID}[$i];
	    $instance_ref->set_parent_ref($self);  # this also weakens
	}
     };

    #--------------------------------------------------------------------------------------
    # Function: xxx
    # Synopsys: 
    #--------------------------------------------------------------------------------------
    sub xxx {
	my $self = shift;
    }
}


sub run_testcases {
    printn "run_testcases: Instantiable package";

    use Globals;
    $verbosity = 2;

    my $obj1_ref = Instantiable->new({
	name => "OBJ1",
    });
    my $obj2_ref = Instantiable->new({
	name => "OBJ2",
    });

    my $O1I0 = $obj1_ref->new_object_instance({});
    my $O1I1 = $obj1_ref->new_object_instance({});
    my $O1I2 = $obj1_ref->new_object_instance({});
    my $O1I3 = $obj1_ref->new_object_instance({});

    my $O2I0 = $obj2_ref->new_object_instance({name => "some_name"});
    my $O2I1 = $obj2_ref->new_object_instance({});

    printn "STORABLE TEST";
    use Storable;
    my $ice_ref = Storable::freeze($obj1_ref);
    my $water_ref = Storable::thaw($ice_ref);
    printn $obj1_ref->_DUMP();
    printn $water_ref->_DUMP();
    map {printn $_->_DUMP()} ($water_ref->get_object_instances());

}


# Package BEGIN must return true value
return 1;

