------------------------------------------------------------------------------
--  This file is a part of the GRLIB VHDL IP LIBRARY
--  Copyright (C) 2017, Cobham Gaisler AB - all rights reserved.
--
-- ANY USE OR REDISTRIBUTION IN PART OR IN WHOLE MUST BE HANDLED IN 
-- ACCORDANCE WITH THE GAISLER LICENSE AGREEMENT AND MUST BE APPROVED 
-- IN ADVANCE IN WRITING. 
-----------------------------------------------------------------------------
-- Entity:        sf2apb3slv_wrapper
-- File:          sf2apb3slv_wrapper.vhd
-- Author:        Pascal Trotta
-- Description:   APB3 slave wrapper for SmartFusion2/IGLOO2 SERDES module generated in Libero SoC.
--                APB3 slave input signals not used: pirq, testen, testrst, scanen, testoen, testin.
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
library grlib;
use grlib.amba.all;
use grlib.devices.all;
use grlib.stdlib.all;
library techmap;
use techmap.gencomp.all;
library gaisler;
use gaisler.misc.all;

entity sf2apb3slv_wrapper is
  generic(
    pindex    : integer := 13;
    paddr     : integer := 13;
    pmask     : integer := 16#FF8#;
    vendorid  : integer := VENDOR_ACTEL; 
    deviceid  : integer := ACTEL_APB3SLV);
  port(
  	rstn      : in  std_ulogic;
    clk       : in  std_ulogic;
    apb3i      : in  apb3_slv_in_type;
    apb3o      : out apb3_slv_out_type;
    sf2apbin  : out apb_in_serdes;
    sf2apbout : in apb_out_serdes);
end sf2apb3slv_wrapper;

architecture sf2apb3slv_wrapper_rtl of sf2apb3slv_wrapper is

  constant REVISION : integer := 1;

  constant pconfig : apb_config_type := (
    0 => ahb_device_reg (vendorid, deviceid, 0, REVISION, 0),
    1 => apb_iobar(paddr, pmask));

begin

  -- APB3 output assignment
  apb3o.pirq <= (others => '0');
  apb3o.pindex <= pindex;
  apb3o.pconfig <= pconfig;
  apb3o.prdata <= sf2apbout.prdata;
  apb3o.pready <= sf2apbout.pready;
  apb3o.pslverr <= sf2apbout.pslverr;

  -- SmartFusion2/IGLOO2 APB3 input assignment
  sf2apbin.paddr <= apb3i.paddr(14 downto 2);
  sf2apbin.penable <= apb3i.penable;
  sf2apbin.psel <= apb3i.psel(pindex);
  sf2apbin.pwdata <= apb3i.pwdata;
  sf2apbin.pwrite <= apb3i.pwrite;
  sf2apbin.pclk <= clk;
  sf2apbin.prstn <= rstn;

end sf2apb3slv_wrapper_rtl;

