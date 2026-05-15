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
// Sept12    Revision 1.0
//
// Notes:
// best viewed with tabstops set to "4"
`timescale 1 ns / 100 ps 

module cpcs_encoder64b80b ( CLK_IN,
                            RESET_N,
                            DATA_IN,
                            K_IN,
                            FORCE_DISP,
                            DISP_SEL,
                            ENC_OUT,
                            INVALID_K);
//////////////////////////////////////////////////////////////////////////////////////
///                                PARAMETER                                        //   
//////////////////////////////////////////////////////////////////////////////////////
 parameter SYNC_RESET = 0;
 parameter EPCS_DWIDTH = 20;                   
 parameter ENDEC_DWIDTH = (EPCS_DWIDTH/10) * 8;
 parameter KWIDTH       = (EPCS_DWIDTH/10);   
 
 localparam TS_L0 = (ENDEC_DWIDTH == 64) ? 13 : (ENDEC_DWIDTH == 32) ? 5 : (ENDEC_DWIDTH == 16) ? 3 : 0;    

//////////////////////////////////////////////////////////////////////////////////////
///                             INPUTS & OUTPUT                                     //   
//////////////////////////////////////////////////////////////////////////////////////
input CLK_IN;
input RESET_N;
input [ENDEC_DWIDTH-1:0] DATA_IN;
input [KWIDTH-1:0] K_IN;
input [KWIDTH-1:0] FORCE_DISP;
input [KWIDTH-1:0] DISP_SEL;
output [EPCS_DWIDTH-1:0] ENC_OUT;
output [KWIDTH-1:0] INVALID_K;
//////////////////////////////////////////////////////////////////////////////////////
///                                    WIRES                                        //   
//////////////////////////////////////////////////////////////////////////////////////
wire [(ENDEC_DWIDTH*2)-1:0] buf32_dout;
wire [(KWIDTH*2)-1:0] kbuf_out;
wire [(KWIDTH*2)-1:0] dsbuf_out;
wire [(KWIDTH*2)-1:0] fdbuf_out;
wire [KWIDTH-2:0] ENCODER_L_RD;
wire [KWIDTH-2:0] ENCODER_N_RD;
wire ENCODER_U_0_RD;
wire ENCODER_RD_IN;
wire aresetn;
wire sresetn; 

assign aresetn = (SYNC_RESET==1) ? 1'b1 : RESET_N;
assign sresetn = (SYNC_RESET==1) ? RESET_N : 1'b1;
assign ENCODER_RD_IN = (ENDEC_DWIDTH == 8) ? ENCODER_U_0_RD : ENCODER_L_RD[KWIDTH-2]; 

//////////////////////////////////////////////////////////////////////////////////////
///                                 INSTATANCES                                     //   
//////////////////////////////////////////////////////////////////////////////////////
//--------cpcs_buff_dara
cpcs_buff_data #( .SYNC_RESET(SYNC_RESET),
                  .ENDEC_DWIDTH(ENDEC_DWIDTH),
                  .KWIDTH(KWIDTH)) BUF_DATA_0 ( .clk(CLK_IN), 
                                                  .rst_n(RESET_N), 
                                                  .d_in(DATA_IN), 
                                                  .dout(buf32_dout),
                                                  .k_in(K_IN), 
                                                  .kout(kbuf_out),
                                                  .disp_sel_in(DISP_SEL),
                                                  .force_disp_in(FORCE_DISP),
                                                  .disp_sel_out(dsbuf_out),
                                                  .force_disp_out(fdbuf_out)
);

//--------cpcs_encoder_u
cpcs_encoder_u #( .SYNC_RESET(SYNC_RESET))
     ENCODER_U_0( // Inputs
                  .D           ( buf32_dout [(ENDEC_DWIDTH*2)-1:(ENDEC_DWIDTH*2)-8] ),
                  .K           ( kbuf_out[(KWIDTH*2)-1] ),
                  .CLK         ( CLK_IN ),
                  .RST_N       ( RESET_N ),
                  .RD_IN       ( ENCODER_RD_IN ),
                  // Outputs
                  .ABCDEI_FGHJ ( ENC_OUT[EPCS_DWIDTH-1:EPCS_DWIDTH-10] ),
                  .INVALID_K   ( INVALID_K[KWIDTH-1] ),
                  .RD_OUT      ( ENCODER_U_0_RD ),
					.FORCE_DISP(fdbuf_out[(KWIDTH*2)-2]),
					.DISP_SEL(dsbuf_out[(KWIDTH*2)-2])
);


generate
if(ENDEC_DWIDTH >= 16)
  begin     
    reg fdbuf_out_reg_l0;
    reg sbuf_out_reg_l0;
	wire fdbuf_out_reg_l0_int;
	wire sbuf_out_reg_l0_int ;
	
	assign fdbuf_out_reg_l0_int = (ENDEC_DWIDTH > 16) ? fdbuf_out_reg_l0 : fdbuf_out[TS_L0];
	assign sbuf_out_reg_l0_int  = (ENDEC_DWIDTH > 16) ? sbuf_out_reg_l0  : dsbuf_out[TS_L0];
	
    always @(posedge CLK_IN or negedge aresetn)
      begin
	    if((!aresetn) || (!sresetn)) begin
	        fdbuf_out_reg_l0  <= 1'b1;
	        sbuf_out_reg_l0   <= 1'b1;
		end else begin
	        fdbuf_out_reg_l0  <= fdbuf_out[TS_L0];
	        sbuf_out_reg_l0   <= dsbuf_out[TS_L0];
		end
	  end
	
    //--------cpcs_encoder_l
    cpcs_encoder_l #( .SYNC_RESET(SYNC_RESET))
         ENCODER_L_0( // Inputs
                      .D           ( buf32_dout [(ENDEC_DWIDTH*2)-9:(ENDEC_DWIDTH*2)-16]  ),
                      .K           ( kbuf_out[(KWIDTH*2)-2] ),
                      .CLK         ( CLK_IN ),
                      .RST_N       ( RESET_N ),
                      .RD_IN       ( ENCODER_U_0_RD ),
                      .RD_NEXT     ( ENCODER_N_RD[0] ),
                      // Outputs
                      .ABCDEI_FGHJ ( ENC_OUT[EPCS_DWIDTH-11:EPCS_DWIDTH-20] ),
                      .INVALID_K   ( INVALID_K[KWIDTH-2] ),
                      .RD_OUT      ( ENCODER_L_RD[0] ) ,
    					.FORCE_DISP(fdbuf_out_reg_l0_int),
    					.DISP_SEL(  sbuf_out_reg_l0_int) 
    );
    
    //--------cpcs_encoder_n
    cpcs_encoder_n #( .SYNC_RESET(SYNC_RESET)) 
         ENCODER_N_0( // Inputs
                      .D           ( buf32_dout [ENDEC_DWIDTH-1:ENDEC_DWIDTH-8] ),
                      .K           ( kbuf_out[KWIDTH-1] ),
                      .CLK         ( CLK_IN ),
                      .RST_N       ( RESET_N ),
                      .RD_IN       ( ENCODER_RD_IN ),
                      // Outputs
                      .RD_OUT      ( ENCODER_N_RD[0] ) ,
						.FORCE_DISP(fdbuf_out[(KWIDTH*2)-2]),
						.DISP_SEL  (dsbuf_out[(KWIDTH*2)-2]   )
    );
  end
endgenerate


generate
if(ENDEC_DWIDTH >= 24)
  begin            
    reg fdbuf_out_reg_l1;
    reg sbuf_out_reg_l1;
	 
    always @(posedge CLK_IN or negedge aresetn)
      begin
	    if((!aresetn) || (!sresetn)) begin
	        fdbuf_out_reg_l1  <= 1'b1;
	        sbuf_out_reg_l1   <= 1'b1;
		end else begin
	        fdbuf_out_reg_l1  <= fdbuf_out[(KWIDTH*2)-4];
	        sbuf_out_reg_l1   <= dsbuf_out[(KWIDTH*2)-4];
		end
	  end
  
    //--------cpcs_encoder_l
    cpcs_encoder_l #( .SYNC_RESET(SYNC_RESET))
         ENCODER_L_1( // Inputs
                      .D           ( buf32_dout [(ENDEC_DWIDTH*2)-17:(ENDEC_DWIDTH*2)-24]  ),
                      .K           ( kbuf_out[(KWIDTH*2)-3] ),
                      .CLK         ( CLK_IN ),
                      .RST_N       ( RESET_N ),
                      .RD_IN       ( ENCODER_L_RD[0] ),
                      .RD_NEXT     ( ENCODER_N_RD[1] ),
                      // Outputs
                      .ABCDEI_FGHJ ( ENC_OUT[EPCS_DWIDTH-21:EPCS_DWIDTH-30] ),
                      .INVALID_K   ( INVALID_K[KWIDTH-3] ),
                      .RD_OUT      ( ENCODER_L_RD[1] ) ,
    					.FORCE_DISP(fdbuf_out_reg_l1),
    					.DISP_SEL  (sbuf_out_reg_l1)
    );
    
    //--------cpcs_encoder_n
    cpcs_encoder_n #( .SYNC_RESET(SYNC_RESET)) 
         ENCODER_N_1( // Inputs
                      .D           ( buf32_dout [ENDEC_DWIDTH-9:ENDEC_DWIDTH-16] ),
                      .K           ( kbuf_out[KWIDTH-2] ),
                      .CLK         ( CLK_IN ),
                      .RST_N       ( RESET_N ),
                      .RD_IN       ( ENCODER_N_RD[0] ),
                      // Outputs
                      .RD_OUT      ( ENCODER_N_RD[1] ) ,
						.FORCE_DISP(fdbuf_out[(KWIDTH*2)-3]),
						.DISP_SEL(dsbuf_out[(KWIDTH*2)-3] )
    );
  end
endgenerate

generate
if(ENDEC_DWIDTH >= 32)
  begin        
    reg fdbuf_out_reg_l2;
    reg sbuf_out_reg_l2;
    wire fdbuf_out_reg_l2_int;
    wire sbuf_out_reg_l2_int;
	 
	assign fdbuf_out_reg_l2_int = (ENDEC_DWIDTH > 32) ? fdbuf_out_reg_l2 : fdbuf_out[KWIDTH+3];
	assign sbuf_out_reg_l2_int  = (ENDEC_DWIDTH > 32) ? sbuf_out_reg_l2  : dsbuf_out[KWIDTH+3];
	
    always @(posedge CLK_IN or negedge aresetn)
      begin
	    if((!aresetn) || (!sresetn)) begin
	        fdbuf_out_reg_l2  <= 1'b1;
	        sbuf_out_reg_l2   <= 1'b1;
		end else begin
	        fdbuf_out_reg_l2  <= fdbuf_out[KWIDTH+3];
	        sbuf_out_reg_l2   <= dsbuf_out[KWIDTH+3];
		end
	  end        
    //--------cpcs_encoder_l
    cpcs_encoder_l #( .SYNC_RESET(SYNC_RESET))
         ENCODER_L_2( // Inputs
                      .D           ( buf32_dout [(ENDEC_DWIDTH*2)-25:(ENDEC_DWIDTH*2)-32]  ),
                      .K           ( kbuf_out[(KWIDTH*2)-4] ),
                      .CLK         ( CLK_IN ),
                      .RST_N       ( RESET_N ),
                      .RD_IN       (ENCODER_L_RD[1]),
                      .RD_NEXT     ( ENCODER_N_RD[2] ),
                      // Outputs
                      .ABCDEI_FGHJ ( ENC_OUT[EPCS_DWIDTH-31:EPCS_DWIDTH-40] ),
                      .INVALID_K   ( INVALID_K[KWIDTH-4] ),
                      .RD_OUT      ( ENCODER_L_RD[2] ) ,
    					.FORCE_DISP(fdbuf_out_reg_l2_int),
    					.DISP_SEL(sbuf_out_reg_l2_int)
    );
    
    //--------cpcs_encoder_n
    cpcs_encoder_n #( .SYNC_RESET(SYNC_RESET)) 
         ENCODER_N_2( // Inputs
                      .D           ( buf32_dout [ENDEC_DWIDTH-17:ENDEC_DWIDTH-24] ),
                      .K           ( kbuf_out[KWIDTH-3] ),
                      .CLK         ( CLK_IN ),
                      .RST_N       ( RESET_N ),
                      .RD_IN       ( ENCODER_N_RD[1] ),
                      // Outputs
                      .RD_OUT      ( ENCODER_N_RD[2] ) ,
						.FORCE_DISP(fdbuf_out[(KWIDTH*2)-4]),
						.DISP_SEL(dsbuf_out[(KWIDTH*2)-4] )
    );
  end
endgenerate

generate
if(ENDEC_DWIDTH >= 40)
  begin            
    reg fdbuf_out_reg_l3;
    reg sbuf_out_reg_l3;
	 
    always @(posedge CLK_IN or negedge aresetn)
      begin
	    if((!aresetn) || (!sresetn)) begin
	        fdbuf_out_reg_l3  <= 1'b1;
	        sbuf_out_reg_l3   <= 1'b1;
		end else begin
	        fdbuf_out_reg_l3  <= fdbuf_out[(KWIDTH*2)-6];
	        sbuf_out_reg_l3   <= dsbuf_out[(KWIDTH*2)-6];
		end
	  end   
    //--------cpcs_encoder_l
    cpcs_encoder_l #( .SYNC_RESET(SYNC_RESET))
         ENCODER_L_3( // Inputs
                      .D           ( buf32_dout [(ENDEC_DWIDTH*2)-33:(ENDEC_DWIDTH*2)-40]  ),
                      .K           ( kbuf_out[(KWIDTH*2)-5] ),
                      .CLK         ( CLK_IN ),
                      .RST_N       ( RESET_N ),
                      .RD_IN       (ENCODER_L_RD[2]),
                      .RD_NEXT     ( ENCODER_N_RD[3] ),
                      // Outputs
                      .ABCDEI_FGHJ ( ENC_OUT[EPCS_DWIDTH-41:EPCS_DWIDTH-50] ),
                      .INVALID_K   ( INVALID_K[KWIDTH-5] ),
                      .RD_OUT      ( ENCODER_L_RD[3] ) ,
    					.FORCE_DISP(fdbuf_out_reg_l3),
    					.DISP_SEL(  sbuf_out_reg_l3 )
    );
    
    //--------cpcs_encoder_n
    cpcs_encoder_n #( .SYNC_RESET(SYNC_RESET)) 
         ENCODER_N_3( // Inputs
                      .D           ( buf32_dout [ENDEC_DWIDTH-25:ENDEC_DWIDTH-32] ),
                      .K           ( kbuf_out[KWIDTH-4] ),
                      .CLK         ( CLK_IN ),
                      .RST_N       ( RESET_N ),
                      .RD_IN       ( ENCODER_N_RD[2] ),
                      // Outputs
                      .RD_OUT      ( ENCODER_N_RD[3] ) ,
						.FORCE_DISP(fdbuf_out[(KWIDTH*2)-5]),
						.DISP_SEL(  dsbuf_out[(KWIDTH*2)-5] )
    );
  end
endgenerate

generate
if(ENDEC_DWIDTH >= 48)
  begin                
    reg fdbuf_out_reg_l4;
    reg sbuf_out_reg_l4;
	 
    always @(posedge CLK_IN or negedge aresetn)
      begin
	    if((!aresetn) || (!sresetn)) begin
	        fdbuf_out_reg_l4  <= 1'b1;
	        sbuf_out_reg_l4   <= 1'b1;
		end else begin
	        fdbuf_out_reg_l4  <= fdbuf_out[(KWIDTH*2)-7];
	        sbuf_out_reg_l4   <= dsbuf_out[(KWIDTH*2)-7];
		end
	  end   
    //--------cpcs_encoder_l
    cpcs_encoder_l #( .SYNC_RESET(SYNC_RESET))
         ENCODER_L_4( // Inputs
                      .D           ( buf32_dout [(ENDEC_DWIDTH*2)-41:(ENDEC_DWIDTH*2)-48]  ),
                      .K           ( kbuf_out[(KWIDTH*2)-6] ),
                      .CLK         ( CLK_IN ),
                      .RST_N       ( RESET_N ),
                      .RD_IN       (ENCODER_L_RD[3]),
                      .RD_NEXT     ( ENCODER_N_RD[4] ),
                      // Outputs
                      .ABCDEI_FGHJ ( ENC_OUT[EPCS_DWIDTH-51:EPCS_DWIDTH-60] ),
                      .INVALID_K   ( INVALID_K[KWIDTH-6] ),
                      .RD_OUT      ( ENCODER_L_RD[4] ) ,
    					.FORCE_DISP(fdbuf_out_reg_l4),
    					.DISP_SEL(  sbuf_out_reg_l4 )
    );
    
    //--------cpcs_encoder_n
    cpcs_encoder_n #( .SYNC_RESET(SYNC_RESET)) 
         ENCODER_N_4( // Inputs
                      .D           ( buf32_dout [ENDEC_DWIDTH-33:ENDEC_DWIDTH-40] ),
                      .K           ( kbuf_out[KWIDTH-5] ),
                      .CLK         ( CLK_IN ),
                      .RST_N       ( RESET_N ),
                      .RD_IN       ( ENCODER_N_RD[3] ),
                      // Outputs
                      .RD_OUT      ( ENCODER_N_RD[4] ) ,
						.FORCE_DISP(fdbuf_out[(KWIDTH*2)-6]),
						.DISP_SEL(  dsbuf_out[(KWIDTH*2)-6] )
    );
  end
endgenerate

generate
if(ENDEC_DWIDTH >= 56)
  begin                    
    reg fdbuf_out_reg_l5;
    reg sbuf_out_reg_l5;
	 
    always @(posedge CLK_IN or negedge aresetn)
      begin
	    if((!aresetn) || (!sresetn)) begin
	        fdbuf_out_reg_l5  <= 1'b1;
	        sbuf_out_reg_l5   <= 1'b1;
		end else begin
	        fdbuf_out_reg_l5  <= fdbuf_out[(KWIDTH*2)-8];
	        sbuf_out_reg_l5   <= dsbuf_out[(KWIDTH*2)-8];
		end
	  end    
    //--------cpcs_encoder_l
    cpcs_encoder_l #( .SYNC_RESET(SYNC_RESET))
         ENCODER_L_5( // Inputs
                      .D           ( buf32_dout [(ENDEC_DWIDTH*2)-49:(ENDEC_DWIDTH*2)-56]  ),
                      .K           ( kbuf_out[(KWIDTH*2)-7] ),
                      .CLK         ( CLK_IN ),
                      .RST_N       ( RESET_N ),
                      .RD_IN       (ENCODER_L_RD[4]),
                      .RD_NEXT     ( ENCODER_N_RD[5] ),
                      // Outputs
                      .ABCDEI_FGHJ ( ENC_OUT[EPCS_DWIDTH-61:EPCS_DWIDTH-70] ),
                      .INVALID_K   ( INVALID_K[KWIDTH-7] ),
                      .RD_OUT      ( ENCODER_L_RD[5] ) ,
    					.FORCE_DISP(fdbuf_out_reg_l5),
    					.DISP_SEL(  sbuf_out_reg_l5 )
    );
    
    //--------cpcs_encoder_n
    cpcs_encoder_n #( .SYNC_RESET(SYNC_RESET)) 
         ENCODER_N_5( // Inputs
                      .D           ( buf32_dout [ENDEC_DWIDTH-41:ENDEC_DWIDTH-48] ),
                      .K           ( kbuf_out[KWIDTH-6] ),
                      .CLK         ( CLK_IN ),
                      .RST_N       ( RESET_N ),
                      .RD_IN       ( ENCODER_N_RD[4] ),
                      // Outputs
                      .RD_OUT      ( ENCODER_N_RD[5] ) ,
						.FORCE_DISP(fdbuf_out[(KWIDTH*2)-7]),
						.DISP_SEL(  dsbuf_out[(KWIDTH*2)-7] )
    );
  end
endgenerate

generate
if(ENDEC_DWIDTH >= 56)
  begin                    
    //--------cpcs_encoder_l
    cpcs_encoder_l #( .SYNC_RESET(SYNC_RESET))
         ENCODER_L_6( // Inputs
                      .D           ( buf32_dout [(ENDEC_DWIDTH*2)-57:(ENDEC_DWIDTH*2)-64]  ),
                      .K           ( kbuf_out[(KWIDTH*2)-8] ),
                      .CLK         ( CLK_IN ),
                      .RST_N       ( RESET_N ),
                      .RD_IN       (ENCODER_L_RD[5]),
                      .RD_NEXT     ( ENCODER_N_RD[6] ),
                      // Outputs
                      .ABCDEI_FGHJ ( ENC_OUT[EPCS_DWIDTH-71:EPCS_DWIDTH-80] ),
                      .INVALID_K   ( INVALID_K[KWIDTH-8] ),
                      .RD_OUT      ( ENCODER_L_RD[6] ) ,
    					.FORCE_DISP(fdbuf_out[(KWIDTH*2)-1]),
    					.DISP_SEL(  dsbuf_out[(KWIDTH*2)-1])
    );
    
    //--------cpcs_encoder_n
    cpcs_encoder_n #( .SYNC_RESET(SYNC_RESET)) 
         ENCODER_N_6( // Inputs
                      .D           ( buf32_dout [ENDEC_DWIDTH-49:ENDEC_DWIDTH-56] ),
                      .K           ( kbuf_out[KWIDTH-7] ),
                      .CLK         ( CLK_IN ),
                      .RST_N       ( RESET_N ),
                      .RD_IN       ( ENCODER_N_RD[5] ),
                      // Outputs
                      .RD_OUT      ( ENCODER_N_RD[6] ) ,
						.FORCE_DISP(fdbuf_out[(KWIDTH*2)-8]),
						.DISP_SEL(  dsbuf_out[(KWIDTH*2)-8] )
    );
  end
endgenerate
endmodule
