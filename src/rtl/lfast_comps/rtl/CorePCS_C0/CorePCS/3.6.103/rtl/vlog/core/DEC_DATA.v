//
// FILE................: cpcs_dec_data.VHD 
// FUNCTION............: 8B10B DATA AND COMMAND DECODING
// PERSON RESPONSIBLE..: JOEL LANDRY
// ORIGINATOR..........: DAN ELFTMANN 
// VERSION.............: 1.0 
// LAST UPDATED........: 01/01/00 
// COMPONENT OF........: DECODER.VHD 
// COMPONENTS REQUIRED.: cpcs_dec_err.VHD 
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
module cpcs_dec_data (CLK, RESET_L, ABCDEI_FGHJ, PD6BU, ND6BU, PD6BC, ND6BC, PD4BU, ND4BU, PD4BC, ND4BC, CERR, K, DATA);

   parameter SYNC_RESET = 0;
 
   input CLK;
   input RESET_L;
   input[0:9] ABCDEI_FGHJ;
   output PD6BU;
   output ND6BU;
   output PD6BC;   
   output ND6BC;   
   output PD4BU;
   output ND4BU;
   output PD4BC;
   output ND4BC;  
   output CERR;
   output K;   
   output[7:0] DATA;
   
   reg PD6BU;
   reg ND6BU;
   reg PD6BC;
   reg ND6BC;
   reg PD4BU;
   reg ND4BU;
   reg PD4BC;
   reg ND4BC;
   reg CERR;
   reg K;
   reg[7:0] DATA;
   reg[0:9] ABCDEI_FGHJ_IR; 
   reg[4:0] DATA_5B; 
   reg[2:0] DATA_3B; 
   
   wire K_INT; 
   wire CERRX; 
   wire ND4BCX; 
   wire ND4BUX; 
   wire ND6BCX; 
   wire ND6BUX; 
   wire PD4BCX; 
   wire PD4BUX; 
   wire PD6BCX; 
   wire PD6BUX; 
   wire aresetn;
   wire sresetn; 
   assign aresetn = (SYNC_RESET==1) ? 1'b1 : RESET_L;
   assign sresetn = (SYNC_RESET==1) ? RESET_L : 1'b1;
   
   cpcs_dec_err UERR (.ABCDEI_FGHJ(ABCDEI_FGHJ_IR), .PD6BU(PD6BUX), .ND6BU(ND6BUX),
   .PD6BC(PD6BCX), .ND6BC(ND6BCX), .PD4BU(PD4BUX), .ND4BU(ND4BUX), .PD4BC(PD4BCX),
   .ND4BC(ND4BCX), .CERR(CERRX)); 

   // 5B DECODE FROM 6B ENCODING
   always @(ABCDEI_FGHJ_IR)
   begin
      case (ABCDEI_FGHJ_IR[0:5])
         6'b100111 :
                  begin
                     DATA_5B <= 5'b00000 ; // 00
                  end
         6'b011000 :
                  begin
                     DATA_5B <= 5'b00000 ; // 00
                  end
         6'b100010 :
                  begin
                     DATA_5B <= 5'b00001 ; // 01
                  end
         6'b011101 :
                  begin
                     DATA_5B <= 5'b00001 ; // 01
                  end
         6'b010010 :
                  begin
                     DATA_5B <= 5'b00010 ; // 02
                  end
         6'b101101 :
                  begin
                     DATA_5B <= 5'b00010 ; // 02
                  end
         6'b110001 :
                  begin
                     DATA_5B <= 5'b00011 ; // 03
                  end
         6'b001010 :
                  begin
                     DATA_5B <= 5'b00100 ; // 04
                  end
         6'b110101 :
                  begin
                     DATA_5B <= 5'b00100 ; // 04
                  end
         6'b101001 :
                  begin
                     DATA_5B <= 5'b00101 ; // 05
                  end
         6'b011001 :
                  begin
                     DATA_5B <= 5'b00110 ; // 06
                  end
         6'b111000 :
                  begin
                     DATA_5B <= 5'b00111 ; // 07
                  end
         6'b000111 :
                  begin
                     DATA_5B <= 5'b00111 ; // 07
                  end
         6'b000110 :
                  begin
                     DATA_5B <= 5'b01000 ; // 08
                  end
         6'b111001 :
                  begin
                     DATA_5B <= 5'b01000 ; // 08
                  end
         6'b100101 :
                  begin
                     DATA_5B <= 5'b01001 ; // 09
                  end
         6'b010101 :
                  begin
                     DATA_5B <= 5'b01010 ; // 10
                  end
         6'b110100 :
                  begin
                     DATA_5B <= 5'b01011 ; // 11
                  end
         6'b001101 :
                  begin
                     DATA_5B <= 5'b01100 ; // 12
                  end
         6'b101100 :
                  begin
                     DATA_5B <= 5'b01101 ; // 13
                  end
         6'b011100 :
                  begin
                     DATA_5B <= 5'b01110 ; // 14
                  end
         6'b010111 :
                  begin
                     DATA_5B <= 5'b01111 ; // 15
                  end
         6'b101000 :
                  begin
                     DATA_5B <= 5'b01111 ; // 15
                  end
         6'b100100 :
                  begin
                     DATA_5B <= 5'b10000 ; // 16
                  end
         6'b011011 :
                  begin
                     DATA_5B <= 5'b10000 ; // 16
                  end
         6'b100011 :
                  begin
                     DATA_5B <= 5'b10001 ; // 17
                  end
         6'b010011 :
                  begin
                     DATA_5B <= 5'b10010 ; // 18
                  end
         6'b110010 :
                  begin
                     DATA_5B <= 5'b10011 ; // 19
                  end
         6'b001011 :
                  begin
                     DATA_5B <= 5'b10100 ; // 20
                  end
         6'b101010 :
                  begin
                     DATA_5B <= 5'b10101 ; // 21
                  end
         6'b011010 :
                  begin
                     DATA_5B <= 5'b10110 ; // 22
                  end
         6'b111010 :
                  begin
                     DATA_5B <= 5'b10111 ; // 23
                  end
         6'b000101 :
                  begin
                     DATA_5B <= 5'b10111 ; // 23
                  end
         6'b110011 :
                  begin
                     DATA_5B <= 5'b11000 ; // 24
                  end
         6'b001100 :
                  begin
                     DATA_5B <= 5'b11000 ; // 24
                  end
         6'b100110 :
                  begin
                     DATA_5B <= 5'b11001 ; // 25
                  end
         6'b010110 :
                  begin
                     DATA_5B <= 5'b11010 ; // 26
                  end
         6'b001001 :
                  begin
                     DATA_5B <= 5'b11011 ; // 27
                  end
         6'b110110 :
                  begin
                     DATA_5B <= 5'b11011 ; // 27
                  end
         6'b110000 :
                  begin
                     DATA_5B <= 5'b11100 ; // 28
                  end
         6'b001111 :
                  begin
                     DATA_5B <= 5'b11100 ; // 28
                  end
         6'b001110 :
                  begin
                     DATA_5B <= 5'b11100 ; // 28
                  end
         6'b010001 :
                  begin
                     DATA_5B <= 5'b11101 ; // 29
                  end
         6'b101110 :
                  begin
                     DATA_5B <= 5'b11101 ; // 29
                  end
         6'b011110 :
                  begin
                     DATA_5B <= 5'b11110 ; // 30
                  end
         6'b100001 :
                  begin
                     DATA_5B <= 5'b11110 ; // 30
                  end
         6'b101011 :
                  begin
                     DATA_5B <= 5'b11111 ; // 31
                  end
         6'b010100 :
                  begin
                     DATA_5B <= 5'b11111 ; // 31
                  end
         default :
                  begin
                     DATA_5B <= 5'b00000 ; 
                  end
      endcase 
   end 

   // 3B DECODE FROM 4B ENCODING
   always @(ABCDEI_FGHJ_IR)
   begin
      case (ABCDEI_FGHJ_IR[6:9])
         4'b0001 :
                  begin
                     DATA_3B <= 3'b111 ; 
                  end
         4'b0010 :
                  begin
                     DATA_3B <= 3'b100 ; 
                  end
         4'b0011 :
                  begin
                     DATA_3B <= 3'b011 ; 
                  end
         4'b0100 :
                  begin
                     DATA_3B <= 3'b000 ; 
                  end
         4'b0101 :
                  begin
                     if (ABCDEI_FGHJ_IR[0:5] == 6'b110000)
                     begin
                        DATA_3B <= 3'b101 ; // K28.5 110000
                     end
                     else
                     begin
                        DATA_3B <= 3'b010 ; // .2
                     end 
                  end
         4'b0110 :
                  begin
                     if (ABCDEI_FGHJ_IR[0:5] == 6'b110000)
                     begin
                        DATA_3B <= 3'b001 ; // K28.1 110000
                     end
                     else
                     begin
                        DATA_3B <= 3'b110 ; // .6
                     end 
                  end
         4'b0111 :
                  begin
                     DATA_3B <= 3'b111 ; 
                  end
         4'b1000 :
                  begin
                     DATA_3B <= 3'b111 ; 
                  end
         4'b1001 :
                  begin
                     if (ABCDEI_FGHJ_IR[0:5] == 6'b110000)
                     begin
                        DATA_3B <= 3'b110 ; // K28.6 110000
                     end
                     else
                     begin
                        DATA_3B <= 3'b001 ; // .1
                     end 
                  end
         4'b1010 :
                  begin
                     if (ABCDEI_FGHJ_IR[0:5] == 6'b110000)
                     begin
                        DATA_3B <= 3'b010 ; // K28.2 110000
                     end
                     else
                     begin
                        DATA_3B <= 3'b101 ; // .5
                     end 
                  end
         4'b1011 :
                  begin
                     DATA_3B <= 3'b000 ; 
                  end
         4'b1100 :
                  begin
                     DATA_3B <= 3'b011 ; 
                  end
         4'b1101 :
                  begin
                     DATA_3B <= 3'b100 ; 
                  end
         4'b1110 :
                  begin
                     DATA_3B <= 3'b111 ; 
                  end
         default :
                  begin
                     DATA_3B <= 3'b000 ; 
                  end
      endcase 
   end 

   always @(posedge CLK or negedge aresetn)
   begin
      if ((!aresetn) || (!sresetn))
      begin
         ABCDEI_FGHJ_IR <= 10'b0000000000 ; 
         PD6BC <= 1'b0 ; 
         ND6BU <= 1'b0 ; 
         PD6BU <= 1'b0 ; 
         ND6BC <= 1'b0 ; 
         PD4BC <= 1'b0 ; 
         ND4BU <= 1'b0 ; 
         PD4BU <= 1'b0 ; 
         ND4BC <= 1'b0 ; 
         CERR <= 1'b0 ; 
         DATA <= 8'b00000000 ; 
         K <= 1'b0 ; 
      end
      else
      begin
         ABCDEI_FGHJ_IR <= ABCDEI_FGHJ ; 
         PD6BU <= PD6BUX ; 
         ND6BU <= ND6BUX ; 
         PD6BC <= PD6BCX ; 
         ND6BC <= ND6BCX ; 
         PD4BU <= PD4BUX ; 
         ND4BU <= ND4BUX ; 
         PD4BC <= PD4BCX ; 
         ND4BC <= ND4BCX ; 
         CERR <= CERRX ; 
         DATA <= {DATA_3B, DATA_5B} ; 
         K <= K_INT ; 
      end 
   end 
   //K28.? RD+
   //K28.? RD-
   //K23.7 RD+
   //K27.7 RD+
   //K29.7 RD+
   //K30.7 RD+
   //K23.7 RD-
   //K27.7 RD-
   //K29.7 RD-
   //K30.7 RD-
   assign K_INT = (ABCDEI_FGHJ_IR[2:5] == 4'b0000 | ABCDEI_FGHJ_IR[2:5] ==
   4'b1111 | ABCDEI_FGHJ_IR[0:9] == 10'b0001010111 | ABCDEI_FGHJ_IR[0:9] == 
   10'b0010010111 | ABCDEI_FGHJ_IR[0:9] == 10'b0100010111 | ABCDEI_FGHJ_IR[0:
   9] == 10'b1000010111 | ABCDEI_FGHJ_IR[0:9] == 10'b1110101000 | ABCDEI_FGHJ_IR[
   0:9] == 10'b1101101000 | ABCDEI_FGHJ_IR[0:9] == 10'b1011101000 | ABCDEI_FGHJ_IR[
   0:9] == 10'b0111101000) ? 1'b1 : 1'b0 ; 
endmodule
