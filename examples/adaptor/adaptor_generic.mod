###############################################################################
# File: adaptor_generic.mod
#
# This example consists of a generic, divalent adapter protein A
# with an input binding site (AX) and an output binding site (AY).
#
# When unliganded, the adapter protein prefers the low-affinity (R) state.
# A modulator X binds to the input site of the adapter more strongly
# in its high-affinity (T) form than in its R form, changing the
# allosteric equilibrium in favour of the active form
#
# Likewise, the target protein Y binds the adapter weakly in
# its low-affinity form, but strongly in its high-affinity form.
#
# Thus, X and Y bind with positive cooperatively to the adaptor.
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
# ALLOSTERY
Parameter : {
	name => "kf_RT",
	value => 0.1,
}
Parameter : {
	name => "kb_RT",
	value => 100.0,
}
Parameter : {
	name => "Phi_X",
	value => 0.5,
}
Parameter : {
	name => "Phi_Y",
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
	name => "kf_TX",
	value => 10.0,
}
Parameter : {
	name => "kb_TX",
	value => 1.0,
}
Parameter : {
	name => "kf_RY",
	value => 0.01,
}
Parameter : {
	name => "kb_RY",
	value => 1.0,
}
Parameter : {
	name => "kf_TY",
	value => 1.0,
}
Parameter : {
	name => "kb_TY",
	value => 0.01,
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
	allosteric_transition_rates => [kf_RT, kb_RT],
	allosteric_state_labels => ['R','T'],
	Phi => [Phi_X, Phi_Y],
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
	ligand_allosteric_labels => ['.', 'T'],
	kf => kf_TX,
	kb => kb_TX,
}

CanBindRule : {
	ligand_names => ['Y', 'AY'],
	ligand_allosteric_labels => ['.', 'R'],
	kf => kf_RY,
	kb => kb_RY,
}

CanBindRule : {
	ligand_names => ['Y', 'AY'],
	ligand_allosteric_labels => ['.', 'T'],
	kf => kf_TY,
	kb => kb_TY,
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
	name => "A",
	classes => ComplexInstance,
	filters => [
 		'$_->get_num_elements() == 1',
 		'$_->get_exported_name() =~ /A/',
        ],
}

Probe : {
	name => "RESPONSE",
	classes => ComplexInstance,
	filters => [
 		'$_->get_exported_name() =~ /A.*Y/',
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
# give non-reference state a non-zero IC
Init : {
	structure => A,
	state => '[T,x,x]',
	IC=> 1.0,
}
Init : {
	structure => X,
	IC => 0.0,
}
Init : {
	structure => Y,
	IC => 1.0,
}

#-----------------------------------------------------
# STIMULUS
#-----------------------------------------------------
# Clamp X at successively different levels and bring
# to steady-state each time. In matlab, the variable
# event_times will give the time at which steady-state
# was reached.
Stimulus : {
	structure => 'X',
	type => "dose_response",
#	delay => 100,
	strength => 1000,
	range => [1e-3,1e3],
	steps => 12,
	log_steps => 1,
}

# Clamp at given level
#Stimulus : {
#	structure => 'X',
#	type => "clamp",
#	strength => 100,
#	concentration => 1,
#}

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


