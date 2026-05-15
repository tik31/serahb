//
// FILE................: cpcs_enc_k.VHD 
// FUNCTION............: 8B10B TRANSMIT COMMAND ENCODER
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
// EACH MODULE ENC_FLIP/cpcs_enc_k/cpcs_enc_d IS ALLOWED TWO LEVELS OF REGISTERS,
// AND THE ALL OUTPUTS MUST COME DIRECTLY FROM THE SECOND STAGE.
//
// THIS MODULE OUTPUTS THE FOLLOWING:
//
// K_SEL[1:0]-
//  PIPELINED K CHARACTER QUALIFIED BY THE FACT THAT THE 8 BIT CODE
//  REPRESENTS A VALID COMMAND CODE (REPLICATED TWICE).
//
// K_ERR
//  INDICATES THAT THE K INPUT WAS ASSERTED, BUT THE 8 BIT CODE DOES NOT 
//  REPRESENT A VALID COMMAND CODE.
//
// KCODE_6B
//  THE 6-BIT CODE FOR THE 5 BITS OF THE INPUT DATA BITS D[4:0] FOR K CODES.
//
// KCODE_4B
//  THE 4-BIT CODE FOR THE 3 BITS OF THE INPUT DATA BITS D[7:5] FOR K CODES.
//
// SP_4B_RDP
//  INDICATES SPECIAL 4 BIT CODE CASE WHEN THE RUNNING DISPARITY(RD) IS POSITIVE.
//  IF THE RD IS POSITIVE, THEN THE OUTPUT STAGE WILL FORCE THE 4 BIT CODE TO A 
//  VALUE OF 4'B1000 (FOR D CODES ONLY NOT K CODES). 
// 
// SP_4B_RDN
//  INDICATES SPECIAL 4 BIT CODE CASE WHEN THE RUNNING DISPARITY(RD) IS NEGATIVE.
//  IF THE RD IS NEGATIVE, THEN THE OUTPUT STAGE WILL FORCE THE 4 BIT CODE TO A 
//  VALUE OF 4'B0111 (FOR D CODES ONLY NOT K CODES). 
//  
//
module cpcs_enc_k (CLK, RST_N, D, K, K_SEL, K_ERR, FLIP_RD, KCODE_6B, KCODE_4B, SP_4B_RDP, SP_4B_RDN  )/* synthesis syn_preserve = 1 */;

   parameter SYNC_RESET = 0;

   input CLK;
   input RST_N;
   input[7:0] D;
   input K;
   output[1:0] K_SEL;
   reg[1:0] K_SEL;
   output K_ERR;
   reg K_ERR;
   output FLIP_RD;
   reg FLIP_RD;
   output[5:0] KCODE_6B;
   reg[5:0] KCODE_6B;
   output[3:0] KCODE_4B;
   reg[3:0] KCODE_4B;
   output SP_4B_RDP;
   reg SP_4B_RDP;
   output SP_4B_RDN;
   reg SP_4B_RDN;

   wire[2:0] Y; 
   wire[4:0] X;  
   wire aresetn;
   wire sresetn; 
   assign aresetn = (SYNC_RESET==1) ? 1'b1 : RST_N;
   assign sresetn = (SYNC_RESET==1) ? RST_N : 1'b1;
   //------------------
   // STAGE 1 REGISTERS 
   //------------------
   reg[4:0] X_DLY; //  STAGE 1 REGISTER, SIMPLY D[4:0] DELAYED  
   reg[2:0] Y_DLY; //  STAGE 1 REGISTER, SIMPLY D[7:5] DELAYED  
   // STAGE 1 REGISTER, D[4:0]==3'D18          
   // STAGE 1 REGISTER, D[4:0]==3'D17          
   // STAGE 1 REGISTER, D[4:0]==3'D14          
   // STAGE 1 REGISTER, D[4:0]==3'D13          
   // STAGE 1 REGISTER, D[4:0]==3'D11          
   // STAGE 1 REGISTER, D[7:5]==3'D7           
   // STAGE 1 REGISTER, D[7:5]=> 0,4           
   // STAGE 1 REGISTER, D[4:0]=> 29,30         
   // STAGE 1 REGISTER, D[4:0]=> 23,27         
   // STAGE 1 REGISTER, SIMPLY D[4:0]==5'D28   
   // STAGE 1 REGISTER, SIMPLY K INPUT DELAYED 
   reg K_DLY; //  STAGE 1 REGISTER, D[4:0]==3'D20          
   reg K28; //  STAGE 1 REGISTER, D[4:0]==3'D20          
   reg K23_K27; //  STAGE 1 REGISTER, D[4:0]==3'D20          
   reg K29_K30; //  STAGE 1 REGISTER, D[4:0]==3'D20          
   reg Y_EQ_0_4; //  STAGE 1 REGISTER, D[4:0]==3'D20          
   reg Y_EQ_7; //  STAGE 1 REGISTER, D[4:0]==3'D20          
   reg X_EQ_11; //  STAGE 1 REGISTER, D[4:0]==3'D20          
   reg X_EQ_13; //  STAGE 1 REGISTER, D[4:0]==3'D20          
   reg X_EQ_14; //  STAGE 1 REGISTER, D[4:0]==3'D20          
   reg X_EQ_17; //  STAGE 1 REGISTER, D[4:0]==3'D20          
   reg X_EQ_18; //  STAGE 1 REGISTER, D[4:0]==3'D20          
   reg X_EQ_20; //  STAGE 1 REGISTER, D[4:0]==3'D20          
   //-------------------
   // STAGE 2 REGISTERS 
   //-------------------
   assign Y = D[7:5] ; 
   assign X = D[4:0] ; 

   always @(posedge CLK or negedge aresetn)
   begin
      if((!aresetn) || (!sresetn))
      begin
         X_DLY <= 5'b11100 ; 
         Y_DLY <= 3'b101 ; 
         K_DLY <= 1'b1 ; 
         K28 <= 1'b1 ; 
         K23_K27 <= 1'b0 ; 
         K29_K30 <= 1'b0 ; 
         Y_EQ_0_4 <= 1'b0 ; 
         Y_EQ_7 <= 1'b0 ; 
         X_EQ_11 <= 1'b0 ; 
         X_EQ_13 <= 1'b0 ; 
         X_EQ_14 <= 1'b0 ; 
         X_EQ_17 <= 1'b0 ; 
         X_EQ_18 <= 1'b0 ; 
         X_EQ_20 <= 1'b0 ; 
      end
      else
      begin
         K_DLY <= K ; 
         X_DLY <= X ; 
         Y_DLY <= Y ; 
         K28 <= X[4] & X[3] & X[2] & ~X[1] & ~X[0] ; // 11100
         if (X == 5'b10111 | X == 5'b11011)
         begin
            K23_K27 <= 1'b1 ; 
         end
         else
         begin
            K23_K27 <= 1'b0 ; 
         end 
         if (X == 5'b11101 | X == 5'b11110)
         begin
            K29_K30 <= 1'b1 ; 
         end
         else
         begin
            K29_K30 <= 1'b0 ; 
         end 
         //000
         //100
         Y_EQ_0_4 <= ~Y[1] & ~Y[0] ; //CONV_STD_LOGIC(Y = "000" OR Y = "100"); 
         Y_EQ_7 <= Y[2] & Y[1] & Y[0] ; //CONV_STD_LOGIC(Y = "111"); -- 111
         X_EQ_11 <= ~X[4] & X[3] & ~X[2] & X[1] & X[0] ; // 01011
         X_EQ_13 <= ~X[4] & X[3] & X[2] & ~X[1] & X[0] ; // 01101
         X_EQ_14 <= ~X[4] & X[3] & X[2] & X[1] & ~X[0] ; // 01110
         X_EQ_17 <= X[4] & ~X[3] & ~X[2] & ~X[1] & X[0] ; // 10001
         X_EQ_18 <= X[4] & ~X[3] & ~X[2] & X[1] & ~X[0] ; // 10010
         X_EQ_20 <= X[4] & ~X[3] & X[2] & ~X[1] & ~X[0] ; // 10100
      end 
   end 

   always @(posedge CLK or negedge aresetn)
   begin
      if((!aresetn) || (!sresetn))
      begin
         K_SEL <= 2'b11 ; 
         K_ERR <= 1'b0 ; 
         FLIP_RD <= 1'b1 ; 
         KCODE_6B <= 6'b001111 ; 
         KCODE_4B <= 4'b0100 ; 
         SP_4B_RDP <= 1'b0 ; 
         SP_4B_RDN <= 1'b0 ; 
      end
      else
      begin
         //
         //   THE FOLLOWING TWO REGISTERS ARE IDENTICAL FOR FANOUT MANAGEMENT
         //   K_SEL WILL ONLY GET ASSERTED FOR VALID K CHARACTERS WHICH IS ALL CASES OF
         //   K28.?, K23.7, K27.7, K29.7, AND K30.7, OTHERWISE WE ASSERT K_ERR.
         //  
         //  
         K_SEL[0] <= K_DLY & (K28 | ((K23_K27 | K29_K30) & Y_EQ_7)) ; 
         K_SEL[1] <= K_DLY & (K28 | ((K23_K27 | K29_K30) & Y_EQ_7)) ; 
         K_ERR <= K_DLY & ~(K28 | ((K23_K27 | K29_K30) & Y_EQ_7)) ; 
         //
         //   THE RD FOR K CODES FLIPS FOR K28.1, K28.2, K28.3, K28.5, AND K28.6.
         //   NOTE WE DON'T QUALIFY WITH K28, BECAUSE INVALID_K WILL BE ASSERTED FOR
         //   ALL OTHER VALUES OF X.
         //  
         FLIP_RD <= ~(Y_EQ_0_4 | Y_EQ_7) ; 
         //
         //   SP_4B_RDP IS FOR D11.7, D13.7, AND D14.7
         //  
         SP_4B_RDP <= Y_EQ_7 & (X_EQ_11 | X_EQ_13 | X_EQ_14) ; 
         //
         //   SP_4B_RDP IS FOR D17.7, D18.7, AND D20.7
         //  
         SP_4B_RDN <= Y_EQ_7 & (X_EQ_17 | X_EQ_18 | X_EQ_20) ; 
         // 
         //   THE FOLLOWING CASE STATEMENTS GENERATE CODE VALUES FOR K CODES, ASSUMING
         //   THAT THE RD IS NEGATIVE.  IF THE RD IS POSITIVE THE OUTPUT STAGE WILL 
         //   SIMPLY INVERT THE ENTIRE VALUE.
         //  
         //   SEE THE 8B10B ENCODING TABLE TO FIND THE VALUES BELOW.
         //  
         case (X_DLY)
            5'b10111 :
                     begin
                        KCODE_6B <= 6'b111010 ; 
                     end
            5'b11011 :
                     begin
                        KCODE_6B <= 6'b110110 ; 
                     end
            5'b11100 :
                     begin
                        KCODE_6B <= 6'b001111 ; 
                     end
            5'b11101 :
                     begin
                        KCODE_6B <= 6'b101110 ; 
                     end
            5'b11110 :
                     begin
                        KCODE_6B <= 6'b011110 ; 
                     end
            default :
                     begin
                        KCODE_6B <= 6'b000000 ; 
                     end
         endcase 
         case (Y_DLY)
            3'b000 :
                     begin
                        KCODE_4B <= 4'b0100 ; 
                     end
            3'b001 :
                     begin
                        KCODE_4B <= 4'b1001 ; 
                     end
            3'b010 :
                     begin
                        KCODE_4B <= 4'b0101 ; 
                     end
            3'b011 :
                     begin
                        KCODE_4B <= 4'b0011 ; 
                     end
            3'b100 :
                     begin
                        KCODE_4B <= 4'b0010 ; 
                     end
            3'b101 :
                     begin
                        KCODE_4B <= 4'b1010 ; 
                     end
            3'b110 :
                     begin
                        KCODE_4B <= 4'b0110 ; 
                     end
            3'b111 :
                     begin
                        KCODE_4B <= 4'b1000 ; 
                     end
            default :
                     begin
                        KCODE_4B <= 4'b0000 ; 
                     end
         endcase 
      end 
   end 
endmodule
