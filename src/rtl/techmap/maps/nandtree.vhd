------------------------------------------------------------------------------
--  This file is a part of the GRLIB VHDL IP LIBRARY
--  Copyright (C) 2017, Cobham Gaisler AB - all rights reserved.
--
-- ANY USE OR REDISTRIBUTION IN PART OR IN WHOLE MUST BE HANDLED IN 
-- ACCORDANCE WITH THE GAISLER LICENSE AGREEMENT AND MUST BE APPROVED 
-- IN ADVANCE IN WRITING. 
-----------------------------------------------------------------------------
-- Entity: 	nandtree
-- File:	nandtree.vhd
-- Author:	Jiri Gaisler - Gaisler Research
-- Description:	Nand-tree with tech mapping
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
library techmap;
use techmap.gencomp.all;

entity nandtree is
  generic(
    tech     :  integer := inferred;
    width    :  integer := 2;
    imp      :  integer := 0 );
  port( i :  in  std_logic_vector(width-1 downto 0); 
	o :  out std_ulogic;
	en :  in std_ulogic
  );
end entity;

architecture rtl of nandtree is

  component rh_lib18t_nand_tree
  generic (npins : integer := 2);
  port(
       -- Input Signlas: --
       TEST_MODE      : in  std_logic;
       IN_PINS_BUS    : in  std_logic_vector(npins-1 downto 0);
       NAND_TREE_OUT  : out std_logic
    );  
  end component;

  function fnandtree(v : std_logic_vector) return std_ulogic is
  variable a : std_logic_vector(v'length-1 downto 0);
  variable b : std_logic_vector(v'length downto 0);
  begin

    a := v; b(0) := '1';

    for i in 0 to v'length-1 loop
      b(i+1) := a(i) nand b(i);
    end loop;

    return b(v'length);

  end;
begin

  behav : if tech /= rhlib18t generate
    o <= fnandtree(i);
  end generate;

  rhlib : if tech = rhlib18t generate
    rhnand : rh_lib18t_nand_tree generic map (width)
      port map (en, i, o);  
  end generate;

end;

