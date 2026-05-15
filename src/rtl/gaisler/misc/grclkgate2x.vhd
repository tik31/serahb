------------------------------------------------------------------------------
--  This file is a part of the GRLIB VHDL IP LIBRARY
--  Copyright (C) 2017, Cobham Gaisler AB - all rights reserved.
--
-- ANY USE OR REDISTRIBUTION IN PART OR IN WHOLE MUST BE HANDLED IN 
-- ACCORDANCE WITH THE GAISLER LICENSE AGREEMENT AND MUST BE APPROVED 
-- IN ADVANCE IN WRITING. 
-----------------------------------------------------------------------------
-- Entity:      grclkgate2x
-- File:        grclkgate2x.vhd
-- Author:      Jiri Gaisler - Gaisler Research
-- Modified:    Jan Andersson - Aeroflex Gaisler
-- Description: Clock gate unit used:
--              .. in systems with dedicated FPUs (fpush = 0)
--              .. in systems with one shared FPU (fpush = 1)
--              .. in systems with one FPU shared between pairs of CPUs
--                 (fpush = 2)
--              .. in systems with dedicated FPUs and separate fpu clocks
--                 (fpush = 0, fpuclken = 1)
--              that requires LEON double clocking. If clk2xen generic is zero
--              then behaviour should be the same as for standard grclkgate.
--              Note, however, that the GRCLKGATE does not support dedicated
--              FPU and separate FPU clocks.
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

--pragma translate_off
use std.textio.all;
--pragma translate_on

entity grclkgate2x is
  generic (
    tech     : integer := 0;
    pindex   : integer := 0;
    paddr    : integer := 0;
    pmask    : integer := 16#fff#;
    ncpu     : integer := 1;
    nclks    : integer := 8;
    emask    : integer := 0;
    extemask : integer := 0;
    scantest : integer := 0;
    edges    : integer := 0; -- Extra edges after reset complete,
                             -- CPU gets #+3 rising eges out of reset
                             -- other cores #+1 rising edges.
    noinv    : integer := 0; -- Do not use inverted clock on gate enable
    fpush    : integer range 0 to 2 := 0;
    clk2xen  : integer := 0;             -- Enable double clocking
    ungateen : integer := 0; -- Use extra ungate signal for test modes
    fpuclken : integer range 0 to 1 := 0;  -- enable separate clocks for FPU.
                                           -- requires that fpush = 0
    nahbclk  : integer := 1;
    nahbclk2x : integer := 1;
    balance   : integer range 1 to 1 := 1
  );
  port (
    rst      : in  std_ulogic;
    clkin    : in  std_ulogic;
    clkin2x  : in  std_ulogic;
    pwd      : in  std_logic_vector(ncpu-1 downto 0);
    fpen     : in  std_logic_vector(ncpu-1 downto 0);
    apbi     : in  apb_slv_in_type;
    apbo     : out apb_slv_out_type;
    gclk     : out std_logic_vector(nclks-1 downto 0);
    reset    : out std_logic_vector(nclks-1 downto 0);
    clkahb   : out std_logic_vector(nahbclk-1 downto 0);
    clkahb2x : out std_logic_vector(nahbclk2x-1 downto 0);
    clkcpu   : out std_logic_vector(ncpu-1 downto 0);
    enable   : out std_logic_vector(nclks-1 downto 0);
    clkfpu   : out std_logic_vector((fpush/2+fpuclken)*(ncpu/(2-fpuclken)-1) downto 0);
    epwen    : in  std_logic_vector(nclks-1 downto 0);
    ungate   : in  std_ulogic
  );
end;

architecture rtl of grclkgate2x is

begin

  grcgx : grclkgatex
    generic map (
      tech      => tech,
      pindex    => pindex,
      paddr     => paddr,
      pmask     => pmask,
      ncpu      => ncpu,
      nclks     => nclks,
      emask     => emask,
      extemask  => extemask,
      scantest  => scantest,
      edges     => edges,
      noinv     => noinv,
      fpush     => fpush,
      clk2xen   => clk2xen,
      ungateen  => ungateen,
      fpuclken  => fpuclken,
      nahbclk   => nahbclk,
      nahbclk2x => nahbclk2x,
      balance   => balance)
    port map (
      rst      => rst,
      clkin    => clkin,
      clkin2x  => clkin2x,
      pwd      => pwd,
      fpen     => fpen,
      apbi     => apbi,
      apbo     => apbo,
      gclk     => gclk,
      reset    => reset,
      clkahb   => open,
      clkahb2x => open,
      clkcpu   => clkcpu,
      enable   => enable,
      clkfpu   => clkfpu,
      epwen    => epwen,
      ungate   => ungate,
      clkahbv  => clkahb,
      clkahb2xv => clkahb2x);

end;

