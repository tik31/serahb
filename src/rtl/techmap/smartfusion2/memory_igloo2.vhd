------------------------------------------------------------------------------
--  This file is a part of the GRLIB VHDL IP LIBRARY
--  Copyright (C) 2017, Cobham Gaisler AB - all rights reserved.
--
-- ANY USE OR REDISTRIBUTION IN PART OR IN WHOLE MUST BE HANDLED IN 
-- ACCORDANCE WITH THE GAISLER LICENSE AGREEMENT AND MUST BE APPROVED 
-- IN ADVANCE IN WRITING. 
-----------------------------------------------------------------------------
-- Entity:       various
-- File:         memory_igloo2.vhd
-- Authors:      Nils Johan Wessman, Pascal Trotta, Jan Andersson
-- Description:	 Custom memory generators for IGLOO2/SmartFusion2
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
library grlib;
use grlib.stdlib.all;
library techmap;
use techmap.gencomp.all;
use grlib.config_types.all;
use grlib.config.all;
-- pragma translate_off
library smartfusion2;
use smartfusion2.RAM1K18;
-- pragma translate_on

entity igloo2_syncram_2p is
  generic (abits : integer := 6; dbits : integer := 8;
	         sepclk : integer := 0; wrfst : integer := 0);
  port (
    rclk     : in std_ulogic;
    renable  : in std_ulogic;
    raddress : in std_logic_vector((abits-1) downto 0);
    dataout  : out std_logic_vector((dbits-1) downto 0);
    wclk     : in std_ulogic;
    write    : in std_ulogic;
    waddress : in std_logic_vector((abits-1) downto 0);
    datain   : in std_logic_vector((dbits-1) downto 0));
end;

architecture rtl of igloo2_syncram_2p is
  component generic_syncram_2p
  generic (abits : integer := 8; dbits : integer := 32; sepclk : integer := 0);
  port (
    rclk : in std_ulogic;
    wclk : in std_ulogic;
    rdaddress: in std_logic_vector (abits -1 downto 0);
    wraddress: in std_logic_vector (abits -1 downto 0);
    data: in std_logic_vector (dbits -1 downto 0);
    wren : in std_ulogic;
    q: out std_logic_vector (dbits -1 downto 0)
  );
  end component;
  component igloo2_syncram_dp is
    generic (abits : integer := 6; dbits : integer := 8);
    port (
      clk1     : in std_ulogic;
      address1 : in std_logic_vector((abits-1) downto 0);
      datain1  : in std_logic_vector((dbits-1) downto 0);
      dataout1 : out std_logic_vector((dbits-1) downto 0);
      enable1  : in std_ulogic;
      write1   : in std_ulogic;
      clk2     : in std_ulogic;
      address2 : in std_logic_vector((abits-1) downto 0);
      datain2  : in std_logic_vector((dbits-1) downto 0);
      dataout2 : out std_logic_vector((dbits-1) downto 0);
      enable2  : in std_ulogic;
      write2   : in std_ulogic);
  end component;
  component RAM1K18 
    generic (WARNING_MSGS_ON : integer := 0; -- Used to turn off warnings (e.g., about read & write to same address at same time)
             MEMORYFILE : string := ""; -- Memory array initialization (otherwise "X")
             NO_COLLISION : integer := 0);    -- Used to turn off collision detection
    port (
      A_CLK         : in  std_logic;
      A_DOUT_CLK    : in  std_logic;
      A_ARST_N      : in  std_logic;
      A_DOUT_EN     : in  std_logic;
      A_BLK         : in  std_logic_vector(2 downto 0);
      A_DOUT_ARST_N : in  std_logic;
      A_DOUT_SRST_N : in  std_logic;
      A_DIN         : in  std_logic_vector(17 downto 0);
      A_ADDR        : in  std_logic_vector(13 downto 0);
      A_WEN         : in  std_logic_vector(1 downto 0);
      A_DOUT_LAT    : in  std_logic;
      A_WIDTH       : in  std_logic_vector(2 downto 0);
      A_WMODE       : in  std_logic;
      A_EN          : in  std_logic;
      A_DOUT        : out std_logic_vector(17 downto 0); 

      B_CLK         : in  std_logic;
      B_DOUT_CLK    : in  std_logic;
      B_ARST_N      : in  std_logic;
      B_DOUT_EN     : in  std_logic;
      B_BLK         : in  std_logic_vector(2 downto 0);
      B_DOUT_ARST_N : in  std_logic;
      B_DOUT_SRST_N : in  std_logic;
      B_DIN         : in  std_logic_vector(17 downto 0);
      B_ADDR        : in  std_logic_vector(13 downto 0);
      B_WEN         : in  std_logic_vector(1 downto 0);
      B_DOUT_LAT    : in  std_logic;
      B_WIDTH       : in  std_logic_vector(2 downto 0);
      B_WMODE       : in  std_logic;
      B_EN          : in  std_logic;
      B_DOUT        : out std_logic_vector(17 downto 0);

      BUSY          : out std_logic;       
      SII_LOCK      : in  std_logic);
  end component;


  signal width        : std_logic_vector(2 downto 0);
  signal vmode        : std_logic;
  signal arst_n       : std_logic;
  signal dout_lat     : std_logic;
  signal dout_arst_n  : std_logic;
  signal dout_srst_n  : std_logic;
  signal dout_en      : std_logic;
  signal dout_clk     : std_logic;
  signal sii_lock     : std_logic;
  signal blk          : std_logic_vector(2 downto 0);
  signal xblka        : std_logic_vector(2 downto 0);
  signal xblkb        : std_logic_vector(2 downto 0);
  signal gnd          : std_logic_vector(2 downto 0);
  signal vcc          : std_logic;
  --
  signal xenable        : std_logic;
  signal raddr,waddr    : std_logic_vector(19 downto 0);
  signal xwen           : std_logic_vector(1 downto 0);
  signal din            : std_logic_vector(dbits+36 downto 0);
  signal dout           : std_logic_vector(dbits+36 downto 0);
  signal xraddr,xwaddr  : std_logic_vector(13 downto 0);
