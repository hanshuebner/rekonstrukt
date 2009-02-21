
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity fifo is
  port (
    reset, clk, r, w : in  std_logic;
    empty, full      : out std_logic;
    d                : in  std_logic_vector(7 downto 0);
    q                : out std_logic_vector(7 downto 0));
end fifo;

architecture rtl of fifo is
  constant m                   : integer := 8;
  constant n                   : integer := 8;
  signal   rcntr, wcntr        : std_logic_vector(2 downto 0);
  subtype  wrdtype is std_logic_vector(n - 1 downto 0);
  type     regtype is array(0 to m - 1) of wrdtype;
  signal   reg                 : regtype;
  signal   rw                  : std_logic_vector(1 downto 0);
  signal   full_buf, empty_buf : std_logic;
begin
  rw <= r & w;
  seq : process(reset, clk)
  begin
    if reset = '1' then
      rcntr     <= (others => '0');
      wcntr     <= (others => '0');
      empty_buf <= '1';
      full_buf  <= '0';
      for j in 0 to m - 1 loop
        reg(j) <= (others => '0');
      end loop;
    elsif falling_edge(clk) then
      case rw is
        when "11" =>
          -- read and write at the same time
          rcntr                    <= rcntr + 1;
          wcntr                    <= wcntr + 1;
          reg(conv_integer(wcntr)) <= d;
        when "10" =>
          -- only read
          if empty_buf = '0' then
            -- not empty
            if (rcntr + 1) = wcntr then
              empty_buf <= '1';
            end if;
            rcntr <= rcntr + 1;
          end if;
          full_buf <= '0';
        when "01" =>
          -- only write
          empty_buf <= '0';
          if full_buf = '0' then
            -- not full
            reg(conv_integer(wcntr)) <= d;
            if (wcntr + 1) = rcntr then
              full_buf <= '1';
            end if;
            wcntr <= wcntr + 1;
          end if;
        when others =>
          null;
      end case;
    end if;
  end process;

  q     <= reg(conv_integer(rcntr));
  full  <= full_buf;
  empty <= empty_buf;
end rtl;
