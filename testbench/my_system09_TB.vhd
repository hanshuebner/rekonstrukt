library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

-- Add your library and packages declaration here ...

entity my_system09_tb is
end my_system09_tb;

architecture TB_ARCHITECTURE of my_system09_tb is
  -- Component declaration of the tested unit
  component my_system09
    port(
      CLK_50MHZ : in STD_LOGIC;
      PS2_CLK : inout STD_LOGIC;
      PS2_DATA : inout STD_LOGIC;
      VGA_VSYNC : out STD_LOGIC;
      VGA_HSYNC : out STD_LOGIC;
      VGA_BLUE : out STD_LOGIC;
      VGA_GREEN : out STD_LOGIC;
      VGA_RED : out STD_LOGIC;
      RS232_DCE_RXD : in STD_LOGIC;
      RS232_DCE_TXD : out STD_LOGIC;
      RS232_DTE_RXD : in STD_LOGIC;
      RS232_DTE_TXD : out STD_LOGIC;
      J4 : inout STD_LOGIC_VECTOR(3 downto 0);
      SPI_MISO : in STD_LOGIC;
      SPI_MOSI : out STD_LOGIC;
      SPI_SCK : out STD_LOGIC;
      DAC_CS : out STD_LOGIC;
      AMP_CS : out STD_LOGIC;
      AD_CONV : out STD_LOGIC;
      SPI_SS_B : out STD_LOGIC;
      SF_CE0 : out STD_LOGIC;
      SF_OE : out STD_LOGIC;
      SF_WE : out STD_LOGIC;
      FPGA_INIT_B : out STD_LOGIC;
      LED : out STD_LOGIC_VECTOR(7 downto 0);
      SW : in STD_LOGIC_VECTOR(3 downto 0);
      BTN_NORTH : in STD_LOGIC;
      BTN_SOUTH : in STD_LOGIC;
      BTN_EAST : in STD_LOGIC;
      BTN_WEST : in STD_LOGIC;
      ROT_A : in STD_LOGIC;
      ROT_B : in STD_LOGIC;
      ROT_CENTER : in STD_LOGIC;
      LCD_E : out STD_LOGIC;
      LCD_RS : out STD_LOGIC;
      LCD_RW : out STD_LOGIC;
      SF_D : out STD_LOGIC_VECTOR(11 downto 8);
      FX2_IO : inout STD_LOGIC_VECTOR(8 downto 1) );
  end component;

  -- Stimulus signals - signals mapped to the input and inout ports of tested entity
  signal CLK_50MHZ : STD_LOGIC;
  signal RS232_DCE_RXD : STD_LOGIC;
  signal RS232_DTE_RXD : STD_LOGIC;
  signal SPI_MISO : STD_LOGIC;
  signal SW : STD_LOGIC_VECTOR(3 downto 0);
  signal BTN_NORTH : STD_LOGIC;
  signal BTN_SOUTH : STD_LOGIC;
  signal BTN_EAST : STD_LOGIC;
  signal BTN_WEST : STD_LOGIC;
  signal ROT_A : STD_LOGIC;
  signal ROT_B : STD_LOGIC;
  signal ROT_CENTER : STD_LOGIC;
  signal PS2_CLK : STD_LOGIC;
  signal PS2_DATA : STD_LOGIC;
  signal J4 : STD_LOGIC_VECTOR(3 downto 0);
  signal FX2_IO : STD_LOGIC_VECTOR(8 downto 1);
  -- Observed signals - signals mapped to the output ports of tested entity
  signal VGA_VSYNC : STD_LOGIC;
  signal VGA_HSYNC : STD_LOGIC;
  signal VGA_BLUE : STD_LOGIC;
  signal VGA_GREEN : STD_LOGIC;
  signal VGA_RED : STD_LOGIC;
  signal RS232_DCE_TXD : STD_LOGIC;
  signal RS232_DTE_TXD : STD_LOGIC;
  signal SPI_MOSI : STD_LOGIC;
  signal SPI_SCK : STD_LOGIC;
  signal DAC_CS : STD_LOGIC;
  signal AMP_CS : STD_LOGIC;
  signal AD_CONV : STD_LOGIC;
  signal SPI_SS_B : STD_LOGIC;
  signal SF_CE0 : STD_LOGIC;
  signal SF_OE : STD_LOGIC;
  signal SF_WE : STD_LOGIC;
  signal FPGA_INIT_B : STD_LOGIC;
  signal LED : STD_LOGIC_VECTOR(7 downto 0);
  signal LCD_E : STD_LOGIC;
  signal LCD_RS : STD_LOGIC;
  signal LCD_RW : STD_LOGIC;
  signal SF_D : STD_LOGIC_VECTOR(11 downto 8);

  -- Add your code here ...

begin

  -- Unit Under Test port map
  UUT : my_system09
    port map (
      CLK_50MHZ => CLK_50MHZ,
      PS2_CLK => PS2_CLK,
      PS2_DATA => PS2_DATA,
      VGA_VSYNC => VGA_VSYNC,
      VGA_HSYNC => VGA_HSYNC,
      VGA_BLUE => VGA_BLUE,
      VGA_GREEN => VGA_GREEN,
      VGA_RED => VGA_RED,
      RS232_DCE_RXD => RS232_DCE_RXD,
      RS232_DCE_TXD => RS232_DCE_TXD,
      RS232_DTE_RXD => RS232_DTE_RXD,
      RS232_DTE_TXD => RS232_DTE_TXD,
      J4 => J4,
      SPI_MISO => SPI_MISO,
      SPI_MOSI => SPI_MOSI,
      SPI_SCK => SPI_SCK,
      DAC_CS => DAC_CS,
      AMP_CS => AMP_CS,
      AD_CONV => AD_CONV,
      SPI_SS_B => SPI_SS_B,
      SF_CE0 => SF_CE0,
      SF_OE => SF_OE,
      SF_WE => SF_WE,
      FPGA_INIT_B => FPGA_INIT_B,
      LED => LED,
      SW => SW,
      BTN_NORTH => BTN_NORTH,
      BTN_SOUTH => BTN_SOUTH,
      BTN_EAST => BTN_EAST,
      BTN_WEST => BTN_WEST,
      ROT_A => ROT_A,
      ROT_B => ROT_B,
      ROT_CENTER => ROT_CENTER,
      LCD_E => LCD_E,
      LCD_RS => LCD_RS,
      LCD_RW => LCD_RW,
      SF_D => SF_D,
      FX2_IO => FX2_IO
      );

  -- Add your stimulus here ...
  gen_clk : process
  begin
    clk_50mhz <= '1'; wait for 10 ns;
    clk_50mhz <= '0'; wait for 10 ns;
  end process;

  ps2_data      <= '0';
  ps2_clk       <= '0';
  rs232_dte_rxd <= '0';
  rs232_dce_rxd <= '0';
  rot_center    <= '0';

end TB_ARCHITECTURE;

configuration TESTBENCH_FOR_my_system09 of my_system09_tb is
  for TB_ARCHITECTURE
    for UUT : my_system09
      use entity work.my_system09(my_computer);
    end for;
  end for;
end TESTBENCH_FOR_my_system09;