begin
  vmode       <= '0';
  arst_n      <= '1';
  dout_lat    <= '1';
  dout_arst_n <= '1';
  dout_srst_n <= '1';
  dout_en     <= '1';
  dout_clk    <= '1';
  sii_lock    <= '1';
  vcc         <= '1';
  gnd         <= (others => '0');

  xenable     <= '1';

  raddr(abits-1 downto 0)  <= raddress; raddr(19 downto abits) <= (others => '0');
  waddr(abits-1 downto 0)  <= waddress; waddr(19 downto abits) <= (others => '0');
  din(dbits-1 downto 0)   <= datain; din(dbits+36 downto dbits) <= (others => '0');
  
  a0 : if abits <= 5 and GRLIB_CONFIG_ARRAY(grlib_techmap_strict_ram) = 0 generate
    r :  generic_syncram_2p 
      generic map (abits, dbits, sepclk)
  	  port map (rclk, wclk, raddress, waddress, datain, write, dataout(dbits-1 downto 0));
  end generate;
  
  a9 : if ((abits > 5 or GRLIB_CONFIG_ARRAY(grlib_techmap_strict_ram) /= 0) and 
           (abits <= 9) and (sepclk = 0) ) generate
    width   <= "110"; -- 36-bit
    xwen    <= "11"; -- fixed in two-port mode
    xblkb   <= (others => write);
    xblka   <= (others => renable);
    dataout <= dout(dbits-1 downto 0);
    xraddr(13 downto 0)          <= raddr(8 downto 0) & "00000";
    xwaddr(13 downto 0)          <= waddr(8 downto 0) & "00000";

    x : for i in 0 to ((dbits-1)/36) generate

      r : RAM1K18 
        port map (
          A_CLK         => rclk,
          A_DOUT_CLK    => dout_clk,
          A_ARST_N      => arst_n,
          A_DOUT_EN     => dout_en,
          A_BLK         => xblka,
          A_DOUT_ARST_N => dout_arst_n,
          A_DOUT_SRST_N => dout_srst_n,
          A_DIN         => din(35+i*36 downto 18+i*36),
          A_ADDR        => xraddr,
          A_WEN         => xwen,
          A_DOUT_LAT    => dout_lat,
          A_WIDTH       => width,
          A_WMODE       => vmode,
          A_EN          => xenable,
          A_DOUT        => dout(35+i*36 downto 18+i*36),

          B_CLK         => wclk,
          B_DOUT_CLK    => dout_clk,
          B_ARST_N      => arst_n,
          B_DOUT_EN     => dout_en,
          B_BLK         => xblkb,
          B_DOUT_ARST_N => dout_arst_n,
          B_DOUT_SRST_N => dout_srst_n,
          B_DIN         => din(17+i*36 downto 0+i*36),
          B_ADDR        => xwaddr,
          B_WEN         => xwen,
          B_DOUT_LAT    => dout_lat,
          B_WIDTH       => width,
          B_WMODE       => vmode,
          B_EN          => xenable,
          B_DOUT        => dout(17+i*36 downto 0+i*36),

          BUSY          => open,
          SII_LOCK      => sii_lock);
    end generate;
  end generate;


  a10 : if ((((abits > 9) and (sepclk = 0)) or 
             ((sepclk = 1) and (abits > 5 or GRLIB_CONFIG_ARRAY(grlib_techmap_strict_ram) /= 0))) and 
            (abits <= 14)) generate
    use_dp : igloo2_syncram_dp
    generic map(
      abits => abits,
      dbits => dbits)
    port map (
      clk1     => rclk,
      address1 => raddress,
      datain1  => (others => '0'),
      dataout1 => dataout,
      enable1  => renable,
      write1   => '0',
      clk2     => wclk,
      address2 => waddress,
      datain2  => datain,
      dataout2 => open,
      enable2  => write,
      write2   => write
    );
  end generate;

-- pragma translate_off  
  unsup : if abits > 14 generate
    x : process
    begin
      assert false
      report "igloo2_syncram address or data width out of bounds ("
	 & tost(2**abits) & "x" & tost(dbits) & ")"
      severity failure;
      wait;
    end process;
  end generate;
-- pragma translate_on
end;


library ieee;
use ieee.std_logic_1164.all;
library grlib;
use grlib.stdlib.all;
use grlib.config_types.all;
use grlib.config.all;
-- pragma translate_off
library smartfusion2;
use smartfusion2.RAM1K18;
-- pragma translate_on

entity igloo2_syncram_dp is
  generic (abits : integer := 6; dbits : integer := 8);
  port (
    clk1     : in std_ulogic;
    address1 : in std_logic_vector((abits-1) downto 0);
    datain1  : in std_logic_vector((dbits-1) downto 0);
    dataout1 : out std_logic_vector((dbits-1) downto 0);
    enable1  : in std_ulogic;
    write1   : in std_ulogic;
    clk2     : in std_ulogic;
    address2 : in std_logic_vector((abits-1) downto 0);
    datain2  : in std_logic_vector((dbits-1) downto 0);
    dataout2 : out std_logic_vector((dbits-1) downto 0);
    enable2  : in std_ulogic;
    write2   : in std_ulogic);
end;

