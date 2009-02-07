--===========================================================================--
--
--  S Y N T H E Z I A B L E    ACIA 6850   C O R E
--
--  www.OpenCores.Org - January 2007
--  This core adheres to the GNU public license  
--
-- Design units   : 6850 ACIA core
--
-- File name      : ACIA6850.vhd
--
-- Purpose        : Implements an RS232 Asynchronous serial communications device 
--                  
-- Dependencies   : ieee.std_logic_1164
--                  ieee.numeric_std
--                  unisim.vcomponents
--
--===========================================================================--
-------------------------------------------------------------------------------
-- Revision list
-- Version   Author                 Date           Changes
--
-- 0.1      Ovidiu Lupas     15 January 2000       New model
-- 1.0      Ovidiu Lupas     January  2000         Synthesis optimizations
-- 2.0      Ovidiu Lupas     April    2000         Bugs removed - RSBusCtrl
--          the RSBusCtrl did not process all possible situations
--
--        olupas@opencores.org
--
-- 3.0      John Kent        October  2002         Changed Status bits to match mc6805
--                                                 Added CTS, RTS, Baud rate control
--                                                 & Software Reset
-- 3.1      John Kent        5 January 2003        Added Word Format control a'la mc6850
-- 3.2      John Kent        19 July 2003          Latched Data input to UART
-- 3.3      John Kent        16 January 2004       Integrated clkunit in rxunit & txunit
--                                                 Now has external TX 7 RX Baud Clock
--                                                 inputs like the MC6850... 
--                                                 also supports x1 clock and DCD. 
-- 3.4		John Kent			13 September 2005		Removed LoadCS signal. 
--																	Fixed ReadCS and Read in "if" in
--																	miniuart_DCD_Init process
-- 3.5      John Kent         28 November 2006     Cleaned up code.
--
-- 4.0      John Kent         3 February 2007      renamed ACIA6850
-- 4.1      John Kent         6 February 2007      Made software reset synchronous
--	4.2      John Kent         25 February 2007     Changed sensitivity lists
--                                                 Rearranged Reset process.
--        dilbert57@opencores.org
--
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--library unisim;
--	use unisim.vcomponents.all;

-----------------------------------------------------------------------
-- Entity for ACIA_6850                                              --
-----------------------------------------------------------------------

entity ACIA_6850 is
  port (
    --
    -- CPU signals
    --
    clk      : in  Std_Logic;  -- System Clock
    rst      : in  Std_Logic;  -- Reset input (active high)
    cs       : in  Std_Logic;  -- miniUART Chip Select
    rw       : in  Std_Logic;  -- Read / Not Write
    irq      : out Std_Logic;  -- Interrupt
    Addr     : in  Std_Logic;  -- Register Select
    DataIn   : in  Std_Logic_Vector(7 downto 0); -- Data Bus In 
    DataOut  : out Std_Logic_Vector(7 downto 0); -- Data Bus Out
    --
    -- Uart Signals
    --
    RxC      : in  Std_Logic;  -- Receive Baud Clock
    TxC      : in  Std_Logic;  -- Transmit Baud Clock
    RxD      : in  Std_Logic;  -- Receive Data
    TxD      : out Std_Logic;  -- Transmit Data
    DCD_n    : in  Std_Logic;  -- Data Carrier Detect
    CTS_n    : in  Std_Logic;  -- Clear To Send
    RTS_n    : out Std_Logic );  -- Request To send
end ACIA_6850; --================== End of entity ==============================--

-------------------------------------------------------------------------------
-- Architecture for ACIA_6850 Interface registees
-------------------------------------------------------------------------------

