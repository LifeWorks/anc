# Generic ligand-induced receptor dimerization, with ad-hoc regulation.
# Dimerization occurs at different rates depending on whether the receptor
# monomers are both liganded or not.

###################################
MODEL:
###################################

#-----------------------------------------------------
# Compile Parameters
#-----------------------------------------------------
$max_species = -1;

#-----------------------------------------------------
# Model Parameters
#-----------------------------------------------------
# (none)

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

Structure : {
  name => "R",
  elements => ["LB", "D"],
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

# ligand-receptor binding occurs only when receptor is not dimerized
CanBindRule : {
  ligand_names => ['L', 'LB'], 
  kf => 10.0, 
  kb => 1.0,
#  constraints => [
#    '!defined $R->get_right_node()->get_ligand()',
#  ],
}

# OPTIONAL: receptor dimerization rates for unliganded or partially liganded dimer
CanBindRule : {
  ligand_names => ['D', 'D'],
  kf => 0.01,
  kb => 20.0,
  constraints => [
    '!defined $R->get_left_node()->get_ligand() || !defined $L->get_left_node()->get_ligand()',
  ],
}


# receptor dimerization for full ligand occupancy
CanBindRule : {
  ligand_names => ['D', 'D'],
  kf => 30,
  kb => 0.2,
  constraints => [
    'defined $R->get_left_node()->get_ligand() && defined $L->get_left_node()->get_ligand()',
  ],
}

