SetActiveLib -work
comp -include "$DSN\..\vhdl\dac.vhd" 
comp -include "$DSN\..\vhdl\sawtooth.vhd" 
comp -include "$DSN\src\TestBench\dac_TB.vhd" 
asim TESTBENCH_FOR_dac 
wave 
wave -noreg reset
wave -noreg clk
wave -noreg data
wave -noreg analog_out
# The following lines can be used for timing simulation
# acom <backannotated_vhdl_file_name>
# comp -include "$DSN\src\TestBench\dac_TB_tim_cfg.vhd" 
# asim TIMING_FOR_dac 
