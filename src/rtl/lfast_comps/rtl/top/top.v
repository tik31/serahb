//////////////////////////////////////////////////////////////////////
// Created by SmartDesign Fri May 15 13:53:48 2026
// Version: 2025.2 2025.2.0.14
//////////////////////////////////////////////////////////////////////

`timescale 1ns / 100ps

// top
module top(
    // Inputs
    CLK0_PAD,
    RXD0_N,
    RXD0_P,
    RXD1_N,
    RXD1_P,
    RXD2_N,
    RXD2_P,
    RXD3_N,
    RXD3_P,
    usr_data_rdy_tx_i,
    usr_data_tx_i,
    usr_data_val_tx_i,
    // Outputs
    EPCS_0_TX_CLK_STABLE,
    TXD0_N,
    TXD0_P,
    TXD1_N,
    TXD1_P,
    TXD2_N,
    TXD2_P,
    TXD3_N,
    TXD3_P,
    block_aligned_rx_o,
    clk50,
    clk_rx,
    clk_tx,
    crc_err_rx_o,
    lane_aligned_rx_o,
    req_usr_data_tx_o,
    reset,
    usr_data_rx_o,
    usr_data_val_rx_o
);

//--------------------------------------------------------------------
// Input
//--------------------------------------------------------------------
input        CLK0_PAD;
input        RXD0_N;
input        RXD0_P;
input        RXD1_N;
input        RXD1_P;
input        RXD2_N;
input        RXD2_P;
input        RXD3_N;
input        RXD3_P;
input        usr_data_rdy_tx_i;
input  [7:0] usr_data_tx_i;
input        usr_data_val_tx_i;
//--------------------------------------------------------------------
// Output
//--------------------------------------------------------------------
output       EPCS_0_TX_CLK_STABLE;
output       TXD0_N;
output       TXD0_P;
output       TXD1_N;
output       TXD1_P;
output       TXD2_N;
output       TXD2_P;
output       TXD3_N;
output       TXD3_P;
output [0:0] block_aligned_rx_o;
output       clk50;
output       clk_rx;
output       clk_tx;
output       crc_err_rx_o;
output       lane_aligned_rx_o;
output       req_usr_data_tx_o;
output       reset;
output [7:0] usr_data_rx_o;
output       usr_data_val_rx_o;
//--------------------------------------------------------------------
// Nets
//--------------------------------------------------------------------
wire   [0:0]  block_aligned_rx_o_net_0;
wire          CLK0_PAD;
wire          clk50_net_0;
wire          clk_rx_net_0 /* synthesis syn_noclockbuf=1 */;
wire          clk_tx_net_0 /* synthesis syn_noclockbuf=1 */;
wire          COREABC_C0_0_APB3Initiator_PENABLE;
wire   [31:0] COREABC_C0_0_APB3Initiator_PRDATA;
wire          COREABC_C0_0_APB3Initiator_PREADY;
wire          COREABC_C0_0_APB3Initiator_PSELx;
wire          COREABC_C0_0_APB3Initiator_PSLVERR;
wire   [31:0] COREABC_C0_0_APB3Initiator_PWDATA;
wire          COREABC_C0_0_APB3Initiator_PWRITE;
wire          CoreAPB3_C0_0_APBmslave0_PENABLE;
wire   [31:0] CoreAPB3_C0_0_APBmslave0_PRDATA;
wire          CoreAPB3_C0_0_APBmslave0_PREADY;
wire          CoreAPB3_C0_0_APBmslave0_PSELx;
wire          CoreAPB3_C0_0_APBmslave0_PSLVERR;
wire   [31:0] CoreAPB3_C0_0_APBmslave0_PWDATA;
wire          CoreAPB3_C0_0_APBmslave0_PWRITE;
wire          CorePCS_C0_0_ALIGNED;
wire          CorePCS_C0_0_EPCS_PWRDN;
wire          CorePCS_C0_0_EPCS_RxERR;
wire   [9:0]  CorePCS_C0_0_EPCS_TxDATA;
wire          CorePCS_C0_0_EPCS_TXOOB;
wire          CorePCS_C0_0_EPCS_TxVAL;
wire   [7:0]  CorePCS_C0_0_RX_DATA;
wire   [0:0]  CorePCS_C0_0_RX_K_CHAR;
wire          crc_err_rx_o_net_0;
wire          EPCS_0_TX_CLK_STABLE_net_0;
wire          FCCC_C0_0_GL1;
wire          lane_aligned_rx_o_net_0;
wire   [7:0]  LiteFast_C0_0_LiteFast_data_tx_o;
wire   [0:0]  LiteFast_C0_0_LiteFast_k_tx_o;
wire   [7:0]  remote_token_rx_o;
wire          req_usr_data_tx_o_net_0;
wire          reset_net_0;
wire          RXD0_N;
wire          RXD0_P;
wire          RXD1_N;
wire          RXD1_P;
wire          RXD2_N;
wire          RXD2_P;
wire          RXD3_N;
wire          RXD3_P;
wire          SERDES_IF_C0_0_EPCS_0_READY;
wire   [9:0]  SERDES_IF_C0_0_EPCS_0_RX_DATA;
wire          SERDES_IF_C0_0_EPCS_0_RX_IDLE;
wire          SERDES_IF_C0_0_EPCS_0_RX_RESET_N;
wire          SERDES_IF_C0_0_EPCS_0_RX_VAL;
wire          SERDES_IF_C0_0_EPCS_0_TX_RESET_N;
wire          TXD0_N_net_0;
wire          TXD0_P_net_0;
wire          TXD1_N_net_0;
wire          TXD1_P_net_0;
wire          TXD2_N_net_0;
wire          TXD2_P_net_0;
wire          TXD3_N_net_0;
wire          TXD3_P_net_0;
wire          usr_data_rdy_tx_i;
wire   [7:0]  usr_data_rx_o_net_0;
wire   [7:0]  usr_data_tx_i;
wire          usr_data_val_rx_o_net_0;
wire          usr_data_val_tx_i;
wire          TXD0_P_net_1;
wire          TXD0_N_net_1;
wire          TXD1_P_net_1;
wire          TXD1_N_net_1;
wire          TXD2_P_net_1;
wire          TXD2_N_net_1;
wire          TXD3_P_net_1;
wire          TXD3_N_net_1;
wire          usr_data_val_rx_o_net_1;
wire          crc_err_rx_o_net_1;
wire          lane_aligned_rx_o_net_1;
wire          req_usr_data_tx_o_net_1;
wire          EPCS_0_TX_CLK_STABLE_net_1;
wire          clk_tx_net_1;
wire          clk_rx_net_1;
wire          clk50_net_1;
wire          reset_net_1;
wire   [7:0]  usr_data_rx_o_net_1;
wire   [0:0]  block_aligned_rx_o_net_1;
//--------------------------------------------------------------------
// TiedOff Nets
//--------------------------------------------------------------------
wire          GND_net;
wire   [7:0]  min_remote_token_tx_i_const_net_0;
wire   [7:0]  local_token_tx_i_const_net_0;
wire          VCC_net;
wire   [31:0] PRDATAS1_const_net_0;
//--------------------------------------------------------------------
// Bus Interface Nets Declarations - Unequal Pin Widths
//--------------------------------------------------------------------
wire   [19:0] COREABC_C0_0_APB3Initiator_PADDR;
wire   [31:0] COREABC_C0_0_APB3Initiator_PADDR_0;
wire   [19:0] COREABC_C0_0_APB3Initiator_PADDR_0_19to0;
wire   [31:20]COREABC_C0_0_APB3Initiator_PADDR_0_31to20;
wire   [31:0] CoreAPB3_C0_0_APBmslave0_PADDR;
wire   [13:2] CoreAPB3_C0_0_APBmslave0_PADDR_0;
wire   [13:2] CoreAPB3_C0_0_APBmslave0_PADDR_0_13to2;
//--------------------------------------------------------------------
// Constant assignments
//--------------------------------------------------------------------
assign GND_net                           = 1'b0;
assign min_remote_token_tx_i_const_net_0 = 8'h03;
assign local_token_tx_i_const_net_0      = 8'hFF;
assign VCC_net                           = 1'b1;
assign PRDATAS1_const_net_0              = 32'h00000000;
//--------------------------------------------------------------------
// Top level output port assignments
//--------------------------------------------------------------------
assign TXD0_P_net_1                = TXD0_P_net_0;
assign TXD0_P                      = TXD0_P_net_1;
assign TXD0_N_net_1                = TXD0_N_net_0;
assign TXD0_N                      = TXD0_N_net_1;
assign TXD1_P_net_1                = TXD1_P_net_0;
assign TXD1_P                      = TXD1_P_net_1;
assign TXD1_N_net_1                = TXD1_N_net_0;
assign TXD1_N                      = TXD1_N_net_1;
assign TXD2_P_net_1                = TXD2_P_net_0;
assign TXD2_P                      = TXD2_P_net_1;
assign TXD2_N_net_1                = TXD2_N_net_0;
assign TXD2_N                      = TXD2_N_net_1;
assign TXD3_P_net_1                = TXD3_P_net_0;
assign TXD3_P                      = TXD3_P_net_1;
assign TXD3_N_net_1                = TXD3_N_net_0;
assign TXD3_N                      = TXD3_N_net_1;
assign usr_data_val_rx_o_net_1     = usr_data_val_rx_o_net_0;
assign usr_data_val_rx_o           = usr_data_val_rx_o_net_1;
assign crc_err_rx_o_net_1          = crc_err_rx_o_net_0;
assign crc_err_rx_o                = crc_err_rx_o_net_1;
assign lane_aligned_rx_o_net_1     = lane_aligned_rx_o_net_0;
assign lane_aligned_rx_o           = lane_aligned_rx_o_net_1;
assign req_usr_data_tx_o_net_1     = req_usr_data_tx_o_net_0;
assign req_usr_data_tx_o           = req_usr_data_tx_o_net_1;
assign EPCS_0_TX_CLK_STABLE_net_1  = EPCS_0_TX_CLK_STABLE_net_0;
assign EPCS_0_TX_CLK_STABLE        = EPCS_0_TX_CLK_STABLE_net_1;
assign clk_tx_net_1                = clk_tx_net_0;
assign clk_tx                      = clk_tx_net_1;
assign clk_rx_net_1                = clk_rx_net_0;
assign clk_rx                      = clk_rx_net_1;
assign clk50_net_1                 = clk50_net_0;
assign clk50                       = clk50_net_1;
assign reset_net_1                 = reset_net_0;
assign reset                       = reset_net_1;
assign usr_data_rx_o_net_1         = usr_data_rx_o_net_0;
assign usr_data_rx_o[7:0]          = usr_data_rx_o_net_1;
assign block_aligned_rx_o_net_1[0] = block_aligned_rx_o_net_0[0];
assign block_aligned_rx_o[0:0]     = block_aligned_rx_o_net_1[0];
//--------------------------------------------------------------------
// Bus Interface Nets Assignments - Unequal Pin Widths
//--------------------------------------------------------------------
assign COREABC_C0_0_APB3Initiator_PADDR_0 = { COREABC_C0_0_APB3Initiator_PADDR_0_31to20, COREABC_C0_0_APB3Initiator_PADDR_0_19to0 };
assign COREABC_C0_0_APB3Initiator_PADDR_0_19to0 = COREABC_C0_0_APB3Initiator_PADDR[19:0];
assign COREABC_C0_0_APB3Initiator_PADDR_0_31to20 = 12'h0;

assign CoreAPB3_C0_0_APBmslave0_PADDR_0 = { CoreAPB3_C0_0_APBmslave0_PADDR_0_13to2 };
assign CoreAPB3_C0_0_APBmslave0_PADDR_0_13to2 = CoreAPB3_C0_0_APBmslave0_PADDR[13:2];

//--------------------------------------------------------------------
// Component instances
//--------------------------------------------------------------------
//--------COREABC_C0
COREABC_C0 COREABC_C0_0(
        // Inputs
        .NSYSRESET ( reset_net_0 ),
        .PCLK      ( clk50_net_0 ),
        .PREADY_M  ( COREABC_C0_0_APB3Initiator_PREADY ),
        .PSLVERR_M ( COREABC_C0_0_APB3Initiator_PSLVERR ),
        .IO_IN     ( GND_net ), // tied to 1'b0 from definition
        .PRDATA_M  ( COREABC_C0_0_APB3Initiator_PRDATA ),
        // Outputs
        .PRESETN   (  ),
        .PSEL_M    ( COREABC_C0_0_APB3Initiator_PSELx ),
        .PENABLE_M ( COREABC_C0_0_APB3Initiator_PENABLE ),
        .PWRITE_M  ( COREABC_C0_0_APB3Initiator_PWRITE ),
        .IO_OUT    (  ),
        .PADDR_M   ( COREABC_C0_0_APB3Initiator_PADDR ),
        .PWDATA_M  ( COREABC_C0_0_APB3Initiator_PWDATA ) 
        );

//--------CoreAPB3_C0
CoreAPB3_C0 CoreAPB3_C0_0(
        // Inputs
        .PSEL      ( COREABC_C0_0_APB3Initiator_PSELx ),
        .PENABLE   ( COREABC_C0_0_APB3Initiator_PENABLE ),
        .PWRITE    ( COREABC_C0_0_APB3Initiator_PWRITE ),
        .PREADYS0  ( CoreAPB3_C0_0_APBmslave0_PREADY ),
        .PSLVERRS0 ( CoreAPB3_C0_0_APBmslave0_PSLVERR ),
        .PREADYS1  ( VCC_net ), // tied to 1'b1 from definition
        .PSLVERRS1 ( GND_net ), // tied to 1'b0 from definition
        .PADDR     ( COREABC_C0_0_APB3Initiator_PADDR_0 ),
        .PWDATA    ( COREABC_C0_0_APB3Initiator_PWDATA ),
        .PRDATAS0  ( CoreAPB3_C0_0_APBmslave0_PRDATA ),
        .PRDATAS1  ( PRDATAS1_const_net_0 ), // tied to 32'h00000000 from definition
        // Outputs
        .PREADY    ( COREABC_C0_0_APB3Initiator_PREADY ),
        .PSLVERR   ( COREABC_C0_0_APB3Initiator_PSLVERR ),
        .PSELS0    ( CoreAPB3_C0_0_APBmslave0_PSELx ),
        .PENABLES  ( CoreAPB3_C0_0_APBmslave0_PENABLE ),
        .PWRITES   ( CoreAPB3_C0_0_APBmslave0_PWRITE ),
        .PSELS1    (  ),
        .PRDATA    ( COREABC_C0_0_APB3Initiator_PRDATA ),
        .PADDRS    ( CoreAPB3_C0_0_APBmslave0_PADDR ),
        .PWDATAS   ( CoreAPB3_C0_0_APBmslave0_PWDATA ) 
        );

//--------CorePCS_C0
CorePCS_C0 CorePCS_C0_0(
        // Inputs
        .RESET_N     ( reset_net_0 ),
        .EPCS_READY  ( SERDES_IF_C0_0_EPCS_0_READY ),
        .EPCS_TxRSTn ( SERDES_IF_C0_0_EPCS_0_TX_RESET_N ),
        .EPCS_TxCLK  ( clk_tx_net_0 ),
        .EPCS_RxRSTn ( SERDES_IF_C0_0_EPCS_0_RX_RESET_N ),
        .EPCS_RxCLK  ( clk_rx_net_0 ),
        .EPCS_RxVAL  ( SERDES_IF_C0_0_EPCS_0_RX_VAL ),
        .EPCS_RxIDLE ( SERDES_IF_C0_0_EPCS_0_RX_IDLE ),
        .WA_RSTn     ( VCC_net ), // tied to 1'b1 from definition
        .EPCS_RxDATA ( SERDES_IF_C0_0_EPCS_0_RX_DATA ),
        .TX_DATA     ( LiteFast_C0_0_LiteFast_data_tx_o ),
        .TX_K_CHAR   ( LiteFast_C0_0_LiteFast_k_tx_o ),
        .FORCE_DISP  ( GND_net ), // tied to 1'b0 from definition
        .DISP_SEL    ( GND_net ),
        // Outputs
        .EPCS_PWRDN  ( CorePCS_C0_0_EPCS_PWRDN ),
        .EPCS_TXOOB  ( CorePCS_C0_0_EPCS_TXOOB ),
        .EPCS_TxVAL  ( CorePCS_C0_0_EPCS_TxVAL ),
        .EPCS_RxERR  ( CorePCS_C0_0_EPCS_RxERR ),
        .ALIGNED     ( CorePCS_C0_0_ALIGNED ),
        .EPCS_TxDATA ( CorePCS_C0_0_EPCS_TxDATA ),
        .INVALID_K   (  ),
        .RX_DATA     ( CorePCS_C0_0_RX_DATA ),
        .CODE_ERR_N  (  ),
        .RX_K_CHAR   ( CorePCS_C0_0_RX_K_CHAR ),
        .B_CERR      (  ),
        .RD_ERR      (  ) 
        );

//--------FCCC_C0
FCCC_C0 FCCC_C0_0(
        // Inputs
        .CLK0_PAD ( CLK0_PAD ),
        // Outputs
        .GL0      ( clk50_net_0 ),
        .GL1      ( FCCC_C0_0_GL1 ),
        .LOCK     ( reset_net_0 ) 
        );

//--------LiteFast_C0
LiteFast_C0 LiteFast_C0_0(
        // Inputs
        .clk_tx_i              ( clk_tx_net_0 ),
        .rst_n_tx_i            ( reset_net_0 ),
        .simplex_en_i          ( GND_net ),
        .local_rece_rdy_tx_i   ( lane_aligned_rx_o_net_0 ),
        .usr_data_rdy_tx_i     ( usr_data_rdy_tx_i ),
        .usr_data_val_tx_i     ( usr_data_val_tx_i ),
        .crc_err_en_tx_i       ( GND_net ),
        .clk_rx_i              ( clk_rx_net_0 ),
        .rst_n_rx_i            ( reset_net_0 ),
        .min_remote_token_tx_i ( min_remote_token_tx_i_const_net_0 ),
        .usr_data_tx_i         ( usr_data_tx_i ),
        .local_token_tx_i      ( local_token_tx_i_const_net_0 ),
        .remote_token_tx_i     ( remote_token_rx_o ),
        .serdes_rx_val_i       ( SERDES_IF_C0_0_EPCS_0_RX_VAL ),
        .word_aligned_rx_i     ( CorePCS_C0_0_ALIGNED ),
        .lane_k_rx_i           ( CorePCS_C0_0_RX_K_CHAR ),
        .lane_data_rx_i        ( CorePCS_C0_0_RX_DATA ),
        // Outputs
        .req_usr_data_tx_o     ( req_usr_data_tx_o_net_0 ),
        .lane_aligned_rx_o     ( lane_aligned_rx_o_net_0 ),
        .crc_err_rx_o          ( crc_err_rx_o_net_0 ),
        .usr_data_val_rx_o     ( usr_data_val_rx_o_net_0 ),
        .LiteFast_k_tx_o       ( LiteFast_C0_0_LiteFast_k_tx_o ),
        .LiteFast_data_tx_o    ( LiteFast_C0_0_LiteFast_data_tx_o ),
        .block_aligned_rx_o    ( block_aligned_rx_o_net_0 ),
        .remote_token_rx_o     ( remote_token_rx_o ),
        .usr_data_rx_o         ( usr_data_rx_o_net_0 ) 
        );

//--------SERDES_IF_C0
SERDES_IF_C0 SERDES_IF_C0_0(
        // Inputs
        .APB_S_PRESET_N       ( reset_net_0 ),
        .APB_S_PCLK           ( clk50_net_0 ),
        .EPCS_FAB_REF_CLK     ( FCCC_C0_0_GL1 ),
        .APB_S_PSEL           ( CoreAPB3_C0_0_APBmslave0_PSELx ),
        .APB_S_PENABLE        ( CoreAPB3_C0_0_APBmslave0_PENABLE ),
        .APB_S_PWRITE         ( CoreAPB3_C0_0_APBmslave0_PWRITE ),
        .APB_S_PADDR          ( CoreAPB3_C0_0_APBmslave0_PADDR_0 ),
        .APB_S_PWDATA         ( CoreAPB3_C0_0_APBmslave0_PWDATA ),
        .RXD0_P               ( RXD0_P ),
        .RXD0_N               ( RXD0_N ),
        .RXD1_P               ( RXD1_P ),
        .RXD1_N               ( RXD1_N ),
        .RXD2_P               ( RXD2_P ),
        .RXD2_N               ( RXD2_N ),
        .RXD3_P               ( RXD3_P ),
        .RXD3_N               ( RXD3_N ),
        .EPCS_0_PWRDN         ( CorePCS_C0_0_EPCS_PWRDN ),
        .EPCS_0_TX_VAL        ( CorePCS_C0_0_EPCS_TxVAL ),
        .EPCS_0_TX_OOB        ( CorePCS_C0_0_EPCS_TXOOB ),
        .EPCS_0_RX_ERR        ( CorePCS_C0_0_EPCS_RxERR ),
        .EPCS_0_RESET_N       ( reset_net_0 ),
        .EPCS_0_TX_DATA       ( CorePCS_C0_0_EPCS_TxDATA ),
        // Outputs
        .APB_S_PREADY         ( CoreAPB3_C0_0_APBmslave0_PREADY ),
        .APB_S_PRDATA         ( CoreAPB3_C0_0_APBmslave0_PRDATA ),
        .APB_S_PSLVERR        ( CoreAPB3_C0_0_APBmslave0_PSLVERR ),
        .TXD0_P               ( TXD0_P_net_0 ),
        .TXD0_N               ( TXD0_N_net_0 ),
        .TXD1_P               ( TXD1_P_net_0 ),
        .TXD1_N               ( TXD1_N_net_0 ),
        .TXD2_P               ( TXD2_P_net_0 ),
        .TXD2_N               ( TXD2_N_net_0 ),
        .TXD3_P               ( TXD3_P_net_0 ),
        .TXD3_N               ( TXD3_N_net_0 ),
        .EPCS_0_READY         ( SERDES_IF_C0_0_EPCS_0_READY ),
        .EPCS_0_RX_VAL        ( SERDES_IF_C0_0_EPCS_0_RX_VAL ),
        .EPCS_0_RX_IDLE       ( SERDES_IF_C0_0_EPCS_0_RX_IDLE ),
        .EPCS_0_TX_CLK_STABLE ( EPCS_0_TX_CLK_STABLE_net_0 ),
        .EPCS_0_RX_RESET_N    ( SERDES_IF_C0_0_EPCS_0_RX_RESET_N ),
        .EPCS_0_TX_RESET_N    ( SERDES_IF_C0_0_EPCS_0_TX_RESET_N ),
        .EPCS_0_RX_CLK        ( clk_rx_net_0 ),
        .EPCS_0_TX_CLK        ( clk_tx_net_0 ),
        .EPCS_0_RX_DATA       ( SERDES_IF_C0_0_EPCS_0_RX_DATA ) 
        );


endmodule
