-- Rotary encoder decoding.

-- This module decodes rotary encoders.  It detects rotations and buffers them
-- into an signed byte register that represents the number of rotary ticks that
-- have been generated since the host performed the last read operation.
-- Reading resets the register to zero.  The internal width of the register is
-- 3 bits, it is sign extended to 8 bits upon reading.  If an overflow is
-- detected (i.e. the host failed to read the register value in time), a flag
-- is set in the error register.  Again, reading the error flag register resets
-- it to zero.

-- 16 encoders can be decoded by this module.

-- Bugs: should use generics for instantiation

-- Address map:

-- 0: Error status 0..7
-- 1: Error status 8..15
-- 16..31: Value registers

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
library unisim;
use unisim.vcomponents.all;

entity rotary_encoder is
  port(
    -- CPU bus interface
    clk       : in  std_logic;
    rst       : in  std_logic;
    cs        : in  std_logic;
    rw        : in  std_logic;
    addr      : in  std_logic_vector(4 downto 0);
    data_out  : out std_logic_vector(7 downto 0);
    -- Polling base clock
    clk_1mhz  : in  std_logic;
    -- 
    rot_left  : in  std_logic_vector(15 downto 0);
    rot_right : in  std_logic_vector(15 downto 0)
    );
end;

architecture rtl of rotary_encoder is

  type   value_registers is array(0 to 15) of std_logic_vector(2 downto 0);
  signal values          : value_registers;
  signal errors          : std_logic_vector(15 downto 0);
  signal rot_left_buf        : std_logic_vector(15 downto 0);
  signal rot_right_buf       : std_logic_vector(15 downto 0);
  -- Clear signal
  signal clear_errors_hi : std_logic;
  signal clear_errors_lo : std_logic;
  signal clear_reg       : std_logic_vector(15 downto 0);
  signal clear_ack       : std_logic;
  -- Clock division
  signal clock_count     : std_logic_vector(10 downto 0);
  signal clk_1mhz_buf    : std_logic;
  signal poll_clock      : std_logic;
  signal poll_clock_buf  : std_logic;
begin

  handle_host_read : process(clk, rst)
    variable encoder_no : integer;
    variable value      : std_logic_vector(2 downto 0);
  begin
    if rst = '1' then
      errors <= (others => '0');
    elsif falling_edge(clk) then
      if clear_ack = '1' then
        clear_errors_lo <= '0';
        clear_errors_hi <= '0';
        clear_reg       <= (others => '0');
      end if;
      if cs = '1' then
        if addr(4) = '0' then
          case addr(3 downto 0) is
            when "0000" =>
              data_out        <= errors(15 downto 8);
              clear_errors_hi <= '1';
            when "0001" =>
              data_out        <= errors(7 downto 0);
              clear_errors_lo <= '1';
            when others =>
              null;
          end case;
        else
          encoder_no := to_integer(unsigned(addr(3 downto 0)));
          value      := values(encoder_no);
          data_out <= (0      => value(0),
                       1      => value(1),
                       others => value(2));
          clear_reg(encoder_no) <= '1';
        end if;
      end if;
    end if;
  end process;

  divide_clock : process(clk)
  begin
    if rst = '1' then
      clock_count <= (others => '0');
    elsif falling_edge(clk) then
      clk_1mhz_buf <= clk_1mhz;
      if clk_1mhz = '1' and clk_1mhz_buf = '0' then
        clock_count <= clock_count + 1;
      end if;
    end if;
  end process;

  poll_clock <= clock_count(clock_count'high);

  poll_encoders : process(clk, rst)
    variable state : std_logic_vector(3 downto 0);
  begin
    if rst = '1' then
      for i in 0 to 16 loop
        values(i) <= (others => '0');
      end loop;
      errors        <= (others => '0');
      rot_left_buf  <= (others => '0');
      rot_right_buf <= (others => '0');
    elsif falling_edge(clk) then
      poll_clock_buf <= poll_clock;
      clear_ack      <= '0';
      if poll_clock = '1' and poll_clock_buf = '0' then
        -- On the rising edge, poll the encoders
        for i in 0 to 16 loop
          rot_left_buf(i)  <= rot_left(i);
          rot_right_buf(i) <= rot_right(i);
          if rot_left(i) /= rot_left_buf(i) or rot_right(i) /= rot_right_buf(i) then
            state := rot_left(i) & rot_left_buf(i) & rot_right(i) & rot_right_buf(i);
            case state is
              when "1011" | "0010" | "0100" | "1101" =>
                values(i) <= values(i) + 1;
                if values(i) = "011" then
                  errors(i) <= '1';
                end if;
              when "1110" | "1000" | "0001" | "0111" =>
                values(i) <= values(i) - 1;
                if values(i) = "100" then
                  errors(i) <= '1';
                end if;
              when others =>
                null;
            end case;
          end if;
        end loop;
      elsif poll_clock = '0' and poll_clock_buf = '1' then
        -- On the falling edge, handle clear signals
        if clear_errors_lo = '1' then
          errors(7 downto 0) <= (others => '0');
        end if;
        if clear_errors_hi = '1' then
          errors(15 downto 8) <= (others => '0');
        end if;
        for i in 0 to 16 loop
          if clear_reg(i) = '1' then
            values(i) <= (others => '0');
          end if;
        end loop;
        clear_ack <= '1';
      end if;
    end if;
  end process;
end rtl;
