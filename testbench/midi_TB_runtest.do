SetActiveLib -work
comp -include "C:\hans\rekonstrukt\vhdl\midi.vhd" 
comp -include "C:\hans\rekonstrukt\testbench\midi_TB.vhd" 
asim TESTBENCH_FOR_midi 
wave 
wave -noreg clk
wave -noreg rst
wave -noreg cs
wave -noreg rw
wave -noreg addr
wave -noreg data_in
wave -noreg data_out
wave -noreg clk_1mhz
wave -noreg midi_tx
# The following lines can be used for timing simulation
# acom <backannotated_vhdl_file_name>
# comp -include "C:\hans\rekonstrukt\testbench\midi_TB_tim_cfg.vhd" 
# asim TIMING_FOR_midi 
