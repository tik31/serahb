------------------------------------------------------------------------------
--  This file is a part of the GRLIB VHDL IP LIBRARY
--  Copyright (C) 2017, Cobham Gaisler AB - all rights reserved.
--
-- ANY USE OR REDISTRIBUTION IN PART OR IN WHOLE MUST BE HANDLED IN 
-- ACCORDANCE WITH THE GAISLER LICENSE AGREEMENT AND MUST BE APPROVED 
-- IN ADVANCE IN WRITING. 
-----------------------------------------------------------------------------
-- Entity:      ddr_ireg
-- File:        ddr_ireg.vhd
-- Author:      Jiri Gaisler - Gaisler Research
-- Description: DDR input reg with tech selection
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
library techmap;
use techmap.gencomp.all;
use techmap.allddr.all;

entity ddr_ireg is
generic ( tech : integer; arch : integer := 0; scantest: integer := 0);
port ( Q1 : out std_ulogic;
       Q2 : out std_ulogic;
       C1 : in std_ulogic;
       C2 : in std_ulogic;
       CE : in std_ulogic;
       D : in std_ulogic;
       R : in std_ulogic;
       S : in std_ulogic;
       testen: in std_ulogic;
       testrst: in std_ulogic);
end;

architecture rtl of ddr_ireg is
begin

  inf : if not((is_unisim(tech) = 1) or (tech = axcel) or
               (tech = axdsp) or (tech = apa3) or (tech = apa3e) or 
               (tech = apa3l) or (tech = rhumc)  or (tech = igloo2) or
               (tech = rtg4)) generate
    inf0 : gen_iddr_reg generic map (scantest,0) port map (Q1, Q2, C1, C2, CE, D, R, S, testen, testrst);
  end generate;

  ax : if (tech = axcel) or (tech = axdsp) generate
    axc0 : axcel_iddr_reg port map (Q1, Q2, C1, C2, CE, D, R, S);
  end generate;

  pa3 : if (tech = apa3) generate
    pa0 : apa3_iddr_reg port map (Q1, Q2, C1, C2, CE, D, R, S);
  end generate;

  pa3e : if (tech = apa3e) generate
    pa0 : apa3e_iddr_reg port map (Q1, Q2, C1, C2, CE, D, R, S);
  end generate;

  pa3l : if (tech = apa3l) generate
    pa0 : apa3l_iddr_reg port map (Q1, Q2, C1, C2, CE, D, R, S);
  end generate;

  igl2 : if (tech = igloo2) or (tech = rtg4) generate
    igl20 : igloo2_iddr_reg port map (Q1, Q2, C1, C2, CE, D, R, S);
  end generate;

  xil : if is_unisim(tech) = 1 generate
    xil0 : unisim_iddr_reg generic map (tech, arch) port map (Q1, Q2, C1, C2, CE, D, R, S);
  end generate;

  rhu : if (tech = rhumc) generate
    rhu0: rhumc_iddr_reg port map (Q1, Q2, C1, C2, CE, D, R, S);
  end generate;

--pragma translate_off
  assert (tech /= easic45) and (tech /= easic90)
    report "ddr_ireg: Not supported on eASIC. Use DDR pad instead."
    severity failure;
--pragma translate_on
  
end architecture;

