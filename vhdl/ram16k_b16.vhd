-- $Id: ram24k_b16.vhd,v 1.2 2008/03/14 15:52:43 dilbert57 Exp $
--===================================================================
--
-- 16K Block RAM
--
--===================================================================
--
-- Date: 24th April 2006
-- Author: John Kent
--
-- Revision History:
-- 24 April 2006 John Kent
-- Initial release
--
-- 29th June 2005 John Kent
-- Added CS term to CE decodes.
--
--
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
library unisim;
use unisim.vcomponents.all;

entity ram_16k is
  Port (
    clk   : in  std_logic;
    rst   : in  std_logic;
    cs    : in  std_logic;
    rw    : in  std_logic;
    addr  : in  std_logic_vector (13 downto 0);
    rdata : out std_logic_vector (7 downto 0);
    wdata : in  std_logic_vector (7 downto 0)
    );
end ram_16k;

architecture rtl of ram_16k is

  signal we    : std_logic;
  signal dp    : std_logic_vector(7 downto 0);
  signal ce    : std_logic_vector(7 downto 0);
  signal rdata_0 : std_logic_vector(7 downto 0);
  signal rdata_1 : std_logic_vector(7 downto 0);
  signal rdata_2 : std_logic_vector(7 downto 0);
  signal rdata_3 : std_logic_vector(7 downto 0);
  signal rdata_4 : std_logic_vector(7 downto 0);
  signal rdata_5 : std_logic_vector(7 downto 0);
  signal rdata_6 : std_logic_vector(7 downto 0);
  signal rdata_7 : std_logic_vector(7 downto 0);

begin

  RAM0 : RAMB16_S9
    port map (
      do   => rdata_0,
      dop(0) => dp(0),
      addr => addr(10 downto 0),
      clk  => clk,
      di   => wdata,
      dip(0) => dp(0),
      en   => ce(0),
      ssr  => rst,
      we   => we
      );

  RAM1 : RAMB16_S9
    port map (
      do   => rdata_1,
      dop(0) => dp(1),
      addr => addr(10 downto 0),
      clk  => clk,
      di   => wdata,
      dip(0) => dp(1),
      en   => ce(1),
      ssr  => rst,
      we   => we
      );

  RAM2 : RAMB16_S9

    port map (
      do   => rdata_2,
      dop(0) => dp(2),
      addr => addr(10 downto 0),
      clk  => clk,
      di   => wdata,
      dip(0) => dp(2),
      en   => ce(2),
      ssr  => rst,
      we   => we
      );

  RAM3 : RAMB16_S9

    port map (
      do   => rdata_3,
      dop(0) => dp(3),
      addr => addr(10 downto 0),
      clk  => clk,
      di   => wdata,
      dip(0) => dp(3),
      en   => ce(3),
      ssr  => rst,
      we   => we
      );

  RAM4 : RAMB16_S9

    port map (
      do   => rdata_4,
      dop(0) => dp(4),
      addr => addr(10 downto 0),
      clk  => clk,
      di   => wdata,
      dip(0) => dp(4),
      en   => ce(4),
      ssr  => rst,
      we   => we
      );

  RAM5 : RAMB16_S9

    port map (
      do   => rdata_5,
      dop(0) => dp(5),
      addr => addr(10 downto 0),
      clk  => clk,
      di   => wdata,
      dip(0) => dp(5),
      en   => ce(5),
      ssr  => rst,
      we   => we
      );

  RAM6 : RAMB16_S9

    port map (
      do   => rdata_6,
      dop(0) => dp(6),
      addr => addr(10 downto 0),
      clk  => clk,
      di   => wdata,
      dip(0) => dp(6),
      en   => ce(6),
      ssr  => rst,
      we   => we
      );

  RAM7 : RAMB16_S9

    port map (
      do   => rdata_7,
      dop(0) => dp(7),
      addr => addr(10 downto 0),
      clk  => clk,
      di   => wdata,
      dip(0) => dp(7),
      en   => ce(7),
      ssr  => rst,
      we   => we
      );

  my_ram_16k : process ( cs, rw, addr,
                         rdata_0, rdata_1, rdata_2, rdata_3,
                         rdata_4, rdata_5, rdata_6, rdata_7 )
  begin
    we <= not rw;
    
    case addr(13 downto 11) is
      when "000" =>
        rdata <= rdata_0;
      when "001" =>
        rdata <= rdata_1;
      when "010" =>
        rdata <= rdata_2;
      when "011" =>
        rdata <= rdata_3;
      when "100" =>
        rdata <= rdata_4;
      when "101" =>
        rdata <= rdata_5;
      when "110" =>
        rdata <= rdata_6;
      when "111" =>
        rdata <= rdata_7;
      when others =>
        null;
    end case;

    ce(0)  <= cs and not( addr(13) ) and not( addr(12) ) and not( addr(11) );
    ce(1)  <= cs and not( addr(13) ) and not( addr(12) ) and      addr(11)  ;
    ce(2)  <= cs and not( addr(13) ) and      addr(12)   and not( addr(11) );
    ce(3)  <= cs and not( addr(13) ) and      addr(12)   and      addr(11)  ;
    ce(4)  <= cs and      addr(13)   and not( addr(12) ) and not( addr(11) );
    ce(5)  <= cs and      addr(13)   and not( addr(12) ) and      addr(11)  ;
    ce(6)  <= cs and      addr(13)   and      addr(12)   and not( addr(11) );
    ce(7)  <= cs and      addr(13)   and      addr(12)   and      addr(11)  ;

  end process;

end architecture rtl;

