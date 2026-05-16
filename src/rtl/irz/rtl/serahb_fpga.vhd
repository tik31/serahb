library ieee;
use ieee.std_logic_1164.all;

library gaisler;
use gaisler.ahbtbp.all;
use gaisler.misc.all;
use gaisler.jtag.all;

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

entity serahb_fpga is
	generic (
		g_master : boolean := true
	);
	port (
		clkin  : in  std_logic;
		rst    : in  std_logic;
		sclk_o : out std_logic;
		sclk_i : in  std_logic;
		mosi_o : out std_logic;
		mosi_i : in  std_logic;
		miso_o : out std_logic;
		miso_i : in  std_logic;
		ss_n_o : out std_logic;
		ss_n_i : in  std_logic
	);
end serahb_fpga;

architecture arch of serahb_fpga is

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

	constant CFG_NCPU                   : integer := 0;
	constant LEON3_MHINDEX              : integer := 0;
	constant AHBJTAG_MHINDEX            : integer := 0;
	constant SERAHB_MHINDEX             : integer := 1;
	constant AHBRAM_SHINDEX             : integer := 0;
	constant SERAHB_SHINDEX             : integer := 1;
	constant UNUSED_SHINDEX             : integer := 2;
	constant AHBRAM_SHADDR              : integer := 16#000#;
	constant APBCTRL_SHADDR             : integer := 16#800#;
	constant SERAHB_SHADDR              : integer := 16#100#;
	constant AHBJTAG_PINDEX             : integer := 0;
	constant IRQMP_PINDEX               : integer := 1;
	constant AHBJTAG_PADDR              : integer := 0;
	constant IRQMP_PADDR                : integer := 1;
	constant SERAHB_IRQ                 : integer := 1;

	signal ahbsi : ahb_slv_in_type;
	signal ahbso : ahb_slv_out_vector := (others => ahbs_none);
	signal ahbmi : ahb_mst_in_type;
	signal ahbmo : ahb_mst_out_vector := (others => ahbm_none);
	signal apbi0 : apb_slv_in_type;
	signal apbo0 : apb_slv_out_vector := (others => apb_none);

	signal lf_req_data_tx : std_logic;
	signal lf_data_val_rx : std_logic;
	signal lf_data_rx     : std_logic_vector(7 downto 0);
	signal lf_data_rdy_tx : std_logic;
	signal lf_data_tx     : std_logic_vector(7 downto 0);
	signal lf_data_val_tx : std_logic;

	signal clk      : std_logic;
	signal pll_lock : std_logic;

begin  -- architecture arch

	pll0 : FCCC_C0
		port map (
			CLK0_PAD => clkin,
			GL0      => clk,
			GL1      => open,
			LOCK     => pll_lock
		);

	spi0 : spi_phy
		generic map (
			g_master  => g_master,
			g_clk_div => 5
		)
		port map (
			clk        => clk,
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
		port map (rst, clk, ahbmi, ahbmo, ahbsi, ahbso);

	ahbram0: ahbram
		generic map (
			hindex => AHBRAM_SHINDEX,
			haddr  => AHBRAM_SHADDR,
			tech   => 0,
			kbytes => 64
		)
		port map (rst, clk, ahbsi, ahbso(AHBRAM_SHINDEX));

	serial_ahb0: serahb
		generic map (
			hindex => SERAHB_SHINDEX,
			haddr  => SERAHB_SHADDR,
			hmask  => 16#fff#,
			mindex => SERAHB_MHINDEX,
			hirq   => SERAHB_IRQ
		)
		port map (
			clk            => clk,
			rst            => rst,
			ahbsi          => ahbsi,
			ahbso          => ahbso(SERAHB_SHINDEX),
			ahbmi          => ahbmi,
			ahbmo          => ahbmo(SERAHB_MHINDEX),
			lf_req_data_tx => lf_req_data_tx,
			lf_data_val_rx => lf_data_val_rx,
			lf_data_rx     => lf_data_rx,
			lf_data_rdy_tx => lf_data_rdy_tx,
			lf_data_tx     => lf_data_tx,
			lf_data_val_tx => lf_data_val_tx
		);

	ahbmo(AHBJTAG_MHINDEX) <= ahbm_none;

end architecture arch;
