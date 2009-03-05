-- $Id: System09_Digilent_3S500E.vhd,v 1.3.2.1 2008/04/08 14:59:48 davidgb Exp $
--===========================================================================----
--
--  S Y N T H E Z I A B L E    System09 - SOC.
--
--===========================================================================----
--
--  This core adheres to the GNU public license  
--
-- File name      : System09_Digilent_3S500E.vhd
--
-- Purpose        : Top level file for 6809 compatible system on a chip
--                  Designed with Xilinx XC3S500E Spartan 3E FPGA.
--                  Implemented With Digilent Xilinx Starter FPGA board,
--
-- Author         : John E. Kent      
--                  dilbert57@opencores.org      

library ieee;
use ieee.std_logic_1164.all;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use ieee.numeric_std.all;

entity my_system09 is
  port(
    CLK_50M : in Std_Logic;             -- System Clock input

    -- PS/2 Keyboard
    PS2_CLK1  : inout Std_logic;
    PS2_DATA1 : inout Std_Logic;

    -- CRTC output signals
    VGA_VSYNC : out Std_Logic;
    VGA_HSYNC : out std_logic;
    VGA_R     : out std_logic_vector(3 downto 0);
    VGA_G     : out std_logic_vector(3 downto 0);
    VGA_B     : out std_logic_vector(3 downto 0);

    -- Uart Interface
    RS232_DCE_RXD : in  std_logic;
    RS232_DCE_TXD : out std_logic;

    -- System SPI interface (Flash, DAC, ADC, AMP)
    SPI_MISO : in  std_logic;
    SPI_MOSI : out std_logic;
    SPI_SCK  : out std_logic;
    DAC_CS,
    AMP_CS,
    AD_CONV,
    SPI_SS_B : out std_logic;

    -- Control signals that need to be initialized to free the SPI bus
    SF_CE0,
    SF_OE,
    SF_WE,
    FPGA_INIT_B : out std_logic;

    -- LEDS & Switches
    LED        : out std_logic_vector(7 downto 0);
    SW         : in  std_logic_vector(3 downto 0);
    BTN_NORTH,
    BTN_SOUTH,
    BTN_EAST,
    BTN_WEST   : in  Std_Logic;
    ROT_A,
    ROT_B,
    ROT_CENTER : in  std_logic;

    -- LCD
    LCD_E, LCD_RS, LCD_RW : out std_logic;
    LCD_DB                : out std_logic_vector(3 downto 0)
    );
end my_system09;

-------------------------------------------------------------------------------
-- Architecture for System09
-------------------------------------------------------------------------------
architecture my_computer of my_system09 is
  -----------------------------------------------------------------------------
  -- constants
  -----------------------------------------------------------------------------
  constant SYS_CLK_FREQ  : integer := 50000000;  -- FPGA System Clock
  constant VGA_CLK_FREQ  : integer := 25000000;  -- VGA Pixel Clock
  constant CPU_CLK_FREQ  : integer := 25000000;  -- CPU Clock
  constant BAUD_RATE     : integer := 57600;	  -- Baud Rate
  constant ACIA_CLK_FREQ : integer := BAUD_RATE * 16;

  -----------------------------------------------------------------------------
  -- Signals
  -----------------------------------------------------------------------------
  -- BOOT ROM
  signal rom_data_out   : Std_Logic_Vector(7 downto 0);

  -- UART Interface signals
  signal uart_data_out  : Std_Logic_Vector(7 downto 0);  
  signal uart_cs        : Std_Logic;
  signal uart_irq       : Std_Logic;
  signal uart_clk       : Std_Logic;
  signal rxbit          : Std_Logic;
  signal txbit          : Std_Logic;
  signal DCD_n          : Std_Logic;
  signal RTS_n          : Std_Logic;
  signal CTS_n          : Std_Logic;

  -- keyboard port
  signal keyboard_data_out : std_logic_vector(7 downto 0);
  signal keyboard_cs       : std_logic;
  signal keyboard_irq      : std_logic;

  -- Video Display Unit
  signal vga_clk      : std_logic;
  signal vdu_cs       : std_logic;
  signal vdu_data_out : std_logic_vector(7 downto 0);
  signal vga_red_i    : std_logic;
  signal vga_green_i  : std_logic;
  signal vga_blue_i   : std_logic;

  -- RAM
  signal ram_cs       : std_logic; -- memory chip select
  signal ram_data_out : std_logic_vector(7 downto 0);

  -- LED
  signal led_cs       : std_logic;
  signal led_reg      : std_logic_vector(7 downto 0);

  -- LCD
  signal lcd_cs       : std_logic;
  signal lcd_reg      : std_logic_vector(6 downto 0);

  -- SPI
  signal spi_cs       : std_logic;
  signal spi_data_out : std_logic_vector(7 downto 0);

  -- System SPI
  signal sys_spi_cs       : std_logic;
  signal sys_spi_data_out : std_logic_vector(7 downto 0);
  signal ad_conv_n        : std_logic;

  -- CPU Interface signals
  signal cpu_reset    : Std_Logic;
  signal cpu_clk      : Std_Logic;
  signal cpu_rw       : std_logic;
  signal cpu_vma      : std_logic;
  signal cpu_halt     : std_logic;
  signal cpu_hold     : std_logic;
  signal cpu_firq     : std_logic;
  signal cpu_irq      : std_logic;
  signal cpu_nmi      : std_logic;
  signal cpu_addr     : std_logic_vector(15 downto 0);
  signal cpu_data_in  : std_logic_vector(7 downto 0);
  signal cpu_data_out : std_logic_vector(7 downto 0);

  -- CLK_50M clock divide by 2
  signal clock_div    : std_logic_vector(1 downto 0);
  signal SysClk       : std_logic;
  signal Reset_n      : std_logic;
  signal CountL       : std_logic_vector(23 downto 0);
  
