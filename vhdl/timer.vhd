-- timer.vhd

-- Timer module, provides for high resolution timestamps, down counters and the
-- like

Library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

entity timer is
  port(
    -- CPU bus interface
    clk      : in  std_logic;
    rst      : in  std_logic;
    cs       : in  std_logic;
    rw       : in  std_logic;
    addr     : in  std_logic_vector(2 downto 0);
    data_in  : in  std_logic_vector(7 downto 0);
    data_out : out std_logic_vector(7 downto 0);
    -- 
    clk_1mhz : in  std_logic;
    midi_clk : out std_logic
    );
end timer;

architecture rtl of timer is

  -- Counter and divider for MIDI clock
  signal midi_count      : std_logic_vector(15 downto 0);
  signal midi_div        : std_logic_vector(15 downto 0);
  signal midi_clk_enable : std_logic;
  signal buf_1mhz        : std_logic;

begin

  handle_host_write : process(clk, rst)
  begin
    if rst = '1' then
      midi_div        <= (others => '0');
      midi_clk_enable <= '0';
    elsif falling_edge(clk) then
      if cs = '1' and rw = '0' then
        case addr is
          when "000" =>
            midi_clk_enable <= data_in(0);
          when "001" =>
            midi_div(15 downto 8) <= data_in;
          when "010" =>
            midi_div(7 downto 0) <= data_in;
          when others =>
            null;
        end case;
      end if;
    end if;
  end process;

  gen_midi_clk : process(clk, rst)
  begin
    if rst = '1' then
      midi_count      <= (others => '0');
    elsif falling_edge(clk) then
      if midi_clk_enable = '1' then
        if buf_1mhz = '0' and clk_1mhz = '1' then
          midi_count <= midi_count + 1;
          midi_clk   <= '0';
          if midi_count = midi_div then
            midi_count <= (0 => '1', others => '0');
            midi_clk   <= '1';
          end if;
        end if;
      end if;
    end if;
  end process;

  buf_clk : process(clk)
  begin
    if falling_edge(clk) then
      buf_1mhz <= clk_1mhz;
    end if;
  end process;

end;
