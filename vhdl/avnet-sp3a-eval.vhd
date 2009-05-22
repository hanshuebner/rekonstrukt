-- Top level for Avnet Spartan-3A Evaluation Board running rekonstrukt

library ieee;
use ieee.std_logic_1164.all;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use ieee.numeric_std.all;

entity my_system09 is
  port(
    CLK_16MHZ : in std_logic;

    -- Uart Interface
    UART_RXD : out std_logic;
    UART_TXD : in std_logic;

    -- System SPI interface
    FLASH_D00 : in  std_logic;
    FPGA_MOSI : out std_logic;
    SPI_CLK   : out std_logic;
    FPGA_SPI_SELn,
    SF_HOLDn,
    SF_Wn     : out std_logic;

    -- LEDS & Switches
    LED1,
    LED2,
    LED3,
    LED4        : out std_logic;
    FPGA_RESET,
    FPGA_PUSH_A,
    FPGA_PUSH_B,
    FPGA_PUSH_C : in  std_logic

   );
end my_system09;

-------------------------------------------------------------------------------
-- Architecture for System09
-------------------------------------------------------------------------------
architecture my_computer of my_system09 is
  -----------------------------------------------------------------------------
  -- constants
  -----------------------------------------------------------------------------
  constant SYSCLK_FREQ   : integer := 16000000;  -- System clock frequency
  constant BAUD_RATE     : integer := 19200;     -- Baud Rate
  constant ACIA_CLK_FREQ : integer := BAUD_RATE * 16;

  -----------------------------------------------------------------------------
  -- Signals
  -----------------------------------------------------------------------------

  -- Buffered system clock, 16 Mhz
  signal sysclk           : std_logic;
  signal sysclk_buf       : std_logic;
  -- System reset, active low
  signal reset_n          : std_logic;
  -- BOOT ROM
  signal rom_data_out     : std_logic_vector(7 downto 0);
  -- UART Interface signals
  signal uart_data_out    : std_logic_vector(7 downto 0);
  signal uart_cs          : std_logic;
  signal uart_irq         : std_logic;
  signal uart_clk         : std_logic;
  signal rxbit            : std_logic;
  signal txbit            : std_logic;
  signal DCD_n            : std_logic;
  signal RTS_n            : std_logic;
  signal CTS_n            : std_logic;
  -- RAM
  signal ram_cs           : std_logic;  -- memory chip select
  signal ram_data_out     : std_logic_vector(7 downto 0);
  -- LED
  signal led_cs           : std_logic;
  signal led_reg          : std_logic_vector(7 downto 0);
  -- Buttons
  signal button_reg       : std_logic_vector(7 downto 0);
  -- SPI
  signal spi_cs           : std_logic;
  signal spi_data_out     : std_logic_vector(7 downto 0);
  signal spi_irq          : std_logic;
  -- System SPI
  signal sys_spi_cs       : std_logic;
  signal sys_spi_data_out : std_logic_vector(7 downto 0);
  signal sys_spi_irq      : std_logic;
  signal ad_conv_n        : std_logic;
  -- Timer
  signal timer_cs         : std_logic;
  signal timer_irq        : std_logic;
  signal timer_data_out   : std_logic_vector(7 downto 0);
  -- MIDI
  signal midi_cs          : std_logic;
  signal midi_irq         : std_logic;
  signal midi_data_out    : std_logic_vector(7 downto 0);
  signal midi_led         : std_logic;
  signal midi_tx          : std_logic;
  -- Clocks
  signal clk_1mhz         : std_logic;
  -- IRQ buffer
  signal irq_buffer       : std_logic_vector(7 downto 0);
  -- CPU Interface signals
  signal cpu_reset        : std_logic;
  signal cpu_rw           : std_logic;
  signal cpu_vma          : std_logic;
  signal cpu_halt         : std_logic;
  signal cpu_hold         : std_logic;
  signal cpu_firq         : std_logic;
  signal cpu_irq          : std_logic;
  signal cpu_nmi          : std_logic;
  signal cpu_addr         : std_logic_vector(15 downto 0);
  signal cpu_data_in      : std_logic_vector(7 downto 0);
  signal cpu_data_out     : std_logic_vector(7 downto 0);
  -- Unused SPI CS signals need to be connected to something, so here:
  signal unused_cs        : std_logic_vector(15 downto 0);
  -- CPU status signal(s)
  signal halted           : std_logic;
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
    firq     => cpu_firq,
    halted   => halted
   );

  my_rom : entity rom port map (
    clk   => sysclk,
    rst   => cpu_reset,
    cs    => '1',
    addr  => cpu_addr(13 downto 0),
    rdata => rom_data_out
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
-- SPI master
--
----------------------------------------
  --my_spi_master : entity spi_master port map (
  --  clk                  => sysclk,
  --  reset                => cpu_reset,
  --  cs                   => spi_cs,
  --  rw                   => cpu_rw,
  --  addr                 => cpu_addr(1 downto 0),
  --  data_in              => cpu_data_out,
  --  data_out             => spi_data_out,
  --  irq                  => spi_irq,
  --  spi_clk              => j4(0),
  --  spi_mosi             => j4(1),
  --  spi_miso             => j4(2),
  --  spi_cs_n(0)          => j4(3),
  --  spi_cs_n(7 downto 1) => unused_cs(6 downto 0)
  -- );

  my_sys_spi_master : entity spi_master port map (
    clk                  => sysclk,
    reset                => cpu_reset,
    cs                   => sys_spi_cs,
    rw                   => cpu_rw,
    addr                 => cpu_addr(1 downto 0),
    data_in              => cpu_data_out,
    data_out             => sys_spi_data_out,
    irq                  => sys_spi_irq,
    spi_clk              => SPI_CLK,
    spi_mosi             => FPGA_MOSI,
    spi_miso             => FLASH_D00,
    spi_cs_n(0)          => FPGA_SPI_SELn,
    spi_cs_n(7 downto 1) => unused_cs(6 downto 0)
    );

  my_clock_div : entity clock_div
    generic map (INPUT_CLK_FREQ => SYSCLK_FREQ)
    port map (
    clk        => sysclk,
    reset      => cpu_reset,
    clk_1mhz   => clk_1mhz
    );

  my_timer : entity timer port map (
    clk       => sysclk,
    rst       => cpu_reset,
    cs        => timer_cs,
    rw        => cpu_rw,
    addr      => cpu_addr(2 downto 0),
    data_in   => cpu_data_out,
    data_out  => timer_data_out,
    --
    clk_1mhz  => clk_1mhz,
    timer_irq => timer_irq
    );

  my_midi : entity midi port map (
    clk      => sysclk,
    rst      => cpu_reset,
    cs       => midi_cs,
    rw       => cpu_rw,
    addr     => cpu_addr(7 downto 0),
    data_in  => cpu_data_out,
    data_out => midi_data_out,
    --
    clk_1mhz => clk_1mhz,
    midi_tx  => midi_tx,
    midi_led => midi_led);

  CLK_16MHZ_IBUFG : IBUFG
    port map (I => CLK_16MHZ,
              O => sysclk_buf);

  sysclk_BUFG : BUFG
    port map (I => sysclk_buf,
              O => sysclk);

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
                      led_reg,
                      spi_data_out, sys_spi_data_out,
                      timer_data_out, irq_buffer,
                      midi_data_out)
    variable decode_addr : std_logic_vector(1 downto 0);
  begin
    decode_addr := cpu_addr(15 downto 14);

    cpu_data_in <= (others => '0');
    led_cs      <= '0';
    ram_cs      <= '0';
    spi_cs      <= '0';
    sys_spi_cs  <= '0';
    uart_cs     <= '0';
    timer_cs    <= '0';
    midi_cs     <= '0';

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
            -- LEDs, switches, buttons $B030
            --
            when X"3" =>
              case cpu_addr(3 downto 0) is
                when "0000" =>
                  cpu_data_in <= led_reg;
                  led_cs      <= cpu_vma;
                when "0001" =>
                  cpu_data_in <= button_reg;
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

            --
            -- Timer clock generation $B050-$B057
            --
            when X"5" =>
              cpu_data_in <= timer_data_out;
              timer_cs    <= cpu_vma;

            --
            -- IRQ buffer readout $B0F0
            --
            when X"F" =>
              cpu_data_in <= irq_buffer;

            when others =>
              null;

          end case;

        elsif cpu_addr(13 downto 8) = "110001" then  -- B100-B1FF, MIDI

          midi_cs     <= cpu_vma;
          cpu_data_in <= midi_data_out;

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
  interrupts : process(reset_n, uart_irq, timer_irq, spi_irq, sys_spi_irq)
  begin
    cpu_reset <= not reset_n; -- CPU reset is active high
    cpu_irq   <= uart_irq or timer_irq or spi_irq or sys_spi_irq;
    cpu_nmi   <= '0';
    cpu_firq  <= '0';
    cpu_halt  <= '0';
    cpu_hold  <= '0';
  end process;

  irq_buffer <= (0 => uart_irq,
                 2 => timer_irq,
                 3 => spi_irq,
                 4 => sys_spi_irq,
                 others => '0');

  set_leds : process(sysclk)
  begin
    if falling_edge(sysclk) then
      if reset_n = '0' then
        LED_reg <= (others => '0');
      elsif led_cs = '1' and cpu_rw = '0' then
        LED_reg(6 downto 0) <= cpu_data_out(6 downto 0);
      end if;
    end if;
  end process;

  read_buttons : process(sysclk)
  begin
    if falling_edge(sysclk) then
      button_reg <= (2      => FPGA_PUSH_C,
                     1      => FPGA_PUSH_B,
                     0      => FPGA_PUSH_A,
                     others => '0');
    end if;
  end process;


  reset_key : process(sysclk)
  begin
    if falling_edge(sysclk) then
      reset_n <= not FPGA_RESET;        -- CPU reset is active high
    end if;
  end process;

  DCD_n    <= '0';
  CTS_n    <= '0';
  rxbit    <= UART_TXD;
  UART_RXD <= txbit;

  LED1 <= led_reg(0);
  LED2 <= led_reg(1);
  LED3 <= led_reg(2);
  LED4 <= led_reg(3);

  SF_HOLDn <= '1';
  SF_Wn    <= '1';

end my_computer;  --===================== End of architecture =======================--

