------------------------------------------------------------------------------
--  This file is a part of the GRLIB VHDL IP LIBRARY
--  Copyright (C) 2017, Cobham Gaisler AB - all rights reserved.
--
-- ANY USE OR REDISTRIBUTION IN PART OR IN WHOLE MUST BE HANDLED IN 
-- ACCORDANCE WITH THE GAISLER LICENSE AGREEMENT AND MUST BE APPROVED 
-- IN ADVANCE IN WRITING. 
-----------------------------------------------------------------------------
-- Entity:      gen_iddr_reg
-- File:        gen_iddr_reg.vhd
-- Author:      David Lindh, Jiri Gaisler - Gaisler Research
-- Description: Generic DDR input reg
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity gen_iddr_reg is
  generic (scantest: integer; noasync: integer);
  port(
         Q1 : out std_ulogic;
         Q2 : out std_ulogic;
         C1 : in std_ulogic;
         C2 : in std_ulogic;
         CE : in std_ulogic;
         D : in std_ulogic;
         R : in std_ulogic;
         S : in std_ulogic;
         testen: in std_ulogic;
         testrst: in std_ulogic
      );
end;
  
architecture rtl of gen_iddr_reg is
  signal preQ2 : std_ulogic;
  signal RI: std_ulogic;
begin

  RI <= (not testrst) when (scantest/=0 and testen='1') else R;

  ddrregp : process(RI,C1)
  begin
    if RI = '1' and (noasync=0) then Q1 <= '0'; Q2 <= '0';
    elsif rising_edge(C1) then Q1 <= D; Q2 <= preQ2; end if;
  end process;

  ddrregn : process(RI,C2)
  begin
    if RI = '1' and (noasync=0) then preQ2 <= '0';
--    elsif falling_edge(C1) then preQ2 <= D; end if;
    elsif rising_edge(C2) then preQ2 <= D; end if;
  end process;

end;

library ieee;
use ieee.std_logic_1164.all;

entity gen_oddr_reg is
  generic (scantest: integer; noasync: integer);
  port (
      Q : out std_ulogic;
      C1 : in std_ulogic;
      C2 : in std_ulogic;
      CE : in std_ulogic;
      D1 : in std_ulogic;
      D2 : in std_ulogic;
      R : in std_ulogic;
      S : in std_ulogic;
      testen: in std_ulogic;
      testrst: in std_ulogic);
end;

architecture rtl of gen_oddr_reg is
  signal Q1,Q2: std_ulogic;
  signal SEL : std_ulogic := '1';
  signal RI,SI: std_ulogic;
begin

  RI <= (not testrst) when (scantest/=0 and testen='1') else R;
  SI <= '0' when (scantest/=0 and testen='1') else S;

  Q <= Q1 when SEL = '1' else Q2;
  
  ddrregp: process(C1,RI,SI)
  begin
    if rising_edge(C1) then Q1 <= D1; Q2 <= D2; end if;
    if SI='1' and noasync=0 then Q1 <= '1'; Q2 <= '1'; end if;
    if RI='1' and noasync=0 then Q1 <= '0'; Q2 <= '0'; end if;
    if C1='1' and noasync=0 then SEL <= '1'; else SEL <= '0'; end if;
  end process;
  
end;
  

