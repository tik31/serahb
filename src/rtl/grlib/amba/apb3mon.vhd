------------------------------------------------------------------------------
--  This file is a part of the GRLIB VHDL IP LIBRARY
--  Copyright (C) 2017, Cobham Gaisler AB - all rights reserved.
--
-- ANY USE OR REDISTRIBUTION IN PART OR IN WHOLE MUST BE HANDLED IN 
-- ACCORDANCE WITH THE GAISLER LICENSE AGREEMENT AND MUST BE APPROVED 
-- IN ADVANCE IN WRITING. 
-----------------------------------------------------------------------------
-- Entity:      apb3mon
-- File:        apb3mon.vhd
-- Author:      Marko Isomaki - Gaisler Research
--              Pascal Trotta - Politecnico di Torino
-- Description: APB3 bus monitor thats checks standard compliancy
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

library grlib;
use grlib.amba.all;
use grlib.stdlib.all;

entity apb3mon is
  generic(
    asserterr   : integer range 0 to 1 := 1;
    assertwarn  : integer range 0 to 1 := 1;
    pslvdisable : integer := 0;
    napb        : integer range 0 to NAPBSLV := NAPBSLV
  );
  port(
    rst         : in std_ulogic;
    clk         : in std_ulogic;
    apb3i       : in apb3_slv_in_type;
    apb3o       : in apb3_slv_out_vector;
    err         : out std_ulogic);
end entity;

architecture beh of apb3mon is

-- pragma translate_off

  type reg_type is record
    war          : std_ulogic;
    err          : std_ulogic;
    apc          : apb3_slv_in_type;
    apvc         : apb3_slv_out_vector;
  end record;

  constant pslvdis : std_logic_vector(31 downto 0) := conv_std_logic_vector(pslvdisable, 32);
  
  signal r, rin   : reg_type;
  signal rst_act  : integer := 0;
