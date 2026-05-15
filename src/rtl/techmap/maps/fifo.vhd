-------------------------------------------------------------------------------
--! @file      fifo4k18.vhd
--! @brief     FIFO4K18 compatibility wrapper
--! @details   Only for Proasic technologies
--! @author    Dmitriy Dyomin  <dmitrodem@gmail.com>
--! @date      2013-02-27
--! @version   0.1
--! @copyright Copyright (c) MIPT 2013
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
library techmap;
use techmap.gencomp.all;
use techmap.allfifo.all;
library grlib;
use grlib.stdlib.all;

entity fifo is
    generic (
      tech  : integer := apa3e;
      depth : integer range 8 to 12 := 9;
      dbits : integer := 9);
    port (
      rst     : in  std_ulogic;
      rclk    : in  std_ulogic;
      wclk    : in  std_ulogic;
      read    : in  std_ulogic;
      write   : in  std_ulogic;
      afval   : in  std_logic_vector (depth-1 downto 0);
      aeval   : in  std_logic_vector (depth-1 downto 0);
      datain  : in  std_logic_vector (dbits-1 downto 0);
      dataout : out std_logic_vector (dbits-1 downto 0);
      full    : out std_ulogic;
      empty   : out std_ulogic;
      afull   : out std_ulogic;
      aempty  : out std_ulogic);
end entity fifo;

architecture rtl of fifo is

begin  -- architecture rtl

  pa3: if tech = apa3 generate
    u0 : proasic3_fifo generic map (depth, dbits)
      port map (rst, rclk, wclk, read, write, afval, aeval, datain, dataout, full, empty, afull, aempty);    
  end generate pa3;  
  
  pa3l: if tech = apa3l generate
    u0 : proasic3l_fifo generic map (depth, dbits)
      port map (rst, rclk, wclk, read, write, afval, aeval, datain, dataout, full, empty, afull, aempty);    
  end generate pa3l;  
  
  pa3e: if tech = apa3e generate
    u0 : proasic3e_fifo generic map (depth, dbits)
      port map (rst, rclk, wclk, read, write, afval, aeval, datain, dataout, full, empty, afull, aempty);    
  end generate pa3e;

--  ig2: if tech = igloo2 generate
--	u0 : sf2_fifo port map ( RESET => rst, RCLOCK => rclk, WCLOCK => wclk, RE => read, WE => write, DATA => datain, 
--	                         Q => dataout, FULL => full, EMPTY => empty, AFULL => afull, AEMPTY => aempty);
--  end generate ig2;

  sf2: if tech = smartfusion2 generate
	u0 : sf2_fifo port map ( RESET => rst, RCLOCK => rclk, WCLOCK => wclk, RE => read, WE => write, DATA => datain, 
	                         Q => dataout, FULL => full, EMPTY => empty, AFULL => afull, AEMPTY => aempty);
  end generate sf2;


end architecture rtl;
