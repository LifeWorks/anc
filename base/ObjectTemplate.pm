######################################################################################
# File:     ObjectTemplate.pm
# Author:   Julien F. Ollivier
#
# Copyright (C) 2005-2010 Julien Ollivier.
#
# This program comes with ABSOLUTELY NO WARRANTY.
# This is free software, and you are welcome to redistribute it
# under certain conditions. See file LICENSE.TXT for details.
#
# Synopsys: Template for the creation of new object classes.
######################################################################################
# Detailed Description:
# ---------------------
#
#
######################################################################################

use strict;
use diagnostics;		# equivalent to -w command-line switch
use warnings;

package ObjectTemplate;
use Class::Std::Storable;
use base qw(Registered Instantiable Set);
{
    use Carp;
    use Utils;

    use ObjectTemplateInstance;

    #######################################################################################
    # CLASS ATTRIBUTES
    #######################################################################################
    ObjectTemplate->set_class_data("INSTANCE_CLASS", "ObjectTemplateInstance");

    #######################################################################################
    # ATTRIBUTES
    #######################################################################################
    my %A_of :ATTR(get => 'A', set => 'A', init_arg => 'A');  # constructor must supply initialization
    my %B_of :ATTR(get => 'B', set => 'B', default => 'yyy'); # default value is yyy

    #######################################################################################
    # FUNCTIONS
    #######################################################################################

    #######################################################################################
    # CLASS METHODS
    #######################################################################################
    #--------------------------------------------------------------------------------------
    # Function: XXX
    # Synopsys: 
    #--------------------------------------------------------------------------------------
    sub XXX {
	my $class = shift;
    }

    #######################################################################################
    # INSTANCE METHODS
    #######################################################################################
    #--------------------------------------------------------------------------------------
    # Function: START
    # Synopsys: 
    #--------------------------------------------------------------------------------------
#    sub BUILD {
    sub START {
        my ($self, $obj_ID, $arg_ref) = @_;

	# check initializers
	# ...
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
    use Null;

    use Globals;
    $verbosity = 2;

    printn "run_testcases: ObjectTemplate package";

    my $null1_ref = Null->new({name => "N1"});
    my $null2_ref = Null->new({name => "N2"});

    my $obj_ref = ObjectTemplate->new({
	name => "X1", 
	A => "AAA",
	element_class => "Null",
	elements_ref => [$null1_ref, $null2_ref, $null1_ref],
    });   # class instance (i.e. object ref)

    my $Instance0_ref = $obj_ref->new_object_instance({
	prefix => "*",
	element_class => "Instance",
    });  # object instance
    my $Instance1_ref = $obj_ref->new_object_instance({
	prefix => "*",
	element_class => "Instance",
    });  # object instance

    print $Instance0_ref->get_obj_inst_data() ."\n";
    print $Instance1_ref->get_obj_inst_data() ."\n";
    $Instance1_ref->set_obj_inst_data("value_yyy");
    print $Instance0_ref->get_obj_inst_data() ."\n";
    print $Instance1_ref->get_obj_inst_data() ."\n";

    print $obj_ref->get_object_instance_names() ."\n";

    print ObjectTemplate->dump_instances()."\n";
}


# Package BEGIN must return true value
return 1;

