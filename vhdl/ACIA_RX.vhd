--===========================================================================--
--
--  S Y N T H E Z I A B L E    ACIA 6850   C O R E
--
--  www.OpenCores.Org - January 2007
--  This core adheres to the GNU public license  
--
-- Design units   : 6850 ACIA core for the System68/09
--
-- File name      : ACIA_RX.vhd
--
-- Purpose        : Implements a 6850 ACIA device for communication purposes 
--                  between the cpu68/09 cpu and the Host computer through
--                  an RS-232 communication protocol.
--                  
-- Dependencies   : ieee.std_logic_1164.all;
--                  ieee.numeric_std.all;
--                  ieee.std_logic_unsigned.all;
--                  unisim.vcomponents.all;
--
--===========================================================================--
-------------------------------------------------------------------------------
-- Revision list
-- Version   Author                 Date                        Changes
--
-- 0.1      Ovidiu Lupas     15 January 2000                   New model
-- 2.0      Ovidiu Lupas     17 April   2000  samples counter cleared for bit 0
--        olupas@opencores.org
--
-- 3.0      John Kent         5 January 2003  Added 6850 word format control
-- 3.1      John Kent        12 January 2003  Significantly revamped receive code.
-- 3.2      John Kent        10 January 2004  Rewrite of code.
-- 4.0      John Kent        3 February 2007  Renamed to ACIA 6850
--                                            Removed input debounce
-- 4.1      John Kent         4 February 2007 Cleaned up Rx state machine
--	4.2      John Kent        25 February 2007 Modified sensitivity lists
--
--        dilbert57@opencores.org
-------------------------------------------------------------------------------
--
-- Description    : Implements the receive unit of the ACIA_6850 core.
--                  Samples 16 times the RxD line and retain the value
--                  in the middle of the time interval. 
--
library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std.all;
   use ieee.std_logic_unsigned.all;
--library unisim;
--	use unisim.vcomponents.all;

-------------------------------------------------------------------------------
-- Entity for the ACIA Receiver
-------------------------------------------------------------------------------
entity ACIA_RX is
  port (
     Clk    : in  Std_Logic;                    -- Clock signal
     RxRst  : in  Std_Logic;                    -- Reset input
     RxRd   : in  Std_Logic;                    -- Read data strobe
     WdFmt  : in  Std_Logic_Vector(2 downto 0); -- word format
     BdFmt  : in  Std_Logic_Vector(1 downto 0); -- baud format
     RxClk  : in  Std_Logic;                    -- RS-232 clock input
     RxDat  : in  Std_Logic;                    -- RS-232 data input
     RxFErr : out Std_Logic;                    -- Framing Error status
     RxOErr : out Std_Logic;                    -- Over Run Error Status
	  RxPErr : out Std_logic;                    -- Parity Error Status
     RxRdy  : out Std_Logic;                    -- Data Ready Status
     RxDout : out Std_Logic_Vector(7 downto 0)
	  );
end ACIA_RX; --================== End of entity ==============================--

-------------------------------------------------------------------------------
-- Architecture for ACIA receiver
-------------------------------------------------------------------------------

