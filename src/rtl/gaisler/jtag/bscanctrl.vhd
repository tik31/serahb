------------------------------------------------------------------------------
--  This file is a part of the GRLIB VHDL IP LIBRARY
--  Copyright (C) 2017, Cobham Gaisler AB - all rights reserved.
--
-- ANY USE OR REDISTRIBUTION IN PART OR IN WHOLE MUST BE HANDLED IN 
-- ACCORDANCE WITH THE GAISLER LICENSE AGREEMENT AND MUST BE APPROVED 
-- IN ADVANCE IN WRITING. 
-----------------------------------------------------------------------------
-- Entity: 	bscanctrl
-- File:	bscanctrl.vhd
-- Author:	Magnus Hjorth - Aeroflex Gaisler
-- Description:	JTAG boundary scan control logic
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity bscanctrl is
  generic (
    spinst   : integer := 5;               -- sample/preload
    etinst   : integer := 6;               -- extest
    itinst   : integer := 7;                --intest
    hzinst   : integer := 8;               -- highz
    clinst   : integer := 10;              -- clamp
    mbist    : integer := 11;              -- mbist
    testx1   : integer := 12;              -- generic test command
    scantest : integer := 0
    );
  port (
    trst        : in std_ulogic;
    tapo_tck    : in std_ulogic;
    tapo_tckn   : in std_ulogic;
    tapo_tdi    : in std_ulogic;
    tapo_ninst  : in std_logic_vector(7 downto 0);
    tapo_iupd   : in std_ulogic;
    tapo_rst    : in std_ulogic;
    tapo_capt   : in std_ulogic;
    tapo_shft   : in std_ulogic;
    tapo_upd    : in std_ulogic;
    tapi_tdo    : out std_ulogic;
    chain_tdi   : out std_ulogic;
    chain_tdo   : in std_ulogic;
    bsshft      : out std_ulogic;
    bscapt      : out std_ulogic;
    bsupdi      : out std_ulogic;
    bsupdo      : out std_ulogic;
    bsdrive     : out std_ulogic;
    bshighz     : out std_ulogic;
    bsmbist     : out std_ulogic;
    bstestx1    : out std_ulogic;
    testen      : in  std_ulogic;
    testrst     : in  std_ulogic;
    bypass_tdo  : out std_ulogic;
    mbist_tdo   : in std_ulogic
    );
end;

architecture rtl of bscanctrl is

  type chainctrl_regsp is record
    -- We implement our own bypass reg in case of CLAMP since the
    -- technology TAP may not expose its own bypass functionality...
    bypreg: std_ulogic;
  end record;

  type chainctrl_regsn is record
    -- We hold these in registers to avoid glitches on outputs and clocks
    bsdrive : std_ulogic;
    bshighz : std_ulogic;
    bsmbist : std_ulogic;
    bscen   : std_ulogic;
    testx1en: std_ulogic;
  end record;

  signal rp,nrp: chainctrl_regsp;
  signal rn,nrn: chainctrl_regsn;

  signal arst: std_ulogic;
  
begin
  arst <= testrst when scantest/=0 and testen='1' else trst;
  
  comb: process(rp,rn,tapo_tdi,tapo_shft,tapo_ninst,tapo_iupd,tapo_capt,tapo_upd,chain_tdo,mbist_tdo)
    variable vp: chainctrl_regsp;
    variable vn: chainctrl_regsn;
    variable spsel,etsel,itsel,hzsel,clsel, mbsel, t1sel: std_logic;
    variable tdo: std_logic;
    variable vctdi: std_logic;    
  begin
    vp := rp; vn := rn;
    tdo := chain_tdo;
    vctdi := tapo_tdi;
    
    spsel:='0'; etsel:='0'; itsel:='0'; hzsel:='0'; clsel:='0'; mbsel := '0'; t1sel:='0';
    if tapo_ninst=std_logic_vector(to_unsigned(spinst,8)) then spsel:='1'; end if;
    if tapo_ninst=std_logic_vector(to_unsigned(etinst,8)) then etsel:='1'; end if;
    if tapo_ninst=std_logic_vector(to_unsigned(itinst,8)) then itsel:='1'; end if;
    if tapo_ninst=std_logic_vector(to_unsigned(hzinst,8)) then hzsel:='1'; end if;
    if tapo_ninst=std_logic_vector(to_unsigned(clinst,8)) then clsel:='1'; end if;
    if tapo_ninst=std_logic_vector(to_unsigned(mbist,8)) then mbsel:='1'; end if;
    if tapo_ninst=std_logic_vector(to_unsigned(testx1,8)) then t1sel:='1'; end if;

    if tapo_iupd='1' then
      vn.bsdrive := etsel or itsel or clsel;
      vn.bshighz := hzsel or itsel;
      vn.bsmbist := mbsel;
      vn.bscen   := spsel or etsel or itsel;
      vn.testx1en:= t1sel;
    end if;

    if rn.bscen='0' then
      tdo := rp.bypreg;
    end if;
    if rn.bsmbist='1' then
      tdo := mbist_tdo;
    end if;

    if tapo_capt='1' then
      vp.bypreg := '0';
    end if;
    if tapo_shft='1' then
      vp.bypreg := tapo_tdi;
    end if;

    nrp <= vp;
    nrn <= vn;
    tapi_tdo <= tdo;
    chain_tdi <= vctdi;
    bsshft <= tapo_shft;
    bscapt <= tapo_capt;
    bsupdi <= tapo_upd and (itsel or spsel);
    bsupdo <= tapo_upd and (etsel or spsel);
    bsdrive <= rn.bsdrive;
    bshighz <= rn.bshighz;
    bsmbist <= rn.bsmbist;
    bstestx1 <= rn.testx1en;
    bypass_tdo <= rp.bypreg;
  end process;

  regs: process(tapo_tck)
  begin
    if rising_edge(tapo_tck) then
      rp <= nrp;
    end if;
  end process;

  nregs: process(tapo_tckn,arst)
  begin
    if rising_edge(tapo_tckn) then
      rn <= nrn;
    end if;
    if arst='0' then
      rn <= ('0','0','0','0','0');
    end if;
  end process;
end;

