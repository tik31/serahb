------------------------------------------------------------------------------
--  This file is a part of the GRLIB VHDL IP LIBRARY
--  Copyright (C) 2017, Cobham Gaisler AB - all rights reserved.
--
-- ANY USE OR REDISTRIBUTION IN PART OR IN WHOLE MUST BE HANDLED IN 
-- ACCORDANCE WITH THE GAISLER LICENSE AGREEMENT AND MUST BE APPROVED 
-- IN ADVANCE IN WRITING. 
-----------------------------------------------------------------------------
-- Entity: 	grgpreg
-- File:	grgpreg.vhd
-- Author:	Kristoffer Glembo - Aeroflex Gaisler
-- Description:	General purpose register
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library grlib;
use grlib.amba.all;
use grlib.stdlib.all;
use grlib.devices.all;
library gaisler;
use gaisler.misc.all;
--pragma translate_off
use std.textio.all;
--pragma translate_on

entity grgpreg is
    generic (
        pindex   : integer := 0;
        paddr    : integer := 0;
        pmask    : integer := 16#fff#;
        nbits    : integer range 1 to 64 := 16;
        rstval   : integer := 0;
        rstval2  : integer := 0;
        extrst   : integer := 0
        );
    port (
        rst    : in  std_ulogic;
        clk    : in  std_ulogic;
        apbi   : in  apb_slv_in_type;
        apbo   : out apb_slv_out_type;
        gprego : out std_logic_vector(nbits-1 downto 0);
        resval : in  std_logic_vector(nbits-1 downto 0) := (others => '0')
        );
end;

architecture rtl of grgpreg is

    constant REVISION : integer := 0;


    constant pconfig : apb_config_type := (
        0 => ahb_device_reg (VENDOR_GAISLER, GAISLER_GPREG, 0, REVISION, 0),
        1 => apb_iobar(paddr, pmask));

    type registers is record
          reg  	:  std_logic_vector(nbits-1 downto 0);
    end record;

    signal r, rin : registers;

begin

    comb : process(rst, r, apbi, resval)
        variable readdata : std_logic_vector(31 downto 0);
        variable v        : registers;
    begin

	v := r;
-- read register

        readdata := (others => '0');
        case apbi.paddr(4 downto 2) is         
            when "000" =>
              if nbits > 32 then
                readdata := r.reg(31 downto 0);
              else
                readdata(nbits-1 downto 0) := r.reg;
              end if;              
            when "001" =>
              if nbits > 32 then
                readdata(nbits-33 downto 0) := r.reg(nbits-1 downto 32);
              end if;              
            when others =>
        end case;

-- write registers

        if (apbi.psel(pindex) and apbi.penable and apbi.pwrite) = '1' then
            case apbi.paddr(4 downto 2) is
                when "000" =>
                  if nbits > 32 then
                    v.reg(31 downto 0) := apbi.pwdata;
                  else
                    v.reg := apbi.pwdata(nbits-1 downto 0);
                  end if;
                when "001" =>
                  if nbits > 32 then
                    v.reg(nbits-1 downto 32) := apbi.pwdata(nbits-33 downto 0);
                  end if;
                when others =>
            end case;
        end if;

        if rst = '0' then
          if extrst = 0 then
            v.reg :=  conv_std_logic_vector(rstval, nbits);
            if nbits > 32 then
              v.reg(nbits-1 downto 32) := conv_std_logic_vector(rstval2, nbits-32);
            end if;
          else
            v.reg := resval;
          end if;
        end if;
        
        rin <= v;

        apbo.prdata <= readdata; 	-- drive apb read bus


    end process;

    gprego <= r.reg;
    apbo.pirq <= (others => '0');
    apbo.pindex <= pindex;
    apbo.pconfig <= pconfig;

-- registers

    regs : process(clk)
    begin
        if rising_edge(clk) then r <= rin; end if;
    end process;

-- boot message

-- pragma translate_off
    bootmsg : report_version
        generic map ("grgpreg" & tost(pindex) &
                     ": " &  tost(nbits) & "-bit GPREG Unit rev " & tost(REVISION));
-- pragma translate_on

end;