begin
  -----------------------------------------------------------------------------
  -- Instantiation of internal components
  -----------------------------------------------------------------------------

  my_cpu : entity cpu09  port map (    
    clk	     => cpu_clk,
    rst       => cpu_reset,
    rw	     => cpu_rw,
    vma       => cpu_vma,
    address   => cpu_addr(15 downto 0),
    data_in   => cpu_data_in,
    data_out  => cpu_data_out,
    halt      => cpu_halt,
    hold      => cpu_hold,
    irq       => cpu_irq,
    nmi       => cpu_nmi,
    firq      => cpu_firq
    );

  my_rom : entity rom port map (
    clk => cpu_clk,
    rst => cpu_reset,
    cs => '1',
    addr => cpu_addr(13 downto 0),
    data => rom_data_out
    );

  my_ram : entity ram_16k port map (
    clk   => cpu_clk,
    rst   => cpu_reset,
    cs    => ram_cs,
    rw    => cpu_rw,
    addr  => cpu_addr(13 downto 0),
    rdata => ram_data_out,
    wdata => cpu_data_out
    );

----------------------------------------
--
-- ACIA/UART Serial interface
--
----------------------------------------
  my_ACIA  : entity ACIA_6850 port map (
    clk	     => cpu_clk,
    rst       => cpu_reset,
    cs        => uart_cs,
    rw        => cpu_rw,
    irq       => uart_irq,
    Addr      => cpu_addr(0),
    Datain    => cpu_data_out,
    DataOut   => uart_data_out,
    RxC       => uart_clk,
    TxC       => uart_clk,
    RxD       => rxbit,
    TxD       => txbit,
    DCD_n     => dcd_n,
    CTS_n     => cts_n,
    RTS_n     => rts_n
    );

----------------------------------------
--
-- ACIA Clock
--
----------------------------------------
  my_ACIA_Clock : entity ACIA_Clock
    generic map(
      SYS_CLK_FREQ  => SYS_CLK_FREQ,
      ACIA_CLK_FREQ => ACIA_CLK_FREQ
      ) 
    port map(
      clk        => SysClk,
      acia_clk   => uart_clk
      ); 



----------------------------------------
--
-- PS/2 Keyboard Interface
--
----------------------------------------
  my_keyboard : entity keyboard
    generic map (
      KBD_CLK_FREQ => CPU_CLK_FREQ
      ) 
    port map(
      clk          => cpu_clk,
      rst          => cpu_reset,
      cs           => keyboard_cs,
      rw           => cpu_rw,
      addr         => cpu_addr(0),
      data_in      => cpu_data_out(7 downto 0),
      data_out     => keyboard_data_out(7 downto 0),
      irq          => keyboard_irq,
      kbd_clk      => PS2_CLK1,
      kbd_data     => PS2_DATA1
      );

