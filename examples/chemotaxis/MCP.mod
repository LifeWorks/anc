#
# Bacterial Chemotaxis Receptor Protein (MCP)
#
# References:
# Asakura S, Honda H. Two-state model for bacterial chemoreceptor proteins.
# The role of multiple methylation. J Mol Biol. 1984 Jul 5;176(3):349-67.
#
# Asakura's model assumptions:
#   S (swim) accepts methyl groups in a definite order
#   T (tumble) releases methyl groups in the reverse order
#
#   Methylation sites are not equivalent and have distinct rates rates
#   Methyl transferase CheR binds to S form only
#   Esterase CheB binds T form only
#   (de)methylation are slow reactions compared to S<->T
#
#   Attractants bind only S form
#   Repellents bind only T form
#   Single ligand binding site changes allosteric equilibrium
# 
# Here, we relax these assumptions and do not impose a particular order
# of methylation, and also allow both ligands to bind to either state.
#
# The total number of species generated for N methylation sites is
# expected to be (2^N*(N+1)*3*2 + 4).
#
# N=1 -> 24+4   = 28
# N=2 -> 72+4   = 76
# N=3 -> 192+4  = 196
# N=6 -> 2688+4 = 2692

###################################
MODEL:
###################################

#-----------------------------------------------------
# COMPILE PARAMETERS
#-----------------------------------------------------
$export_graphviz = "network,collapse_states,collapse_complexes"
$max_csite_bound_to_msite_number = 1;
$max_species = -1;

#-----------------------------------------------------
# MODEL PARAMETERS
#-----------------------------------------------------
# ALLOSTERIC
Parameter : {
	name => "k_ST",
	value => 1.0,
}
Parameter : {
	name => "k_TS",
	value => 10000,
}
Parameter : {
	name => "Phi_ST",
	value => 0.5,
}

# LIGAND BINDING
# (attractant)
Parameter : {
	name => "kf_AS",
	value => 100.0,
}
Parameter : {
	name => "kb_AS",
	value => 0.1,
}
Parameter : {
	name => "kf_AT",
	value => 100.0,
}
Parameter : {
	name => "kb_AT",
	value => 100.0,
}
# (repellent)
Parameter : {
	name => "kf_RS",
	value => 100.0,
}
Parameter : {
	name => "kb_RS",
	value => 0.1,
}
Parameter : {
	name => "kf_RT",
	value => 100.0,
}
Parameter : {
	name => "kb_RT",
	value => 100.0,
}

# METHYLATION SITE KEQ_RATIOS
Parameter : {
	name => "KeqR1",
	value => 1.0,
}
Parameter : {
	name => "KeqR2",
	value => 1.0,
}
Parameter : {
	name => "KeqR3",
	value => 1.0,
}
Parameter : {
	name => "KeqR4",
	value => 1.0,
}
Parameter : {
	name => "KeqR5",
	value => 1.0,
}
Parameter : {
	name => "KeqR6",
	value => 1.0,
}

# METHYLATION RATES
Parameter : {
	name => "kf_RM1S",
	value => 1.0,
}
Parameter : {
	name => "kb_RM1S",
	value => 1.0,
}
Parameter : {
	name => "kp_RM1S",
	value => 1.0,
}
Parameter : {
	name => "kf_RM1T",
	value => 1.0,
}
Parameter : {
	name => "kb_RM1T",
	value => 1.0,
}
Parameter : {
	name => "kp_RM1T",
	value => 1.0,
}

Parameter : {
	name => "kf_RM2S",
	value => 1.0,
}
Parameter : {
	name => "kb_RM2S",
	value => 1.0,
}
Parameter : {
	name => "kp_RM2S",
	value => 1.0,
}
Parameter : {
	name => "kf_RM2T",
	value => 1.0,
}
Parameter : {
	name => "kb_RM2T",
	value => 1.0,
}
Parameter : {
	name => "kp_RM2T",
	value => 1.0,
}

