-- pulse_shaper.vhd - shape a long pulse to a one clock cycle pulse

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

entity pulse_shaper is
  port(
    clk : in  std_logic;
    rst : in  std_logic;
    d   : in  std_logic;
    q   : out std_logic
    );
end;

architecture rtl of pulse_shaper is

  signal buf : std_logic;

begin

  shape_pulse : process(clk, rst)
  begin
    if rst = '1' then
      q <= '0';
    elsif falling_edge(clk) then
      q <= '0';
      buf <= d;
      if d = '1' and buf = '0' then
        q <= '1';
      end if;
    end if;
  end process;

end rtl;
