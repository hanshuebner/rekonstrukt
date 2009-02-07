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
    Clk    : in  Std_Logic;                    -- CPU Clock signal
    TxRst  : in  Std_Logic;                    -- Reset input
    TxWr   : in  Std_Logic;                    -- Load transmit data
    TxDin  : in  Std_Logic_Vector(7 downto 0);	-- Transmit data input.
    WdFmt  : in  Std_Logic_Vector(2 downto 0); -- word format
    BdFmt  : in  Std_Logic_Vector(1 downto 0); -- baud format
    TxClk  : in  Std_Logic;                    -- Enable input
    TxDat  : out Std_Logic;                    -- RS-232 data bit output
    TxEmp  : out Std_Logic );                  -- Tx buffer empty
end ACIA_TX; --================== End of entity ==============================--

-------------------------------------------------------------------------------
-- Architecture for  ACIA_TX
-------------------------------------------------------------------------------

architecture rtl of ACIA_TX is

  type TxStateType is ( Tx1Stop_State, TxStart_State, 
                        TxData_State, TxParity_State, Tx2Stop_State );

  -----------------------------------------------------------------------------
  -- Signals
  -----------------------------------------------------------------------------

  signal TxClkDel   : Std_Logic := '0';             -- Delayed Tx Input Clock
  signal TxClkEdge  : Std_Logic := '0';             -- Tx Input Clock Edge pulse
  signal TxClkCnt   : Std_Logic_Vector(5 downto 0) := (others => '0'); -- Tx Baud Clock Counter
  signal TxBdDel    : Std_Logic := '0';             -- Delayed Tx Baud Clock
  signal TxBdEdge   : Std_Logic := '0';             -- Tx Baud Clock Edge pulse
  signal TxBdClk    : Std_Logic := '0';             -- Tx Baud Clock
  signal TxShiftReg : Std_Logic_Vector(7 downto 0) := (others => '0'); -- Transmit shift register
  signal TxParity   : Std_logic := '0';             -- Parity Bit
  signal TxBitCount : Std_Logic_Vector(2 downto 0) := (others => '0'); -- Data Bit Counter
  signal TxReq      : Std_Logic := '0';             -- Request Transmit
  signal TxAck      : Std_Logic := '0';             -- Transmit Commenced
  signal TxState    : TxStateType;						 -- Transmitter state

begin

  ---------------------------------------------------------------------
  -- Transmit Clock Edge Detection
  -- A falling edge will produce a one clock cycle pulse
  ---------------------------------------------------------------------

--  acia_tx_clock_edge : process(Clk, TxRst, TxClk, TxClkDel )
  acia_tx_clock_edge : process( TxRst, Clk )
  begin
    if TxRst = '1' then
      TxClkDel  <= '0';
      TxClkEdge <= '0';
    elsif Clk'event and Clk = '0' then
      TxClkDel  <= TxClk;
      TxClkEdge <= TxClkDel and (not TxClk);
    end if;
  end process;


  ---------------------------------------------------------------------
  -- Transmit Clock Divider
  -- Advance the count only on an input clock pulse
  ---------------------------------------------------------------------

--  acia_tx_clock_divide : process( Clk, TxRst, TxClkEdge, TxClkCnt )
  acia_tx_clock_divide : process( TxRst, Clk )
  begin
    if TxRst = '1' then
      TxClkCnt <= "000000";
    elsif Clk'event and Clk = '0' then
      if TxClkEdge = '1' then 
        TxClkCnt <= TxClkCnt + "000001";
      end if; -- TxClkEdge
    end if;	-- reset / clk
  end process;

  ---------------------------------------------------------------------
  -- Transmit Baud Clock Selector
  ---------------------------------------------------------------------
  acia_tx_baud_clock_select : process( BdFmt, TxClk, TxClkCnt )
  begin
    -- BdFmt
    -- 0 0     - Baud Clk divide by 1
    -- 0 1     - Baud Clk divide by 16
    -- 1 0     - Baud Clk divide by 64
    -- 1 1     - reset
    case BdFmt is
      when "00" =>	  -- Div by 1
        TxBdClk <= TxClk;
      when "01" =>	  -- Div by 16
        TxBdClk <= TxClkCnt(3);
      when "10" =>	  -- Div by 64
        TxBdClk <= TxClkCnt(5);
      when others =>  -- reset
        TxBdClk <= '0';
    end case;
  end process;

  ---------------------------------------------------------------------
  -- Transmit Baud Clock Edge Detector
  ---------------------------------------------------------------------
  --
  -- Generate one clock pulse strobe on falling edge of Tx Baud Clock
  --
