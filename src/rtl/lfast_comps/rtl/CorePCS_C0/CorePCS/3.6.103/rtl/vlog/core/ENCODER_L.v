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
module cpcs_encoder_l (D, K, CLK, RST_N, ABCDEI_FGHJ, INVALID_K, RD_IN, RD_OUT, RD_NEXT, FORCE_DISP, DISP_SEL)/* synthesis syn_preserve = 1 */;

   parameter SYNC_RESET = 0;
   
   input[7:0] D;
   input K;
   input CLK;
   input RST_N;
   input RD_IN;
   input RD_NEXT;
   input FORCE_DISP;
   input DISP_SEL;   //0=RD-, 1=RD+
   output RD_OUT;
   output[0:9] ABCDEI_FGHJ;
   wire[0:9] ABCDEI_FGHJ;
   output INVALID_K;
   reg INVALID_K;

   wire[5:0] KCODE_6B; 
   wire[5:0] DCODE_6B; 
   wire[3:0] KCODE_4B; 
   wire[3:0] DCODE_4B; 
   wire[1:0] K_SEL; 
   //
   //
   // K CODE AND THE D CODE, AND DETERMINES WHETHER THE RD SHOULD FLIP OR NOT.
   // THIS STAGE DETERMINES INVERSION FOR THE NEXT STAGE, SELECTS BETWEEN THE 
   //
   //
   reg BAD_K; 
   reg INV_6B; 
   reg INV_4B; 
   reg FLIP_RD; 
   reg[5:0] CODE_6B; 
   reg[5:0] ABCDEI; 
   reg[3:0] CODE_4B; 
   reg[3:0] FGHJ; 
   reg [1:0] force_disp_reg;
   reg [1:0] disp_sel_reg;
   reg TFLIP_RD;  
   wire NEXT_RD; 
   wire K_ERR; 
   wire SP_4B_RDN; 
   wire SP_4B_RDP; 
   wire DFLIP_RD; 
   wire EN_INV_4B; 
   wire EN_INV_6B; 
   wire INV_4B_RD; 
   wire KFLIP_RD; 
   wire RD_OUT;
   wire aresetn;
   wire sresetn; 
   assign aresetn = (SYNC_RESET==1) ? 1'b1 : RST_N;
   assign sresetn = (SYNC_RESET==1) ? RST_N : 1'b1;
   //
   //
   // THESE THREE MODULES HAVE THREE STAGES INPUT->INTERMEDIATE->OUTPUT
   //
   //
   cpcs_enc_flip #( .SYNC_RESET(SYNC_RESET)) UF (.CLK(CLK), .RST_N(RST_N), .D(D), .FLIP_RD(DFLIP_RD), .EN_INV_6B(EN_INV_6B), .EN_INV_4B(EN_INV_4B), .INV_4B_RD(INV_4B_RD)); 
   cpcs_enc_k    #( .SYNC_RESET(SYNC_RESET)) UK (.CLK(CLK), .RST_N(RST_N), .D(D), .K(K), .K_SEL(K_SEL), .K_ERR(K_ERR), .FLIP_RD(KFLIP_RD), .KCODE_6B(KCODE_6B), .KCODE_4B(KCODE_4B), .SP_4B_RDP(SP_4B_RDP), .SP_4B_RDN(SP_4B_RDN));
   cpcs_enc_d    #( .SYNC_RESET(SYNC_RESET)) UD (.CLK(CLK), .RST_N(RST_N), .D(D), .DCODE_6B(DCODE_6B), .DCODE_4B(DCODE_4B)); 
   assign NEXT_RD = RD_NEXT ;
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
	   if(force_disp_reg[1]) begin
		   if(disp_sel_reg[1]) begin
			   if(RD_IN) begin
				   TFLIP_RD <= 1'b0;
			   end else begin
				   TFLIP_RD <= 1'b1;
			   end
		  end else begin
			   if(RD_IN) begin
				   TFLIP_RD <= 1'b1;
			   end else begin
				   TFLIP_RD <= 1'b0; 
			   end
		  end
	   end else begin
		   TFLIP_RD <= FLIP_RD;
	   end
	 end
	 
   always @(posedge CLK or negedge aresetn)
   begin
      if((!aresetn) || (!sresetn))
      begin
         BAD_K <= 1'b0 ; 
         INV_6B <= 1'b0 ; 
         INV_4B <= 1'b0 ; 
         CODE_6B <= 6'b001111 ; 
         CODE_4B <= 4'b0100 ; 
         ABCDEI <= 6'b001111 ; 
         FGHJ <= 4'b0100 ; 
         INVALID_K <= 1'b0 ; 
		 FLIP_RD <= 1'b0;
      end
      else
      begin
         BAD_K <= K_ERR ;
		 if (K_SEL[0])
         begin
            FLIP_RD <= KFLIP_RD ; 
         end
         else
         begin
            FLIP_RD <= DFLIP_RD ; 
         end 
         if ((K_SEL[1]))
         begin
            CODE_6B <= KCODE_6B ; 
         end
         else
         begin
            CODE_6B <= DCODE_6B ; 
         end 
         if ((K_SEL[0]))
         begin
            CODE_4B <= KCODE_4B ; 
         end
         else
         begin
            case (NEXT_RD)
               1'b0 :
                        begin
                           if (SP_4B_RDN)
                           begin
                              CODE_4B <= 4'b0111 ; 
                           end
                           else
                           begin
                              CODE_4B <= DCODE_4B ; 
                           end 
                        end
               1'b1 :
                        begin
                           if (SP_4B_RDP)
                           begin
                              CODE_4B <= 4'b1000 ; 
                           end
                           else
                           begin
                              CODE_4B <= DCODE_4B ; 
                           end 
                        end
            endcase
         end 
         if (INV_6B)
         begin
            ABCDEI <= ~CODE_6B ; 
         end
         else
         begin
            ABCDEI <= CODE_6B ; 
         end 
         if (INV_4B)
         begin
            FGHJ <= ~CODE_4B ; 
         end
         else
         begin
            FGHJ <= CODE_4B ; 
         end 
         if (K_SEL[1])
         begin
            INV_6B <= NEXT_RD ; 
         end
         else
         begin
            INV_6B <= (EN_INV_6B & NEXT_RD) ; 
         end 
         if (K_SEL[0])
         begin
            INV_4B <= NEXT_RD ; 
         end
         else
         begin
            INV_4B <= EN_INV_4B & ~(INV_4B_RD ^ NEXT_RD) & ~(SP_4B_RDP & 
            NEXT_RD) & ~(SP_4B_RDN & ~NEXT_RD) ; 
         end 
         INVALID_K <= BAD_K ; 
      end 
   end 
   //
   // MERGE THE 6B AND 4B CODES INTO ONE VECTOR (NO GATES HERE)
   //
   assign ABCDEI_FGHJ = {ABCDEI, FGHJ} ; 
   //   ABCDEI_FGHJ <= FGHJ & ABCDEI ;
endmodule
