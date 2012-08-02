# File: multimer_TTS_gem.mod
#
# Tertiary two-state model (TTS) model of a tetrameric protein
# * includes geminate rebinding via a special "docking site"
# * does *not* include non-exponential tertiary relaxation (c.f. Henry et al.)
# * numerical values for parameters were chosen arbitrarily for illustration purposes
#
# References:
# Henry et al., 2002, "A tertiary two-state allosteric model
# for hemoglobin", Biophysical Chemistry, (98) 2002,149-164.
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
# ALLOSTERIC
Parameter : {
	name => "k_tr",
	value => .1,
}
Parameter : {
	name => "k_rt",
	value => 20.0,
}
Parameter : {
	name => "k_TR",
	value => 0.15,
}
Parameter : {
	name => "k_RT",
	value => 40.0,
}
Parameter : {
	name => "Gamma",
	value => 100.0,
}
Parameter : {
	name => "Phi_T", # phi-value for quaternary transition modified by tertiary subunit state
	value => 0.5,
}
Parameter : {
	name => "Phi_Q", # phi-value for tertiary transition modified by quaternary state
	value => 0.5,
}
Parameter : {
	name => "Phi_LB", # phi-value for tertiary transition modified by ligand binding
	value => 0.5,
}

# BINDING
Parameter : {
	name => "kin",
	value => 1.0,
}
Parameter : {
	name => "kout",
	value => 1.0,
}
Parameter : {
	name => "kf_t",
	value => 100.0,
}
Parameter : {
	name => "kb_t",
	value => 100.0,
}
Parameter : {
	name => "kf_r",
	value => 100.0,
}
Parameter : {
	name => "kb_r",
	value => 0.1,
}

#-----------------------------------------------------
# MULTIMER
#-----------------------------------------------------
# We use use a ligand "docking" site to separate
# ligand entry and exit into the subunit with the
# actual binding step.

ReactionSite: {
	name => "D",    # ligand docking site (subunit entry & exit)
	type => "bsite",
}
ReactionSite: {
	name => "B",    # ligand binding site
	type => "bsite",
}
AllostericStructure: {
	name => SUBUNIT,
	elements => [D,B],
	allosteric_transition_rates => ['k_tr', 'k_rt'],
	allosteric_state_labels => ['t','r'],
	Phi => Phi_LB,
}
AllostericStructure: {
	name => H,
	elements => [SUBUNIT, SUBUNIT, SUBUNIT, SUBUNIT],
	allosteric_transition_rates => ['k_TR', 'k_RT'],
	allosteric_state_labels => ['T','R'],
	reg_factors => Gamma,    # allosteric effect on R/T ratio when SUBUNIT in r state
	Phi => [[Phi_T,Phi_Q],[Phi_T,Phi_Q],[Phi_T,Phi_Q],[Phi_T,Phi_Q]],
}

#-----------------------------------------------------
# LIGAND
#-----------------------------------------------------
ReactionSite: {
	name => "Dn",    # docking
	type => "bsite",
}
ReactionSite: {
	name => "Bn",    # binding
	type => "bsite",
}
Structure: {name => L, elements => [Dn,Bn]}

#-----------------------------------------------------
# RULES
#-----------------------------------------------------
# These binding rules contain ad-hoc constraints to
# ensure that a ligand will bind to the same subunit
# that it has "docked" to, to ensure docking
# (i.e. ligand entry into the subunit) precedes binding,
# and to ensure undocking (i.e. exit) cannot occur unless
# the ligand has unbound first.

# DOCKING
CanBindRule : {
	ligand_names => ['D', 'Dn'], 
	ligand_allosteric_labels => ['.', '.'],
	kf => 'kin', 
	kb => 'kout',
#	steric_factor => 1,
	constraints => [
		'$R->get_right_node()->is_bound() != 1',
	],
}

# BINDING
CanBindRule : {
	ligand_names => ['B', 'Bn'], 
	ligand_allosteric_labels => ['t', '.'],
	kf => 'kf_t', 
	kb => 'kb_t',
	steric_factor => 1,
	constraints => [
		# has to be an internal reaction
		'$internal_flag == 1',
		# docking site must be bound...
		'$L->get_left_node()->is_bound()',
		# to the same sub-unit
		'ident($L->get_left_node()->get_ligand()->get_in_object()) == ident($R->get_in_object())',
	],
}

CanBindRule : {
	ligand_names => ['B', 'Bn'], 
	ligand_allosteric_labels => ['r', '.'],
	kf => 'kf_r', 
	kb => 'kb_r',
	steric_factor => 1,
	constraints => [
		# has to be an internal reaction
		'$internal_flag == 1',
		# docking site must be bound...
		'$L->get_left_node()->is_bound()',
		# to the same sub-unit
		'ident($L->get_left_node()->get_ligand()->get_in_object()) == ident($R->get_in_object())',
	],
}

#-----------------------------------------------------
# ICs
#-----------------------------------------------------
Init : {
	structure => H,
	IC => 1,
}

#-----------------------------------------------------
# STIMULUS
#-----------------------------------------------------
Stimulus : {
	structure => 'L',
	type => "dose_response",
	strength => 1000,
	range => [1e-4,1e1],
	steps => 40,
	log_steps => 1,
}

#-----------------------------------------------------
# PROBES
#-----------------------------------------------------
Probe : {
	name => "p_R",
	classes => AllostericStructureInstance,
	filters => [
 		'$_->get_exported_name() =~ "H"',
 		'$_->get_allosteric_label() eq "R"',
        ],
}

Probe : {
	name => "p_T",
	classes => AllostericStructureInstance,
	filters => [
 		'$_->get_exported_name() =~ "H"',
 		'$_->get_allosteric_label() eq "T"',
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

t_final = 100000
t_vector = [0:1:tf]

matlab_ode_solver = ode15s
matlab_odeset_options = odeset('InitialStep', 1e-15, 'AbsTol', 1e-48, 'RelTol', 1e-5)

SS_timescale = 100
SS_RelTol = 1e-3
SS_AbsTol = 1e-6

