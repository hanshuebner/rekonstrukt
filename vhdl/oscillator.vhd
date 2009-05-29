
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity oscillator is
  port(
    reset           : in  std_logic;
    clk             : in  std_logic;
    phase_increment : in  std_logic_vector(31 downto 0);
    select_waveform : in  std_logic_vector(3 downto 0);
    output          : out std_logic_vector(7 downto 0));
end oscillator;

architecture rtl of oscillator is

  signal phase_accumulator : std_logic_vector(31 downto 0);
  signal address           : std_logic_vector(7 downto 0);
  signal table_output      : std_logic_vector(7 downto 0);
  signal sin_output        : std_logic_vector(7 downto 0);
  signal saw_output        : std_logic_vector(7 downto 0);
  signal square_output     : std_logic_vector(7 downto 0);

begin

  my_lut : entity sin_lut port map(
    clk     => clk,
    address => address,
    output  => sin_output);

  address       <= phase_accumulator(31 downto 24);
  saw_output    <= address;
  square_output <= (others => address(7));

  with select_waveform select output <=
    sin_output      when X"0",
    square_output   when X"8",
    saw_output      when X"9",
    (others => '0') when others;

  process(reset, clk)
  begin
    if reset = '1' then
      phase_accumulator <= (others => '0');
    elsif rising_edge(clk) then
      phase_accumulator <= phase_accumulator + phase_increment;
    end if;
  end process;

end;
