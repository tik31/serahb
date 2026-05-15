-- Version: v11.8 SP1 11.8.1.12

library ieee;
use ieee.std_logic_1164.all;
library smartfusion2;
use smartfusion2.all;

entity fifo4kx8_sf2_fifo4kx8_sf2_0_LSRAM_top is

    port( WD    : in    std_logic_vector(7 downto 0);
          RD    : out   std_logic_vector(7 downto 0);
          WADDR : in    std_logic_vector(11 downto 0);
          RADDR : in    std_logic_vector(11 downto 0);
          WEN   : in    std_logic;
          REN   : in    std_logic;
          CLK   : in    std_logic
        );

end fifo4kx8_sf2_fifo4kx8_sf2_0_LSRAM_top;

architecture DEF_ARCH of fifo4kx8_sf2_fifo4kx8_sf2_0_LSRAM_top is 

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
    signal nc47, nc34, nc60, nc64, nc9, nc13, nc23, nc55, nc33, 
        nc16, nc26, nc45, nc58, nc63, nc27, nc17, nc36, nc48, 
        nc37, nc5, nc52, nc51, nc4, nc42, nc41, nc59, nc25, nc15, 
        nc35, nc49, nc28, nc18, nc38, nc1, nc2, nc50, nc22, nc12, 
        nc21, nc11, nc54, nc3, nc32, nc40, nc31, nc44, nc7, nc6, 
        nc62, nc61, nc19, nc29, nc53, nc39, nc8, nc43, nc56, nc20, 
        nc10, nc57, nc24, nc14, nc46, nc30 : std_logic;

