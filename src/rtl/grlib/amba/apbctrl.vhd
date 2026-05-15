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

entity apbctrl is
  generic (
    hindex      : integer := 0;
    haddr       : integer := 0;
    hmask       : integer := 16#fff#;
    nslaves     : integer range 1 to NAPBSLV := NAPBSLV;
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
    ahbi    : in  ahb_slv_in_type;
    ahbo    : out ahb_slv_out_type;
    apbi    : out apb_slv_in_type;
    apbo    : in  apb_slv_out_vector
  );
end;

architecture struct of apbctrl is
signal lahbi    : ahb_slv_in_vector_type(0 to 0);
signal lahbo    : ahb_slv_out_vector_type(0 to 0);
signal lapbi    : apb_slv_in_vector;
signal lwp      : std_logic_vector(0 to 0);
signal lwpv     : std_logic_vector(256-1 downto 0);
begin

  lahbi(0) <= ahbi;
  ahbo <= lahbo(0);
  apbi <= lapbi(0);
  lwp(0) <= '0';
  lwpv <= (others => '0');

  apbx : apbctrlx
    generic map(
      hindex0     => hindex,
      haddr0      => haddr,
      hmask0      => hmask,
      hindex1     => 0,
      haddr1      => 0,
      hmask1      => 0,
      nslaves     => nslaves,
      nports      => 1,
      wprot       => 0,
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
      apbi        => lapbi,
      apbo        => apbo,
      wp          => lwp,
      wpv         => lwpv);
end;
