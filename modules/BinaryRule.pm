######################################################################################
# File:     BinaryRule.pm
# Author:   Julien F. Ollivier
#
# Copyright (C) 2005-2010 Julien Ollivier.
#
# This program comes with ABSOLUTELY NO WARRANTY.
# This is free software, and you are welcome to redistribute it
# under certain conditions. See file LICENSE.TXT for details.
#
# Synopsys: Base class for any rule involving two interacting objects.
######################################################################################
# Detailed Description:
# ---------------------
# Each rule involves two interacting objects whose names must match the regular
# expression given in the ligand_names attribute.
#
# A compile() method finds each matching pair of objects for each rule,
# and compiles a lookup table keyed on matching object IDs, which contains the
# list of the rules which apply to a given pair of interacting objects.
#
# A lookup() method returns an element of this lookup table, given the object IDs.
#
# For a given rule, if commutes_flag is set, then arguments to lookup() commute and
# this method must return identical results.  In this case, a BinaryRuleInstance is
# created, having a commuted_flag indicating whether arguments are swapped with respect to
# the parent rule.  Derived classes can use this flag to swap the order of their
# attributes when appropriate.
######################################################################################

use strict;
use diagnostics;		# equivalent to -w command-line switch
use warnings;

package BinaryRule;
use Class::Std::Storable;
use base qw(Rule Instantiable);
{
    use Carp;

    use Utils;
    use Globals;

    #######################################################################################
    # CLASS ATTRIBUTES
    #######################################################################################
    BinaryRule->set_class_data("LOOKUP_TABLE", {});
    BinaryRule->set_class_data("INSTANCE_CLASS", "BinaryRuleInstance");

    #######################################################################################
    # ATTRIBUTES
    #######################################################################################
    my %ligand_names_of :ATTR(get => 'ligand_names', set => 'ligand_names', init_arg => 'ligand_names');
    # this flag true if match is to be attempted with commuted arguments during compilation
    my %commutes_flag_of :ATTR(get => 'commutes_flag', set => 'commutes_flag', default => 1);

    #######################################################################################
    # FUNCTIONS
    #######################################################################################

    #######################################################################################
    # CLASS METHODS
    #######################################################################################

    #--------------------------------------------------------------------------------------
    # Function: lookup
    # Synopsys: Find list of rules that match arguments using lookup table.
    #--------------------------------------------------------------------------------------
    sub lookup {
	my $class = shift;
	my $L = shift;
	my $R = shift;
	
	my $lookup_table_ref = $class->get_class_data("LOOKUP_TABLE");
	return undef if (!defined $lookup_table_ref);
	
	my $rules_ref = $lookup_table_ref->{$L}{$R}{rules};
	
	return (defined $rules_ref) ? $rules_ref : undef;
    }

#    #--------------------------------------------------------------------------------------
#    # Function: XXX
#    # Synopsys: 
#    #--------------------------------------------------------------------------------------
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
	my $class = ref $self;

	# check initializers
	issue_error("remove deprecated ligand_class attribute from $class ".$self->get_name()) if (exists $arg_ref->{ligand_class});
	croak "ERROR: supply exactly two ligand names in $class ".$self->get_name() if (@{$ligand_names_of{$obj_ID}} != 2)
    }

    #--------------------------------------------------------------------------------------
    # Function: compile  (dual class/instance method)
    # Synopsys: Compile a BinaryRule lookup table, storing under both orders if the
    #           arguments commute because the rule commutes or because
    #           L and R are identical.
    #--------------------------------------------------------------------------------------
    sub compile {
	if (!ref $_[0]) {
	    # class method
	    my $class = shift;
	    foreach my $rule_ref ($class->get_instances()) {
		$rule_ref->compile(@_);
	    }
	    return;
	} else {
	    # instance method
	    my $self = shift;
	    my $class = ref $self;
	    my %args = (
		ligand_classes => undef,
		@_,
	       );
	    check_args(\%args,1);
	    my @ligand_classes = @{$args{ligand_classes}};

	    my $name = $self->get_name();
	    printn "Compiling rule $name of class $class" if ($verbosity >= 1);

	    my $action = $class;
	    $action =~ s/Rule//;

	    my $lookup_table_ref = $class->get_class_data("LOOKUP_TABLE");

	    my @ligand_refs = map {$_->get_instances()} @ligand_classes;

	    my $L_patt = $self->get_ligand_names()->[0];
	    my $R_patt = $self->get_ligand_names()->[1];

	    for (my $i=0; $i < @ligand_refs; $i++) {
		my $i_ref = $ligand_refs[$i];
		my $i_name = $i_ref->get_name();
		for (my $j=$i; $j < @ligand_refs; $j++) {
		    my $j_ref = $ligand_refs[$j];
		    my $j_name = $j_ref->get_name();

		    my $ij_matches_LR;
		    my $ji_matches_LR;

		    my $eval_str = (
			"\$ij_matches_LR = (\$i_name =~ /\^$L_patt\$/) ? 1 : 0;\n".
			"\$ij_matches_LR = (\$ij_matches_LR && \$j_name =~ /\^$R_patt\$/) ? 1 : 0;\n".
			"\$ji_matches_LR = (\$j_name =~ /\^$L_patt\$/) ? 1 : 0;\n".
			"\$ji_matches_LR = (\$ji_matches_LR && \$i_name =~ /\^$R_patt\$/) ? 1 : 0;\n"
 		       );
		    eval ($eval_str);
		    confess "ERROR: something wrong with pattern matching\nCODE:\n$eval_str\nMESSAGE:\n$@" if ($@);
		    my $dimerization_flag = $i_name eq $j_name ? 1 : 0;
		    my $commutes_flag = $commutes_flag_of{ident $self} || $dimerization_flag ? 1 : 0;
		    if ($ij_matches_LR || ($ji_matches_LR && $commutes_flag)) {
			if ($commutes_flag) {
			    my $rule_instance_ref = $self->new_object_instance({
				commuted_flag => $ij_matches_LR ? 0 : 1,  # commuted_flag must be opposite to below
			    });
			    push @{$lookup_table_ref->{$i_ref}{$j_ref}{rules}}, $rule_instance_ref;
			} else {
			    push @{$lookup_table_ref->{$i_ref}{$j_ref}{rules}}, $self;
			}
		    }
		    if ($ji_matches_LR || ($ij_matches_LR && $commutes_flag)) {
			if ($commutes_flag) {
			    my $rule_instance_ref = $self->new_object_instance({
				commuted_flag => $ij_matches_LR ? 1 : 0,  # commuted_flag must be opposite to above
			    });
			    push @{$lookup_table_ref->{$j_ref}{$i_ref}{rules}}, $rule_instance_ref;
			} else {
			    push @{$lookup_table_ref->{$j_ref}{$i_ref}{rules}}, $self;
			}
		    }
		    if ($verbosity >= 1) {
			printn "$i_name $action $j_name" if ( $commutes_flag && ($ij_matches_LR || $ji_matches_LR));
			printn "$i_name $action $j_name" if (!$commutes_flag && $ij_matches_LR);
			printn "$j_name $action $i_name" if (!$commutes_flag && $ji_matches_LR && (!$dimerization_flag));
		    }
		}
	    }
	}
    }
}

sub run_testcases {

    printn "NO TESTCASES!!!";
}

# Package BEGIN must return true value
return 1;

