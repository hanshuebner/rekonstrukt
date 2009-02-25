library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
library unisim;
use unisim.vcomponents.all;

entity clock_div is
  port(
    -- 25 Mhz clock input
    clk        : in  std_logic;
    reset      : in  std_logic;
    clk_1mhz   : out std_logic;
    clk_500khz : out std_logic
    );
end clock_div;

architecture rtl of clock_div is

  signal count1 : std_logic_vector(4 downto 0);
  signal count2 : std_logic_vector(0 downto 0);

begin

  count : process(clk, reset)
  begin
    if reset = '1' then
      count1 <= (others => '0');
      count2 <= (others => '0');
    elsif rising_edge(clk) then
      count1 <= count1 + 1;
      if unsigned(count1) = 24 then
        count1 <= (others => '0');
        count2 <= count2 + "1";
      end if;
    end if;
  end process;

  gen_clk_1mhz : process(clk)
  begin
    if rising_edge(clk) then
      if unsigned(count1) = 1 then
        clk_1mhz <= '1';
      elsif unsigned(count1) = 13 then
        clk_1mhz <= '0';
      end if;
    end if;
  end process;

  clk_500khz <= count2(0);

end;
