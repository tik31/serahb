------------------------------------------------------------------------------
--  This file is a part of the GRLIB VHDL IP LIBRARY
--  Copyright (C) 2017, Cobham Gaisler AB - all rights reserved.
--
-- ANY USE OR REDISTRIBUTION IN PART OR IN WHOLE MUST BE HANDLED IN 
-- ACCORDANCE WITH THE GAISLER LICENSE AGREEMENT AND MUST BE APPROVED 
-- IN ADVANCE IN WRITING. 
--============================================================================--
-- Design unit  : GR FIFO Interface (Entity & architecture declarations)
--
-- File name    : grfifo.vhd
--
-- Library      : gaisler
--
-- Authors      : Cobham Gaisler AB
--
-- Contact      : mailto:support@gaisler.com
--                http://www.gaisler.com
--
-- Disclaimer   : All information is provided "as is", there is no warranty that
--                the information is correct or suitable for any purpose,
--                neither implicit nor explicit.
--
--------------------------------------------------------------------------------
library  IEEE;
use      IEEE.Std_Logic_1164.all;

LIBRARY  GRLIB;
USE      GRLIB.AMBA.ALL;
USE      GRLIB.STDLIB.ALL;

LIBRARY  GAISLER;
USE      GAISLER.MISC.ALL;

LIBRARY  GRLIB;
USE      GRLIB.DMA2AHB_Package.ALL;

--pragma translate_off
use      Std.TextIO.all;
--pragma translate_on

entity grfifo is
   generic (
      hindex:           Integer := 0;
      pindex:           Integer := 0;
      paddr:            Integer := 0;
      pmask:            Integer := 16#FFF#;
      pirq:             Integer := 1;                    -- index of first irq
      dwidth:           Integer := 16;                   -- data width
      ptrwidth:         Integer range 16 to 16 := 16;    --  16 to  64k bytes
                                                         -- 128 to 512k bits
      singleirq:        Integer range 0 to 1 := 1;       -- single irq output
      oepol:            Integer := 1);                   -- output enable polarity
   port (
      rstn:       in    Std_ULogic;
      clk:        in    Std_ULogic;
      apbi:       in    APB_Slv_In_Type;
      apbo:       out   APB_Slv_Out_Type;
      ahbi:       in    AHB_Mst_In_Type;
      ahbo:       out   AHB_Mst_Out_Type;
      fifoi:      in    FIFO_In_Type;
      fifoo:      out   FIFO_Out_Type);
end entity grfifo;

