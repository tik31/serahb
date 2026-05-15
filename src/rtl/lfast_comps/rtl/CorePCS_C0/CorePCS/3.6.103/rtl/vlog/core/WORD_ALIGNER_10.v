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
// Oct12    Revision 1.0
//
// Notes:
// best viewed with tabstops set to "4"

module cpcs_wa_10( CLK,
                     RST_N,
                     DATA_IN,
                     WA_DATA,
//                     WRD_SYNC,
//                     CDE,
                     CODE_ERROR,
//                     COMMA_DETECT,
                     ALIGNED
                    );

/////////////////////////////////////////////////////////////////////////////////
//                              PARAMETERS                                     //
/////////////////////////////////////////////////////////////////////////////////
 parameter SYNC_RESET       = 0;
 parameter COMMA_DETECT_SEL = 0;
 parameter WA_10_W          = (COMMA_DETECT_SEL == 2) ? 8 : 10;
 parameter PROG_COMMA_EN    = 0;
 parameter NO_OF_COMMAS     = 10;
 parameter COMMAS_TO_DET    = (PROG_COMMA_EN) ? NO_OF_COMMAS : 3;
 parameter POS_NUM          = 30;
 parameter CD_DELAY         = 4;
// parameter POS_NUM_CD       = 10;
 parameter WA_INIT          = 2'b00, WA_SEL = 2'b01, WA_WAIT_0 = 2'b10, WA_WAIT_1 = 2'b11;
 parameter K28_1_p          = 10'b1100000110, K28_1_n = 10'b0011111001;
 parameter K28_5_p          = 10'b1100000101, K28_5_n = 10'b0011111010;
 parameter K28_7_p          = 10'b1100000111, K28_7_n = 10'b0011111000;

 parameter COMMA_PU         = 8'b11000001, COMMA_NU = 8'b00111110;
 parameter COMMA_p_sel      = (COMMA_DETECT_SEL==0) ? K28_5_p : (COMMA_DETECT_SEL==1) ? K28_1_p : (COMMA_DETECT_SEL==3) ? K28_7_p : COMMA_PU;
 parameter COMMA_n_sel      = (COMMA_DETECT_SEL==0) ? K28_5_n : (COMMA_DETECT_SEL==1) ? K28_1_n : (COMMA_DETECT_SEL==3) ? K28_7_n : COMMA_NU;

 parameter SEL_NONE = 10'b0000000000,
           SEL_DET0 = 10'b0000000001,
           SEL_DET1 = 10'b0000000010,
           SEL_DET2 = 10'b0000000100,
           SEL_DET3 = 10'b0000001000,
           SEL_DET4 = 10'b0000010000,
           SEL_DET5 = 10'b0000100000,
           SEL_DET6 = 10'b0001000000,
           SEL_DET7 = 10'b0010000000,
           SEL_DET8 = 10'b0100000000,
           SEL_DET9 = 10'b1000000000;

 parameter[0:0] SEARCH_1 = 1'b0;//3'b000; 
//   parameter[2:0] SEARCH_2 = 3'b001; 
//   parameter[2:0] SYNC_0 = 3'b010; 
//   parameter[2:0] SYNC_1 = 3'b011; 
 parameter[0:0] SYNC_2   = 1'b1;//3'b100; 
 parameter[3:0] TRIGGER  = 4'b0100; 

/////////////////////////////////////////////////////////////////////////////////
//                          INPUTS & OUTPUTS                                   //
/////////////////////////////////////////////////////////////////////////////////
 input CLK;
 input RST_N;
 input [9:0] DATA_IN;
// input WRD_SYNC;
// input CDE;
 input CODE_ERROR;

// output COMMA_DETECT;
 output ALIGNED;
 output [9:0] WA_DATA;

/////////////////////////////////////////////////////////////////////////////////
//                        COUNTER REGS : COMMA                                 //
/////////////////////////////////////////////////////////////////////////////////
  reg [11:0] Count0;
  reg [11:0] Count1;
  reg [11:0] Count2;
  reg [11:0] Count3;
  reg [11:0] Count4;
  reg [11:0] Count5;
  reg [11:0] Count6;
  reg [11:0] Count7;
  reg [11:0] Count8;
  reg [11:0] Count9;

