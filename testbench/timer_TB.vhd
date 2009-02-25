library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

-- Add your library and packages declaration here ...

entity timer_tb is
end timer_tb;

architecture TB_ARCHITECTURE of timer_tb is
  -- Component declaration of the tested unit
  component timer
    port(
      clk       : in  STD_LOGIC;
      rst       : in  STD_LOGIC;
      cs        : in  STD_LOGIC;
      rw        : in  STD_LOGIC;
      addr      : in  STD_LOGIC_VECTOR(2 downto 0);
      data_in   : in  STD_LOGIC_VECTOR(7 downto 0);
      data_out  : out STD_LOGIC_VECTOR(7 downto 0);
      clk_1mhz  : in  STD_LOGIC;
      midi_clk  : out STD_LOGIC;
      timer_irq : out STD_LOGIC);
  end component;

  -- Stimulus signals - signals mapped to the input and inout ports of tested entity
  signal clk       : STD_LOGIC;
  signal rst       : STD_LOGIC;
  signal cs        : STD_LOGIC;
  signal rw        : STD_LOGIC;
  signal addr      : STD_LOGIC_VECTOR(2 downto 0);
  signal data_in   : STD_LOGIC_VECTOR(7 downto 0);
  signal clk_1mhz  : STD_LOGIC;
  -- Observed signals - signals mapped to the output ports of tested entity
  signal data_out  : STD_LOGIC_VECTOR(7 downto 0);
  signal midi_clk  : STD_LOGIC;
  signal timer_irq : STD_LOGIC;

  -- Add your code here ...

begin

  -- Unit Under Test port map
  UUT : timer
    port map (
      clk       => clk,
      rst       => rst,
      cs        => cs,
      rw        => rw,
      addr      => addr,
      data_in   => data_in,
      data_out  => data_out,
      clk_1mhz  => clk_1mhz,
      midi_clk  => midi_clk,
      timer_irq => timer_irq
      );

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

    procedure set_reg(a    : in std_logic_vector(addr'range);
                      data : in std_logic_vector(7 downto 0)) is
    begin
      wait until rising_edge(clk);
      cs      <= '1';
      rw      <= '0';
      addr    <= a;
      data_in <= data;
      wait until rising_edge(clk);
      cs      <= '0';
      wait until rising_edge(clk);
    end procedure;

  begin
    wait for 600 ns;
    set_reg("001", X"FF");
    set_reg("010", X"FF");
    set_reg("000", X"01");
    
    set_reg("101", X"00");
    set_reg("110", X"0A");              -- 10 ms
    set_reg("100", X"01");              -- timer running now
    wait for 14ms;
    set_reg("100", X"00");              -- acknowledge IRQ
    wait;
  end process;

end TB_ARCHITECTURE;

configuration TESTBENCH_FOR_timer of timer_tb is
  for TB_ARCHITECTURE
    for UUT : timer
      use entity work.timer(rtl);
    end for;
  end for;
end TESTBENCH_FOR_timer;

