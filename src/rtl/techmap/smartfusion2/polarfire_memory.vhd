------------------------------------------------------------------------------
--  This file is a part of the GRLIB VHDL IP LIBRARY
--  Copyright (C) 2017, Cobham Gaisler AB - all rights reserved.
--
-- ANY USE OR REDISTRIBUTION IN PART OR IN WHOLE MUST BE HANDLED IN 
-- ACCORDANCE WITH THE GAISLER LICENSE AGREEMENT AND MUST BE APPROVED 
-- IN ADVANCE IN WRITING. 
-----------------------------------------------------------------------------
-- Entity:       various
-- File:         memory_polarfire.vhd
-- Authors:      Based on memory_igloo2.vhd, adapted for PolarFire
-- Description:	 Custom memory generators for PolarFire/PolarFire SoC
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
library polarfire;
use polarfire.RAM1K20;
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
  
  component RAM1K20 
    generic (
      MEMORYFILE : string := "";
      INIT_MODE : string := "NONE";
      ECC : string := "OFF";
      RDWIDTH_A : integer := 20;
      RDWIDTH_B : integer := 20;
      WRWIDTH_A : integer := 20;
      WRWIDTH_B : integer := 20;
      RDDEPTH_A : integer := 1024;
      RDDEPTH_B : integer := 1024;
      WRDEPTH_A : integer := 1024;
      WRDEPTH_B : integer := 1024
    );
    port (
      CLK_A        : in  std_logic;
      CLK_B        : in  std_logic;
      REN_A        : in  std_logic;
      REN_B        : in  std_logic;
      WEN_A        : in  std_logic;
      WEN_B        : in  std_logic;
      BEN_A        : in  std_logic_vector(1 downto 0);
      BEN_B        : in  std_logic_vector(1 downto 0);
      ADDR_A       : in  std_logic_vector(13 downto 0);
      ADDR_B       : in  std_logic_vector(13 downto 0);
      WDATA_A      : in  std_logic_vector(19 downto 0);
      WDATA_B      : in  std_logic_vector(19 downto 0);
      RDATA_A      : out std_logic_vector(19 downto 0);
      RDATA_B      : out std_logic_vector(19 downto 0);
      PIPE_A       : in  std_logic;
      PIPE_B       : in  std_logic;
      RESET_A      : in  std_logic;
      RESET_B      : in  std_logic
    );
  end component;

  signal raddr,waddr    : std_logic_vector(19 downto 0);
  signal din            : std_logic_vector(dbits+40 downto 0);
  signal dout           : std_logic_vector(dbits+40 downto 0);
  signal xraddr,xwaddr  : std_logic_vector(13 downto 0);
  signal xben           : std_logic_vector(1 downto 0);
  signal pipe           : std_logic;
  signal reset_n        : std_logic;

