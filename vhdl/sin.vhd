
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

entity sin is
  port(
    reset         : in  std_logic;
    clk           : in  std_logic;
    phase_inc     : in  std_logic_vector(23 downto 0);
    sin_output    : out std_logic_vector(7 downto 0);
    saw_output    : out std_logic_vector(7 downto 0);
    square_output : out std_logic_vector(7 downto 0)
    );
end sin;

architecture rtl of sin is

  signal phase_accumulator : std_logic_vector(31 downto 0);
  signal address : std_logic_vector(7 downto 0);

begin

  my_lut : entity sin_lut port map(
    clk     => clk,
    address => address,
    output  => sin_output);

  address       <= phase_accumulator(31 downto 24);
  saw_output    <= address;
  square_output <= (others => address(7));

  process(reset, clk)
  begin
    if reset = '1' then
      phase_accumulator <= (others => '0');
    elsif rising_edge(clk) then
      phase_accumulator <= unsigned(phase_accumulator) + unsigned(phase_inc);
    end if;
  end process;

end;
