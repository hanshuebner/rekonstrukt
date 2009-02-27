SetActiveLib -work
comp -include "c:\hans\rekonstrukt\vhdl\bit_funcs.vhd" 
comp -include "c:\hans\rekonstrukt\vhdl\ram2k_b16.vhd" 
comp -include "c:\hans\rekonstrukt\vhdl\char_rom2k_b16.vhd" 
comp -include "c:\hans\rekonstrukt\vhdl\keymap_rom_slice.vhd" 
comp -include "c:\hans\rekonstrukt\vhdl\ps2_keyboard.vhd" 
comp -include "c:\hans\rekonstrukt\vhdl\acia_tx.vhd" 
comp -include "c:\hans\rekonstrukt\vhdl\acia_rx.vhd" 
comp -include "c:\hans\rekonstrukt\vhdl\clock_synthesis_spartan3.vhd" 
comp -include "c:\hans\rekonstrukt\vhdl\timer.vhd" 
comp -include "c:\hans\rekonstrukt\vhdl\clock_div.vhd" 
comp -include "c:\hans\rekonstrukt\vhdl\spi-master.vhd" 
comp -include "c:\hans\rekonstrukt\vhdl\vdu8.vhd" 
comp -include "c:\hans\rekonstrukt\vhdl\keyboard.vhd" 
comp -include "c:\hans\rekonstrukt\vhdl\acia_clock.vhd" 
comp -include "c:\hans\rekonstrukt\vhdl\acia_6850.vhd" 
comp -include "c:\hans\rekonstrukt\vhdl\ram16k_b16.vhd" 
comp -include "c:\hans\rekonstrukt\maisforth\an601.vhd" 
comp -include "c:\hans\rekonstrukt\vhdl\cpu09.vhd" 
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
