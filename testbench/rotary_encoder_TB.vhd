library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
library unisim;
use unisim.vcomponents.all;

-- Add your library and packages declaration here ...

entity rotary_encoder_tb is
end rotary_encoder_tb;

architecture TB_ARCHITECTURE of rotary_encoder_tb is
  -- Component declaration of the tested unit
  component rotary_encoder
    port(
      clk : in STD_LOGIC;
      rst : in STD_LOGIC;
      cs : in STD_LOGIC;
      rw : in STD_LOGIC;
      addr : in STD_LOGIC_VECTOR(4 downto 0);
      data_out : out STD_LOGIC_VECTOR(7 downto 0);
      clk_1mhz : in STD_LOGIC;
      rot_left : in STD_LOGIC_VECTOR(15 downto 0);
      rot_right : in STD_LOGIC_VECTOR(15 downto 0) );
  end component;

  -- Stimulus signals - signals mapped to the input and inout ports of tested entity
  signal clk : STD_LOGIC;
  signal rst : STD_LOGIC;
  signal cs : STD_LOGIC;
  signal rw : STD_LOGIC;
  signal addr : STD_LOGIC_VECTOR(4 downto 0);
  signal clk_1mhz : STD_LOGIC;
  signal rot_left : STD_LOGIC_VECTOR(15 downto 0);
  signal rot_right : STD_LOGIC_VECTOR(15 downto 0);
  -- Observed signals - signals mapped to the output ports of tested entity
  signal data_out : STD_LOGIC_VECTOR(7 downto 0);

  -- Add your code here ...

begin

  -- Unit Under Test port map
  UUT : rotary_encoder
    port map (
      clk => clk,
      rst => rst,
      cs => cs,
      rw => rw,
      addr => addr,
      data_out => data_out,
      clk_1mhz => clk_1mhz,
      rot_left => rot_left,
      rot_right => rot_right
      );

  -- Add your stimulus here ...

  rst <= '1', '0' after 500 ns;

  cs <= '0';
  rw <= '0';
  addr <= (others => '0');

  gen_clk : process
  begin
    clk <= '0'; wait for 20 ns;
    clk <= '1'; wait for 20 ns;
  end process;

  gen_clk_1mhz : process
  begin
    clk_1mhz <= '0'; wait for 500 ns;
    clk_1mhz <= '1'; wait for 500 ns;
  end process;

  gen_encoder0 : process
  begin
    rot_left(0) <= '0';
    wait for 50 ms;
    rot_right(0) <= '0';
    wait for 50 ms;
    rot_left(0) <= '1';
    wait for 50 ms;
    rot_right(0) <= '1';
    wait for 50 ms;
  end process;

  gen_encoder1 : process
  begin
    rot_right(1) <= '0';
    wait for 50 ms;
    rot_left(1) <= '0';
    wait for 50 ms;
    rot_right(1) <= '1';
    wait for 50 ms;
    rot_left(1) <= '1';
    wait for 50 ms;
  end process;

  rot_left(15 downto 2) <= (others => '0');
  rot_right(15 downto 2) <= (others => '0');

end TB_ARCHITECTURE;

configuration TESTBENCH_FOR_rotary_encoder of rotary_encoder_tb is
  for TB_ARCHITECTURE
    for UUT : rotary_encoder
      use entity work.rotary_encoder(rtl);
    end for;
  end for;
end TESTBENCH_FOR_rotary_encoder;

