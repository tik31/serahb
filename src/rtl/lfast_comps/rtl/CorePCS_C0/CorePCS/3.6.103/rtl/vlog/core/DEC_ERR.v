//
// FILE................: cpcs_dec_err.VHD 
// FUNCTION............: DECODE ERROR AND DISPARITY LOGIC
// PERSON RESPONSIBLE..: JOEL LANDRY
// ORIGINATOR..........: DAN ELFTMANN 
// VERSION.............: 1.0 
// LAST UPDATED........: 01/01/00 
// COMPONENT OF........: DEC_DATA.VHD 
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
module cpcs_dec_err (ABCDEI_FGHJ, PD6BU, ND6BU, PD6BC, ND6BC, PD4BU, ND4BU, PD4BC,
ND4BC, CERR);

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
   
   wire PD6BU;
   wire ND6BU;
   wire PD6BC;
   wire ND6BC;
   wire PD4BU;
   wire ND4BU;
   wire PD4BC;
   wire ND4BC;
   wire CERR;

   wire PD6BU_INT; 
   wire ND6BU_INT; 
   wire PD6BC_INT; 
   wire ND6BC_INT; 
   wire PD4BU_INT; 
   wire ND4BU_INT; 
   wire PD4BC_INT; 
   wire ND4BC_INT; 
   wire CERR_INT; 
   wire A; 
   wire B; 
   wire C; 
   wire D; 
   wire E; 
   wire I; 
   wire F; 
   wire G; 
   wire H; 
   wire J; 
   reg ABCD_31; 
   reg ABCD_22; 
   reg ABCD_13; 
   wire[15:0] ERR;
//   wire[3:0] TEMP1;
//   wire[3:0] TEMP2;
//   wire[3:0] TEMP3;
   assign PD6BU = PD6BU_INT ;
   assign ND6BU = ND6BU_INT ; 
   assign PD6BC = PD6BC_INT ; 
   assign ND6BC = ND6BC_INT ; 
   assign PD4BU = PD4BU_INT ; 
   assign ND4BU = ND4BU_INT ; 
   assign PD4BC = PD4BC_INT ; 
   assign ND4BC = ND4BC_INT ; 
   assign CERR = CERR_INT ; 
   assign A = ABCDEI_FGHJ[0] ; 
   assign B = ABCDEI_FGHJ[1] ; 
   assign C = ABCDEI_FGHJ[2] ; 
   assign D = ABCDEI_FGHJ[3] ; 
   assign E = ABCDEI_FGHJ[4] ; 
   assign I = ABCDEI_FGHJ[5] ; 
   assign F = ABCDEI_FGHJ[6] ; 
   assign G = ABCDEI_FGHJ[7] ; 
   assign H = ABCDEI_FGHJ[8] ; 
   assign J = ABCDEI_FGHJ[9] ;
//   assign TEMP1 = {A, B, C, D};
//   assign TEMP2 = {A, B, C, D};
//   assign TEMP3 = {A, B, C, D};

   always @(A or B or C or D)
   begin
//      TEMP1 = {A, B, C, D};
//      case (TEMP1)
      case ({A, B, C,D})
         4'b1110 :
                  begin
                     ABCD_31 <= 1'b1 ; 
                  end
         4'b1101 :
                  begin
                     ABCD_31 <= 1'b1 ; 
                  end
         4'b1011 :
                  begin
                     ABCD_31 <= 1'b1 ; 
                  end
         4'b0111 :
                  begin
                     ABCD_31 <= 1'b1 ; 
                  end
         default :
                  begin
                     ABCD_31 <= 1'b0 ; 
                  end
      endcase 
//      TEMP2 = {A, B, C, D};
//      case (TEMP2)
      case ({A, B, C,D})
         4'b0011 :
                  begin
                     ABCD_22 <= 1'b1 ; 
                  end
         4'b0101 :
                  begin
                     ABCD_22 <= 1'b1 ; 
                  end
         4'b0110 :
                  begin
                     ABCD_22 <= 1'b1 ; 
                  end
         4'b1001 :
                  begin
                     ABCD_22 <= 1'b1 ; 
                  end
         4'b1010 :
                  begin
                     ABCD_22 <= 1'b1 ; 
                  end
         4'b1100 :
                  begin
                     ABCD_22 <= 1'b1 ; 
                  end
         default :
                  begin
                     ABCD_22 <= 1'b0 ; 
                  end
      endcase 
