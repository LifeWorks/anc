#
# The Cubic Ternary Complex (CTC) model of GPCR
#
# N.b. this implementation of the CTC does not include the gamma/delta
#      cooperativity parameters of (ref. [1]) because these are incompatible
#      with ANC's assumption that a ligand's affinity to a protein depends
#      only on the conformational state of the protein (see ref. [2]).
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

$export_graphviz = "network,collapse_states,collapse_complexes"

#-----------------------------------------------------
# MODEL PARAMETERS
#-----------------------------------------------------
# ALLOSTERIC
Parameter : {
	name => "Kact",
	value => 0.012,
}
Parameter : {
	name => "k_ia",
	value => 1.0,
}
Parameter : {
	name => "k_ai",
	value => "k_ia/Kact",
}
Parameter : {
	name => "Phi",
	value => 0.5,
}

# LIGAND BINDING
# AGONIST
Parameter : {
	name => "Ka1",
	value => "0.1",
}
Parameter : {
	name => "kf1_i",
	value => 1.0,
}
Parameter : {
	name => "kb1_i",
	value => "kf1_i/Ka1",
}
Parameter : {
	name => "alpha1",
	value => "95",
}
Parameter : {
	name => "kf1_a",
	value => 1.0,
}
Parameter : {
	name => "kb1_a",
	value => "kf1_a/alpha1/Ka1",
}
# INVERSE AGONIST
Parameter : {
	name => "Ka2",
	value => "10.0",
}
Parameter : {
	name => "kf2_i",
	value => 1.0,
}
Parameter : {
	name => "kb2_i",
	value => "kf2_i/Ka2",
}
Parameter : {
	name => "alpha2",
	value => "100",
}
Parameter : {
	name => "kf2_a",
	value => 1.0,
}
Parameter : {
	name => "kb2_a",
	value => "kf2_a/alpha2/Ka2",
}

# G-PROTEIN BINDING
Parameter : {
	name => "Kg",
	value => "0.15",
}
Parameter : {
	name => "kfg_i",
	value => 1.0,
}
Parameter : {
	name => "kbg_i",
	value => "kfg_i/Kg",
}
Parameter : {
	name => "beta",
	value => "103",
}
Parameter : {
	name => "kfg_a",
	value => 1.0,
}
Parameter : {
	name => "kbg_a",
	value => "kfg_a/beta/Kg",
}

# AD HOC INTERACTIONS
# n.b. these params have no effect but the compiled equation file can
# be hacked to include them as per the published model

Parameter : {
	name => "gamma1",
	value => 4.5,
}
Parameter : {
	name => "delta1",
	value => 0.075,
}
Parameter : {
	name => "gamma2",
	value => 4.5,
}
Parameter : {
	name => "delta2",
	value => 0.075,
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
	name => R,      # activation subunit
	elements => [LB,GB],
	allosteric_transition_rates => [k_ia, k_ai],
	allosteric_state_labels => ['i','a'],
	Phi => "Phi",
}

#-----------------------------------------------------
# LIGANDS
#-----------------------------------------------------
# AGONIST
ReactionSite: {
	name => "L1",    # ligand
	type => "bsite",
}
Structure: {name => L1, elements => [L1]}

# INVERSE AGONIST
ReactionSite: {
	name => "L2",    # ligand
	type => "bsite",
}
Structure: {name => L2, elements => [L2]}

# G-PROTEIN
ReactionSite: {
	name => "G",    # G-protein
	type => "bsite",
}
Structure: {name => G, elements => [G]}

#-----------------------------------------------------
# RULES
#-----------------------------------------------------
# AGONIST
CanBindRule : {
	ligand_names => ['LB', 'L1'], 
	ligand_allosteric_labels => ['i', '.'],
	kf => kf1_i, 
	kb => kb1_i,
}
CanBindRule : {
	ligand_names => ['LB', 'L1'], 
	ligand_allosteric_labels => ['a', '.'],
	kf => kf1_a, 
	kb => kb1_a,
}

# INVERSE AGONIST
CanBindRule : {
	ligand_names => ['LB', 'L2'], 
	ligand_allosteric_labels => ['i', '.'],
	kf => kf2_i, 
	kb => kb2_i,
}
CanBindRule : {
	ligand_names => ['LB', 'L2'], 
	ligand_allosteric_labels => ['a', '.'],
	kf => kf2_a, 
	kb => kb2_a,
}

# G-PROTEIN
CanBindRule : {
	ligand_names => ['GB', 'G'], 
	ligand_allosteric_labels => ['i', '.'],
	kf => kfg_i, 
	kb => kbg_i,
}
CanBindRule : {
	ligand_names => ['GB', 'G'], 
	ligand_allosteric_labels => ['a', '.'],
	kf => kfg_a, 
	kb => kbg_a,
}

#-----------------------------------------------------
# ICs
#-----------------------------------------------------
Init : {
	structure => R,
	IC => 10,
}
Init : {
	structure => L1,
	IC => 0, #4,
}
Init : {
	structure => L2,
	IC => 0,
}
Init : {
	structure => G,
	IC => 5.5,
}

#-----------------------------------------------------
# STIMULUS
#-----------------------------------------------------
Stimulus : {
	structure => 'L1',
	type => "clamp",
	length => 1000,
	delay => 500,
	strength => 1000,
	concentration => "100*(t-500)/1000",
}

#-----------------------------------------------------
# PROBES
#-----------------------------------------------------
Probe : {
	name => "p_Ri",
	classes => ComplexInstance,
	filters => [
 		'$_->get_exported_name() =~ "Ri"',
        ],
}
Probe : {
	name => "p_Ra",
	classes => ComplexInstance,
	filters => [
 		'$_->get_exported_name() =~ "Ra"',
        ],
}

Probe : {
	name => L1,
	structure => L1,
}
Probe : {
	name => L2,
	structure => L2,
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
 		'$_->get_exported_name() =~ /R/',
 		'$_->get_num_elements() == 3',
        ],
}


# ACTIVE, G-PROTEIN COUPLED (OPTIONAL L)
Probe : {
	name => "p_Ra_G",
	classes => ComplexInstance,
	filters => [
 		'$_->get_exported_name() =~ /G.*Ra/',
        ],
}

# INACTIVE, G-PROTEIN COUPLED
Probe : {
	name => "p_Ri_G",
	classes => ComplexInstance,
	filters => [
 		'$_->get_exported_name() =~ /G.*Ri/',
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
t_final = 2000
t_vector = [0:0.1:tf]


