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
// Oct12    Revision 1.0
//
// Notes:
// best viewed with tabstops set to "4"
 
module cpcs_dec_wa( RST_N,
                    WA_RST_n,
                    CLOCK,
                    DATA_IN,
                    DATA_OUT,
                    VALID_OUT,
                    K_OUT,
                    NIT_ERR,
                    DISP_ERR,
			        ALIGNED
                    );
					
/////////////////////////////////////////////////////////////////////////////////
///                               PARAMETER                                    //   
/////////////////////////////////////////////////////////////////////////////////
 parameter SHIFT_EN = 0;                        // 0 = disabled, 1 = enabled
 parameter PROG_COMMA_EN = 0;                   // 0 = disabled, 1 = enabled
 parameter NO_OF_COMMAS = 10;                   // Number of commas required for word align if PROG_COMMA_EN is enabled
 parameter COMMA_DETECT_SEL = 0;                // 0 = K28.5, 1 = K28.1, 2 = K28.5 & K28.1
 parameter SYNC_RESET = 0;
 parameter EPCS_DWIDTH = 20;   
 parameter ENDEC_DWIDTH = (EPCS_DWIDTH/10) * 8;
 parameter IO_SIZE = (EPCS_DWIDTH/10) - 1; 
 integer i=0;
/////////////////////////////////////////////////////////////////////////////////
///                                  INPUTS                                    //   
/////////////////////////////////////////////////////////////////////////////////
input RST_N;
input WA_RST_n;
input CLOCK;
input [EPCS_DWIDTH-1:0] DATA_IN;

/////////////////////////////////////////////////////////////////////////////////
///                                  OUTPUTS                                    //   
/////////////////////////////////////////////////////////////////////////////////
output [ENDEC_DWIDTH-1:0] DATA_OUT;
output [IO_SIZE:0] VALID_OUT;
output [IO_SIZE:0] K_OUT;
output [IO_SIZE:0] NIT_ERR;
output [IO_SIZE:0] DISP_ERR;
output ALIGNED;

/////////////////////////////////////////////////////////////////////////////////
///                           REGS & WIRES                                     //   
/////////////////////////////////////////////////////////////////////////////////
reg [4:0] EXPD_ERR_reg;
reg [EPCS_DWIDTH-1:0] data_rev;

wire [IO_SIZE:0] NIT_ERR;
wire [IO_SIZE:0] DISP_ERR;
wire [EPCS_DWIDTH-1:0] W2D_DATA;
//wire [IO_SIZE:0] d2w_ws;
//wire [IO_SIZE:0] d2w_cde;
//wire [IO_SIZE:0] w2d_cd;
wire [IO_SIZE:0] NIT_ERR_int;
wire [IO_SIZE:0] DISP_ERR_int;
wire [IO_SIZE:0] VALID_OUT_int;
wire EXPD_ERR;
wire rd_u2l;
wire aresetn;
wire sresetn; 
wire [IO_SIZE-1:0] rd_l2l;
wire rd_in_u;

/////////////////////////////////////////////////////////////////////////////////
///                                  ASSIGNS                                   //   
/////////////////////////////////////////////////////////////////////////////////
assign aresetn = (SYNC_RESET==1) ? 1'b1 : RST_N;
assign sresetn = (SYNC_RESET==1) ? RST_N : 1'b1;
assign NIT_ERR = NIT_ERR_int;
assign DISP_ERR  = (EXPD_ERR_reg[4:3] > 2'b0) ? {IO_SIZE+1{1'b0}} : DISP_ERR_int;
assign VALID_OUT = (EXPD_ERR_reg[4:3] > 2'b0) ? {IO_SIZE+1{1'b1}} : VALID_OUT_int;

assign rd_in_u = (ENDEC_DWIDTH == 8) ? rd_u2l : rd_l2l[IO_SIZE-1];
/////////////////////////////////////////////////////////////////////////////////
///                                  RTL                                       //   
/////////////////////////////////////////////////////////////////////////////////
  always @(*)
    begin
      for (i=0; i<EPCS_DWIDTH; i=i+1)
        begin
          data_rev[i] <= DATA_IN[EPCS_DWIDTH-(1+i)];
        end
    end
	  
  always @(posedge CLOCK or negedge aresetn)
    begin
      if((!aresetn) || (!sresetn))
        begin
          EXPD_ERR_reg <= 5'b0;
        end
      else
        begin
          EXPD_ERR_reg <= {EXPD_ERR_reg[3:0], EXPD_ERR};
        end
    end
