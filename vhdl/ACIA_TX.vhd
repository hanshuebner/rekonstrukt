--===========================================================================--
--
--  S Y N T H E Z I A B L E    ACIA 6850   C O R E
--
--  www.OpenCores.Org - January 2007
--  This core adheres to the GNU public license  
--
-- Design units   : 6850 ACIA core for the System68/09
--
-- File name      : ACIA_TX.vhd
--
-- Purpose        : Implements an ACIA device for communication purposes 
--                  between the FPGA processor and the Host computer through
--                  a RS-232 communication protocol.
--                  
-- Dependencies   : ieee.std_logic_1164
--                  ieee.numeric_std
--                  ieee.std_logic_unsigned
--
--===========================================================================--
-------------------------------------------------------------------------------
-- Revision list
-- Version  Author        Date                        Changes
--
-- 0.1      Ovidiu Lupas  15 January 2000    New model
-- 2.0      Ovidiu Lupas  17 April   2000    unnecessary variable removed
--
-- 3.0      John Kent      5 January 2003    added 6850 word format control
-- 3.1      John Kent     12 January 2003    Rearranged state machine code
-- 3.2      John Kent     30 March 2003      Revamped State machine
-- 3.3      John Kent     16 January 2004    Major re-write - added baud rate gen
--	4.0      John Kent      3 February 2007   renamed txunit to ACIA_TX
-- 4.1      John Kent      4 February 2007   Cleaned up transmiter
-- 4.2      John Kent     25 Februauy 2007   Modify sensitivity lists and
--                                           split Tx Baud Clock select
--                                           and edge detection.
--  dilbert57@opencores.org
--
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

-------------------------------------------------------------------------------
-- Entity for the ACIA Transmitter
-------------------------------------------------------------------------------
entity ACIA_TX is
  port (
    Clk   : in  Std_Logic;                     -- CPU Clock signal
    Reset : in  Std_Logic;                     -- Reset input
    Wr    : in  Std_Logic;                     -- Load transmit data
    Din   : in  Std_Logic_Vector(7 downto 0);  -- Transmit data input.
    WdFmt : in  Std_Logic_Vector(2 downto 0);  -- word format
    BdFmt : in  Std_Logic_Vector(1 downto 0);  -- baud format
    TxClk : in  Std_Logic;                     -- Enable input
    Dat   : out Std_Logic;                     -- RS-232 data bit output
    Empty : out Std_Logic);                    -- Tx buffer empty
end ACIA_TX;  --================== End of entity ==============================--

-------------------------------------------------------------------------------
-- Architecture for  ACIA_TX
-------------------------------------------------------------------------------

architecture rtl of ACIA_TX is

  type StateType is ( SIdle, SStart, SData, SParity, S2Stop );

  -----------------------------------------------------------------------------
  -- Signals
  -----------------------------------------------------------------------------

  signal ClkDel    : Std_Logic                    := '0';  -- Delayed Tx Input Clock
  signal TxClkEdge : Std_Logic                    := '0';  -- Tx Input Clock Edge pulse
  signal ClkCnt    : Std_Logic_Vector(5 downto 0) := (others => '0');  -- Tx Baud Clock Counter
  signal BdDel     : Std_Logic                    := '0';  -- Delayed Tx Baud Clock
  signal BdClk     : Std_Logic                    := '0';  -- Tx Baud Clock
  signal ShiftReg  : Std_Logic_Vector(7 downto 0) := (others => '0');  -- Transmit shift register
  signal Parity    : Std_logic                    := '0';  -- Parity Bit
  signal BitCount  : Std_Logic_Vector(2 downto 0) := (others => '0');  -- Data Bit Counter
  signal State     : StateType;         -- Transmitter state
  signal Start     : std_logic;         -- Start transmitter

