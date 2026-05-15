library ieee;
use ieee.std_logic_1164.all;

library PolarFire;
--use PolarFire.RAM1K20;
--use PolarFire.RAM64X12;

entity igloo2_syncram is
	generic (
		abits 		: integer := 10; 
		dbits 		: integer := 8; 
		ecc 		: integer range 0 to 1 := 0;
		doutpipe 	: integer := 0; 
		eccpipe 	: integer := 0
	);
	port (
		clk      	: in  std_ulogic;
		address  	: in  std_logic_vector((abits -1) downto 0);
		datain   	: in  std_logic_vector((dbits -1) downto 0);
		dataout  	: out std_logic_vector((dbits -1) downto 0);
		enable   	: in  std_ulogic;
		write    	: in  std_ulogic;
		error    	: out std_logic_vector(1 downto 0)
	);
end entity;

architecture rtl of igloo2_syncram is

	component RAM64x12
		port (
			BLK_EN 			: in 	std_ulogic;
			W_CLK 			: in 	std_ulogic;
			W_ADDR 			: in 	std_logic_vector (5 downto 0);
			W_DATA 			: in 	std_logic_vector (11 downto 0);
			W_EN 			: in 	std_ulogic;
			R_CLK 			: in 	std_ulogic;
			R_ADDR 			: in 	std_logic_vector (5 downto 0);
			R_DATA 			: out	std_logic_vector (11 downto 0);
			R_ADDR_EN 		: in 	std_ulogic;
			R_ADDR_BYPASS	: in 	std_ulogic;
			R_ADDR_SL_N 	: in 	std_ulogic;
			R_ADDR_AL_N 	: in 	std_ulogic;
			R_ADDR_AD_N 	: in 	std_ulogic;
			R_ADDR_SD 		: in 	std_ulogic;
			R_DATA_BYPASS	: in 	std_ulogic;
			R_DATA_EN 		: in 	std_ulogic;
			R_DATA_SD 		: in 	std_ulogic;
			R_DATA_SL_N		: in 	std_ulogic;
			R_DATA_AL_N 	: in 	std_ulogic;
			R_DATA_AD_N 	: in 	std_ulogic;
			BUSY_FB 		: in 	std_ulogic;
			ACCESS_BUSY 	: out 	std_ulogic
		);
	end component;

	component RAM1K20 is
		port (
			A_ADDR 			: in  std_logic_vector(13 downto 0);
			A_BLK_EN 		: in  std_logic_vector(2 downto 0);
			A_CLK 			: in  std_logic;
			A_DIN 			: in  std_logic_vector(19 downto 0);
			A_DOUT 			: out std_logic_vector(19 downto 0);
			A_WEN 			: in  std_logic_vector(1 downto 0);
			A_REN 			: in  std_logic;
			A_WIDTH 		: in  std_logic_vector(2 downto 0);
			A_WMODE 		: in  std_logic_vector(1 downto 0);
			A_BYPASS 		: in  std_logic;
			A_DOUT_EN 		: in  std_logic;
			A_DOUT_SRST_N 	: in  std_logic;
			A_DOUT_ARST_N 	: in  std_logic;

			B_ADDR 			: in  std_logic_vector(13 downto 0);
			B_BLK_EN 		: in  std_logic_vector(2 downto 0);
			B_CLK 			: in  std_logic;
			B_DIN 			: in  std_logic_vector(19 downto 0);
			B_DOUT 			: out std_logic_vector(19 downto 0);
			B_WEN 			: in  std_logic_vector(1 downto 0);
			B_REN 			: in  std_logic;
			B_WIDTH 		: in  std_logic_vector(2 downto 0);
			B_WMODE 		: in  std_logic_vector(1 downto 0);
			B_BYPASS 		: in  std_logic;
			B_DOUT_EN 		: in  std_logic;
			B_DOUT_SRST_N 	: in  std_logic;
			B_DOUT_ARST_N 	: in  std_logic;

			ECC_EN 			: in  std_logic;
			ECC_BYPASS 		: in  std_logic;
			SB_CORRECT 		: out std_logic;
			DB_DETECT 		: out std_logic;
			BUSY_FB 		: in  std_logic;
			ACCESS_BUSY 	: out std_logic
		);
	end component RAM1K20;

	signal vcc, gnd : std_ulogic;
	signal do, di : std_logic_vector(dbits+80 downto 0);
	signal fake : std_logic_vector(2047 downto 0);
	signal xa, ya : std_logic_vector(14 downto 0);

	signal bypass : std_logic;
	signal ecc_bypass : std_logic;
	signal ecc_en : std_logic;


begin
	error <= "00";
	vcc <= '1'; gnd <= '0'; dataout <= do(dbits-1 downto 0); di(dbits-1 downto 0) <= datain;
	di(dbits+80 downto dbits) <= (others => '0'); xa(abits-1 downto 0) <= address;
	xa(14 downto abits) <= (others => '0'); ya(abits-1 downto 0) <= address;
	ya(14 downto abits) <= (others => '0');

	ecc_bypass <= '0' when eccpipe = 1 else '1';
	ecc_en <= '1' when eccpipe = 1 else '0';
	bypass <= '0' when doutpipe = 1 else '1';

	a6 : if (abits <= 6 and ecc = 0) generate
		x : for i in 0 to ((dbits-1)/12) generate
			r0 : RAM64x12 port map (
				BLK_EN => vcc, BUSY_FB => '0', R_ADDR => xa(5 downto 0), R_ADDR_AD_N => vcc,
				R_DATA_AD_N => vcc, R_ADDR_BYPASS => gnd, R_ADDR_EN => vcc, R_ADDR_AL_N => vcc,
				R_ADDR_SD => vcc, R_ADDR_SL_N => vcc, R_CLK => clk, 
				R_DATA_AL_N => vcc, R_DATA_BYPASS => bypass, R_DATA_EN => vcc, 
				R_DATA_SD => gnd, R_DATA_SL_N => vcc, W_ADDR => ya(5 downto 0), 
				W_CLK => clk, W_DATA => di(i*12+11 downto i*12), W_EN => write, 
				R_DATA => do(i*12+11 downto i*12), ACCESS_BUSY => open
			);
		end generate;
		do(dbits+40 downto 40*(((dbits-1)/40)+1)) <= (others => '0');
	end generate;

	a9d40 : if (abits > 6 and abits <= 9 and ecc = 0) generate
		x : for i in 0 to ((dbits-1)/40) generate
			r0 : RAM1K20 port map (
				A_ADDR => xa(8 downto 0) & "00000", A_BLK_EN => enable & vcc & vcc, A_CLK => clk,
				A_DIN => di(i*40+39 downto i*40+20), A_DOUT => do(i*40+39 downto i*40+20),
				A_WEN => write & write, A_REN => enable and not(write), A_WIDTH => vcc & gnd & vcc, A_WMODE => gnd & gnd,
				A_BYPASS => bypass, A_DOUT_EN => bypass, A_DOUT_SRST_N => vcc, A_DOUT_ARST_N => vcc,

				B_ADDR => xa(8 downto 0) & "00000", B_BLK_EN => enable & vcc & vcc, B_CLK => clk,
				B_DIN => di(i*40+19 downto i*40), B_DOUT => do(i*40+19 downto i*40),
				B_WEN => write & write, B_REN => gnd, B_WIDTH => vcc & gnd & vcc, B_WMODE => gnd & gnd,
				B_BYPASS => bypass, B_DOUT_EN => bypass, B_DOUT_SRST_N => vcc, B_DOUT_ARST_N => vcc,

				ECC_EN => ecc_en, ECC_BYPASS => '1', SB_CORRECT => open, DB_DETECT => open, 
				BUSY_FB => '0',	ACCESS_BUSY => open
			);
		end generate;
	end generate;

	a10d20 : if (abits = 10 and ecc = 0) generate
		x : for i in 0 to ((dbits-1)/20) generate
			r0 : RAM1K20 port map (
				A_ADDR => xa(9 downto 0) & "0000", A_BLK_EN => enable & vcc & vcc, A_CLK => clk,
				A_DIN => di(i*20+19 downto i*20), A_DOUT => open,
				A_WEN => write & write, A_REN => enable and not(write), A_WIDTH => vcc & gnd & gnd, A_WMODE => gnd & gnd,
				A_BYPASS => bypass, A_DOUT_EN => bypass, A_DOUT_SRST_N => vcc, A_DOUT_ARST_N => vcc,

				B_ADDR => xa(9 downto 0) & "0000", B_BLK_EN => enable & vcc & vcc, B_CLK => clk,
				B_DIN => (others => gnd), B_DOUT => do(i*20+19 downto i*20),
				B_WEN => (others => gnd), B_REN => enable, B_WIDTH => vcc & gnd & gnd, B_WMODE => gnd & gnd,
				B_BYPASS => bypass, B_DOUT_EN => bypass, B_DOUT_SRST_N => vcc, B_DOUT_ARST_N => vcc,

				ECC_EN => ecc_en, ECC_BYPASS => '1', SB_CORRECT => open, DB_DETECT => open, 
				BUSY_FB => '0',	ACCESS_BUSY => open
			);
		end generate;
	end generate;

	a11d10 : if (abits = 11 and ecc = 0) generate
		x : for i in 0 to ((dbits-1)/10) generate
			r0 : RAM1K20 port map (
				A_ADDR => xa(10 downto 0) & "000", A_BLK_EN => enable & vcc & vcc, A_CLK => clk,
				A_DIN => "0000000000" & di(i*10+9 downto i*10), A_DOUT => open,
				A_WEN => gnd & write, A_REN => enable and not(write), A_WIDTH => gnd & vcc & vcc, A_WMODE => gnd & gnd,
				A_BYPASS => bypass, A_DOUT_EN => bypass, A_DOUT_SRST_N => vcc, A_DOUT_ARST_N => vcc,

				B_ADDR => xa(10 downto 0) & "000", B_BLK_EN => enable & vcc & vcc, B_CLK => clk,
				B_DIN => (others => gnd), B_DOUT => fake(20*i+19 downto i*20),
				B_WEN => (others => gnd), B_REN => enable, B_WIDTH => gnd & vcc & vcc, B_WMODE => gnd & gnd,
				B_BYPASS => bypass, B_DOUT_EN => bypass, B_DOUT_SRST_N => vcc, B_DOUT_ARST_N => vcc,

				ECC_EN => ecc_en, ECC_BYPASS => '1', SB_CORRECT => open, DB_DETECT => open, 
				BUSY_FB => '0',	ACCESS_BUSY => open
			);
			do(i*10+9 downto i*10) <= fake(20*i+9 downto i*20);
		end generate;
	end generate;

	a12d5 : if (abits = 12 and ecc = 0) generate
		x : for i in 0 to ((dbits-1)/5) generate
			r0 : RAM1K20 port map (
				A_ADDR => xa(11 downto 0) & "00", A_BLK_EN => enable & vcc & vcc, A_CLK => clk,
				A_DIN => "000000000000000" & di(i*5+4 downto i*5), A_DOUT => open,
				A_WEN => gnd & write, A_REN => enable and not(write), A_WIDTH => gnd & vcc & gnd, A_WMODE => gnd & gnd,
				A_BYPASS => bypass, A_DOUT_EN => bypass, A_DOUT_SRST_N => vcc, A_DOUT_ARST_N => vcc,

				B_ADDR => xa(11 downto 0) & "00", B_BLK_EN => enable & vcc & vcc, B_CLK => clk,
				B_DIN => (others => gnd), B_DOUT => fake(20*i+19 downto i*20),
				B_WEN => (others => gnd), B_REN => enable, B_WIDTH => gnd & vcc & gnd, B_WMODE => gnd & gnd,
				B_BYPASS => bypass, B_DOUT_EN => bypass, B_DOUT_SRST_N => vcc, B_DOUT_ARST_N => vcc,

				ECC_EN => ecc_en, ECC_BYPASS => '1', SB_CORRECT => open, DB_DETECT => open, 
				BUSY_FB => '0',	ACCESS_BUSY => open
			);
			do(i*5+4 downto i*5) <= fake(20*i+4 downto i*20);
		end generate;
	end generate;

	a13d2 : if (abits = 13 and ecc = 0) generate
		x : for i in 0 to ((dbits-1)/2) generate
			r0 : RAM1K20 port map (
				A_ADDR => xa(12 downto 0) & "0", A_BLK_EN => enable & vcc & vcc, A_CLK => clk,
				A_DIN => "000000000000000000" & di(i*2+1 downto i*2), A_DOUT => open,
				A_WEN => gnd & write, A_REN => enable and not(write), A_WIDTH => gnd & gnd & vcc, A_WMODE => gnd & gnd,
				A_BYPASS => bypass, A_DOUT_EN => bypass, A_DOUT_SRST_N => vcc, A_DOUT_ARST_N => vcc,

				B_ADDR => xa(12 downto 0) & "0", B_BLK_EN => enable & vcc & vcc, B_CLK => clk,
				B_DIN => (others => gnd), B_DOUT => fake(20*i+19 downto i*20),
				B_WEN => (others => gnd), B_REN => enable, B_WIDTH => gnd & gnd & vcc, B_WMODE => gnd & gnd,
				B_BYPASS => bypass, B_DOUT_EN => bypass, B_DOUT_SRST_N => vcc, B_DOUT_ARST_N => vcc,

				ECC_EN => ecc_en, ECC_BYPASS => '1', SB_CORRECT => open, DB_DETECT => open, 
				BUSY_FB => '0',	ACCESS_BUSY => open
			);
			do(i*2+1 downto i*2) <= fake(20*i+1 downto i*20);
		end generate;
	end generate;

	a14d1 : if (abits = 14 and ecc = 0) generate
		x : for i in 0 to ((dbits-1)/1) generate
			r0 : RAM1K20 port map (
				A_ADDR => xa(13 downto 0), A_BLK_EN => enable & vcc & vcc, A_CLK => clk,
				A_DIN => "0000000000000000000" & di(i*1 downto i), A_DOUT => open,
				A_WEN => gnd & write, A_REN => enable and not(write), A_WIDTH => gnd & gnd & gnd, A_WMODE => gnd & gnd,
				A_BYPASS => bypass, A_DOUT_EN => bypass, A_DOUT_SRST_N => vcc, A_DOUT_ARST_N => vcc,

				B_ADDR => xa(13 downto 0), B_BLK_EN => enable & vcc & vcc, B_CLK => clk,
				B_DIN => (others => gnd), B_DOUT => fake(20*i+19 downto i*20),
				B_WEN => (others => gnd), B_REN => enable, B_WIDTH => gnd & gnd & gnd, B_WMODE => gnd & gnd,
				B_BYPASS => bypass, B_DOUT_EN => bypass, B_DOUT_SRST_N => vcc, B_DOUT_ARST_N => vcc,

				ECC_EN => ecc_en, ECC_BYPASS => '1', SB_CORRECT => open, DB_DETECT => open, 
				BUSY_FB => '0',	ACCESS_BUSY => open
			);
			do(i*1 downto i*1) <= fake(20*i downto i*20);
		end generate;
	end generate;
