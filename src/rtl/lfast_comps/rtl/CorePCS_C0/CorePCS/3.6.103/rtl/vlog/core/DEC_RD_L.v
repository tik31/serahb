//
// FILE................: cpcs_dec_rd.VHD 
// FUNCTION............: 8B10B RUNNING DISPARITY CHECKER
// PERSON RESPONSIBLE..: JOEL LANDRY
// ORIGINATOR..........: DAN ELFTMANN 
// VERSION.............: 1.0 
// LAST UPDATED........: 01/01/00 
// COMPONENT OF........: DECODER.VHD 
// COMPONENTS REQUIRED.: NONE 
// COMPILATION NOTES...: 
// 
// REVISION HISTORY: 
//
// 12/13/99  MODIFIED FROM THE ORIGINAL ALPHA VERSION BY ELIMINATING PIPE-LINE ON THE OUTPUTS.
//     
// COPYRIGHT 1999 BY ACTEL 
// THE INFORMATION CONTAINED IN THIS DOCUMENT IS SUBJECT TO LICENSING RESTRICTIONS FROM ACTEL 
// CORP.  IF YOU ARE NOT IN POSSESSION OF WRITTEN AUTHORIZATION FROM ACTEL FOR USE OF THIS FILE, 
// THEN THE FILE SHOULD BE IMMEDIATELY DESTROYED AND NO BACK-UP OF THE FILE SHOULD BE MADE. 
// 
// 
module cpcs_dec_rd_l (RBC1, RESET_L,B_PD6BU, B_ND6BU, B_PD6BC, B_ND6BC, B_PD4BU, B_ND4BU, B_PD4BC, B_ND4BC, B_DERR6, B_DERR4, RD_ERR, B_RD_ERR, RD_IN, RD_OUT);

   parameter SYNC_RESET = 0;
   
   input RBC1;
   input RESET_L;
   input B_PD6BU;
   input B_ND6BU;
   input B_PD6BC;
   input B_ND6BC;
   input B_PD4BU;
   input B_ND4BU;
   input B_PD4BC;
   input B_ND4BC;
   input RD_IN;
   
   output B_DERR6;
   output B_DERR4;   
   output RD_ERR;  
   output B_RD_ERR;
   output RD_OUT;
   
   wire B_DERR6;
   wire B_DERR4;
   wire RD_ERR;
   wire B_RD_ERR;

   reg RD; 
   //
   //   1        1       1       0    RD+ TO RD-
   //   1        1       0       1    RD+ TO RD+
   //   1        0       1       0    RD+ TO RD-
   //   1        0       0       1    RD+ TO RD+
   //   0        1       1       0    RD- TO RD-
   //   0        1       0       1    RD- TO RD+
   //   0        0       1       0    RD- TO RD-
   //   0        0       0       0    RD- TO RD-
   //-------------------------------------------
   //  RD     A_PD6BU A_ND6BU  A_RD6B
 
   //
   //                          V
   //      ---------------------
   //     |

   //
   //                          V
   //      ---------------------
   //     |
   wire B_RD6B; 
   //
   //                          V
   //      ---------------------
   //     |
   wire B_RD4B; 
   //
   // PREVIOUS RD WAS NEGATIVE AND A CODE WITH +RD WAS RECEIVED
   // PREVIOUS RD WAS POSITIVE AND A CODE WITH -RD WAS RECEIVED OR
   //

   wire B_DERR6X; 
   wire B_DERR4X; 

   wire RD_OUT;
   wire aresetn;
   wire sresetn; 
   
   assign aresetn = (SYNC_RESET==1) ? 1'b1 : RESET_L;
   assign sresetn = (SYNC_RESET==1) ? RESET_L : 1'b1;
   assign B_RD6B = (B_PD6BU | RD) & ~B_ND6BU ;   //A_RD4B
   assign B_RD4B = (B_PD4BU | B_RD6B) & ~B_ND4BU ; 
   assign B_DERR6X = (RD) ? B_ND6BC : B_PD6BC ; //A_RD4B 
   assign B_DERR4X = (B_RD6B) ? B_ND4BC : B_PD4BC ; 
   assign RD_OUT = B_RD4B;
   
   always @(posedge RBC1 or negedge aresetn)
     begin
       if ((!aresetn) || (!sresetn))
         begin
           RD <= 1'b0 ; 
         end
       else
         begin
           RD <= RD_IN;
         end 
     end 
    
   assign B_DERR6 = B_DERR6X ; 
   assign B_DERR4 = B_DERR4X ; 
   assign B_RD_ERR = B_DERR6X | B_DERR4X ; 
   assign RD_ERR =  B_DERR6X | B_DERR4X ; 

endmodule