----------------------------------------
--
-- Video Display Unit instantiation
--
----------------------------------------
  my_vdu : entity vdu8 
    generic map(
      VGA_CLK_FREQ           => VGA_CLK_FREQ, -- HZ
      VGA_HOR_CHARS          => 80, -- CHARACTERS
      VGA_VER_CHARS          => 25, -- CHARACTERS
      VGA_PIX_PER_CHAR       => 8,  -- PIXELS
      VGA_LIN_PER_CHAR       => 16, -- LINES
      VGA_HOR_BACK_PORCH     => 40, -- PIXELS
      VGA_HOR_SYNC           => 96, -- PIXELS
      VGA_HOR_FRONT_PORCH    => 24, -- PIXELS
      VGA_VER_BACK_PORCH     => 13, -- LINES
      VGA_VER_SYNC           => 1,  -- LINES
      VGA_VER_FRONT_PORCH    => 36  -- LINES
      )
    port map(

      -- Control Registers
      vdu_clk       => cpu_clk,					 -- 25 MHz System Clock in
      vdu_rst       => cpu_reset,
      vdu_cs        => vdu_cs,
      vdu_rw        => cpu_rw,
      vdu_addr      => cpu_addr(2 downto 0),
      vdu_data_in   => cpu_data_out,
      vdu_data_out  => vdu_data_out,

      -- vga port connections
      vga_clk       => vga_clk,					 -- 25 MHz VDU pixel clock
      vga_red_o     => vga_red_i,
      vga_green_o   => vga_green_i,
      vga_blue_o    => vga_blue_i,
      vga_hsync_o   => vga_hsync,
      vga_vsync_o   => vga_vsync
      );

  vga_r <= "1111" when vga_red_i = '1'   else "0000";
  vga_g <= "1111" when vga_green_i = '1' else "0000";
  vga_b <= "1111" when vga_blue_i = '1'  else "0000";


----------------------------------------
--
-- SPI master
--
----------------------------------------
  my_sys_spi_master : entity spi_master port map (
    clk                  => cpu_clk,
    reset                => cpu_reset,
    cs                   => sys_spi_cs,
    rw                   => cpu_rw,
    addr                 => cpu_addr(1 downto 0),
    data_in              => cpu_data_out,
    data_out             => sys_spi_data_out,
    irq                  => open,
    spi_clk              => SPI_SCK,
    spi_mosi             => SPI_MOSI,
    spi_miso             => SPI_MISO,
    spi_cs_n(0)          => DAC_CS,
    spi_cs_n(1)          => AMP_CS,
    spi_cs_n(2)          => ad_conv_n,
    spi_cs_n(3)          => SPI_SS_B,
    spi_cs_n(4)          => SF_CE0,
    spi_cs_n(7 downto 5) => open
    );

--
-- 25 MHz CPU clock
--
  cpu_clk_buffer : BUFG port map(
    i => clock_div(0),
    o => cpu_clk
    );
  
--
-- 25 MHz VGA Pixel clock
--
  vga_clk_buffer : BUFG port map(
    i => clock_div(0),
    o => vga_clk
    );	 
  