end;

library ieee;
use ieee.std_logic_1164.all;

library PolarFire;
--use PolarFire.RAM1K20;
--use PolarFire.RAM64X12;

entity igloo2_syncram_dp is
	generic ( abits : integer := 6; dbits : integer := 8; doutpipe : integer := 0);
	port (
		clk1     	: in 	std_ulogic;
		address1 	: in 	std_logic_vector((abits -1) downto 0);
		datain1  	: in 	std_logic_vector((dbits -1) downto 0);
		dataout1 	: out 	std_logic_vector((dbits -1) downto 0);
		enable1  	: in 	std_ulogic;
		write1   	: in 	std_ulogic;
		clk2     	: in 	std_ulogic;
		address2 	: in 	std_logic_vector((abits -1) downto 0);
		datain2  	: in 	std_logic_vector((dbits -1) downto 0);
		dataout2 	: out 	std_logic_vector((dbits -1) downto 0);
		enable2  	: in 	std_ulogic;
		write2   	: in 	std_ulogic);
end entity;

architecture rtl of igloo2_syncram_dp is

	component RAM64x12
		port (
			BLK_EN 			: in 	std_ulogic;
			W_CLK 			: in 	std_ulogic;
			W_ADDR 			: in 	std_logic_vector (5 downto 0);
			W_DATA 			: in 	std_logic_vector (11 downto 0);
			W_EN 			: in 	std_ulogic;
			R_CLK 			: in 	std_ulogic;
			R_ADDR 			: in 	std_logic_vector (5 downto 0);
			R_DATA 			: out	std_logic_vector (11 downto 0);
			R_ADDR_EN 		: in 	std_ulogic;
			R_ADDR_BYPASS	: in 	std_ulogic;
			R_ADDR_SL_N 	: in 	std_ulogic;
			R_ADDR_AL_N 	: in 	std_ulogic;
			R_ADDR_AD_N 	: in 	std_ulogic;
			R_ADDR_SD 		: in 	std_ulogic;
			R_DATA_BYPASS	: in 	std_ulogic;
			R_DATA_EN 		: in 	std_ulogic;
			R_DATA_SD 		: in 	std_ulogic;
			R_DATA_SL_N		: in 	std_ulogic;
			R_DATA_AL_N 	: in 	std_ulogic;
			R_DATA_AD_N 	: in 	std_ulogic;
			BUSY_FB 		: in 	std_ulogic;
			ACCESS_BUSY 	: out 	std_ulogic
		);
	end component;

	component RAM1K20 is
		port (
			A_ADDR 			: in  std_logic_vector(13 downto 0);
			A_BLK_EN 		: in  std_logic_vector(2 downto 0);
			A_CLK 			: in  std_logic;
			A_DIN 			: in  std_logic_vector(19 downto 0);
			A_DOUT 			: out std_logic_vector(19 downto 0);
			A_WEN 			: in  std_logic_vector(1 downto 0);
			A_REN 			: in  std_logic;
			A_WIDTH 		: in  std_logic_vector(2 downto 0);
			A_WMODE 		: in  std_logic_vector(1 downto 0);
			A_BYPASS 		: in  std_logic;
			A_DOUT_EN 		: in  std_logic;
			A_DOUT_SRST_N 	: in  std_logic;
			A_DOUT_ARST_N 	: in  std_logic;

			B_ADDR 			: in  std_logic_vector(13 downto 0);
			B_BLK_EN 		: in  std_logic_vector(2 downto 0);
			B_CLK 			: in  std_logic;
			B_DIN 			: in  std_logic_vector(19 downto 0);
			B_DOUT 			: out std_logic_vector(19 downto 0);
			B_WEN 			: in  std_logic_vector(1 downto 0);
			B_REN 			: in  std_logic;
			B_WIDTH 		: in  std_logic_vector(2 downto 0);
			B_WMODE 		: in  std_logic_vector(1 downto 0);
			B_BYPASS 		: in  std_logic;
			B_DOUT_EN 		: in  std_logic;
			B_DOUT_SRST_N 	: in  std_logic;
			B_DOUT_ARST_N 	: in  std_logic;

			ECC_EN 			: in  std_logic;
			ECC_BYPASS 		: in  std_logic;
			SB_CORRECT 		: out std_logic;
			DB_DETECT 		: out std_logic;
			BUSY_FB 		: in  std_logic;
			ACCESS_BUSY 	: out std_logic
		);
	end component RAM1K20;

	signal vcc, gnd : std_ulogic;
	signal do1, di1, di2, do2 : std_logic_vector(dbits+80 downto 0);
	signal fake1, fake2 : std_logic_vector(2047 downto 0);
	signal in_fake1, in_fake2 : std_logic_vector(2047 downto 0);
	signal xa, ya : std_logic_vector(14 downto 0);

	signal bypass : std_logic;

