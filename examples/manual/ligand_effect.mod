###############################################################################
# File: ligand_effect.mod
#
# This example consists of a generic, monovalent protein A with a
# a single binding site (AX).
#
# When unliganded, the protein prefers the low-affinity R
# conformation. A modifier X binds to the protein more strongly in
# the S conformation by changing the allosteric equilibrium in favour of S.
#
###############################################################################

###################################
MODEL:
###################################

#-----------------------------------------------------
# COMPILE PARAMETERS
#-----------------------------------------------------
$max_species = -1;

#-----------------------------------------------------
# MODEL PARAMETERS
#-----------------------------------------------------
# (none)
# ALLOSTERY
Parameter : {
	name => "kf_RS",
	value => 0.1,
}
Parameter : {
	name => "kb_RS",
	value => 100.0,
}
Parameter : {
	name => "Phi_AX",
	value => 0.5,
}

# LIGAND BINDING
Parameter : {
	name => "kf_RX",
	value => 1.0,
}
Parameter : {
	name => "kb_RX",
	value => 10.0,
}
Parameter : {
	name => "kf_SX",
	value => 10.0,
}
Parameter : {
	name => "kb_SX",
	value => 1.0,
}

#-----------------------------------------------------
# MONOVALENT PROTEIN
#-----------------------------------------------------
ReactionSite: {
	name => "AX",
	type => "bsite",
}
AllostericStructure: {
	name => A, 
	elements => [AX],
	allosteric_transition_rates => [kf_RS, kb_RS],
	allosteric_state_labels => ['R','S'],
	Phi => Phi_AX,
}

#-----------------------------------------------------
# LIGAND X
#-----------------------------------------------------
ReactionSite : {
	name => "X",
	type => "bsite",
}
Structure: {name => X, elements => [X]}

#-----------------------------------------------------
# RULES
#-----------------------------------------------------
CanBindRule : {
	ligand_names => ['X', 'AX'],
	ligand_allosteric_labels => ['.', 'R'],
	kf => kf_RX,
	kb => kb_RX,
}

CanBindRule : {
	ligand_names => ['X', 'AX'],
	ligand_allosteric_labels => ['.', 'S'],
	kf => kf_SX,
	kb => kb_SX,
}

#-----------------------------------------------------
# ICs
#-----------------------------------------------------
Init : {
	structure => A,
	IC=> 1.0,
}
Init : {
	structure => X,
	IC => 0.0,
}

#-----------------------------------------------------
# PROBES
#-----------------------------------------------------
Probe : {
	name => "AX_DIMER",
	classes => ComplexInstance,
	filters => [
 		'$_->get_num_elements() == 2',
 		'$_->get_exported_name() =~ /A.*X/',
        ],
}

Probe : {
	name => "A",
	classes => ComplexInstance,
	filters => [
 		'$_->get_num_elements() == 1',
 		'$_->get_exported_name() =~ /A/',
        ],
}

Probe : {
	structure => X,
}
Probe : {
	structure => Y,
}

#-----------------------------------------------------
# STIMULUS
#-----------------------------------------------------
# Slowly ramp up concentration of X.
# The system will stay close to equilibrium as the
# stimulus increases, so the equilibrium response
# can be obtained by plotting X vs AY concentrations
# (see RESPONSE probe above).
#Stimulus : {
#	structure => 'X',
#	type => "clamp",
#	strength => 100,
#	concentration => "t/200",
#}

# Clamp at given level
Stimulus : {
	structure => 'X',
	type => "clamp",
	strength => 100,
	concentration => 1,
}

################################
CONFIG:
################################

t_final = 20000.0

