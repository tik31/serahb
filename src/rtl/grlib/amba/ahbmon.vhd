------------------------------------------------------------------------------
--  This file is a part of the GRLIB VHDL IP LIBRARY
--  Copyright (C) 2017, Cobham Gaisler AB - all rights reserved.
--
-- ANY USE OR REDISTRIBUTION IN PART OR IN WHOLE MUST BE HANDLED IN 
-- ACCORDANCE WITH THE GAISLER LICENSE AGREEMENT AND MUST BE APPROVED 
-- IN ADVANCE IN WRITING. 
-----------------------------------------------------------------------------
-- Entity:      ahbmon
-- File:        ahbmon.vhd
-- Author:      Marko Isomaki - Gaisler Research
-- Description: AHB bus monitor that checks standard compliancy
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

library grlib;
use grlib.amba.all;
use grlib.stdlib.all;
-- pragma translate_off
use grlib.testlib.ahb_doff;
-- pragma translate_on

entity ahbmon is
  generic(
    asserterr   : integer range 0 to 1 := 1;
    assertwarn  : integer range 0 to 1 := 1;
    hmstdisable : integer := 0;
    hslvdisable : integer := 0;
    arbdisable  : integer := 0;
    nahbm       : integer range 0 to NAHBMST := NAHBMST;
    nahbs       : integer range 0 to NAHBSLV := NAHBSLV;
    ebterm      : integer range 0 to 1 := 0
  );
  port(
    rst         : in std_ulogic;
    clk         : in std_ulogic;
    ahbmi       : in ahb_mst_in_type;
    ahbmo       : in ahb_mst_out_vector;
    ahbsi       : in ahb_slv_in_type;
    ahbso       : in ahb_slv_out_vector;
    err         : out std_ulogic);
end entity;

architecture beh of ahbmon is

