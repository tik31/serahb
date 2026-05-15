------------------------------------------------------------------------------
--  This file is a part of the GRLIB VHDL IP LIBRARY
--  Copyright (C) 2017, Cobham Gaisler AB - all rights reserved.
--
-- ANY USE OR REDISTRIBUTION IN PART OR IN WHOLE MUST BE HANDLED IN 
-- ACCORDANCE WITH THE GAISLER LICENSE AGREEMENT AND MUST BE APPROVED 
-- IN ADVANCE IN WRITING. 
-----------------------------------------------------------------------------
-- Entity: 	clkinv
-- File:	clkinv.vhd
-- Author:	Fredrik Ringhage - Aeroflex Gaisler Research
-- Description: SET protected inverters for clock tree
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use work.gencomp.all;
use work.allclkgen.all;

entity clkinv is
  generic(tech : integer := 0);
  port(
    i  :  in  std_ulogic;
    o  :  out std_ulogic
  );
end entity;

architecture rtl of clkinv is
begin
  
  tec : if has_clkinv(tech) = 1 generate

    saed : if (tech = saed32) generate
      x0 : clkinv_saed32 port map (i => i, o => o);
    end generate;

    dar : if (tech = dare) generate
      x0 : clkinv_dare port map (i => i, o => o);
    end generate;

    rhs : if (tech = rhs65) generate
      x0 : clkinv_rhs65 port map (i => i, o => o);
    end generate;

  end generate;

  gen : if has_clkinv(tech) = 0 generate
    o <= not i;
  end generate;

end architecture;




