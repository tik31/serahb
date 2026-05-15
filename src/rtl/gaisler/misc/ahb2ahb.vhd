------------------------------------------------------------------------------
--  This file is a part of the GRLIB VHDL IP LIBRARY
--  Copyright (C) 2017, Cobham Gaisler AB - all rights reserved.
--
-- ANY USE OR REDISTRIBUTION IN PART OR IN WHOLE MUST BE HANDLED IN 
-- ACCORDANCE WITH THE GAISLER LICENSE AGREEMENT AND MUST BE APPROVED 
-- IN ADVANCE IN WRITING. 
----------------------------------------------------------------------------
-- Entity:      ahb2ahb
-- File:        ahb2ahb.vhd
-- Author:      Edvin Catovic, Gaisler Research
-- Modified:    Jan Andersson, Aeroflex Gaisler
-- Contact:     support@gaisler.com
-- Description: AHB to AHB bridge (uni-directional)
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
library grlib;
use grlib.config_types.all;
use grlib.config.all;
use grlib.stdlib.all;
use grlib.amba.all;
use grlib.devices.all;
library gaisler;
use gaisler.misc.all;
library techmap;
use techmap.gencomp.all;

entity ahb2ahb is
  generic(
    memtech     : integer := 0;
    hsindex     : integer := 0;
    hmindex     : integer := 0;
    slv         : integer range 0 to 1 := 0;
    dir         : integer range 0 to 1 := 0;   -- 0 - down, 1 - up
    ffact       : integer range 0 to 15 := 2;
    pfen        : integer range 0 to 1 := 0;
    wburst      : integer range 2 to 32 := 8;
    iburst      : integer range 4 to 8 :=  8;
    rburst      : integer range 2 to 32 := 8;
    irqsync     : integer range 0 to 3 := 0;
    bar0        : integer range 0 to 1073741823 := 0;
    bar1        : integer range 0 to 1073741823 := 0;
    bar2        : integer range 0 to 1073741823 := 0;
    bar3        : integer range 0 to 1073741823 := 0;
    sbus        : integer := 0;
    mbus        : integer := 0;
    ioarea      : integer := 0;
    ibrsten     : integer := 0;
    lckdac      : integer range 0 to 2 := 0;
    slvmaccsz   : integer range 32 to 256 := 32;
    mstmaccsz   : integer range 32 to 256 := 32;
    rdcomb      : integer range 0 to 2 := 0;
    wrcomb      : integer range 0 to 2 := 0;
    combmask    : integer := 16#ffff#;
    allbrst     : integer range 0 to 2 := 0;
    ifctrlen    : integer range 0 to 1 := 0;
    fcfs        : integer range 0 to NAHBMST := 0;
    fcfsmtech   : integer range 0 to NTECH := inferred;
    scantest    : integer range 0 to 1 := 0;
    split       : integer range 0 to 1 := 1;
    pipe        : integer range 0 to 128 := 0);
  port (
    rstn        : in  std_ulogic;
    hclkm       : in  std_ulogic;
    hclks       : in  std_ulogic;
    ahbsi       : in  ahb_slv_in_type;
    ahbso       : out ahb_slv_out_type;
    ahbmi       : in  ahb_mst_in_type;
    ahbmo       : out ahb_mst_out_type;
    ahbso2      : in  ahb_slv_out_vector;
    lcki        : in  ahb2ahb_ctrl_type;
    lcko        : out ahb2ahb_ctrl_type;
    ifctrl      : in  ahb2ahb_ifctrl_type := ahb2ahb_ifctrl_none;
    idle        : out std_ulogic
    );
end;

architecture rtl of ahb2ahb is

  -----------------------------------------------------------------------------
  -- Constants
  -----------------------------------------------------------------------------
  constant DOWN : boolean := (dir = 0);
  constant UP   : boolean := not DOWN;

  -- Core version
  constant AHB2AHB_VER : amba_version_type := 2;

  -- Highest interrupt line that will be forwarded
  constant IRQH : integer := 15 + 16 * (irqsync/2) + 32 * (irqsync/3);
  -- Lowest interrupt line that will be forwarded
  -- Workaround for DC bug
  --constant IRQL : integer := conv_integer(conv_std_logic_vector(irqsync, 2) and conv_std_logic_vector(1, 2));
  function IRQL return integer is
  begin
    if irqsync = 1 then return 1; end if;
    return 0;
  end;
  
  -- Include logic for handling simultaneous locked accesses in bidir config
  constant DBLLCK : boolean := lckdac > 0;  

  -- Resolve dead lock condition due to locked transfer while in SPLIT by
  -- responding with ERROR to locked access.
  constant SPLNOLCK : boolean := lckdac = 1 and split /= 0;

  -- Allow locked accesses while in SPLIT
  constant SPLANDLCK : boolean := lckdac = 2 and split /= 0;

  -- Maximum slave access size
  constant SMAXDW : integer := slvmaccsz;

  -- Maximum master access size 
  constant MMAXDW : integer := mstmaccsz;

  -- Do not use match variable in slave process
  constant MATCHDIS : boolean := ((fcfs = 0) and not SPLANDLCK) or (split = 0); 

  -- CHECKRACE1: Clock frequency on master i/f is lower
  constant CHECKRACE1 : boolean := (DOWN and FFACT > 1);
  -- CHECKRACE2: Clock frequency on master i/f is higher
  constant CHECKRACE2 : boolean := (UP and ffact > 2) and (pipe = 0);
  -- CHECKRACE3: Clock frequency on master is higher or equal to slave i/f
  constant CHECKRACE3 : boolean := (UP or FFACT = 1) or (pipe /= 0);
  
  -- Maximum of slvmaccsz and mstmaccsz
  function maxdw return integer is
  begin  -- maxdw
    if slvmaccsz > mstmaccsz then return slvmaccsz; end if;
    return mstmaccsz;
  end maxdw;

  -- Return minimum of slvmaccsz and mstmaccsz
  function mindw return integer is
  begin  -- mindw
    if slvmaccsz > mstmaccsz then return mstmaccsz; end if;
    return slvmaccsz;
  end mindw;
  
  constant ibbits : integer := log2(iburst);

  constant rbbits : integer := log2(rburst);

  constant wbbits : integer := log2(wburst);
  
  -- Required number of address bits for the read buffer
  function rbufbits return integer is
  begin  -- rbufbits
    if (ibrsten /= 0) and (rbbits < ibbits) then
      return ibbits;
    end if;
    return rbbits;
  end rbufbits;

  -- Maximum required number of address bits for buffers
  function bbits return integer is
  begin  -- bbits
    if (rbufbits < wbbits) then
      return wbbits;
    end if;
    return rbufbits;
  end bbits;

  -- Number of required fcfs bits, work around tool issues with null arrays
  function fcfs_bits return integer is
  begin -- fcfs_bits
    if fcfs = 0 then
      return 1;
    end if;
    return log2x(fcfs);
  end fcfs_bits;

  -- Returns 1 if syncram_2p RAMs used for prefetch and write buffers are
  -- running on separate clocks.
  function rwbuf_sepclk return integer is
  begin
    if ffact /= 1 then return 1; end if;
    return 0;
  end rwbuf_sepclk;
  
  -----------------------------------------------------------------------------
  -- Types
  -----------------------------------------------------------------------------
  type slave_state_type is (sidle, split2, ret, saddr, sdata, bfill, bflush, pfsplit, pfread);

--   subtype slave_state_type is std_logic_vector(3 downto 0);

--   constant sidle   : slave_state_type := "0000";
--   constant split2  : slave_state_type := "0001";
--   constant ret     : slave_state_type := "0010";
--   constant saddr   : slave_state_type := "0011";
--   constant sdata   : slave_state_type := "0100";
--   constant bfill   : slave_state_type := "0101";
--   constant bflush  : slave_state_type := "0110";
--   constant pfsplit : slave_state_type := "0111";
--   constant pfread  : slave_state_type := "1000";

  type split_save_type is record
    act       : std_ulogic;
    abort     : std_ulogic;
    mst       : std_logic_vector(3 downto 0);
    hrdata    : std_logic_vector(SMAXDW-1 downto 0);
    hresp     : std_logic_vector(1 downto 0);
    unsplit   : std_ulogic;             -- Used with FCFS
    pfact     : std_ulogic;             -- Used with PF
    rbaddr    : std_logic_vector(rbufbits-1 downto 0);
    err       : std_ulogic;
    nofetch   : std_ulogic;
    sphold    : std_ulogic;
  end record;

  type fcfs_split_type is record
    act       : std_ulogic;
    si        : std_logic_vector(fcfs_bits-1 downto 0);  -- Split index
    ui        : std_logic_vector(fcfs_bits-1 downto 0);  -- Unsplit index
    splmst    : std_logic_vector(3 downto 0);  -- Active master
    lcksmst   : std_logic_vector(3 downto 0);  -- Saved master during locked access
    lck       : std_ulogic;             -- Locked access
    rethold   : std_ulogic;             -- Do not issue complete SPLIT
    sp2hold   : std_ulogic;             -- Do not issue complete SPLIT
    hold      : std_ulogic;             -- Do not issue complete SPLIT
    keep      : std_ulogic;             -- Keep master first in queue
    handled   : std_ulogic;             -- Current access handled
    retwait   : std_ulogic;             -- Waiting for return of master, do not
                                        -- advance queue
  end record;
  
  type slave_type is record
    haddr	: std_logic_vector(31 downto 0);
    wbhaddr     : std_logic_vector(4 downto 2);  -- Utilized for data mux:ing
    hwrite      : std_ulogic;
    htrans	: std_logic_vector(1 downto 0);
    hsize	: std_logic_vector(2 downto 0);
    hburst	: std_logic_vector(2 downto 0);
    hprot	: std_logic_vector(3 downto 0);
    hmastlock	: std_ulogic;

    hready	: std_ulogic;
    hresp	: std_logic_vector(1 downto 0);

    state       : slave_state_type;
    splmst      : std_logic_vector(log2(NAHBMST)-1 downto 0);
    rbaddr      : std_logic_vector(rbufbits-1 downto 0);
    wbaddr      : std_logic_vector(wbbits-1 downto 0);

    hrdata      : std_logic_vector(SMAXDW-1 downto 0);
    hsplit      : std_logic_vector(NAHBMST-1 downto 0);

    race        : std_ulogic;
    bfull       : std_ulogic;
    err         : std_ulogic;
    ba          : std_ulogic;
    nsplit      : std_ulogic;
    ardy        : std_ulogic;
    mwreq       : std_ulogic;

    mstlock     : std_ulogic;

    wr          : std_ulogic;

    nwords      : std_logic_vector(bbits downto 0);  -- # 32-bit words

    pfhsize     : std_logic_vector(2 downto 0);  -- hsize to read out pfdata
    
    -- Registers for saved response when lckdac = 2
    sv          : split_save_type;

    -- Registers for controlling fcfs splits
    fcfs        : fcfs_split_type;

    sp2tog      : std_ulogic;
  end record;                          

  type master_state_type is (midle, addr0, data0, wreq, maddr, mdata, mdata2, mdata2x, wrburst,
                             wrburst2, pfget, pfrdy, brel);

--   subtype master_state_type is std_logic_vector(3 downto 0);
  
