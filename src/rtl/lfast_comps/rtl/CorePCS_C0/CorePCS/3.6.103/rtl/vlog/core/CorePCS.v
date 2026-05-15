// ********************************************************************
//  Microsemi Corporation Proprietary and Confidential
//  Copyright 2012 Microsemi Corporation.  All rights reserved.
//
// ANY USE OR REDISTRIBUTION IN PART OR IN WHOLE MUST BE HANDLED IN
// ACCORDANCE WITH THE MICROSEMI LICENSE AGREEMENT AND MUST BE APPROVED
// IN ADVANCE IN WRITING.
//
// Description: CorePCS core
//
// Revision Information:
// Date     Description
// Nov12    Revision 2.0
//
// Notes:
// best viewed with tabstops set to "4"

module CorePCS( //Resets 
                 RESET_N,
                 WA_RSTn,
                //EPCS Control Signals
                 EPCS_READY,
                 EPCS_PWRDN,
                 EPCS_TXOOB,
                //EPCS Tx Channel
                 EPCS_TxRSTn,
                 EPCS_TxCLK,
                 EPCS_TxVAL,
                 EPCS_TxDATA,
                //EPCS Rx Channel
                 EPCS_RxRSTn,
                 EPCS_RxCLK,
                 EPCS_RxVAL,
                 EPCS_RxDATA,
                 EPCS_RxIDLE,
                 EPCS_RxERR,
                //8B10B cpcs_encoder
                 TX_DATA,
                 TX_K_CHAR,
                 INVALID_K,
                //8B10B cpcs_decoder
                 RX_DATA,
                 CODE_ERR_N,
                 RX_K_CHAR,
                 B_CERR,
                 RD_ERR,
                //Tx Disparity Control
                 FORCE_DISP,
                 DISP_SEL,
                // Word Aligner
                 ALIGNED
   );
 //  
 // Parameters  
 //
 parameter FAMILY           = 19;
 parameter LANE_MODE        = 2;                        // 0 = Transmitter only, 1 = Receiver only, 2 = Transmitter & Receiver
 parameter EPCS_DWIDTH      = 20;                       // 10bit, 20bit, 40bit or 80bit
 parameter PROG_COMMA_EN    = 1;                        // 0 = Fixed, 1 = Configurable
 parameter NO_OF_COMMAS     = 10;                       // Number of commas required for word align if PROG_COMMA_EN is Configurable (1 to 2048)
 parameter COMMA_DETECT_SEL = 1;                        // 0 = K28.5, 1 = K28.1, 2 = K28.1 or K28.5 or K28.7, 3 = K28.7 
 parameter ENDEC_DWIDTH     = (EPCS_DWIDTH/10)*8;       // 8bit, 16bit, 32bit or 64bit
 parameter IO_SIZE          = (EPCS_DWIDTH/10)-1;       // 0,1,3,7
 parameter SHIFT_EN         = 0;                        // 0 = disabled, 1 = enabled

 parameter SYNC_RESET       = (FAMILY == 25) ? 1 : 0;   // 0 = async mode, 1 = sync mode

 parameter integer TGIGEN_DISPLAY_SYMBOL    = 1;
 integer i=0;
 //
 // Resets 
 //
 input RESET_N;
 input WA_RSTn;
 //
 // EPCS Control Signals
 //
 input EPCS_READY;
 output EPCS_PWRDN;
 output EPCS_TXOOB;
 //
 // EPCS Tx Channel
 //
 input EPCS_TxRSTn;
 input EPCS_TxCLK;
 output EPCS_TxVAL;
 output [EPCS_DWIDTH-1:0] EPCS_TxDATA;
 //
 // EPCS Rx Channel
 //
 input EPCS_RxRSTn;
 input EPCS_RxCLK;
 input EPCS_RxVAL;
 input [EPCS_DWIDTH-1:0] EPCS_RxDATA;
 input EPCS_RxIDLE;
 output EPCS_RxERR;
 //
 // 8B10B cpcs_encoder
 //
 input [ENDEC_DWIDTH-1:0] TX_DATA;
 input [IO_SIZE:0] TX_K_CHAR;
 output [IO_SIZE:0] INVALID_K;
 //   
 // 8B10B cpcs_decoder
 //
 output [ENDEC_DWIDTH-1:0] RX_DATA;
 output [IO_SIZE:0] CODE_ERR_N;
 output [IO_SIZE:0] RX_K_CHAR;
 output [IO_SIZE:0] B_CERR;
 output [IO_SIZE:0] RD_ERR;
 //
 // Tx Disparity Control
 //
 input [IO_SIZE:0] FORCE_DISP;
 input [IO_SIZE:0] DISP_SEL;   //0=RD-, 1=RD+
 //
 // Word Aligner
 //
 output ALIGNED;
 //
 // Regs & Wires
 //
 reg [EPCS_DWIDTH-1:0] EPCS_TxDATA;
 wire [EPCS_DWIDTH-1:0] EPCS_TxDATA_int;
 wire ALIGNED;
