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
		clkperiod    : integer := 20;
		refclkperiod : integer := 8
	);
end;

architecture behav of testbench is

	component dut is
	generic (
		g_master : boolean := true
	);
	port (
		rst         : in  std_logic;
		clk         : in  std_logic;
		debug_ahbmo : in  ahb_mst_out_type;
		debug_ahbmi : out ahb_mst_in_type;
		sclk_o      : out std_logic;
		sclk_i      : in  std_logic;
		mosi_o      : out std_logic;
		mosi_i      : in  std_logic;
		miso_o      : out std_logic;
		miso_i      : in  std_logic;
		ss_n_o      : out std_logic;
		ss_n_i      : in  std_logic;
		serdes_ready: out std_logic;
		clk_out     : out std_logic
	);
	end component;


	constant ct       : integer := clkperiod/2;
	constant refct    : integer := refclkperiod/2;

	signal  ctrl_a, ctrl_b      : ahbtb_ctrl_type;

	signal d_ahbmi_a, d_ahbmi_b : ahb_mst_in_type;
	signal d_ahbmo_a, d_ahbmo_b : ahb_mst_out_type;

	signal clk_out : std_logic;

---------------------------------------------------------------------------
-- generic pads -----------------------------------------------------------
---------------------------------------------------------------------------
	signal   addr      : std_logic := '1';
	signal   resetn    : std_logic := '0';
	signal   clk       : std_ulogic := '0';
	signal   refclk    : std_ulogic := '0';
	signal   refclk_n  : std_ulogic;
	signal   devrst_n  : std_logic := '0';

	-- SPI loopback: master (dut_a) <-> slave (dut_b)
	signal   spi_sclk  : std_logic;
	signal   spi_mosi  : std_logic;
	signal   spi_miso  : std_logic;
	signal   spi_ss_n  : std_logic;

	-- discarded outputs of master miso_o and slave sclk_o/mosi_o/ss_n_o
	signal   dummy_a_miso_o : std_logic;
	signal   dummy_b_sclk_o : std_logic;
	signal   dummy_b_mosi_o : std_logic;
	signal   dummy_b_ss_n_o : std_logic;

	signal   ready_a   : std_logic;
	signal   ready_b   : std_logic;


begin  -- architecture behav

	dut_a : dut
		generic map (
			g_master => true
		)
		port map (
			rst          => resetn,
			clk          => clk,
			debug_ahbmo  => d_ahbmo_a,
			debug_ahbmi  => d_ahbmi_a,
			sclk_o       => spi_sclk,
			sclk_i       => '0',
			mosi_o       => spi_mosi,
			mosi_i       => '0',
			miso_o       => dummy_a_miso_o,
			miso_i       => spi_miso,
			ss_n_o       => spi_ss_n,
			ss_n_i       => '1',
			serdes_ready => ready_a,
			clk_out      => clk_out
		);

	dut_b : dut
		generic map (
			g_master => false
		)
		port map (
			rst          => resetn,
			clk          => clk,
			debug_ahbmo  => d_ahbmo_b,
			debug_ahbmi  => d_ahbmi_b,
			sclk_o       => dummy_b_sclk_o,
			sclk_i       => spi_sclk,
			mosi_o       => dummy_b_mosi_o,
			mosi_i       => spi_mosi,
			miso_o       => spi_miso,
			miso_i       => '0',
			ss_n_o       => dummy_b_ss_n_o,
			ss_n_i       => spi_ss_n,
			serdes_ready => ready_b,
			clk_out      => open
		);

	clk      <= not clk    after ct * 1 ns;
	refclk   <= not refclk after refct * 1 ns;
	refclk_n <= not refclk;
	resetn   <= '1'        after 1000 ns;
	devrst_n <= '1'        after 100 ns;


	ahbtbm_a : ahbtbm
		generic map(hindex => 1)
		port map(ready_a, clk_out, ctrl_a.i, ctrl_a.o, d_ahbmi_a, d_ahbmo_a);

	ahbtbm_b : ahbtbm
		generic map(hindex => 1)
		port map(ready_b, clk_out, ctrl_b.i, ctrl_b.o, d_ahbmi_b, d_ahbmo_b);

	process
	variable i: integer;
	begin
		report "TEST: waiting for ready_a and ready_b";
		wait until ((ready_a and ready_b) = '1');
		report "TEST: both DUTs ready, initializing ahbtbm";
		ahbtbminit(ctrl_a);
		ahbtbminit(ctrl_b);
		report "TEST: ahbtbm init complete";

		-- Sanity test: write to local AHB RAM (slave 0) of master DUT
		ahbwrite(x"00000000", x"DEADBEEF", "10", 3, TRUE, ctrl_a);
		report "TEST: sanity write to ahbram complete";
		ahbread(x"00000000", x"DEADBEEF", "10", 3, TRUE, ctrl_a);
		report "TEST: sanity read from ahbram complete";

		report "TEST: loading 128 words into serahb data RAM";
		-- Load 128 words of test data into serahb's local data RAM (offset 0x1000+)
		for i in 0 to 127 loop
			ahbwrite(('1' & std_logic_vector(to_unsigned(4096 + i*4,31))),
			         std_logic_vector(to_unsigned(i,32)), "10", 3, FALSE, ctrl_a);
		end loop;
		report "TEST: 128 words loaded";

		-- Configure and start a SERAHB transaction on master side
		ahbwrite(x"80000008", x"00000000", "10", 3, FALSE, ctrl_a);  -- target address
		ahbwrite(x"8000000C", x"00800045", "10", 3, FALSE, ctrl_a);  -- length / timeout
		ahbwrite(x"80000000", x"0000001D", "10", 3, TRUE,  ctrl_a);  -- CTRL: start
		ahbtbmidle(TRUE, ctrl_b);

		-- SPI is slower than SERDES. Allow ample time for the byte stream.
		wait for 2000 us;
		ahbread(x"80000004", x"0000001C", "10", 3, TRUE, ctrl_a);
		ahbread(x"80000004", x"00000000", "10", 3, TRUE, ctrl_a);

		wait for 5 us;
		ahbwrite(x"80000008", x"00000000", "10", 3, FALSE, ctrl_a);
		ahbwrite(x"8000000C", x"0080FFFF", "10", 3, FALSE, ctrl_a);
		ahbwrite(x"80000000", x"00000003", "10", 3, TRUE,  ctrl_a);

		wait for 2000 us;

		for i in 0 to 127 loop
			ahbread(('1' & std_logic_vector(to_unsigned(4096+i*4,31))),
			        std_logic_vector(to_unsigned(i,32)), "10", 3, FALSE, ctrl_a);
		end loop;

		ahbtbmdone(0, ctrl_a);
		ahbtbmdone(0, ctrl_b);

	end process;


end architecture behav;
