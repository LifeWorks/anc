######################################################################################
# File:     Node.pm
# Author:   Julien F. Ollivier
#
# Copyright (C) 2005-2010 Julien Ollivier.
#
# This program comes with ABSOLUTELY NO WARRANTY.
# This is free software, and you are welcome to redistribute it
# under certain conditions. See file LICENSE.TXT for details.
#
# Synopsys: Base class for Structure nodes.
######################################################################################
# Detailed Description:
# ---------------------
######################################################################################

use strict;
use diagnostics;		# equivalent to -w command-line switch
use warnings;

package Node;
use Class::Std::Storable;
use base qw(Registered Instantiable SetElement);
{
    use Carp;
    use Utils;

    use NodeInstance;

    #######################################################################################
    # CLASS ATTRIBUTES
    #######################################################################################
    Node->set_class_data("INSTANCE_CLASS", "NodeInstance");

    #######################################################################################
    # ATTRIBUTES
    #######################################################################################
    # specifies whether this node is a group node
    my %group_node_flag_of :ATTR(get => 'group_node_flag', set => 'group_node_flag', init_arg => 'group_node_flag', default => 0);

    # type is U (unary) or B (binary), as set by derived classes
    my %reaction_type_of   :ATTR(get => 'reaction_type', set => 'reaction_type', default => 'X');
    my %static_flag_of	   :ATTR(get => 'static_flag', set => 'static_flag', init_arg => 'static_flag', default => 0);

    ###################################
    # ALLOWED ATTRIBUTE VALUES
    ###################################
    my @allowed_reaction_types = ('X', 'U', 'B');  # X=don't care, U=unary, B=binary

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
#    sub XXX {
#	my $class = shift;
#    }

    #######################################################################################
    # INSTANCE METHODS
    #######################################################################################
    #--------------------------------------------------------------------------------------
    # Function: START
    # Synopsys: 
    #--------------------------------------------------------------------------------------
    sub START {
        my ($self, $obj_ID, $arg_ref) = @_;

	# check initializers
	my $class = ref $self;
	my $reaction_type = $self->get_reaction_type();
	croak "Initializer $reaction_type not valid for attribute type of in class $class\n" if ((grep /$reaction_type/, @allowed_reaction_types) != 1);
    }

    #--------------------------------------------------------------------------------------
    # Function: xxx
    # Synopsys: 
    #--------------------------------------------------------------------------------------
#    sub xxx {
#	my $self = shift;
#    }

}


sub run_testcases {
    printn "NO TESTCASES!!!";
}


# Package BEGIN must return true value
return 1;