-- pragma translate_off

  function errltr(errno: integer) return character is
  begin
    case errno/100 is
      when 0 => return 'M';
      when 1 => return 'S';
      when 2 => return 'A';
      when others => return '?';
    end case;
  end errltr;

  function errstr(errno,errid: integer) return string is
  begin
    case errno is
      -- AHB master errors/warnings
      when 1 => return "BUSY cycle followed an IDLE cycle";
      when 2 => return "BUSY can only occur at the end of INCR burst";
      when 3 => return "Address and/or control did not reflect the next access during BUSY";
      when 4 => return "First access of burst or single access must be NONSEQ";
      when 5 => return "HSIZE must not be set larger than the bus width";
      when 6 => return "HADDR must be aligned to transfer size";
      when 7 => return "Address and control signals must be stable when hready is deasserted except for transitions from IDLE or BUSY";
      when 8 => return "Address and control signals must be the same for consecutive BUSY cycles";
      when 9 => return "Address and control signals must be related for SEQ cycles";
      when 10 => return "IDLE cycle must be inserted during RETRY response";
      when 11 => return "IDLE cycle must be inserted during SPLIT response";
      when 12 => return "Master did not reattempt current transfer after RETRY";
      when 13 => return "Master did not reattempt current transfer after SPLIT";
      when 14 => return "IDLE cycle should (optionally) be inserted during ERROR response";
      when 15 => return "Master did not hold hwdata stable";
      when 16 => return "Burst crossed a 1 kB boundary";
      when 17 => return "HMASTLOCK was not set for locked transfer";
      when 18 => return "Master did not assert hlock at least one cycle before address phase";
      when 19 => return "HLOCK must be asserted for the duration of a burst";
      when 20 => return "Master " & tost(errid) & " did not deassert hlock in last address phase of burst";
      when 21 => return "Master " & tost(errid) & " did not drive HTRANS to IDLE during reset";
      when 22 => return "HTRANS changed from IDLE to illegal value when HREADY was deasserted";
      -- AHB slave errors/warnings
      when 101 => return "Zero wait state OKAY response must be given to BUSY";
      when 102 => return "Zero wait state OKAY response must be given to IDLE";
      when 103 => return "HRESP was set to ERROR, RETRY or SPLIT for more than one cycle when hready was low";
      when 104 => return "Two cycle ERROR response was not given correctly";
      when 105 => return "Two cycle SPLIT response was not given correctly";
      when 106 => return "Two cycle RETRY response was not given correctly";
      when 107 => return "Slave " & tost(errid) & " returned Split complete without giving a SPLIT response";
      when 108 => return "Split complete cannot be asserted on the same cycle as SPLIT response is given for the same master";
      when 109 => return "Slave " & tost(errid) & " did not set hready='1' and hresp=OKAY when not selected";
      when 110 => return "More than 16 wait states inserted by slave";
      when 111 => return "Slave " & tost(errid) & " repeated Split complete";
      -- Arbiter errors/warnings
      when 201 => return "Global hready not equal to hready from selected slave";
      when 202 => return "Master " & tost(errid) & " was granted the bus when it had received SPLIT response but not SPLIT complete";
      when 203 => return "A Master was granted the bus during a locked SPLIT";

      when others => return "Bad error number";
    end case;
  end errstr;    
  
  function next_addr(
    ahbsi : in ahb_slv_in_type) return std_logic_vector is
    variable incr  : integer;
    variable bsize : integer;
    variable msb   : integer;
    variable addr  : std_logic_vector(31 downto 0);
  begin
    incr := 2**(conv_integer(ahbsi.hsize));
    if ahbsi.htrans = HTRANS_BUSY then
      return ahbsi.haddr;
    else
      case ahbsi.hburst is
        when HBURST_SINGLE =>
          return ahbsi.haddr + incr;
        when HBURST_INCR =>
          return ahbsi.haddr + incr;
        when HBURST_WRAP4 =>
          bsize := 4 * incr;
          msb := log2(bsize);
          return ahbsi.haddr(31 downto msb) & (ahbsi.haddr(msb-1 downto 0) + incr);
        when HBURST_INCR4 =>
          return ahbsi.haddr + incr;
        when HBURST_WRAP8 =>
          bsize := 8 * incr;
          msb := log2(bsize);
          return ahbsi.haddr(31 downto msb) & (ahbsi.haddr(msb-1 downto 0) + incr);
        when HBURST_INCR8 =>
          return ahbsi.haddr + incr;
        when HBURST_WRAP16 =>
          bsize := 16 * incr;
          msb := log2(bsize);
          return ahbsi.haddr(31 downto msb) & (ahbsi.haddr(msb-1 downto 0) + incr);
        when HBURST_INCR16 =>
          return ahbsi.haddr + incr;
        when others =>
          addr := (others => 'X');
          return addr;
      end case;
    end if;
  end function;

  function compare_hwdata(
    n : in ahb_slv_in_type;
    o : in ahb_slv_in_type)
        return boolean is
    variable offset, size : integer;
  begin
    if o.hsize = HSIZE_8WORD then
      assert o.hwdata'length >= 256
        report "HSIZE_8WORD detected but bus width is less than 256"
        severity failure;      
    elsif o.hsize = HSIZE_4WORD then
      assert o.hwdata'length >= 128
        report "HSIZE_4WORD detected but bus width is less than 128"
        severity failure;
    elsif o.hsize = HSIZE_DWORD then
      assert o.hwdata'length >= 64
          report "HSIZE_DWORD detected but bus width is less than 64"
          severity failure;
    end if;

    size := 8*2**conv_integer(o.hsize);
    offset := ahb_doff(AHBDW, size, o.haddr(4 downto 0));

    return (n.hwdata(size-1+offset downto offset) /=
            o.hwdata(size-1+offset downto offset));
  end function;

  type split_retry_slv_in_array is array (0 to NAHBM-1) of ahb_slv_in_type;

  type reg_type is record
    war          : std_ulogic;
    err          : std_ulogic;
    errno        : integer range 0 to 299;
    errid        : integer range 0 to 127;    
    split        : std_logic_vector(0 to NAHBMST-1);
    retry        : std_logic_vector(0 to NAHBMST-1);
    split_slv    : split_retry_slv_in_array;
    retry_slv    : split_retry_slv_in_array;
    amr          : ahb_mst_in_type;
    amr2         : ahb_mst_in_type;
    amvr         : ahb_mst_out_vector;
    amvr2        : ahb_mst_out_vector;
    amc          : ahb_mst_in_type;
    amvc         : ahb_mst_out_vector;
    asr          : ahb_slv_in_type;
    asr2         : ahb_slv_in_type;
    asvr         : ahb_slv_out_vector;
    asc          : ahb_slv_in_type;
    asvc         : ahb_slv_out_vector;
    waitcnt      : integer;
    splitc       : std_logic_vector(NAHBMST-1 downto 0);
    dummymst     : boolean;
    dmstndx      : integer;
  end record;

  constant hmstdis : std_logic_vector(31 downto 0) := conv_std_logic_vector(hmstdisable, 32);
  constant hslvdis : std_logic_vector(31 downto 0) := conv_std_logic_vector(hslvdisable, 32);
  constant arbdis  : std_logic_vector(31 downto 0) := conv_std_logic_vector(arbdisable, 32);

  signal r, rin   : reg_type;
  signal rst_act  : integer := 0;
