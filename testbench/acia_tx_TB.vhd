library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

-- Add your library and packages declaration here ...

entity acia_tx_tb is
end acia_tx_tb;

architecture TB_ARCHITECTURE of acia_tx_tb is
  -- Component declaration of the tested unit
  component acia_tx
    port(
      Clk : in STD_LOGIC;
      Reset : in STD_LOGIC;
      Wr : in STD_LOGIC;
      Din : in STD_LOGIC_VECTOR(7 downto 0);
      WdFmt : in STD_LOGIC_VECTOR(2 downto 0);
      BdFmt : in STD_LOGIC_VECTOR(1 downto 0);
      TxClk : in STD_LOGIC;
      Dat : out STD_LOGIC;
      Empty : out STD_LOGIC );
  end component;

  -- Stimulus signals - signals mapped to the input and inout ports of tested entity
  signal Clk : STD_LOGIC;
  signal Reset : STD_LOGIC;
  signal Wr : STD_LOGIC;
  signal Din : STD_LOGIC_VECTOR(7 downto 0);
  signal WdFmt : STD_LOGIC_VECTOR(2 downto 0);
  signal BdFmt : STD_LOGIC_VECTOR(1 downto 0);
  signal TxClk : STD_LOGIC;
  -- Observed signals - signals mapped to the output ports of tested entity
  signal Dat : STD_LOGIC;
  signal Empty : STD_LOGIC;

  -- Add your code here ...

begin

  -- Unit Under Test port map
  UUT : acia_tx
    port map (
      Clk => Clk,
      Reset => Reset,
      Wr => Wr,
      Din => Din,
      WdFmt => WdFmt,
      BdFmt => BdFmt,
      TxClk => TxClk,
      Dat => Dat,
      Empty => Empty
      );

  reset <= '1', '0' after 500 ns;

  clk_gen : process
  begin
    clk <= '0'; wait for 250 ns;
    clk <= '1'; wait for 250 ns;
  end process;

  acia_clk_gen : process
  begin
    txclk <= '0'; wait for 1000 ns;
    txclk <= '1'; wait for 1000 ns;
  end process;

  stimulus : process
  begin
    wait for 1000 ns;
    wait until falling_edge(clk);
    wr <= '0';
    din <= X"55";
    wdfmt <= "101";
    bdfmt <= "00";
    wait until falling_edge(clk);
    wr <= '1';
    wait until falling_edge(clk);
    wr <= '0';
    wr <= '0';
    din <= X"55";
    wdfmt <= "101";
    bdfmt <= "00";
    wait until empty = '1';
    wr <= '1';
    wait;
  end process;

end TB_ARCHITECTURE;

configuration TESTBENCH_FOR_acia_tx of acia_tx_tb is
  for TB_ARCHITECTURE
    for UUT : acia_tx
      use entity work.acia_tx(rtl);
    end for;
  end for;
end TESTBENCH_FOR_acia_tx;

