------------------------------------------------------------------------------
--  This file is a part of the GRLIB VHDL IP LIBRARY
--  Copyright (C) 2017, Cobham Gaisler AB - all rights reserved.
--
-- ANY USE OR REDISTRIBUTION IN PART OR IN WHOLE MUST BE HANDLED IN 
-- ACCORDANCE WITH THE GAISLER LICENSE AGREEMENT AND MUST BE APPROVED 
-- IN ADVANCE IN WRITING. 
--============================================================================--
-- Design unit  : ADC/DAC Interface (Entity & architecture declarations)
--
-- File name    : gradcdac.vhd
--
-- Library      : gaisler
--
-- Authors      : Aeroflex Gaisler AB
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

library  grlib;
use      grlib.amba.all;
use      grlib.stdlib.all;

library  gaisler;
use      gaisler.misc.all;

--pragma translate_off
use      Std.TextIO.all;
--pragma translate_on

entity gradcdac is
   generic (
      pindex:           Integer := 0;
      paddr:            Integer := 0;
      pmask:            Integer := 16#FFF#;
      pirq:             Integer := 1;                    -- index of first irq
      awidth:           Integer := 8;                    -- address width
      dwidth:           Integer := 16;                   -- data width
      oepol:            Integer := 1);                   -- output enable polarity
   port (
      rstn:       in    Std_ULogic;
      clk:        in    Std_ULogic;
      apbi:       in    APB_Slv_In_Type;
      apbo:       out   APB_Slv_Out_Type;
      adi:        in    Analog_In_Type;
      ado:        out   Analog_Out_Type);
end entity gradcdac;