Parameter : {
	name => "kf_RM3S",
	value => 1.0,
}
Parameter : {
	name => "kb_RM3S",
	value => 1.0,
}
Parameter : {
	name => "kp_RM3S",
	value => 1.0,
}
Parameter : {
	name => "kf_RM3T",
	value => 1.0,
}
Parameter : {
	name => "kb_RM3T",
	value => 1.0,
}
Parameter : {
	name => "kp_RM3T",
	value => 1.0,
}

Parameter : {
	name => "kf_RM4S",
	value => 1.0,
}
Parameter : {
	name => "kb_RM4S",
	value => 1.0,
}
Parameter : {
	name => "kp_RM4S",
	value => 1.0,
}
Parameter : {
	name => "kf_RM4T",
	value => 1.0,
}
Parameter : {
	name => "kb_RM4T",
	value => 1.0,
}
Parameter : {
	name => "kp_RM4T",
	value => 1.0,
}

Parameter : {
	name => "kf_RM5S",
	value => 1.0,
}
Parameter : {
	name => "kb_RM5S",
	value => 1.0,
}
Parameter : {
	name => "kp_RM5S",
	value => 1.0,
}
Parameter : {
	name => "kf_RM5T",
	value => 1.0,
}
Parameter : {
	name => "kb_RM5T",
	value => 1.0,
}
Parameter : {
	name => "kp_RM5T",
	value => 1.0,
}

Parameter : {
	name => "kf_RM6S",
	value => 1.0,
}
Parameter : {
	name => "kb_RM6S",
	value => 1.0,
}
Parameter : {
	name => "kp_RM6S",
	value => 1.0,
}
Parameter : {
	name => "kf_RM6T",
	value => 1.0,
}
Parameter : {
	name => "kb_RM6T",
	value => 1.0,
}
Parameter : {
	name => "kp_RM6T",
	value => 1.0,
}


# DE-METHYLATION RATES
Parameter : {
	name => "kf_BM1S",
	value => 1.0,
}
Parameter : {
	name => "kb_BM1S",
	value => 1.0,
}
Parameter : {
	name => "kp_BM1S",
	value => 1.0,
}
Parameter : {
	name => "kf_BM1T",
	value => 1.0,
}
Parameter : {
	name => "kb_BM1T",
	value => 1.0,
}
Parameter : {
	name => "kp_BM1T",
	value => 1.0,
}

Parameter : {
	name => "kf_BM2S",
	value => 1.0,
}
Parameter : {
	name => "kb_BM2S",
	value => 1.0,
}
Parameter : {
	name => "kp_BM2S",
	value => 1.0,
}
Parameter : {
	name => "kf_BM2T",
	value => 1.0,
}
Parameter : {
	name => "kb_BM2T",
	value => 1.0,
}
Parameter : {
	name => "kp_BM2T",
	value => 1.0,
}

Parameter : {
	name => "kf_BM3S",
	value => 1.0,
}
Parameter : {
	name => "kb_BM3S",
	value => 1.0,
}
Parameter : {
	name => "kp_BM3S",
	value => 1.0,
}
Parameter : {
	name => "kf_BM3T",
	value => 1.0,
}
Parameter : {
	name => "kb_BM3T",
	value => 1.0,
}
Parameter : {
	name => "kp_BM3T",
	value => 1.0,
}

Parameter : {
	name => "kf_BM4S",
	value => 1.0,
}
Parameter : {
	name => "kb_BM4S",
	value => 1.0,
}
Parameter : {
	name => "kp_BM4S",
	value => 1.0,
}
Parameter : {
	name => "kf_BM4T",
	value => 1.0,
}
Parameter : {
	name => "kb_BM4T",
	value => 1.0,
}
Parameter : {
	name => "kp_BM4T",
	value => 1.0,
}