begin

  ---------------------------------------------------------------------
  -- Transmit Clock Edge Detection
  -- A falling edge will produce a one clock cycle pulse
  ---------------------------------------------------------------------

  acia_tx_clock_edge : process(Reset, Clk)
  begin
    if Reset = '1' then
      ClkDel    <= '0';
      TxClkEdge <= '0';
    elsif falling_edge(clk) then
      ClkDel    <= TxClk;
      TxClkEdge <= ClkDel and (not TxClk);
    end if;
  end process;

  ---------------------------------------------------------------------
  -- Transmit Clock Divider
  -- Advance the count only on an input clock pulse
  ---------------------------------------------------------------------

  acia_tx_clock_divide : process( Reset, Clk )
  begin
    if Reset = '1' then
      ClkCnt <= "000000";
    elsif falling_edge(clk) then
      if TxClkEdge = '1' then 
        ClkCnt <= ClkCnt + "000001";
      end if;
    end if;
  end process;

  ---------------------------------------------------------------------
  -- Transmit Baud Clock Selector
  ---------------------------------------------------------------------
  acia_tx_baud_clock_select : process( BdFmt, Clk, ClkCnt, TxClk )
  begin
    -- BdFmt
    -- 0 0     - Baud Clk divide by 1
    -- 0 1     - Baud Clk divide by 16
    -- 1 0     - Baud Clk divide by 64
    -- 1 1     - reset
    case BdFmt is
      when "00" =>	  -- Div by 1
        BdClk <= TxClk;
      when "01" =>	  -- Div by 16
        BdClk <= ClkCnt(3);
      when "10" =>	  -- Div by 64
        BdClk <= ClkCnt(5);
      when others =>  -- reset
        BdClk <= '0';
    end case;
  end process;

  -----------------------------------------------------------------------------
  -- Implements the Tx unit
  -----------------------------------------------------------------------------
  -- WdFmt - Bits[4..2]
  -- 0 0 0   - 7 data, even parity, 2 stop
  -- 0 0 1   - 7 data, odd  parity, 2 stop
  -- 0 1 0   - 7 data, even parity, 1 stop
  -- 0 1 1   - 7 data, odd  parity, 1 stop
  -- 1 0 0   - 8 data, no   parity, 2 stop
  -- 1 0 1   - 8 data, no   parity, 1 stop
  -- 1 1 0   - 8 data, even parity, 1 stop
  -- 1 1 1   - 8 data, odd  parity, 1 stop
  acia_tx_transmit : process(Reset, Clk)
  begin
    if Reset = '1' then

      Dat      <= '1';
      ShiftReg <= "00000000";
      Parity   <= '0';
      BitCount <= "000";
      State    <= SIdle;

    elsif falling_edge(clk) then

      if Wr = '1' then
        ShiftReg <= Din;            -- Load Shift reg with Tx Data
      end if;
      
      BdDel <= BdClk;
      -- On rising edge of baud clock, run the state machine
      if BdDel = '0' and BdClk = '1' then

        case State is
          when SIdle =>
            Dat <= '1';
            if Start = '1' then
              State <= SStart;
            end if;

          when SStart =>
            Dat      <= '0';            -- Start bit
            Parity   <= '0';
            if WdFmt(2) = '0' then
              BitCount <= "110";        -- 7 data + parity
            else
              BitCount <= "111";        -- 8 data
            end if;
            State <= SData;

          when SData =>
            Dat      <= ShiftReg(0);
            ShiftReg <= '1' & ShiftReg(7 downto 1);
            Parity   <= Parity xor ShiftReg(0);
            BitCount <= BitCount - "001";  
            if BitCount = "000" then
              if (WdFmt(2) = '1') and (WdFmt(1) = '0') then
                if WdFmt(0) = '0' then  -- 8 data bits
                  State <= S2Stop;      -- 2 stops
                else
                  State <= SIdle;      -- 1 stop
                end if;
              else
                State <= SParity;       -- parity
              end if;
            end if;

          when SParity =>               -- 7/8 data + parity bit
            if WdFmt(0) = '0' then
              Dat <= not(Parity);       -- even parity
            else
              Dat <= Parity;            -- odd parity
            end if;
            if WdFmt(1) = '0' then
              State <= S2Stop;          -- 2 stops
            else
              State <= SIdle;          -- 1 stop
            end if;

          when S2Stop =>                -- first of two stop bits
            Dat   <= '1';
            State <= SIdle;

        end case;
      end if;
    end if;
  end process;

  start_state_machine : process(clk, reset)
  begin
    if reset = '1' then
      Start <= '0';
    elsif falling_edge(clk) then
      if State = SStart then
        Start <= '0';
      elsif Wr = '1' and State = SIdle then
        Start <= '1';
      end if;
    end if;
  end process;

  generate_empty : process(Start, State)
  begin
    if (Start = '1') or (State /= SIdle) then
      Empty <= '0';
    else
      Empty <= '1';
    end if;
  end process;
                                                            
end rtl;
