------------------------------------------------------------------------------
--  This file is a part of the GRLIB VHDL IP LIBRARY
--  Copyright (C) 2017, Cobham Gaisler AB - all rights reserved.
--
-- ANY USE OR REDISTRIBUTION IN PART OR IN WHOLE MUST BE HANDLED IN 
-- ACCORDANCE WITH THE GAISLER LICENSE AGREEMENT AND MUST BE APPROVED 
-- IN ADVANCE IN WRITING. 
-----------------------------------------------------------------------------
-- Entity: 	ddr_igloo2
-- File:	ddr_igloo2.vhd
-- Author:	Pascal Trotta
-- Description:	IGLOO2 DDR input and output registers
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
-- pragma translate_off
library smartfusion2;
use smartfusion2.ddr_out;
-- pragma translate_on

entity igloo2_oddr_reg is
  port(
    Q : out std_ulogic;
    C1 : in std_ulogic;
    C2 : in std_ulogic;
    CE : in std_ulogic;
    D1 : in std_ulogic;
    D2 : in std_ulogic;
    R : in std_ulogic;
    S : in std_ulogic);
end entity;

architecture rtl of igloo2_oddr_reg is
  component ddr_out
    port(dr, df, clk, en, aln, adn, sln, sd : in std_ulogic;
         q : out std_logic);
    end component;
    signal rn, sn : std_ulogic;
begin
  rn <= not(R); sn <= not(S);
  ddr_out0 : ddr_out
    port map(dr => D1, df => D2, clk => C1, en => '1', aln => rn, adn => '1', sln => sn, sd => '1', q => Q);
end architecture;

library ieee;
use ieee.std_logic_1164.all;
-- pragma translate_off
library smartfusion2;
use smartfusion2.ddr_in;
-- pragma translate_on

entity igloo2_iddr_reg is
  port(
    Q1 : out std_ulogic;
    Q2 : out std_ulogic;
    C1 : in std_ulogic;
    C2 : in std_ulogic;
    CE : in std_ulogic;
    D  : in std_ulogic;
    R  : in std_ulogic;
    S  : in std_ulogic);
end entity;

architecture rtl of igloo2_iddr_reg is
  component ddr_in
    port(d, clk, en, aln, adn, sln, sd : in std_ulogic;
         qr, qf : out std_ulogic);
  end component;
  signal rn, sn : std_ulogic;
begin
  rn <= not(R); sn <= not(S);
  ddr_in0 : ddr_in
    port map(d => D, clk => C1, en => '1', aln => rn, adn => '1', sln => sn, sd => '1', qr => Q1, qf => Q2);
end architecture;