architecture rtl of gradcdac is
   -----------------------------------------------------------------------------
   -- addressing constants
   -----------------------------------------------------------------------------
   --                                         765432     -- address bit numbers
   constant cADCONF:    Std_Logic_Vector :=  "000000";   -- global registers
   constant cADSTAT:    Std_Logic_Vector :=  "000001";

   constant cADIN:      Std_Logic_Vector :=  "000100";   -- adc input
   constant cADOUT:     Std_Logic_Vector :=  "000101";   -- dac output

   constant cADAIN:     Std_Logic_Vector :=  "001000";   -- general purpose addr
   constant cADAOUT:    Std_Logic_Vector :=  "001001";
   constant cADADIR:    Std_Logic_Vector :=  "001010";

   constant cADDIN:     Std_Logic_Vector :=  "001100";   -- general purpose data
   constant cADDOUT:    Std_Logic_Vector :=  "001101";
   constant cADDDIR:    Std_Logic_Vector :=  "001110";

   -----------------------------------------------------------------------------
   -- interrupt controller constants
   -----------------------------------------------------------------------------
   constant NIRQEXT:    Integer := 2;                    -- number of interrupts

   -----------------------------------------------------------------------------
   -- configuration constants
   -----------------------------------------------------------------------------
   constant REVISION:   Integer := 0;

   constant pconfig:    apb_config_type := (
      0 => ahb_device_reg (16#01#, 16#036#, 0, REVISION, pirq),
      1 => apb_iobar(paddr, pmask));

   -----------------------------------------------------------------------------
   -- synchronization
   -----------------------------------------------------------------------------
   type sync_type is record
      first:            Analog_In_Type;
      second:           Analog_In_Type;
      third:            Analog_In_Type;
   end record;

   -----------------------------------------------------------------------------
   -- configuration register
   -----------------------------------------------------------------------------
   type conf_type is record
      DACWS:            Std_Logic_Vector(4 downto 0);    -- Number of DAC wait states, 0 to 31 [5 bits]
      WRPOL:            Std_ULogic;                      -- Polarity of DAC write strobe:
                                                         --     0b = active low
                                                         --     1b = active high
      DACDW:            Std_Logic_Vector(1 downto 0);    -- DAC data width
                                                         --    00b = none
                                                         --    01b =  8 bit ADO.Dout[ 7:0]
                                                         --    10b = 16 bit ADO.Dout[15:0]
                                                         --    11b = none/spare
      ADCWS:            Std_Logic_Vector(4 downto 0);    -- Number of ADC wait states, 0 to 31 [5 bits]
      RCPOL:            Std_ULogic;                      -- Polarity of ADC read convert:
                                                         --     0b = active low read
                                                         --     1b = active high read
      CSMODE:           Std_Logic_Vector(1 downto 0);    -- Mode of ADC chip select:
                                                         --    00b = asserted during conversion and read phases
                                                         --    01b = asserted during conversion phase
                                                         --    10b = asserted during read phase
                                                         --    11b = asserted continuously during both phases
      CSPOL:            Std_ULogic;                      -- Polarity of ADC chip select:
                                                         --     0b = active low
                                                         --     1b = active high
      RDYMODE:          Std_ULogic;                      -- Mode of ADC ready:
                                                         --     0b = unused, i.e. open-loop
                                                         --     1b = used, with time-out
      RDYPOL:           Std_ULogic;                      -- Polarity of ADC ready:
                                                         --     0b = falling edge
                                                         --     1b = rising edge
      TRIGPOL:          Std_ULogic;                      -- Polarity of ADC triggers:
                                                         --    0b = falling edge
                                                         --    1b = rising edge
      TRIGMODE:         Std_Logic_Vector(1 downto 0);    -- ADC trigger source:
                                                         --    00b = none
                                                         --    01b = ADI.TRIG[0]
                                                         --    10b = ADI.TRIG[1]
                                                         --    11b = ADI.TRIG[2]
      ADCDW:            Std_Logic_Vector(1 downto 0);    -- ADC data width
                                                         --    00b = none
                                                         --    01b =  8 bit ADI.Din[ 7:0]
                                                         --    10b = 16 bit ADI.Din[15:0]
                                                         --    11b = none/spare
   end record;

   -----------------------------------------------------------------------------
   -- status register
   -----------------------------------------------------------------------------
   type stat_type is record
      DACNO:            Std_ULogic;                      -- DA cnv rejected
      DACRDY:           Std_ULogic;                      -- DA cnv completed
      DACON:            Std_ULogic;                      -- DA cnv ongoing
      ADCTO:            Std_ULogic;                      -- AD cnv timeout
      ADCNO:            Std_ULogic;                      -- AD cnv rejected
      ADCRDY:           Std_ULogic;                      -- AD cnv completed
      ADCON:            Std_ULogic;                      -- AD cnv ongoing
   end record;

   -----------------------------------------------------------------------------
   -- state register
   -----------------------------------------------------------------------------
   type state_type is (sIdle, sConfigure,
                              sConv, sConvSelect, sWait,
                              sRead, sReadSelect, sSample, sIrq,
                              sSetup, sWrite, sHold, sDisable);

   type ctrl_type is record
      state:            state_type;
      ws:               Std_Logic_Vector(16 downto 0);

      -- adc data input register
      ADCIN:            Std_Logic_Vector(dwidth-1 downto 0);
   end record;

   constant Zero:       Std_Logic_Vector(16 downto 0) := (others => '0');
   constant One:        Std_Logic_Vector( 5 downto 0) := "000001";

   -----------------------------------------------------------------------------
   -- registers
   -----------------------------------------------------------------------------
   type register_type is record
      -- configuration register
      conf:             conf_type;

      -- status register
      stat:             stat_type;

      -- state machine
      ctrl:             ctrl_type;

      -- adc/dac output interface
      ado:              analog_out_type;

      -- synchronisation
      sync:             sync_type;
   end record;

   signal   r, rin:     register_type;
begin

   -----------------------------------------------------------------------------
   -- combinatorial logic
   -----------------------------------------------------------------------------
   comb: process(rstn, r, apbi, adi)
      variable prdata:        Std_Logic_Vector(31 downto 0);
      variable pinterrupt:    Std_Logic_Vector(NIRQEXT-1 downto 0);
      variable pstartadc:     Std_ULogic;
      variable pstartdac:     Std_ULogic;
      variable v:             register_type;
   begin
      --------------------------------------------------------------------------
      -- local varianble
      prdata               := (others => '0');
      pstartadc            := '0';
      pstartdac            := '0';
      -- interrupt asserted one period only
      pinterrupt           := (others => '0');

      --------------------------------------------------------------------------
      -- local varianble copy of register signal
      v := r;

      --------------------------------------------------------------------------
      -- synchronization of external inputs
      v.sync.first         := adi;
      v.sync.second        := r.sync.first;
      v.sync.third         := r.sync.second;             -- not all used

      --------------------------------------------------------------------------
      -- amba apb interface
      --------------------------------------------------------------------------
      --------------------------------------------------------------------------
      -- read registers
      prdata := (others => '0');
      if    apbi.paddr(7 downto 2)=cADCONF then
         -- configuration register
         prdata(23 downto 19) := r.conf.DACWS;
         prdata(18)           := r.conf.WRPOL;
         prdata(17 downto 16) := r.conf.DACDW;
         prdata(15 downto 11) := r.conf.ADCWS;
         prdata(10)           := r.conf.RCPOL;
         prdata(9 downto 8)   := r.conf.CSMODE;
         prdata(7)            := r.conf.CSPOL;
         prdata(6)            := r.conf.RDYMODE;
         prdata(5)            := r.conf.RDYPOL;
         prdata(4)            := r.conf.TRIGPOL;
         prdata(3 downto 2)   := r.conf.TRIGMODE;
         prdata(1 downto 0)   := r.conf.ADCDW;

      elsif apbi.paddr(7 downto 2)=cADSTAT then
         -- status register
         prdata(6)            := r.stat.DACNO;
         prdata(5)            := r.stat.DACRDY;
         prdata(4)            := r.stat.DACON;
         prdata(3)            := r.stat.ADCTO;
         prdata(2)            := r.stat.ADCNO;
         prdata(1)            := r.stat.ADCRDY;
         prdata(0)            := r.stat.ADCON;

         -- cleared on read
         if apbi.penable='1' and apbi.psel(pindex)='1' and apbi.pwrite='0' then
            v.stat.DACNO      := '0';
            v.stat.DACRDY     := '0';
            v.stat.ADCTO      := '0';
            v.stat.ADCNO      := '0';
            v.stat.ADCRDY     := '0';
         end if;

      -- general purpose input output address
      elsif apbi.paddr(7 downto 2)=cADAIN then
         prdata(awidth-1 downto 0)     := r.sync.second.Ain(awidth-1 downto 0);
      elsif apbi.paddr(7 downto 2)=cADAOUT then
         prdata(awidth-1 downto 0)     := r.ado.aout(awidth-1 downto 0);
      elsif apbi.paddr(7 downto 2)=cADADIR then
         if oepol = 0 then
            prdata(awidth-1 downto 0)  := not r.ado.aen(awidth-1 downto 0);
         else
            prdata(awidth-1 downto 0)  :=     r.ado.aen(awidth-1 downto 0);
         end if;

      -- general purpose input output data
      elsif apbi.paddr(7 downto 2)=cADDIN then
         if    r.conf.ADCDW="01" then
            -- 8 least significant bits unavailable
            prdata(dwidth-1 downto 8)  := r.sync.second.Din(dwidth-1 downto 8);
         elsif r.conf.ADCDW="00" then
            -- all bits available
            prdata(dwidth-1 downto 0)  := r.sync.second.Din(dwidth-1 downto 0);
         end if;
      elsif apbi.paddr(7 downto 2)=cADDOUT then
         if    (r.conf.DACDW="00" and r.conf.ADCDW="01") or
               (r.conf.DACDW="01" and r.conf.ADCDW="00") or
               (r.conf.DACDW="01" and r.conf.ADCDW="01") then
            -- 8 least significant bits unavailable
            prdata(dwidth-1 downto 8)     := r.ado.dout(dwidth-1 downto 8);
         elsif r.conf.DACDW="00" and r.conf.ADCDW="00" then
            -- all bits available
            prdata(dwidth-1 downto 0)     := r.ado.dout(dwidth-1 downto 0);
         end if;
      elsif apbi.paddr(7 downto 2)=cADDDIR then
         if    (r.conf.DACDW="00" and r.conf.ADCDW="01") or
               (r.conf.DACDW="01" and r.conf.ADCDW="00") or
               (r.conf.DACDW="01" and r.conf.ADCDW="01") then
            -- 8 least significant bits unavailable
            if oepol = 0 then
               prdata(dwidth-1 downto 8)  := not r.ado.den(dwidth-1 downto 8);
            else
               prdata(dwidth-1 downto 8)  :=     r.ado.den(dwidth-1 downto 8);
            end if;
         elsif r.conf.DACDW="00" and r.conf.ADCDW="00" then
            -- all bits available
            if oepol = 0 then
               prdata(dwidth-1 downto 0)  := not r.ado.den(dwidth-1 downto 0);
            else
               prdata(dwidth-1 downto 0)  :=     r.ado.den(dwidth-1 downto 0);
            end if;
         end if;

      elsif apbi.paddr(7 downto 2)=cADIN then
         -- adc data input register
         if    r.conf.ADCDW="01" then
            prdata(8-1 downto 0)       := r.ctrl.ADCIN(8-1 downto 0);
         elsif r.conf.ADCDW="10" then
            prdata(16-1 downto 0)      := r.ctrl.ADCIN(16-1 downto 0);
         end if;

      elsif apbi.paddr(7 downto 2)=cADOUT then
         -- dac data output register
         if    r.conf.DACDW="01" then
            prdata(8-1 downto 0)       := r.ado.dout(8-1 downto 0);
         elsif r.conf.DACDW="10" then
            prdata(16-1 downto 0)      := r.ado.dout(16-1 downto 0);
         end if;
      end if;

      --------------------------------------------------------------------------
      -- write registers
      if (apbi.psel(pindex) and apbi.penable and apbi.pwrite) = '1' then
         if apbi.paddr(7 downto 2)=cADCONF then
            -- configuration register
            v.conf.DACWS        := apbi.pwdata(23 downto 19);
            v.conf.WRPOL        := apbi.pwdata(18);
            v.conf.DACDW        := apbi.pwdata(17 downto 16);
            v.conf.ADCWS        := apbi.pwdata(15 downto 11);
            v.conf.RCPOL        := apbi.pwdata(10);
            v.conf.CSMODE       := apbi.pwdata(9 downto 8);
            v.conf.CSPOL        := apbi.pwdata(7);
            v.conf.RDYMODE      := apbi.pwdata(6);
            v.conf.RDYPOL       := apbi.pwdata(5);
            v.conf.TRIGPOL      := apbi.pwdata(4);
            v.conf.TRIGMODE     := apbi.pwdata(3 downto 2);
            v.conf.ADCDW        := apbi.pwdata(1 downto 0);

         -- general purpose input output address
         elsif apbi.paddr(7 downto 2)=cADAOUT then
            v.ado.aout(awidth-1 downto 0)    := apbi.pwdata(awidth-1 downto 0);
         elsif apbi.paddr(7 downto 2)=cADADIR then
            if oepol = 0 then
               v.ado.aen(awidth-1 downto 0)  := not apbi.pwdata(awidth-1 downto 0);
            else
               v.ado.aen(awidth-1 downto 0)  :=     apbi.pwdata(awidth-1 downto 0);
            end if;

         -- general purpose input output data
         elsif apbi.paddr(7 downto 2)=cADDOUT then
            if    (r.conf.DACDW="00" and r.conf.ADCDW="01") or
                  (r.conf.DACDW="01" and r.conf.ADCDW="00") or
                  (r.conf.DACDW="01" and r.conf.ADCDW="01") then
               -- 8 least significant bits unavailable
               v.ado.dout(dwidth-1 downto 8) := apbi.pwdata(dwidth-1 downto 8);
            elsif r.conf.DACDW="00" and r.conf.ADCDW="00" then
               -- all bits available
               v.ado.dout(dwidth-1 downto 0) := apbi.pwdata(dwidth-1 downto 0);
            end if;
         elsif apbi.paddr(7 downto 2)=cADDDIR then
            if    (r.conf.DACDW="00" and r.conf.ADCDW="01") or
                  (r.conf.DACDW="01" and r.conf.ADCDW="00") or
                  (r.conf.DACDW="01" and r.conf.ADCDW="01") then
               -- 8 least significant bits unavailable
               if oepol = 0 then
                  v.ado.den(dwidth-1 downto 8)  := not apbi.pwdata(dwidth-1 downto 8);
               else
                  v.ado.den(dwidth-1 downto 8)  :=     apbi.pwdata(dwidth-1 downto 8);
               end if;
            elsif r.conf.DACDW="00" and r.conf.ADCDW="00" then
               -- all bits available
               if oepol = 0 then
                  v.ado.den(dwidth-1 downto 0)  := not apbi.pwdata(dwidth-1 downto 0);
               else
                  v.ado.den(dwidth-1 downto 0)  :=     apbi.pwdata(dwidth-1 downto 0);
               end if;
            end if;

         elsif apbi.paddr(7 downto 2)=cADIN then
            -- adc data input register
            if    (r.conf.ADCDW="01" or r.conf.ADCDW="10") and r.stat.DACON='0' and r.stat.ADCON='0' then
               -- start ad conversion
               pstartadc   := '1';
            else
               v.stat.ADCNO      := '1';
            end if;

         elsif apbi.paddr(7 downto 2)=cADOUT then
            -- dac data output register
            if    r.conf.DACDW="01" and r.stat.DACON='0' and r.stat.ADCON='0' then
               -- start da conversion
               pstartdac                  := '1';
               v.ado.dout(8-1 downto 0)   := apbi.pwdata(8-1 downto 0);
            elsif r.conf.DACDW="10" and r.stat.DACON='0' and r.stat.ADCON='0' then
               -- start da conversion
               pstartdac                  := '1';
               v.ado.dout(16-1 downto 0)  := apbi.pwdata(16-1 downto 0);
            else
               v.stat.DACNO               := '1';
            end if;
         end if;
      end if;

      --------------------------------------------------------------------------
      -- ADC/ADC control
      --------------------------------------------------------------------------
      case r.ctrl.state is
         when sIdle =>
            v.stat.DACON         := '0';
            v.stat.ADCON         := '0';
            if    (r.conf.DACDW="01" or r.conf.DACDW="10") and (pstartdac='1') then
               v.ctrl.state      := sConfigure;
               v.stat.DACON      := '1';
            elsif (r.conf.ADCDW="01" or r.conf.ADCDW="10") and
                  ((pstartadc='1') or
                  (r.conf.TRIGMODE="01" and r.sync.second.Trig(0)=r.conf.TRIGPOL and not r.sync.third.Trig(0)=r.conf.TRIGPOL) or
                  (r.conf.TRIGMODE="10" and r.sync.second.Trig(1)=r.conf.TRIGPOL and not r.sync.third.Trig(1)=r.conf.TRIGPOL) or
                  (r.conf.TRIGMODE="11" and r.sync.second.Trig(2)=r.conf.TRIGPOL and not r.sync.third.Trig(2)=r.conf.TRIGPOL)) then
               v.ctrl.state      := sConfigure;
               v.stat.ADCON      := '1';
            end if;
            v.ado.WR             := not r.conf.WRPOL;
            v.ado.CS             := not r.conf.CSPOL;
            v.ado.RC             := not r.conf.RCPOL;
            if    r.conf.DACDW="01" or r.conf.ADCDW="01" then
               -- 8 bits used by either ADC or DAC
               if oepol = 0 then
                  v.ado.den(8-1 downto 0)  := (others => '1');
               else
                  v.ado.den(8-1 downto 0)  := (others => '0');
               end if;
            elsif r.conf.DACDW="10" or r.conf.ADCDW="10" then
               -- 16 bits used by either ADC or DAC
               if oepol = 0 then
                  v.ado.den(16-1 downto 0) := (others => '1');
               else
                  v.ado.den(16-1 downto 0) := (others => '0');
               end if;
            end if;

         when sConfigure =>
            if r.stat.ADCON='1' then
               v.ctrl.ws         := "000000000000" & r.conf.ADCWS;
               v.ctrl.state      := sConv;
               if    r.conf.ADCDW="01" then
                  if oepol = 0 then
                     v.ado.den(8-1 downto 0)  := (others => '1');
                  else
                     v.ado.den(8-1 downto 0)  := (others => '0');
                  end if;
               elsif r.conf.ADCDW="10" then
                  if oepol = 0 then
                     v.ado.den(16-1 downto 0) := (others => '1');
                  else
                     v.ado.den(16-1 downto 0) := (others => '0');
                  end if;
               end if;
            else
               v.ctrl.ws         := "000000000000" & r.conf.DACWS;
               v.ctrl.state      := sSetup;
            end if;

         -- ADC conversion
         when sConv =>
            if r.ctrl.ws=Zero then
               v.ctrl.state      := sConvSelect;
               v.ctrl.ws         := "000000000000" & r.conf.ADCWS;
            else
               v.ctrl.ws         := r.ctrl.ws-1;
            end if;
         when sConvSelect =>
            if r.ctrl.ws=Zero then
               v.ctrl.state   := sWait;
               if r.conf.RDYMODE='1' then
                  -- ready with time out x 2048
                  v.ctrl.ws      := (r.conf.ADCWS+One) & "00000000000";
               else
                  -- open loop x 512
                  v.ctrl.ws      := "00" & (r.conf.ADCWS+One) & "000000000";
               end if;
            else
               v.ctrl.ws         := r.ctrl.ws-1;
            end if;
            if r.conf.CSMODE /="10" then
               v.ado.CS          := r.conf.CSPOL;
            else
               v.ado.CS          := not r.conf.CSPOL;
            end if;
         when sWait =>
            if r.conf.RDYMODE='1' and
                   v.sync.second.RDY=r.conf.RDYPOL and
               not v.sync.third.RDY=r.conf.RDYPOL then
               v.ctrl.state      := sRead;
               v.ctrl.ws         := "000000000000" & r.conf.ADCWS;
            elsif r.ctrl.ws=Zero then
               v.ctrl.state      := sRead;
               v.ctrl.ws         := "000000000000" & r.conf.ADCWS;
               if r.conf.RDYMODE='1' then
                  v.stat.ADCTO   := '1';
               end if;
            else
               v.ctrl.ws         := r.ctrl.ws-1;
            end if;
            if r.conf.CSMODE="11" then
               v.ado.CS          :=     r.conf.CSPOL;
            else
               v.ado.CS          := not r.conf.CSPOL;
            end if;
         when sRead =>
            if r.ctrl.ws=Zero then
               v.ctrl.state   := sReadSelect;
               v.ctrl.ws         := "000000000000" & r.conf.ADCWS;
            else
               v.ctrl.ws         := r.ctrl.ws-1;
            end if;
            if r.conf.CSMODE="11" then
               v.ado.CS          :=     r.conf.CSPOL;
            else
               v.ado.CS          := not r.conf.CSPOL;
            end if;
            v.ado.RC             := r.conf.RCPOL;
         when sReadSelect =>
            if r.ctrl.ws=Zero then
               v.ctrl.state      := sSample;
               v.ctrl.ws         := "000000000000" & r.conf.ADCWS;
            else
               v.ctrl.ws         := r.ctrl.ws-1;
            end if;
            v.ado.RC             := r.conf.RCPOL;
            if r.conf.CSMODE /= "01" then
               v.ado.CS          :=     r.conf.CSPOL;
            else
               v.ado.CS          := not r.conf.CSPOL;
            end if;

         when sSample =>
            v.ctrl.ADCIN(dwidth-1 downto 0) := adi.Din(dwidth-1 downto 0);
            v.ctrl.state         := sIrq;
            v.ado.RC             := r.conf.RCPOL;
            v.ado.CS             := not r.conf.CSPOL;
         when sIrq =>
            v.ado.RC             := not r.conf.RCPOL;
            v.ado.CS             := not r.conf.CSPOL;
            v.ctrl.state         := sIdle;
            pinterrupt(0)        := '1';
            v.stat.ADCRDY        := '1';
            v.stat.DACON         := '0';
            v.stat.ADCON         := '0';

         -- DAC conversion
         when sSetup =>
            if r.ctrl.ws=Zero then
               v.ctrl.state   := sWrite;
               v.ctrl.ws         := "000000000000" & r.conf.DACWS;
            else
               v.ctrl.ws         := r.ctrl.ws-1;
            end if;
            v.ado.WR             := not r.conf.WRPOL;
            if    r.conf.DACDW="01" then
               if oepol = 0 then
                  v.ado.den(8-1 downto 0)  := (others => '0');
               else
                  v.ado.den(8-1 downto 0)  := (others => '1');
               end if;
            elsif r.conf.DACDW="10" then
               if oepol = 0 then
                  v.ado.den(16-1 downto 0) := (others => '0');
               else
                  v.ado.den(16-1 downto 0) := (others => '1');
               end if;
            end if;

         when sWrite =>
            if r.ctrl.ws=Zero then
               v.ctrl.state      := sHold;
               v.ctrl.ws         := "000000000000" & r.conf.DACWS;
            else
               v.ctrl.ws         := r.ctrl.ws-1;
            end if;
            v.ado.WR             := r.conf.WRPOL;
         when sHold =>
            if r.ctrl.ws=Zero then
               v.ctrl.state      := sDisable;
            else
               v.ctrl.ws         := r.ctrl.ws-1;
            end if;
            v.ado.WR             := not r.conf.WRPOL;
         when sDisable =>
            v.ctrl.state      := sIdle;
            v.stat.DACRDY     := '1';
            v.stat.DACON      := '0';
            v.stat.ADCON      := '0';
            pinterrupt(1)     := '1';
            if    r.conf.DACDW="01" then
               if oepol = 0 then
                  v.ado.den(8-1 downto 0)  := (others => '1');
               else
                  v.ado.den(8-1 downto 0)  := (others => '0');
               end if;
            elsif r.conf.DACDW="10" then
               if oepol = 0 then
                  v.ado.den(16-1 downto 0) := (others => '1');
               else
                  v.ado.den(16-1 downto 0) := (others => '0');
               end if;
            end if;
         when others =>
      end case;

      --------------------------------------------------------------------------
      -- interrupt handling: events in priority order
      --------------------------------------------------------------------------
      -- 1) synchronous reset
      -- 2) interrupt detect
      --------------------------------------------------------------------------
      -- interrupt priority ordering / numbering
      --------------------------------------------------------------------------
      -- 0  ADC   ADC conversion ready
      -- 1  DAC   DAC conversion ready
      --------------------------------------------------------------------------

      --------------------------------------------------------------------------
      -- synchronous reset operation
      if rstn = '0' then
         v.conf.DACWS      := (others => '0');
         v.conf.WRPOL      := '0';
         v.conf.DACDW      := (others => '0');
         v.conf.ADCWS      := (others => '0');
         v.conf.RCPOL      := '0';
         v.conf.CSMODE     := (others => '0');
         v.conf.CSPOL      := '0';
         v.conf.RDYMODE    := '0';
         v.conf.RDYPOL     := '0';
         v.conf.TRIGPOL    := '0';
         v.conf.TRIGMODE   := (others => '0');
         v.conf.ADCDW      := (others => '0');

         v.stat.DACNO      := '0';
         v.stat.DACRDY     := '0';
         v.stat.DACON      := '0';
         v.stat.ADCTO      := '0';
         v.stat.ADCNO      := '0';
         v.stat.ADCRDY     := '0';
         v.stat.ADCON      := '0';

         v.ctrl.state      := sIdle;
         v.ctrl.ws         := (others => '0');
         v.ctrl.ADCIN      := (others => '0');

         v.sync.first.ain  := (others => '0');
         v.sync.first.din  := (others => '0');
         v.sync.first.RDY  := '0';
         v.sync.first.TRIG := (others => '0');

         v.sync.second.ain := (others => '0');
         v.sync.second.din := (others => '0');
         v.sync.second.RDY := '0';
         v.sync.second.TRIG:= (others => '0');

         v.sync.third.RDY  := '0';
         v.sync.third.TRIG := (others => '0');

         if oepol=0 then
            v.ado.Aen      := (others => '1');
            v.ado.Den      := (others => '1');
         else
            v.ado.Aen      := (others => '0');
            v.ado.Den      := (others => '0');
         end if;

         v.ado.Aout        := (others => '0');
         v.ado.Dout        := (others => '0');
         v.ado.Wr          := '1';
         v.ado.CS          := '1';
         v.ado.RC          := '1';
      end if;

      --------------------------------------------------------------------------
      -- variable to signal assigment
      rin               <= v;
      apbo.prdata       <= prdata;                       -- drive apb read bus

      --------------------------------------------------------------------------
      -- amba apb interrupt output
      --------------------------------------------------------------------------
      if pirq = 0 then                                   -- interrupt mapping
         apbo.pirq      <= (others => '0');
      else
         apbo.pirq      <= (others => '0');
         for i in 0 to NIRQEXT-1 loop
            if (pirq+i) < NAHBIRQ then
               apbo.pirq(pirq+i) <= pinterrupt(i);
            end if;
         end loop;
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

   ado.Aout(31 downto awidth)   <= (others => '0');
   ado.Dout(31 downto dwidth)   <= (others => '0');
   ado.Aen(31 downto awidth)    <= (others => '0');
   ado.Den(31 downto dwidth)    <= (others => '0');

   ado.Aout(awidth-1 downto 0)   <= r.ado.Aout(awidth-1 downto 0);
   ado.Dout(dwidth-1 downto 0)   <= r.ado.Dout(dwidth-1 downto 0);

   ado.Aen(awidth-1 downto 0)    <= r.ado.Aen(awidth-1 downto 0);
   ado.Den(dwidth-1 downto 0)    <= r.ado.Den(dwidth-1 downto 0);

   ado.Wr                        <= r.ado.Wr;
   ado.CS                        <= r.ado.CS;
   ado.RC                        <= r.ado.RC;

   -----------------------------------------------------------------------------
   -- boot message
   -----------------------------------------------------------------------------
