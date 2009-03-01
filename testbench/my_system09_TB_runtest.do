SetActiveLib -work
comp -include "c:\hans\rekonstrukt\vhdl\s3esk-maisforth.vhd" 
comp -include "C:\hans\rekonstrukt\testbench\my_system09_TB.vhd" 
asim TESTBENCH_FOR_my_system09 
wave 
wave -noreg CLK_50MHZ
wave -noreg PS2_CLK
wave -noreg PS2_DATA
wave -noreg VGA_VSYNC
wave -noreg VGA_HSYNC
wave -noreg VGA_BLUE
wave -noreg VGA_GREEN
wave -noreg VGA_RED
wave -noreg RS232_DCE_RXD
wave -noreg RS232_DCE_TXD
wave -noreg RS232_DTE_RXD
wave -noreg RS232_DTE_TXD
wave -noreg J4
wave -noreg SPI_MISO
wave -noreg SPI_MOSI
wave -noreg SPI_SCK
wave -noreg DAC_CS
wave -noreg AMP_CS
wave -noreg AD_CONV
wave -noreg SPI_SS_B
wave -noreg SF_CE0
wave -noreg SF_OE
wave -noreg SF_WE
wave -noreg FPGA_INIT_B
wave -noreg LED
wave -noreg SW
wave -noreg BTN_NORTH
wave -noreg BTN_SOUTH
wave -noreg BTN_EAST
wave -noreg BTN_WEST
wave -noreg ROT_A
wave -noreg ROT_B
wave -noreg ROT_CENTER
wave -noreg LCD_E
wave -noreg LCD_RS
wave -noreg LCD_RW
wave -noreg SF_D
wave -noreg FX2_IO
# The following lines can be used for timing simulation
# acom <backannotated_vhdl_file_name>
# comp -include "C:\hans\rekonstrukt\testbench\my_system09_TB_tim_cfg.vhd" 
# asim TIMING_FOR_my_system09 
