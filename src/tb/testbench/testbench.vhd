library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library gaisler;
use gaisler.ahbtbp.all;

library grlib;
use grlib.amba.all;

library techmap;
use techmap.gencomp.all;
library lfast_comps;
use lfast_comps.all;

entity testbench is
    generic (
        clkperiod                       : integer := 20;
        refclkperiod                       : integer := 8
    );
end;

architecture behav of testbench is

    component dut is
    port (
		rst 		: in std_logic;
		clk 		: in std_logic;
		debug_ahbmo	: in ahb_mst_out_type;
		debug_ahbmi	: out ahb_mst_in_type;
		RXD0_N		: in std_logic;
		RXD0_P		: in std_logic;
		RXD1_N		: in std_logic;
		RXD1_P		: in std_logic;
		RXD2_N		: in std_logic;
		RXD2_P		: in std_logic;
		RXD3_N		: in std_logic;
		RXD3_P		: in std_logic;
		TXD0_N		: out std_logic;
		TXD0_P		: out std_logic;
		TXD1_N		: out std_logic;
		TXD1_P		: out std_logic;
		TXD2_N		: out std_logic;
		TXD2_P		: out std_logic;
		TXD3_N		: out std_logic;
		TXD3_P		: out std_logic;
		serdes_ready: out std_logic;
		clk_out		: out std_logic
    );
    end component;


    constant ct       : integer := clkperiod/2;
    constant refct    : integer := refclkperiod/2;
	--															0	0	  0	  0		2	0	 9	 0		B	F	5	 5
	--constant uart_packet : std_logic_vector(59 downto 0) := "100000000010000000001001000000110010000011011111101010101010";

    signal  ctrl_a, ctrl_b      : ahbtb_ctrl_type;
	
	signal d_ahbmi_a, d_ahbmi_b : ahb_mst_in_type;
	signal d_ahbmo_a, d_ahbmo_b : ahb_mst_out_type;
	
	signal clk_out : std_logic;
	
	
	--signal clk_dbg, rst_dbg, rxd, txd : std_logic;

---------------------------------------------------------------------------
-- generic pads -----------------------------------------------------------
---------------------------------------------------------------------------
    signal   addr    : std_logic := '1';			-- VCC => A1, GND => A2
    signal   resetn  : std_logic := '0';
    signal   clk    : std_ulogic := '0';
    signal   refclk    : std_ulogic := '0';
    signal   refclk_n    : std_ulogic;
    signal   devrst_n   : std_logic := '0';

	signal	ba0_n : std_logic;
	signal	ba0_p : std_logic;
	signal	ba1_n : std_logic;
	signal	ba1_p : std_logic;
	signal	ba2_n : std_logic;
	signal	ba2_p : std_logic;
	signal	ba3_n : std_logic;
	signal	ba3_p : std_logic;
	signal	ab0_n : std_logic;
	signal	ab0_p : std_logic;
	signal	ab1_n : std_logic;
	signal	ab1_p : std_logic;
	signal	ab2_n : std_logic;
	signal	ab2_p : std_logic;
	signal	ab3_n : std_logic;
	signal	ab3_p : std_logic;
	
	signal	ready_a	: std_logic;
	signal	ready_b	: std_logic;


