//
// FILE................: cpcs_enc_d.VHD 
// FUNCTION............: 8B10B TRANSMIT DATA ENCODER
// PERSON RESPONSIBLE..: JOEL LANDRY
// ORIGINATOR..........: DAN ELFTMANN 
// VERSION.............: 1.0 
// LAST UPDATED........: 01/01/00 
// COMPONENT OF........: ENCODER.VHD 
// COMPONENTS REQUIRED.: cpcs_mux32x6.VHD 
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
module cpcs_enc_d (D, CLK, RST_N, DCODE_6B, DCODE_4B)/* synthesis syn_preserve = 1 */;

   parameter SYNC_RESET = 0;

   input[7:0] D;
   input CLK;
   input RST_N;
   output[5:0] DCODE_6B;
   wire[5:0] DCODE_6B;
   output[3:0] DCODE_4B;
   reg[3:0] DCODE_4B;

   //
   // TABLE FOR 6B CODE CALCULATION
   //
   reg[2:0] Y; 
   wire[5:0] WORD0; 
   wire[5:0] WORD1; 
   wire[5:0] WORD2; 
   wire[5:0] WORD3; 
   wire[5:0] WORD4; 
   wire[5:0] WORD5; 
   wire[5:0] WORD6; 
   wire[5:0] WORD7; 
   wire[5:0] WORD8; 
   wire[5:0] WORD9; 
   wire[5:0] WORD10; 
   wire[5:0] WORD11; 
   wire[5:0] WORD12; 
   wire[5:0] WORD13; 
   wire[5:0] WORD14; 
   wire[5:0] WORD15; 
   wire[5:0] WORD16; 
   wire[5:0] WORD17; 
   wire[5:0] WORD18; 
   wire[5:0] WORD19; 
   wire[5:0] WORD20; 
   wire[5:0] WORD21; 
   wire[5:0] WORD22; 
   wire[5:0] WORD23; 
   wire[5:0] WORD24; 
   wire[5:0] WORD25; 
   wire[5:0] WORD26; 
   wire[5:0] WORD27; 
   wire[5:0] WORD28; 
   wire[5:0] WORD29; 
   wire[5:0] WORD30; 
   wire[5:0] WORD31; 
   wire aresetn;
   wire sresetn; 
   
   assign aresetn = (SYNC_RESET==1) ? 1'b1 : RST_N;
   assign sresetn = (SYNC_RESET==1) ? RST_N : 1'b1;
   assign WORD0  = 6'b100111;
   assign WORD1  = 6'b011101;
   assign WORD2  = 6'b101101;
   assign WORD3  = 6'b110001;
   assign WORD4  = 6'b110101;
   assign WORD5  = 6'b101001;
   assign WORD6  = 6'b011001;
   assign WORD7  = 6'b111000;
   assign WORD8  = 6'b111001;
   assign WORD9  = 6'b100101;
   assign WORD10 = 6'b010101;
   assign WORD11 = 6'b110100;
   assign WORD12 = 6'b001101;
   assign WORD13 = 6'b101100;
   assign WORD14 = 6'b011100;
   assign WORD15 = 6'b010111;
   assign WORD16 = 6'b011011;
   assign WORD17 = 6'b100011;
   assign WORD18 = 6'b010011;
   assign WORD19 = 6'b110010;
   assign WORD20 = 6'b001011;
   assign WORD21 = 6'b101010;
   assign WORD22 = 6'b011010;
   assign WORD23 = 6'b111010;
   assign WORD24 = 6'b110011;
   assign WORD25 = 6'b100110;
   assign WORD26 = 6'b010110;
   assign WORD27 = 6'b110110;
   assign WORD28 = 6'b001110;
   assign WORD29 = 6'b101110;
   assign WORD30 = 6'b011110;
   assign WORD31 = 6'b101011;


   //
   // THE cpcs_mux32x6 MODULE EMULATES A 32X6 ROM LOOKUP FOR THE 5->6 BIT ENCODE OF 
   // BITS 4:0 ASSUMING A DATA CODE.  THE RESULTING 6 BIT CODE ASSUMES THAT THE 
   // RUNNING DISPARITY IS NEGATIVE.  IF THE RUNNING DISPARITY THE VALUE WILL GET
   // INVERTED, IF NEEDED.  THE 6 BIT CODE WILL BE INVERTED IF X IS IN THE 
   // FOLLOWING RANGE:
   //
   //  <3,4,7,8,15,16,23,24,27,>28
   //
   cpcs_mux32x6 #( .SYNC_RESET(SYNC_RESET)) URN (.CLK(CLK), .RST_N(RST_N), .SEL(D[4:0]), .WORD0(WORD0), .WORD1(
   WORD1), .WORD2(WORD2), .WORD3(WORD3), .WORD4(WORD4), .WORD5(WORD5), .WORD6(
   WORD6), .WORD7(WORD7), .WORD8(WORD8), .WORD9(WORD9), .WORD10(WORD10), .WORD11(
   WORD11), .WORD12(WORD12), .WORD13(WORD13), .WORD14(WORD14), .WORD15(WORD15),
   .WORD16(WORD16), .WORD17(WORD17), .WORD18(WORD18), .WORD19(WORD19), .WORD20(
   WORD20), .WORD21(WORD21), .WORD22(WORD22), .WORD23(WORD23), .WORD24(WORD24),
   .WORD25(WORD25), .WORD26(WORD26), .WORD27(WORD27), .WORD28(WORD28), .WORD29(
   WORD29), .WORD30(WORD30), .WORD31(WORD31), .YREG(DCODE_6B)); 

   always @(posedge CLK or negedge aresetn)
   begin
      if((!aresetn) || (!sresetn))
      begin
         Y <= 3'b000 ; 
      end
      else
      begin
         Y <= D[7:5] ; 
      end 
   end 

   always @(posedge CLK or negedge aresetn)
   begin
      if((!aresetn) || (!sresetn))
      begin
         DCODE_4B <= 4'b0000 ; 
      end
      else
      begin
         // IN SPECIAL CASE WITH D11.7/D13.7/D14.7 WHEN RD IS 
         // POSITIVE THE VALUE BECOMES 4'B1000
         case (Y)
            3'b000 :
                     begin
                        DCODE_4B <= 4'b0100 ; //  GETS INVERTED BY FLIP_4B IF RD+
                     end
            3'b001 :
                     begin
                        DCODE_4B <= 4'b1001 ; //  NEVER GETS INVERTED
                     end
            3'b010 :
                     begin
                        DCODE_4B <= 4'b0101 ; //  NEVER GETS INVERTED
                     end
            3'b011 :
                     begin
                        DCODE_4B <= 4'b0011 ; //  GETS INVERTED BY FLIP_4B IF RD+
                     end
            3'b100 :
                     begin
                        DCODE_4B <= 4'b0010 ; //  GETS INVERTED BY FLIP_4B IF RD+
                     end
            3'b101 :
                     begin
                        DCODE_4B <= 4'b1010 ; //  NEVER GETS INVERTED
                     end
            3'b110 :
                     begin
                        DCODE_4B <= 4'b0110 ; //  NEVER GETS INVERTED
                     end
            default :
                     begin
                        DCODE_4B <= 4'b0001 ; //  GETS INVERTED BY FLIP_4B IF RD+
                     end
         endcase 
      end 
   end 
endmodule
