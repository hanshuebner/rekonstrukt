library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

-- Add your library and packages declaration here ...

entity beep_tb is
end beep_tb;

architecture TB_ARCHITECTURE of beep_tb is
  -- Component declaration of the tested unit
  component beep
    port(
      reset : in STD_LOGIC;
      clk : in STD_LOGIC;
      analog_out : out STD_LOGIC );
  end component;

  -- Stimulus signals - signals mapped to the input and inout ports of tested entity
  signal reset : STD_LOGIC;
  signal clk : STD_LOGIC;
  -- Observed signals - signals mapped to the output ports of tested entity
  signal analog_out : STD_LOGIC;

  -- Add your code here ...

begin

  -- Unit Under Test port map
  UUT : beep
    port map (
      reset => reset,
      clk => clk,
      analog_out => analog_out
      );

  -- Add your stimulus here ...

  reset <= '1', '0' after 500 ns;

  gen_clk : process
  begin
    clk <= '0'; wait for 31.333 ns;
    clk <= '1'; wait for 31.333 ns;
  end process;

end TB_ARCHITECTURE;

configuration TESTBENCH_FOR_beep of beep_tb is
  for TB_ARCHITECTURE
    for UUT : beep
      use entity work.beep(rtl);
    end for;
  end for;
end TESTBENCH_FOR_beep;

