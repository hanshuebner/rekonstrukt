SetActiveLib -work
comp -include "c:\hans\vhdl\System09\rtl\VHDL\spi-master.vhd" 
comp -include "c:\hans\vhdl\System09\rtl\Testbench\spi_master_TB.vhd" 
asim TESTBENCH_FOR_spi_master 
wave 
wave -noreg clk
wave -noreg reset
wave -noreg cs
wave -noreg rw
wave -noreg addr
wave -noreg data_in
wave -noreg data_out
wave -noreg irq
wave -noreg spi_clk
wave -noreg spi_mosi
wave -noreg spi_cs_n
wave -noreg spi_miso
wave -noreg state
wave -noreg start
wave -noreg start_reg
wave -noreg clr_start
# The following lines can be used for timing simulation
# acom <backannotated_vhdl_file_name>
# comp -include "$DSN\src\TestBench\spi_master_TB_tim_cfg.vhd" 
# asim TIMING_FOR_spi_master 