// wire [IO_SIZE:0] d2w_ws;
// wire [IO_SIZE:0] d2w_cde;
// wire [IO_SIZE:0] w2d_cd;
 wire [EPCS_DWIDTH-1:0] w2d_data;
 wire tx_rst_n;
 wire rx_rst_n;
 wire wa_rst_n;
 wire EPCS_PWRDN;
 wire EPCS_TXOOB;
 wire EPCS_RxERR;
 wire EPCS_TxVAL;
 wire [IO_SIZE:0] INVALID_K;
 wire [ENDEC_DWIDTH-1:0] RX_DATA;
 wire [IO_SIZE:0] CODE_ERR_N;
 wire [IO_SIZE:0] RX_K_CHAR;
 wire [IO_SIZE:0] B_CERR;
 wire [IO_SIZE:0] RD_ERR;

 assign EPCS_PWRDN = 1'b0;
 assign EPCS_TXOOB = 1'b0;
 assign EPCS_RxERR = (!(&CODE_ERR_N)) | (|B_CERR) | (|RD_ERR);
 assign EPCS_TxVAL = (IO_SIZE == 0) ? !INVALID_K : !(| INVALID_K);
 
 //
 // Instances
 // 
cpcs_reset_sync 
#(
    .SYNC_RESET     (SYNC_RESET     )
 ) 
