# File: multimer_KNF_square.mod
#
# A sequential model of a generic tetrameric protein 'H'
# * "square" model for subunit interactions
# * numerical values for parameters were chosen arbitrarily for illustration purposes
#
# References:
# Koshland DE Jr, Némethy G, Filmer D. Comparison of experimental binding data
# and theoretical models in proteins containing subunits. Biochemistry. 1966 Jan;5(1):365-85.
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
	name => "k_TR",
	value => 1.0,
}
Parameter : {
	name => "k_RT",
	value => 100,
}
Parameter : {
	name => "Gamma",
	value => 10,
}
Parameter : {
	name => "Phi_TR",
	value => 0.2,
}
# BINDING
Parameter : {
	name => "kf_T",
	value => 1.0,
}
Parameter : {
	name => "kb_T",
	value => 10.0,
}
Parameter : {
	name => "kf_R",
	value => 10.0,
}
Parameter : {
	name => "kb_R",
	value => 1,
}

#-----------------------------------------------------
# MULTIMER
#-----------------------------------------------------
ReactionSite: {
	name => "LB",    # ligand binding site
	type => "bsite",
}

AllostericStructure: {
	name => SUBUNIT,
	elements => [LB],
	allosteric_transition_rates => [k_TR, k_RT],
	allosteric_state_labels => ['T','R'],
	Phi => Phi_TR,
}

Structure: {
	name => H,
	elements => [SUBUNIT, SUBUNIT, SUBUNIT, SUBUNIT],
	add_allosteric_couplings => [
		[0, 1, Gamma, Phi_TR],
		[1, 2, Gamma, Phi_TR],
		[2, 3, Gamma, Phi_TR],
		[3, 0, Gamma, Phi_TR],
	],
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
	structure => H,
	IC => 1,
	state => '[,[T,x],[T,x],[T,x],[T,x]]',
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
	name => "p_R0",
	classes => StructureInstance,
	filters => [
 		'$_->get_exported_name() =~ "H"',
		'$_->get_num_elements() == 4',
 		'scalar(grep {$_->get_allosteric_label() eq "R"} $_->get_elements()) == 0',
        ],
}
Probe : {
	name => "p_R1",
	classes => StructureInstance,
	filters => [
 		'$_->get_exported_name() =~ "H"',
		'$_->get_num_elements() == 4',
 		'scalar(grep {$_->get_allosteric_label() eq "R"} $_->get_elements()) == 1',
        ],
}
Probe : {
	name => "p_R2",
	classes => StructureInstance,
	filters => [
 		'$_->get_exported_name() =~ "H"',
		'$_->get_num_elements() == 4',
 		'scalar(grep {$_->get_allosteric_label() eq "R"} $_->get_elements()) == 2',
        ],
}
Probe : {
	name => "p_R3",
	classes => StructureInstance,
	filters => [
 		'$_->get_exported_name() =~ "H"',
		'$_->get_num_elements() == 4',
 		'scalar(grep {$_->get_allosteric_label() eq "R"} $_->get_elements()) == 3',
        ],
}
Probe : {
	name => "p_R4",
	classes => StructureInstance,
	filters => [
 		'$_->get_exported_name() =~ "H"',
		'$_->get_num_elements() == 4',
 		'scalar(grep {$_->get_allosteric_label() eq "R"} $_->get_elements()) == 4',
        ],
}

Probe : {
	structure => L,
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

t_final = 10000
t_vector = [0:1:tf]

matlab_ode_solver = ode15s
matlab_odeset_options = odeset('InitialStep', 1e-15, 'AbsTol', 1e-48, 'RelTol', 1e-5)

SS_timescale = 100
SS_RelTol = 1e-3
SS_AbsTol = 1e-6

