# File: multimer_MWC.mod
#
# Toy model for a generic, multimeric concerted allosteric protein 'H'.
# * the number of subunits is easily changed below
# * numerical values for parameters were chosen arbitrarily for illustration purposes
#
# References:
# Monod, Wyman, Changeux, "On the nature of allosteric transitions:
# a plausible model", J Mol Biol. 1965 May;12:88-118.
#
# Parameter values are not to scale.
#
# T is the tense, low-affinity state.
# R is the relaxed, high-affinity state.

###################################
MODEL:
###################################

#-----------------------------------------------------
# COMPILE PARAMETERS
#-----------------------------------------------------
$max_species = -1;

$export_graphviz = "network,collapse_states,collapse_complexes"

#-----------------------------------------------------
# MODEL PARAMETERS
#-----------------------------------------------------
# ALLOSTERY
Parameter : {
	name => "K_TR",
	value => 1e-4,
}
Parameter : {
	name => "k_TR",
	value => 1.0,
}
Parameter : {
	name => "k_RT",
	value => "k_TR/K_TR",
}
Parameter : {
	name => "Phi_TR",
	value => 0.5,
}
# BINDING L
Parameter : {
	name => "K_T",
	value => 0.1,
}
Parameter : {
	name => "kf_T",
	value => 1.0,
}
Parameter : {
	name => "kb_T",
	value => "kf_T/K_T",
}
Parameter : {
	name => "K_R",
	value => 10,
}
Parameter : {
	name => "kf_R",
	value => 10.0,
}
Parameter : {
	name => "kb_R",
	value => "kf_R/K_R",
}

#-----------------------------------------------------
# MULTIMER
#-----------------------------------------------------
ReactionSite: {
	name => "LB",    # ligand binding site
	type => "bsite",
}

AllostericStructure: {name => H,
	elements => [map(LB, (0..3))],  # repeat ligand-binding site N times....
	allosteric_transition_rates => [k_TR, k_RT],
	allosteric_state_labels => ['T','R'],
	Phi => Phi_TR,
}

#-----------------------------------------------------
# LIGAND
#-----------------------------------------------------
ReactionSite: {
	name => "L",    # ligand
	type => "bsite",
}
Structure: {name => L, elements => [L]}

#-----------------------------------------------------
# RULES
#-----------------------------------------------------
CanBindRule : {
	ligand_names => ['LB', 'L'], 
	ligand_allosteric_labels => ['T', '.'],
	kf => kf_T, 
	kb => kb_T,
}

CanBindRule : {
	ligand_names => ['LB', 'L'], 
	ligand_allosteric_labels => ['R', '.'],
	kf => kf_R, 
	kb => kb_R,
}

#-----------------------------------------------------
# ICs
#-----------------------------------------------------
Init : {
	structure => L,
	IC=> 0.0,
}
Init : {
	structure => H,
	IC => 1,
	state => '[T,x,x,x,x]',
}

#-----------------------------------------------------
# STIMULUS
#-----------------------------------------------------
Stimulus : {
	structure => 'L',
	type => "dose_response",
	strength => 1000,
	range => [1e-2,1e2],
	steps => 40,
	log_steps => 1,
}

#-----------------------------------------------------
# PROBES
#-----------------------------------------------------
Probe : {
	name => "p_H_R",
	classes => AllostericStructureInstance,
	filters => [
 		'$_->get_name() =~ "H"',
 		'$_->get_allosteric_label() eq "R"',
        ],
}

Probe : {
	name => "p_H_T",
	classes => AllostericStructureInstance,
	filters => [
 		'$_->get_name() =~ "H"',
 		'$_->get_allosteric_label() eq "T"',
        ],
}

Probe : {
	name => "p_L0",
	classes => ComplexInstance,
	filters => [
 		'$_->get_exported_name() =~ /H/',
 		'$_->get_num_elements() == 1',
        ],
}

Probe : {
	name => "p_L1",
	classes => ComplexInstance,
	filters => [
 		'$_->get_exported_name() =~ /H/',
 		'$_->get_num_elements() == 2',
        ],
}

Probe : {
	name => "p_L2",
	classes => ComplexInstance,
	filters => [
 		'$_->get_exported_name() =~ /H/',
 		'$_->get_num_elements() == 3',
        ],
}

Probe : {
	name => "p_L3",
	classes => ComplexInstance,
	filters => [
 		'$_->get_exported_name() =~ /H/',
 		'$_->get_num_elements() == 4',
        ],
}

Probe : {
	name => "p_L4",
	classes => ComplexInstance,
	filters => [
 		'$_->get_exported_name() =~ /H/',
 		'$_->get_num_elements() == 5',
        ],
}

Probe : {
	structure => L,
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

CONFIG:

t_final = 10000
t_vector = [0:1:tf]

matlab_ode_solver = ode15s
matlab_odeset_options = odeset('InitialStep', 1e-15, 'AbsTol', 1e-48, 'RelTol', 1e-5)

SS_timescale = 100
SS_RelTol = 1e-3
SS_AbsTol = 1e-6

