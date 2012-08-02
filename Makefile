######################################################################################
# File:     Makefile
# Author:   Julien F. Ollivier
#
# Copyright (C) 2005-2011 Julien Ollivier.
#
# This program comes with ABSOLUTELY NO WARRANTY.
# This is free software, and you are welcome to redistribute it
# under certain conditions. See file LICENSE.TXT for details.
#
# Synopsys: Allosteric Network Compiler (ANC) makefile.  Runs tests and examples.
######################################################################################
#  Detailed Description:
#  ---------------------
######################################################################################

######################################################################################
# SETUP
######################################################################################
ANC_HOME = .
ANC_CMD = $(ANC_HOME)/anc.pl --clean
ANC_PROF_CMD = perl -d:DProf $(ANC_HOME)/anc.pl

FACILE_CMD = $(FACILE_HOME)/facile.pl

DIFF_CMD = tkdiff
#DIFF_CMD = diff
#DIFF_CMD = 'tkdiff "-I Copyright -I Version -I Release -I Start -I End"'

do_nothing:
	@echo "To make a tarball, try 'make tarball'"
	@echo "To run all testcases, try 'make test'"
	@echo "To fix permissions, try 'make read_permissions' or 'make write_permissions'"

RELEASE = RELEASE_1V01

RELEASE_FILES = \
	anc-logo.png \
	COPYRIGHT.TXT \
	README.TXT \
	RELEASE_HISTORY.TXT \
	LICENSE.TXT \
	Makefile \
	anc.pl \
	base/ClassData.pm \
	base/CmdLineOptions.pm \
	base/ComponentInstance.pm \
	base/Component.pm \
	base/Infinity.pm \
	base/Instance.pm \
	base/Instantiable.pm \
	base/Matrix.pm \
	base/Named.pm \
	base/Null.pm \
	base/ObjectTemplateInstance.pm \
	base/ObjectTemplate.pm \
	base/Registered.pm \
	base/SetElement.pm \
	base/SetInstance.pm \
	base/Set.pm \
	base/Utils.pm \
	modules/AllostericReaction.pm \
	modules/AllostericSiteInstance.pm \
	modules/AllostericSite.pm \
	modules/AllostericStructureInstance.pm \
	modules/AllostericStructure.pm \
	modules/BinaryReaction.pm \
	modules/BinaryRuleInstance.pm \
	modules/BinaryRule.pm \
	modules/BindingReaction.pm \
	modules/CanBindRuleInstance.pm \
	modules/CanBindRule.pm \
	modules/CatalyticReaction.pm \
	modules/CompileModel.pm \
	modules/ComplexInstance.pm \
	modules/Complex.pm \
	modules/ElementaryReaction.pm \
	modules/Facile.pm \
	modules/Filter.pm \
	modules/Globals.pm \
	modules/GraphInstance.pm \
	modules/Graph.pm \
	modules/GraphSet.pm \
	modules/HiGraphInstance.pm \
	modules/HiGraph.pm \
	modules/Init.pm \
	modules/LoadModules.pm \
	modules/ModelParser.pm \
	modules/NodeInstance.pm \
	modules/Node.pm \
	modules/Parameter.pm \
	modules/Probe.pm \
	modules/ReactionNetwork.pm \
	modules/Reaction.pm \
	modules/ReactionSiteInstance.pm \
	modules/ReactionSite.pm \
	modules/RegisteredGraph.pm \
	modules/Rule.pm \
	modules/Selector.pm \
	modules/SiteInfo.pm \
	modules/Species.pm \
	modules/Stimulus.pm \
	modules/StructureInstance.pm \
	modules/Structure.pm \
	modules/UnaryReaction.pm \
	modules/Variable.pm \
	\
	examples/matlab/get_samples.m \
	\
	examples/adaptor/adaptor_generic.mod \
	examples/adaptor/adaptor_generic.log \
	examples/adaptor/adaptor_generic.eqn \
	examples/adaptor/dose_response.m \
	examples/mma/XAY_ss.mod \
	examples/mma/XAY_ss.log \
	examples/mma/XAY_ss.eqn \
	examples/mma/XAY_ssFunc.m \
	examples/mma/XAY_prozone.m \
	examples/multimers/multimer_MWC.mod \
	examples/multimers/multimer_MWC.log \
	examples/multimers/multimer_MWC.eqn \
	examples/multimers/multimer_KNF_asym.mod \
	examples/multimers/multimer_KNF_asym.log \
	examples/multimers/multimer_KNF_asym.eqn \
	examples/multimers/multimer_KNF_linear.mod \
	examples/multimers/multimer_KNF_linear.log \
	examples/multimers/multimer_KNF_linear.eqn \
	examples/multimers/multimer_KNF_square.mod \
	examples/multimers/multimer_KNF_square.log \
	examples/multimers/multimer_KNF_square.eqn \
	examples/multimers/multimer_KNF_tetra.mod \
	examples/multimers/multimer_KNF_tetra.log \
	examples/multimers/multimer_KNF_tetra.eqn \
	examples/multimers/multimer_TTS.mod \
	examples/multimers/multimer_TTS.log \
	examples/multimers/multimer_TTS.eqn \
	examples/multimers/multimer_TTS_gem.mod \
	examples/multimers/multimer_TTS_gem.log \
	examples/multimers/multimer_TTS_gem.eqn \
	examples/multimers/dose_response.m \
	examples/multimers_mix/multimer_MWC_mix.mod \
	examples/multimers_mix/multimer_MWC_mix.log \
	examples/multimers_mix/multimer_MWC_mix.eqn \
	examples/multimers_mix/multimer_KNF_tetra_mix.mod \
	examples/multimers_mix/multimer_KNF_tetra_mix.log \
	examples/multimers_mix/multimer_KNF_tetra_mix.eqn \
	examples/multimers_mix/multimer_MWC_mixFunc.m \
	examples/multimers_mix/multimer_KNF_tetra_mixFunc.m \
	examples/multimers_mix/dose_response_sim.m \
	examples/multimers_mix/dose_response_analyze.m \
	examples/GPCR/GPCR_CTC.mod \
	examples/GPCR/GPCR_CTC.log \
	examples/GPCR/GPCR_CTC.eqn \
	examples/GPCR/GPCR_QTC.mod \
	examples/GPCR/GPCR_QTC.log \
	examples/GPCR/GPCR_QTC.eqn \
	examples/GPCR/dose_response.m \
	examples/GPCR/GPCR_QTC_fsel3x2Func.m \
	examples/GPCR/fsel.m \
	examples/calmodulin/calmodulin.mod \
	examples/calmodulin/calmodulin.log \
	examples/calmodulin/calmodulin.eqn \
	examples/Rdimer/Rdimer_adhoc.mod \
	examples/Rdimer/Rdimer_adhoc.log \
	examples/Rdimer/Rdimer_adhoc.eqn \
	examples/Rdimer/Rdimer_mwc.mod \
	examples/Rdimer/Rdimer_mwc.log \
	examples/Rdimer/Rdimer_mwc.eqn \
	examples/chemotaxis/MCP.mod \
	examples/chemotaxis/MCP.log \
	examples/chemotaxis/MCP.eqn \
	examples/MAPK/MAPK_ste5_adhoc.mod \
	examples/MAPK/MAPK_ste5_adhoc.log \
	examples/MAPK/MAPK_ste5_adhoc.eqn \
	examples/manual/ligand_effect.mod \
	examples/manual/ligand_effect.log \
	examples/manual/ligand_effect.eqn \
	examples/manual/modification_effect.mod \
	examples/manual/modification_effect.log \
	examples/manual/modification_effect.eqn \
	examples/manual/asite_effect.mod \
	examples/manual/asite_effect.log \
	examples/manual/asite_effect.eqn \
	examples/manual/combined_effect.mod \
	examples/manual/combined_effect.log \
	examples/manual/combined_effect.eqn \

