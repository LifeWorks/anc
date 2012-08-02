# File: combined_effect.mod
#
# A model of a heterodimeric protein with each subunit transitioning between alternate
# conformations in a sequential fashion. The subunits transition individually
# but not independently. They are allosterically coupled, such that when one
# of the subunits is in the non-reference conformational state, the allosteric
# equilibrium of the other subunit is affected.
#
# In addition, the alpha subunit is subject to regulation by its interaction sites.
#
# The model is a combination of ligand_effect.mod, modification_effect.mod and
# asite_effect.mod, showing how multiple modifiers affect the allosteric transition
# of an allosteric subunit.

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
# ALLOSTERY
Parameter : {
	name => "k_RS_alpha",
	value => 1.0,
}
Parameter : {
	name => "k_SR_alpha",
	value => 10000,
}
Parameter : {
	name => "k_RS_beta",
	value => 1.0,
}
Parameter : {
	name => "k_SR_beta",
	value => 10000,
}
Parameter : {
	name => "Gamma_ab",
	value => 200.0,
}
Parameter : {
	name => "Phi_ab",
	value => 0.2,
}
Parameter : {
	name => "Phi_ba",
	value => 0.3,
}
Parameter : {
	name => "Gamma_AX",
	value => 5000,
}
Parameter : {
	name => "Phi_AX",
	value => 0.5,
}
Parameter : {
	name => "Gamma_T",
	value => 5000,
}
Parameter : {
	name => "Phi_T",
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
# HETERODIMER
#-----------------------------------------------------
ReactionSite: {
	name => "AX",
	type => "bsite",
}
ReactionSite: {
	name => "T",
	type => "msite",
}
AllostericStructure: {
	name => ALPHA,
	elements => [AX, T],
	allosteric_transition_rates => [k_RS_alpha, k_SR_alpha],
	allosteric_state_labels => ['R','S'],
	reg_factors => [undef,Gamma_T],
	Phi => [Phi_AX, Phi_T],
}
AllostericStructure: {
	name => BETA,
	elements => [],
	allosteric_transition_rates => [k_RS_beta, k_SR_beta],
	allosteric_state_labels => ['R','S'],
}
Structure: {
	name => H,
	elements => [ALPHA, BETA],
	add_allosteric_couplings => [
		[0, 1, Gamma_ab, Phi_ab, Phi_ba],
	],
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
# KINASE
#-----------------------------------------------------
ReactionSite : {
	name => "K",
	type => "csite",
}
Structure: {name => K, elements => [K]}

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
CanBindRule : {
	ligand_names => ['K', 'T'],
	ligand_allosteric_labels => ['.', 'R'],
	ligand_msite_states => ['.', '0'],
	kf => kf_RK,
	kb => kb_RK,
	kp => kp_RK,
}
CanBindRule : {
	ligand_names => ['K', 'T'],
	ligand_allosteric_labels => ['.', 'S'],
	ligand_msite_states => ['.', '0'],
	kf => kf_SK,
	kb => kb_SK,
	kp => kp_SK,
}

#-----------------------------------------------------
# ICs
#-----------------------------------------------------
Init : {
	structure => H,
	IC => 10,
}
Init : {
	structure => X,
	IC => 0.0,
}
Init : {
	structure => K,
	IC => 0.0,
}

#-----------------------------------------------------
# PROBES
#-----------------------------------------------------
Probe : {
	name => "R0",
	classes => StructureInstance,
	filters => [
 		'scalar(grep {$_->get_allosteric_label() eq "R"} $_->get_elements()) == 0',
        ],
}
Probe : {
	name => "R1",
	classes => StructureInstance,
	filters => [
 		'scalar(grep {$_->get_allosteric_label() eq "R"} $_->get_elements()) == 1',
        ],
}
Probe : {
	name => "R2",
	classes => StructureInstance,
	filters => [
 		'scalar(grep {$_->get_allosteric_label() eq "R"} $_->get_elements()) == 2',
        ],
}

################################
EQN:
################################

################################
INIT:
################################

################################
PROBE:
################################

################################
CONFIG:
################################

t_vector = [0:0.1:tf]