-- pragma translate_off
   bootmsg : report_version
      generic map(
         "gradcdac" & tost(pindex) & ":  " &
         "GR ADC/DAC Interface Unit rev " & tost(REVISION) & ", " &
         tost(awidth) & "-bit address, " &
         tost(dwidth) & "-bit data, " &
         "irq " & tost(pirq) & " to " & tost(pirq+NIRQEXT-1));
-- pragma translate_on

-- pragma translate_off
   assert dwidth=16
      report "gradcdac: dwidth not equal to 16 bits"
      severity Failure;
-- pragma translate_on

-- pragma translate_off
   assert awidth=8
      report "gradcdac: awidth not equal to 8 bits"
      severity Failure;
-- pragma translate_on

end architecture rtl; --======================================================--

--------------------------------------------------------------------------------
-- ADC timing diagram
--------------------------------------------------------------------------------
--
--            | Start Conv. |        | Read result |
--            |             |        |             |
--            |  WS  |  WS  |        |  WS  |  WS  | |
--       _____|______|      |__  ____|______|      |_|_______________
-- CS         |      \______/        |      \______/ |
-- 00b        |      |      |        |      |      | |
--       _____|______|      |__  ____|______|______|_|_______________
-- CS         |      \______/        |      |      | |
-- 01b        |      |      |        |      |      | |
--       _____|______|______|__  ____|______|      |_|_______________
-- CS         |      |      |        |      \______/ |
-- 10b        |      |      |        |      |      | |
--       _____|______|      |        |      |      |_|_______________
-- CS         |      \______|__  ____|______|______/ |
-- 11b        |      |      |        |      |      | |
--            |      |      |        |______|______|_|
-- RC    _____|______|______|__  ____/             | \_______________
--            |_                     |             | |
-- TRIG  _____/ \______________  ____|_____________|_________________
--                                   |_            |
-- RDY   ______________________  ____/ \___________|_________________
--                                           ______|
-- DATA  ----------------------  -----------<______|>----------------
--                                                 |_
-- IRQ   ______________________  __________________/ \_______________
--       _ ____________________  __________________|_______________ _
-- ADDR  _X____________________  __________________|_______________X_
--                                                 |
--                                              Sample data
-- RCPOL   = 0
-- CSPOL   = 0
-- RDYPOL  = 1
-- TRIGPOL = 1
-- RDYMODE = 1
-- CSMODE  = see diagram
-- ADCWS   = corresponds to WS in diagram
--
-- States:    sIdle, sConv, sConvSelect, sWait, sRead, sReadSelect, sSample, sIrq
--------------------------------------------------------------------------------
-- The ADCONF.ADCWS field shall define the number of system clock periods,
-- ranging from 1 to 32, for the following timing relationships between the ADC
-- control signals:
-- ADO.RC stable before ADO.CS period
-- ADO.CS asserted period, when pulsed
-- ADO.TRIG[2:0] event until ADO.CS asserted period      (same as first period)
--
-- Time-out period for ADO.RDY: 512 * ADCONF.ADCWS
-- Open-loop conversion timing: 128 * ADCONF.ADCWS
--
--------------------------------------------------------------------------------
-- DAC timing diagram
--------------------------------------------------------------------------------
--
--                  Conversion
--            |                    |
--            |  WS  |  WS  |  WS  |
--       _____|______|      |______|________
-- WR         |      \______/      |
--            ______________|______|
-- DATA  ----<______________|______|>-------
--                                _|
-- IRQ   ________________________/ \________
--       _ _______________________________ _
-- ADDR  _X_______________________________X_
--
-- WRPOL = 0
-- DACWS = corresponds to WS in diagram
--
-- States:  sIdle, sSetup, sWrite, sHold
--------------------------------------------------------------------------------
-- The ADCONF.DACWS field shall define the number of system clock periods,
-- ranging from 1 to 32, for the following timing relationships between the DAC
-- control signals:
-- ADO.Dout[15:0] stable before ADO.WR period
-- ADO.WR asserted period
-- ADO.Dout[15:0] stable after ADO.WR period
--------------------------------------------------------------------------------