/////////////////////////////////////////////////////////////////////////////////
//                               OTHER REGS                                   //
/////////////////////////////////////////////////////////////////////////////////
 reg [CD_DELAY-1:0]COMMA_DETECT_reg;
 wire COMMA_DETECT_DONE;
 reg [9:0] WA_DATA;
 reg [4:0] MUX_SEL;
 reg [1:0] WA_FSM_STATE;
 reg [49:0] buff_data;
 wire [9:0] comma_p;
 wire [9:0] comma_n;
// reg [3:0] wait_cnt;
 reg ALIGNED;
 reg [19:0] comma_all_buf;

 reg[0:0] SYNC_STATE; 
 reg[3:0] ERROR_CNT; 
 reg COMMA_FOUND; 
 reg COMMA_DETECT_ENABLE;
 reg WORD_SYNC_L;
 wire ERROR; 

/////////////////////////////////////////////////////////////////////////////////
//                               OTHER WIRES                                   //
/////////////////////////////////////////////////////////////////////////////////
  reg [9:0] COUNT_HOT;
  wire CDE_int;
  wire WRD_SYNC_int;
  wire COMMA_DETECT;
  wire RST_CNT_N;
  wire [9:0] comma_all;
  wire aresetn;
  wire sresetn;

  assign aresetn = (SYNC_RESET==1) ? 1'b1 : RST_N;
  assign sresetn = (SYNC_RESET==1) ? RST_N : 1'b1;
  assign RST_CNT_N = (WA_FSM_STATE == WA_INIT) ? 1'b0 : 1'b1;
  assign COMMA_DETECT = COMMA_DETECT_reg[CD_DELAY-1];//COMMA_DETECT_int;
//  assign CDE_int = CDE;
//  assign WRD_SYNC_int = WRD_SYNC;
  assign CDE_int = COMMA_DETECT_ENABLE;
  assign WRD_SYNC_int = WORD_SYNC_L;
  assign COMMA_DETECT_DONE = (|COUNT_HOT);

/////////////////////////////////////////////////////////////////////////////////
//                               COMNA ALL                                     //
/////////////////////////////////////////////////////////////////////////////////
//  assign comma_all[0] = (comma_p[0] || comma_n[0]) ? 1'b1 : 1'b0;
//  assign comma_all[1] = (comma_p[1] || comma_n[1]) ? 1'b1 : 1'b0;
//  assign comma_all[2] = (comma_p[2] || comma_n[2]) ? 1'b1 : 1'b0;
//  assign comma_all[3] = (comma_p[3] || comma_n[3]) ? 1'b1 : 1'b0;
//  assign comma_all[4] = (comma_p[4] || comma_n[4]) ? 1'b1 : 1'b0;
//  assign comma_all[5] = (comma_p[5] || comma_n[5]) ? 1'b1 : 1'b0;
//  assign comma_all[6] = (comma_p[6] || comma_n[6]) ? 1'b1 : 1'b0;
//  assign comma_all[7] = (comma_p[7] || comma_n[7]) ? 1'b1 : 1'b0;
//  assign comma_all[8] = (comma_p[8] || comma_n[8]) ? 1'b1 : 1'b0;
//  assign comma_all[9] = (comma_p[9] || comma_n[9]) ? 1'b1 : 1'b0;