architecture rtl of grfifo is
   -----------------------------------------------------------------------------
   -- addressing constants
   -----------------------------------------------------------------------------
   --                                         8765432    -- address bit numbers
   constant cFifoCONF:   Std_Logic_Vector := "0000000";  -- global registers
   constant cFifoSTAT:   Std_Logic_Vector := "0000001";
   constant cFifoCTRL:   Std_Logic_Vector := "0000010";

   constant cFifoDin:    Std_Logic_Vector := "0011000";  -- general purpose I/O
   constant cFifoDout:   Std_Logic_Vector := "0011001";
   constant cFifoDdir:   Std_Logic_Vector := "0011010";

   constant cFifoTxCTRL: Std_Logic_Vector := "0001000";  -- transmit channel
   constant cFifoTxSTAT: Std_Logic_Vector := "0001001";
   constant cFifoTxADDR: Std_Logic_Vector := "0001010";
   constant cFifoTxSIZE: Std_Logic_Vector := "0001011";
   constant cFifoTxWR:   Std_Logic_Vector := "0001100";
   constant cFifoTxRD:   Std_Logic_Vector := "0001101";
   constant cFifoTxIRQ:  Std_Logic_Vector := "0001110";

   constant cFifoRxCTRL: Std_Logic_Vector := "0010000";  -- receive channel
   constant cFifoRxSTAT: Std_Logic_Vector := "0010001";
   constant cFifoRxADDR: Std_Logic_Vector := "0010010";
   constant cFifoRxSIZE: Std_Logic_Vector := "0010011";
   constant cFifoRxWR:   Std_Logic_Vector := "0010100";
   constant cFifoRxRD:   Std_Logic_Vector := "0010101";
   constant cFifoRxIRQ:  Std_Logic_Vector := "0010110";

   --                                         8765432    -- address bit numbers
   constant cFifoPIMSR:  Std_Logic_Vector := "1000000";  -- interrupt registers
   constant cFifoPIMR:   Std_Logic_Vector := "1000001";
   constant cFifoPISR:   Std_Logic_Vector := "1000010";
   constant cFifoPIR:    Std_Logic_Vector := "1000011";
   constant cFifoIMR:    Std_Logic_Vector := "1000100";
   constant cFifoPICR:   Std_Logic_Vector := "1000101";

   -----------------------------------------------------------------------------
   -- interrupt controller constants
   -----------------------------------------------------------------------------
   constant NIRQEXT:    Integer := 7;                    -- number of interrupts

   -----------------------------------------------------------------------------
   -- interrupt handling: events in priority order
   -----------------------------------------------------------------------------
   -- a) synchronous reset
   -- b) interrupt detect
   -----------------------------------------------------------------------------
   -- interrupt priority ordering / numbering
   -----------------------------------------------------------------------------
   constant iTxIrq:     Integer := 0; -- Successful transmission of block of data
   constant iTxEmpty:   Integer := 1; -- Circular transmission buffer empty
   constant iTxError:   Integer := 2; -- AMBA AHB access error during transmission
   constant iRxIrq:     Integer := 3; -- Successful reception of block of data
   constant iRxFull:    Integer := 4; -- Circular reception buffer full
   constant iRxError:   Integer := 5; -- AMBA AHB access error during reception
   constant iRxParity:  Integer := 6; -- Parity error during reception
   -----------------------------------------------------------------------------

   -----------------------------------------------------------------------------
   -- configuration constants
   -----------------------------------------------------------------------------
   constant REVISION:   Integer := 0;

   constant pconfig:    apb_config_type := (
      0 => ahb_device_reg (16#01#, 16#035#, 0, REVISION, pirq),
      1 => apb_iobar(paddr, pmask));

   -----------------------------------------------------------------------------
   -- caclulate parity, odd or even
   -----------------------------------------------------------------------------
   function parity (
      constant odd:  in Std_ULogic;
      constant d:    in Std_Logic_Vector)
      return            Std_ULogic is
      variable p:       Std_ULogic;
   begin
      p := '0';
      for i in d'Range loop
         p := p xor d(i);
      end loop;
      if odd='1' then
         return  not p;
      else
         return      p;
      end if;
   end function parity;

   -----------------------------------------------------------------------------
   -- synchronization
   -----------------------------------------------------------------------------
   type sync_type is record
      first:            FIFO_In_Type;
      second:           FIFO_In_Type;
      third:            FIFO_In_Type;
      grant:            Std_ULogic;
   end record;

   -----------------------------------------------------------------------------
   -- interrupts
   -----------------------------------------------------------------------------
   type irq_type is record
      -- interrupt registers
      pir:              Std_Logic_Vector(NIRQEXT-1 downto 0);
      imr:              Std_Logic_Vector(NIRQEXT-1 downto 0);
   end record;

   -----------------------------------------------------------------------------
   -- configuration register
   -----------------------------------------------------------------------------
   type conf_type is record
      ABORT:            Std_ULogic;                      -- Abort on AHB error
                                                         --    0b = no action
                                                         --    1b = abort
      DW:               Std_Logic_Vector(1 downto 0);    -- FIFO data width:
                                                         --    00b = none
                                                         --    01b =  8 bit FIFOI.Din[ 7:0], FIFOO.Dout[ 7:0]
                                                         --    10b = 16 bit FIFOI.Din[15:0], FIFOO.Dout[15:0]
                                                         --    11b = none/spare
      PARITY:           Std_ULogic;                      -- Parity Type:
                                                         --    0b = even
                                                         --    1b = odd
      WS:               Std_Logic_Vector(2 downto 0);    -- Number of wait states
   end record;


   -----------------------------------------------------------------------------
   -- control register
   -----------------------------------------------------------------------------
   type ctrl_type is record
      RESET:            Std_ULogic;                      --    0b = no action
                                                         --    1b = reset
   end record;

   -----------------------------------------------------------------------------
   -- WS threshold for adding additional gap between accesses
   -----------------------------------------------------------------------------
   constant WSLarge:    Std_Logic_Vector(2 downto 0) := "100";

   -----------------------------------------------------------------------------
   -- buffer types
   -----------------------------------------------------------------------------
   subtype  buff_type       is Std_Logic_Vector(63 downto 0);
   type     buff_array_type is array (Natural range <>) of buff_type;

   -----------------------------------------------------------------------------
   -- transmit channel registers
   -----------------------------------------------------------------------------
   type tx_reg_type is record
      -- ctrl
      enable:           Std_ULogic;
      -- status
      txongoing:        Std_ULogic;
      txirq:            Std_ULogic;
      txempty:          Std_ULogic;
      txerror:          Std_ULogic;
      -- dma settings and pointers
      addr:             Std_Logic_Vector(31 downto 10);
      size:             Std_Logic_Vector(ptrwidth   downto 2);
      wr:               Std_Logic_Vector(ptrwidth-1 downto 0);
      rd:               Std_Logic_Vector(ptrwidth-1 downto 0);
      irq:              Std_Logic_Vector(ptrwidth-1 downto 0);
      -- buffer
      buff_rdaddr:      Std_ULogic;                      -- buffer read address
      buff_wraddr:      Std_ULogic;                      -- buffer write address
      buff:             buff_array_type(0 to 1);
      eval:             Std_ULogic;
      -- dma handling
      dma_first_req:    Std_ULogic;
      dma_first_rdy:    Std_ULogic;
      dma_second_req:   Std_ULogic;
      dma_second_rdy:   Std_ULogic;
      dma_second_err:   Std_ULogic;
   end record;

   -----------------------------------------------------------------------------
   -- receive channel registers
   -----------------------------------------------------------------------------
   type rx_reg_type is record
      -- ctrl
      enable:           Std_ULogic;
      -- status
      rxongoing:        Std_ULogic;
      rxparity:         Std_ULogic;
      rxirq:            Std_ULogic;
      rxfull:           Std_ULogic;
      rxerror:          Std_ULogic;
      -- dma settings and pointers
      addr:             Std_Logic_Vector(31 downto 10);
      size:             Std_Logic_Vector(ptrwidth   downto 2);
      wr:               Std_Logic_Vector(ptrwidth-1 downto 0);
      rd:               Std_Logic_Vector(ptrwidth-1 downto 0);
      irq:              Std_Logic_Vector(ptrwidth-1 downto 0);
      -- buffer
      buff_rdaddr:      Std_ULogic;                      -- buffer read address
      buff_wraddr:      Std_ULogic;                      -- buffer write address
      buff:             buff_array_type(0 to 1);
      buffptr:          Std_Logic_Vector(3 downto 0);    -- none, 1, 2, 3, 4, 5, 6, 7, 8, -
      eval:             Std_ULogic;
      -- dma handling
      dma_first_req:    Std_ULogic;
      dma_first_rdy:    Std_ULogic;
      dma_inc:          Std_Logic_Vector(3 downto 0);    -- none, 1, 2, 3, 4, 5, 6, 7, 8, -
   end record;

   -----------------------------------------------------------------------------
   -- state register
   -----------------------------------------------------------------------------
   type fifo_state_type is (sIdle, sRead, sWrite, sGap);

   type fifo_ctrl_type is record
      state:            fifo_state_type;
      ws:               Std_Logic_Vector(2 downto 0);
      sel_tx:           Std_ULogic;
      last_tx:          Std_ULogic;
      last_rx:          Std_ULogic;
      sample_rx:        Std_ULogic;
      empty:            Std_ULogic;
      full:             Std_ULogic;
   end record;

   constant Zero:       Std_Logic_Vector(2 downto 0) := (others => '0');
   constant One:        Std_Logic_Vector(2 downto 0) := "001";

   -----------------------------------------------------------------------------
   -- AHB/DMA handling
   -----------------------------------------------------------------------------
   type ahb_ctrl_type is record
      sel_tx:           Std_ULogic;
      busy:             Std_ULogic;
      restart:          Std_ULogic;
      pause:            Std_ULogic;
      second:           Std_ULogic;                      -- pre-fetch ongoing
      firstburst:       Std_ULogic;
      firstgrant:       Std_ULogic;
   end record;

   -----------------------------------------------------------------------------
   -- registers
   -----------------------------------------------------------------------------
   type register_type is record
      -- synchronisation
      sync:             sync_type;

      -- configuration
      conf:             conf_type;
      -- control
      ctrl:             ctrl_type;
      -- transmit channel
      tx:               tx_reg_type;
      -- receive channel
      rx:               rx_reg_type;

      -- fifo handling
      fifo:             fifo_ctrl_type;

      -- fifo output interface
      fifoo:            fifo_out_type;

      -- ahb/dma handling
      ahb:              ahb_ctrl_type;
      dmai:             dma_in_type;

      -- interrupt handling
      irq:              irq_type;
   end record;

   signal   r, rin:     register_type;

   -----------------------------------------------------------------------------
   -- local unregistered signals
   -----------------------------------------------------------------------------
   signal   dmao:       dma_out_type;                    -- dma output

   -----------------------------------------------------------------------------
   -- temporary unregistered variables
   -----------------------------------------------------------------------------
   type fifo_handling_type is record
      req:              Std_ULogic;
      rdy:              Std_ULogic;
      last:             Std_ULogic;                      -- last byte
      data:             Std_Logic_Vector(31 downto 0);
      parity:           Std_Logic_Vector( 3 downto 0);
   end record;

   type temporary_type is record
      prdata:           Std_Logic_Vector(31 downto 0);
      pirq:             Std_Logic_Vector(NIRQEXT-1 downto 0);
      tmp:              Std_ULogic;

      fifo_tx:          fifo_handling_type;
      fifo_rx:          fifo_handling_type;
   end record;

   -----------------------------------------------------------------------------
   -- pointer handling functions
   -----------------------------------------------------------------------------
   -- It is not possible to write the buffer full, always one word
   -- unused during transmit and receive.
   -- Software is responible for not overwriting buffer (i.e. setting wr=rd
   -- on wrap around), since this will disable transmission.
   -----------------------------------------------------------------------------

   -----------------------------------------------------------------------------
   -- General pointer increment
   -----------------------------------------------------------------------------
   function inc_ptr(
      constant ptr:     in    Std_Logic_Vector;
      constant size:    in    Std_Logic_Vector)
      return                  Std_Logic_Vector is
      variable tmp_size:      Std_Logic_Vector(size'Length -1 downto 0);
      variable tmp_ptr:       Std_Logic_Vector(ptr'Length     downto 0);
      variable result:        Std_Logic_Vector(ptr'Length -1  downto 0);
      constant zero:          Std_Logic_Vector(ptr'Length -1  downto 0) :=
                                 (others => '0');
   begin
      tmp_size    := size-1;
      tmp_ptr     := '0' & ptr;
      if tmp_ptr < tmp_size then
         result   := ptr+1;
      else
         result   := zero;
      end if;
      return result;
   end function;

   -----------------------------------------------------------------------------
   -- Rx write pointer increment - doubleword
   -----------------------------------------------------------------------------
   function inc_double_wr(
      constant rx:      in    rx_reg_type)
      return                  Std_Logic_Vector is
   begin
      return inc_ptr(rx.wr  (ptrwidth-1 downto 3),
                     rx.size(ptrwidth downto 3)) & "000";
   end function;

   -----------------------------------------------------------------------------
   -- Tx read pointer increment - byte
   -----------------------------------------------------------------------------
   function inc_rd(
      constant tx:      in    tx_reg_type;
      constant dw:      in    Std_Logic_Vector(1 downto 0))
      return                  Std_Logic_Vector is
      variable result:        Std_Logic_Vector(ptrwidth-1 downto 0);
   begin
      -- mask lsb if 16 bit interface
      if dw="10" then
         result := inc_ptr(tx.rd(ptrwidth-1 downto 1), tx.size & "0") & '0';
      else
         result := inc_ptr(tx.rd, tx.size & "00");
      end if;
      return result;
   end function;

   -----------------------------------------------------------------------------
   -- Tx read pointer increment - doubleword
   -----------------------------------------------------------------------------
   function inc_double_rd(
      constant tx:      in    tx_reg_type)
      return                  Std_Logic_Vector is
      variable tmp:           Std_Logic_Vector(ptrwidth-1 downto 2);
      variable result:        Std_Logic_Vector(ptrwidth-1 downto 3);
   begin
      tmp   := inc_ptr(tx.rd(ptrwidth-1 downto 2),
                       tx.size(ptrwidth downto 2));
      tmp   := inc_ptr(tmp, tx.size(ptrwidth downto 2));
      result:=tmp(ptrwidth-1 downto 3);
      return result;
   end function;

   -----------------------------------------------------------------------------
   -- General request based on read and write pointer, and size
   -----------------------------------------------------------------------------
   function request(
      constant inptr:   in    Std_Logic_Vector;
      constant outptr:  in    Std_Logic_Vector;
      constant size:    in    Std_Logic_Vector;
      constant nochk:   in    Boolean := False)
      return                  Boolean is
      variable iless:         Boolean;
      variable oless:         Boolean;
      variable more:          Boolean;
      variable less:          Boolean;
      variable equal:         Boolean;
   begin
      -- -- original logic
      -- if inptr < size and outptr < size then          -- in range
      --    if    inptr > outptr then                    -- no wrap
      --       return True;
      --    elsif inptr < outptr then                    --    wrap
      --       return True;
      --    else
      --       return False;
      --    end if;
      -- else                                            -- out of range
      --    return False;
      -- end if;

      -- -- optimised logic
      iless := inptr < size;
      oless := nochk or (outptr < size);
      -- more  := inptr > outptr;
      -- less  := inptr < outptr;
      -- equal := not (more or less;)
      equal := inptr = outptr;
      return (iless and oless) and (not equal);
   end function;

   -----------------------------------------------------------------------------
   -- Tx request for message fetch
   -----------------------------------------------------------------------------
   function tx_request(
      constant tx:      in    tx_reg_type;
      constant dw:      in    Std_Logic_Vector(1 downto 0))
      return                  Boolean is
      variable txp_wr:        Std_Logic_Vector(ptrwidth-1 downto 0);
      variable txp_rd:        Std_Logic_Vector(ptrwidth-1 downto 0);
   begin
      -- mask lsb if 16 bit interface
      if dw="00" or dw="11" then
         return False;
      elsif dw="10" then
         txp_wr   := tx.wr(ptrwidth-1 downto 1) & '0';
         txp_rd   := tx.rd(ptrwidth-1 downto 1) & '0';
      else
         txp_wr   := tx.wr;
         txp_rd   := tx.rd;
      end if;
      return request('0' & txp_wr, '0' & txp_rd, tx.size & "00");
   end function;

   -----------------------------------------------------------------------------
   -- Tx request for message pre-fetch
   -----------------------------------------------------------------------------
   function tx_request2(
      constant tx:      in    tx_reg_type;
      constant dw:      in    Std_Logic_Vector(1 downto 0))
      return                  Boolean is
      variable txp_wr:        Std_Logic_Vector(ptrwidth-1 downto 0);
      variable txp_rd:        Std_Logic_Vector(ptrwidth-1 downto 0);
   begin
      -- mask lsb if 16 bit interface
      if dw="00" or dw="11" then
         return False;
      elsif dw="10" then
         txp_wr   := tx.wr(ptrwidth-1 downto 1) & '0';
         txp_rd   := inc_rd(tx, dw)(ptrwidth-1 downto 1) & '0';
      else
         txp_wr   := tx.wr;
         txp_rd   := inc_rd(tx, dw);
      end if;
      -- determine if there is more data available after increment
      if request('0' & txp_wr, '0' & txp_rd, tx.size & "00", True) then
         -- determine if the data is in the next two words
         if (txp_wr(ptrwidth-1 downto 3) /= tx.rd(ptrwidth-1 downto 3)) and
            ((txp_wr(2 downto 0) /= "000") or
             (txp_wr(ptrwidth-1 downto 3) /=
              inc_ptr(tx.rd(ptrwidth-1 downto 3),
                      tx.size(ptrwidth downto 3)))) then
            return True;
         else
            return False;
         end if;
      else
         return False;
      end if;
   end function;

   -----------------------------------------------------------------------------
   -- General available based on read and write pointer, and size
   -----------------------------------------------------------------------------
   function available(
      constant inptr:   in    Std_Logic_Vector;
      constant outptr:  in    Std_Logic_Vector;
      constant size:    in    Std_Logic_Vector)
      return                  Boolean is
      constant zero:          Std_Logic_Vector(inptr'Length -1 downto 0) :=
                                 (others => '0');
      variable iless:         Boolean;
      variable oless:         Boolean;
      variable no_wrap:       Boolean;
      variable wrap:          Boolean;
      variable wrapped:       Boolean;
   begin
      -- -- original logic
      -- if inptr < size and outptr < size then             -- in range
      --    if    inptr >= outptr and inptr < size-1 then   -- no wrap
      --       return True;
      --    elsif inptr = size-1 and                        --    wrap
      --          outptr > zero then
      --       return True;
      --    elsif inptr < outptr-1 and                      --    wrapped
      --          outptr > zero then
      --       return True;
      --    else
      --       return False;
      --    end if;
      -- else                                               -- out of range
      --    return False;
      -- end if;

      -- -- optimised logic
      iless    := inptr < size;
      oless    := outptr < size;
      no_wrap  := (inptr >= outptr) and (inptr < size-1);
      wrap     := (inptr = size-1) and (outptr > zero);
      wrapped  := (inptr < outptr-1) and (outptr > zero);
      return (iless and oless) and (no_wrap or wrap or wrapped);
   end function;

   -----------------------------------------------------------------------------
   -- Rx avaiable for message store
   -----------------------------------------------------------------------------
   function rx_available(
      constant rx:      in    rx_reg_type;
      constant dw:      in    Std_Logic_Vector(1 downto 0))
      return                  Boolean is
   begin
      return available('0' & rx.wr(ptrwidth-1 downto 3),
                       '0' & rx.rd(ptrwidth-1 downto 3),
                        rx.size(ptrwidth downto 3));
   end function;

   -----------------------------------------------------------------------------
   -- Tx irq match
   -----------------------------------------------------------------------------
   function tx_irq_match(
      constant tx:      in    tx_reg_type;
      constant dw:      in    Std_Logic_Vector(1 downto 0))
      return                  Boolean is
   begin
      if    dw="00" or dw="11" then
         return False;
      elsif dw="10" then
         return tx.rd(ptrwidth-1 downto 1)=tx.irq(ptrwidth-1 downto 1);
      else
         return tx.rd=tx.irq;
      end if;
   end function;

   -----------------------------------------------------------------------------
   -- Rx irq match, store data
   -----------------------------------------------------------------------------
   function rx_irq_match(
      constant rx:      in    rx_reg_type;
      constant dw:      in    Std_Logic_Vector(1 downto 0))
      return                  Boolean is
      variable rxp_irq:       Std_Logic_Vector(ptrwidth-1 downto 0);
      variable rxp_wr:        Std_Logic_Vector(ptrwidth-1 downto 0);
   begin
      -- mask lsb if 16 bit interface
      if    dw="00" or dw="11" then
         return False;
      elsif dw="10" then
         rxp_irq  := rx.irq(ptrwidth-1 downto 1) & '0';
         rxp_wr   := rx.wr (ptrwidth-1 downto 1) & '0';
      else
         rxp_irq  := rx.irq;
         rxp_wr   := rx.wr;
      end if;
      return rxp_wr=rxp_irq;
   end function;

   -----------------------------------------------------------------------------
   -- Rx irq match, store data
   -----------------------------------------------------------------------------
   function rx_irq_partial_match(
      constant rx:      in    rx_reg_type;
      constant dw:      in    Std_Logic_Vector(1 downto 0))
      return                  Boolean is
      variable tmp:           Std_Logic_Vector(ptrwidth-1 downto 0);
   begin
      if (rx.wr(2 downto 1) < rx.buffptr(2 downto 1) and dw="10") or
         (rx.wr(2 downto 0) < rx.buffptr(2 downto 0) and dw="01") then
         tmp := rx.wr(ptrwidth-1 downto 3) & "000";
         if (dw="01" and rx.irq = (tmp + rx.buffptr)) or
            (dw="10" and rx.irq(ptrwidth-1 downto 1) = (tmp(ptrwidth-1 downto 1) + rx.buffptr(3 downto 1))) then
            return True;
         else
            return False;
         end if;
      else
         return False;
      end if;
   end function;

   -----------------------------------------------------------------------------
   -- Last transmit data
   -----------------------------------------------------------------------------
   function tx_last(
      constant v:       in    tx_reg_type;
      constant r:       in    tx_reg_type;
      constant dw:      in    Std_Logic_Vector(1 downto 0))
      return                  Boolean is
      variable vp_rd:         Std_Logic_Vector(ptrwidth-1 downto 0);
      variable rp_wr:         Std_Logic_Vector(ptrwidth-1 downto 0);

   begin
      -- mask lsb if 16 bit interface
      if    dw="00" or dw="11" then
         return False;
      elsif dw="10" then
         vp_rd   := v.rd(ptrwidth-1 downto 1) & '0';
         rp_wr   := r.wr(ptrwidth-1 downto 1) & '0';
      else
         vp_rd   := v.rd;
         rp_wr   := r.wr;
      end if;
      return vp_rd = rp_wr;
   end function;

begin

   -----------------------------------------------------------------------------
   -- combinatorial logic
   -----------------------------------------------------------------------------
   comb: process(rstn, r, apbi, fifoi, dmao)
      variable v:             register_type;
      variable t:             temporary_type;
   begin
      --------------------------------------------------------------------------
      -- local temporary variables
      t.prdata             := (others => '0');
      -- interrupt asserted one period only
      t.pirq               := (others => '0');

      t.fifo_tx.req        := '0';
      t.fifo_tx.rdy        := '0';
      t.fifo_tx.last       := '0';
      t.fifo_tx.data       := (others => '0');
      t.fifo_tx.parity     := (others => '0');

      t.fifo_rx.req        := '0';
      t.fifo_rx.rdy        := '0';
      t.fifo_rx.last       := '0';
      t.fifo_rx.data       := (others => '0');
      t.fifo_rx.parity     := (others => '0');

      --------------------------------------------------------------------------
      -- local variable copy of register signal
      v := r;

      --------------------------------------------------------------------------
      -- synchronization of external inputs
      v.sync.first         := fifoi;
      v.sync.second        := r.sync.first;
      v.sync.third         := r.sync.second;             -- not all used

      v.sync.grant         := dmao.grant;

      --------------------------------------------------------------------------
      -- FIFO flag handling
      --------------------------------------------------------------------------
      if    r.sync.second.EFn='0' and r.sync.third.EFn='0' then
         v.fifo.empty   := '1';
      elsif r.sync.second.EFn='1' and r.sync.third.EFn='1' then
         v.fifo.empty   := '0';
      end if;

      if    r.sync.second.FFn='0' and r.sync.third.FFn='0' then
         v.fifo.full   := '1';
      elsif r.sync.second.FFn='1' and r.sync.third.FFn='1' then
         v.fifo.full   := '0';
      end if;

      --------------------------------------------------------------------------
      -- amba apb interface
      --------------------------------------------------------------------------
      --------------------------------------------------------------------------
      -- read registers
      if    apbi.paddr(8 downto 2)=cFifoCONF then
         -- configuration register
         t.prdata(6)                      := r.conf.ABORT;
         t.prdata(5 downto 4)             := r.conf.DW;
         t.prdata(3)                      := r.conf.PARITY;
         t.prdata(2 downto 0)             := r.conf.WS;

      elsif apbi.paddr(8 downto 2)=cFifoSTAT then
         -- status register
         -- t.prdata(31 downto 28) := Conv_Std_Logic_Vector(txchannels-1, 4);
         -- t.prdata(27 downto 24) := Conv_Std_Logic_Vector(rxchannels-1, 4);
         if singleirq /= 0 then
            t.prdata(5)                   := '1';
         end if;

      -- transmit channel
      elsif apbi.paddr(8 downto 2)=cFifoTxCTRL then
         t.prdata(0)                      := r.tx.enable;
      elsif apbi.paddr(8 downto 2)=cFifoTxSTAT then
         t.prdata(6)                      := r.tx.txongoing;
         t.prdata(4)                      := r.tx.txirq;
         t.prdata(3)                      := r.tx.txempty;
         t.prdata(2)                      := r.tx.txerror;
         t.prdata(1)                      := not r.sync.second.FFn;
         t.prdata(0)                      := not r.sync.second.HFn;
         -- cleared on read
         if apbi.penable='1' and apbi.psel(pindex)='1' and apbi.pwrite='0' then
            v.tx.txirq                    := '0';
            v.tx.txempty                  := '0';
            v.tx.txerror                  := '0';
         end if;

      elsif apbi.paddr(8 downto 2)=cFifoTxADDR then
         t.prdata(31 downto 10)           := r.tx.addr;
      elsif apbi.paddr(8 downto 2)=cFifoTxSIZE then
         t.prdata(ptrwidth downto 6)      := r.tx.size(ptrwidth downto 6);
      elsif apbi.paddr(8 downto 2)=cFifoTxWR then
         t.prdata(ptrwidth-1 downto 0)    := r.tx.wr;
      elsif apbi.paddr(8 downto 2)=cFifoTxRD then
         t.prdata(ptrwidth-1 downto 0)    := r.tx.rd;
      elsif apbi.paddr(8 downto 2)=cFifoTxIRQ then
         t.prdata(ptrwidth-1 downto 0)    := r.tx.irq;

      -- receive channel
      elsif apbi.paddr(8 downto 2)=cFifoRxCTRL then
         t.prdata(0)                      := r.rx.enable;
      elsif apbi.paddr(8 downto 2)=cFifoRxSTAT then
         if r.conf.DW="01" then
            t.prdata(10 downto 8)         := r.rx.buffptr(2 downto 0) -
                                             r.rx.wr(2 downto 0);
         else
            t.prdata(10 downto 9)         := r.rx.buffptr(2 downto 1) -
                                             r.rx.wr(2 downto 1);
         end if;
         t.prdata(6)                      := r.rx.rxongoing;
         t.prdata(5)                      := r.rx.rxparity;
         t.prdata(4)                      := r.rx.rxirq;
         t.prdata(3)                      := r.rx.rxfull;
         t.prdata(2)                      := r.rx.rxerror;
         t.prdata(1)                      := not r.sync.second.EFn;
         t.prdata(0)                      := not r.sync.second.HFn;
         -- cleared on read
         if apbi.penable='1' and apbi.psel(pindex)='1' and apbi.pwrite='0' then
            v.rx.rxparity                 := '0';
            v.rx.rxirq                    := '0';
            v.rx.rxfull                   := '0';
            v.rx.rxerror                  := '0';
         end if;

      elsif apbi.paddr(8 downto 2)=cFifoRxADDR then
         t.prdata(31 downto 10)           := r.rx.addr;
      elsif apbi.paddr(8 downto 2)=cFifoRxSIZE then
         t.prdata(ptrwidth downto 6)      := r.rx.size(ptrwidth downto 6);
      elsif apbi.paddr(8 downto 2)=cFifoRxWR then
         t.prdata(ptrwidth-1 downto 0)    := r.rx.wr;
      elsif apbi.paddr(8 downto 2)=cFifoRxRD then
         t.prdata(ptrwidth-1 downto 0)    := r.rx.rd;
      elsif apbi.paddr(8 downto 2)=cFifoRxIRQ then
         t.prdata(ptrwidth-1 downto 0)    := r.rx.irq;

      -- general purpose input output data
      elsif apbi.paddr(8 downto 2)=cFifoDin then
         if    r.conf.DW="01" then
            -- 8 least significant bits unavailable
            t.prdata(dwidth-1 downto 8)   := r.sync.second.din(dwidth-1 downto 8);
         elsif r.conf.DW="00" then
            -- all bits available
            t.prdata(dwidth-1 downto 0)   := r.sync.second.din(dwidth-1 downto 0);
         end if;
      elsif apbi.paddr(8 downto 2)=cFifoDout then
         if    r.conf.DW="01" then
            -- 8 least significant bits unavailable
            t.prdata(dwidth-1 downto 8)   := r.fifoo.dout(dwidth-1 downto 8);
         elsif r.conf.DW="00" then
            -- all bits available
            t.prdata(dwidth-1 downto 0)   := r.fifoo.dout(dwidth-1 downto 0);
         end if;
      elsif apbi.paddr(8 downto 2)=cFifoDdir then
         if    r.conf.DW="01" then
            -- 8 least significant bits unavailable
            if oepol = 0 then
               t.prdata(dwidth-1 downto 8):= not r.fifoo.den(dwidth-1 downto 8);
            else
               t.prdata(dwidth-1 downto 8):=     r.fifoo.den(dwidth-1 downto 8);
            end if;
         elsif r.conf.DW="00" then
            -- all bits available
            if oepol = 0 then
               t.prdata(dwidth-1 downto 0):= not r.fifoo.den(dwidth-1 downto 0);
            else
               t.prdata(dwidth-1 downto 0):=     r.fifoo.den(dwidth-1 downto 0);
            end if;
         end if;

      -- interrupt registers
      elsif apbi.paddr(8 downto 2)=cFifoPIMSR and singleirq /= 0 then
         t.prdata(NIRQEXT-1 downto 0)  := r.irq.pir(NIRQEXT-1 downto 0) and
                                          r.irq.imr(NIRQEXT-1 downto 0);
      elsif apbi.paddr(8 downto 2)=cFifoPIMR and singleirq /= 0  then
         t.prdata(NIRQEXT-1 downto 0)  := r.irq.pir(NIRQEXT-1 downto 0) and
                                          r.irq.imr(NIRQEXT-1 downto 0);
         if apbi.penable='1' and apbi.psel(pindex)='1' and apbi.pwrite='0' then
            v.irq.pir                  := (others => '0');
         end if;
      elsif apbi.paddr(8 downto 2)=cFifoPISR and singleirq /= 0  then
         t.prdata(NIRQEXT-1 downto 0)  := r.irq.pir(NIRQEXT-1 downto 0);
      elsif apbi.paddr(8 downto 2)=cFifoPIR and singleirq /= 0  then
         t.prdata(NIRQEXT-1 downto 0)  := r.irq.pir(NIRQEXT-1 downto 0);
         if apbi.penable='1' and apbi.psel(pindex)='1' and apbi.pwrite='0' then
            v.irq.pir                  := (others => '0');
         end if;
      elsif apbi.paddr(8 downto 2)=cFifoIMR and singleirq /= 0  then
         t.prdata(NIRQEXT-1 downto 0)  := r.irq.imr(NIRQEXT-1 downto 0);
      elsif apbi.paddr(8 downto 2)=cFifoPICR and singleirq /= 0  then

      end if;

      --------------------------------------------------------------------------
      -- write registers
      if (apbi.psel(pindex) and apbi.penable and apbi.pwrite) = '1' then
         if    apbi.paddr(8 downto 2)=cFifoCONF then
            -- configuration register
            v.conf.ABORT   := apbi.pwdata(6);
            v.conf.DW      := apbi.pwdata(5 downto 4);
            v.conf.PARITY  := apbi.pwdata(3);
            v.conf.WS      := apbi.pwdata(2 downto 0);

         elsif apbi.paddr(8 downto 2)=cFifoCTRL then
            -- control register
            v.ctrl.RESET   := apbi.pwdata(1);

         -- transmit channel
         elsif apbi.paddr(8 downto 2)=cFifoTxCTRL then
            v.tx.enable    := apbi.pwdata(0);
         elsif apbi.paddr(8 downto 2)=cFifoTxADDR then
            v.tx.addr      := apbi.pwdata(31 downto 10);
         elsif apbi.paddr(8 downto 2)=cFifoTxSIZE then
            v.tx.size      := apbi.pwdata(ptrwidth downto 6) & "0000";
         elsif apbi.paddr(8 downto 2)=cFifoTxWR then
            v.tx.wr        := apbi.pwdata(ptrwidth-1 downto 0);
         elsif apbi.paddr(8 downto 2)=cFifoTxRD then
            v.tx.rd        := apbi.pwdata(ptrwidth-1 downto 0);
         elsif apbi.paddr(8 downto 2)=cFifoTxIRQ then
            v.tx.irq       := apbi.pwdata(ptrwidth-1 downto 0);

         -- receive channel
         elsif apbi.paddr(8 downto 2)=cFifoRxCTRL then
            v.rx.enable    := apbi.pwdata(0);
         elsif apbi.paddr(8 downto 2)=cFifoRxADDR then
            v.rx.addr      := apbi.pwdata(31 downto 10);
         elsif apbi.paddr(8 downto 2)=cFifoRxSIZE then
            v.rx.size      := apbi.pwdata(ptrwidth downto 6) & "0000";
         elsif apbi.paddr(8 downto 2)=cFifoRxWR then
            v.rx.wr        := apbi.pwdata(ptrwidth-1 downto 0);
            v.rx.buffptr   := '0' & apbi.pwdata(2 downto 0);
         elsif apbi.paddr(8 downto 2)=cFifoRxRD then
            v.rx.rd        := apbi.pwdata(ptrwidth-1 downto 0);
         elsif apbi.paddr(8 downto 2)=cFifoRxIRQ then
            v.rx.irq       := apbi.pwdata(ptrwidth-1 downto 0);

         -- general purpose input output data
         elsif apbi.paddr(8 downto 2)=cFifoDout then
            if    r.conf.DW="01" then
               -- 8 least significant bits unavailable
               v.fifoo.dout(dwidth-1 downto 8)  := apbi.pwdata(dwidth-1 downto 8);
            elsif r.conf.DW="00" then
               -- all bits available
               v.fifoo.dout(dwidth-1 downto 0)  := apbi.pwdata(dwidth-1 downto 0);
            end if;
         elsif apbi.paddr(8 downto 2)=cFifoDdir then
            if    r.conf.DW="01" then
               -- 8 least significant bits unavailable
               if oepol = 0 then
                  v.fifoo.den(dwidth-1 downto 8):= not apbi.pwdata(dwidth-1 downto 8);
               else
                  v.fifoo.den(dwidth-1 downto 8):=     apbi.pwdata(dwidth-1 downto 8);
               end if;
            elsif r.conf.DW="00" then
               -- all bits available
               if oepol = 0 then
                  v.fifoo.den(dwidth-1 downto 0):= not apbi.pwdata(dwidth-1 downto 0);
               else
                  v.fifoo.den(dwidth-1 downto 0):=     apbi.pwdata(dwidth-1 downto 0);
               end if;
            end if;

         -- interrupt registers
         elsif apbi.paddr(8 downto 2)=cFifoPIMSR and singleirq /= 0 then
         elsif apbi.paddr(8 downto 2)=cFifoPIMR and singleirq /= 0 then
         elsif apbi.paddr(8 downto 2)=cFifoPISR and singleirq /= 0 then
         elsif apbi.paddr(8 downto 2)=cFifoPIR and singleirq /= 0 then
            for i in NIRQEXT-1 downto 0 loop
               v.irq.pir(i)                  := v.irq.pir(i) or apbi.pwdata(i);
            end loop;
         elsif apbi.paddr(8 downto 2)=cFifoIMR and singleirq /= 0 then
               v.irq.imr(NIRQEXT-1 downto 0) := apbi.pwdata(NIRQEXT-1 downto 0);
         elsif apbi.paddr(8 downto 2)=cFifoPICR and singleirq /= 0 then
            for i in NIRQEXT-1 downto 0 loop
               if apbi.pwdata(i)='1' then
                  v.irq.pir(i)               := '0';
               end if;
            end loop;
         end if;
      end if;

      --======================================================================--
      -- Transmit Channel
      --------------------------------------------------------------------------
      -- TX STEP 1: tx channel dma request
      --------------------------------------------------------------------------
      if    r.tx.enable='1' and
            r.tx.dma_first_req='0' and r.tx.dma_second_req='0' then
         -- fetch
         if tx_request(r.tx, r.conf.DW) and r.fifo.full='0' then
            -- request a message fetch from any channel
            v.tx.dma_first_req   := '1';
            v.tx.dma_second_err  := '0';
            v.tx.txongoing       := '1';
         end if;
      elsif r.tx.enable='1' and
            r.tx.dma_first_req='1' and r.tx.dma_second_req='0' and
            r.tx.dma_second_err='0' then
         -- pre-fetch
         if tx_request2(r.tx, r.conf.DW) and r.fifo.full='0' then
            -- request a second message fetch from the same channel
            v.tx.dma_second_req  := '1';
            v.tx.txongoing       := '1';
         end if;
      elsif r.tx.enable='1' and
            r.tx.dma_first_req='0' and
            r.tx.dma_second_req='1' and r.tx.dma_second_rdy='1' then
         -- swap fetch and pre-fetch transmit message buffers
         v.tx.dma_first_req      := '1';
         v.tx.dma_first_rdy      := '1';
         v.tx.dma_second_req     := '0';
         v.tx.dma_second_rdy     := '0';
         v.tx.dma_second_err     := '0';
         v.tx.buff_rdaddr        :=     r.tx.buff_wraddr;
         v.tx.buff_wraddr        := not r.tx.buff_wraddr;
         v.tx.txongoing          := '1';
      elsif r.tx.enable='0' then
         -- remove all requests when disabled
         v.tx.dma_first_req      := '0';
         v.tx.dma_first_rdy      := '0';
         v.tx.dma_second_req     := '0';
         v.tx.dma_second_rdy     := '0';
         v.tx.dma_second_err     := '0';
         v.tx.txongoing          := '0';
      end if;

      --------------------------------------------------------------------------
      -- TX STEP 2: perform AHB fetch or prefetch (see below)
      --------------------------------------------------------------------------

      --------------------------------------------------------------------------
      -- TX STEP 3: tx channel fifo request
      --------------------------------------------------------------------------
      if r.tx.enable='1' and
         tx_request(r.tx, r.conf.DW) and r.fifo.full='0' and
         r.tx.dma_first_req='1' and r.tx.dma_first_rdy='1' then
         -- data available in circular buffer, fifo not full,
         -- DMA access completed with data
         t.fifo_tx.req           := '1';
         if (r.tx.rd(2 downto 0) = "111" and r.conf.DW="01") or
            (r.tx.rd(2 downto 0) = "110" and r.conf.DW="10") then
            t.fifo_tx.last       := '1';
         end if;

         if    r.conf.DW="01" then
            -- big-endianess
            if    r.tx.rd(2 downto 0) = "111" then
               t.fifo_tx.data(7 downto  0) := r.tx.buff(Conv_Integer(r.tx.buff_rdaddr))( 7 downto  0);
               t.fifo_tx.parity(0)         := parity(r.conf.parity, r.tx.buff(Conv_Integer(r.tx.buff_rdaddr))( 7 downto  0));
            elsif r.tx.rd(2 downto 0) = "110" then
               t.fifo_tx.data(7 downto  0) := r.tx.buff(Conv_Integer(r.tx.buff_rdaddr))(15 downto  8);
               t.fifo_tx.parity(0)         := parity(r.conf.parity, r.tx.buff(Conv_Integer(r.tx.buff_rdaddr))(15 downto  8));
            elsif r.tx.rd(2 downto 0) = "101" then
               t.fifo_tx.data(7 downto  0) := r.tx.buff(Conv_Integer(r.tx.buff_rdaddr))(23 downto 16);
               t.fifo_tx.parity(0)         := parity(r.conf.parity, r.tx.buff(Conv_Integer(r.tx.buff_rdaddr))(23 downto 16));
            elsif r.tx.rd(2 downto 0) = "100" then
               t.fifo_tx.data(7 downto  0) := r.tx.buff(Conv_Integer(r.tx.buff_rdaddr))(31 downto 24);
               t.fifo_tx.parity(0)         := parity(r.conf.parity, r.tx.buff(Conv_Integer(r.tx.buff_rdaddr))(31 downto 24));

            elsif r.tx.rd(2 downto 0) = "011" then
               t.fifo_tx.data(7 downto  0) := r.tx.buff(Conv_Integer(r.tx.buff_rdaddr))(39 downto 32);
               t.fifo_tx.parity(0)         := parity(r.conf.parity, r.tx.buff(Conv_Integer(r.tx.buff_rdaddr))(39 downto 32));
            elsif r.tx.rd(2 downto 0) = "010" then
               t.fifo_tx.data(7 downto  0) := r.tx.buff(Conv_Integer(r.tx.buff_rdaddr))(47 downto 40);
               t.fifo_tx.parity(0)         := parity(r.conf.parity, r.tx.buff(Conv_Integer(r.tx.buff_rdaddr))(47 downto 40));
            elsif r.tx.rd(2 downto 0) = "001" then
               t.fifo_tx.data(7 downto  0) := r.tx.buff(Conv_Integer(r.tx.buff_rdaddr))(55 downto 48);
               t.fifo_tx.parity(0)         := parity(r.conf.parity, r.tx.buff(Conv_Integer(r.tx.buff_rdaddr))(55 downto 48));
            else
               t.fifo_tx.data(7 downto  0) := r.tx.buff(Conv_Integer(r.tx.buff_rdaddr))(63 downto 56);
               t.fifo_tx.parity(0)         := parity(r.conf.parity, r.tx.buff(Conv_Integer(r.tx.buff_rdaddr))(63 downto 56));
            end if;

         elsif r.conf.DW="10" then
            -- big-endianess
            if    r.tx.rd(2 downto 1) = "11" then
               t.fifo_tx.data(15 downto 0) := r.tx.buff(Conv_Integer(r.tx.buff_rdaddr))(15 downto  0);
               t.fifo_tx.parity(1)         := parity(r.conf.parity, r.tx.buff(Conv_Integer(r.tx.buff_rdaddr))(15 downto  8));
               t.fifo_tx.parity(0)         := parity(r.conf.parity, r.tx.buff(Conv_Integer(r.tx.buff_rdaddr))( 7 downto  0));
            elsif r.tx.rd(2 downto 1) = "10" then
               t.fifo_tx.data(15 downto 0) := r.tx.buff(Conv_Integer(r.tx.buff_rdaddr))(31 downto 16);
               t.fifo_tx.parity(1)         := parity(r.conf.parity, r.tx.buff(Conv_Integer(r.tx.buff_rdaddr))(31 downto 16));
               t.fifo_tx.parity(0)         := parity(r.conf.parity, r.tx.buff(Conv_Integer(r.tx.buff_rdaddr))(15 downto  8));
            elsif r.tx.rd(2 downto 1) = "01" then
               t.fifo_tx.data(15 downto 0) := r.tx.buff(Conv_Integer(r.tx.buff_rdaddr))(47 downto 32);
               t.fifo_tx.parity(1)         := parity(r.conf.parity, r.tx.buff(Conv_Integer(r.tx.buff_rdaddr))(47 downto 40));
               t.fifo_tx.parity(0)         := parity(r.conf.parity, r.tx.buff(Conv_Integer(r.tx.buff_rdaddr))(39 downto 32));
            else
               t.fifo_tx.data(15 downto 0) := r.tx.buff(Conv_Integer(r.tx.buff_rdaddr))(63 downto 48);
               t.fifo_tx.parity(1)         := parity(r.conf.parity, r.tx.buff(Conv_Integer(r.tx.buff_rdaddr))(63 downto 56));
               t.fifo_tx.parity(0)         := parity(r.conf.parity, r.tx.buff(Conv_Integer(r.tx.buff_rdaddr))(55 downto 48));
            end if;
         end if;
      elsif r.tx.enable='0' then
         v.tx.txongoing          := '0';
         t.fifo_tx.req           := '0';
      else
         t.fifo_tx.req           := '0';
      end if;

      --------------------------------------------------------------------------
      -- TX STEP 4: fifo handler: write to fifo (see below)
      --------------------------------------------------------------------------

      --------------------------------------------------------------------------
      -- TX STEP 5: interrupts
      --------------------------------------------------------------------------
      -- delayed one clock period after fifo access complete, to improve timing
      if r.tx.eval='1' then
         v.tx.eval               := '0';
         -- interrupt pointer reached
         if tx_irq_match(r.tx, r.conf.DW) then
            v.tx.txirq           := '1';
            t.pirq(iTxIrq)       := '1';
         end if;

         -- circular buffer empty
         if not tx_request(r.tx, r.conf.DW) then
            v.tx.txempty         := '1';
            t.pirq(iTxEmpty)     := '1';
         end if;
      end if;

      --======================================================================--
      -- Receive Channel
      --------------------------------------------------------------------------
      -- RX STEP 1: rx channel request to FIFO read
      --------------------------------------------------------------------------

      --------------------------------------------------------------------------
      -- RX STEP 2: fifo handler: read from fifo (see below)
      --------------------------------------------------------------------------

      --------------------------------------------------------------------------
      -- RX STEP 3: rx channel fifo data sample, parity check
      --------------------------------------------------------------------------
      if r.fifo.sample_rx='1' then
         if    r.conf.DW="01" then
            -- big-endianess
            if    r.rx.buffptr="0001" then
               v.rx.buff(Conv_Integer(r.rx.buff_wraddr))(63 downto 56) := r.sync.first.din(7 downto 0);
            elsif r.rx.buffptr="0010" then
               v.rx.buff(Conv_Integer(r.rx.buff_wraddr))(55 downto 48) := r.sync.first.din(7 downto 0);
            elsif r.rx.buffptr="0011" then
               v.rx.buff(Conv_Integer(r.rx.buff_wraddr))(47 downto 40) := r.sync.first.din(7 downto 0);
            elsif r.rx.buffptr="0100" then
               v.rx.buff(Conv_Integer(r.rx.buff_wraddr))(39 downto 32) := r.sync.first.din(7 downto 0);
            elsif r.rx.buffptr="0101" then
               v.rx.buff(Conv_Integer(r.rx.buff_wraddr))(31 downto 24) := r.sync.first.din(7 downto 0);
            elsif r.rx.buffptr="0110" then
               v.rx.buff(Conv_Integer(r.rx.buff_wraddr))(23 downto 16) := r.sync.first.din(7 downto 0);
            elsif r.rx.buffptr="0111" then
               v.rx.buff(Conv_Integer(r.rx.buff_wraddr))(15 downto  8) := r.sync.first.din(7 downto 0);
            else
               v.rx.buff(Conv_Integer(r.rx.buff_wraddr))( 7 downto  0) := r.sync.first.din(7 downto 0);
            end if;
            if r.sync.first.pin(0) /= parity(r.conf.parity,r.sync.first.din(7 downto 0)) then
               v.rx.rxparity     := '1';
               t.pirq(iRxParity) := '1';
            end if;
         elsif r.conf.DW="10" then
            -- big-endianess
            if    r.rx.buffptr(3 downto 1)="001" then
               v.rx.buff(Conv_Integer(r.rx.buff_wraddr))(63 downto 48) := r.sync.first.din(15 downto 0);
            elsif r.rx.buffptr(3 downto 1)="010" then
               v.rx.buff(Conv_Integer(r.rx.buff_wraddr))(47 downto 32) := r.sync.first.din(15 downto 0);
            elsif r.rx.buffptr(3 downto 1)="011" then
               v.rx.buff(Conv_Integer(r.rx.buff_wraddr))(31 downto 16) := r.sync.first.din(15 downto 0);
            else
               v.rx.buff(Conv_Integer(r.rx.buff_wraddr))(15 downto  0) := r.sync.first.din(15 downto 0);
            end if;
            if r.sync.first.pin(0) /= parity(r.conf.parity,r.sync.first.din( 7 downto 0)) or
               r.sync.first.pin(1) /= parity(r.conf.parity,r.sync.first.din(15 downto 8)) then
               v.rx.rxparity     := '1';
               t.pirq(iRxParity) := '1';
            end if;
         end if;
      end if;

      --------------------------------------------------------------------------
      -- RX STEP 4: rx channel dma request
      --------------------------------------------------------------------------
      -- conditions to start data store over AHB:
      --
      -- complete word stored in buffer, and no ongoing AHB access:
      -- - switch buffers, reset buffptr, start access,
      -- - copy buff(rd) to dma data
      -- - increment by 4 on completion, or 4 - remembered buffptr value
      --
      -- incomplete word stored in buffer, and irq pointing to last byte, and
      -- fifo empty, and no ongoing AHB access:
      -- - copy buffer rdptr to wrptr
      -- - remember buffptr for this and next access
      -- - copy buff(rd) to dma data
      -- - start access
      -- - increment by buffptr on completion

      if    r.rx.enable='1' and rx_available(r.rx, r.conf.DW) and
            r.rx.dma_first_req='0' then
         -- ready for AHB store access
         if    (r.rx.buffptr(3 downto 0)="1000" and r.conf.DW="01") or
               (r.rx.buffptr(3 downto 1)="100"  and r.conf.DW="10") then
            -- buffer word completed

            -- swap buffers
            v.rx.buff_rdaddr     :=     r.rx.buff_wraddr;
            v.rx.buff_wraddr     := not r.rx.buff_wraddr;

            v.rx.dma_inc         := "1000";
            v.rx.buffptr         := "0000";

            -- request a message store
            v.rx.dma_first_req   := '1';

         elsif ((r.rx.buffptr(3 downto 0)/="0000" and r.conf.DW="01") or
                (r.rx.buffptr(3 downto 1)/="000"  and r.conf.DW="10")) and
               rx_irq_partial_match(r.rx, r.conf.DW) then
            -- buffer word incomplete, but matching irq pointer,
            -- copy buffer pointers
            v.rx.buff_rdaddr     := r.rx.buff_wraddr;

            -- calculate increment
            v.rx.dma_inc         := r.rx.buffptr;

            -- request a message store
            v.rx.dma_first_req   := '1';
         end if;
      elsif r.rx.enable='0' then
         v.rx.rxongoing          := '0';
      end if;

      --------------------------------------------------------------------------
      -- RX STEP 5: perform AHB store, evalute results (see below)
      --------------------------------------------------------------------------

      --------------------------------------------------------------------------
      -- RX STEP 6: rx channel dma access completed
      --------------------------------------------------------------------------
      if r.rx.dma_first_req='1' and r.rx.dma_first_rdy='1' then
         -- increment pointer with the number of relevant bytes written
         if    r.rx.dma_inc="1000" then
            -- when doubleword group is completed, the ptr is incremented by 8
            v.rx.wr              := inc_double_wr(r.rx);
         else
            -- with bytes in the same doubleword group, only ptr lsb are copied
            v.rx.wr              := r.rx.wr(ptrwidth-1 downto 3) &
                                    r.rx.dma_inc(2 downto 0);
         end if;

         -- remove request
         v.rx.dma_first_req      := '0';
         v.rx.dma_first_rdy      := '0';

         -- evaluate pointers in next clock period
         v.rx.eval               := '1';
      end if;

      --------------------------------------------------------------------------
      -- RX STEP 7: rx channel interrupts
      --------------------------------------------------------------------------
      -- delayed one clock period after dma access complete, to improve timing
      -- interrupt generation, etc.
      if r.rx.eval='1' then
         v.rx.rxongoing             := '0';
         v.rx.eval                  := '0';

         -- interrupt pointer reached: either exactly or when a complete
         -- word is stored (not partial word, since interrupt already issued)
         if rx_irq_match(r.rx, r.conf.DW) then
            v.rx.rxirq              := '1';
            t.pirq(iRxIrq)          := '1';
         end if;

         -- circular reception buffer full
         if not rx_available(r.rx, r.conf.DW) then
            v.rx.rxfull             := '1';
            t.pirq(iRxFull)         := '1';
         end if;
      end if;

      --======================================================================--
      -- DMA handler and priority handling
      --------------------------------------------------------------------------
      -- TX STEP 2: perform AHB fetch or prefetch access, evaluate results
      --------------------------------------------------------------------------
      -- RX STEP 5: perform AHB store, evalute results
      --------------------------------------------------------------------------
      if    r.ahb.pause='1' then
         -- idle cycle to allow DMA to recover
         v.ahb.pause       := '0';
         if r.dmai.Store='1' then
            v.rx.rxongoing :='1';
         else
            v.tx.txongoing :='1';
         end if;
      elsif r.ahb.restart='1' then
         -- restart access
         v.dmai.Request    := '1';
         v.ahb.restart     := '0';
         v.dmai.Beat       := HINCR;
         v.dmai.Burst      := r.ahb.firstburst;
         v.ahb.firstgrant  := r.ahb.firstburst;
         if r.dmai.Store='1' then
            v.rx.rxongoing :='1';
         else
            v.tx.txongoing :='1';
         end if;
      elsif r.ahb.busy='0' and
            r.rx.dma_first_req='1' and r.rx.dma_first_rdy='0' and
            ((r.ahb.sel_tx='0') or (r.tx.enable='0') or
             (r.ahb.sel_tx='1' and r.tx.dma_first_req='0' and
                                   r.tx.dma_second_req='0')) then
         -- start store access / receive
         v.ahb.sel_tx      := '0';
         v.dmai.Request    := '1';
         v.dmai.Burst      := '1';
         v.dmai.Beat       := HINCR;
         v.dmai.Store      := '1';
         v.ahb.busy        := '1';
         v.ahb.firstburst  := '1';
         v.ahb.firstgrant  := '1';
         v.dmai.Data       := r.rx.buff(Conv_Integer(r.rx.buff_rdaddr))(63 downto 32);
         v.dmai.Address    := (r.rx.addr & "0000000000") +
                              (r.rx.wr(ptrwidth-1 downto 3) & "000");
         v.rx.rxongoing    := '1';
      elsif r.tx.enable='1' and
            r.ahb.busy='0' and (r.tx.txerror='0' or r.conf.ABORT='0') and
            r.tx.dma_first_req='1' and r.tx.dma_first_rdy='0' and
            ((r.ahb.sel_tx='1') or (r.rx.enable='0') or
             (r.ahb.sel_tx='0' and r.rx.dma_first_req='0')) then
         -- start fetch access / transmit
         v.ahb.sel_tx      := '1';
         v.dmai.Request    := '1';
         v.dmai.Burst      := '1';
         v.dmai.Beat       := HINCR;
         v.dmai.Store      := '0';
         v.ahb.busy        := '1';
         v.ahb.second      := '0';
         v.ahb.firstburst  := '1';
         v.ahb.firstgrant  := '1';
         v.dmai.Address    := (r.tx.addr & "0000000000") +
                              (r.tx.rd(ptrwidth-1 downto 3) & "000");
         v.tx.txongoing    :='1';
      elsif r.tx.enable='1' and
            r.ahb.busy='0' and (r.tx.txerror='0' or r.conf.ABORT='0') and
            r.tx.dma_second_req='1' and r.tx.dma_second_rdy='0' and
            r.tx.dma_second_err='0' and
            ((r.ahb.sel_tx='1') or (r.rx.enable='0') or
             (r.ahb.sel_tx='0' and r.rx.dma_first_req='0')) then
         -- start prefetch access / transmit
         v.ahb.sel_tx      := '1';
         v.dmai.Request    := '1';
         v.dmai.Burst      := '1';
         v.dmai.Beat       := HINCR;
         v.dmai.Store      := '0';
         v.ahb.busy        := '1';
         v.ahb.second      := '1';
         v.ahb.firstburst  := '1';
         v.ahb.firstgrant  := '1';
         v.dmai.Address    := (r.tx.addr & "0000000000") +
                              (inc_double_rd(r.tx) & "000");
         v.tx.txongoing    :='1';
      elsif r.ahb.busy='1' then
         if r.dmai.Store='1' then
            v.rx.rxongoing :='1';
         else
            v.tx.txongoing :='1';
         end if;

         if dmao.Grant='1' then                          -- remove requests
            if r.ahb.firstgrant='1' then
               v.ahb.firstgrant  := '0';
            else
               v.dmai.Request    := '0';
               v.dmai.Burst      := '0';
            end if;
         end if;

         -- access handling
         if    dmao.Ready='1' and r.dmai.Store='0' and r.ahb.firstburst='1' then
            -- transmit/read access handling
            -- store data in right position after first access
            v.ahb.firstburst := '0';
            v.tx.buff(Conv_Integer(r.tx.buff_wraddr))(63 downto 32) := dmao.Data;

         elsif dmao.Ready='1' and r.dmai.Store='0' then
            -- transmit/read access handling
            -- store data in right position after second access
            v.tx.buff(Conv_Integer(r.tx.buff_wraddr))(31 downto  0) := dmao.Data;

            -- access completed
            v.ahb.busy                 := '0';
            if r.ahb.second='1' then
               v.tx.dma_second_rdy     := '1';
               v.ahb.second            := '0';
            else
               v.tx.dma_first_rdy      := '1';
               v.tx.buff_rdaddr        :=     r.tx.buff_wraddr;
               v.tx.buff_wraddr        := not r.tx.buff_wraddr;
            end if;
            v.ahb.sel_tx               := '0';

         elsif dmao.OKAY='1' and r.dmai.Store='1' and r.ahb.firstburst='1' then
            -- receive/write access handling
            -- first store completed
            v.dmai.Data                := r.rx.buff(Conv_Integer(r.rx.buff_rdaddr))(31 downto  0);
            v.ahb.firstburst           := '0';
         elsif dmao.OKAY='1' and r.dmai.Store='1' and v.ahb.firstburst='0' then
            -- receive/write access handling
            -- second store completed
            -- access completed
            v.ahb.busy                 := '0';
            v.rx.dma_first_rdy         := '1';
            v.ahb.sel_tx               := '1';
         end if;

         -- retry/error response handling
         if dmao.Fault='1' and r.conf.ABORT='0' then
            if r.dmai.Store='1' then
               -- store access
               -- generate interrupt
               v.rx.rxerror         := '1';
               t.pirq(iRxError)     := '1';
               -- restart access
               v.ahb.pause          := '1';
               v.ahb.restart        := '1';
               v.dmai.Request       := '0';
               v.dmai.Burst         := '0';
            elsif r.ahb.second='0' then
               -- fetch access (not pre-fetch)
               -- generate interrupt
               v.tx.txerror         := '1';
               t.pirq(iTxError)     := '1';
               -- restart access
               v.ahb.pause          := '1';
               v.ahb.restart        := '1';
               v.dmai.Request       := '0';
               v.dmai.Burst         := '0';
            elsif r.ahb.second='1' then
               -- pre-fetch access
               -- abort access
               v.ahb.pause          := '1';
               v.dmai.Request       := '0';
               v.dmai.Burst         := '0';
               v.ahb.busy           := '0';
               v.ahb.second         := '0';
               -- stop pre-fetch
               v.tx.dma_second_req  := '0';
               v.tx.dma_second_rdy  := '0';
               v.tx.dma_second_err  := '1';
            end if;

         elsif dmao.Fault='1' and r.conf.ABORT='1' then
            if r.dmai.Store='1' then
               -- store access
               -- generate interrupt
               v.rx.rxerror         := '1';
               t.pirq(iRxError)     := '1';
               -- abort access
               v.ahb.pause          := '1';
               v.dmai.Request       := '0';
               v.dmai.Burst         := '0';
               v.ahb.busy           := '0';
               v.ahb.firstburst     := '0';
               -- disable affected channel immediately
               v.rx.enable          := '0';
               v.rx.dma_first_req   := '0';
               v.rx.dma_first_rdy   := '0';
               v.rx.dma_inc         := "0000";
               v.rx.rxongoing       := '0';
            elsif r.ahb.second='0' then
               -- fetch access (not pre-fetch)
               -- generate interrupt
               v.tx.txerror         := '1';
               t.pirq(iTxError)     := '1';
               -- abort access
               v.ahb.pause          := '1';
               v.dmai.Request       := '0';
               v.dmai.Burst         := '0';
               v.ahb.busy           := '0';
               v.ahb.firstburst     := '0';
               -- disable affected channel immediately
               v.tx.txongoing       := '0';
               v.tx.enable          := '0';
               v.tx.dma_first_req   := '0';
               v.tx.dma_first_rdy   := '0';
               v.tx.dma_second_req  := '0';
               v.tx.dma_second_rdy  := '0';
               v.tx.dma_second_err  := '0';

            elsif r.ahb.second='1' then
               -- pre-fetch access
               -- abort access
               v.ahb.pause          := '1';
               v.dmai.Request       := '0';
               v.dmai.Burst         := '0';
               v.ahb.busy           := '0';
               v.ahb.second         := '0';
               v.ahb.firstburst     := '0';
               -- stop pre-fetch
               v.tx.dma_second_req  := '0';
               v.tx.dma_second_rdy  := '0';
               v.tx.dma_second_err  := '1';
            end if;
         end if;
      end if;


      --------------------------------------------------------------------------
      -- RX STEP 1: rx channel request to FIFO read
      --------------------------------------------------------------------------
      if v.rx.buffptr < "1000" and                       -- dword incomplete
         r.rx.enable='1' then                            -- enabled
         -- word in buffer incomplete
         if r.fifo.empty='0' and (r.conf.DW="01" or r.conf.DW="10") then
            -- fifo not empty
            t.fifo_rx.req        := '1';
            if (r.rx.buffptr(3 downto 0)="0111" and r.conf.DW="01") or
               (r.rx.buffptr(3 downto 1)="011"  and r.conf.DW="10") then
               t.fifo_rx.last    := '1';
            end if;
         end if;
      end if;

      --======================================================================--
      -- FIFO handler and priority handling
      --------------------------------------------------------------------------
      -- TX STEP 4: write to fifo
      --------------------------------------------------------------------------
      -- RX STEP 2: read from fifo
      --------------------------------------------------------------------------
      case r.fifo.state is
         when sIdle =>
            -- arbitration
            -- only override arbitration after last byte access
            -- only start new type of access after additional idle cycle
            if    (r.tx.enable='1') and
                  (v.tx.txerror='0' or r.conf.ABORT='0') and
                  (t.fifo_tx.req='1') and (r.fifo.last_rx='0') and
                  ((r.fifo.sel_tx='1') or (r.rx.enable='0') or
                   (r.fifo.sel_tx='0' and t.fifo_rx.req='0')) then
               t.fifo_tx.req                    := '1';
               t.fifo_rx.req                    := '0';
               v.fifo.sel_tx                    := '1';
            elsif (r.rx.enable='1') and
                  (t.fifo_rx.req='1') and (r.fifo.last_tx='0') and
                  ((r.fifo.sel_tx='0') or (r.tx.enable='0') or
                   (r.fifo.sel_tx='1' and t.fifo_tx.req='0')) then
               t.fifo_tx.req                    := '0';
               t.fifo_rx.req                    := '1';
               v.fifo.sel_tx                    := '0';
            else
               -- no requests, or
               -- insert additional idle cycle between different access types
               t.fifo_tx.req                    := '0';
               t.fifo_rx.req                    := '0';
            end if;
            -- clear status information after first arbitration
            v.fifo.last_tx                      := '0';
            v.fifo.last_rx                      := '0';

            -- start access
            if    t.fifo_tx.req='1' then
               v.fifo.state                     := sWrite;
               v.fifo.ws                        := r.conf.WS;
               v.fifoo.WEn                      := '0';
               v.fifoo.REn                      := '1';
               v.tx.txongoing                   := '1';
               -- drive only used output data
               if    r.conf.DW="01" then
                  v.fifoo.dout(8-1 downto 0)    := t.fifo_tx.data(8-1 downto 0);
                  v.fifoo.pout(0)               := parity(r.conf.parity, t.fifo_tx.data(8-1 downto 0));
               elsif r.conf.DW="10" then
                  v.fifoo.dout(16-1 downto 0)   := t.fifo_tx.data(16-1 downto 0);
                  v.fifoo.pout(0)               := parity(r.conf.parity, t.fifo_tx.data( 8-1 downto 0));
                  v.fifoo.pout(1)               := parity(r.conf.parity, t.fifo_tx.data(16-1 downto 8));
               end if;
               -- drive only used output data buffers
               if    r.conf.DW="01" then
                  if oepol = 0 then
                     v.fifoo.den(8-1 downto 0)  := (others => '0');
                     v.fifoo.pen                := (others => '0');
                  else
                     v.fifoo.den(8-1 downto 0)  := (others => '1');
                     v.fifoo.pen                := (others => '1');
                  end if;
               elsif r.conf.DW="10" then
                  if oepol = 0 then
                     v.fifoo.den(16-1 downto 0) := (others => '0');
                     v.fifoo.pen                := (others => '0');
                  else
                     v.fifoo.den(16-1 downto 0) := (others => '1');
                     v.fifoo.pen                := (others => '1');
                  end if;
               end if;
            elsif t.fifo_rx.req='1' then
               v.fifo.state                     := sRead;
               v.fifo.ws                        := r.conf.WS;
               v.fifoo.WEn                      := '1';
               v.fifoo.REn                      := '0';
               v.rx.rxongoing                   := '1';
               -- un-drive only used output data buffers
               if    r.conf.DW="01" then
                  if oepol = 0 then
                     v.fifoo.den(8-1 downto 0)  := (others => '1');
                     v.fifoo.pen                := (others => '1');
                  else
                     v.fifoo.den(8-1 downto 0)  := (others => '0');
                     v.fifoo.pen                := (others => '0');
                  end if;
               elsif r.conf.DW="10" then
                  if oepol = 0 then
                     v.fifoo.den(16-1 downto 0) := (others => '1');
                     v.fifoo.pen                := (others => '1');
                  else
                     v.fifoo.den(16-1 downto 0) := (others => '0');
                     v.fifoo.pen                := (others => '0');
                  end if;
               end if;
            else
               v.fifoo.WEn                      := '1';
               v.fifoo.REn                      := '1';
               -- clear only all used enables
               if    r.conf.DW="01" then
                  if oepol = 0 then
                     v.fifoo.den(8-1 downto 0)  := (others => '1');
                     v.fifoo.pen                := (others => '1');
                  else
                     v.fifoo.den(8-1 downto 0)  := (others => '0');
                     v.fifoo.pen                := (others => '0');
                  end if;
               elsif r.conf.DW="10" then
                  if oepol = 0 then
                     v.fifoo.den(16-1 downto 0) := (others => '1');
                     v.fifoo.pen                := (others => '1');
                  else
                     v.fifoo.den(16-1 downto 0) := (others => '0');
                     v.fifoo.pen                := (others => '0');
                  end if;
               end if;
            end if;
            v.fifo.sample_rx                    := '0';

         when sRead | sWrite =>
            if r.fifo.ws=Zero then
               v.fifoo.WEn                      := '1';
               v.fifoo.REn                      := '1';
               if r.fifo.state=sRead then
                  -- signal ready
                  v.fifo.last_rx                := '1';

                  -- increment local buffer pointer
                  if r.conf.DW="01" then
                     v.rx.buffptr(3 downto 0)   := r.rx.buffptr(3 downto 0) + "0001";
                  else
                     v.rx.buffptr(3 downto 1)   := r.rx.buffptr(3 downto 1) + "001";
                  end if;

                  -- arbitration lost on word boundary
                  if t.fifo_rx.last='1' then
                     v.fifo.sel_tx              := '1';
                  end if;

                  -- route data to buffer in next cycle, taking the fifoi.din
                  -- data directly in next cycle (sampled this cycle)
                  v.fifo.sample_rx              := '1';

                  -- sample fifo status
                  v.fifo.empty                  := not fifoi.EFn;
                  v.sync.second.EFn             :=     fifoi.EFn;
                  v.sync.third.EFn              :=     fifoi.EFn;

               else
                  -- increment tx channel read pointer on completed transfer
                  v.tx.rd                       := inc_rd(r.tx, r.conf.DW);

                  -- evaluate pointers in the next clock period
                  v.tx.eval                     := '1';

                  if r.tx.enable='1' and
                     (t.fifo_tx.last='1' or tx_last(v.tx, r.tx, r.conf.DW)) then
                     -- arbitration lost on word boundary
                     v.fifo.sel_tx              := '0';

                     if    r.tx.dma_first_rdy='1' and
                           v.tx.dma_second_rdy='0' then
                        -- clear fetch message buffer
                        v.tx.dma_first_req      := '0';
                        v.tx.dma_first_rdy      := '0';
                        v.tx.txongoing          := '0';
                        if r.tx.dma_second_req='1' then
                           -- swap fetch and pre-fetch transmit message buffers
                           v.tx.dma_first_req   := '1';
                           v.tx.dma_first_rdy   := '0';
                           v.tx.dma_second_req  := '0';
                           v.tx.dma_second_rdy  := '0';
                           v.tx.buff_rdaddr     :=     r.tx.buff_wraddr;
                           v.tx.txongoing       := '1';
                           v.ahb.second         := '0';
                        end if;
                     elsif r.tx.dma_first_rdy='1' and
                           v.tx.dma_second_rdy='1' then
                        -- swap fetch and pre-fetch transmit message buffers
                        v.tx.dma_first_req      := '1';
                        v.tx.dma_first_rdy      := '1';
                        v.tx.dma_second_req     := '0';
                        v.tx.dma_second_rdy     := '0';
                        v.tx.buff_rdaddr        :=     r.tx.buff_wraddr;
                        v.tx.buff_wraddr        := not r.tx.buff_wraddr;
                        v.tx.txongoing          := '1';
                     end if;
                  elsif r.tx.enable='0' then
                     -- channel disabled
                     v.tx.dma_first_req         := '0';
                     v.tx.dma_first_rdy         := '0';
                     v.tx.dma_second_req        := '0';
                     v.tx.dma_second_rdy        := '0';
                     v.tx.txongoing             := '0';
                     v.fifo.sel_tx              := '0';
                  end if;
                  v.fifo.last_tx                := '1';

                  -- sample fifo status
                  v.fifo.full                   := not fifoi.FFn;
                  v.sync.second.FFn             :=     fifoi.FFn;
                  v.sync.third.FFn              :=     fifoi.FFn;
               end if;

               -- add gap if long wait states
               if r.conf.WS >= WSLarge then
                  v.fifo.state                  := sGap;
               else
                  v.fifo.state                  := sIdle;
               end if;
            else
               v.fifo.ws                        := r.fifo.ws-1;
               if r.fifo.state=sRead then
                  v.rx.rxongoing                :='1';
               else
                  v.tx.txongoing                :='1';
               end if;
            end if;

         when others =>                                  -- sGap
            -- add gap after long wait states
            v.fifoo.WEn                         := '1';
            v.fifoo.REn                         := '1';
            v.fifo.state                        := sIdle;
            v.fifo.sample_rx                    := '0';
      end case;

      --======================================================================--
      -- Interrupt handling
      --------------------------------------------------------------------------
      if singleirq /= 0 then                             -- single irq output
         for i in 0 to NIRQEXT-1 loop
            if t.pirq(i)='1' then
               v.irq.pir(i) := '1';
            end if;
         end loop;
      end if;

      --======================================================================--
      -- Synchronous reset operation
      --------------------------------------------------------------------------
      if rstn = '0' or r.ctrl.RESET = '1' then
         v.conf.ABORT            := '0';
         v.conf.DW               := (others => '0');
         v.conf.PARITY           := '0';
         v.conf.WS               := (others => '0');

         v.ctrl.RESET            := '0';

         if singleirq /= 0 then
            v.irq.pir            := (others => '0');
            v.irq.imr            := (others => '0');
         end if;

         v.tx.enable             := '0';
         v.tx.txongoing          := '0';
         v.tx.txirq              := '0';
         v.tx.txempty            := '0';
         v.tx.txerror            := '0';
         v.tx.addr               := (others => '0');
         v.tx.size               := (others => '0');
         v.tx.wr                 := (others => '0');
         v.tx.rd                 := (others => '0');
         v.tx.irq                := (others => '0');
         v.tx.buff_rdaddr        := '0';
         v.tx.buff_wraddr        := '0';
         v.tx.buff               := (others => (others => '0'));
         v.tx.eval               := '0';
         v.tx.dma_first_req      := '0';
         v.tx.dma_first_rdy      := '0';
         v.tx.dma_second_req     := '0';
         v.tx.dma_second_rdy     := '0';
         v.tx.dma_second_err     := '0';
         v.fifo.last_tx          := '0';
         v.fifo.full             := '1';

         v.rx.enable             := '0';
         v.rx.rxongoing          := '0';
         v.rx.rxparity           := '0';
         v.rx.rxirq              := '0';
         v.rx.rxfull             := '0';
         v.rx.rxerror            := '0';
         v.rx.addr               := (others => '0');
         v.rx.size               := (others => '0');
         v.rx.wr                 := (others => '0');
         v.rx.rd                 := (others => '0');
         v.rx.irq                := (others => '0');
         v.rx.buff_rdaddr        := '0';
         v.rx.buff_wraddr        := '0';
         v.rx.buff               := (others => (others => '0'));
         v.rx.buffptr            := (others => '0');
         v.rx.eval               := '0';
         v.rx.dma_first_req      := '0';
         v.rx.dma_first_rdy      := '0';
         v.rx.dma_inc            := (others => '0');
         v.fifo.last_rx          := '0';
         v.fifo.sample_rx        := '0';
         v.fifo.empty            := '1';

         v.fifoo.WEn             := '1';
         v.fifoo.REn             := '1';
         v.fifoo.Dout            := (others => '0');
         v.fifoo.Pout            := (others => '0');

         if oepol=0 then
            v.fifoo.Den          := (others => '1');
            v.fifoo.Pen          := (others => '1');
         else
            v.fifoo.Den          := (others => '0');
            v.fifoo.Pen          := (others => '0');
         end if;

         v.sync.first.Din        := (others => '0');
         v.sync.first.Pin        := (others => '0');
         v.sync.first.EFn        := '0';
         v.sync.first.FFn        := '0';
         v.sync.first.HFn        := '0';
         v.sync.second.Din       := (others => '0');
         v.sync.second.Pin       := (others => '0');
         v.sync.second.EFn       := '0';
         v.sync.second.FFn       := '0';
         v.sync.second.HFn       := '0';
         v.sync.third.Din        := (others => '0');
         v.sync.third.Pin        := (others => '0');
         v.sync.third.EFn        := '0';
         v.sync.third.FFn        := '0';
         v.sync.third.HFn        := '0';

         v.sync.grant            := '0';

         v.fifo.state            := sIdle;
         v.fifo.ws               := (others => '0');
         v.fifo.sel_tx           := '0';
         v.fifo.last_tx          := '0';
         v.fifo.last_rx          := '0';
         v.fifo.sample_rx        := '0';
         v.fifo.empty            := '1';
         v.fifo.full             := '1';

         v.ahb.sel_tx            := '0';
         v.ahb.busy              := '0';
         v.ahb.restart           := '0';
         v.ahb.pause             := '0';
         v.ahb.second            := '0';
         v.ahb.firstburst        := '0';
         v.ahb.firstgrant        := '0';

         v.dmai.Reset            := '0';
         v.dmai.Request          := '0';
         v.dmai.Burst            := '0';
         v.dmai.Beat             := (others => '0');
         v.dmai.Store            := '0';
         v.dmai.Data             := (others => '0');
         v.dmai.Address          := (others => '0');
         v.dmai.Size             := HSIZE32;
         v.dmai.Lock             := '0';
      end if;

      --------------------------------------------------------------------------
      -- variable to signal assigment
      rin               <= v;
      apbo.prdata       <= t.prdata;                     -- drive apb read bus

      --------------------------------------------------------------------------
      -- amba apb interrupt output
      --------------------------------------------------------------------------
      if pirq = 0 then                                   -- interrupt mapping
         apbo.pirq      <= (others => '0');
      elsif singleirq = 0 then                           -- multiple irq outputs
         apbo.pirq      <= (others => '0');
         for i in 0 to NIRQEXT-1 loop
            if (pirq+i) < NAHBIRQ then
               apbo.pirq(pirq+i) <= t.pirq(i);
            end if;
         end loop;
      elsif singleirq /= 0 then                          -- single irq output
         t.tmp := '0';
         for i in 0 to NIRQEXT-1 loop
            t.tmp := (r.irq.pir(i) and r.irq.imr(i)) or t.tmp;
         end loop;

         apbo.pirq   <= (others => '0');
         if pirq < NAHBIRQ then
            apbo.pirq(pirq) <= t.tmp;
         end if;
      end if;
   end process comb;

   -----------------------------------------------------------------------------
   -- configuration assigment
   -----------------------------------------------------------------------------
   apbo.pindex          <= pindex;
   apbo.pconfig         <= pconfig;

   -----------------------------------------------------------------------------
   -- registers
   -----------------------------------------------------------------------------
   regs: process(clk)
   begin
      if Rising_Edge(clk) then
         r              <= rin;
      end if;
   end process regs;

   -----------------------------------------------------------------------------
   -- output ports
   -----------------------------------------------------------------------------
   FIFOO.Dout(dwidth-1 downto 0) <= r.fifoo.Dout(dwidth-1 downto 0);
   FIFOO.Den(dwidth-1 downto 0)  <= r.fifoo.Den(dwidth-1 downto 0);
   FIFOO.Pout                    <= r.fifoo.Pout;
   FIFOO.Pen                     <= r.fifoo.Pen;
   FIFOO.WEn                     <= r.fifoo.WEn;
   FIFOO.REn                     <= r.fifoo.REn;

   -----------------------------------------------------------------------------
   -- component instances
   -----------------------------------------------------------------------------
   DMA2AHB0: DMA2AHB
      generic map(
         hindex            => hindex,
         vendorid          => 16#01#,
         deviceid          => 16#035#,
         version           => REVISION,
         boundary          => 0)
      port map(
         HCLK              => clk,
         HRESETn           => rstn,
         DMAIn             => r.dmai,
         DMAOut            => dmao,
         AHBIn             => ahbi,
         AHBOut            => ahbo);

   -----------------------------------------------------------------------------
   -- boot message
   -----------------------------------------------------------------------------
-- pragma translate_off
   bootmsg : report_version
      generic map(
         "grfifo" & tost(pindex) & ": " &
         "GR FIFO Interface Unit rev " & tost(REVISION) & ", " &
         tost(dwidth) & "-bit data, " &
         "irq " & tost(pirq) & " to " & tost(pirq+(NIRQEXT-1)*(1-singleirq)));
-- pragma translate_on

-- pragma translate_off
   assert dwidth=16
      report "grfifo: dwidth not equal to 16 bits"
      severity Error;
-- pragma translate_on
end architecture rtl; --======================================================--

