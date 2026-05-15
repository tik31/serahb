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
    port (
		--rstin 		: in std_logic;
		clkin 		: in std_logic;
		--tck			: in std_logic;
		--tms			: in std_logic;
		--tdi			: in std_logic;
		--trst		: in std_logic;
		--tdo			: out std_logic;
		RXD0_N		: in std_logic;
		RXD0_P		: in std_logic;
		TXD0_N		: out std_logic;
		TXD0_P		: out std_logic;
		RXD1_N		: in std_logic;
		RXD1_P		: in std_logic;
		TXD1_N		: out std_logic;
		TXD1_P		: out std_logic;
		RXD2_N		: in std_logic;
		RXD2_P		: in std_logic;
		TXD2_N		: out std_logic;
		TXD2_P		: out std_logic;
		RXD3_N		: in std_logic;
		RXD3_P		: in std_logic;
		TXD3_N		: out std_logic;
		TXD3_P		: out std_logic--;
	--	clk50_out	: out std_logic;
	--	rst_out		: out std_logic;
	--	clk_tx_out	: out std_logic;
	--	clk_rx_out	: out std_logic		
	);
end serahb_fpga;

architecture arch of serahb_fpga is

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
		clk50					: out std_logic;
		clk_rx					: out std_logic;
		clk_tx					: out std_logic;
		crc_err_rx_o			: out std_logic;
		lane_aligned_rx_o		: out std_logic;
		req_usr_data_tx_o		: out std_logic;
		reset					: out std_logic;
		usr_data_rx_o			: out std_logic_vector(7 downto 0);
		usr_data_val_rx_o		: out std_logic
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
    	
	constant CFG_NCPU	                : integer := 0;
	
	constant LEON3_MHINDEX              : integer := 0;
    constant AHBJTAG_MHINDEX            : integer := 0;--1 + CFG_NCPU-1;
	constant SERAHB_MHINDEX	            : integer := 1;--2 + CFG_NCPU-1;
	--constant DEBUG_MHINDEX	            : integer := 3 + CFG_NCPU-1;
	
    -- AHB slave indexes
    constant AHBRAM_SHINDEX             : integer := 0;
    --constant APBCTRL_SHINDEX            : integer := 1;
    --constant DSU_SHINDEX                : integer := 2;
    constant SERAHB_SHINDEX             : integer := 1;
    
    constant UNUSED_SHINDEX             : integer := 2;

  --  -- AHB slave addresses 
    constant AHBRAM_SHADDR              : integer := 16#000#;
    constant APBCTRL_SHADDR             : integer := 16#800#;
    --constant DSU_SHADDR                 : integer := 16#900#; 
	constant SERAHB_SHADDR				: integer := 16#100#;
  
  --  -- APB indexes
    constant AHBJTAG_PINDEX             : integer := 0;
    constant IRQMP_PINDEX				: integer := 1;

    constant AHBJTAG_PADDR              : integer := 0; 
    constant IRQMP_PADDR				: integer := 1;

  ---- IRQs
    constant SERAHB_IRQ                 : integer := 1; 
     
    
	signal ahbsi : ahb_slv_in_type;
    signal ahbso : ahb_slv_out_vector := (others => ahbs_none);
    signal ahbmi : ahb_mst_in_type;
    signal ahbmo : ahb_mst_out_vector := (others => ahbm_none);
	signal apbi0 : apb_slv_in_type;
    signal apbo0 : apb_slv_out_vector := (others => apb_none);
	--signal irqi  : irq_in_vector(0 to CFG_NCPU-1);
    --signal irqo  : irq_out_vector(0 to CFG_NCPU-1);
	--signal dbgi  : l3_debug_in_vector(0 to CFG_NCPU-1);
    --signal dbgo  : l3_debug_out_vector(0 to CFG_NCPU-1);
    --signal dsui  : dsu_in_type;
    --signal dsuo  : dsu_out_type;
	
	signal req_usr_data_tx_o	: std_logic;
	signal usr_data_val_rx_o	: std_logic;
	signal usr_data_rx_o		: std_logic_vector(7 downto 0);
	signal usr_data_rdy_tx_i	: std_logic;
	signal usr_data_tx_i		: std_logic_vector(7 downto 0);
	signal usr_data_val_tx_i	: std_logic;
	
	signal clk		: std_logic;
	signal clk_rx	: std_logic;
	signal clk_tx	: std_logic;
	signal rst	: std_logic;
	
begin  -- architecture behav

	lfast : top
        port map (
			CLK0_PAD				=> clkin,
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
			clk50					=> clk,
			clk_rx					=> clk_rx,
			clk_tx					=> clk_tx,
			crc_err_rx_o			=> open,
			lane_aligned_rx_o		=> open,
			req_usr_data_tx_o		=> req_usr_data_tx_o,
			reset					=> rst,
			usr_data_rx_o			=> usr_data_rx_o,
			usr_data_val_rx_o		=> usr_data_val_rx_o	
    );

	ahb0 : ahbctrl                        -- AHB arbiter/multiplexer
        generic map (
            fpnpen      => 1,
			ahbtrace	=> 1,
			nahbm		=> 2,
			nahbs		=> 2
        )
        port map (rst, clk, ahbmi, ahbmo, ahbsi, ahbso);
		
	ahbram0: ahbram
        generic map (
            hindex	=> AHBRAM_SHINDEX,
			haddr	=> AHBRAM_SHADDR,
			tech	=> 0, 
            kbytes	=> 64
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
			clk          	=> clk,
			rst          	=> rst,
			ahbsi        	=> ahbsi,
			ahbso        	=> ahbso(SERAHB_SHINDEX),
			ahbmi		 	=> ahbmi,
			ahbmo		 	=> ahbmo(SERAHB_MHINDEX),
			lf_req_data_tx	=> req_usr_data_tx_o,
			lf_data_val_rx	=> usr_data_val_rx_o,
			lf_data_rx		=> usr_data_rx_o,
			lf_data_rdy_tx	=> usr_data_rdy_tx_i,
			lf_data_tx		=> usr_data_tx_i,
			lf_data_val_tx	=> usr_data_val_tx_i
		);
	
	-- jtag0: ahbjtag
            -- generic map (
                -- tech                    => smartfusion2,
                -- hindex                  => AHBJTAG_MHINDEX,
                -- ainst                   => 16,
                -- dinst                   => 17)
            -- port map (
                -- rst                     => rst,
                -- clk                     => clk,
                -- tck                     => tck,
                -- tms                     => tms,
                -- tdi                     => tdi,
                -- tdo                     => tdo,
                -- ahbi                    => ahbmi,
                -- ahbo                    => ahbmo(AHBJTAG_MHINDEX),
                -- tapo_tck                => open,
                -- tapo_tckn               => open,
                -- tapo_tdi                => open,
                -- tapo_inst               => open,
                -- tapo_ninst              => open,
                -- tapo_rst                => open,
                -- tapo_capt               => open,
                -- tapo_shft               => open,
                -- tapo_iupd               => open,
                -- tapo_upd                => open,
                -- tapi_tdo                => '0',
                -- trst                    => trst,
                -- tdoen                   => open);

	--clk50_out	<= clk;
	--rst_out		<= rst;
	--clk_tx_out	<= clk_tx;
	--clk_rx_out	<= clk_rx;
	ahbmo(AHBJTAG_MHINDEX) <= ahbm_none;
				
 end architecture arch;
