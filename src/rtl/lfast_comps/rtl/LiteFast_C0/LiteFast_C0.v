//////////////////////////////////////////////////////////////////////
// Created by SmartDesign Fri Feb 27 13:58:04 2026
// Version: 2025.2 2025.2.0.14
//////////////////////////////////////////////////////////////////////

`timescale 1ns / 100ps

//////////////////////////////////////////////////////////////////////
// Component Description (Tcl) 
//////////////////////////////////////////////////////////////////////
/*
# Exporting Component Description of LiteFast_C0 to TCL
# Family: SmartFusion2
# Part Number: M2S025T-VF400I
# Create and Configure the core component LiteFast_C0
create_and_configure_core -core_vlnv {Microsemi:Solutioncore:LiteFast:1.0.5} -component_name {LiteFast_C0} -params {\
"g_DATA_WID:8"  \
"g_LANE_NUM:1"  \
"LiteFast_Mode:0"   }
# Exporting Component Description of LiteFast_C0 to TCL done
*/

// LiteFast_C0
module LiteFast_C0(
    // Inputs
    clk_rx_i,
    clk_tx_i,
    crc_err_en_tx_i,
    lane_data_rx_i,
    lane_k_rx_i,
    local_rece_rdy_tx_i,
    local_token_tx_i,
    min_remote_token_tx_i,
    remote_token_tx_i,
    rst_n_rx_i,
    rst_n_tx_i,
    serdes_rx_val_i,
    simplex_en_i,
    usr_data_rdy_tx_i,
    usr_data_tx_i,
    usr_data_val_tx_i,
    word_aligned_rx_i,
    // Outputs
    LiteFast_data_tx_o,
    LiteFast_k_tx_o,
    block_aligned_rx_o,
    crc_err_rx_o,
    lane_aligned_rx_o,
    remote_token_rx_o,
    req_usr_data_tx_o,
    usr_data_rx_o,
    usr_data_val_rx_o
);

//--------------------------------------------------------------------
// Input
//--------------------------------------------------------------------
input        clk_rx_i;
input        clk_tx_i;
input        crc_err_en_tx_i;
input  [7:0] lane_data_rx_i;
input  [0:0] lane_k_rx_i;
input        local_rece_rdy_tx_i;
input  [7:0] local_token_tx_i;
input  [7:0] min_remote_token_tx_i;
input  [7:0] remote_token_tx_i;
input        rst_n_rx_i;
input        rst_n_tx_i;
input  [0:0] serdes_rx_val_i;
input        simplex_en_i;
input        usr_data_rdy_tx_i;
input  [7:0] usr_data_tx_i;
input        usr_data_val_tx_i;
input  [0:0] word_aligned_rx_i;
//--------------------------------------------------------------------
// Output
//--------------------------------------------------------------------
output [7:0] LiteFast_data_tx_o;
output [0:0] LiteFast_k_tx_o;
output [0:0] block_aligned_rx_o;
output       crc_err_rx_o;
output       lane_aligned_rx_o;
output [7:0] remote_token_rx_o;
output       req_usr_data_tx_o;
output [7:0] usr_data_rx_o;
output       usr_data_val_rx_o;
//--------------------------------------------------------------------
// Nets
//--------------------------------------------------------------------
wire   [0:0] block_aligned_rx_o_net_0;
wire         clk_rx_i;
wire         clk_tx_i;
wire         crc_err_en_tx_i;
wire         crc_err_rx_o_net_0;
wire         lane_aligned_rx_o_net_0;
wire   [7:0] lane_data_rx_i;
wire   [0:0] lane_k_rx_i;
wire   [7:0] LiteFast_data_tx_o_net_0;
wire   [0:0] LiteFast_k_tx_o_net_0;
wire         local_rece_rdy_tx_i;
wire   [7:0] local_token_tx_i;
wire   [7:0] min_remote_token_tx_i;
wire   [7:0] remote_token_rx_o_net_0;
wire   [7:0] remote_token_tx_i;
wire         req_usr_data_tx_o_net_0;
wire         rst_n_rx_i;
wire         rst_n_tx_i;
wire   [0:0] serdes_rx_val_i;
wire         simplex_en_i;
wire         usr_data_rdy_tx_i;
wire   [7:0] usr_data_rx_o_net_0;
wire   [7:0] usr_data_tx_i;
wire         usr_data_val_rx_o_net_0;
wire         usr_data_val_tx_i;
wire   [0:0] word_aligned_rx_i;
wire         req_usr_data_tx_o_net_1;
wire         lane_aligned_rx_o_net_1;
wire         crc_err_rx_o_net_1;
wire         usr_data_val_rx_o_net_1;
wire   [0:0] LiteFast_k_tx_o_net_1;
wire   [7:0] LiteFast_data_tx_o_net_1;
wire   [0:0] block_aligned_rx_o_net_1;
wire   [7:0] remote_token_rx_o_net_1;
wire   [7:0] usr_data_rx_o_net_1;
//--------------------------------------------------------------------
// Top level output port assignments
//--------------------------------------------------------------------
assign req_usr_data_tx_o_net_1     = req_usr_data_tx_o_net_0;
assign req_usr_data_tx_o           = req_usr_data_tx_o_net_1;
assign lane_aligned_rx_o_net_1     = lane_aligned_rx_o_net_0;
assign lane_aligned_rx_o           = lane_aligned_rx_o_net_1;
assign crc_err_rx_o_net_1          = crc_err_rx_o_net_0;
assign crc_err_rx_o                = crc_err_rx_o_net_1;
assign usr_data_val_rx_o_net_1     = usr_data_val_rx_o_net_0;
assign usr_data_val_rx_o           = usr_data_val_rx_o_net_1;
assign LiteFast_k_tx_o_net_1[0]    = LiteFast_k_tx_o_net_0[0];
assign LiteFast_k_tx_o[0:0]        = LiteFast_k_tx_o_net_1[0];
assign LiteFast_data_tx_o_net_1    = LiteFast_data_tx_o_net_0;
assign LiteFast_data_tx_o[7:0]     = LiteFast_data_tx_o_net_1;
assign block_aligned_rx_o_net_1[0] = block_aligned_rx_o_net_0[0];
assign block_aligned_rx_o[0:0]     = block_aligned_rx_o_net_1[0];
assign remote_token_rx_o_net_1     = remote_token_rx_o_net_0;
assign remote_token_rx_o[7:0]      = remote_token_rx_o_net_1;
assign usr_data_rx_o_net_1         = usr_data_rx_o_net_0;
assign usr_data_rx_o[7:0]          = usr_data_rx_o_net_1;
//--------------------------------------------------------------------
// Component instances
//--------------------------------------------------------------------
//--------LiteFast   -   Microsemi:Solutioncore:LiteFast:1.0.5
LiteFast #( 
        .g_DATA_WID    ( 8 ),
        .g_LANE_NUM    ( 1 ),
        .LiteFast_Mode ( 0 ) )
LiteFast_C0_0(
        // Inputs
        .clk_tx_i              ( clk_tx_i ),
        .rst_n_tx_i            ( rst_n_tx_i ),
        .simplex_en_i          ( simplex_en_i ),
        .local_rece_rdy_tx_i   ( local_rece_rdy_tx_i ),
        .usr_data_rdy_tx_i     ( usr_data_rdy_tx_i ),
        .usr_data_val_tx_i     ( usr_data_val_tx_i ),
        .crc_err_en_tx_i       ( crc_err_en_tx_i ),
        .clk_rx_i              ( clk_rx_i ),
        .rst_n_rx_i            ( rst_n_rx_i ),
        .min_remote_token_tx_i ( min_remote_token_tx_i ),
        .usr_data_tx_i         ( usr_data_tx_i ),
        .local_token_tx_i      ( local_token_tx_i ),
        .remote_token_tx_i     ( remote_token_tx_i ),
        .serdes_rx_val_i       ( serdes_rx_val_i ),
        .word_aligned_rx_i     ( word_aligned_rx_i ),
        .lane_k_rx_i           ( lane_k_rx_i ),
        .lane_data_rx_i        ( lane_data_rx_i ),
        // Outputs
        .req_usr_data_tx_o     ( req_usr_data_tx_o_net_0 ),
        .lane_aligned_rx_o     ( lane_aligned_rx_o_net_0 ),
        .crc_err_rx_o          ( crc_err_rx_o_net_0 ),
        .usr_data_val_rx_o     ( usr_data_val_rx_o_net_0 ),
        .LiteFast_k_tx_o       ( LiteFast_k_tx_o_net_0 ),
        .LiteFast_data_tx_o    ( LiteFast_data_tx_o_net_0 ),
        .block_aligned_rx_o    ( block_aligned_rx_o_net_0 ),
        .remote_token_rx_o     ( remote_token_rx_o_net_0 ),
        .usr_data_rx_o         ( usr_data_rx_o_net_0 ) 
        );


endmodule
