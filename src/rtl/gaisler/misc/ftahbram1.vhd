------------------------------------------------------------------------------
--  This file is a part of the GRLIB VHDL IP LIBRARY
--  Copyright (C) 2017, Cobham Gaisler AB - all rights reserved.
--
-- ANY USE OR REDISTRIBUTION IN PART OR IN WHOLE MUST BE HANDLED IN 
-- ACCORDANCE WITH THE GAISLER LICENSE AGREEMENT AND MUST BE APPROVED 
-- IN ADVANCE IN WRITING. 
-----------------------------------------------------------------------------
-- Entity:      ftahbram1
-- File:        ftahbram1.vhd
-- Author:      Marko Isomaki - Gaisler Research
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

entity ftahbram1 is
  generic (
    hindex    : integer := 0;
    haddr     : integer := 0;
    hmask     : integer := 16#fff#;
    tech      : integer := DEFMEMTECH; 
    kbytes    : integer := 1;
    pindex    : integer := 0;
    paddr     : integer := 0;
    pmask     : integer := 16#fff#;
    edacen    : integer range 0 to 3 := 1;  --enable EDAC: 1 AHBRAM EDAC, 2:
                                            --SYNCRAMFT(BCH), 3: SYNCRAMFT(TECHSPEC)
    autoscrub : integer range 0 to 1 := 0;  --enable auto-scrubbing    
    errcnten  : integer range 0 to 1 := 0;  --enable error counter in stat.reg
    cntbits   : integer range 1 to 8 := 1; --errcnt size in bits
    ahbpipe   : integer range 0 to 1 := 0;
    testen    : integer := 0);
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

architecture rtl of ftahbram1 is

constant abits : integer := log2(kbytes) + 8;

constant memsize : integer := log2(kbytes);
  
constant hconfig : ahb_config_type := (
  0 => ahb_device_reg ( VENDOR_GAISLER, GAISLER_FTAHBRAM, 0, abits+2, 0),
  4 => ahb_membar(haddr, '1', '1', hmask),
  others => zero32);

constant pconfig : apb_config_type := (
  0 => ahb_device_reg ( VENDOR_GAISLER, GAISLER_FTAHBRAM, 0, abits+2, 0),
  1 => apb_iobar(paddr, pmask));

constant zeroerrcnt : std_logic_vector(cntbits - 1 downto 0) := (others => '0');
constant maxerrcnt  : std_logic_vector(cntbits - 1 downto 0) := (others => '1');

type pipe_reg_type is record
  hwrite  : std_logic;
  hready  : std_logic;
  phready : std_logic;
  hsel    : std_logic_vector(0 to NAHBSLV-1);
  htrans  : std_logic_vector(1 downto 0);
  haddr   : std_logic_vector(abits+1 downto 0);
  hsize   : std_logic_vector(1 downto 0);
  hwdata  : std_logic_vector(31 downto 0);
  stage   : std_logic_vector(1 downto 0);
end record;

type reg_type is record
  --AHB Slave interface 
  hwrite  : std_ulogic; 
  hready  : std_ulogic; 
  hsel    : std_ulogic;
  addr    : std_logic_vector(abits+1 downto 0);
  size    : std_logic_vector(1 downto 0);
  --APB Interface
  en      : std_ulogic; --edac enable
  wb      : std_ulogic; --write bypass
  rb      : std_ulogic; --read bypass
  tcb     : std_logic_vector(6 downto 0); --test checkbits
  errcnt  : std_logic_vector(cntbits - 1 downto 0); --error counter
  --Internal state
  dhwrite : std_ulogic; --delayed hwrite
  ahready : std_ulogic; --registered ahbsi.hready delayed one period
  merrcnt : std_ulogic; --hresp=err 2 cycle counter
  bhwrite : std_ulogic; --read or bhwrite. used with stage  
  stage   : std_logic_vector(1 downto 0); --decode stage
  decout  : edacdectype; --output from edac decoder in decode stage
  ascrub  : std_ulogic; --autoscrub done previous cycle
  p       : pipe_reg_type;
  diag    : std_logic_vector(1 downto 0); --test checkbits
  
end record;

