------------------------------------------------------------------------------
--  This file is a part of the GRLIB VHDL IP LIBRARY
--  Copyright (C) 2017, Cobham Gaisler AB - all rights reserved.
--
-- ANY USE OR REDISTRIBUTION IN PART OR IN WHOLE MUST BE HANDLED IN 
-- ACCORDANCE WITH THE GAISLER LICENSE AGREEMENT AND MUST BE APPROVED 
-- IN ADVANCE IN WRITING. 
-----------------------------------------------------------------------------
-- Package:     charrom_package
-- File:        charrom_package.vhd
-- Author:      Marcus Hellqvist
-- Description: Charrom types and component
-----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
library grlib;
use grlib.stdlib.all;

package charrom_package is

type rom_type is record
 addr           : std_logic_vector(11 downto 0);
 data           : std_logic_vector(7 downto 0);
end record;

component charrom
  port(
    clk         : in std_ulogic;
    addr        : in std_logic_vector(11 downto 0);
    data        : out std_logic_vector(7 downto 0)
    );
end component;

end package;

