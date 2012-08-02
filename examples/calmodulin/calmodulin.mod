#
# Allosteric model for Calmodulin
#
# References:
# An allosteric model of calmodulin explains differential activation of PP2B and CaMKII.
# Stefan MI, Edelstein SJ, Le Novère N. Proc Natl Acad Sci U S A. 2008 Aug 5;105(31):10768-73.
# Epub 2008 Jul 31.
#
# T is the low-affinity state.
# R is the high-affinity state.
#
# N.B. This model generates more equations than in Stefan et al. because
# the model allows CaM to transition to T state when target is bound. Thus,
# this model is somewhat more general than the published model. However,
# setting the appropriate parameters to zero as we have done here recovers the
# same behaviour as in Stefan et al. because the extra species are never populated.
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
# MODEL PARAMETERS (from Stefan et al. Supporting Information)
#-----------------------------------------------------
# R-state calcium binding dissociation constants
Parameter: {
	name => "K_RA",
	value => 8.32e-6,
}
Parameter: {
	name => "K_RB",
	value => 1.66e-8,
}
Parameter: {
	name => "K_RC",
	value => 1.74e-5,
}
Parameter: {
	name => "K_RD",
	value => 1.45e-8,
}
# Ratio of R and T state calcium dissociation constants
#
# c = c_i = K_R/K_T
# 
Parameter: {
	name => "c",
	value => 3.96e-3,
}
# T-state calcium binding dissociation constants
Parameter: {
	name => "K_TA",
	value => "K_RA/c",
}
Parameter: {
	name => "K_TB",
	value => "K_RB/c",
}
Parameter: {
	name => "K_TC",
	value => "K_RC/c",
}
Parameter: {
	name => "K_TD",
	value => "K_RD/c",
}

# Calcium on rate (same for all sites)
Parameter: {
	name => "kon",
	value => 1e6,
}

# Calcium off rates
Parameter: {
	name => "koff_RA",
	value => "K_RA * kon",
}
Parameter: {
	name => "koff_RB",
	value => "K_RB * kon",
}
Parameter: {
	name => "koff_RC",
	value => "K_RC * kon",
}
Parameter: {
	name => "koff_RD",
	value => "K_RD * kon",
}
Parameter: {
	name => "koff_TA",
	value => "K_TA * kon",
}
Parameter: {
	name => "koff_TB",
	value => "K_TB * kon",
}
Parameter: {
	name => "koff_TC",
	value => "K_TC * kon",
}
Parameter: {
	name => "koff_TD",
	value => "K_TD * kon",
}

# Unliganded allosteric equilibrium and dynamics
Parameter: {
	name => "L",
	value => 20.670e3,
}
Parameter: {
	name => "k_RT",
	value => 1e6,
}
Parameter: {
	name => "k_TR",
	value => "k_RT/L",
}

# Target ligand binding to R state
Parameter: {
	name => "kon_CaMKII",
	value => 3.2e6,
}
Parameter: {
	name => "koff_CaMKII",
	value => 0.343,
}
Parameter: {
	name => "kon_PP2B",
	value => 4.6e7,
}
Parameter: {
	name => "koff_PP2B",
	value => 1.3e-3,
}


#-----------------------------------------------------
# CALMODULIN
#-----------------------------------------------------
ReactionSite: {
	name => "A",    # Ca binding site
	type => "bsite",
}

ReactionSite: {
	name => "B",    # Ca binding site
	type => "bsite",
}

ReactionSite: {
	name => "C",    # Ca binding site
	type => "bsite",
}

ReactionSite: {
	name => "D",    # Ca binding site
	type => "bsite",
}

ReactionSite: {
	name => "T",    # CaMKII/PP2B target binding site
	type => "bsite",
}

AllostericStructure: {
	name => CAM,
	elements => [A,B,C,D,T],
	allosteric_transition_rates => [k_TR, k_RT],
	allosteric_state_labels => ['T','R'],
	Phi => [0.5, 0.5, 0.5, 0.5, 0],
}

#-----------------------------------------------------
# LIGANDS
#-----------------------------------------------------
ReactionSite: {
	name => "Ca",    # ligand
	type => "bsite",
}
Structure: {name => Ca, elements => [Ca]}

ReactionSite: {
	name => "CaMKII",    # ligand
	type => "bsite",
}
Structure: {name => CaMKII, elements => [CaMKII]}

ReactionSite: {
	name => "PP2B",    # ligand
	type => "bsite",
}
Structure: {name => PP2B, elements => [PP2B]}

