------------------------------------------------------------------------------
--  This file is a part of the GRLIB VHDL IP LIBRARY
--  Copyright (C) 2017, Cobham Gaisler AB - all rights reserved.
--
-- ANY USE OR REDISTRIBUTION IN PART OR IN WHOLE MUST BE HANDLED IN 
-- ACCORDANCE WITH THE GAISLER LICENSE AGREEMENT AND MUST BE APPROVED 
-- IN ADVANCE IN WRITING. 
-----------------------------------------------------------------------------
-- Entity:        sf2ficmst_wrapper
-- File:          sf2ficmst_wrapper.vhd
-- Author:        Pascal Trotta
-- Description:   AHB master wrapper for SmartFusion2/IGLOO2 FIC master interface (for HPDMA / PDMA operations)
-- Limitations:   Support only 32-bit wide bus. Between two consecutive transfers, ahbmi.hgrant must change
--                (i.e., it must not be the default master)
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
library grlib;
use grlib.amba.all;
use grlib.devices.all;
use grlib.stdlib.all;
library gaisler;
use gaisler.misc.all;

entity sf2ficmst_wrapper is
  generic (
    hindex    : integer := 0;
    pindex    : integer := 14; 
    paddr     : integer := 14; -- mapped at 0x8000e000
    pmask     : integer := 16#FFF#; -- 256 B
    vendorid  : integer := VENDOR_ACTEL; 
    deviceid  : integer := ACTEL_FICMST);
  port (
    rstn      : in  std_ulogic;
    clk       : in  std_ulogic;
    ahbmi     : in  ahb_mst_in_type;
    ahbmo     : out ahb_mst_out_type;
    sf2mi     : out sf2_mst_in_type;
    sf2mo     : in  sf2_mst_out_type;
    apbi      : in  apb_slv_in_type;
    apbo      : out apb_slv_out_type;
    dma_ready : out std_logic_vector(1 downto 0));
end sf2ficmst_wrapper;

architecture sf2ficmst_wrapper_rtl of sf2ficmst_wrapper is

  constant REVISION : integer := 1;

  constant hconfig : ahb_config_type := (
    0 => ahb_device_reg (vendorid, deviceid, 0, REVISION, 0),
    others => zero32);

  constant pconfig : apb_config_type := (
    0 => ahb_device_reg (vendorid, deviceid, 0, REVISION, 0),
    1 => apb_iobar(paddr, pmask));

  type fsm_state is (idle, wait_grant, address_phase, data_phase);

  type reg_type is record
    state : fsm_state;
    source : std_logic_vector(31 downto 0);
    destination : std_logic_vector(31 downto 0);
    hwrite : std_logic;
    hsize : std_logic_vector(1 downto 0);
    htrans : std_logic_vector(1 downto 0);
    haddr : std_logic_vector(31 downto 0);
  end record;

  signal regs, regin : reg_type;

