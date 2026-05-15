------------------------------------------------------------------------------
--  This file is a part of the GRLIB VHDL IP LIBRARY
--  Copyright (C) 2017, Cobham Gaisler AB - all rights reserved.
--
-- ANY USE OR REDISTRIBUTION IN PART OR IN WHOLE MUST BE HANDLED IN 
-- ACCORDANCE WITH THE GAISLER LICENSE AGREEMENT AND MUST BE APPROVED 
-- IN ADVANCE IN WRITING. 
-----------------------------------------------------------------------------
-- Entity: 	skew_outpad
-- File:	skew_outpad.vhd
-- Author:	Nils-Johan Wessman - Gaisler Research
-- Description:	output pad with technology wrapper
------------------------------------------------------------------------------

library techmap;
library ieee;
use ieee.std_logic_1164.all;
use techmap.gencomp.all;
use techmap.allpads.all;

entity skew_outpad is
  generic (tech : integer := 0; level : integer := 0; slew : integer := 0;
	   voltage : integer := x33v; strength : integer := 12; skew : integer := 0);
  port (pad : out std_ulogic; i : in std_ulogic; rst : in std_ulogic;
        o : out std_ulogic);
end; 

architecture rtl of skew_outpad is
signal padx, gnd, vcc : std_ulogic;
begin
  gnd <= '0'; vcc <= '1';
  gen0 : if has_pads(tech) = 0 generate
    pad <= i 
-- pragma translate_off
	after 2 ns
-- pragma translate_on
 	when slew = 0 else i;
  end generate;
  xcv : if (is_unisim(tech) = 1) generate
    x0 : unisim_skew_outpad generic map (level, slew, voltage, strength, skew) port map (pad, i, rst, o);
  end generate;
end;