/////////////////////////////////////////////////////////////////////////////////
//                                    BUFFER                                   //
/////////////////////////////////////////////////////////////////////////////////
  always @(posedge CLK or negedge aresetn)
    begin
      if((!aresetn) || (!sresetn))
        begin
          buff_data         <= 50'b0;
          COMMA_DETECT_reg  <= {CD_DELAY{1'b0}};
//		  comma_all_buf <= 20'b0;
        end
      else
        begin
          buff_data         <= {buff_data[39:0], DATA_IN};
          COMMA_DETECT_reg  <= {COMMA_DETECT_reg[CD_DELAY-2:0],COMMA_DETECT_DONE};
//		  comma_all_buf <={comma_all_buf[9:0], comma_all};
        end
    end

/////////////////////////////////////////////////////////////////////////////////
//                           ASSIGNMENTS - COUNT_HOT                           //
/////////////////////////////////////////////////////////////////////////////////
//  assign COUNT_HOT[0] = (Count0 >= COMMAS_TO_DET) ? 1'b1 : 1'b0;
//  assign COUNT_HOT[1] = (Count1 >= COMMAS_TO_DET) ? 1'b1 : 1'b0;
//  assign COUNT_HOT[2] = (Count2 >= COMMAS_TO_DET) ? 1'b1 : 1'b0;
//  assign COUNT_HOT[3] = (Count3 >= COMMAS_TO_DET) ? 1'b1 : 1'b0;
//  assign COUNT_HOT[4] = (Count4 >= COMMAS_TO_DET) ? 1'b1 : 1'b0;
//  assign COUNT_HOT[5] = (Count5 >= COMMAS_TO_DET) ? 1'b1 : 1'b0;
//  assign COUNT_HOT[6] = (Count6 >= COMMAS_TO_DET) ? 1'b1 : 1'b0;
//  assign COUNT_HOT[7] = (Count7 >= COMMAS_TO_DET) ? 1'b1 : 1'b0;
//  assign COUNT_HOT[8] = (Count8 >= COMMAS_TO_DET) ? 1'b1 : 1'b0;
//  assign COUNT_HOT[9] = (Count9 >= COMMAS_TO_DET) ? 1'b1 : 1'b0;

/////////////////////////////////////////////////////////////////////////////////
//                                    DETECTOR                                 //
/////////////////////////////////////////////////////////////////////////////////
//    always @(posedge CLK or negedge aresetn)
//      begin
//        if((!aresetn) || (!sresetn))
//          begin
//            comma_p <= 10'b0;
//            comma_n <= 10'b0;
//          end
//        else
//          begin
          assign  comma_p[0] = COMMA_DETECT_DONE ? 1'b0 : ( buff_data[9:(10-WA_10_W)  ] == COMMA_p_sel);
          assign  comma_p[1] = COMMA_DETECT_DONE ? 1'b0 : (buff_data[10:(10-WA_10_W)+1] == COMMA_p_sel);
          assign  comma_p[2] = COMMA_DETECT_DONE ? 1'b0 : (buff_data[11:(10-WA_10_W)+2] == COMMA_p_sel);
          assign  comma_p[3] = COMMA_DETECT_DONE ? 1'b0 : (buff_data[12:(10-WA_10_W)+3] == COMMA_p_sel);
          assign  comma_p[4] = COMMA_DETECT_DONE ? 1'b0 : (buff_data[13:(10-WA_10_W)+4] == COMMA_p_sel);
          assign  comma_p[5] = COMMA_DETECT_DONE ? 1'b0 : (buff_data[14:(10-WA_10_W)+5] == COMMA_p_sel);
          assign  comma_p[6] = COMMA_DETECT_DONE ? 1'b0 : (buff_data[15:(10-WA_10_W)+6] == COMMA_p_sel);
          assign  comma_p[7] = COMMA_DETECT_DONE ? 1'b0 : (buff_data[16:(10-WA_10_W)+7] == COMMA_p_sel);
          assign  comma_p[8] = COMMA_DETECT_DONE ? 1'b0 : (buff_data[17:(10-WA_10_W)+8] == COMMA_p_sel);
          assign  comma_p[9] = COMMA_DETECT_DONE ? 1'b0 : (buff_data[18:(10-WA_10_W)+9] == COMMA_p_sel);

          assign  comma_n[0] = COMMA_DETECT_DONE ? 1'b0 : ( buff_data[9:(10-WA_10_W)  ] == COMMA_n_sel);
          assign  comma_n[1] = COMMA_DETECT_DONE ? 1'b0 : (buff_data[10:(10-WA_10_W)+1] == COMMA_n_sel);
          assign  comma_n[2] = COMMA_DETECT_DONE ? 1'b0 : (buff_data[11:(10-WA_10_W)+2] == COMMA_n_sel);
          assign  comma_n[3] = COMMA_DETECT_DONE ? 1'b0 : (buff_data[12:(10-WA_10_W)+3] == COMMA_n_sel);
          assign  comma_n[4] = COMMA_DETECT_DONE ? 1'b0 : (buff_data[13:(10-WA_10_W)+4] == COMMA_n_sel);
          assign  comma_n[5] = COMMA_DETECT_DONE ? 1'b0 : (buff_data[14:(10-WA_10_W)+5] == COMMA_n_sel);
          assign  comma_n[6] = COMMA_DETECT_DONE ? 1'b0 : (buff_data[15:(10-WA_10_W)+6] == COMMA_n_sel);
          assign  comma_n[7] = COMMA_DETECT_DONE ? 1'b0 : (buff_data[16:(10-WA_10_W)+7] == COMMA_n_sel);
          assign  comma_n[8] = COMMA_DETECT_DONE ? 1'b0 : (buff_data[17:(10-WA_10_W)+8] == COMMA_n_sel);
          assign  comma_n[9] = COMMA_DETECT_DONE ? 1'b0 : (buff_data[18:(10-WA_10_W)+9] == COMMA_n_sel);
//          end
//      end
/////////////////////////////////////////////////////////////////////////////////
//                                    COUNT0                                   //
/////////////////////////////////////////////////////////////////////////////////
  always @(posedge CLK or negedge aresetn)
    begin
      if((!aresetn) || (!sresetn) || (!RST_CNT_N))
        begin
          Count0 <= 2'b0;
          COUNT_HOT[0] <= 1'b0;
        end
      else
        begin
          if(!ALIGNED)
            begin
              //RD- and RD+ Detection
              if(Count0 < COMMAS_TO_DET)
                begin
                  if((comma_n[0] || comma_p[0]))
                    begin
                      Count0 <= Count0 + 1'b1;
                      COUNT_HOT[0] <= 1'b0;
                    end
                  else
                    begin
                      Count0 <= 2'b0;
                      COUNT_HOT[0] <= 1'b0;
                   end
                end
              else
                begin
                  Count0 <= Count0;
                  COUNT_HOT[0] <= 1'b1;
                end
            end
          else
            begin
              Count0 <= 2'b0;
              COUNT_HOT[0] <= 1'b0;
            end
        end
    end

  /////////////////////////////////////////////////////////////////////////////////
//                                   COUNT1                                    //
/////////////////////////////////////////////////////////////////////////////////
  always @(posedge CLK or negedge aresetn)
    begin
      if((!aresetn) || (!sresetn) || (!RST_CNT_N))
        begin
          Count1 <= 2'b0;
          COUNT_HOT[1] <= 1'b0;
        end
      else
        begin
          if(!ALIGNED)
            begin
              //RD- and RD+ Detection
              if(Count1 < COMMAS_TO_DET)
                begin
                  if((comma_n[1] || comma_p[1]))
                    begin
                      Count1 <= Count1 + 1'b1;
                      COUNT_HOT[1] <= 1'b0;
                    end
                  else
                    begin
                      Count1 <= 2'b0;
                      COUNT_HOT[1] <= 1'b0;
                    end
                end
              else
                begin
                  Count1 <= Count1;
                  COUNT_HOT[1] <= 1'b1;
                end
            end
          else
            begin
              Count1 <= 2'b0;
              COUNT_HOT[1] <= 1'b0;
            end
        end
    end

/////////////////////////////////////////////////////////////////////////////////
//                                   COUNT2                                    //
/////////////////////////////////////////////////////////////////////////////////
  always @(posedge CLK or negedge aresetn)
    begin
      if((!aresetn) || (!sresetn) || (!RST_CNT_N))
        begin
          Count2 <= 2'b0;
          COUNT_HOT[2] <= 1'b0;
        end
      else
        begin
          if(!ALIGNED)
            begin
              //RD- and RD+ Detection
              if(Count2 < COMMAS_TO_DET)
                begin
                  if((comma_n[2] || comma_p[2]))
                    begin
                      Count2 <= Count2 + 1'b1;
                      COUNT_HOT[2] <= 1'b0;
                    end
                  else
                    begin
                      Count2 <= 2'b0;
                      COUNT_HOT[2] <= 1'b0;
                    end
                end
              else
                begin
                  Count2 <= Count2;
                  COUNT_HOT[2] <= 1'b1;
                end
            end
          else
            begin
              Count2 <= 2'b0;
              COUNT_HOT[2] <= 1'b0;
            end
        end
    end

/////////////////////////////////////////////////////////////////////////////////
//                                   COUNT3                                    //
/////////////////////////////////////////////////////////////////////////////////
  always @(posedge CLK or negedge aresetn)
    begin
      if((!aresetn) || (!sresetn) || (!RST_CNT_N))
        begin
          Count3 <= 2'b0;
          COUNT_HOT[3] <= 1'b0;
        end
      else
        begin
          if(!ALIGNED)
            begin
              //RD- and RD+ Detection
              if(Count3 < COMMAS_TO_DET)
                begin
                  if((comma_n[3] || comma_p[3]))
                    begin
                      Count3 <= Count3 + 1'b1;
                      COUNT_HOT[3] <= 1'b0;
                    end
                  else
                    begin
                      Count3 <= 2'b0;
                      COUNT_HOT[3] <= 1'b0;
                    end
                end
              else
                begin
                  Count3 <= Count3;
                  COUNT_HOT[3] <= 1'b1;
                end
            end
          else
            begin
              Count3 <= 2'b0;
              COUNT_HOT[3] <= 1'b0;
            end
        end
    end

/////////////////////////////////////////////////////////////////////////////////
//                                   COUNT4                                    //
/////////////////////////////////////////////////////////////////////////////////
  always @(posedge CLK or negedge aresetn)
    begin
      if((!aresetn) || (!sresetn) || (!RST_CNT_N))
        begin
          Count4 <= 2'b0;
          COUNT_HOT[4] <= 1'b0;
        end
      else
        begin
          if(!ALIGNED)
            begin
              //RD- and RD+ Detection
              if(Count4 < COMMAS_TO_DET)
                begin
                  if((comma_n[4] || comma_p[4]))
                    begin
                      Count4 <= Count4 + 1'b1;
                      COUNT_HOT[4] <= 1'b0;
                    end
                  else
                    begin
                      Count4 <= 2'b0;
                      COUNT_HOT[4] <= 1'b0;
                    end
                end
              else
                begin
                  Count4 <= Count4;
                  COUNT_HOT[4] <= 1'b1;
                end
            end
          else
            begin
              Count4 <= 2'b0;
              COUNT_HOT[4] <= 1'b0;
            end
        end
    end

/////////////////////////////////////////////////////////////////////////////////
//                                   COUNT5                                    //
/////////////////////////////////////////////////////////////////////////////////
  always @(posedge CLK or negedge aresetn)
    begin
      if((!aresetn) || (!sresetn) || (!RST_CNT_N))
        begin
          Count5 <= 2'b0;
          COUNT_HOT[5] <= 1'b0;
        end
      else
        begin
          if(!ALIGNED)
            begin
              //RD- and RD+ Detection
              if(Count5 < COMMAS_TO_DET)
                begin
                  if((comma_n[5] || comma_p[5]))
                    begin
                      Count5 <= Count5 + 1'b1;
                      COUNT_HOT[5] <= 1'b0;
                    end
                  else
                    begin
                      Count5 <= 2'b0;
                      COUNT_HOT[5] <= 1'b0;
                    end
                end
              else
                begin
                  Count5 <= Count5;
                  COUNT_HOT[5] <= 1'b1;
                end
            end
          else
            begin
              Count5 <= 2'b0;
              COUNT_HOT[5] <= 1'b0;
            end
        end
    end

/////////////////////////////////////////////////////////////////////////////////
//                                   COUNT6                                    //
/////////////////////////////////////////////////////////////////////////////////
  always @(posedge CLK or negedge aresetn)
    begin
      if((!aresetn) || (!sresetn) || (!RST_CNT_N))
        begin
          Count6 <= 2'b0;
          COUNT_HOT[6] <= 1'b0;
        end
      else
        begin
          if(!ALIGNED)
            begin
              //RD- and RD+ Detection
              if(Count6 < COMMAS_TO_DET)
                begin
                  if((comma_n[6] || comma_p[6]))
                    begin
                      Count6 <= Count6 + 1'b1;
                      COUNT_HOT[6] <= 1'b0;
                    end
                  else
                    begin
                      Count6 <= 2'b0;
                      COUNT_HOT[6] <= 1'b0;
                    end
                end
              else
                begin
                  Count6 <= Count6;
                  COUNT_HOT[6] <= 1'b1;
                end
            end
          else
            begin
              Count6 <= 2'b0;
              COUNT_HOT[6] <= 1'b0;
            end
        end
    end

/////////////////////////////////////////////////////////////////////////////////
//                                   COUNT7                                    //
/////////////////////////////////////////////////////////////////////////////////
  always @(posedge CLK or negedge aresetn)
    begin
      if((!aresetn) || (!sresetn) || (!RST_CNT_N))
        begin
          Count7 <= 2'b0;
          COUNT_HOT[7] <= 1'b0;
        end
      else
        begin
          if(!ALIGNED)
            begin
              //RD- and RD+ Detection
              if(Count7 < COMMAS_TO_DET)
                begin
                  if((comma_n[7] || comma_p[7]))
                    begin
                      Count7 <= Count7 + 1'b1;
                      COUNT_HOT[7] <= 1'b0;
                    end
                  else
                    begin
                      Count7 <= 2'b0;
                      COUNT_HOT[7] <= 1'b0;
                    end
                end
              else
                begin
                  Count7 <= Count7;
                  COUNT_HOT[7] <= 1'b1;
                end
            end
          else
            begin
              Count7 <= 2'b0;
              COUNT_HOT[7] <= 1'b0;
            end
        end
    end

/////////////////////////////////////////////////////////////////////////////////
//                                   COUNT8                                    //
/////////////////////////////////////////////////////////////////////////////////
  always @(posedge CLK or negedge aresetn)
    begin
      if((!aresetn) || (!sresetn) || (!RST_CNT_N))
        begin
          Count8 <= 2'b0;
          COUNT_HOT[8] <= 1'b0;
        end
      else
        begin
          if(!ALIGNED)
            begin
              //RD- and RD+ Detection
              if(Count8 < COMMAS_TO_DET)
                begin
                  if((comma_n[8] || comma_p[8]))
                    begin
                      Count8 <= Count8 + 1'b1;
                      COUNT_HOT[8] <= 1'b0;
                    end
                  else
                    begin
                      Count8 <= 2'b0;
                      COUNT_HOT[8] <= 1'b0;
                    end
                end
              else
                begin
                  Count8 <= Count8;
                  COUNT_HOT[8] <= 1'b1;
                end
            end
          else
            begin
              Count8 <= 2'b0;
              COUNT_HOT[8] <= 1'b0;
            end
        end
    end

/////////////////////////////////////////////////////////////////////////////////
//                                   COUNT9                                    //
/////////////////////////////////////////////////////////////////////////////////
  always @(posedge CLK or negedge aresetn)
    begin
      if((!aresetn) || (!sresetn) || (!RST_CNT_N))
        begin
          Count9 <= 2'b0;
          COUNT_HOT[9] <= 1'b0;
        end
      else
        begin
          if(!ALIGNED)
            begin
              //RD- and RD+ Detection
              if(Count9 < COMMAS_TO_DET)
                begin
                  if((comma_n[9] || comma_p[9]))
                    begin
                      Count9 <= Count9 + 1'b1;
                      COUNT_HOT[9] <= 1'b0;
                    end
                  else
                    begin
                      Count9 <= 2'b0;
                      COUNT_HOT[9] <= 1'b0;
                    end
                end
              else
                begin
                  Count9 <= Count9;
                  COUNT_HOT[9] <= 1'b1;
                end
            end
          else
            begin
              Count9 <= 2'b0;
              COUNT_HOT[9] <= 1'b0;
            end
        end
    end

 ///////////////////////////////////////////////////////////////////////////////////
//                                  WA_FSM                                       //
///////////////////////////////////////////////////////////////////////////////////
  always @(posedge CLK or negedge aresetn)
    begin
      if((!aresetn) || (!sresetn))
        begin
          WA_FSM_STATE <= WA_INIT;
          MUX_SEL <= 5'b11111;     //NONE
//          wait_cnt <= 4'b0;
          ALIGNED <= 1'b0;
        end
      else
        begin
          case(WA_FSM_STATE)
            WA_INIT: begin
                       if((WRD_SYNC_int) && (CDE_int))
                         begin
                           WA_FSM_STATE <= WA_SEL;
                           MUX_SEL <= 5'b11111;
                           ALIGNED <= 1'b0;
                         end
                       else
                         begin
                           WA_FSM_STATE <= WA_INIT;
                         end
                     end
             WA_SEL: begin
                       case(COUNT_HOT)
                         SEL_NONE: begin
                                     MUX_SEL <= 5'b11111;
                                     WA_FSM_STATE <= WA_SEL;
                                   end
                          SEL_DET0: begin
                                     MUX_SEL <= 5'd0;
                                     WA_FSM_STATE <= WA_WAIT_0;
                                    end
                          SEL_DET1: begin
                                     MUX_SEL <= 5'd1;
                                     WA_FSM_STATE <= WA_WAIT_0;
                                    end
                          SEL_DET2: begin
                                     MUX_SEL <= 5'd2;
                                     WA_FSM_STATE <= WA_WAIT_0;
                                    end
                          SEL_DET3: begin
                                     MUX_SEL <= 5'd3;
                                     WA_FSM_STATE <= WA_WAIT_0;
                                    end
                          SEL_DET4: begin
                                     MUX_SEL <= 5'd4;
                                     WA_FSM_STATE <= WA_WAIT_0;
                                    end
                          SEL_DET5: begin
                                     MUX_SEL <= 5'd5;
                                     WA_FSM_STATE <= WA_WAIT_0;
                                    end
                          SEL_DET6: begin
                                     MUX_SEL <= 5'd6;
                                     WA_FSM_STATE <= WA_WAIT_0;
                                    end
                          SEL_DET7: begin
                                     MUX_SEL <= 5'd7;
                                     WA_FSM_STATE <= WA_WAIT_0;
                                    end
                          SEL_DET8: begin
                                     MUX_SEL <= 5'd8;
                                     WA_FSM_STATE <= WA_WAIT_0;
                                    end
                          SEL_DET9: begin
                                     MUX_SEL <= 5'd9;
                                     WA_FSM_STATE <= WA_WAIT_0;
                                    end
                          default: begin
                                      MUX_SEL <= 5'b11111;
                                      WA_FSM_STATE <= WA_INIT;
                                   end
                        endcase
                     end
            WA_WAIT_0: if((!WRD_SYNC_int) && (!CDE_int))
                         begin
                           WA_FSM_STATE <= WA_WAIT_1;
//                           wait_cnt <= 4'b0;
                           ALIGNED <= 1'b1;
                          end
//                        else if(wait_cnt == 4'd10)
//                          begin
//                            WA_FSM_STATE <= WA_SEL;
//                           wait_cnt <= 4'b0;
//                          end
                        else
                         begin
                           WA_FSM_STATE <= WA_WAIT_0;
                           ALIGNED <= 1'b0;
//                           wait_cnt <= wait_cnt + 1'b1;
                         end
            WA_WAIT_1: WA_FSM_STATE <= WA_INIT;
              default: WA_FSM_STATE <= WA_INIT;
          endcase
        end
    end

/////////////////////////////////////////////////////////////////////////////////
//                                   WA_MUX                                    //
/////////////////////////////////////////////////////////////////////////////////

  always @(posedge CLK or negedge aresetn)
    begin
      if((!aresetn) || (!sresetn))
        begin
          WA_DATA <= 10'b0;
//          COMMA_DETECT_int <= 1'b0;
        end
      else
        begin
          case(MUX_SEL)
              5'd0 : begin
                      WA_DATA <=buff_data[9+POS_NUM:0+POS_NUM];
//                      COMMA_DETECT_int <= comma_all_buf[0+POS_NUM_CD];
                     end
              5'd1 : begin
                      WA_DATA <= buff_data[10+POS_NUM:1+POS_NUM];
//                      COMMA_DETECT_int <= comma_all_buf[1+POS_NUM_CD];
                     end
              5'd2 : begin
                      WA_DATA <= buff_data[11+POS_NUM:2+POS_NUM];
//                      COMMA_DETECT_int <= comma_all_buf[2+POS_NUM_CD];
                     end
              5'd3 : begin
                       WA_DATA <= buff_data[12+POS_NUM:3+POS_NUM];
//                       COMMA_DETECT_int <= comma_all_buf[3+POS_NUM_CD];
                     end
              5'd4 : begin
                       WA_DATA <= buff_data[13+POS_NUM:4+POS_NUM];
//                       COMMA_DETECT_int <= comma_all_buf[4+POS_NUM_CD];
                     end
              5'd5 : begin
                       WA_DATA <= buff_data[14+POS_NUM:5+POS_NUM];
//                       COMMA_DETECT_int <= comma_all_buf[5+POS_NUM_CD];
                     end
              5'd6 : begin
                       WA_DATA <= buff_data[15+POS_NUM:6+POS_NUM];
//                       COMMA_DETECT_int <= comma_all_buf[6+POS_NUM_CD];
                     end
              5'd7 : begin
                       WA_DATA <= buff_data[16+POS_NUM:7+POS_NUM];
//                       COMMA_DETECT_int <= comma_all_buf[7+POS_NUM_CD];
                     end
              5'd8 : begin
                       WA_DATA <= buff_data[17+POS_NUM:8+POS_NUM];
//                       COMMA_DETECT_int <= comma_all_buf[8+POS_NUM_CD];
                     end
              5'd9 : begin
                       WA_DATA <= buff_data[18+POS_NUM:9+POS_NUM];
//                       COMMA_DETECT_int <= comma_all_buf[9+POS_NUM_CD];
                     end
          5'b11111 : begin
                       WA_DATA <= 10'b0;
//                       COMMA_DETECT_int <= 1'b0;
                     end
           default : begin
                       WA_DATA <= 10'b0;
//                       COMMA_DETECT_int <= 1'b0;
                     end
          endcase
        end
     end

// SYNCHRONIZING STATE MACHINE
    always @(posedge CLK or negedge aresetn)
    begin
       if((!aresetn) || (!sresetn))
       begin
          SYNC_STATE <= SEARCH_1 ; 
          COMMA_FOUND <= 1'b0 ; 
          WORD_SYNC_L <= 1'b1 ; 
          COMMA_DETECT_ENABLE <= 1'b1 ; 
       end
       else
       begin
          COMMA_FOUND <= COMMA_DETECT ; 
          case (SYNC_STATE)
             SEARCH_1 :
                      begin
                         if (COMMA_FOUND)
                         begin
                            SYNC_STATE <= SYNC_2 ; 
                            COMMA_DETECT_ENABLE <= 1'b0 ; 
                            WORD_SYNC_L <= 1'b0 ; 
                         end 
                         else
                         begin
                            SYNC_STATE <= SEARCH_1 ; 
                         end
                      end
             SYNC_2 :
                      begin
                         if (ERROR_CNT > TRIGGER-1)
                         begin
                            SYNC_STATE <= SEARCH_1 ; 
                            WORD_SYNC_L <= 1'b1 ; 
                            COMMA_DETECT_ENABLE <= 1'b1 ; 
                         end
                         else
                         begin
                            SYNC_STATE <= SYNC_2 ; 
                         end 
                      end
             default :
                      begin
                         SYNC_STATE <= SEARCH_1 ; 
                         WORD_SYNC_L <= 1'b1 ; 
                         COMMA_DETECT_ENABLE <= 1'b1 ; 
                      end
          endcase 
       end 
    end

   // ERROR COUNTER.  THE COUNTER WILL INCREMENT BY ONE WHENEVER CODE_ERROR BIT IS ACTIVE.  WHENEVER A
   // VALID CODE IS RECEIVED, THE COUNTER WILL RESET TO 0.
   assign ERROR = ~CODE_ERROR; 

   always @(posedge CLK or negedge aresetn)
   begin
      if((!aresetn) || (!sresetn))
      begin
         ERROR_CNT[3:0] <= 4'b0000 ;
      end
      else
      begin
         if (SYNC_STATE == SYNC_2 & ERROR)
         begin
//		   if(COMMA_FOUND)
//		     begin
//			   ERROR_CNT[3:0] <= ERROR_CNT[3:0];
//			 end
//		   else
//		     begin
               ERROR_CNT[3:0] <= ERROR_CNT[3:0] + 4'b0001 ;
//			 end
         end
         else
         begin
            ERROR_CNT[3:0] <= 4'b0000 ;
         end 
      end 
   end 

endmodule