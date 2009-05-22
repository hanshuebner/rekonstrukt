library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity beep is
  port(
    fpga_reset  : in  std_logic;
    fpga_push_a : in  std_logic;
    fpga_push_b : in  std_logic;
    fpga_push_c : in  std_logic;
    clk_16mhz   : in  std_logic;
    digi1_0     : out std_logic);
end beep;

architecture RTL of beep is

  signal gen_out    : std_logic_vector(7 downto 0);
  signal dac_in     : std_logic_vector(7 downto 0);
  signal divisor    : std_logic_vector(15 downto 0);
  signal poll_div   : std_logic_vector(15 downto 0);
  signal volume     : std_logic_vector(7 downto 0);
  signal volume_out : std_logic_vector(15 downto 0);

begin

  my_dac : entity dac
    port map (
      reset      => fpga_reset,
      clk        => clk_16mhz,
      data       => dac_in,
      analog_out => digi1_0);

  my_sawtooth : entity sawtooth
    port map (
      reset  => fpga_reset,
      clk    => clk_16mhz,
      output => gen_out,
      div    => divisor);

  dac_in <= volume_out(15 downto 8);

  volume_control : process(clk_16mhz)
  begin
    if rising_edge(clk_16mhz) then
      volume_out <= gen_out * volume;
    end if;
  end process;

  my_freq : process(clk_16mhz, fpga_reset)
  begin
    if fpga_reset = '1' then
      divisor  <= X"0040";
      volume   <= (others => '1');
      poll_div <= (others => '0');
    elsif rising_edge(clk_16mhz) then
      poll_div <= poll_div + 1;
      if poll_div = 0 then
        if fpga_push_c = '1' then
          if fpga_push_a = '1' and volume < 255 then
            volume <= volume + 1;
          elsif fpga_push_b = '1' and volume > 0 then
            volume <= volume - 1;
          end if;
        else
          if fpga_push_a = '1' then
            divisor <= divisor + 1;
          elsif fpga_push_b = '1' then
            divisor <= divisor - 1;
          end if;
        end if;
      end if;
    end if;
  end process;


end RTL;


