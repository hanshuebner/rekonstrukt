library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

-- Add your library and packages declaration here ...

entity midi_tb is
end midi_tb;

architecture TB_ARCHITECTURE of midi_tb is
  -- Component declaration of the tested unit
  component midi
    port(
      clk : in STD_LOGIC;
      rst : in STD_LOGIC;
      cs : in STD_LOGIC;
      rw : in STD_LOGIC;
      addr : in STD_LOGIC_VECTOR(7 downto 0);
      data_in : in STD_LOGIC_VECTOR(7 downto 0);
      data_out : out STD_LOGIC_VECTOR(7 downto 0);
      clk_1mhz : in STD_LOGIC;
      midi_tx : out STD_LOGIC );
  end component;

  -- Stimulus signals - signals mapped to the input and inout ports of tested entity
  signal clk : STD_LOGIC;
  signal rst : STD_LOGIC;
  signal cs : STD_LOGIC;
  signal rw : STD_LOGIC;
  signal addr : STD_LOGIC_VECTOR(7 downto 0);
  signal data_in : STD_LOGIC_VECTOR(7 downto 0);
  signal clk_1mhz : STD_LOGIC;
  -- Observed signals - signals mapped to the output ports of tested entity
  signal data_out : STD_LOGIC_VECTOR(7 downto 0);
  signal midi_tx : STD_LOGIC;

  -- Add your code here ...

begin

  -- Unit Under Test port map
  UUT : midi
    port map (
      clk => clk,
      rst => rst,
      cs => cs,
      rw => rw,
      addr => addr,
      data_in => data_in,
      data_out => data_out,
      clk_1mhz => clk_1mhz,
      midi_tx => midi_tx
      );

  -- Add your stimulus here ...
  rst <= '1', '0' after 500 ns;

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

  test : process

    procedure set_reg(a    : in natural;
                      data : in std_logic_vector(7 downto 0)) is
    begin
      wait until rising_edge(clk);
      cs      <= '1';
      rw      <= '0';
      addr    <= std_logic_vector(to_unsigned(a, addr'length));
      data_in <= data;
      wait until rising_edge(clk);
      cs      <= '0';
      wait until rising_edge(clk);
    end procedure;

  begin
    cs <= '0';
    rw <= '0';
    wait for 600 ns;
    set_reg(16#88#, X"00");
    for a in 0 to 7 loop
      set_reg(16#80# + a, std_logic_vector(to_unsigned(a, 8)));
    end loop;
    for a in 0 to 127 loop
      set_reg(a, std_logic_vector(to_unsigned(a, 8)));
    end loop;
    set_reg(16#89#, X"03");
    set_reg(16#8A#, X"00");
    set_reg(16#8B#, X"01");
    wait;
  end process;

end TB_ARCHITECTURE;

configuration TESTBENCH_FOR_midi of midi_tb is
  for TB_ARCHITECTURE
    for UUT : midi
      use entity work.midi(rtl);
    end for;
  end for;
end TESTBENCH_FOR_midi;

