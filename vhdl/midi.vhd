-- midi.vhd midi in/out/sequencer module

-- First sketch:
--
-- 8 track sequencer
-- 1/16th resolution
-- One instrument
--
-- Address map:
-- 00-0F - Pattern track 0
-- 10-1F - Pattern track 1
-- ..
-- 70-7F - Pattern track 7
-- 80-87 - Note assignment track 0-7
-- 88    - Pattern select
-- 89-8A - Tempo (usec/96th)
-- 8B    - Control, 0: midi_enable

library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity midi is
  port(
    -- CPU bus interface
    clk      : in  std_logic;
    rst      : in  std_logic;
    cs       : in  std_logic;
    rw       : in  std_logic;
    addr     : in  std_logic_vector(7 downto 0);
    data_in  : in  std_logic_vector(7 downto 0);
    data_out : out std_logic_vector(7 downto 0);
    --
    clk_1mhz : in  std_logic;
    midi_tx  : out std_logic;
    midi_led : out std_logic
    );
end midi;

architecture rtl of midi is

  -- Counter and divider for MIDI clock
  signal midi_count        : std_logic_vector(15 downto 0);
  signal sequencer_running : std_logic;
  signal buf_1mhz          : std_logic;
  signal clk_midi_stb      : std_logic;
  signal clk_midi          : std_logic;
  signal clk_midi_serial   : std_logic;
  -- Interface to the dual port pattern ram
  signal ram_we            : std_logic;
  signal ram_read_addr     : std_logic_vector(10 downto 0);  -- UART RAM read address
  signal ram_host_addr     : std_logic_vector(10 downto 0);  -- Host RAM read address
  signal ram_read_data     : std_logic_vector(7 downto 0);  -- UART RAM read port
  signal ram_host_data     : std_logic_vector(7 downto 0);  -- Host RAM read port
  -- Interface to serial transmitter
  signal uart_we           : std_logic;
  signal uart_empty        : std_logic;
  signal uart_data         : std_logic_vector(7 downto 0);

  --
  -- Sequencer variables
  --

  -- Current pattern number
  signal pattern         : std_logic_vector(3 downto 0);
  -- Current tempo
  signal tempo           : std_logic_vector(15 downto 0);
  -- Notes assignment array, defines the note that each channel plays
  type   notes_assignment is array(7 downto 0) of std_logic_vector(7 downto 0);
  signal notes           : notes_assignment;
  -- Playback stuff
  -- Channel number to check next
  signal channel         : std_logic_vector(2 downto 0);
  -- Current pattern position
  signal pattern_pos     : std_logic_vector(3 downto 0);
  -- Midi clock divider stuff
  signal clk_16th_stb    : std_logic;
  signal clk_16th        : std_logic;
  signal buf_clk_midi    : std_logic;
  signal count_96th      : std_logic_vector(2 downto 0);
  -- Sequencer state
  type   sequencer_state_type is (s_waiting, s_play_note, s_wait_uart, s_pause);
  signal sequencer_state : sequencer_state_type;

