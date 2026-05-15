------------------------------------------------------------------------------
--  This file is a part of the GRLIB VHDL IP LIBRARY
--  Copyright (C) 2017, Cobham Gaisler AB - all rights reserved.
--
-- ANY USE OR REDISTRIBUTION IN PART OR IN WHOLE MUST BE HANDLED IN 
-- ACCORDANCE WITH THE GAISLER LICENSE AGREEMENT AND MUST BE APPROVED 
-- IN ADVANCE IN WRITING. 
-----------------------------------------------------------------------------
-- Entity: 	ahbtrace
-- File:	ahbtrace.vhd
-- Author:	Jiri Gaisler - Gaisler Research
-- Description:	AHB trace unit
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
use gaisler.misc.all;

entity ahbtrace is
  generic (
    hindex   : integer := 0;
    ioaddr   : integer := 16#000#;
    iomask   : integer := 16#E00#;
    tech     : integer := DEFMEMTECH; 
    irq      : integer := 0; 
    kbytes   : integer := 1;
    bwidth   : integer := 32;
    ahbfilt  : integer := 0;
    scantest : integer range 0 to 1 := 0;
    exttimer : integer range 0 to 1 := 0;
    exten    : integer range 0 to 1 := 0);
  port (
    rst      : in  std_ulogic;
    clk      : in  std_ulogic;
    ahbmi    : in  ahb_mst_in_type;
    ahbsi    : in  ahb_slv_in_type;
    ahbso    : out ahb_slv_out_type;
    timer    : in  std_logic_vector(30 downto 0) := (others => '0');
    astat    : out amba_stat_type;
    resen    : in  std_ulogic := '0'
  );
end; 

architecture rtl of ahbtrace is

begin

  ahbt0 : ahbtrace_mb
    generic map (
      hindex   => hindex,
      ioaddr   => ioaddr,
      iomask   => iomask,
      tech     => tech,
      irq      => irq,
      kbytes   => kbytes,
      bwidth   => bwidth,
      ahbfilt  => ahbfilt,
      scantest => scantest,
      exttimer => exttimer,
      exten    => exten)
    port map(
      rst      => rst,
      clk      => clk,
      ahbsi    => ahbsi,
      ahbso    => ahbso,
      tahbmi   => ahbmi,
      tahbsi   => ahbsi,
      timer    => timer,
      astat    => astat,
      resen    => resen);
  
end;

