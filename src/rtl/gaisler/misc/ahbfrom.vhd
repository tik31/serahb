------------------------------------------------------------------------------
--  This file is a part of the GRLIB VHDL IP LIBRARY
--  Copyright (C) 2017, Cobham Gaisler AB - all rights reserved.
--
-- ANY USE OR REDISTRIBUTION IN PART OR IN WHOLE MUST BE HANDLED IN 
-- ACCORDANCE WITH THE GAISLER LICENSE AGREEMENT AND MUST BE APPROVED 
-- IN ADVANCE IN WRITING. 
--------------------------------------------------------------------------------
-- Entity:      ahbfrom
-- File:        ahbfrom.vhd
-- Author:      Aeroflex Gaisler
-- Contact:     support@gaisler.com
-- Description: AHB slave interface towards Microsemi/Actel Flash ROM
--              128 bytes accessed as either 32 words or one byte in 128 words
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

library grlib;
use grlib.amba.all;

entity ahbfrom is
   generic (
      tech:          integer  := 0;
      hindex:        integer  := 0;
      haddr:         integer  := 0;
      hmask:         integer  := 16#fff#;
      width8:        integer  := 0;
      memoryfile:    string   := "from.mem";
      progfile:      string   := "from.ufc");
  port (
      rstn:    in    std_ulogic;
      clk:     in    std_ulogic;
      ahbi:    in    ahb_slv_in_type;
      ahbo:    out   ahb_slv_out_type);
end entity;

--============================== Architecture ================================--

library grlib;
use grlib.stdlib.all;
use grlib.devices.all;

library techmap;
use techmap.allmem.from;

architecture rtl of ahbfrom is
   -----------------------------------------------------------------------------
   -- supporting types
   -----------------------------------------------------------------------------
   type ahb_type is record
      DataPhase:              Std_ULogic;
      ErrorPhase:             Std_ULogic;
      WritePhase:             Std_ULogic;

      HREADY:                 Std_Ulogic;
      HRESP:                  Std_Logic_Vector(1 downto 0);
      HRDATA:                 Std_Logic_Vector(31 downto 0);
   end record;

   -----------------------------------------------------------------------------
   -- registers
   -----------------------------------------------------------------------------
   type register_type is record
      ahb:                    ahb_type;
      addr:                   std_logic_vector(6 downto 0);
      cntr:                   integer range 0 to 7;
   end record;

   signal r, rin:             register_type;

   signal data:               std_logic_vector(7 downto 0);
   signal addr:               std_logic_vector(6 downto 0);

   -----------------------------------------------------------------------------
   -- configuration constants
   -----------------------------------------------------------------------------
   constant hconfig: ahb_config_type :=
      (0      => ahb_device_reg (VENDOR_GAISLER, GAISLER_AHBFROM, 0, 1-width8, 0),
       4      => ahb_membar(haddr, '1', '1', hmask),
       others => zero32);