TARBALL_DIR = anc_$(RELEASE)

tarball:
	mkdir -p $(TARBALL_DIR)
	cp --parents -p $(RELEASE_FILES) $(TARBALL_DIR)
	tar -czf $(TARBALL_DIR).tar.gz $(TARBALL_DIR)
	rm -rf $(TARBALL_DIR)

group = swainlab

read_permissions :
	find . -type 'd' | xargs chmod 750
	find . -name '*.pl' | xargs chmod 550
	find . -name '*.pm' | xargs chmod 440
	find . -name '*.mod' | xargs chmod 440
	find . -name '*.eqn' | xargs chmod 440
	find . -name '*.log' | xargs chmod 440
	find . -name '*.rpt' | xargs chmod 440
	find . -name '*.m' | xargs chmod 440
	find . -name '*.TXT' | xargs chmod 440
	chgrp -R $(group) .

write_permissions :
	find . -type 'd' | xargs chmod 750
	find . -name '*.pl' | xargs chmod 750
	find . -name '*.pm' | xargs chmod 640
	find . -name '*.mod' | xargs chmod 640
	find . -name '*.eqn' | xargs chmod 640
	find . -name '*.log' | xargs chmod 640
	find . -name '*.rpt' | xargs chmod 640
	find . -name '*.m' | xargs chmod 640
	find . -name '*.TXT' | xargs chmod 640
	chgrp -R $(group) .