begin 

    \GND\ <= GND_power_net1;
    \VCC\ <= VCC_power_net1;
    ADLIB_VCC <= VCC_power_net1;

    fifo4kx8_sf2_fifo4kx8_sf2_0_LSRAM_top_R0C0 : RAM1K18
      port map(A_DOUT(17) => nc47, A_DOUT(16) => nc34, A_DOUT(15)
         => nc60, A_DOUT(14) => nc64, A_DOUT(13) => nc9, 
        A_DOUT(12) => nc13, A_DOUT(11) => nc23, A_DOUT(10) => 
        nc55, A_DOUT(9) => nc33, A_DOUT(8) => nc16, A_DOUT(7) => 
        nc26, A_DOUT(6) => nc45, A_DOUT(5) => nc58, A_DOUT(4) => 
        nc63, A_DOUT(3) => RD(3), A_DOUT(2) => RD(2), A_DOUT(1)
         => RD(1), A_DOUT(0) => RD(0), B_DOUT(17) => nc27, 
        B_DOUT(16) => nc17, B_DOUT(15) => nc36, B_DOUT(14) => 
        nc48, B_DOUT(13) => nc37, B_DOUT(12) => nc5, B_DOUT(11)
         => nc52, B_DOUT(10) => nc51, B_DOUT(9) => nc4, B_DOUT(8)
         => nc42, B_DOUT(7) => nc41, B_DOUT(6) => nc59, B_DOUT(5)
         => nc25, B_DOUT(4) => nc15, B_DOUT(3) => nc35, B_DOUT(2)
         => nc49, B_DOUT(1) => nc28, B_DOUT(0) => nc18, BUSY => 
        OPEN, A_CLK => CLK, A_DOUT_CLK => \VCC\, A_ARST_N => 
        \VCC\, A_DOUT_EN => \VCC\, A_BLK(2) => REN, A_BLK(1) => 
        \VCC\, A_BLK(0) => \VCC\, A_DOUT_ARST_N => \VCC\, 
        A_DOUT_SRST_N => \VCC\, A_DIN(17) => \GND\, A_DIN(16) => 
        \GND\, A_DIN(15) => \GND\, A_DIN(14) => \GND\, A_DIN(13)
         => \GND\, A_DIN(12) => \GND\, A_DIN(11) => \GND\, 
        A_DIN(10) => \GND\, A_DIN(9) => \GND\, A_DIN(8) => \GND\, 
        A_DIN(7) => \GND\, A_DIN(6) => \GND\, A_DIN(5) => \GND\, 
        A_DIN(4) => \GND\, A_DIN(3) => \GND\, A_DIN(2) => \GND\, 
        A_DIN(1) => \GND\, A_DIN(0) => \GND\, A_ADDR(13) => 
        RADDR(11), A_ADDR(12) => RADDR(10), A_ADDR(11) => 
        RADDR(9), A_ADDR(10) => RADDR(8), A_ADDR(9) => RADDR(7), 
        A_ADDR(8) => RADDR(6), A_ADDR(7) => RADDR(5), A_ADDR(6)
         => RADDR(4), A_ADDR(5) => RADDR(3), A_ADDR(4) => 
        RADDR(2), A_ADDR(3) => RADDR(1), A_ADDR(2) => RADDR(0), 
        A_ADDR(1) => \GND\, A_ADDR(0) => \GND\, A_WEN(1) => \GND\, 
        A_WEN(0) => \GND\, B_CLK => CLK, B_DOUT_CLK => \VCC\, 
        B_ARST_N => \VCC\, B_DOUT_EN => \VCC\, B_BLK(2) => WEN, 
        B_BLK(1) => \VCC\, B_BLK(0) => \VCC\, B_DOUT_ARST_N => 
        \GND\, B_DOUT_SRST_N => \VCC\, B_DIN(17) => \GND\, 
        B_DIN(16) => \GND\, B_DIN(15) => \GND\, B_DIN(14) => 
        \GND\, B_DIN(13) => \GND\, B_DIN(12) => \GND\, B_DIN(11)
         => \GND\, B_DIN(10) => \GND\, B_DIN(9) => \GND\, 
        B_DIN(8) => \GND\, B_DIN(7) => \GND\, B_DIN(6) => \GND\, 
        B_DIN(5) => \GND\, B_DIN(4) => \GND\, B_DIN(3) => WD(3), 
        B_DIN(2) => WD(2), B_DIN(1) => WD(1), B_DIN(0) => WD(0), 
        B_ADDR(13) => WADDR(11), B_ADDR(12) => WADDR(10), 
        B_ADDR(11) => WADDR(9), B_ADDR(10) => WADDR(8), B_ADDR(9)
         => WADDR(7), B_ADDR(8) => WADDR(6), B_ADDR(7) => 
        WADDR(5), B_ADDR(6) => WADDR(4), B_ADDR(5) => WADDR(3), 
        B_ADDR(4) => WADDR(2), B_ADDR(3) => WADDR(1), B_ADDR(2)
         => WADDR(0), B_ADDR(1) => \GND\, B_ADDR(0) => \GND\, 
        B_WEN(1) => \GND\, B_WEN(0) => \VCC\, A_EN => \VCC\, 
        A_DOUT_LAT => \VCC\, A_WIDTH(2) => \GND\, A_WIDTH(1) => 
        \VCC\, A_WIDTH(0) => \GND\, A_WMODE => \GND\, B_EN => 
        \VCC\, B_DOUT_LAT => \VCC\, B_WIDTH(2) => \GND\, 
        B_WIDTH(1) => \VCC\, B_WIDTH(0) => \GND\, B_WMODE => 
        \GND\, SII_LOCK => \GND\);
    
    fifo4kx8_sf2_fifo4kx8_sf2_0_LSRAM_top_R0C1 : RAM1K18
      port map(A_DOUT(17) => nc38, A_DOUT(16) => nc1, A_DOUT(15)
         => nc2, A_DOUT(14) => nc50, A_DOUT(13) => nc22, 
        A_DOUT(12) => nc12, A_DOUT(11) => nc21, A_DOUT(10) => 
        nc11, A_DOUT(9) => nc54, A_DOUT(8) => nc3, A_DOUT(7) => 
        nc32, A_DOUT(6) => nc40, A_DOUT(5) => nc31, A_DOUT(4) => 
        nc44, A_DOUT(3) => RD(7), A_DOUT(2) => RD(6), A_DOUT(1)
         => RD(5), A_DOUT(0) => RD(4), B_DOUT(17) => nc7, 
        B_DOUT(16) => nc6, B_DOUT(15) => nc62, B_DOUT(14) => nc61, 
        B_DOUT(13) => nc19, B_DOUT(12) => nc29, B_DOUT(11) => 
        nc53, B_DOUT(10) => nc39, B_DOUT(9) => nc8, B_DOUT(8) => 
        nc43, B_DOUT(7) => nc56, B_DOUT(6) => nc20, B_DOUT(5) => 
        nc10, B_DOUT(4) => nc57, B_DOUT(3) => nc24, B_DOUT(2) => 
        nc14, B_DOUT(1) => nc46, B_DOUT(0) => nc30, BUSY => OPEN, 
        A_CLK => CLK, A_DOUT_CLK => \VCC\, A_ARST_N => \VCC\, 
        A_DOUT_EN => \VCC\, A_BLK(2) => REN, A_BLK(1) => \VCC\, 
        A_BLK(0) => \VCC\, A_DOUT_ARST_N => \VCC\, A_DOUT_SRST_N
         => \VCC\, A_DIN(17) => \GND\, A_DIN(16) => \GND\, 
        A_DIN(15) => \GND\, A_DIN(14) => \GND\, A_DIN(13) => 
        \GND\, A_DIN(12) => \GND\, A_DIN(11) => \GND\, A_DIN(10)
         => \GND\, A_DIN(9) => \GND\, A_DIN(8) => \GND\, A_DIN(7)
         => \GND\, A_DIN(6) => \GND\, A_DIN(5) => \GND\, A_DIN(4)
         => \GND\, A_DIN(3) => \GND\, A_DIN(2) => \GND\, A_DIN(1)
         => \GND\, A_DIN(0) => \GND\, A_ADDR(13) => RADDR(11), 
        A_ADDR(12) => RADDR(10), A_ADDR(11) => RADDR(9), 
        A_ADDR(10) => RADDR(8), A_ADDR(9) => RADDR(7), A_ADDR(8)
         => RADDR(6), A_ADDR(7) => RADDR(5), A_ADDR(6) => 
        RADDR(4), A_ADDR(5) => RADDR(3), A_ADDR(4) => RADDR(2), 
        A_ADDR(3) => RADDR(1), A_ADDR(2) => RADDR(0), A_ADDR(1)
         => \GND\, A_ADDR(0) => \GND\, A_WEN(1) => \GND\, 
        A_WEN(0) => \GND\, B_CLK => CLK, B_DOUT_CLK => \VCC\, 
        B_ARST_N => \VCC\, B_DOUT_EN => \VCC\, B_BLK(2) => WEN, 
        B_BLK(1) => \VCC\, B_BLK(0) => \VCC\, B_DOUT_ARST_N => 
        \GND\, B_DOUT_SRST_N => \VCC\, B_DIN(17) => \GND\, 
        B_DIN(16) => \GND\, B_DIN(15) => \GND\, B_DIN(14) => 
        \GND\, B_DIN(13) => \GND\, B_DIN(12) => \GND\, B_DIN(11)
         => \GND\, B_DIN(10) => \GND\, B_DIN(9) => \GND\, 
        B_DIN(8) => \GND\, B_DIN(7) => \GND\, B_DIN(6) => \GND\, 
        B_DIN(5) => \GND\, B_DIN(4) => \GND\, B_DIN(3) => WD(7), 
        B_DIN(2) => WD(6), B_DIN(1) => WD(5), B_DIN(0) => WD(4), 
        B_ADDR(13) => WADDR(11), B_ADDR(12) => WADDR(10), 
        B_ADDR(11) => WADDR(9), B_ADDR(10) => WADDR(8), B_ADDR(9)
         => WADDR(7), B_ADDR(8) => WADDR(6), B_ADDR(7) => 
        WADDR(5), B_ADDR(6) => WADDR(4), B_ADDR(5) => WADDR(3), 
        B_ADDR(4) => WADDR(2), B_ADDR(3) => WADDR(1), B_ADDR(2)
         => WADDR(0), B_ADDR(1) => \GND\, B_ADDR(0) => \GND\, 
        B_WEN(1) => \GND\, B_WEN(0) => \VCC\, A_EN => \VCC\, 
        A_DOUT_LAT => \VCC\, A_WIDTH(2) => \GND\, A_WIDTH(1) => 
        \VCC\, A_WIDTH(0) => \GND\, A_WMODE => \GND\, B_EN => 
        \VCC\, B_DOUT_LAT => \VCC\, B_WIDTH(2) => \GND\, 
        B_WIDTH(1) => \VCC\, B_WIDTH(0) => \GND\, B_WMODE => 
        \GND\, SII_LOCK => \GND\);
    
    GND_power_inst1 : GND
      port map( Y => GND_power_net1);

    VCC_power_inst1 : VCC
      port map( Y => VCC_power_net1);


end DEF_ARCH; 
