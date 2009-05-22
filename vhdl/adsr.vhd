library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity adsr is
  port(
    reset   : in  std_logic;
    clk     : in  std_logic;
    attack  : in  std_logic_vector(7 downto 0);
    decay   : in  std_logic_vector(7 downto 0);
    sustain : in  std_logic_vector(7 downto 0);
    release : in  std_logic_vector(7 downto 0);
    note    : in  std_logic_vector(7 downto 0);
    input   : in  std_logic_vector(7 downto 0);
    output  : out std_logic_vector(7 downto 0)
    );
end adsr;

architecture rtl of sawtooth is
  signal result        : std_logic_vector(15 downto 0);
  signal level         : std_logic_vector(7 downto 0);
  type   state_type is (s_attack, s_decay, s_sustain, s_release);
  signal state         : state_type;
  signal step_divider  : std_logic_vector(13 downto 0);
  signal step_pulse    : std_logic;
  signal phase_counter : std_logic_vector(7 downto 0);
begin

  output <= result(15 downto 8);

  my_step_counter : process(clk, reset)
  begin
    if reset = '1' then
      step_divider <= (others => '0');
    elsif rising_edge(clk) then
      step_divider <= step_divider + 1;
      step_pulse   <= '0';
      if step_divider = 0 then
        step_pulse <= '1';
      end if;
    end if;
  end process;

  my_adsr : process(clk, reset)
  begin
    if reset = '1' then
      state <= s_release;
      level <= (others => '0');
    elsif rising_edge(clk) then
      if step_pulse = '1' then
        case state is
          s_attack =>
            if note = 0 then
              state = s_release;
            else
              
