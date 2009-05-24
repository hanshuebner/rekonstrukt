
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity sin_lut is
  port(clk     : in  std_logic;
       address : in  std_logic_vector(7 downto 0);
       output  : out std_logic_vector(7 downto 0));
end;

architecture rtl of sin_lut is

  type lut_type is array(0 to 255) of std_logic_vector(7 downto 0);

  constant lut : lut_type := (
    X"80",X"83",X"86",X"89",X"8C",X"8F",X"92",X"95",X"98",X"9C",X"9F",X"A2",X"A5",X"A8",X"AB",X"AE",
    X"B0",X"B3",X"B6",X"B9",X"BC",X"BF",X"C1",X"C4",X"C7",X"C9",X"CC",X"CE",X"D1",X"D3",X"D5",X"D8",
    X"DA",X"DC",X"DE",X"E0",X"E2",X"E4",X"E6",X"E8",X"EA",X"EC",X"ED",X"EF",X"F0",X"F2",X"F3",X"F5",
    X"F6",X"F7",X"F8",X"F9",X"FA",X"FB",X"FC",X"FC",X"FD",X"FE",X"FE",X"FF",X"FF",X"FF",X"FF",X"FF",
    X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FE",X"FE",X"FD",X"FC",X"FC",X"FB",X"FA",X"F9",X"F8",X"F7",
    X"F6",X"F5",X"F3",X"F2",X"F0",X"EF",X"ED",X"EC",X"EA",X"E8",X"E6",X"E4",X"E2",X"E0",X"DE",X"DC",
    X"DA",X"D8",X"D5",X"D3",X"D1",X"CE",X"CC",X"C9",X"C7",X"C4",X"C1",X"BF",X"BC",X"B9",X"B6",X"B3",
    X"B0",X"AE",X"AB",X"A8",X"A5",X"A2",X"9F",X"9C",X"98",X"95",X"92",X"8F",X"8C",X"89",X"86",X"83",
    X"80",X"7C",X"79",X"76",X"73",X"70",X"6D",X"6A",X"67",X"63",X"60",X"5D",X"5A",X"57",X"54",X"51",
    X"4F",X"4C",X"49",X"46",X"43",X"40",X"3E",X"3B",X"38",X"36",X"33",X"31",X"2E",X"2C",X"2A",X"27",
    X"25",X"23",X"21",X"1F",X"1D",X"1B",X"19",X"17",X"15",X"13",X"12",X"10",X"0F",X"0D",X"0C",X"0A",
    X"09",X"08",X"07",X"06",X"05",X"04",X"03",X"03",X"02",X"01",X"01",X"00",X"00",X"00",X"00",X"00",
    X"00",X"00",X"00",X"00",X"00",X"00",X"01",X"01",X"02",X"03",X"03",X"04",X"05",X"06",X"07",X"08",
    X"09",X"0A",X"0C",X"0D",X"0F",X"10",X"12",X"13",X"15",X"17",X"19",X"1B",X"1D",X"1F",X"21",X"23",
    X"25",X"27",X"2A",X"2C",X"2E",X"31",X"33",X"36",X"38",X"3B",X"3E",X"40",X"43",X"46",X"49",X"4C",
    X"4F",X"51",X"54",X"57",X"5A",X"5D",X"60",X"63",X"67",X"6A",X"6D",X"70",X"73",X"76",X"79",X"7C");

begin

  process(clk)
  begin
    if rising_edge(clk) then
      output <= lut(conv_integer(address));
    end if;
  end process;

end;
