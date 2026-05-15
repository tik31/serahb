------------------------------------------------------------------------------
--  This file is a part of the GRLIB VHDL IP LIBRARY
--  Copyright (C) 2017, Cobham Gaisler AB - all rights reserved.
--
-- ANY USE OR REDISTRIBUTION IN PART OR IN WHOLE MUST BE HANDLED IN 
-- ACCORDANCE WITH THE GAISLER LICENSE AGREEMENT AND MUST BE APPROVED 
-- IN ADVANCE IN WRITING. 
-----------------------------------------------------------------------------
-- Entity:        sf2ficslv_wrapper
-- File:          sf2ficslv_wrapper.vhd
-- Author:        Pascal Trotta
-- Description:   AHB slave wrapper for SmartFusion2/IGLOO2 FIC interfaces.
--                AHB slave input signals not used: hmaster, hirq, testen, testrst,
--                scanen, testoen, testin 
-- Limitations:   Support only 32-bit wide bus
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library grlib;
use grlib.amba.all;
use grlib.devices.all;
use grlib.stdlib.all;
library gaisler;
use gaisler.misc.all;

entity sf2ficslv_wrapper is
  generic (
    hindex     : integer := 0;
    haddr1     : integer := 16#500#; -- eSRAM mapped at 0x50000000
    hmask1     : integer := 16#FFF#; -- 1 MB (actually 64 or 80 KB depending on SECDED ON/OFF)
    haddr2     : integer := 16#000#; -- eNVM mapped at 0x00000000
    hmask2     : integer := 16#FFF#; -- 1 MB (actually 512 KB)
    haddr3     : integer := 16#600#; -- eNVM configuration registers mapped at 0x60000000
    hmask3     : integer := 16#FFF#; -- 1 MB (actually 512 KB)
    haddr4     : integer := 16#000#; -- Subsystem peripherals mapped at 0xFFF00000
    hmask4     : integer := 16#800#; -- 512 KB
    vendorid  : integer := VENDOR_ACTEL; 
    deviceid  : integer := ACTEL_FICSLV);
  port (
    rstn      : in  std_ulogic;
    clk       : in  std_ulogic;
    ahbsi     : in  ahb_slv_in_type;
    ahbso     : out ahb_slv_out_type;
    sf2si     : out sf2_slv_in_type;
    sf2so     : in  sf2_slv_out_type);
end sf2ficslv_wrapper;

architecture sf2ficslv_wrapper_rtl of sf2ficslv_wrapper is

  constant REVISION : integer := 1;

  constant hconfig : ahb_config_type := (
    0 => ahb_device_reg (vendorid, deviceid, 0, REVISION, 0),
    4 => ahb_membar(haddr1, '1', '1', hmask1),
    5 => ahb_membar(haddr2, '1', '1', hmask2),
    6 => ahb_membar(haddr3, '0', '0', hmask3),
    7 => ahb_iobar(haddr4, hmask4),
    others => zero32);

begin

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

    -- Map haddr depending on the actual selection
    if (ahbsi.hmbsel(0)='1') then -- eSRAM selected
      sf2si.haddr <= x"200"&"000"&ahbsi.haddr(16 downto 2)&vhaddr;
    elsif (ahbsi.hmbsel(1)='1') then -- eNVM selected
      sf2si.haddr <= x"600"&'0'&ahbsi.haddr(18 downto 2)&vhaddr;
    elsif (ahbsi.hmbsel(2)='1') then -- eNVM configuration registers selected
      sf2si.haddr <= x"600"&ahbsi.haddr(19 downto 2)&vhaddr;
    else
      sf2si.haddr <= x"400"&'0'&ahbsi.haddr(18 downto 2)&vhaddr;
    end if;

  end process;

  -- AHB slave input forwarding
  sf2si.hwrite <= ahbsi.hwrite;
  sf2si.hsize <= ahbsi.hsize(1 downto 0);
  sf2si.hburst <= ahbsi.hburst;
  sf2si.hmastlock <= ahbsi.hmastlock;
  sf2si.hwdata <= ahbsi.hwdata(31 downto 0);
  sf2si.htrans <= ahbsi.htrans;
  sf2si.hsel <= ahbsi.hsel(hindex);
  sf2si.hready <= ahbsi.hready;

  -- AHB slave output assignment
  ahbso.hrdata <= ahbdrivedata(sf2so.hrdata);
  ahbso.hready <= sf2so.hreadyout;
  ahbso.hresp <= '0'&sf2so.hresp;
  ahbso.hsplit <= (others => '0');
  ahbso.hconfig <= hconfig;
  ahbso.hirq <= (others => '0');
  ahbso.hindex <= hindex;

end sf2ficslv_wrapper_rtl;