architecture rtl of ACIA_6850 is

  type DCD_State_Type is ( DCD_State_Idle, DCD_State_Int, DCD_State_Reset );

  -----------------------------------------------------------------------------
  -- Signals
  -----------------------------------------------------------------------------

  ----------------------------------------------------------------------
  --  Status Register: StatReg 
  ----------------------------------------------------------------------
  --
  -- IO address + 0 Read
  --
  -----------+--------+-------+--------+--------+--------+--------+--------+
  --  Irq    | PErr   | OErr  | FErr   |  CTS   |  DCD   |  TxBE  |  RxDR  |
  -----------+--------+-------+--------+--------+--------+--------+--------+
  -- Irq  - Bit[7] - Interrupt request
  -- PErr - Bit[6] - Receive Parity error (parity bit does not match)
  -- OErr - Bit[5] - Receive Overrun error (new character received before last read)
  -- FErr - Bit[4] - Receive Framing Error (bad stop bit)
  -- CTS  - Bit[3] - Clear To Send level
  -- DCD  - Bit[2] - Data Carrier Detect (lost modem carrier)
  -- TxBE - Bit[1] - Transmit Buffer Empty (ready to accept next transmit character)
  -- RxDR - Bit[0] - Receive Data Ready (character received)
  -- 
  signal StatReg : Std_Logic_Vector(7 downto 0) := (others => '0'); -- status register

  ----------------------------------------------------------------------
  --  Control Register: CtrlReg
  ----------------------------------------------------------------------
  --
  -- IO address + 0 Write
  --
  -----------+--------+--------+--------+--------+--------+--------+--------+
  --  RxIEnb |TxCtl(1)|TxCtl(0)|WdFmt(2)|WdFmt(1)|WdFmt(0)|BdCtl(1)|BdCtl(0)|
  -----------+--------+--------+--------+--------+--------+--------+--------+
  -- RxIEnb - Bit[7]
  -- 0       - Rx Interrupt disabled
  -- 1       - Rx Interrupt enabled
  -- TxCtl - Bits[6..5]
  -- 0 1     - Tx Interrupt Enable
  -- 1 0     - RTS high
  -- WdFmt - Bits[4..2]
  -- 0 0 0   - 7 data, even parity, 2 stop
  -- 0 0 1   - 7 data, odd  parity, 2 stop
  -- 0 1 0   - 7 data, even parity, 1 stop
  -- 0 1 1   - 7 data, odd  parity, 1 stop
  -- 1 0 0   - 8 data, no   parity, 2 stop
  -- 1 0 1   - 8 data, no   parity, 1 stop
  -- 1 1 0   - 8 data, even parity, 1 stop
  -- 1 1 1   - 8 data, odd  parity, 1 stop
  -- BdCtl - Bits[1..0]
  -- 0 0     - Baud Clk divide by 1
  -- 0 1     - Baud Clk divide by 16
  -- 1 0     - Baud Clk divide by 64
  -- 1 1     - reset
  signal CtrlReg : Std_Logic_Vector(7 downto 0) := (others => '0'); -- control register

  ----------------------------------------------------------------------
  -- Receive Register
  ----------------------------------------------------------------------
  --
  -- IO address + 1	Read
  --
  signal RecvReg : Std_Logic_Vector(7 downto 0) := (others => '0');
  ----------------------------------------------------------------------
  -- Transmit Register
  ----------------------------------------------------------------------
  --
  -- IO address + 1	Write
  --
  signal TranReg : Std_Logic_Vector(7 downto 0) := (others => '0');
  
  signal Reset    : Std_Logic;  -- Reset (Software & Hardware)
  signal RxRst    : Std_Logic;  -- Receive Reset (Software & Hardware)
  signal TxRst    : Std_Logic;  -- Transmit Reset (Software & Hardware)
  signal TxDbit   : Std_Logic;  -- Transmit data bit
  signal RxDR     : Std_Logic := '0';  -- Receive Data ready
  signal TxBE     : Std_Logic := '0';  -- Transmit buffer empty

  signal FErr     : Std_Logic := '0';  -- Frame error
  signal OErr     : Std_Logic := '0';  -- Output error
  signal PErr     : Std_Logic := '0';  -- Parity Error

  signal TxIEnb   : Std_Logic := '0';  -- Transmit interrupt enable
  signal RxIEnb   : Std_Logic := '0';  -- Receive interrupt enable

  signal ReadRR   : Std_Logic := '0';  -- Read receive buffer
  signal WriteTR  : Std_Logic := '0';  -- Write transmit buffer
  signal ReadSR   : Std_Logic := '0';  -- Read Status register

  signal DCDState : DCD_State_Type;    -- DCD Reset state sequencer
  signal DCDDel   : Std_Logic := '0';  -- Delayed DCD_n
  signal DCDEdge  : Std_Logic := '0';  -- Rising DCD_N Edge Pulse
  signal DCDInt   : Std_Logic := '0';  -- DCD Interrupt

  -----------------------------------------------------------------------------
  -- ACIA Receiver
  -----------------------------------------------------------------------------
  component ACIA_RX
    port (
      Clk     : in  Std_Logic;                    -- Bus Clock signal
      RxRst   : in  Std_Logic;                    -- Reset input
      RxRd    : in  Std_Logic;                    -- Read data strobe
      WdFmt   : in  Std_Logic_Vector(2 downto 0); -- word format
      BdFmt   : in  Std_Logic_Vector(1 downto 0); -- baud format
      RxClk   : in  Std_Logic;                    -- Receive clock input
      RxDat   : in  Std_Logic;                    -- Receive data bit input
      RxFErr  : out Std_Logic;                    -- Framing Error Status signal
      RxOErr  : out Std_Logic;                    -- Overrun Error Status signal
      RxPErr  : out Std_logic;                    -- Parity Error Status signal
      RxRdy   : out Std_Logic;                    -- Data Ready Status signal
      RxDout  : out Std_Logic_Vector(7 downto 0));-- Receive data bus output
  end component;

  -----------------------------------------------------------------------------
  -- ACIA Transmitter
  -----------------------------------------------------------------------------
  component ACIA_TX
    port (
      Clk    : in  Std_Logic;                    -- Bus Clock signal
      TxRst  : in  Std_Logic;                    -- Reset input
      TxWr   : in  Std_Logic;                    -- Load transmit data strobe
      TxDin  : in  Std_Logic_Vector(7 downto 0); -- Transmit data bus input
      WdFmt  : in  Std_Logic_Vector(2 downto 0); -- Word format Control signal
      BdFmt  : in  Std_Logic_Vector(1 downto 0); -- Baud format Control signal
      TxClk  : in  Std_Logic;                    -- Transmit clock input
      TxDat  : out Std_Logic;                    -- Transmit data bit output
      TxEmp  : out Std_Logic );                  -- Tx buffer empty status signal
  end component;

