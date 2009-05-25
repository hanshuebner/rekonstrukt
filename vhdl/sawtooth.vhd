library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity sawtooth is
  port(
    reset  : in  std_logic;
    clk    : in  std_logic;
    div    : in  std_logic_vector(15 downto 0);
    output : out std_logic_vector(7 downto 0)
    );
end sawtooth;

architecture rtl of sawtooth is
  -- current output value
  signal value          : std_logic_vector(7 downto 0);
  -- current generator division count
  signal count          : std_logic_vector(15 downto 0);
  -- current dac output divider
  signal output_divider : std_logic_vector(7 downto 0);

begin

  generate_waveform : process(reset, clk)
  begin
    if reset = '1' then
      value          <= (others => '0');
      count          <= (others => '0');
    elsif rising_edge(clk) then
      count          <= count + 1;
      if count = div then
        value <= value + 1;
        count <= (others => '0');
      end if;
    end if;
  end process;

  sample_output : process(reset, clk)
  begin
    if reset = '1' then
      output_divider <= (others => '0');
      output         <= (others => '0');
    elsif rising_edge(clk) then
      output_divider <= output_divider + 1;
      if output_divider = 0 then
        output <= value;
      end if;
    end if;
  end process;
end;
