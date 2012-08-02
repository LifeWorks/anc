# File: multimer_KNF_tetra.mod
#
# A sequential model of a generic tetrameric protein 'H'
# * "tetrameric" model for subunit interactions
# * numerical values for parameters were chosen arbitrarily for illustration purposes
# * mixture of 2 ligands, L1 and L2
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
	name => "K_TR",
	value => 0.01,
}
Parameter : {
	name => "Gamma",
	value => 10,
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
	value => 0.2,
}
# BINDING L1
Parameter : {
	name => "K1_T",
	value => 0.1,
}
Parameter : {
	name => "kf1_T",
	value => 1.0,
}
Parameter : {
	name => "kb1_T",
	value => "kf1_T/K1_T",
}
Parameter : {
	name => "K1_R",
	value => 10,
}
Parameter : {
	name => "kf1_R",
	value => 1.0,
}
Parameter : {
	name => "kb1_R",
	value => "kf1_R/K1_R",
}
# BINDING L2
Parameter : {
	name => "K2_T",
	value => 0.1,
}
Parameter : {
	name => "kf2_T",
	value => 1.0,
}
Parameter : {
	name => "kb2_T",
	value => "kf2_T/K2_T",
}
Parameter : {
	name => "K2_R",
	value => 10,
}
Parameter : {
	name => "kf2_R",
	value => 1.0,
}
Parameter : {
	name => "kb2_R",
	value => "kf2_R/K2_R",
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
		[0, 2, Gamma, Phi_TR],
		[0, 3, Gamma, Phi_TR],
		[1, 2, Gamma, Phi_TR],
		[1, 3, Gamma, Phi_TR],
		[2, 3, Gamma, Phi_TR],
	],
}

#-----------------------------------------------------
# LIGANDS
#-----------------------------------------------------
ReactionSite: {
	name => "L1",    # ligand
	type => "bsite",
}
Structure: {name => L1, elements => [L1]}
ReactionSite: {
	name => "L2",    # ligand
	type => "bsite",
}
Structure: {name => L2, elements => [L2]}

#-----------------------------------------------------
# RULES
#-----------------------------------------------------
CanBindRule : {
	ligand_names => ['LB', 'L1'], 
	ligand_allosteric_labels => ['T', '.'],
	kf => kf1_T, 
	kb => kb1_T,
}
CanBindRule : {
	ligand_names => ['LB', 'L1'], 
	ligand_allosteric_labels => ['R', '.'],
	kf => kf1_R, 
	kb => kb1_R,
}
CanBindRule : {
	ligand_names => ['LB', 'L2'], 
	ligand_allosteric_labels => ['T', '.'],
	kf => kf2_T, 
	kb => kb2_T,
}
CanBindRule : {
	ligand_names => ['LB', 'L2'], 
	ligand_allosteric_labels => ['R', '.'],
	kf => kf2_R, 
	kb => kb2_R,
}

#-----------------------------------------------------
# ICs
#-----------------------------------------------------
Init : {
	structure => H,
	IC => 1,
}

Init : {
	structure => L1,
	IC => 0,
}

Init : {
	structure => L2,
	IC => 0,
}

#-----------------------------------------------------
# STIMULUS
#-----------------------------------------------------
Parameter : {
	name => "L1_clamp",
	value => 0,
}
Parameter : {
	name => "L2_clamp",
	value => 0,
}
Stimulus : {
	structure => 'L1',
	type => "clamp",
	strength => 1000,
	concentration => L1_clamp,
}
Stimulus : {
	structure => 'L2',
	type => "clamp",
	strength => 1000,
	concentration => L2_clamp,
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
	name => "p_L1x0",
	classes => ComplexInstance,
	filters => [
 		'$_->get_exported_name() =~ /H/',
 		'scalar(grep {$_->get_parent_name() eq "L1"} $_->get_elements()) == 0',
        ],
}

Probe : {
	name => "p_L1x1",
	classes => ComplexInstance,
	filters => [
 		'$_->get_exported_name() =~ /H/',
 		'scalar(grep {$_->get_parent_name() eq "L1"} $_->get_elements()) == 1',
        ],
}

Probe : {
	name => "p_L1x2",
	classes => ComplexInstance,
	filters => [
 		'$_->get_exported_name() =~ /H/',
 		'scalar(grep {$_->get_parent_name() eq "L1"} $_->get_elements()) == 2',
        ],
}

Probe : {
	name => "p_L1x3",
	classes => ComplexInstance,
	filters => [
 		'$_->get_exported_name() =~ /H/',
 		'scalar(grep {$_->get_parent_name() eq "L1"} $_->get_elements()) == 3',
        ],
}

Probe : {
	name => "p_L1x4",
	classes => ComplexInstance,
	filters => [
 		'$_->get_exported_name() =~ /H/',
 		'scalar(grep {$_->get_parent_name() eq "L1"} $_->get_elements()) == 4',
        ],
}

Probe : {
	structure => L1,
}

Probe : {
	structure => L2,
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

ode_event_times = ~

matlab_ode_solver = ode15s
matlab_odeset_options = odeset('InitialStep', 1e-15, 'AbsTol', 1e-48, 'RelTol', 1e-5)

SS_timescale = 100
SS_RelTol = 1e-3
SS_AbsTol = 1e-6