begin  -- architecture behav

    dut_a : dut
        port map (
			rst 			=> resetn,
			clk 			=> clk,
			debug_ahbmo		=> d_ahbmo_a,
			debug_ahbmi		=> d_ahbmi_a,
			RXD0_N			=> ba0_n,
			RXD0_P			=> ba0_p,
			RXD1_N			=> ba1_n,
			RXD1_P			=> ba1_p,
			RXD2_N			=> ba2_n,
			RXD2_P			=> ba2_p,
			RXD3_N			=> ba3_n,
			RXD3_P			=> ba3_p,
			TXD0_N			=> ab0_n,
			TXD0_P			=> ab0_p,
			TXD1_N			=> ab1_n,
			TXD1_P			=> ab1_p,
			TXD2_N			=> ab2_n,
			TXD2_P			=> ab2_p,
			TXD3_N			=> ab3_n,
			TXD3_P			=> ab3_p,
			serdes_ready	=> ready_a,
			clk_out			=> clk_out
    );

	dut_b : dut
        port map (
			rst 			=> resetn,
			clk 			=> clk,
			debug_ahbmo		=> d_ahbmo_b,
			debug_ahbmi		=> d_ahbmi_b,
			RXD0_N			=> ab0_n,
			RXD0_P			=> ab0_p,
			RXD1_N			=> ab1_n,
			RXD1_P			=> ab1_p,
			RXD2_N			=> ab2_n,
			RXD2_P			=> ab2_p,
			RXD3_N			=> ab3_n,
			RXD3_P			=> ab3_p,
			TXD0_N			=> ba0_n,
			TXD0_P			=> ba0_p,
			TXD1_N			=> ba1_n,
			TXD1_P			=> ba1_p,
			TXD2_N			=> ba2_n,
			TXD2_P			=> ba2_p,
			TXD3_N			=> ba3_n,
			TXD3_P			=> ba3_p,
			serdes_ready	=> ready_b,
			clk_out			=> open
    );

   

    clk    <= not clk after ct * 1 ns;
    refclk    <= not refclk after refct * 1 ns;
    refclk_n <= not refclk;
    resetn <= '1'     after 1000 ns;
    devrst_n <= '1'     after 100 ns;
	
	
	ahbtbm_a : ahbtbm
        generic map(hindex => 1) -- AMBA master index 0
        port map(ready_a, clk_out, ctrl_a.i, ctrl_a.o, d_ahbmi_a, d_ahbmo_a);
		
	ahbtbm_b : ahbtbm
        generic map(hindex => 1) -- AMBA master index 0
        port map(ready_b, clk_out, ctrl_b.i, ctrl_b.o, d_ahbmi_b, d_ahbmo_b);

    process 
	variable i: integer;
	begin
		--rxd <= '1';
		wait until ((ready_a and ready_b) = '1');
        ahbtbminit(ctrl_a);
		ahbtbminit(ctrl_b);
		--wait until ((ready_a and ready_b) = '1');
        
		for i in 0 to 127 loop
			ahbwrite(('1' & std_logic_vector(to_unsigned(4096 + i*4,31))), std_logic_vector(to_unsigned(i,32)), "10", 3, FALSE, ctrl_a);
		end loop; 
		-- Software reset
        --ahbwrite(x"80001000", x"80000008", "10", 3, FALSE, ctrl_a);
		--ahbwrite(x"80001004", x"0002FFFF", "10", 3, FALSE, ctrl_a);
        ahbwrite(x"80000008", x"00000000", "10", 3, FALSE, ctrl_a);
		ahbwrite(x"8000000C", x"00800045", "10", 3, FALSE, ctrl_a);
        ahbwrite(x"80000000", x"0000001D", "10", 3, TRUE, ctrl_a);
		ahbtbmidle(TRUE, ctrl_b);
		
		wait for 50 us;
		ahbread(x"80000004", x"0000001C", "10", 3, TRUE, ctrl_a);
		ahbread(x"80000004", x"00000000", "10", 3, TRUE, ctrl_a);
		wait for 5 us;
		--ahbwrite(x"80001000", x"00000005", "10", 3, FALSE, ctrl_a);
        ahbwrite(x"80000008", x"00000000", "10", 3, FALSE, ctrl_a);
		ahbwrite(x"8000000C", x"0080FFFF", "10", 3, FALSE, ctrl_a);
        ahbwrite(x"80000000", x"00000003", "10", 3, TRUE, ctrl_a);
		
		--ahbwrite(x"80000008", x"00000130", "10", 3, FALSE, ctrl_a);
        --ahbwrite(x"8000000C", x"0035FFFF", "10", 3, FALSE, ctrl_a);
        --ahbwrite(x"80000000", x"00000003", "10", 3, TRUE, ctrl_a);
		
		wait for 50 us;
		
		--ahbread(x"80000004", x"0000001C", "10", 3, TRUE, ctrl_a);
		for i in 0 to 127 loop
			ahbread(('1' & std_logic_vector(to_unsigned(4096+i*4,31))), std_logic_vector(to_unsigned(i,32)), "10", 3, FALSE, ctrl_a);
		end loop; 
        --ahbread(x"20000000", x"FFFFFFFF", "10", 3, FALSE, ctrl);
        --ahbwrite(x"20000000", x"11223344", "10", 3, FALSE, ctrl);
        --ahbread(x"30000000", x"FFFFFFFF", "10", 3, FALSE, ctrl);
        --ahbwrite(x"30000000", x"99887766", "10", 3, FALSE, ctrl);

        --ahbwrite(x"00200000", x"11111111", "10", 3, FALSE, ctrl);
        --ahbwrite(x"10000000", x"11111111", "10", 3, FALSE, ctrl);
        -- ahbwrite(x"00200004", x"22222222", "10", 3, FALSE, ctrl);
        -- ahbwrite(x"00200008", x"33333333", "10", 3, FALSE, ctrl);
        -- ahbwrite(x"0020000C", x"44444444", "10", 3, FALSE, ctrl);

        -- ahbwrite(x"08000000", x"55555555", "10", 3, FALSE, ctrl);
        -- ahbwrite(x"08000004", x"66666666", "10", 3, FALSE, ctrl);
        -- ahbwrite(x"08000008", x"77777777", "10", 3, FALSE, ctrl);
        -- ahbwrite(x"0800000C", x"88888888", "10", 3, FALSE, ctrl);

        -- ahbwrite(x"C0000000", x"AAAAAAAA", "10", 3, FALSE, ctrl);
        -- ahbwrite(x"C0000004", x"BBBBBBBB", "10", 3, FALSE, ctrl);
        -- ahbwrite(x"C0000008", x"CCCCCCCC", "10", 3, FALSE, ctrl);
        -- ahbwrite(x"C000000C", x"DDDDDDDD", "10", 3, FALSE, ctrl);

        -- -- ahbwrite(x"11800000", x"EEEEEEEE", "10", 3, FALSE, ctrl);
        -- -- ahbwrite(x"11800004", x"FFFFFFFF", "10", 3, FALSE, ctrl);
        -- -- ahbwrite(x"11800008", x"00000000", "10", 3, FALSE, ctrl);
        -- -- ahbwrite(x"1180000C", x"99999999", "10", 3, FALSE, ctrl);

        -- ahbread(x"00200000", x"11111111", "10", 3, FALSE, ctrl);
        -- ahbread(x"00200004", x"22222222", "10", 3, FALSE, ctrl);
        -- ahbread(x"00200008", x"33333333", "10", 3, FALSE, ctrl);
        -- ahbread(x"0020000C", x"44444444", "10", 3, FALSE, ctrl);

        -- ahbread(x"08000000", x"55555555", "10", 3, FALSE, ctrl);
        -- ahbread(x"08000004", x"66666666", "10", 3, FALSE, ctrl);
        -- ahbread(x"08000008", x"77777777", "10", 3, FALSE, ctrl);
        -- ahbread(x"0800000C", x"88888888", "10", 3, FALSE, ctrl);

        -- ahbread(x"C0000000", x"AAAAAAAA", "10", 3, FALSE, ctrl);
        -- ahbread(x"C0000004", x"BBBBBBBB", "10", 3, FALSE, ctrl);
        -- ahbread(x"C0000008", x"CCCCCCCC", "10", 3, FALSE, ctrl);
        -- ahbread(x"C000000C", x"DDDDDDDD", "10", 3, FALSE, ctrl);

        -- ahbread(x"80000400", x"800004CC", "10", 3, FALSE, ctrl);
        -- ahbread(x"80000404", x"FFFFFFFF", "10", 3, FALSE, ctrl);
        -- ahbread(x"80000408", x"00000000", "10", 3, FALSE, ctrl);
        -- ahbread(x"8000040C", x"80040000", "10", 3, FALSE, ctrl);
        
         ahbtbmdone(0, ctrl_a);
		 ahbtbmdone(0, ctrl_b);
		
		
	-- for i in 0 to 59 loop
		-- wait for 5000 ns;
		-- rxd <= uart_packet(i);
	-- end loop;
		 
    end process;


end architecture behav;