/////////////////////////////////////////////////////////////////////////////////
///                                INSTANCES                                   //   
/////////////////////////////////////////////////////////////////////////////////
cpcs_decoder_co #( .PROG_COMMA_EN(PROG_COMMA_EN),
                   .SYNC_RESET(SYNC_RESET))
  cpcs_decoder_co( .RX_DATA({W2D_DATA[EPCS_DWIDTH-10], W2D_DATA[EPCS_DWIDTH-9], W2D_DATA[EPCS_DWIDTH-8], W2D_DATA[EPCS_DWIDTH-7], W2D_DATA[EPCS_DWIDTH-6], 
                             W2D_DATA[EPCS_DWIDTH-5],  W2D_DATA[EPCS_DWIDTH-4], W2D_DATA[EPCS_DWIDTH-3], W2D_DATA[EPCS_DWIDTH-2], W2D_DATA[EPCS_DWIDTH-1]}), 
                   .RBC1(CLOCK), 
                   .RSTN(RST_N), 
//                   .COMMA_DETECT(w2d_cd[IO_SIZE]), 
                   .K(K_OUT[IO_SIZE]), 
                   .RX_WORD(DATA_OUT[ENDEC_DWIDTH-1:ENDEC_DWIDTH-8]), 
                   .CODE_ERROR_L(VALID_OUT_int[IO_SIZE]), 
//                   .WORD_SYNC_L(d2w_ws[IO_SIZE]), 
//                   .COMMA_DETECT_ENABLE(d2w_cde[IO_SIZE]), 
                   .RD_ERR(DISP_ERR_int[IO_SIZE]), 
                   .B_CERR(NIT_ERR_int[IO_SIZE]), 
                   .RD_IN(rd_in_u), 
                   .RD_OUT(rd_u2l)
);

cpcs_decoder_ci  #( .PROG_COMMA_EN(PROG_COMMA_EN),
                    .SYNC_RESET(SYNC_RESET))
   cpcs_decoder_ci_0( .RX_DATA({W2D_DATA[EPCS_DWIDTH-20], W2D_DATA[EPCS_DWIDTH-19], W2D_DATA[EPCS_DWIDTH-18], W2D_DATA[EPCS_DWIDTH-17], W2D_DATA[EPCS_DWIDTH-16], 
                                W2D_DATA[EPCS_DWIDTH-15], W2D_DATA[EPCS_DWIDTH-14], W2D_DATA[EPCS_DWIDTH-13], W2D_DATA[EPCS_DWIDTH-12], W2D_DATA[EPCS_DWIDTH-11]}), 
                    .RBC1(CLOCK), 
                    .RSTN(RST_N), 
//                    .COMMA_DETECT(w2d_cd[IO_SIZE-1]), 
                    .K(K_OUT[IO_SIZE-1]), 
                    .RX_WORD(DATA_OUT[ENDEC_DWIDTH-9:ENDEC_DWIDTH-16]), 
                    .CODE_ERROR_L(VALID_OUT_int[IO_SIZE-1]),
//                    .WORD_SYNC_L(d2w_ws[IO_SIZE-1]), 
//                    .COMMA_DETECT_ENABLE(d2w_cde[IO_SIZE-1]), 
                    .RD_ERR(DISP_ERR_int[IO_SIZE-1]), 
                    .B_CERR(NIT_ERR_int[IO_SIZE-1]), 
                    .RD_IN(rd_u2l), 
                    .RD_OUT(rd_l2l[0])
);