architecture rtl of igloo2_syncram_dp is
  signal width        : std_logic_vector(2 downto 0);
  signal vmode        : std_logic;
  signal arst_n       : std_logic;
  signal dout_lat     : std_logic;
  signal dout_arst_n  : std_logic;
  signal dout_srst_n  : std_logic;
  signal dout_en      : std_logic;
  signal dout_clk     : std_logic;
  signal sii_lock     : std_logic;
  signal blk          : std_logic_vector(2 downto 0);
  signal xblka        : std_logic_vector(2 downto 0);
  signal xblkb        : std_logic_vector(2 downto 0);
  signal gnd          : std_logic_vector(2 downto 0);
  signal vcc          : std_logic;
  --
  signal xenable        : std_logic;
  signal xblk1,xblk2    : std_logic_vector(2 downto 0);
  signal addr1,addr2    : std_logic_vector(19 downto 0);
  signal xwen1,xwen2    : std_logic_vector(1 downto 0);
  signal din1,din2      : std_logic_vector(dbits+36 downto 0);
  signal dout1,dout2    : std_logic_vector(dbits+36 downto 0);
  signal xaddr1,xaddr2  : std_logic_vector(13 downto 0);
  --signal xdina,xdinb  : std_logic_vector(17 downto 0);
  signal xdout1,xdout2  : std_logic_vector(dbits*18 downto 0);

  component RAM1K18 
    generic (WARNING_MSGS_ON : integer := 0; -- Used to turn off warnings (e.g., about read & write to same address at same time)
             MEMORYFILE : string := ""; -- Memory array initialization (otherwise "X")
             NO_COLLISION : integer := 0);    -- Used to turn off collision detection
    port (
      A_CLK         : in  std_logic;
      A_DOUT_CLK    : in  std_logic;
      A_ARST_N      : in  std_logic;
      A_DOUT_EN     : in  std_logic;
      A_BLK         : in  std_logic_vector(2 downto 0);
      A_DOUT_ARST_N : in  std_logic;
      A_DOUT_SRST_N : in  std_logic;
      A_DIN         : in  std_logic_vector(17 downto 0);
      A_ADDR        : in  std_logic_vector(13 downto 0);
      A_WEN         : in  std_logic_vector(1 downto 0);
      A_DOUT_LAT    : in  std_logic;
      A_WIDTH       : in  std_logic_vector(2 downto 0);
      A_WMODE       : in  std_logic;
      A_EN          : in  std_logic;
      A_DOUT        : out std_logic_vector(17 downto 0); 

      B_CLK         : in  std_logic;
      B_DOUT_CLK    : in  std_logic;
      B_ARST_N      : in  std_logic;
      B_DOUT_EN     : in  std_logic;
      B_BLK         : in  std_logic_vector(2 downto 0);
      B_DOUT_ARST_N : in  std_logic;
      B_DOUT_SRST_N : in  std_logic;
      B_DIN         : in  std_logic_vector(17 downto 0);
      B_ADDR        : in  std_logic_vector(13 downto 0);
      B_WEN         : in  std_logic_vector(1 downto 0);
      B_DOUT_LAT    : in  std_logic;
      B_WIDTH       : in  std_logic_vector(2 downto 0);
      B_WMODE       : in  std_logic;
      B_EN          : in  std_logic;
      B_DOUT        : out std_logic_vector(17 downto 0);

      BUSY          : out std_logic;       
      SII_LOCK      : in  std_logic);
  end component;

  function paddata(di : in std_logic_vector) return std_logic_vector is
    variable data : std_logic_vector(17 downto 0);
  begin
    data := (others => '0');
    data(di'length-1 downto 0) := di;
    return data;
  end function;
    
begin

  vmode       <= '0';
  arst_n      <= '1';
  dout_lat    <= '1';
  dout_arst_n <= '1';
  dout_srst_n <= '1';
  dout_en     <= '1';
  dout_clk    <= '1';
  sii_lock    <= '1';
  vcc         <= '1';
  gnd         <= (others => '0');

  xenable     <= '1';

  xblk1       <= (others => enable1);
  xblk2       <= (others => enable2);
  addr1(abits-1 downto 0)  <= address1; addr1(19 downto abits) <= (others => '0');
  addr2(abits-1 downto 0)  <= address2; addr2(19 downto abits) <= (others => '0');
  din1(dbits-1 downto 0)   <= datain1; din1(dbits+36 downto dbits) <= (others => '0');
  din2(dbits-1 downto 0)   <= datain2; din2(dbits+36 downto dbits) <= (others => '0');
  dataout1                 <= dout1(dbits-1 downto 0);
  dataout2                 <= dout2(dbits-1 downto 0);

  a10 : if (abits <= 10) generate
    width <= "100"; -- 18-bit
    xwen1 <= (others => write1);
    xwen2 <= (others => write2);
    xaddr1(13 downto 0)          <= addr1(9 downto 0) & "0000";
    xaddr2(13 downto 0)          <= addr2(9 downto 0) & "0000";

    x : for i in 0 to ((dbits-1)/18) generate

      r : RAM1K18 
        port map (
          A_CLK         => clk1,
          A_DOUT_CLK    => dout_clk,
          A_ARST_N      => arst_n,
          A_DOUT_EN     => dout_en,
          A_BLK         => xblk1,
          A_DOUT_ARST_N => dout_arst_n,
          A_DOUT_SRST_N => dout_srst_n,
          A_DIN         => din1(17+i*18 downto 0+i*18),
          A_ADDR        => xaddr1,
          A_WEN         => xwen1,
          A_DOUT_LAT    => dout_lat,
          A_WIDTH       => width,
          A_WMODE       => vmode,
          A_EN          => xenable,
          A_DOUT        => dout1(17+i*18 downto 0+i*18),

          B_CLK         => clk2,
          B_DOUT_CLK    => dout_clk,
          B_ARST_N      => arst_n,
          B_DOUT_EN     => dout_en,
          B_BLK         => xblk2,
          B_DOUT_ARST_N => dout_arst_n,
          B_DOUT_SRST_N => dout_srst_n,
          B_DIN         => din2(17+i*18 downto 0+i*18),
          B_ADDR        => xaddr2,
          B_WEN         => xwen2,
          B_DOUT_LAT    => dout_lat,
          B_WIDTH       => width,
          B_WMODE       => vmode,
          B_EN          => xenable,
          B_DOUT        => dout2(17+i*18 downto 0+i*18),

          BUSY          => open,
          SII_LOCK      => sii_lock);
    end generate;
  end generate;

  a11 : if (abits = 11) generate
    width <= "011"; -- 9-bit
    xwen1 <= "0" &  write1;
    xwen2 <= "0" &  write2;
    xaddr1(13 downto 0)        <= addr1(10 downto 0) & "000";
    xaddr2(13 downto 0)        <= addr2(10 downto 0) & "000";

    x : for i in 0 to ((dbits-1)/9) generate
      dout1(8+i*9 downto 0+i*9)  <= xdout1(8+i*18 downto 0+i*18);
      dout2(8+i*9 downto 0+i*9)  <= xdout2(8+i*18 downto 0+i*18);

      r : RAM1K18 
        port map (
          A_CLK         => clk1,
          A_DOUT_CLK    => dout_clk,
          A_ARST_N      => arst_n,
          A_DOUT_EN     => dout_en,
          A_BLK         => xblk1,
          A_DOUT_ARST_N => dout_arst_n,
          A_DOUT_SRST_N => dout_srst_n,
          A_DIN         => paddata(din1(8+i*9 downto 0+i*9)),
          A_ADDR        => xaddr1,
          A_WEN         => xwen1,
          A_DOUT_LAT    => dout_lat,
          A_WIDTH       => width,
          A_WMODE       => vmode,
          A_EN          => xenable,
          A_DOUT        => xdout1(17+i*18 downto 0+i*18),

          B_CLK         => clk2,
          B_DOUT_CLK    => dout_clk,
          B_ARST_N      => arst_n,
          B_DOUT_EN     => dout_en,
          B_BLK         => xblk2,
          B_DOUT_ARST_N => dout_arst_n,
          B_DOUT_SRST_N => dout_srst_n,
          B_DIN         => paddata(din2(8+i*9 downto 0+i*9)),
          B_ADDR        => xaddr2,
          B_WEN         => xwen2,
          B_DOUT_LAT    => dout_lat,
          B_WIDTH       => width,
          B_WMODE       => vmode,
          B_EN          => xenable,
          B_DOUT        => xdout2(17+i*18 downto 0+i*18),

          BUSY          => open,
          SII_LOCK      => sii_lock);
    end generate;
  end generate;

  a12 : if (abits = 12) generate
    width <= "010"; -- 4-bit
    xwen1 <= "0" &  write1;
    xwen2 <= "0" &  write2;
    xaddr1(13 downto 0)        <= addr1(11 downto 0) & "00";
    xaddr2(13 downto 0)        <= addr2(11 downto 0) & "00";

    x : for i in 0 to ((dbits-1)/4) generate
      dout1(3+i*4 downto 0+i*4)  <= xdout1(3+i*18 downto 0+i*18);
      dout2(3+i*4 downto 0+i*4)  <= xdout2(3+i*18 downto 0+i*18);

      r : RAM1K18 
        port map (
          A_CLK         => clk1,
          A_DOUT_CLK    => dout_clk,
          A_ARST_N      => arst_n,
          A_DOUT_EN     => dout_en,
          A_BLK         => xblk1,
          A_DOUT_ARST_N => dout_arst_n,
          A_DOUT_SRST_N => dout_srst_n,
          A_DIN         => paddata(din1(3+i*4 downto 0+i*4)),
          A_ADDR        => xaddr1,
          A_WEN         => xwen1,
          A_DOUT_LAT    => dout_lat,
          A_WIDTH       => width,
          A_WMODE       => vmode,
          A_EN          => xenable,
          A_DOUT        => xdout1(17+i*18 downto 0+i*18),

          B_CLK         => clk2,
          B_DOUT_CLK    => dout_clk,
          B_ARST_N      => arst_n,
          B_DOUT_EN     => dout_en,
          B_BLK         => xblk2,
          B_DOUT_ARST_N => dout_arst_n,
          B_DOUT_SRST_N => dout_srst_n,
          B_DIN         => paddata(din2(3+i*4 downto 0+i*4)),
          B_ADDR        => xaddr2,
          B_WEN         => xwen2,
          B_DOUT_LAT    => dout_lat,
          B_WIDTH       => width,
          B_WMODE       => vmode,
          B_EN          => xenable,
          B_DOUT        => xdout2(17+i*18 downto 0+i*18),

          BUSY          => open,
          SII_LOCK      => sii_lock);
    end generate;
  end generate;

  a13 : if (abits = 13) generate
    width <= "001"; -- 2-bit
    xwen1 <= "0" &  write1;
    xwen2 <= "0" &  write2;
    xaddr1(13 downto 0)        <= addr1(12 downto 0) & "0";
    xaddr2(13 downto 0)        <= addr2(12 downto 0) & "0";

    x : for i in 0 to ((dbits-1)/2) generate
      dout1(1+i*2 downto 0+i*2)  <= xdout1(1+i*18 downto 0+i*18);
      dout2(1+i*2 downto 0+i*2)  <= xdout2(1+i*18 downto 0+i*18);

      r : RAM1K18 
        port map (
          A_CLK         => clk1,
          A_DOUT_CLK    => dout_clk,
          A_ARST_N      => arst_n,
          A_DOUT_EN     => dout_en,
          A_BLK         => xblk1,
          A_DOUT_ARST_N => dout_arst_n,
          A_DOUT_SRST_N => dout_srst_n,
          A_DIN         => paddata(din1(1+i*2 downto 0+i*2)),
          A_ADDR        => xaddr1,
          A_WEN         => xwen1,
          A_DOUT_LAT    => dout_lat,
          A_WIDTH       => width,
          A_WMODE       => vmode,
          A_EN          => xenable,
          A_DOUT        => xdout1(17+i*18 downto 0+i*18),

          B_CLK         => clk2,
          B_DOUT_CLK    => dout_clk,
          B_ARST_N      => arst_n,
          B_DOUT_EN     => dout_en,
          B_BLK         => xblk2,
          B_DOUT_ARST_N => dout_arst_n,
          B_DOUT_SRST_N => dout_srst_n,
          B_DIN         => paddata(din2(1+i*2 downto 0+i*2)),
          B_ADDR        => xaddr2,
          B_WEN         => xwen2,
          B_DOUT_LAT    => dout_lat,
          B_WIDTH       => width,
          B_WMODE       => vmode,
          B_EN          => xenable,
          B_DOUT        => xdout2(17+i*18 downto 0+i*18),

          BUSY          => open,
          SII_LOCK      => sii_lock);
    end generate;
  end generate;

  a14 : if (abits = 14) generate
    width <= "000"; -- 1-bit
    xwen1 <= "0" &  write1;
    xwen2 <= "0" &  write2;
    xaddr1(13 downto 0)        <= addr1(13 downto 0);
    xaddr2(13 downto 0)        <= addr2(13 downto 0);

    x : for i in 0 to ((dbits-1)/1) generate
      dout1(0+i*1 downto 0+i*1)  <= xdout1(0+i*18 downto 0+i*18);
      dout2(0+i*1 downto 0+i*1)  <= xdout2(0+i*18 downto 0+i*18);

      r : RAM1K18 
        port map (
          A_CLK         => clk1,
          A_DOUT_CLK    => dout_clk,
          A_ARST_N      => arst_n,
          A_DOUT_EN     => dout_en,
          A_BLK         => xblk1,
          A_DOUT_ARST_N => dout_arst_n,
          A_DOUT_SRST_N => dout_srst_n,
          A_DIN         => paddata(din1(0+i*1 downto 0+i*1)),
          A_ADDR        => xaddr1,
          A_WEN         => xwen1,
          A_DOUT_LAT    => dout_lat,
          A_WIDTH       => width,
          A_WMODE       => vmode,
          A_EN          => xenable,
          A_DOUT        => xdout1(17+i*18 downto 0+i*18),

          B_CLK         => clk2,
          B_DOUT_CLK    => dout_clk,
          B_ARST_N      => arst_n,
          B_DOUT_EN     => dout_en,
          B_BLK         => xblk2,
          B_DOUT_ARST_N => dout_arst_n,
          B_DOUT_SRST_N => dout_srst_n,
          B_DIN         => paddata(din2(0+i*1 downto 0+i*1)),
          B_ADDR        => xaddr2,
          B_WEN         => xwen2,
          B_DOUT_LAT    => dout_lat,
          B_WIDTH       => width,
          B_WMODE       => vmode,
          B_EN          => xenable,
          B_DOUT        => xdout2(17+i*18 downto 0+i*18),

          BUSY          => open,
          SII_LOCK      => sii_lock);
    end generate;
  end generate;

-- pragma translate_off  
  unsup : if abits > 14 generate
    x : process
    begin
      assert false
      report "igloo2_syncram address or data width out of bounds ("
	 & tost(2**abits) & "x" & tost(dbits) & ")"
      severity failure;
      wait;
    end process;
  end generate;
-- pragma translate_on

end;


library ieee;
use ieee.std_logic_1164.all;
library grlib;
use grlib.stdlib.all;
library techmap;
use techmap.gencomp.all;
use grlib.config_types.all;
use grlib.config.all;
-- pragma translate_off
library smartfusion2;
use smartfusion2.RAM1K18;
-- pragma translate_on

entity igloo2_syncram is
  generic (abits : integer := 6; dbits : integer := 8);
  port (
    clk      : in std_ulogic;
    address  : in std_logic_vector((abits -1) downto 0);
    datain   : in std_logic_vector((dbits -1) downto 0);
    dataout  : out std_logic_vector((dbits -1) downto 0);
    enable   : in std_ulogic;
    write    : in std_ulogic);
end;

architecture rtl of igloo2_syncram is
  signal width        : std_logic_vector(2 downto 0);
  signal vmode        : std_logic;
  signal arst_n       : std_logic;
  signal dout_lat     : std_logic;
  signal dout_arst_n  : std_logic;
  signal dout_srst_n  : std_logic;
  signal dout_en      : std_logic;
  signal dout_clk     : std_logic;
  signal sii_lock     : std_logic;
  signal blk          : std_logic_vector(2 downto 0);
  signal xblka        : std_logic_vector(2 downto 0);
  signal xblkb        : std_logic_vector(2 downto 0);
  signal gnd          : std_logic_vector(2 downto 0);
  signal vcc          : std_logic;
  --
  signal addr         : std_logic_vector(19 downto 0);
  signal wen          : std_logic_vector(1 downto 0);
  signal din          : std_logic_vector(dbits+36 downto 0);
  signal dout         : std_logic_vector(dbits+36 downto 0);
  signal xaddr        : std_logic_vector(13 downto 0);
  signal xdina,xdinb  : std_logic_vector(17 downto 0);
  signal xdouta,xdoutb: std_logic_vector(512 downto 0);
  signal xenable      : std_logic;

  component generic_syncram
  generic ( abits : integer := 10; dbits : integer := 8 );
  port (
    clk      : in std_ulogic;
    address  : in std_logic_vector((abits -1) downto 0);
    datain   : in std_logic_vector((dbits -1) downto 0);
    dataout  : out std_logic_vector((dbits -1) downto 0);
    write    : in std_ulogic);
  end component;
  component igloo2_syncram_dp is
    generic (abits : integer := 6; dbits : integer := 8);
    port (
      clk1     : in std_ulogic;
      address1 : in std_logic_vector((abits-1) downto 0);
      datain1  : in std_logic_vector((dbits-1) downto 0);
      dataout1 : out std_logic_vector((dbits-1) downto 0);
      enable1  : in std_ulogic;
      write1   : in std_ulogic;
      clk2     : in std_ulogic;
      address2 : in std_logic_vector((abits-1) downto 0);
      datain2  : in std_logic_vector((dbits-1) downto 0);
      dataout2 : out std_logic_vector((dbits-1) downto 0);
      enable2  : in std_ulogic;
      write2   : in std_ulogic);
  end component;
  component RAM1K18 
    generic (WARNING_MSGS_ON : integer := 0; -- Used to turn off warnings (e.g., about read & write to same address at same time)
             MEMORYFILE : string := ""; -- Memory array initialization (otherwise "X")
             NO_COLLISION : integer := 0);    -- Used to turn off collision detection
    port (
      A_CLK         : in  std_logic;
      A_DOUT_CLK    : in  std_logic;
      A_ARST_N      : in  std_logic;
      A_DOUT_EN     : in  std_logic;
      A_BLK         : in  std_logic_vector(2 downto 0);
      A_DOUT_ARST_N : in  std_logic;
      A_DOUT_SRST_N : in  std_logic;
      A_DIN         : in  std_logic_vector(17 downto 0);
      A_ADDR        : in  std_logic_vector(13 downto 0);
      A_WEN         : in  std_logic_vector(1 downto 0);
      A_DOUT_LAT    : in  std_logic;
      A_WIDTH       : in  std_logic_vector(2 downto 0);
      A_WMODE       : in  std_logic;
      A_EN          : in  std_logic;
      A_DOUT        : out std_logic_vector(17 downto 0); 

      B_CLK         : in  std_logic;
      B_DOUT_CLK    : in  std_logic;
      B_ARST_N      : in  std_logic;
      B_DOUT_EN     : in  std_logic;
      B_BLK         : in  std_logic_vector(2 downto 0);
      B_DOUT_ARST_N : in  std_logic;
      B_DOUT_SRST_N : in  std_logic;
      B_DIN         : in  std_logic_vector(17 downto 0);
      B_ADDR        : in  std_logic_vector(13 downto 0);
      B_WEN         : in  std_logic_vector(1 downto 0);
      B_DOUT_LAT    : in  std_logic;
      B_WIDTH       : in  std_logic_vector(2 downto 0);
      B_WMODE       : in  std_logic;
      B_EN          : in  std_logic;
      B_DOUT        : out std_logic_vector(17 downto 0);

      BUSY          : out std_logic;       
      SII_LOCK      : in  std_logic);
  end component;

  function paddata(di : in std_logic_vector) return std_logic_vector is
    variable data : std_logic_vector(17 downto 0);
  begin
    data := (others => '0');
    data(di'length-1 downto 0) := di;
    return data;
  end function;
    
begin

  vmode       <= '0';
  arst_n      <= '1';
  dout_lat    <= '1';
  dout_arst_n <= '1';
  dout_srst_n <= '1';
  dout_en     <= '1';
  dout_clk    <= '1';
  sii_lock    <= '1';
  vcc         <= '1';
  gnd         <= (others => '0');

  xenable     <= '1';
  blk         <= (others => enable);

  addr(abits-1 downto 0)  <= address; addr(19 downto abits) <= (others => '0');
  din(dbits-1 downto 0)   <= datain; din(dbits+36 downto dbits) <= (others => '0');
  
  a0 : if (abits <= 5) and (GRLIB_CONFIG_ARRAY(grlib_techmap_strict_ram) = 0) generate
    r : generic_syncram 
      generic map (abits, dbits)
      port map (clk, address, datain, dataout(dbits-1 downto 0), write);
  end generate;

  a9 : if ((abits > 5 or GRLIB_CONFIG_ARRAY(grlib_techmap_strict_ram) /= 0) and
          (abits <= 9)) generate
    width <= "110"; -- 36-bit
    wen   <= "11"; -- fixed in two-port mode
    xblkb <= (others => write);
    xblka <= (others => (enable and not write));
    dataout <= dout(dbits-1 downto 0);
    xaddr(13 downto 0)          <= addr(8 downto 0) & "00000";
    
    x : for i in 0 to ((dbits-1)/36) generate

      r : RAM1K18 
        port map (
          A_CLK         => clk,
          A_DOUT_CLK    => dout_clk,
          A_ARST_N      => arst_n,
          A_DOUT_EN     => dout_en,
          A_BLK         => xblka,
          A_DOUT_ARST_N => dout_arst_n,
          A_DOUT_SRST_N => dout_srst_n,
          A_DIN         => din(35+i*36 downto 18+i*36),
          A_ADDR        => xaddr,
          A_WEN         => wen,
          A_DOUT_LAT    => dout_lat,
          A_WIDTH       => width,
          A_WMODE       => vmode,
          A_EN          => xenable,
          A_DOUT        => dout(35+i*36 downto 18+i*36),

          B_CLK         => clk,
          B_DOUT_CLK    => dout_clk,
          B_ARST_N      => arst_n,
          B_DOUT_EN     => dout_en,
          B_BLK         => xblkb,
          B_DOUT_ARST_N => dout_arst_n,
          B_DOUT_SRST_N => dout_srst_n,
          B_DIN         => din(17+i*36 downto 0+i*36),
          B_ADDR        => xaddr,
          B_WEN         => wen,
          B_DOUT_LAT    => dout_lat,
          B_WIDTH       => width,
          B_WMODE       => vmode,
          B_EN          => xenable,
          B_DOUT        => dout(17+i*36 downto 0+i*36),

          BUSY          => open,
          SII_LOCK      => sii_lock);
    end generate;
  end generate;

  a10 : if ((abits > 9) and (abits <= 14)) generate
    use_dp : igloo2_syncram_dp
    generic map(
      abits => abits,
      dbits => dbits)
    port map (
      clk1     => clk,
      address1 => address,
      datain1  => datain,
      dataout1 => dataout,
      enable1  => enable,
      write1   => write,
      clk2     => vcc,
      address2 => (others => '0'),
      datain2  => (others => '0'),
      dataout2 => open,
      enable2  => gnd(0),
      write2   => gnd(0)
    );
  end generate;

-- pragma translate_off  
  unsup : if abits > 14 generate
    x : process
    begin
      assert false
      report "igloo2_syncram address or data width out of bounds ("
	 & tost(2**abits) & "x" & tost(dbits) & ")"
      severity failure;
      wait;
    end process;
  end generate;
-- pragma translate_on

end;

library ieee;
use ieee.std_logic_1164.all;
library grlib;
use grlib.stdlib.all;
library techmap;
use techmap.gencomp.all;
use grlib.config_types.all;
use grlib.config.all;
-- pragma translate_off
library smartfusion2;
use smartfusion2.RAM1K18;
-- pragma translate_on

entity igloo2_syncram_be is
  generic (abits : integer := 6; dbits : integer := 8);
  port (
    clk      : in std_ulogic;
    address  : in std_logic_vector((abits -1) downto 0);
    datain   : in std_logic_vector((dbits -1) downto 0);
    dataout  : out std_logic_vector((dbits -1) downto 0);
    enable   : in std_logic_vector (dbits/8-1 downto 0);
    write    : in std_logic_vector (dbits/8-1 downto 0));
end;

architecture rtl of igloo2_syncram_be is
  signal width        : std_logic_vector(2 downto 0);
  signal vmode        : std_logic;
  signal arst_n       : std_logic;
  signal dout_lat     : std_logic;
  signal dout_arst_n  : std_logic;
  signal dout_srst_n  : std_logic;
  signal dout_en      : std_logic;
  signal dout_clk     : std_logic;
  signal sii_lock     : std_logic;
  signal blk          : std_logic_vector(2 downto 0);
  signal xblka        : std_logic_vector(2 downto 0);
  signal xblkb        : std_logic_vector(2 downto 0);
  signal gnd          : std_logic_vector(2 downto 0);
  signal vcc          : std_logic;
  --
  signal addr         : std_logic_vector(19 downto 0);
  signal din          : std_logic_vector(dbits+36 downto 0);
  signal dout         : std_logic_vector(dbits+36 downto 0);
  signal xaddr        : std_logic_vector(13 downto 0);
  signal xdina,xdinb  : std_logic_vector(17 downto 0);
  signal xdouta,xdoutb: std_logic_vector(512 downto 0);
  signal xenable      : std_logic;

  type xwen_type is array (0 to 255) of std_logic_vector(1 downto 0);
  signal wen : xwen_type;
  type d_type is array (0 to 255) of std_logic_vector(17 downto 0);
  signal xdin, xdout : d_type;

  component generic_syncram
  generic ( abits : integer := 10; dbits : integer := 8 );
  port (
    clk      : in std_ulogic;
    address  : in std_logic_vector((abits -1) downto 0);
    datain   : in std_logic_vector((dbits -1) downto 0);
    dataout  : out std_logic_vector((dbits -1) downto 0);
    write    : in std_ulogic);
  end component;
  
  component RAM1K18 
    generic (WARNING_MSGS_ON : integer := 0; -- Used to turn off warnings (e.g., about read & write to same address at same time)
             MEMORYFILE : string := ""; -- Memory array initialization (otherwise "X")
             NO_COLLISION : integer := 0);    -- Used to turn off collision detection
    port (
      A_CLK         : in  std_logic;
      A_DOUT_CLK    : in  std_logic;
      A_ARST_N      : in  std_logic;
      A_DOUT_EN     : in  std_logic;
      A_BLK         : in  std_logic_vector(2 downto 0);
      A_DOUT_ARST_N : in  std_logic;
      A_DOUT_SRST_N : in  std_logic;
      A_DIN         : in  std_logic_vector(17 downto 0);
      A_ADDR        : in  std_logic_vector(13 downto 0);
      A_WEN         : in  std_logic_vector(1 downto 0);
      A_DOUT_LAT    : in  std_logic;
      A_WIDTH       : in  std_logic_vector(2 downto 0);
      A_WMODE       : in  std_logic;
      A_EN          : in  std_logic;
      A_DOUT        : out std_logic_vector(17 downto 0); 

      B_CLK         : in  std_logic;
      B_DOUT_CLK    : in  std_logic;
      B_ARST_N      : in  std_logic;
      B_DOUT_EN     : in  std_logic;
      B_BLK         : in  std_logic_vector(2 downto 0);
      B_DOUT_ARST_N : in  std_logic;
      B_DOUT_SRST_N : in  std_logic;
      B_DIN         : in  std_logic_vector(17 downto 0);
      B_ADDR        : in  std_logic_vector(13 downto 0);
      B_WEN         : in  std_logic_vector(1 downto 0);
      B_DOUT_LAT    : in  std_logic;
      B_WIDTH       : in  std_logic_vector(2 downto 0);
      B_WMODE       : in  std_logic;
      B_EN          : in  std_logic;
      B_DOUT        : out std_logic_vector(17 downto 0);

      BUSY          : out std_logic;       
      SII_LOCK      : in  std_logic);
  end component;

  function paddata(di : in std_logic_vector) return std_logic_vector is
    variable data : std_logic_vector(17 downto 0);
  begin
    data := (others => '0');
    data(di'length-1 downto 0) := di;
    return data;
  end function;
    
begin

  vmode       <= '0';
  arst_n      <= '1';
  dout_lat    <= '1';
  dout_arst_n <= '1';
  dout_srst_n <= '1';
  dout_en     <= '1';
  dout_clk    <= '1';
  sii_lock    <= '1';
  vcc         <= '1';
  gnd         <= (others => '0');

  xenable     <= '1';
  blk         <= (others => orv(enable));

  addr(abits-1 downto 0)  <= address; addr(19 downto abits) <= (others => '0');
  din(dbits-1 downto 0)   <= datain; din(dbits+36 downto dbits) <= (others => '0');
  dataout <= dout(dbits-1 downto 0);

  a0 : if (abits <= 5) and (GRLIB_CONFIG_ARRAY(grlib_techmap_strict_ram) = 0) generate
    x : for i in 0 to ((dbits-1)/8) generate
      r : generic_syncram generic map (abits, 8)
        port map (clk, address, din(i*8+8-1 downto i*8), dout(i*8+8-1 downto i*8), write(i));
    end generate;
    dout(dbits+36 downto 8*(((dbits-1)/8)+1)) <= (others => '0');
  end generate;

  a10 : if ((abits > 5 or GRLIB_CONFIG_ARRAY(grlib_techmap_strict_ram) /= 0) and
          (abits <= 10)) generate
    width <= "100"; -- 16-bit
    xblka <= (others => orv(write));
    xblkb <= (others => (orv(enable) and not orv(write)));
    xaddr(13 downto 0) <= addr(9 downto 0) & "0000";
    
    x : for i in 0 to ((dbits-1)/16) generate

      wen(i)   <= write(i*2+2-1 downto i*2);
      xdin(i)  <= "0"&din(15+i*16 downto 8+i*16)&"0"&din(7+i*16 downto 0+i*16);
      dout(15+i*16 downto 0+i*16) <= xdout(i)(16 downto 9)&xdout(i)(7 downto 0); 

      r : RAM1K18 
        port map (
          A_CLK         => clk,
          A_DOUT_CLK    => dout_clk,
          A_ARST_N      => arst_n,
          A_DOUT_EN     => dout_en,
          A_BLK         => xblka,
          A_DOUT_ARST_N => dout_arst_n,
          A_DOUT_SRST_N => dout_srst_n,
          A_DIN         => xdin(i),
          A_ADDR        => xaddr,
          A_WEN         => wen(i),
          A_DOUT_LAT    => dout_lat,
          A_WIDTH       => width,
          A_WMODE       => vmode,
          A_EN          => xenable,
          A_DOUT        => open,

          B_CLK         => clk,
          B_DOUT_CLK    => dout_clk,
          B_ARST_N      => arst_n,
          B_DOUT_EN     => dout_en,
          B_BLK         => xblkb,
          B_DOUT_ARST_N => dout_arst_n,
          B_DOUT_SRST_N => dout_srst_n,
          B_DIN         => "000000000000000000",
          B_ADDR        => xaddr,
          B_WEN         => "00",
          B_DOUT_LAT    => dout_lat,
          B_WIDTH       => width,
          B_WMODE       => vmode,
          B_EN          => xenable,
          B_DOUT        => xdout(i),

          BUSY          => open,
          SII_LOCK      => sii_lock);
    end generate;
    dout(dbits+36 downto 16*(((dbits-1)/16)+1)) <= (others => '0');
  end generate;

  a11 : if (abits = 11) generate
    width <= "011"; -- 8-bit
    xblka <= (others => orv(write));
    xblkb <= (others => (orv(enable) and not orv(write)));
    xaddr(13 downto 0) <= addr(10 downto 0) & "000";
    
    x : for i in 0 to ((dbits-1)/8) generate

      wen(i)   <= '0'&write(i);
      xdin(i)(17 downto 8) <= (others=>'0');
      xdin(i)(7 downto 0)  <= din(7+i*8 downto 0+i*8);
      dout(7+i*8 downto 0+i*8) <= xdout(i)(7 downto 0);

      r : RAM1K18 
        port map (
          A_CLK         => clk,
          A_DOUT_CLK    => dout_clk,
          A_ARST_N      => arst_n,
          A_DOUT_EN     => dout_en,
          A_BLK         => xblka,
          A_DOUT_ARST_N => dout_arst_n,
          A_DOUT_SRST_N => dout_srst_n,
          A_DIN         => xdin(i),
          A_ADDR        => xaddr,
          A_WEN         => wen(i),
          A_DOUT_LAT    => dout_lat,
          A_WIDTH       => width,
          A_WMODE       => vmode,
          A_EN          => xenable,
          A_DOUT        => open,

          B_CLK         => clk,
          B_DOUT_CLK    => dout_clk,
          B_ARST_N      => arst_n,
          B_DOUT_EN     => dout_en,
          B_BLK         => xblkb,
          B_DOUT_ARST_N => dout_arst_n,
          B_DOUT_SRST_N => dout_srst_n,
          B_DIN         => "000000000000000000",
          B_ADDR        => xaddr,
          B_WEN         => "00",
          B_DOUT_LAT    => dout_lat,
          B_WIDTH       => width,
          B_WMODE       => vmode,
          B_EN          => xenable,
          B_DOUT        => xdout(i),

          BUSY          => open,
          SII_LOCK      => sii_lock);
    end generate;
    dout(dbits+36 downto 8*(((dbits-1)/8)+1)) <= (others => '0');
  end generate;

  a12 : if (abits = 12) generate
    width <= "010"; -- 4-bit
    xblka <= (others => orv(write));
    xblkb <= (others => (orv(enable) and not orv(write)));
    xaddr(13 downto 0) <= addr(11 downto 0) & "00";
    
    x : for i in 0 to ((dbits-1)/4) generate

      wen(i)   <= '0'&write(i/2);
      xdin(i)(17 downto 4) <= (others=>'0');
      xdin(i)(3 downto 0)  <= din(3+i*4 downto 0+i*4);
      dout(3+i*4 downto 0+i*4) <= xdout(i)(3 downto 0);

      r : RAM1K18 
        port map (
          A_CLK         => clk,
          A_DOUT_CLK    => dout_clk,
          A_ARST_N      => arst_n,
          A_DOUT_EN     => dout_en,
          A_BLK         => xblka,
          A_DOUT_ARST_N => dout_arst_n,
          A_DOUT_SRST_N => dout_srst_n,
          A_DIN         => xdin(i),
          A_ADDR        => xaddr,
          A_WEN         => wen(i),
          A_DOUT_LAT    => dout_lat,
          A_WIDTH       => width,
          A_WMODE       => vmode,
          A_EN          => xenable,
          A_DOUT        => open,

          B_CLK         => clk,
          B_DOUT_CLK    => dout_clk,
          B_ARST_N      => arst_n,
          B_DOUT_EN     => dout_en,
          B_BLK         => xblkb,
          B_DOUT_ARST_N => dout_arst_n,
          B_DOUT_SRST_N => dout_srst_n,
          B_DIN         => "000000000000000000",
          B_ADDR        => xaddr,
          B_WEN         => "00",
          B_DOUT_LAT    => dout_lat,
          B_WIDTH       => width,
          B_WMODE       => vmode,
          B_EN          => xenable,
          B_DOUT        => xdout(i),

          BUSY          => open,
          SII_LOCK      => sii_lock);
    end generate;
    dout(dbits+36 downto 4*(((dbits-1)/4)+1)) <= (others => '0');
  end generate;

  a13 : if (abits = 13) generate
    width <= "001"; -- 2-bit
    xblka <= (others => orv(write));
    xblkb <= (others => (orv(enable) and not orv(write)));
    xaddr(13 downto 0) <= addr(12 downto 0) & "0";
    
    x : for i in 0 to ((dbits-1)/2) generate

      wen(i)   <= '0'&write(i/4);
      xdin(i)(17 downto 2) <= (others=>'0');
      xdin(i)(1 downto 0)  <= din(1+i*2 downto 0+i*2);
      dout(1+i*2 downto 0+i*2) <= xdout(i)(1 downto 0);

      r : RAM1K18 
        port map (
          A_CLK         => clk,
          A_DOUT_CLK    => dout_clk,
          A_ARST_N      => arst_n,
          A_DOUT_EN     => dout_en,
          A_BLK         => xblka,
          A_DOUT_ARST_N => dout_arst_n,
          A_DOUT_SRST_N => dout_srst_n,
          A_DIN         => xdin(i),
          A_ADDR        => xaddr,
          A_WEN         => wen(i),
          A_DOUT_LAT    => dout_lat,
          A_WIDTH       => width,
          A_WMODE       => vmode,
          A_EN          => xenable,
          A_DOUT        => open,

          B_CLK         => clk,
          B_DOUT_CLK    => dout_clk,
          B_ARST_N      => arst_n,
          B_DOUT_EN     => dout_en,
          B_BLK         => xblkb,
          B_DOUT_ARST_N => dout_arst_n,
          B_DOUT_SRST_N => dout_srst_n,
          B_DIN         => "000000000000000000",
          B_ADDR        => xaddr,
          B_WEN         => "00",
          B_DOUT_LAT    => dout_lat,
          B_WIDTH       => width,
          B_WMODE       => vmode,
          B_EN          => xenable,
          B_DOUT        => xdout(i),

          BUSY          => open,
          SII_LOCK      => sii_lock);
    end generate;
    dout(dbits+36 downto 2*(((dbits-1)/2)+1)) <= (others => '0');
  end generate;

  a14 : if (abits = 14) generate
    width <= "000"; -- 1-bit
    xblka <= (others => orv(write));
    xblkb <= (others => (orv(enable) and not orv(write)));
    xaddr(13 downto 0) <= addr(13 downto 0);
    
    x : for i in 0 to (dbits-1) generate

      wen(i)   <= '0'&write(i/8);
      xdin(i)(17 downto 1) <= (others=>'0');
      xdin(i)(0)  <= din(i);
      dout(i) <= xdout(i)(0);

      r : RAM1K18 
        port map (
          A_CLK         => clk,
          A_DOUT_CLK    => dout_clk,
          A_ARST_N      => arst_n,
          A_DOUT_EN     => dout_en,
          A_BLK         => xblka,
          A_DOUT_ARST_N => dout_arst_n,
          A_DOUT_SRST_N => dout_srst_n,
          A_DIN         => xdin(i),
          A_ADDR        => xaddr,
          A_WEN         => wen(i),
          A_DOUT_LAT    => dout_lat,
          A_WIDTH       => width,
          A_WMODE       => vmode,
          A_EN          => xenable,
          A_DOUT        => open,

          B_CLK         => clk,
          B_DOUT_CLK    => dout_clk,
          B_ARST_N      => arst_n,
          B_DOUT_EN     => dout_en,
          B_BLK         => xblkb,
          B_DOUT_ARST_N => dout_arst_n,
          B_DOUT_SRST_N => dout_srst_n,
          B_DIN         => "000000000000000000",
          B_ADDR        => xaddr,
          B_WEN         => "00",
          B_DOUT_LAT    => dout_lat,
          B_WIDTH       => width,
          B_WMODE       => vmode,
          B_EN          => xenable,
          B_DOUT        => xdout(i),

          BUSY          => open,
          SII_LOCK      => sii_lock);
    end generate;
    dout(dbits+36 downto dbits) <= (others => '0');
  end generate;

  a15 : if (abits > 14) generate
    x : for i in 0 to ((dbits-1)/8) generate
      r : generic_syncram generic map (abits, 8)
        port map (clk, address, din(i*8+8-1 downto i*8), dout(i*8+8-1 downto i*8), write(i));
    end generate;
    dout(dbits+36 downto 8*(((dbits-1)/8)+1)) <= (others => '0');
  end generate;

  -- pragma translate_off  
  gen_sram : if abits > 14 generate
    x : process
    begin
      report "igloo2_syncram_be address width out of bounds. It will be implemented resorting to inferred syncram.";
      wait;
    end process;
  end generate;
  -- pragma translate_on

end;