begin
  pipe    <= '0';
  reset_n <= '0';
  xben    <= "11";

  raddr(abits-1 downto 0)  <= raddress; raddr(19 downto abits) <= (others => '0');
  waddr(abits-1 downto 0)  <= waddress; waddr(19 downto abits) <= (others => '0');
  din(dbits-1 downto 0)   <= datain; din(dbits+40 downto dbits) <= (others => '0');
  
  a0 : if abits <= 5 and GRLIB_CONFIG_ARRAY(grlib_techmap_strict_ram) = 0 generate
    r :  generic_syncram_2p 
      generic map (abits, dbits, sepclk)
  	  port map (rclk, wclk, raddress, waddress, datain, write, dataout(dbits-1 downto 0));
  end generate;
  
  a10 : if ((abits > 5 or GRLIB_CONFIG_ARRAY(grlib_techmap_strict_ram) /= 0) and 
           (abits <= 10) and (sepclk = 0) ) generate
    dataout <= dout(dbits-1 downto 0);
    xraddr(13 downto 0) <= raddr(9 downto 0) & "0000";
    xwaddr(13 downto 0) <= waddr(9 downto 0) & "0000";

    x : for i in 0 to ((dbits-1)/40) generate
      r : RAM1K20 
        generic map (
          RDWIDTH_A => 20,
          RDWIDTH_B => 20,
          WRWIDTH_A => 20,
          WRWIDTH_B => 20,
          RDDEPTH_A => 1024,
          RDDEPTH_B => 1024,
          WRDEPTH_A => 1024,
          WRDEPTH_B => 1024
        )
        port map (
          CLK_A        => rclk,
          CLK_B        => wclk,
          REN_A        => renable,
          REN_B        => '0',
          WEN_A        => '0',
          WEN_B        => write,
          BEN_A        => xben,
          BEN_B        => xben,
          ADDR_A       => xraddr,
          ADDR_B       => xwaddr,
          WDATA_A      => din(39+i*40 downto 20+i*40),
          WDATA_B      => din(19+i*40 downto 0+i*40),
          RDATA_A      => dout(39+i*40 downto 20+i*40),
          RDATA_B      => dout(19+i*40 downto 0+i*40),
          PIPE_A       => pipe,
          PIPE_B       => pipe,
          RESET_A      => reset_n,
          RESET_B      => reset_n
        );
    end generate;
  end generate;

  a11 : if ((((abits > 10) and (sepclk = 0)) or 
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
      report "polarfire_syncram address or data width out of bounds ("
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
library polarfire;
use polarfire.RAM1K20;
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
  signal addr1,addr2    : std_logic_vector(19 downto 0);
  signal din1,din2      : std_logic_vector(dbits+40 downto 0);
  signal dout1,dout2    : std_logic_vector(dbits+40 downto 0);
  signal xaddr1,xaddr2  : std_logic_vector(13 downto 0);
  signal xdout1,xdout2  : std_logic_vector(dbits*20 downto 0);
  signal xben           : std_logic_vector(1 downto 0);
  signal pipe           : std_logic;
  signal reset_n        : std_logic;

  component RAM1K20 
    generic (
      MEMORYFILE : string := "";
      INIT_MODE : string := "NONE";
      ECC : string := "OFF";
      RDWIDTH_A : integer := 20;
      RDWIDTH_B : integer := 20;
      WRWIDTH_A : integer := 20;
      WRWIDTH_B : integer := 20;
      RDDEPTH_A : integer := 1024;
      RDDEPTH_B : integer := 1024;
      WRDEPTH_A : integer := 1024;
      WRDEPTH_B : integer := 1024
    );
    port (
      CLK_A        : in  std_logic;
      CLK_B        : in  std_logic;
      REN_A        : in  std_logic;
      REN_B        : in  std_logic;
      WEN_A        : in  std_logic;
      WEN_B        : in  std_logic;
      BEN_A        : in  std_logic_vector(1 downto 0);
      BEN_B        : in  std_logic_vector(1 downto 0);
      ADDR_A       : in  std_logic_vector(13 downto 0);
      ADDR_B       : in  std_logic_vector(13 downto 0);
      WDATA_A      : in  std_logic_vector(19 downto 0);
      WDATA_B      : in  std_logic_vector(19 downto 0);
      RDATA_A      : out std_logic_vector(19 downto 0);
      RDATA_B      : out std_logic_vector(19 downto 0);
      PIPE_A       : in  std_logic;
      PIPE_B       : in  std_logic;
      RESET_A      : in  std_logic;
      RESET_B      : in  std_logic
    );
  end component;

  function paddata(di : in std_logic_vector) return std_logic_vector is
    variable data : std_logic_vector(19 downto 0);
  begin
    data := (others => '0');
    data(di'length-1 downto 0) := di;
    return data;
  end function;
    
begin
  pipe    <= '0';
  reset_n <= '0';
  xben    <= "11";

  addr1(abits-1 downto 0)  <= address1; addr1(19 downto abits) <= (others => '0');
  addr2(abits-1 downto 0)  <= address2; addr2(19 downto abits) <= (others => '0');
  din1(dbits-1 downto 0)   <= datain1; din1(dbits+40 downto dbits) <= (others => '0');
  din2(dbits-1 downto 0)   <= datain2; din2(dbits+40 downto dbits) <= (others => '0');
  dataout1                 <= dout1(dbits-1 downto 0);
  dataout2                 <= dout2(dbits-1 downto 0);

  a10 : if (abits <= 10) generate
    xaddr1(13 downto 0) <= addr1(9 downto 0) & "0000";
    xaddr2(13 downto 0) <= addr2(9 downto 0) & "0000";

    x : for i in 0 to ((dbits-1)/20) generate
      r : RAM1K20 
        generic map (
          RDWIDTH_A => 20,
          RDWIDTH_B => 20,
          WRWIDTH_A => 20,
          WRWIDTH_B => 20,
          RDDEPTH_A => 1024,
          RDDEPTH_B => 1024,
          WRDEPTH_A => 1024,
          WRDEPTH_B => 1024
        )
        port map (
          CLK_A        => clk1,
          CLK_B        => clk2,
          REN_A        => enable1,
          REN_B        => enable2,
          WEN_A        => write1,
          WEN_B        => write2,
          BEN_A        => xben,
          BEN_B        => xben,
          ADDR_A       => xaddr1,
          ADDR_B       => xaddr2,
          WDATA_A      => din1(19+i*20 downto 0+i*20),
          WDATA_B      => din2(19+i*20 downto 0+i*20),
          RDATA_A      => dout1(19+i*20 downto 0+i*20),
          RDATA_B      => dout2(19+i*20 downto 0+i*20),
          PIPE_A       => pipe,
          PIPE_B       => pipe,
          RESET_A      => reset_n,
          RESET_B      => reset_n
        );
    end generate;
  end generate;

  a11 : if (abits = 11) generate
    xaddr1(13 downto 0) <= addr1(10 downto 0) & "000";
    xaddr2(13 downto 0) <= addr2(10 downto 0) & "000";

    x : for i in 0 to ((dbits-1)/10) generate
      dout1(9+i*10 downto 0+i*10)  <= xdout1(9+i*20 downto 0+i*20);
      dout2(9+i*10 downto 0+i*10)  <= xdout2(9+i*20 downto 0+i*20);

      r : RAM1K20 
        generic map (
          RDWIDTH_A => 10,
          RDWIDTH_B => 10,
          WRWIDTH_A => 10,
          WRWIDTH_B => 10,
          RDDEPTH_A => 2048,
          RDDEPTH_B => 2048,
          WRDEPTH_A => 2048,
          WRDEPTH_B => 2048
        )
        port map (
          CLK_A        => clk1,
          CLK_B        => clk2,
          REN_A        => enable1,
          REN_B        => enable2,
          WEN_A        => write1,
          WEN_B        => write2,
          BEN_A        => xben,
          BEN_B        => xben,
          ADDR_A       => xaddr1,
          ADDR_B       => xaddr2,
          WDATA_A      => paddata(din1(9+i*10 downto 0+i*10)),
          WDATA_B      => paddata(din2(9+i*10 downto 0+i*10)),
          RDATA_A      => xdout1(19+i*20 downto 0+i*20),
          RDATA_B      => xdout2(19+i*20 downto 0+i*20),
          PIPE_A       => pipe,
          PIPE_B       => pipe,
          RESET_A      => reset_n,
          RESET_B      => reset_n
        );
    end generate;
  end generate;

  a12 : if (abits = 12) generate
    xaddr1(13 downto 0) <= addr1(11 downto 0) & "00";
    xaddr2(13 downto 0) <= addr2(11 downto 0) & "00";

    x : for i in 0 to ((dbits-1)/5) generate
      dout1(4+i*5 downto 0+i*5)  <= xdout1(4+i*20 downto 0+i*20);
      dout2(4+i*5 downto 0+i*5)  <= xdout2(4+i*20 downto 0+i*20);

      r : RAM1K20 
        generic map (
          RDWIDTH_A => 5,
          RDWIDTH_B => 5,
          WRWIDTH_A => 5,
          WRWIDTH_B => 5,
          RDDEPTH_A => 4096,
          RDDEPTH_B => 4096,
          WRDEPTH_A => 4096,
          WRDEPTH_B => 4096
        )
        port map (
          CLK_A        => clk1,
          CLK_B        => clk2,
          REN_A        => enable1,
          REN_B        => enable2,
          WEN_A        => write1,
          WEN_B        => write2,
          BEN_A        => xben,
          BEN_B        => xben,
          ADDR_A       => xaddr1,
          ADDR_B       => xaddr2,
          WDATA_A      => paddata(din1(4+i*5 downto 0+i*5)),
          WDATA_B      => paddata(din2(4+i*5 downto 0+i*5)),
          RDATA_A      => xdout1(19+i*20 downto 0+i*20),
          RDATA_B      => xdout2(19+i*20 downto 0+i*20),
          PIPE_A       => pipe,
          PIPE_B       => pipe,
          RESET_A      => reset_n,
          RESET_B      => reset_n
        );
    end generate;
  end generate;

  a13 : if (abits = 13) generate
    xaddr1(13 downto 0) <= addr1(12 downto 0) & "0";
    xaddr2(13 downto 0) <= addr2(12 downto 0) & "0";

    x : for i in 0 to ((dbits-1)/2) generate
      dout1(1+i*2 downto 0+i*2)  <= xdout1(1+i*20 downto 0+i*20);
      dout2(1+i*2 downto 0+i*2)  <= xdout2(1+i*20 downto 0+i*20);

      r : RAM1K20 
        generic map (
          RDWIDTH_A => 2,
          RDWIDTH_B => 2,
          WRWIDTH_A => 2,
          WRWIDTH_B => 2,
          RDDEPTH_A => 8192,
          RDDEPTH_B => 8192,
          WRDEPTH_A => 8192,
          WRDEPTH_B => 8192
        )
        port map (
          CLK_A        => clk1,
          CLK_B        => clk2,
          REN_A        => enable1,
          REN_B        => enable2,
          WEN_A        => write1,
          WEN_B        => write2,
          BEN_A        => xben,
          BEN_B        => xben,
          ADDR_A       => xaddr1,
          ADDR_B       => xaddr2,
          WDATA_A      => paddata(din1(1+i*2 downto 0+i*2)),
          WDATA_B      => paddata(din2(1+i*2 downto 0+i*2)),
          RDATA_A      => xdout1(19+i*20 downto 0+i*20),
          RDATA_B      => xdout2(19+i*20 downto 0+i*20),
          PIPE_A       => pipe,
          PIPE_B       => pipe,
          RESET_A      => reset_n,
          RESET_B      => reset_n
        );
    end generate;
  end generate;

  a14 : if (abits = 14) generate
    xaddr1(13 downto 0) <= addr1(13 downto 0);
    xaddr2(13 downto 0) <= addr2(13 downto 0);

    x : for i in 0 to ((dbits-1)/1) generate
      dout1(0+i*1 downto 0+i*1)  <= xdout1(0+i*20 downto 0+i*20);
      dout2(0+i*1 downto 0+i*1)  <= xdout2(0+i*20 downto 0+i*20);

      r : RAM1K20 
        generic map (
          RDWIDTH_A => 1,
          RDWIDTH_B => 1,
          WRWIDTH_A => 1,
          WRWIDTH_B => 1,
          RDDEPTH_A => 16384,
          RDDEPTH_B => 16384,
          WRDEPTH_A => 16384,
          WRDEPTH_B => 16384
        )
        port map (
          CLK_A        => clk1,
          CLK_B        => clk2,
          REN_A        => enable1,
          REN_B        => enable2,
          WEN_A        => write1,
          WEN_B        => write2,
          BEN_A        => xben,
          BEN_B        => xben,
          ADDR_A       => xaddr1,
          ADDR_B       => xaddr2,
          WDATA_A      => paddata(din1(0+i*1 downto 0+i*1)),
          WDATA_B      => paddata(din2(0+i*1 downto 0+i*1)),
          RDATA_A      => xdout1(19+i*20 downto 0+i*20),
          RDATA_B      => xdout2(19+i*20 downto 0+i*20),
          PIPE_A       => pipe,
          PIPE_B       => pipe,
          RESET_A      => reset_n,
          RESET_B      => reset_n
        );
    end generate;
  end generate;

-- pragma translate_off  
  unsup : if abits > 14 generate
    x : process
    begin
      assert false
      report "polarfire_syncram address or data width out of bounds ("
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
library polarfire;
use polarfire.RAM1K20;
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
  signal addr         : std_logic_vector(19 downto 0);
  signal din          : std_logic_vector(dbits+40 downto 0);
  signal dout         : std_logic_vector(dbits+40 downto 0);
  signal xaddr        : std_logic_vector(13 downto 0);
  signal xben         : std_logic_vector(1 downto 0);
  signal pipe         : std_logic;
  signal reset_n      : std_logic;
  signal enable_and_not_write: std_logic;

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
  
  component RAM1K20 
    generic (
      MEMORYFILE : string := "";
      INIT_MODE : string := "NONE";
      ECC : string := "OFF";
      RDWIDTH_A : integer := 20;
      RDWIDTH_B : integer := 20;
      WRWIDTH_A : integer := 20;
      WRWIDTH_B : integer := 20;
      RDDEPTH_A : integer := 1024;
      RDDEPTH_B : integer := 1024;
      WRDEPTH_A : integer := 1024;
      WRDEPTH_B : integer := 1024
    );
    port (
      CLK_A        : in  std_logic;
      CLK_B        : in  std_logic;
      REN_A        : in  std_logic;
      REN_B        : in  std_logic;
      WEN_A        : in  std_logic;
      WEN_B        : in  std_logic;
      BEN_A        : in  std_logic_vector(1 downto 0);
      BEN_B        : in  std_logic_vector(1 downto 0);
      ADDR_A       : in  std_logic_vector(13 downto 0);
      ADDR_B       : in  std_logic_vector(13 downto 0);
      WDATA_A      : in  std_logic_vector(19 downto 0);
      WDATA_B      : in  std_logic_vector(19 downto 0);
      RDATA_A      : out std_logic_vector(19 downto 0);
      RDATA_B      : out std_logic_vector(19 downto 0);
      PIPE_A       : in  std_logic;
      PIPE_B       : in  std_logic;
      RESET_A      : in  std_logic;
      RESET_B      : in  std_logic
    );
  end component;

begin
  pipe    <= '0';
  reset_n <= '0';
  xben    <= "11";

  addr(abits-1 downto 0)  <= address; addr(19 downto abits) <= (others => '0');
  din(dbits-1 downto 0)   <= datain; din(dbits+40 downto dbits) <= (others => '0');
  
  enable_and_not_write <= (enable and not write);
  
  a0 : if (abits <= 5) and (GRLIB_CONFIG_ARRAY(grlib_techmap_strict_ram) = 0) generate
    r : generic_syncram 
      generic map (abits, dbits)
      port map (clk, address, datain, dataout(dbits-1 downto 0), write);
  end generate;

  a10 : if ((abits > 5 or GRLIB_CONFIG_ARRAY(grlib_techmap_strict_ram) /= 0) and
          (abits <= 10)) generate
    dataout <= dout(dbits-1 downto 0);
    xaddr(13 downto 0) <= addr(9 downto 0) & "0000";
    
    x : for i in 0 to ((dbits-1)/40) generate
      r : RAM1K20 
        generic map (
          RDWIDTH_A => 20,
          RDWIDTH_B => 20,
          WRWIDTH_A => 20,
          WRWIDTH_B => 20,
          RDDEPTH_A => 1024,
          RDDEPTH_B => 1024,
          WRDEPTH_A => 1024,
          WRDEPTH_B => 1024
        )
        port map (
          CLK_A        => clk,
          CLK_B        => clk,
          REN_A        => enable_and_not_write,
          REN_B        => '0',
          WEN_A        => '0',
          WEN_B        => write,
          BEN_A        => xben,
          BEN_B        => xben,
          ADDR_A       => xaddr,
          ADDR_B       => xaddr,
          WDATA_A      => din(39+i*40 downto 20+i*40),
          WDATA_B      => din(19+i*40 downto 0+i*40),
          RDATA_A      => dout(39+i*40 downto 20+i*40),
          RDATA_B      => dout(19+i*40 downto 0+i*40),
          PIPE_A       => pipe,
          PIPE_B       => pipe,
          RESET_A      => reset_n,
          RESET_B      => reset_n
        );
    end generate;
  end generate;

  a11 : if ((abits > 10) and (abits <= 14)) generate
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
      clk2     => '1',
      address2 => (others => '0'),
      datain2  => (others => '0'),
      dataout2 => open,
      enable2  => '0',
      write2   => '0'
    );
  end generate;

-- pragma translate_off  
  unsup : if abits > 14 generate
    x : process
    begin
      assert false
      report "polarfire_syncram address or data width out of bounds ("
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
library polarfire;
use polarfire.RAM1K20;
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
  signal addr         : std_logic_vector(19 downto 0);
  signal din          : std_logic_vector(dbits+40 downto 0);
  signal dout         : std_logic_vector(dbits+40 downto 0);
  signal xaddr        : std_logic_vector(13 downto 0);
  signal pipe         : std_logic;
  signal reset_n      : std_logic;
  signal orv_enable_and_not_orv_write : std_logic;

  type xben_type is array (0 to 255) of std_logic_vector(1 downto 0);
  signal ben : xben_type;
  type d_type is array (0 to 255) of std_logic_vector(19 downto 0);
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
  
  component RAM1K20 
    generic (
      MEMORYFILE : string := "";
      INIT_MODE : string := "NONE";
      ECC : string := "OFF";
      RDWIDTH_A : integer := 20;
      RDWIDTH_B : integer := 20;
      WRWIDTH_A : integer := 20;
      WRWIDTH_B : integer := 20;
      RDDEPTH_A : integer := 1024;
      RDDEPTH_B : integer := 1024;
      WRDEPTH_A : integer := 1024;
      WRDEPTH_B : integer := 1024
    );
    port (
      CLK_A        : in  std_logic;
      CLK_B        : in  std_logic;
      REN_A        : in  std_logic;
      REN_B        : in  std_logic;
      WEN_A        : in  std_logic;
      WEN_B        : in  std_logic;
      BEN_A        : in  std_logic_vector(1 downto 0);
      BEN_B        : in  std_logic_vector(1 downto 0);
      ADDR_A       : in  std_logic_vector(13 downto 0);
      ADDR_B       : in  std_logic_vector(13 downto 0);
      WDATA_A      : in  std_logic_vector(19 downto 0);
      WDATA_B      : in  std_logic_vector(19 downto 0);
      RDATA_A      : out std_logic_vector(19 downto 0);
      RDATA_B      : out std_logic_vector(19 downto 0);
      PIPE_A       : in  std_logic;
      PIPE_B       : in  std_logic;
      RESET_A      : in  std_logic;
      RESET_B      : in  std_logic
    );
  end component;

  function paddata(di : in std_logic_vector) return std_logic_vector is
    variable data : std_logic_vector(19 downto 0);
  begin
    data := (others => '0');
    data(di'length-1 downto 0) := di;
    return data;
  end function;
    
begin
  pipe    <= '0';
  reset_n <= '0';

  addr(abits-1 downto 0)  <= address; addr(19 downto abits) <= (others => '0');
  din(dbits-1 downto 0)   <= datain; din(dbits+40 downto dbits) <= (others => '0');
  dataout <= dout(dbits-1 downto 0);
  
  orv_enable_and_not_orv_write <=(orv(enable) and not orv(write));

  a0 : if (abits <= 5) and (GRLIB_CONFIG_ARRAY(grlib_techmap_strict_ram) = 0) generate
    x : for i in 0 to ((dbits-1)/8) generate
      r : generic_syncram generic map (abits, 8)
        port map (clk, address, din(i*8+8-1 downto i*8), dout(i*8+8-1 downto i*8), write(i));
    end generate;
    dout(dbits+40 downto 8*(((dbits-1)/8)+1)) <= (others => '0');
  end generate;

  a10 : if ((abits > 5 or GRLIB_CONFIG_ARRAY(grlib_techmap_strict_ram) /= 0) and
          (abits <= 10)) generate
    xaddr(13 downto 0) <= addr(9 downto 0) & "0000";
    
    x : for i in 0 to ((dbits-1)/20) generate
      ben(i)   <= write(i*2+2-1 downto i*2) when i*2+1 < dbits/8 else write(i*2) & write(i*2);
      xdin(i)  <= din(19+i*20 downto 0+i*20);
      dout(19+i*20 downto 0+i*20) <= xdout(i); 

      r : RAM1K20 
        generic map (
          RDWIDTH_A => 20,
          RDWIDTH_B => 20,
          WRWIDTH_A => 20,
          WRWIDTH_B => 20,
          RDDEPTH_A => 1024,
          RDDEPTH_B => 1024,
          WRDEPTH_A => 1024,
          WRDEPTH_B => 1024
        )
        port map (
          CLK_A        => clk,
          CLK_B        => clk,
          REN_A        => '0',
          REN_B        => orv_enable_and_not_orv_write,
          WEN_A        => orv(write),
          WEN_B        => '0',
          BEN_A        => ben(i),
          BEN_B        => "11",
          ADDR_A       => xaddr,
          ADDR_B       => xaddr,
          WDATA_A      => xdin(i),
          WDATA_B      => (others => '0'),
          RDATA_A      => open,
          RDATA_B      => xdout(i),
          PIPE_A       => pipe,
          PIPE_B       => pipe,
          RESET_A      => reset_n,
          RESET_B      => reset_n
        );
    end generate;
    dout(dbits+40 downto 20*(((dbits-1)/20)+1)) <= (others => '0');
  end generate;

  a15 : if (abits > 10) generate
    x : for i in 0 to ((dbits-1)/8) generate
      r : generic_syncram generic map (abits, 8)
        port map (clk, address, din(i*8+8-1 downto i*8), dout(i*8+8-1 downto i*8), write(i));
    end generate;
    dout(dbits+40 downto 8*(((dbits-1)/8)+1)) <= (others => '0');
  end generate;

  -- pragma translate_off  
  gen_sram : if abits > 10 generate
    x : process
    begin
      report "polarfire_syncram_be address width out of bounds for RAM1K20. It will be implemented resorting to inferred syncram.";
      wait;
    end process;
  end generate;
  -- pragma translate_on

end;