//      TEMP3 = {A, B, C, D};
//      case (TEMP3)
      case ({A, B, C,D})
         4'b0001 :
                  begin
                     ABCD_13 <= 1'b1 ; 
                  end
         4'b0010 :
                  begin
                     ABCD_13 <= 1'b1 ; 
                  end
         4'b0100 :
                  begin
                     ABCD_13 <= 1'b1 ; 
                  end
         4'b1000 :
                  begin
                     ABCD_13 <= 1'b1 ; 
                  end
         default :
                  begin
                     ABCD_13 <= 1'b0 ; 
                  end
      endcase 
   end 
   // 
   // RUNNING DISPARITY FOR THE SUB-BLOCKS SHALL BE CALCULATED AS FOLLOWS:
   // 
   // 1. RUNNING DISPARITY AT THE END OF ANY SUB-BLOCK IS POSITIVE IF
   //    THE SUB-BLOCK CONTAINS MORE ONES THAN ZEROS. IT IS ALSO
   //    POSITIVE AT THE END OF THE 6-BIT SUB-BLOCK IF THE 6-BIT
   //    SUB-BLOCK IS 000111, AND IT IS POSITIVE AT THE END OF THE 4-BIT
   //    SUB-BLOCK IF THE 4-BIT SUB-BLOCK IS 0011.
   //
   // 2. RUNNING DISPARITY AT THE END OF ANY SUB-BLOCK IS NEGATIVE IF
   //    THE SUB-BLOCK CONTAINS MORE ZEROS THAN ONES. IT IS ALSO
   //    NEGATIVE AT THE END OF THE 6-BIT SUB-BLOCK IF THE 6-BIT
   //    SUB-BLOCK IS 111000, AND IT IS NEGATIVE AT THE END OF THE 4-BIT
   //    SUB-BLOCK IF THE 4-BIT SUB-BLOCK IS 1100.
   //
   // 3. OTHERWISE, RUNNING DISPARITY AT THE END OF THE SUB-BLOCK IS
   //    THE SAME AS AT THE BEGINNING OF THE SUB-BLOCK.
   //
   //
   // IMPLEMENT THE DISPARITY FUNCTIONS FOR THE 5B6B ENCODER
   //  THE ?D6BU VALUES ARE USED TO CALCULATE NEXT VALUE OF RD,
   //  WHILE ?D6BC VALUES ARE USED TO DETERMINE ERRORS.
   //
   //11  4 OR MORE ONES
   //X1  4 OR MORE ONES
   //1X  4 OR MORE ONES
   assign PD6BU_INT = ((ABCD_22 & E) & I) | (ABCD_31 & I) | (ABCD_31 & E) ; 
   //00  4 OR MORE ZEROS
   //X0  4 OR MORE ZEROS
   //0X  4 OR MORE ZEROS
   assign ND6BU_INT = ((ABCD_22 & ~E) & ~I) | (ABCD_13 & ~I) | (ABCD_13 & ~E) ; 
   //00  4 OR MORE ZEROS
   //X0  4 OR MORE ZEROS
   //0X  4 OR MORE ZEROS
   //000111 SEE RULE 1
   assign PD6BC_INT = ((ABCD_22 & ~E) & ~I) | (ABCD_13 & ~I) | (ABCD_13 & ~E) | 
   (((((~A & ~B) & ~C) & D) & E) & I) ; 
   //11  4 OR MORE ONES
   //X1  4 OR MORE ONES 
   //1X  4 OR MORE ONES 
   //111000 SEE RULE 2 
   assign ND6BC_INT = ((ABCD_22 & E) & I) | (ABCD_31 & I) | (ABCD_31 & E) | 
   (((((A & B) & C) & ~D) & ~E) & ~I) ; 
   //
   // IMPLEMENT THE DISPARITY FUNCTIONS FOR THE 3B4B ENCODER
   //  THE ?D4BU VALUES ARE USED TO CALCULATE NEXT VALUE OF RD,
   //  WHILE ?D4BC VALUES ARE USED TO DETERMINE ERRORS.
   //
   //X000 3 OR MORE ZEROS
   //0X00 3 OR MORE ZEROS
   //00X0 3 OR MORE ZEROS
   //000X
   assign ND4BU_INT = ((~G & ~H) & ~J) | ((~F & ~H) & ~J) | ((~F & ~G) & ~ J) | 
   ((~F & ~G) & ~H) ; 
   //X111 3 OR MORE ONES
   //1X11 3 OR MORE ONES
   //11X1 3 OR MORE ONES
   //111X 3 OR MORE ONES
   assign PD4BU_INT = ((G & H) & J) | ((F & H) & J) | ((F & G) & J) | ((F & G) & H) ; 
   //X000 3 OR MORE ZEROS
   //0X00 3 OR MORE ZEROS
   //00X0 3 OR MORE ZEROS
   //000X 3 OR MORE ZEROS
   //0011 SEE RULE 1
   assign PD4BC_INT = ((~G & ~H) & ~J) | ((~F & ~H) & ~J) | ((~F & ~G) & ~ J) |
   ((~F & ~G) & ~H) | (((~F & ~G) & H) & J) ; 
   //X111 3 OR MORE ONES
   //1X11 3 OR MORE ONES
   //11X1 3 OR MORE ONES
   //111X 3 OR MORE ONES
   //1100 SEE RULE 2
   assign ND4BC_INT = ((G & H) & J) | ((F & H) & J) | ((F & G) & J) | ((F & G) & H) |
   (((F & G) & ~H) & ~J) ; 
   //
   // ABCDEI_FGHJ
   // 001111_0001 28 7
   // 110000_1110 28 7
   //
   //
   assign ERR[15] = ((((((((~A & ~B) & C) & D) & E) & I) & ~F) & ~G) & ~H) & J ; 
   assign ERR[14] = ((((((((A & B) & ~C) & ~D) & ~E) & ~I) & F) & G) & H)  & ~J ; 
   //
   // FROM WIDMER/FRANASZEK
   //
   // A = B = C = D
   //
   assign ERR[13] = ((A & B) & C) & D ; 
   assign ERR[12] = ~(A | B | C | D) ; 
   //
   // P13 & !E & !I
   //
   assign ERR[11] = (ABCD_13 & ~E) & ~I ; 
   //
   // P31 & E & I
   //
   assign ERR[10] = (ABCD_31 & E) & I ; 
   //
   // F = G = H = J
   //
   assign ERR[9] = ((F & G) & H) & J ; 
   assign ERR[8] = ~(F | G | H | J) ; 
   //
   // E = I = F = G = H
   //
   assign ERR[7] = (((E & I) & F) & G) & H ; 
   assign ERR[6] = ~(E | I | F | G | H) ; 
   //
   // I != E = G = H = J
   //
   assign ERR[5] = (((E & ~I) & G) & H) & J ; 
   assign ERR[4] = (((~E & I) & ~G) & ~H) & ~J ; 
   //
   //
   //
   assign ERR[3] = ((((~(((C & D) & E) | ((~C & ~D) & ~E)) & ~E) & ~I) & 
   G) & H) & J ; 
   assign ERR[2] = ((((~(((C & D) & E) | ((~C & ~D) & ~E)) & E) & I) & ~G)
   & ~H) & ~J ; 
   //
   // !P31 & E & !I & !G & !H & !J
   //
   assign ERR[1] = ((((~ABCD_31 & E) & ~I) & ~G) & ~H) & ~J ; 
   //
   // !P13 & !E & I & G & H & J
   //
   assign ERR[0] = ((((~ABCD_13 & ~E) & I) & G) & H) & J ; 
   assign CERR_INT = ERR[0] | ERR[1] | ERR[2] | ERR[3] | ERR[4] | ERR[5] |
   ERR[6] | ERR[7] | ERR[8] | ERR[9] | ERR[10] | ERR[11] | ERR[12] | ERR[13]
   | ERR[14] | ERR[15] ; 
endmodule
