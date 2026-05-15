------------------------------------------------------------------------------
--  This file is a part of the GRLIB VHDL IP LIBRARY
--  Copyright (C) 2017, Cobham Gaisler AB - all rights reserved.
--
-- ANY USE OR REDISTRIBUTION IN PART OR IN WHOLE MUST BE HANDLED IN 
-- ACCORDANCE WITH THE GAISLER LICENSE AGREEMENT AND MUST BE APPROVED 
-- IN ADVANCE IN WRITING. 
-----------------------------------------------------------------------------
-- Entity:      ambamon
-- File:        ambamon.vhd
-- Author:      Marko Isomaki - Gaisler Research
-- Description: AMBA bus monitor that checks standard compliancy
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

library grlib;
use grlib.amba.all;
use grlib.stdlib.all;

entity ambamon is
  generic(
    asserterr   : integer range 0 to 1 := 1;
    assertwarn  : integer range 0 to 1 := 1;
    hmstdisable : integer := 0;
    hslvdisable : integer := 0;
    pslvdisable : integer := 0;
    arbdisable  : integer := 0;
    nahbm       : integer range 0 to NAHBMST := NAHBMST;
    nahbs       : integer range 0 to NAHBSLV := NAHBSLV;
    napb        : integer range 0 to NAPBSLV := NAPBSLV;
    ebterm      : integer range 0 to 1 := 0
  );
  port(
    rst         : in std_ulogic;
    clk         : in std_ulogic;
    ahbmi       : in ahb_mst_in_type;
    ahbmo       : in ahb_mst_out_vector;
    ahbsi       : in ahb_slv_in_type;
    ahbso       : in ahb_slv_out_vector;
    apbi        : in apb_slv_in_type;
    apbo        : in apb_slv_out_vector;
    err         : out std_ulogic);
end entity;

architecture beh of ambamon is
  signal ahberr : std_ulogic;
  signal apberr : std_ulogic;
begin
  ahb0 : ahbmon
    generic map(
      asserterr   => asserterr,
      assertwarn  => assertwarn,
      hmstdisable => hmstdisable,
      hslvdisable => hslvdisable,
      arbdisable  => arbdisable,
      nahbm       => nahbm,
      nahbs       => nahbs,
      ebterm      => ebterm)
    port map(
      rst         => rst,
      clk         => clk,
      ahbmi       => ahbmi,
      ahbmo       => ahbmo,
      ahbsi       => ahbsi,
      ahbso       => ahbso,
      err         => ahberr
    );

  apb0 : apbmon 
    generic map(
      asserterr     => asserterr,
      assertwarn    => assertwarn,
      pslvdisable   => pslvdisable,
      napb          => napb)
    port map (
      rst           => rst,
      clk           => clk,
      apbi          => apbi,
      apbo          => apbo,
      err           => apberr);

  err <= apberr or ahberr;
  
end architecture;









