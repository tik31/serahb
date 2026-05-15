------------------------------------------------------------------------------
--  This file is a part of the GRLIB VHDL IP LIBRARY
--  Copyright (C) 2017, Cobham Gaisler AB - all rights reserved.
--
-- ANY USE OR REDISTRIBUTION IN PART OR IN WHOLE MUST BE HANDLED IN 
-- ACCORDANCE WITH THE GAISLER LICENSE AGREEMENT AND MUST BE APPROVED 
-- IN ADVANCE IN WRITING. 
-----------------------------------------------------------------------------   
-- Entity:      ahbjtag
-- File:        ahbjtag.vhd
-- Author:      Edvin Catovic, Jiri Gaisler - Gaisler Research
-- Description: JTAG communication link with AHB master interface
------------------------------------------------------------------------------  

library ieee;
use ieee.std_logic_1164.all;
library grlib;
use grlib.amba.all;
use grlib.stdlib.all;
use grlib.devices.all;
library techmap;
use techmap.gencomp.all;
library gaisler;
use gaisler.libjtagcom.all;
use gaisler.jtag.all;

entity ahbjtag_bsd is
  generic (
    tech    : integer range 0 to NTECH := 0;
    hindex  : integer := 0;
    nsync : integer range 1 to 2 := 1;
    ainst   : integer range 0 to 255 := 2;
    dinst   : integer range 0 to 255 := 3);
  port (
    rst         : in  std_ulogic;
    clk         : in  std_ulogic;
    ahbi        : in  ahb_mst_in_type;
    ahbo        : out ahb_mst_out_type;
    asel        : in  std_ulogic;
    dsel        : in  std_ulogic;
    tck         : in  std_ulogic;
    regi        : in  std_ulogic;
    shift       : in std_ulogic;
    rego        : out  std_ulogic        
    );
end;      

architecture struct of ahbjtag_bsd is


-- Set REREAD to 1 to include support for re-read operation when host reads
-- out data register before jtagcom has completed the current AMBA access and
-- returned to state 'shft'.
constant REREAD : integer := 1;

constant REVISION : integer := REREAD;

signal dmai : ahb_dma_in_type;
signal dmao : ahb_dma_out_type;
signal ltapi : tap_in_type;
signal ltapo : tap_out_type;
signal trst: std_ulogic;

begin
  
  ahbmst0 : ahbmst 
    generic map (hindex => hindex, venid => VENDOR_GAISLER, devid => GAISLER_AHBJTAG, version => REVISION)
    port map (rst, clk, dmai, dmao, ahbi, ahbo);
  
  jtagcom0 : jtagcom generic map (isel => 1, nsync => nsync, ainst => ainst, dinst => dinst, reread => REREAD)
    port map (rst, clk, ltapo, ltapi, dmao, dmai, tck, trst);

  ltapo.asel  <= asel;
  ltapo.dsel  <= dsel;
  ltapo.tck   <= tck;
  ltapo.tdi   <= regi;
  ltapo.shift <= shift;
  ltapo.reset <= '0';
  ltapo.inst  <= (others => '0');
  rego <= ltapi.tdo;
  trst <= '1';
  
-- pragma translate_off
    bootmsg : report_version 
    generic map ("ahbjtag AHB Debug JTAG rev " & tost(REVISION));
-- pragma translate_on

end;