Parameter : {
	name => "kf_BM5S",
	value => 1.0,
}
Parameter : {
	name => "kb_BM5S",
	value => 1.0,
}
Parameter : {
	name => "kp_BM5S",
	value => 1.0,
}
Parameter : {
	name => "kf_BM5T",
	value => 1.0,
}
Parameter : {
	name => "kb_BM5T",
	value => 1.0,
}
Parameter : {
	name => "kp_BM5T",
	value => 1.0,
}

Parameter : {
	name => "kf_BM6S",
	value => 1.0,
}
Parameter : {
	name => "kb_BM6S",
	value => 1.0,
}
Parameter : {
	name => "kp_BM6S",
	value => 1.0,
}
Parameter : {
	name => "kf_BM6T",
	value => 1.0,
}
Parameter : {
	name => "kb_BM6T",
	value => 1.0,
}
Parameter : {
	name => "kp_BM6T",
	value => 1.0,
}

#-----------------------------------------------------
# MCP
#-----------------------------------------------------
ReactionSite: {
	name => "LB",    # ligand binding site
	type => "bsite",
}
ReactionSite: {
	name => "M1",    # methylation site
	type => "msite",
	reg_factor => KeqR1,
}
ReactionSite: {
	name => "M2",    # methylation site
	type => "msite",
	reg_factor => KeqR2,
}
ReactionSite: {
	name => "M3",    # methylation site
	type => "msite",
	reg_factor => KeqR3,
}
ReactionSite: {
	name => "M4",    # methylation site
	type => "msite",
	reg_factor => KeqR4,
}
ReactionSite: {
	name => "M5",    # methylation site
	type => "msite",
	reg_factor => KeqR5,
}
ReactionSite: {
	name => "M6",    # methylation site
	type => "msite",
	reg_factor => KeqR6,
}

AllostericStructure: {
	name => MCP,
	elements => [LB,M1,M2,M3,M4,M5,M6],
	allosteric_transition_rates => [k_ST, k_TS],
	allosteric_state_labels => ['S','T'],
	Phi => Phi_ST,
}

#-----------------------------------------------------
# (DE)METHYLATION ENZYMES
#-----------------------------------------------------
# Methyl transferase CheR
ReactionSite: {
	name => CheR,
	type => "csite",
}
Structure: {
	name => CheR,
	elements => [CheR],
}
# Esterase CheB
ReactionSite: {
	name => CheB,
	type => "csite",
}
Structure: {
	name => CheB,
	elements => [CheB],
}

#-----------------------------------------------------
# LIGANDS
#-----------------------------------------------------
# Attractor
ReactionSite: {
	name => "A",    # ligand
	type => "bsite",
}
Structure: {name => A, elements => [A]}
# Repellent
ReactionSite: {
	name => "R",    # ligand
	type => "bsite",
}
Structure: {name => R, elements => [R]}

#-----------------------------------------------------
# RULES
#-----------------------------------------------------
# LIGAND BINDING
CanBindRule : {
	ligand_names => ['LB', 'A'], 
	ligand_allosteric_labels => ['S', '.'],
	kf => kf_AS, 
	kb => kb_AS,
}
CanBindRule : {
	ligand_names => ['LB', 'A'], 
	ligand_allosteric_labels => ['T', '.'],
	kf => kf_AT, 
	kb => kb_AT,
}
CanBindRule : {
	ligand_names => ['LB', 'R'], 
	ligand_allosteric_labels => ['S', '.'],
	kf => kf_RS, 
	kb => kb_RS,
}
CanBindRule : {
	ligand_names => ['LB', 'R'], 
	ligand_allosteric_labels => ['T', '.'],
	kf => kf_RT, 
	kb => kb_RT,
}