generate
if(ENDEC_DWIDTH >= 32)
  begin
    cpcs_decoder_ci  #( .PROG_COMMA_EN(PROG_COMMA_EN),
                        .SYNC_RESET(SYNC_RESET))
       cpcs_decoder_ci_1( .RX_DATA({W2D_DATA[EPCS_DWIDTH-30], W2D_DATA[EPCS_DWIDTH-29], W2D_DATA[EPCS_DWIDTH-28], W2D_DATA[EPCS_DWIDTH-27], W2D_DATA[EPCS_DWIDTH-26], 
                                    W2D_DATA[EPCS_DWIDTH-25], W2D_DATA[EPCS_DWIDTH-24], W2D_DATA[EPCS_DWIDTH-23], W2D_DATA[EPCS_DWIDTH-22], W2D_DATA[EPCS_DWIDTH-21]}), 
                        .RBC1(CLOCK), 
                        .RSTN(RST_N), 
//                        .COMMA_DETECT(w2d_cd[IO_SIZE-2]), 
                        .K(K_OUT[IO_SIZE-2]), 
                        .RX_WORD(DATA_OUT[ENDEC_DWIDTH-17:ENDEC_DWIDTH-24]), 
                        .CODE_ERROR_L(VALID_OUT_int[IO_SIZE-2]),
//                        .WORD_SYNC_L(d2w_ws[IO_SIZE-2]), 
//                        .COMMA_DETECT_ENABLE(d2w_cde[IO_SIZE-2]), 
                        .RD_ERR(DISP_ERR_int[IO_SIZE-2]), 
                        .B_CERR(NIT_ERR_int[IO_SIZE-2]), 
                        .RD_IN(rd_l2l[0]), 
                        .RD_OUT(rd_l2l[1])
    );
    
    
    cpcs_decoder_ci  #( .PROG_COMMA_EN(PROG_COMMA_EN),
                        .SYNC_RESET(SYNC_RESET))
       cpcs_decoder_ci_2( .RX_DATA({W2D_DATA[EPCS_DWIDTH-40], W2D_DATA[EPCS_DWIDTH-39], W2D_DATA[EPCS_DWIDTH-38], W2D_DATA[EPCS_DWIDTH-37], W2D_DATA[EPCS_DWIDTH-36], 
                                    W2D_DATA[EPCS_DWIDTH-35], W2D_DATA[EPCS_DWIDTH-34], W2D_DATA[EPCS_DWIDTH-33], W2D_DATA[EPCS_DWIDTH-32], W2D_DATA[EPCS_DWIDTH-31]}), 
                        .RBC1(CLOCK), 
                        .RSTN(RST_N), 
//                        .COMMA_DETECT(w2d_cd[IO_SIZE-3]), 
                        .K(K_OUT[IO_SIZE-3]), 
                        .RX_WORD(DATA_OUT[ENDEC_DWIDTH-25:ENDEC_DWIDTH-32]), 
                        .CODE_ERROR_L(VALID_OUT_int[IO_SIZE-3]),
//                        .WORD_SYNC_L(d2w_ws[IO_SIZE-3]), 
//                        .COMMA_DETECT_ENABLE(d2w_cde[IO_SIZE-3]), 
                        .RD_ERR(DISP_ERR_int[IO_SIZE-3]), 
                        .B_CERR(NIT_ERR_int[IO_SIZE-3]), 
                        .RD_IN(rd_l2l[1]), 
                        .RD_OUT(rd_l2l[2])
    );
  end
endgenerate