architecture rtl of ACIA_RX is

  type RxStateType is ( RxStart_State, RxData_state,  
								RxParity_state, RxStop_state );

  -----------------------------------------------------------------------------
  -- Signals
  -----------------------------------------------------------------------------
  signal RxDatDel0  : Std_Logic := '0';             -- Delayed Rx Data
  signal RxDatDel1  : Std_Logic := '0';             -- Delayed Rx Data
  signal RxDatDel2  : Std_Logic := '0';             -- Delayed Rx Data
  signal RxDatEdge  : Std_Logic := '0';             -- Rx Data Edge pulse
  signal RxClkDel   : Std_Logic := '0';             -- Delayed Rx Input Clock
  signal RxClkEdge  : Std_Logic := '0';             -- Rx Input Clock Edge pulse
  signal RxStart    : Std_Logic := '0';             -- Rx Start request
  signal RxEnable   : Std_Logic := '0';             -- Rx Enabled
  signal RxClkCnt   : Std_Logic_Vector(5 downto 0) := (others => '0'); -- Rx Baud Clock Counter
  signal RxBdClk    : Std_Logic := '0';             -- Rx Baud Clock
  signal RxBdDel    : Std_Logic := '0';             -- Delayed Rx Baud Clock
  signal RxBdEdge   : Std_Logic := '0';             -- Rx Baud Clock Edge pulse

  signal RxReady    : Std_Logic := '0';             -- Data Ready flag
  signal RxReq      : Std_Logic := '0';             -- Rx Data Valid
  signal RxAck      : Std_Logic := '0';             -- Rx Data Valid
  signal RxParity   : Std_Logic := '0';             -- Calculated RX parity bit
  signal RxState    : RxStateType;           -- receive bit state
  signal RxBitCount : Std_Logic_Vector(2 downto 0) := (others => '0');  -- Rx Bit counter
  signal RxShiftReg : Std_Logic_Vector(7 downto 0) := (others => '0');  -- Shift Register

begin

  ---------------------------------------------------------------------
  -- Receiver Clock Edge Detection
  ---------------------------------------------------------------------
  -- A rising edge will produce a one clock cycle pulse
  --
--  acia_rx_clock_edge : process( Clk, RxRst, RxClk, RxClkDel )
  acia_rx_clock_edge : process( RxRst, Clk )
  begin
    if RxRst = '1' then
	   RxClkDel  <= '0';
		RxClkEdge <= '0';
	 elsif Clk'event and Clk = '0' then
	   RxClkDel  <= RxClk;
		RxClkEdge <= (not RxClkDel) and RxClk;
	 end if;
  end process;

  ---------------------------------------------------------------------
  -- Receiver Data Edge Detection
  ---------------------------------------------------------------------
  -- A falling edge will produce a pulse on RxClk wide
  --
--  acia_rx_data_edge : process(Clk, RxRst, RxClkEdge, RxDat, RxDatDel0, RxDatDel1, RxDatDel2 )
  acia_rx_data_edge : process( RxRst, Clk )
  begin
    if RxRst = '1' then
	   RxDatDel0 <= '0';
	   RxDatDel1 <= '0';
	   RxDatDel2 <= '0';
		RxDatEdge <= '0';
	 elsif Clk'event and Clk = '0' then
--	   if RxClkEdge = '1' then
	     RxDatDel0 <= RxDat;
	     RxDatDel1 <= RxDatDel0;
	     RxDatDel2 <= RxDatDel1;
		  RxDatEdge <= RxDatDel0 and (not RxDat);
--    end if;
	 end if;
  end process;

  ---------------------------------------------------------------------
  -- Receiver Start / Stop
  ---------------------------------------------------------------------
  -- Enable the receive clock on detection of a start bit
  -- Disable the receive clock after a byte is received.
  -- 
--  acia_rx_start_stop : process( Clk, RxRst, RxDatEdge, RxAck, RxStart, RxEnable )
  acia_rx_start_stop : process( RxRst, Clk )
  begin
    if RxRst = '1' then
        RxEnable <= '0';
		  RxStart  <= '0';
    elsif Clk'event and Clk='0' then
        if (RxEnable = '0') and (RxDatEdge = '1') then
		    -- Data Edge detected 
			 -- Request Start and Enable Receive Clock.
          RxEnable <= '1';
			 RxStart  <= '1';
		  else
		    if (RxStart = '1') and (RxAck = '1') then
			   -- Data is being received
				-- reset start request
				RxStart <= '0';
			 else
			   -- Data has now been received
				-- Disable Receiver until next start bit
			   if (RxStart = '0') and (RxAck = '0') then
			     RxEnable <= '0';
				end if;
			 end if; -- RxStart
        end if; -- RxDatEdge
    end if; -- clk / RxRst
  end process;

  ---------------------------------------------------------------------
  -- Receiver Clock Divider
  ---------------------------------------------------------------------
  -- Hold the Rx Clock divider in reset when the receiver is disabled
  -- Advance the count only on a rising Rx clock edge
  --