# METHYLATION
CanBindRule : {
	ligand_names => ['CheR', 'M1'], 
	ligand_allosteric_labels => ['.', 'S'],
	ligand_msite_states => ['.', '0'],
	kf => kf_RM1S, 
	kb => kb_RM1S,
	kp => kp_RM1S,
}
CanBindRule : {
	ligand_names => ['CheR', 'M1'], 
	ligand_allosteric_labels => ['.', 'T'],
	ligand_msite_states => ['.', '0'],
	kf => kf_RM1T, 
	kb => kb_RM1T,
	kp => kp_RM1T,
}
CanBindRule : {
	ligand_names => ['CheR', 'M2'], 
	ligand_allosteric_labels => ['.', 'S'],
	ligand_msite_states => ['.', '0'],
	kf => kf_RM2S, 
	kb => kb_RM2S,
	kp => kp_RM2S,
}
CanBindRule : {
	ligand_names => ['CheR', 'M2'], 
	ligand_allosteric_labels => ['.', 'T'],
	ligand_msite_states => ['.', '0'],
	kf => kf_RM2T, 
	kb => kb_RM2T,
	kp => kp_RM2T,
}
CanBindRule : {
	ligand_names => ['CheR', 'M3'], 
	ligand_allosteric_labels => ['.', 'S'],
	ligand_msite_states => ['.', '0'],
	kf => kf_RM3S, 
	kb => kb_RM3S,
	kp => kp_RM3S,
}
CanBindRule : {
	ligand_names => ['CheR', 'M3'], 
	ligand_allosteric_labels => ['.', 'T'],
	ligand_msite_states => ['.', '0'],
	kf => kf_RM3T, 
	kb => kb_RM3T,
	kp => kp_RM3T,
}
CanBindRule : {
	ligand_names => ['CheR', 'M4'], 
	ligand_allosteric_labels => ['.', 'S'],
	ligand_msite_states => ['.', '0'],
	kf => kf_RM4S, 
	kb => kb_RM4S,
	kp => kp_RM4S,
}
CanBindRule : {
	ligand_names => ['CheR', 'M4'], 
	ligand_allosteric_labels => ['.', 'T'],
	ligand_msite_states => ['.', '0'],
	kf => kf_RM4T, 
	kb => kb_RM4T,
	kp => kp_RM4T,
}
CanBindRule : {
	ligand_names => ['CheR', 'M5'], 
	ligand_allosteric_labels => ['.', 'S'],
	ligand_msite_states => ['.', '0'],
	kf => kf_RM5S, 
	kb => kb_RM5S,
	kp => kp_RM5S,
}
CanBindRule : {
	ligand_names => ['CheR', 'M5'], 
	ligand_allosteric_labels => ['.', 'T'],
	ligand_msite_states => ['.', '0'],
	kf => kf_RM5T, 
	kb => kb_RM5T,
	kp => kp_RM5T,
}
CanBindRule : {
	ligand_names => ['CheR', 'M6'], 
	ligand_allosteric_labels => ['.', 'S'],
	ligand_msite_states => ['.', '0'],
	kf => kf_RM6S, 
	kb => kb_RM6S,
	kp => kp_RM6S,
}
CanBindRule : {
	ligand_names => ['CheR', 'M6'], 
	ligand_allosteric_labels => ['.', 'T'],
	ligand_msite_states => ['.', '0'],
	kf => kf_RM6T, 
	kb => kb_RM6T,
	kp => kp_RM6T,
}
# DE-METHYLATION
CanBindRule : {
	ligand_names => ['CheB', 'M1'], 
	ligand_allosteric_labels => ['.', 'S'],
	ligand_msite_states => ['.', '1'],
	kf => kf_BM1S, 
	kb => kb_BM1S,
	kp => kp_BM1S,
}
CanBindRule : {
	ligand_names => ['CheB', 'M1'], 
	ligand_allosteric_labels => ['.', 'T'],
	ligand_msite_states => ['.', '1'],
	kf => kf_BM1T, 
	kb => kb_BM1T,
	kp => kp_BM1T,
}
CanBindRule : {
	ligand_names => ['CheB', 'M2'], 
	ligand_allosteric_labels => ['.', 'S'],
	ligand_msite_states => ['.', '1'],
	kf => kf_BM2S, 
	kb => kb_BM2S,
	kp => kp_BM2S,
}
CanBindRule : {
	ligand_names => ['CheB', 'M2'], 
	ligand_allosteric_labels => ['.', 'T'],
	ligand_msite_states => ['.', '1'],
	kf => kf_BM2T, 
	kb => kb_BM2T,
	kp => kp_BM2T,
}
CanBindRule : {
	ligand_names => ['CheB', 'M3'], 
	ligand_allosteric_labels => ['.', 'S'],
	ligand_msite_states => ['.', '1'],
	kf => kf_BM3S, 
	kb => kb_BM3S,
	kp => kp_BM3S,
}
CanBindRule : {
	ligand_names => ['CheB', 'M3'], 
	ligand_allosteric_labels => ['.', 'T'],
	ligand_msite_states => ['.', '1'],
	kf => kf_BM3T, 
	kb => kb_BM3T,
	kp => kp_BM3T,
}
CanBindRule : {
	ligand_names => ['CheB', 'M4'], 
	ligand_allosteric_labels => ['.', 'S'],
	ligand_msite_states => ['.', '1'],
	kf => kf_BM4S, 
	kb => kb_BM4S,
	kp => kp_BM4S,
}
CanBindRule : {
	ligand_names => ['CheB', 'M4'], 
	ligand_allosteric_labels => ['.', 'T'],
	ligand_msite_states => ['.', '1'],
	kf => kf_BM4T, 
	kb => kb_BM4T,
	kp => kp_BM4T,
}
CanBindRule : {
	ligand_names => ['CheB', 'M5'], 
	ligand_allosteric_labels => ['.', 'S'],
	ligand_msite_states => ['.', '1'],
	kf => kf_BM5S, 
	kb => kb_BM5S,
	kp => kp_BM5S,
}
CanBindRule : {
	ligand_names => ['CheB', 'M5'], 
	ligand_allosteric_labels => ['.', 'T'],
	ligand_msite_states => ['.', '1'],
	kf => kf_BM5T, 
	kb => kb_BM5T,
	kp => kp_BM5T,
}
CanBindRule : {
	ligand_names => ['CheB', 'M6'], 
	ligand_allosteric_labels => ['.', 'S'],
	ligand_msite_states => ['.', '1'],
	kf => kf_BM6S, 
	kb => kb_BM6S,
	kp => kp_BM6S,
}
CanBindRule : {
	ligand_names => ['CheB', 'M6'], 
	ligand_allosteric_labels => ['.', 'T'],
	ligand_msite_states => ['.', '1'],
	kf => kf_BM6T, 
	kb => kb_BM6T,
	kp => kp_BM6T,
}

#-----------------------------------------------------
# ICs
#-----------------------------------------------------
Init : {
	structure => MCP,
	IC => 10,
}
Init : {
	structure => A,
	IC => 10,
}
Init : {
	structure => R,
	IC => 10,
}
Init : {
	structure => CheR,
	IC => 10,
}
Init : {
	structure => CheB,
	IC => 10,
}

#-----------------------------------------------------
# STIMULUS
#-----------------------------------------------------
#Stimulus : {
#	structure => 'L',
#	type => "clamp",
#	length => 1000,
#	delay => 500,
#	strength => 1000,
#	concentration => "0.04*(t-500)/1000",
#}

#-----------------------------------------------------
# PROBES
#-----------------------------------------------------
Probe : {
	name => "MCP_S",
	classes => AllostericStructureInstance,
	filters => [
 		'$_->get_name() =~ "MCP"',
 		'$_->get_allosteric_label() eq "S"',
        ],
}
Probe : {
	name => "MCP_T",
	classes => AllostericStructureInstance,
	filters => [
 		'$_->get_name() =~ "MCP"',
 		'$_->get_allosteric_label() eq "T"',
        ],
}

#Probe : {
#	structure => L,
#}

################################
CONFIG:
################################

t_vector = [0:0.1:tf]


