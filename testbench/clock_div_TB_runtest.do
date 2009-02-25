SetActiveLib -work
comp -include "c:\hans\rekonstrukt\vhdl\clock_div.vhd" 
comp -include "C:\hans\rekonstrukt\testbench\clock_div_TB.vhd" 
asim TESTBENCH_FOR_clock_div 
wave 
wave -noreg clk
wave -noreg reset
wave -noreg clk_1mhz
wave -noreg clk_500khz
# The following lines can be used for timing simulation
# acom <backannotated_vhdl_file_name>
# comp -include "C:\hans\rekonstrukt\testbench\clock_div_TB_tim_cfg.vhd" 
# asim TIMING_FOR_clock_div 
