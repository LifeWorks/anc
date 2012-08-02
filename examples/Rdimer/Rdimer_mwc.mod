# Generic ligand-induced receptor dimerization, with MWC-type model.
# Based on the model for EGFR receptor dimerization of Ozcan et al.
# Dimerization occurs at different rates depending on the receptor
# monomer conformation. Dimerization occurs cooperatively with ligand
# binding.  Parameter values are illustrative and do not correspond
# to an experimental situation.
#
# References: On the nature of low- and high-affinity EGF receptors
# on living cells. Ozcan F, Klein P, Lemmon MA, Lax I, Schlessinger J.
# Proc Natl Acad Sci U S A. 2006 Apr 11;103(15):5735-40.
# Epub 2006 Mar 29. 
#

######################################################
MODEL:
######################################################

#-----------------------------------------------------
# Compile Parameters
#-----------------------------------------------------
$max_species = -1;

#-----------------------------------------------------
# Model Parameters
#-----------------------------------------------------
# ligand-receptor binding
Parameter : {name => 'kf_LI', value => 5.0}
Parameter : {name => 'kb_LI', value => 1.0}
Parameter : {name => 'kf_LA', value => 500.0}
Parameter : {name => 'kb_LA', value => 1.0}

# receptor allostery
Parameter : {name => 'k_IA', value => 1.0}
Parameter : {name => 'k_AI', value => 100.0}
Parameter : {name => 'Phi_IA', value => 0.5}

# receptor dimerization
Parameter : {name => 'kf_II', value => 1.0}
Parameter : {name => 'kb_II', value => 100.0}
Parameter : {name => 'kf_IA', value => 1.0}
Parameter : {name => 'kb_IA', value => 1.0}
Parameter : {name => 'kf_AA', value => 100.0}
Parameter : {name => 'kb_AA', value => 1.0}

#-----------------------------------------------------
# Receptor
#-----------------------------------------------------
ReactionSite : {
  name => "LB",   # ligand-binding site
  type => "bsite",
}

ReactionSite : {
  name => "D",  # dimerization site
  type => "bsite",
}

AllostericStructure : {
  name => "R",
  elements => ["LB", "D"],
  allosteric_transition_rates => [k_IA, k_AI],
  allosteric_state_labels => ['I', 'A'], # inactive, active 
  Phi => Phi_IA,
}

#-----------------------------------------------------
# Ligand
#-----------------------------------------------------
ReactionSite : {
  name => "L",
  type => "bsite",
}

Structure : {
  name => "L",
  elements => ["L"],
}

#-----------------------------------------------------
# Rules
#-----------------------------------------------------

# ligand-receptor binding
CanBindRule : {
  ligand_names => ['L', 'LB'], 
  ligand_allosteric_labels => ['.', 'I'],
  kf => kf_LI, 
  kb => kb_LI,
}
CanBindRule : {
  ligand_names => ['L', 'LB'], 
  ligand_allosteric_labels => ['.', 'A'],
  kf => kf_LA, 
  kb => kb_LA,
}

# receptor dimerization
CanBindRule : {
  ligand_names => ['D', 'D'],
  ligand_allosteric_labels => ['I', 'I'],
  kf => kf_II,
  kb => kb_II,
}
CanBindRule : {
  ligand_names => ['D', 'D'],
  ligand_allosteric_labels => ['I', 'A'],
  kf => kf_IA,
  kb => kb_IA,
}
CanBindRule : {
  ligand_names => ['D', 'D'],
  ligand_allosteric_labels => ['A', 'A'],
  kf => kf_AA,
  kb => kb_AA,
}

#-----------------------------------------------------
# Init
#-----------------------------------------------------
Init : {
	structure => R,
	IC => 1.0,
}

#-----------------------------------------------------
# Stimulus
#-----------------------------------------------------
Stimulus : {
	structure => 'L',
	type => "clamp",
	length => 10000,
	delay => 5000,
	strength => 1000,
	concentration => "0.04*(t-5000)/1000",
}

#-----------------------------------------------------
# Probes
#-----------------------------------------------------

Probe : {
	name => "MONOMER_L0",
	classes => ComplexInstance,
	filters => [
 		'$_->get_exported_name() =~ /R/',
 		'$_->get_num_elements() == 1',
        ],
}

Probe : {
	name => "MONOMER_L1",
	classes => ComplexInstance,
	filters => [
 		'$_->get_exported_name() =~ /L.*R/',
 		'$_->get_num_elements() == 2',
        ],
}

Probe : {
	name => "DIMER_L0",
	classes => ComplexInstance,
	filters => [
 		'$_->get_exported_name() =~ /R.*R/',
 		'$_->get_num_elements() == 2',
        ],
}

Probe : {
	name => "DIMER_L1",
	classes => ComplexInstance,
	filters => [
 		'$_->get_num_elements() == 3',
        ],
}

Probe : {
	name => "DIMER_L2",
	classes => ComplexInstance,
	filters => [
 		'$_->get_num_elements() == 4',
        ],
}

Probe : {
	name => "DIMER_ACTIVE",
	classes => ComplexInstance,
	filters => [
 		'$_->get_exported_name() =~ "RA.*RA"',
        ],
}

Probe : {
	structure => L,
}

######################################################
CONFIG:
######################################################

t_vector = [t0:0.1:tf]

# MATLAB commands for Scatchard plots:
# range = (51000:150001);  # when at small concentrations, system does not reach steady-state
# (with dimerization)
# bound = (MONOMER_L1 + DIMER_L1 + 2*DIMER_L2) / 1.0; figure(1); plot(bound(range), bound(range) ./ L(range));
# (no dimerization)
# bound = (MONOMER_L1) / 1.0; figure(1); plot(bound(range), bound(range) ./ L(range));

