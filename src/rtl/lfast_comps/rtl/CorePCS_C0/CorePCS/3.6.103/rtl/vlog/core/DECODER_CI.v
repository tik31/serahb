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
// 
module cpcs_decoder_ci (RX_DATA, RBC1, RSTN, /*COMMA_DETECT,*/ K, RX_WORD, CODE_ERROR_L, /*WORD_SYNC_L, COMMA_DETECT_ENABLE,*/ RD_ERR, B_CERR, RD_IN, RD_OUT);
 
   parameter PROG_COMMA_EN = 0;                   // 0 = disabled, 1 = enabled
   parameter SYNC_RESET = 0;

   input[9:0] RX_DATA;
   input RBC1;
   input RSTN;
//   input COMMA_DETECT;
   input RD_IN;
   
   output K;
   output[7:0] RX_WORD;
   output CODE_ERROR_L;
//   output WORD_SYNC_L;
//   output COMMA_DETECT_ENABLE;
   output RD_ERR; 
   output B_CERR; 
   output RD_OUT;
   
   reg K;   
   reg[7:0] RX_WORD;
   reg CODE_ERROR_L;   
   
//   wire COMMA_DETECT_ENABLE;
//   wire WORD_SYNC_L; 
   wire[0:9] ABCDEI_FGHJ; 
   reg[0:9] UB_ABCDEI_FGHJ; // ONE_CLOCK
   wire[7:0] DECX; 
   //
   // MERGE STAGE 
   //
   wire[7:0] DEC; 
   wire K_DEC; 
   wire C_ERR_DEC; 
   wire B_PD6BU; 
   wire B_ND6BU; 
   wire B_PD6BC; 
   wire B_ND6BC; 
   wire B_PD4BU; 
   wire B_ND4BU; 
   wire B_PD4BC; 
   wire B_ND4BC; 
   reg CODE_ERROR; 
   reg B_CERR; 
   reg RD_ERR; 
   
   wire B_DERR4; 
   wire B_DERR6; 
   wire B_K; 
   wire B_ND4BCX; 
   wire B_ND4BUX; 
   wire B_ND6BCX; 
   wire B_ND6BUX; 
   wire B_PD4BCX; 
   wire B_PD4BUX; 
   wire B_PD6BCX; 
   wire B_PD6BUX; 
   wire B_RD_ERR; 
   wire B_CERR_int; 
   wire RD_ERR_int; 
   wire aresetn;
   wire sresetn;
   
   assign aresetn = (SYNC_RESET==1) ? 1'b1 : RSTN;
   assign sresetn = (SYNC_RESET==1) ? RSTN : 1'b1; 
   assign ABCDEI_FGHJ[0] = RX_DATA[0] ; 
   assign ABCDEI_FGHJ[1] = RX_DATA[1] ; 
   assign ABCDEI_FGHJ[2] = RX_DATA[2] ; 
   assign ABCDEI_FGHJ[3] = RX_DATA[3] ; 
   assign ABCDEI_FGHJ[4] = RX_DATA[4] ; 
   assign ABCDEI_FGHJ[5] = RX_DATA[5] ; 
   assign ABCDEI_FGHJ[6] = RX_DATA[6] ; 
   assign ABCDEI_FGHJ[7] = RX_DATA[7] ; 
   assign ABCDEI_FGHJ[8] = RX_DATA[8] ; 
   assign ABCDEI_FGHJ[9] = RX_DATA[9] ; 

   always @(posedge RBC1 or negedge aresetn)
   begin
      if ((!aresetn) || (!sresetn))
      begin
         UB_ABCDEI_FGHJ <= 10'b0000000000 ; 
      end
      else
      begin
         UB_ABCDEI_FGHJ <= ABCDEI_FGHJ ; 
      end 
   end 

   // DECODE OF DATA REGISTERED BY RBC0 (RESYNCHRONIZED WITH RBC1)
   cpcs_dec_data #( .SYNC_RESET(SYNC_RESET)) UB (.CLK(RBC1), .RESET_L(RSTN), .ABCDEI_FGHJ(UB_ABCDEI_FGHJ),
   .PD6BU(B_PD6BUX), .ND6BU(B_ND6BUX), .PD6BC(B_PD6BCX), .ND6BC(B_ND6BCX), .
   PD4BU(B_PD4BUX), .ND4BU(B_ND4BUX), .PD4BC(B_PD4BCX), .ND4BC(B_ND4BCX), .CERR(
   B_CERR_int), .K(B_K), .DATA(DECX[7:0]));