--  acia_tx_baud_clock_edge : process(Clk, TxRst, TxBdClk, TxBdDel )
  acia_tx_baud_clock_edge : process( TxRst, Clk )
  begin
    if TxRst = '1' then
      TxBdDel  <= '0';
      TxBdEdge <= '0';
    elsif Clk'event and Clk = '0' then
      TxBdDel  <= TxBdClk;
      TxBdEdge <= (not TxBdClk) and TxBdDel;
    end if;
  end process;


  ---------------------------------------------------------------------
  -- Transmitter activation process
  ---------------------------------------------------------------------
--  acia_tx_write : process(Clk, TxRst, TxWr, TxReq, TxAck )
  acia_tx_write : process( TxRst, Clk )
  begin
    if TxRst = '1' then
      TxReq <= '0';
      TxEmp <= '1';
    elsif Clk'event and Clk = '0' then
      if TxWr = '1' then
        -- Write requests transmit
        -- and clears the Empty Flag 
        TxReq <= '1';
        TxEmp <= '0';
      else
        if (TxReq = '1') and (TxAck = '1') then
          -- Once the transmitter is started 
          -- We can clear request.
          TxReq <= '0';
        elsif (TxReq = '0') and (TxAck = '0') then
          -- When the transmitter is finished
          -- We can flag transmit empty
          TxEmp <= '1';
        end if;
      end if;
    end if; -- clk / reset
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
--  acia_tx_transmit :  process(TxRst, Clk, TxState, TxDin, WdFmt,  
--                              TxShiftReg, TxBdEdge, TxParity, TxBitCount,
--	                             TxReq, TxAck )
  acia_tx_transmit :  process( TxRst, Clk )  
  begin
    if TxRst = '1' then
      TxDat      <= '1';
      TxShiftReg <= "00000000";
      TxParity   <= '0';
      TxBitCount <= "000";
      TxAck      <= '0';
      TxState    <= Tx1Stop_State;
    elsif Clk'event and Clk = '0' then
      if TxBdEdge = '1' then
        case TxState is
          when Tx1Stop_State =>           -- Last Stop bit state
            TxDat <= '1';
            TxAck <= '0';				       -- Transmitter halted
            if TxReq = '1' then
              TxState <= TxStart_State;
            end if;

          when TxStart_State =>
            TxDat      <= '0';            -- Start bit
            TxShiftReg <= TxDin;		    -- Load Shift reg with Tx Data
            TxParity   <= '0';
            if WdFmt(2) = '0' then
              TxBitCount <= "110";       -- 7 data + parity
            else
              TxBitCount <= "111";       -- 8 data
            end if;
            TxAck      <= '1';				 -- Flag transmit started
            TxState    <= TxData_State;

          when TxData_State =>
            TxDat       <= TxShiftReg(0);
            TxShiftReg  <= '1' & TxShiftReg(7 downto 1);
            TxParity    <= TxParity xor TxShiftReg(0);
            TxBitCount  <= TxBitCount - "001";
            if TxBitCount = "000" then
              if (WdFmt(2) = '1') and (WdFmt(1) = '0') then
                if WdFmt(0) = '0' then          -- 8 data bits
                  TxState <= Tx2Stop_State;     -- 2 stops
                else
                  TxState <= Tx1Stop_State;     -- 1 stop
                end if;
              else
                TxState <= TxParity_State;      -- parity
              end if;
            end if;

          when TxParity_State =>                -- 7/8 data + parity bit
            if WdFmt(0) = '0' then
              TxDat <= not( TxParity );        -- even parity
            else
              TxDat <= TxParity;               -- odd parity
            end if;
            if WdFmt(1) = '0' then
              TxState <= Tx2Stop_State;         -- 2 stops
            else
              TxState <= Tx1Stop_State;         -- 1 stop
            end if;

          when Tx2Stop_State =>                 -- first of two stop bits
            TxDat   <= '1';
            TxState <= Tx1Stop_State;

          when others =>  -- Undefined
            TxDat   <= '1';
            TxState <= Tx1Stop_State;

        end case; -- TxState

      end if; -- TxBdEdge
    end if;	 -- clk / reset

  end process;

end rtl; --=================== End of architecture ====================--
