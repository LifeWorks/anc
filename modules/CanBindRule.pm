######################################################################################
# File:     CanBindRule.pm
# Author:   Julien F. Ollivier
#
# Copyright (C) 2005-2010 Julien Ollivier.
#
# This program comes with ABSOLUTELY NO WARRANTY.
# This is free software, and you are welcome to redistribute it
# under certain conditions. See file LICENSE.TXT for details.
#
# Synopsys: A BinaryRule derived class for two objects in a reversible binding
#           reaction, with forward and backward rates.
######################################################################################
# Detailed Description:
# ---------------------
######################################################################################

use strict;
use diagnostics;		# equivalent to -w command-line switch
use warnings;

package CanBindRule;
use Class::Std::Storable;
use base qw(BinaryRule);
{
    use Carp;
    use Utils;

    use Globals qw($debug
		   $verbosity
		   $default_steric_factor
		  );

    use CanBindRuleInstance;

    #######################################################################################
    # CLASS ATTRIBUTES
    #######################################################################################
    CanBindRule->set_class_data("INSTANCE_CLASS", "CanBindRuleInstance");
    CanBindRule->set_class_data("LOOKUP_TABLE", {});
    CanBindRule->set_class_data("AUTONAME", "BR");

    #######################################################################################
    # ATTRIBUTES
    #######################################################################################
    my %kf_of :ATTR(get => 'kf', set => 'kf', init_arg => 'kf');
    my %kb_of :ATTR(get => 'kb', set => 'kb', init_arg => 'kb');
    my %kp_of :ATTR(get => 'kp', set => 'kp', init_arg => 'kp', default => 0.0);
    my %ligand_msite_states_of	:ATTR(get => 'ligand_msite_states', set => 'ligand_msite_states', init_arg => 'ligand_msite_states', default => 'UNDEF');
    my %ligand_allosteric_labels_of :ATTR(get => 'ligand_allosteric_labels', set => 'ligand_allosteric_labels', init_arg => 'ligand_allosteric_labels', default => 'UNDEF');
    my %steric_factor_of :ATTR(get => 'steric_factor', set => 'steric_factor', init_arg => 'steric_factor', default => "UNDEF");
    my %association_constraints_of :ATTR(get => 'association_constraints', set => 'association_constraints');
    my %dissociation_constraints_of :ATTR(get => 'dissociation_constraints', set => 'dissociation_constraints');

    ###################################
    # ALLOWED ATTRIBUTE VALUES
    ###################################
    my @allowed_ligand_msite_states = (0, 1, '.');

    #######################################################################################
    # FUNCTIONS
    #######################################################################################

    #######################################################################################
    # CLASS METHODS
    #######################################################################################
    #--------------------------------------------------------------------------------------
    # Function: lookup
    # Synopsys: 
    #--------------------------------------------------------------------------------------
    sub lookup {
	my $class = shift;
	my $L_ref = shift;
	my $R_ref = shift;
	my $association_flag = shift;
	my $internal_flag = shift;

	# -1: unconstrained
	# 0:     association_constraints
	# 1:     dissociation_constraints
	my $constraints_select = shift;
	if ($debug) {
	    confess "ERROR: internal error -- argument not defined" if !defined $L_ref;
	    confess "ERROR: internal error -- argument not defined" if !defined $R_ref;
	    confess "ERROR: internal error -- argument not defined" if !defined $association_flag;
	    confess "ERROR: internal error -- argument not defined" if !defined $internal_flag;
	    confess "ERROR: internal error -- argument not defined" if !defined $constraints_select;
	}
	my $unconstrained_flag = $constraints_select == -1 ? 1 : 0;

	my $L_parent_ref = $L_ref->get_parent_ref();
	my $R_parent_ref = $R_ref->get_parent_ref();

	#--------------------------------------------
	# lookup binding rules
	#--------------------------------------------
	my $rules_ref = BinaryRule::lookup($class, $L_parent_ref, $R_parent_ref);
	return undef if (!defined $rules_ref);

	RULE : foreach my $rule_ref (@$rules_ref) {
	    #--------------------------------------------
	    # check ligand polarity
	    #--------------------------------------------
	    # n.b. get_ligand_msite_states() will swap on commute_flag if necessary
	    my @ligand_msite_states = @{$rule_ref->get_ligand_msite_states()};
	    my $L_required_msite_state = $ligand_msite_states[0];
	    my $R_required_msite_state = $ligand_msite_states[1];
	    next if (($L_parent_ref->get_type() eq "msite") && ($L_required_msite_state ne '.') &&
		     ($L_ref->get_msite_state() != $L_required_msite_state));
	    next if (($R_parent_ref->get_type() eq "msite") && ($R_required_msite_state ne '.') &&
		     ($R_ref->get_msite_state() != $R_required_msite_state));

	    #--------------------------------------------
	    # check allosteric state labels
	    #--------------------------------------------
	    # n.b. get_ligand_allosteric_labels() will swap on commute_flag if necessary
	    my @ligand_allosteric_labels = @{$rule_ref->get_ligand_allosteric_labels()};
	    my $L_required_allosteric_label = $ligand_allosteric_labels[0];
	    my $R_required_allosteric_label = $ligand_allosteric_labels[1];
	    if ($L_required_allosteric_label ne '.') {
		my $L_label = $L_ref->get_allosteric_label();
		if (!defined $L_label || $L_label eq "") {
		    my $rule_name = $rule_ref->isa("Instance") ? $rule_ref->get_parent_ref()->get_name() : $rule_ref->get_name();
		    printn "ERROR: rule $rule_name requires 1st ligand ".$L_parent_ref->get_name()." to have allosteric state label $L_required_allosteric_label, but it has no allosteric state";
		    exit(1);
		}
		if (length($L_required_allosteric_label) != length($L_label)) {
		    my $rule_name = $rule_ref->isa("Instance") ? $rule_ref->get_parent_ref()->get_name() : $rule_ref->get_name();
		    printn "ERROR: in rule $rule_name, incomplete specification of allosteric label for 1st ligand ".$L_parent_ref->get_name();
		    exit(1);
		}
		next if ($L_label !~ /$L_required_allosteric_label/);
	    }
	    if ($R_required_allosteric_label ne '.') {
		my $R_label = $R_ref->get_allosteric_label();
		if (!defined $R_label || $R_label eq "") {
		    my $rule_name = $rule_ref->isa("Instance") ? $rule_ref->get_parent_ref()->get_name() : $rule_ref->get_name();
		    printn "ERROR: rule $rule_name requires 2nd ligand ".$R_parent_ref->get_name()." to have allosteric state label $R_required_allosteric_label, but it has no allosteric state";
		    exit(1);
		}
		if (length($R_required_allosteric_label) != length($R_label)) {
		    my $rule_name = $rule_ref->isa("Instance") ? $rule_ref->get_parent_ref()->get_name() : $rule_ref->get_name();
		    printn "ERROR: in rule $rule_name, incomplete specification of allosteric label for 2nd ligand ".$R_parent_ref->get_name();
		    exit(1);
		}
		next if ($R_label !~ /$R_required_allosteric_label/);
	    }
	    return $rule_ref if $unconstrained_flag;

	    #--------------------------------------------
	    # check ad-hoc constraints
	    #--------------------------------------------
	    my $commuted_flag = $rule_ref->get_commuted_flag();
	    my $L = $commuted_flag ? $R_ref : $L_ref;  # for use by user in eval
	    my $R = $commuted_flag ? $L_ref : $R_ref;

	    my $constraints_ref = !$constraints_select ?
	    $rule_ref->get_association_constraints() :
	    $rule_ref->get_dissociation_constraints();

	    my $eval_result;
	    foreach my $constraint (@$constraints_ref) {
		no warnings; $eval_result = eval $constraint; use warnings;
		if ($@) {
		    print "ERROR: something wrong with constraint expression\nCONSTRAINT:\n$constraint\nMESSAGE:\n$@";
		    exit(1);
		}
		next RULE if !$eval_result;
	    }

	    # all tests passed, return the rule
	    return $rule_ref;
	}

	return undef;
    }

    #######################################################################################
    # INSTANCE METHODS
    #######################################################################################
    #--------------------------------------------------------------------------------------
    # Function: BUILD
    # Synopsys: 
    #--------------------------------------------------------------------------------------
    sub BUILD {
        my ($self, $obj_ID, $arg_ref) = @_;

	# this rule is commutative
	$self->set_commutes_flag(1);

	if (exists $arg_ref->{ligand_allosteric_states}) {
	    printn "ERROR: ligand_allosteric_states argument of CanBindRule is obsolete, use ligand_allosteric_labels instead";
	    exit(1);
	}

	if (defined $arg_ref->{association_constraints}) {
	    $association_constraints_of{$obj_ID} = $arg_ref->{association_constraints};
	} elsif (defined $arg_ref->{constraints}) {
	    $association_constraints_of{$obj_ID} = $arg_ref->{constraints};
	} else {
	    $association_constraints_of{$obj_ID} = [];
	}
	if (defined $arg_ref->{dissociation_constraints}) {
	    $dissociation_constraints_of{$obj_ID} = $arg_ref->{dissociation_constraints};
	} elsif (defined $arg_ref->{constraints}) {
	    $dissociation_constraints_of{$obj_ID} = $arg_ref->{constraints};
	} else {
	    $dissociation_constraints_of{$obj_ID} = [];
	}
    }

    #--------------------------------------------------------------------------------------
    # Function: START
    # Synopsys: 
    #--------------------------------------------------------------------------------------
    sub START {
        my ($self, $obj_ID, $arg_ref) = @_;

	# default values
	$ligand_msite_states_of{$obj_ID} = ['.', '.'] if ($ligand_msite_states_of{$obj_ID} eq 'UNDEF');
	$ligand_allosteric_labels_of{$obj_ID} = ['.', '.'] if ($ligand_allosteric_labels_of{$obj_ID} eq 'UNDEF');
	$steric_factor_of{$obj_ID} = $default_steric_factor if ($steric_factor_of{$obj_ID} eq "UNDEF");

	# check initializers
	my $class = ref $self;
	foreach my $ligand_msite_state (@{$self->get_ligand_msite_states()}) {
	    if (grep($_ eq $ligand_msite_state, @allowed_ligand_msite_states) != 1) {
		croak "Initializer $ligand_msite_state not valid for attribute ligand_msite_states of in class $class\n";
	    }
	}
    }
}

sub run_testcases {

    printn "NO TESTCASES!!!";
}


# Package BEGIN must return true value
return 1;

