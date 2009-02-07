library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

-- Add your library and packages declaration here ...

entity spi_master_tb is
end spi_master_tb;

architecture TB_ARCHITECTURE of spi_master_tb is
  -- Component declaration of the tested unit
  component spi_master
    port(
      clk : in std_logic;
      reset : in std_logic;
      cs : in std_logic;
      rw : in std_logic;
      addr : in std_logic_vector(1 downto 0);
      data_in : in std_logic_vector(7 downto 0);
      data_out : out std_logic_vector(7 downto 0);
      irq : out std_logic;
      spi_clk : out std_logic;
      spi_mosi : out std_logic;
      spi_cs_n : out std_logic_vector(7 downto 0);
      spi_miso : in std_logic );
  end component;

  -- Stimulus signals - signals mapped to the input and inout ports of tested entity
  signal clk : std_logic := '0';
  signal reset : std_logic;
  signal cs : std_logic;
  signal rw : std_logic;
  signal addr : std_logic_vector(1 downto 0);
  signal data_in : std_logic_vector(7 downto 0);
  signal spi_miso : std_logic;
  -- Observed signals - signals mapped to the output ports of tested entity
  signal data_out : std_logic_vector(7 downto 0);
  signal irq : std_logic;
  signal spi_clk : std_logic;
  signal spi_mosi : std_logic;
  signal spi_cs_n : std_logic_vector(7 downto 0);

  -- Add your code here ...

begin

  -- Unit Under Test port map
  UUT : spi_master
    port map (
      clk => clk,
      reset => reset,
      cs => cs,
      rw => rw,
      addr => addr,
      data_in => data_in,
      data_out => data_out,
      irq => irq,
      spi_clk => spi_clk,
      spi_mosi => spi_mosi,
      spi_cs_n => spi_cs_n,
      spi_miso => spi_miso
      );

  -- Add your stimulus here ...

  gen_clock : process
  begin
    clk <= not clk;
    wait for 40ns;
  end process;

  start_transfer : process
    
    procedure set_reg(a    : in std_logic_vector(1 downto 0);
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

    procedure wait_until_done is
      variable busy : std_logic;
    begin
      loop
        wait until rising_edge(clk);
        cs   <= '1';
        rw   <= '1';
        addr <= "10";
        busy := data_out(0);
        wait until rising_edge(clk);
        cs   <= '0';
        wait until rising_edge(clk);
        exit when busy = '0';
      end loop;
    end procedure;
    
  begin
    reset <= '1';
    cs <= '0';
    wait for 300ns;
    reset <= '0';
    wait for 300ns;
    set_reg("11", "00001101");          -- div=01, 16 bits
    set_reg("00", X"A5");
    set_reg("01", X"5A");               -- data bytes
    set_reg("10", "00000011");          -- send with deselect
    wait_until_done;
    set_reg("11", "00001100");          -- div=00, 16 bits
    set_reg("00", X"A5");
    set_reg("01", X"5A");               -- data bytes
    set_reg("10", "00000011");          -- send with deselect
    wait_until_done;
    set_reg("00", X"A5");
    set_reg("01", X"5A");               -- data bytes
    set_reg("10", "00000001");          -- send, keep selected
    wait_until_done;
    set_reg("11", "00000101");          -- div=01, 8 bits
    set_reg("00", X"00");
    set_reg("01", X"FF");               -- data bytes
    set_reg("10", "00000011");          -- send and deselect
    wait_until_done;
    set_reg("11", "01110101");          -- adr=7, div=01, 8 bits
    set_reg("00", X"00");
    set_reg("01", X"FF");               -- data bytes
    set_reg("10", "01110011");          -- send and deselect
    wait_until_done;
    wait for 1000ms;
  end process;
    
  spi_miso <= spi_mosi;

end TB_ARCHITECTURE;

configuration TESTBENCH_FOR_spi_master of spi_master_tb is
  for TB_ARCHITECTURE
    for UUT : spi_master
      use entity work.spi_master(rtl);
    end for;
  end for;
end TESTBENCH_FOR_spi_master;

