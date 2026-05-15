------------------------------------------------------------------------------
--  This file is a part of the GRLIB VHDL IP LIBRARY
--  Copyright (C) 2017, Cobham Gaisler AB - all rights reserved.
--
-- ANY USE OR REDISTRIBUTION IN PART OR IN WHOLE MUST BE HANDLED IN 
-- ACCORDANCE WITH THE GAISLER LICENSE AGREEMENT AND MUST BE APPROVED 
-- IN ADVANCE IN WRITING. 
-----------------------------------------------------------------------------
-- Entity:      ftahbram
-- File:        ftahbram.vhd
-- Author:      Cobham Gaisler AB
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
use grlib.ftlib.all;
use gaisler.misc.all;

entity ftahbram is
  generic (
    hindex    : integer := 0;
    haddr     : integer := 0;
    hmask     : integer := 16#fff#;
    tech      : integer := DEFMEMTECH; 
    kbytes    : integer := 1;
    pindex    : integer := 0;
    paddr     : integer := 0;
    pmask     : integer := 16#fff#;
    edacen    : integer range 0 to 3 := 1;  --enable EDAC
    autoscrub : integer range 0 to 1 := 0;  --enable auto-scrubbing    
    errcnten  : integer range 0 to 1 := 0;  --enable error counter in stat.reg
    cntbits   : integer range 1 to 8 := 1; --errcnt size in bits
    ahbpipe   : integer range 0 to 1 := 0;
    testen    : integer := 0);
  port (
    rst     : in  std_ulogic;
    clk     : in  std_ulogic;
    ahbsi   : in  ahb_slv_in_type;
    ahbso   : out ahb_slv_out_type;
    apbi    : in  apb_slv_in_type;
    apbo    : out apb_slv_out_type;
    aramo   : out ahbram_out_type
  );
end;

architecture rtl of ftahbram is

begin

  nopipe : if ahbpipe = 0 generate
    v1 : ftahbram1
      generic map (hindex, haddr, hmask, tech, kbytes, pindex, paddr, pmask,
                   edacen, autoscrub, errcnten, cntbits, ahbpipe, testen)
      port map (rst, clk, ahbsi, ahbso, apbi, apbo, aramo);
  end generate;

  pipe : if ahbpipe /= 0 generate
    v2 : ftahbram2
      generic map (hindex, haddr, hmask, tech, kbytes, pindex, paddr, pmask, testen,
                   edacen)
      port map (rst, clk, ahbsi, ahbso, apbi, apbo, aramo);
--pragma translate_off
    gencheck : process
  begin
    assert autoscrub = 0 report "FTAHBRAM: autoscrub /= cannot be used with ahbpipe /= 0"
      severity failure;
    wait;
    assert edacen /= 0 report "FTAHBRAM: edac is always suppored with ahbpipe /= 0"
      severity note;
    assert errcnten /= 0 report "FTAHBRAM: error counter is always enabled with ahbpipe /= 0"
      severity note;
    wait;
    assert edacen /= 2 report "FTAHBRAM: ahbpipe /= 0 and edacen = 2 is currently unsupported"
      severity note;
    wait;
  end process;
--pragma translate_on
  end generate;

end;
