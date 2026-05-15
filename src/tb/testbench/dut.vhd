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
end dut;

architecture arch of dut is

    component top is
    port (
		CLK0_PAD				: in std_logic;
		RXD0_N					: in std_logic;
		RXD0_P					: in std_logic;
		RXD1_N					: in std_logic;
		RXD1_P					: in std_logic;
		RXD2_N					: in std_logic;
		RXD2_P					: in std_logic;
		RXD3_N					: in std_logic;
		RXD3_P					: in std_logic;
		usr_data_rdy_tx_i		: in std_logic;
		usr_data_tx_i			: in std_logic_vector(7 downto 0);
		usr_data_val_tx_i		: in std_logic;
		EPCS_0_TX_CLK_STABLE	: out std_logic;
		TXD0_N					: out std_logic;
		TXD0_P					: out std_logic;
		TXD1_N					: out std_logic;
		TXD1_P					: out std_logic;
		TXD2_N					: out std_logic;
		TXD2_P					: out std_logic;
		TXD3_N					: out std_logic;
		TXD3_P					: out std_logic;
		block_aligned_rx_o		: out std_logic_vector(0 downto 0);
		crc_err_rx_o			: out std_logic;
		lane_aligned_rx_o		: out std_logic;
		req_usr_data_tx_o		: out std_logic;
		usr_data_rx_o			: out std_logic_vector(7 downto 0);
		usr_data_val_rx_o		: out std_logic;
		clk50					: out std_logic;
		clk_tx					: out std_logic;
		clk_rx					: out std_logic;
		reset					: out std_logic
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
			clk          	: IN	std_logic;
			clk_tx         	: IN	std_logic;
			clk_rx         	: IN	std_logic;
			rst          	: IN	std_logic;
			ahbsi        	: IN	ahb_slv_in_type;
			ahbso        	: OUT	ahb_slv_out_type;
			ahbmi		 	: IN	ahb_mst_in_type;
			ahbmo		 	: OUT	ahb_mst_out_type;
			lf_req_data_tx	: IN	std_logic;
			lf_data_val_rx	: IN	std_logic;
			lf_data_rx		: IN	std_logic_vector(7 downto 0);
			lf_data_rdy_tx	: OUT	std_logic;
			lf_data_tx		: OUT	std_logic_vector(7 downto 0);
			lf_data_val_tx	: OUT	std_logic
		);
	end component;
    	
	signal ahbsi : ahb_slv_in_type;
    signal ahbso : ahb_slv_out_vector := (others => ahbs_none);
    signal ahbmi : ahb_mst_in_type;
    signal ahbmo : ahb_mst_out_vector := (others => ahbm_none);
	
	signal req_usr_data_tx_o	: std_logic;
	signal usr_data_val_rx_o	: std_logic;
	signal usr_data_rx_o		: std_logic_vector(7 downto 0);
	signal usr_data_rdy_tx_i	: std_logic;
	signal usr_data_tx_i		: std_logic_vector(7 downto 0);
	signal usr_data_val_tx_i	: std_logic;
	
	signal clkm, clk_tx, clk_rx	: std_logic;
	signal rstn	: std_logic;
	
begin  -- architecture behav

    ahbmo(1) <= debug_ahbmo;
	debug_ahbmi <= ahbmi;
	
	clk_out <= clkm;
	
	lfast : top
        port map (
			CLK0_PAD				=> clk,
			RXD0_N					=> RXD0_N,
			RXD0_P					=> RXD0_P,
			RXD1_N					=> RXD1_N,
			RXD1_P					=> RXD1_P,
			RXD2_N					=> RXD2_N,
			RXD2_P					=> RXD2_P,
			RXD3_N					=> RXD3_N,
			RXD3_P					=> RXD3_P,
			usr_data_rdy_tx_i		=> usr_data_rdy_tx_i,
			usr_data_tx_i			=> usr_data_tx_i,
			usr_data_val_tx_i		=> usr_data_val_tx_i,
			EPCS_0_TX_CLK_STABLE	=> open,
			TXD0_N					=> TXD0_N,
			TXD0_P					=> TXD0_P,
			TXD1_N					=> TXD1_N,
			TXD1_P					=> TXD1_P,
			TXD2_N					=> TXD2_N,
			TXD2_P					=> TXD2_P,
			TXD3_N					=> TXD3_N,
			TXD3_P					=> TXD3_P,
			block_aligned_rx_o		=> open,
			crc_err_rx_o			=> open,
			lane_aligned_rx_o		=> serdes_ready,
			req_usr_data_tx_o		=> req_usr_data_tx_o,
			usr_data_rx_o			=> usr_data_rx_o,
			usr_data_val_rx_o		=> usr_data_val_rx_o,
			clk50					=> clkm,
			clk_tx					=> clk_tx,
			clk_rx					=> clk_rx,
			reset					=> rstn
    );

	ahb0 : ahbctrl                        -- AHB arbiter/multiplexer
        generic map (
            fpnpen      => 1,
			ahbtrace	=> 1,
			nahbm		=> 2,
			nahbs		=> 2
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
			clk          	=> clkm,
			clk_tx			=> clk_tx,
			clk_rx			=> clk_rx,
			rst          	=> rstn,
			ahbsi        	=> ahbsi,
			ahbso        	=> ahbso(1),
			ahbmi		 	=> ahbmi,
			ahbmo		 	=> ahbmo(0),
			lf_req_data_tx	=> req_usr_data_tx_o,
			lf_data_val_rx	=> usr_data_val_rx_o,
			lf_data_rx		=> usr_data_rx_o,
			lf_data_rdy_tx	=> usr_data_rdy_tx_i,
			lf_data_tx		=> usr_data_tx_i,
			lf_data_val_tx	=> usr_data_val_tx_i
		);
	
	
 end architecture arch;

