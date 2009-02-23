library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

-- Add your library and packages declaration here ...

entity acia_6850_tb is
end acia_6850_tb;

architecture TB_ARCHITECTURE of acia_6850_tb is
  -- Component declaration of the tested unit
  component acia_6850
    port(
      clk     : in  STD_LOGIC;
      rst     : in  STD_LOGIC;
      cs      : in  STD_LOGIC;
      rw      : in  STD_LOGIC;
      irq     : out STD_LOGIC;
      Addr    : in  STD_LOGIC;
      DataIn  : in  STD_LOGIC_VECTOR(7 downto 0);
      DataOut : out STD_LOGIC_VECTOR(7 downto 0);
      RxC     : in  STD_LOGIC;
      TxC     : in  STD_LOGIC;
      RxD     : in  STD_LOGIC;
      TxD     : out STD_LOGIC;
      DCD_n   : in  STD_LOGIC;
      CTS_n   : in  STD_LOGIC;
      RTS_n   : out STD_LOGIC;
      debug   : out STD_LOGIC);
  end component;

  -- Stimulus signals - signals mapped to the input and inout ports of tested entity
  signal clk     : STD_LOGIC;
  signal rst     : STD_LOGIC;
  signal cs      : STD_LOGIC;
  signal rw      : STD_LOGIC;
  signal Addr    : STD_LOGIC;
  signal DataIn  : STD_LOGIC_VECTOR(7 downto 0);
  signal RxC     : STD_LOGIC;
  signal TxC     : STD_LOGIC;
  signal RxD     : STD_LOGIC;
  signal DCD_n   : STD_LOGIC;
  signal CTS_n   : STD_LOGIC;
  -- Observed signals - signals mapped to the output ports of tested entity
  signal irq     : STD_LOGIC;
  signal DataOut : STD_LOGIC_VECTOR(7 downto 0);
  signal TxD     : STD_LOGIC;
  signal RTS_n   : STD_LOGIC;
  signal debug   : STD_LOGIC;

  -- Add your code here ...

begin

  -- Unit Under Test port map
  UUT : acia_6850
    port map (
      clk     => clk,
      rst     => rst,
      cs      => cs,
      rw      => rw,
      irq     => irq,
      Addr    => Addr,
      DataIn  => DataIn,
      DataOut => DataOut,
      RxC     => RxC,
      TxC     => TxC,
      RxD     => RxD,
      TxD     => TxD,
      DCD_n   => DCD_n,
      CTS_n   => CTS_n,
      RTS_n   => RTS_n,
      debug   => debug
      );

  -- Add your stimulus here ...
  rst <= '1', '0' after 500 ns;

  clk_gen : process
  begin
    clk <= '0'; wait for 250 ns;
    clk <= '1'; wait for 250 ns;
  end process;

  txc_clk_gen : process
  begin
    txc <= '0'; wait for 400 ns;
    txc <= '1'; wait for 400 ns;
  end process;

  test : process
    procedure set_reg(a    : in std_logic;
                      data : in std_logic_vector(7 downto 0)) is
    begin
      wait until rising_edge(clk);
      cs     <= '1';
      rw     <= '0';
      addr   <= a;
      datain <= data;
      wait until rising_edge(clk);
      cs     <= '0';
      wait until rising_edge(clk);
    end procedure;

    procedure wait_until_done is
      variable idle : std_logic;
    begin
      loop
        wait until rising_edge(clk);
        cs   <= '1';
        rw   <= '1';
        addr <= '0';
        wait until falling_edge(clk);
        idle := dataout(1);
        wait until rising_edge(clk);
        cs   <= '0';
        wait until falling_edge(clk);
        exit when idle = '1';
      end loop;
    end procedure;
    
  begin
    wait for 600 ns;
    set_reg('0', "01010101");
    set_reg('1', X"AA");
    wait_until_done;
    set_reg('1', X"55");
    wait_until_done;
    set_reg('1', X"FF");
    wait_until_done;
    wait;
  end process;

  cts_n <= '0';

end TB_ARCHITECTURE;

configuration TESTBENCH_FOR_acia_6850 of acia_6850_tb is
  for TB_ARCHITECTURE
    for UUT : acia_6850
      use entity work.acia_6850(rtl);
    end for;
  end for;
end TESTBENCH_FOR_acia_6850;