--  acia_rx_clock_divide : process( Clk, RxRst, RxEnable, RxClkEdge, RxClkCnt )
  acia_rx_clock_divide : process( RxRst, Clk )
  begin
    if RxRst = '1' then
	   RxClkCnt  <= (others => '0');
	 elsif Clk'event and Clk = '0' then
--	   if RxEnable = '0' then
      if RxDatEdge = '1' then
		    RxClkCnt <= (others => '0');   -- reset on falling data edge
		else
		  if RxClkEdge = '1' then          -- increment count on Clock edge
		    RxClkCnt <= RxClkCnt + "000001";
        end if; -- RxClkEdge
      end if; -- RxState
	 end if;	 -- clk / RxRst
  end process;

  ---------------------------------------------------------------------
  -- Receiver Baud Clock Selector
  ---------------------------------------------------------------------
  -- BdFmt
  -- 0 0     - Baud Clk divide by 1
  -- 0 1     - Baud Clk divide by 16
  -- 1 0     - Baud Clk divide by 64
  -- 1 1     - Reset
  --
  acia_rx_baud_clock_select : process( BdFmt, RxClk, RxClkCnt )
  begin
    case BdFmt is
	 when "00" =>	  -- Div by 1
	   RxBdClk <= RxClk;
	 when "01" =>	  -- Div by 16
	   RxBdClk <= RxClkCnt(3);
	 when "10" =>	  -- Div by 64
	   RxBdClk <= RxClkCnt(5);
	 when others =>  -- RxRst
	   RxBdClk <= '0';
    end case;
  end process;

  ---------------------------------------------------------------------
  -- Receiver Baud Clock Edge Detect
  ---------------------------------------------------------------------
  --
  -- Generate one clock strobe on rising baud clock edge
  --
--  acia_rx_baud_clock_edge : process( Clk, RxRst, RxBdClk, RxBdDel )
  acia_rx_baud_clock_edge : process( RxRst, Clk )
  begin
    if RxRst = '1' then
	   RxBdDel  <= '0';
		RxBdEdge <= '0';
	 elsif Clk'event and Clk = '0' then
	   RxBdDel  <= RxBdClk;
		RxBdEdge <= RxBdClk and (not RxBdDel);
	 end if;
  end process;

  ---------------------------------------------------------------------
  -- Receiver process
  ---------------------------------------------------------------------
  -- WdFmt - Bits[4..2]
  -- 0 0 0   - 7 data, even parity, 2 stop
  -- 0 0 1   - 7 data, odd  parity, 2 stop
  -- 0 1 0   - 7 data, even parity, 1 stop
  -- 0 1 1   - 7 data, odd  parity, 1 stop
  -- 1 0 0   - 8 data, no   parity, 2 stop
  -- 1 0 1   - 8 data, no   parity, 1 stop
  -- 1 1 0   - 8 data, even parity, 1 stop
  -- 1 1 1   - 8 data, odd  parity, 1 stop