begin

	vcc <= '1'; gnd <= '0'; 
	di1(dbits-1 downto 0) <= datain1; di1(dbits+80 downto dbits) <= (others => '0');
	di2(dbits-1 downto 0) <= datain2; di2(dbits+80 downto dbits) <= (others => '0');
	xa(abits-1 downto 0) <= address1; xa(14 downto abits) <= (others => '0'); 
	ya(abits-1 downto 0) <= address2; ya(14 downto abits) <= (others => '0');

	bypass <= '0' when doutpipe = 1 else '1';

	a10d20 : if (abits <= 10) generate
		x : for i in 0 to ((dbits-1)/20) generate
			r0 : RAM1K20 port map (
				A_ADDR => xa(9 downto 0) & "0000", A_BLK_EN => enable1 & vcc & vcc, A_CLK => clk1,
				A_DIN => di1(i*20+19 downto i*20), A_DOUT => do1(20*i+19 downto i*20),
				A_WEN => write1 & write1, A_REN => enable1 and not(write1), A_WIDTH => vcc & gnd & gnd, A_WMODE => gnd & gnd,
				A_BYPASS => bypass, A_DOUT_EN => bypass, A_DOUT_SRST_N => vcc, A_DOUT_ARST_N => vcc,

				B_ADDR => ya(9 downto 0) & "0000", B_BLK_EN => enable2 & vcc & vcc, B_CLK => clk2,
				B_DIN => di2(i*20+19 downto i*20), B_DOUT => do2(20*i+19 downto i*20),
				B_WEN => write2 & write2, B_REN => enable2, B_WIDTH => vcc & gnd & gnd, B_WMODE => gnd & gnd,
				B_BYPASS => bypass, B_DOUT_EN => bypass, B_DOUT_SRST_N => vcc, B_DOUT_ARST_N => vcc,

				ECC_EN => gnd, ECC_BYPASS => '1', SB_CORRECT => open, DB_DETECT => open, 
				BUSY_FB => '0',	ACCESS_BUSY => open
			);
			dataout1(i*20+19 downto i*20) <= do1(20*i+19 downto i*20);
			dataout2(i*20+19 downto i*20) <= do2(20*i+19 downto i*20);
		end generate;
	end generate;

	a11d10 : if (abits = 11) generate
		x : for i in 0 to ((dbits-1)/10) generate
			in_fake1(i*20+19 downto i*20) <= "0000000000" & di1(i*10+9 downto i*10);
			r0 : RAM1K20 port map (
				A_ADDR => xa(10 downto 0) & "000", A_BLK_EN => enable1 & vcc & vcc, A_CLK => clk1,
				--A_DIN => "0000000000" & di1(i*10+9 downto i*10), A_DOUT => fake1(20*i+19 downto i*20),
				A_DIN => in_fake1(i*20+19 downto i*20), A_DOUT => fake1(20*i+19 downto i*20),
				A_WEN => gnd & write1, A_REN => enable1 and not(write1), A_WIDTH => gnd & vcc & vcc, A_WMODE => gnd & gnd,
				A_BYPASS => bypass, A_DOUT_EN => bypass, A_DOUT_SRST_N => vcc, A_DOUT_ARST_N => vcc,

				B_ADDR => ya(10 downto 0) & "000", B_BLK_EN => enable2 & vcc & vcc, B_CLK => clk2,
				B_DIN => "0000000000" & di2(i*10+9 downto i*10), B_DOUT => fake2(20*i+19 downto i*20),
				B_WEN => gnd & write2, B_REN => enable2, B_WIDTH => gnd & vcc & vcc, B_WMODE => gnd & gnd,
				B_BYPASS => bypass, B_DOUT_EN => bypass, B_DOUT_SRST_N => vcc, B_DOUT_ARST_N => vcc,

				ECC_EN => gnd, ECC_BYPASS => '1', SB_CORRECT => open, DB_DETECT => open, 
				BUSY_FB => '0',	ACCESS_BUSY => open
			);
			dataout1(i*10+9 downto i*10) <= fake1(20*i+9 downto i*20);
			dataout2(i*10+9 downto i*10) <= fake2(20*i+9 downto i*20);
		end generate;
	end generate;

	a12d5 : if (abits = 12) generate
		x : for i in 0 to ((dbits-1)/5) generate
			in_fake1(i*20+19 downto i*20) <= "000000000000000" & di1(i*5+4 downto i*5);
			r0 : RAM1K20 port map (
				A_ADDR => xa(11 downto 0) & "00", A_BLK_EN => enable1 & vcc & vcc, A_CLK => clk1,
				A_DIN => in_fake1(i*20+19 downto i*20), A_DOUT => fake1(20*i+19 downto i*20),
				A_WEN => gnd & write1, A_REN => enable1 and not(write1), A_WIDTH => gnd & vcc & gnd, A_WMODE => gnd & gnd,
				A_BYPASS => bypass, A_DOUT_EN => bypass, A_DOUT_SRST_N => vcc, A_DOUT_ARST_N => vcc,

				B_ADDR => ya(11 downto 0) & "00", B_BLK_EN => enable2 & vcc & vcc, B_CLK => clk2,
				B_DIN => "000000000000000" & di2(i*5+4 downto i*5), B_DOUT => fake2(20*i+19 downto i*20),
				B_WEN => gnd & write2, B_REN => enable2, B_WIDTH => gnd & vcc & gnd, B_WMODE => gnd & gnd,
				B_BYPASS => bypass, B_DOUT_EN => bypass, B_DOUT_SRST_N => vcc, B_DOUT_ARST_N => vcc,

				ECC_EN => gnd, ECC_BYPASS => '1', SB_CORRECT => open, DB_DETECT => open, 
				BUSY_FB => '0',	ACCESS_BUSY => open
			);
			dataout1(i*5+4 downto i*5) <= fake1(20*i+4 downto i*20);
			dataout2(i*5+4 downto i*5) <= fake2(20*i+4 downto i*20);
		end generate;
	end generate;

	a13d2 : if (abits = 13) generate
		x : for i in 0 to ((dbits-1)/2) generate
			in_fake1(i*20+19 downto i*20) <= "000000000000000000" & di1(i*2+1 downto i*2);
			r0 : RAM1K20 port map (
				A_ADDR => xa(12 downto 0) & "0", A_BLK_EN => enable1 & vcc & vcc, A_CLK => clk1,
				A_DIN => in_fake1(i*20+19 downto i*20), A_DOUT => fake1(20*i+19 downto i*20),
				A_WEN => gnd & write1, A_REN => enable1 and not(write1), A_WIDTH => gnd & gnd & vcc, A_WMODE => gnd & gnd,
				A_BYPASS => bypass, A_DOUT_EN => bypass, A_DOUT_SRST_N => vcc, A_DOUT_ARST_N => vcc,

				B_ADDR => ya(12 downto 0) & "0", B_BLK_EN => enable2 & vcc & vcc, B_CLK => clk2,
				B_DIN => "000000000000000000" & di2(i*2+1 downto i*2), B_DOUT => fake2(20*i+19 downto i*20),
				B_WEN => gnd & write2, B_REN => enable2, B_WIDTH => gnd & gnd & vcc, B_WMODE => gnd & gnd,
				B_BYPASS => bypass, B_DOUT_EN => bypass, B_DOUT_SRST_N => vcc, B_DOUT_ARST_N => vcc,

				ECC_EN => gnd, ECC_BYPASS => '1', SB_CORRECT => open, DB_DETECT => open, 
				BUSY_FB => '0',	ACCESS_BUSY => open
			);
			dataout1(i*2+1 downto i*2) <= fake1(20*i+1 downto i*20);
			dataout2(i*2+1 downto i*2) <= fake2(20*i+1 downto i*20);
		end generate;
	end generate;

	a14d1 : if (abits = 14) generate
		x : for i in 0 to ((dbits-1)/1) generate
			in_fake1(i*20+19 downto i*20) <= "0000000000000000000" & di1(i*1 downto i*1);
			r0 : RAM1K20 port map (
				A_ADDR => xa(13 downto 0), A_BLK_EN => enable1 & vcc & vcc, A_CLK => clk1,
				A_DIN => in_fake1(i*20+19 downto i*20), A_DOUT => fake1(20*i+19 downto i*20),
				A_WEN => gnd & write1, A_REN => enable1 and not(write1), A_WIDTH => gnd & gnd & gnd, A_WMODE => gnd & gnd,
				A_BYPASS => bypass, A_DOUT_EN => bypass, A_DOUT_SRST_N => vcc, A_DOUT_ARST_N => vcc,

				B_ADDR => ya(13 downto 0), B_BLK_EN => enable2 & vcc & vcc, B_CLK => clk2,
				B_DIN => "0000000000000000000" & di2(i*1 downto i*1), B_DOUT => fake2(20*i+19 downto i*20),
				B_WEN => gnd & write2, B_REN => enable2, B_WIDTH => gnd & gnd & gnd, B_WMODE => gnd & gnd,
				B_BYPASS => bypass, B_DOUT_EN => bypass, B_DOUT_SRST_N => vcc, B_DOUT_ARST_N => vcc,

				ECC_EN => gnd, ECC_BYPASS => '1', SB_CORRECT => open, DB_DETECT => open, 
				BUSY_FB => '0',	ACCESS_BUSY => open
			);
			dataout1(i*1 downto i*1) <= fake1(20*i downto i*20);
			dataout2(i*1 downto i*1) <= fake2(20*i downto i*20);
		end generate;
	end generate;

	--a12d5 : if (abits = 12) generate
	--	x : for i in 0 to ((dbits-1)/5) generate
	--		r0 : RAM1K20 port map (
	--			A_ADDR => xa(11 downto 0) & "00", A_BLK_EN => enable & vcc & vcc, A_CLK => clk,
	--			A_DIN => "000000000000000" & di(i*5+4 downto i*5), A_DOUT => open,
	--			A_WEN => gnd & write, A_REN => enable and not(write), A_WIDTH => gnd & vcc & gnd, A_WMODE => gnd & gnd,
	--			A_BYPASS => bypass, A_DOUT_EN => bypass, A_DOUT_SRST_N => vcc, A_DOUT_ARST_N => vcc,

	--			B_ADDR => xa(11 downto 0) & "00", B_BLK_EN => enable & vcc & vcc, B_CLK => clk,
	--			B_DIN => (others => gnd), B_DOUT => fake(20*i+19 downto i*20),
	--			B_WEN => (others => gnd), B_REN => enable, B_WIDTH => gnd & vcc & gnd, B_WMODE => gnd & gnd,
	--			B_BYPASS => bypass, B_DOUT_EN => bypass, B_DOUT_SRST_N => vcc, B_DOUT_ARST_N => vcc,

	--			ECC_EN => ecc_en, ECC_BYPASS => '1', SB_CORRECT => open, DB_DETECT => open, 
	--			BUSY_FB => '0',	ACCESS_BUSY => open
	--		);
	--		do(i*5+4 downto i*5) <= fake(20*i+4 downto i*20);
	--	end generate;
	--end generate;

	--a13d2 : if (abits = 13) generate
	--	x : for i in 0 to ((dbits-1)/2) generate
	--		r0 : RAM1K20 port map (
	--			A_ADDR => xa(12 downto 0) & "0", A_BLK_EN => enable & vcc & vcc, A_CLK => clk,
	--			A_DIN => "000000000000000000" & di(i*2+1 downto i*2), A_DOUT => open,
	--			A_WEN => gnd & write, A_REN => enable and not(write), A_WIDTH => gnd & gnd & vcc, A_WMODE => gnd & gnd,
	--			A_BYPASS => bypass, A_DOUT_EN => bypass, A_DOUT_SRST_N => vcc, A_DOUT_ARST_N => vcc,

	--			B_ADDR => xa(12 downto 0) & "0", B_BLK_EN => enable & vcc & vcc, B_CLK => clk,
	--			B_DIN => (others => gnd), B_DOUT => fake(20*i+19 downto i*20),
	--			B_WEN => (others => gnd), B_REN => enable, B_WIDTH => gnd & gnd & vcc, B_WMODE => gnd & gnd,
	--			B_BYPASS => bypass, B_DOUT_EN => bypass, B_DOUT_SRST_N => vcc, B_DOUT_ARST_N => vcc,

	--			ECC_EN => ecc_en, ECC_BYPASS => '1', SB_CORRECT => open, DB_DETECT => open, 
	--			BUSY_FB => '0',	ACCESS_BUSY => open
	--		);
	--		do(i*2+1 downto i*2) <= fake(20*i+1 downto i*20);
	--	end generate;
	--end generate;

	--a14d1 : if (abits = 14) generate
	--	x : for i in 0 to ((dbits-1)/1) generate
	--		r0 : RAM1K20 port map (
	--			A_ADDR => xa(13 downto 0), A_BLK_EN => enable & vcc & vcc, A_CLK => clk,
	--			A_DIN => "0000000000000000000" & di(i*1 downto i), A_DOUT => open,
	--			A_WEN => gnd & write, A_REN => enable and not(write), A_WIDTH => gnd & gnd & gnd, A_WMODE => gnd & gnd,
	--			A_BYPASS => bypass, A_DOUT_EN => bypass, A_DOUT_SRST_N => vcc, A_DOUT_ARST_N => vcc,

	--			B_ADDR => xa(13 downto 0), B_BLK_EN => enable & vcc & vcc, B_CLK => clk,
	--			B_DIN => (others => gnd), B_DOUT => fake(20*i+19 downto i*20),
	--			B_WEN => (others => gnd), B_REN => enable, B_WIDTH => gnd & gnd & gnd, B_WMODE => gnd & gnd,
	--			B_BYPASS => bypass, B_DOUT_EN => bypass, B_DOUT_SRST_N => vcc, B_DOUT_ARST_N => vcc,

	--			ECC_EN => ecc_en, ECC_BYPASS => '1', SB_CORRECT => open, DB_DETECT => open, 
	--			BUSY_FB => '0',	ACCESS_BUSY => open
	--		);
	--		do(i*1 downto i*1) <= fake(20*i downto i*20);
	--	end generate;
	--end generate;

end architecture;

library ieee;
use ieee.std_logic_1164.all;

library PolarFire;

entity igloo2_syncram_2p is
	generic ( abits : integer := 8; dbits : integer := 32; sepclk : integer := 0;
		ecc : integer range 0 to 1 := 0; doutpipe : integer := 0; eccpipe : integer := 0);
	port (
		rclk     : in std_ulogic;
		renable  : in std_ulogic := '1';
		raddress : in std_logic_vector((abits-1) downto 0);
		dataout  : out std_logic_vector((dbits-1) downto 0);
		rerror   : out std_logic_vector(1 downto 0);
		wclk     : in std_ulogic;
		write    : in std_ulogic;
		waddress : in std_logic_vector((abits-1) downto 0);
		datain   : in std_logic_vector((dbits-1) downto 0));
end entity;

architecture rtl of igloo2_syncram_2p is

	component RAM64x12
		port (
			BLK_EN 			: in 	std_ulogic;
			W_CLK 			: in 	std_ulogic;
			W_ADDR 			: in 	std_logic_vector (5 downto 0);
			W_DATA 			: in 	std_logic_vector (11 downto 0);
			W_EN 			: in 	std_ulogic;
			R_CLK 			: in 	std_ulogic;
			R_ADDR 			: in 	std_logic_vector (5 downto 0);
			R_DATA 			: out	std_logic_vector (11 downto 0);
			R_ADDR_EN 		: in 	std_ulogic;
			R_ADDR_BYPASS	: in 	std_ulogic;
			R_ADDR_SL_N 	: in 	std_ulogic;
			R_ADDR_AL_N 	: in 	std_ulogic;
			R_ADDR_AD_N 	: in 	std_ulogic;
			R_ADDR_SD 		: in 	std_ulogic;
			R_DATA_BYPASS	: in 	std_ulogic;
			R_DATA_EN 		: in 	std_ulogic;
			R_DATA_SD 		: in 	std_ulogic;
			R_DATA_SL_N		: in 	std_ulogic;
			R_DATA_AL_N 	: in 	std_ulogic;
			R_DATA_AD_N 	: in 	std_ulogic;
			BUSY_FB 		: in 	std_ulogic;
			ACCESS_BUSY 	: out 	std_ulogic
		);
	end component;

	component RAM1K20 is
		port (
			A_ADDR 			: in  std_logic_vector(13 downto 0);
			A_BLK_EN 		: in  std_logic_vector(2 downto 0);
			A_CLK 			: in  std_logic;
			A_DIN 			: in  std_logic_vector(19 downto 0);
			A_DOUT 			: out std_logic_vector(19 downto 0);
			A_WEN 			: in  std_logic_vector(1 downto 0);
			A_REN 			: in  std_logic;
			A_WIDTH 		: in  std_logic_vector(2 downto 0);
			A_WMODE 		: in  std_logic_vector(1 downto 0);
			A_BYPASS 		: in  std_logic;
			A_DOUT_EN 		: in  std_logic;
			A_DOUT_SRST_N 	: in  std_logic;
			A_DOUT_ARST_N 	: in  std_logic;

			B_ADDR 			: in  std_logic_vector(13 downto 0);
			B_BLK_EN 		: in  std_logic_vector(2 downto 0);
			B_CLK 			: in  std_logic;
			B_DIN 			: in  std_logic_vector(19 downto 0);
			B_DOUT 			: out std_logic_vector(19 downto 0);
			B_WEN 			: in  std_logic_vector(1 downto 0);
			B_REN 			: in  std_logic;
			B_WIDTH 		: in  std_logic_vector(2 downto 0);
			B_WMODE 		: in  std_logic_vector(1 downto 0);
			B_BYPASS 		: in  std_logic;
			B_DOUT_EN 		: in  std_logic;
			B_DOUT_SRST_N 	: in  std_logic;
			B_DOUT_ARST_N 	: in  std_logic;

			ECC_EN 			: in  std_logic;
			ECC_BYPASS 		: in  std_logic;
			SB_CORRECT 		: out std_logic;
			DB_DETECT 		: out std_logic;
			BUSY_FB 		: in  std_logic;
			ACCESS_BUSY 	: out std_logic
		);
	end component RAM1K20;

	component generic_syncram_2p
  generic (abits : integer := 8; dbits : integer := 32; sepclk : integer := 0;
  pipeline : integer := 0; rdhold : integer := 0);
  port (
    rclk : in std_ulogic;
    wclk : in std_ulogic;
    rdaddress: in std_logic_vector (abits -1 downto 0);
    wraddress: in std_logic_vector (abits -1 downto 0);
    data: in std_logic_vector (dbits -1 downto 0);
    wren : in std_ulogic;
    q: out std_logic_vector (dbits -1 downto 0);
    rden : in std_ulogic := '1'
  );