-- pragma translate_on
begin
-- pragma translate_off
  comb : process(rst, r, apb3i, apb3o, rst_act, clk) is
    variable v        : reg_type;
    variable found    : integer;
    variable rst_done : integer := 0;
    variable enable   : integer;
  begin
    v := r;

    if (asserterr = 1) and (rst_done = 1) and rising_edge(clk) then
      enable := 1;
    else
      enable := 0;
    end if;
    
    v.apc   := apb3i;
    v.apvc  := apb3o;

    --All rules are numbered. See documentation in grip for ambamon to see
    --exact description of what is checked.

    ----------------------------------------------------------------------------
    -- APB Slave Checks
    ----------------------------------------------------------------------------
    --1 The APB bus can only move from IDLE to SETUP or IDLE to IDLE
    if pslvdis(1) = '0' then
      if (orv(r.apc.psel) = '0') and (r.apc.penable = '0') and
         (apb3i.penable /= '0') then
        v.err := '1'; 
        assert enable /= 1
        report "ERROR P1: APB bus moved from IDLE to illegal state"
        severity error;
      end if;
    end if;
    
    --2 The APB bus must move from SETUP to ACCESS in one cycle.
    if pslvdis(2) = '0' then
      if (orv(r.apc.psel) = '1') and (r.apc.penable = '0') and
         ((apb3i.penable /= '1') or (orv(apb3i.psel) /= '1')) then
        v.err := '1'; 
        assert enable /= 1
        report "ERROR P2: APB did not move from SETUP to ACCESS in one cycle"
        severity error;
      end if;
    end if;
    
    --3 The APB bus must move from ACCESS to SETUP or IDLE in one cycle when pready is asserted.
    if pslvdis(3) = '0' then 
      for i in 0 to napb-1 loop
        if (r.apc.psel(i) = '1') and (r.apc.penable = '1') and
         (apb3i.penable = '1') and (r.apvc(i).pready = '1') then
          v.err := '1'; 
          assert enable /= 1
          report "ERROR P3: APB did not move from ACCESS to IDLE or SETUP in one cycle after pready has been asserted at index " & tost(i)
          severity error;
        end if;
      end loop;
    end if;

    --4 The APB bus must never be in other states than IDLE, SETUP or ACCESS
    if pslvdis(4) = '0' then
      if not ( ((orv(apb3i.psel(0 to napb-1)) = '0') and (apb3i.penable = '0')) or
               ((orv(apb3i.psel(0 to napb-1)) = '1') and (apb3i.penable = '0')) or
               ((orv(apb3i.psel(0 to napb-1)) = '1') and (apb3i.penable = '1')) ) then
        v.err := '1'; 
        assert enable /= 1
        report "ERROR P4: APB was in illegal state"
        severity error;
      end if;
    end if;
    
    --5 PADDR must be stable during transition from SETUP to ACCESS
    if pslvdis(5) = '0' then
      if (orv(apb3i.psel) = '1') and (apb3i.penable = '1') and
         (orv(r.apc.psel) = '1') and (r.apc.penable = '0') and
         (r.apc.paddr /= apb3i.paddr) then
        v.err := '1'; 
        assert enable /= 1
        report "ERROR P5: PADDR was not stable during transition from SETUP to ACCESS"
        severity error;
      end if;
    end if;

    --6 PWRITE must be stable during transition from SETUP to ACCESS
    if pslvdis(6) = '0' then
      if (orv(apb3i.psel) = '1') and (apb3i.penable = '1') and
         (orv(r.apc.psel) = '1') and (r.apc.penable = '0') and
         (r.apc.pwrite /= apb3i.pwrite) then
        v.err := '1'; 
        assert enable /= 1
        report "ERROR P6: PWRITE was not stable during transition from SETUP to ACCESS"
        severity error;
      end if;
    end if;
    
    --7 PWDATA must be stable during transition from SETUP to ACCESS
    if pslvdis(7) = '0' then
      if (orv(apb3i.psel) = '1') and (apb3i.penable = '1') and
         (orv(r.apc.psel) = '1') and (r.apc.penable = '0') and
         (r.apc.pwdata /= apb3i.pwdata) then
        v.err := '1'; 
        assert enable /= 1
        report "ERROR P7: PWDATA was not stable during transition from SETUP to ACCESS"
        severity error;
      end if;
    end if;

    --8 Only one PSEL can be asserted at a time.
    if pslvdis(8) = '0' then
      found := 0;
      for i in 0 to napb-1 loop
        if apb3i.psel(i) = '1' then
          if found = 1 then
            v.err := '1'; 
            assert enable /= 1
            report "ERROR P8: More than one PSEL was asserted the same cycle"
            severity error;
          else
            found := 1;
          end if;
        end if;
      end loop;
    end if;

    --9 PSEL must be stable during transition from SETUP to ACCESS.
    if pslvdis(9) = '0' then
      for i in 0 to napb-1 loop
        if (apb3i.psel(i) = '1') and (apb3i.penable = '1') and (apb3i.psel /= r.apc.psel) then
          v.err := '1'; 
          assert enable /= 1
          report "ERROR P9: PSEL was not stable during transition from SETUP to ACCESS at index " & tost(i)
          severity error;
        end if;
      end loop;
    end if;  

    --10 PSEL must be stable during transition from ACCESS to ACCESS.
    if pslvdis(9) = '0' then
      for i in 0 to napb-1 loop
        if (r.apvc(i).pready='0') and (apb3i.psel /= r.apc.psel) then
          v.err := '1'; 
          assert enable /= 1
          report "ERROR P10: PSEL was not stable during transition from ACCESS to ACCESS at index " & tost(i)
          severity error;
        end if;
      end loop;
    end if;  

    --11 PWDATA must be stable during transition from ACCESS to ACCESS during a write access.
    if pslvdis(9) = '0' then
      for i in 0 to napb-1 loop
        if (r.apvc(i).pready='0') and (apb3i.pwrite = '1') and (apb3i.psel(i) = '1') and (apb3i.penable = '1') and (apb3i.pwdata /= r.apc.pwdata) then
          v.err := '1'; 
          assert enable /= 1
          report "ERROR P11: PWDATA was not stable during transition from ACCESS to ACCESS at index " & tost(i)
          severity error;
        end if;
      end loop;
    end if;  

    --12 PADDR must be stable during transition from ACCESS to ACCESS.
    if pslvdis(9) = '0' then
      for i in 0 to napb-1 loop
        if (r.apvc(i).pready='0') and (apb3i.paddr /= r.apc.paddr) then
          v.err := '1'; 
          assert enable /= 1
          report "ERROR P12: PADDR was not stable during transition from ACCESS to ACCESS at index " & tost(i)
          severity error;
        end if;
      end loop;
    end if;  

    --13 PENABLE must be stable during transition from ACCESS to ACCESS.
    if pslvdis(9) = '0' then
      for i in 0 to napb-1 loop
        if (r.apvc(i).pready='0') and (apb3i.penable /= r.apc.penable) then
          v.err := '1'; 
          assert enable /= 1
          report "ERROR P13: PENABLE was not stable during transition from ACCESS to ACCESS at index " & tost(i)
          severity error;
        end if;
      end loop;
    end if;  

    --14 PWRITE must be stable during transition from ACCESS to ACCESS.
    if pslvdis(9) = '0' then
      for i in 0 to napb-1 loop
        if (r.apvc(i).pready='0') and (apb3i.pwrite /= r.apc.pwrite) then
          v.err := '1'; 
          assert enable /= 1
          report "ERROR P14: PWRITE was not stable during transition from ACCESS to ACCESS at index " & tost(i)
          severity error;
        end if;
      end loop;
    end if;  

    --15 PSLVERR must be asserted only during the last ACCESS cycle.
    if pslvdis(9) = '0' then
      for i in 0 to napb-1 loop
        if (apb3o(i).pslverr='1') and ( (apb3o(i).pready='0') or (apb3i.penable = '0') or (apb3i.psel(i)='0') ) then
          v.err := '1'; 
          assert enable /= 1
          report "ERROR P15: PSLVERR was not asserted during the last ACCESS cycle at index " & tost(i)
          severity error;
        end if;
      end loop;
    end if;  
    
    if rst = '0' then
      v.err := '0'; v.war := '0';
      rst_done := 0; 
    end if;
    if rising_edge(rst) then
      rst_done := 1;
    end if;
    err <= r.err;
    rin <= v;
  end process;

  reg : process(clk) is
  begin
    if rising_edge(clk) then
      r <= rin;
      if (rst = '0') then
        rst_act <= 1;
      end if;
    end if;  
  end process;
-- pragma translate_on
end architecture;

