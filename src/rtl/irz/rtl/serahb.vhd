--
-- Created:
--          by - 47604506 (476045SVI)
--          at - 03.2026
--

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
LIBRARY grlib;
USE grlib.amba.all;
USE grlib.config_types.all;
USE grlib.config.all;
use grlib.stdlib.all;
use grlib.devices.all;
LIBRARY gaisler;
USE gaisler.misc.all;
LIBRARY techmap;
USE techmap.allmem.all;

ENTITY serahb IS
    GENERIC(
        g_master : boolean := true;
        hindex : integer := 0;
        haddr  : integer := 0;
        hmask  : integer := 16#fff#;
		mindex : integer := 0;
		hirq   : integer := 0
    );
    PORT(
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

-- Declarations

END serahb ;

--
ARCHITECTURE rtl OF serahb IS	
	type ahb_state is (IDLE, NONSEQ);
	type x_state is (IDLE, SEND_OP, SEND_ADDR, SEND_LENGTH, SEND_TIMEOUT, SEND_DATA, SEND_REPLY_STATUS, SEND_REPLY_DATA);
	type r_state is (IDLE, RECV_REPLY_DATA, RECV_ADDR, RECV_LENGTH, RECV_TIMEOUT, RECV_WDATA);
	type a_state is (IDLE, WRITE_AHB, READ_AHB);
	
	type reg_ctrl is record
		start			: std_logic;
		op				: std_logic_vector(1 downto 0);
		isend			: std_logic;
		irecv			: std_logic;
		timeout			: std_logic_vector(15 downto 0);
		len				: std_logic_vector(15 downto 0);
		address			: std_logic_vector(31 downto 0);
	end record;
	
	type reg_sts is record
		busy_m			: std_logic;
		busy_s			: std_logic;
		complete		: std_logic;
		status			: std_logic_vector(1 downto 0);
		isend			: std_logic;
		irecv			: std_logic;
		lf_send_timeout	: std_logic;
		lf_recv_timeout	: std_logic;
	end record;
	
	type ahb_params is record
		start			: std_logic;
		op				: std_logic_vector(1 downto 0);
		address			: std_logic_vector(31 downto 0);
		len				: std_logic_vector(15 downto 0);
		timeout			: std_logic_vector(15 downto 0);
		timer			: integer range 0 to 65535;
	end record;
	
	type reg_type is record
		state			: ahb_state;
		--xmit_state		: x_state;
		--recv_state		: r_state;
		ahb_state		: a_state;
		ctrl			: reg_ctrl;
		sts				: reg_sts;
		ahb				: ahb_params;
		htrans			: std_logic_vector(1 downto 0);
		haddr			: std_logic_vector(31 downto 0);
		hwdata			: std_logic_vector(31 downto 0);
		hready			: std_logic;
		hwrite			: std_logic;
		hsel			: std_logic;
		hirq			: std_logic_vector(NAHBIRQ-1 downto 0); 
		start_cmd		: std_logic;
		start_reply		: std_logic_vector(1 downto 0);
		--lf_req_data_tx	: std_logic;
		--lf_req_data_tx1	: std_logic;
		--lf_data_rdy_tx	: std_logic;
		--lf_data_val_tx	: std_logic;
		--lf_data_val_rx	: std_logic;
		--lf_data_rx		: std_logic_vector(7 downto 0);
		--data_tx			: std_logic_vector(7 downto 0);
		data_count		: integer range 0 to 65535;
		rply_status		: std_logic_vector(1 downto 0);
		timer_send		: std_logic;
		--timer_recv		: integer range 0 to 65535;
		reset			: std_logic;
		stsread			: std_logic;
		wa_mem_xmit		: std_logic_vector(9 downto 0);
		wd_mem_xmit		: std_logic_vector(31 downto 0);
		wr_mem_xmit		: std_logic;
		ready_mem_wdata	: std_logic;
		wa_mem_rply		: std_logic_vector(9 downto 0);
		wd_mem_rply		: std_logic_vector(31 downto 0);
		wr_mem_rply		: std_logic;
		--ra_mem_recv		: std_logic_vector(9 downto 0);
	end record;
	
	type regrx_type is record
		recv_state		: r_state;
		lf_data_val_rx	: std_logic;
		lf_data_rx		: std_logic_vector(7 downto 0);
		data_count		: integer range 0 to 65535;
		timer_recv		: integer range 0 to 65535;
		complete		: std_logic;
		status			: std_logic_vector(1 downto 0);
		irecv			: std_logic;
		lf_recv_timeout	: std_logic;
		busy_s			: std_logic;
		busy_m			: std_logic;
		op				: std_logic_vector(1 downto 0);
		address			: std_logic_vector(31 downto 0);
		len				: std_logic_vector(15 downto 0);
		timeout			: std_logic_vector(15 downto 0);
		start			: std_logic;
		start_reply		: std_logic;
		wa_mem_recv		: std_logic_vector(9 downto 0);
		wd_mem_recv		: std_logic_vector(31 downto 0);
		wr_mem_recv		: std_logic;
		wa_mem_wdata	: std_logic_vector(9 downto 0);
		wd_mem_wdata	: std_logic_vector(31 downto 0);
		wr_mem_wdata	: std_logic;
	end record;
	
	type regtx_type is record
		xmit_state		: x_state;
		lf_req_data_tx	: std_logic;
		lf_req_data_tx1	: std_logic;
		lf_data_rdy_tx	: std_logic;
		lf_data_val_tx	: std_logic;
		data_tx			: std_logic_vector(7 downto 0);
		data_count		: integer range 0 to 65535;
		timer_send		: integer range 0 to 65535;
		busy_m			: std_logic;
		busy_s			: std_logic;
		start_reply		: std_logic;
		start			: std_logic;
		lf_send_timeout	: std_logic;
		isend			: std_logic;
		ra_mem_xmit		: std_logic_vector(9 downto 0);
		ready_mem_xmit	: std_logic;
		ra_mem_rply		: std_logic_vector(9 downto 0);
		ready_mem_rply	: std_logic;
	end record;
	
	constant RES_CTRL	: reg_ctrl := (
		start			=> '0', 
		op				=> (others => '0'),
		isend			=> '0',
		irecv			=> '0',
		timeout			=> (others => '1'),
		len				=> x"0001",
		address			=> (others => '0')
	);

	constant RES_STS	: reg_sts := (
		busy_m			=> '0',
		busy_s			=> '0',
		complete		=> '0',
		status			=> (others => '0'),
		isend			=> '0',
		irecv			=> '0',
		lf_send_timeout	=> '0',
		lf_recv_timeout	=> '0'
	);

	constant RES_AHB	: ahb_params := (
		start			=> '0',
		op				=> (others => '0'), 
		address			=> (others => '0'), 
		len				=> (others => '0'), 
		timeout			=> (others => '1'),
		timer			=> 65535
	);
	
	constant timeout_lf : integer := 65535;
	
	constant RES 		: reg_type := (
		state	 		=> IDLE,
		--xmit_state 		=> IDLE,
		--recv_state 		=> IDLE,
		ahb_state		=> IDLE,
		ctrl			=> RES_CTRL,
		sts				=> RES_STS,
		ahb				=> RES_AHB,
		htrans			=> (others => '0'),
		haddr			=> (others => '0'),
		hwdata			=> (others => '0'),
		hready 			=> '1',
		hwrite 			=> '0',
		hsel 			=> '0',
		hirq			=> (others => '0'),
		start_cmd		=> '0',
		start_reply		=> "00",
		--lf_req_data_tx	=> '0',
		--lf_req_data_tx1	=> '0',
		--lf_data_rdy_tx	=> '0',
		--lf_data_val_tx	=> '0',
		--lf_data_val_rx	=> '0',
		--lf_data_rx		=> (others => '0'),
		--data_tx			=> (others => '0'),
		data_count		=> 0,
		rply_status		=> "00",
		timer_send		=> '0',
		--timer_recv		=> timeout_lf,
		reset			=> '0',
		stsread			=> '0',
		wa_mem_xmit		=> (others => '0'),
		wd_mem_xmit		=> (others => '0'),
		wr_mem_xmit		=> '0',
		ready_mem_wdata	=> '0',
		wa_mem_rply		=> (others => '0'),
		wd_mem_rply		=> (others => '0'),
		wr_mem_rply		=> '0'
		--ra_mem_recv		=> (others => '0')
	);
	
	constant RESRX 		: regrx_type := (
		recv_state 		=> IDLE,
		lf_data_val_rx	=> '0',
		lf_data_rx		=> (others => '0'),
		data_count		=> 0,
		timer_recv		=> timeout_lf,
		complete		=> '0',
		status			=> "00",
		irecv			=> '0',
		lf_recv_timeout	=> '0',
		busy_s			=> '0',
		busy_m			=> '1',
		op				=> (others => '0'),
		address			=> (others => '0'),
		len				=> (others => '0'),
		timeout			=> (others => '0'),
		start			=> '0',
		start_reply		=> '0',
		wa_mem_recv		=> (others => '0'),
		wd_mem_recv		=> (others => '0'),
		wr_mem_recv		=> '0',
		wa_mem_wdata	=> (others => '0'),
		wd_mem_wdata	=> (others => '0'),
		wr_mem_wdata	=> '0'
	);

	constant RESTX 		: regtx_type := (
		xmit_state 		=> IDLE,
		lf_req_data_tx	=> '0',
		lf_req_data_tx1	=> '0',
		lf_data_rdy_tx	=> '0',
		lf_data_val_tx	=> '0',
		data_tx			=> (others => '0'),
		data_count		=> 0,
		timer_send		=> timeout_lf,
		busy_m			=> '0',
		busy_s			=> '1',
		start_reply		=> '1',
		start			=> '1',
		lf_send_timeout	=> '0',
		isend			=> '0',
		ra_mem_xmit		=> (others => '0'),
		ready_mem_xmit	=> '0',
		ra_mem_rply		=> (others => '0'),
		ready_mem_rply	=> '0'
	);

	constant hconfig : ahb_config_type := (
		0 => ahb_device_reg ( VENDOR_GAISLER, GAISLER_AHBRAM, 0, 12, 0),
		4 => ahb_membar(haddr, '1', '1', hmask),
		others => zero32);
		
	signal	r, rin			: reg_type;
	signal	rrx, rrxin		: regrx_type;
	signal	rtx, rtxin		: regtx_type;
	
	type mem8 is array(0 to 4095) 
		of std_logic_vector(7 downto 0);
	type mem32 is array(0 to 1023) 
		of std_logic_vector(31 downto 0);	
	--signal mem_xmit, rmem_xmit : mem32;
	--signal mem_recv, rmem_recv : mem32;
	--signal mem_wdata, rmem_wdata : mem32;
	--signal mem_rply, rmem_rply : mem32;
	
	signal rd_mem_xmit	: std_logic_vector(31 downto 0);
	signal rd_mem_recv	: std_logic_vector(31 downto 0);
	signal ra_mem_recv	: std_logic_vector(9 downto 0);
	signal rd_mem_wdata	: std_logic_vector(31 downto 0);
	signal ra_mem_wdata	: std_logic_vector(9 downto 0);
	signal rd_mem_rply	: std_logic_vector(31 downto 0);
	signal ra_mem_rply	: std_logic_vector(9 downto 0);
	
	attribute syn_ramstyle : string;
	--attribute syn_ramstyle of mem_xmit : signal is "block_ram";
	--attribute syn_ramstyle of mem_recv : signal is "block_ram";
	--attribute syn_ramstyle of mem_wdata : signal is "block_ram";
	--attribute syn_ramstyle of mem_rply : signal is "block_ram";
	
	signal dmai : ahb_dma_in_type;
	signal dmao : ahb_dma_out_type;
	
	signal reset : std_logic;
	
BEGIN
	
		
comb: process (r, ahbsi, ahbmi, dmao, rrx.complete, rtx.busy_m, rrx.irecv, rrx.lf_recv_timeout, rrx.busy_s, rtx.busy_s, rrx.op, rrx.address, rrx.len, rrx.start, rtx.start_reply, rrx.start_reply, rtx.start, rtx.lf_send_timeout, rtx.isend) 
		variable 	v		: reg_type;
		--variable	vmem_xmit, vmem_rply : mem;
	begin
		v := r;
		v.timer_send := '0';
		v.hirq := (others => '0'); v.hirq(hirq) := r.sts.isend or r.sts.irecv;
		v.reset := '0';
		v.stsread := '0';
		v.sts.complete := rrx.complete;
		v.sts.status := rrx.status;
		--if (rrx.busy_m = '0') then
		--	v.sts.busy_m := '0';
		--else
			v.sts.busy_m := rtx.busy_m;
		--end if;
		v.sts.irecv := rrx.irecv;
		v.sts.lf_recv_timeout := rrx.lf_recv_timeout;
		if (rrx.busy_s = '1') then
			v.sts.busy_s := '1';
		elsif (rtx.busy_s = '0') then
			v.sts.busy_s := '0';
		end if;
		v.ahb.op := rrx.op;
		v.ahb.address := rrx.address;
		v.ahb.len := rrx.len;
		v.ahb.timeout := rrx.timeout;
		if (rrx.start = '1') then v.ahb.start := '1'; end if;
		if (rtx.start_reply = '0') then
			v.start_reply := "00";
		elsif (rrx.start_reply = '1') then
			v.start_reply := "11";
			v.rply_status := "11";
		end if;
		if (rtx.start = '0') then v.ctrl.start := '0'; end if;
		v.sts.lf_send_timeout := rtx.lf_send_timeout;
		v.sts.isend := rtx.isend;
		v.wr_mem_xmit := '0';
		v.wr_mem_rply := '0';
		--vmem_rply := mem_rply;
		 
		
--AHB SLAVE (Master mode only)
		if g_master then
		case (r.state) is
			when IDLE =>
			    v.hsel := ahbsi.hsel(hindex);
				v.hwrite := ahbsi.hwrite;
				v.htrans := ahbsi.htrans;
				v.hready := '1';
				if (ahbsi.hsel(hindex) = '1' and (ahbsi.htrans = "10" or ahbsi.htrans = "11")) then
					v.haddr := ahbsi.haddr;
					v.wa_mem_xmit := ahbsi.haddr(11 downto 2);
					ra_mem_recv <= ahbsi.haddr(11 downto 2);
					v.hready := '0';
					v.state := NONSEQ;
				end if;
			
			when NONSEQ => 
				v.hready := '0';
				if ((r.hwrite = '1') and (r.haddr(12) = '0') and (r.haddr(3 downto 2) = "00")) then
					v.reset	:= ahbsi.hwdata(31);
				end if;
				if ((r.hwrite = '1') and (r.sts.busy_m = '0') and (r.sts.busy_s = '0')) then
					if (r.haddr(12) = '1') then 
						v.wd_mem_xmit := ahbsi.hwdata;
						v.wr_mem_xmit := '1';
						--mem_xmit(conv_integer(r.haddr(11 downto 2))) <= ahbsi.hwdata;
						--mem_xmit(conv_integer(r.haddr(11 downto 0))) := ahbsi.hwdata(7 downto 0);
						--mem_xmit(conv_integer(r.haddr(11 downto 0)) + 1) := ahbsi.hwdata(15 downto 8);
						--mem_xmit(conv_integer(r.haddr(11 downto 0)) + 2) := ahbsi.hwdata(23 downto 16);
						--mem_xmit(conv_integer(r.haddr(11 downto 0)) + 3) := ahbsi.hwdata(31 downto 24);
					else
						case (r.haddr(3 downto 2)) is
							when "00" =>
								v.ctrl.start	:= ahbsi.hwdata(0);
								v.ctrl.op		:= ahbsi.hwdata(2 downto 1);
								v.ctrl.isend	:= ahbsi.hwdata(3);
								v.ctrl.irecv	:= ahbsi.hwdata(4);
							when "10" =>
								v.ctrl.address	:= ahbsi.hwdata;
							when "11" =>
								v.ctrl.timeout	:= ahbsi.hwdata(15 downto 0);
								v.ctrl.len		:= ahbsi.hwdata(31 downto 16);
							when others =>
								null;
						end case;
					end if;
				else
					if (r.haddr(12) = '1') then 
						ahbso.hrdata <= rd_mem_recv;
						--ahbso.hrdata <= mem_recv(conv_integer(r.haddr(11 downto 2)));
						--ahbso.hrdata(7 downto 0) <= mem_recv(conv_integer(r.haddr(11 downto 0)));
						--ahbso.hrdata(15 downto 8) <= mem_recv(conv_integer(r.haddr(11 downto 0)) + 1);
						--ahbso.hrdata(23 downto 16) <= mem_recv(conv_integer(r.haddr(11 downto 0)) + 2);
						--ahbso.hrdata(31 downto 24) <= mem_recv(conv_integer(r.haddr(11 downto 0)) + 3);
					else
						case (r.haddr(3 downto 2)) is
							when "00" =>
								ahbso.hrdata <= "000000000000000000000000000" & r.ctrl.irecv & r.ctrl.isend & r.ctrl.op & r.ctrl.start;
							when "01" =>
								ahbso.hrdata <= r.sts.status & "00000000000000000000000" & r.sts.lf_recv_timeout & r.sts.lf_send_timeout & r.sts.irecv & r.sts.isend & r.sts.complete & r.sts.busy_s & r.sts.busy_m;
								--v.sts.complete := '0';
								--v.sts.isend := '0';
								--v.sts.irecv := '0';
								--v.sts.lf_send_timeout := '0';
								--v.sts.lf_recv_timeout := '0';
								v.stsread := '1';
							when "10" =>
								ahbso.hrdata <= r.ctrl.address;
							when "11" =>
								ahbso.hrdata <= r.ctrl.len & r.ctrl.timeout;	
							when others =>
								null;
						end case;
					end if;
				end if;
				v.hready := '1';
				v.state := IDLE;
				
			when others =>
				v.state := IDLE;
		end case;
		else
			-- Slave mode: AHB slave interface inactive
			v.hsel := '0';
			v.hready := '1';
			v.state := IDLE;
		end if;

--AHBDMA (Slave mode only)
		if not g_master then
		case(r.ahb_state) is
			
			when IDLE =>
				if (r.ahb.start = '1') then
					v.data_count := 0;
					v.ready_mem_wdata := '0';
					ra_mem_wdata <= (others => '0');
					v.ahb.timer := conv_integer(r.ahb.timeout);
					if (r.ahb.op = "10") then
						v.ahb_state := WRITE_AHB;
					else
						v.ahb_state := READ_AHB;
					end if;
				end if;
			
			when WRITE_AHB =>
				if (r.data_count < conv_integer(r.ahb.len)) then
					ra_mem_wdata <= std_logic_vector(to_unsigned(r.data_count,10));
					dmai.address <= std_logic_vector((ieee.numeric_std.unsigned(r.ahb.address) + r.data_count * 4));
					dmai.wdata <= rd_mem_wdata;
					--dmai.wdata(7 downto 0) <= mem_wdata(r.data_count * 4);
					--dmai.wdata(15 downto 8) <= mem_wdata(r.data_count * 4 + 1);
					--dmai.wdata(23 downto 16) <= mem_wdata(r.data_count * 4 + 2);
					--dmai.wdata(31 downto 24) <= mem_wdata(r.data_count * 4 + 3);
					dmai.write <= '1';
					if (dmao.active = '1') then
						dmai.start <= '0';
						if (dmao.ready = '1') then
							v.ready_mem_wdata := '0';
							v.ahb.timer := conv_integer(r.ahb.timeout);
							if (dmao.mexc = '1') then
								v.ahb.start := '0';
								v.rply_status := "01";
								v.start_reply := "11";
								v.timer_send := '1';--vtx.timer_send := timeout_lf;
								v.data_count := 0;
								v.ahb_state := IDLE;
							else
								v.data_count := r.data_count + 1;
							end if;
						elsif (dmao.retry = '1') then
							v.ahb.start := '0';
							v.rply_status := "01";
							v.start_reply := "11";
							v.timer_send := '1';--vtx.timer_send := timeout_lf;
							v.data_count := 0;
							v.ahb_state := IDLE;
						else
							if (r.ahb.timer = 0) then
								v.ahb.start := '0';
								v.rply_status := "10";
								v.start_reply := "11";
								v.timer_send := '1';--vtx.timer_send := timeout_lf;
								v.data_count := 0;
								v.ahb_state := IDLE;
							else
								v.ahb.timer := r.ahb.timer - 1;
							end if;
						end if;
					else
						v.ready_mem_wdata := '1';
						if (r.ready_mem_wdata = '1') then
							dmai.start <= '1';
						end if;
						if (r.ahb.timer = 0) then
							v.ahb.start := '0';
							v.rply_status := "10";
							v.start_reply := "11";
							v.timer_send := '1';--vtx.timer_send := timeout_lf;
							v.data_count := 0;
							v.ahb_state := IDLE;
						else
							v.ahb.timer := r.ahb.timer - 1;
						end if;
					end if;
				else
					v.ahb.start := '0';
					v.rply_status := "00";
					v.start_reply := "11";
					v.timer_send := '1';--vtx.timer_send := timeout_lf;
					v.data_count := 0;
					v.ahb_state := IDLE;
				end if;
				
			when READ_AHB =>
				if (r.data_count < conv_integer(r.ahb.len)) then
					dmai.address <= std_logic_vector((ieee.numeric_std.unsigned(r.ahb.address) + r.data_count * 4));
					dmai.write <= '0';
					if (dmao.active = '1') then
						v.wa_mem_rply := std_logic_vector(to_unsigned(r.data_count,10));
						dmai.start <= '0';
						if (dmao.ready = '1') then
							v.ahb.timer := conv_integer(r.ahb.timeout);
							if (dmao.mexc = '1') then
								v.ahb.start := '0';
								v.rply_status := "01";
								v.start_reply := "11";
								v.timer_send := '1';--vtx.timer_send := timeout_lf;
								v.data_count := 0;
								v.ahb_state := IDLE;
							else
								v.data_count := r.data_count + 1;
								v.wd_mem_rply := dmao.rdata;
								v.wr_mem_rply := '1';
								--vmem_rply(r.data_count * 4) := dmao.rdata(7 downto 0);
								--vmem_rply(r.data_count * 4 + 1) := dmao.rdata(15 downto 8);
								--vmem_rply(r.data_count * 4 + 2) := dmao.rdata(23 downto 16);
								--vmem_rply(r.data_count * 4 + 3) := dmao.rdata(31 downto 24);
							end if;
						elsif (dmao.retry = '1') then
							v.ahb.start := '0';
							v.rply_status := "01";
							v.start_reply := "11";
							v.timer_send := '1';--vtx.timer_send := timeout_lf;
							v.data_count := 0;
							v.ahb_state := IDLE;
						else
							if (r.ahb.timer = 0) then
								v.ahb.start := '0';
								v.rply_status := "10";
								v.start_reply := "11";
								v.timer_send := '1';--vtx.timer_send := timeout_lf;
								v.data_count := 0;
								v.ahb_state := IDLE;
							else
								v.ahb.timer := r.ahb.timer - 1;
							end if;
						end if;
					else
						dmai.start <= '1';
						if (r.ahb.timer = 0) then
							v.ahb.start := '0';
							v.rply_status := "10";
							v.start_reply := "11";
							v.timer_send := '1';--vtx.timer_send := timeout_lf;
							v.data_count := 0;
							v.ahb_state := IDLE;
						else
							v.ahb.timer := r.ahb.timer - 1;
						end if;
					end if;
				else
					v.ahb.start := '0';
					v.rply_status := "00";
					v.start_reply := "10";
					v.timer_send := '1';--vtx.timer_send := timeout_lf;
					v.data_count := 0;
					v.ahb_state := IDLE;
				end if;
			
		end case;
		else
			-- Master mode: AHB DMA inactive
			v.ahb_state := IDLE;
		end if;

		rin <= v;
		--rmem_xmit <= vmem_xmit;
		--rmem_rply <= vmem_rply;
				
	end process;
	
combrx: process (rrx, lf_data_val_rx, lf_data_rx, r.stsread, r.sts.busy_m, r.sts.busy_s, r.ahb.start, r.start_reply) 
		variable 	vrx		: regrx_type;
		--variable	vmem_recv, vmem_wdata : mem;
	begin
		vrx := rrx;
		vrx.lf_data_val_rx := lf_data_val_rx;
		vrx.lf_data_rx := lf_data_rx;
		if (r.stsread = '1') then 
			vrx.complete := '0';
			vrx.irecv := '0';
			vrx.lf_recv_timeout := '0';
		end if;
		if (r.sts.busy_m = '0') then vrx.busy_m := '1'; end if;
		if (r.sts.busy_s = '1') then vrx.busy_s := '0'; end if;
		if (r.ahb.start = '1') then vrx.start := '0'; end if;
		if (r.start_reply = "11") then vrx.start_reply := '0'; end if;
		--vmem_recv := mem_recv;
		--vmem_wdata := mem_wdata;
		vrx.wr_mem_recv := '0';
		vrx.wr_mem_wdata := '0';

-- LITEFAST RECEIVER

		case(rrx.recv_state) is
			
			when IDLE =>
				vrx.timer_recv := timeout_lf;
				if (rrx.lf_data_val_rx = '1') then
					if (rrx.lf_data_rx(7) = '1') then
						if g_master then
							vrx.status := rrx.lf_data_rx(1 downto 0);--v.sts.status := rrx.lf_data_rx(1 downto 0);
							if (r.ctrl.op = "01") then
								vrx.recv_state := RECV_REPLY_DATA;
								vrx.data_count := 0;
							else
								vrx.complete := '1';--v.sts.complete := '1';
								vrx.busy_m := '0';--v.sts.busy_m := '0';
								vrx.irecv := r.ctrl.irecv or r.sts.irecv;--v.sts.irecv := r.ctrl.irecv or r.sts.irecv;
							end if;
						end if;
					else
						if not g_master then
							vrx.busy_s := '1';--v.sts.busy_s := '1';
							vrx.op := rrx.lf_data_rx(1 downto 0);
							vrx.data_count := 0;
							vrx.recv_state := RECV_ADDR;
						end if;
					end if;
				end if;
				
			when RECV_REPLY_DATA =>
				vrx.wa_mem_recv := std_logic_vector(to_unsigned((rrx.data_count / 4),10));
				if (rrx.lf_data_val_rx = '1') then
					vrx.timer_recv := timeout_lf;
					case (rrx.data_count mod 4) is
						when 0 =>
							vrx.wd_mem_recv(7 downto 0) := rrx.lf_data_rx;
						when 1 =>
							vrx.wd_mem_recv(15 downto 8) := rrx.lf_data_rx;
						when 2 =>
							vrx.wd_mem_recv(23 downto 16) := rrx.lf_data_rx;
						when 3 =>
							vrx.wd_mem_recv(31 downto 24) := rrx.lf_data_rx;
							vrx.wr_mem_recv := '1';
						when others => null;
					end case;
					--mem_recv(rrx.data_count / 4)(8*(rrx.data_count mod 4) + 7 downto 8*(rrx.data_count mod 4)) <= rrx.lf_data_rx;
					if (rrx.data_count < (conv_integer(r.ctrl.len) * 4) - 1) then
						vrx.data_count := rrx.data_count + 1;
					else
						vrx.data_count := 0;
						vrx.recv_state := IDLE;
						vrx.busy_m := '0';--v.sts.busy_m := '0';
						vrx.complete := '1';--v.sts.complete := '1';
						vrx.irecv := r.ctrl.irecv or r.sts.irecv;--v.sts.irecv := r.ctrl.irecv or r.sts.irecv;
					end if;
				elsif (rrx.timer_recv = 0) then
					vrx.data_count := 0;
					vrx.recv_state := IDLE;
					vrx.busy_m := '0';--v.sts.busy_m := '0';
					vrx.lf_recv_timeout := '1';--v.sts.lf_recv_timeout := '1';
				else
					vrx.timer_recv := rrx.timer_recv - 1;
				end if;
				
			when RECV_ADDR =>
				if (rrx.lf_data_val_rx = '1') then
					vrx.timer_recv := timeout_lf;
					vrx.address(rrx.data_count * 8 + 7 downto rrx.data_count * 8) := rrx.lf_data_rx;--v.ahb.address(r.data_count * 8 + 7 downto r.data_count * 8) := rrx.lf_data_rx;
					if (rrx.data_count < 3) then
						vrx.data_count := rrx.data_count + 1;
					else
						vrx.data_count := 0;
						vrx.recv_state := RECV_LENGTH;
					end if;
				elsif (rrx.timer_recv = 0) then
					vrx.data_count := 0;
					vrx.recv_state := IDLE;
					--vrx.rply_status := "11";--v.rply_status := "11";
					vrx.start_reply := '1';--v.start_reply := "11";
					--vrx_tx.timer_send := timeout_lf;--vtx.timer_send := timeout_lf;
					vrx.lf_recv_timeout := '1';--v.sts.lf_recv_timeout := '1';
				else
					vrx.timer_recv := rrx.timer_recv - 1;
				end if;
				
			when RECV_LENGTH =>
				if (rrx.lf_data_val_rx = '1') then
					vrx.timer_recv := timeout_lf;
					vrx.len(rrx.data_count * 8 + 7 downto rrx.data_count * 8) := rrx.lf_data_rx;--v.ahb.len(r.data_count * 8 + 7 downto r.data_count * 8) := rrx.lf_data_rx;
					if (rrx.data_count < 1) then
						vrx.data_count := rrx.data_count + 1;
					else
						vrx.data_count := 0;
						vrx.recv_state := RECV_TIMEOUT;
					end if;
				elsif (rrx.timer_recv = 0) then
					vrx.data_count := 0;
					vrx.recv_state := IDLE;
					--vrx_r.rply_status := "11";--v.rply_status := "11";
					vrx.start_reply := '1';--v.start_reply := "11";
					--vrx_tx.timer_send := timeout_lf;--vtx.timer_send := timeout_lf;
					vrx.lf_recv_timeout := '1';--v.sts.lf_recv_timeout := '1';
				else
					vrx.timer_recv := rrx.timer_recv - 1;	
				end if;
			
			when RECV_TIMEOUT =>
				if (rrx.lf_data_val_rx = '1') then
					vrx.timer_recv := timeout_lf;
					vrx.timeout(rrx.data_count * 8 + 7 downto rrx.data_count * 8) := rrx.lf_data_rx;--v.ahb.timeout(r.data_count * 8 + 7 downto r.data_count * 8) := rrx.lf_data_rx;
					if (rrx.data_count < 1) then
						vrx.data_count := rrx.data_count + 1;
					else
						vrx.data_count := 0;
						if ((rrx.op = "10") and (rrx.len /= x"0000")) then
							vrx.recv_state := RECV_WDATA;
						elsif ((rrx.op = "01") and (rrx.len /= x"0000") and (conv_integer(rrx.len) < 1024) and (rrx.address(1 downto 0) = "00")) then
							vrx.recv_state := IDLE;
							vrx.start := '1';--v.ahb.start := '1';-- запуск AHB на чтение
						else 
							vrx.recv_state := IDLE;
							--vrx_r.rply_status := "11";--v.rply_status := "11";
							vrx.start_reply := '1';--v.start_reply := "11";
							--vrx_tx.timer_send := timeout_lf;--vtx.timer_send := timeout_lf;
						end if;
					end if;
				elsif (rrx.timer_recv = 0) then
					vrx.data_count := 0;
					vrx.recv_state := IDLE;
					--vrx_r.rply_status := "11";--v.rply_status := "11";
					vrx.start_reply := '1';--v.start_reply := "11";
					vrx.lf_recv_timeout := '1';--v.sts.lf_recv_timeout := '1';
				else
					vrx.timer_recv := rrx.timer_recv - 1;
				end if;
			
			when RECV_WDATA =>
				vrx.wa_mem_wdata := std_logic_vector(to_unsigned(((rrx.data_count / 4) mod 1024),10));
				if (rrx.lf_data_val_rx = '1') then
					vrx.timer_recv := timeout_lf;
					--mem_wdata(rrx.data_count mod 1024) := rrx.lf_data_rx;
					case (rrx.data_count mod 4) is
						when 0 =>
							vrx.wd_mem_wdata(7 downto 0) := rrx.lf_data_rx;
						when 1 =>
							vrx.wd_mem_wdata(15 downto 8) := rrx.lf_data_rx;
						when 2 =>
							vrx.wd_mem_wdata(23 downto 16) := rrx.lf_data_rx;
						when 3 =>
							vrx.wd_mem_wdata(31 downto 24) := rrx.lf_data_rx;
							vrx.wr_mem_wdata := '1';
						when others => null;
					end case;
					--mem_wdata((rrx.data_count / 4) mod 1024)(8*(rrx.data_count mod 4) + 7 downto 8*(rrx.data_count mod 4)) <= rrx.lf_data_rx;
					if (rrx.data_count < ((conv_integer(rrx.len) * 4) - 1)) then
						vrx.data_count := rrx.data_count + 1;
					else
						vrx.recv_state := IDLE;
						if ((rrx.address(1 downto 0) = "00") and (conv_integer(rrx.len) < 1024)) then
							vrx.start := '1';--v.ahb.start := '1';-- запуск AHB на запись
						else
							--vrx_r.rply_status := "11";--v.rply_status := "11";
							vrx.start_reply := '1';--v.start_reply := "11";
							--vrx_tx.timer_send := timeout_lf;--vtx.timer_send := timeout_lf;
						end if;
					end if;
				elsif (rrx.timer_recv = 0) then
					vrx.data_count := 0;
					vrx.recv_state := IDLE;
					--vrx_r.rply_status := "11";--v.rply_status := "11";
					vrx.start_reply := '1';--v.start_reply := "11";
					--vrx_tx.timer_send := timeout_lf;--vtx.timer_send := timeout_lf;
					vrx.lf_recv_timeout := '1';--v.sts.lf_recv_timeout := '1';
				else
					vrx.timer_recv := rrx.timer_recv - 1;
				end if;
			
			when others =>
				vrx.recv_state := IDLE;
				
		end case;
		
		rrxin <= vrx;
		--rmem_recv <= vmem_recv;
		--rmem_wdata <= vmem_wdata;
				
	end process;

combtx: process (rtx, lf_req_data_tx, rrx.start_reply, rrx.busy_m, r.ctrl.start, r.stsread, r.sts.busy_s, r.start_reply) 
		variable 	vtx		: regtx_type;
		variable 	vtx_r	: regtx_type;
	begin
		vtx := rtx;
		vtx.lf_req_data_tx1 := lf_req_data_tx;
		vtx.lf_req_data_tx := rtx.lf_req_data_tx1;
		if (rrx.start_reply = '1') then vtx.timer_send := timeout_lf; end if;
		if (rrx.busy_m = '0') then vtx.busy_m := '0'; end if;
		if (r.ctrl.start = '0') then vtx.start := '1'; end if;
		if (r.stsread = '1') then 
			vtx.isend := '0';
			vtx.lf_send_timeout := '0';
		end if;
		if (r.sts.busy_s = '0') then vtx.busy_s := '1'; end if;
		if (r.start_reply = "00") then vtx.start_reply := '1'; end if;
		
-- LITEFAST TRANSMITTER		
		case(rtx.xmit_state) is
			
			when IDLE =>
				vtx.lf_data_val_tx := '0';
				if (r.ctrl.start = '1') then
					if (r.sts.busy_m = '0') then
						vtx.timer_send := timeout_lf;
					end if;
					vtx.busy_m := '1';--v.sts.busy_m := '1';
					vtx.lf_data_rdy_tx := '1';
					if (lf_req_data_tx = '1') then
						vtx.xmit_state := SEND_OP;
						vtx.data_count := 0;
						-- Drive OP byte already on the transition so spi_phy can
						-- latch it on the SAME cycle as the SEND_OP register update.
						vtx.lf_data_val_tx := '1';
						vtx.data_tx := "000000" & r.ctrl.op;
					elsif (rtx.timer_send = 0) then
						vtx.busy_m := '0';--v.sts.busy_m := '0';
						vtx.start := '0';--v.ctrl.start := '0';
						vtx.lf_send_timeout := '1';--v.sts.lf_send_timeout := '1';
					else
						vtx.timer_send := rtx.timer_send - 1;
					end if;
				elsif (not g_master and (r.start_reply(1) = '1') and (rtx.start_reply = '1')) then
					if (r.timer_send = '1') then
						vtx.timer_send := timeout_lf;
					end if;
					vtx.lf_data_rdy_tx := '1';
					if (lf_req_data_tx = '1') then
						if (r.start_reply(0) = '1') then
							vtx.lf_data_rdy_tx := '0';
						end if;
						vtx.xmit_state := SEND_REPLY_STATUS;
						vtx.data_count := 0;
						-- Drive reply status byte on the transition.
						vtx.lf_data_val_tx := '1';
						vtx.data_tx := "100000" & r.rply_status;
					elsif (rtx.timer_send = 0) then
						vtx.busy_s := '0';--v.sts.busy_s := '0';
						vtx.start_reply := '0';--v.start_reply := "00";
						vtx.lf_send_timeout := '1';--v.sts.lf_send_timeout := '1';
					else
						vtx.timer_send := rtx.timer_send - 1;
					end if;
				end if;
				
			when SEND_OP =>
					vtx.lf_data_val_tx := '1';
					vtx.data_tx := "000000" & r.ctrl.op;
					vtx.xmit_state := SEND_ADDR;
					vtx.start := '0';--v.ctrl.start := '0';
			
			when SEND_ADDR =>
				if (lf_req_data_tx = '1') then
					vtx.timer_send := timeout_lf;
					vtx.lf_data_val_tx := '1';
					vtx.data_tx := r.ctrl.address(rtx.data_count * 8 + 7 downto rtx.data_count * 8);
					vtx.data_count := rtx.data_count + 1;
					if (rtx.data_count >= 3) then
						vtx.data_count := 0;
						vtx.xmit_state := SEND_LENGTH;
					end if;
				elsif (rtx.timer_send = 0) then
					vtx.data_count := 0;
					vtx.xmit_state := IDLE;
					vtx.busy_m := '0';--v.sts.busy_m := '0';
					vtx.lf_send_timeout := '1';--v.sts.lf_send_timeout := '1';
				else
					vtx.timer_send := rtx.timer_send - 1;
					vtx.lf_data_val_tx := '0';
				end if;
			
			when SEND_LENGTH =>
				if (lf_req_data_tx = '1') then
					vtx.timer_send := timeout_lf;
					vtx.lf_data_val_tx := '1';
					vtx.data_tx := r.ctrl.len(rtx.data_count * 8 + 7 downto rtx.data_count * 8);
					vtx.data_count := rtx.data_count + 1;
					if (rtx.data_count >= 1) then
						vtx.data_count := 0;
						vtx.xmit_state := SEND_TIMEOUT;
					end if;
				elsif (rtx.timer_send = 0) then
					vtx.data_count := 0;
					vtx.xmit_state := IDLE;
					vtx.busy_m := '0';--v.sts.busy_m := '0';
					vtx.lf_send_timeout := '1';--v.sts.lf_send_timeout := '1';
				else
					vtx.timer_send := rtx.timer_send - 1;
					vtx.lf_data_val_tx := '0';
				end if;
			
			when SEND_TIMEOUT =>
				if ((r.ctrl.op = "01") or (r.ctrl.op = "00") or (r.ctrl.op = "11") or (r.ctrl.op = "10" and r.ctrl.len = x"0000")) then --or (r.ctrl.op = "10" and r.data_count = 1 and r.ctrl.len = x"0001")) or (r.ctrl.op = "10" and r.ctrl.len = x"0000")) then 
					vtx.lf_data_rdy_tx := '0';
				end if;
				if (lf_req_data_tx = '1') then
					vtx.timer_send := timeout_lf;
					vtx.lf_data_val_tx := '1';
					vtx.data_tx := r.ctrl.timeout(rtx.data_count * 8 + 7 downto rtx.data_count * 8);
					vtx.data_count := rtx.data_count + 1;
					if (rtx.data_count >= 1) then
						vtx.data_count := 0;
						if ((r.ctrl.op = "10") and (r.ctrl.len /= x"0000")) then
							vtx.xmit_state := SEND_DATA;
							vtx.ready_mem_xmit := '0';
							vtx.ra_mem_xmit := (others => '0');
						else
							vtx.xmit_state := IDLE;
							vtx.isend := r.ctrl.isend or r.sts.isend;--v.sts.isend := r.ctrl.isend or r.sts.isend;
						end if;
					end if;
				elsif (rtx.timer_send = 0) then
					vtx.data_count := 0;
					vtx.xmit_state := IDLE;
					vtx.busy_m := '0';--v.sts.busy_m := '0';
					vtx.lf_send_timeout := '1';--v.sts.lf_send_timeout := '1';
				else
					vtx.timer_send := rtx.timer_send - 1;
					vtx.lf_data_val_tx := '0';
				end if;
			
			when SEND_DATA =>
				vtx.ra_mem_xmit := std_logic_vector(to_unsigned((((rtx.data_count + 1) / 4) mod 1024),10));
				vtx.lf_data_val_tx := '0';
				if (lf_req_data_tx = '1') then
					vtx.timer_send := timeout_lf;
					if (rtx.data_count < (conv_integer(r.ctrl.len) * 4)) then
						-- One strobe = one byte (no toggle); SPI's per-frame gap gives the
						-- inferred RAM the required cycle to latch a new read address.
						vtx.lf_data_val_tx := '1';
						vtx.data_tx := rd_mem_xmit(8*(rtx.data_count mod 4) + 7 downto 8*(rtx.data_count mod 4));
						vtx.data_count := rtx.data_count + 1;
						if (rtx.data_count = (conv_integer(r.ctrl.len) * 4 - 1)) then vtx.lf_data_rdy_tx := '0'; end if;
					else
						vtx.lf_data_val_tx := '0';
						vtx.xmit_state := IDLE;
						vtx.isend := r.ctrl.isend or r.sts.isend;--v.sts.isend := r.ctrl.isend or r.sts.isend;
					end if;
				elsif (rtx.timer_send = 0) then
					vtx.data_count := 0;
					vtx.xmit_state := IDLE;
					vtx.busy_m := '0';--v.sts.busy_m := '0';
					vtx.lf_send_timeout := '1';--v.sts.lf_send_timeout := '1';
				else
					vtx.timer_send := rtx.timer_send - 1;
					vtx.lf_data_val_tx := '0';
				end if;
			
			when SEND_REPLY_STATUS =>
				vtx.lf_data_val_tx := '1';
				vtx.data_tx := "100000" & r.rply_status;
				if (r.start_reply(0) = '1') then
					vtx.start_reply := '0';--v.start_reply := "00";
					vtx.xmit_state := IDLE;
					vtx.busy_s := '0';--v.sts.busy_s := '0';
				else
					if (conv_integer(r.ahb.len) = 1) then 
						vtx.lf_data_rdy_tx := '0';
					end if;
					vtx.xmit_state := SEND_REPLY_DATA;
					vtx.ready_mem_rply := '0';
				end if;
				
			when SEND_REPLY_DATA =>
				vtx.ra_mem_rply := std_logic_vector(to_unsigned(((rtx.data_count + 1) / 4),10));
				vtx.lf_data_val_tx := '0';
				if (lf_req_data_tx = '1') then
					vtx.timer_send := timeout_lf;
					if (rtx.data_count < (conv_integer(r.ahb.len) * 4)) then
						-- One strobe = one byte (no toggle).
						vtx.lf_data_val_tx := '1';
						vtx.data_tx := rd_mem_rply(8*(rtx.data_count mod 4) + 7 downto 8*(rtx.data_count mod 4));
						vtx.data_count := rtx.data_count + 1;
						if (rtx.data_count = (conv_integer(r.ahb.len) * 4 - 1)) then vtx.lf_data_rdy_tx := '0'; end if;
					else
						vtx.start_reply := '0';--v.start_reply := "00";
						vtx.lf_data_val_tx := '0';
						vtx.xmit_state := IDLE;
						vtx.busy_s := '0';--v.sts.busy_s := '0';
					end if;
				elsif (rtx.timer_send = 0) then
					vtx.data_count := 0;
					vtx.xmit_state := IDLE;
					vtx.busy_s := '0';--v.sts.busy_s := '0';
					vtx.lf_send_timeout := '1';--v.sts.lf_send_timeout := '1';
				else
					vtx.timer_send := rtx.timer_send - 1;
					vtx.lf_data_val_tx := '0';
				end if;
			
			when others =>
				vtx.xmit_state := IDLE;
		
		end case;
		
		rtxin <= vtx;
				
	end process;
	
	
	ahbso.hresp   	<= "00"; 
	ahbso.hsplit  	<= (others => '0'); 
	ahbso.hirq    	<= r.hirq;
	ahbso.hconfig 	<= hconfig;
	ahbso.hindex 	<= hindex;
	ahbso.hready 	<= r.hready;
	dmai.burst      <= '0';
    dmai.busy       <= '0';
    dmai.irq        <= '0';
    dmai.size       <= "010";
	lf_data_rdy_tx	<= rtx.lf_data_rdy_tx;
	lf_data_tx		<= rtx.data_tx;
	lf_data_val_tx	<= rtx.lf_data_val_tx;
	
	--ra_mem_xmit		<= std_logic_vector(to_unsigned(rtx.ra_mem_xmit, 12));
	
	reset <= rst and (not r.reset);
	
	serahbmst : ahbmst generic map (hindex => mindex, devid => 16#26#, incaddr => 0) 
	port map (rst, clk, dmai, dmao, ahbmi, ahbmo);
	
	reg: process (clk, reset)
	begin
		if (reset = '0') then
			r <= RES;
		elsif (clk'event and clk = '1') then
			r <= rin;
			--mem_rply <= rmem_rply;
			--mem_xmit <= rmem_xmit;
		end if;
	end process;	
	
	regrx: process (clk, reset)
	begin
		if (reset = '0') then
			rrx <= RESRX;
		elsif (clk'event and clk = '1') then
			rrx <= rrxin;
			--mem_recv <= rmem_recv;
			--mem_wdata <= rmem_wdata;
		end if;
	end process;

	regtx: process (clk, reset)
	begin
		if (reset = '0') then
			rtx <= RESTX;
		elsif (clk'event and clk = '1') then
			rtx <= rtxin;
		end if;
	end process;
	
	mem_xmit: generic_syncram_2p
	generic map(
		abits => 10,
		dbits => 32,
		sepclk => 0
	)
	port map(
		rclk => clk,
		wclk => clk,
		rdaddress => rtx.ra_mem_xmit,
		wraddress => r.wa_mem_xmit,
		data => r.wd_mem_xmit,
		wren => r.wr_mem_xmit,
		q => rd_mem_xmit
	);

	mem_recv: generic_syncram_2p
	generic map(
		abits => 10,
		dbits => 32,
		sepclk => 0
	)
	port map(
		rclk => clk,
		wclk => clk,
		rdaddress => ra_mem_recv,
		wraddress => rrx.wa_mem_recv,
		data => rrx.wd_mem_recv,
		wren => rrx.wr_mem_recv,
		q => rd_mem_recv
	);

	mem_wdata: generic_syncram_2p
	generic map(
		abits => 10,
		dbits => 32,
		sepclk => 0
	)
	port map(
		rclk => clk,
		wclk => clk,
		rdaddress => ra_mem_wdata,
		wraddress => rrx.wa_mem_wdata,
		data => rrx.wd_mem_wdata,
		wren => rrx.wr_mem_wdata,
		q => rd_mem_wdata
	);

	mem_rply: generic_syncram_2p
	generic map(
		abits => 10,
		dbits => 32,
		sepclk => 0
	)
	port map(
		rclk => clk,
		wclk => clk,
		rdaddress => rtx.ra_mem_rply,
		wraddress => r.wa_mem_rply,
		data => r.wd_mem_rply,
		wren => r.wr_mem_rply,
		q => rd_mem_rply
	);
	
END ARCHITECTURE rtl;
