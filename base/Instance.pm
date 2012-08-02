######################################################################################
# File:     Instance.pm
# Author:   Julien F. Ollivier
#
# Copyright (C) 2005-2010 Julien Ollivier.
#
# This program comes with ABSOLUTELY NO WARRANTY.
# This is free software, and you are welcome to redistribute it
# under certain conditions. See file LICENSE.TXT for details.
#
# Synopsys: This is an inheritable base class for object instances (as opposed to
#           instances of classes, which are objects).
######################################################################################
# Detailed Description:
# ---------------------
# Instances of objects have a reference to parent object, hence identical attribute
# values across all object instances, plus per-instance data which may be different for
# each object instance.  Methods associated with the parent object may be called on
# an instance object.  Also, the reference to parent object is WEAK, to prevent
# reference loops and allow the parent to be garbage collected when deleted.
#
######################################################################################

use strict;
use diagnostics;		# equivalent to -w command-line switch
use warnings;

package Instance;
use Class::Std::Storable;
use base qw(Named);
{
    use Carp;
    use WeakRef;

    use Utils;
    use Globals;

    #######################################################################################
    # Attributes
    #######################################################################################
    my %parent_ref_of        :ATTR(get => 'parent_ref', init_arg => 'parent_ref');
    my %parent_name_of       :ATTR(get => 'parent_name');
    my %parent_class_of      :ATTR(get => 'parent_class');

    #######################################################################################
    # Functions
    #######################################################################################

    #######################################################################################
    # Methods
    #######################################################################################

    # CLASS METHODS

    # INSTANCE METHODS
    #--------------------------------------------------------------------------------------
    # Function: START
    # Synopsys: 
    #--------------------------------------------------------------------------------------
    sub START {
        my ($self, $obj_ID, $arg_ref) = @_;
	
	# weaken the parent ref to so that parent will get garbage-collected
	# even if child instances still exist
	confess "ERROR: parent reference not defined\n" if (!defined $parent_ref_of{$obj_ID});
	weaken($parent_ref_of{$obj_ID});

	# cache the parent's name
	if ($parent_ref_of{$obj_ID}->isa("Named")) {
	    $parent_name_of{$obj_ID} = $parent_ref_of{$obj_ID}->get_name();
	} else {
	    $parent_name_of{$obj_ID} = "NONAME";
	}

	# cache the parent's class
	$parent_class_of{$obj_ID} = ref $parent_ref_of{$obj_ID};

	# check initializers
	# ...
    }

    # just to know when it's called
    sub DEMOLISH {
        my ($self, $obj_ID) = @_;

	my $self_name = $self->get_name();
	my $parent_name = $self->get_parent_name();
	printn "called DEMOLISH on instance ".($self->get_name())." of object ".
	($self->get_parent_name())." of class ".($self->get_parent_class()) if ($verbosity >= 3);
    }

    #--------------------------------------------------------------------------------------
    # Function: set_parent_ref
    # Synopsys: 
    #--------------------------------------------------------------------------------------
    sub set_parent_ref {
	my $self = shift;
	my $obj_ID = ident $self;
	my $parent_ref = shift;

	$parent_ref_of{$obj_ID} = $parent_ref;
	weaken($parent_ref_of{$obj_ID});
    }


    #--------------------------------------------------------------------------------------
    # Function: AUTOMETHOD
    # Synopsys: Create and alias handler routine to avoid future AUTOMETHOD calls.
    # The handler simply kicks unknown (instance or class) method calls upstairs
    # to containing object.
    #--------------------------------------------------------------------------------------
    sub AUTOMETHOD {
        my ($self, $obj_ID, @args) = @_;
	my $sub_name = $_;   # Requested subroutine name is passed via $_

	printn "AUTOMETHOD $sub_name called on $self" if ($verbosity >= 3);

	my ($instance_class, $parent_class);
	if (ref $self) {  # was it an instance method call ?
	    $instance_class = ref $self;
	    $parent_class = ref $self->get_parent_ref();
	} else {              # no, it was a class method call
	    $instance_class = $self;
	    # assume that if parent class is XXX then instance class is XXXInstance
	    $parent_class = $instance_class;
	    $parent_class =~ s/Instance$//;  # strip off suffix
	    croak "ERROR: can't find appropriate class method $sub_name on $instance_class instance class" if (!$parent_class);
	}

	# create, alias (to avoid future AUTOMETHOD calls) and return a subroutine which
	# i) determines whether class or instance method is called
	# i) calls parent instance or class method with same arguments
	my $auto_sub = sub {
	    my $self = shift;
	    if (ref $self) {
		$self->get_parent_ref()->$sub_name(@_);
	    } else {
		$parent_class->$sub_name(@_);
	    }
	};
	my $auto_name = "$instance_class"."::".$sub_name;
	no strict 'refs'; *{$auto_name} = \&{$auto_sub}; use strict;
	return $auto_sub;
    }

    #--------------------------------------------------------------------------------------
    # Function: STORABLE_freeze_pre, STORABLE_freeze_post, etc.
    # Synopsys: Hooks provided by Class::Std::Storable.
    #           All 4 of these functions are necessary because otherwise AUTOMETHOD defined
    #           above interferes with freeze/thaw.
    #--------------------------------------------------------------------------------------
    sub STORABLE_freeze_pre: CUMULATIVE {
 	my ($self, $clone_flag) = @_;
    };
    sub STORABLE_freeze_post: CUMULATIVE {
 	my ($self, $clone_flag, $ref) = @_;
	# delete the weakref to parent object
	$ref->{Instance}{parent_ref} = undef;
    };
    sub STORABLE_thaw_pre: CUMULATIVE {
 	my ($self, $clone_flag, $ref) = @_;
    };
    sub STORABLE_thaw_post: CUMULATIVE {
 	my ($self, $clone_flag) = @_;
    };

    #--------------------------------------------------------------------------------------
    # Function: instantiate_components
    # Synopsys: Dummy.
    #--------------------------------------------------------------------------------------
    sub instantiate_components : CUMULATIVE(BASE FIRST) {
#	my ($self, $arg_ref) = @_;
    }
    #--------------------------------------------------------------------------------------
    # Function: register_components
    # Synopsys: Dummy.
    #--------------------------------------------------------------------------------------
    sub register_components : CUMULATIVE(BASE FIRST) {
#	my $self = $_[0];
    }

#    #--------------------------------------------------------------------------------------
#    # Function: xxx
#    # Synopsys: 
#    #--------------------------------------------------------------------------------------
#    sub xxx {
#	my $self = shift;
#    }
}