end component;

	signal vcc, gnd : std_ulogic;
	signal do, di : std_logic_vector(dbits+80 downto 0);
	signal fake : std_logic_vector(2047 downto 0);
	signal xa, ya : std_logic_vector(14 downto 0);

	signal bypass : std_logic;
	signal ecc_bypass : std_logic;
	signal ecc_en : std_logic;

begin

	rerror <= "00";
	vcc <= '1'; gnd <= '0'; dataout <= do(dbits-1 downto 0); di(dbits-1 downto 0) <= datain;
	di(dbits+80 downto dbits) <= (others => '0'); xa(abits-1 downto 0) <= raddress;
	xa(14 downto abits) <= (others => '0'); ya(abits-1 downto 0) <= waddress;
	ya(14 downto abits) <= (others => '0');

	ecc_bypass <= '0' when eccpipe = 1 else '1';
	ecc_en <= '1' when ecc = 1 else '0';
	bypass <= '0' when doutpipe = 1 else '1';
	
	a6 : if (abits <= 6 and ecc = 0) generate
		x : for i in 0 to ((dbits-1)/12) generate
			r0 : RAM64x12 port map (
				BLK_EN => vcc, BUSY_FB => '0', R_ADDR => xa(5 downto 0), R_ADDR_AD_N => vcc,
				R_DATA_AD_N => vcc, R_ADDR_BYPASS => gnd, R_ADDR_EN => vcc, R_ADDR_AL_N => vcc,
				R_ADDR_SD => vcc, R_ADDR_SL_N => vcc, R_CLK => rclk, 
				R_DATA_AL_N => vcc, R_DATA_BYPASS => bypass, R_DATA_EN => vcc, 
				R_DATA_SD => gnd, R_DATA_SL_N => vcc, W_ADDR => ya(5 downto 0), 
				W_CLK => wclk, W_DATA => di(i*12+11 downto i*12), W_EN => write, 
				R_DATA => do(i*12+11 downto i*12), ACCESS_BUSY => open
			);
		end generate;
		do(dbits+40 downto 40*(((dbits-1)/40)+1)) <= (others => '0');
	end generate;

	a9d40 : if (abits > 6 and abits <= 9 and ecc = 0) generate
		x : for i in 0 to ((dbits-1)/40) generate
			r0 : RAM1K20 port map (
				A_ADDR => xa(8 downto 0) & "00000", A_BLK_EN => (write or renable) & vcc & vcc, A_CLK => rclk,
				A_DIN => di(i*40+39 downto i*40+20), A_DOUT => do(i*40+39 downto i*40+20),
				A_WEN => write & write, A_REN => renable, A_WIDTH => vcc & gnd & vcc, A_WMODE => gnd & gnd,
				A_BYPASS => bypass, A_DOUT_EN => bypass, A_DOUT_SRST_N => vcc, A_DOUT_ARST_N => vcc,

				B_ADDR => ya(8 downto 0) & "00000", B_BLK_EN => (write or renable) & vcc & vcc, B_CLK => wclk,
				B_DIN => di(i*40+19 downto i*40), B_DOUT => do(i*40+19 downto i*40),
				B_WEN => write & write, B_REN => renable, B_WIDTH => vcc & gnd & vcc, B_WMODE => gnd & gnd,
				B_BYPASS => bypass, B_DOUT_EN => bypass, B_DOUT_SRST_N => vcc, B_DOUT_ARST_N => vcc,

				ECC_EN => ecc_en, ECC_BYPASS => '1', SB_CORRECT => open, DB_DETECT => open, 
				BUSY_FB => '0',	ACCESS_BUSY => open
			);
		end generate;
	end generate;

	--gs2p : generic_syncram_2p
	--	generic map (
	--		abits => abits, dbits => dbits, sepclk => sepclk, pipeline => doutpipe, rdhold => 0)
	--	port map (
	--		rclk => rclk, wclk => wclk, rdaddress => raddress, wraddress => waddress, data => datain,
	--		wren => write, q => open);

end architecture;


--library ieee;
--use ieee.std_logic_1164.all;

--library PolarFire;

--entity polarfire_syncram_be is
--	generic ( abits : integer := 8; dbits : integer := 32;
--		 doutpipe : integer := 0);
--	port (
--		clk      : in std_ulogic;
--		address  : in std_logic_vector((abits-1) downto 0);
--		datain   : in std_logic_vector((dbits-1) downto 0);
--		dataout  : out std_logic_vector((dbits-1) downto 0);
--		write    : in std_logic_vector (dbits/8-1 downto 0);
--		enable   : in std_logic_vector (dbits/8-1 downto 0)
--	);
--end entity;

--architecture rtl of polarfire_syncram_be is

--	component RAM1K20 is
--		port (
--			A_ADDR 			: in  std_logic_vector(13 downto 0);
--			A_BLK_EN 		: in  std_logic_vector(2 downto 0);
--			A_CLK 			: in  std_logic;
--			A_DIN 			: in  std_logic_vector(19 downto 0);
--			A_DOUT 			: out std_logic_vector(19 downto 0);
--			A_WEN 			: in  std_logic_vector(1 downto 0);
--			A_REN 			: in  std_logic;
--			A_WIDTH 		: in  std_logic_vector(2 downto 0);
--			A_WMODE 		: in  std_logic_vector(1 downto 0);
--			A_BYPASS 		: in  std_logic;
--			A_DOUT_EN 		: in  std_logic;
--			A_DOUT_SRST_N 	: in  std_logic;
--			A_DOUT_ARST_N 	: in  std_logic;

--			B_ADDR 			: in  std_logic_vector(13 downto 0);
--			B_BLK_EN 		: in  std_logic_vector(2 downto 0);
--			B_CLK 			: in  std_logic;
--			B_DIN 			: in  std_logic_vector(19 downto 0);
--			B_DOUT 			: out std_logic_vector(19 downto 0);
--			B_WEN 			: in  std_logic_vector(1 downto 0);
--			B_REN 			: in  std_logic;
--			B_WIDTH 		: in  std_logic_vector(2 downto 0);
--			B_WMODE 		: in  std_logic_vector(1 downto 0);
--			B_BYPASS 		: in  std_logic;
--			B_DOUT_EN 		: in  std_logic;
--			B_DOUT_SRST_N 	: in  std_logic;
--			B_DOUT_ARST_N 	: in  std_logic;

--			ECC_EN 			: in  std_logic;
--			ECC_BYPASS 		: in  std_logic;
--			SB_CORRECT 		: out std_logic;
--			DB_DETECT 		: out std_logic;
--			BUSY_FB 		: in  std_logic;
--			ACCESS_BUSY 	: out std_logic
--		);
--	end component RAM1K20;

--	signal vcc, gnd : std_ulogic;
--	signal xenable, xwe : std_ulogic;
--	signal do, di : std_logic_vector(dbits+80 downto 0);
--	signal fake : std_logic_vector(2047 downto 0);
--	signal fake_di : std_logic_vector(2047 downto 0);
--	signal xa, ya : std_logic_vector(14 downto 0);

--	signal bypass : std_logic;	

--begin

--	vcc <= '1'; gnd <= '0'; 
--	dataout <= do(dbits-1 downto 0); 
--	di(dbits-1 downto 0) <= datain;
--	di(dbits+80 downto dbits) <= (others => '0'); xa(abits-1 downto 0) <= address;
--	xa(14 downto abits) <= (others => '0'); ya(abits-1 downto 0) <= address;
--	ya(14 downto abits) <= (others => '0');

--	bypass <= '0' when doutpipe = 1 else '1';
	

--	a9d40 : if (abits > 6 and abits <= 9 and ecc = 0) generate
--		for i in 0 to dbits/8-1 loop
--			fake_di(i*10+9 downto i*10) <= "00" & di(i*10+9 downto i*10);
--		end loop;
--		x : for i in 0 to ((dbits-1)/40) generate
--			r0 : RAM1K20 port map (
--				A_ADDR => xa(8 downto 0) & "00000", A_BLK_EN => (write or renable) & vcc & vcc, A_CLK => rclk,
--				A_DIN => di(i*40+39 downto i*40+20), A_DOUT => do(i*40+39 downto i*40+20),
--				A_WEN => write & write, A_REN => renable, A_WIDTH => vcc & gnd & vcc, A_WMODE => gnd & gnd,
--				A_BYPASS => bypass, A_DOUT_EN => bypass, A_DOUT_SRST_N => vcc, A_DOUT_ARST_N => vcc,

--				B_ADDR => ya(8 downto 0) & "00000", B_BLK_EN => (write or renable) & vcc & vcc, B_CLK => wclk,
--				B_DIN => di(i*40+19 downto i*40), B_DOUT => do(i*40+19 downto i*40),
--				B_WEN => write & write, B_REN => renable, B_WIDTH => vcc & gnd & vcc, B_WMODE => gnd & gnd,
--				B_BYPASS => bypass, B_DOUT_EN => bypass, B_DOUT_SRST_N => vcc, B_DOUT_ARST_N => vcc,

--				ECC_EN => ecc_en, ECC_BYPASS => '1', SB_CORRECT => open, DB_DETECT => open, 
--				BUSY_FB => '0',	ACCESS_BUSY => open
--			);
--		end generate;
--	end generate;

--end architecture;




































--library ieee;
--use ieee.std_logic_1164.all;

--library polarfire;
--use polarfire.RAM1K20;
--use polarfire.RAM64X12;

--entity polarfire_syncram is
--	generic (
--		abits 		: integer := 10; 
--		dbits 		: integer := 8; 
--		ecc 		: integer range 0 to 1 := 0;
--		doutpipe 	: integer := 0; 
--		eccpipe 	: integer := 0
--	);
--	port (
--		clk      	: in  std_ulogic;
--		address  	: in  std_logic_vector((abits -1) downto 0);
--		datain   	: in  std_logic_vector((dbits -1) downto 0);
--		dataout  	: out std_logic_vector((dbits -1) downto 0);
--		enable   	: in  std_ulogic;
--		write    	: in  std_ulogic;
--		error    	: out std_logic_vector(1 downto 0)
--	);
--end entity;

--architecture rtl of polarfire_syncram is

--	component RAM64X12
--		port (
--			BLK_EN 			: in 	std_ulogic;
--			W_CLK 			: in 	std_ulogic;
--			W_ADDR 			: in 	std_logic_vector (5 downto 0);
--			W_DATA 			: in 	std_logic_vector (11 downto 0);
--			W_EN 			: in 	std_ulogic;
--			R_CLK 			: in 	std_ulogic;
--			R_ADDR 			: in 	std_logic_vector (5 downto 0);
--			R_DATA 			: out	std_logic_vector (11 downto 0);
--			R_ADDR_EN 		: in 	std_ulogic;
--			R_ADDR_BYPASS	: in 	std_ulogic;
--			R_ADDR_SL_N 	: in 	std_ulogic;
--			R_ADDR_AL_N 	: in 	std_ulogic;
--			R_ADDR_AD_N 	: in 	std_ulogic;
--			R_ADDR_SD 		: in 	std_ulogic;
--			R_DATA_BYPASS	: in 	std_ulogic;
--			R_DATA_EN 		: in 	std_ulogic;
--			R_DATA_SD 		: in 	std_ulogic;
--			R_DATA_SL_N		: in 	std_ulogic;
--			R_DATA_AL_N 	: in 	std_ulogic;
--			R_DATA_AD_N 	: in 	std_ulogic;
--			BUSY_FB 		: in 	std_ulogic;
--			ACCESS_BUSY 	: out 	std_ulogic
--		);
--	end component;

