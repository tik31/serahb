------------------------------------------------------------------------------
--  This file is a part of the GRLIB VHDL IP LIBRARY
--  Copyright (C) 2017, Cobham Gaisler AB - all rights reserved.
--
-- ANY USE OR REDISTRIBUTION IN PART OR IN WHOLE MUST BE HANDLED IN 
-- ACCORDANCE WITH THE GAISLER LICENSE AGREEMENT AND MUST BE APPROVED 
-- IN ADVANCE IN WRITING. 
-----------------------------------------------------------------------------
-- Package: 	util
-- File:	util.vhd
-- Author:	Jiri Gaisler, Gaisler Research
-- Description:	Misc utilities
------------------------------------------------------------------------------

-- pragma translate_off

library ieee;
use ieee.std_logic_1164.all;
library grlib;
use grlib.stdlib.all;

entity report_version is
  generic (msg1, msg2, msg3, msg4 : string := ""; mdel : integer := 4);
end;

architecture beh of report_version is
begin

  x : process
  
  begin
    wait for mdel * 1 ns;
    if (msg1 /= "") then print(msg1); end if;
    if (msg2 /= "") then print(msg2); end if;
    if (msg3 /= "") then print(msg3); end if;
    if (msg4 /= "") then print(msg4); end if;
    wait;
  end process;
end;


library ieee;
use ieee.std_logic_1164.all;
library grlib;
use grlib.stdlib.all;

entity report_design is
  generic (msg1, fabtech, memtech : string := ""; mdel : integer := 4);
end;

architecture beh of report_design is
begin

  x : report_version
    generic map (
      msg1 => msg1,
      msg2 => "GRLIB Version " & tost(LIBVHDL_VERSION/1000) & "." & tost((LIBVHDL_VERSION mod 1000)/100)
      & "." & tost(LIBVHDL_VERSION mod 100) & ", build " & tost(LIBVHDL_BUILD),
      msg3 => "Target technology: " & fabtech & ", memory library: " & memtech,
      mdel => mdel);

end;

-- pragma translate_on

