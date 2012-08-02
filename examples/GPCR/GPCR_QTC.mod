#
# The Quartic Ternary Complex (QTC) model of GPCR
#
# References:
# 1. Ollivier JF, Shahrezaei V, Swain PS. Scalable rule-based modelling
#    of allosteric proteins and biochemical networks. 2010. In press.
# 
# 2. Weiss JM, Morgan PH, Lutz MW, Kenakin TP.
#    The cubic ternary complex receptor-occupancy model.
#    III. resurrecting efficacy.
#    J Theor Biol. 1996 Aug 21;181(4):381-97.
#

###################################
MODEL:
###################################

#-----------------------------------------------------
# COMPILE PARAMETERS
#-----------------------------------------------------
$max_species = -1;
$max_complex_size = -1;

$export_graphviz = "network,collapse_states,collapse_complexes"

#-----------------------------------------------------
# MODEL PARAMETERS
#-----------------------------------------------------
# ALLOSTERIC
Parameter : {
	name => "KactL",
	value => 1,
}
Parameter : {
	name => "k_st",
	value => 10.0,
}
Parameter : {
	name => "k_ts",
	value => "k_st/KactL",
}
Parameter : {
	name => "KactG",
	value => 0.05,
}
Parameter : {
	name => "k_ia",
	value => 1.0,
}
Parameter : {
	name => "k_ai",
	value => "k_ia/KactG",
}
Parameter : {
	name => "Gamma",
	value => 1,
}
# use the same Phi-value for all modifiers
Parameter : {
	name => "Phi",
	value => 0.5,
}

# LIGAND BINDING
Parameter : {
	name => "Ka",
	value => 10.0,
}
Parameter : {
	name => "kf_is",
	value => 1.0,
}
Parameter : {
	name => "kb_is",
	value => "kf_is/Ka",
}
Parameter : {
	name => "alpha_t",
	value => 0.1,
}
Parameter : {
	name => "kf_it",
	value => 1.0,
}
Parameter : {
	name => "kb_it",
	value => "kf_it/alpha_t/Ka",
}
Parameter : {
	name => "alpha_a",
	value => 10.0,
}
Parameter : {
	name => "kf_as",
	value => 1.0,
}
Parameter : {
	name => "kb_as",
	value => "kf_as/alpha_a/Ka",
}
Parameter : {
	name => "alpha_at",
	value => 1.0,
}
Parameter : {
	name => "kf_at",
	value => 100.0,
}
Parameter : {
	name => "kb_at",
	value => "kf_at/alpha_at/Ka",
}

# G-PROTEIN BINDING
Parameter : {
	name => "Kg",
	value => 10.0,
}
Parameter : {
	name => "kfg_is",
	value => 1.0,
}
Parameter : {
	name => "kbg_is",
	value => "kfg_is/Kg",
}
Parameter : {
	name => "beta_t",
	value => 0.1,
}
Parameter : {
	name => "kfg_it",
	value => 1.0,
}
Parameter : {
	name => "kbg_it",
	value => "kfg_it/beta_t/Kg",
}
Parameter : {
	name => "beta_a",
	value => 10.0,
}
Parameter : {
	name => "kfg_as",
	value => 1.0,
}
Parameter : {
	name => "kbg_as",
	value => "kfg_as/beta_a/Kg",
}
Parameter : {
	name => "beta_at",
	value => 1.0,
}
Parameter : {
	name => "kfg_at",
	value => 1.0,
}
Parameter : {
	name => "kbg_at",
	value => "kfg_at/beta_at/Kg",
}

#-----------------------------------------------------
# GPCR
#-----------------------------------------------------
ReactionSite: {
	name => "LB",    # ligand binding site
	type => "bsite",
}

ReactionSite: {
	name => "GB",    # G-protein binding site
		type => "bsite",
}

AllostericStructure: {
	name => ED,      # binding subunit
	elements => [LB],
	allosteric_transition_rates => [k_st, k_ts],
	allosteric_state_labels => ['s','t'],
	Phi => Phi,
}

AllostericStructure: {
	name => ID,      # activation subunit
	elements => [GB],
	allosteric_transition_rates => [k_ia, k_ai],
	allosteric_state_labels => ['i','a'],
	Phi => Phi,
}

Structure: {
	name => R,      # receptor
	elements => [ID, ED],
	add_allosteric_couplings => [
		[0, 1, Gamma, Phi],     # link binding and activation subunits
		[0, [1,0], undef, Phi], # cross-link activation subunit to LB
		[1, [0,0], undef, Phi], # cross-link binding subunit to GB
	],
}

#-----------------------------------------------------
# LIGANDS
#-----------------------------------------------------
# LIGAND
ReactionSite: {
	name => "L",    # ligand
	type => "bsite",
}
Structure: {name => L, elements => [L]}

