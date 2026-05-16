library ieee;
use ieee.std_logic_1164.all;

library gaisler;
use gaisler.ahbtbp.all;
use gaisler.misc.all;

library grlib;
use grlib.amba.all;
use grlib.stdlib.all;
use grlib.devices.all;
use grlib.config_types.all;
use grlib.config.all;

library techmap;
use techmap.gencomp.all;

library lfast_comps;
use lfast_comps.all;

entity dut is
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
end dut;

architecture arch of dut is

	component FCCC_C0 is
		port (
			CLK0_PAD : in  std_logic;
			GL0      : out std_logic;
			GL1      : out std_logic;
			LOCK     : out std_logic
		);
	end component;

	component spi_phy is
		generic(
			g_master  : boolean := true;
			g_clk_div : integer := 5
		);
		port(
			clk        : in  std_logic;
			rstn       : in  std_logic;
			tx_byte_i  : in  std_logic_vector(7 downto 0);
			tx_valid_i : in  std_logic;
			tx_req_o   : out std_logic;
			rx_byte_o  : out std_logic_vector(7 downto 0);
			rx_valid_o : out std_logic;
			sclk_o     : out std_logic;
			sclk_i     : in  std_logic;
			mosi_o     : out std_logic;
			mosi_i     : in  std_logic;
			miso_o     : out std_logic;
			miso_i     : in  std_logic;
			ss_n_o     : out std_logic;
			ss_n_i     : in  std_logic
		);
	end component;

	component serahb is
		generic(
			hindex : integer := 0;
			haddr  : integer := 0;
			hmask  : integer := 16#fff#;
			mindex : integer := 0;
			hirq   : integer := 0
		);
		port (
			clk            : IN  std_logic;
			rst            : IN  std_logic;
			ahbsi          : IN  ahb_slv_in_type;
			ahbso          : OUT ahb_slv_out_type;
			ahbmi          : IN  ahb_mst_in_type;
			ahbmo          : OUT ahb_mst_out_type;
			lf_req_data_tx : IN  std_logic;
			lf_data_val_rx : IN  std_logic;
			lf_data_rx     : IN  std_logic_vector(7 downto 0);
			lf_data_rdy_tx : OUT std_logic;
			lf_data_tx     : OUT std_logic_vector(7 downto 0);
			lf_data_val_tx : OUT std_logic
		);
	end component;

	signal ahbsi : ahb_slv_in_type;
	signal ahbso : ahb_slv_out_vector := (others => ahbs_none);
	signal ahbmi : ahb_mst_in_type;
	signal ahbmo : ahb_mst_out_vector := (others => ahbm_none);

	signal lf_req_data_tx : std_logic;
	signal lf_data_val_rx : std_logic;
	signal lf_data_rx     : std_logic_vector(7 downto 0);
	signal lf_data_rdy_tx : std_logic;
	signal lf_data_tx     : std_logic_vector(7 downto 0);
	signal lf_data_val_tx : std_logic;

	signal clkm     : std_logic;
	signal pll_lock : std_logic;

begin  -- architecture arch

	ahbmo(1) <= debug_ahbmo;
	debug_ahbmi <= ahbmi;

	clk_out <= clkm;
	-- Ready when reset is deasserted (rst is active-low)
	serdes_ready <= rst;

	-- Simulation bypass: FCCC_C0 SmartFusion2 PLL model exhibits clock-startup
	-- issues in pure VHDL simulation. Since clk in is already 50 MHz, pass through.
	-- Real hardware retains FCCC_C0 (see serahb_fpga.vhd).
	clkm <= clk;
	pll_lock <= '1';

	-- pll0 : FCCC_C0
	--     port map (
	--         CLK0_PAD => clk,
	--         GL0      => clkm,
	--         GL1      => open,
	--         LOCK     => pll_lock
	--     );

	spi0 : spi_phy
		generic map (
			g_master  => g_master,
			g_clk_div => 5
		)
		port map (
			clk        => clkm,
			rstn       => rst,
			tx_byte_i  => lf_data_tx,
			tx_valid_i => lf_data_val_tx,
			tx_req_o   => lf_req_data_tx,
			rx_byte_o  => lf_data_rx,
			rx_valid_o => lf_data_val_rx,
			sclk_o     => sclk_o,
			sclk_i     => sclk_i,
			mosi_o     => mosi_o,
			mosi_i     => mosi_i,
			miso_o     => miso_o,
			miso_i     => miso_i,
			ss_n_o     => ss_n_o,
			ss_n_i     => ss_n_i
		);

	ahb0 : ahbctrl                        -- AHB arbiter/multiplexer
		generic map (
			fpnpen   => 1,
			ahbtrace => 1,
			nahbm    => 2,
			nahbs    => 2
		)
		port map (rst, clkm, ahbmi, ahbmo, ahbsi, ahbso);

	ahbram0: ahbram
		generic map (
			tech   => 0,
			kbytes => 64
		)
		port map (rst, clkm, ahbsi, ahbso(0));

	serial_ahb0: serahb
		generic map (
			hindex => 1,
			haddr  => 16#800#,
			hmask  => 16#fff#,
			mindex => 0,
			hirq   => 0
		)
		port map (
			clk            => clkm,
			rst            => rst,
			ahbsi          => ahbsi,
			ahbso          => ahbso(1),
			ahbmi          => ahbmi,
			ahbmo          => ahbmo(0),
			lf_req_data_tx => lf_req_data_tx,
			lf_data_val_rx => lf_data_val_rx,
			lf_data_rx     => lf_data_rx,
			lf_data_rdy_tx => lf_data_rdy_tx,
			lf_data_tx     => lf_data_tx,
			lf_data_val_tx => lf_data_val_tx
		);

end architecture arch;
