------------------------------------------------------------------------------
--  This file is a part of the GRLIB VHDL IP LIBRARY
--  Copyright (C) 2017, Cobham Gaisler AB - all rights reserved.
--
-- ANY USE OR REDISTRIBUTION IN PART OR IN WHOLE MUST BE HANDLED IN 
-- ACCORDANCE WITH THE GAISLER LICENSE AGREEMENT AND MUST BE APPROVED 
-- IN ADVANCE IN WRITING. 
-----------------------------------------------------------------------------
-- Entity:        sf2mddr_wrapper
-- File:          sf2mddr_wrapper.vhd
-- Author:        Pascal Trotta
-- Description:   AHB/APB3 slave wrapper for SmartFusion2/IGLOO2 MDDR with single 32-bit AHB Lite interface
--                and APB3 interface for standalone configuration.
--                AHB slave input signals not used: hmaster, hmbsel, hirq, testen, testrst,
--                scanen, testoen, testin;
--                APB3 slave input signals not used: pirq, testen, testrst, scanen, testoen, testin.
-- Limitations:   Support only 32-bit wide bus
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library grlib;
use grlib.amba.all;
use grlib.devices.all;
use grlib.stdlib.all;
library techmap;
use techmap.gencomp.all;
library gaisler;
use gaisler.misc.all;


entity sf2mddr_wrapper is
    generic (
      hindex    : integer := 0;
      haddr     : integer := 16#400#; -- mapped at 0x40000000
      hmask     : integer := 16#FC0#; -- 64 MB
      pindex    : integer := 13;
      paddr     : integer := 13;
      pmask     : integer := 16#FF8#;
      delay     : integer := 4;         -- unused
      vendorid  : integer := VENDOR_ACTEL; 
      deviceid  : integer := ACTEL_MDDR;
      pnpuser0  : integer := 0);
    port (
      rstn      : in  std_ulogic;
      clk       : in  std_ulogic;
      ahbsi     : in  ahb_slv_in_type;
      ahbso     : out ahb_slv_out_type;
      sf2si    : out sf2_slv_in_type;
      sf2so    : in sf2_slv_out_type;
      apb3i      : in  apb3_slv_in_type;
      apb3o      : out apb3_slv_out_type;
      sf2apbin : out sf2_apb3_in_type;
      sf2apbout : in sf2_apb3_out_type);
end sf2mddr_wrapper;

architecture sf2mddr_wrapper_arch of sf2mddr_wrapper is

  constant REVISION : integer := 1;

  constant hconfig : ahb_config_type := (
    0 => ahb_device_reg (vendorid, deviceid, 0, REVISION, 0),
    1 => conv_std_logic_vector(pnpuser0, 32),
    4 => ahb_membar(haddr, '1', '1', hmask),
    others => zero32);

  constant pconfig : apb_config_type := (
    0 => ahb_device_reg (vendorid, deviceid, 0, REVISION, 0),
    1 => apb_iobar(paddr, pmask));

begin

  -- APB output assignment
  apb3o.pirq <= (others => '0');
  apb3o.pindex <= pindex;
  apb3o.pconfig <= pconfig;
  apb3o.prdata <= x"0000"&sf2apbout.prdata;
  apb3o.pready <= sf2apbout.pready;
  apb3o.pslverr <= sf2apbout.pslverr;

  -- SmartFusion2/IGLOO2 APB input assignment
  sf2apbin.paddr <= apb3i.paddr;
  sf2apbin.penable <= apb3i.penable;
  sf2apbin.psel <= apb3i.psel(pindex);
  sf2apbin.pwdata <= apb3i.pwdata(15 downto 0);
  sf2apbin.pwrite <= apb3i.pwrite;
  
  
  -- SmartFusion2/IGLOO2 slave input assignment
  comb: process(ahbsi)
    variable vhaddr : std_logic_vector(1 downto 0);
  begin
    --remap haddr for big endian AHB bus compliance
    vhaddr := ahbsi.haddr(1 downto 0);
    if (ahbsi.hsize=HSIZE_HWORD) then
      vhaddr := not(ahbsi.haddr(1))&'0'; -- swap half words
    elsif (ahbsi.hsize=HSIZE_BYTE) then
      vhaddr := not(ahbsi.haddr(1 downto 0)); -- swap bytes
    end if;

    sf2si.haddr <= std_logic_vector(not(to_unsigned(hmask,12)&x"00000") and (unsigned(ahbsi.haddr(31 downto 2))&unsigned(vhaddr)));
  end process;

  -- AHB slave input forwarding
  sf2si.hwrite <= ahbsi.hwrite;
  sf2si.hready <= ahbsi.hready;
  sf2si.hsize <= ahbsi.hsize(1 downto 0);
  sf2si.hburst <= ahbsi.hburst;
  sf2si.hmastlock <= ahbsi.hmastlock;
  sf2si.hwdata <= ahbsi.hwdata(31 downto 0);
  sf2si.htrans <= ahbsi.htrans;
  sf2si.hsel <= ahbsi.hsel(hindex);

  -- AHB slave output assignment
  ahbso.hready <= sf2so.hreadyout;
  ahbso.hresp <= '0'&sf2so.hresp;
  ahbso.hsplit <= (others => '0');
  ahbso.hconfig <= hconfig;
  ahbso.hirq <= (others => '0');
  ahbso.hindex <= hindex;
  ahbso.hrdata <= ahbdrivedata(sf2so.hrdata);

end sf2mddr_wrapper_arch;

