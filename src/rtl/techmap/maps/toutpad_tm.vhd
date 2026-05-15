------------------------------------------------------------------------------
--  This file is a part of the GRLIB VHDL IP LIBRARY
--  Copyright (C) 2017, Cobham Gaisler AB - all rights reserved.
--
-- ANY USE OR REDISTRIBUTION IN PART OR IN WHOLE MUST BE HANDLED IN 
-- ACCORDANCE WITH THE GAISLER LICENSE AGREEMENT AND MUST BE APPROVED 
-- IN ADVANCE IN WRITING. 
-----------------------------------------------------------------------------
-- Entity:      toutpad_tm, toutpad_tmvv
-- File:        toutpad_tm.vhd
-- Author:      Magnus Hjorth - Aeroflex Gaisler
-- Description: Tech map for IO pad with built-in test mux
------------------------------------------------------------------------------

-- This is implemented recursively by passing in the test signals via the cfgi
-- input for technologies that support it, and muxing manually for others.

library ieee;
use ieee.std_logic_1164.all;
library techmap;
use techmap.gencomp.all;
use techmap.allpads.all;

entity toutpad_tm is
  generic (tech : integer := 0; level : integer := 0; slew : integer := 0;
           voltage : integer := x33v; strength : integer := 12;
           oepol : integer := 0);
  port (pad : out std_ulogic; i, en : in std_ulogic;
        test: in std_ulogic; ti,ten : in std_ulogic;
        cfgi: in std_logic_vector(19 downto 0) := "00000000000000000000");
end;

architecture rtl of toutpad_tm is
  signal mi,men: std_ulogic;
  signal mcfgi: std_logic_vector(19 downto 0);
begin

  notm: if has_tm_pads(tech)=0 generate
    mi <= ti when test='1' else i;
    men <= ten when test='1' else en;
    mcfgi <= cfgi;
  end generate;

  hastm: if has_tm_pads(tech)/=0 generate
    mi <= i;
    men <= en;
    mcfgi <= cfgi(19 downto 3) & ti & ten & test;
  end generate;

  p: toutpad
    generic map (tech => tech, level => level, slew => slew,
                 voltage => voltage, strength => strength,
                 oepol => oepol)
    port map (pad => pad, i => mi, en => men, cfgi => mcfgi);

end;



library techmap;
library ieee;
use ieee.std_logic_1164.all;
use techmap.gencomp.all;

entity toutpad_tmvv is
  generic (tech : integer := 0; level : integer := 0; slew : integer := 0;
        voltage : integer := x33v; strength : integer := 12; width : integer := 1;
        oepol : integer := 0);
  port (
    pad : out std_logic_vector(width-1 downto 0);
    i   : in  std_logic_vector(width-1 downto 0);
    en  : in  std_logic_vector(width-1 downto 0);
    test: in  std_ulogic;
    ti  : in  std_logic_vector(width-1 downto 0);
    ten : in  std_logic_vector(width-1 downto 0);
    cfgi: in std_logic_vector(19 downto 0) := "00000000000000000000");
end;
architecture rtl of toutpad_tmvv is
begin
  v : for j in width-1 downto 0 generate
    x0 : toutpad_tm generic map (tech, level, slew, voltage, strength, oepol)
         port map (pad(j), i(j), en(j), test, ti(j), ten(j), cfgi);
  end generate;
end;

