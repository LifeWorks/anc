###############################################################################
# File: modification_effect.mod
#
# This example consists of a generic, monovalent protein A with a
# a single modification site (T).
#
# When unmodified, the protein prefers the low-affinity R
# conformation. A modification site K, when modified favours
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
	name => "Gamma_T",
	value => 5000,
}
Parameter : {
	name => "Phi_T",
	value => 0.5,
}

# PHOSPHORYLATION
Parameter : {
	name => "kf_RK",
	value => 1.0,
}
Parameter : {
	name => "kb_RK",
	value => 10.0,
}
Parameter : {
	name => "kp_RK",
	value => 20.0,
}
Parameter : {
	name => "kf_SK",
	value => 10.0,
}
Parameter : {
	name => "kb_SK",
	value => 1.0,
}
Parameter : {
	name => "kp_SK",
	value => 20.0,
}

#-----------------------------------------------------
# MONOVALENT PROTEIN
#-----------------------------------------------------
ReactionSite: {
	name => "T",
	type => "msite",
}
AllostericStructure: {
	name => A, 
	elements => [T],
	allosteric_transition_rates => [kf_RS, kb_RS],
	allosteric_state_labels => ['R','S'],
	reg_factors => [Gamma_T],
	Phi => Phi_T,
}

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
	structure => A,
	IC=> 1.0,
}
Init : {
	structure => K,
	IC => 0.0,
}

#-----------------------------------------------------
# PROBES
#-----------------------------------------------------
Probe : {
	name => "AK_DIMER",
	classes => ComplexInstance,
	filters => [
 		'$_->get_num_elements() == 2',
 		'$_->get_exported_name() =~ /A.*K/',
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
	structure => K,
}
Probe : {
	structure => A,
}

################################
CONFIG:
################################

t_final = 2000.0

