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
module cpcs_encoder_n (D, K, CLK, RST_N, RD_IN, RD_OUT, FORCE_DISP, DISP_SEL  )/* synthesis syn_preserve = 1 */;

   parameter SYNC_RESET = 0;
   
   input[7:0] D;
   input K;
   input CLK;
   input RST_N;
   input RD_IN;
   input FORCE_DISP;
   input DISP_SEL;   //0=RD-, 1=RD+
   output RD_OUT;
   wire[1:0] K_SEL; 
   //
   //
   // K CODE AND THE D CODE, AND DETERMINES WHETHER THE RD SHOULD FLIP OR NOT.
   // THIS STAGE DETERMINES INVERSION FOR THE NEXT STAGE, SELECTS BETWEEN THE 
   //
   //
   reg FLIP_RD; 
   reg [1:0] force_disp_reg;
   reg [1:0] disp_sel_reg;
   wire NEXT_RD; 
   wire DFLIP_RD; 
   wire KFLIP_RD; 
   wire RD_OUT; 
   reg TFLIP_RD;
   wire aresetn;
   wire sresetn; 
   assign aresetn = (SYNC_RESET==1) ? 1'b1 : RST_N;
   assign sresetn = (SYNC_RESET==1) ? RST_N : 1'b1;
   //
   //
   // THESE THREE MODULES HAVE THREE STAGES INPUT->INTERMEDIATE->OUTPUT
   //
   //
   cpcs_enc_flip #( .SYNC_RESET(SYNC_RESET)) UF (.CLK(CLK), .RST_N(RST_N), .D(D), .FLIP_RD(DFLIP_RD), .EN_INV_6B(), .EN_INV_4B(), .INV_4B_RD()); 
   cpcs_enc_k    #( .SYNC_RESET(SYNC_RESET)) UK (.CLK(CLK), .RST_N(RST_N), .D(D), .K(K), .K_SEL(K_SEL), .K_ERR(), .FLIP_RD(KFLIP_RD), .KCODE_6B(), .KCODE_4B(), .SP_4B_RDP(), .SP_4B_RDN());

   assign NEXT_RD = RD_IN; 
   assign RD_OUT  = (TFLIP_RD) ? ~RD_IN : RD_IN ; 

   // Tx Disparity Delay Registers 
   always @(posedge CLK or negedge aresetn)
   begin
      if((!aresetn) || (!sresetn))
      begin
        force_disp_reg <= 2'b0;
        disp_sel_reg <= 2'b0;
      end
      else
      begin
        force_disp_reg <= {force_disp_reg[0], FORCE_DISP};
        disp_sel_reg <= {disp_sel_reg[0], DISP_SEL};
      end
   end
   
      always @(force_disp_reg or disp_sel_reg or FLIP_RD or RD_IN)
     begin
	   if(force_disp_reg[1])
	     begin
		   if(disp_sel_reg[1])
		     begin
			   if(RD_IN)
			     begin
				   TFLIP_RD <= 1'b0;
				 end
			   else
			     begin
				   TFLIP_RD <= 1'b1;
				 end
			 end
		   else
		     begin
			   if(RD_IN)
			     begin
				   TFLIP_RD <= 1'b1;
				 end
			   else
			     begin
				   TFLIP_RD <= 1'b0; 
				 end
			 end
		 end
	   else
	     begin
		   TFLIP_RD <= FLIP_RD;
		 end
	 end
   
   
   always @(posedge CLK or negedge aresetn)
   begin
      if((!aresetn) || (!sresetn))
      begin
         FLIP_RD <= 1'b0 ; 
      end
      else
      begin
         if (K_SEL[0])
         begin
            FLIP_RD <= KFLIP_RD ; 
         end
         else
         begin
            FLIP_RD <= DFLIP_RD ; 
         end 
      end 
   end 
endmodule
