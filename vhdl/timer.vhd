-- timer.vhd

-- Timer module, provides for high resolution timestamps, down counters and the
-- like

-- Bugs: 1khz clock is not precise

Library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

entity timer is
  port(
    -- CPU bus interface
    clk       : in  std_logic;
    rst       : in  std_logic;
    cs        : in  std_logic;
    rw        : in  std_logic;
    addr      : in  std_logic_vector(2 downto 0);
    data_in   : in  std_logic_vector(7 downto 0);
    data_out  : out std_logic_vector(7 downto 0);
    -- 
    clk_1mhz  : in  std_logic;
    clk_midi  : out std_logic;
    timer_irq : out std_logic
    );
end timer;

architecture rtl of timer is

  -- Counter and divider for MIDI clock
  signal midi_count      : std_logic_vector(15 downto 0);
  signal midi_div        : std_logic_vector(15 downto 0);
  signal clk_midi_enable : std_logic;
  signal buf_1mhz        : std_logic;
  signal clk_midi_stb    : std_logic;
  signal clk_midi_buf    : std_logic;

  -- General purpose timer, 1ms resolution, counts down, then interrupts
  signal timer_count  : std_logic_vector(15 downto 0);
  signal timer_end    : std_logic_vector(15 downto 0);
  signal timer_div    : std_logic_vector(9 downto 0);
  --
  type   timer_state_type is (TSIdle, TSRunning, TSFinished);
  signal timer_state  : timer_state_type;
  signal timer_start  : std_logic;
  signal timer_irqack : std_logic;
  signal clk_1khz     : std_logic;
  signal timer_zero   : std_logic;

begin

  handle_host_write : process(clk, rst)
  begin
    if rst = '1' then
      midi_div        <= (others => '0');
      clk_midi_enable <= '0';
    elsif falling_edge(clk) then
      if cs = '1' and rw = '0' then
        timer_start  <= '0';
        timer_irqack <= '0';
        case addr is
          -- Midi clock register write
          when "000" =>
            clk_midi_enable <= data_in(0);
          when "001" =>
            midi_div(15 downto 8) <= data_in;
          when "010" =>
            midi_div(7 downto 0) <= data_in;
          -- Millisecond timer register write
          when "100" =>
            timer_start  <= data_in(0);
            if data_in(0) = '0' then
              timer_irqack <= '1';
            end if;
          when "101" =>
            timer_end(15 downto 8) <= data_in;
          when "110" =>
            timer_end(7 downto 0) <= data_in;
          when others =>
            null;
        end case;
      end if;
    end if;
  end process;

  handle_host_read : process(midi_div, timer_state, addr)
  begin
    case addr is
      -- Midi clock readback
      when "001" =>
        data_out <= midi_div(15 downto 8);
      when "010" =>
        data_out <= midi_div(7 downto 0);
      -- Timer finished
      when "100" =>
        if timer_state = TSRunning then
          data_out(0) <= '1';
        else
          data_out(0) <= '0';
        end if;
        data_out(7 downto 1) <= (others => '0');
      when others =>
        data_out <= (others => '0');
    end case;
  end process;

  -- generate midi clock
  gen_midi_stb : process(clk, rst)
  begin
    if rst = '1' then
      midi_count <= (others => '0');
      clk_midi_stb <= '0';
    elsif falling_edge(clk) then
      if clk_midi_enable = '1' then
        if buf_1mhz = '0' and clk_1mhz = '1' then
          midi_count   <= midi_count + 1;
          clk_midi_stb <= '0';
          if midi_count = midi_div then
            midi_count   <= (0 => '1', others => '0');
            clk_midi_stb <= '1';
          end if;
        end if;
      end if;
    end if;
  end process;

  -- generate one clk cycle midi clock pulses
  gen_clk_midi : process(clk, rst)
  begin
    if rst = '1' then
      clk_midi     <= '0';
      clk_midi_buf <= '0';
    elsif falling_edge(clk) then
      clk_midi_buf <= clk_midi_stb;
      clk_midi     <= '0';
      if clk_midi_buf = '0' and clk_midi_stb = '1' then
        clk_midi <= '1';
      end if;
    end if;
  end process;

  -- Buffer 1 Mhz clock to be used as clock by timer modules
  buf_clk : process(clk)
  begin
    if falling_edge(clk) then
      buf_1mhz <= clk_1mhz;
    end if;
  end process;

  timer_state_machine : process(clk, rst)
  begin
    if rst = '1' then
      timer_state <= TSIdle;
    elsif falling_edge(clk) then
      case timer_state is
        when TSIdle =>
          timer_irq   <= '0';
          if timer_start = '1' then
            timer_state <= TSRunning;
          end if;
        when TSRunning =>
          if timer_zero = '1' then
            timer_irq   <= '1';
            timer_state <= TSFinished;
          end if;
        when TSFinished =>
          if timer_irqack = '1' then
            timer_state <= TSIdle;
          end if;
      end case;
    end if;
  end process;

  gen_clk_1khz : process(clk)
  begin
    if falling_edge(clk) then
      clk_1khz   <= '0';
      if buf_1mhz = '0' and clk_1mhz = '1' then
        if timer_state /= TSRunning then
          timer_div <= (others => '0');
        else
          timer_div <= timer_div + 1;
          if unsigned(timer_div) = 999 then
            clk_1khz <= '1';
            timer_div <= (others => '0');
          end if;
        end if;
      end if;
    end if;
  end process;

  timer_countup : process(clk, rst)
  begin
    if rst = '1' then
      timer_count <= (0 => '1', others => '0');
    elsif falling_edge(clk) then
      timer_zero <= '0';
      if clk_1khz = '1' then
        timer_count <= timer_count + 1;
        if timer_count = timer_end then
          timer_zero <= '1';
          timer_count <= (0 => '1', others => '0');
        end if;
      end if;
    end if;
  end process;
  
end;