#-------------------------------------------------------------------------------------
# FILES
#-------------------------------------------------------------------------------------

# These are the main program modules of the ANC application
base_modules = \
	test/modules/Named.log \
	test/modules/ClassData.log \
	test/modules/Registered.log \
	test/modules/Instance.log \
	test/modules/Instantiable.log \
	test/modules/Null.log \
	test/modules/Component.log \
	test/modules/Set.log \
	test/modules/SetElement.log \
	test/modules/SetInstance.log \
	test/modules/ObjectTemplate.log \
	test/modules/Matrix.log \

main_modules = \
	test/modules/Parameter.log \
	test/modules/Variable.log \
	test/modules/SiteInfo.log \
	test/modules/Filter.log \
	test/modules/Probe.log \
	test/modules/Graph.log \
	test/modules/GraphInstance.log \
	test/modules/RegisteredGraph.log \
	test/modules/Node.log \
	test/modules/NodeInstance.log \
	test/modules/HiGraph.log \
	test/modules/HiGraphInstance.log \
	test/modules/Structure.log \
	test/modules/AllostericStructure.log \
	test/modules/ReactionSite.log \
	test/modules/ReactionSiteInstance.log \
	test/modules/AllostericSite.log \
	test/modules/AllostericSiteInstance.log \
	test/modules/Species.log \
	test/modules/Complex.log \
	test/modules/Rule.log \
	test/modules/BinaryRule.log \
	test/modules/CanBindRule.log \
	test/modules/CanBindRuleInstance.log \
	test/modules/AllostericReaction.log \
	test/modules/UnaryReaction.log \
	test/modules/BinaryReaction.log \
	test/modules/BindingReaction.log \
	test/modules/CatalyticReaction.log \
	test/modules/ReactionNetwork.log \
	test/modules/Filter.log \
	test/modules/Selector.log \
	test/modules/Stimulus.log \
	test/modules/Probe.log \

test_models = \
	test/models/isomorphs/ISOMORPHS-EXT.log \
	test/models/isomorphs/ISOMORPHS-INT.log \
	test/models/polymer/POLYMER.log \
	test/models/rtk/RTK.log \
	test/models/loop-and-chain/LOOP-AND-CHAIN.log \
	test/models/loop-and-chain/LOOP-AND-CHAIN-2.log \
	test/models/dissociation/DISS.log \
	test/models/adaptor/adaptor_simple.log \
	test/models/dimers/dimer.log \
	test/models/dimers/heterodimer.log \
	test/models/dimers/homodimer.log \
	test/models/dimers/bivalent_dimer.log \
	test/models/misc/ALLOSTERIC.log \
	test/models/misc/STIMULUS.log \
	test/models/multistate/multistate.log \

test_models_low_verbosity = \
	test/models/mapk/MAPK.MXCSITE1.log \
	test/models/mapk/MAPK.NOMXCSITE.log \

examples = \
	examples/adaptor/adaptor_generic.log \
	examples/adaptor/adaptor_locked.log \
	examples/adaptor/adaptor_with_msite.log \
	examples/mma/AXY_sequential.log \
	examples/mma/XAY_ss.log \
	examples/Rdimer/Rdimer_adhoc.log \
	examples/Rdimer/Rdimer_mwc.log \
	examples/MAPK/MAPK_ste5_adhoc.log \
	examples/multimers/multimer_MWC.log \
	examples/multimers/multimer_KNF_tetra.log \
	examples/multimers/multimer_KNF_square.log \
	examples/multimers/multimer_KNF_linear.log \
	examples/multimers/multimer_KNF_asym.log \
	examples/multimers/multimer_TTS.log \
	examples/multimers/multimer_TTS_gem.log \
	examples/multimers_mix/multimer_MWC_mix.log \
	examples/multimers_mix/multimer_KNF_tetra_mix.log \
	examples/calmodulin/calmodulin.log \
	examples/GluR/GLUR.log \
	examples/GluR/GLUR_ATG.log \
	examples/GPCR/GPCR_CTC.log \
	examples/GPCR/GPCR_QTC.log \
	examples/GPCR/GPCR_QTC_fsel3x2.log \
	examples/GPCR/GPCR_CTC_verify.log \
	examples/GPCR/GPCR_QTC_verify.log \
	examples/manual/ligand_effect.log \
	examples/manual/modification_effect.log \
	examples/manual/asite_effect.log \
	examples/manual/combined_effect.log \
	examples/chemotaxis/MCP.log \