# G-PROTEIN
ReactionSite: {
	name => "G",    # G-protein
	type => "bsite",
}
Structure: {name => G, elements => [G]}

#-----------------------------------------------------
# RULES
#-----------------------------------------------------
# LIGAND
CanBindRule : {
	ligand_names => ['LB', 'L'], 
	ligand_allosteric_labels => ['is', '.'],
	kf => kf_is, 
	kb => kb_is,
}
CanBindRule : {
	ligand_names => ['LB', 'L'], 
	ligand_allosteric_labels => ['it', '.'],
	kf => kf_it, 
	kb => kb_it,
}
CanBindRule : {
	ligand_names => ['LB', 'L'], 
	ligand_allosteric_labels => ['as', '.'],
	kf => kf_as, 
	kb => kb_as,
}
CanBindRule : {
	ligand_names => ['LB', 'L'], 
	ligand_allosteric_labels => ['at', '.'],
	kf => kf_at, 
	kb => kb_at,
}

# G-PROTEIN
CanBindRule : {
	ligand_names => ['GB', 'G'], 
	ligand_allosteric_labels => ['is', '.'],
	kf => kfg_is, 
	kb => kbg_is,
}
CanBindRule : {
	ligand_names => ['GB', 'G'], 
	ligand_allosteric_labels => ['it', '.'],
	kf => kfg_it, 
	kb => kbg_it,
}
CanBindRule : {
	ligand_names => ['GB', 'G'], 
	ligand_allosteric_labels => ['as', '.'],
	kf => kfg_as, 
	kb => kbg_as,
}
CanBindRule : {
	ligand_names => ['GB', 'G'], 
	ligand_allosteric_labels => ['at', '.'],
	kf => kfg_at, 
	kb => kbg_at,
}

#-----------------------------------------------------
# ICs
#-----------------------------------------------------
Init : {
	structure => R,
	IC => 1.0,
}
Init : {
	structure => L,
	IC => 0,
}
Init : {
	structure => G,
	IC => 1.0,
}

#-----------------------------------------------------
# STIMULUS
#-----------------------------------------------------
Stimulus : {
	structure => 'L',
	type => "dose_response",
	strength => 1000,
	range => [1e-4,1e2],
	steps => 20,
	log_steps => 1,
}

#-----------------------------------------------------
# PROBES
#-----------------------------------------------------
Probe : {
	name => "p_Ris",
	classes => ComplexInstance,
	filters => [
 		'$_->get_exported_name() =~ "Ris"',
        ],
}
Probe : {
	name => "p_Rit",
	classes => ComplexInstance,
	filters => [
 		'$_->get_exported_name() =~ "Rit"',
        ],
}
Probe : {
	name => "p_Ras",
	classes => ComplexInstance,
	filters => [
 		'$_->get_exported_name() =~ "Ras"',
        ],
}
Probe : {
	name => "p_Rat",
	classes => ComplexInstance,
	filters => [
 		'$_->get_exported_name() =~ "Rat"',
        ],
}
Probe : {
	name => "p_Rix",
	classes => ComplexInstance,
	filters => [
 		'$_->get_exported_name() =~ "Ri."',
        ],
}
Probe : {
	name => "p_Rax",
	classes => ComplexInstance,
	filters => [
 		'$_->get_exported_name() =~ "Ra."',
        ],
}

Probe : {
	name => L,
	structure => L,
}
Probe : {
	name => "p_TOTAL_R",
	classes => ComplexInstance,
	filters => [
 		'$_->get_exported_name() =~ /R/',
        ],
}
Probe : {
	name => "p_FREE_R",
	classes => ComplexInstance,
	filters => [
 		'$_->get_exported_name() =~ /R/',
 		'$_->get_num_elements() == 1',
        ],
}

Probe : {
	name => "p_Lx_R",
	classes => ComplexInstance,
	filters => [
 		'$_->get_exported_name() =~ /L/',
 		'$_->get_num_elements() == 2',
        ],
}

Probe : {
	name => "p_R_G",
	classes => ComplexInstance,
	filters => [
 		'$_->get_exported_name() =~ /G/',
 		'$_->get_num_elements() == 2',
        ],
}

Probe : {
	name => "p_Lx_R_G",
	classes => ComplexInstance,
	filters => [
 		'$_->get_exported_name() =~ /G/',
 		'$_->get_num_elements() == 3',
        ],
}


# ACTIVE, G-PROTEIN COUPLED (OPTIONAL L)
Probe : {
	name => "p_Rax_G",
	classes => ComplexInstance,
	filters => [
 		'$_->get_exported_name() =~ /G.*Ra./',
        ],
}

# INACTIVE, G-PROTEIN COUPLED (OPTIONAL L)
Probe : {
	name => "p_Rix_G",
	classes => ComplexInstance,
	filters => [
 		'$_->get_exported_name() =~ /G.*Ri./',
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