-- pragma translate_on
begin
-- pragma translate_off
  
  assertproc: process(clk,rst) is
    variable rst_done : integer := 0;
  begin    
    if rst='0' then
      rst_done := 0;
    end if;
    if rising_edge(clk) and rst_done=1 then
      if r.err='1' and asserterr=1 then
        assert false report "ERROR " & errltr(r.errno) & tost(r.errno mod 100) & ": " & errstr(r.errno,r.errid) severity error;
      end if;
      if r.war='1' and assertwarn=1 then
        assert false report "WARNING " & errltr(r.errno) & tost(r.errno mod 100) & ": " & errstr(r.errno,r.errid) severity warning;
      end if;
    end if;
    if rising_edge(rst) then
      rst_done := 1;
    end if;    
  end process;

  
  comb : process(rst, r, ahbmi, ahbmo, ahbsi, ahbso, rst_act) is
    variable v        : reg_type;
    variable hmast    : integer;
    variable rhmast   : integer;
    variable hslave   : integer;
    variable rhslave  : integer;
    variable found    : integer;
  begin
    v := r; 
    v.err := '0';
    v.war := '0';
    
    hmast  := conv_integer(ahbsi.hmaster);
    rhmast := conv_integer(r.asr.hmaster);
    hslave := 0; rhslave := 0;
    for j in 0 to nahbs-1 loop
      if ahbsi.hsel(j) = '1' then
        hslave := j;
      end if;
      if r.asr.hsel(j) = '1' then
        rhslave := j;
      end if;
    end loop;

    --store current values on rising_edge when hready='1'
    if ahbmi.hready = '1' then
      v.amr   := ahbmi;
      v.amvr  := ahbmo;
      v.amvr2 := r.amvr;
      v.amr2  := r.amr;
    end if;
    if ahbsi.hready = '1' then
      v.asr  := ahbsi;
      v.asvr := ahbso;
      v.asr2 := r.asr;
    end if;
    --store current values on every rising edge
    v.amc   := ahbmi;
    v.amvc  := ahbmo;
    v.asc   := ahbsi;
    v.asvc  := ahbso;

    for i in 0 to nahbs-1 loop
      v.splitc := v.splitc or ahbso(i).hsplit;
    end loop;

    --store ahb slave in vector when RETRY or SPLIT is returned
    if (ahbmi.hready = '1') then
      if (ahbmi.hresp = HRESP_SPLIT) then
        v.split(rhmast) := '1';
        v.split_slv(rhmast) := r.asr;
      end if;
      if (ahbmi.hresp = HRESP_RETRY) then
        v.retry(rhmast) := '1';
        v.retry_slv(rhmast) := r.asr;
      end if;
    end if;

    --determine if dummy master should be selected
    if r.dummymst and (r.splitc(r.dmstndx) = '0') then
      v.dummymst := false; 
    end if;
    
    if (ahbmi.hready = '1') and (ahbmi.hresp = HRESP_SPLIT) then
      if r.asr.hmastlock = '1' then
        v.dummymst := true; v.dmstndx := conv_integer(r.asr.hmaster);
      end if;
    end if;
       
    --All rules are numbered. See documentation in grip for ambamon to see
    --exact description of what is checked.

    ----------------------------------------------------------------------------
    -- AHB Master Checks
    ----------------------------------------------------------------------------
    --1 Busy Check
    if hmstdis(1) = '0' then
      if (ahbsi.htrans = HTRANS_BUSY) and (r.asr.htrans = HTRANS_IDLE) then
        v.err := '1';
        v.errno := 1;
      end if;
    end if;

    --2 Busy Check
    if hmstdis(2) = '0' then
      if ((ahbsi.htrans = HTRANS_IDLE) or (ahbsi.htrans = HTRANS_NONSEQ)) and
         (r.asr.htrans = HTRANS_BUSY) and (r.asr.hburst /= HBURST_INCR) then
        v.err := '1';
        v.errno := 2;
      end if;
    end if;

    --3 Address/control during busy
    if hmstdis(3) = '0' then
      if (ahbsi.htrans = HTRANS_BUSY) and (ebterm = 0 or ahbsi.hmaster = r.asr.hmaster) and
         ((r.asr.htrans = HTRANS_NONSEQ) or (r.asr.htrans = HTRANS_SEQ)) and
         ((ahbsi.haddr /= next_addr(r.asr)) or
          (ahbsi.hsize /= r.asr.hsize) or
          (ahbsi.hwrite /= r.asr.hwrite) or
          (ahbsi.hburst /= r.asr.hburst) or
          (ahbsi.hprot /= r.asr.hprot) or
          (ebterm = 0 and ahbsi.hmaster /= r.asr.hmaster)) then
        v.err := '1';
        v.errno := 3;
      end if;
    end if;

    --4 SEQ Check
    if hmstdis(4) = '0' then
      if (ahbsi.htrans = HTRANS_SEQ) and (r.asr.htrans = HTRANS_IDLE) then
        v.err := '1';
        v.errno := 4;
      end if;
    end if;

    --5 HSIZE maximum size
    if hmstdis(5) = '0' then
     if (8*2**conv_integer(ahbsi.hsize) > AHBDW) then
       v.err := '1';
       v.errno := 5;
      end if;
    end if;

    --6 HADDR must be aligned to the transfer size
    if hmstdis(6) = '0' then
      if ahbsi.hsize /= "000" then
        for i in 0 to conv_integer(ahbsi.hsize)-1 loop
          if ahbsi.haddr(i) = '1' then
            v.err := '1';
            v.errno := 6;
          end if;
        end loop;
      end if;
    end if;

    --7 Address/Control must be stable when hready is deasserted except for transitions from IDLE or BUSY. 
    if hmstdis(7) = '0' then
      if (r.asc.hready = '0') and (r.asc.htrans /= HTRANS_IDLE) and
         (r.asc.htrans /= HTRANS_BUSY) and (r.amc.hresp = HRESP_OKAY) and (
         (ahbsi.haddr /= r.asc.haddr) or
         (ahbsi.hsize /= r.asc.hsize) or
         (ahbsi.hwrite /= r.asc.hwrite) or
         (ahbsi.hburst /= r.asc.hburst) or
         (ahbsi.hprot /= r.asc.hprot) or
         (ahbsi.htrans /= r.asc.htrans) or
         (ahbsi.hmaster /= r.asc.hmaster)) then
        v.err := '1';
        v.errno := 7;
      end if;
    end if;

    --8 Address/control for consecutive busy
    if hmstdis(8) = '0' then
      if (ahbsi.htrans = HTRANS_BUSY) and
         (r.asr.htrans = HTRANS_BUSY) and
         ((ahbsi.haddr /= r.asr.haddr) or
          (ahbsi.hsize /= r.asr.hsize) or
          (ahbsi.hwrite /= r.asr.hwrite) or
          (ahbsi.hburst /= r.asr.hburst) or
          (ahbsi.hprot /= r.asr.hprot) or
          (ahbsi.hmaster /= r.asr.hmaster)) then
        v.err := '1';
        v.errno := 8;
      end if;
    end if;

    --9 Address and control for SEQ
    if hmstdis(9) = '0' then
      if (ahbsi.htrans = HTRANS_SEQ) and (ebterm = 0 or ahbsi.hmaster = r.asr.hmaster) and (
         (ahbsi.haddr /= next_addr(r.asr)) or
         (ahbsi.hsize /= r.asr.hsize) or
         (ahbsi.hwrite /= r.asr.hwrite) or
         (ahbsi.hburst /= r.asr.hburst) or
         (ahbsi.hprot /= r.asr.hprot) or
         (ebterm = 0 and ahbsi.hmaster /= r.asr.hmaster) ) then
        v.err := '1';
        v.errno := 9;
      end if;
    end if;

    --10 IDLE transfer during RETRY response
    if hmstdis(10) = '0' then
      if (ahbmi.hresp = HRESP_RETRY) and (ahbmi.hready = '1') and
         (ahbmo(rhmast).htrans /= HTRANS_IDLE) then
        v.err := '1';
        v.errno := 10;
      end if;
    end if;

    --11 IDLE transfer during SPLIT response
    if hmstdis(11) = '0' then
      if (ahbmi.hresp = HRESP_SPLIT) and (ahbmi.hready = '1') and
         (ahbmo(rhmast).htrans /= HTRANS_IDLE) then
        v.err := '1';
        v.errno := 11;
      end if;
    end if;

    --12 Reattempt transfer that received RETRY.
    if hmstdis(12) = '0' then
      if (ahbsi.hready = '1') and (
        (ahbsi.htrans = HTRANS_NONSEQ) or
        (ahbsi.htrans = HTRANS_SEQ)) and
        (r.retry(hmast) = '1') then
        v.retry(hmast) := '0';
        if (ahbsi.hsel /= r.retry_slv(hmast).hsel) or
           (ahbsi.haddr /= r.retry_slv(hmast).haddr) or
           (ahbsi.hwrite /= r.retry_slv(hmast).hwrite) or
           (ahbsi.htrans /= HTRANS_NONSEQ) or
           (ahbsi.hsize /= r.retry_slv(hmast).hsize) or
