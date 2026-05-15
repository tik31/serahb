------------------------------------------------------------------------------
--  This file is a part of the GRLIB VHDL IP LIBRARY
--  Copyright (C) 2017, Cobham Gaisler AB - all rights reserved.
--
-- ANY USE OR REDISTRIBUTION IN PART OR IN WHOLE MUST BE HANDLED IN 
-- ACCORDANCE WITH THE GAISLER LICENSE AGREEMENT AND MUST BE APPROVED 
-- IN ADVANCE IN WRITING. 
-----------------------------------------------------------------------------
-- Entity:      ftahbram
-- File:        ftahbram.vhd
-- Author:      Marko Isomaki - Gaisler Research
-- Based on:    ahbram.vhd
-- Description: AHB ram with EDAC. 0/1-waitstate read, 0/1-waitstate write.
--              1/2-waitstate byte/halfword write
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
library grlib;
use grlib.amba.all;
use grlib.stdlib.all;
use grlib.devices.all;
library techmap;
use techmap.gencomp.all;
library gaisler;
use grlib.ftlib.all;
use gaisler.misc.all;

entity ftahbram2 is
  generic (
    hindex    : integer := 0;
    haddr     : integer := 0;
    hmask     : integer := 16#fff#;
    tech      : integer := DEFMEMTECH; 
    kbytes    : integer := 1;
    pindex    : integer := 0;
    paddr     : integer := 0;
    pmask     : integer := 16#fff#;
    testen    : integer := 0;
    edacen    : integer range 1 to 3 := 1);
  port (
    rst     : in  std_ulogic;
    clk     : in  std_ulogic;
    ahbsi   : in  ahb_slv_in_type;
    ahbso   : out ahb_slv_out_type;
    apbi    : in  apb_slv_in_type;
    apbo    : out apb_slv_out_type;
    aramo   : out ahbram_out_type
  );
end;

architecture rtl of ftahbram2 is

constant abits : integer := log2(kbytes) + 8;

constant memsize : integer := log2(kbytes);
  
constant hconfig : ahb_config_type := (
  0 => ahb_device_reg ( VENDOR_GAISLER, GAISLER_FTAHBRAM, 0, abits+2, 0),
  4 => ahb_membar(haddr, '1', '1', hmask),
  others => zero32);

constant pconfig : apb_config_type := (
  0 => ahb_device_reg ( VENDOR_GAISLER, GAISLER_FTAHBRAM, 0, abits+2, 0),
  1 => apb_iobar(paddr, pmask));


type state_type is (idle, wr, rd0, rd1, rde0, rde1, err, wr2rd, rds);

type ahb_ctrl is record
  haddr   : std_logic_vector(abits+1 downto 0);
  hwrite  : std_ulogic;
  hsize   : std_logic_vector(1 downto 0);
  htrans  : std_logic_vector(1 downto 0);
end record;

type ahb_ctrl_vector is array (0 to 1) of ahb_ctrl;

type reg_type is record
  state   : state_type;
  --AHB Slave interface 
  hready  : std_ulogic; 
  hsel    : std_ulogic;
  ahbc    : ahb_ctrl_vector;
  wdata   : std_logic_vector(31 downto 0);
  hresp   : std_logic_vector(1 downto 0);

  --APB Interface
  en      : std_ulogic; --edac enable
  wb      : std_ulogic; --write bypass
  rb      : std_ulogic; --read bypass
  tcb     : std_logic_vector(6 downto 0); --test checkbits
  errcnt  : std_logic_vector(7 downto 0); --error counter
  --Internal state
  decout  : edacdectype; --output from edac decoder in decode stage
  diag    : std_logic_vector(1 downto 0); --test checkbits
  rdata   : std_logic_vector(31 downto 0);
  cbits   : std_logic_vector(6 downto 0);
  wren    : std_ulogic;
  ramsel  : std_ulogic;
end record;

