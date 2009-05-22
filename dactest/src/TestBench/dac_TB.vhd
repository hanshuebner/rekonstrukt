library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

-- Add your library and packages declaration here ...

entity dac_tb is
end dac_tb;

architecture TB_ARCHITECTURE of dac_tb is
  -- Component declaration of the tested unit
  component dac
    port(
      reset      : in  STD_LOGIC;
      clk        : in  STD_LOGIC;
      data       : in  STD_LOGIC_VECTOR(7 downto 0);
      analog_out : out STD_LOGIC);
  end component;

  component sawtooth
    port(
      reset  : in  std_logic;
      clk    : in  std_logic;
      div    : in  std_logic_vector(15 downto 0);
      output : out std_logic_vector(7 downto 0));
  end component;

  -- Stimulus signals - signals mapped to the input and inout ports of tested entity
  signal reset      : STD_LOGIC;
  signal clk        : STD_LOGIC;
  signal data       : STD_LOGIC_VECTOR(7 downto 0);
  signal divisor    : STD_LOGIC_VECTOR(15 downto 0);
  -- Observed signals - signals mapped to the output ports of tested entity
  signal analog_out : STD_LOGIC;

  -- Add your code here ...

begin

  -- Unit Under Test port map
  my_dac : dac
    port map (
      reset      => reset,
      clk        => clk,
      data       => data,
      analog_out => analog_out);

  my_sawtooth : sawtooth
    port map (
      reset  => reset,
      clk    => clk,
      output => data,
      div    => divisor);

  -- Add your stimulus here ...

  divisor <= X"0400";

  reset <= '1', '0' after 500 ns;

  gen_clk : process
  begin
    clk <= '0'; wait for 31.333 ns;
    clk <= '1'; wait for 31.333 ns;
  end process;

end TB_ARCHITECTURE;

configuration TESTBENCH_FOR_dac of dac_tb is
  for TB_ARCHITECTURE
    for my_dac : dac
      use entity work.dac(rtl);
    end for;
  end for;
end TESTBENCH_FOR_dac;

