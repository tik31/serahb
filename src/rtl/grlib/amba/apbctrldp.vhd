------------------------------------------------------------------------------
--  This file is a part of the GRLIB VHDL IP LIBRARY
--  Copyright (C) 2017, Cobham Gaisler AB - all rights reserved.
--
-- ANY USE OR REDISTRIBUTION IN PART OR IN WHOLE MUST BE HANDLED IN 
-- ACCORDANCE WITH THE GAISLER LICENSE AGREEMENT AND MUST BE APPROVED 
-- IN ADVANCE IN WRITING. 
-----------------------------------------------------------------------------   
-- Entity:      apbctrl
-- File:        apbctrl.vhd
-- Author:      Jiri Gaisler - Gaisler Research
-- Description: AMBA AHB/APB bridge with plug&play support
------------------------------------------------------------------------------ 

library ieee;
use ieee.std_logic_1164.all;
library grlib;
use grlib.config_types.all;
use grlib.config.all;
use grlib.amba.all;
use grlib.stdlib.all;

entity apbctrldp is
  generic (
    hindex0     : integer := 0;
    haddr0      : integer := 0;
    hmask0      : integer := 16#fff#;
    hindex1     : integer := 0;
    haddr1      : integer := 0;
    hmask1      : integer := 16#fff#;
    nslaves     : integer range 1 to NAPBSLV := NAPBSLV;
    wprot       : integer range 0 to 1 := 0;
    debug       : integer range 0 to 2 := 2;
    icheck      : integer range 0 to 1 := 1;
    enbusmon    : integer range 0 to 1 := 0;
    asserterr   : integer range 0 to 1 := 0;
    assertwarn  : integer range 0 to 1 := 0;
    pslvdisable : integer := 0;
    mcheck      : integer range 0 to 1 := 1;
    ccheck      : integer range 0 to 1 := 1
    );
  port (
    rst     : in  std_ulogic;
    clk     : in  std_ulogic;
    ahb0i   : in  ahb_slv_in_type;
    ahb0o   : out ahb_slv_out_type;
    ahb1i   : in  ahb_slv_in_type;
    ahb1o   : out ahb_slv_out_type;
    apbi    : out apb_slv_in_vector;
    apbo    : in  apb_slv_out_vector;
    wp      : in  std_logic_vector(0 to 1) := (others => '0');
    wpv     : in  std_logic_vector((256*2)-1 downto 0) := (others => '0')
  );
end;

architecture struct of apbctrldp is
signal lahbi    : ahb_slv_in_vector_type(0 to 1);
signal lahbo    : ahb_slv_out_vector_type(0 to 1);
begin

  lahbi(0) <= ahb0i;
  lahbi(1) <= ahb1i;
  ahb0o <= lahbo(0);
  ahb1o <= lahbo(1);

  apbx : apbctrlx
    generic map(
      hindex0     => hindex0,
      haddr0      => haddr0,
      hmask0      => hmask0,
      hindex1     => hindex1,
      haddr1      => haddr1,
      hmask1      => hmask1,
      nslaves     => nslaves,
      nports      => 2,
      wprot       => wprot,
      debug       => debug,
      icheck      => icheck,
      enbusmon    => enbusmon,
      asserterr   => asserterr,
      assertwarn  => assertwarn,
      pslvdisable => pslvdisable,
      mcheck      => mcheck,
      ccheck      => ccheck)
    port map(
      rst         => rst,
      clk         => clk,
      ahbi        => lahbi,
      ahbo        => lahbo,
      apbi        => apbi,
      apbo        => apbo,
      wp          => wp,
      wpv         => wpv);
end;
