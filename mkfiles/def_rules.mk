#-----------------------------------------------------------------
# File:    def_rules.mk
# Author:  David Burnette
# Date:    April 7, 2008
#
# Description:
#
# Usage:
#  This make file fragment contains default translate rules.
#
# Dependencies:
#  Depends on 'def_cmds.mk' fragment.
#
# Revision History:
#   dgb 2008-04-07   Original version
#
#-----------------------------------------------------------------

#===================================================================
# Include default commands

include $(MKFRAGS)/def_cmds.mk

#===================================================================
# TRANSLATE RULES

#   RULE: .asm => .S19
# Assemble 6809 source into S19 record file
%.S19: %.asm
	@$(ECHO)
	@$(ECHO) "======= Running 6809 assembler to generate ROM code  ================"
	$(ASM) $(notdir $<)  >$(basename $@).lst

#   RULE: .S19 => .vhd
# Build a VHDL file instantiated BRAMS initialized with the source from a S19 file
%.vhd: %.S19
	@$(ECHO)
	@$(ECHO) "======= Generating Xilinx block RAM to hold ROM code ================"
	$(s19tovhd) $< $(basename $@) $(ENTITY) $(ADDRS)
	$(CAT) $(TOP_RAM) >>$@

