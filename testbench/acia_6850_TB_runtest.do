SetActiveLib -work
comp -include "c:\hans\rekonstrukt\vhdl\acia_6850.vhd" 
comp -include "$DSN\src\TestBench\acia_6850_TB.vhd" 
asim TESTBENCH_FOR_acia_6850 
wave 
wave -noreg clk
wave -noreg rst
wave -noreg cs
wave -noreg rw
wave -noreg irq
wave -noreg Addr
wave -noreg DataIn
wave -noreg DataOut
wave -noreg RxC
wave -noreg TxC
wave -noreg RxD
wave -noreg TxD
wave -noreg DCD_n
wave -noreg CTS_n
wave -noreg RTS_n
wave -noreg debug
# The following lines can be used for timing simulation
# acom <backannotated_vhdl_file_name>
# comp -include "$DSN\src\TestBench\acia_6850_TB_tim_cfg.vhd" 
# asim TIMING_FOR_acia_6850 
