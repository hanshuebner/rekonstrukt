library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
library unisim;
use unisim.vcomponents.all;

-- Add your library and packages declaration here ...

entity clock_synthesis_tb is
end clock_synthesis_tb;

architecture TB_ARCHITECTURE of clock_synthesis_tb is
  -- Component declaration of the tested unit
  component clock_synthesis
    port(
      CLKIN_IN : in STD_LOGIC;
      CLK0_OUT : out STD_LOGIC;
      CLK270_OUT : out STD_LOGIC;
      LOCKED_OUT : out STD_LOGIC );
  end component;

  -- Stimulus signals - signals mapped to the input and inout ports of tested entity
  signal CLKIN_IN : STD_LOGIC;
  -- Observed signals - signals mapped to the output ports of tested entity
  signal CLK0_OUT : STD_LOGIC;
  signal CLK270_OUT : STD_LOGIC;
  signal LOCKED_OUT : STD_LOGIC;

  -- Add your code here ...

begin

  -- Unit Under Test port map
  UUT : clock_synthesis
    port map (
      CLKIN_IN => CLKIN_IN,
      CLK0_OUT => CLK0_OUT,
      CLK270_OUT => CLK270_OUT,
      LOCKED_OUT => LOCKED_OUT
      );

  -- Add your stimulus here ...

  clk_gen : process
  begin
    clkin_in <= '1'; wait for 10 ns;
    clkin_in <= '0'; wait for 10 ns;
  end process;

end TB_ARCHITECTURE;

configuration TESTBENCH_FOR_clock_synthesis of clock_synthesis_tb is
  for TB_ARCHITECTURE
    for UUT : clock_synthesis
      use entity work.clock_synthesis(behavioral);
    end for;
  end for;
end TESTBENCH_FOR_clock_synthesis;