--   constant midle    : master_state_type := "0000";
--   constant addr0    : master_state_type := "0001";
--   constant data0    : master_state_type := "0010";
--   constant wreq     : master_state_type := "0011";
--   constant maddr    : master_state_type := "0100";
--   constant mdata    : master_state_type := "0101";
--   constant mdata2   : master_state_type := "0110";
--   constant mdata2x  : master_state_type := "0111";
--   constant wrburst  : master_state_type := "1000";
--   constant wrburst2 : master_state_type := "1001";
--   constant pfget    : master_state_type := "1010";
--   constant pfrdy    : master_state_type := "1011";
--   constant brel     : master_state_type := "1100";
  
  type master_type is record
    haddr	: std_logic_vector(31 downto 0);
    hwrite      : std_ulogic;
    htrans	: std_logic_vector(1 downto 0);
    hsize	: std_logic_vector(2 downto 0);
    hburst	: std_logic_vector(2 downto 0);
    hprot	: std_logic_vector(3 downto 0);
    hmastlock   : std_ulogic;

    hdata       : std_logic_vector(maxdw-1 downto 0);
    hresp       : std_logic_vector(1 downto 0);
    ba          : std_ulogic;
    bg          : std_ulogic;
    bl          : std_ulogic;

    state       : master_state_type;
    resp2c      : std_ulogic;
    rbaddr      : std_logic_vector(rbufbits-1 downto 0);
    wbaddr      : std_logic_vector(wbbits-1 downto 0);
    nseq        : std_ulogic;
    err         : std_ulogic;
    ldp         : std_ulogic;
    bsycnt      : std_logic_vector(3 downto 0);
    nbsy        : std_ulogic;

    nwords      : std_logic_vector(bbits downto 0);  -- # 32-bit words
    
    rdcnt       : std_logic_vector(log2(SMAXDW/MMAXDW) downto 0); -- # accesses
    rdw         : std_logic_vector(0 to (SMAXDW/MMAXDW-1)*SMAXDW/maxdw);

    mwreq       : std_ulogic;
    addrlock    : std_ulogic;

    sp2tog      : std_ulogic;
  end record;

  type slave_to_master_type is record
    state     : slave_state_type;
    hmastlock : std_ulogic;
    ardy      : std_ulogic;
    nofetch   : std_ulogic;
    rbaddr    : std_logic_vector(rbufbits-1 downto 0);
    race      : std_ulogic;
    sp2tog    : std_ulogic;
    nwords    : std_logic_vector(bbits downto 0);
    haddr     : std_logic_vector(31 downto 0);
    hsize     : std_logic_vector(2 downto 0);
    hprot     : std_logic_vector(3 downto 0);
    hwrite    : std_ulogic;
    htrans    : std_logic_vector(1 downto 0);
    hburst    : std_logic_vector(2 downto 0);
  end record;

  type master_to_slave_type is record
    state     : master_state_type;
    mwreq     : std_ulogic;
    hdata     : std_logic_vector(SMAXDW-1 downto 0);
    hresp     : std_logic_vector(1 downto 0);
    err       : std_ulogic;
    rbaddr    : std_logic_vector(rbufbits-1 downto 0);
  end record;
  
  -----------------------------------------------------------------------------
  -- Constants used for option to reset all registers
  -----------------------------------------------------------------------------
  constant RESET_ALL : boolean := GRLIB_CONFIG_ARRAY(grlib_sync_reset_enable_all) = 1;

  function master_type_reset_func return master_type is
    variable m : master_type;
  begin
    m.haddr	:= (others => '0');
    m.hwrite    := '0';
    m.htrans	:= (others => '0');
    m.hsize	:= (others => '0');
    m.hburst	:= (others => '0');
    m.hprot	:= (others => '0');
    m.hmastlock := '0';
    m.hdata     := (others => '0');
    m.hresp     := (others => '0');
    m.ba        := '0';
    m.bg        := '0';
    m.bl        := '0';
    m.state     := midle;
    m.resp2c    := '0';
    m.rbaddr    := (others => '0');
    m.wbaddr    := (others => '0');
    m.nseq      := '0';
    m.err       := '0';
    m.ldp       := '0';
    m.bsycnt    := (others => '0');
    m.nbsy      := '1';
    m.nwords    := (others => '0');
    m.rdcnt     := (others => '0');
    m.rdw       := (others => '0');
    m.mwreq     := '0';
    m.addrlock  := '0';
    m.sp2tog    := '0';
    return m;
  end master_type_reset_func;

  constant MRES : master_type := master_type_reset_func;

  function slave_type_reset_func return slave_type is
    variable s : slave_type;
  begin
    s.haddr	   := (others => '0');
    s.wbhaddr      := (others => '0');
    s.hwrite       := '0';
    s.htrans	   := (others => '0');
    s.hsize	   := (others => '0');
    s.hburst	   := (others => '0');
    s.hprot	   := (others => '0');
    s.hmastlock	   := '0';
    s.hready	   := '1';
    s.hresp	   := (others => '0');
    s.state        := sidle;
    s.splmst       := (others => '0');
    s.rbaddr       := (others => '0');
    s.wbaddr       := (others => '0');
    s.hrdata       := (others => '0');
    s.hsplit       := (others => '0');
    s.race         := '0';
    s.bfull        := '0';
    s.err          := '0';
    s.ba           := '0';
    s.nsplit       := '0';
    s.ardy         := '0';
    s.mwreq        := '0';
    s.mstlock      := '0';
    s.wr           := '0';
    s.nwords       := (others => '0');
    s.pfhsize      := (others => '0');
    s.sv.act       := '0';
    s.sv.abort     := '0';
    s.sv.mst       := (others => '0');
    s.sv.hrdata    := (others => '0');
    s.sv.hresp     := (others => '0');
    s.sv.unsplit   := '0';
    s.sv.pfact     := '0';
    s.sv.rbaddr    := (others => '0');
    s.sv.err       := '0';
    s.sv.nofetch   := '0';
    s.sv.sphold    := '0';
    s.fcfs.act     := '0';
    s.fcfs.si      := (others => '0');
    s.fcfs.ui      := (others => '0');
    s.fcfs.splmst  := (others => '0');
    s.fcfs.lcksmst := (others => '0');
    s.fcfs.lck     := '0';
    s.fcfs.rethold := '0';
    s.fcfs.sp2hold := '0';
    s.fcfs.hold    := '0';
    s.fcfs.keep    := '0';
    s.fcfs.handled := '0';
    if fcfs /= 0 then
      s.fcfs.handled := '1';
    end if;      
    s.fcfs.retwait := '0';
    s.sp2tog       := '0';
    return s;
  end slave_type_reset_func;

  constant SRES : slave_type := slave_type_reset_func;
  
  -----------------------------------------------------------------------------
  -- Subprograms
  -----------------------------------------------------------------------------
  -- Used to increment haddr
  function addrinc(rm : master_type) return std_logic_vector is
    variable newaddr : std_logic_vector(31 downto 0);
    variable addrx : std_logic_vector(9 downto 0);
    variable inc : std_logic_vector(5 downto 0);
  begin
    newaddr := rm.haddr;
    inc := (others => '0');
    if MMAXDW > 32 then
      inc(conv_integer(rm.hsize(2 downto 0))) := '1';
    else
      inc(conv_integer(rm.hsize(1 downto 0))) := '1';
      inc(5 downto 3) := "000";
    end if;
    
    addrx := rm.haddr(9 downto 0) + inc;
    if allbrst = 0 then
      newaddr(9 downto 0) := addrx;
    else
      case rm.hburst is
        when HBURST_SINGLE | HBURST_INCR | HBURST_INCR4 | HBURST_INCR8 | HBURST_INCR16 =>
          newaddr(9 downto 0) := addrx;
        when HBURST_WRAP4 =>
          case rm.hsize is
            when HSIZE_BYTE =>
              newaddr(1 downto 0) := addrx(1 downto 0);
            when HSIZE_HWORD =>
              newaddr(2 downto 0) := addrx(2 downto 0);
            when HSIZE_WORD =>
              newaddr(3 downto 0) := addrx(3 downto 0);
            when HSIZE_DWORD =>
              if MMAXDW > 32 then newaddr(4 downto 0) := addrx(4 downto 0);
              else null; end if;
            when HSIZE_4WORD =>
              if MMAXDW > 64 then newaddr(5 downto 0) := addrx(5 downto 0);
              else null; end if;
            when others =>                -- HSIZE_8WORD
              if MMAXDW > 128 then newaddr(6 downto 0) := addrx(6 downto 0);
              else null; end if;
          end case;
        when HBURST_WRAP8 =>
          case rm.hsize is
            when HSIZE_BYTE =>
              newaddr(2 downto 0) := addrx(2 downto 0);
            when HSIZE_HWORD =>
              newaddr(3 downto 0) := addrx(3 downto 0);
            when HSIZE_WORD =>
              newaddr(4 downto 0) := addrx(4 downto 0);
            when HSIZE_DWORD =>
              if MMAXDW > 32 then newaddr(5 downto 0) := addrx(5 downto 0);
              else null; end if;
            when HSIZE_4WORD =>
              if MMAXDW > 64 then newaddr(6 downto 0) := addrx(6 downto 0);
              else null; end if;
            when others =>                -- HSIZE_8WORD
              if MMAXDW > 128 then newaddr(7 downto 0) := addrx(7 downto 0);
              else null; end if;
          end case;
        when HBURST_WRAP16 =>
          case rm.hsize is
            when HSIZE_BYTE =>
              newaddr(3 downto 0) := addrx(3 downto 0);
            when HSIZE_HWORD =>
              newaddr(4 downto 0) := addrx(4 downto 0);
            when HSIZE_WORD =>
              newaddr(5 downto 0) := addrx(5 downto 0);
            when HSIZE_DWORD =>
              if MMAXDW > 32 then newaddr(6 downto 0) := addrx(6 downto 0);
              else null; end if;
            when HSIZE_4WORD =>
              if MMAXDW > 64 then newaddr(7 downto 0) := addrx(7 downto 0);
              else null; end if;
            when others =>                -- HSIZE_8WORD
              if MMAXDW > 128 then newaddr(8 downto 0) := addrx(8 downto 0);
              else null; end if;
          end case;
        when others =>
      end case;
    end if;
    return(newaddr);
  end;

  -- Used to increment read/write buffer address
  function baddrinc (
    constant max : integer;
    baddr        : std_logic_vector;
    hsize        : std_logic_vector(2 downto 0))
    return std_logic_vector is
    variable newaddr : std_logic_vector(7 downto 0);
    variable inc : std_logic_vector(5 downto 0);
    variable vhsize : std_logic_vector(2 downto 0);
  begin
    inc := (others => '0');
    vhsize := hsize;
    if hsize = HSIZE_BYTE or hsize = HSIZE_HWORD then
      vhsize := HSIZE_WORD;
    end if;
    if max > 32 then
      inc(conv_integer(vhsize(2 downto 0))) := '1';
    else
      inc(conv_integer(vhsize(1 downto 0))) := '1';
      inc(5 downto 3) := "000";
    end if;
    if baddr'length < 4 then
      newaddr(5 downto 0) := (baddr & "00") + inc;
    else
      newaddr(baddr'length+1 downto 0) := (baddr & "00") + inc;
    end if;
    return(newaddr(baddr'length+1 downto 2));
  end;

  -- Used to decrement read/write buffer address
  function baddrdec (
    constant max : integer;
    baddr        : std_logic_vector;
    hsize        : std_logic_vector(2 downto 0))
    return std_logic_vector is
    variable newaddr : std_logic_vector(7 downto 0);
    variable dec : std_logic_vector(5 downto 0);
    variable vhsize : std_logic_vector(2 downto 0);
  begin
    dec := (others => '0');
    vhsize := HSIZE;
    if hsize = HSIZE_BYTE or hsize = HSIZE_HWORD then
      vhsize := HSIZE_WORD;
    end if;
    if max > 32 then
      dec(conv_integer(vhsize(2 downto 0))) := '1';
    else
      dec(conv_integer(vhsize(1 downto 0))) := '1';
      dec(5 downto 3) := "000";
    end if;
    if baddr'length < 4 then
      newaddr(5 downto 0) := (baddr & "00") - dec;
    else
      newaddr(baddr'length+1 downto 0) := (baddr & "00") - dec;
    end if;
    return(newaddr(baddr'length+1 downto 2));
  end;

  -- Used to increment number of words in write buffer
  function winc (
    constant max : integer;
    nwords       : std_logic_vector(bbits downto 0);
    hsize        : std_logic_vector(2 downto 0))
    return std_logic_vector is
    variable newnwords : std_logic_vector(bbits downto 0);
  begin
    if max > 128 and hsize = HSIZE_8WORD then
      newnwords := nwords + 8;
    elsif max > 64 and hsize = HSIZE_4WORD then
      newnwords := nwords + 4;
    elsif max > 32 and hsize = HSIZE_DWORD then
      newnwords := nwords + 2;
    else
      newnwords := nwords + 1;
    end if;

    return newnwords;
  end;

  -- Used to decrement number of words in write buffer
  function wdec (
    constant max : integer;
    nwords       : std_logic_vector(bbits downto 0);
    hsize        : std_logic_vector(2 downto 0))
    return std_logic_vector is
    variable newnwords : std_logic_vector(bbits downto 0);
  begin
    if max > 128 and hsize = HSIZE_8WORD then
      newnwords := nwords - 8;
    elsif max > 64 and hsize = HSIZE_4WORD then
      newnwords := nwords - 4;
    elsif max > 32 and hsize = HSIZE_DWORD then
      newnwords := nwords - 2;
    else
      newnwords := nwords - 1;
    end if;

    return newnwords;
  end;

  -- Detects when 1K bounadry is approaching so that the bridge can skip
  -- inserting an IDLE cycle instead of a BUSY cycle
  function linc(
    hburst : in  std_logic_vector(2 downto 0);
    haddr  : in  std_logic_vector(9 downto 0);
    hsize  : in  std_logic_vector(2 downto 0))
    return std_ulogic is
    variable nbsy : std_ulogic;
  begin
    nbsy := '0';
    if ((hburst = HBURST_INCR or allbrst = 0) and
        (haddr(9 downto log2(MMAXDW/8)) = one32(9 downto log2(MMAXDW/8)))) then
      case hsize is
        when HSIZE_BYTE  =>
          if haddr(log2(MMAXDW/16) downto 0) = one32(log2(MMAXDW/16) downto 0) then
            nbsy := '1';
          end if;
        when HSIZE_HWORD =>
          if haddr(log2(MMAXDW/16) downto 1) = one32(log2(MMAXDW/16) downto 1) then
            nbsy := '1';
          end if;
        when HSIZE_WORD =>
          if MMAXDW > 32 then
            if haddr(log2(MMAXDW/16) downto 2) = one32(log2(MMAXDW/16) downto 2) then
              nbsy := '1';
            end if;
          else nbsy := '1'; end if;
        when HSIZE_DWORD =>
          if MMAXDW > 64 then
            if haddr(log2(MMAXDW/16) downto 3) = one32(log2(MMAXDW/16) downto 3) then
              nbsy := '1';
            end if;
          else nbsy := '1'; end if;
        when HSIZE_4WORD =>
          if MMAXDW > 128 then
            if haddr(log2(MMAXDW/16) downto 4) = one32(log2(MMAXDW/16) downto 4) then
              nbsy := '1';
            end if;
          else nbsy := '1'; end if;
        when others => 
          if MMAXDW > 128 then
            if haddr(log2(MMAXDW/16) downto 5) = one32(log2(MMAXDW/16) downto 5) then
              nbsy := '1';
            end if;
          else nbsy := '1'; end if;
      end case;
    end if;
    return nbsy;
  end;

  -- Duplicates vector of 'insize' to vector of 'outsize'
  function dupvec (
    constant outsize : integer;
    constant insize  : integer;
    vec              : std_logic_vector)
    return std_logic_vector is
    variable ret : std_logic_vector(255 downto 0);
  begin  -- dupvec
    for i in 0 to outsize/insize-1 loop
      ret(insize-1+insize*i downto insize*i) := vec; 
    end loop;
    return ret(outsize-1 downto 0);
  end dupvec;

  -- Selects data based on hsize and addr and duplicates the selected data to a
  -- vector of length 'outsize'.
  function selectdata (
    constant outsize : integer;
    signal   addr    : std_logic_vector(2 downto 0);
    signal   hsize   : std_logic_vector(2 downto 0);
    signal   data    : std_logic_vector(maxdw-1 downto 0))
    return std_logic_vector is
    variable rdata : std_logic_vector(maxdw-1 downto 0);
  begin  -- selectdata
    if outsize = 256 and hsize = HSIZE_8WORD then
      return dupvec(256, 256, data);
    elsif outsize > 64 and hsize = HSIZE_4WORD then
      if maxdw = 256 then
        if addr(2) = '0' then rdata(maxdw/2-1 downto 0) := data(maxdw-1 downto maxdw/2);
        else rdata(maxdw/2-1 downto 0) := data(maxdw/2-1 downto 0); end if;
        return dupvec(outsize, maxdw/2, rdata(maxdw/2-1 downto 0));
      else
        return dupvec(outsize, maxdw, data);
      end if;
    elsif outsize > 32 and hsize = HSIZE_DWORD then
      if maxdw = 256 then
        case addr(2 downto 1) is
          when "00" =>   rdata((maxdw/4)-1 downto 0) := data(4*(maxdw/4)-1 downto 3*(maxdw/4));
          when "01" =>   rdata((maxdw/4)-1 downto 0) := data(3*(maxdw/4)-1 downto 2*(maxdw/4));
          when "10" =>   rdata((maxdw/4)-1 downto 0) := data(2*(maxdw/4)-1 downto 1*(maxdw/4));
          when others => rdata((maxdw/4)-1 downto 0) := data(1*(maxdw/4)-1 downto 0*(maxdw/4));
        end case;
        return dupvec(outsize, 64, rdata((maxdw/4)-1 downto 0));
      elsif maxdw = 128 then
        if addr(1) = '0' then rdata(maxdw/2-1 downto 0) := data(maxdw-1 downto maxdw/2);
        else rdata(maxdw/2-1 downto 0) := data(maxdw/2-1 downto 0); end if;
        return dupvec(outsize, maxdw/2, rdata(maxdw/2-1 downto 0));
      else
        return dupvec(outsize, maxdw, data);
      end if;
    elsif maxdw = 256 then -- HSIZE <= HSIZE_WORD
      case addr(2 downto 0) is
        when "000" =>  rdata((maxdw/8)-1 downto 0) := data(8*(maxdw/8)-1 downto 7*(maxdw/8));
        when "001" =>  rdata((maxdw/8)-1 downto 0) := data(7*(maxdw/8)-1 downto 6*(maxdw/8));
        when "010" =>  rdata((maxdw/8)-1 downto 0) := data(6*(maxdw/8)-1 downto 5*(maxdw/8));
        when "011" =>  rdata((maxdw/8)-1 downto 0) := data(5*(maxdw/8)-1 downto 4*(maxdw/8));
        when "100" =>  rdata((maxdw/8)-1 downto 0) := data(4*(maxdw/8)-1 downto 3*(maxdw/8));
        when "101" =>  rdata((maxdw/8)-1 downto 0) := data(3*(maxdw/8)-1 downto 2*(maxdw/8));
        when "110" =>  rdata((maxdw/8)-1 downto 0) := data(2*(maxdw/8)-1 downto 1*(maxdw/8));
        when others => rdata((maxdw/8)-1 downto 0) := data(1*(maxdw/8)-1 downto 0*(maxdw/8));
      end case;
      return dupvec(outsize, maxdw/8, rdata((maxdw/8)-1 downto 0));
    elsif maxdw = 128 then
      case addr(1 downto 0) is
        when "00" => rdata((maxdw/4)-1 downto 0) := data(4*(maxdw/4)-1 downto 3*(maxdw/4));
        when "01" => rdata((maxdw/4)-1 downto 0) := data(3*(maxdw/4)-1 downto 2*(maxdw/4));
        when "10" => rdata((maxdw/4)-1 downto 0) := data(2*(maxdw/4)-1 downto 1*(maxdw/4));
        when others => rdata((maxdw/4)-1 downto 0) := data(1*(maxdw/4)-1 downto 0*(maxdw/4));
      end case;
      return dupvec(outsize, maxdw/4, rdata((maxdw/4)-1 downto 0));
    elsif maxdw = 64 then
      if addr(0) = '0' then rdata(maxdw/2-1 downto 0) := data(maxdw-1 downto maxdw/2);
      else rdata(maxdw/2-1 downto 0) := data(maxdw/2-1 downto 0); end if;
      return dupvec(outsize, maxdw/2, rdata(maxdw/2-1 downto 0));
    end if;
    return dupvec(outsize, maxdw, data);
  end selectdata;

  -- Handles access size and burst assignments for writecombining. The
  -- procedure is called on the cross between the slave and master interface.
  -- Write combine strategies:
  -- wrcomb        Description
  --  0            No write combining
  --  1            Combine if burst can be preserved
  --  2            Combine if burst can be preserved and allow single
  --               accesses to be converted to bursts
  --  
  procedure writecombine (
    nwords   : in  std_logic_vector(bbits downto 0);
    shaddr   : in  std_logic_vector(4 downto 0);
    shburst  : in  std_logic_vector(2 downto 0);
    shsize   : in  std_logic_vector(2 downto 0);
    mhsize   : out std_logic_vector(2 downto 0);
    mhburst  : out std_logic_vector(2 downto 0)) is
    variable accaddr : std_logic_vector(0 to log2(MMAXDW/32));
    variable accsz : std_logic_vector(0 to log2(MMAXDW/32));
  begin  -- writecombine
    -- acc*(x) decoding:
    -------------------
    --  x        HSIZE
    -------------------
    --  0        WORD
    --  1        DWORD
    --  2        4WORD
    --  3        8WORD
    --
    accaddr := (others => '0');
    accsz := (others => '0');

    if MMAXDW > 32 and wrcomb /= 0 then
      -- Check access size that address allows
      for i in accsz'range loop
        if shaddr(i+1 downto 0) = zero32(i+1 downto 0) then
          accaddr(i) := '1';
        end if;
      end loop;  -- i

      -- Check access size that buffer contents allows
      for i in 0 to log2(MMAXDW/32) loop
        accsz(i) := orv(nwords(nwords'left downto i));
      end loop;  -- i

      -- For full buffer (wrcomb = 1 and wrcomb = 2)
      for i in 1-32/MMAXDW to log2(MMAXDW/32) loop
        if (wrcomb = 1) or (wrcomb = 2) then  
          accsz(i) := accsz(i) and not orv(nwords(i-1 downto 0));
        end if; 
      end loop;  -- i
      
      -- Set size to use for access
      for i in 0 to log2(MMAXDW/32) loop
        if (accaddr(i) and accsz(i)) = '1' then
          mhsize := conv_std_logic_vector(i+2, 3);
        end if;
      end loop;  -- i
    else
      -- HSIZE < HSIZE_WORD fixed below...
      mhsize := HSIZE_WORD;
    end if;

    -- Handle bursts
    if (wrcomb mod 2) = 0 then mhburst := HBURST_INCR;
    else mhburst := shburst; end if;
    
    if shsize = HSIZE_HWORD or shsize = HSIZE_BYTE then
      mhsize := shsize;
      mhburst := shburst;
    end if;
  end writecombine;

  -- Returns '1' if access is to an area where read/write combining is performed
  function comb_addr(
    haddr  : std_logic_vector(31 downto 28))
    return std_ulogic is
    variable hit : std_ulogic;
    variable tbl : std_logic_vector(15 downto 0);
  begin
    hit := '0'; tbl := (others => '0');
    if combmask = 16#ffff# then
      hit := '1';
    elsif combmask = 0 then
      hit := '0';
    else
      tbl := conv_std_logic_vector(combmask, 16);
      hit := tbl(conv_integer(haddr(31 downto 28)));
    end if;
    return hit;
  end;

  -- Used to update rm.rdw that decides which parts of the read data vector
  -- that should be updated then the master interfaces performs an access.
  -- This will not work if rs.hsize changes
  -- Make it work(X), make it fast( ), make it pretty( )
  procedure updrdw (
    shsize   : in  std_logic_vector(2 downto 0);
    rdwin    : in  std_logic_vector(0 to (SMAXDW/MMAXDW-1)*SMAXDW/maxdw);
    rdwout   : out std_logic_vector(0 to (SMAXDW/MMAXDW-1)*SMAXDW/maxdw)) is
  begin  -- updrdw
    if rdcomb /= 0 and SMAXDW > MMAXDW then
      if SMAXDW = 256 then
        case shsize is
          when HSIZE_8WORD =>
            rdwout := '0' & rdwin(rdwin'left to rdwin'right-1);
          when HSIZE_4WORD =>
            if MMAXDW = 128 then
              rdwout := (others => '0');
            else
              rdwout(rdwin'left to rdwin'length/2-1) :=
                '0' & rdwin(rdwin'left to rdwin'length/2-2);
              rdwout(rdwin'length/2 to rdwin'right) :=
                '0' & rdwin(rdwin'length/2 to rdwin'right-1);
            end if;
          when HSIZE_DWORD =>
            for i in rdwin'range loop
              if (i mod 2) = 0 then
                rdwout(i) := '0';
              end if;
            end loop;  -- i
          when others => rdwout := (others => '0');
        end case;
      elsif SMAXDW = 128 then
        case shsize is
          when HSIZE_4WORD =>
            rdwout := '0' & rdwin(rdwin'left to rdwin'right-1);
          when HSIZE_DWORD =>  
            if MMAXDW = 64 then
              rdwout := (others => '0');
            else
              rdwout(rdwin'left to rdwin'length/2-1) :=
                '0' & rdwin(rdwin'left); 
              rdwout(rdwin'length/2 to rdwin'right) :=
                '0' & rdwin(rdwin'length/2);
            end if;
          when others => rdwout := (others => '0');
        end case;
      else
        rdwout := '0' & rdwin(rdwin'left to rdwin'right-1);
      end if;
    else
      rdwout := (others => '0');
    end if;
  end updrdw;

  -- Returns true if incoming burst should be treated as an incrementing burst
  -- of undefined length by the bridge.
  function incr_burst(hburst : std_logic_vector(2 downto 0)) return boolean is
  begin
    -- Then we can always use maximum access size instead.
    -- Only use when combining is not used?
    return (allbrst = 0 or hburst = HBURST_INCR);
  end;

  function wrap_burst(hburst : std_logic_vector(2 downto 0)) return std_ulogic is
    variable ret : std_ulogic;
  begin
    ret := '0';
    if (allbrst /= 0 and (hburst = HBURST_WRAP4 or hburst = HBURST_WRAP8 or
                          hburst = HBURST_WRAP16)) then
      ret := '1';
    end if;
    return ret;
  end;

  function fixed_burst(hburst : std_logic_vector(2 downto 0)) return std_ulogic is
    variable ret : std_ulogic;
  begin
    ret := '0';
    if (allbrst /= 0 and (hburst = HBURST_INCR4 or hburst = HBURST_INCR8 or
                          hburst = HBURST_INCR16)) then
      ret := '1';
    end if;
    return ret;
  end;

  -- Returns true if high:low slice of vector is all ones, or if the slice is
  -- outside of the read buffer address vector range.
  function pfget_limit_reached(
    rbaddr : std_logic_vector(rbufbits-1 downto 0);
    constant high    : integer;
    constant low     : integer)
    return boolean is
  begin
    if low > (rbufbits-1) then
      return true;
    end if;
    if low < (rbufbits-1) and high < (rbufbits-1) then
      return rbaddr(high downto low) = one32(high downto low);
    end if;
    -- high > (rbufbits-1) then
    return rbaddr(rbufbits-1 downto low) = one32(rbufbits-1 downto low);
  end;

  -- Returns true if high:low slice of vector is all zeroes, or if the slice is
  -- outside of the read buffer address vector range.
  function pfread_limit_reached(
    rbaddr : std_logic_vector(rbufbits-1 downto 0);
    constant high    : integer;
    constant low     : integer)
    return boolean is
  begin
    if low > (rbufbits-1) then
      return true;
    end if;
    if low < (rbufbits-1) and high < (rbufbits-1) then
      return rbaddr(high downto low) = zero32(high downto low);
    end if;
    -- high > (rbufbits-1) then
    return rbaddr(rbufbits-1 downto low) = zero32(rbufbits-1 downto low);
  end;
  
  -----------------------------------------------------------------------------
  -- Signals
  -----------------------------------------------------------------------------
  -- Registers
  signal rs, rsin   : slave_type;
  signal rm, rmin   : master_type;
  -- Signals master <-> slave
  signal s2m        : slave_to_master_type;
  signal m2s        : master_to_slave_type;
  -- Read buffer signals
  signal rb_ren, rb_wr : std_logic_vector((maxdw/32-1) downto 0);
  signal rb_addr    : std_logic_vector(rbufbits-1 downto 0);
  signal rb_raddr, rb_waddr : std_logic_vector(rbufbits-1 downto log2(maxdw/32));
  signal rb_do      : std_logic_vector(maxdw-1 downto 0);
  signal rbo        : std_logic_vector(SMAXDW-1 downto 0);
  signal rseladdr   : std_logic_vector(2 downto 0);
  -- Write buffer signals
  signal wb_ren, wb_wr : std_logic_vector((maxdw/32-1) downto 0);
  signal wb_addr    : std_logic_vector(wbbits-1 downto 0);
  signal wb_raddr, wb_waddr : std_logic_vector(wbbits-1 downto log2(maxdw/32));
  signal wb_do      : std_logic_vector(maxdw-1 downto 0);
  signal wbo        : std_logic_vector(MMAXDW-1 downto 0);
  signal wseladdr   : std_logic_vector(2 downto 0);
  -- Split buffer signals
  signal sb_do      : std_logic_vector(3 downto 0);
  signal sb_di      : std_logic_vector(3 downto 0);
  signal sb_wr      : std_ulogic;
  signal sb_ren     : std_ulogic;
  --
  signal hsb_hirqo, lsb_hirqo : std_logic_vector(NAHBIRQ-1 downto 0);
  signal hrdata, hrdatax, hwdata, hwdatax : std_logic_vector(maxdw-1 downto 0);

begin

  -----------------------------------------------------------------------------
  -- AHB slave side combinational logic
  -----------------------------------------------------------------------------
  slvcomb : process(rstn, rs, ahbsi, ahbmi, ahbso2, rbo, hsb_hirqo,
                    lsb_hirqo, ifctrl, sb_do, m2s)
    variable vs        : slave_type;
    variable hsplit    : std_logic_vector(NAHBMST-1 downto 0);
    variable hsel      : std_ulogic;
    variable slock     : std_ulogic; -- split lock, and wait state lock
    variable buslock   : std_ulogic; -- bus lock, currently not used
    variable slvcfg    : ahb_config_type;
    variable pfetch    : std_ulogic;
    variable wr        : std_ulogic;
    variable ren       : std_ulogic;
    variable lw        : std_ulogic;
    variable rbaddr    : std_logic_vector(rbufbits-1 downto 0);
    variable tbar      : std_logic_vector(29 downto 0);
    variable unsplit   : std_ulogic;
    variable sbdi      : std_logic_vector(3 downto 0);
    variable sbwr      : std_ulogic;
    variable sbren     : std_ulogic;
    variable handled   : std_ulogic;
    variable match     : std_ulogic;    -- FCFS match
  begin

    vs := rs;
    hsplit := (others => '0');
    hsel := ahbsi.hsel(hsindex); handled := '0';
    wr := '0'; ren := '0'; unsplit := '0'; match := '0';
    sbren := '0'; sbwr := '0'; sbdi := (others => '0');
    
    slock := '0'; buslock := '0'; lw := '0'; rbaddr := (others => '0');
    if split /= 0 then
      if (rs.state = split2) and (m2s.state = wreq) and (rs.hburst /= HBURST_SINGLE)
      then slock := '1'; end if;
    else
      slock := not rs.hready;
    end if;
    lcko.slck <= slock;

    pfetch := '0';
    if (pfen = 1) then
      if (((ahb_slv_dec_pfetch(ahbsi.haddr, ahbso2) = '1') or
           (allbrst = 2 and (wrap_burst(ahbsi.hburst) or fixed_burst(ahbsi.hburst)) = '1')) and
          (ahbsi.hburst /= HBURST_SINGLE) and (ahbsi.hmastlock = '0'))
      then pfetch := '1'; end if;
    end if;

    if split /= 0 then
      if fcfs /= 0 then
        if (ahbsi.hmaster = rs.fcfs.splmst and
            (rs.fcfs.act = '1' or rs.fcfs.handled = '0' or ((SPLANDLCK and rs.sv.act = '1')))) then
          match := '1';
        else
          match := (rs.fcfs.act nor (conv_std_logic(SPLANDLCK) and rs.sv.act)) and rs.fcfs.handled;
        end if;
        match := match or ahbsi.hmastlock;
      elsif SPLANDLCK then
        if rs.sv.act = '0' or ahbsi.hmaster = rs.sv.mst then
          match := '1';
        end if;
        match := match or ahbsi.hmastlock;
      end if;
    end if;

    if (rs.state = sidle) or (rs.state = ret) or (rs.state = sdata) or (rs.state = pfread) then
      vs.haddr := ahbsi.haddr;
      vs.htrans := ahbsi.htrans; vs.hsize := ahbsi.hsize;
      vs.hburst := ahbsi.hburst; vs.hprot := ahbsi.hprot;
      vs.hmastlock := ahbsi.hmastlock;
      vs.hwrite := ahbsi.hwrite;
    end if;

    vs.hready := '1'; vs.hresp := HRESP_OKAY;

    case rs.state is
      when sidle =>
        if split /= 0 then
          if rs.hresp /= HRESP_SPLIT then
            if fcfs = 0 then hsplit := rs.hsplit; vs.hsplit := (others => '0');
            else unsplit := not rs.nsplit; end if;
          end if;
          if fcfs = 0 and SPLANDLCK and rs.sv.abort = '1' then
            -- If we aborted a transfer, due to incoming locked transfer, we need to return
            -- split complete to the first master. This is not necessary with FCFS as the
            -- master will still be in the queue
            hsplit(conv_integer(rs.splmst)) := '1';
          end if;
        end if;
        if DBLLCK then vs.mstlock := '0'; end if;
        if (hsel and ahbsi.hready and ahbsi.htrans(1)) = '1' then
          if MATCHDIS or match = '1' then
            if ahbsi.hwrite = '0' then
              if not SPLANDLCK or ahbsi.htrans(0) = '0' then
                vs.hready := '0';
                if split /= 0 then
                  if ahbsi.hmastlock = '0' then vs.hresp := HRESP_SPLIT;
                  elsif fcfs /= 0 then vs.fcfs.hold := '1'; end if;
                end if;
                if pfetch = '0' then
                  vs.state := split2;
                else
                  vs.state := pfsplit;
                  if m2s.state = pfrdy then vs.race := '1'; else vs.race := '0'; end if;
                end if;
                if split /= 0 and SPLANDLCK and rs.sv.act = '1' and rs.sv.mst = ahbsi.hmaster then
                  -- Bridge has a saved response for access that was aborted by
                  -- incoming locked transfer.
                  if pfen = 0 or rs.sv.pfact = '0' then
                    vs.hready := '0';
                    vs.hresp := rs.sv.hresp;
                    vs.hrdata := rs.sv.hrdata;
                    if rs.sv.hresp /= HRESP_OKAY then vs.hready := '0'; end if;
                    vs.race := rs.race;
                    vs.state := ret;
                    vs.sv.act := '0';
                    -- We will unsplit in ret, prevent additional unsplit when
                    -- we return.
                    vs.sv.sphold := '1'; 
                  else
                    vs.sv.nofetch := '1';
                    vs.hready := '0'; vs.hresp := HRESP_OKAY;
                  end if;
                end if;
                if split /= 0 and fcfs /= 0 then handled := '1'; end if;
              else
                -- We can get SEQ transfer here with:
                -- * with SPLANDLCK (lckdac = 2) 
                -- * via split2 -> ret and master driving BUSY while
                --   we pass through the ret state
                -- * via split2 -> sidle and collision in bidir config
                -- * After issuing an ERROR response and continued burst from master
                -- Issue RETRY to the master to get NONSEQ.
                vs.hready := '0';
                vs.hresp := HRESP_RETRY;
                -- Another option is to issue a SPLIT response here, in that
                -- case rs.nsplit must be zero:ed so that the master receives a
                -- complete SPLIT
              end if;
            else
              vs.state := bfill; vs.hready := not ahbsi.hmastlock;
              vs.wbaddr := ahbsi.haddr(wbbits+1 downto 2);
              vs.nwords := (others => '0');
              if CORE_ACDM = 1 then vs.wbhaddr := ahbsi.haddr(4 downto 2); end if;
              if split /= 0 and fcfs /= 0 then handled := '1'; end if;
            end if;
            if split /= 0 then vs.splmst := ahbsi.hmaster; end if;
            if DBLLCK then vs.mstlock := ahbsi.hmastlock; end if;
          elsif split /= 0 then
            if fcfs = 0 then vs.hsplit(conv_integer(ahbsi.hmaster)) := '1'; end if;
            vs.hready := '0'; vs.hresp := HRESP_SPLIT; 
          end if;
        end if;
        
      when split2 =>
        if (rs.hready = '0') and (rs.hresp = HRESP_OKAY) then vs.hready := '0'; end if;
        if ((split /= 0) and ((ahbsi.hready and hsel and ahbsi.htrans(1)) = '1') and
            (ahbsi.hmaster /= rs.splmst)) then
          if SPLNOLCK and ahbsi.hmastlock = '1' then
            -- Resolve dead lock condition due to locked transfer while in SPLIT by
            -- responding with ERROR to locked access.
            vs.hresp := HRESP_ERROR;
          else
            if SPLANDLCK and ahbsi.hmastlock = '1' then
              -- Incoming locked transfer. Save read data when it is ready,
              -- then handle the locked access.
              vs.sv.act := '1';
              vs.sv.mst := rs.splmst;
              if fcfs = 0 then vs.hsplit(conv_integer(rs.splmst)) := not rs.nsplit;
              else vs.sv.unsplit := '1'; end if;
            end if;
            -- Here we may respond with SPLIT to incoming locked transfer
            vs.hresp := HRESP_SPLIT;
            if fcfs = 0 then vs.hsplit(conv_integer(ahbsi.hmaster)) := '1'; end if;
          end if;
          vs.hready := '0'; 
        end if;

        if (m2s.state /= wreq and (pipe = 0 or m2s.state /= brel)) then vs.race := '0'; end if;

        if ((m2s.state = wreq or m2s.mwreq = '1') and
            (rs.race = '0') and ((split = 0) or (ahbsi.hmaster = rs.splmst)) and
            (((hsel and ahbsi.hready and ahbsi.htrans(1)) = '1') or
             ((rs.hready = '0') and (rs.hresp = HRESP_OKAY)))) then
          vs.state := ret; vs.hready := '1';
          vs.hrdata := m2s.hdata(SMAXDW-1 downto 0); vs.hresp := m2s.hresp;
          if (m2s.hresp /= HRESP_OKAY) then vs.hready := '0'; end if;
          -- Check for collision
          if slv = 1 and m2s.state = brel then vs.state := sidle;
          else vs.state := ret; end if;
          -- Returning data, unsplit next master (and also prevent current
          -- master from performing one more access) in FCFS mode.
          -- Issuing SPLIT here also means that we, if there are other masters
          -- in the queue, will chop up an incoming burst (to non-prefetchable
          -- areas).
          if split /= 0 and fcfs /= 0 then
            -- Here we may assert HSPLIT to a master in the second cycle that
            -- the master receives HRESP_SPLIT. The GRLIB arbiter can handle
            -- that scenario. However it is not fully AMBA compliant to do so.
            -- By avoiding the if rs.hresp /= HRESP_SPLIT we gain some
            -- performance. Also, there is a case where we wait for the return
            -- for a master here and another master performs an access and gets
            -- split here. Since rethold is set we may violate the order of
            -- incoming accesses => If the rs.hresp check is uncommented below,
            -- then rerun the AHB2AHB test bench and add handling for the case
            -- checked by the FCFSEB test.
--            if rs.hresp /= HRESP_SPLIT then
              -- Set sp2hold here to prevent additional unsplit in sidle
              unsplit := '1'; vs.fcfs.sp2hold := '1';
--            end if;
          end if;
          handled := '1';
        elsif ((split /= 0) and SPLANDLCK and (vs.sv.act = '1') and
               (m2s.state = wreq or m2s.mwreq = '1') and (rs.race = '0')) then
          vs.sv.hrdata := m2s.hdata(SMAXDW-1 downto 0); vs.sv.hresp := m2s.hresp;
          vs.state := sidle;
          if (fcfs /= 0) and (((rs.mwreq = '1') and (rs.hresp /= HRESP_SPLIT)) or (rs.fcfs.rethold = '1')) then
            -- Unsplit has been, or will be in this cycle, issued for this
            -- access. Do not unsplit after the locked access completes
            vs.sv.unsplit := '0';
          end if;
          -- Unsplit locked access in sidle
          vs.nsplit := '0';
        elsif (slv = 1) and (m2s.state = brel) and (m2s.mwreq = '0') then
          if (split = 0) or (ahbsi.hready = '1') then
            -- Collision in bidirectional configuration, data has not been read
            vs.state := sidle;
            if split /= 0 then
              -- When FCFS is enabled we just return to idle where the master
              -- will receive SPLIT complete. In this case set handled to '0' in
              -- order to ensure that the master will still be first in the queue
              if fcfs = 0 then vs.hsplit(conv_integer(rs.splmst)) := not rs.nsplit;
              else vs.fcfs.handled := '0'; end if;
            else
              -- Issue a retry response to let the other bridge access the bus
              vs.hresp := HRESP_RETRY;
            end if;
          end if;
        end if;
        -- ERROR response for locked access in both directions in
        -- bidirectional configuration.
        if DBLLCK and slv = 1 and m2s.err = '1' then
          vs.hresp := HRESP_ERROR;
          vs.state := sidle;
        end if;
        
      when pfsplit =>
        if (pfen = 1) then
          if split = 0 or (SPLANDLCK and rs.sv.pfact = '1') then
            if (rs.hready = '0') and (rs.hresp = HRESP_OKAY) then vs.hready := '0'; end if;
          end if;
          if m2s.state /= pfrdy then vs.race := '0'; end if;
          vs.hrdata := rbo; vs.err := '0';
          if (split /= 0) and ((hsel and ahbsi.hready and ahbsi.htrans(1)) = '1') then
            if SPLNOLCK and ahbsi.hmastlock = '1' then
              -- Resolve dead lock condition due to locked transfer while in SPLIT by
              -- responding with ERROR to locked access (lckdac is 1).
              -- No need to check ahbsi.hmaster above since we will not get
              -- here if hmastlock was initially set (see pfetch assignment).
              vs.hresp := HRESP_ERROR;
            else
              -- Here we may respond with SPLIT to incoming locked transfer
              -- This will lead to a deadlock in the next state if lckdac = 0.
              -- If lckdac = 2 we return to sidle to handle the locked access
              -- instead, dropping the prefetched data.
              if SPLANDLCK then vs.sv.abort := ahbsi.hmastlock; end if;
              vs.hresp := HRESP_SPLIT;
              if fcfs = 0 then vs.hsplit(conv_integer(ahbsi.hmaster)) := '1'; end if;
            end if;
            vs.hready := '0';
          elsif (split = 0 or ahbsi.hready = '1') and ((m2s.state = pfrdy) and (vs.race = '0')) then
            if split /= 0 and SPLANDLCK and rs.sv.abort = '1' then
              vs.state := sidle; vs.sv.act := '1';
              vs.sv.pfact := '1'; vs.sv.rbaddr := m2s.rbaddr;
              vs.sv.mst := rs.splmst; vs.sv.err := m2s.err;
              vs.sv.unsplit := '1';
            else vs.state := pfread; end if;
            if (split = 0) and (m2s.err = '1') and (m2s.rbaddr = rs.rbaddr) then
              vs.err := '1';
              vs.hresp := HRESP_ERROR;
            end if;
            vs.ba := '0';
            --   if split = 0 then vs.rbaddr := baddrinc(SMAXDW, rs.rbaddr, rs.hsize); end if;
          elsif SPLANDLCK and rs.sv.pfact = '1' then
            vs.sv.act := '0';
            if rs.sv.act = '0' then
              vs.state := pfread;
              if (rs.sv.err = '1') and (rs.sv.rbaddr = rs.rbaddr) then
                vs.err := '1';
                vs.hresp := HRESP_ERROR;
              end if;
              vs.ba := '0';
            end if;
          elsif (slv = 1) and (split = 0) and (m2s.state = brel) then
            -- Dead lock resolve during PF for split = 0
            vs.hresp := HRESP_RETRY;
            vs.state := sidle;
          end if;
          vs.rbaddr := (others => '0');
          -- Do not pre-fetch over 1k limit, and do not prefetch over address boundary
          if incr_burst(rs.hburst) then
            vs.rbaddr := rs.haddr(rbufbits+1 downto 2);
          end if;
        end if;
        
      when pfread =>
        if (pfen = 1) then
          vs.hrdata := rbo;
          if split /= 0 and (not SPLANDLCK or rs.sv.pfact = '0') then
            if fcfs = 0 then hsplit(conv_integer(rs.splmst)) := not rs.nsplit;
            else unsplit := not rs.nsplit; end if;
          else
            vs.ba := '1'; -- Master that initiated PF performs access
            if rs.ba = '0' then
              vs.rbaddr := baddrinc(SMAXDW, rs.rbaddr, rs.hsize);
            end if;
          end if;
          rbaddr := (others => '0'); rbaddr(rbufbits-1 downto 0) := rs.rbaddr;
          if incr_burst(rs.hburst) then
            if (ibrsten = 0) or (rs.hprot(0) = '1') then
              if rbaddr(rbbits-1 downto 0) = zero32(rbbits-1 downto 0) then lw := '1'; end if;
            else
              if rbaddr(ibbits-1 downto 0) = zero32(ibbits-1 downto 0) then lw := '1'; end if;
            end if;
          else
            case rs.hburst is
              when HBURST_WRAP4 | HBURST_INCR4 =>
                if mindw > 128 and rs.hsize = HSIZE_8WORD then
                  if pfread_limit_reached(rbaddr, 4, 3) then lw := '1'; end if;
                elsif mindw > 64 and rs.hsize = HSIZE_4WORD then
                  if pfread_limit_reached(rbaddr, 3, 2) then lw := '1'; end if;
                elsif mindw > 32 and rs.hsize = HSIZE_DWORD then
                  if pfread_limit_reached(rbaddr, 2, 1) then lw := '1'; end if;
                else
                  if pfread_limit_reached(rbaddr, 1, 0) then lw := '1'; end if;
                end if;
              when HBURST_WRAP8 | HBURST_INCR8 =>
                if mindw > 128 and rs.hsize = HSIZE_8WORD then
                  if pfread_limit_reached(rbaddr, 5,  3) then lw := '1'; end if;
                elsif mindw > 64 and rs.hsize = HSIZE_4WORD then
                  if pfread_limit_reached(rbaddr, 4, 2) then lw := '1'; end if;
                elsif mindw > 32 and rs.hsize = HSIZE_DWORD then
                  if pfread_limit_reached(rbaddr, 3, 1) then lw := '1'; end if;
                else
                  if pfread_limit_reached(rbaddr, 2, 0) then lw := '1'; end if;
                end if;
              when HBURST_WRAP16 | HBURST_INCR16 =>
                if mindw > 128 and rs.hsize = HSIZE_8WORD then
                  if pfread_limit_reached(rbaddr, 6, 3) then lw := '1'; end if;
                elsif mindw > 64 and rs.hsize = HSIZE_4WORD then
                  if pfread_limit_reached(rbaddr, 5, 2) then lw := '1'; end if;
                elsif mindw > 32 and rs.hsize = HSIZE_DWORD then
                  if pfread_limit_reached(rbaddr, 4, 1) then lw := '1'; end if;
                else
                  if pfread_limit_reached(rbaddr, 3, 0) then lw := '1'; end if;
                end if;
              when others =>
            end case;
          end if;

          if (split = 0) or (ahbsi.hmaster = rs.splmst) or (SPLANDLCK and rs.sv.pfact = '1') then
            if ((split = 0 or ahbsi.hready = '1' or (SPLANDLCK and rs.sv.pfact = '1')) and
                ((hsel and ahbsi.htrans(1)) = '1')) then
              if split /= 0 and (not SPLANDLCK or rs.sv.pfact = '0') then
                vs.ba := '1'; -- Master that initiated PF performs access
                if fcfs = 0 then
                  hsplit := rs.hsplit; vs.hsplit := (others => '0');
                else
                  unsplit := not rs.ba; handled := not rs.ba;
                end if;
              end if;
              vs.rbaddr := baddrinc(SMAXDW, rs.rbaddr, ahbsi.hsize);
              if (((ahbsi.htrans = HTRANS_NONSEQ) and (rs.ba = '1')) or
                  ((ahbsi.htrans = HTRANS_SEQ) and ((lw = '1') and
                   ((split /= 0 and (not SPLANDLCK or rs.sv.pfact = '0')) or rs.hready = '1')))) then
                -- In FCFS mode the bridge will allow the pf-initiating master
                -- to fetch one buffer worth of words, then we check if we
                -- should serve another master
                if SPLANDLCK then vs.sv.pfact := '0'; end if;
                if MATCHDIS or match = '1' then
                  if ahbsi.hwrite = '0' then
                    vs.hready := '0';
                    if split /= 0 then
                      if ahbsi.hmastlock = '0' then vs.hresp := HRESP_SPLIT;
                      elsif fcfs /= 0 then vs.fcfs.hold := '1'; end if;
                    end if;
                    if pfetch = '0' then
                      vs.state := split2;
                    else
                      vs.state := pfsplit;
                      if m2s.state = pfrdy then vs.race := '1'; else vs.race := '0'; end if;
                    end if;
                  else
                    vs.state := bfill; vs.hready := not ahbsi.hmastlock;
                    vs.wbaddr := ahbsi.haddr(wbbits+1 downto 2);
                    vs.nwords := (others => '0');
                    if CORE_ACDM = 1 then vs.wbhaddr := ahbsi.haddr(4 downto 2); end if;
                  end if;
                  if split /= 0 then vs.splmst := ahbsi.hmaster; end if;
                  if split /= 0 and fcfs /= 0 then handled := '1'; end if;
                  if DBLLCK then vs.mstlock := ahbsi.hmastlock; end if;
                elsif split /= 0 then
                  if fcfs = 0 then vs.hsplit(conv_integer(ahbsi.hmaster)) := '1'; end if;
                  vs.hready := '0'; vs.hresp := HRESP_SPLIT;
                end if;
              end if;
              if rs.err = '1' and (rs.ba = '0' or ahbsi.htrans = HTRANS_SEQ) then
                vs.hready := '0'; vs.hresp := HRESP_ERROR;
                vs.state := sidle;
              end if;
            end if;
          else
            -- Not used if split = 0
            if (ahbsi.hready and hsel and ahbsi.htrans(1)) = '1' then
              if SPLANDLCK then vs.sv.pfact := '0'; end if;
              if rs.ba = '1' or (SPLANDLCK and ahbsi.hmastlock = '1') then
                -- If master that initiated prefetch has accessed the FIFO,
                -- or if prefetch was aborted by incoming locked access and
                -- lckdac = 2, the bridge could return to sidle:
                -- vs.state := sidle;
                -- However, in this state we have a potential starvation problem,
                -- we have served the master that initiated the prefetch. Now
                -- another master may want to perform an access. However, if we
                -- issue a SPLIT response to that master and return to sidle.
                -- That could lead to another master getting to perform an
                -- access over the bridge. The same pattern could then repeat
                -- and we have a starvation problem. To prevent this, handle
                -- the incoming access here:
                if SPLANDLCK and ahbsi.hmastlock = '1' and rs.ba = '0' then
                  vs.sv.act := '1'; vs.sv.pfact := '1'; vs.sv.err := m2s.err;
                  vs.sv.rbaddr := m2s.rbaddr; vs.sv.mst := rs.splmst;
                end if;
                if MATCHDIS or match = '1' then
                  if ahbsi.hwrite = '0' then
                    vs.hready := '0';
                    if ahbsi.hmastlock = '0' then vs.hresp := HRESP_SPLIT;
                    elsif fcfs /= 0 then vs.fcfs.hold := '1'; end if;
                    if pfetch = '0' then
                      vs.state := split2;
                    else
                      vs.state := pfsplit;
                      if m2s.state = pfrdy then vs.race := '1'; else vs.race := '0'; end if;
                    end if;
                    -- No need to check for saved response for access that was aborted by
                    -- incoming locked transfer since locked transfers do not
                    -- initiate prefetch operations.
                  else
                    vs.state := bfill; vs.hready := not ahbsi.hmastlock;
                    vs.wbaddr := ahbsi.haddr(wbbits+1 downto 2);
                    vs.nwords := (others => '0');
                    if CORE_ACDM = 1 then vs.wbhaddr := ahbsi.haddr(4 downto 2); end if;
                  end if;
                  vs.splmst := ahbsi.hmaster;
                  -- No need to set abort, we have asserted HSPLIT for the
                  -- splitted master when entering this state:
                  -- if SPLANDLCK then vs.sv.abort := ahbsi.hmastlock; end if;
                  if DBLLCK then vs.mstlock := ahbsi.hmastlock; end if;
                  if split /= 0 and fcfs /= 0 then handled := '1'; end if;
                else
                  if fcfs = 0 then vs.hsplit(conv_integer(ahbsi.hmaster)) := '1'; end if;
                  vs.hready := '0'; vs.hresp := HRESP_SPLIT;
                end if;
              else
                vs.hready := '0';
                -- In lckdac = 1 we should respond with error to incoming locked
                -- access, unless the SPLIT'd master has returned.
                if SPLNOLCK and rs.ba = '0' and ahbsi.hmastlock = '1' then
                  vs.hresp := HRESP_ERROR;
                else
                  -- Here we may respond with a SPLIT response to an incoming
                  -- locked transfer.
                  vs.hresp := HRESP_SPLIT;
                  if fcfs = 0 then vs.hsplit(conv_integer(ahbsi.hmaster)) := '1'; end if;
                end if;
              end if;
            end if;
          end if;
          if SPLANDLCK and rs.sv.pfact = '1' then
            if (rs.sv.err = '1') and (rs.sv.rbaddr = vs.rbaddr) then
              vs.err := '1';
            end if;
          else
            if (m2s.err = '1') and (m2s.rbaddr = vs.rbaddr) then
              vs.err := '1';
            end if;
          end if;
          if SPLANDLCK then vs.sv.nofetch := '0'; end if;
        end if;
        
      when ret =>
        -- In order to improve performance (on the access we are currently serving)
        -- we could wait here in the case of BUSY cycles. Currently we will go
        -- to sidle and (if split /= 0)issue a SPLIT response when the master goes BUSY -> SEQ.
        vs.state := sidle;
        if (hsel and ahbsi.hready and ahbsi.htrans(1)) = '1' then
          if MATCHDIS or match = '1' then
            if ahbsi.hwrite = '0' then
              if ahbsi.htrans(0) = '0' then -- HTRANS_NONSEQ
                vs.hready := '0';
                if split /= 0 then
                  if ahbsi.hmastlock = '0' then vs.hresp := HRESP_SPLIT;
                  elsif fcfs /= 0 then vs.fcfs.hold := '1'; end if;
                end if;
                if pfetch = '0' then
                  vs.state := split2;
                else
                  vs.state := pfsplit; vs.race := '0';
                end if;
              else                          -- HTRANS_SEQ
                vs.state := saddr; vs.hready := '0';
                vs.race := '0';
              end if;
              if split /= 0 and SPLANDLCK and rs.sv.act = '1' and rs.sv.mst = ahbsi.hmaster then
                -- Bridge has a saved response for access that was aborted by
                -- incoming locked transfer.
                -- Handle the access here directly
                if pfen = 0 or rs.sv.pfact = '0' then
                  vs.hready := '1';
                  vs.hresp := rs.sv.hresp;
                  vs.hrdata := rs.sv.hrdata;
                  if rs.sv.hresp /= HRESP_OKAY then vs.hready := '0'; end if;
                  vs.race := rs.race;
                  vs.sv.act := '0';
                else
                  vs.sv.nofetch := '1';
                  vs.hready := '0'; vs.hresp := HRESP_OKAY;
                end if;
              end if;
            else
              vs.state := bfill; vs.hready := not ahbsi.hmastlock;
              vs.wbaddr := ahbsi.haddr(wbbits+1 downto 2);
              vs.nwords := (others => '0');
              if CORE_ACDM = 1 then vs.wbhaddr := ahbsi.haddr(4 downto 2); end if;
            end if;
            if split /= 0 then vs.splmst := ahbsi.hmaster; end if;
            if split /= 0 and fcfs /= 0 then handled := '1'; end if;
            if DBLLCK then vs.mstlock := ahbsi.hmastlock; end if;
          elsif split /= 0 then
            if fcfs = 0 then vs.hsplit(conv_integer(ahbsi.hmaster)) := '1'; end if;
            vs.hready := '0'; vs.hresp := HRESP_SPLIT;
          end if;
        end if;
        
      when saddr =>
        vs.hready := '0';
--        buslock := '1';
        if CHECKRACE1 or (pipe /= 0) then
          if m2s.state /= mdata2 then
            vs.race := '0';
          end if;
        end if;
        if (slv = 1) and (m2s.state = brel) then
          vs.hready := '0'; vs.hresp := HRESP_RETRY;
          vs.state := sidle;
        elsif ((m2s.state = mdata2) and
               (not (CHECKRACE1 or pipe /= 0) or (vs.race = '0')) and
               (not (CHECKRACE3) or (rs.race = '0'))) then
          vs.hready := '1'; vs.state := sdata;
          vs.hrdata := m2s.hdata(SMAXDW-1 downto 0);
          vs.hresp := m2s.hresp;
          if (m2s.hresp /= HRESP_OKAY) then vs.hready := '0'; end if;
        end if;
        
      when sdata =>
        if (hsel and ahbsi.hready and ahbsi.htrans(1)) = '1' then
          if ahbsi.htrans(0) = '1' then  -- HTRANS_SEQ
            vs.state := saddr;
            if CHECKRACE1 or pipe /= 0 then vs.race := '1'; end if;
            vs.hready := '0';
          else
            if MATCHDIS or match = '1' then
              if ahbsi.hwrite = '0' then -- HTRANS_NONSEQ, read
                vs.hready := '0';
                if split /= 0 then
                  if ahbsi.hmastlock = '0' then vs.hresp := HRESP_SPLIT;
                  elsif fcfs /= 0 then vs.fcfs.hold := '1'; end if;
                end if;
                if pfetch = '0' then
                  vs.state := split2;
                else
                  vs.state := pfsplit; vs.race := '0';
                end if;
                if split /= 0 and SPLANDLCK and rs.sv.act = '1' and rs.sv.mst = ahbsi.hmaster then
                  -- Bridge has a saved response for access that was aborted by
                  -- incoming locked transfer.
                  -- Handle the access here directly
                  if pfen = 0 or rs.sv.pfact = '0' then
                    vs.hready := '1';
                    vs.hresp := rs.sv.hresp;
                    vs.hrdata := rs.sv.hrdata;
                    if rs.sv.hresp /= HRESP_OKAY then vs.hready := '0'; end if;
                    vs.race := rs.race;
                    vs.state := sidle;
                    vs.sv.act := '0';
                  else
                    vs.sv.nofetch := '1';
                    vs.hready := '0'; vs.hresp := HRESP_OKAY;
                  end if;
                end if;
              else                      -- HTRANS_NONSEQ, write
                vs.state := bfill; vs.hready := not ahbsi.hmastlock;
                vs.wbaddr := ahbsi.haddr(wbbits+1 downto 2);
                vs.nwords := (others => '0');
                if CORE_ACDM = 1 then vs.wbhaddr := ahbsi.haddr(4 downto 2); end if;
              end if;
              if split /= 0 then vs.splmst := ahbsi.hmaster; end if;
              if split /= 0 and fcfs /= 0 then handled := '1'; end if;
              if DBLLCK then vs.mstlock := ahbsi.hmastlock; end if;
            elsif split /= 0 then
              if fcfs = 0 then vs.hsplit(conv_integer(ahbsi.hmaster)) := '1'; end if;
              vs.hready := '0'; vs.hresp := HRESP_SPLIT;
            end if;
          end if;
        elsif not (hsel = '1' and ahbsi.hready = '1' and ahbsi.htrans = HTRANS_BUSY) then
          vs.state := sidle;
        end if;
        
      when bfill =>
        if (rs.hready = '0') and (rs.hresp = HRESP_OKAY) then
          vs.hready := '0';
        end if;

        if rs.wr = '1' then
          if SMAXDW > 128 and rs.hsize = HSIZE_8WORD then
            if (conv_integer(rs.wbaddr) = (wburst-8)) then
              vs.bfull := '1';
            end if;
          elsif SMAXDW > 64 and rs.hsize = HSIZE_4WORD then
            if (conv_integer(rs.wbaddr) = (wburst-4)) then
              vs.bfull := '1';
            end if;
          elsif SMAXDW > 32 and rs.hsize = HSIZE_DWORD then
            if (conv_integer(rs.wbaddr) = (wburst-2)) then
              vs.bfull := '1';
            end if;
          else
            if (conv_integer(rs.wbaddr) = (wburst-1)) then
              vs.bfull := '1';
            end if;
          end if;
        end if;
        
        if ((ahbsi.hmastlock = '1' or wrcomb /= 0) and
               ((hsel = '1') and (ahbsi.htrans = HTRANS_BUSY))) and vs.bfull = '0' then
          -- If write combining is disabled and the incoming access is not locked
          -- we always go to bflush if we get a access that is not HTRANS_SEQ.
          -- If write combining is enabled or the incoming access is locked we
          -- will not flush the buffer if the master drives HTRANS_BUSY.
          vs.wr := '0';
          vs.hready := '1';
        elsif (hsel = '1') and ((ahbsi.htrans = HTRANS_NONSEQ) or (vs.bfull = '1')) then
          vs.state := bflush;
          if ahbsi.htrans(1) = '1' then
            vs.hready := '0';
            -- Handle case where the burst is longer than the write buffer. We
            -- need to be able to issue a ERROR response in the case of a
            -- bi-directional configuration. The access will then be handled
            -- when we return to sidle.
            if split = 0 then
              -- Issue RETRY response, otherwise the last that did not fit into
              -- the buffer will be registered as completed when the bridge
              -- returns to sidle and asserts hready
              if rs.hmastlock = '0' then vs.hresp := HRESP_RETRY; end if;
            else
              if rs.hmastlock = '0' then
                vs.hresp := HRESP_SPLIT;
                if fcfs = 0 then vs.hsplit(conv_integer(ahbsi.hmaster)) := '1'; end if;
              elsif fcfs /= 0 then vs.fcfs.hold := '1'; end if;
            end if;
          end if;
        elsif (hsel = '1') and (ahbsi.htrans = HTRANS_SEQ) then
          -- If the incoming access is locked, add one wait state to each access
          -- in order to be able to give an error response in bflush. Really only
          -- required for bi-directional configurations. However, locked write
          -- are typically rare in GRLIB systems so we live with the extra
          -- penalty in all configs.
          if rs.hmastlock = '1' then vs.hready := not rs.hready; end if;
          vs.wr := rs.hready;
        else
          vs.state := bflush;
        end if;

        wr := rs.wr;

--        if (rs.hready = '0') and (rs.hresp = HRESP_OKAY) then
--          vs.wr := '0';
--        end if;
        
        if rs.wr = '1' then
          vs.nwords := winc(SMAXDW, rs.nwords, rs.hsize);
        end if;

        if CORE_ACDM = 1 then vs.wbhaddr := ahbsi.haddr(4 downto 2); end if;
        
        if vs.state = bfill and rs.wr = '1' then
          vs.wbaddr := baddrinc(SMAXDW, rs.wbaddr, rs.hsize);
        end if;

        vs.race := '0';
        if CHECKRACE1 or (pipe /= 0) then
          if (vs.state = bflush) and (m2s.state = wrburst2) then
            vs.race := '1';
          end if;
        end if;

      when bflush =>
        if (rs.hready = '0') and (rs.hresp = HRESP_OKAY) then
          vs.hready := '0';
        end if;

        if CHECKRACE1 or (pipe /= 0) then
          if (m2s.state /= wrburst2) then
            vs.race := '0';
          end if;
        end if;

        if (ahbsi.hready and hsel and ahbsi.htrans(1)) = '1' then
          -- Here we may issue a SPLIT response to a locked access even
          -- when lckdac /= 2
          vs.hready := '0';
          if split /= 0 then
            vs.hresp := HRESP_SPLIT;
            if fcfs = 0 then vs.hsplit(conv_integer(ahbsi.hmaster)) := '1'; end if;
          else
            vs.hresp := HRESP_RETRY;
          end if;
        elsif (m2s.state = wrburst2) and (rs.race = '0') and (split = 0 or rs.hresp = HRESP_OKAY) then
          if DBLLCK and slv = 1 and m2s.err = '1' then
            -- ERROR response for locked access in both directions in
            -- bidirectional configuration.
            vs.hresp := HRESP_ERROR;
          end if;
          -- For non-FCFS mode and split /= 0:
          -- In the previous cycle we may have issued a SPLIT response to an
          -- incoming master and in the next cycle we will be in sidle where
          -- yet another master (or the master that initiated the write that
          -- got us here) gets to perform an access to the bridge. This can
          -- happen in several scenarios with the bridge. If all masters except
          -- one have received SPLIT responses, the master that is "free" has
          -- an advantage since it can perform an access in the cycle where the
          -- other masters are unsplit:ed and the bridge is free. This may alter
          -- the arbitration order of the bus and is something that we will
          -- have to live with. However, in this scenario we have a potential
          -- starvation issue since we may end up here with the same master
          -- SPLIT:ed over and over again. To lower the odds of this we unsplit
          -- all masters here. That way there will not be a situation where the
          -- bridge is free and one or several masters are SPLIT:ed, providing
          -- an advantage during one cycle for masters that have not received
          -- SPLIT.
          --
          if split /= 0 then
            if fcfs = 0 then hsplit := rs.hsplit; vs.hsplit := (others => '0');
            else unsplit := '1'; end if;
          end if;
          vs.state := sidle;
        end if;
      when others =>
    end case;

    if (rs.hready = '0') and (rs.hresp /= HRESP_OKAY) then
      vs.hready := '1'; vs.hresp := rs.hresp;
    end if;

    if (m2s.state = wreq or m2s.mwreq = '1') then vs.mwreq := '1'; else vs.mwreq := '0'; end if;
    
    if split /= 0 then
      vs.nsplit := '0';
      if (rs.state = split2) and (rs.mwreq = '1') and (rs.race = '0') and (rs.hmastlock = '0') then
        if not SPLANDLCK or vs.sv.act = '0' or vs.state /= sidle then
          vs.nsplit := rs.nsplit;         -- Keep value so that nsplit does not toggle
        end if;
        if (rs.hresp /= HRESP_SPLIT) then
          if rs.nsplit = '0' then
            if fcfs = 0 then
              hsplit(conv_integer(rs.splmst)) := '1';
              vs.hsplit(conv_integer(rs.splmst)) := '0';
            else
              -- Do not assert HSPLIT in ret if it has been asserted here
              unsplit := '1';
              vs.fcfs.rethold := '1';
            end if;
          end if;
          -- Do not assert multiple SPLIT complete
          if not SPLANDLCK or vs.sv.act = '0' then vs.nsplit := '1'; end if;
        end if;
      elsif (rs.state = pfread) and (vs.state = pfread) then
        vs.nsplit := '1';
      elsif (fcfs /= 0) and (rs.state = sidle or rs.state = bflush) and (vs.state = sidle) then
        vs.nsplit := rs.nsplit;         -- Keep value so that nsplit does not toggle
        if rs.hresp /= HRESP_SPLIT then
          vs.nsplit := '1';
        end if;
      elsif (fcfs /= 0) and (rs.state = saddr or rs.state = sdata) then
        vs.nsplit := rs.nsplit;
      end if;
    
      if rs.state = ret then
        -- We may already have asserted HSPLIT for the master in the split2
        -- expression above. 
        if fcfs = 0 then hsplit := rs.hsplit; vs.hsplit := (others => '0');
        else
          unsplit := not rs.fcfs.rethold;
          vs.nsplit := rs.fcfs.sp2hold;
          vs.fcfs.rethold := '0';
          vs.fcfs.sp2hold := '0';
          if SPLANDLCK then
            vs.nsplit := vs.nsplit or rs.sv.sphold;
            vs.sv.sphold := '0';
          end if;
        end if;
      end if;

      if (fcfs /= 0) and (rs.state /= split2) and (rs.state /= ret) then
        vs.fcfs.rethold := '0'; vs.fcfs.sp2hold := '0';
      end if;
    end if; -- split /= 0
    
    if (rs.state /= split2) and (vs.state = split2) and
      (m2s.state = wreq or (pipe /= 0 and m2s.state = brel)) then
      vs.race := '1';
    end if;
    if pipe /= 0 then
      if rs.state /= split2 and vs.state = split2 then vs.sp2tog := not rs.sp2tog; end if;
    end if;
      
    if (rs.state /= bfill) and (vs.state = bfill) then vs.bfull := '0'; end if;
    if (rs.state /= bfill) and (vs.state = bfill) then vs.wr := '1'; end if;

    if (rs.state /= pfsplit) then vs.ardy := '0'; else vs.ardy := '1'; end if;

    if split /= 0 and SPLANDLCK and rs.state /= pfsplit then vs.sv.abort := '0'; end if;
    
    if (vs.state = pfsplit) or (vs.state = pfread) then ren := '1'; end if;

    if pfen /= 0 then
      if (rs.state /= pfsplit) and (vs.state = pfsplit) then vs.pfhsize := ahbsi.hsize; end if;
    else
      vs.pfhsize := (others => '0');
    end if;
    
    -- Interface disable
    if ifctrlen /= 0 then
      if ifctrl.slvifen = '0' then
        -- Slave interface disabled
        vs.state := sidle;
        vs.hready := '1';
        vs.hresp := HRESP_OKAY;
        if split /= 0 then
          if fcfs = 0 then  vs.hsplit := rs.hsplit;
          else unsplit := '0'; vs.fcfs := rs.fcfs; end if;
          vs.splmst := rs.splmst;
          hsplit := (others => '0');
          if SPLANDLCK then vs.sv := rs.sv; end if;
        end if;
      end if;
    end if;
    
    -- First come, first served queue handling
    if split /= 0 and fcfs /= 0 then
      sbren := rs.fcfs.act;
      -- SPLIT complete
      if unsplit = '1' then vs.fcfs.hold := '0'; end if;
      if (unsplit and (rs.fcfs.act or rs.fcfs.lck)) = '1' then
        -- Assertion of unsplit may come from completion of a locked access
        -- that did not receive a split response. In that case, hold will be
        -- '1'.
        if rs.fcfs.hold = '0' or (SPLANDLCK and (rs.sv.act and rs.sv.unsplit) = '1') then
          -- Here we handle complete SPLIT for all accesses that have received
          -- SPLIT responses.
          if rs.fcfs.lck = '1' then
            -- Restore after handling locked access, this also takes care of
            -- the case with SPLANDLCK and saved accesses when the locked
            -- access received a SPLIT response
            hsplit(conv_integer(rs.fcfs.lcksmst)) := '1';
            vs.fcfs.lck := '0';
          elsif (((not SPLANDLCK) or (rs.sv.act = '0' or rs.sv.unsplit = '1')) and 
                 ((rs.fcfs.retwait = '0') or (handled = '1' and vs.splmst = rs.fcfs.splmst))) then
            -- Last access was not locked, or, we issue complete SPLIT to an
            -- access that was interrupted by a locked access.
            -- rs.fcfs.keep = '1' signals that a SPLIT response was issued to
            -- the master at the HEAD of the queue. In that case we do not
            -- advance the queue.
            if rs.fcfs.keep = '0' then
              vs.fcfs.ui := rs.fcfs.ui + 1;
              vs.fcfs.splmst := sb_do;
              hsplit(conv_integer(sb_do)) := '1';
            else
              -- Complete SPLIT to master 
              hsplit(conv_integer(rs.fcfs.splmst)) := '1';
            end if;
            if (vs.fcfs.ui = rs.fcfs.si) then
              vs.fcfs.act := '0';
            end if;
            vs.fcfs.handled := '0';
            vs.fcfs.retwait := not rs.fcfs.handled;
            vs.sv.unsplit := '0';
            vs.fcfs.keep := '0';
          end if;
        elsif SPLANDLCK and rs.sv.act = '1' then
          -- Core may have a saved access due to an interruption by a locked
          -- access. In that case unsplit the master for which we have saved
          -- data. The case covered is when the first access was interrupted
          -- before unsplit was issued.
          vs.fcfs.splmst := rs.sv.mst;
        end if;
      end if;

      -- SPLIT response
      if vs.hready = '0' and vs.hresp = HRESP_SPLIT then
        -- Locked accesses have precedence
        vs.fcfs.lck := ahbsi.hmastlock;
        -- Signal if current access is handled
        -- If we have active responses, then this is not the final handling of
        -- this access.
        if ahbsi.hmastlock = '0' then
          vs.fcfs.handled := handled;
          sbdi := ahbsi.hmaster;
          -- If we issue a SPLIT response to master at the head of the queue,
          -- do not add it last.
          if (rs.fcfs.act and handled) = '1' then 
            vs.fcfs.keep := '1';
          else
            sbwr := '1';
            vs.fcfs.si := rs.fcfs.si + 1;
          end if;
          vs.fcfs.act := '1';
        else
          -- Locked access
          vs.fcfs.lcksmst := ahbsi.hmaster;
        end if;
      else
        -- If the access does not receive yet another SPLIT response we need to
        -- set handled to 1 so that we do not wait for the master to return again.
        -- We check for vs.splmst = rs.fcfs.splmst so that we do not accidentally
        -- set handled high when handling a sequence of locked accesses. 
        if rs.fcfs.act = '0' and handled = '1' and vs.splmst = rs.fcfs.splmst then
          vs.fcfs.handled := '1';
        end if;
      end if;

      if handled = '1' and vs.splmst = rs.fcfs.splmst then
        vs.fcfs.retwait := '0';
      end if;
    end if; -- fcfs /= 0 and split /= 0

    -- Core reset
    if (not RESET_ALL) and (rstn = '0') then
      vs.state := SRES.state; vs.wbaddr := SRES.wbaddr;
      vs.race := SRES.race; vs.err := SRES.err; vs.wr := SRES.wr;
      vs.nwords := SRES.nwords;
      if split /= 0 then
        if SPLANDLCK then
          vs.sv.act := SRES.sv.act;
          if pfen /= 0 then
            vs.sv.pfact := SRES.sv.pfact;
            vs.sv.nofetch := SRES.sv.nofetch;
          end if;
          vs.sv.sphold := SRES.sv.sphold;
        end if;
        if fcfs /= 0 then
          vs.fcfs.act     := SRES.fcfs.act;
          vs.fcfs.si      := SRES.fcfs.si;
          vs.fcfs.ui      := SRES.fcfs.ui;
          vs.fcfs.splmst  := SRES.fcfs.splmst;
          vs.fcfs.lck     := SRES.fcfs.lck;
          vs.fcfs.hold    := SRES.fcfs.hold;
          vs.fcfs.keep    := SRES.fcfs.keep;
          vs.fcfs.handled := SRES.fcfs.handled;
          vs.fcfs.retwait := SRES.fcfs.retwait;
        else
          vs.hsplit := SRES.hsplit;
        end if;
      end if;
      vs.sp2tog := SRES.sp2tog;
    end if;

    if pipe = 0 then vs.sp2tog := '0'; end if;
    
    if not DBLLCK then vs.mstlock := '0'; end if;

    if (split = 0) or (not SPLANDLCK) then
      vs.sv.abort   := '0';
      vs.sv.act     := '0';
      vs.sv.mst     := (others => '0');
      vs.sv.hrdata  := (others => '0');
      vs.sv.hresp   := (others => '0');
      vs.sv.unsplit := '0';
      vs.sv.pfact   := '0';
      vs.sv.rbaddr  := (others => '0');
      vs.sv.err     := '0';
      vs.sv.nofetch := '0';
      vs.sv.sphold  := '0';
    end if;

    if (split = 0) or (fcfs = 0) then
      vs.fcfs.act     := '0';
      vs.fcfs.si      := (others => '0');
      vs.fcfs.ui      := (others => '0');
      vs.fcfs.splmst  := (others => '0');
      vs.fcfs.lcksmst := (others => '0');
      vs.fcfs.lck     := '0';
      vs.fcfs.rethold := '0';
      vs.fcfs.sp2hold := '0';
      vs.fcfs.hold    := '0';
      vs.fcfs.keep    := '0';
      vs.fcfs.handled := '0';
      vs.fcfs.retwait := '0';
      sbdi            := (others => '0');
      sbwr            := '0';
      sbren           := '0';
      vs.sv.unsplit   := '0';
    end if;

    if (split = 0) or (fcfs /= 0) then
      vs.hsplit := (others => '0');
    end if;

    if split = 0 then
      vs.splmst := (others => '0');
      vs.nsplit := '0';
    end if;

    if pfen = 0 then
      vs.sv.pfact := '0'; vs.sv.rbaddr := (others => '0');
      vs.sv.err := '0'; vs.sv.nofetch := '0';
    end if;
    
    -- wbhaddr not used if CORE_ACDM is disabled
    if CORE_ACDM = 0 then vs.wbhaddr := (others => '0'); end if;
    
    rsin <= vs;

    -- slave configuration info
    slvcfg := (others => (others => '0'));
    slvcfg(0) := ahb_device_reg(VENDOR_GAISLER, GAISLER_AHB2AHB, 0, AHB2AHB_VER, 0);
    slvcfg(1)(8) := conv_std_logic(UP);
    slvcfg(1)(7 downto 4) := conv_std_logic_vector(ffact, 4);
    slvcfg(1)(3 downto 2) := conv_std_logic_vector(mbus, 2);
    slvcfg(1)(1 downto 0) := conv_std_logic_vector(sbus, 2);
    slvcfg(2)(31 downto 20) := conv_std_logic_vector(ioarea, 12);
    tbar := conv_std_logic_vector(bar0, 30);
    slvcfg(4)(31 downto 20) := tbar(29 downto 18); slvcfg(4)(17 downto 0) := tbar(17 downto 0);
    tbar := conv_std_logic_vector(bar1, 30);
    slvcfg(5)(31 downto 20) := tbar(29 downto 18); slvcfg(5)(17 downto 0) := tbar(17 downto 0);
    tbar := conv_std_logic_vector(bar2, 30);
    slvcfg(6)(31 downto 20) := tbar(29 downto 18); slvcfg(6)(17 downto 0) := tbar(17 downto 0);
    tbar := conv_std_logic_vector(bar3, 30);
    slvcfg(7)(31 downto 20) := tbar(29 downto 18); slvcfg(7)(17 downto 0) := tbar(17 downto 0);

    ahbso.hready <= rs.hready;
    ahbso.hresp  <= rs.hresp;
    ahbso.hrdata <= ahbdrivedata(rs.hrdata);
    if split /= 0 then ahbso.hsplit <= hsplit;
    else ahbso.hsplit <= (others => '0'); end if;
    if ifctrlen = 0 or ifctrl.slvifen = '1' then
      if DOWN then ahbso.hirq <= hsb_hirqo; else ahbso.hirq <= lsb_hirqo; end if;
    else
      ahbso.hirq <= (others => '0');
    end if;
    ahbso.hconfig <= slvcfg;
    ahbso.hindex <= hsindex;

    -- FCFS SPLIT buffer
    if scantest = 1 and (ahbsi.scanen and ahbsi.testen) = '1' then
      sb_ren <= '0';
      sb_wr  <= '0';
    else
      sb_ren <= sbren;
      sb_wr  <= sbwr;
    end if;
    sb_di  <= sbdi;
    
    -- Read buffer
    rb_addr <= vs.rbaddr;
    
    if scantest = 1 and (ahbsi.scanen and ahbsi.testen) = '1' then
      -- Read buffer read enable
      rb_ren <= (others => '0');
      -- Write buffer write enable
      wb_wr <= (others => '0');
    else
      -- Read buffer read enable decoding
      for i in rb_ren'range loop
        rb_ren(i) <= ren;
      end loop;  -- i
      -- Write buffer write enable decoding
      for i in wb_wr'range loop
        -- If there is an incoming burst we only want to write specific parts of
        -- the buffer. If there is an incoming single access we write to all parts
        -- of the buffer and do not need to select and duplicate the data on the
        -- other side of the buffer. This means that the bridge will not "fix"
        -- masters that do not adhere to the GRLIB method of duplicating valid
        -- data onto all invalid lines.
        wb_wr(i) <= wr and not orv(rs.hburst);
        --
        if (SMAXDW > 128 and rs.hsize = HSIZE_8WORD) then
          wb_wr(i) <= wr;
        elsif SMAXDW > 64 and rs.hsize = HSIZE_4WORD then
          if (maxdw = 128 or conv_integer(rs.wbaddr(2)) = i/4) then
            wb_wr(i) <= wr;
          end if;
        elsif SMAXDW > 32 and rs.hsize = HSIZE_DWORD then
          if (maxdw = 64 or conv_integer(rs.wbaddr((1+maxdw/256) downto 1)) = i/2) then
            wb_wr(i) <= wr;
          end if;
        elsif ((maxdw = 32) or
               (conv_integer(rs.wbaddr(log2x(maxdw/32)-1 downto 0)) =
                (i mod (maxdw/32)))) then
          wb_wr(i) <= wr;
        end if; 
      end loop;  -- i
    end if;
    
    -- Lock signaling
    lcko.blck <= buslock;
    lcko.mlck <= rs.mstlock;
    
    if rs.state=sidle and rm.state=midle then idle<='1'; else idle<='0'; end if;
  end process;

  -----------------------------------------------------------------------------
  -- FCFS SPLIT'd master buffer
  -----------------------------------------------------------------------------
  -- Small RAM abstraction to keep track of SPLIT:ed masters, will typically be
  -- implemented as flip-flops
  fcfssplitbuf : if split /= 0 and fcfs /= 0 generate
    fcfsbuf : syncram_2p
      generic map (
        tech     => fcfsmtech,
        abits    => log2x(fcfs),
        dbits    => 4,
        sepclk   => 0,
        wrfst    => 0,
        testen   => 0)
      port map (
        rclk     => hclks,
        renable  => sb_ren,
        raddress => rs.fcfs.ui,
        dataout  => sb_do,
        wclk     => hclks,
        write    => sb_wr,
        waddress => rs.fcfs.si,
        datain   => sb_di);
  end generate;
  nofcfssplit : if split = 0 or fcfs = 0 generate
    sb_do <= (others => '0');
  end generate;
  
  -----------------------------------------------------------------------------
  -- AHB master side combination logic
  -----------------------------------------------------------------------------
  mstcomb : process(rstn, ahbmi, rm, wbo, lcki, hsb_hirqo, lsb_hirqo, ifctrl, s2m)
    variable vm      : master_type;
    variable htrans  : std_logic_vector(1 downto 0);
    variable hbusreq : std_ulogic;
    variable hburst  : std_logic_vector(2 downto 0);
    variable hlock   : std_ulogic;
    variable burst   : std_ulogic;
    variable mload   : std_ulogic;
    variable wr      : std_ulogic;
    variable haddr   : std_logic_vector(31 downto 0);
    variable hrdata  : std_logic_vector(MMAXDW-1 downto 0);
    variable hwrite  : std_ulogic;
    variable rbaddr  : std_logic_vector(rbufbits-1 downto 0);
    variable lw      : std_ulogic;
    variable lwx     : std_ulogic;
    variable ren     : std_ulogic;
    variable combine : std_ulogic;
    variable wrap    : std_ulogic;
    variable fixed   : std_ulogic;
    variable mstcfg  : ahb_config_type;
  begin

    vm := rm;

    vm.resp2c := not ahbmi.hready and (ahbmi.hresp(1) or ahbmi.hresp(0)) and rm.ba;
    wr := '0'; lw := '0'; lwx := '0'; rbaddr := (others => '0');
    if ahbmi.hready = '1' then vm.ldp := '0'; end if;  ren := '0'; burst := '0';
    rb_wr <= (others => '0'); combine := '0'; wrap := '0'; fixed := '0';

    htrans := HTRANS_IDLE; hbusreq := '0';
    hburst := rm.hburst; mload := '0';
    hlock := rm.hmastlock;
    haddr := rm.haddr;
    hrdata := (others => '0');
    
    if allbrst = 0 then
      if rm.hburst /= HBURST_SINGLE then burst := not rm.nbsy; end if;
    else
      case rm.hburst is
        when HBURST_INCR => burst := not rm.nbsy;
        when HBURST_WRAP4 | HBURST_INCR4   => if rm.bsycnt /= "0100" then burst := '1'; end if;
        when HBURST_WRAP8 | HBURST_INCR8   => if rm.bsycnt /= "1000" then burst := '1'; end if;
        when HBURST_WRAP16 | HBURST_INCR16 => if rm.bsycnt /= "0000" then burst := '1'; end if;
        when others =>
      end case;
    end if;

    case rm.state is
      when midle =>
        -- If lock from slave side is asserted and master side holds lock then
        -- wait, otherwise lock may be asserted for first address phase of the
        -- next (non-locked) access.
        if (not s2m.hmastlock and rm.hmastlock) = '0' then
          if s2m.state = split2 then
            vm.state := addr0; vm.nseq := '0';
            if pipe /= 0 then vm.sp2tog := s2m.sp2tog; end if;
          elsif s2m.state = bflush then
            vm.state := wrburst; vm.nseq := '1'; vm.nwords := (others => '0');
            vm.wbaddr := s2m.haddr(wbbits+1 downto 2);
          elsif (pfen = 1) and ((s2m.state = pfsplit) and (s2m.ardy = '1')
                                and (not SPLANDLCK or s2m.nofetch = '0')) then
            vm.state := pfget;
            vm.rbaddr := s2m.rbaddr;
            vm.nseq := '1'; vm.err := '0';
          end if;
        end if;
        vm.addrlock := '1';
        
      when pfget =>
        if (pfen = 1) then
          rbaddr := (others => '1');
          if incr_burst(rm.hburst) then
            if (ibrsten = 0) or (rm.hprot(0) = '1') then
              rbaddr(rbbits-1 downto 0) := rm.rbaddr(rbbits-1 downto 0);
            else
              rbaddr(ibbits-1 downto 0) := rm.rbaddr(ibbits-1 downto 0);
            end if;
            if rdcomb /= 0 then
              if rm.hsize /= HSIZE_BYTE and rm.hsize /= HSIZE_HWORD then
                if pfget_limit_reached(rbaddr, rbufbits-1, log2(MMAXDW/16)) then
                  lwx := not rm.rbaddr(log2(MMAXDW/32));
                  lw := rm.rbaddr(log2(MMAXDW/32));
                end if;
              else
                if (rbaddr(rbufbits-1 downto 1) = one32(rbufbits-1 downto 1)) then
                  lwx := not rm.rbaddr(0); lw := rm.rbaddr(0);
                end if;
              end if;
            else
              if MMAXDW > 128 and rm.hsize = HSIZE_8WORD then
                if pfget_limit_reached(rbaddr, rbufbits-1, 4) then
                  lwx := not rm.rbaddr(3); lw := rm.rbaddr(3);
                end if;
              elsif MMAXDW > 64 and rm.hsize = HSIZE_4WORD then
                if pfget_limit_reached(rbaddr, rbufbits-1, 3) then
                  lwx := not rm.rbaddr(2); lw := rm.rbaddr(2);
                end if;
              elsif MMAXDW > 32 and rm.hsize = HSIZE_DWORD then
                if pfget_limit_reached(rbaddr, rbufbits-1, 2) then
                  lwx := not rm.rbaddr(1); lw := rm.rbaddr(1);
                end if;
              else
                if (rbaddr(rbufbits-1 downto 1) = one32(rbufbits-1 downto 1)) then
                  lwx := not rm.rbaddr(0); lw := rm.rbaddr(0);
                end if;
              end if;  
            end if;
          else
            rbaddr(rbufbits-1 downto 0) := rm.rbaddr(rbufbits-1 downto 0);
            case rm.hburst is
              when HBURST_WRAP4 | HBURST_INCR4 =>
                if mindw > 128 and rm.hsize = HSIZE_8WORD then
                  if pfget_limit_reached(rbaddr, 4, 4) then
                    lwx := not rm.rbaddr(3); lw := rm.rbaddr(3);
                  end if;
                elsif mindw > 64 and rm.hsize = HSIZE_4WORD then
                  if pfget_limit_reached(rbaddr, 3, 3) then
                    lwx := not rm.rbaddr(2); lw := rm.rbaddr(2);
                  end if;
                elsif mindw > 32 and rm.hsize = HSIZE_DWORD then
                  if pfget_limit_reached(rbaddr, 2, 2) then
                    lwx := not rm.rbaddr(1); lw := rm.rbaddr(1);
                  end if;
                else
                  if rbaddr(1) = one32(1) then
                    lwx := not rm.rbaddr(0); lw := rm.rbaddr(0);
                  end if;
                end if;
              when HBURST_WRAP8 | HBURST_INCR8 =>
                if mindw > 128 and rm.hsize = HSIZE_8WORD then
                  if pfget_limit_reached(rbaddr, 5, 4) then
                    lwx := not rm.rbaddr(3); lw := rm.rbaddr(3);
                  end if;
                elsif mindw > 64 and rm.hsize = HSIZE_4WORD then
                  if pfget_limit_reached(rbaddr, 4, 3) then
                    lwx := not rm.rbaddr(2); lw := rm.rbaddr(2);
                  end if;
                elsif mindw > 32 and rm.hsize = HSIZE_DWORD then
                  if rbaddr(3 downto 2) = one32(3 downto 2) then
                    lwx := not rm.rbaddr(1); lw := rm.rbaddr(1);
                  end if;
                else
                  if rbaddr(2 downto 1) = one32(2 downto 1) then
                    lwx := not rm.rbaddr(0); lw := rm.rbaddr(0);
                  end if;
                end if;
              when HBURST_WRAP16 | HBURST_INCR16 =>
                if mindw > 128 and rm.hsize = HSIZE_8WORD then
                  if pfget_limit_reached(rbaddr, 6, 4) then
                    lwx := not rm.rbaddr(3); lw := rm.rbaddr(3);
                  end if;
                elsif mindw > 64 and rm.hsize = HSIZE_4WORD then
                  if pfget_limit_reached(rbaddr, 5, 3) then
                    lwx := not rm.rbaddr(2); lw := rm.rbaddr(2);
                  end if;
                elsif mindw > 32 and rm.hsize = HSIZE_DWORD then
                  if pfget_limit_reached(rbaddr, 4, 2) then
                    lwx := not rm.rbaddr(1); lw := rm.rbaddr(1);
                  end if;
                else
                  if pfget_limit_reached(rbaddr, 3, 1) then
                    lwx := not rm.rbaddr(0); lw := rm.rbaddr(0);
                  end if;
                end if;
              when others => null;
            end case;
          end if;

          if rm.nseq = '1' then htrans := HTRANS_NONSEQ; elsif lw = '0' then htrans := HTRANS_SEQ; end if;
          if rm.resp2c = '1' then htrans := HTRANS_IDLE; end if;
          if (rm.bg and ahbmi.hready) = '1' then vm.nseq := '0'; vm.addrlock := '0'; end if;
          if (rm.hmastlock and not (rm.bl or rm.ba)) = '1' then htrans := HTRANS_IDLE; end if;
          if rm.addrlock = '0' then haddr := addrinc(rm); end if;

          if split = 0 then
            -- SPLIT may lead to deadlock in bi-dir configs with split = 0
            if (slv = 1) and (lcki.slck = '1') then vm.state := brel; htrans := HTRANS_IDLE; end if;
          end if;

          if ahbmi.hready = '1' then
            if rm.ba = '1' then
              wr := '1';
              case ahbmi.hresp is
                when HRESP_SPLIT | HRESP_RETRY =>
                  vm.nseq := '1'; vm.addrlock := '1';
                when HRESP_ERROR =>
                  vm.err := '1'; vm.state := pfrdy;
                when others =>
                  if lw = '1' then
                    vm.state := pfrdy;
                  end if;
                  vm.rbaddr := baddrinc(MMAXDW, rm.rbaddr, rm.hsize);
--                  if rm.addrlock = '0' then
--                    vm.haddr := haddr;
--                  end if;
              end case;
            end if;
            if (((htrans(1) and rm.bg) = '1') and
                ((rm.ba = '0') or (ahbmi.hresp = HRESP_OKAY))) then
              vm.haddr := haddr;
            end if;
          end if;
          if rm.addrlock = '1' then hbusreq := '1'; else hbusreq := not ((lw or lwx) and rm.bg); end if;
          if (rm.ba and not rm.bg and ahbmi.hready) = '1' then vm.nseq := '1'; end if;
          -- if (htrans(1) and hbusreq and not ahbmi.hgrant(hmindex)) = '1' then vm.nseq := '1'; end if;
        end if;
        
      when pfrdy =>
        if (pfen = 1) then
          if (s2m.state /= pfsplit) or (s2m.race = '1') then
            vm.state := midle;
          end if;
        end if;
        
      when addr0 =>
        if (not rm.hmastlock or rm.bl) = '1' then
          htrans := HTRANS_NONSEQ;
        end if;
        if rdcomb = 2 and SMAXDW > MMAXDW and conv_integer(rm.rdcnt) /= 1 then
          hburst := HBURST_INCR;
          hbusreq := '1';
        end if;
        if rm.resp2c = '1' then htrans := HTRANS_IDLE; end if;
        if rm.bg = '1' then
          if (ahbmi.hready and htrans(1)) = '1' then
            vm.state := data0;
            if allbrst /= 0 then vm.bsycnt := "0001"; end if;
            if rdcomb = 2 and SMAXDW > MMAXDW and conv_integer(rm.rdcnt) /= 1 then
              htrans := HTRANS_NONSEQ;
            end if;
          end if;
          vm.nbsy := linc(rm.hburst, rm.haddr(9 downto 0), rm.hsize);
        else
          if (slv = 0) or (lcki.slck = '0') then
            hbusreq := '1';
          end if;
        end if;
        if (slv = 1) and (lcki.slck = '1') then
          vm.state := brel;
          htrans := HTRANS_IDLE;
        end if;
        -- Detect locked access in both directions
        if DBLLCK and slv = 1 and (rm.hmastlock and lcki.mlck) = '1'  then
          htrans := HTRANS_IDLE;
          vm.state := brel;
          vm.err := '1';
        end if;
        if rm.hburst /= "000" then hbusreq := '1'; end if;
        
      when data0 =>
        haddr := addrinc(rm);
        if rm.hburst /= "000" then hbusreq := '1'; end if;
        if rm.bg = '0' then vm.nseq := '1'; end if;
        if rdcomb /= 2 or SMAXDW <= MMAXDW then
          if (burst and rm.bg and not rm.nseq) = '1' then htrans := HTRANS_BUSY; end if;
        end if;
        if rdcomb = 2 and SMAXDW > MMAXDW then
          vm.nbsy := linc(rm.hburst, rm.haddr(9 downto 0), rm.hsize);
          if (burst and rm.bg and not rm.nseq) = '1' and vm.nbsy = '0' then 
            htrans := HTRANS_BUSY;
          end if;
          if conv_integer(rm.rdcnt) /= 1 then
            if (burst and rm.bg and not rm.nseq) = '1' then
              htrans := HTRANS_SEQ;
            else
              htrans := HTRANS_NONSEQ;
            end if;
            hburst := HBURST_INCR;
            if conv_integer(rm.rdcnt) > 2 then
              hbusreq := '1';
            end if;
--            if (slv = 1) and (lcki.slck = '1') then vm.state := brel; end if;
          end if;
        end if;
        if (ahbmi.hready) = '1' then
          if rm.ba = '1' and ahbmi.hresp(1) = '0' then  -- OKAY, ERROR  
            if rm.bg = '0' then vm.state := addr0; end if;  -- early burst termination
            if rdcomb /= 0 and SMAXDW > MMAXDW then
              hrdata := ahbreaddata(ahbmi.hrdata, rm.haddr(4 downto 2),
                  conv_std_logic_vector(log2(MMAXDW/8), 3))(MMAXDW-1 downto 0);
              vm.rdcnt := rm.rdcnt - 1;
              for i in 0 to SMAXDW/MMAXDW-1 loop
                if rm.rdw(i) = '1' then
                  vm.hdata(SMAXDW-1-i*MMAXDW downto SMAXDW-MMAXDW-i*MMAXDW) := hrdata;
                end if;
              end loop;
              
              if (orv(vm.rdcnt) = '0') or (ahbmi.hresp(0) = '1') then        
                vm.state := wreq; -- All data read or ERROR                
              elsif rdcomb /= 2 then
                vm.state := addr0;
              end if;
              updrdw(s2m.hsize, rm.rdw, vm.rdw);
            else
              vm.hdata(SMAXDW-1 downto 0) :=
                ahbreaddata(ahbmi.hrdata, rm.haddr(4 downto 2),
                            conv_std_logic_vector(log2(SMAXDW/8), 3))(SMAXDW-1 downto 0);
              vm.state := wreq;
            end if;
            vm.haddr := haddr;
            vm.hresp := ahbmi.hresp;
          elsif rm.ba = '1' and ahbmi.hresp(1) = '1' then   -- SPLIT, RETRY
            vm.state := addr0;
          end if;
        end if;
        if rm.resp2c = '1' then htrans := HTRANS_IDLE; end if;
        if DBLLCK and slv = 1 and (rm.hmastlock and lcki.mlck) = '1'  then
          htrans := HTRANS_IDLE;
          vm.state := brel;
          vm.err := '1';
        end if;
        
      when wreq =>
        if rm.hburst /= "000" then hbusreq := '1'; end if;
        case s2m.state is
          when saddr => vm.state := maddr; mload := '1';
          when split2 =>
            if s2m.race = '1' and (pipe = 0 or (rm.sp2tog xor s2m.sp2tog) = '1') then
              -- Don't lock the wrong access
              if (s2m.hmastlock xor rm.hmastlock) = '1' then vm.state := midle;
              else vm.state := addr0; vm.sp2tog := s2m.sp2tog; end if;
            end if;
          when ret =>
            -- Prevent race condition where vs.race is not zeroed in split2 because
            -- the transition wreq -> addr0 -> data0 -> wreq happens too fast.
            -- The expression contains rm.hburst in order to allow transitions
            -- from ret to saddr
           if CHECKRACE2 and rm.hburst = "000" then vm.state := midle; end if;
          when sidle => vm.state := midle;
          when pfsplit  => vm.state := midle;
          when bfill | bflush  => vm.state := midle;
          when others =>
        end case;
        if (burst and rm.bg and not rm.nseq and (s2m.hmastlock xnor rm.hmastlock)) = '1' then
          htrans := HTRANS_BUSY;
        end if;
        if rm.bg = '0' then vm.nseq := '1'; end if;
        if (rm.resp2c = '1') or (rm.hresp /= HRESP_OKAY) or rm.bg = '0' then
          htrans := HTRANS_IDLE;
        end if;
        if (slv = 1) and (lcki.slck = '1') then
          if vm.state /= midle then     -- Collision may just have been resolved
            vm.state := brel;
            vm.mwreq := '1';                -- Signal that core has been in wreq
          end if;
        end if;
        
      when maddr =>
        htrans := rm.htrans;
        if rm.resp2c = '1' then htrans := HTRANS_IDLE; end if;
        hbusreq := '1';
        if rm.bg = '0' then vm.nseq := '1'; end if;
        if (not rm.bg  or rm.nseq) = '1' then htrans := HTRANS_NONSEQ; end if;
        if rm.bg = '1' then
          if ahbmi.hready = '1' then
            vm.state := mdata;
            vm.nseq := '0';
            if allbrst /= 0 then vm.bsycnt := rm.bsycnt + 1; end if;
          end if;
          vm.nbsy := linc(rm.hburst, rm.haddr(9 downto 0), rm.hsize);
        --else
        --  if (slv = 1) and (lcki.blck = '1') then
        --    vm.state := brel;
        --  end if;
        end if;
        if (slv = 1) and (lcki.slck = '1') then
          htrans := HTRANS_IDLE;
          vm.state := brel;
        end if;
        
      when mdata =>
        haddr := addrinc(rm);
        hbusreq := '1';
        if (burst and rm.bg and not rm.nseq) = '1' then htrans := HTRANS_BUSY; end if;
        if rm.bg = '0' then vm.nseq := '1'; end if;
        if rm.resp2c = '1' then htrans := HTRANS_IDLE; end if;
        if ahbmi.hready = '1' then
          if ahbmi.hresp(1) = '0' then -- OKAY, ERROR
            if rdcomb /= 0 and SMAXDW > MMAXDW then
              hrdata := ahbreaddata(ahbmi.hrdata, rm.haddr(4 downto 2),
                  conv_std_logic_vector(log2(MMAXDW/8), 3))(MMAXDW-1 downto 0);
              vm.rdcnt := rm.rdcnt - 1;
              for i in 0 to SMAXDW/MMAXDW-1 loop
                if rm.rdw(i) = '1' then
                  vm.hdata(SMAXDW-1-i*MMAXDW downto SMAXDW-MMAXDW-i*MMAXDW) := hrdata;
                end if;
              end loop;
              if (orv(vm.rdcnt) = '0') or (ahbmi.hresp(0) = '1') then
                vm.state := mdata2; -- All data read or ERROR
              else
                -- Jump back to maddr, we can likely save a couple of cycles
                -- here if we stay in mdata, as we do in state data0 for read
                -- combining. However, bursts to non-prefetchable areas are not
                -- expected to be very common in GRLIB and we select to save
                -- some area over performance in this case.
                vm.state := maddr;
              end if;
              updrdw(s2m.hsize, rm.rdw, vm.rdw);
            else
              vm.hdata(SMAXDW-1 downto 0) :=
                ahbreaddata(ahbmi.hrdata, rm.haddr(4 downto 2),
                            conv_std_logic_vector(log2(SMAXDW/8), 3))(SMAXDW-1 downto 0);
              vm.state := mdata2;
            end if;
            vm.hresp := ahbmi.hresp;
            vm.haddr := haddr;
          else   -- SPLIT, RETRY
            vm.state := maddr; vm.htrans(0) := '0';
          end if;
        end if;
        
      when mdata2 =>
        hbusreq := '1';
        if (burst and rm.bg and not rm.nseq) = '1' then htrans := HTRANS_BUSY; end if;
        if rm.bg = '0' then vm.nseq := '1'; end if;
        if rm.resp2c = '1' or rm.hresp = HRESP_ERROR then htrans := HTRANS_IDLE; end if;
        case s2m.state is
          when saddr =>
            if CHECKRACE1 and pipe = 0 then vm.state := maddr; mload := '1'; end if;
          when sdata => vm.state := mdata2x;
          when others => vm.state := midle; mload := '1';
        end case;
        
      when mdata2x =>
          hbusreq := '1';
          if (burst and rm.bg and not rm.nseq) = '1' then htrans := HTRANS_BUSY; end if;
          if rm.bg = '0' then vm.nseq := '1'; end if;
          if rm.resp2c = '1' or rm.hresp = HRESP_ERROR then htrans := HTRANS_IDLE; end if;
          if s2m.state = saddr then vm.state := maddr; mload := '1';
          elsif s2m.state /= sdata then vm.state := midle; end if;
          
      when wrburst =>
        if rm.hburst = "000" then
          if rm.bg = '0' then hbusreq := '1'; end if;
        else
          hbusreq := '1';
        end if;

        if rm.ldp = '0' then
          if rm.nseq = '1' then
            htrans := HTRANS_NONSEQ;
          else
            if (wrcomb = 0) or (rm.hburst /= HBURST_SINGLE) then
              htrans := HTRANS_SEQ;
            else
              htrans := HTRANS_NONSEQ;
            end if;
          end if;
          if rm.addrlock = '0' then haddr := addrinc(rm);  end if;
        end if;
        if rm.resp2c = '1' then htrans := HTRANS_IDLE; end if;
        if (rm.hmastlock and not (rm.bl or rm.ba)) = '1' then htrans := HTRANS_IDLE; end if;
        
        -- Detect locked access in both directions
        if DBLLCK and slv = 1 and (rm.hmastlock and lcki.mlck) = '1'  then
          htrans := HTRANS_IDLE;
          vm.state := wrburst2;
          vm.err := '1';
        end if;
        
        if ((((htrans(1) and rm.bg) and ahbmi.hready) = '1') and
            ((rm.ba = '0') or (ahbmi.hresp = HRESP_OKAY))) then
          vm.haddr := haddr;
          vm.wbaddr := baddrinc(MMAXDW, rm.wbaddr, rm.hsize);
          vm.nwords := winc(MMAXDW, rm.nwords, rm.hsize);
        end if;

        -- Cannot compare buffer addresses when using combining
        if (((rm.bg and ahbmi.hready and htrans(1)) = '1') and
            (vm.nwords = s2m.nwords)) then
          vm.ldp := '1';
          -- HLOCK should be deasserted in last address phase of burst
          vm.hmastlock := '0'; hlock := '0';
        end if;

        if rm.ldp = '1' then
          if (rm.ba = '1') and (ahbmi.hready = '1') and (ahbmi.hresp(1) = '0') then --OKAY, ERROR
            vm.state := wrburst2;
          end if;
          hbusreq := '0';
        end if;

        if (ahbmi.hready = '1') then vm.hdata(MMAXDW-1 downto 0) := wbo; end if;

        if (rm.bg and ahbmi.hready) = '1' and htrans /= HTRANS_IDLE then
          vm.nseq := '0'; vm.addrlock := '0';
        end if;

        -- Early burst termination
        if (rm.ba and not rm.bg and ahbmi.hready) = '1' then vm.nseq := '1'; end if;
        
        if (rm.ba and ahbmi.hready and ahbmi.hresp(1)) = '1' then
          vm.wbaddr := baddrdec(MMAXDW, rm.wbaddr, rm.hsize);
          vm.nwords := wdec(MMAXDW, rm.nwords, rm.hsize);
          vm.state := wrburst; vm.nseq := '1';
          vm.ldp := '0'; vm.addrlock := '1';
        end if;

        if (rm.resp2c = '1') and (ahbmi.hresp = HRESP_ERROR) then
          vm.state := wrburst2;
        end if;

      when wrburst2 =>
        vm.wbaddr := (others => '0'); vm.nwords := (others => '0');
        if (s2m.state /= bflush) or (s2m.race = '1') then
          vm.state := midle;
          if DBLLCK then vm.err := '0'; end if;
        end if;
        
      when brel =>
        -- The check below is safe since we only get here with slv = 1, and
        -- this means that the frequenecy of the master interface is higher or
        -- equal to the frequency on the slave interface.
        if slv = 1 then
          if s2m.state = sidle then
            vm.state := midle;
            if slv = 1 then  vm.mwreq := '0'; end if;
            if DBLLCK then vm.err := '0'; end if;
          end if;
        else
          null;
        end if;
      when others =>

    end case;

    if ((s2m.state = split2) or
        ((s2m.state = saddr) and (mload = '1')) or
        ((s2m.state = sidle and rm.state = midle)) or
        ((s2m.state = bflush) and (rm.state /= wrburst))  or
        ((s2m.state = pfsplit) and (rm.state /= pfget))) then
      vm.hmastlock := s2m.hmastlock;
      vm.hprot := s2m.hprot; 
      vm.hwrite := s2m.hwrite;
      vm.htrans := s2m.htrans;
      -- The address is increased in data0 when performing read
      -- combining, we do not want it to be overwritten with the original
      -- address as this will lead to an address change while the master drives
      -- HTRANS_BUSY.
      if not ((rm.state = addr0 or rm.state = data0) or
              (rm.state = wreq and vm.state = wreq)) then
        vm.haddr := s2m.haddr;
      end if;

      combine := comb_addr(s2m.haddr(31 downto 28));
      wrap := wrap_burst(s2m.hburst);
      fixed := fixed_burst(s2m.hburst);
      if (rdcomb = 0 and wrcomb = 0) then
        -- No read or write combining
        vm.hsize := s2m.hsize;
        vm.hburst := s2m.hburst;
      else
        -- Read and/or write combining, need to differentiate between read and
        -- write accesses.
        if s2m.hwrite = '0' then
          -- Read
          if rdcomb = 0 then
            -- No read combining
            vm.hsize := s2m.hsize;
            vm.hburst := s2m.hburst;
          elsif wrap = '1' then
            -- Wrapping burst, do not perform read combining
            -- (with relatively little effort we could combine if the wrapping
            -- burst is aligned in a good way, but that has a cost in logic).
            vm.hsize := s2m.hsize;
            vm.hburst := s2m.hburst;
            if SMAXDW > MMAXDW then
              if (rm.state /= data0) and (rm.state /= addr0) then
                vm.rdcnt := conv_std_logic_vector(1, rm.rdcnt'length);
                vm.rdw := (others => '1');
              end if;
            end if;
          elsif s2m.state = pfsplit then    -- Prefetch
            if s2m.hsize = HSIZE_HWORD or s2m.hsize = HSIZE_BYTE then
              vm.hsize := s2m.hsize;
              if allbrst = 0 then vm.hburst := HBURST_INCR;
              else vm.hburst := s2m.hburst; end if;
            else
              if allbrst = 0 then
                -- Always use incrementing burst of unspecified length for prefetch
                vm.hsize := conv_std_logic_vector(log2(MMAXDW/8), 3);
                -- Adjust address used in prefetch
                if MMAXDW > 128 then vm.haddr(4) := '0'; end if;
                if MMAXDW > 64 then vm.haddr(3) := '0'; end if;
                if MMAXDW > 32 then vm.haddr(2) := '0'; end if;
                vm.hburst := HBURST_INCR;
              else
                -- Support fixed length and wrapping bursts.
                -- If the master interface supports the incoming access size
                -- then we propagate the access through. Otherwise we use an
                -- incrementing burst
                if ((wrap or fixed) = '1' and
                    s2m.hsize <= conv_std_logic_vector(log2(MMAXDW/8), 3)) then
                  vm.hburst := s2m.hburst;
                  vm.hsize := s2m.hsize;
                else
                  vm.hsize := conv_std_logic_vector(log2(MMAXDW/8), 3);
                  if MMAXDW > 128 then vm.haddr(4) := '0'; end if;
                  if MMAXDW > 64 then vm.haddr(3) := '0'; end if;
                  if MMAXDW > 32 then vm.haddr(2) := '0'; end if;
                  vm.hburst := HBURST_INCR;
                end if;
              end if;
            end if;
          else                          -- No prefetch          
            vm.hsize := s2m.hsize;
            if SMAXDW > MMAXDW then
              -- May need to perform multiple accesses
              -- Preventing read combining, or rather read splitting, one large
              -- access into several smaller accesses here seems unnecessary.
              -- Most systems would probably be well served by having combmask
              -- only preventing combinations of write bursts into large accesses.
              -- But we prevent splits of reads here, in the name of consistency.
              if combine = '1' then
                if s2m.hsize > conv_std_logic_vector(log2(MMAXDW/8), 3) then
                  vm.hsize := conv_std_logic_vector(log2(MMAXDW/8), 3);
                end if;
              end if;
              -- Determine number of accesses required
              if (rm.state /= data0) and (rm.state /= addr0) then
                vm.rdcnt := conv_std_logic_vector(1, rm.rdcnt'length);
                if combine = '1' then
                  if SMAXDW > 128 and s2m.hsize = HSIZE_8WORD then
                    vm.rdcnt := conv_std_logic_vector(256/MMAXDW, rm.rdcnt'length);
                  elsif SMAXDW > 64 and MMAXDW < 128 and s2m.hsize = HSIZE_4WORD then
                    vm.rdcnt := conv_std_logic_vector(128/MMAXDW, rm.rdcnt'length);
                  elsif MMAXDW < 64 and s2m.hsize = HSIZE_DWORD then
                    vm.rdcnt := conv_std_logic_vector(64/MMAXDW, rm.rdcnt'length);
                  end if;
                end if;
                vm.rdw := (others => '1');
              end if;
              if (allbrst /= 0 and rdcomb /= 0 and combine = '1' and
                  s2m.hsize > conv_std_logic_vector(log2(MMAXDW/8), 3) and
                  s2m.hburst /= HBURST_SINGLE) then
                vm.hburst := HBURST_INCR;
              else
                vm.hburst := s2m.hburst;
              end if;
            else
              vm.hburst := s2m.hburst;
            end if;
          end if;
        else
          -- Write
          if wrcomb = 0 or combine = '0' or wrap = '1' then
            -- No write combining
            -- Write combining could be enabled for wrapping bursts, with some
            -- trickery for short bursts, but for now we do not support
            -- combining for wrapping bursts.
            vm.hsize := s2m.hsize;
            vm.hburst := s2m.hburst;
          else
            writecombine(s2m.nwords, s2m.haddr(4 downto 0), s2m.hburst,
                         s2m.hsize, vm.hsize, vm.hburst);
          end if;
        end if;
      end if;
    end if;

    if ahbmi.hready = '1' then
      vm.bg := ahbmi.hgrant(hmindex);
      if (rm.bg and htrans(1)) = '1' then vm.ba := '1'; else vm.ba := '0'; end if;
      if (((not htrans(1) and ahbmi.hgrant(hmindex)) or rm.bl) and hlock) = '1' then vm.bl := '1';
      else vm.bl := '0'; end if;
    end if;

    if (rm.state = wrburst) or (rm.state = wrburst2) then hwrite := rm.hwrite; else hwrite := '0'; end if;

    if (vm.state = wrburst) then ren := '1'; end if;

    if ifctrlen /= 0 then
      if ifctrl.mstifen = '0' then
        -- Master interface disabled
        vm.state := midle;
        vm.hmastlock := '0';
        vm.hprot  := (others => '0');
        vm.htrans := HTRANS_IDLE;
        vm.haddr  := (others => '0');
        vm.hsize  := HSIZE_WORD;
        vm.hburst := HBURST_SINGLE;
      end if;
    end if;

    if slv = 1 and (rm.state /= wreq) and (rm.state /= brel) then vm.mwreq := '0';  end if;
    
    if (not RESET_ALL) and (rstn = '0') then
      vm.ba := MRES.ba; vm.bg := MRES.bg; vm.state := MRES.state;
      vm.hmastlock := MRES.hmastlock;
      if DBLLCK then vm.err := MRES.err; end if;
      vm.wbaddr := MRES.wbaddr;
      vm.nwords := MRES.nwords;
      vm.nbsy := MRES.nbsy;
      vm.rbaddr := MRES.rbaddr;
      vm.sp2tog := MRES.sp2tog;
    end if;

    if pipe = 0 then vm.sp2tog := '0'; end if;
    
    -- bsycnt only used for bursts that are not incremental
    if allbrst = 0 then vm.bsycnt := (others => '0'); end if;

    -- rdcnt used for keeping track of large access split into smaller
    if rdcomb = 0 or SMAXDW <= MMAXDW then
      vm.rdcnt := (others => '0'); vm.rdw := (others => '0');
    end if;

    -- mwreq is only used for slv = 1
    if slv = 0 then vm.mwreq := '0'; end if;

    if scantest = 1 and (ahbmi.scanen and ahbmi.testen) = '1' then
      -- Read buffer write enable
      rb_wr <= (others => '0');
      -- Write buffer read enable
      wb_ren <= (others => '0');
    else
      -- Read buffer write enable decoding
      for i in rb_wr'range loop
        if MMAXDW > 128 and rm.hsize = HSIZE_8WORD then
          rb_wr(i) <= wr;
        elsif MMAXDW > 64 and rm.hsize = HSIZE_4WORD then
          if (maxdw = 128 or conv_integer(rm.rbaddr(2)) = i/4) then
            rb_wr(i) <= wr;
          end if;
        elsif MMAXDW > 32 and rm.hsize = HSIZE_DWORD then
          if (maxdw = 64 or conv_integer(rm.rbaddr((1+maxdw/256) downto 1)) = i/2) then
            rb_wr(i) <= wr;
          end if;
        elsif ((maxdw = 32) or
               (conv_integer(rm.rbaddr(log2x(maxdw/32)-1 downto 0)) =
                (i mod (maxdw/32)))) then
          rb_wr(i) <= wr;
        end if;
      end loop;  -- i

      -- Write buffer read enable decoding
      for i in wb_ren'range loop
        wb_ren(i) <= ren;
      end loop;  -- i
    end if;
    wb_addr <= vm.wbaddr;

    mstcfg := (others => (others => '0'));
    mstcfg(0) := ahb_device_reg(VENDOR_GAISLER, GAISLER_AHB2AHB, 0, AHB2AHB_VER, 0);
    mstcfg(1)(8) := conv_std_logic(UP);
    mstcfg(1)(7 downto 4) := conv_std_logic_vector(ffact, 4);
    mstcfg(1)(3 downto 2) := conv_std_logic_vector(mbus, 2);
    mstcfg(1)(1 downto 0) := conv_std_logic_vector(sbus, 2);

    if htrans = "00" then haddr(1 downto 0) := "00"; end if;
    ahbmo.hbusreq <= hbusreq;
    ahbmo.hlock   <= hlock;
    ahbmo.htrans  <= htrans;
    ahbmo.haddr   <= haddr;
    ahbmo.hwrite  <= hwrite;
    ahbmo.hsize   <= rm.hsize;
    ahbmo.hburst  <= hburst;
    ahbmo.hprot   <= rm.hprot;
    ahbmo.hwdata  <= ahbdrivedata(rm.hdata(MMAXDW-1 downto 0));
    if ifctrlen = 0 or ifctrl.mstifen = '1' then
      if DOWN then ahbmo.hirq <= lsb_hirqo; else ahbmo.hirq <= hsb_hirqo; end if;
    else
      ahbmo.hirq <= (others => '0');
    end if;
    ahbmo.hconfig <= mstcfg;
    ahbmo.hindex  <= hmindex;

    rmin <= vm;

  end process;

  -----------------------------------------------------------------------------
  -- Interrupt forwarding
  -----------------------------------------------------------------------------
  irqsgen : if (irqsync /= 0) generate
    irqsynclogic : block
      type irqhsb_sync_type is record
        irqs : std_logic_vector(IRQH downto IRQL);
        irq  : std_logic_vector(IRQH downto IRQL);
        en2  : std_ulogic;
      end record;
  
      type irqlsb_sync_type is record
        irq  : std_logic_vector(IRQH downto IRQL);
        en   : std_ulogic;
      end record;

      constant irqhsb_sync_none : irqhsb_sync_type :=
        ((others => '0'), (others => '0'), '0');

      constant irqlsb_sync_none : irqlsb_sync_type :=
        ((others => '0'), '0');
      
      signal rih, rihin : irqhsb_sync_type;
      signal ril, rilin : irqlsb_sync_type;
          
    begin
      xirqsync : process(ahbsi, ahbmi, rih, ril, rstn)
        variable hsb_hirqi, lsb_hirqi, env : std_logic_vector(IRQH downto IRQL);
        variable vih : irqhsb_sync_type;
        variable vil : irqlsb_sync_type;
        variable irqoh, irqol : std_logic_vector(NAHBIRQ-1 downto 0);
      begin

        irqoh := (others => '0'); irqol := (others => '0');
        vil.en := not ril.en; vih.en2 := ril.en;
        for i in IRQL to IRQH loop env(i) := ril.en xor rih.en2; end loop;

        if DOWN then
          hsb_hirqi := ahbsi.hirq(IRQH downto IRQL);
          lsb_hirqi := ahbmi.hirq(IRQH downto IRQL);
        else
          hsb_hirqi := ahbmi.hirq(IRQH downto IRQL);
          lsb_hirqi := ahbsi.hirq(IRQH downto IRQL);
        end if;

        -- down synchronization
        vih.irqs := ((hsb_hirqi and not rih.irq) or rih.irqs) and not ril.irq;
        vil.irq  := rih.irqs and not ril.irq;

        -- up synchronization
        vih.irq := (lsb_hirqi and not ril.irq) and env;

        if rstn = '0' then
          vih.irqs := (others => '0');
          vil.irq := (others => '0');
          vih.irq := (others => '0');
          vil.en := '0'; vih.en2 := '0';
        end if;

        irqoh(IRQH downto IRQL) := rih.irq; irqol(IRQH downto IRQL) := ril.irq;
        hsb_hirqo <= irqoh;
        lsb_hirqo <= irqol;

        rihin <= vih; rilin <= vil;
      end process;

      -----------------------------------------------------------------------------
      -- Interrupt forwarding registers
      -----------------------------------------------------------------------------
      irqgen0 : if ((irqsync /= 0) and DOWN) generate
        irqreg0 : process(hclks)
        begin
          if rising_edge(hclks) then
            rih <= rihin;
            if RESET_ALL and (rstn = '0') then rih <= irqhsb_sync_none; end if;
          end if;
        end process;
        irqreg1 : process(hclkm)
        begin
          if rising_edge(hclkm) then
            ril <= rilin;
            if RESET_ALL and (rstn = '0') then ril <= irqlsb_sync_none; end if;
          end if;
        end process;
      end generate;

      irqgen1 : if ((irqsync /= 0) and UP) generate
        irqreg0 : process(hclks)
        begin
          if rising_edge(hclks) then
            ril <= rilin;
            if RESET_ALL and (rstn = '0') then ril <= irqlsb_sync_none; end if;
          end if;
        end process;

        irqreg1 : process(hclkm)
        begin
          if rising_edge(hclkm) then
            rih <= rihin;
            if RESET_ALL and (rstn = '0') then rih <= irqhsb_sync_none; end if;
          end if;
        end process;
      end generate;
    end block irqsynclogic;
  end generate;

  noirqsync : if (irqsync = 0) generate
    hsb_hirqo  <= (others => '0');
    lsb_hirqo  <= (others => '0');
  end generate;

  -----------------------------------------------------------------------------
  -- Buffers
  -----------------------------------------------------------------------------
  -- All cases require muxing since we work with word sized buffers and allow
  -- byte and half-words bursts. If byte and half-word burst support is
  -- dropped, the need to mux will decrease - in particular for CORE_ACDM = 1.
  
  -- Read buffer (when data prefetch is enabled)
  rbgen : if (pfen = 1) generate
    hrdatax <= dupvec(maxdw, MMAXDW,
                     ahbreaddata(ahbmi.hrdata, rm.haddr(4 downto 2),  
                                 conv_std_logic_vector(log2(MMAXDW/8), 3)));
    rbnoacdm: if CORE_ACDM = 0 generate
      hrdata <= hrdatax;
    end generate rbnoacdm;
    rbacdm: if CORE_ACDM /= 0 generate
      hrdata <= selectdata(maxdw, rm.haddr(4 downto 2), rm.hsize, hrdatax);
    end generate rbacdm;
    
    rb_raddr <= rb_addr(rbufbits-1 downto log2(maxdw/32));
    rb_waddr <= rm.rbaddr(rbufbits-1 downto log2(maxdw/32));
    
    -- Instantiates 32-bit wide buffers to get a memory word width of
    -- max(SMAXDW,MMAXDW). The total amount of instantiated memory
    -- will be rburst, or max(rburst, iburst) if irbrsten = 1, 32-bit words.
    slvmax: if SMAXDW > MMAXDW generate
      readbuffers: for i in 0 to SMAXDW/32-1 generate
        readbuf : syncram_2p
          generic map (
            tech   => memtech,
            abits  => rbufbits-log2(maxdw/32),
            dbits  => 32,
            sepclk => rwbuf_sepclk,
            wrfst  => 0)
          port map (
            rclk => hclks,
            renable => rb_ren(i),
            raddress => rb_raddr,
            dataout => rb_do(SMAXDW-1-32*i downto SMAXDW-32-32*i),
            wclk => hclkm,
            write => rb_wr(i),
            waddress => rb_waddr,
            datain => hrdata(SMAXDW-1-32*i downto SMAXDW-32-32*i));
      end generate readbuffers;    
    end generate slvmax;

    mstmax: if SMAXDW <= MMAXDW generate
      readbuffers: for i in 0 to MMAXDW/32-1 generate
        readbuf : syncram_2p
          generic map (
            tech   => memtech,
            abits  => rbufbits-log2(maxdw/32),
            dbits  => 32,
            sepclk => rwbuf_sepclk,
            wrfst  => 0)
          port map (
            rclk => hclks,
            renable => rb_ren(i),
            raddress => rb_raddr,
            dataout => rb_do(MMAXDW-1-32*i downto MMAXDW-32-32*i),
            wclk => hclkm,
            write => rb_wr(i),
            waddress => rb_waddr,
            datain => hrdata(MMAXDW-1-32*i downto MMAXDW-32-32*i));
      end generate readbuffers;
    end generate mstmax;

    rseladdrgen1: if (ibrsten /= 0 and ibbits >= 3) or (rbbits >= 3) generate
      rseladdr <= rs.rbaddr(2 downto 0);
    end generate rseladdrgen1;
    rseladdrgen2: if (ibrsten = 0 or ibbits < 3) and (rbbits < 3) generate
      rseladdr(2 downto rbufbits) <= (others => '0');
      rseladdr(rbufbits-1 downto 0) <= rs.rbaddr;
    end generate rseladdrgen2;
    rbo <= selectdata(SMAXDW, rseladdr, rs.pfhsize, rb_do); 
  end generate rbgen;

  -- Write buffer
  hwdatax <= ahbreaddata(ahbsi.hwdata, rs.wbhaddr,
                        conv_std_logic_vector(log2(maxdw/8), 3));
  wbnoacdm: if CORE_ACDM = 0 generate
    hwdata <= hwdatax;
  end generate wbnoacdm;
  wbacdm: if CORE_ACDM /= 0 generate
    hwdata <= selectdata(maxdw, rs.wbhaddr(4 downto 2), rs.hsize, hwdatax);
  end generate wbacdm;
    
  wb_raddr <= wb_addr(wbbits-1 downto log2(maxdw/32));
  wb_waddr <= rs.wbaddr(wbbits-1 downto log2(maxdw/32));
    
  slvmax: if SMAXDW > MMAXDW generate
    writebuffers: for i in 0 to SMAXDW/32-1 generate
      writebuf : syncram_2p
        generic map (
          tech   => memtech,
          abits  => wbbits-log2(maxdw/32),
          dbits  => 32,
          sepclk => rwbuf_sepclk,
          wrfst  => 0)
        port map (
          rclk => hclkm,
          renable => wb_ren(i),
          raddress => wb_raddr,
          dataout => wb_do(SMAXDW-1-32*i downto SMAXDW-32-32*i),
          wclk => hclks,
          write => wb_wr(i),
          waddress => wb_waddr,
          datain => hwdata(SMAXDW-1-32*i downto SMAXDW-32-32*i));
    end generate writebuffers;
  end generate slvmax;
    
  mstmax: if SMAXDW <= MMAXDW generate
    writebuffers: for i in 0 to MMAXDW/32-1 generate
      writebuf : syncram_2p
        generic map (
          tech   => memtech,
          abits  => wbbits-log2(maxdw/32),
          dbits  => 32,
          sepclk => rwbuf_sepclk,
          wrfst  => 0)
        port map (
          rclk => hclkm,
          renable => wb_ren(i),
          raddress => wb_raddr,
          dataout => wb_do(MMAXDW-1-32*i downto MMAXDW-32-32*i),
          wclk => hclks,
          write => wb_wr(i),
          waddress => wb_waddr,
          datain => hwdata(MMAXDW-1-32*i downto MMAXDW-32-32*i));
    end generate writebuffers;      
  end generate mstmax;

  wseladdrgen1: if (wbbits >= 3) generate
    wseladdr <= rm.wbaddr(2 downto 0);
  end generate wseladdrgen1;
  wseladdrgen2: if (wbbits < 3) generate
    wseladdr(2 downto wbbits) <= (others => '0');
    wseladdr(wbbits-1 downto 0) <= rm.wbaddr;
  end generate wseladdrgen2;
  wbo <= selectdata(MMAXDW, wseladdr, rm.hsize, wb_do);

  -----------------------------------------------------------------------------
  -- Master side registers
  -----------------------------------------------------------------------------
  mreg : process(hclkm)
  begin
    if rising_edge(hclkm) then
      rm <= rmin;
      if RESET_ALL and rstn = '0' then
        rm <= MRES;
      end if;
    end if;
  end process;

  -----------------------------------------------------------------------------
  -- Signals master <-> slave
  -----------------------------------------------------------------------------
  -- Registers used by master interface clocked by slave side clock:
  --  rs.state     
  --  rs.hmastlock 
  --  rs.ardy      
  --  rs.sv.nofetch
  --  rs.rbaddr    
  --  rs.race      
  --  rs.nwords    
  --  rs.haddr     
  --  rs.hsize     
  --  rs.hprot     
  --  rs.hwrite    
  --  rs.htrans    
  --  rs.hburst
  --  rs.sp2tog
  --
  -- Registers used by slave interface clock by master side clock
  --  rm.state     
  --  rm.mwreq     
  --  rm.hdata     
  --  rm.hresp     
  --  rm.err       
  --  rm.rbaddr    
  --
  -- Most of the master<->slave connections are register to register, possibly
  -- with a multiplexer before the destination where the control signals are
  -- clocked by the receiving side's clock.
  --
  -- Some of the registers have paths that go out on the receiveing side's AMBA
  -- interface. This can create long paths when the master/slave sides have
  -- been placed far apart in the floorplan or when the frequency factor is
  -- high. The paths are:
  --
  -- master to slave:
  --   m2s.state
  --     in split2 and bflush this path affects hsplit via the unsplit variable
  --
  --   m2s.mwreq
  --     in split2 and bflush this path affects hsplit via the unsplit variable
  --
  -- slave to master:
  --   s2m.hmastlock
  --     affects htrans, and through this the two MSb of haddr.
  --     affects read enable to write buffer
  --    
  --   s2m.state, s2m.race
  --      read enable to write buffer
  --
  --
  -- pipe = 0: No pipeline registers
  -- pipe = 1: Pipeline regs on all signals between master <-> slave side
  -- pipe = 2: Pipeline regs on all signals slave -> master, no regs on m -> s
  -- pipe = 3: Pipeline regs on all signals master -> slave, no regs on s -> m
  --
  -- pipe = 128: Pipeline regs on subset on all signals master <-> slave
  
  -- Interface between master and slave sides of bridge
  iconndirects2m : if pipe = 0 or pipe = 3 generate
    -- Direct connection
    s2m <= (state     => rs.state,
            hmastlock => rs.hmastlock,
            ardy      => rs.ardy,
            nofetch   => rs.sv.nofetch,
            rbaddr    => rs.rbaddr,
            race      => rs.race,
            nwords    => rs.nwords,
            haddr     => rs.haddr,
            hsize     => rs.hsize,
            hprot     => rs.hprot,
            hwrite    => rs.hwrite,
            htrans    => rs.htrans,
            hburst    => rs.hburst,
            sp2tog    => rs.sp2tog);
  end generate iconndirects2m;
  iconndirectm2s : if pipe = 0 or pipe = 2 generate    
    m2s <= (state     => rm.state,
            mwreq     => rm.mwreq,
            hdata     => rm.hdata(SMAXDW-1 downto 0),
            hresp     => rm.hresp,
            err       => rm.err, 
            rbaddr    => rm.rbaddr);
  end generate iconndirectm2s;
  iconnregall : if (pipe > 0) and (pipe < 128) generate
    -- Registers on all signals. Inter clock-domain signals are always register-to-register
    s2mregs : if pipe /= 3 generate
      s2mreg : process(hclkm)
      begin
        if rising_edge(hclkm) then
          s2m <= (state     => rs.state,
                  hmastlock => rs.hmastlock,
                  ardy      => rs.ardy,
                  nofetch   => rs.sv.nofetch,
                  rbaddr    => rs.rbaddr,
                  race      => rs.race,
                  nwords    => rs.nwords,
                  haddr     => rs.haddr,
                  hsize     => rs.hsize,
                  hprot     => rs.hprot,
                  hwrite    => rs.hwrite,
                  htrans    => rs.htrans,
                  hburst    => rs.hburst,
                  sp2tog    => rs.sp2tog);
          if RESET_ALL and rstn = '0' then
            s2m <= (state     => SRES.state,
                    hmastlock => SRES.hmastlock,
                    ardy      => SRES.ardy,
                    nofetch   => SRES.sv.nofetch,
                    rbaddr    => SRES.rbaddr,
                    race      => SRES.race,
                    nwords    => SRES.nwords,
                    haddr     => SRES.haddr,
                    hsize     => SRES.hsize,
                    hprot     => SRES.hprot,
                    hwrite    => SRES.hwrite,
                    htrans    => SRES.htrans,
                    hburst    => SRES.hburst,
                    sp2tog    => SRES.sp2tog);
          end if;
        end if;
      end process;
    end generate;
    m2sregs : if pipe /= 2 generate
      m2sreg : process(hclks)
      begin
        if rising_edge(hclks) then
          m2s <= (state     => rm.state,
                  mwreq     => rm.mwreq,
                  hdata     => rm.hdata(SMAXDW-1 downto 0),
                  hresp     => rm.hresp,
                  err       => rm.err, 
                  rbaddr    => rm.rbaddr);
          if RESET_ALL and rstn = '0' then
            m2s <= (state     => MRES.state,
                    mwreq     => MRES.mwreq,
                    hdata     => MRES.hdata(SMAXDW-1 downto 0),
                    hresp     => MRES.hresp,
                    err       => MRES.err, 
                    rbaddr    => MRES.rbaddr);
          end if;
        end if;
      end process;
    end generate;
  end generate iconnregall;
  iconnpartialreg : if (pipe > 127) generate
    iconnpregblock : block
      type slave_to_master_reg_type is record
        state     : slave_state_type;
        hmastlock : std_ulogic;
        race      : std_ulogic;
        sp2tog    : std_ulogic;
        haddr     : std_logic_vector(31 downto 0);
      end record;
  
      type master_to_slave_reg_type is record
        state     : master_state_type;
        mwreq     : std_ulogic;
      end record;
      
      signal s2mr : slave_to_master_reg_type;
      signal m2sr : master_to_slave_reg_type;
    begin
      s2mreg : process(hclkm)
      begin
        if rising_edge(hclkm) then
          s2mr <= (state     => rs.state,
                   hmastlock => rs.hmastlock,
                   race      => rs.race,
                   sp2tog    => rs.sp2tog,
                   haddr     => rs.haddr);
          if RESET_ALL and rstn = '0' then
            s2mr <= (state     => SRES.state,
                     hmastlock => SRES.hmastlock,
                     race      => SRES.race,
                     sp2tog    => SRES.sp2tog,
                     haddr     => SRES.haddr);
          end if;
        end if;
      end process;
      m2sreg : process(hclks)
      begin
        if rising_edge(hclks) then
          m2sr <= (state     => rm.state,
                   mwreq     => rm.mwreq);
          if RESET_ALL and rstn = '0' then
            m2sr <= (state     => MRES.state,
                     mwreq     => MRES.mwreq);
          end if;
        end if;
      end process;
      s2m <= (state     => s2mr.state,
              hmastlock => s2mr.hmastlock,
              ardy      => rs.ardy,
              nofetch   => rs.sv.nofetch,
              rbaddr    => rs.rbaddr,
              race      => s2mr.race,
              sp2tog    => s2mr.sp2tog,
              nwords    => rs.nwords,
              haddr     => rs.haddr,
              hsize     => rs.hsize,
              hprot     => rs.hprot,
              hwrite    => rs.hwrite,
              htrans    => rs.htrans,
              hburst    => rs.hburst);
      
      m2s <= (state     => m2sr.state,
              mwreq     => m2sr.mwreq,
              hdata     => rm.hdata(SMAXDW-1 downto 0),
              hresp     => rm.hresp,
              err       => rm.err, 
              rbaddr    => rm.rbaddr);
    end block iconnpregblock;
  end generate iconnpartialreg;

      
  -----------------------------------------------------------------------------
  -- Slave side registers
  -----------------------------------------------------------------------------
  sreg : process(hclks)
  begin
    if rising_edge(hclks) then
      rs <= rsin;
      if RESET_ALL and rstn = '0' then
        rs <= SRES;
      end if;
    end if;
  end process;

  -----------------------------------------------------------------------------
  -- Check generics (in simulation)
  -----------------------------------------------------------------------------
-- pragma translate_off
    wproc : process
    begin
      if (MMAXDW > AHBDW) then
        assert false
          report "AHB bridge (ahb2ahb): Maximum master i/f AHB access size > AHB bus width"
          severity failure;
        wait;
      end if;

      if (SMAXDW > AHBDW) then
        assert false
          report "AHB bridge (ahb2ahb): Maximum slave i/f AHB access size > AHB bus width"
          severity failure;
        wait;
      end if;
      
      if (pfen = 1) and (maxdw/32 >= rburst) and (ibrsten = 0 or (maxdw/32 > iburst)) then
        assert false
          report "AHB bridge (ahb2ahb): Read buffer must be able to hold two maximum sized accesses"
          severity failure;
        wait;
      end if;

      if (maxdw/32 >= wburst) then
         assert false
           report "AHB bridge (ahb2ahb): Write buffer must be able to hold two maximum sized accesses"
           severity failure;
        wait;
      end if;
      
      if (SMAXDW/32 > rburst) then
        assert false
          report "AHB bridge (ahb2ahb): Slave maximum AHB access size > read burst length"
          severity failure;
        wait;
      end if;

      if (SMAXDW /= MMAXDW) and (wrcomb = 0) then
        assert false
          report "AHB bridge (ahb2ahb): slave and master i/f max AHB access size mismatch and wrcomb = 0"
          severity failure;
        wait;
      end if;

      if (SMAXDW /= MMAXDW) and (rdcomb = 0) then
        assert false
          report "AHB bridge (ahb2ahb): slave and master i/f max AHB access size mismatch and rdcomb = 0"
          severity failure;
        wait;
      end if;

      if (allbrst /= 0) and (rbufbits < 4) then
        assert false
          report "AHB bridge (ahb2ahb): prefetch buffer must at least have 16 slots for allbrst = 1"
          severity failure;
        wait;
      end if;

      if (rdcomb /= 0) and (combmask = 0) then
        assert false
          report "AHB bridge (ahb2ahb): combmask is 0 but rdcomb /= 0"
          severity failure;
        wait;
      end if;

      if (wrcomb /= 0) and (combmask = 0) then
        assert false
          report "AHB bridge (ahb2ahb): combmask is 0 but wrcomb /= 0"
          severity failure;
        wait;
      end if;

      if (slv = 1) and (dir = 0) and (ffact /= 1) then
        assert false
          report "AHB bridge (ahb2ahb): slv=1 can only be set on a bridge where mst bus freq is >= slv bus freq"
          severity failure;
      end if;

      if (fcfs /= 0) and (split = 0) then
        assert false
          report "AHB bridge (ahb2ahb): fcfs /= 0 and split = 0 is not a supported configuration"
          severity failure;
      end if;

      if (pfen /= 0) and (rbufbits <= log2(maxdw/32)) then
        assert false
          report "AHB bridge (ahb2ahb): prefetch buffer must be able to hold two maximum sized accesses"
          severity failure;
      end if;
      
      wait;
    end process;
-- pragma translate_on

end;

