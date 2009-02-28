SetActiveLib -work
comp -include "c:\hans\rekonstrukt\vhdl\rotary.vhd" 
comp -include "C:\hans\rekonstrukt\testbench\rotary_encoder_TB.vhd" 
asim TESTBENCH_FOR_rotary_encoder 
wave 
wave -noreg clk
wave -noreg rst
wave -noreg cs
wave -noreg rw
wave -noreg addr
wave -noreg data_out
wave -noreg clk_1mhz
wave -noreg rot_left
wave -noreg rot_right
# The following lines can be used for timing simulation
# acom <backannotated_vhdl_file_name>
# comp -include "C:\hans\rekonstrukt\testbench\rotary_encoder_TB_tim_cfg.vhd" 
# asim TIMING_FOR_rotary_encoder 
