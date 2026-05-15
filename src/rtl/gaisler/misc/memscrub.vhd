------------------------------------------------------------------------------
--  This file is a part of the GRLIB VHDL IP LIBRARY
--  Copyright (C) 2017, Cobham Gaisler AB - all rights reserved.
--
-- ANY USE OR REDISTRIBUTION IN PART OR IN WHOLE MUST BE HANDLED IN 
-- ACCORDANCE WITH THE GAISLER LICENSE AGREEMENT AND MUST BE APPROVED 
-- IN ADVANCE IN WRITING. 
-----------------------------------------------------------------------------
-- Entity:      memscrub
-- File:        memscrub.vhd
-- Author:      Magnus Hjorth - Aeroflex Gaisler
-- Description: EDAC Memory scrubber (expanded ahbstat)
------------------------------------------------------------------------------

library ieee;
library grlib;
library gaisler;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use grlib.amba.all;
use grlib.stdlib.all;
use grlib.devices.all;
use gaisler.misc.all;

entity memscrub is
  generic(
    hmindex : integer;
    hsindex : integer;    
    ioaddr  : integer;
    iomask  : integer;
    hirq    : integer;
    nftslv  : integer range 1 to NAHBSLV-1;
    -- Width of memory in bits (32/64/128/256/512/1024)
    memwidth: integer;
    -- Read block (cache line) burst size, must be even mult of 2
    burstlen: integer;
    countlen: integer
    );
  port(
    rst   : in std_ulogic;
    clk   : in std_ulogic;
    ahbmi : in ahb_mst_in_type;
    ahbmo : out ahb_mst_out_type;
    ahbsi : in ahb_slv_in_type;
    ahbso : out ahb_slv_out_type;
    scrubi: in memscrub_in_type
  );
  attribute sync_set_reset of rst : signal is "true"; 
end entity;

architecture rtl of memscrub is


    -- How to handle uncorrectable read errors in regeneration mode
    -- 1 = Fall back to regular scrub routine for this block
    -- 2 = Overwrite location with zeroes
    -- 3 = Overwrite location with the data that is put on the AHB bus the same
    --     cycle as hresp=HRESP_ERROR and hready=0
  constant regen_errmode: integer range 1 to 3 := 1;
  
  function gethsize(sz: integer) return std_logic_vector is
    variable hs: std_logic_vector(2 downto 0);
  begin
    hs := std_logic_vector(to_unsigned(log2(sz/8),3));
    return hs;
  end;
  
  constant MODE_NORMAL: std_logic_vector := "00";
  constant MODE_REGEN:  std_logic_vector := "01";
  constant MODE_INIT:   std_logic_vector := "10";

  -- AHB bus address alignment bit pos
  constant ahbal: integer := log2(memwidth / 8);
  -- Block alignment bit pos
  constant blkal: integer := ahbal + log2(burstlen);
  -- Count block alignment bit pos
  constant cntblkal: integer := ahbal + log2(countlen);
  
  constant addrpad: std_logic_vector(ahbal-1 downto 0) := (others => '0');
  
  subtype ahbword is std_logic_vector(memwidth-1 downto 0);
  type scrub_fifo_type is array(natural range <>) of ahbword;
  
  constant zerodata: ahbword := (others => '0');
  
  type scrub_state_type is (IDLE,GETLOCK,READBURST,SCRUB0,SCRUB1,SCRUB2,SCRUB3,SCRUB4,WRITEBURST,DELAY);

  type counter_dir is (NONE,UP,DOWN,CLR);
    
  type reg_type is record
    -- AHB Status register/error counters etc
    addr      : std_logic_vector(31 downto 0); --failing address
    hsize     : std_logic_vector(2 downto 0);  --ahb signals for failing op.
    hmaster   : std_logic_vector(3 downto 0);
    hwrite    : std_ulogic;
    newerr    : std_ulogic; --new error detected
    cerror    : std_ulogic; --correctable error detected
    hirq      : std_ulogic;
    uecount   : std_logic_vector(7 downto 0);
    cecount   : std_logic_vector(9 downto 0);
    uetrig    : std_logic_vector(7 downto 0);
    cetrig    : std_logic_vector(9 downto 0);
    uetrigen  : std_logic;
    cetrigen  : std_logic;
    -- Register I/O area state
    io_issel  : std_logic;
    io_errres : std_logic;
    io_addr   : std_logic_vector(6 downto 2);
    io_wra    : std_logic;
    io_wrd    : std_logic;
    io_data   : std_logic_vector(31 downto 0);
    -- AHB master state
    mst_addr_owner : std_logic;
    mst_data_owner : std_logic;
    mo_hbusreq     : std_logic;
    mo_hlock       : std_logic;
    mo_htrans      : std_logic_vector(1 downto 0);
    mo_hwrite      : std_logic;
    mo_hburst      : std_logic_vector(2 downto 0);    
    lastlock       : std_logic;
    lasterr        : std_logic;
    -- Scrubber state and registers
    scrub_st       : scrub_state_type;
    scrub_enable   : std_logic;
    scrub_loop     : std_logic;
    scrub_extstart : std_logic;
    scrub_extclear : std_logic;
    scrub_mode     : std_logic_vector(1 downto 0);
    scrub_start    : std_logic_vector(31 downto blkal);
    scrub_end      : std_logic_vector(31 downto blkal);
    scrub_pos      : std_logic_vector(31 downto blkal);
    scrub_range2_en: std_logic;
    scrub_start2   : std_logic_vector(31 downto blkal);
    scrub_end2     : std_logic_vector(31 downto blkal);    
    scrub_blkpos   : std_logic_vector(blkal-1 downto ahbal);
    scrub_fifo     : scrub_fifo_type(burstlen-1 downto 0);
    scrub_blkcount   : std_logic_vector(7 downto 0);
    scrub_blktrig    : std_logic_vector(7 downto 0);
    scrub_blktrig_en : std_logic;
    scrub_blktrig_t  : std_logic;
    scrub_runcount   : std_logic_vector(9 downto 0);
    scrub_runtrig    : std_logic_vector(9 downto 0);
    scrub_runtrig_en : std_logic;
    scrub_runtrig_t  : std_logic;
    scrub_rundone    : std_logic;
    scrub_rundone_irq: std_logic;
    next_done: std_logic;
    next_ce: std_logic;
    blockerr: std_logic;
    delay   : std_logic_vector(7 downto 0);
    -- scrub_blkpos is reused to store lsb:s for delay counter
    delaycnt : std_logic_vector(7-(blkal-ahbal) downto 0);
  end record;

  signal r, rin : reg_type;

  constant VERSION : integer := 0;

  constant hsconfig : ahb_config_type := (
  0 => ahb_device_reg (VENDOR_GAISLER, GAISLER_MEMSCRUB, 0, VERSION, hirq),
  4 => ahb_iobar(ioaddr, iomask),
  others => (others => '0'));

  constant hmconfig : ahb_config_type := (
  0 => ahb_device_reg (VENDOR_GAISLER, GAISLER_MEMSCRUB, 0, VERSION, 0),
  others => (others => '0'));
  
