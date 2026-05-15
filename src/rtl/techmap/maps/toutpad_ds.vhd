------------------------------------------------------------------------------
--  This file is a part of the GRLIB VHDL IP LIBRARY
--  Copyright (C) 2017, Cobham Gaisler AB - all rights reserved.
--
-- ANY USE OR REDISTRIBUTION IN PART OR IN WHOLE MUST BE HANDLED IN 
-- ACCORDANCE WITH THE GAISLER LICENSE AGREEMENT AND MUST BE APPROVED 
-- IN ADVANCE IN WRITING. 
-----------------------------------------------------------------------------
-- Entity: 	toutpad_ds
-- File:	toutpad_ds.vhd
-- Author:	Jonas Ekergarn - Aeroflex Gaisler
-- Description:	tri-state differential output pad with technology wrapper
------------------------------------------------------------------------------

library techmap;
library ieee;
use ieee.std_logic_1164.all;
use techmap.gencomp.all;
use techmap.allpads.all;

entity toutpad_ds is
  generic (tech : integer := 0; level : integer := 0; slew : integer := 0;
	   voltage : integer := x33v; strength : integer := 12;
	   oepol : integer := 0);
  port (padp, padn : out std_ulogic; i, en : in std_ulogic);
end;

architecture rtl of toutpad_ds is
signal oen : std_ulogic;
signal padx, gnd : std_ulogic;
begin
  gnd <= '0';
  oen <= not en when oepol /= padoen_polarity(tech) else en;
  gen0 : if has_ds_pads(tech) = 0 or (is_unisim(tech) = 1) or
           tech = axcel or tech = axdsp or tech = rhlib18t or
           tech = ut25 or tech = ut130 
           generate
    padp <= i 
-- pragma translate_off
	after 2 ns 
-- pragma translate_on
	when oen = '0'
-- pragma translate_off
           else 'X' after 2 ns when is_x(en)
-- pragma translate_on
           else 'Z' 
-- pragma translate_off
	after 2 ns
-- pragma translate_on
	;
    padn <= not i 
-- pragma translate_off
	after 2 ns 
-- pragma translate_on
	when oen = '0'
-- pragma translate_off
           else 'X' after 2 ns when is_x(en)
-- pragma translate_on
           else 'Z' 
-- pragma translate_off
	after 2 ns
-- pragma translate_on
	;
  end generate;
  pa3 : if (tech = apa3) generate
    u0 : apa3_toutpad_ds generic map (level)
      port map (padp, padn, i, oen);
  end generate;
  pa3e : if (tech = apa3e) generate
    u0 : apa3e_toutpad_ds generic map (level)
      port map (padp, padn, i, oen);
  end generate;
  igl2 : if (tech = igloo2) or (tech = rtg4) generate
    u0 : igloo2_toutpad_ds port map (padp, padn, i, oen);
  end generate;
  pa3l : if (tech = apa3l) generate
    u0 : apa3l_toutpad_ds generic map (level)
      port map (padp, padn, i, oen);
  end generate;
  fus : if (tech = actfus) generate
    u0 : fusion_toutpad_ds generic map (level)
      port map (padp, padn, i, oen);
  end generate;
end;

library techmap;
library ieee;
use ieee.std_logic_1164.all;
use techmap.gencomp.all;

entity toutpad_dsv is
  generic (tech : integer := 0; level : integer := 0; slew : integer := 0;
	voltage : integer := x33v; strength : integer := 12; width : integer := 1;
	oepol : integer := 0);
  port (
    padp : out std_logic_vector(width-1 downto 0);
    padn : out std_logic_vector(width-1 downto 0);
    i    : in  std_logic_vector(width-1 downto 0);
    en   : in  std_ulogic);
end;
architecture rtl of toutpad_dsv is
begin
  v : for j in width-1 downto 0 generate
    u0 : toutpad_ds generic map (tech, level, slew, voltage, strength, oepol)
	 port map (padp(j), padn(j), i(j), en);
  end generate;
end;

library techmap;
library ieee;
use ieee.std_logic_1164.all;
use techmap.gencomp.all;

entity toutpad_dsvv is
  generic (tech : integer := 0; level : integer := 0; slew : integer := 0;
	voltage : integer := x33v; strength : integer := 12; width : integer := 1;
	oepol : integer := 0);
  port (
    padp : out std_logic_vector(width-1 downto 0);
    padn : out std_logic_vector(width-1 downto 0);
    i    : in  std_logic_vector(width-1 downto 0);
    en   : in  std_logic_vector(width-1 downto 0));
end;
architecture rtl of toutpad_dsvv is
begin
  v : for j in width-1 downto 0 generate
    u0 : toutpad_ds generic map (tech, level, slew, voltage, strength, oepol)
	 port map (padp(j), padn(j), i(j), en(j));
  end generate;
end;