begin
  -----------------------------------------------------------------------------
  -- Instantiation of internal components
  -----------------------------------------------------------------------------

  RxDev   : ACIA_RX  port map (
    Clk      => clk,
    RxRst    => RxRst,
    RxRd     => ReadRR,
    WdFmt    => CtrlReg(4 downto 2),
    BdFmt    => CtrlReg(1 downto 0),
    RxClk    => RxC,
    RxDat    => RxD,
    RxFErr   => FErr,
    RxOErr   => OErr,
    RxPErr   => PErr,
    RxRdy    => RxDR,
    RxDout   => RecvReg
    );

  
  TxDev   : ACIA_TX  port map (
    Clk      => clk,
    TxRst    => TxRst,
    TxWr     => WriteTR,
    TxDin    => TranReg,
    WdFmt    => CtrlReg(4 downto 2),
    BdFmt    => CtrlReg(1 downto 0),
    TxClk    => TxC,
    TxDat    => TxDbit,
    TxEmp    => TxBE
    );

---------------------------------------------------------------
-- ACIA Reset may be hardware or software
---------------------------------------------------------------
  ACIA_Reset : process( clk, rst, Reset, DCD_n )
  begin
    -- Asynchronous External reset
    if rst = '1' then
      Reset <= '1';
    elsif clk'Event and clk = '0' then
      -- Synchronous Software reset
      Reset <= CtrlReg(1) and CtrlReg(0);
    end if;	  	 
    -- Transmitter reset
    TxRst <= Reset;
    -- Receiver reset
    RxRst <= Reset or DCD_n;

  end process;

  -----------------------------------------------------------------------------
  -- ACIA Status Register
  -----------------------------------------------------------------------------
--
--ACIA_Status : process(clk,  Reset, TxIEnb, RxIEnb,
--                          RxDR, TxBE,  DCD_n, CTS_n, DCDInt,
--                          FErr, OErr,  PErr )
  ACIA_Status : process(Reset, clk )
  begin
    if Reset = '1' then
      StatReg <= (others => '0');
    elsif clk'event and clk='0' then
      StatReg(0) <= RxDR;   -- Receive Data Ready
      StatReg(1) <= TxBE and (not CTS_n); -- Transmit Buffer Empty
      StatReg(2) <= DCDInt; -- Data Carrier Detect
      StatReg(3) <= CTS_n;  -- Clear To Send
      StatReg(4) <= FErr;   -- Framing error
      StatReg(5) <= OErr;   -- Overrun error
      StatReg(6) <= PErr;   -- Parity error
      StatReg(7) <= (RxIEnb and RxDR)   or
                    (RxIEnb and DCDInt) or
                    (TxIEnb and TxBE);
    end if;
  end process;