--  acia_rx_receive : process( Clk, RxRst, RxState, RxBdEdge, RxDatDel2, RxBitCount, RxReady, RxShiftReg )
  acia_rx_receive : process( RxRst, Clk )
  begin
    if RxRst = '1' then
        RxFErr     <= '0';
        RxOErr     <= '0';
		  RxPErr     <= '0';
        RxShiftReg <= (others => '0');         -- Resert Shift register
		  RxDOut     <= (others => '0');
		  RxParity   <= '0';                     -- reset Parity bit
		  RxAck      <= '0';                     -- Receiving data
		  RxBitCount <= (others => '0');
        RxState    <= RxStart_state;
    elsif Clk'event and Clk='0' then
        if RxBdEdge = '1' then
          case RxState is
          when RxStart_state =>
            RxShiftReg <= (others => '0');     -- Reset Shift register
		      RxParity   <= '0';                 -- Parity bit
 			   if WdFmt(2) = '0' then           
				  -- WdFmt(2) = '0' => 7 data
		        RxBitCount <= "110";
				else
				  -- WdFmt(2) = '1' => 8 data				 
		        RxBitCount <= "111";
				end if;
			   if RxDatDel2 = '0' then            -- look for start request
              RxState <= RxData_state;         -- yes, read data
			   end if;
  
          when RxData_state => -- data bits 0 to 6
            RxShiftReg <= RxDatDel2 & RxShiftReg(7 downto 1);
			   RxParity   <= RxParity xor RxDatDel2;
			 	RxAck      <= '1';   				  -- Flag receive in progress
            RxBitCount <= RxBitCount - "001";
				if RxBitCount = "000" then
 			     if WdFmt(2) = '0' then           -- WdFmt(2) = '0' => 7 data
                 RxState <= RxParity_state;    -- 7 bits always has parity
			     else                             -- WdFmt(2) = '1' => 8 data				 
			       if WdFmt(1) = '0' then         
                  RxState <= RxStop_state;     -- WdFmt(1) = '0' no parity
				    else
                  RxState <= RxParity_state;   -- WdFmt(1) = '1' parity
			       end if;	-- WdFmt(1)
				  end if; -- WdFmt(2)
				end if; -- RxBitCount

	       when RxParity_state =>               -- parity bit
 			   if WdFmt(2) = '0' then             -- 7 data, shift right
              RxShiftReg <= RxDatDel2 & RxShiftReg(7 downto 1); -- 7 data + parity
            end if;
				if WdFmt(0) = '0' then             -- parity polarity ?
				  if RxParity = RxDatDel2 then     -- check even parity
					  RxPErr <= '1';
				  else
					  RxPErr <= '0';
				  end if;
				else
				  if RxParity = RxDatDel2 then     -- check for odd parity
					  RxPErr <= '0';
				  else
					  RxPErr <= '1';
				  end if;
				end if;
            RxState <= RxStop_state;

          when RxStop_state =>                 -- stop bit (Only one required for RX)
			 	RxAck  <= '0';                     -- Flag Receive Complete
				RxDOut <= RxShiftReg;
            if RxDatDel2 = '1' then            -- stop bit expected
              RxFErr <= '0';                   -- yes, no framing error
            else
              RxFErr <= '1';                   -- no, framing error
            end if;
            if RxReady = '1' then              -- Has previous data been read ? 
              RxOErr <= '1';                   -- no, overrun error
            else
              RxOErr <= '0';                   -- yes, no over run error
            end if;
            RxState <= RxStart_state;

          when others =>
			 	RxAck   <= '0';                     -- Flag Receive Complete
            RxState <= RxStart_state;
          end case; -- RxState

        end if; -- RxBdEdge
    end if; -- clk / RxRst

  end process;

  ---------------------------------------------------------------------
  -- Receiver Read process
  ---------------------------------------------------------------------
--  acia_rx_read : process(Clk, RxRst, RxRd, RxReq, RxAck, RxReady )
  acia_rx_read : process( RxRst, Clk, RxReady )
  begin
    if RxRst = '1' then
        RxReady <= '0';
		  RxReq   <= '0';
    elsif Clk'event and Clk='0' then
        if RxRd = '1' then
		    -- Data was read, Reset data ready
			 -- Request more data
          RxReady <= '0';
			 RxReq   <= '1';
		  else
		    if RxReq = '1' and RxAck = '1' then
			   -- Data is being received
				-- reset receive request
				RxReq   <= '0';
			 else
			   -- Data now received
				-- Flag RxReady and read Shift Register
			   if RxReq = '0' and RxAck = '0' then
			     RxReady <= '1';
				end if;
			 end if; -- RxReq
        end if; -- RxRd
    end if; -- clk / RxRst
    RxRdy  <= RxReady;
  end process;

end rtl; --==================== End of architecture ====================--