//   // SYNCHRONIZATION STATE MACHINE
//   cpcs_sync_fsm #(.PROG_COMMA_EN(PROG_COMMA_EN), .SYNC_RESET(SYNC_RESET)) 
//   USYNC (.COMMA_DETECT_ENABLE(COMMA_DETECT_ENABLE), .WORD_SYNC_L(WORD_SYNC_L), 
//   .COMMA_DETECT(COMMA_DETECT), .CODE_ERROR(CODE_ERROR), .RBC1(RBC1), .RESET_L(RSTN)); 
   assign DEC = DECX ; 
   assign K_DEC = B_K; 
   assign C_ERR_DEC = B_CERR; 
   assign B_PD6BU = B_PD6BUX ; 
   assign B_ND6BU = B_ND6BUX ; 
   assign B_PD6BC = B_PD6BCX ; 
   assign B_ND6BC = B_ND6BCX ; 
   assign B_PD4BU = B_PD4BUX ; 
   assign B_ND4BU = B_ND4BUX ; 
   assign B_PD4BC = B_PD4BCX ; 
   assign B_ND4BC = B_ND4BCX ; 
   //
   // PART OF THE MERGE PHASE, STAGE 1
   //
   // OUTPUTS 
   cpcs_dec_rd_u #( .SYNC_RESET(SYNC_RESET)) URD (.RBC1(RBC1), .RESET_L(RSTN), .B_PD6BU(B_PD6BU), .B_ND6BU(B_ND6BU),
   .B_PD6BC(B_PD6BC), .B_ND6BC(B_ND6BC), .B_PD4BU(B_PD4BU), .B_ND4BU(B_ND4BU),
   .B_PD4BC(B_PD4BC), .B_ND4BC(B_ND4BC),
   .B_DERR6(B_DERR6), .B_DERR4(B_DERR4), .RD_ERR(RD_ERR_int),.B_RD_ERR(B_RD_ERR), .RD_IN(RD_IN), .RD_OUT(RD_OUT)); 

   //ERR <= A_CERR OR B_CERR OR A_RD_ERRX OR A_RD_ERR OR B_RD_ERR ;
   always @(posedge RBC1 or negedge aresetn)
   begin
      if ((!aresetn) || (!sresetn))
      begin
         RX_WORD <= 8'b0 ; 
         K <= 1'b0 ; 
         B_CERR <= 1'b0 ;
         RD_ERR <= 1'b0 ;
         CODE_ERROR <= 1'b0 ; 
         CODE_ERROR_L <= 1'b1 ; 
      end
      else
      begin
         RX_WORD <= DEC ; 
         K <= K_DEC ; 
         CODE_ERROR <= B_CERR_int | RD_ERR_int ; 
         B_CERR <= B_CERR_int;
         RD_ERR <= RD_ERR_int;
         //
         //   CODE_ERROR_L LOOKS BACK THREE BYTES FOR RD ERRORS, WHILE CODE_ERROR DOES 
         //   NOT.  THE CODE_ERROR SIGNAL FEEDS THE cpcs_sync_fsm STATE MACHINE, AND WE DON'T
         //   WANT TO COUNT AN ERROR MORE THAN ONCE THERE.
         //  
         CODE_ERROR_L <= ~(B_CERR_int | RD_ERR_int) ; 
      end 
   end 
endmodule
