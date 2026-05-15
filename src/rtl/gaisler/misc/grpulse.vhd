------------------------------------------------------------------------------
--  This file is a part of the GRLIB VHDL IP LIBRARY
--  Copyright (C) 2017, Cobham Gaisler AB - all rights reserved.
--
-- ANY USE OR REDISTRIBUTION IN PART OR IN WHOLE MUST BE HANDLED IN 
-- ACCORDANCE WITH THE GAISLER LICENSE AGREEMENT AND MUST BE APPROVED 
-- IN ADVANCE IN WRITING. 
--============================================================================--
-- Design unit  : GRPULSE Interface (Entity & architecture declarations)
--
-- File name    : grpulse.vhd
--
-- Library      : {independent}
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
-- Version  Author   Date           Changes
--
-- 1.0      SH        1 Sep 2005    New design
-- 1.1      SH       25 Nov 2005    APB address decoding range 7:2 extended
--                                  Extended pulse width with one clock period
-- 1.2      SH       24 Feb 2006    Added syncrst generic
--                                  Vendor and device ID hard coded
-- 1.3      SH       15 Mar 2006    Added interrupt mask and offset
--                                  Harmonized register address map with GRGPIO
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

entity grpulse is
   generic (
      pindex:           Integer :=  0;
      paddr:            Integer :=  0;
      pmask:            Integer := 16#fff#;
      pirq:             Integer :=  1;                   -- Interrupt index
      nchannel:         Integer := 24;                   -- Number of channels
      npulse:           Integer :=  8;                   -- Channels with pulses
      imask:            Integer := 16#ff0000#;           -- Interrupt mask
      ioffset:          Integer :=  8;                   -- Interrupt offset
      invertpulse:      Integer :=  0;                   -- Invert pulses
      cntrwidth:        Integer := 20;                   -- Width of counter
      syncrst:          Integer :=  1;                   -- Only synchronous reset
      oepol:            Integer :=  1);                  -- Output enable polarity
   port (
      rstn:       in    Std_ULogic;
      clk:        in    Std_ULogic;
      apbi:       in    apb_slv_in_type;
      apbo:       out   apb_slv_out_type;
      gpioi:      in    gpio_in_type;
      gpioo:      out   gpio_out_type);
end entity grpulse;

