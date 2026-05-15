//
// FILE................: cpcs_enc_flip.VHD 
// FUNCTION............: 8B10B DATA DISPARITY INVERSION LOGIC
// PERSON RESPONSIBLE..: JOEL LANDRY
// ORIGINATOR..........: DAN ELFTMANN 
// VERSION.............: 1.0 
// LAST UPDATED........: 01/01/00 
// COMPONENT OF........: ENCODER.VHD 
// COMPONENTS REQUIRED.: NONE 
// COMPILATION NOTES...: 
// 
// REVISION HISTORY: 
//     
//     
// COPYRIGHT 1999 BY ACTEL 
// THE INFORMATION CONTAINED IN THIS DOCUMENT IS SUBJECT TO LICENSING RESTRICTIONS FROM ACTEL 
// CORP.  IF YOU ARE NOT IN POSSESSION OF WRITTEN AUTHORIZATION FROM ACTEL FOR USE OF THIS FILE, 
// THEN THE FILE SHOULD BE IMMEDIATELY DESTROYED AND NO BACK-UP OF THE FILE SHOULD BE MADE. 
// 
// 
//
// 
// EACH MODULE cpcs_enc_flip/cpcs_enc_k/cpcs_enc_d IS ALLOWED TWO LEVELS OF REGISTERS,
// AND THE ALL OUTPUTS MUST COME DIRECTLY FROM THE SECOND STAGE.
//
module cpcs_enc_flip (CLK, RST_N, D, FLIP_RD, EN_INV_6B, EN_INV_4B, INV_4B_RD)/* synthesis syn_preserve = 1 */;

   parameter SYNC_RESET = 0;

   input CLK;
   input RST_N;
   input[7:0] D;
   output FLIP_RD;
   reg FLIP_RD;
   output EN_INV_6B;
   reg EN_INV_6B;
   output EN_INV_4B;
   reg EN_INV_4B;
   output INV_4B_RD;
   reg INV_4B_RD;

   wire[2:0] Y; 
   wire[4:0] X; 
   reg Y_0_4_7; 
   reg X_FLIP0; 
   reg X_FLIP1; 
   reg X_7; 
   reg Y_3; 
   wire aresetn;
   wire sresetn; 
   assign aresetn = (SYNC_RESET==1) ? 1'b1 : RST_N;
   assign sresetn = (SYNC_RESET==1) ? RST_N : 1'b1;
   assign Y = D[7:5] ; 
   assign X = D[4:0] ; 

   always @(posedge CLK or negedge aresetn)
   begin
      if((!aresetn) || (!sresetn))
        begin
           Y_0_4_7 <= 1'b0 ; 
           X_FLIP0 <= 1'b0 ; 
           X_FLIP1 <= 1'b0 ; 
           X_7 <= 1'b0 ; 
           Y_3 <= 1'b0 ; 
        end
      else
        begin
           if (Y == 3'b000 | Y == 3'b100 | Y == 3'b111)
             begin
                Y_0_4_7 <= 1'b1 ; 
             end
           else
             begin
                Y_0_4_7 <= 1'b0 ; 
             end 
           if (X < 5'b00011 | X > 5'b11100)
             begin
                X_FLIP0 <= 1'b1 ; 
             end
           else
             begin
                X_FLIP0 <= 1'b0 ; 
             end 
           if (X == 5'b00100 | X == 5'b01000 | X == 5'b01111 | X == 5'b10000 | X == 5'b10111 | X == 5'b11000 | X == 5'b11011)
             begin
                X_FLIP1 <= 1'b1 ; 
             end
           else
             begin
                X_FLIP1 <= 1'b0 ; 
             end 
           X_7 <= ~X[4] & ~X[3] & X[2] & X[1] & X[0] ; 
           Y_3 <= ~Y[2] & Y[1] & Y[0] ; 
        end 
   end 

   always @(posedge CLK or negedge aresetn)
   begin
      if((!aresetn) || (!sresetn))
      begin
         FLIP_RD <= 1'b0 ; 
         EN_INV_6B <= 1'b0 ; 
         EN_INV_4B <= 1'b0 ; 
         INV_4B_RD <= 1'b0 ; 
      end
      else
      begin
         FLIP_RD <= (~Y_0_4_7 & (X_FLIP0 | X_FLIP1)) | (Y_0_4_7 & ~(X_FLIP0 |
         X_FLIP1)) ; 
         EN_INV_6B <= (X_FLIP0 | X_FLIP1) | X_7 ; 
         EN_INV_4B <= Y_0_4_7 | Y_3 ; 
         INV_4B_RD <= (X_FLIP0 | X_FLIP1) ; 
      end 
   end 
endmodule
