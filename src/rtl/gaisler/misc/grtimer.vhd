------------------------------------------------------------------------------
--  This file is a part of the GRLIB VHDL IP LIBRARY
--  Copyright (C) 2017, Cobham Gaisler AB - all rights reserved.
--
-- ANY USE OR REDISTRIBUTION IN PART OR IN WHOLE MUST BE HANDLED IN 
-- ACCORDANCE WITH THE GAISLER LICENSE AGREEMENT AND MUST BE APPROVED 
-- IN ADVANCE IN WRITING. 
-----------------------------------------------------------------------------
-- Entity:      grtimer
-- File:        grtimer.vhd
-- Author:      Aeroflex Gaisler AB
-- Description: GRTIMER functionality has been merged into GPTIMER
--
-- This entity is a wrapper that overrides the PnP information
--
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
library grlib;
use grlib.amba.all;
use grlib.devices.all;
library gaisler;
use gaisler.misc.all;

entity grtimer is
  generic (
    pindex   : integer := 0;
    paddr    : integer := 0;
    pmask    : integer := 16#fff#;
    pirq     : integer := 0;
    sepirq   : integer := 0;    -- use separate interrupts for each timer
    sbits    : integer := 16;                   -- scaler bits
    ntimers  : integer range 1 to 7 := 1;       -- number of timers
    nbits    : integer := 32;                   -- timer bits
    wdog     : integer := 0;
    glatch   : integer := 0;
    gextclk  : integer := 0;
    gset     : integer := 0
  );
  port (
    rst    : in  std_ulogic;
    clk    : in  std_ulogic;
    apbi   : in  apb_slv_in_type;
    apbo   : out apb_slv_out_type;
    gpti   : in  gptimer_in_type;
    gpto   : out gptimer_out_type
  );
end;

architecture rtl of grtimer is

  constant REVISION : integer := 2;

  constant pconfig : apb_config_type := (
    0 => ahb_device_reg (VENDOR_GAISLER, GAISLER_GRTIMER, 0, REVISION, pirq),
    1 => apb_iobar(paddr, pmask));

  signal apbox : apb_slv_out_type;
  
begin

  gpt0 : gptimer
    generic map (
      pindex   => pindex,
      paddr    => paddr,
      pmask    => pmask,
      pirq     => pirq,
      sepirq   => sepirq,
      sbits    => sbits,
      ntimers  => ntimers,
      nbits    => nbits,
      wdog     => wdog,
      ewdogen  => 0,
      glatch   => glatch,
      gextclk  => gextclk,
      gset     => gset,
      gelatch  => 0)
    port map (rst, clk, apbi, apbox, gpti, gpto);

  pnpoverride : process(apbox)
  begin
    apbo <= apbox; apbo.pconfig <= pconfig;
  end process pnpoverride;

end;

