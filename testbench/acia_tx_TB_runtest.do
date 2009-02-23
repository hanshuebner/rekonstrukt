SetActiveLib -work
comp -include "c:\hans\rekonstrukt\vhdl\acia_tx.vhd" 
comp -include "$DSN\src\TestBench\acia_tx_TB.vhd" 
asim TESTBENCH_FOR_acia_tx 
wave 
wave -noreg Clk
wave -noreg Reset
wave -noreg Wr
wave -noreg Din
wave -noreg WdFmt
wave -noreg BdFmt
wave -noreg TxClk
wave -noreg Dat
wave -noreg Empty
# The following lines can be used for timing simulation
# acom <backannotated_vhdl_file_name>
# comp -include "$DSN\src\TestBench\acia_tx_TB_tim_cfg.vhd" 
# asim TIMING_FOR_acia_tx 