architecture rtl of grpulse is

   -----------------------------------------------------------------------------
   -- addressing constants
   -----------------------------------------------------------------------------
   --                                         765432
   constant cGpioIN:    Std_Logic_Vector(7 downto 2) := "000000";
   constant cGpioOUT:   Std_Logic_Vector(7 downto 2) := "000001";
   constant cGpioDIR:   Std_Logic_Vector(7 downto 2) := "000010";

   constant cGpioMASK:  Std_Logic_Vector(7 downto 2) := "000011";
   constant cGpioPOL:   Std_Logic_Vector(7 downto 2) := "000100";
   constant cGpioEDGE:  Std_Logic_Vector(7 downto 2) := "000101";

   constant cGpioPULSE: Std_Logic_Vector(7 downto 2) := "000110";
   constant cGpioCNTR:  Std_Logic_Vector(7 downto 2) := "000111";

   constant cZeroCntr:  Std_Logic_Vector(cntrwidth-1 downto 0):= (others => '0');

   -----------------------------------------------------------------------------
   -- Interrupt mask
   -----------------------------------------------------------------------------
   constant PIMASK:     Std_Logic_Vector(31 downto 0) :=
                             Conv_Std_Logic_Vector(imask/65536, 16) &
                             Conv_Std_Logic_Vector(imask mod 65536, 16);

   -----------------------------------------------------------------------------
   -- configuration constants
   -----------------------------------------------------------------------------
   constant REVISION:   Integer := 0;

   constant pconfig:    apb_config_type := (
      0 => ahb_device_reg (16#01#, 16#037#, 0, REVISION, pirq),
      1 => apb_iobar(paddr, pmask));

   -----------------------------------------------------------------------------
   -- local types and signal declarations
   -----------------------------------------------------------------------------
   type register_type is record
      din1:             Std_Logic_Vector(nchannel-1 downto 0);
      din2:             Std_Logic_Vector(nchannel-1 downto 0);
      din3:             Std_Logic_Vector(nchannel-1 downto 0);
      dout:             Std_Logic_Vector(nchannel-1 downto 0);
      dir:              Std_Logic_Vector(nchannel-1 downto 0);

      pulse:            Std_Logic_Vector(npulse-1 downto 0);
      pulsecntr:        Std_Logic_Vector(cntrwidth-1 downto 0);
      pulseactive:      Std_ULogic;

      imask:            Std_Logic_Vector(nchannel-1 downto 0);
      level:            Std_Logic_Vector(nchannel-1 downto 0);
      edge:             Std_Logic_Vector(nchannel-1 downto 0);
   end record;

   signal r, rin:       register_type;

begin

   -----------------------------------------------------------------------------
   -- combinatorial logic
   -----------------------------------------------------------------------------
   comb: process(rstn, r, apbi, gpioi)
      variable prdata:     Std_Logic_Vector(31 downto 0);
      variable pinterrupt: Std_Logic_Vector(NAHBIRQ-1 downto 0);
      variable pfilter:    Std_Logic_Vector(nchannel-1 downto 0);
      variable pulsetoggle:Std_ULogic;
      variable v:          register_type;
      variable paddr7_2:   Std_Logic_Vector(7 downto 2);
   begin
      paddr7_2 := apbi.paddr(7 downto 2);

      -- local copy
      v        := r;

      -- synchronization
      v.din3   := r.din2;
      v.din2   := r.din1;
      v.din1   := gpioi.din(nchannel-1 downto 0);

      -- read registers
      prdata := (others => '0');
      case paddr7_2 is
         when cGpioIN =>
            prdata(nchannel-1 downto 0)      := r.din2;
         when cGpioOUT =>
            prdata(nchannel-1 downto 0)      := r.dout;
         when cGpioDIR =>
            if oepol = 0 then
               prdata(nchannel-1 downto 0)   := not r.dir;
            else
               prdata(nchannel-1 downto 0)   := r.dir;
            end if;
         when cGpioPULSE =>
            prdata(npulse-1 downto 0)        := r.pulse;
         when cGpioCNTR =>
            prdata(cntrwidth-1 downto 0)     := r.pulsecntr;
         when cGpioMASK =>
            if (imask /= 0) then
               prdata(nchannel-1 downto 0)   := r.imask and
                                                PIMASK(nchannel-1 downto 0);
            end if;
         when cGpioPOL =>
            if (imask /= 0) then
               prdata(nchannel-1 downto 0)   := r.level and
                                                PIMASK(nchannel-1 downto 0);
            end if;
         when cGpioEDGE =>
            if (imask /= 0) then
               prdata(nchannel-1 downto 0)   := r.edge and
                                                PIMASK(nchannel-1 downto 0);
            end if;
         when others =>
            null;
      end case;

      -- write registers
      if (apbi.psel(pindex) and apbi.penable and apbi.pwrite) = '1' then
         case paddr7_2 is
            when cGpioIN =>
               null;
            when cGpioOUT =>
               if (npulse =0) or (r.pulseactive = '0' and npulse > 0)  then
                  v.dout      := apbi.pwdata(nchannel-1 downto 0);
               end if;
            when cGpioDIR =>
               if (npulse =0) or (r.pulseactive = '0' and npulse > 0)  then
                  if oepol = 0 then
                     v.dir    := not apbi.pwdata(nchannel-1 downto 0);
                  else
                     v.dir    := apbi.pwdata(nchannel-1 downto 0);
                  end if;
               end if;
            when cGpioPULSE =>
               if r.pulseactive = '0' and npulse > 0 then
                  v.pulse     := apbi.pwdata(npulse-1 downto 0);
               end if;
            when cGpioCNTR =>
               if r.pulseactive = '0' and npulse > 0 then
                  v.pulsecntr := apbi.pwdata(cntrwidth-1 downto 0);
               end if;
            when cGpioMASK =>
               if (imask /= 0) then
                  v.imask     := apbi.pwdata(nchannel-1 downto 0) and
                                 PIMASK(nchannel-1 downto 0);
               end if;
            when cGpioPOL =>
               if (imask /= 0) then
                  v.level     := apbi.pwdata(nchannel-1 downto 0) and
                                 PIMASK(nchannel-1 downto 0);
               end if;
            when cGpioEDGE =>
               if (imask /= 0) then
                  v.edge      := apbi.pwdata(nchannel-1 downto 0) and
                                 PIMASK(nchannel-1 downto 0);
               end if;

            when others =>
               null;
         end case;
      end if;

      -- interrupt asserted one period only
      pinterrupt              := (others => '0');
      pulsetoggle             := '0';

      -- pulse generation
      if r.pulsecntr > cZeroCntr and npulse > 0 then
         if r.pulseactive='0' then
            v.pulseactive     := '1';
            pulsetoggle       := '1';
         end if;
          v.pulsecntr         := r.pulsecntr-1;
      elsif r.pulseactive='1' and r.pulsecntr = cZeroCntr and npulse > 0 then
         v.pulseactive        := '0';
         pulsetoggle          := '1';
         if pirq > 0 and pirq < NAHBIRQ then
            pinterrupt(pirq)  := '1';
         end if;
      end if;

      -- output and pulse channels
      for i in npulse-1 downto 0 loop
         if (r.pulse(i)='1') and
            (npulse > 0) and
            ((r.dir(i)='1' and oepol=1) or
             (r.dir(i)='0' and oepol=0)) then            -- pulse output
            if pulsetoggle='1' then
               if invertpulse=1 then
                  v.dout(i)      := not v.dout(i);       -- activate/inactivate
               else
                  if v.pulseactive='1' then
                     v.dout(i)   := '1';                 -- active
                  else
                     v.dout(i)   := '0';                 -- inactive
                  end if;
               end if;
            end if;
         end if;
      end loop;

      -- interrupt filtering and routing with offset
      if (imask /= 0) then
         for i in 0 to nchannel-1 loop
            if (PIMASK(i) and r.imask(i)) = '1' then
               if r.edge(i) = '1' then                   -- edge detect
                  if r.level(i) = '1' then
                     -- rising edge
                     pfilter(i)  :=     r.din2(i) and not r.din3(i);
                  else
                     -- falling edge
                     pfilter(i)  := not r.din2(i) and     r.din3(i);
                  end if;
               else                                      -- level detect
                  pfilter(i)     :=     r.din2(i) xor not r.level(i);
               end if;
            else
               pfilter(i)        := '0';
            end if;
         end loop;

         for i in 0 to nchannel-1 loop
            if i+ioffset > NAHBIRQ-1 then
               exit;
            end if;
            pinterrupt(i+ioffset) := pinterrupt(i+ioffset) or pfilter(i);
         end loop;
      end if;

      -- synchronous reset operation
      if rstn = '0' then
         v.din1            := (others => '0');
         v.din2            := (others => '0');
         v.din3            := (others => '0');
         v.dout            := (others => '0');
         if syncrst /= 0 then
            if oepol=0 then
               v.dir       := (others => '1');
            else
               v.dir       := (others => '0');
            end if;
         end if;
         v.pulse           := (others => '0');
         v.pulsecntr       := (others => '0');
         v.pulseactive     := '0';
         v.imask           := (others => '0');
         v.level           := (others => '0');
         v.edge            := (others => '0');
      end if;

      -- variable to signal assigment
      rin         <= v;

      apbo.prdata <= prdata;                             -- drive apb read bus
      apbo.pirq   <= pinterrupt;

      -- internal to external signal assigment
      -- output only channels
      gpioo.dout(nchannel-1 downto 0)  <= r.dout;

      -- buffer output enable
      gpioo.oen(nchannel-1 downto 0)   <= r.dir;

   end process;

   -----------------------------------------------------------------------------
   -- configuration assigment
   -----------------------------------------------------------------------------
   apbo.pindex    <= pindex;
   apbo.pconfig   <= pconfig;

   -----------------------------------------------------------------------------
   -- registers
   -----------------------------------------------------------------------------
   regs: process(clk, rstn)
   begin
      if Rising_Edge(clk) then
         r        <= rin;
      end if;
      if (syncrst = 0) and (rstn = '0') then
         if oepol=0 then
            r.dir <= (others => '1');                    -- asynchronous reset
         else
            r.dir <= (others => '0');                    -- asynchronous reset
         end if;
         r.dout   <= (others => '0');                    -- asynchronous reset
      end if;
   end process;

   -----------------------------------------------------------------------------
   -- boot message
   -----------------------------------------------------------------------------
-- pragma translate_off
    bootmsg : report_version
      generic map(
         "grpulse" & tost(pindex) & ": " &
         "General Purpose I/O with Pulses rev " & tost(REVISION) & ", " &
         tost(nchannel) & "-bit channel, " &
         tost(npulse) & "-bit pulse, " &
         "irq " & tost(pirq) &
         ", irq mask " & tost(imask) &
         ", irq offset " & tost(ioffset));
-- pragma translate_on

-- pragma translate_off
   assert nchannel >= npulse
      report "grpulse: nchannel < npulse failure"
      severity Failure;
-- pragma translate_on

end architecture rtl; --======================================================--

