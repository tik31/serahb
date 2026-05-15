-- Version: v11.8 11.8.0.26

library ieee;
use ieee.std_logic_1164.all;
library smartfusion2;
use smartfusion2.all;

entity sf2_fifo_sf2_fifo_0_LSRAM_top is

    port( WD    : in    std_logic_vector(38 downto 0);
          RD    : out   std_logic_vector(38 downto 0);
          WADDR : in    std_logic_vector(8 downto 0);
          RADDR : in    std_logic_vector(8 downto 0);
          WEN   : in    std_logic;
          REN   : in    std_logic;
          WCLK  : in    std_logic;
          RCLK  : in    std_logic
        );

end sf2_fifo_sf2_fifo_0_LSRAM_top;

architecture DEF_ARCH of sf2_fifo_sf2_fifo_0_LSRAM_top is 

  component RAM1K18
    generic (MEMORYFILE:string := "");

    port( A_DOUT        : out   std_logic_vector(17 downto 0);
          B_DOUT        : out   std_logic_vector(17 downto 0);
          BUSY          : out   std_logic;
          A_CLK         : in    std_logic := 'U';
          A_DOUT_CLK    : in    std_logic := 'U';
          A_ARST_N      : in    std_logic := 'U';
          A_DOUT_EN     : in    std_logic := 'U';
          A_BLK         : in    std_logic_vector(2 downto 0) := (others => 'U');
          A_DOUT_ARST_N : in    std_logic := 'U';
          A_DOUT_SRST_N : in    std_logic := 'U';
          A_DIN         : in    std_logic_vector(17 downto 0) := (others => 'U');
          A_ADDR        : in    std_logic_vector(13 downto 0) := (others => 'U');
          A_WEN         : in    std_logic_vector(1 downto 0) := (others => 'U');
          B_CLK         : in    std_logic := 'U';
          B_DOUT_CLK    : in    std_logic := 'U';
          B_ARST_N      : in    std_logic := 'U';
          B_DOUT_EN     : in    std_logic := 'U';
          B_BLK         : in    std_logic_vector(2 downto 0) := (others => 'U');
          B_DOUT_ARST_N : in    std_logic := 'U';
          B_DOUT_SRST_N : in    std_logic := 'U';
          B_DIN         : in    std_logic_vector(17 downto 0) := (others => 'U');
          B_ADDR        : in    std_logic_vector(13 downto 0) := (others => 'U');
          B_WEN         : in    std_logic_vector(1 downto 0) := (others => 'U');
          A_EN          : in    std_logic := 'U';
          A_DOUT_LAT    : in    std_logic := 'U';
          A_WIDTH       : in    std_logic_vector(2 downto 0) := (others => 'U');
          A_WMODE       : in    std_logic := 'U';
          B_EN          : in    std_logic := 'U';
          B_DOUT_LAT    : in    std_logic := 'U';
          B_WIDTH       : in    std_logic_vector(2 downto 0) := (others => 'U');
          B_WMODE       : in    std_logic := 'U';
          SII_LOCK      : in    std_logic := 'U'
        );
  end component;

  component GND
    port(Y : out std_logic); 
  end component;

  component VCC
    port(Y : out std_logic); 
  end component;

    signal \VCC\, \GND\, ADLIB_VCC : std_logic;
    signal GND_power_net1 : std_logic;
    signal VCC_power_net1 : std_logic;
    signal nc9, nc13, nc23, nc33, nc16, nc26, nc27, nc17, nc5, 
        nc4, nc25, nc15, nc28, nc18, nc1, nc2, nc22, nc12, nc21, 
        nc11, nc3, nc32, nc31, nc7, nc6, nc19, nc29, nc8, nc20, 
        nc10, nc24, nc14, nc30 : std_logic;

