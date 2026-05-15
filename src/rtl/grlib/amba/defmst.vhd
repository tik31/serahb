------------------------------------------------------------------------------
--  This file is a part of the GRLIB VHDL IP LIBRARY
--  Copyright (C) 2017, Cobham Gaisler AB - all rights reserved.
--
-- ANY USE OR REDISTRIBUTION IN PART OR IN WHOLE MUST BE HANDLED IN 
-- ACCORDANCE WITH THE GAISLER LICENSE AGREEMENT AND MUST BE APPROVED 
-- IN ADVANCE IN WRITING. 
----------------------------------------------------------------------------   
-- Entity:      defmst
-- File:        defmst.vhd
-- Author:      Edvin Catovic, Gaisler Research
-- Description: Default AHB master
------------------------------------------------------------------------------ 


library IEEE;
use IEEE.std_logic_1164.all;
library grlib;
use grlib.stdlib.all;
use grlib.amba.all;

entity ahbdefmst is
  generic ( hindex : integer range 0 to NAHBMST-1 := 0);
  port ( ahbmo  : out ahb_mst_out_type);
end;


architecture rtl of ahbdefmst is
begin
  
  ahbmo.hbusreq <= '0';
  ahbmo.hlock   <= '0';
  ahbmo.htrans  <= HTRANS_IDLE;
  ahbmo.haddr   <= (others => '0');
  ahbmo.hwrite  <= '0';
  ahbmo.hsize   <= (others => '0');
  ahbmo.hburst  <= (others => '0');
  ahbmo.hprot   <= (others => '0');
  ahbmo.hwdata  <= (others => '0');
  ahbmo.hirq    <= (others => '0');
  ahbmo.hconfig <= (others => (others => '0'));
  ahbmo.hindex  <= hindex;

end;

