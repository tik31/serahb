------------------------------------------------------------------------------
--  This file is a part of the GRLIB VHDL IP LIBRARY
--  Copyright (C) 2017, Cobham Gaisler AB - all rights reserved.
--
-- ANY USE OR REDISTRIBUTION IN PART OR IN WHOLE MUST BE HANDLED IN 
-- ACCORDANCE WITH THE GAISLER LICENSE AGREEMENT AND MUST BE APPROVED 
-- IN ADVANCE IN WRITING. 
-----------------------------------------------------------------------------
-- Entity: buffer_igloo2
-- File:	buffer_igloo2.vhd
-- Author:	Pascal Trotta
-- Description:	Clock buffer generator for IGLOO2 devices
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
-- pragma translate_off
library smartfusion2;
use smartfusion2.clkint;
use smartfusion2.rclkint;
use smartfusion2.bufd;
-- pragma translate_on

entity clkbuf_igloo2 is
  generic(
    buftype :  integer range 0 to 5 := 0);
  port(
    i       :  in  std_ulogic;
    o       :  out std_ulogic
  );
end entity;

architecture rtl of clkbuf_igloo2 is
  signal o2, no2, nin : std_ulogic;
  component clkint port(a : in std_ulogic; y : out std_ulogic); end component;
  component rclkint port(a : in std_ulogic; y : out std_ulogic); end component;
  component bufd port(a : in std_ulogic; y : out std_ulogic); end component;
  attribute syn_maxfan : integer;
  attribute syn_maxfan of o2 : signal is 10000;
begin
  o <= o2;
  buf0 : if buftype = 0 generate
    nin <= '0'; no2 <= '0';
    o2 <= i;
  end generate;
  buf1 : if buftype = 1 generate
    nin <= '0'; no2 <= '0';
    buf : clkint port map(A => i, Y => o2);
  end generate;
  buf2 : if buftype = 2 generate
    nin <= '0'; no2 <= '0';
    buf : clkint port map(A => i, Y => o2);
  end generate;
  buf3 : if buftype = 3 generate 
    nin <= not i;
    buf : clkint port map(A => nin, Y => no2);
    o2 <= not no2;
  end generate;
  buf4 : if buftype = 4 generate
    nin <= '0'; no2 <= '0';
    buf : rclkint port map(A => i, Y => o2);
  end generate;
  buf5 : if buftype = 5 generate
    nin <= '0'; no2 <= '0';
    buf : bufd port map(A => i, Y => o2);
  end generate;
  buf6 : if buftype > 5 generate 
    nin <= not i;
    buf : rclkint port map(A => nin, Y => no2);
    o2 <= not no2;
  end generate;
end architecture;