--	component RAM1K20 is
--		port (
--			A_ADDR 			: in  std_logic_vector(13 downto 0);
--			A_BLK_EN 		: in  std_logic_vector(2 downto 0);
--			A_CLK 			: in  std_logic;
--			A_DIN 			: in  std_logic_vector(19 downto 0);
--			A_DOUT 			: out std_logic_vector(19 downto 0);
--			A_WEN 			: in  std_logic_vector(1 downto 0);
--			A_REN 			: in  std_logic;
--			A_WIDTH 		: in  std_logic_vector(2 downto 0);
--			A_WMODE 		: in  std_logic_vector(1 downto 0);
--			A_BYPASS 		: in  std_logic;
--			A_DOUT_EN 		: in  std_logic;
--			A_DOUT_SRST_N 	: in  std_logic;
--			A_DOUT_ARST_N 	: in  std_logic;

--			B_ADDR 			: in  std_logic_vector(13 downto 0);
--			B_BLK_EN 		: in  std_logic_vector(2 downto 0);
--			B_CLK 			: in  std_logic;
--			B_DIN 			: in  std_logic_vector(19 downto 0);
--			B_DOUT 			: out std_logic_vector(19 downto 0);
--			B_WEN 			: in  std_logic_vector(1 downto 0);
--			B_REN 			: in  std_logic;
--			B_WIDTH 		: in  std_logic_vector(2 downto 0);
--			B_WMODE 		: in  std_logic_vector(1 downto 0);
--			B_BYPASS 		: in  std_logic;
--			B_DOUT_EN 		: in  std_logic;
--			B_DOUT_SRST_N 	: in  std_logic;
--			B_DOUT_ARST_N 	: in  std_logic;

--			ECC_EN 			: in  std_logic;
--			ECC_BYPASS 		: in  std_logic;
--			SB_CORRECT 		: out std_logic;
--			DB_DETECT 		: out std_logic;
--			BUSY_FB 		: in  std_logic;
--			ACCESS_BUSY 	: out std_logic
--		);
--	end component RAM1K20;

--	signal vcc, gnd : std_ulogic;
--	signal do, di : std_logic_vector(dbits+80 downto 0);
--	signal fake : std_logic_vector(dbits+80 downto 0);
--	signal xa, ya : std_logic_vector(14 downto 0);

--	signal bypass : std_logic;
--	signal ecc_bypass : std_logic;
--	signal ecc_en : std_logic;


--begin

--	vcc <= '1'; gnd <= '0'; dataout <= do(dbits-1 downto 0); di(dbits-1 downto 0) <= datain;
--	di(dbits+80 downto dbits) <= (others => '0'); xa(abits-1 downto 0) <= address;
--	xa(14 downto abits) <= (others => '0'); ya(abits-1 downto 0) <= address;
--	ya(14 downto abits) <= (others => '0');

--	ecc_bypass <= '0' when eccpipe = 1 else '1';
--	ecc_en <= '1' when eccpipe = 1 else '0';
--	bypass <= '0' when doutpipe = 1 else '1';

--	a6 : if (abits <= 6 and ecc = 0) generate
--		x : for i in 0 to ((dbits-1)/12) generate
--			r0 : RAM64X12 port map (
--				BLK_EN => vcc, BUSY_FB => '0', R_ADDR => xa(5 downto 0), R_ADDR_AD_N => vcc,
--				R_DATA_AD_N => vcc, R_ADDR_BYPASS => vcc, R_ADDR_EN => vcc, R_ADDR_AL_N => vcc,
--				R_ADDR_SD => gnd, R_ADDR_SL_N => vcc, R_CLK => vcc, 
--				R_DATA_AL_N => vcc, R_DATA_BYPASS => bypass, R_DATA_EN => vcc, 
--				R_DATA_SD => gnd, R_DATA_SL_N => vcc, W_ADDR => ya(5 downto 0), 
--				W_CLK => clk, W_DATA => di(i*12+11 downto i*12), W_EN => write, 
--				R_DATA => do(i*12+11 downto i*12), ACCESS_BUSY => open
--			);
--		end generate;
--		do(dbits+40 downto 40*(((dbits-1)/40)+1)) <= (others => '0');
--	end generate;

--	a9d40 : if (abits > 6 and abits <= 9 and ecc = 0) generate
--		x : for i in 0 to ((dbits-1)/40) generate
--			r0 : RAM1K20 port map (
--				A_ADDR => xa(8 downto 0) & "00000", A_BLK_EN => enable & vcc & vcc, A_CLK => clk,
--				A_DIN => di(i*40+39 downto i*40+20), A_DOUT => do(i*40+39 downto i*40+20),
--				A_WEN => write & write, A_REN => enable and not(write), A_WIDTH => vcc & gnd & vcc, A_WMODE => gnd & gnd,
--				A_BYPASS => bypass, A_DOUT_EN => bypass, A_DOUT_SRST_N => vcc, A_DOUT_ARST_N => vcc,

--				B_ADDR => xa(8 downto 0) & "00000", B_BLK_EN => enable & vcc & vcc, B_CLK => clk,
--				B_DIN => di(i*40+19 downto i*40), B_DOUT => do(i*40+19 downto i*40),
--				B_WEN => write & write, B_REN => gnd, B_WIDTH => vcc & gnd & vcc, B_WMODE => gnd & gnd,
--				B_BYPASS => bypass, B_DOUT_EN => bypass, B_DOUT_SRST_N => vcc, B_DOUT_ARST_N => vcc,

--				ECC_EN => ecc_en, ECC_BYPASS => '1', SB_CORRECT => open, DB_DETECT => open, 
--				BUSY_FB => '0',	ACCESS_BUSY => open
--			);
--		end generate;
--	end generate;

--	a10d20 : if (abits = 10 and ecc = 0) generate
--		x : for i in 0 to ((dbits-1)/20) generate
--			r0 : RAM1K20 port map (
--				A_ADDR => xa(9 downto 0) & "0000", A_BLK_EN => enable & vcc & vcc, A_CLK => clk,
--				A_DIN => di(i*20+19 downto i*20), A_DOUT => open,
--				A_WEN => write & write, A_REN => enable and not(write), A_WIDTH => vcc & gnd & gnd, A_WMODE => gnd & gnd,
--				A_BYPASS => bypass, A_DOUT_EN => bypass, A_DOUT_SRST_N => vcc, A_DOUT_ARST_N => vcc,

--				B_ADDR => xa(9 downto 0) & "0000", B_BLK_EN => enable & vcc & vcc, B_CLK => clk,
--				B_DIN => (others => gnd), B_DOUT => do(i*20+19 downto i*20),
--				B_WEN => (others => gnd), B_REN => enable, B_WIDTH => vcc & gnd & gnd, B_WMODE => gnd & gnd,
--				B_BYPASS => bypass, B_DOUT_EN => bypass, B_DOUT_SRST_N => vcc, B_DOUT_ARST_N => vcc,

--				ECC_EN => ecc_en, ECC_BYPASS => '1', SB_CORRECT => open, DB_DETECT => open, 
--				BUSY_FB => '0',	ACCESS_BUSY => open
--			);
--		end generate;
--	end generate;

--	a11d10 : if (abits = 11 and ecc = 0) generate
--		x : for i in 0 to ((dbits-1)/10) generate
--			r0 : RAM1K20 port map (
--				A_ADDR => xa(10 downto 0) & "000", A_BLK_EN => enable & vcc & vcc, A_CLK => clk,
--				A_DIN => "0000000000" & di(i*10+9 downto i*10), A_DOUT => open,
--				A_WEN => gnd & write, A_REN => enable and not(write), A_WIDTH => gnd & vcc & vcc, A_WMODE => gnd & gnd,
--				A_BYPASS => bypass, A_DOUT_EN => bypass, A_DOUT_SRST_N => vcc, A_DOUT_ARST_N => vcc,

--				B_ADDR => xa(10 downto 0) & "000", B_BLK_EN => enable & vcc & vcc, B_CLK => clk,
--				B_DIN => (others => gnd), B_DOUT => fake(20*i+19 downto i*20),
--				B_WEN => (others => gnd), B_REN => enable, B_WIDTH => gnd & vcc & vcc, B_WMODE => gnd & gnd,
--				B_BYPASS => bypass, B_DOUT_EN => bypass, B_DOUT_SRST_N => vcc, B_DOUT_ARST_N => vcc,

--				ECC_EN => ecc_en, ECC_BYPASS => '1', SB_CORRECT => open, DB_DETECT => open, 
--				BUSY_FB => '0',	ACCESS_BUSY => open
--			);
--			do(i*10+9 downto i*10) <= fake(20*i+9 downto i*20);
--		end generate;
--	end generate;

--	a12d5 : if (abits = 12 and ecc = 0) generate
--		x : for i in 0 to ((dbits-1)/5) generate
--			r0 : RAM1K20 port map (
--				A_ADDR => xa(11 downto 0) & "00", A_BLK_EN => enable & vcc & vcc, A_CLK => clk,
--				A_DIN => "000000000000000" & di(i*5+4 downto i*5), A_DOUT => open,
--				A_WEN => gnd & write, A_REN => enable and not(write), A_WIDTH => gnd & vcc & gnd, A_WMODE => gnd & gnd,
--				A_BYPASS => bypass, A_DOUT_EN => bypass, A_DOUT_SRST_N => vcc, A_DOUT_ARST_N => vcc,

--				B_ADDR => xa(11 downto 0) & "00", B_BLK_EN => enable & vcc & vcc, B_CLK => clk,
--				B_DIN => (others => gnd), B_DOUT => fake(20*i+19 downto i*20),
--				B_WEN => (others => gnd), B_REN => enable, B_WIDTH => gnd & vcc & gnd, B_WMODE => gnd & gnd,
--				B_BYPASS => bypass, B_DOUT_EN => bypass, B_DOUT_SRST_N => vcc, B_DOUT_ARST_N => vcc,

--				ECC_EN => ecc_en, ECC_BYPASS => '1', SB_CORRECT => open, DB_DETECT => open, 
--				BUSY_FB => '0',	ACCESS_BUSY => open
--			);
--			do(i*5+4 downto i*5) <= fake(20*i+4 downto i*20);
--		end generate;
--	end generate;

--	a13d2 : if (abits = 13 and ecc = 0) generate
--		x : for i in 0 to ((dbits-1)/2) generate
--			r0 : RAM1K20 port map (
--				A_ADDR => xa(12 downto 0) & "0", A_BLK_EN => enable & vcc & vcc, A_CLK => clk,
--				A_DIN => "000000000000000000" & di(i*2+1 downto i*2), A_DOUT => open,
--				A_WEN => gnd & write, A_REN => enable and not(write), A_WIDTH => gnd & gnd & vcc, A_WMODE => gnd & gnd,
--				A_BYPASS => bypass, A_DOUT_EN => bypass, A_DOUT_SRST_N => vcc, A_DOUT_ARST_N => vcc,

--				B_ADDR => xa(12 downto 0) & "0", B_BLK_EN => enable & vcc & vcc, B_CLK => clk,
--				B_DIN => (others => gnd), B_DOUT => fake(20*i+19 downto i*20),
--				B_WEN => (others => gnd), B_REN => enable, B_WIDTH => gnd & gnd & vcc, B_WMODE => gnd & gnd,
--				B_BYPASS => bypass, B_DOUT_EN => bypass, B_DOUT_SRST_N => vcc, B_DOUT_ARST_N => vcc,

--				ECC_EN => ecc_en, ECC_BYPASS => '1', SB_CORRECT => open, DB_DETECT => open, 
--				BUSY_FB => '0',	ACCESS_BUSY => open
--			);
--			do(i*2+1 downto i*2) <= fake(20*i+1 downto i*20);
--		end generate;
--	end generate;

--	a14d1 : if (abits = 14 and ecc = 0) generate
--		x : for i in 0 to ((dbits-1)/1) generate
--			r0 : RAM1K20 port map (
--				A_ADDR => xa(13 downto 0), A_BLK_EN => enable & vcc & vcc, A_CLK => clk,
--				A_DIN => "0000000000000000000" & di(i*1 downto i), A_DOUT => open,
--				A_WEN => gnd & write, A_REN => enable and not(write), A_WIDTH => gnd & gnd & gnd, A_WMODE => gnd & gnd,
--				A_BYPASS => bypass, A_DOUT_EN => bypass, A_DOUT_SRST_N => vcc, A_DOUT_ARST_N => vcc,

--				B_ADDR => xa(13 downto 0), B_BLK_EN => enable & vcc & vcc, B_CLK => clk,
--				B_DIN => (others => gnd), B_DOUT => fake(20*i+19 downto i*20),
--				B_WEN => (others => gnd), B_REN => enable, B_WIDTH => gnd & gnd & gnd, B_WMODE => gnd & gnd,
--				B_BYPASS => bypass, B_DOUT_EN => bypass, B_DOUT_SRST_N => vcc, B_DOUT_ARST_N => vcc,

--				ECC_EN => ecc_en, ECC_BYPASS => '1', SB_CORRECT => open, DB_DETECT => open, 
--				BUSY_FB => '0',	ACCESS_BUSY => open
--			);
--			do(i*1 downto i*1) <= fake(20*i downto i*20);
--		end generate;
--	end generate;
--end;

