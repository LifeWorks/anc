######################################################################################
# File:     ElementaryReaction.pm
# Author:   Julien F. Ollivier
#
# Copyright (C) 2005-2010 Julien Ollivier.
#
# This program comes with ABSOLUTELY NO WARRANTY.
# This is free software, and you are welcome to redistribute it
# under certain conditions. See file LICENSE.TXT for details.
#
# Synopsys: An elementary reaction has reactants, products and a rate determined
#           using mass-action law or an explicit rate law.
######################################################################################
# Detailed Description:
# ---------------------
######################################################################################

use strict;
use diagnostics;		# equivalent to -w command-line switch
use warnings;

package ElementaryReaction;
use Class::Std::Storable;
use base qw(Registered);
{
    use Carp;
    use WeakRef;

    #######################################################################################
    # Attributes
    #######################################################################################
    my %container_ref_of	:ATTR(get => 'container_ref', set => 'container_ref', init_arg => 'container_ref');

    my %type_of			:ATTR(get => 'type', init_arg => 'type');
    my %reactants_ref_of	:ATTR(get => 'reactants_ref', init_arg => 'reactants_ref');
    my %products_ref_of		:ATTR(get => 'products_ref', init_arg => 'products_ref');
    my %rate_constant_of	:ATTR(get => 'rate_constant', set => 'rate_constant', init_arg => 'rate_constant');
    my %velocity_of		:ATTR(get => 'velocity', set => 'velocity');

    my @allowed_types = ("MASS-ACTION", "RATE-LAW");

    #######################################################################################
    # Functions
    #######################################################################################

    #######################################################################################
    # Methods
    #######################################################################################

    # CLASS METHODS

    # INSTANCE METHODS
    sub START {
        my ($self, $obj_ID, $arg_ref) = @_;
	
	# check initializers
	my $class = ref $self;
	croak "Initializer $arg_ref->{type} not valid for attribute type of in class $class\n" if ((grep /$arg_ref->{type}/, @allowed_types) != 1);

	# weaken ref to container reaction
	weaken($container_ref_of{$obj_ID});
    }

    sub order {
	my $self = shift;
	return scalar(@{$reactants_ref_of{ident $self}});
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
}


# Package BEGIN must return true value
return 1;

