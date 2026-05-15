//
// FILE................: cpcs_mux4x1.VHD 
// FUNCTION............: 8B10B 4:1 MUX USED FOR DATA ENCODING
// PERSON RESPONSIBLE..: JOEL LANDRY
// ORIGINATOR..........: DAN ELFTMANN 
// VERSION.............: 1.0 
// LAST UPDATED........: 01/01/00 
// COMPONENT OF........: cpcs_mux32x1.VHD 
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
module cpcs_mux4x1 (SEL, BIT0, BIT1, BIT2, BIT3, Y)/* synthesis syn_preserve = 1 */;

   input[1:0] SEL;
   input BIT0;
   input BIT1;
   input BIT2;
   input BIT3;
   output Y;
   reg Y;

   always @(SEL or BIT0 or BIT1 or BIT2 or BIT3)
   begin
      case (SEL)
         2'b00 :
                  begin
                     Y = BIT0;
                  end
         2'b01 :
                  begin
                     Y = BIT1;
                  end
         2'b10 :
                  begin
                     Y = BIT2;
                  end
         default :
                  begin
                     Y = BIT3;
                  end
      endcase 
//      Y <= Y_VAR ;
   end 
endmodule