begin

  pattern_ram : entity dp_ram port map(
    clk  => clk,
    we   => ram_we,
    a    => ram_host_addr,
    dpra => ram_read_addr,
    di   => data_in,
    spo  => ram_host_data,
    dpo  => ram_read_data);

  ram_host_addr              <= pattern & addr(6 downto 0);
  ram_read_addr(10 downto 7) <= pattern;

  handle_host_write : process(clk, rst)
  begin
    if rst = '1' then
      tempo             <= (others => '0');
      sequencer_running <= '0';
    elsif falling_edge(clk) then
      if cs = '1' and rw = '0' then
        if addr(7) = '1' then
          if addr(6 downto 3) = "0000" then
            -- write to note assignment number
            notes(conv_integer(addr(2 downto 0))) <= data_in;
          else
            case addr(7 downto 0) is
              when X"88"  => pattern            <= data_in(3 downto 0);
              when X"89"  => tempo(15 downto 8) <= data_in;
              when X"8A"  => tempo(7 downto 0)  <= data_in;
              when X"8B"  => sequencer_running  <= data_in(0);
              when others => null;
            end case;
          end if;
        end if;
      end if;
    end if;
  end process;

  gen_ram_we : process(cs, rw, addr)
  begin
    if cs = '1' and rw = '0' and addr(7) = '0' then
      ram_we <= '1';
    else
      ram_we <= '0';
    end if;
  end process;

  handle_host_read : process(tempo, addr, sequencer_running, pattern, pattern_pos, notes, ram_host_data)
  begin
    data_out <= (others => '0');
    if addr(7) = '0' then
      -- read from pattern memory
      data_out <= ram_host_data;
    elsif addr(6 downto 3) = "0000" then
      -- read note assignment number
      data_out <= notes(conv_integer(addr(2 downto 0)));
    else
      case conv_integer(addr(6 downto 0)) is
        when 16#8#  => data_out(3 downto 0) <= pattern;
        when 16#9#  => data_out             <= tempo(15 downto 8);
        when 16#A#  => data_out             <= tempo(7 downto 0);
        when 16#B#  => data_out(0)          <= sequencer_running;
        when others => null;
      end case;
    end if;
  end process;

  -- generate midi clock
  gen_midi_stb : process(clk, rst)
  begin
    if rst = '1' then
      midi_count   <= (others => '0');
      clk_midi_stb <= '0';
    elsif falling_edge(clk) then
      if sequencer_running = '1' then
        if buf_1mhz = '0' and clk_1mhz = '1' then
          midi_count   <= midi_count + 1;
          clk_midi_stb <= '0';
          if midi_count = tempo then
            midi_count   <= (0 => '1', others => '0');
            clk_midi_stb <= '1';
          end if;
        end if;
      end if;
    end if;
  end process;

  shape_clk_midi : entity pulse_shaper port map (
    clk => clk,
    rst => rst,
    d => clk_midi_stb,
    q => clk_midi
  );

  gen_clk_16th : process(clk, rst)
  begin
    if rst = '1' then
      count_96th   <= (others => '0');
      clk_16th_stb <= '0';
    elsif rising_edge(clk) then
      buf_clk_midi <= clk_midi;
      if clk_midi = '1' and buf_clk_midi = '0' then
        count_96th   <= count_96th + 1;
        clk_16th_stb <= '0';
        if count_96th = "101" then
          count_96th   <= (others => '0');
          clk_16th_stb <= '1';
        end if;
      end if;
    end if;
  end process;

  shape_clk_16th : entity pulse_shaper port map (
    clk => clk,
    rst => rst,
    d => clk_16th_stb,
    q => clk_16th
  );

  gen_midi_serial_clk : process(clk, rst)
  begin
    if rst = '1' then
      clk_midi_serial <= '0';
    elsif falling_edge(clk) then
      if clk_1mhz = '1' and buf_1mhz = '0' then
        clk_midi_serial <= not clk_midi_serial;
      end if;
    end if;
  end process;

  -- Buffer 1 Mhz clock to be used as clock by midi clock modules
  buf_clk : process(clk)
  begin
    if falling_edge(clk) then
      buf_1mhz <= clk_1mhz;
    end if;
  end process;

  -- Instantiate MIDI transmitter
  midi_uart : entity ACIA_TX port map(
    clk   => clk,
    reset => rst,
    wr    => uart_we,
    din   => uart_data,
    wdfmt => "101",                     -- 8n1
    bdfmt => "01",                      -- divide clk by 16
    txclk => clk_midi_serial,
    dat   => midi_tx,
    empty => uart_empty);

  -- For now, just connect the uart data port to the secondary RAM output.
  -- We'll propably want a multiplexer here
  uart_data     <= notes(conv_integer(channel));
  ram_read_addr <= pattern & channel & pattern_pos;

  sequencer : process(clk, rst)
  begin
    if rst = '1' then
      channel     <= (others => '0');
      pattern_pos <= (others => '0');
      uart_we     <= '0';
    elsif falling_edge(clk) then
      uart_we <= '0';
      case sequencer_state is
        when s_waiting =>
          if sequencer_running = '0' then
            sequencer_state <= s_pause;
          elsif clk_16th = '1' then
            sequencer_state <= s_play_note;
          end if;
        when s_play_note =>
          if uart_empty = '1' then
            channel <= channel + 1;
            if ram_read_data /= X"00" then
              uart_we         <= '1';
              sequencer_state <= s_wait_uart;
            end if;
            if channel = "110" then
              sequencer_state <= s_waiting;
              pattern_pos     <= pattern_pos + 1;
            end if;
          end if;
        when s_wait_uart =>
          sequencer_state <= s_play_note;
        when s_pause =>
          if sequencer_running = '1' then
            sequencer_state <= s_waiting;
          end if;
      end case;
    end if;
  end process;

  gen_led : process(clk, rst)
  begin
    if rst = '1' then
      midi_led <= '0';
    elsif falling_edge(clk) then
      midi_led <= '0';
      if sequencer_running = '1' then
        if pattern_pos(1 downto 0) = "00" or pattern_pos = "0001" then
          midi_led <= '1';
        end if;
      end if;
    end if;
  end process;
end;
