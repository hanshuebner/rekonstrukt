-- Dual port RAM with synchronous read (read through)
-- Xilinx rams_11

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity dp_ram is
  port(clk  : in  std_logic;
       we   : in  std_logic;
       a    : in  std_logic_vector(10 downto 0);
       dpra : in  std_logic_vector(10 downto 0);
       di   : in  std_logic_vector(7 downto 0);
       spo  : out std_logic_vector(7 downto 0);
       dpo  : out std_logic_vector(7 downto 0)
       );
end dp_ram;

architecture rtl of dp_ram is
  type   ram_type is array(2047 downto 0) of std_logic_vector(7 downto 0);
  signal RAM       : ram_type;
  signal read_a    : std_logic_vector(10 downto 0);
  signal read_dpra : std_logic_vector(10 downto 0);
begin

  process(clk)
  begin
    if rising_edge(clk) then
      if we = '1' then
        RAM(conv_integer(a)) <= di;
      end if;
      read_a    <= a;
      read_dpra <= dpra;
    end if;
  end process;

  spo <= RAM(conv_integer(read_a));
  dpo <= RAM(conv_integer(read_dpra));

end rtl;
