
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity dac is
  port(
    reset      : in  std_logic;
    clk        : in  std_logic;
    data       : in  std_logic_vector(7 downto 0);
    analog_out : out std_logic
    );
end dac;

architecture rtl of dac is
  signal delta_adder : std_logic_vector(9 downto 0);
  signal sigma_adder : std_logic_vector(9 downto 0);
  signal sigma_latch : std_logic_vector(9 downto 0);
  signal delta_b     : std_logic_vector(9 downto 0);
begin
  delta_b <= (9      => sigma_latch(9),
              8      => sigma_latch(9),
              others => '0');
  delta_adder <= data + delta_b;
  sigma_adder <= delta_adder + sigma_latch;

  generate_output : process(reset, clk)
  begin
    if reset = '1' then
      sigma_latch <= "1100000000";
      analog_out  <= '1';
    elsif rising_edge(clk) then
      sigma_latch <= sigma_adder;
      analog_out  <= sigma_latch(9);
    end if;
  end process;
end;