cpcs_rst_sync 
 ( 
    .EPCS_TxCLK     (EPCS_TxCLK     ),
    .EPCS_RxCLK     (EPCS_RxCLK     ),
    .EPCS_TxRSTn    (EPCS_TxRSTn    ),
    .EPCS_RxRSTn    (EPCS_RxRSTn    ),
    .RESET_N        (RESET_N        ),
    .WA_RSTn        (WA_RSTn        ),
    .EPCS_RxVAL     (EPCS_RxVAL     ),
    .syncd_tx_rst_n (tx_rst_n       ),
    .syncd_rx_rst_n (rx_rst_n       ),
    .syncd_wa_rst_n (wa_rst_n       )
 );

 generate
 if((EPCS_DWIDTH >= 20) && ((LANE_MODE == 0) || (LANE_MODE == 2)))
   begin
     cpcs_encoder64b80b #(.SYNC_RESET(SYNC_RESET), .EPCS_DWIDTH(EPCS_DWIDTH)) ENC_80 ( .CLK_IN(EPCS_TxCLK), .RESET_N(tx_rst_n), .DATA_IN(TX_DATA), .K_IN(TX_K_CHAR), .ENC_OUT(EPCS_TxDATA_int), .FORCE_DISP(FORCE_DISP), .DISP_SEL(DISP_SEL), .INVALID_K(INVALID_K));
	 always @(*)
      begin
        for (i=0; i<EPCS_DWIDTH; i=i+1)
          begin
            EPCS_TxDATA[i] <= EPCS_TxDATA_int[EPCS_DWIDTH-(1+i)];  
          end
      end
   
   end
 else if((EPCS_DWIDTH == 10) && ((LANE_MODE == 0) || (LANE_MODE == 2)))
   begin
     cpcs_encoder #(.SYNC_RESET(SYNC_RESET)) ENC_10 ( .D(TX_DATA), .K(TX_K_CHAR), .CLK(EPCS_TxCLK), .RST_N(tx_rst_n), .ABCDEI_FGHJ(EPCS_TxDATA_int), .INVALID_K(INVALID_K), .FORCE_DISP(FORCE_DISP), .DISP_SEL(DISP_SEL)); 
	 always @(*)
      begin	 
	    EPCS_TxDATA <= {EPCS_TxDATA_int[0], EPCS_TxDATA_int[1], EPCS_TxDATA_int[2], EPCS_TxDATA_int[3], EPCS_TxDATA_int[4], EPCS_TxDATA_int[5], EPCS_TxDATA_int[6], EPCS_TxDATA_int[7], EPCS_TxDATA_int[8], EPCS_TxDATA_int[9]};
      end
   end
 else
   begin
     assign INVALID_K = {IO_SIZE+1{1'b0}};
     assign EPCS_TxDATA_int = {EPCS_DWIDTH{1'b0}};
	 always @(*)
      begin	 
	    EPCS_TxDATA <= {EPCS_DWIDTH{1'b0}};
      end
   end
 endgenerate
 
  generate
     if((EPCS_DWIDTH >= 20) && ((LANE_MODE == 1) || (LANE_MODE == 2)))
       begin
         cpcs_dec_wa #( .SHIFT_EN(SHIFT_EN),
    	                .PROG_COMMA_EN(PROG_COMMA_EN),
    			        .NO_OF_COMMAS(NO_OF_COMMAS),
				        .COMMA_DETECT_SEL(COMMA_DETECT_SEL),
				        .SYNC_RESET(SYNC_RESET),
						.EPCS_DWIDTH(EPCS_DWIDTH)) 
         cpcs_dec_wa  ( .RST_N(rx_rst_n),
                        .WA_RST_n(wa_rst_n),
                        .CLOCK(EPCS_RxCLK),
                        .DATA_IN(EPCS_RxDATA),
                        .DATA_OUT(RX_DATA),
                        .VALID_OUT(CODE_ERR_N),
                        .K_OUT(RX_K_CHAR),
                        .NIT_ERR(B_CERR),
                        .DISP_ERR(RD_ERR),
                        .ALIGNED(ALIGNED));

    	 assign w2d_data[EPCS_DWIDTH-1:0] = {EPCS_DWIDTH{1'b0}};
//         assign w2d_cd = {IO_SIZE+1{1'b0}};
//         assign d2w_ws = {IO_SIZE+1{1'b0}};
//         assign d2w_cde = {IO_SIZE+1{1'b0}}; 
       end
     else if((EPCS_DWIDTH == 10) && ((LANE_MODE == 1) || (LANE_MODE == 2)))
       begin
         wire [9:0] EPCS_RxDATA_rev;
         assign EPCS_RxDATA_rev = {EPCS_RxDATA[0], EPCS_RxDATA[1], EPCS_RxDATA[2], EPCS_RxDATA[3], EPCS_RxDATA[4], EPCS_RxDATA[5], EPCS_RxDATA[6], EPCS_RxDATA[7], EPCS_RxDATA[8], EPCS_RxDATA[9]};
         cpcs_decoder #( .PROG_COMMA_EN(PROG_COMMA_EN),.SYNC_RESET(SYNC_RESET))
               DEC_10  ( .RX_DATA({w2d_data[0], w2d_data[1], w2d_data[2], w2d_data[3], w2d_data[4], w2d_data[5], w2d_data[6], w2d_data[7], w2d_data[8], w2d_data[9]}), 
                         .RBC1(EPCS_RxCLK), .RSTN(rx_rst_n), /*.COMMA_DETECT(w2d_cd),*/ .K(RX_K_CHAR), .RX_WORD(RX_DATA), .CODE_ERROR_L(CODE_ERR_N), 
                         /*.WORD_SYNC_L(d2w_ws), .COMMA_DETECT_ENABLE(d2w_cde),*/ .B_CERR(B_CERR),.RD_ERR(RD_ERR));

          cpcs_wa_10  #( .PROG_COMMA_EN(PROG_COMMA_EN), .NO_OF_COMMAS(NO_OF_COMMAS), .COMMA_DETECT_SEL(COMMA_DETECT_SEL), .SYNC_RESET(SYNC_RESET)) 
          cpcs_wa_10   ( .CLK(EPCS_RxCLK), .RST_N(wa_rst_n), .DATA_IN(EPCS_RxDATA_rev), .WA_DATA(w2d_data), .CODE_ERROR(CODE_ERR_N),/*.WRD_SYNC(d2w_ws), .CDE(d2w_cde), .COMMA_DETECT(w2d_cd),*/ .ALIGNED(ALIGNED)); 
       end
     else
       begin
         assign ALIGNED = 1'b0;
         assign w2d_data = {EPCS_DWIDTH{1'b0}};
//         assign w2d_cd = {IO_SIZE+1{1'b0}};
         assign RX_K_CHAR = {IO_SIZE+1{1'b0}};
         assign CODE_ERR_N = {IO_SIZE+1{1'b0}};
         assign B_CERR = {IO_SIZE+1{1'b0}};
         assign RD_ERR = {IO_SIZE+1{1'b0}};
         assign RX_DATA = {ENDEC_DWIDTH{1'b0}};
//         assign d2w_ws = {IO_SIZE+1{1'b0}};
//         assign d2w_cde = {IO_SIZE+1{1'b0}}; 
       end
 endgenerate
 

endmodule