--library ieee;
--use ieee.std_logic_1164.all;

--library polarfire;
--use polarfire.RAM1K20;
--use polarfire.RAM64X12;

--entity polarfire_syncram_dp is
--	generic ( abits : integer := 6; dbits : integer := 8; doutpipe : integer := 0);
--	port (
--		clk1     	: in 	std_ulogic;
--		address1 	: in 	std_logic_vector((abits -1) downto 0);
--		datain1  	: in 	std_logic_vector((dbits -1) downto 0);
--		dataout1 	: out 	std_logic_vector((dbits -1) downto 0);
--		enable1  	: in 	std_ulogic;
--		write1   	: in 	std_ulogic;
--		clk2     	: in 	std_ulogic;
--		address2 	: in 	std_logic_vector((abits -1) downto 0);
--		datain2  	: in 	std_logic_vector((dbits -1) downto 0);
--		dataout2 	: out 	std_logic_vector((dbits -1) downto 0);
--		enable2  	: in 	std_ulogic;
--		write2   	: in 	std_ulogic);
--end entity;

--architecture rtl of polarfire_syncram_dp is

--begin

--end architecture;

--library ieee;
--use ieee.std_logic_1164.all;

--library polarfire;
--use polarfire.RAM1K20;
--use polarfire.RAM64X12;

--entity polarfire_syncram_2p is
--	generic ( abits : integer := 8; dbits : integer := 32; sepclk : integer := 0;
--		ecc : integer range 0 to 1 := 0; doutpipe : integer := 0; eccpipe : integer := 0);
--	port (
--		rclk     : in std_ulogic;
--		renable  : in std_ulogic;
--		raddress : in std_logic_vector((abits-1) downto 0);
--		dataout  : out std_logic_vector((dbits-1) downto 0);
--		rerror   : out std_logic_vector(1 downto 0);
--		wclk     : in std_ulogic;
--		write    : in std_ulogic;
--		waddress : in std_logic_vector((abits-1) downto 0);
--		datain   : in std_logic_vector((dbits-1) downto 0));
--end entity;

--architecture rtl of polarfire_syncram_2p is
	
--	component generic_syncram_2p
--  generic (abits : integer := 8; dbits : integer := 32; sepclk : integer := 0;
--  pipeline : integer := 0; rdhold : integer := 0);
--  port (
--    rclk : in std_ulogic;
--    wclk : in std_ulogic;
--    rdaddress: in std_logic_vector (abits -1 downto 0);
--    wraddress: in std_logic_vector (abits -1 downto 0);
--    data: in std_logic_vector (dbits -1 downto 0);
--    wren : in std_ulogic;
--    q: out std_logic_vector (dbits -1 downto 0);
--    rden : in std_ulogic := '1'
--  );
--end component;

--begin

--	gs2p : generic_syncram_2p
--		generic map (
--			abits => abits, dbits => dbits, sepclk => sepclk, pipeline => doutpipe, rdhold => 0)
--		port map (
--			rclk => rclk, wclk => wclk, rdaddress => raddress, wraddress => waddress, data => datain,
--			wren => write, q => dataout);

--end architecture;

----library ieee;
----use ieee.std_logic_1164.all;

----library polarfire;
----use polarfire.RAM1K20;

----entity polarfire_ram1k20 is
----	generic (
----		abits			: integer range 9 to 14 := 11;
----		dbits 			: integer := 8;
----		sepclk 			: integer := 0;
----		ecc 			: integer range 0 to 1 := 0; 
----		doutpipe 		: integer := 0; 
----		eccpipe 		: integer := 0
----	);
----	port (
----		addra, addrb	: in  std_logic_vector(abits-1 downto 0);
----		clka, clkb 		: in  std_ulogic;
----		dia, dib     	: in  std_logic_vector(dbits-1 downto 0);
----		doa, dob     	: out std_logic_vector(dbits-1 downto 0);
----		ena, enb     	: in  std_logic_vector((dbits-1)/8 downto 0);
----		wea, web     	: in  std_ulogic
----	);
----end entity;

----architecture rtl of polarfire_ram1k20 is

----	function bitbang_in (
----		constant dbits 	: in integer;
----		constant d 		: in std_logic_vector
----	) return std_logic_vector is
----		variable v : std_logic_vector(19 downto 0);
----	begin
----		case (dbits) is
----			when 1 	=> v(0) := d(0); v(19 downto 1) := (others => '0');
----			when 2 	=> v(1 downto 0) := d(1 downto 0); v(19 downto 2) := (others => '0');
----			when 4 	=> v(3 downto 0) := d(3 downto 0); v(19 downto 4) := (others => '0');
----			when 5 	=> v(4 downto 0) := d(4 downto 0); v(19 downto 5) := (others => '0');
----			when 8 	=> v(8 downto 5) := d(7 downto 4); v(3 downto 0) :=  d(3 downto 0); v(19 downto 9) := (others => '0'); v(4) := '0';
----			when 10	=> v(9 downto 0) := d(9 downto 0); v(19 downto 10) := (others => '0');
----			when 16	=> v(18 downto 15) := d(15 downto 12); v(13 downto 10) := d(11 downto 8); v(8 downto 5) := d(7 downto 4); v(3 downto 0) := d(3 downto 0); v(19) := '0'; v(14) := '0'; v(9) := '0'; v(4) := '0';
----			when 20 => v(19 downto 0) := d(19 downto 0);
----			when others =>
----				null;
----		end case;
----		return v;
----	end function;

----	function bitbang_out (
----		constant dbits 	: in integer;
----		constant d 		: in std_logic_vector
----	) return std_logic_vector is
----		variable v : std_logic_vector(dbits-1 downto 0);
----	begin
----		case (dbits) is
----			when 1 	=> v(0) := d(0);
----			when 2 	=> v(1 downto 0) := d(1 downto 0);
----			when 4 	=> v(3 downto 0) := d(3 downto 0);
----			when 5 	=> v(4 downto 0) := d(4 downto 0);
----			when 8 	=> v(7 downto 0) := d(8 downto 5) & d(3 downto 0);
----			when 10	=> v(9 downto 0) := d(9 downto 0);
----			when 16	=> v(15 downto 0) := d(18 downto 15) & d(13 downto 10) & d(8 downto 5) & d(3 downto 0);
----			when 20 => v(19 downto 0) := d(19 downto 0);
----			when others =>
----				null;
----		end case;
----		return v;
----	end function;

----	component RAM1K20 is
----		port (
----			A_ADDR 			: in  std_logic_vector(13 downto 0);
----			A_BLK_EN 		: in  std_logic_vector(2 downto 0);
----			A_CLK 			: in  std_logic;
----			A_DIN 			: in  std_logic_vector(19 downto 0);
----			A_DOUT 			: out std_logic_vector(19 downto 0);
----			A_WEN 			: in  std_logic_vector(1 downto 0);
----			A_REN 			: in  std_logic;
----			A_WIDTH 		: in  std_logic_vector(2 downto 0);
----			A_WMODE 		: in  std_logic_vector(1 downto 0);
----			A_BYPASS 		: in  std_logic;
----			A_DOUT_EN 		: in  std_logic;
----			A_DOUT_SRST_N 	: in  std_logic;
----			A_DOUT_ARST_N 	: in  std_logic;

----			B_ADDR 			: in  std_logic_vector(13 downto 0);
----			B_BLK_EN 		: in  std_logic_vector(2 downto 0);
----			B_CLK 			: in  std_logic;
----			B_DIN 			: in  std_logic_vector(19 downto 0);
----			B_DOUT 			: out std_logic_vector(19 downto 0);
----			B_WEN 			: in  std_logic_vector(1 downto 0);
----			B_REN 			: in  std_logic;
----			B_WIDTH 		: in  std_logic_vector(2 downto 0);
----			B_WMODE 		: in  std_logic_vector(1 downto 0);
----			B_BYPASS 		: in  std_logic;
----			B_DOUT_EN 		: in  std_logic;
----			B_DOUT_SRST_N 	: in  std_logic;
----			B_DOUT_ARST_N 	: in  std_logic;

----			ECC_EN 			: in  std_logic;
----			ECC_BYPASS 		: in  std_logic;
----			SB_CORRECT 		: out std_logic;
----			DB_DETECT 		: out std_logic;
----			BUSY_FB 		: in  std_logic;
----			ACCESS_BUSY 	: out std_logic
----		);
----	end component RAM1K20;

----	attribute syn_black_box : boolean;
----  	attribute syn_black_box of RAM1K20: component is true;
----  	attribute syn_tco1 : string;
----  	attribute syn_tco2 : string;
----  	--attribute syn_tco1 of RAM4K9 : component is
----  	--"CLKA->DOUTA0,DOUTA1,DOUTA2,DOUTA3,DOUTA4,DOUTA5,DOUTA6,DOUTA7,DOUTA8 = 3.0";
----  	--attribute syn_tco2 of RAM4K9 : component is
----  	--"CLKB->DOUTB0,DOUTB1,DOUTB2,DOUTB3,DOUTB4,DOUTB5,DOUTB6,DOUTB7,DOUTB8 = 3.0";

----  	signal gnd, vcc : std_ulogic;
----	signal aa, ab : std_logic_vector(14 downto 0);
----	signal da, db : std_logic_vector(19 downto 0);
----	signal qa, qb : std_logic_vector(19 downto 0);
----	signal width : std_logic_vector(2 downto 0);
----	signal a_blk_en : std_logic_vector(2 downto 0);
----	signal b_blk_en : std_logic_vector(2 downto 0);
----	signal wmode : std_logic_vector(1 downto 0);
----	signal A_WEN, web_i : std_logic_vector(1 downto 0);
----	signal rea_i, reb_i : std_logic;
----	signal a_bypass, b_bypass : std_logic;
----	signal ecc_bypass : std_logic;
----	signal ecc_en : std_logic;

----	begin
----		gnd <= '0'; vcc <= '1';

----		width <= "000" when abits = 14 else "001" when abits = 13 else
----			"010" when abits = 12 else "011" when abits = 11 else "100"
----			when abits = 10 else "101";

----		ecc_bypass <= '0' when eccpipe = 1 else '1';
----		ecc_en <= '1' when eccpipe = 1 else '0';
----		a_bypass <= '0' when doutpipe = 1 else '1';
----		b_bypass <= '0' when doutpipe = 1 else '1';

----		a_blk_en <= ena & ena & ena;
----		b_blk_en <= enb & enb & enb;

----		wmode <= "00";
----        A_WEN(0) <= wea and ((dbits-1)/8);
----        A_WEN(1) <= wea and ((dbits-1)/8) width(2) = '1' else '0';
----        web_i(0) <= web;
----        web_i(1) <= web when width(2) = '1' else '0';
----        rea_i <= not(wea) and ena;
----        reb_i <= not(web) and enb;
----  		da <= bitbang_in(dbits, dia);
----  		db <= bitbang_in(dbits, dib);
----  		doa <= bitbang_out(dbits, qa);
----  		dob <= bitbang_out(dbits, qb);
----  		aa(14 downto 14-(abits-1)) <= addra; aa(14-(abits) downto 0) <= (others => '0');
----  		ab(14 downto 14-(abits-1)) <= addrb; ab(14-(abits) downto 0) <= (others => '0');

----  		u0 : RAM1K20
----		port map (
----			A_ADDR => aa(14 downto 1), A_CLK => clka, A_DIN => da, A_DOUT => qa,
----			A_WEN => A_WEN, A_WIDTH => width, A_BYPASS => a_bypass,
----			A_DOUT_EN => ena, A_DOUT_SRST_N => vcc, A_DOUT_ARST_N => vcc,
----			A_BLK_EN => a_blk_en, A_REN => rea_i,	
----			A_WMODE => wmode,

----			B_ADDR => ab(14 downto 1), B_CLK => clkb, B_DIN => db, B_DOUT => qb,
----			B_WEN => web_i, B_WIDTH => width, B_BYPASS => b_bypass,
----			B_DOUT_EN => enb, B_DOUT_SRST_N => vcc, B_DOUT_ARST_N => vcc,
----			B_BLK_EN => b_blk_en, B_REN => reb_i,
----			B_WMODE => wmode,

----			ECC_EN => ecc_en, ECC_BYPASS => ecc_bypass,
----			SB_CORRECT => open, DB_DETECT => open, 	BUSY_FB => gnd,
----			ACCESS_BUSY => open
----		);
----	end;


----library ieee;
----use ieee.std_logic_1164.all;

----library polarfire;
----use polarfire.RAM1K20;

