//
// FILE................: cpcs_mux32x6.VHD 
// FUNCTION............: 32:6 8B10B TRANSMIT ENCODER MUX FOR 6B DATA CODES
// PERSON RESPONSIBLE..: JOEL LANDRY
// ORIGINATOR..........: DAN ELFTMANN 
// VERSION.............: 1.0 
// LAST UPDATED........: 01/01/00 
// COMPONENT OF........: cpcs_enc_d.VHD 
// COMPONENTS REQUIRED.: cpcs_mux32x1.VHD 
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
module cpcs_mux32x6 (SEL, CLK, RST_N, WORD0, WORD1, WORD2, WORD3, WORD4, WORD5,
WORD6, WORD7, WORD8, WORD9, WORD10, WORD11, WORD12, WORD13, WORD14, WORD15,
WORD16, WORD17, WORD18, WORD19, WORD20, WORD21, WORD22, WORD23, WORD24, WORD25,
WORD26, WORD27, WORD28, WORD29, WORD30, WORD31, YREG  )/* synthesis syn_preserve = 1 */;

 parameter SYNC_RESET = 0;
 
   input[4:0] SEL;
   input CLK;
   input RST_N;
   input[5:0] WORD0;
   input[5:0] WORD1;
   input[5:0] WORD2;
   input[5:0] WORD3;
   input[5:0] WORD4;
   input[5:0] WORD5;
   input[5:0] WORD6;
   input[5:0] WORD7;
   input[5:0] WORD8;
   input[5:0] WORD9;
   input[5:0] WORD10;
   input[5:0] WORD11;
   input[5:0] WORD12;
   input[5:0] WORD13;
   input[5:0] WORD14;
   input[5:0] WORD15;
   input[5:0] WORD16;
   input[5:0] WORD17;
   input[5:0] WORD18;
   input[5:0] WORD19;
   input[5:0] WORD20;
   input[5:0] WORD21;
   input[5:0] WORD22;
   input[5:0] WORD23;
   input[5:0] WORD24;
   input[5:0] WORD25;
   input[5:0] WORD26;
   input[5:0] WORD27;
   input[5:0] WORD28;
   input[5:0] WORD29;
   input[5:0] WORD30;
   input[5:0] WORD31;
   output[5:0] YREG;
   reg[5:0] YREG;

   reg[4:0] SEL_R0; 
   reg[4:0] SEL_R1; 
   reg[1:0] SEL_R2; 
   reg[1:0] SEL_R3; 
   reg[1:0] SEL_R4; 
   reg[1:0] SEL_R5; 
   wire[5:0] Y; 
   wire[4:0] SEL0; 
   wire[4:0] SEL1; 
   wire[4:0] SEL2; 
   wire[4:0] SEL3; 
   wire[4:0] SEL4; 
   wire aresetn;
   wire sresetn; 
   assign aresetn = (SYNC_RESET==1) ? 1'b1 : RST_N;
   assign sresetn = (SYNC_RESET==1) ? RST_N : 1'b1;
   
   always @(posedge CLK or negedge aresetn)
   begin
      if ((!aresetn) || (!sresetn))
      begin
         SEL_R0 <= 5'b00000 ; 
         SEL_R1 <= 5'b00000 ; 
         SEL_R2 <= 2'b00 ; 
         SEL_R3 <= 2'b00 ; 
         SEL_R4 <= 2'b00 ; 
         SEL_R5 <= 2'b00 ; 
      end
      else
      begin
         SEL_R0 <= SEL ; 
         SEL_R1 <= SEL ; 
         SEL_R2 <= SEL[1:0] ; 
         SEL_R3 <= SEL[1:0] ; 
         SEL_R4 <= SEL[1:0] ; 
         SEL_R5 <= SEL[1:0] ; 
      end 
   end 
   cpcs_mux32x1 UB5 (.SEL(SEL_R0[4:0]), .BIT0(WORD0[5]), .BIT1(WORD1[5]), .BIT2(
   WORD2[5]), .BIT3(WORD3[5]), .BIT4(WORD4[5]), .BIT5(WORD5[5]), .BIT6(WORD6[
   5]), .BIT7(WORD7[5]), .BIT8(WORD8[5]), .BIT9(WORD9[5]), .BIT10(WORD10[5]),
   .BIT11(WORD11[5]), .BIT12(WORD12[5]), .BIT13(WORD13[5]), .BIT14(WORD14[5]),
   .BIT15(WORD15[5]), .BIT16(WORD16[5]), .BIT17(WORD17[5]), .BIT18(WORD18[5]),
   .BIT19(WORD19[5]), .BIT20(WORD20[5]), .BIT21(WORD21[5]), .BIT22(WORD22[5]),
   .BIT23(WORD23[5]), .BIT24(WORD24[5]), .BIT25(WORD25[5]), .BIT26(WORD26[5]),
   .BIT27(WORD27[5]), .BIT28(WORD28[5]), .BIT29(WORD29[5]), .BIT30(WORD30[5]),
   .BIT31(WORD31[5]), .Y(Y[5])); 
   assign SEL4 = {SEL_R0[4:2], SEL_R1[1:0]} ; 
   cpcs_mux32x1 UB4 (.SEL(SEL4), .BIT0(WORD0[4]), .BIT1(WORD1[4]), .BIT2(WORD2[
   4]), .BIT3(WORD3[4]), .BIT4(WORD4[4]), .BIT5(WORD5[4]), .BIT6(WORD6[4]), .
   BIT7(WORD7[4]), .BIT8(WORD8[4]), .BIT9(WORD9[4]), .BIT10(WORD10[4]), .BIT11(
   WORD11[4]), .BIT12(WORD12[4]), .BIT13(WORD13[4]), .BIT14(WORD14[4]), .BIT15(
   WORD15[4]), .BIT16(WORD16[4]), .BIT17(WORD17[4]), .BIT18(WORD18[4]), .BIT19(
   WORD19[4]), .BIT20(WORD20[4]), .BIT21(WORD21[4]), .BIT22(WORD22[4]), .BIT23(
   WORD23[4]), .BIT24(WORD24[4]), .BIT25(WORD25[4]), .BIT26(WORD26[4]), .BIT27(
   WORD27[4]), .BIT28(WORD28[4]), .BIT29(WORD29[4]), .BIT30(WORD30[4]), .BIT31(
   WORD31[4]), .Y(Y[4])); 
   assign SEL3 = {SEL_R0[4:2], SEL_R2[1:0]} ; 
   cpcs_mux32x1 UB3 (.SEL(SEL3), .BIT0(WORD0[3]), .BIT1(WORD1[3]), .BIT2(WORD2[
   3]), .BIT3(WORD3[3]), .BIT4(WORD4[3]), .BIT5(WORD5[3]), .BIT6(WORD6[3]), .
   BIT7(WORD7[3]), .BIT8(WORD8[3]), .BIT9(WORD9[3]), .BIT10(WORD10[3]), .BIT11(
   WORD11[3]), .BIT12(WORD12[3]), .BIT13(WORD13[3]), .BIT14(WORD14[3]), .BIT15(
   WORD15[3]), .BIT16(WORD16[3]), .BIT17(WORD17[3]), .BIT18(WORD18[3]), .BIT19(
   WORD19[3]), .BIT20(WORD20[3]), .BIT21(WORD21[3]), .BIT22(WORD22[3]), .BIT23(
   WORD23[3]), .BIT24(WORD24[3]), .BIT25(WORD25[3]), .BIT26(WORD26[3]), .BIT27(
   WORD27[3]), .BIT28(WORD28[3]), .BIT29(WORD29[3]), .BIT30(WORD30[3]), .BIT31(
   WORD31[3]), .Y(Y[3])); 
   assign SEL2 = {SEL_R1[4:2], SEL_R3[1:0]} ; 
   cpcs_mux32x1 UB2 (.SEL(SEL2), .BIT0(WORD0[2]), .BIT1(WORD1[2]), .BIT2(WORD2[
   2]), .BIT3(WORD3[2]), .BIT4(WORD4[2]), .BIT5(WORD5[2]), .BIT6(WORD6[2]), .
   BIT7(WORD7[2]), .BIT8(WORD8[2]), .BIT9(WORD9[2]), .BIT10(WORD10[2]), .BIT11(
   WORD11[2]), .BIT12(WORD12[2]), .BIT13(WORD13[2]), .BIT14(WORD14[2]), .BIT15(
   WORD15[2]), .BIT16(WORD16[2]), .BIT17(WORD17[2]), .BIT18(WORD18[2]), .BIT19(
   WORD19[2]), .BIT20(WORD20[2]), .BIT21(WORD21[2]), .BIT22(WORD22[2]), .BIT23(
   WORD23[2]), .BIT24(WORD24[2]), .BIT25(WORD25[2]), .BIT26(WORD26[2]), .BIT27(
   WORD27[2]), .BIT28(WORD28[2]), .BIT29(WORD29[2]), .BIT30(WORD30[2]), .BIT31(
   WORD31[2]), .Y(Y[2])); 
   assign SEL1 = {SEL_R1[4:2], SEL_R4[1:0]} ; 
   cpcs_mux32x1 UB1 (.SEL(SEL1), .BIT0(WORD0[1]), .BIT1(WORD1[1]), .BIT2(WORD2[
   1]), .BIT3(WORD3[1]), .BIT4(WORD4[1]), .BIT5(WORD5[1]), .BIT6(WORD6[1]), .
   BIT7(WORD7[1]), .BIT8(WORD8[1]), .BIT9(WORD9[1]), .BIT10(WORD10[1]), .BIT11(
   WORD11[1]), .BIT12(WORD12[1]), .BIT13(WORD13[1]), .BIT14(WORD14[1]), .BIT15(
   WORD15[1]), .BIT16(WORD16[1]), .BIT17(WORD17[1]), .BIT18(WORD18[1]), .BIT19(
   WORD19[1]), .BIT20(WORD20[1]), .BIT21(WORD21[1]), .BIT22(WORD22[1]), .BIT23(
   WORD23[1]), .BIT24(WORD24[1]), .BIT25(WORD25[1]), .BIT26(WORD26[1]), .BIT27(
   WORD27[1]), .BIT28(WORD28[1]), .BIT29(WORD29[1]), .BIT30(WORD30[1]), .BIT31(
   WORD31[1]), .Y(Y[1])); 
   assign SEL0 = {SEL_R1[4:2], SEL_R5[1:0]} ; 
   cpcs_mux32x1 UB0 (.SEL(SEL0), .BIT0(WORD0[0]), .BIT1(WORD1[0]), .BIT2(WORD2[
   0]), .BIT3(WORD3[0]), .BIT4(WORD4[0]), .BIT5(WORD5[0]), .BIT6(WORD6[0]), .
   BIT7(WORD7[0]), .BIT8(WORD8[0]), .BIT9(WORD9[0]), .BIT10(WORD10[0]), .BIT11(
   WORD11[0]), .BIT12(WORD12[0]), .BIT13(WORD13[0]), .BIT14(WORD14[0]), .BIT15(
   WORD15[0]), .BIT16(WORD16[0]), .BIT17(WORD17[0]), .BIT18(WORD18[0]), .BIT19(
   WORD19[0]), .BIT20(WORD20[0]), .BIT21(WORD21[0]), .BIT22(WORD22[0]), .BIT23(
   WORD23[0]), .BIT24(WORD24[0]), .BIT25(WORD25[0]), .BIT26(WORD26[0]), .BIT27(
   WORD27[0]), .BIT28(WORD28[0]), .BIT29(WORD29[0]), .BIT30(WORD30[0]), .BIT31(
   WORD31[0]), .Y(Y[0])); 

   always @(posedge CLK or negedge aresetn)
   begin
      if ((!aresetn) || (!sresetn))
      begin
         YREG <= 6'b000000 ; 
      end
      else
      begin
         YREG <= Y ; 
      end 
   end 
endmodule