begin 

    \GND\ <= GND_power_net1;
    \VCC\ <= VCC_power_net1;
    ADLIB_VCC <= VCC_power_net1;

    sf2_fifo_sf2_fifo_0_LSRAM_top_R0C1 : RAM1K18
      port map(A_DOUT(17) => nc9, A_DOUT(16) => nc13, A_DOUT(15)
         => nc23, A_DOUT(14) => nc33, A_DOUT(13) => nc16, 
        A_DOUT(12) => nc26, A_DOUT(11) => nc27, A_DOUT(10) => 
        nc17, A_DOUT(9) => nc5, A_DOUT(8) => nc4, A_DOUT(7) => 
        nc25, A_DOUT(6) => nc15, A_DOUT(5) => nc28, A_DOUT(4) => 
        nc18, A_DOUT(3) => nc1, A_DOUT(2) => nc2, A_DOUT(1) => 
        nc22, A_DOUT(0) => nc12, B_DOUT(17) => nc21, B_DOUT(16)
         => nc11, B_DOUT(15) => nc3, B_DOUT(14) => nc32, 
        B_DOUT(13) => nc31, B_DOUT(12) => nc7, B_DOUT(11) => nc6, 
        B_DOUT(10) => nc19, B_DOUT(9) => nc29, B_DOUT(8) => nc8, 
        B_DOUT(7) => nc20, B_DOUT(6) => nc10, B_DOUT(5) => nc24, 
        B_DOUT(4) => nc14, B_DOUT(3) => nc30, B_DOUT(2) => RD(38), 
        B_DOUT(1) => RD(37), B_DOUT(0) => RD(36), BUSY => OPEN, 
        A_CLK => RCLK, A_DOUT_CLK => \VCC\, A_ARST_N => \VCC\, 
        A_DOUT_EN => \VCC\, A_BLK(2) => REN, A_BLK(1) => \VCC\, 
        A_BLK(0) => \VCC\, A_DOUT_ARST_N => \VCC\, A_DOUT_SRST_N
         => \VCC\, A_DIN(17) => \GND\, A_DIN(16) => \GND\, 
        A_DIN(15) => \GND\, A_DIN(14) => \GND\, A_DIN(13) => 
        \GND\, A_DIN(12) => \GND\, A_DIN(11) => \GND\, A_DIN(10)
         => \GND\, A_DIN(9) => \GND\, A_DIN(8) => \GND\, A_DIN(7)
         => \GND\, A_DIN(6) => \GND\, A_DIN(5) => \GND\, A_DIN(4)
         => \GND\, A_DIN(3) => \GND\, A_DIN(2) => \GND\, A_DIN(1)
         => \GND\, A_DIN(0) => \GND\, A_ADDR(13) => RADDR(8), 
        A_ADDR(12) => RADDR(7), A_ADDR(11) => RADDR(6), 
        A_ADDR(10) => RADDR(5), A_ADDR(9) => RADDR(4), A_ADDR(8)
         => RADDR(3), A_ADDR(7) => RADDR(2), A_ADDR(6) => 
        RADDR(1), A_ADDR(5) => RADDR(0), A_ADDR(4) => \GND\, 
        A_ADDR(3) => \GND\, A_ADDR(2) => \GND\, A_ADDR(1) => 
        \GND\, A_ADDR(0) => \GND\, A_WEN(1) => \VCC\, A_WEN(0)
         => \VCC\, B_CLK => WCLK, B_DOUT_CLK => \VCC\, B_ARST_N
         => \VCC\, B_DOUT_EN => \VCC\, B_BLK(2) => WEN, B_BLK(1)
         => \VCC\, B_BLK(0) => \VCC\, B_DOUT_ARST_N => \VCC\, 
        B_DOUT_SRST_N => \VCC\, B_DIN(17) => \GND\, B_DIN(16) => 
        \GND\, B_DIN(15) => \GND\, B_DIN(14) => \GND\, B_DIN(13)
         => \GND\, B_DIN(12) => \GND\, B_DIN(11) => \GND\, 
        B_DIN(10) => \GND\, B_DIN(9) => \GND\, B_DIN(8) => \GND\, 
        B_DIN(7) => \GND\, B_DIN(6) => \GND\, B_DIN(5) => \GND\, 
        B_DIN(4) => \GND\, B_DIN(3) => \GND\, B_DIN(2) => WD(38), 
        B_DIN(1) => WD(37), B_DIN(0) => WD(36), B_ADDR(13) => 
        WADDR(8), B_ADDR(12) => WADDR(7), B_ADDR(11) => WADDR(6), 
        B_ADDR(10) => WADDR(5), B_ADDR(9) => WADDR(4), B_ADDR(8)
         => WADDR(3), B_ADDR(7) => WADDR(2), B_ADDR(6) => 
        WADDR(1), B_ADDR(5) => WADDR(0), B_ADDR(4) => \GND\, 
        B_ADDR(3) => \GND\, B_ADDR(2) => \GND\, B_ADDR(1) => 
        \GND\, B_ADDR(0) => \GND\, B_WEN(1) => \VCC\, B_WEN(0)
         => \VCC\, A_EN => \VCC\, A_DOUT_LAT => \VCC\, A_WIDTH(2)
         => \VCC\, A_WIDTH(1) => \GND\, A_WIDTH(0) => \VCC\, 
        A_WMODE => \GND\, B_EN => \VCC\, B_DOUT_LAT => \VCC\, 
        B_WIDTH(2) => \VCC\, B_WIDTH(1) => \GND\, B_WIDTH(0) => 
        \VCC\, B_WMODE => \GND\, SII_LOCK => \GND\);
    
    sf2_fifo_sf2_fifo_0_LSRAM_top_R0C0 : RAM1K18
      port map(A_DOUT(17) => RD(35), A_DOUT(16) => RD(34), 
        A_DOUT(15) => RD(33), A_DOUT(14) => RD(32), A_DOUT(13)
         => RD(31), A_DOUT(12) => RD(30), A_DOUT(11) => RD(29), 
        A_DOUT(10) => RD(28), A_DOUT(9) => RD(27), A_DOUT(8) => 
        RD(26), A_DOUT(7) => RD(25), A_DOUT(6) => RD(24), 
        A_DOUT(5) => RD(23), A_DOUT(4) => RD(22), A_DOUT(3) => 
        RD(21), A_DOUT(2) => RD(20), A_DOUT(1) => RD(19), 
        A_DOUT(0) => RD(18), B_DOUT(17) => RD(17), B_DOUT(16) => 
        RD(16), B_DOUT(15) => RD(15), B_DOUT(14) => RD(14), 
        B_DOUT(13) => RD(13), B_DOUT(12) => RD(12), B_DOUT(11)
         => RD(11), B_DOUT(10) => RD(10), B_DOUT(9) => RD(9), 
        B_DOUT(8) => RD(8), B_DOUT(7) => RD(7), B_DOUT(6) => 
        RD(6), B_DOUT(5) => RD(5), B_DOUT(4) => RD(4), B_DOUT(3)
         => RD(3), B_DOUT(2) => RD(2), B_DOUT(1) => RD(1), 
        B_DOUT(0) => RD(0), BUSY => OPEN, A_CLK => RCLK, 
        A_DOUT_CLK => \VCC\, A_ARST_N => \VCC\, A_DOUT_EN => 
        \VCC\, A_BLK(2) => REN, A_BLK(1) => \VCC\, A_BLK(0) => 
        \VCC\, A_DOUT_ARST_N => \VCC\, A_DOUT_SRST_N => \VCC\, 
        A_DIN(17) => WD(35), A_DIN(16) => WD(34), A_DIN(15) => 
        WD(33), A_DIN(14) => WD(32), A_DIN(13) => WD(31), 
        A_DIN(12) => WD(30), A_DIN(11) => WD(29), A_DIN(10) => 
        WD(28), A_DIN(9) => WD(27), A_DIN(8) => WD(26), A_DIN(7)
         => WD(25), A_DIN(6) => WD(24), A_DIN(5) => WD(23), 
        A_DIN(4) => WD(22), A_DIN(3) => WD(21), A_DIN(2) => 
        WD(20), A_DIN(1) => WD(19), A_DIN(0) => WD(18), 
        A_ADDR(13) => RADDR(8), A_ADDR(12) => RADDR(7), 
        A_ADDR(11) => RADDR(6), A_ADDR(10) => RADDR(5), A_ADDR(9)
         => RADDR(4), A_ADDR(8) => RADDR(3), A_ADDR(7) => 
        RADDR(2), A_ADDR(6) => RADDR(1), A_ADDR(5) => RADDR(0), 
        A_ADDR(4) => \GND\, A_ADDR(3) => \GND\, A_ADDR(2) => 
        \GND\, A_ADDR(1) => \GND\, A_ADDR(0) => \GND\, A_WEN(1)
         => \VCC\, A_WEN(0) => \VCC\, B_CLK => WCLK, B_DOUT_CLK
         => \VCC\, B_ARST_N => \VCC\, B_DOUT_EN => \VCC\, 
        B_BLK(2) => WEN, B_BLK(1) => \VCC\, B_BLK(0) => \VCC\, 
        B_DOUT_ARST_N => \VCC\, B_DOUT_SRST_N => \VCC\, B_DIN(17)
         => WD(17), B_DIN(16) => WD(16), B_DIN(15) => WD(15), 
        B_DIN(14) => WD(14), B_DIN(13) => WD(13), B_DIN(12) => 
        WD(12), B_DIN(11) => WD(11), B_DIN(10) => WD(10), 
        B_DIN(9) => WD(9), B_DIN(8) => WD(8), B_DIN(7) => WD(7), 
        B_DIN(6) => WD(6), B_DIN(5) => WD(5), B_DIN(4) => WD(4), 
        B_DIN(3) => WD(3), B_DIN(2) => WD(2), B_DIN(1) => WD(1), 
        B_DIN(0) => WD(0), B_ADDR(13) => WADDR(8), B_ADDR(12) => 
        WADDR(7), B_ADDR(11) => WADDR(6), B_ADDR(10) => WADDR(5), 
        B_ADDR(9) => WADDR(4), B_ADDR(8) => WADDR(3), B_ADDR(7)
         => WADDR(2), B_ADDR(6) => WADDR(1), B_ADDR(5) => 
        WADDR(0), B_ADDR(4) => \GND\, B_ADDR(3) => \GND\, 
        B_ADDR(2) => \GND\, B_ADDR(1) => \GND\, B_ADDR(0) => 
        \GND\, B_WEN(1) => \VCC\, B_WEN(0) => \VCC\, A_EN => 
        \VCC\, A_DOUT_LAT => \VCC\, A_WIDTH(2) => \VCC\, 
        A_WIDTH(1) => \GND\, A_WIDTH(0) => \VCC\, A_WMODE => 
        \GND\, B_EN => \VCC\, B_DOUT_LAT => \VCC\, B_WIDTH(2) => 
        \VCC\, B_WIDTH(1) => \GND\, B_WIDTH(0) => \VCC\, B_WMODE
         => \GND\, SII_LOCK => \GND\);
    
    GND_power_inst1 : GND
      port map( Y => GND_power_net1);

    VCC_power_inst1 : VCC
      port map( Y => VCC_power_net1);


end DEF_ARCH; 
