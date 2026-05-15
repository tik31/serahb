------------------------------------------------------------------------------
--  This file is a part of the GRLIB VHDL IP LIBRARY
--  Copyright (C) 2017, Cobham Gaisler AB - all rights reserved.
--
-- ANY USE OR REDISTRIBUTION IN PART OR IN WHOLE MUST BE HANDLED IN 
-- ACCORDANCE WITH THE GAISLER LICENSE AGREEMENT AND MUST BE APPROVED 
-- IN ADVANCE IN WRITING. 
-----------------------------------------------------------------------------
-- Entity: 	outpad_ddr, outpad_ddrv
-- File:	outpad_ddr.vhd
-- Author:	Jan Andersson - Aeroflex Gaisler
-- Description:	Wrapper that instantiates a DDR register connected to an
--              output pad. The generic tech wrappers are not used for nextreme
--              since this technology requires that the output enable signal is
--              connected between the DDR register and the pad.
------------------------------------------------------------------------------

library techmap;
library ieee;
use ieee.std_logic_1164.all;
use techmap.gencomp.all;
use techmap.allddr.all;
use techmap.allpads.all;

entity outpad_ddr is
  generic (
    tech     : integer := 0;
    level    : integer := 0;
    slew     : integer := 0;
    voltage  : integer := x33v;
    strength : integer := 12
    );
  port (
    pad    : out std_ulogic;
    i1, i2 : in  std_ulogic;
    c1, c2 : in  std_ulogic;
    ce     : in  std_ulogic;
    r      : in  std_ulogic;
    s      : in  std_ulogic
    );
end; 

architecture rtl of outpad_ddr is
signal q, oe, vcc : std_ulogic;
begin
  vcc <= '1';
  
  def: if (tech /= easic90) and (tech /= easic45) generate
    ddrreg : ddr_oreg generic map (tech)
      port map (q, c1, c2, ce, i1, i2, r, s);
    p : outpad generic map (tech, level, slew, voltage, strength)
      port map (pad, q);
    oe <= '0';
  end generate def;

  nex  : if (tech = easic90) generate
    ddrreg : nextreme_oddr_reg
      port map (ck => c1, dh => i1, dl => i2, doe => vcc, q => q, oe => oe, rstb => r);
    p : nextreme_toutpad generic map (level, slew, voltage, strength)
      port map(pad, q, oe);
  end generate;

  n2x : if (tech = easic45) generate
--    ddrpad : n2x_outpad_ddr  generic map (level, slew, voltage, strength)
--      port map ();
--pragma translate_off
    assert false report "outpad_ddr: Not yet supported on Nextreme2"
      severity failure;
--pragma translate_on
    q <= '0'; oe <= '0';
  end generate;
  
end;

library techmap;
library ieee;
use ieee.std_logic_1164.all;
use techmap.gencomp.all;

entity outpad_ddrv is
  generic (
    tech     : integer := 0;
    level    : integer := 0;
    slew     : integer := 0;
    voltage  : integer := 0;
    strength : integer := 12;
    width    : integer := 1
    );
  port (
    pad    : out std_logic_vector(width-1 downto 0); 
    i1, i2 : in  std_logic_vector(width-1 downto 0);
    c1, c2 : in  std_ulogic;
    ce     : in  std_ulogic;
    r      : in  std_ulogic;
    s      : in  std_ulogic
    );
end; 
architecture rtl of outpad_ddrv is
begin
  v : for j in width-1 downto 0 generate
    x0 : outpad_ddr generic map (tech, level, slew, voltage, strength) 
	 port map (pad(j), i1(j), i2(j), c1, c2, ce, r, s);
  end generate;
end;