signal r, c     : reg_type;
signal ramsel   : std_ulogic;
signal write    : std_logic_vector(3 downto 0);
signal ramaddr  : std_logic_vector(abits-1 downto 0);
signal ramdata  : std_logic_vector(31 downto 0);
signal cbwrite  : std_ulogic;
signal cbin     : std_logic_vector(6 downto 0);
signal cbout    : std_logic_vector(6 downto 0);
signal wdata    : std_logic_vector(31 downto 0);
signal testin   : std_logic_vector(3 downto 0);
signal error    : std_logic_vector(1 downto 0);

begin

  testin <= ahbsi.testen & '0' & r.diag;

  comb : process (ahbsi, r, rst, ramdata, apbi, cbout, error)
  variable v      : reg_type;        
  variable bs     : std_logic_vector(3 downto 0); --byte select
  variable haddr  : std_logic_vector(abits-1 downto 0);--ahb address
  variable syn    : std_logic_vector(6 downto 0); --syndrome in read stage
  variable vhresp : std_logic_vector(1 downto 0); --hresp for the AHB interface
  variable vcbin  : std_logic_vector(6 downto 0); --checkbits to RAM
  variable prdata : std_logic_vector(31 downto 0); --apb read data
  variable vwdata : std_logic_vector(31 downto 0); --write data
  variable hready   : std_ulogic; --hready signal used during mult.err
  variable vcbwrite : std_ulogic; --checkbits write signal
  variable cbauto   : std_ulogic; --checkbits write signal for autoscrub
  variable vce      : std_ulogic; --notify single error to ahbstat
  variable vp     : pipe_reg_type;
  begin
    v := r; 
    
    vp.hready := ahbsi.hready;
    vp.hsel := ahbsi.hsel;
    vp.htrans := ahbsi.htrans;
    vp.hwrite := ahbsi.hwrite;
    vp.haddr := ahbsi.haddr(abits+1 downto 0); 
    vp.hsize := ahbsi.hsize(1 downto 0);
    vp.hwdata := ahbreadword(ahbsi.hwdata);
    v.p.phready := '1';
    
    v.hready := '1'; bs := (others => '0'); vce := '0';
    vhresp := "00"; vwdata := vp.hwdata; vcbwrite := '0'; hready := '1';
    prdata := (others => '0'); cbauto := '0';  vcbin := (others => '0');
    v.stage(1) := r.stage(0); v.stage(0) := '0'; v.ascrub := '0';
    syn := (others => '0');

    --AHB Slave interface
    if vp.hready = '1' then 
      v.hsel := vp.hsel(hindex) and vp.htrans(1);
      v.hwrite := vp.hwrite and v.hsel;
      v.addr := vp.haddr(abits+1 downto 0); 
      v.size := vp.hsize(1 downto 0);
      v.dhwrite := r.hwrite;
    end if;
    
    if r.hwrite = '1' then
      case r.size(1 downto 0) is
      when "00" => bs (conv_integer(r.addr(1 downto 0))) := '1';
      when "01" => bs := r.addr(1) & r.addr(1) & not (r.addr(1) & r.addr(1));
      when others => bs := (others => '1');
      end case;
      v.hready := not (v.hsel and not vp.hwrite);  
    end if;

    --Control functions needed when EDAC is enabled
    if (edacen > 1) or (edacen = 1 and r.en = '1') then
      if vp.hready = '0' then v.hready := '1'; end if;
      --delayed hready
      v.ahready := vp.hready and vp.hsel(hindex);
      --byte/halfword and read control
      if (vp.hready and v.hsel) = '1' then
      	v.hready := (v.hwrite and v.size(1)) or r.stage(0);
      end if;
      if r.ahready = '1' then
        v.bhwrite := (not r.size(1)) and r.hwrite and (not r.hready);
	if ((not r.hwrite or v.bhwrite) and r.hsel and not r.hready) = '1' then
	  if not (r.dhwrite or r.ascrub) = '1' then
	    v.stage(1) := '1';
          else
	    v.stage(0) := '1';
	  end if;
	end if;
      end if;
      --second consecutive read 
      if (vp.hsel(hindex) and
	  not vp.hwrite and vp.htrans(1) and not v.bhwrite) = '1' then
	if (v.stage(1) and not r.stage(1)) = '1' then
	  v.stage(0) := '1';
	end if;
      end if;
      --read diagonostics. store checkbits in tcb
      if edacen = 1 then                -- not supported for tech spec EDAC
        if (r.rb and v.stage(1)) = '1' then
          v.tcb := cbout;
        end if;
      end if;
      --not ready if not second consecutive read or byte/halfword write
      if (r.stage(0) and not r.stage(1)) = '1' then
        hready := '0'; 
      end if;
      --uncorrectable error detected
      if ( (r.decout.merr and r.stage(1)) or r.merrcnt ) = '1' then
        hready := r.merrcnt; vhresp(0) := '1';
        v.merrcnt := not r.merrcnt;
      end if;
    end if;

    if (r.hwrite or (not r.hready and not v.stage(1))) = '1' then
      haddr := r.addr(abits+1 downto 2);
    else
      haddr := vp.haddr(abits+1 downto 2); 
    end if;

    --EDAC
    if edacen /= 0 then
      --select indata to syncram
      if r.bhwrite = '1' then
        vwdata := r.decout.data(31 downto 0);
        if bs(0) = '1' then
          vwdata(31 downto 24) := vp.hwdata(31 downto 24);
        end if;
        if bs(1) = '1' then
          vwdata(23 downto 16) := vp.hwdata(23 downto 16);
        end if;
        if bs(2) = '1' then
          vwdata(15 downto 8)  := vp.hwdata(15 downto 8);
        end if;
        if bs(3) = '1' then
          vwdata(7 downto 0)   := vp.hwdata(7 downto 0);
        end if;
      end if;
      --mask bs vector
      if (edacen > 1) or (r.en = '1') then
        if (not(r.stage(1) and not r.decout.merr) and not r.size(1)) = '1' then
          bs := (others => '0');
        elsif (r.bhwrite and r.stage(1)) = '1' then
	  bs := (others => '1');
        end if;
      end if;
      --autoscrubbing
      if autoscrub = 1 then
        if (r.decout.err and r.stage(1) and not r.bhwrite) = '1' then
          cbauto := '1'; vwdata := r.decout.data(31 downto 0); bs := (others => '1');
	  haddr := r.addr(abits+1 downto 2); 
          --extra waitstate if bhwrite or not second consecutive read after
	  if (not (v.stage(1) or (v.hwrite and v.size(1))) ) = '1' then
	    v.hready := '0';
	    v.ascrub := '1';
	  end if;
	end if;
      end if;
      if edacen = 1 then                -- AHBRAM EDAC
        --write encode stage(calculate checkbits)
        vcbin := edacencode(vwdata);
        --read stage
        syn := edacsyngen(ramdata, cbout); --syndrome calculation
        v.decout := edacdecode(ramdata, syn); --decoder
        --set checkbits write signal
        vcbwrite := (r.hwrite and r.hready and r.size(1)) or
                    (r.stage(1) and r.bhwrite and not r.decout.merr) or cbauto;
      end if;
      --write diagnostics. select external checkbits
      if r.wb = '1' then vcbin := r.tcb; end if;
      if edacen = 2 or edacen = 3 then                -- tech specific EDAC
        v.decout.data(63 downto 32) := (others => '0');
        v.decout.data(31 downto 0) := ramdata;
        v.decout.err := error(0) and not error(1);
        v.decout.merr := error(1);
      end if;
    end if;

   --Single error counter
   if edacen /= 0 then 
     if (r.decout.err and r.stage(1)) = '1' then
       vce := '1'; --notify ahbstat about single error
       if r.errcnt /= maxerrcnt and errcnten = 1 then
	 v.errcnt := r.errcnt + 1;
       end if;
     end if;
   end if;
    
   --APB interface
   if edacen /= 0 then
     if (apbi.psel(pindex) and apbi.penable and apbi.pwrite) = '1' then
       --write transfers
       if errcnten = 1 then
	 v.errcnt := r.errcnt and not apbi.pwdata(cntbits + 12 downto 13);
       end if;
       if edacen = 1 then
         v.diag   := apbi.pwdata(31 downto 30);
         v.rb     := apbi.pwdata(8);
         v.en     := apbi.pwdata(7);
       end if;
       v.wb     := apbi.pwdata(9);
       v.tcb    := apbi.pwdata(6 downto 0);
     end if;    
     --read transfers
     prdata(27 downto 24) := conv_std_logic_vector(edacen, 4);
     if errcnten = 1 then
       --single error counter
       prdata(cntbits + 12 downto 13) := r.errcnt;
     end if;
     prdata(12 downto 10) := conv_std_logic_vector(memsize,3);
     prdata(9) := r.wb;
     prdata(8) := r.rb;
     if edacen < 2 then
       prdata(7) := r.en;
     else
       prdata(7) := '1';
     end if;
     prdata(6 downto 0) := r.tcb;
     prdata(31 downto 30) := r.diag;
   end if;

   if edacen < 2 and r.en = '1' and v.en = '0' then v.hready := '1'; end if;

   --Reset and signal declarations
    if rst = '0' then
      v.hwrite := '0'; v.hready := '1';
      if edacen /= 0 then
        v.merrcnt := '0'; v.bhwrite := '0'; v.en := '0'; v.rb := '0';
	v.stage := "00"; v.ahready := '0'; v.wb := '0'; v.dhwrite := '0';
      end if;
      if errcnten = 1 and edacen /= 0 then
	v.errcnt := (others => '0');
      end if;
    end if;

    write <= bs; ramsel <= v.hsel or r.hwrite or r.hsel;
    ramaddr <= haddr; c <= v; wdata <= vwdata; 
    ahbso.hready <= r.hready and hready and r.p.phready; ahbso.hresp <= vhresp; 

    cbin <= vcbin;
    if edacen = 1 then
      cbwrite <= vcbwrite;
    end if;

    if edacen > 1 then
      v.en     := '1';
      v.diag   := (others => '0');
      v.rb     := '0';
    end if;
    
    if (edacen > 1) or (edacen = 1 and r.en = '1') then ahbso.hrdata <= ahbdrivedata(r.decout.data(31 downto 0));
    else ahbso.hrdata <= ahbdrivedata(ramdata); end if;

    apbo.prdata <= prdata;
    apbo.pirq   <= (others => '0');

    aramo.ce <= vce;
  end process;
  
  apbo.pindex   <= pindex;
  apbo.pconfig  <= pconfig;
  
  ahbso.hsplit  <= (others => '0'); 
  ahbso.hirq    <= (others => '0');
  ahbso.hconfig <= hconfig;
  ahbso.hindex  <= hindex;

  -- Generic, technology agnostic implementation of EDAC in FTAHBRAM
  gen : if edacen < 2 generate
    --Syncram
    ra : for i in 0 to 3 generate
      aram : syncram generic map (tech, abits, 8, testen) port map (
        clk, ramaddr, wdata(i*8+7 downto i*8),
        ramdata(i*8+7 downto i*8), ramsel, write(3-i), testin); 
    end generate;
  
    --Syncram for checkbits
    re : if edacen = 1 generate
      cbram : syncram generic map (tech, abits, 7, testen) port map(
        clk, ramaddr, cbin, cbout, ramsel, cbwrite, testin);
    end generate;
    error <= (others => '0');
  end generate;
  -- Use SECDED EDAC provided by SYNCRAMFT.
  -- edacen = 2 -> Technology agnostic BCH
  -- edacen = 3 -> Technology specific SECDED
  techspec : if edacen > 1 generate
    ram : syncramft generic map(tech, abits, 32, 2+edacen, testen)
      port map (clk, ramaddr, wdata, ramdata, write(0), ramsel, error, testin, cbin);
    cbout <= (others => '0');
  end generate;

    
  reg : process (clk)
  begin
    if rising_edge(clk) then r <= c; end if;
  end process;

-- pragma translate_off
    bootmsg : report_version 
    generic map ("ftahbram" & tost(hindex) &
    ": FT AHB SRAM Module rev 0, " & tost(kbytes) & " kbytes");
-- pragma translate_on

-- pragma translate_off
  gencheck : process
  begin
    assert ahbpipe = 0 report "FTAHBRAM: ahbpipe /= 0 not supported. Use FTAHBRAM2 instead."
      severity failure;
    wait;
  end process;
-- pragma translate_on

end;