begin

  comb : process(rst, ahbmi, ahbsi, scrubi, r) is
  variable v       : reg_type;
  variable iordata : std_logic_vector(31 downto 0);  
  variable iowrite : std_logic;
  variable iowdata : std_logic_vector(31 downto 0);
  variable ce      : std_ulogic; --correctable error
  variable so      : ahb_slv_out_type;
  variable mo      : ahb_mst_out_type;
  variable clear_cecount, clear_uecount: std_logic;
  variable x       : std_logic;
  constant blkpos_zero: std_logic_vector(blkal-1 downto ahbal) := (others => '0');
  constant blkpos_ones: std_logic_vector(blkal-1 downto ahbal) := (others => '1');
  variable blkpos_dir: counter_dir;
  constant delaycnt_zero: std_logic_vector(7-r.scrub_blkpos'length downto 0) := (others => '0');
  variable scrubbing: boolean;
  variable rearb: std_logic;
  variable advdata: std_logic_vector(memwidth-1 downto 0);
  variable adv: std_logic;
  begin
    v := r; iordata := (others => '0'); v.hirq := '0';
    so := ahbs_none; mo := ahbm_none;
    mo.hconfig := hmconfig; so.hconfig := hsconfig;
    mo.hindex := hmindex; so.hindex := hsindex;
    iowrite := '0';
    iowdata := ahbreadword(ahbsi.hwdata, r.io_addr(4 downto 2));
    clear_cecount := '0'; clear_uecount := '0';
    scrubbing := (r.scrub_st=SCRUB3 and r.mst_data_owner='1');
    rearb := '0';
    advdata := ahbreaddata(ahbmi.hrdata, gethsize(memwidth));
    adv := '0';

    ce := orv(scrubi.cerror(0 to nftslv-1));
    
    ---------------------------------------------------------------------------
    -- AHB Register interface
    ---------------------------------------------------------------------------

      
    if ahbsi.hready='1' then
      if ahbsi.hsel(hsindex)='1' and ahbsi.hready='1' and ahbsi.htrans /= HTRANS_IDLE then
        v.io_issel := '1';
        v.io_addr := ahbsi.haddr(6 downto 2);
        v.io_wra := ahbsi.hwrite;
        if ahbsi.hsize /= HSIZE_WORD then
          v.io_errres := '1';
        else
          v.io_errres := '0';
        end if;
      else
        v.io_issel := '0';
        v.io_errres := '0';
      end if;
    end if;

    if r.io_errres='1' then so.hresp:=HRESP_ERROR; end if;
    
    if r.io_issel='1' then
      v.io_issel := '0';
      so.hready := '0';
      v.io_wrd := r.io_wra;
    else
      v.io_wrd := '0';
    end if;

    iowrite := r.io_wrd;
      
    case r.io_addr(5 downto 2) is
      when "0000" => --status values
        iordata(2 downto 0) := r.hsize;
        iordata(6 downto 3) := r.hmaster;
        iordata(7) := r.hwrite;
        iordata(8) := r.newerr;
        iordata(9) := r.cerror;
        iordata(10) := r.scrub_blktrig_t;
        iordata(11) := r.scrub_runtrig_t;
        iordata(13) := r.scrub_rundone;
        iordata(21 downto 14) := r.uecount;
        iordata(31 downto 22) := r.cecount;
      when "0001" => --failing address
        iordata := r.addr;
      when "0010" => --error config
        iordata(0) := r.uetrigen;
        iordata(1) := r.cetrigen;
        iordata(21 downto 14) := r.uetrig;
        iordata(31 downto 22) := r.cetrig;
      when "0100" =>                    -- scrubber status
        case r.scrub_st is
          when IDLE   => iordata(0) := '0';
          when others => iordata(0) := '1';
        end case;
        iordata(4 downto 1) := std_logic_vector(to_unsigned(log2(burstlen),4));
        iordata(13) := r.scrub_rundone;
        iordata(21 downto 14) := r.scrub_blkcount;
        iordata(31 downto 22) := r.scrub_runcount;
      when "0101" =>                     --scrubber config register
        iordata(0) := r.scrub_enable;
        iordata(1) := r.scrub_extstart;
        iordata(3 downto 2) := r.scrub_mode;
        iordata(4) := r.scrub_loop;
        iordata(5) := r.scrub_range2_en;
        iordata(6) := r.scrub_extclear;
        iordata(7) := r.scrub_rundone_irq;
        iordata(15 downto 8) := r.delay;
      when "0110" =>                     -- scrubber start address
        iordata(31 downto blkal) := r.scrub_start;
        iordata(blkal-1 downto 0) := (others => '0');
      when "0111" =>                     -- scrubber end address
        iordata(31 downto blkal) := r.scrub_end;
        iordata(blkal-1 downto 0) := (others => '1');
      when "1000" =>                    -- scrubber position
        if r.scrub_st /= IDLE then
          iordata := r.scrub_pos & blkpos_zero & addrpad;
        end if;
      when "1001" =>                    -- scrubber error config
        iordata(0) := r.scrub_blktrig_en;
        iordata(1) := r.scrub_runtrig_en;
        iordata(21 downto 14) := r.scrub_blktrig;
        iordata(31 downto 22) := r.scrub_runtrig;
      when "1011" =>                     -- scrubber second start address
        iordata(31 downto blkal) := r.scrub_start2;
        iordata(blkal-1 downto 0) := (others => '0');
      when "1100" =>                     -- scrubber second end address
        iordata(31 downto blkal) := r.scrub_end2;
        iordata(blkal-1 downto 0) := (others => '1');              
      when others => null;
    end case;

    if r.io_wra='0' then
      v.io_data := iordata;
    else
      v.io_data := ahbreadword(ahbsi.hwdata, r.io_addr(4 downto 2));
    end if;
    
    so.hrdata := ahbdrivedata(r.io_data);
    
    --writes.
    iowdata := r.io_data;
    if iowrite = '1' then

      case r.io_addr(5 downto 2) is 
        when "0000" =>              -- Status register
          
          -- The AHBSTAT allows these two bits to be set. If newerr is
          -- set to 1, it will then trigger an interrupt. Note that it
          -- might mess up the counters but that is the software's
          -- responsibility.
          v.newerr := iowdata(8);
          v.cerror := iowdata(9);

          v.scrub_blktrig_t := iowdata(10);
          v.scrub_runtrig_t := iowdata(11);
          v.uecount := iowdata(21 downto 14);
          v.cecount := iowdata(31 downto 22);
          
        when "0010" =>              -- Error config register
          v.uetrigen := iowdata(0);
          v.cetrigen := iowdata(1);
          v.uetrig := iowdata(21 downto 14);
          v.cetrig := iowdata(31 downto 22);

        when "0100" =>             -- Scrubber status register
          v.scrub_rundone := iowdata(13);          
          
        when "0101" =>             -- Scrubber config register
          v.scrub_enable := iowdata(0);
          v.scrub_extstart := iowdata(1);
          v.scrub_mode := iowdata(3 downto 2);
          v.scrub_loop := iowdata(4);
          v.scrub_range2_en := iowdata(5);
          v.scrub_extclear := iowdata(6);
          v.scrub_rundone_irq := iowdata(7);
          v.delay := iowdata(15 downto 8);
          
        when "0110" =>                     -- scrubber start address
          v.scrub_start := iowdata(31 downto blkal);
          
        when "0111" =>                     -- scrubber end address
          v.scrub_end := iowdata(31 downto blkal);
          
        when "1001" =>                    -- scrubber error config
          v.scrub_blktrig_en := iowdata(0);
          v.scrub_runtrig_en := iowdata(1);
          v.scrub_blktrig := iowdata(21 downto 14);
          v.scrub_runtrig := iowdata(31 downto 22);

        when "1010" =>                  -- FIFO write reg.
          for x in burstlen-1 downto 1 loop
            v.scrub_fifo(x)(31 downto 0) := r.scrub_fifo(x-1)(memwidth-1 downto memwidth-32);
          end loop;
          v.scrub_fifo(0)(31 downto 0) := iowdata;
          if memwidth > 32 then
            for x in burstlen-1 downto 0 loop
              v.scrub_fifo(x)(memwidth-1 downto 32) := r.scrub_fifo(x)(memwidth-33 downto 0);
            end loop;
          end if;

        when "1011" =>                     -- scrubber start address
          v.scrub_start2 := iowdata(31 downto blkal);
          
        when "1100" =>                     -- scrubber end address
          v.scrub_end2 := iowdata(31 downto blkal);
          
          
        when others => null;
      end case;

    end if; -- iowrite=1


    ---------------------------------------------------------------------------
    -- Scrubber state machine
    ---------------------------------------------------------------------------

    blkpos_dir := NONE;
    
    case r.scrub_st is

      -- Idle state, wait for scrub enable
      when IDLE =>
        v.mo_hlock := '0';
        v.mo_hburst := HBURST_INCR;
        v.blockerr := '0';
        v.delaycnt := (others => '0');
        
        if r.scrub_enable='1' then
          v.mo_hbusreq := '1';
          if r.scrub_mode=MODE_REGEN then 
            -- Assert the busreq/lock signals one cycle in advance (possibly
            -- causing an idle transfer cycle if already granted)
            v.scrub_st := GETLOCK;
            v.mo_hlock := '1';
          elsif r.scrub_mode=MODE_NORMAL then
            v.scrub_st := READBURST;
            v.mo_htrans := HTRANS_NONSEQ;
            v.mo_hwrite := '0';
          else
            v.scrub_st := WRITEBURST;
            v.mo_htrans := HTRANS_NONSEQ;
            v.mo_hwrite := '1';
          end if;
          v.scrub_pos := r.scrub_start;
          blkpos_dir := CLR;
          v.scrub_runcount := (others => '0');
          v.scrub_blkcount := (others => '0');
          v.scrub_rundone := '0';
        end if;


      -- Extra state for acquiring lock
      when GETLOCK =>
        v.mo_hbusreq := '1';
        v.scrub_st := READBURST;
        v.mo_htrans := HTRANS_NONSEQ;
        v.mo_hwrite := '0';
        
        
      -- Read block of data for scrubbing / regeneration
      when READBURST =>

        if ahbmi.hready='1' then
          
          -- Advance burst address
          if r.mst_addr_owner='1' then           
            blkpos_dir := UP;
            if r.mo_hbusreq='1' then
              v.mo_htrans := HTRANS_SEQ;
            end if;

            if r.scrub_blkpos=blkpos_ones then
              if r.mo_hlock='1' then
                
                -- pragma translate_off
                assert r.mo_hwrite='0' severity failure;
                -- pragma translate_on
                
                v.mo_hwrite := '1';
                v.mo_htrans := HTRANS_NONSEQ;
                  
              else
                v.mo_hbusreq := '0';
                v.mo_hlock := '0';
                v.mo_htrans := HTRANS_IDLE;
              end if;
            end if;
              
          end if;   -- hready and addr_owner

          if r.mst_data_owner='1' then
            -- Read data into FIFO
            v.scrub_fifo := r.scrub_fifo(burstlen-2 downto 0) & advdata;                        

            -- State transitions
            if r.scrub_blkpos=blkpos_zero then
              if r.mo_hlock='0' then
                v.scrub_st := DELAY;
                v.mo_hbusreq := '0';
                v.mo_htrans := HTRANS_IDLE;
                blkpos_dir := CLR;
              else
                -- pragma translate_off
                assert r.mo_hwrite='1' severity failure;
                -- pragma translate_on
                v.scrub_st := WRITEBURST;
              end if;
            end if;
            
            -- Handle correctable error
            if ce='1' then
              v.blockerr:='1';
              if r.mo_hlock='0' then
                v.scrub_st := SCRUB1;
                v.mo_hbusreq := '1';
                v.mo_hlock := '1';
                v.mo_htrans := HTRANS_IDLE;
                v.mo_hburst := HBURST_SINGLE;
                blkpos_dir := DOWN;
              end if;
            end if;
            
          end if;   -- hready and data_owner
          
        end if;     -- hready
               
        -- Handle RETRY/SPLIT/ERROR 
        if r.mst_data_owner='1' then

          case ahbmi.hresp is
            when HRESP_SPLIT | HRESP_RETRY => 
              -- Step back to retry old addr
              blkpos_dir := DOWN;
              -- Special case for last element in regen mode
              v.mo_hwrite := '0';
              
            when HRESP_ERROR =>
              
              if r.mo_hlock='1' then
                v.mo_htrans := HTRANS_NONSEQ;
                case regen_errmode is
                  when 1 =>                  
                    v.mo_hlock := '0';
                    blkpos_dir := CLR;
                    v.mo_hwrite := '0';
                  when 2 =>
                    v.scrub_fifo := r.scrub_fifo(burstlen-2 downto 0) & zerodata;                                        
                  when 3 =>
                    v.scrub_fifo := r.scrub_fifo(burstlen-2 downto 0) & advdata;                    
                end case;
                if regen_errmode > 1 and r.scrub_blkpos=blkpos_zero then
                  v.scrub_st := WRITEBURST;
                end if;
                
              else
                -- Special case: scrub mode, UC error on the last element of
                -- the read burst.
                if r.scrub_blkpos=blkpos_zero then
                  v.scrub_st := DELAY;
                  v.mo_hbusreq := '0';
                  blkpos_dir := CLR;
                end if;
              end if;  -- hlock, hresp, data_owner
              
            when others => null;
              
          end case;  -- hresp and data_owner
          
        end if;     -- data_owner

        -- Set next_done to '0' before entering scrub1
        v.next_done := '0';



      when SCRUB0 =>
        -- Scrubbing 0: Retry read N+1
        -- Read N+1 in address phase, nothing in data phase

        -- pragma translate_off
        assert r.mo_hbusreq='1' and r.mo_hlock='0' and r.mst_data_owner='0' severity failure;
        -- pragma translate_on

        if ahbmi.hready='1' then
          if r.mst_addr_owner='1' then
            blkpos_dir := DOWN;
            v.mo_hlock := '1';
            v.mo_htrans := HTRANS_IDLE;
            v.scrub_st := SCRUB1;
          end if;
        end if;
          
      -- Scrubbing 1: Transition from burst to scrub RMW cycle (locked idle cycle)
        -- idle w hlock in address phase
        -- either idle or read N+1 in data phase
        
      when SCRUB1 =>

        -- pragma translate_off
        assert r.mo_hbusreq='1' and (r.mo_hlock='1') severity failure;
        -- pragma translate_on
        
        if ahbmi.hready='1' then
          
          if r.mst_addr_owner='1' then
            v.mo_htrans := HTRANS_NONSEQ;
            v.mo_hwrite := '0';
            v.scrub_st := SCRUB2;
          end if;
        
          -- There may be a ongoing read in the burst sequence in the data phase
          -- If there is, we wait for it to finish, and set next_done/next_ce

          if r.mst_data_owner='1' then
            v.next_done := '1';
            v.next_ce := ce;
          end if;
          
        end if;

        -- Special cases: The following read gives error or retry response.

        if r.mst_data_owner='1' and ahbmi.hresp=HRESP_ERROR then
          v.next_done := '1';
          v.next_ce := '0';
        end if;

        if r.mst_data_owner='1' and (ahbmi.hresp=HRESP_SPLIT or ahbmi.hresp=HRESP_RETRY) then
          v.scrub_st := SCRUB0;
          v.mo_hlock := '0';
          v.mo_htrans := HTRANS_NONSEQ;
          blkpos_dir := UP;
        end if;


        
      -- Scrubbing 2: Read
      -- locked read in address phase
      -- nothing in data phase
        
      when SCRUB2 => 

        -- pragma translate_off
        assert r.mo_hbusreq='1' and r.mo_hlock='1' and r.mst_data_owner='0' and r.mo_hwrite='0' severity failure;
        -- pragma translate_on

        if ahbmi.hready='1' then

          if r.mst_addr_owner='1' then
            
            v.mo_hwrite := '1';
            v.scrub_st := SCRUB3;

          end if;
          
        end if;               


      -- Scrubbing 3: Read data, write addr
      -- write N in address phase, read N or nothing in data phase
        
      when SCRUB3 => 

        -- pragma translate_off
        assert r.mo_hbusreq='1' and r.mo_hlock='1' and r.mo_hwrite='1' severity failure;
        -- pragma translate_on

        if ahbmi.hready='1' then

          if r.mst_addr_owner='1' then
              
            v.mo_hwrite := '0';
            if r.next_done='0' or r.next_ce='0' then
              v.mo_htrans := HTRANS_IDLE;
              v.mo_hlock := '0';
            end if;
            if r.next_done='1' then
              blkpos_dir := UP;
            end if;
            v.scrub_st := SCRUB4;
            
          end if;

          if r.mst_data_owner='1' then
            -- Read data into front of FIFO
            v.scrub_fifo(burstlen-1) := advdata;
          end if;          
          
        end if;

        
        if r.mst_data_owner='1' then
          if (ahbmi.hresp=HRESP_SPLIT or ahbmi.hresp=HRESP_RETRY) then
            v.mo_hwrite := '0';
            v.scrub_st := SCRUB2;            
          elsif ahbmi.hresp=HRESP_ERROR then
            v.mo_hlock := '0';
            v.mo_htrans := HTRANS_IDLE;
            v.next_done := '0';
            v.next_ce := '0';
            v.scrub_st := SCRUB4;
          end if;
        end if;


      -- Scrubbing 4: Write data, read N+1 or idle (w. hlock='0') addr
      when SCRUB4 =>

        adv := '0';
        
        if ahbmi.hready='1' then
          
          if r.mst_addr_owner='1' then
            
            if r.next_done='1' and r.next_ce='1' then
              v.mo_hwrite := '1';
              v.next_done := '0';
              v.next_ce := '0';
              v.scrub_st := SCRUB3;
            else
              adv := '1';
            end if;

          end if;

        end if;

        if r.mst_data_owner='1' then
          if (ahbmi.hresp=HRESP_SPLIT or ahbmi.hresp=HRESP_RETRY) then
            if r.next_done='1' then
              blkpos_dir := DOWN;
            end if;
            v.mo_hwrite := '1';
            v.mo_hlock := '1';
            v.mo_hbusreq := '1';
            v.mo_htrans := HTRANS_NONSEQ;
            v.scrub_st := SCRUB3;
          elsif ahbmi.hresp=HRESP_ERROR then
            v.mo_hlock := '0';
            v.mo_htrans := HTRANS_IDLE;
            if r.next_done='1' then
              blkpos_dir := DOWN;
              v.next_done := '0';
              v.next_ce := '0';
            end if;            
          end if;
        end if;

        if adv='1' then
          blkpos_dir := UP;
          v.mo_hburst := HBURST_INCR;
          v.mo_hwrite := '0';
          if r.scrub_blkpos=blkpos_ones then
            v.scrub_st := DELAY;
            v.mo_hbusreq := '0';
            v.mo_htrans := HTRANS_IDLE;
          else
            v.scrub_st := READBURST;                
            v.mo_htrans := HTRANS_NONSEQ;
          end if;
        end if;
        
        


      -- Write block with locked burst
      when WRITEBURST =>

        if ahbmi.hready='1' then

          if r.mst_addr_owner='1' then
            blkpos_dir := UP;
            if r.mo_hbusreq='1' then
              v.mo_htrans := HTRANS_SEQ;
            end if;
            if r.scrub_blkpos=blkpos_ones then
              v.mo_htrans := HTRANS_IDLE;
              v.mo_hlock := '0';
              v.mo_hbusreq := '0';
            end if;
          end if;

          if r.mst_data_owner='1' then
            -- Rotate FIFO
            v.scrub_fifo := r.scrub_fifo(burstlen-2 downto 0) & r.scrub_fifo(burstlen-1);
            
            if r.scrub_blkpos=blkpos_zero then
              v.scrub_st := DELAY;
              blkpos_dir := CLR;
            end if;
          end if;              
            
        end if;

        if r.mst_data_owner='1' then
          if (ahbmi.hresp=HRESP_SPLIT or ahbmi.hresp=HRESP_RETRY) then
            blkpos_dir := DOWN;
            -- Last element
            v.mo_htrans := HTRANS_NONSEQ;
            v.mo_hwrite := '1';
            v.mo_hbusreq := '1';
            v.mo_hlock := '1';
          elsif ahbmi.hresp=HRESP_ERROR then
            -- Rotate FIFO
            v.scrub_fifo := r.scrub_fifo(burstlen-2 downto 0) & r.scrub_fifo(burstlen-1);
            v.mo_htrans := HTRANS_NONSEQ;

            if r.scrub_blkpos=blkpos_zero then
              v.scrub_st := DELAY;
              v.mo_hbusreq := '0';
              v.mo_htrans := HTRANS_IDLE;
              blkpos_dir := CLR;
            end if;            
            
          end if;
        end if;

          
      -- Sleep delay+1 cycles
      when DELAY =>
        -- pragma translate_off
        assert r.mo_htrans=HTRANS_IDLE and r.mo_hbusreq='0' and r.mo_hlock='0' severity failure;        
        -- pragma translate_on
        v.blockerr := '0';
        blkpos_dir := UP;
        if r.scrub_blkpos=blkpos_ones then
          v.delaycnt := std_logic_vector(unsigned(r.delaycnt)+1);
        end if;

        if r.scrub_enable='0' then
          v.scrub_st := IDLE;            
        
        elsif ( (r.delaycnt & r.scrub_blkpos)=r.delay) then

          v.scrub_blkpos := (others => '0');
          v.scrub_pos := std_logic_vector(unsigned(r.scrub_pos)+1);
          v.delaycnt := (others => '0');          
          if countlen=burstlen or orv(v.scrub_pos(cntblkal-1 downto blkal))='0' then 
            v.scrub_blkcount := (others => '0');
          end if;

          if r.scrub_pos = r.scrub_end and r.scrub_range2_en='1' then
            v.scrub_pos := r.scrub_start2;
          end if;
            
          if (r.scrub_pos=r.scrub_end and r.scrub_range2_en='0') or
            (r.scrub_pos=r.scrub_end2 and r.scrub_range2_en='1') then
            v.scrub_st := IDLE;
            v.scrub_rundone := '1';
            v.scrub_enable := r.scrub_loop;

          else
            v.mo_hbusreq := '1';
            v.mo_htrans := HTRANS_NONSEQ;
            blkpos_dir := CLR;
            if r.scrub_mode=MODE_NORMAL then
              v.scrub_st := READBURST;
              v.mo_hlock := '0';              
              v.mo_hwrite := '0';
            elsif r.scrub_mode=MODE_REGEN then
              v.scrub_st := GETLOCK;
              v.mo_hlock := '1';
              v.mo_htrans := HTRANS_IDLE;
              v.mo_hwrite := '0';
            else
              v.scrub_st := WRITEBURST;
              v.mo_hlock := '0';
              v.mo_hwrite := '1';
            end if;
          end if;                     
          
        end if;

    end case;

    -- Update scrubber error counters
    if (r.scrub_st=READBURST or r.scrub_st=SCRUB1) and
      r.mst_data_owner='1' and ahbmi.hready='1' and ce='1' and r.newerr='0' then
      
      v.scrub_blkcount := std_logic_vector(unsigned(r.scrub_blkcount)+1);
      v.scrub_runcount := std_logic_vector(unsigned(r.scrub_runcount)+1);
      
      if r.scrub_blkcount = r.scrub_blktrig and r.scrub_blktrig_en='1' then
        v.newerr := '1';
        v.scrub_blktrig_t := '1';              
      end if;
      if r.scrub_runcount = r.scrub_runtrig and r.scrub_runtrig_en='1' then
        v.newerr := '1';
        v.scrub_runtrig_t := '1';
      end if;
      
    end if;

    -- External start
    if (scrubi.start='1' and r.scrub_extstart='1') then
      v.scrub_enable := '1';
    end if;

    case blkpos_dir is
      when NONE => null;
      when UP   => v.scrub_blkpos := std_logic_vector(unsigned(r.scrub_blkpos)+1);
      when DOWN => v.scrub_blkpos := std_logic_vector(unsigned(r.scrub_blkpos)-1);
      when CLR  => v.scrub_blkpos := blkpos_zero;
    end case;
    
    ---------------------------------------------------------------------------
    -- AHB master logic
    ---------------------------------------------------------------------------

    v.lasterr := '0';
    if ahbmi.hready='1' then
      v.mst_addr_owner := ahbmi.hgrant(hmindex);      
      v.mst_data_owner := r.mst_addr_owner and (r.mo_htrans(1) or r.mo_htrans(0));
    end if;
    if ahbmi.hresp /= HRESP_OKAY or rearb='1' then
      v.mst_addr_owner := '0';
      v.mst_data_owner := '0';
      v.lasterr := '1';
    end if;    
    if r.mst_addr_owner='0' and r.mo_htrans/=HTRANS_IDLE then
      v.mo_htrans := HTRANS_NONSEQ;
    end if;
      
    mo.hsize := gethsize(memwidth);
    mo.haddr := r.scrub_pos & r.scrub_blkpos & addrpad;
    mo.hwdata := ahbdrivedata(r.scrub_fifo(burstlen-1));
    mo.hbusreq := r.mo_hbusreq;
    mo.hlock := r.mo_hlock;
    mo.htrans := r.mo_htrans;
    if r.lasterr='1' then mo.htrans:=HTRANS_IDLE; end if;
    mo.hwrite := r.mo_hwrite;
    mo.hburst := r.mo_hburst;    
    
    v.lastlock := mo.hlock;

    -- pragma translate_off
    -- assert (mo.htrans /= HTRANS_IDLE and mo.hbusreq='1') or (mo.hlock='0' and mo.hwrite='0') severity failure;
    if mo.htrans=HTRANS_IDLE or mo.hbusreq='0' then
      mo.hwrite := '0';
    end if;
    
    -- pragma translate_on

    
    ---------------------------------------------------------------------------
    -- AHB bus error snooping
    ---------------------------------------------------------------------------
    
    -- v.hresp := ahbmi.hresp;
    
    if (ahbsi.hready = '1') and (r.newerr = '0') then
      if (ce = '1') and not scrubbing then
        v.cecount := std_logic_vector(unsigned(r.cecount)+1);
        if r.cecount=r.cetrig and r.cetrigen='1' then
          v.newerr := '1';
          v.cerror := '1';
        end if;
      end if;
      if (ahbmi.hresp = HRESP_ERROR) then
        v.uecount := std_logic_vector(unsigned(r.uecount)+1);
        if r.uecount=r.uetrig and r.uetrigen='1' then
          v.newerr := '1';
          v.cerror := '0';
        end if;
      end if;
    end if;        
    
    if (ahbsi.hready = '1') and (v.newerr = '0') then
      v.addr := ahbsi.haddr;
      v.hsize := ahbsi.hsize;
      v.hmaster := ahbsi.hmaster;
      v.hwrite := ahbsi.hwrite;
    end if;

    ---------------------------------------------------------------------------

    if scrubi.clrcount='1' and r.scrub_extclear='1' and r.hirq='0' and v.newerr='0' then
      clear_cecount:='1';
      clear_uecount:='1';
    end if;
    
    if clear_cecount='1' then v.cecount := (others => '0'); end if;
    if clear_uecount='1' then v.uecount := (others => '0'); end if;
    
    --irq generation
    v.hirq := (v.newerr and not r.newerr) or (v.scrub_rundone and not r.scrub_rundone and r.scrub_rundone_irq);
    so.hirq(hirq) := r.hirq;
        
    --reset
    if rst = '0' then
      v.newerr := '0'; v.cerror := '0';
      v.io_issel := '0';
      v.uecount := (others => '0');
      v.cecount := (others => '0');
      v.uetrig := (others => '0');
      v.cetrig := (others => '0');
      v.mst_addr_owner := '0';
      v.scrub_st := IDLE;
      v.scrub_enable := '0';
      v.scrub_loop := '0';
      v.scrub_extstart := '0';
      v.scrub_extclear := '0';
      v.scrub_mode := "00";
      v.scrub_start := (others => '0');
      v.scrub_end := (others => '0');
      v.scrub_pos := (others => '0');
      v.scrub_range2_en := '0';
      v.scrub_start2 := (others => '0');
      v.scrub_end2 := (others => '0');
      v.scrub_blkcount := (others => '0');
      v.scrub_blktrig := (others => '0');
      v.scrub_blktrig_en := '0';
      v.scrub_blktrig_t := '0';
      v.scrub_runcount := (others => '0');
      v.scrub_runtrig := (others => '0');
      v.scrub_runtrig_en := '0';
      v.scrub_runtrig_t := '0';
      v.scrub_rundone := '0';
      v.scrub_rundone_irq := '0';
      v.next_done := '0';
      v.next_ce := '0';
      v.delay := (others => '0');
      -- Global triggers enabled at reset for compatibility with ahbstat
      v.uetrigen := '1';
      v.cetrigen := '1';
      v.mo_htrans := HTRANS_IDLE;
      v.mo_hbusreq := '0';
      v.mo_hwrite := '0';
      v.scrub_blkpos := blkpos_zero;
      mo.htrans := HTRANS_IDLE;
      mo.hbusreq := '0';
      -- Extra resets
      v.delaycnt := (others => '0');
    end if;

    -- Don't allow setting the block error count trigger >= count block size
    -- Allow the tools to optimize some unneccesary counter bits out
    v.scrub_blktrig(7 downto log2(countlen)+1) := (others => '0');
    v.scrub_blkcount(7 downto log2(countlen)+1) := (others => '0');
    
    rin <= v;
    ahbso <= so;
    ahbmo <= mo;
  end process;

  regs : process(clk) is
  begin
    if rising_edge(clk) then r <= rin; end if;
  end process;

-- boot message

-- pragma translate_off
    bootmsg : report_version 
    generic map ("memscrub" & tost(hsindex) & 
	": AHB memory scrubber rev " & tost(VERSION) & 
	", irq " & tost(hirq));
-- pragma translate_on

end architecture;

