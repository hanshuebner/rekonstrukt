-----------------------------------------------------------------
--
-- ACIA Clock Divider for System09
--
-----------------------------------------------------------------
--
library ieee;
use ieee.std_logic_1164.all;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use ieee.numeric_std.all;
library unisim;
use unisim.vcomponents.all;
library work;
use work.bit_funcs.all;

entity acia_clock is
  generic (
    SYS_CLK_FREQ  : integer;
    ACIA_CLK_FREQ : integer
    );
  port(
    clk      : in  Std_Logic;  -- System Clock input
    acia_clk : out Std_Logic   -- ACIA Clock output
    );
end acia_clock;

-------------------------------------------------------------------------------
-- Architecture for ACIA_Clock
-------------------------------------------------------------------------------
architecture rtl of ACIA_Clock is

  constant FULL_CYCLE : integer :=  (SYS_CLK_FREQ / ACIA_CLK_FREQ);
  constant HALF_CYCLE : integer :=  (FULL_CYCLE / 2);
  signal   acia_count : Std_Logic_Vector(log2(FULL_CYCLE) downto 0) := (Others => '0');

begin
--
-- Baud Rate Clock Divider
--
-- 25MHz / 27  = 926,000 KHz = 57,870Bd * 16
-- 50MHz / 54  = 926,000 KHz = 57,870Bd * 16
--
  my_acia_clock: process( clk  )
  begin
    if falling_edge(clk) then
      if( acia_count = (FULL_CYCLE - 1) )	then
        acia_clk   <= '0';
        acia_count <= (others => '0'); --"000000";
      else
        if( acia_count = (HALF_CYCLE - 1) )	then
          acia_clk <='1';
        end if;
        acia_count <= acia_count + 1;
      end if;			
    end if;
  end process;

end rtl;
