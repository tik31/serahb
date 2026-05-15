------------------------------------------------------------------------------
--  This file is a part of the GRLIB VHDL IP LIBRARY
--  Copyright (C) 2017, Cobham Gaisler AB - all rights reserved.
--
-- ANY USE OR REDISTRIBUTION IN PART OR IN WHOLE MUST BE HANDLED IN 
-- ACCORDANCE WITH THE GAISLER LICENSE AGREEMENT AND MUST BE APPROVED 
-- IN ADVANCE IN WRITING. 
-----------------------------------------------------------------------------
-- Entity:        ringosc
-- File:          ringosc.vhd
-- Author:        Jiri Gaisler - Gaisler Research
-- Description:   Ring-oscillator with tech mapping
------------------------------------------------------------------------------
library  IEEE;
use      IEEE.Std_Logic_1164.all;
library techmap;
use techmap.gencomp.all;

entity ringosc is
   generic (tech : integer := 0);
   port (
      roen  :  in    Std_ULogic;
      roout :  out   Std_ULogic);
end ;

architecture rtl of ringosc is
  component ringosc_rhumc 
   port (
      roen  :  in    Std_ULogic;
      roout :  out   Std_ULogic);
  end component;

  component ringosc_ut130hbd
   port (
      roen  :  in    Std_ULogic;
      roout :  out   Std_ULogic);
  end component;

  component ringosc_rhs65
   port (
      roen  :  in    Std_ULogic;
      roout :  out   Std_ULogic);
  end component;

begin

  dr : if tech = rhumc generate
    drx : ringosc_rhumc port map (roen, roout);
  end generate;

  ut130r : if tech = ut130 generate
    ut130rx : ringosc_ut130hbd port map (roen, roout);
  end generate;

  rhs65r : if tech = rhs65 generate
    rhs65rx : ringosc_rhs65 port map (roen, roout);
  end generate;

-- pragma translate_off
  gen : if tech /= rhumc and tech /= ut130 and tech /= rhs65 generate
  signal tmp : std_ulogic := '0';
  begin
    tmp <= not tmp after 1 ns when roen = '1' else '0';
    roout <= tmp;
  end generate;
-- pragma translate_on

end architecture rtl;

