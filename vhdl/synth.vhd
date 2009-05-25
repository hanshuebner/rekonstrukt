library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.all;

entity synth is
  port(
    -- CPU bus interface
    clk          : in  std_logic;
    rst          : in  std_logic;
    cs           : in  std_logic;
    rw           : in  std_logic;
    addr         : in  std_logic_vector(3 downto 0);
    data_in      : in  std_logic_vector(7 downto 0);
    data_out     : out std_logic_vector(7 downto 0);
    --
    audio_output : out std_logic
    );
end synth;

architecture rtl of synth is
  -- ADSR registers
  signal attack            : std_logic_vector(7 downto 0);
  signal decay             : std_logic_vector(7 downto 0);
  signal sustain           : std_logic_vector(7 downto 0);
  signal release           : std_logic_vector(7 downto 0);
  -- Note registers
  signal velocity          : std_logic_vector(7 downto 0);
  signal frequency         : std_logic_vector(15 downto 0);
  -- Internal signals
  signal oscillator_output : std_logic_vector(7 downto 0);
  signal adsr_output       : std_logic_vector(7 downto 0);
begin

  my_dac : entity dac
    port map (
      reset      => rst,
      clk        => clk,
      data       => adsr_output,
      analog_out => audio_output);

  my_sawtooth : entity sawtooth
    port map (
      reset  => rst,
      clk    => clk,
      output => oscillator_output,
      div    => frequency);

  my_adsr : entity adsr
    port map (
      reset    => rst,
      clk      => clk,
      attack   => attack,
      decay    => decay,
      sustain  => sustain,
      release  => release,
      velocity => velocity,
      input    => oscillator_output,
      output   => adsr_output);

  handle_host_write : process(clk, rst)
  begin
    if rst = '1' then
      velocity  <= "10000000";
      frequency <= "1000000000000000";
      attack    <= "10000000";
      decay     <= "10000000";
      sustain   <= "10000000";
      release   <= "10000000";
    elsif falling_edge(clk) then
      if cs = '1' and rw = '0' then
        case addr(3 downto 0) is
          when X"0"   => velocity               <= data_in;
          when X"1"   => frequency(15 downto 8) <= data_in;
          when X"2"   => frequency(7 downto 0)  <= data_in;
          when X"3"   => attack                 <= data_in;
          when X"4"   => decay                  <= data_in;
          when X"5"   => sustain                <= data_in;
          when X"6"   => release                <= data_in;
          when others => null;
        end case;
      end if;
    end if;
  end process;

  with addr select data_out <=
    velocity               when X"0",
    frequency(7 downto 0)  when X"1",
    frequency(15 downto 8) when X"2",
    attack                 when X"3",
    decay                  when X"4",
    sustain                when X"5",
    release                when X"6",
    (others => '0')        when others;

end;