----entity polarfire_ram521x40 is
----	generic (
----		abits			: integer range 9 to 14 := 11;
----		dbits 			: integer := 8;
----		sepclk 			: integer := 0;
----        ecc 			: integer range 0 to 1 := 0; 
----        doutpipe 		: integer := 0; 
----        eccpipe 		: integer := 0
----	);
----  	port (
----  		wclk 	 		: in  std_ulogic;
----  		rclk 	 		: in  std_ulogic;
----		raddress		: in  std_logic_vector(abits-1 downto 0);
----		waddress		: in  std_logic_vector(abits-1 downto 0);
----		datain 	    	: in  std_logic_vector(dbits-1 downto 0);
----    	dataout     	: out std_logic_vector(dbits-1 downto 0);
----    	renable     	: in  std_ulogic;
----    	write 	     	: in  std_ulogic
----  	) ;
----end entity; -- polarfire_ram1k20

----architecture rtl of polarfire_ram521x40 is
	
----	function bitbang_in (
----		constant dbits 	: in integer;
----		constant d 		: in std_logic_vector
----	) return std_logic_vector is
----		variable v : std_logic_vector(40 downto 0);
----	begin
----		case (dbits) is			
----			when 40 => v(39 downto 0) := d(39 downto 0);
----			when others =>
----				null;
----		end case;
----		return v;
----	end function;

----	function bitbang_out (
----		constant dbits 	: in integer;
----		constant d 		: in std_logic_vector
----	) return std_logic_vector is
----		variable v : std_logic_vector(dbits-1 downto 0);
----	begin
----		case (dbits) is
----			when 40 => v(39 downto 0) := d(39 downto 0);
----			when others =>
----				null;
----		end case;
----		return v;
----	end function;

----	component RAM1K20 is
----		port (
----			A_ADDR 			: in  std_logic_vector(13 downto 0);
----			A_BLK_EN 		: in  std_logic_vector(2 downto 0);
----			A_CLK 			: in  std_logic;
----			A_DIN 			: in  std_logic_vector(19 downto 0);
----			A_DOUT 			: out std_logic_vector(19 downto 0);
----			A_WEN 			: in  std_logic_vector(1 downto 0);
----			A_REN 			: in  std_logic;
----			A_WIDTH 		: in  std_logic_vector(2 downto 0);
----			A_WMODE 		: in  std_logic_vector(1 downto 0);
----			A_BYPASS 		: in  std_logic;
----			A_DOUT_EN 		: in  std_logic;
----			A_DOUT_SRST_N 	: in  std_logic;
----			A_DOUT_ARST_N 	: in  std_logic;

----			B_ADDR 			: in  std_logic_vector(13 downto 0);
----			B_BLK_EN 		: in  std_logic_vector(2 downto 0);
----			B_CLK 			: in  std_logic;
----			B_DIN 			: in  std_logic_vector(19 downto 0);
----			B_DOUT 			: out std_logic_vector(19 downto 0);
----			B_WEN 			: in  std_logic_vector(1 downto 0);
----			B_REN 			: in  std_logic;
----			B_WIDTH 		: in  std_logic_vector(2 downto 0);
----			B_WMODE 		: in  std_logic_vector(1 downto 0);
----			B_BYPASS 		: in  std_logic;
----			B_DOUT_EN 		: in  std_logic;
----			B_DOUT_SRST_N 	: in  std_logic;
----			B_DOUT_ARST_N 	: in  std_logic;

----			ECC_EN 			: in  std_logic;
----			ECC_BYPASS 		: in  std_logic;
----			SB_CORRECT 		: out std_logic;
----			DB_DETECT 		: out std_logic;
----			BUSY_FB 		: in  std_logic;
----			ACCESS_BUSY 	: out std_logic
----		);
----	end component RAM1K20;

----	attribute syn_black_box : boolean;
----  	attribute syn_black_box of RAM1K20: component is true;
----  	attribute syn_tco1 : string;
----  	attribute syn_tco2 : string;
----  	--attribute syn_tco1 of RAM4K9 : component is
----  	--"CLKA->DOUTA0,DOUTA1,DOUTA2,DOUTA3,DOUTA4,DOUTA5,DOUTA6,DOUTA7,DOUTA8 = 3.0";
----  	--attribute syn_tco2 of RAM4K9 : component is
----  	--"CLKB->DOUTB0,DOUTB1,DOUTB2,DOUTB3,DOUTB4,DOUTB5,DOUTB6,DOUTB7,DOUTB8 = 3.0";

----  	signal gnd, vcc : std_ulogic;
----	signal aa, ab : std_logic_vector(14 downto 0);
----	signal da, db : std_logic_vector(19 downto 0);
----	signal qa, qb : std_logic_vector(19 downto 0);
----	signal width : std_logic_vector(2 downto 0);
----	signal a_blk_en : std_logic_vector(2 downto 0);
----	signal b_blk_en : std_logic_vector(2 downto 0);
----	signal wmode : std_logic_vector(1 downto 0);
----	signal A_WEN, web_i : std_logic_vector(1 downto 0);
----	signal rea_i, reb_i : std_logic;
----	signal a_bypass, b_bypass : std_logic;
----	signal ecc_bypass : std_logic;
----	signal ecc_en : std_logic;

----	begin
----		gnd <= '0'; vcc <= '1';

----		width <= "000" when abits = 14 else "001" when abits = 13 else
----           "010" when abits = 12 else "011" when abits = 11 else "100"
----           when abits = 10 else "101";

----        ecc_bypass <= '0' when eccpipe = 1 else '1';
----        ecc_en <= '1' when eccpipe = 1 else '0';
----        a_bypass <= '0' when doutpipe = 1 else '1';
----        b_bypass <= '0' when doutpipe = 1 else '1';

----        a_blk_en <= "111";
----        b_blk_en <= "111";
----        wmode <= "00";
----        A_WEN(0) <= write;
----        A_WEN(1) <= write;
----        web_i(0) <= write;
----        web_i(1) <= write;
----        rea_i <= renable when write = '0' else '0';
----  		da <= bitbang_in(dbits, datain)(39 downto 20);
----  		db <= bitbang_in(dbits, datain)(19 downto 0);
----  		dataout <= qa & qb;
----  		aa(14 downto 14-(abits-1)) <= raddress; aa(14-(abits) downto 0) <= (others => '0');
----  		ab(14 downto 14-(abits-1)) <= waddress; ab(14-(abits) downto 0) <= (others => '0');
----  		u0 : RAM1K20
----		port map (
----			A_ADDR => aa(14 downto 1), A_CLK => rclk, A_DIN => da, A_DOUT => qa,
----			A_WEN => A_WEN, A_WIDTH => width, A_BYPASS => a_bypass,
----			A_DOUT_EN => rea_i, A_DOUT_SRST_N => vcc, A_DOUT_ARST_N => vcc,
----			A_BLK_EN => a_blk_en, A_REN => rea_i,	
----			A_WMODE => wmode,

----			B_ADDR => ab(14 downto 1), B_CLK => wclk, B_DIN => db, B_DOUT => qb,
----			B_WEN => web_i, B_WIDTH => width, B_BYPASS => b_bypass,
----			B_DOUT_EN => rea_i, B_DOUT_SRST_N => vcc, B_DOUT_ARST_N => vcc,
----			B_BLK_EN => b_blk_en, B_REN => '0',
----			B_WMODE => wmode,

----			ECC_EN => ecc_en, ECC_BYPASS => ecc_bypass,
----			SB_CORRECT => open, DB_DETECT => open, 	BUSY_FB => gnd,
----			ACCESS_BUSY => open
----		);
----	end;

----library ieee;
----use ieee.std_logic_1164.all;

----entity polarfire_syncram is
----  	generic (
----  		abits 		: integer := 10; 
----  		dbits 		: integer := 8; 
----  		ecc 		: integer range 0 to 1 := 0;
----        doutpipe 	: integer := 0; 
----        eccpipe 	: integer := 0
----    );
----  	port (
----    	clk      	: in  std_ulogic;
----    	address  	: in  std_logic_vector((abits -1) downto 0);
----    	datain   	: in  std_logic_vector((dbits -1) downto 0);
----    	dataout  	: out std_logic_vector((dbits -1) downto 0);
----    	enable   	: in  std_ulogic;
----    	write    	: in  std_ulogic;
----    	error    	: out std_logic_vector(1 downto 0)
----    );
----end entity;

----architecture rtl of polarfire_syncram is
----	component polarfire_syncram_dp
----  		generic ( 
----  			abits 		: integer := 8; 
----  			dbits 		: integer := 32; 
----    	    doutpipe 	: integer := 0);
----  		port (
----    		clk1     	: in  std_ulogic;
----    		address1 	: in  std_logic_vector((abits -1) downto 0);
----    		datain1  	: in  std_logic_vector((dbits -1) downto 0);
----    		dataout1 	: out std_logic_vector((dbits -1) downto 0);
----    		enable1  	: in  std_ulogic;
----    		write1   	: in  std_ulogic;
----    		clk2     	: in  std_ulogic;
----    		address2 	: in  std_logic_vector((abits -1) downto 0);
----    		datain2  	: in  std_logic_vector((dbits -1) downto 0);
----    		dataout2 	: out std_logic_vector((dbits -1) downto 0);
----    		enable2  	: in  std_ulogic;
----    		write2   	: in  std_ulogic
----    	);
----	end component;

----	component polarfire_syncram_2p
----  		generic ( 
----  			abits 		: integer := 8; 
----  			dbits 		: integer := 32; 
----  			sepclk 		: integer := 0;
----    	    ecc 		: integer range 0 to 1 := 0; 
----    	    doutpipe 	: integer := 0; 
----    	    eccpipe 	: integer := 0);
----  		port (
----    		rclk     	: in  std_ulogic;
----    		renable  	: in  std_ulogic;
----    		raddress 	: in  std_logic_vector((abits-1) downto 0);
----    		dataout  	: out std_logic_vector((dbits-1) downto 0);
----    		rerror   	: out std_logic_vector(1 downto 0);
----    		wclk     	: in  std_ulogic;
----    		write    	: in  std_ulogic;
----    		waddress 	: in  std_logic_vector((abits-1) downto 0);
----    		datain   	: in  std_logic_vector((dbits-1) downto 0)
----    	);
----	end component;

----	signal gnd : std_logic_vector(abits+dbits downto 0);
----begin
----	gnd <= (others => '0');
----	rdp  : if abits > 9 generate 
----    	u0 : polarfire_syncram_dp generic map (
----    			abits => abits, dbits => dbits,	doutpipe => doutpipe)
----    	    port map (
----    	    	clk1 => clk, address1 => address, datain1 => datain,
----    	    	dataout1 => dataout, write1 => write, enable1 => enable,
----    	    	clk2 => clk, address2 => gnd(abits-1 downto 0), datain2 => gnd(dbits-1 downto 0),
----    	    	dataout2 => open, write2 => gnd(0), enable2 => gnd(0));
----  	end generate;
----  	r2p : if abits <= 9 generate
----  		u0 : polarfire_syncram_2p generic map (
----  			abits => abits, dbits => dbits, doutpipe => doutpipe,
----  			ecc => ecc, eccpipe => eccpipe, sepclk => 0)
----  		port map (
----    		rclk => clk, renable => enable, raddress => address,
----    		dataout	=> dataout, rerror => open, wclk => clk,
----    		write => write, waddress => address, datain => datain
----    	);
----    end generate;
----end;

----library ieee;
----use ieee.std_logic_1164.all;

----entity polarfire_syncram_dp is
----  	generic ( 
----  		abits 		: integer := 10; 
----  		dbits 		: integer := 8; 
----  		doutpipe 	: integer := 0
----  	);
----  	port (
----    	clk1     	: in  std_ulogic;
----    	address1 	: in  std_logic_vector((abits -1) downto 0);
----    	datain1  	: in  std_logic_vector((dbits -1) downto 0);
----    	dataout1 	: out std_logic_vector((dbits -1) downto 0);
----    	enable1  	: in  std_logic_vector((dbits -1)/8 downto 0);
----    	write1   	: in  std_ulogic;
----    	clk2     	: in  std_ulogic;
----    	address2 	: in  std_logic_vector((abits -1) downto 0);
----    	datain2  	: in  std_logic_vector((dbits -1) downto 0);
----    	dataout2 	: out std_logic_vector((dbits -1) downto 0);
----    	enable1  	: in  std_logic_vector((dbits -1)/8 downto 0);
----    	write2   	: in  std_ulogic
----    );
----end entity;