begin

   -----------------------------------------------------------------------------
   -- 32-bit wide memory
   -----------------------------------------------------------------------------
   data32: if width8 = 0 generate
      --------------------------------------------------------------------------
      -- combinatorial logic
      --------------------------------------------------------------------------
      comb: process(rstn, r, ahbi, data)
         variable v:       register_type;
      begin
         -----------------------------------------------------------------------
         -- local variable copy of register signal
         v := r;

         -----------------------------------------------------------------------
         -- amba apb slave interface
         -----------------------------------------------------------------------
         -- data phase
         -----------------------------------------------------------------------
         -- data always available for readout
         -----------------------------------------------------------------------
         -- two-cycle error response
         if    r.ahb.ErrorPhase='1' then
            v.ahb.HREADY                  := '1';
            v.ahb.DataPhase               := '0';
            v.ahb.WritePhase              := '0';
            v.ahb.ErrorPhase              := '0';

         -----------------------------------------------------------------------
         -- data access
         -- 32-bit big-endian data bus
         elsif r.ahb.DataPhase='1' and r.cntr=0 then
            v.ahb.DataPhase               := '0';
            v.ahb.WritePhase              := '0';
            v.ahb.ErrorPhase              := '0';
            v.ahb.HRDATA( 7 downto  0)    := data;
            v.ahb.HREADY                  := '1';
         elsif r.ahb.DataPhase='1' then
            if    r.cntr = 4 then
               v.addr(1 downto 0)         := "01";
            elsif r.cntr = 3 then
               v.ahb.HRDATA(31 downto 24) := data;
               v.addr(1 downto 0)         := "10";
            elsif r.cntr = 2 then
               v.ahb.HRDATA(23 downto 16) := data;
               v.addr(1 downto 0)         := "11";
            elsif r.cntr = 1 then
               v.ahb.HRDATA(15 downto  8) := data;
            end if;
            v.cntr                        := r.cntr -1;
         end if;

         -----------------------------------------------------------------------
         -- address phase
         -----------------------------------------------------------------------
         -- relevant access
         if    ahbi.HSEL(hindex)='1' and
               ahbi.HMBSEL(0)='1'and
               ahbi.HREADY='1'and
               (ahbi.HTRANS=HTRANS_SEQ or
                ahbi.HTRANS=HTRANS_NONSEQ) and
               (ahbi.HBURST=HBURST_SINGLE or
                ahbi.HBURST=HBURST_INCR or
                ahbi.HBURST=HBURST_INCR4 or
                ahbi.HBURST=HBURST_INCR8 or
                ahbi.HBURST=HBURST_INCR16) and
               ahbi.HMASTLOCK='0' and
               ahbi.HSIZE = HSIZE_WORD and
               ahbi.HWRITE='0' then

            -- access decoding
            -- read access
            v.ahb.HRESP          := HRESP_OKAY;
            v.ahb.HREADY         := '0';
            v.ahb.DataPhase      := '1';
            v.ahb.WritePhase     := '0';
            v.addr               := ahbi.haddr(6 downto 2) & "00";
            v.cntr               := 4;

         -- default slave response on idle or busy
         elsif ahbi.HSEL(hindex)='1' and
               ahbi.HMBSEL(0)='1' and
               ahbi.HREADY='1' and
               (ahbi.HTRANS=HTRANS_IDLE or
                ahbi.HTRANS=HTRANS_BUSY) and
               r.ahb.DataPhase='0' and
               r.ahb.ErrorPhase='0' then
            v.ahb.HREADY         := '1';
            v.ahb.HRESP          := HRESP_OKAY;

         -- error response
         elsif ahbi.HSEL(hindex)='1' and
               ahbi.HMBSEL(0)='1' and
               ahbi.HREADY='1' and
               r.ahb.DataPhase='0' and
               r.ahb.ErrorPhase='0' then
            v.ahb.HREADY         := '0';
            v.ahb.HRESP          := HRESP_ERROR;
            v.ahb.DataPhase      := '1';
            v.ahb.ErrorPhase     := '1';

         -- default response
         elsif r.ahb.DataPhase='0' and r.ahb.ErrorPhase='0' then
            v.ahb.HREADY         := '1';
            v.ahb.HRESP          := HRESP_OKAY;
         end if;

         --===================================================================--
         -- Synchronous reset operation
         -----------------------------------------------------------------------
         if rstn = '0' then
            v.ahb.DataPhase      := '0';
            v.ahb.ErrorPhase     := '0';
            v.ahb.WritePhase     := '0';

            v.ahb.HREADY         := '1';
            v.ahb.HRESP          := (others => '0');
            v.ahb.HRDATA         := (others => '0');
            v.addr               := (others => '0');
            v.cntr               := 0;
         end if;

         -----------------------------------------------------------------------
         -- variable to signal assigment
         rin               <= v;
      end process comb;

      --------------------------------------------------------------------------
      -- registers
      --------------------------------------------------------------------------
      regs: process(clk)
      begin
         if Rising_Edge(clk) then
            r              <= rin;
         end if;
      end process regs;

      --------------------------------------------------------------------------
      -- amba ahb output ports
      --------------------------------------------------------------------------
      ahbo.hready          <= r.ahb.hready;
      ahbo.hresp           <= r.ahb.hresp;
      ahbo.hrdata          <= ahbdrivedata(r.ahb.HRDATA);

      ahbo.hsplit          <= (others => '0');
      ahbo.hirq            <= (others => '0');

      --------------------------------------------------------------------------
      -- amba ahb configuration
      --------------------------------------------------------------------------
      ahbo.hindex          <= hindex;
      ahbo.hconfig         <= hconfig;

      --------------------------------------------------------------------------
      -- FROM interface
      --------------------------------------------------------------------------
      addr                 <= r.addr;

      --------------------------------------------------------------------------
      -- boot message
      --------------------------------------------------------------------------
-- pragma translate_off
      bootmsg : report_version
         generic map (
            "ahbfrom" & tost(hindex) &
            ": 32-bit AHB FROM Module, 128 bytes, 5 address bits");
-- pragma translate_on
   end generate;


   -----------------------------------------------------------------------------
   -- 8-bit wide memory
   -----------------------------------------------------------------------------
   data8: if width8 > 0 generate
      --------------------------------------------------------------------------
      -- amba ahb signals
      --------------------------------------------------------------------------
      ahbo.hresp     <= "00";
      ahbo.hsplit    <= (others => '0');
      ahbo.hirq      <= (others => '0');
      ahbo.hconfig   <= hconfig;
      ahbo.hindex    <= hindex;
      ahbo.hrdata    <= ahbdrivedata(data);
      ahbo.hready    <= '1';
      addr           <= ahbi.haddr(6+2 downto 0+2);

      --------------------------------------------------------------------------
      -- boot message
      --------------------------------------------------------------------------
-- pragma translate_off
      bootmsg : report_version
         generic map (
            "ahbfrom" & tost(hindex) &
            ": 8-bit AHB FROM Module, 128 bytes, 7 address bits");
-- pragma translate_on
   end generate;

   -----------------------------------------------------------------------------
   -- Microsemia/Actel Flash ROM - FROM
   -----------------------------------------------------------------------------
   flashrom: from
      generic map(
         tech        => tech,
         memoryfile  => memoryfile,
         progfile    => progfile)
      port map(
         clk         => clk,
         addr        => addr,
         data        => data);

end architecture rtl; --======================================================--

