SetActiveLib -work
comp -include "c:\hans\rekonstrukt\vhdl\clock_synthesis_spartan3.vhd" 
comp -include "C:\hans\rekonstrukt\testbench\dcmtest_TB.vhd" 
asim TESTBENCH_FOR_dcmtest 
wave 
wave -noreg CLKIN_IN
wave -noreg RST_IN
wave -noreg CLK0_OUT
wave -noreg CLK270_OUT
wave -noreg LOCKED_OUT
# The following lines can be used for timing simulation
# acom <backannotated_vhdl_file_name>
# comp -include "C:\hans\rekonstrukt\testbench\dcmtest_TB_tim_cfg.vhd" 
# asim TIMING_FOR_dcmtest 