sub run_testcases {
    $verbosity = 3;

    printn "run_testcases: Instance package";
    # create a DUMMY class and object
    package DUMMY;
    use Class::Std;
    use base qw(Instantiable Registered);
    DUMMY->set_class_data("INSTANCE_CLASS", "DUMMYInstance"); # default
    sub dummy {return "DUMMY @_"};
    sub to_string : STRINGIFY {my $self = shift; return $self->get_name()};

    package DUMMYInstance;
    use base qw(Instance);

    package Instance;

    my $dummy_ref = DUMMY->new({name => "P_DUMMY"});

    # now create an Instance
    my $dummy_instance_ref = $dummy_ref->new_object_instance();
	
    # and check the AUTOMETHOD (instance method call)
    printn "call to dummy instance method returned: ".$dummy_instance_ref->dummy("a", "b", "c");
    printn "call to dummy instance method returned: ".$dummy_instance_ref->dummy("d", "e", "f");

    # and check the AUTOMETHOD (class method call)
    printn "call to dummy class method returned: ".DUMMYInstance->dummy("A", "B", "C");
    printn "call to dummy class method returned: ".DUMMYInstance->dummy("D", "E", "F");


    package DAMMY;
    use Class::Std;
    use base qw(Instantiable Registered);
    DAMMY->set_class_data("INSTANCE_CLASS", "DAMMYInstance"); # default
    sub dammy {return "DAMMY @_"};
    sub to_string : STRINGIFY {my $self = shift; return $self->get_name()};

    package DAMMYInstance;
    use base qw(Instance);

    package Instance;

    my $dammy_ref = DAMMY->new({name => "P_DAMMY"});

    # now create an Instance
    my $dammy_instance_ref = $dammy_ref->new_object_instance();
	
    # and check the AUTOMETHOD (class method call)
    printn "call to dammy class method returned: ".DAMMYInstance->dammy("AA", "BB", "CC");
    printn "call to dammy class method returned: ".DAMMYInstance->dammy("DD", "EE", "FF");

    # and check the AUTOMETHOD (instance method call)
    printn "call to dammy instance method returned: ".$dammy_instance_ref->dammy("aa", "bb", "cc");
    printn "call to dammy instance method returned: ".$dammy_instance_ref->dammy("dd", "ee", "ff");
}


# Package BEGIN must return true value
return 1;

