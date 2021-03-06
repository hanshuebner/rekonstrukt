-- $Id: System09_Digilent_3S500E.vhd,v 1.3.2.1 2008/04/08 14:59:48 davidgb Exp $
--===========================================================================----
--
--  S Y N T H E Z I A B L E    System09 - SOC.
--
--===========================================================================----
--
--  This core adheres to the GNU public license  
--
-- File name      : nb3000xn-maisforth.vhd
--
-- Purpose        : Top level file for 6809 compatible system on a chip
--                  Designed with Xilinx XC3S1400AN Spartan 3A FPGA.
--                  Implemented with Altium Nanoboard 3000XN.
--
-- Author         : John E. Kent      
--                  dilbert57@opencores.org
-- This port      : Hans Huebner (hans.huebner@gmail.com)

library ieee;
use ieee.std_logic_1164.all;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use ieee.numeric_std.all;

entity my_system09 is
  port(
    CLK_BRD : in Std_Logic;             -- System Clock input

    -- PS/2 Keyboard
    PS2A_CLK  : inout Std_logic;
    PS2A_DATA : inout Std_Logic;

    -- CRTC output signals
    VGA_VSYNC : out Std_Logic;
    VGA_HSYNC : out std_logic;
    VGA_RED   : out std_logic_vector(7 downto 0);
    VGA_GREEN : out std_logic_vector(7 downto 0);
    VGA_BLUE  : out std_logic_vector(7 downto 0);

    -- Uart Interface
    RS_RX : in  std_logic;
    RS_TX : out std_logic;

    -- LEDS & Switches
    LED_R : out std_logic_vector(7 downto 0);
    LED_G : out std_logic_vector(7 downto 0);
    LED_B : out std_logic_vector(7 downto 0);
    SW    : in  std_logic_vector(7 downto 0)
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
  signal led_r_cs     : std_logic;
  signal led_r_reg    : std_logic_vector(7 downto 0);
  signal led_g_cs     : std_logic;
  signal led_g_reg    : std_logic_vector(7 downto 0);
  signal led_b_cs     : std_logic;
  signal led_b_reg    : std_logic_vector(7 downto 0);

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

  -- CLK_BRD clock divide by 2
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
    rdata => rom_data_out
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
      kbd_clk      => PS2A_CLK,
      kbd_data     => PS2A_DATA
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

  vga_red   <= "11111111" when vga_red_i = '1'   else "00000000";
  vga_green <= "11111111" when vga_green_i = '1' else "00000000";
  vga_blue  <= "11111111" when vga_blue_i = '1'  else "00000000";


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
                       led_r_reg, led_g_reg, led_b_reg,
                       sw)
    variable decode_addr : std_logic_vector(1 downto 0);
  begin
    decode_addr := cpu_addr(15 downto 14);

    cpu_data_in <= (others => '0');
    led_r_cs    <= '0';
    led_g_cs    <= '0';
    led_b_cs    <= '0';
    ram_cs      <= '0';
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
                  cpu_data_in <= led_r_reg;
                  led_r_cs    <= cpu_vma;
                when "0001" =>
                  cpu_data_in <= led_g_reg;
                  led_g_cs    <= cpu_vma;
                when "0010" =>
                  cpu_data_in <= led_b_reg;
                  led_b_cs    <= cpu_vma;
                when "0011" =>
                  cpu_data_in <= sw;
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
        LED_r_reg <= (others => '0');
        LED_g_reg <= (others => '0');
        LED_b_reg <= (others => '0');
      elsif led_r_cs = '1' and cpu_rw = '0' then
        LED_r_reg <= cpu_data_out;
      elsif led_g_cs = '1' and cpu_rw = '0' then
        LED_g_reg <= cpu_data_out;
      elsif led_b_cs = '1' and cpu_rw = '0' then
        LED_b_reg <= cpu_data_out;
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

  DCD_n   <= '0';
  CTS_n   <= '0';
  Reset_n <= not sw(0);                 -- CPU reset is active high
  SysClk  <= CLK_BRD;
  rxbit   <= RS_RX;
  RS_TX   <= txbit;
  led_r   <= led_r_reg;
  led_g   <= led_g_reg;
  led_b   <= led_b_reg;

end my_computer;  --===================== End of architecture =======================--

