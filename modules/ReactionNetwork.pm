######################################################################################
# File:     ReactionNetwork.pm
# Author:   Julien F. Ollivier
#
# Copyright (C) 2005-2010 Julien Ollivier.
#
# This program comes with ABSOLUTELY NO WARRANTY.
# This is free software, and you are welcome to redistribute it
# under certain conditions. See file LICENSE.TXT for details.
#
# Synopsys: This module compiles a reaction network given an initial starting set
#           of species.
######################################################################################
# Detailed Description:
# ---------------------
# The initial set of species must be subclasses of the Species class, which has an
# attribute to keep track of new species generated during the network compilation
# process.
######################################################################################

use strict;
use diagnostics;		# equivalent to -w command-line switch
use warnings;

package ReactionNetwork;
use Class::Std::Storable;
use base qw();
{
    use Carp;
    use IO::Handle;

    use Utils;
    use Globals qw($verbosity $debug $sort_reactions_by_number);

    #######################################################################################
    # ATTRIBUTES
    #######################################################################################
    my %species_of :ATTR(get => 'species', set => 'species');
    my %reactions_of :ATTR(get => 'reactions', set => 'reactions');

    #######################################################################################
    # FUNCTIONS
    #######################################################################################

    #######################################################################################
    # CLASS METHODS
    #######################################################################################

    #######################################################################################
    # INSTANCE METHODS
    #######################################################################################
    #--------------------------------------------------------------------------------------
    # Function: START
    # Synopsys: 
    #--------------------------------------------------------------------------------------
    sub BUILD {
        my ($self, $obj_ID, $arg_ref) = @_;

	# initialize species, mark as NOT new
	$species_of{ident $self} = [];
	if (defined $arg_ref->{species}) {
	    foreach my $species_ref (@{$arg_ref->{species}}) {
		croak "ERROR: species supplied must inherit from Species class" if (!$species_ref->isa("Species"));
		push @{$species_of{ident $self}}, $species_ref;
		$species_ref->set_is_new_flag(0);
	    }
	}
	
	# initialize reactions
	$reactions_of{ident $self} = [];
    }

    sub START {
        my ($self, $obj_ID, $arg_ref) = @_;

	# check initializers
	croak "ERROR: species must be a list reference"   if (ref $species_of{ident $self}   ne "ARRAY");
	croak "ERROR: reactions must be a list reference" if (ref $reactions_of{ident $self} ne "ARRAY");
    }

    #--------------------------------------------------------------------------------------
    # Function: compile_network
    # Synopsys: 
    #------------------------ --------------------------------------------------------------
    sub compile_network {
	my $self = shift;

	# !!! below, should we sort the initial species list prior to processing ???

	my %args = (
	    # default values
	    UNARY_REACTION_TYPES => [],
	    BINARY_REACTION_TYPES => [],
	    MAX_EXTERNAL_ITERATIONS => -1,
	    MAX_INTERNAL_ITERATIONS => -1,
	    MAX_SPECIES => -1,
	    MAX_COMPLEX_SIZE => -1,
	    @_,
	   );

	check_args(\%args, 6);

	my $max_external_iterations = $args{MAX_EXTERNAL_ITERATIONS};
	my $max_species = $args{MAX_SPECIES};

	printn "ReactionNetwork::compile_network: starting..." if ($verbosity >= 1);

	if ($verbosity >= 2) {
	    printn "ReactionNetwork::compile_network: reporting initial species and nodes";
	    # report reaction sites
	    foreach my $species (@{$species_of{ident $self}}) {
		foreach my $node_instance (@{$species->get_node_instances()}) {
		    printn join " ", ($node_instance->get_species_ref()->get_name(),
				      join(",", @{$node_instance->get_site_address_ref()}),
				      $node_instance->get_site_ref()->get_name()
				     );
		}
	    }
	}

	# begin compilation
	my $initial_num_species = @{$species_of{ident $self}};
	my $first_new_internal = 0;
	my $first_new_external = 0;

	my $iteration = 0;

	NEW_SPECIES : while ($first_new_external <= $#{$species_of{ident $self}}) {
	    if (($iteration >= $max_external_iterations) && ($max_external_iterations > -1)) {
		printn "compile_network: reached maximum iterations ($max_external_iterations), exiting..." if $verbosity >= 1;
		last;
	    }
	    $iteration++;

#	    printn "ReactionNetwork::compile_network: STARTING INTERNAL iteration=$iteration total_species=".scalar(@{$species_of{ident $self}})." first_new_internal=$first_new_internal first_new_external=$first_new_external" if $verbosity >= 1;
	    printn "ReactionNetwork::compile_network: STARTING INTERNAL iteration=$iteration total_species=".scalar(@{$species_of{ident $self}}) if $verbosity >= 1;

	    #----------------------------------------------------------------
	    # compile internal interactions on new species
	    #----------------------------------------------------------------
	    $self->compile_internal_reactions(
		UNARY_REACTION_TYPES => $args{UNARY_REACTION_TYPES},
		BINARY_REACTION_TYPES => $args{BINARY_REACTION_TYPES},
		SPECIES_LIST_REF => [@{$species_of{ident $self}}[$first_new_internal..$#{$species_of{ident $self}}]],
		MAX_INTERNAL_ITERATIONS => $args{MAX_INTERNAL_ITERATIONS},
		MAX_SPECIES => $args{MAX_SPECIES},
	    );
	    $first_new_internal = @{$species_of{ident $self}};

	    # check to see if max number of species has been reached
	    last NEW_SPECIES if (($max_species != -1) && (@{$species_of{ident $self}} >= $max_species));

	    printn "ReactionNetwork::compile_network: STARTING EXTERNAL iteration=$iteration total_species=".scalar(@{$species_of{ident $self}}) if $verbosity == 1;
	    printn "ReactionNetwork::compile_network: STARTING EXTERNAL iteration=$iteration total_species=".scalar(@{$species_of{ident $self}})." first_new_internal=$first_new_internal first_new_external=$first_new_external" if $verbosity >= 2;

	    #----------------------------------------------------------------
	    # compile external interactions, all species with new species
	    #----------------------------------------------------------------
	    my $last_new_external = $#{$species_of{ident $self}};  # need to remember what last species was when we started
	    $self->compile_external_reactions(
		BINARY_REACTION_TYPES => $args{BINARY_REACTION_TYPES},
		SPECIES_LIST_REF => $species_of{ident $self},
		FIRST_NEW_EXTERNAL => $first_new_external,
		MAX_SPECIES => $args{MAX_SPECIES},
		MAX_COMPLEX_SIZE => $args{MAX_COMPLEX_SIZE},
	       );
	    $first_new_external = $last_new_external + 1;

	    printn "ReactionNetwork::compile_network: DONE EXTERNAL iteration=$iteration total_species=".scalar(@{$species_of{ident $self}}) if $verbosity == 1;
	    printn "ReactionNetwork::compile_network: DONE EXTERNAL iteration=$iteration total_species=".scalar(@{$species_of{ident $self}})." first_new_internal=$first_new_internal first_new_external=$first_new_external" if $verbosity >= 2;

	    # check to see if max number of species has been reached
	    last NEW_SPECIES if (($max_species != -1) && (@{$species_of{ident $self}} >= $max_species));

	}   # NEW_SPECIES

	if (($max_species != -1) && (@{$species_of{ident $self}} >= $max_species)) {
	    printn "WARNING: ReactionNetwork::compile_network -- max # of species ($max_species) reached!!!";
	} else {
	    #----------------------------------------------------------------
	    # finish by compiling all internal interactions on new species
	    #----------------------------------------------------------------
	    printn "ReactionNetwork::compile_network: STARTING FINAL-INTERNAL total_species=".scalar(@{$species_of{ident $self}}) if $verbosity == 1;
	    printn "ReactionNetwork::compile_network: STARTING FINAL-INTERNAL total_species=".scalar(@{$species_of{ident $self}})." first_new_internal=$first_new_internal first_new_external=$first_new_external" if $verbosity >= 2;
	    $self->compile_internal_reactions(
		UNARY_REACTION_TYPES => $args{UNARY_REACTION_TYPES},
		BINARY_REACTION_TYPES => $args{BINARY_REACTION_TYPES},
		SPECIES_LIST_REF => [@{$species_of{ident $self}}[$first_new_internal..$#{$species_of{ident $self}}]],
		MAX_INTERNAL_ITERATIONS => $args{MAX_INTERNAL_ITERATIONS},
		MAX_SPECIES => $args{MAX_SPECIES},
		);
	    $first_new_internal = @{$species_of{ident $self}};
	}
	
	# final stats
	my $new_species_count = @{$species_of{ident $self}} - $initial_num_species;
	printn "ReactionNetwork::compile_network: DONE FINAL-INTERNAL total_species=".scalar(@{$species_of{ident $self}}) if $verbosity == 1;
	printn "ReactionNetwork::compile_network: DONE FINAL-INTERNAL total_species=".scalar(@{$species_of{ident $self}})." new_species_count=$new_species_count, first_new_internal=$first_new_internal first_new_external=$first_new_external" if $verbosity >= 2;
	printn "ReactionNetwork::compile_network: Done computing species in $iteration iterations" if $verbosity >= 1;

	return scalar(@{$species_of{ident $self}});  # return total species
    }

    #--------------------------------------------------------------------------------------
    # Function: compile_external_reactions
    # Synopsys: Compile reactions involving two distinct (though possibly
    #           identical) Species.
    #--------------------------------------------------------------------------------------
    my %node_instance_cache;  # cache to save results of get_node_instances() calls
    sub compile_external_reactions {
	my $self = shift;
	my %args = (
	    # default values
	    BINARY_REACTION_TYPES => [],
	    SPECIES_LIST_REF => [],
	    FIRST_NEW_EXTERNAL => undef,
	    MAX_SPECIES => -1,
	    MAX_COMPLEX_SIZE => -1,
	    @_,
	   );

	check_args(\%args, 5);

	my @binary_reaction_types = @{$args{BINARY_REACTION_TYPES}};
	my @species_list = @{$args{SPECIES_LIST_REF}};
	my $first_new_external = $args{FIRST_NEW_EXTERNAL};
	my $max_species = $args{MAX_SPECIES};
	my $max_complex_size = $args{MAX_COMPLEX_SIZE};

	# check to see if max number of species has been reached
	if (($max_species != -1) && (@{$species_of{ident $self}} >= $max_species)) {
	    printn "WARNING: ReactionNetwork::compile_external_reactions -- max # of species ($max_species) reached!!!";
	    return;
	}

	my $last_new_external = $#species_list;


	# here we retrieve/unpack much of the information that will be needed later,
	# so that the inner loops and NEW() calls won't have to do this repeatedly at
	# each iteration
	my @L_species = map {
	    my $species_ref = $species_list[$_];
	    my $species_ID = ident $species_ref;
	    my @site_info_refs = (defined $node_instance_cache{$species_ID} ?	    # get ReactionSites from cache if possible
			 @{$node_instance_cache{$species_ID}} :
			 @{$node_instance_cache{$species_ID} = $species_ref->get_node_instances()});
	    @site_info_refs = grep {!($_->get_site_ref()->get_static_flag())} @site_info_refs;          # skip static reaction sites
	    @site_info_refs = grep {$_->get_site_ref()->get_reaction_type() eq 'B'} @site_info_refs;    # binary reaction sites only
	    my @site_address_refs = map {$_->get_site_address_ref()} @site_info_refs;
	    my @site_refs = map {$_->get_site_ref()} @site_info_refs;
	    [$species_ref, $species_ref->get_name(),
	     \@site_info_refs, \@site_address_refs, \@site_refs];  # return value
	} (0..$#species_list);

	my $num_L_species = @L_species;
	L_SPECIES : for (my $i=0; $i < $num_L_species; $i++) {
	    my $L_species_ref = $L_species[$i]->[0];
	    my $L_species_name = $L_species[$i]->[1];
	    my @L_info_refs = @{$L_species[$i]->[2]};
	    my @L_site_address_refs = @{$L_species[$i]->[3]};
	    my @L_site_refs = @{$L_species[$i]->[4]};
	    # for the R list, don't need to redo old with old
	    my @R_species = (($i > $first_new_external) ?
			     @L_species[$i..$last_new_external] :
			     @L_species[$first_new_external..$last_new_external]
			    );

	    if ($verbosity >= 1) {
		if ($i != 0 && ($i % 5) == 0) {
		    printn "ReactionNetwork::compile_external_reactions: processing species $i of $num_L_species";
		}
	    }

	    my $num_L_sites = @L_site_refs;
	    L_NODE_INSTANCES : for (my $ii=0; $ii < $num_L_sites; $ii++) {
		my $L_info_ref = $L_info_refs[$ii];
		my $L_site_address_ref = $L_site_address_refs[$ii];
		my $L_site_ref = $L_site_refs[$ii];
		my $num_R_species = @R_species;
		R_SPECIES : for (my $j=0; $j < $num_R_species; $j++) {
		    my $R_species_ref = $R_species[$j]->[0];
		    my $R_species_name = $R_species[$j]->[1];
		    my @R_info_refs = @{$R_species[$j]->[2]};
		    my @R_site_address_refs = @{$R_species[$j]->[3]};
		    my @R_site_refs = @{$R_species[$j]->[4]};
		    my $num_R_sites = @R_site_refs;
		    R_NODE_INSTANCES : for (my $jj=0; $jj < $num_R_sites; $jj++) {
			my $R_info_ref = $R_info_refs[$jj];
			my $R_site_address_ref = $R_site_address_refs[$jj];
			my $R_site_ref = $R_site_refs[$jj];
			if ($verbosity >= 2) {
			    my $L_name = $L_species_ref->get_exported_name();
			    my $R_name = $R_species_ref->get_exported_name();
			    my @L_address = @{$L_info_ref->get_site_address_ref()};
			    my @R_address = @{$R_info_ref->get_site_address_ref()};
			    printn "ReactionNetwork::compile_external_reactions: NEW-EXTERNAL --> $L_name(@L_address) <-?-> $R_name(@R_address)";
			}
			my (@reaction_list, $reaction_ref);
		      BINARY_REACTION: foreach my $reaction_type (@binary_reaction_types) {
			    printn "ReactionNetwork::compile_external_reactions: trying $reaction_type" if $verbosity >= 2;
			    $reaction_ref = $reaction_type->NEW(
				"R",   # reaction name
				$L_info_ref,
				$L_species_ref,
				$L_species_name,
				$L_site_address_ref,
				$L_site_ref,
				$R_info_ref,
				$R_species_ref,
				$R_species_name,
				$R_site_address_ref,
				$R_site_ref,
				0,                        # internal_flag
				1,                        # association_flag
				0,                        # internal_association_flag
				$max_complex_size,        # max_complex_size
				$reaction_ref,            # last_reaction_ref
			       );
			    push @reaction_list, $reaction_ref if defined $reaction_ref;
			}
		
			foreach my $reaction_ref (@reaction_list) {
			    # push reaction onto reaction list
			    push @{$reactions_of{ident $self}}, $reaction_ref;

			    # push any new species created onto species list
			    foreach my $new_species_ref ($reaction_ref->get_new_species()) {
				push @{$species_of{ident $self}}, $new_species_ref;
				$new_species_ref->set_is_new_flag(0);
			
				if ($verbosity >= 1) {
				    if ((@{$species_of{ident $self}} % 20) == 0) {
					printn "ReactionNetwork::compile_external_reactions: total_species=".scalar(@{$species_of{ident $self}});
				    }
				}
			    }

			    # check to see if max number of species has been reached
			    if (($max_species != -1) && (@{$species_of{ident $self}} >= $max_species)) {
				printn "WARNING: ReactionNetwork::compile_external_reactions -- max # of species ($max_species) reached!!!";
				last L_SPECIES;
			    }
			}
		    }
		}
	    }
	}
    }

    sub compile_internal_reactions {
	my $self = shift;
	my %args = (
	    # default values
	    UNARY_REACTION_TYPES => [],
	    BINARY_REACTION_TYPES => [],
	    SPECIES_LIST_REF => [],
	    MAX_INTERNAL_ITERATIONS => -1,
	    MAX_SPECIES => -1,
	    ITERATION => 0,   # keep track of recursive calls
	    @_,
	   );

	check_args(\%args, 6);

	my @unary_reaction_types = @{$args{UNARY_REACTION_TYPES}};
	my @binary_reaction_types = @{$args{BINARY_REACTION_TYPES}};
	my $iteration = $args{ITERATION};
	my $max_internal_iterations = $args{MAX_INTERNAL_ITERATIONS};
	my $max_species = $args{MAX_SPECIES};
	my $max_species_reached_flag = 0;

	$iteration++;
	if (($iteration > $max_internal_iterations) && ($max_internal_iterations > -1)) {
	    printn "ReactionNetwork::compile_internal_reactions: reached maximum iterations ($max_internal_iterations), exiting..." if $verbosity >= 1;
	    return ();
	}

	my @species_list = @{$args{SPECIES_LIST_REF}};
	my @new_species_list = ();

	my $species_exported_name = undef;

	my $num_species = @species_list;
	SPECIES : for (my $i=0; $i < $num_species; $i++) {
	    my $species_ref = $species_list[$i];
	    my $species_name = $species_ref->get_name();
	    my $species_exported_name = $species_ref->get_exported_name() if $verbosity >= 2;
	    my $species_ID = ident $species_ref;
	    my @node_instances = (defined $node_instance_cache{$species_ID} ?	    # get ReactionSites from cache if possible
				  @{$node_instance_cache{$species_ID}} :
				  @{$node_instance_cache{$species_ID} = $species_ref->get_node_instances()});

	    if ($verbosity >= 1) {
		if ($i != 0 && ($i % 20) == 0) {
		    printn "ReactionNetwork::compile_internal_reactions: processing species $i of $num_species";
		}
	    }

	    my $num_node_instances = @node_instances;
	    for (my $j=0; $j < $num_node_instances; $j++) {
		my $L_node_instance = $node_instances[$j];
		my $L_site_address_ref = $L_node_instance->get_site_address_ref();
		my $L_site_ref = $L_node_instance->get_site_ref();
		next if ($L_site_ref->get_static_flag());	        # skip static reaction sites
	      UNARY_BLOCK: {
		    last UNARY_BLOCK if ($L_site_ref->get_reaction_type() ne 'U');  # unary reaction sites only
		    if ($verbosity >= 2) {
			my @L_address = @{$L_site_address_ref};
			printn "ReactionNetwork::compile_internal_reactions NEW-INTERNAL (UNARY) --> $species_exported_name(@L_address)";
		    }
		    my @unary_reaction_list;
		  UNARY_REACTION: foreach my $reaction_type (@unary_reaction_types) {
			printn "ReactionNetwork::compile_internal_reactions: trying unary $reaction_type" if $verbosity >= 2;
			my $unary_reaction_ref = $reaction_type->NEW({
			    name => "R",
			    S_info_ref => $L_node_instance,
			});
			push @unary_reaction_list, $unary_reaction_ref if defined $unary_reaction_ref;
		    }
		    foreach my $unary_reaction_ref (@unary_reaction_list) {
			# push reaction onto reaction list
			push @{$reactions_of{ident $self}}, $unary_reaction_ref;
			# push any new species created onto list
			foreach my $new_species_ref ($unary_reaction_ref->get_new_species()) {
			    push @{$species_of{ident $self}}, , $new_species_ref;
			    push @new_species_list, $new_species_ref;
			    $new_species_ref->set_is_new_flag(0);

			    if ((@{$species_of{ident $self}} % 20) == 0) {
				printn "ReactionNetwork::compile_internal_reactions: total_species=".scalar(@{$species_of{ident $self}}) if $verbosity >= 1;
			    }
			}
			# check to see if max number of species has been reached
			if (($max_species != -1) && (@{$species_of{ident $self}} >= $max_species)) {
			    printn "WARNING: compile_internal_reactions -- max # of species ($args{MAX_SPECIES}) reached!!!";
			    last SPECIES;
			}
		    }
		}

	      BINARY_BLOCK: {
		    last BINARY_BLOCK if ($L_site_ref->get_reaction_type() ne 'B'); # binary reaction sites only
		    for (my $k=($j+1); $k < $num_node_instances; $k++) { # k=j+1 because a site can't interact with itself
			my $R_node_instance = $node_instances[$k];
			my $R_site_address_ref = $R_node_instance->get_site_address_ref();
			my $R_site_ref = $R_node_instance->get_site_ref();
			next if ($R_site_ref->get_static_flag());	        # skip static reaction sites
			next if ($R_site_ref->get_reaction_type() ne 'B');	# binary reaction sites only
			printn "ReactionNetwork::compile_internal_reactions NEW-INTERNAL (BINARY) --> $species_exported_name(@$L_site_address_ref, @$R_site_address_ref)" if $verbosity >= 2;
			my (@binary_reaction_list, $binary_reaction_ref);
		      BINARY_REACTION: foreach my $reaction_type (@binary_reaction_types) {
			    printn "ReactionNetwork::compile_internal_reactions: trying binary $reaction_type" if $verbosity >= 2;
			    # CHECK IF THE SITES ARE ALREADY ASSOCIATED TO EACH OTHER
			    my $association_flag = (@{$species_ref->get_edges(':',$L_site_address_ref, $R_site_address_ref)} ? 0 : 1);
			    my $internal_association_flag = $association_flag ? 1 : undef;  # undef if dissociation, meaning we don't know
			    $binary_reaction_ref = $reaction_type->NEW(
				"R",  # reaction name
				$L_node_instance,
				$species_ref,
				$species_name,
				$L_site_address_ref,
				$L_site_ref,
				$R_node_instance,
				$species_ref,
				$species_name,
				$R_site_address_ref,
				$R_site_ref,
				1,                            # internal_flag
				$association_flag,            # association_flag
				$internal_association_flag,   # internal_association_flag
				undef,                        # max_complex_size
				$binary_reaction_ref,         # last_reaction_ref
			    );
			    push @binary_reaction_list, $binary_reaction_ref if defined $binary_reaction_ref;
			}

			foreach my $binary_reaction_ref (@binary_reaction_list) {
			    # push reaction onto reaction list
			    push @{$reactions_of{ident $self}}, $binary_reaction_ref;
			    # push any new species created onto list
			    foreach my $new_species_ref ($binary_reaction_ref->get_new_species()) {
				push @{$species_of{ident $self}}, , $new_species_ref;
				push @new_species_list, $new_species_ref;
				$new_species_ref->set_is_new_flag(0);

				if ((@{$species_of{ident $self}} % 20) == 0) {
				    printn "ReactionNetwork::compile_internal_reactions: total_species=".scalar(@{$species_of{ident $self}}) if $verbosity >= 1;
				}
			    }
			    # check to see if max number of species has been reached
			    if (($max_species != -1) && (@{$species_of{ident $self}} >= $max_species)) {
				printn "WARNING: compile_internal_reactions -- max # of species ($args{MAX_SPECIES}) reached!!!";
				$max_species_reached_flag = 1;
				last SPECIES;
			    }
			}
		    }
		}
	    }
	}

	# for all new species created, recursively compile internal interactions for those
	if (@new_species_list != 0 && !$max_species_reached_flag) {
	    push @new_species_list, $self->compile_internal_reactions(
		UNARY_REACTION_TYPES => $args{UNARY_REACTION_TYPES},
		BINARY_REACTION_TYPES => $args{BINARY_REACTION_TYPES},
		SPECIES_LIST_REF => \@new_species_list,
		MAX_INTERNAL_ITERATIONS => $max_internal_iterations,
		MAX_SPECIES => $max_species,
		ITERATION => $iteration,
	       );
	}

	# return the new species created
	return @new_species_list;
    }

    #--------------------------------------------------------------------------------------
    # Function: export_facile
    # Synopsys: 
    #--------------------------------------------------------------------------------------
    sub export_facile {
	my $self = shift;
	my %args = (
	    REACTION_TYPES => undef,
	    @_
	);

	check_args(\%args, 1);

	my @export = ();

	my @reaction_refs = @{$self->get_reactions()};

	foreach my $reaction_class (@{$args{REACTION_TYPES}}) {
	    my @filtered_reaction_refs = grep {ref $_ eq $reaction_class} @reaction_refs;

	    if (@filtered_reaction_refs) {
		my $temp = "\n# REACTION CLASS: $reaction_class\n";
		push @export, $temp;
		push @export, "# ".("-" x (length($temp)-4))."\n";

		# sort according to cmp function of reaction class
		my @export_list = ($sort_reactions_by_number ?
				   @filtered_reaction_refs :
				   sort {$reaction_class->cmp($a, $b)} @filtered_reaction_refs);
		foreach my $reaction_ref (@export_list) {
		    if (!$reaction_ref->get_exported_flag()) {
			push @export, $reaction_ref->export_equations();
			$reaction_ref->set_exported_flag(1);
		    }
		}
	    }
	}
	return \@export;
    }

    #--------------------------------------------------------------------------------------
    # Function: export_graphviz
    # Synopsys: Generate graph for reaction network.  Arguments allow user to collapse
    #           the reaction network to hide the multiplicity of complexes and states.
    #           Nodes without any edges are not displayed.
    #--------------------------------------------------------------------------------------
    # Detailed Description:  The ultimate purpose of this function is to display the
    # equation file graphically.  If neither states nor complexes are collapsed, then
    # each arrow in the eqn file should have a matching arrow in the graph.  If collapsing
    # complexes, then we must merge sets of reactions that occur repeatedly in different
    # complexes, but that in fact involve the same proteins and sites.  We must similarly
    # merge reactions when collapsing states.
    #--------------------------------------------------------------------------------------
    sub export_graphviz {
 	my $self = shift; my $obj_ID = ident $self;
 	my %args = (
 	    REACTION_TYPES => ["CatalyticReaction", "BindingReaction"],
	    COLLAPSE_COMPLEXES => 1,
	    COLLAPSE_STATES => 1,
	    HIGHLIGHT_ALLOSTERY => 0,
 	    FILENAME => undef,
 	    @_
 	);
 	check_args(\%args, 5);
	my $collapse_complexes = $args{COLLAPSE_COMPLEXES};
	my $collapse_states = $args{COLLAPSE_STATES};
	my $highlight_allostery = $args{HIGHLIGHT_ALLOSTERY};

	eval "use GraphViz";
	if ($@) {    # in case GraphViz is not present
	    printn "WARNING: GraphViz is not properly installed, cannot export Graph objects...";
	    print $@ if $verbosity >= 2;
	    return;
	}

	my $gv_ref = GraphViz->new(directed => 1);

	my %nodes;
	
	# we use the %edges hash to store edges already created.
	# this is necessary to avoid duplication when collapsing complexes and states
	my %edges;

	my @reaction_refs = @{$self->get_reactions()};
 	foreach my $reaction_class (@{$args{REACTION_TYPES}}) {
 	    my @filtered_reaction_refs = grep {ref $_ eq $reaction_class} @reaction_refs;
 	    foreach my $reaction_ref (@filtered_reaction_refs) {
		my ($L_info_ref, $R_info_ref);
		if ($reaction_class eq "CatalyticReaction") {
		    $L_info_ref = $reaction_ref->get_qE_info_ref();
		    $R_info_ref = $reaction_ref->get_qP_info_ref();
		} elsif ($reaction_class eq "BindingReaction") {
		    $L_info_ref = $reaction_ref->get_dL_info_ref();
		    $R_info_ref = $reaction_ref->get_dR_info_ref();
		} elsif ($reaction_class eq "AllostericReaction") {
		    $L_info_ref = $reaction_ref->get_S_info_ref();
		    $R_info_ref = $reaction_ref->get_P_info_ref();
		} else {
		    confess "ERROR: not implemented ($reaction_class)";
		}

		my $L_species_ref = $L_info_ref->get_species_ref();
		my @L_address = @{$L_info_ref->get_site_address_ref()};
		my $L_site_ref = $L_info_ref->get_site_ref();

		my $R_species_ref = $R_info_ref->get_species_ref();
		my @R_address = @{$R_info_ref->get_site_address_ref()};
		my $R_site_ref = $R_info_ref->get_site_ref();

		my ($L_ref, $R_ref);
		if ($collapse_complexes) {
		    # use top-level Structure
		    $L_ref = $L_species_ref->get_element($L_address[0]);
		    $R_ref = $R_species_ref->get_element($R_address[0]);
		    @L_address = @L_address[1..$#L_address];
		    @R_address = @R_address[1..$#R_address];
		} else {
		    # use Complex nodes
		    $L_ref = $L_species_ref;
		    $R_ref = $R_species_ref;
		    # replace msb with label
		    $L_address[0] = $L_species_ref->get_parent_ref()->get_element($L_address[0])->get_name();
		    $R_address[0] = $R_species_ref->get_parent_ref()->get_element($R_address[0])->get_name();
		}
		my ($L_name, $R_name);
		if ($collapse_states) {
		    #                               Structure                              Complex
		    $L_name = $collapse_complexes ? $L_ref->get_parent_ref()->get_name() : $L_ref->get_parent_ref()->get_exported_name();
		    $R_name = $collapse_complexes ? $R_ref->get_parent_ref()->get_name() : $R_ref->get_parent_ref()->get_exported_name();
		} else {
		    #                               StructureInstance                      ComplexInstance
		    $L_name = $collapse_complexes ? $L_ref->get_exported_name()          : $L_ref->get_exported_name();
		    $R_name = $collapse_complexes ? $R_ref->get_exported_name()          : $R_ref->get_exported_name();
		}
		my $L_address = join ".", @L_address;
		my $R_address = join ".", @R_address;

		$gv_ref->add_node("$L_name", label => "$L_name") if (!defined $nodes{$L_name});
		$nodes{$L_name} = 1;
		$gv_ref->add_node("$R_name", label => "$R_name") if (!defined $nodes{$R_name});
		$nodes{$R_name} = 1;

		if ($reaction_class eq "CatalyticReaction") {
		    if (!defined $edges{$L_name}{$R_name}{$reaction_class}{$L_address}{$R_address}) {
			$edges{$L_name}{$R_name}{$reaction_class}{$L_address}{$R_address} = 1;
			$gv_ref->add_edge($L_name => $R_name,
					  dir => "forward",
					  taillabel => $L_address, headlabel => $R_address,
					  labeldistance => 1.0, labelangle => 45, labelfontsize => 6,
					  color => ($R_info_ref->get_site_ref()->get_msite_state() ? "red" : "blue"),
					 );
		    }
		} elsif ($reaction_class eq "BindingReaction") {
		    if (!defined $edges{$L_name}{$R_name}{$reaction_class}{$L_address}{$R_address}) {
			$edges{$L_name}{$R_name}{$reaction_class}{$L_address}{$R_address} = 1;
			$edges{$R_name}{$L_name}{$reaction_class}{$R_address}{$L_address} = 1;
			my $L_allosteric_flag = ($highlight_allostery &&
						 $L_site_ref->get_in_set()->get_allosteric_flag());
			my $R_allosteric_flag = ($highlight_allostery &&
						 $R_site_ref->get_in_set()->get_allosteric_flag());
			$gv_ref->add_edge($L_name => $R_name,
					  dir => "none",
					  labeldistance => 1.0, labelangle => 45, labelfontsize => 6,
					  taillabel => $L_address.($L_allosteric_flag ? "*" : ""),
					  headlabel => $R_address.($R_allosteric_flag ? "*" : ""),
					  color => ($L_allosteric_flag||$R_allosteric_flag) ? "darkgreen" : "black",
					 );
		    }
		} elsif  ($reaction_class eq "AllostericReaction") {
		    my $dir = "both";
		    $dir = "forward" if $reaction_ref->get_is_duplicate_backward_reaction_flag();
		    $dir = "backward" if $reaction_ref->get_is_duplicate_forward_reaction_flag();
		    if ($collapse_states) {
			#printn "XXX0 ".$L_ref->get_exported_name()."($L_address) ".$R_ref->get_exported_name."($R_address) $dir";

			# since we are collapsing states, we just want a double arrow for each allosteric site
			# hence, we store one edge per address, as opposed to per address pairs
			# (this is true whether we are collapsing complexes or not)
			if (!defined $edges{$L_name}{$L_name}{$reaction_class}{$L_address}{$L_address}) {
			    $edges{$L_name}{$L_name}{$reaction_class}{$L_address}{$L_address} = 1;
			    $gv_ref->add_edge($L_name => $L_name,
					      dir => "$dir",
					      labeldistance => 1.0, labelangle => 45, labelfontsize => 6,
					      taillabel => $L_address,
					      headlabel => $L_address,
					      color => "darkgreen",
					     );
			}
			if (!defined $edges{$R_name}{$R_name}{$reaction_class}{$R_address}{$R_address}) {
			    $edges{$R_name}{$R_name}{$reaction_class}{$R_address}{$R_address} = 1;
			    $gv_ref->add_edge($R_name => $R_name,
					      dir => "$dir",
					      labeldistance => 1.0, labelangle => 45, labelfontsize => 6,
					      taillabel => $R_address,
					      headlabel => $R_address,
					      color => "darkgreen",
					     );
			}
		    } else {
			# in this case, draw an arrow between the species, and show degenerate reactions
			if (!defined $edges{$L_name}{$R_name}{$reaction_class}{$L_address}{$R_address} ||
			    !defined $edges{$R_name}{$L_name}{$reaction_class}{$R_address}{$L_address}
			   ) {
			    $edges{$L_name}{$R_name}{$reaction_class}{$L_address}{$R_address} = 1 if $dir eq "both" || $dir eq "forward";
			    $edges{$R_name}{$L_name}{$reaction_class}{$R_address}{$L_address} = 1 if $dir eq "both" || $dir eq "backward";

			    #printn "XXX1 ".$L_ref->get_exported_name()."($L_address) ".$R_ref->get_exported_name."($R_address) $dir";
			    $gv_ref->add_edge($L_name => $R_name,
					      dir => "$dir",
					      labeldistance => 1.0, labelangle => 45, labelfontsize => 6,
					      taillabel => $L_address,
					      headlabel => $R_address,
					      color => "darkgreen",
					     );
			}
		    }
		} else {
		    confess "ERROR: not implemented ($reaction_class)";
		}
 	    }
 	}

	my $basename = $args{FILENAME};
	my $ext = "svg";
	if ($basename =~ /(.*)\.(\w+)$/) {
	    $basename = $1;
	    $ext = $2;
	}
	my $type = $ext eq "jpg" ? "jpeg" : $ext;

	eval "\$gv_ref->as_$type(\"${basename}.$ext\")";
	if ($@) {
	    printn $@;
	    die "ERROR: unsupported format -- $type" ;
	}
    }
}


sub run_testcases {
    printn "NO TESTCASES!!!";
}


# Package BEGIN must return true value
return 1;

