# File: asite_effect.mod
#
# A model of a heterodimeric protein with each subunit transitioning between alternate
# conformations in a sequential fashion. The subunits transition individually
# but not independently. They are allosterically coupled, such that when one
# of the subunits is in the non-reference conformational state, the allosteric
# equilibrium of the other subunit is affected.
#

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

#-----------------------------------------------------
# HETERODIMER
#-----------------------------------------------------
AllostericStructure: {
	name => ALPHA,
	elements => [],
	allosteric_transition_rates => [k_RS_alpha, k_SR_alpha],
	allosteric_state_labels => ['R','S'],
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
# ICs
#-----------------------------------------------------
Init : {
	structure => H,
	IC => 10,
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


