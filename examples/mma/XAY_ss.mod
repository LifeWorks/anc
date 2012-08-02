###############################################################################
# File: XAY_ss.mod
#
# Description: Assembly of  X-A-Y.
# The system is simulated to steady-state.
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
# ALLOSTERY
Parameter : {
	name => "K_RS",
	value => 1e-3,
}
Parameter : {
	name => "kf_RS",
	value => 0.1,
}
Parameter : {
	name => "kb_RS",
	value => "kf_RS/K_RS",
}
Parameter : {
	name => "Phi_AX",
	value => 0.5,
}
Parameter : {
	name => "Phi_AY",
	value => 0.5,
}

# COOPERATIVITY PARAMETERS
Parameter : {
	name => "alpha_X",  # differential affinity of X
	value => 1.0,
}
Parameter : {
	name => "alpha_Y",  # differential affinity of Y
	value => 1.0,
}

# LIGAND BINDING (X to A)
Parameter : {
	name => "K_RX",   # affinity of X to R-state
	value => 1.0,
}
Parameter : {
	name => "kf_RX",
	value => 1.0,
}
Parameter : {
	name => "kb_RX",
	value => "kf_RX/K_RX",
}
Parameter : {
	name => "kf_SX",
	value => 1.0,
}
Parameter : {
	name => "kb_SX",
	value => "kf_SX/alpha_X/K_RX",
}
# LIGAND BINDING (Y to A)
Parameter : {
	name => "K_RY",   # affinity of Y to R-state
	value => 1.0,
}
Parameter : {
	name => "kf_RY",
	value => 1.0,
}
Parameter : {
	name => "kb_RY",
	value => "kf_RY/K_RY",
}
Parameter : {
	name => "kf_SY",
	value => 1.0,
}
Parameter : {
	name => "kb_SY",
	value => "kf_SY/alpha_Y/K_RY",
}

#-----------------------------------------------------
# ADAPTOR PROTEIN
#-----------------------------------------------------
ReactionSite: {
	name => "AX",
	type => "bsite",
}
ReactionSite: {
	name => "AY",
	type => "bsite",
}
AllostericStructure: {
	name => A, 
	elements => [AX, AY],
	allosteric_transition_rates => [kf_RS, kb_RS],
	allosteric_state_labels => ['R','S'],
	Phi => [Phi_AX, Phi_AY],
}

#-----------------------------------------------------
# LIGANDS X and Y
#-----------------------------------------------------
ReactionSite : {
	name => "X",
	type => "bsite",
}
Structure: {name => X, elements => [X]}

ReactionSite : {
	name => "Y",
	type => "bsite",
}
Structure: {name => Y, elements => [Y]}

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
	ligand_names => ['Y', 'AY'],
	ligand_allosteric_labels => ['.', 'R'],
	kf => kf_RY,
	kb => kb_RY,
}

CanBindRule : {
	ligand_names => ['Y', 'AY'],
	ligand_allosteric_labels => ['.', 'S'],
	kf => kf_SY,
	kb => kb_SY,
}

#-----------------------------------------------------
# PROBES
#-----------------------------------------------------

Probe : {
	name => "TRIMER",
	classes => ComplexInstance,
	filters => [
 		'$_->get_num_elements() == 3',
        ],
}

Probe : {
	name => "AX_DIMER",
	classes => ComplexInstance,
	filters => [
 		'$_->get_num_elements() == 2',
 		'$_->get_exported_name() =~ /A.*X/',
        ],
}

Probe : {
	name => "AY_DIMER",
	classes => ComplexInstance,
	filters => [
 		'$_->get_num_elements() == 2',
 		'$_->get_exported_name() =~ /A.*Y/',
        ],
}

Probe : {
	name => "A_FREE",
	classes => ComplexInstance,
	filters => [
 		'$_->get_num_elements() == 1',
 		'$_->get_exported_name() =~ /A/',
        ],
}

Probe : {
	name => "A_TOTAL",
	classes => ComplexInstance,
	filters => [
 		'$_->get_exported_name() =~ /A/',
        ],
}

Probe : {
	name => "X_TOTAL",
	classes => ComplexInstance,
	filters => [
 		'$_->get_exported_name() =~ /X/',
        ],
}

Probe : {
	name => "Y_TOTAL",
	classes => ComplexInstance,
	filters => [
 		'$_->get_exported_name() =~ /Y/',
        ],
}

Probe : {
	structure => X,
}
Probe : {
	structure => Y,
}

#-----------------------------------------------------
# INITIAL CONDITIONS
#-----------------------------------------------------
Init : {
	structure => A,
	IC=> 1.0,
}
Init : {
	structure => X,
	IC => 1.0,
}
Init : {
	structure => Y,
	IC => 1.0,
}

################################
CONFIG:
################################
t_final = 500000
t_vector = [0:1:tf]

ode_event_times = ~

matlab_ode_solver = ode15s


