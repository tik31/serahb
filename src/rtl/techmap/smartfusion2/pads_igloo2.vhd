------------------------------------------------------------------------------
--  This file is a part of the GRLIB VHDL IP LIBRARY
--  Copyright (C) 2017, Cobham Gaisler AB - all rights reserved.
--
-- ANY USE OR REDISTRIBUTION IN PART OR IN WHOLE MUST BE HANDLED IN 
-- ACCORDANCE WITH THE GAISLER LICENSE AGREEMENT AND MUST BE APPROVED 
-- IN ADVANCE IN WRITING. 
-----------------------------------------------------------------------------
-- File:	pads_igloo2.vhd
-- Author:	Pascal Trotta
-- Description:	IGLOO2 pad wrappers
------------------------------------------------------------------------------

-- pragma translate_off
library smartfusion2;
use smartfusion2.clkbuf;
-- pragma translate_on
library ieee;
use ieee.std_logic_1164.all;
library techmap;
use techmap.gencomp.all;

entity igloo2_clkpad is
  port (pad : in std_ulogic; o : out std_ulogic);
end; 
architecture rtl of igloo2_clkpad is
  component clkbuf port(pad : in std_ulogic; y : out std_ulogic); end component;
begin
  cp : clkbuf port map (pad => pad, y => o);    
end;

-- pragma translate_off
library smartfusion2;
use smartfusion2.clkbuf_diff;
-- pragma translate_on
library ieee;
use ieee.std_logic_1164.all;
library techmap;
use techmap.gencomp.all;

entity igloo2_clkpad_ds is
  port (padp, padn : in std_ulogic; o : out std_ulogic);
end; 
architecture rtl of igloo2_clkpad_ds is
  component clkbuf_diff port(padp, padn : in std_ulogic; y : out std_ulogic); end component;
begin
  cp : clkbuf_diff port map(padp => padp, padn => padn, y => o);  
end;

-- pragma translate_off
library smartfusion2;
use smartfusion2.inbuf;
-- pragma translate_on
library ieee;
use ieee.std_logic_1164.all;
library techmap;
use techmap.gencomp.all;

entity igloo2_inpad is
  port (pad : in std_ulogic; o : out std_ulogic);
end; 
architecture rtl of igloo2_inpad is
  component inbuf port(pad : in std_ulogic; y : out std_ulogic); end component;
begin
  ip : inbuf port map (pad => pad, y => o);
end;

-- pragma translate_off
library smartfusion2;
use smartfusion2.inbuf_diff;
-- pragma translate_on
library ieee;
use ieee.std_logic_1164.all;
library techmap;
use techmap.gencomp.all;

entity igloo2_inpad_ds is
  port (padp, padn : in std_ulogic; o : out std_ulogic);
end;
architecture rtl of igloo2_inpad_ds is 
  component inbuf_diff port(padp, padn : in std_ulogic; y : out std_ulogic); end component;
begin
  ip: inbuf_diff port map (y => o, padp => padp, padn => padn);
end;

-- pragma translate_off
library smartfusion2;
use smartfusion2.bibuf;
-- pragma translate_on
library ieee;
use ieee.std_logic_1164.all;
library techmap;
use techmap.gencomp.all;

entity igloo2_iopad  is
  port (pad : inout std_ulogic; i, en : in std_ulogic; o : out std_ulogic);
end ;
architecture rtl of igloo2_iopad is
  component bibuf port(d, e : in std_ulogic; pad : inout std_ulogic; y : out std_ulogic); end component;
begin
  iop : bibuf port map (d => i, e => en, pad => pad, y => o);
end;

-- pragma translate_off
library smartfusion2;
use smartfusion2.bibuf_diff;
-- pragma translate_on
library ieee;
use ieee.std_logic_1164.all;
library techmap;
use techmap.gencomp.all;

entity igloo2_iopad_ds  is
  port (padp, padn : inout std_ulogic; i, en : in std_ulogic; o : out std_ulogic);
end ;
architecture rtl of igloo2_iopad_ds is
  component bibuf_diff port(d, e : in std_ulogic; padp, padn : inout std_ulogic; y : out std_ulogic); end component;
begin
  iop : bibuf_diff port map (d => i, e => en, padp => padp, padn => padn, y => o);
end;

-- pragma translate_off
library smartfusion2;
use smartfusion2.outbuf;
-- pragma translate_on
library ieee;
use ieee.std_logic_1164.all;
library techmap;
use techmap.gencomp.all;

entity igloo2_outpad  is
  port (pad : out std_ulogic; i : in std_ulogic);
end ;
architecture rtl of igloo2_outpad is
  component outbuf port(d : in std_ulogic; pad : out std_ulogic); end component;
begin
  op : outbuf port map (d => i, pad => pad);
end;

-- pragma translate_off
library smartfusion2;
use smartfusion2.outbuf_diff;
-- pragma translate_on
library ieee;
use ieee.std_logic_1164.all;
library techmap;
use techmap.gencomp.all;

entity igloo2_outpad_ds is
  port (padp, padn : out std_ulogic; i : in std_ulogic);
end;
architecture rtl of igloo2_outpad_ds is
  component outbuf_diff port(d : in std_ulogic; padp, padn : out std_ulogic); end component;
begin
  op: outbuf_diff port map (d => i, padp => padp, padn => padn);
end;

-- pragma translate_off
library smartfusion2;
use smartfusion2.tribuff;
-- pragma translate_on
library ieee;
use ieee.std_logic_1164.all;
library techmap;
use techmap.gencomp.all;

entity igloo2_toutpad  is
  port (pad : out std_ulogic; i, en : in std_ulogic);
end ;
architecture rtl of igloo2_toutpad is
  component tribuff port(d, e : in std_ulogic; pad : out std_ulogic); end component;
begin
  top : tribuff port map (d => i, e => en, pad => pad);
end;

-- pragma translate_off
library smartfusion2;
use smartfusion2.tribuff_diff;
-- pragma translate_on
library ieee;
use ieee.std_logic_1164.all;
library techmap;
use techmap.gencomp.all;

entity igloo2_toutpad_ds  is
  port (padp, padn : out std_ulogic; i, en : in std_ulogic);
end ;
architecture rtl of igloo2_toutpad_ds is
  component tribuff_diff port(d, e : in std_ulogic; padp, padn : out std_ulogic); end component;
begin
  top : tribuff_diff port map (d => i, e => en, padp => padp, padn => padn);
end;