#	examples/MAPK/MAPK_ste5_mwc.log \
#	examples/MAPK/MAPK_yeast_mwc.log \
#	examples/MAPK/MAPK_yeast_new.log \

test_model_profiles = \
	test/models/adaptor/adaptor_simple.prof.rpt \
	test/models/loop-and-chain/LOOP-AND-CHAIN.prof.rpt \
	test/models/loop-and-chain/LOOP-AND-CHAIN-2.prof.rpt \
	test/models/adaptor/adaptor_simple.prof.rpt \

example_profiles = \
	examples/adaptor/adaptor2.prof.rpt \
	examples/adaptor/adaptor3.prof.rpt \
	examples/multimers/HEMOGLOBIN_SIMPLE.prof.rpt \
	examples/MAPK/STE5_MAPK.prof.rpt \

#	examples/hemoglobin/HEMOGLOBIN_SUBUNITS.prof.rpt \

#-------------------------------------------------------------------------------------
# SYMBOLIC TARGETS
#-------------------------------------------------------------------------------------
info:
	@echo "To make a tarball, try 'make tarball'"
	@echo "To run all testcases, try 'make test'"

test : test_all_modules test_models test_examples

test_all_modules : test_base_modules test_main_modules

test_base_modules : $(base_modules)
	@echo "Done running base module tests.  BZR Status:"
	@-bzr status -V test/modules 2>&1 | grep File

test_main_modules : $(main_modules)
	@echo "Done running main module tests.  BZR Status:"
	@-bzr status -V test/modules 2>&1 | grep File

test_models : $(test_models)
	@echo "Done running test models.  BZR Status:"
	@-bzr status -V test/models 2>&1 | grep File

test_examples : $(examples)
	@echo "Done running examples.  BZR Status:"
	@-bzr status -V examples 2>&1 | grep File

profiles : test_model_profiles example_profiles

test_model_profiles : $(test_model_profiles)

example_profiles : $(example_profiles)


#-------------------------------------------------------------------------------------
# MODULE TESTS
#-------------------------------------------------------------------------------------
test/modules/%.log : FORCE
	@echo "Running $* testcase..."
	-chmod -f +w test/modules/$*.log
	-perl -Ibase -Imodules -M$* -e '$*::run_testcases()' 2>&1 > test/modules/$*.log
	-bzr diff --using=$(DIFF_CMD) $@

GRAPHVIZ = --graphviz="primary,canonical,network,collapse_states,collapse_complexes"

#-------------------------------------------------------------------------------------
# MODEL TESTS
# * low verbosity
#-------------------------------------------------------------------------------------
$(test_models_low_verbosity) : FORCE
	echo "Compiling $(basename $@).mod ..."
	-rm -f $(basename $@).log
	-$(ANC_CMD) $(GRAPHVIZ) --debug --verbosity=1 --report=all --outdir=$(basename $@) $(basename $@).mod 2>&1 > $(basename $@).log
	-bzr diff --using=$(DIFF_CMD) $@
	-bzr diff --using=$(DIFF_CMD) $(basename $@).eqn

#-------------------------------------------------------------------------------------
# MODEL TESTS
# * high verbosity (default)
#-------------------------------------------------------------------------------------
test/models/%.log : FORCE
	echo "Compiling $(basename $@).mod ..."
	-rm -f $(basename $@).log
	-$(ANC_CMD) $(GRAPHVIZ) --debug --verbosity=2 --report=all --outdir=$(basename $@) $(basename $@).mod 2>&1 > $(basename $@).log
	-bzr diff --using=$(DIFF_CMD) $@
	-bzr diff --using=$(DIFF_CMD) $(basename $@).eqn

