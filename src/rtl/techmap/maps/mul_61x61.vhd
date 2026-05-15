------------------------------------------------------------------------------
--  This file is a part of the GRLIB VHDL IP LIBRARY
--  Copyright (C) 2017, Cobham Gaisler AB - all rights reserved.
--
-- ANY USE OR REDISTRIBUTION IN PART OR IN WHOLE MUST BE HANDLED IN 
-- ACCORDANCE WITH THE GAISLER LICENSE AGREEMENT AND MUST BE APPROVED 
-- IN ADVANCE IN WRITING. 
-----------------------------------------------------------------------------
-- Entity: 	mul_61x61
-- File:	mul_61x61.vhd
-- Author:	Edvin Catovic - Gaisler Research
-- Description:	61x61 multiplier
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
library techmap;
use techmap.gencomp.all;

entity mul_61x61 is
  generic (multech : integer := 0;
           fabtech : integer := 0);
    port(A       : in std_logic_vector(60 downto 0);
         B       : in std_logic_vector(60 downto 0);
         EN      : in std_logic;
         CLK     : in std_logic;
         PRODUCT : out std_logic_vector(121 downto 0));
end;


architecture rtl of mul_61x61 is

component dw_mul_61x61 is
    port(A       : in std_logic_vector(60 downto 0);
         B       : in std_logic_vector(60 downto 0);
         CLK     : in std_logic;
         PRODUCT : out std_logic_vector(121 downto 0));
end component;

component gen_mul_61x61 is
    port(A       : in std_logic_vector(60 downto 0);
         B       : in std_logic_vector(60 downto 0);
         EN      : in std_logic;
         CLK     : in std_logic;
         PRODUCT : out std_logic_vector(121 downto 0));
end component;

component axcel_mul_61x61 is
    port(A       : in std_logic_vector(60 downto 0);
         B       : in std_logic_vector(60 downto 0);
         EN      : in std_logic;
         CLK     : in std_logic;
         PRODUCT : out std_logic_vector(121 downto 0));
end component;

component virtex4_mul_61x61
port(
  A : in std_logic_vector(60 downto 0);
  B : in std_logic_vector(60 downto 0);
  EN :  in std_logic;
  CLK :  in std_logic;
  PRODUCT : out std_logic_vector(121 downto 0));
end component;

component virtex6_mul_61x61
port(
  A : in std_logic_vector(60 downto 0);
  B : in std_logic_vector(60 downto 0);
  EN :  in std_logic;
  CLK :  in std_logic;
  PRODUCT : out std_logic_vector(121 downto 0));
end component;

component virtex7_mul_61x61
port(
  A : in std_logic_vector(60 downto 0);
  B : in std_logic_vector(60 downto 0);
  EN :  in std_logic;
  CLK :  in std_logic;
  PRODUCT : out std_logic_vector(121 downto 0));
end component;

component kintex7_mul_61x61
port(
  A : in std_logic_vector(60 downto 0);
  B : in std_logic_vector(60 downto 0);
  EN :  in std_logic;
  CLK :  in std_logic;
  PRODUCT : out std_logic_vector(121 downto 0));
end component;

begin

  gen0 : if multech = 0 generate
    mul0 : gen_mul_61x61 port map (A, B, EN, CLK, PRODUCT);
  end generate;

  dw0 : if multech = 1 generate
    mul0 : dw_mul_61x61 port map (A, B, CLK, PRODUCT);
  end generate;

  tech0 : if multech = 3 generate
    axd0 : if fabtech = axdsp generate
      mul0 : axcel_mul_61x61 port map (A, B, EN, CLK, PRODUCT);
    end generate;
    xc5v : if fabtech = virtex5 generate
      mul0 : virtex4_mul_61x61 port map (A, B, EN, CLK, PRODUCT);
    end generate;
    xc6v : if fabtech = virtex6 generate
      mul0 : virtex6_mul_61x61 port map (A, B, EN, CLK, PRODUCT);
    end generate;
    gen0 : if not ((fabtech = axdsp) or (fabtech = virtex5) or (fabtech = virtex6)) generate
      mul0 : gen_mul_61x61 port map (A, B, EN, CLK, PRODUCT);
    end generate;
  end generate;

end;

