-- $Id: System09_Digilent_3S500E.vhd,v 1.3.2.1 2008/04/08 14:59:48 davidgb Exp $
--===========================================================================----
--
--  S Y N T H E Z I A B L E    System09 - SOC.
--
--===========================================================================----
--
--  This core adheres to the GNU public license  
--
-- Purpose        : Top level file for 6809 compatible system on a chip
--                  Designed with Xilinx XC4VLX25 FPGA.
--                  Implemented with Xilinx ML401 FPGA board,

library ieee;
use ieee.std_logic_1164.all;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use ieee.numeric_std.all;

entity my_system09 is
  port(
    -- clock, reset
    sys_clk_in,
    sys_rst_in      : in    std_logic;
    -- UART
    uart_rx         : in    std_logic;
    uart_tx         : out   std_logic;
    -- Misc. on-board I/O
    ext_irq         : in    std_logic;
    gpio            : inout std_logic_vector(26 downto 0);
    -- PS/2 keyboard and mouse
    ps2_keyb_clk,
    ps2_keyb_data,
    ps2_mouse_clk,
    ps2_mouse_data  : inout std_logic;
    -- I2C bus
    iic_scl         : inout std_logic;
    iic_sda         : inout std_logic;
    -- AC97 audio controller
    ac97_bit_clk    : inout std_logic;
    ac97_sdata_in   : out   std_logic;
    ac97_reset_n    : out   std_logic;
    ac97_sdata_out  : in    std_logic;
    ac97_sync       : out   std_logic;
    -- VGA DAC
    tft_lcd_r,
    tft_lcd_g,
    tft_lcd_b       : out   std_logic_vector(5 downto 0);
    tft_lcd_clk,
    tft_lcd_hsync,
    tft_lcd_vsync   : out   std_logic;
    -- Error LEDs
    plb_error,
    obp_error       : out   std_logic;
    -- SRAM and Flash
    sram_clk        : out   std_logic;
    sram_clk_fb     : in    std_logic;
    flash_a23       : out   std_logic;
    sram_flash_addr : out   std_logic_vector(22 downto 0);
    sram_flash_data : inout std_logic_vector(31 downto 0);
    sram_cen,
    sram_flash_oe_n,
    sram_flash_we_n,
    flash_ce,
    sram_adv_ld_n,
    sram_mode       : out   std_logic;
    sram_bw         : out   std_logic_vector(3 downto 0);
    -- GPIO on expansion header
    gpio_exp_hdr1   : inout std_logic_vector(31 downto 0);
    gpio_exp_hdr2   : inout std_logic_vector(31 downto 0);
    -- LCD
    gpio_char_lcd   : inout std_logic_vector(6 downto 0)
   );
end my_system09;

-------------------------------------------------------------------------------
-- Architecture for System09
-------------------------------------------------------------------------------
architecture my_computer of my_system09 is
  -----------------------------------------------------------------------------
  -- constants
  -----------------------------------------------------------------------------
  constant CLKIN_FREQ    : integer := 100000000;  -- FPGA input System Clock
  constant SYSCLK_FREQ   : integer := 25000000;   -- System clock frequency
  constant BAUD_RATE     : integer := 19200;      -- Baud Rate
  constant ACIA_CLK_FREQ : integer := BAUD_RATE * 16;

  -----------------------------------------------------------------------------
  -- Signals
  -----------------------------------------------------------------------------

  -- Buffered system clock, 25 Mhz
  signal sysclk            : std_logic;
  -- DCM locked signal
  signal dcm_locked        : std_logic;
  -- System reset, active low
  signal reset_n           : std_logic;
  -- BOOT ROM
  signal rom_data_out      : std_logic_vector(7 downto 0);
  -- UART Interface signals
  signal uart_data_out     : std_logic_vector(7 downto 0);
  signal uart_cs           : std_logic;
  signal uart_irq          : std_logic;
  signal uart_clk          : std_logic;
  signal rxbit             : std_logic;
  signal txbit             : std_logic;
  signal DCD_n             : std_logic;
  signal RTS_n             : std_logic;
  signal CTS_n             : std_logic;
  -- keyboard port
  signal keyboard_data_out : std_logic_vector(7 downto 0);
  signal keyboard_cs       : std_logic;
  signal keyboard_irq      : std_logic;
  -- Video Display Unit
  signal vdu_cs            : std_logic;
  signal vdu_data_out      : std_logic_vector(7 downto 0);
  -- RAM
  signal ram_cs            : std_logic;  -- memory chip select
  signal ram_data_out      : std_logic_vector(7 downto 0);
  -- LED
  signal led_cs            : std_logic;
  signal led_reg           : std_logic_vector(7 downto 0);
  -- LCD
  signal lcd_cs            : std_logic;
  signal lcd_reg           : std_logic_vector(6 downto 0);
  -- SPI
  signal spi_cs            : std_logic;
  signal spi_data_out      : std_logic_vector(7 downto 0);
  -- System SPI
  signal sys_spi_cs        : std_logic;
  signal sys_spi_data_out  : std_logic_vector(7 downto 0);
  signal ad_conv_n         : std_logic;
  -- CPU Interface signals
  signal cpu_reset         : std_logic;
  signal cpu_rw            : std_logic;
  signal cpu_vma           : std_logic;
  signal cpu_halt          : std_logic;
  signal cpu_hold          : std_logic;
  signal cpu_firq          : std_logic;
  signal cpu_irq           : std_logic;
  signal cpu_nmi           : std_logic;
  signal cpu_addr          : std_logic_vector(15 downto 0);
  signal cpu_data_in       : std_logic_vector(7 downto 0);
  signal cpu_data_out      : std_logic_vector(7 downto 0);
  
