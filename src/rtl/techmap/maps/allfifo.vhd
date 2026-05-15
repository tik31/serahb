-------------------------------------------------------------------------------
--! @file      allfifo.vhd
--! @brief     All FIFO4K18 components
--! @details   This module is valid only for Proasic technologies
--! @author    Dmitriy Dyomin  <dmitrodem@gmail.com>
--! @date      2013-02-27
--! @version   0.1
--! @copyright Copyright (c) MIPT 2013
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

package allfifo is
    
  component proasic3_fifo is
    generic (
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
  end component proasic3_fifo;
  
  component proasic3l_fifo is
    generic (
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
  end component proasic3l_fifo;
  
  component proasic3e_fifo is
    generic (
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
  end component proasic3e_fifo;

  component sf2_fifo is
    -- Port list
    port(
        -- Inputs
        DATA   : in  std_logic_vector(38 downto 0);
        RCLOCK : in  std_logic;
        RE     : in  std_logic;
        RESET  : in  std_logic;
        WCLOCK : in  std_logic;
        WE     : in  std_logic;
        -- Outputs
        AEMPTY : out std_logic;
        AFULL  : out std_logic;
        EMPTY  : out std_logic;
        FULL   : out std_logic;
        Q      : out std_logic_vector(38 downto 0)
        );
	end component sf2_fifo;

end package allfifo;
