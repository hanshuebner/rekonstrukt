SetActiveLib -work
comp -include "c:\hans\rekonstrukt\vhdl\timer.vhd" 
comp -include "C:\hans\rekonstrukt\testbench\timer_TB.vhd" 
asim TESTBENCH_FOR_timer 
wave 
wave -noreg clk
wave -noreg rst
wave -noreg cs
wave -noreg rw
wave -noreg addr
wave -noreg data_in
wave -noreg data_out
wave -noreg clk_1mhz
wave -noreg midi_clk
wave -noreg timer_irq
# The following lines can be used for timing simulation
# acom <backannotated_vhdl_file_name>
# comp -include "C:\hans\rekonstrukt\testbench\timer_TB_tim_cfg.vhd" 
# asim TIMING_FOR_timer 