begin
  -----------------------------------------------------------------------------
  -- Instantiation of internal components
  -----------------------------------------------------------------------------

  my_cpu : entity cpu09 port map (
    clk      => sysclk,
    rst      => cpu_reset,
    rw       => cpu_rw,
    vma      => cpu_vma,
    address  => cpu_addr(15 downto 0),
    data_in  => cpu_data_in,
    data_out => cpu_data_out,
    halt     => cpu_halt,
    hold     => cpu_hold,
    irq      => cpu_irq,
    nmi      => cpu_nmi,
    firq     => cpu_firq
   );

  my_rom : entity rom port map (
    clk  => sysclk,
    rst  => cpu_reset,
    cs   => '1',
    addr => cpu_addr(13 downto 0),
    data => rom_data_out
   );

  my_ram : entity ram_16k port map (
    clk   => sysclk,
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
  my_ACIA : entity ACIA_6850 port map (
    clk     => sysclk,
    rst     => cpu_reset,
    cs      => uart_cs,
    rw      => cpu_rw,
    irq     => uart_irq,
    Addr    => cpu_addr(0),
    Datain  => cpu_data_out,
    DataOut => uart_data_out,
    RxC     => uart_clk,
    TxC     => uart_clk,
    RxD     => rxbit,
    TxD     => txbit,
    DCD_n   => dcd_n,
    CTS_n   => cts_n,
    RTS_n   => rts_n
   );

----------------------------------------
--
-- ACIA Clock
--
----------------------------------------
  my_ACIA_Clock : entity ACIA_Clock
    generic map(
      SYS_CLK_FREQ  => SYSCLK_FREQ,
      ACIA_CLK_FREQ => ACIA_CLK_FREQ
     ) 
    port map(
      clk        => sysclk,
      acia_clk   => uart_clk
     ); 



----------------------------------------
--
-- PS/2 Keyboard Interface
--
----------------------------------------
  my_keyboard : entity keyboard
    generic map (
      KBD_CLK_FREQ => SYSCLK_FREQ
     ) 
    port map(
      clk      => sysclk,
      rst      => cpu_reset,
      cs       => keyboard_cs,
      rw       => cpu_rw,
      addr     => cpu_addr(0),
      data_in  => cpu_data_out(7 downto 0),
      data_out => keyboard_data_out(7 downto 0),
      irq      => keyboard_irq,
      kbd_clk  => PS2_CLK,
      kbd_data => PS2_DATA
     );

----------------------------------------
--
-- Video Display Unit instantiation
--
----------------------------------------
  my_vdu : entity vdu8 
    generic map(
      VDU_CLK_FREQ           => SYSCLK_FREQ, -- HZ
      VGA_CLK_FREQ           => SYSCLK_FREQ, -- HZ
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
      vdu_clk       => sysclk,					 -- 25 MHz System Clock in
      vdu_rst       => cpu_reset,
      vdu_cs        => vdu_cs,
      vdu_rw        => cpu_rw,
      vdu_addr      => cpu_addr(2 downto 0),
      vdu_data_in   => cpu_data_out,
      vdu_data_out  => vdu_data_out,

      -- vga port connections
      vga_clk       => sysclk,					 -- 25 MHz VDU pixel clock
      vga_red_o     => vga_red,
      vga_green_o   => vga_green,
      vga_blue_o    => vga_blue,
      vga_hsync_o   => vga_hsync,
      vga_vsync_o   => vga_vsync
     );

  my_clock_synthesis : entity clock_synthesis port map (
    CLKIN_IN   => sys_clk_in,
    CLKDV_OUT  => sysclk,
    LOCKED_OUT => dcm_locked
    );
----------------------------------------------------------------------
--
-- Process to decode memory map
--
----------------------------------------------------------------------

  mem_decode: process(sysclk, reset_n,
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
  interrupts : process(reset_n, uart_irq, keyboard_irq)
  begin
    cpu_reset <= not reset_n; -- CPU reset is active high
    cpu_irq   <= uart_irq or keyboard_irq;
    cpu_nmi   <= '0';
    cpu_firq  <= '0';
    cpu_halt  <= '0';
    cpu_hold  <= '0';
  end process;

  set_leds : process(sysclk)
  begin
    if falling_edge(sysclk) then
      if reset_n = '0' then
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

  reset_key : process(sysclk)
  begin
    if dcm_locked = '0' then
      reset_n <= '0';
    elsif falling_edge(sysclk) then
      reset_n <= not ROT_CENTER;        -- CPU reset is active high
    end if;
  end process;

  lcd_rs            <= lcd_reg(6);
  lcd_rw            <= lcd_reg(5);
  lcd_e             <= lcd_reg(4);
  sf_d(11 downto 8) <= lcd_reg(3 downto 0);

  DCD_n         <= '0';
  CTS_n         <= '0';
  rxbit         <= RS232_DCE_RXD;
  RS232_DCE_TXD <= txbit;
  RS232_DTE_TXD <= rts_n;

  led           <= led_reg;
  AD_CONV       <= not ad_conv_n;

  -- disable devices that would otherwise cause conflicts on the SPI bus
  FPGA_INIT_B   <= '0';
  SF_OE         <= '1';
  SF_WE         <= '1';

  fx2_io <= (5 => RS232_DCE_RXD, 6 => txbit, 7 => CTS_n, 8 => RTS_n, others => '0');

end my_computer;  --===================== End of architecture =======================--

