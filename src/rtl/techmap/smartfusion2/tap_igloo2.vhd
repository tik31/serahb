------------------------------------------------------------------------------
--  This file is a part of the GRLIB VHDL IP LIBRARY
--  Copyright (C) 2017, Cobham Gaisler AB - all rights reserved.
--
-- ANY USE OR REDISTRIBUTION IN PART OR IN WHOLE MUST BE HANDLED IN 
-- ACCORDANCE WITH THE GAISLER LICENSE AGREEMENT AND MUST BE APPROVED 
-- IN ADVANCE IN WRITING. 
-----------------------------------------------------------------------------   
-- Entity:      igloo2_tap
-- File:        tap_igloo2.vhd
-- Author:      Pascal Trotta
-- Description: Microsemi IGLOO2 TAP controller wrapper
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
-- pragma translate_off
library smartfusion2;
use smartfusion2.UJTAG;
-- pragma translate_on

entity igloo2_tap is
  port (
    tck         : in std_ulogic;
    tms         : in std_ulogic;
    tdi         : in std_ulogic;
    trst        : in std_ulogic;
    tdo         : out std_ulogic;                    
    tapi_tdo    : in std_ulogic;
    tapo_tck    : out std_ulogic;
    tapo_tdi    : out std_ulogic;
    tapo_rst    : out std_ulogic;
    tapo_capt   : out std_ulogic;
    tapo_shft   : out std_ulogic;
    tapo_upd    : out std_ulogic;
    tapo_inst   : out std_logic_vector(7 downto 0));
end;

architecture rtl of igloo2_tap is

  component UJTAG
    port(
      UIREG : out std_logic_vector(7 downto 0);
      URSTB : out std_ulogic;
      UDRCK : out std_ulogic;
      UTDI : out std_ulogic;
      UDRCAP : out std_ulogic;
      UDRSH : out std_ulogic;
      UDRUPD : out std_ulogic;
      UTDO : in std_ulogic;
      TRSTB : in std_ulogic;
      TDO : out std_ulogic;
      TDI : in std_ulogic;
      TMS : in std_ulogic;
      TCK : in std_ulogic);
  end component;  

 signal rsti : std_ulogic;
 
begin

  tapo_rst <= not rsti; 
  
  u0 : UJTAG port map (
    UTDO    => tapi_tdo,
    TMS     => tms,       
    TDI     => tdi,       
    TCK     => tck,       
    TRSTB   => trst,       
    UIREG  => tapo_inst,   
    UTDI    => tapo_tdi,       
    URSTB   => rsti,        
    UDRCK   => tapo_tck,        
    UDRCAP  => tapo_capt,      
    UDRSH   => tapo_shft,        
    UDRUPD  => tapo_upd,       
    TDO     => tdo);       

end;

