------------------------------------------------------------------------------
--  This file is a part of the GRLIB VHDL IP LIBRARY
--  Copyright (C) 2017, Cobham Gaisler AB - all rights reserved.
--
-- ANY USE OR REDISTRIBUTION IN PART OR IN WHOLE MUST BE HANDLED IN 
-- ACCORDANCE WITH THE GAISLER LICENSE AGREEMENT AND MUST BE APPROVED 
-- IN ADVANCE IN WRITING. 
----------------------------------------------------------------------------   
-- Entity:      ahbbridge
-- File:        ahbbridge.vhd
-- Author:      Edvin Catovic, Gaisler Research
-- Modified:    Jan Andersson, Aeroflex Gaisler
-- Description: AHB to AHB bridge (bi-directional)
------------------------------------------------------------------------------ 

library IEEE;
use IEEE.std_logic_1164.all;
library grlib;
use grlib.stdlib.all;
use grlib.amba.all;
use grlib.devices.all;
library gaisler;
use gaisler.misc.all;
library techmap;
use techmap.gencomp.all;

entity ahbbridge is
  generic(
    memtech     : integer := 0;
    ffact       : integer range 0 to 15 := 2;
    -- high-speed bus    
    hsb_hsindex : integer := 0;
    hsb_hmindex : integer := 0;
    hsb_iclsize : integer range 4 to 8 := 8;
    hsb_bank0   : integer range 0 to 1073741823 := 0;
    hsb_bank1   : integer range 0 to 1073741823 := 0;
    hsb_bank2   : integer range 0 to 1073741823 := 0;
    hsb_bank3   : integer range 0 to 1073741823 := 0;
    hsb_ioarea  : integer := 0;
    -- low-speed bus
    lsb_hsindex : integer := 0;
    lsb_hmindex : integer := 0;
    lsb_rburst  : integer range 16 to 32 := 16;
    lsb_wburst  : integer range 2 to 32 :=  8;
    lsb_bank0   : integer range 0 to 1073741823 := 0;
    lsb_bank1   : integer range 0 to 1073741823 := 0;
    lsb_bank2   : integer range 0 to 1073741823 := 0;
    lsb_bank3   : integer range 0 to 1073741823 := 0;
    lsb_ioarea  : integer := 0;
    --
    lckdac      : integer range 0 to 2 := 2;
    maccsz      : integer range 32 to 256 := 32;
    rdcomb      : integer range 0 to 2 := 0;
    wrcomb      : integer range 0 to 4 := 0;
    combmask    : integer := 16#ffff#;
    allbrst     : integer range 0 to 2 := 0;
    fcfs        : integer range 0 to NAHBMST := 0;
    scantest    : integer range 0 to 1 := 0);
  port (
    rstn        : in  std_ulogic;    
    hsb_clk     : in  std_ulogic;
    lsb_clk     : in  std_ulogic;
    hsb_ahbsi   : in  ahb_slv_in_type;
    hsb_ahbso   : out ahb_slv_out_type;
    hsb_ahbsov  : in  ahb_slv_out_vector;
    hsb_ahbmi   : in  ahb_mst_in_type;
    hsb_ahbmo   : out ahb_mst_out_type;
    lsb_ahbsi   : in  ahb_slv_in_type;
    lsb_ahbso   : out ahb_slv_out_type;
    lsb_ahbsov  : in  ahb_slv_out_vector;
    lsb_ahbmi   : in  ahb_mst_in_type;
    lsb_ahbmo   : out ahb_mst_out_type);
end;



architecture rtl of ahbbridge is
  
  signal lock, nolock : ahb2ahb_ctrl_type;
  signal noifctrl     : ahb2ahb_ifctrl_type;
  
begin

  -- down bridge
  --
  -- if ffact is 1 the down bridge will be marked as an
  -- UP bridge in AMBA PnP
  --
  ahb2ahb0 : ahb2ahb generic map (
    hsindex     => hsb_hsindex,
    hmindex     => lsb_hmindex,
    dir         => 1/ffact,
    slv         => 0,
    ffact       => ffact,
    memtech     => memtech,
    pfen        => 1,
    irqsync     => 1,
    wburst      => 2,    
    iburst      => hsb_iclsize, 
    rburst      => 2,  
    bar0        => lsb_bank0,
    bar1        => lsb_bank1,
    bar2        => lsb_bank2,
    bar3        => lsb_bank3,    
    sbus        => 0,
    mbus        => 1,
    ioarea      => lsb_ioarea,
    ibrsten     => 1,
    lckdac      => lckdac,
    slvmaccsz   => maccsz,
    mstmaccsz   => maccsz,
    rdcomb      => rdcomb,
    wrcomb      => wrcomb,
    combmask    => combmask,
    allbrst     => allbrst,
    ifctrlen    => 0,
    fcfs        => fcfs,
    fcfsmtech   => 0,
    scantest    => scantest,
    split       => 1)
  port map (
    hclkm  => lsb_clk,
    hclks  => hsb_clk,
    rstn   => rstn, 
    ahbsi  => hsb_ahbsi, 
    ahbso  => hsb_ahbso,
    ahbmi  => lsb_ahbmi, 
    ahbmo  => lsb_ahbmo,
    ahbso2 => lsb_ahbsov,
    lcki   => nolock,
    lcko   => lock,
    ifctrl => noifctrl);


  ahb2ahb1 : ahb2ahb generic map (
    hsindex     => lsb_hsindex,
    hmindex     => hsb_hmindex,
    dir         => 1,
    slv         => 1,
    ffact       => ffact,
    memtech     => memtech,
    pfen        => 1,
    irqsync     => 0,
    wburst      => lsb_wburst,
    rburst      => lsb_rburst,
    bar0        => hsb_bank0,
    bar1        => hsb_bank1,
    bar2        => hsb_bank2,
    bar3        => hsb_bank3,        
    sbus        => 1,
    mbus        => 0,
    ioarea      => hsb_ioarea,
    ibrsten     => 0,
    lckdac      => lckdac,
    slvmaccsz   => maccsz,
    mstmaccsz   => maccsz,
    rdcomb      => rdcomb,
    wrcomb      => wrcomb,
    combmask    => combmask,
    allbrst     => allbrst,
    ifctrlen    => 0,
    fcfs        => fcfs,
    fcfsmtech   => 0,
    scantest    => scantest,
    split       => 1)
  port map (
    hclkm  => hsb_clk,
    hclks  => lsb_clk,
    rstn   => rstn, 
    ahbsi  => lsb_ahbsi, 
    ahbso  => lsb_ahbso,
    ahbmi  => hsb_ahbmi, 
    ahbmo  => hsb_ahbmo,
    ahbso2 => hsb_ahbsov,
    lcki   => lock, 
    lcko   => open,
    ifctrl => noifctrl);

  nolock <= ahb2ahb_ctrl_none;
  noifctrl <= ahb2ahb_ifctrl_none;
  
end;  

