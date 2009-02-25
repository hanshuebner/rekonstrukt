library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
library unisim;
use unisim.vcomponents.all;

-- Add your library and packages declaration here ...

entity clock_div_tb is
end clock_div_tb;

architecture TB_ARCHITECTURE of clock_div_tb is
  -- Component declaration of the tested unit
  component clock_div
    port(
      clk : in STD_LOGIC;
      reset : in STD_LOGIC;
      clk_1mhz : out STD_LOGIC;
      clk_500khz : out STD_LOGIC );
  end component;

  -- Stimulus signals - signals mapped to the input and inout ports of tested entity
  signal clk : STD_LOGIC;
  signal reset : STD_LOGIC;
  -- Observed signals - signals mapped to the output ports of tested entity
  signal clk_1mhz : STD_LOGIC;
  signal clk_500khz : STD_LOGIC;

  -- Add your code here ...

begin

  -- Unit Under Test port map
  UUT : clock_div
    port map (
      clk => clk,
      reset => reset,
      clk_1mhz => clk_1mhz,
      clk_500khz => clk_500khz
      );

  -- Add your stimulus here ...

  reset <= '1', '0' after 300 ns;

  gen_clk : process
  begin
    clk <= '1';
    wait for 20 ns;
    clk <= '0';
    wait for 20 ns;
  end process;

end TB_ARCHITECTURE;

configuration TESTBENCH_FOR_clock_div of clock_div_tb is
  for TB_ARCHITECTURE
    for UUT : clock_div
      use entity work.clock_div(rtl);
    end for;
  end for;
end TESTBENCH_FOR_clock_div;

