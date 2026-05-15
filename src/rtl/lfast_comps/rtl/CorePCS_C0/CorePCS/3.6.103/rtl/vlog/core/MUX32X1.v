//
// FILE................: cpcs_mux32x1.VHD 
// FUNCTION............: 32:1 MUX USED BY 8B10B TRANSMIT ENCODER
// PERSON RESPONSIBLE..: JOEL LANDRY
// ORIGINATOR..........: DAN ELFTMANN 
// VERSION.............: 1.0 
// LAST UPDATED........: 01/01/00 
// COMPONENT OF........: cpcs_mux32x6.VHD 
// COMPONENTS REQUIRED.: cpcs_mux4x1.VHD 
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
module cpcs_mux32x1 (SEL, BIT0, BIT1, BIT2, BIT3, BIT4, BIT5, BIT6, BIT7, BIT8,
BIT9, BIT10, BIT11, BIT12, BIT13, BIT14, BIT15, BIT16, BIT17, BIT18, BIT19,
BIT20, BIT21, BIT22, BIT23, BIT24, BIT25, BIT26, BIT27, BIT28, BIT29, BIT30,
BIT31, Y )/* synthesis syn_preserve = 1 */;

   input[4:0] SEL;
   input BIT0;
   input BIT1;
   input BIT2;
   input BIT3;
   input BIT4;
   input BIT5;
   input BIT6;
   input BIT7;
   input BIT8;
   input BIT9;
   input BIT10;
   input BIT11;
   input BIT12;
   input BIT13;
   input BIT14;
   input BIT15;
   input BIT16;
   input BIT17;
   input BIT18;
   input BIT19;
   input BIT20;
   input BIT21;
   input BIT22;
   input BIT23;
   input BIT24;
   input BIT25;
   input BIT26;
   input BIT27;
   input BIT28;
   input BIT29;
   input BIT30;
   input BIT31;
   output Y;
   reg Y;

   //
   // TIER 3
   //
   wire SEL_HI; 
   wire T1B0; 
   wire T1B1; 
   wire T1B2; 
   wire T1B3; 
   wire T1B4; 
   wire T1B5; 
   wire T1B6; 
   wire T1B7; 
   wire T2B0; 
   wire T2B1; 
   //
   // TIER 1
   //
   cpcs_mux4x1 UT1B0 (.SEL(SEL[1:0]), .BIT0(BIT0), .BIT1(BIT1), .BIT2(BIT2), .
   BIT3(BIT3), .Y(T1B0)); 
   cpcs_mux4x1 UT1B1 (.SEL(SEL[1:0]), .BIT0(BIT4), .BIT1(BIT5), .BIT2(BIT6), .
   BIT3(BIT7), .Y(T1B1)); 
   cpcs_mux4x1 UT1B2 (.SEL(SEL[1:0]), .BIT0(BIT8), .BIT1(BIT9), .BIT2(BIT10), .
   BIT3(BIT11), .Y(T1B2)); 
   cpcs_mux4x1 UT1B3 (.SEL(SEL[1:0]), .BIT0(BIT12), .BIT1(BIT13), .BIT2(BIT14),
   .BIT3(BIT15), .Y(T1B3)); 
   cpcs_mux4x1 UT1B4 (.SEL(SEL[1:0]), .BIT0(BIT16), .BIT1(BIT17), .BIT2(BIT18),
   .BIT3(BIT19), .Y(T1B4)); 
   cpcs_mux4x1 UT1B5 (.SEL(SEL[1:0]), .BIT0(BIT20), .BIT1(BIT21), .BIT2(BIT22),
   .BIT3(BIT23), .Y(T1B5)); 
   cpcs_mux4x1 UT1B6 (.SEL(SEL[1:0]), .BIT0(BIT24), .BIT1(BIT25), .BIT2(BIT26),
   .BIT3(BIT27), .Y(T1B6)); 
   cpcs_mux4x1 UT1B7 (.SEL(SEL[1:0]), .BIT0(BIT28), .BIT1(BIT29), .BIT2(BIT30),
   .BIT3(BIT31), .Y(T1B7)); 
   //
   // TIER 2
   //
   cpcs_mux4x1 UT2B0 (.SEL(SEL[3:2]), .BIT0(T1B0), .BIT1(T1B1), .BIT2(T1B2), .
   BIT3(T1B3), .Y(T2B0)); 
   cpcs_mux4x1 UT2B1 (.SEL(SEL[3:2]), .BIT0(T1B4), .BIT1(T1B5), .BIT2(T1B6), .
   BIT3(T1B7), .Y(T2B1)); 
   assign SEL_HI = SEL[4] ; 

   always @(SEL_HI or T2B0 or T2B1)
   begin
      if (SEL_HI)
      begin
         Y = T2B1;
      end
      else
      begin
         Y = T2B0;
      end 
//      Y <= Y_VAR ;
   end 
endmodule