begin

  -- AHB master input assignment
  sf2mi.hrdata <= ahbmi.hrdata(31 downto 0);
  sf2mi.hresp <= ahbmi.hresp(0);
  
  -- AHB master output assignment
  ahbmo.hlock <= '0';
  ahbmo.hprot <= (others => '0');
  ahbmo.hirq <= (others => '0');
  ahbmo.hconfig <= hconfig;
  ahbmo.hindex <= hindex;
  ahbmo.hwdata <= ahbdrivedata(sf2mo.hwdata);

  -- APB interface with address register
  apbo.pirq <= (others => '0');
  apbo.pindex <= pindex;
  apbo.pconfig <= pconfig;

  -- AHB master output assignment
  comb: process(sf2mo, ahbmi, apbi, regs)
    variable vhaddr : std_logic_vector(1 downto 0);
    variable readdata, haddr : std_logic_vector(31 downto 0);
    variable regv : reg_type;
  begin
    
    regv := regs;

    ahbmo.hbusreq <= '0';
    ahbmo.hwrite <= '0';
    ahbmo.hsize <= (others=>'0');
    ahbmo.htrans <= (others=>'0');

    sf2mi.hready <= '0';
    dma_ready <= "00";

    haddr := (others=>'0');
   
    case regv.state is
      when idle =>
        if sf2mo.htrans/=HTRANS_IDLE then  -- if FIC master request a transaction
          ahbmo.hbusreq <= '1';
          if (ahbmi.hgrant(hindex)='1') and (ahbmi.hready='1') then -- if FIC master is granted
            regv.state := address_phase;
          else
            regv.state := wait_grant;
          end if;
          -- sample address & control signals
          regv.hwrite := sf2mo.hwrite;
          regv.hsize := sf2mo.hsize;
          regv.htrans := sf2mo.htrans;
          regv.haddr := sf2mo.haddr;
        end if;
        sf2mi.hready <= ahbmi.hready;
        dma_ready <= ahbmi.hready&ahbmi.hready;
        
      when wait_grant => 
        ahbmo.hbusreq <= '1';                 
        if (ahbmi.hgrant(hindex)='1') and (ahbmi.hready='1') then -- if FIC master is granted
          regv.state := address_phase;
        end if;

      when address_phase =>
        if ahbmi.hready='1' then
          regv.state := data_phase;
          ahbmo.hwrite <= regs.hwrite;
          ahbmo.hsize <= '0'&regs.hsize;
          ahbmo.htrans <= regs.htrans;
        end if;
        haddr:=regs.haddr;
        
      when data_phase =>
        if ahbmi.hready='1' then
          if sf2mo.htrans/=HTRANS_IDLE then  -- if FIC master request another transaction
            ahbmo.hbusreq <= '1';
            if (ahbmi.hgrant(hindex)='1') and (ahbmi.hready='1') then -- if FIC master is granted
              regv.state := address_phase;
            else
              regv.state := wait_grant;
            end if;
            -- sample address & control signals
            regv.hwrite := sf2mo.hwrite;
            regv.hsize := sf2mo.hsize;
            regv.htrans := sf2mo.htrans;
            regv.haddr := sf2mo.haddr;
          else
            regv.state := idle;
          end if;
        end if;
        haddr:=regs.haddr;
        -- data received
        sf2mi.hready <= ahbmi.hready;
        dma_ready <= ahbmi.hready&ahbmi.hready;

    end case;

    -- read register
    readdata := (others => '0');
    if (apbi.paddr(2)='0') then         
      readdata := regv.source;
    else
      readdata := regv.destination;
    end if;
    -- write registers
    if (apbi.psel(pindex) and apbi.penable and apbi.pwrite) = '1' then
      if apbi.paddr(2)='0' then
        regv.source := apbi.pwdata;
      else
        regv.destination := apbi.pwdata;
      end if;
    end if;

    apbo.prdata <= readdata;

    --remap haddr for big endian AHB bus compliance
    vhaddr := haddr(1 downto 0);
    if (regs.hsize="01") then
      vhaddr := not(haddr(1))&'0'; -- swap half words
    elsif (regs.hsize="00") then
      vhaddr := not(haddr(1 downto 0)); -- swap bytes
    end if;

    -- select source / destination register
    haddr := regs.source(31 downto 28)&haddr(27 downto 2)&vhaddr;
    if (sf2mo.hwrite='1') then
      haddr := regs.destination(31 downto 28)&haddr(27 downto 2)&vhaddr;
    end if;

    ahbmo.haddr <= haddr;

    regin <= regv;
  
  end process;

  reg: process(clk,rstn)
  begin
    if rstn = '0' then
      regs.source <= (others => '0');
      regs.destination <= (others => '0');
      regs.state <= idle; 
      regs.hwrite <= '0';
      regs.hsize <= (others => '0');
      regs.htrans <= (others => '0');
      regs.haddr <= (others => '0');
    elsif rising_edge(clk) then
      regs <= regin;
    end if;
  end process;

end sf2ficmst_wrapper_rtl;

