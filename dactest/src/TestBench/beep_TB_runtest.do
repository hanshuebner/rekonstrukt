SetActiveLib -work
comp -include "c:\hans\rekonstrukt\vhdl\beep.vhd" 
comp -include "$DSN\src\TestBench\beep_TB.vhd" 
asim TESTBENCH_FOR_beep 
wave 
wave -noreg reset
wave -noreg clk
wave -noreg analog_out
# The following lines can be used for timing simulation
# acom <backannotated_vhdl_file_name>
# comp -include "$DSN\src\TestBench\beep_TB_tim_cfg.vhd" 
# asim TIMING_FOR_beep 