-----------------------------------------------------------------------------
-- ACIA Transmit Control
-----------------------------------------------------------------------------

  ACIA_Control : process( CtrlReg, TxDbit )
  begin
    case CtrlReg(6 downto 5) is
      when "00" => -- Disable TX Interrupts, Assert RTS
        RTS_n  <= '0';
        TxD    <= TxDbit;
        TxIEnb <= '0';
      when "01" => -- Enable TX interrupts, Assert RTS
        RTS_n  <= '0';
        TxD    <= TxDbit;
        TxIEnb <= '1';
      when "10" => -- Disable Tx Interrupts, Clear RTS
        RTS_n  <= '1';
        TxD    <= TxDbit;
        TxIEnb <= '0';
      when "11" => -- Disable Tx interrupts, Assert RTS, send break
        RTS_n  <= '0';
        TxD    <= '0';
        TxIEnb <= '0';
      when others =>
        null;
    end case;

    RxIEnb <= CtrlReg(7);
    
  end process;

-----------------------------------------------------------------------------
-- Generate Read / Write strobes.
-----------------------------------------------------------------------------

--ACIA_Read_Write:  process(clk, Reset, cs, rw, Addr, DataIn )
  ACIA_Read_Write:  process(clk, Reset )
  begin
    if reset = '1' then
      CtrlReg <= (others => '0');
      TranReg <= (others => '0');
      ReadRR  <= '0';
      WriteTR <= '0';
      ReadSR	<= '0';
    elsif clk'event and clk='0' then
      ReadRR  <= '0';
      WriteTR <= '0';
      ReadSR  <= '0';
      if cs = '1' then
        if Addr = '0' then	-- Control / Status register
          if rw = '0' then   -- write control register
            CtrlReg <= DataIn;
          else               -- read status register
            ReadSR	<= '1';
          end if;
        else					   -- Data Register
          if rw = '0' then   -- write transmiter register
            TranReg <= DataIn;
            WriteTR <= '1';
          else               -- read receiver register
            ReadRR  <= '1';
          end if; -- rw
        end if; -- Addr
      end if;  -- cs
    end if; -- clk / reset
  end process;

---------------------------------------------------------------
-- Set Data Output Multiplexer
--------------------------------------------------------------

  ACIA_Data_Mux: process(Addr, StatReg, RecvReg)
  begin
    if Addr = '1' then
      DataOut <= RecvReg;   -- read receiver register
    else
      DataOut <= StatReg;   -- read status register
    end if; -- Addr
    irq <= StatReg(7);
  end process;


---------------------------------------------------------------
-- Data Carrier Detect Edge rising edge detect
---------------------------------------------------------------
--ACIA_DCD_edge : process( reset, clk, DCD_n, DCDDel	)
  ACIA_DCD_edge : process( reset, clk	)
  begin
    if reset = '1' then
      DCDEdge <= '0';
      DCDDel  <= '0';
    elsif clk'event and clk = '0' then
      DCDDel <= DCD_n;
      DCDEdge <= DCD_n and (not DCDDel);
    end if;
  end process;


---------------------------------------------------------------
-- Data Carrier Detect Interrupt
---------------------------------------------------------------
-- If Data Carrier is lost, an interrupt is generated
-- To clear the interrupt, first read the status register
--	then read the data receive register
--
--ACIA_DCD_Int : process( reset, clk, DCDState, DCDEdge, ReadRR, ReadSR )
  ACIA_DCD_Int : process( reset, clk )
  begin
    if reset = '1' then
      DCDInt   <= '0';
      DCDState <= DCD_State_Idle;
    elsif clk'event and clk = '0' then
      case DCDState is
        when DCD_State_Idle =>
          -- DCD Edge activates interrupt
          if DCDEdge = '1' then
            DCDInt     <= '1';
            DCDState   <= DCD_State_Int;
          end if;
        when DCD_State_Int =>
          -- To reset DCD interrupt, 
          -- First read status
          if ReadSR = '1' then
            DCDState <= DCD_State_Reset;
          end if;
        when DCD_State_Reset =>
          -- Then read receive register
          if ReadRR = '1' then
            DCDInt   <= '0';
            DCDState <= DCD_State_Idle;
          end if;
        when others =>
          null;
      end case;			
    end if; -- clk / reset
  end process;

end rtl; --===================== End of architecture =======================--