----------------------------------------------------------------------
--
-- Process to decode memory map
--
----------------------------------------------------------------------

  mem_decode: process( cpu_clk, Reset_n,
                       cpu_addr, cpu_rw, cpu_vma,
                       rom_data_out, 
                       ram_data_out,
                       uart_data_out,
                       keyboard_data_out,
                       vdu_data_out,
                       led_reg, sw, rot_a, rot_b, rot_center,
                       btn_north, btn_west, btn_east, btn_south,
                       spi_data_out, sys_spi_data_out)
    variable decode_addr : std_logic_vector(1 downto 0);
  begin
    decode_addr := cpu_addr(15 downto 14);

    cpu_data_in <= (others => '0');
    led_cs      <= '0';
    lcd_cs      <= '0';
    ram_cs      <= '0';
    spi_cs      <= '0';
    sys_spi_cs  <= '0';
    uart_cs     <= '0';
    keyboard_cs <= '0';
    vdu_cs      <= '0';

    case decode_addr is

      --
      -- 0000-3FFF: RAM
      --
      when "00" =>
        cpu_data_in <= ram_data_out;
        ram_cs      <= cpu_vma;

      --
      -- 4000-7FFF: Unmapped
      --
      when "01" =>
          null;
      --
      -- 8000-BFFF: I/O and unused
      --
      when "10" =>

        if cpu_addr(13 downto 8) = "110000" then  -- B000-B0FF

          case cpu_addr(7 downto 4) is

            --
            -- UART / ACIA $B000
            --
            when X"0" =>
              cpu_data_in <= uart_data_out;
              uart_cs     <= cpu_vma;

            --
            -- Keyboard port $B010
            --
            when X"1" =>
              cpu_data_in <= keyboard_data_out;
              keyboard_cs <= cpu_vma;

            --
            -- VDU port $B020
            --
            when X"2" =>
              cpu_data_in <= vdu_data_out;
              vdu_cs      <= cpu_vma;

            --
            -- LEDs, switches, buttons, encoder, LCD $B030
            --
            when X"3" =>
              case cpu_addr(3 downto 0) is
                when "0000" =>
                  cpu_data_in <= led_reg;
                  led_cs      <= cpu_vma;
                when "0001" =>
                  cpu_data_in <= BTN_NORTH
                                 & BTN_EAST
                                 & BTN_SOUTH
                                 & BTN_WEST
                                 & SW;
                when "0010" =>
                  cpu_data_in <= "000000" & ROT_A & ROT_B;
                when "0011" =>
                  lcd_cs <= cpu_vma;
                when others =>
                  null;
              end case;

            --
            -- SPI Masters $B040-$B047
            --
            when X"4" =>
              case cpu_addr(3 downto 2) is
                when "00" =>
                  cpu_data_in <= spi_data_out;
                  spi_cs      <= cpu_vma;
                when "01" =>
                  cpu_data_in <= sys_spi_data_out;
                  sys_spi_cs  <= cpu_vma;
                when others =>
                  null;
              end case;

            when others =>
              null;

          end case;
        end if;

      --
      -- C000-FFFF: Maisforth ROM
      --
      when others =>
        cpu_data_in <= rom_data_out;

    end case;
  end process;

--
-- Interrupts and other bus control signals
--
  interrupts : process( Reset_n, uart_irq, keyboard_irq )
  begin
    cpu_reset <= not Reset_n; -- CPU reset is active high
    cpu_irq   <= uart_irq or keyboard_irq;
    cpu_nmi   <= '0';
    cpu_firq  <= '0';
    cpu_halt  <= '0';
    cpu_hold  <= '0';
  end process;

--
--
  set_leds : process(sysclk)
  begin
    if falling_edge(sysclk) then
      if Reset_n = '0' then
        LED_reg <= (others => '0');
      elsif led_cs = '1' and cpu_rw = '0' then
        LED_reg <= cpu_data_out;
      end if;
    end if;
  end process;

  set_lcd : process(sysclk)
  begin
    if falling_edge(sysclk) then
      if reset_n = '0' then
        lcd_reg <= (others => '0');
      elsif lcd_cs = '1' and cpu_rw = '0' then
        lcd_reg <= cpu_data_out(6 downto 0);
      end if;
    end if;
  end process;

--
-- Clock divider
--
  my_clock_divider: process( SysClk )
  begin
    if falling_edge(SysClk) then
      clock_div <= clock_div + "01";
    end if;
  end process;

  LCD_RS <= lcd_reg(6);
  LCD_RW <= lcd_reg(5);
  LCD_E  <= lcd_reg(4);
  LCD_DB <= lcd_reg(3 downto 0);

  DCD_n         <= '0';
  CTS_n         <= '0';
  Reset_n       <= not ROT_CENTER;      -- CPU reset is active high
  SysClk        <= CLK_50M;
  rxbit         <= RS232_DCE_RXD;
  RS232_DCE_TXD <= txbit;
  led           <= led_reg;
  AD_CONV       <= not ad_conv_n;

  -- disable devices that would otherwise cause conflicts on the SPI bus
  FPGA_INIT_B   <= '0';
  SF_OE         <= '1';
  SF_WE         <= '1';
  
end my_computer;  --===================== End of architecture =======================--