#-----------------------------------------------------
# RULES
#-----------------------------------------------------
# Calcium binding
CanBindRule : {
	ligand_names => ['A', 'Ca'], 
	ligand_allosteric_labels => ['T', '.'],
	kf => "kon", 
	kb => koff_TA,
}
CanBindRule : {
	ligand_names => ['A', Ca], 
	ligand_allosteric_labels => ['R', '.'],
	kf => "kon", 
	kb => koff_RA,
}
CanBindRule : {
	ligand_names => ['B', 'Ca'], 
	ligand_allosteric_labels => ['T', '.'],
	kf => "kon", 
	kb => koff_TB,
}
CanBindRule : {
	ligand_names => ['B', 'Ca'], 
	ligand_allosteric_labels => ['R', '.'],
	kf => "kon", 
	kb => koff_RB,
}
CanBindRule : {
	ligand_names => ['C', 'Ca'], 
	ligand_allosteric_labels => ['T', '.'],
	kf => "kon", 
	kb => koff_TC,
}
CanBindRule : {
	ligand_names => ['C', 'Ca'], 
	ligand_allosteric_labels => ['R', '.'],
	kf => "kon", 
	kb => koff_RC,
}
CanBindRule : {
	ligand_names => ['D', 'Ca'], 
	ligand_allosteric_labels => ['T', '.'],
	kf => "kon", 
	kb => koff_TD,
}
CanBindRule : {
	ligand_names => ['D', 'Ca'], 
	ligand_allosteric_labels => ['R', '.'],
	kf => "kon", 
	kb => koff_RD,
}

# Target binding to low-affinity T form
# n.b. setting the association rate to zero
# implements Stefan's et al.'s assumption that
# the target does not bind to the T form
CanBindRule : {
	ligand_names => ['T', 'CaMKII'], 
	ligand_allosteric_labels => ['T', '.'],
	kf => 0, 
	kb => 1,
}
CanBindRule : {
	ligand_names => ['T', 'PP2B'], 
	ligand_allosteric_labels => ['T', '.'],
	kf => 0, 
	kb => 1,
}
# Target binding to high-affinity R form
CanBindRule : {
	ligand_names => ['T', 'CaMKII'], 
	ligand_allosteric_labels => ['R', '.'],
	kf => kon_CaMKII, 
	kb => koff_CaMKII,
}
CanBindRule : {
	ligand_names => ['T', 'PP2B'], 
	ligand_allosteric_labels => ['R', '.'],
	kf => kon_PP2B, 
	kb => koff_PP2B,
}


#-----------------------------------------------------
# INIT
#-----------------------------------------------------
Init : {
	structure => CaMKII,
	IC => 7e-5,
}
Init : {
	structure => CAM,
	IC => 2e-7,
}
Init : {
	structure => Ca,
	IC => 0,
}

#-----------------------------------------------------
# STIMULUS
#-----------------------------------------------------
# To reproduce Fig. 3 of Stefan et al., uncomment the "ramp" stimulus
# below and type the following commands in Matlab. Providing the ramp
# is slow enough, this gives a reasonable approximation to the equilibrum
# response.
# > CaBound=p_CAM1 + 2*p_CAM2 + 3*p_CAM3 + 4*p_CAM4;
# > total_Ca = CaBound + Ca;
# > figure(1);plot(total_Ca, CaBound./2e-7)
# > (And change the x-axis to a logarithmic scale)
# > total_CAM=p_CAM0 + p_CAM1 + p_CAM2 + p_CAM3 + p_CAM4;
# > figure(2);plot(total_CAM);
# ramp up at 500s
Stimulus : {
	structure => 'Ca',
	type => "clamp",
	length => 1000,
	delay => 500,
	strength => 1000,
	concentration => "0.001*(t-500)/1000",
}

# Use this stimulus to get more accurate steady-state measurements
# fixed free Ca
#Stimulus : {
#	structure => 'Ca',
#	type => "clamp",
#	length => 1000,
#	delay => 10,
#	strength => 10,
#	concentration => "1e-6",
#}

#-----------------------------------------------------
# PROBES
#-----------------------------------------------------
Probe : {
	structure => Ca,
}

Probe : {
	name => "p_CAMR",
	classes => AllostericStructureInstance,
	filters => [
 		'$_->get_exported_name() =~ "CAM"',
 		'$_->get_allosteric_label() eq "R"',
        ],
}

Probe : {
	name => "p_CAMT",
	classes => AllostericStructureInstance,
	filters => [
 		'$_->get_exported_name() =~ "CAM"',
 		'$_->get_allosteric_label() eq "T"',
        ],
}

Probe : {
	name => "p_CAM0",
	classes => ComplexInstance,
	filters => [
 		'$_->get_exported_name() =~ "^CAM"',
 		'$_->get_exported_name() !~ "_Ca(?!M)"',
        ],
}
Probe : {
	name => "p_CAM1",
	classes => ComplexInstance,
	filters => [
 		'$_->get_exported_name() =~ "^CAM._Ca(?!M)(?!_Ca(?!M))"',
        ],
}
Probe : {
	name => "p_CAM2",
	classes => ComplexInstance,
	filters => [
 		'$_->get_exported_name() =~ "^CAM._Ca(?!M)_Ca(?!M)(?!_Ca(?!M))"',
        ],
}
Probe : {
	name => "p_CAM3",
	classes => ComplexInstance,
	filters => [
 		'$_->get_exported_name() =~ "^CAM._Ca(?!M)_Ca(?!M)_Ca(?!M)(?!_Ca(?!M))"',
        ],
}
Probe : {
	name => "p_CAM4",
	classes => ComplexInstance,
	filters => [
 		'$_->get_exported_name() =~ "^CAM._Ca(?!M)_Ca(?!M)_Ca(?!M)_Ca(?!M)(?!_Ca(?!M))"',
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

CONFIG:

t_vector = [0:0.1:tf]
matlab_odeset_options = odeset('AbsTol', 1e-15, 'RelTol', 1e-3)   # matlab options for odeset

t_final = 2000