--##         (ahbsi.hburst /= r.retry_slv(hmast).hburst) or
           (ahbsi.hprot /= r.retry_slv(hmast).hprot) or
           (ahbsi.hmaster /= r.retry_slv(hmast).hmaster) then
          v.err := '1';
          v.errno := 12;
        end if;
      end if;
    end if;

    --13 Reattempt transfer that received SPLIT.
    if hmstdis(13) = '0' then
      if (ahbsi.hready = '1') and (
         (ahbsi.htrans = HTRANS_NONSEQ) or
         (ahbsi.htrans = HTRANS_SEQ)) and
         (r.split(hmast) = '1') then
        v.split(hmast) := '0'; v.splitc(hmast) := '0';
        if (ahbsi.hsel /= r.split_slv(hmast).hsel) or
           (ahbsi.haddr /= r.split_slv(hmast).haddr) or
           (ahbsi.hwrite /= r.split_slv(hmast).hwrite) or
           (ahbsi.htrans /= HTRANS_NONSEQ) or
           (ahbsi.hsize /= r.split_slv(hmast).hsize) or
--##         (ahbsi.hburst /= r.split_slv(hmast).hburst) or
           (ahbsi.hprot /= r.split_slv(hmast).hprot) or
           (ahbsi.hmaster /= r.split_slv(hmast).hmaster) then
          v.err := '1';
          v.errno := 13;
        end if;
      end if;
    end if;

    --14 Check that the following transfer is cancelled after ERROR responses
    --(this optional and only gives a warning).
    if hmstdis(14) = '0' then
      if (ahbmi.hresp = HRESP_ERROR) and (ahbmi.hready = '1') and
         (ahbsi.htrans /= HTRANS_IDLE) then
        v.war := '1';
        v.errno := 14;
      end if;
    end if;

    --15 Master must hold HWDATA stable through the whole data phase
    if hmstdis(15) = '0' then
      if ((r.asr.htrans = HTRANS_NONSEQ) or (r.asr.htrans = HTRANS_SEQ)) and
         (r.asr.hwrite = '1') and compare_hwdata(ahbsi, r.asc) and (r.asr.hready = '0') then
        v.err := '1';
        v.errno := 15;
      end if;
    end if;


    --16 An incrementing burst must not cross (wrapping cannot cross it) a 1 kB boundary
    if hmstdis(16) = '0' then
      if (ahbsi.htrans /= HTRANS_IDLE) and (ahbsi.htrans /= HTRANS_NONSEQ) and
         (ahbsi.hburst(0) = '1') and -- INCR, INCR4, INCR8, INCR16
         (ahbsi.haddr(9 downto 0) = "0000000000") then
        v.err := '1';
        v.errno := 16;
      end if;
    end if;
    
    --17 HMASTLOCK must be set during locked transfers
    
    --due to the ambiguous definition of "address phase" which on page 3-4
    --says that it is always one cycle but on page 3-6 also says it can be
    --extended necessitates a solution where lock can be set only at
    --hready='1' and at any time when hready = '0'.

    -- Check modified 2012-11-01: If a master performs the sequence:
    -- <acc0> <locked acc>
    -- and receives a SPLIT response to acc0 then AHBCTRL will not treat the
    -- retry of <acc0> as a locked access. Solve this by adding check for
    -- HRESP.
    if hmstdis(17) = '0' then
      if (r.amvr(hmast).hlock = '1') and (ahbsi.hmastlock /= '1') and
         orv(r.amr.hgrant) /= '0' and (r.amc.hresp(1) /= '1') then
        v.err := '1';
        v.errno := 17;
      end if;
    end if;

    if hmstdis(17) = '0' then
      if (r.amvc(hmast).hlock = '1') and (ahbsi.hmastlock /= '1') and
         (orv(r.amr.hgrant) /= '0') and (r.amc.hresp(1) /= '1') then
        v.err := '1';
        v.errno := 17;
      end if;
    end if;

    if hmstdis(17) = '0' then
      if (r.amvc(hmast).hlock = '0') and orv(r.amr.hgrant) /= '0' and
         (r.amvr(hmast).hlock = '0') and (ahbsi.hmastlock /= '0') then
        v.err := '1';
        v.errno := 17;
      end if;
    end if;

    --18 HLOCK must be asserted at least one cycle before the address to which it refers
    --this is not a complete test. It only covers the case when a NONSEQ transaction is
    --either not granted or hready is deasserted. Thus one can know that the current hlock
    --is referrring to the current access and not the next one.
    if hmstdis(18) = '0' then
      for j in 0 to nahbm-1 loop
        if (ahbmo(j).htrans = HTRANS_NONSEQ) and (ahbmo(j).hlock = '1') and
           (r.amvc(j).hlock /= '1') and (r.amr.hgrant(j) = '0' or ahbmi.hready = '0') and
           (ahbmi.hresp = HRESP_OKAY) then
          v.err := '1';
          v.errno := 18;
        end if;
      end loop;
    end if;

    --19 HLOCK must be asserted for the duration of a burst (Checked with HMASTLOCK
    --since HMASTLOCK is directly coupled to HLOCK and the relationship between
    --them is checked with M17
    if hmstdis(19) = '0' then
      if ((ahbsi.htrans = HTRANS_SEQ) or (ahbsi.htrans = HTRANS_BUSY)) and
         ((r.asr.htrans = HTRANS_SEQ) or (r.asr.htrans = HTRANS_BUSY) or
          (r.asr.htrans = HTRANS_NONSEQ)) and
          (r.asr.hmastlock /= ahbsi.hmastlock) then
        v.err := '1';
        v.errno := 19;
      end if;
    end if;

    --20 HLOCK must be deasserted during the last address phase of a burst (it
    --actually says "should deassert" in the AMBA FAQ and it is not possible to
    --determine if a master intends to continue performing locked accesses
    --after the burst, so this is reported as a WARNING instead of an error
    if hmstdis(20) = '0' then
      if (ahbsi.htrans /= HTRANS_SEQ and ahbsi.htrans /= HTRANS_BUSY) and
         ((r.asr.htrans = HTRANS_SEQ) or (r.asr.htrans = HTRANS_BUSY)) and
         (r.amvr2(rhmast).hlock = '1' and r.amvr(rhmast).hlock /= '0') and
         (ahbmi.hresp = HRESP_OKAY) then
        v.war := '1';
        v.errno := 20;
        v.errid := rhmast;
      end if;
    end if;

    --21 All masters must drive HTRANS to IDLE during reset
    if hmstdis(21) = '0' then
      if (rst = '0') and (rst_act = 1) then
        for j in 0 to nahbm-1 loop
          if ahbmo(j).htrans /= HTRANS_IDLE then
            v.err := '1';
            v.errno := 21;
            v.errid := j;
          end if;
        end loop;
      end if;
    end if;

    --22 HTRANS must only change from IDLE to NONSEQ when hready is deasserted 
    if hmstdis(22) = '0' then
      if (r.asc.hready = '0') and (r.asc.htrans = HTRANS_IDLE) and
         (ahbsi.htrans /= HTRANS_IDLE) and (ahbsi.htrans /= HTRANS_NONSEQ) then
        v.err := '1';
        v.errno := 22;
      end if;
    end if;

    ----------------------------------------------------------------------------
    -- AHB Slave Checks
    ----------------------------------------------------------------------------
    --1 Response to busy
    if hslvdis(1) = '0' then
      if (r.asc.htrans = HTRANS_BUSY) and (r.asc.hready = '1') and 
         ((ahbmi.hready /= '1') or (ahbmi.hresp /= HRESP_OKAY)) then
        v.err := '1';
        v.errno := 101;
      end if;
    end if;  

    --2 Response to idle
    if hslvdis(2) = '0' then
      if (r.asc.htrans = HTRANS_IDLE) and (r.asc.hready = '1') and
         ((ahbmi.hready /= '1') or (ahbmi.hresp /= HRESP_OKAY)) then
        v.err := '1';
        v.errno := 102;
      end if;
    end if;

    --3 ERROR, SPLIT, RETRY maximum one cycle when HREADY is low
    if hslvdis(3) = '0' then
      if ((r.amc.hresp = HRESP_ERROR) or (r.amc.hresp = HRESP_SPLIT) or
          (r.amc.hresp = HRESP_RETRY)) and (r.amc.hready = '0') and
         ((ahbmi.hresp = HRESP_ERROR) or (ahbmi.hresp = HRESP_SPLIT) or
          (ahbmi.hresp = HRESP_RETRY)) and (ahbmi.hready = '0') then
        v.err := '1';
        v.errno := 103;
      end if;
    end if;

    --4 Two cycle ERROR response
    if hslvdis(4) = '0' then
      if ((ahbmi.hresp = HRESP_ERROR) and (ahbmi.hready = '1') and (
          (r.amc.hresp /= HRESP_ERROR) or (r.amc.hready /= '0'))) or
         ((r.amc.hresp = HRESP_ERROR) and (r.amc.hready = '0') and (
           (ahbmi.hresp /= HRESP_ERROR) or (ahbmi.hready /= '1'))) then
        v.err := '1';
        v.errno := 104;
      end if;
    end if;

    --5 Two cycle SPLIT response
    if hslvdis(5) = '0' then
      if ((ahbmi.hresp = HRESP_SPLIT) and (ahbmi.hready = '1') and (
          (r.amc.hresp /= HRESP_SPLIT) or (r.amc.hready /= '0'))) or
         ((r.amc.hresp = HRESP_SPLIT) and (r.amc.hready = '0') and (
           (ahbmi.hresp /= HRESP_SPLIT) or (ahbmi.hready /= '1'))) then
        v.err := '1';
        v.errno := 105;
      end if;
    end if;

    --6 Two cycle RETRY response
    if hslvdis(6) = '0' then
      if ((ahbmi.hresp = HRESP_RETRY) and (ahbmi.hready = '1') and (
          (r.amc.hresp /= HRESP_RETRY) or (r.amc.hready /= '0'))) or
         ((r.amc.hresp = HRESP_RETRY) and (r.amc.hready = '0') and (
           (ahbmi.hresp /= HRESP_RETRY) or (ahbmi.hready /= '1'))) then
        v.err := '1';
        v.errno := 106;
      end if;
    end if;

    --7 Split to master which has not been given a split response
    if hslvdis(7) = '0' then
      for i in 0 to nahbs-1 loop
        for j in 0 to 15 loop
          if (ahbso(i).hsplit(j) = '1') and (r.split(j) = '0') then
            v.err := '1';
            v.errno := 107;
            v.errid := i;
          end if;
        end loop;
      end loop;
    end if;

    --8 Split complete cannot be asserted on the same cycle as SPLIT response is given for the
    --same master
    if hslvdis(8) = '0' then
      if (ahbmi.hready = '1') and (ahbmi.hresp = HRESP_SPLIT) and
         (ahbso(hslave).hsplit(rhmast) = '1') then
        v.err := '1';
        v.errno := 108;
      end if;
    end if;

    --9 It is recommended that hready='0' and hresp=OKAY when slave is not selected
    if hslvdis(9) = '0' then
      for i in 0 to nahbs-1 loop
        if ((ahbso(i).hready = '0') or (ahbso(i).hresp /= HRESP_OKAY)) and (r.asr.hsel(i) = '0') then
          v.war := '1';
          v.errno := 109;
          v.errid := i;
        end if;
      end loop;
    end if;

    --10 It is recommended that no more than 16 wait states are inserted by a slave
    if ahbmi.hready = '1' then
      v.waitcnt := 0;
    else
      v.waitcnt := r.waitcnt + 1;
    end if;

    if hslvdis(10) = '0' then
      if r.waitcnt > 16 then
        v.war := '1';
        v.errno := 110;
      end if;
    end if;  

    --11 Slaves should only return Split complete once for each SPLIT response
    if hslvdis(11) = '0' then
      for i in 0 to nahbs-1 loop
        if (ahbso(i).hsplit and r.splitc) /= zero32(NAHBMST-1 downto 0) then
          v.war := '1';
          v.errno := 111;
          v.errid := i;
        end if;
      end loop;
    end if;
    
    ----------------------------------------------------------------------------
    -- ARBITER Checks
    ----------------------------------------------------------------------------
    --1 Global Hready routed from selected slave
    if arbdis(1) = '0' then
      if (ahbsi.hready /= ahbso(rhslave).hready) and (orv(r.asr.hsel) = '1') then
        v.err := '1';
        v.errno := 201;
      end if;
    end if;

    --2 Master which received split response must not be granted the bus until slave sets HSPLIT
    if arbdis(2) = '0' then
      for i in 0 to nahbm-1 loop
        if (ahbmi.hgrant(i) = '1') and (r.split(i) = '1') and (r.splitc(i) = '0') then
          v.err := '1';
          v.errno := 202;
          v.errid := i;
        end if;
      end loop;
    end if;

    --3 Dummy master must be selected for locked splits
    if arbdis(3) = '0' then
      if r.dummymst and orv(ahbmi.hgrant) /= '0' then
        v.err := '1';
        v.errno := 203;
      end if;
    end if;

    if rst = '0' then
      v.err := '0'; v.split := (others => '0'); v.war := '0';
      v.retry := (others => '0'); v.waitcnt := 0;
      v.splitc := (others => '0');
      v.dummymst := false; 
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