----architecture rtl of polarfire_syncram_dp is
----	component polarfire_ram1k20
----		generic (
----			abits			: integer range 9 to 14 := 11;
----			dbits 			: integer := 8;
----			sepclk 			: integer := 0;
----    	    ecc 			: integer range 0 to 1 := 0; 
----    	    doutpipe 		: integer := 0; 
----    	    eccpipe 		: integer := 0
----		);
----  		port (
----			addra, addrb	: in  std_logic_vector(abits-1 downto 0);
----			clka, clkb 		: in  std_ulogic;
----			dia, dib     	: in  std_logic_vector(dbits -1 downto 0);
----    		doa, dob     	: out std_logic_vector(dbits -1 downto 0);
----    		ena, enb     	: in  std_ulogic;
----    		wea, web     	: in  std_ulogic
----  		) ;
----	end component;

----	constant dlen : integer := dbits + 20;
----	signal di1, di2, q1, q2 : std_logic_vector(dlen downto 0);
----  	signal a1, a2 : std_logic_vector(13 downto 0);
----  	signal en1, en2, we1, we2 : std_ulogic;
----begin
----	di1(dbits-1 downto 0) <= datain1; di1(dlen downto dbits) <= (others => '0');
----	di2(dbits-1 downto 0) <= datain1; di1(dlen downto dbits) <= (others => '0');
----	a1(abits-1 downto 0) <= address1; a1(13 downto abits) <= (others => '0');
----	a2(abits-1 downto 0) <= address1; a2(13 downto abits) <= (others => '0');
----	dataout1 <= q1(dbits-1 downto 0);
----	dataout2 <= q2(dbits-1 downto 0);
----	en1 <= enable1; en2 <= enable2;
----  	we1 <= write1; we2 <= write2;

----	a10 : if (abits <= 10) generate
----		x : for i in 0 to (dbits-1)/16 generate
----			u0 : polarfire_ram1k20 generic map (
----				abits => abits, dbits => 16, doutpipe => doutpipe
----			) port map (
----				clka => clk1, clkb => clk2, addra => a1(9 downto 0), addrb => a2(9 downto 0),
----				dia => di1(i*16+15 downto i*16), dib => di2(i*16+15 downto i*16), 
----				doa => q1(i*16+15 downto i*16), dob => q2(i*16+15 downto i*16),
----				ena => en1, enb => en2, wea => we1, web => we2
----			);
----		end generate;
----	end generate;
----	a11 : if (abits = 11) generate
----		x : for i in 0 to (dbits-1)/8 generate
----			u0 : polarfire_ram1k20 generic map (
----				abits => abits, dbits => 8, doutpipe => doutpipe
----			) port map (
----				clka => clk1, clkb => clk2, addra => a1(10 downto 0), addrb => a2(10 downto 0),
----				dia => di1(i*8+7 downto i*8), dib => di2(i*8+7 downto i*8), 
----				doa => q1(i*8+7 downto i*8), dob => q2(i*8+7 downto i*8),
----				ena => en1, enb => en2, wea => we1, web => we2
----			);
----		end generate;
----	end generate;
----	a12 : if (abits = 12) generate
----		x : for i in 0 to (dbits-1)/4 generate
----			u0 : polarfire_ram1k20 generic map (
----				abits => abits, dbits => 4, doutpipe => doutpipe
----			) port map (
----				clka => clk1, clkb => clk2, addra => a1(11 downto 0), addrb => a2(11 downto 0),
----				dia => di1(i*4+3 downto i*4), dib => di2(i*4+3 downto i*4), 
----				doa => q1(i*4+3 downto i*4), dob => q2(i*4+3 downto i*4),
----				ena => en1, enb => en2, wea => we1, web => we2
----			);
----		end generate;
----	end generate;
----	a13 : if (abits = 13) generate
----		x : for i in 0 to (dbits-1)/2 generate
----			u0 : polarfire_ram1k20 generic map (
----				abits => abits, dbits => 2, doutpipe => doutpipe
----			) port map (
----				clka => clk1, clkb => clk2, addra => a1(12 downto 0), addrb => a2(12 downto 0),
----				dia => di1(i*2+1 downto i*2), dib => di2(i*2+1 downto i*2), 
----				doa => q1(i*2+1 downto i*2), dob => q2(i*2+1 downto i*2),
----				ena => en1, enb => en2, wea => we1, web => we2
----			);
----		end generate;
----	end generate;
----	a14 : if (abits = 14) generate
----		x : for i in 0 to (dbits-1) generate
----			u0 : polarfire_ram1k20 generic map (
----				abits => abits, dbits => 1, doutpipe => doutpipe
----			) port map (
----				clka => clk1, clkb => clk2, addra => a1(13 downto 0), addrb => a2(13 downto 0),
----				dia => di1(i*1 downto i*1), dib => di2(i*1 downto i*1), 
----				doa => q1(i*1 downto i*1), dob => q2(i*1 downto i*1),
----				ena => en1, enb => en2, wea => we1, web => we2
----			);
----		end generate;
----	end generate;
----	-- pragma translate_off  
----  	unsup : if abits > 14 generate
----    	x : process
----    	begin
----    	  	assert false
----    	  	report  "Address depth larger than 14 not supported for PolarFire rams"
----    	  	severity failure;
----    	  	wait;
----    	end process;
----  	end generate;
----	-- pragma translate_on

----end;

----library ieee;
----use ieee.std_logic_1164.all;

----entity polarfire_syncram_2p is
----  	generic ( 
----  		abits 		: integer := 8; 
----  		dbits 		: integer := 32; 
----  		sepclk 		: integer := 0;
----        ecc 		: integer range 0 to 1 := 0; 
----        doutpipe 	: integer := 0; 
----        eccpipe 	: integer := 0);
----  	port (
----    	rclk     	: in  std_ulogic;
----    	renable  	: in  std_ulogic;
----    	raddress 	: in  std_logic_vector((abits-1) downto 0);
----    	dataout  	: out std_logic_vector((dbits-1) downto 0);
----    	rerror   	: out std_logic_vector(1 downto 0);
----    	wclk     	: in  std_ulogic;
----    	write    	: in  std_ulogic;
----    	waddress 	: in  std_logic_vector((abits-1) downto 0);
----    	datain   	: in  std_logic_vector((dbits-1) downto 0)
----    );
----end entity;

----architecture rtl of polarfire_syncram_2p is
----	component polarfire_ram521x40
----		generic (
----			abits			: integer range 9 to 14 := 11;
----			dbits 			: integer := 8;
----			sepclk 			: integer := 0;
----    	    ecc 			: integer range 0 to 1 := 0; 
----    	    doutpipe 		: integer := 0; 
----    	    eccpipe 		: integer := 0
----		);
----  		port (
----			rclk 	 		: in  std_ulogic;
----			wclk 	 		: in  std_ulogic;
----			raddress		: in  std_logic_vector(abits-1 downto 0);
----			waddress		: in  std_logic_vector(abits-1 downto 0);
----			datain 	    	: in  std_logic_vector(dbits-1 downto 0);
----    		dataout     	: out std_logic_vector(dbits-1 downto 0);
----    		renable     	: in  std_ulogic;
----    		write 	     	: in  std_ulogic
----  		) ;
----	end component;

----	component polarfire_ram1k20
----		generic (
----			abits			: integer range 9 to 14 := 11;
----			dbits 			: integer := 8;
----			sepclk 			: integer := 0;
----    	    ecc 			: integer range 0 to 1 := 0; 
----    	    doutpipe 		: integer := 0; 
----    	    eccpipe 		: integer := 0
----		);
----  		port (
----			addra, addrb	: in  std_logic_vector(abits-1 downto 0);
----			clka, clkb 		: in  std_ulogic;
----			dia, dib     	: in  std_logic_vector(dbits -1 downto 0);
----    		doa, dob     	: out std_logic_vector(dbits -1 downto 0);
----    		ena, enb     	: in  std_ulogic;
----    		wea, web     	: in  std_ulogic
----  		) ;
----	end component;

----	constant dlen : integer := dbits + 40;
----	signal di1, q2, gnd : std_logic_vector(dlen downto 0);
----  	signal a1, a2 : std_logic_vector(13 downto 0);
----  	signal en1, en2, we1, vcc : std_ulogic;
----begin
----	vcc <= '1'; gnd <= (others => '0');
----  	di1(dbits-1 downto 0) <= datain; di1(dlen downto dbits) <= (others => '0');
----	a1(abits-1 downto 0) <= waddress; a1(13 downto abits) <= (others => '0');
----  	a2(abits-1 downto 0) <= raddress; a2(13 downto abits) <= (others => '0');  	  	
----  	dataout <= q2(dbits-1 downto 0); q2(dlen downto dbits) <= (others => '0');
----  	en1 <= write; en2 <= renable; we1 <= write;

----  	a9 : if (abits <= 9) generate
----  		x : for i in 0 to (dbits-1)/40 generate
----  			u0 : polarfire_ram521x40 generic map (
----				abits => abits, dbits => 40, doutpipe => doutpipe
----			) port map (
----				rclk => rclk, wclk => wclk, 
----				raddress => a2(8 downto 0), 
----				waddress => a1(8 downto 0),
----				datain => di1(i*40+39 downto i*40),
----				dataout => q2(i*40+39 downto i*40),
----				renable => en2, write => we1
----			);
----		end generate;
----	end generate;
----	a10 : if (abits = 10) generate
----  		x : for i in 0 to (dbits-1)/16 generate
----  			u0 : polarfire_ram1k20 generic map (
----				abits => abits, dbits => 16, doutpipe => doutpipe
----			) port map (
----				clka => wclk, clkb => rclk, addra => a1(9 downto 0), addrb => a2(9 downto 0),
----				dia => di1(i*16+15 downto i*16), dib => (others => '0'), 
----				doa => open, dob => q2(i*16+15 downto i*16),
----				ena => en1, enb => en2, wea => write, web => '0'
----			);
----		end generate;
----	end generate;
----	a11 : if (abits = 11) generate
----  		x : for i in 0 to (dbits-1)/8 generate
----  			u0 : polarfire_ram1k20 generic map (
----				abits => abits, dbits => 8, doutpipe => doutpipe
----			) port map (
----				clka => wclk, clkb => rclk, addra => a1(10 downto 0), addrb => a2(10 downto 0),
----				dia => di1(i*8+7 downto i*8), dib => (others => '0'), 
----				doa => open, dob => q2(i*8+7 downto i*8),
----				ena => en1, enb => en2, wea => write, web => '0'
----			);
----		end generate;
----	end generate;
----	a12 : if (abits = 12) generate
----  		x : for i in 0 to (dbits-1)/4 generate
----  			u0 : polarfire_ram1k20 generic map (
----				abits => abits, dbits => 4, doutpipe => doutpipe
----			) port map (
----				clka => wclk, clkb => rclk, addra => a1(11 downto 0), addrb => a2(11 downto 0),
----				dia => di1(i*4+3 downto i*4), dib => (others => '0'), 
----				doa => open, dob => q2(i*4+3 downto i*4),
----				ena => en1, enb => en2, wea => write, web => '0'
----			);
----		end generate;
----	end generate;
----	a13 : if (abits = 13) generate
----  		x : for i in 0 to (dbits-1)/2 generate
----  			u0 : polarfire_ram1k20 generic map (
----				abits => abits, dbits => 2, doutpipe => doutpipe
----			) port map (
----				clka => wclk, clkb => rclk, addra => a1(12 downto 0), addrb => a2(12 downto 0),
----				dia => di1(i*2+1 downto i*2), dib => (others => '0'), 
----				doa => open, dob => q2(i*2+1 downto i*2),
----				ena => en1, enb => en2, wea => write, web => '0'
----			);
----		end generate;
----	end generate;
----	a14 : if (abits = 14) generate
----  		x : for i in 0 to (dbits-1)/1 generate
----  			u0 : polarfire_ram1k20 generic map (
----				abits => abits, dbits => 1, doutpipe => doutpipe
----			) port map (
----				clka => wclk, clkb => rclk, addra => a1(13 downto 0), addrb => a2(13 downto 0),
----				dia => di1(i*1 downto i*1), dib => (others => '0'), 
----				doa => open, dob => q2(i*1 downto i*1),
----				ena => en1, enb => en2, wea => write, web => '0'
----			);
----		end generate;
----	end generate;
----end;

----library ieee;
----use ieee.std_logic_1164.all;

----entity polarfire_syncram_be is
----  	generic (
----  		abits 		: integer := 6; 
----  		dbits 		: integer := 8; 
----  		doutpipe 	: integer := 0
----  	);
----  	port (
----    	clk      	: in  std_ulogic;
----    	address  	: in  std_logic_vector((abits -1) downto 0);
----    	datain   	: in  std_logic_vector((dbits -1) downto 0);
----    	dataout  	: out std_logic_vector((dbits -1) downto 0);
----    	enable   	: in  std_logic_vector (dbits/8-1 downto 0);
----    	write    	: in  std_logic_vector (dbits/8-1 downto 0)
----    );
----end entity;

----architecture rtl of polarfire_syncram_be is
----begin
	
----end;