#-------------------------------------------------------------------------------------
# EXAMPLES
# * low verbosity, else slow and log file is huge!!
#-------------------------------------------------------------------------------------
examples/%.log : FORCE
	echo "Compiling example/$*.mod ..."
	-rm -f $(@D)/$(*F).log
	-$(ANC_CMD) $(GRAPHVIZ) --debug --verbosity=1 --report=all --outdir=$(@D)/$(*F) $(@D)/$(*F).mod 2>&1 | tee -i $(@D)/$(*F).log
	-bzr diff --using=$(DIFF_CMD) $@
	-bzr diff --using=$(DIFF_CMD) $(@D)/$(*F).eqn
	-bzr diff --using=$(DIFF_CMD) $(@D)/$(*F)/$(*F).structures.rpt
	-bzr diff --using=$(DIFF_CMD) $(@D)/$(*F)/$(*F).species.rpt

#-------------------------------------------------------------------------------------
# PROFILING
#-------------------------------------------------------------------------------------
examples/%.prof.rpt : FORCE
	-rm -f $(@D)/$(*F).prof.log
	-$(ANC_PROF_CMD) --verbosity=1 --outdir=$(@D)/$(*F) --out=$(@D)/$(*F).prof.eqn $(@D)/$(*F).mod 2>&1 | tee -i $(@D)/$(*F).prof.log
	-cp -pf $(@D)/$(*F).prof.rpt $(@D)/$(*F).prof.rpt.save
	-dprofpp -R -O 30 -u 2>&1 | tee -i $(@D)/$(*F).prof.rpt
	-bzr diff --using=$(DIFF_CMD) $(@D)/$(*F).prof.log
	-bzr diff --using=$(DIFF_CMD) $(@D)/$(*F).prof.eqn $(@D)/$(*F).eqn
	-bzr diff --using=$(DIFF_CMD) $(@D)/$(*F).prof.rpt

test/models/%.prof.rpt : FORCE
	-rm -f $(@D)/$(*F).prof.log
	-$(ANC_PROF_CMD) --verbosity=1 --outdir=$(@D)/$(*F) --out=$(@D)/$(*F).prof.eqn $(@D)/$(*F).mod 2>&1 | tee -i $(@D)/$(*F).prof.log
	-cp -pf $(@D)/$(*F).prof.rpt $(@D)/$(*F).prof.rpt.save
	-dprofpp -R -O 30 -u 2>&1 | tee -i $(@D)/$(*F).prof.rpt
	-bzr diff --using=$(DIFF_CMD) $(@D)/$(*F).prof.log
	-bzr diff --using=$(DIFF_CMD) $(@D)/$(*F).prof.eqn $(@D)/$(*F).eqn
	-bzr diff --using=$(DIFF_CMD) $(@D)/$(*F).prof.rpt

#-------------------------------------------------------------------------------------
# SIMULATION
#-------------------------------------------------------------------------------------
examples/%.simlog : FORCE
	-$(FACILE_CMD) -P -m -o $(@D)/$(*F)/$(*F) $(@D)/$(*F).eqn 2>&1 | tee -i $(@D)/$(*F).simlog
	-matlab -nodesktop -nosplash -r "run $(@D)/$(*F)/$(*F)Driver.m" 2>&1 | tee -i -a $(@D)/$(*F).simlog

test/models/%.simlog : FORCE
	-$(FACILE_CMD) -P -m -o $(@D)/$(*F)/$(*F) $(@D)/$(*F).eqn 2>&1 | tee -i $(@D)/$(*F).simlog
	-matlab -nodesktop -nosplash -r "run $(@D)/$(*F)/$(*F)Driver.m" 2>&1 | tee -i -a $(@D)/$(*F).simlog

#-------------------------------------------------------------------------------------
# MISC
#-------------------------------------------------------------------------------------
class_hierarchy : class_inheritance_hierarchy

class_inheritance_hierarchy : FORCE
	perl -Ibase -Imodules -MUtils -e 'print Utils::sprint_class_hierarchy("class_inheritance_hierarchy.png", Structure, Complex, AllostericSite, AllostericStructure, BindingReaction, CatalyticReaction, AllostericReaction, Filter, Rule, CanBindRule)'
	perl -Ibase -Imodules -MUtils -e 'print Utils::sprint_class_hierarchy("class_instance_inheritance_hierarchy.png", ComplexInstance, StructureInstance, AllostericSiteInstance, AllostericStructureInstance, Species)'

FORCE:


