------------------------------------------------------------------------------
--  This file is a part of the GRLIB VHDL IP LIBRARY
--  Copyright (C) 2017, Cobham Gaisler AB - all rights reserved.
--
-- ANY USE OR REDISTRIBUTION IN PART OR IN WHOLE MUST BE HANDLED IN 
-- ACCORDANCE WITH THE GAISLER LICENSE AGREEMENT AND MUST BE APPROVED 
-- IN ADVANCE IN WRITING. 
-----------------------------------------------------------------------------
-- Entity:      syncreg
-- File:        syncreg.vhd
-- Author:      Aeroflex Gaisler AB
-- Description: Technology wrapper for sync registers
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
library techmap;
use techmap.gencomp.all;

entity syncreg is
  generic (
    tech    : integer := 0;
    stages  : integer range 1 to 5 := 2
    );
  port (
    clk    : in  std_ulogic;
    d      : in  std_ulogic;
    q      : out std_ulogic
    );
end;

architecture tmap of syncreg is
  
begin
  sync0 : if has_syncreg(tech) = 0 generate
    --syncreg : block
    --  signal c : std_logic_vector(stages-1 downto 0);
    --begin
    --  x0 : process(clk)
    --  begin
    --    if rising_edge(clk) then
    --      for i in 0 to stages-1 loop
    --        c(i) <= d;
    --        if i /= 0 then c(i) = c(i-1); end if;
    --      end loop;
    --    end if;
    --  end process;
    --  q <= c(stages-1);
    --end block syncreg;
    syncreg : block
      signal c            : std_logic_vector(stages downto 0);
      attribute keep      : boolean;
      attribute keep of c : signal is true;
    begin
      c(0) <= d;
      syncregs : for i in 1 to stages generate
        dff : grdff
          generic map(tech => tech)
          port map(clk => clk, d => c(i-1), q => c(i));
      end generate;
      q <= c(stages);
    end block syncreg;
  end generate;
end;