signal r, rin   : reg_type;
signal ramsel   : std_ulogic;
signal ramaddr  : std_logic_vector(abits-1 downto 0);
signal ramdata  : std_logic_vector(31 downto 0);
signal cbin     : std_logic_vector(6 downto 0);
signal cbout    : std_logic_vector(6 downto 0);
signal testin   : std_logic_vector(3 downto 0);
signal ramdin, ramdout   : std_logic_vector(38 downto 0);
signal error    : std_logic_vector(1 downto 0);

begin

  testin <= ahbsi.testen & ahbsi.scanen & r.diag;

  comb : process (ahbsi, r, rst, ramdata, apbi, cbout, error)
    variable v        : reg_type;        
    variable syn      : std_logic_vector(6 downto 0); --syndrome in read stage
    variable prdata   : std_logic_vector(31 downto 0); --apb read data
    variable vcbin    : std_logic_vector(6 downto 0); --checkbits
    variable hready   : std_ulogic;
    variable ce       : std_ulogic;
    variable haddrtmp : std_logic_vector(1 downto 0);
    variable hwdata    : std_logic_vector(31 downto 0);
  begin
    v := r; ce := '0'; syn := (others => '0');

    hready := '1'; v.wren := '0';

    hwdata := ahbreadword(ahbsi.hwdata);
    
    ----------------------------------------------------------------------------
    --EDAC
    ----------------------------------------------------------------------------
    --generate checkbits for write
    vcbin := (others => '0');
    if edacen = 1 then vcbin := edacencode(r.wdata); end if;

    --diagnostic write enabled, use checkbits from apb register
    if r.wb = '1' then
      vcbin := r.tcb;
    end if;

    --read decoding
    v.rdata := ramdata; v.cbits := cbout;
    if edacen > 1 then v.cbits(1 downto 0) := error; end if;
    if r.en = '1' then
      if edacen = 1 then
        syn     := edacsyngen(r.rdata, r.cbits); --syndrome calculation
        v.decout := edacdecode(r.rdata, syn);   --decoder
      else
        v.decout.data := zero32 & r.rdata;
        v.decout.err := r.cbits(0) and not r.cbits(1);
        v.decout.merr := r.cbits(1);
      end if;
    else
      v.decout.data := zero32 & r.rdata;
      v.decout.merr := '0';
      v.decout.err  := '0';
    end if;
     
    ----------------------------------------------------------------------------
    --Memory access fsm
    ----------------------------------------------------------------------------
    v.hsel := ahbsi.hready and ahbsi.hsel(hindex) and ahbsi.htrans(1);
    v.hresp := HRESP_OKAY;
    
    case r.state is
      when idle =>
        v.ramsel := '0';
        if v.hsel = '1' then
          if (ahbsi.hwrite = '0') or
             ((ahbsi.hwrite = '1') and (ahbsi.hsize /= HSIZE_WORD)) then
            v.hready := '0'; v.state := rd0; v.ramsel := '1';
            v.ahbc(1).hwrite := ahbsi.hwrite;
            v.ahbc(1).haddr  := ahbsi.haddr(abits+1 downto 0);
            v.ahbc(1).hsize  := ahbsi.hsize(1 downto 0);
            v.ahbc(1).htrans := ahbsi.htrans;
          else
            v.state := wr; v.ramsel := '1';
            v.ahbc(0).hwrite := ahbsi.hwrite;
            v.ahbc(0).haddr  := ahbsi.haddr(abits+1 downto 0);
            v.ahbc(0).hsize  := ahbsi.hsize(1 downto 0);
            v.ahbc(0).htrans := ahbsi.htrans;
          end if;
        end if;
      when wr =>
        v.ahbc(0).hwrite := ahbsi.hwrite;
        v.ahbc(0).haddr  := ahbsi.haddr(abits+1 downto 0);
        v.ahbc(0).hsize  := ahbsi.hsize(1 downto 0);
        v.ahbc(0).htrans := ahbsi.htrans;
        
        v.ahbc(1).hwrite := r.ahbc(0).hwrite;
        v.ahbc(1).haddr  := r.ahbc(0).haddr;
        v.ahbc(1).htrans := r.ahbc(0).htrans;
        v.wren           := '1';
        v.wdata          := hwdata(31 downto 0);
        if v.hsel = '0' then
          v.state := idle; 
        else
          if (ahbsi.hwrite = '0') or
             ((ahbsi.hwrite = '1') and (ahbsi.hsize /= HSIZE_WORD)) then
            v.state := wr2rd; v.hready := '0';
          end if;
        end if;
      when wr2rd =>
        v.ahbc(1).hwrite := r.ahbc(0).hwrite;
        v.ahbc(1).haddr  := r.ahbc(0).haddr(abits+1 downto 0);
        v.ahbc(1).hsize  := r.ahbc(0).hsize(1 downto 0);
        v.ahbc(1).htrans := r.ahbc(0).htrans;
        v.state := rd0;
      when rd0 =>
        v.state := rd1;
        if r.ahbc(1).hwrite = '0' then
          v.ahbc(1).haddr  := ahbsi.haddr(abits+1 downto 0);
        end if;
      when rd1 => --read stage
        v.state := rde0;
        if r.ahbc(1).hwrite = '0' then
          v.ahbc(1).haddr := r.ahbc(1).haddr + 4;
        end if;
      when rde0 => --edac decode stage
        v.state := rde1; 
        if r.ahbc(1).hwrite = '0' then
          v.ahbc(1).haddr(abits+1 downto 2) := r.ahbc(1).haddr(abits+1 downto 2) + 1;
        end if;
        if r.ahbc(1).hwrite = '0' then
          v.hready := '1';
        end if;
        if r.rb = '1' then
          v.tcb := r.cbits;
        end if;
      when rde1 =>
        if r.ahbc(1).hwrite = '0' then
          v.ahbc(1).haddr(abits+1 downto 2) := r.ahbc(1).haddr(abits+1 downto 2) + 1;
        end if;
        if r.decout.err = '1' then
          ce := '1';
          if r.errcnt /= one32(7 downto 0) then
            v.errcnt := r.errcnt + 1;
          end if;
        end if;
        if r.decout.merr = '1' then
          v.state := err; v.hresp := HRESP_ERROR;
          hready := '0'; v.hready := '0';
        else
          if r.ahbc(1).hwrite = '1' then  --subword write go to write state
            v.state := idle; v.wdata := r.decout.data(31 downto 0); v.wren := '1';
            if v.hsel = '1' then
              if ahbsi.hwrite = '0' then --single access
                v.state := wr2rd; 
              else
                v.state := wr; v.hready := '1';
                v.ahbc(0).hwrite := ahbsi.hwrite;
                v.ahbc(0).haddr  := ahbsi.haddr(abits+1 downto 0);
                v.ahbc(0).hsize  := ahbsi.hsize(1 downto 0);
                v.ahbc(0).htrans := ahbsi.htrans;
              end if;
            else
              v.state := idle; v.hready := '1';
            end if;
            v.hready := '1';
            if r.ahbc(1).hsize(0) = '1' then
              if r.ahbc(1).haddr(1) = '1' then
                v.wdata(15 downto 0) := hwdata(15 downto 0);                
              else
                v.wdata(31 downto 16) := hwdata(31 downto 16);
              end if;
            else
              --ghdl cannot handle the case statement without the variable
              --haddrtmp
              haddrtmp := r.ahbc(1).haddr(1 downto 0);  
              case haddrtmp is
                when "00" =>
                  v.wdata(31 downto 24) := hwdata(31 downto 24);
                when "01" =>
                  v.wdata(23 downto 16) := hwdata(23 downto 16);
                when "10" =>
                  v.wdata(15 downto 8) := hwdata(15 downto 8);
                when "11" =>
                  v.wdata(7 downto 0) := hwdata(7 downto 0); 
                when others =>
                  null;
              end case;
            end if;
          else  
            if v.hsel = '1' then
              if (ahbsi.hwrite = '0') then
                --single access followed by single access zero wait state
                --special case
                v.ahbc(1).htrans := ahbsi.htrans;
                v.ahbc(1).hsize  := ahbsi.hsize(1 downto 0);
                v.ahbc(1).hwrite := ahbsi.hwrite;
                if ahbsi.htrans(0) = '0' then
                  if r.ahbc(1).htrans(0) = '0' then
                    v.state := rds; v.hready := '1';
                    if r.rb = '1' then
                      v.tcb := r.cbits;
                    end if;
                  else
                    v.state := rd0; v.hready := '0';
                    v.ahbc(1).haddr  := ahbsi.haddr(abits+1 downto 0);
                  end if;
                else
                  if r.rb = '1' then
                    v.tcb := r.cbits;
                  end if;
                end if;
              else
                if ahbsi.hsize /= HSIZE_WORD then
                  v.state := rd0; v.hready := '0';
                  v.ahbc(1).hwrite := ahbsi.hwrite;
                  v.ahbc(1).haddr  := ahbsi.haddr(abits+1 downto 0);
                  v.ahbc(1).hsize  := ahbsi.hsize(1 downto 0);
                  v.ahbc(1).htrans := ahbsi.htrans;
                else
                  v.state := wr; v.hready := '1';
                  v.ahbc(0).hwrite := ahbsi.hwrite;
                  v.ahbc(0).haddr  := ahbsi.haddr(abits+1 downto 0);
                  v.ahbc(0).hsize  := ahbsi.hsize(1 downto 0);
                  v.ahbc(0).htrans := ahbsi.htrans;
                end if;
              end if;
            else
              v.state := idle; v.hready := '1';
            end if;
          end if;
        end if;
      when rds =>  --second consecutive single read
        if r.ahbc(1).hwrite = '0' then
          v.ahbc(1).haddr(abits+1 downto 2) := r.ahbc(1).haddr(abits+1 downto 2) + 1;
        end if;
        if r.decout.err = '1' then
          ce := '1';
          if r.errcnt /= one32(7 downto 0) then
            v.errcnt := r.errcnt + 1;
          end if;
        end if;
        if r.decout.merr = '1' then
          v.state := err; v.hresp := HRESP_ERROR;
          hready := '0'; v.hready := '0';
        else
          if v.hsel = '1' then
            if ahbsi.hwrite = '0' then --single access
              v.state := rd0; v.hready := '0';
              v.ahbc(1).hwrite := ahbsi.hwrite;
              v.ahbc(1).haddr  := ahbsi.haddr(abits+1 downto 0);
              v.ahbc(1).hsize  := ahbsi.hsize(1 downto 0);
              v.ahbc(1).htrans := ahbsi.htrans;
            else
              if ahbsi.hsize /= HSIZE_WORD then
                v.state := rd0; v.hready := '0';
                v.ahbc(1).hwrite := ahbsi.hwrite;
                v.ahbc(1).haddr  := ahbsi.haddr(abits+1 downto 0);
                v.ahbc(1).hsize  := ahbsi.hsize(1 downto 0);
                v.ahbc(1).htrans := ahbsi.htrans;
              else
                v.state := wr; v.hready := '1';
                v.ahbc(0).hwrite := ahbsi.hwrite;
                v.ahbc(0).haddr  := ahbsi.haddr(abits+1 downto 0);
                v.ahbc(0).hsize  := ahbsi.hsize(1 downto 0);
                v.ahbc(0).htrans := ahbsi.htrans;
              end if;
            end if;
          else
            v.state := idle; v.hready := '1';
          end if;
        end if;
      when err =>  --Multiple error detected when reading data
        v.state := idle; v.hresp := HRESP_ERROR;
        v.hready := '1';
      when others =>
        null;
    end case;
            
    ----------------------------------------------------------------------------
    --APB interface
    ----------------------------------------------------------------------------
    if (apbi.psel(pindex) and apbi.penable and apbi.pwrite) = '1' then
      --write transfers
      v.errcnt := r.errcnt and not apbi.pwdata(20 downto 13);
      v.diag   := apbi.pwdata(31 downto 30);
      v.wb     := apbi.pwdata(9);
      v.rb     := apbi.pwdata(8);
      v.en     := apbi.pwdata(7);
      v.tcb    := apbi.pwdata(6 downto 0);
    end if;    

    --read transfers
    prdata := (others => '0');
    prdata(27 downto 24) := conv_std_logic_vector(edacen, 4);
    prdata(23 downto 21) := conv_std_logic_vector(memsize, 6)(5 downto 3);
    prdata(20 downto 13) := r.errcnt;
    prdata(12 downto 10) := conv_std_logic_vector(memsize, 6)(2 downto 0);
    prdata(9) := r.wb;
    prdata(8) := r.rb;
    prdata(7) := r.en;
    prdata(6 downto 0) := r.tcb;
    prdata(31 downto 30) := r.diag;

    ---------------------------------------------------------------------------- 
    --Reset
    ----------------------------------------------------------------------------
    if rst = '0' then
      v.hready := '1'; v.state := idle; v.en := '0'; v.rb := '0'; v.wb := '0';
      v.errcnt := (others => '0'); v.ramsel := '0';
      v.diag := (others => '0');
      v.tcb := (others => '0');
    end if;

    ---------------------------------------------------------------------------- 
    --Signal assignments from process variables
    ----------------------------------------------------------------------------
    apbo.prdata  <= prdata;
    ahbso.hready <= r.hready and hready;
    cbin         <= vcbin;
    aramo.ce     <= ce;
    
    rin          <= v;
  end process;

  ---------------------------------------------------------------------------- 
  --Signal assignments from constants and other signals
  ----------------------------------------------------------------------------
  apbo.pindex   <= pindex;
  apbo.pconfig  <= pconfig;
  apbo.pirq     <= (others => '0');
  
  ahbso.hsplit  <= (others => '0'); 
  ahbso.hirq    <= (others => '0');
  ahbso.hconfig <= hconfig;
  ahbso.hindex  <= hindex;
  ahbso.hrdata  <= ahbdrivedata(r.decout.data(31 downto 0));
  ahbso.hresp   <= r.hresp;
  
  ramsel        <= r.ramsel;
  ramaddr       <= r.ahbc(1).haddr(abits + 1 downto 2);
    
  -- Syncram
  gen : if edacen = 1 generate
    ramdin <= cbin & r.wdata;
    ramdata <= ramdout(31 downto 0);
    cbout <= ramdout(38 downto 32);
    error <= (others => '0');
    sramgen : syncram generic map (tech, abits, 39, testen)
      port map(clk, ramaddr, ramdin, ramdout, ramsel, r.wren, testin);
  end generate;
  -- Use SECDED EDAC provided by SYNCRAMFT.
  -- edacen = 2 -> Technology agnostic BCH
  -- edacen = 3 -> Technology specific SECDED
  techspec : if edacen > 1 generate
    ramdin <= (others => '0');
    ramdout <= (others => '0');
    cbout <= (others => '0');
    ram : syncramft generic map(tech, abits, 32, 2+edacen, testen)
      port map (clk, ramaddr, r.wdata, ramdata, r.wren, ramsel, error, testin, cbin);
  end generate;

  reg : process (clk)
  begin
    if rising_edge(clk) then r <= rin; end if;
  end process;

-- pragma translate_off
    bootmsg : report_version 
    generic map ("ahbram" & tost(hindex) &
    ": FT AHB SRAM Module rev 2, " & tost(kbytes) & " kbytes");
-- pragma translate_on
end;

