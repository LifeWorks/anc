######################################################################################
# File:     Named.pm
# Author:   Julien F. Ollivier
#
# Copyright (C) 2005-2010 Julien Ollivier.
#
# This program comes with ABSOLUTELY NO WARRANTY.
# This is free software, and you are welcome to redistribute it
# under certain conditions. See file LICENSE.TXT for details.
#
# Synopsys: Simple class to give a name attribute to object.
######################################################################################
# Detailed Description:
# ---------------------
######################################################################################
#
######################################################################################

use strict;
use diagnostics;		# equivalent to -w command-line switch
use warnings;

package Named;

# since most applications use Named, this will init Sortkeys
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;

use Class::Std::Storable;
{
    use Utils;
    use Carp;

    my %name_of :ATTR(get => 'name', set => 'name');

    sub BUILD {
        my ($self, $obj_ID, $arg_ref) = @_;

	if (defined $arg_ref->{name}) {
	    $name_of{$obj_ID} = $arg_ref->{name};
	} else {
	    if ($self->isa('Registered')) {
		my $autoname = $self->get_class_data("AUTONAME");
		if (defined $autoname) {
		    $name_of{$obj_ID} = uniquify($autoname);
		}
	    }
	}
	confess "ERROR: need to initialize name attribute of object $self" if (!exists $name_of{$obj_ID});
    }

    # Convert object to a string (automatically in string contexts)...
    # (n.b. this function gets called when printing out the object reference)
    sub as_str : STRINGIFY {
	my $self = shift;

	my $class = ref $self;

        return "$class=SCALAR(".$self->get_name().")";
    }

    # Convert object to a number (automatically in numeric contexts)...
    # (n.b. this function gets called when object references are numerically compared)
    sub as_num : NUMERIFY {
	my $self = shift;
	return ident $self;
    }

}

# TESTING
sub run_testcases {
    use Globals;
    $verbosity = 2;

    printn "run_testcases: Named package";
    my $instance = Named->new({name => "PHI"});
    printn "New object name -> ".$instance->get_name();
    $instance->set_name("XI");
    printn "Changed object name -> ".$instance->get_name();
    exit(0);
}

#run_testcases();

# Package BEGIN must return true value
return 1;