generate
if(ENDEC_DWIDTH == 64)
  begin
    cpcs_decoder_ci  #( .PROG_COMMA_EN(PROG_COMMA_EN),
                        .SYNC_RESET(SYNC_RESET))
       cpcs_decoder_ci_3( .RX_DATA({W2D_DATA[EPCS_DWIDTH-50], W2D_DATA[EPCS_DWIDTH-49], W2D_DATA[EPCS_DWIDTH-48], W2D_DATA[EPCS_DWIDTH-47], W2D_DATA[EPCS_DWIDTH-46], 
                                    W2D_DATA[EPCS_DWIDTH-45], W2D_DATA[EPCS_DWIDTH-44], W2D_DATA[EPCS_DWIDTH-43], W2D_DATA[EPCS_DWIDTH-42], W2D_DATA[EPCS_DWIDTH-41]}), 
                        .RBC1(CLOCK), 
                        .RSTN(RST_N), 
//                        .COMMA_DETECT(w2d_cd[IO_SIZE-4]), 
                        .K(K_OUT[IO_SIZE-4]), 
                        .RX_WORD(DATA_OUT[ENDEC_DWIDTH-33:ENDEC_DWIDTH-40]), 
                        .CODE_ERROR_L(VALID_OUT_int[IO_SIZE-4]),
//                        .WORD_SYNC_L(d2w_ws[IO_SIZE-4]), 
//                        .COMMA_DETECT_ENABLE(d2w_cde[IO_SIZE-4]), 
                        .RD_ERR(DISP_ERR_int[IO_SIZE-4]), 
                        .B_CERR(NIT_ERR_int[IO_SIZE-4]), 
                        .RD_IN(rd_l2l[2]), 
                        .RD_OUT(rd_l2l[3])
    );
    
    
    cpcs_decoder_ci  #( .PROG_COMMA_EN(PROG_COMMA_EN),
                        .SYNC_RESET(SYNC_RESET))
       cpcs_decoder_ci_4( .RX_DATA({W2D_DATA[EPCS_DWIDTH-60], W2D_DATA[EPCS_DWIDTH-59], W2D_DATA[EPCS_DWIDTH-58], W2D_DATA[EPCS_DWIDTH-57], W2D_DATA[EPCS_DWIDTH-56], 
                                    W2D_DATA[EPCS_DWIDTH-55], W2D_DATA[EPCS_DWIDTH-54], W2D_DATA[EPCS_DWIDTH-53], W2D_DATA[EPCS_DWIDTH-52], W2D_DATA[EPCS_DWIDTH-51]}), 
                        .RBC1(CLOCK), 
                        .RSTN(RST_N), 
//                        .COMMA_DETECT(w2d_cd[IO_SIZE-5]), 
                        .K(K_OUT[IO_SIZE-5]), 
                        .RX_WORD(DATA_OUT[ENDEC_DWIDTH-41:ENDEC_DWIDTH-48]), 
                        .CODE_ERROR_L(VALID_OUT_int[IO_SIZE-5]),
//                        .WORD_SYNC_L(d2w_ws[IO_SIZE-5]), 
//                        .COMMA_DETECT_ENABLE(d2w_cde[IO_SIZE-5]), 
                        .RD_ERR(DISP_ERR_int[IO_SIZE-5]), 
                        .B_CERR(NIT_ERR_int[IO_SIZE-5]), 
                        .RD_IN(rd_l2l[3]), 
                        .RD_OUT(rd_l2l[4])
    );
    
    
    cpcs_decoder_ci  #( .PROG_COMMA_EN(PROG_COMMA_EN),
                        .SYNC_RESET(SYNC_RESET))
       cpcs_decoder_ci_5( .RX_DATA({W2D_DATA[EPCS_DWIDTH-70], W2D_DATA[EPCS_DWIDTH-69], W2D_DATA[EPCS_DWIDTH-68], W2D_DATA[EPCS_DWIDTH-67], W2D_DATA[EPCS_DWIDTH-66], 
                                    W2D_DATA[EPCS_DWIDTH-65], W2D_DATA[EPCS_DWIDTH-64], W2D_DATA[EPCS_DWIDTH-63], W2D_DATA[EPCS_DWIDTH-62], W2D_DATA[EPCS_DWIDTH-61]}), 
                        .RBC1(CLOCK), 
                        .RSTN(RST_N), 
//                        .COMMA_DETECT(w2d_cd[IO_SIZE-6]), 
                        .K(K_OUT[IO_SIZE-6]), 
                        .RX_WORD(DATA_OUT[ENDEC_DWIDTH-49:ENDEC_DWIDTH-56]), 
                        .CODE_ERROR_L(VALID_OUT_int[IO_SIZE-6]),
//                        .WORD_SYNC_L(d2w_ws[IO_SIZE-6]), 
//                        .COMMA_DETECT_ENABLE(d2w_cde[IO_SIZE-6]), 
                        .RD_ERR(DISP_ERR_int[IO_SIZE-6]), 
                        .B_CERR(NIT_ERR_int[IO_SIZE-6]), 
                        .RD_IN(rd_l2l[4]), 
                        .RD_OUT(rd_l2l[5])
    );
    
    cpcs_decoder_ci  #( .PROG_COMMA_EN(PROG_COMMA_EN),
                        .SYNC_RESET(SYNC_RESET))
       cpcs_decoder_ci_6( .RX_DATA({W2D_DATA[EPCS_DWIDTH-80], W2D_DATA[EPCS_DWIDTH-79], W2D_DATA[EPCS_DWIDTH-78], W2D_DATA[EPCS_DWIDTH-77], W2D_DATA[EPCS_DWIDTH-76], 
                                    W2D_DATA[EPCS_DWIDTH-75], W2D_DATA[EPCS_DWIDTH-74], W2D_DATA[EPCS_DWIDTH-73], W2D_DATA[EPCS_DWIDTH-72], W2D_DATA[EPCS_DWIDTH-71]}), 
                        .RBC1(CLOCK), 
                        .RSTN(RST_N), 
//                        .COMMA_DETECT(w2d_cd[IO_SIZE-7]), 
                        .K(K_OUT[IO_SIZE-7]), 
                        .RX_WORD(DATA_OUT[ENDEC_DWIDTH-57:ENDEC_DWIDTH-64]), 
                        .CODE_ERROR_L(VALID_OUT_int[IO_SIZE-7]),
//                        .WORD_SYNC_L(d2w_ws[IO_SIZE-7]), 
//                        .COMMA_DETECT_ENABLE(d2w_cde[IO_SIZE-7]), 
                        .RD_ERR(DISP_ERR_int[IO_SIZE-7]), 
                        .B_CERR(NIT_ERR_int[IO_SIZE-7]), 
                        .RD_IN(rd_l2l[5]), 
                        .RD_OUT(rd_l2l[6])
    );
  end
endgenerate
    
cpcs_wa_80 #( .SHIFT_EN(SHIFT_EN),
              .PROG_COMMA_EN(PROG_COMMA_EN),
              .NO_OF_COMMAS(NO_OF_COMMAS),
              .COMMA_DETECT_SEL(COMMA_DETECT_SEL),
              .SYNC_RESET(SYNC_RESET),
              .EPCS_DWIDTH(EPCS_DWIDTH))
  cpcs_wa_80( .CLK(CLOCK),
              .RST_N(WA_RST_n),
              .DATA_IN(data_rev),
              .WA_DATA(W2D_DATA), 
              .CODE_ERROR(VALID_OUT_int),
//              .WRD_SYNC(d2w_ws),
//              .CDE(d2w_cde),
//              .COMMA_DETECT(w2d_cd),
              .ALIGNED(ALIGNED),
              .EXPD_ERR(EXPD_ERR)
);


endmodule
