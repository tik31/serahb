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

module cpcs_wa_80( CLK,
                     RST_N,
                     DATA_IN,
                     WA_DATA,
                     CODE_ERROR,
//                     WRD_SYNC,
//                     CDE,
//                     COMMA_DETECT,
                     ALIGNED,
                     EXPD_ERR
                    );
/////////////////////////////////////////////////////////////////////////////////
//                              PARAMETERS                                     //
/////////////////////////////////////////////////////////////////////////////////
 parameter EPCS_DWIDTH      = 80;
 parameter KWIDTH           = (EPCS_DWIDTH/10);
 parameter SYNC_RESET       = 0;
 parameter COMMA_DETECT_SEL = 0;   // 0 = K28.5, 1 = K28.1, 2 = ALL, 3 = K28.7
 parameter PROG_COMMA_EN    = 0;
 parameter NO_OF_COMMAS     = 1;
 parameter COMMAS_TO_DET    = (PROG_COMMA_EN) ? NO_OF_COMMAS : 10;
// parameter POS_COMMA        = (COMMA_DETECT_SEL == 2) ? 8 : 0;
 parameter BUFF_INDEX       = 3;
 parameter POS_NUM          = (EPCS_DWIDTH*BUFF_INDEX);//(EPCS_DWIDTH*5)+POS_COMMA;
 parameter CD_DELAY         = (COMMAS_TO_DET == 1) ? BUFF_INDEX+4 :  BUFF_INDEX+3;
 parameter WA_BUFF_INDEX    = (COMMAS_TO_DET == 1) ? 3 : 2;
// parameter POS_NUM_CD       = 10;//(PROG_COMMA_EN) ? 10 : 0;
 
 parameter SHIFT_EN         = 1;  // 0 = disabled, 1 = enabled
 parameter WA_INIT = 2'b00, WA_SEL = 2'b01, WA_WAIT_0 = 2'b10, WA_WAIT_1 = 2'b11;  //WA FSM states

 parameter COMMA_PU    = 8'b11000001,    COMMA_NU   = 8'b00111110;
 parameter K28_7_p_10  = 10'b1100000111, K28_7_n_10 = 10'b0011111000;
 parameter K28_5_p_10  = 10'b1100000101, K28_5_n_10 = 10'b0011111010;
 parameter K28_1_p_10  = 10'b1100000110, K28_1_n_10 = 10'b0011111001;
 parameter COMMA_p_sel = (COMMA_DETECT_SEL==0) ? K28_5_p_10 : (COMMA_DETECT_SEL==1) ? K28_1_p_10 : (COMMA_DETECT_SEL==3) ? K28_7_p_10 : COMMA_PU;
 parameter COMMA_n_sel = (COMMA_DETECT_SEL==0) ? K28_5_n_10 : (COMMA_DETECT_SEL==1) ? K28_1_n_10 : (COMMA_DETECT_SEL==3) ? K28_7_n_10 : COMMA_NU;
 parameter COMMA_WIDTH = (COMMA_DETECT_SEL==2) ? 8 : 10;

 parameter    SEL_NONE  = 10'h000,
              SEL_DET0  = 10'h001, SEL_DET1  = 10'h002, SEL_DET2  = 10'h004, SEL_DET3  = 10'h008, SEL_DET4  = 10'h010, SEL_DET5  = 10'h020, SEL_DET6  = 10'h040, SEL_DET7  = 10'h080, SEL_DET8  = 10'h100, SEL_DET9  = 10'h200;

   parameter[0:0] SEARCH_1 = 1'b0;//3'b000; 
//   parameter[2:0] SEARCH_2 = 3'b001; 
//   parameter[2:0] SYNC_0 = 3'b010; 
//   parameter[2:0] SYNC_1 = 3'b011; 
   parameter[0:0] SYNC_2 = 1'b1;//3'b100; 
   parameter[3:0] TRIGGER = 4'b0100; 

  integer i=0;
  genvar x, d, ch, ca_0, ca_1, ca_2, gco_x;
/////////////////////////////////////////////////////////////////////////////////
//                          INPUTS & OUTPUTS                                   //
/////////////////////////////////////////////////////////////////////////////////
 input CLK;
 input RST_N;
 input [EPCS_DWIDTH-1:0] DATA_IN;
 input [KWIDTH-1:0] CODE_ERROR;
// input [KWIDTH-1:0] WRD_SYNC;
// input [KWIDTH-1:0] CDE;

// output [KWIDTH-1:0] COMMA_DETECT;
 output [EPCS_DWIDTH-1:0] WA_DATA;
 output ALIGNED;
 output EXPD_ERR;
/////////////////////////////////////////////////////////////////////////////////
//                        REGS                                                 //
/////////////////////////////////////////////////////////////////////////////////
 reg [CD_DELAY-1:0]COMMA_DETECT_reg;
 wire comma_detect_done;
 wire block_comma_detect;
// reg [19:0] comma_all_buf;
 reg [EPCS_DWIDTH-1:0] WA_DATA;
 reg [(EPCS_DWIDTH*7)-1:0] buff_data;
 reg [(EPCS_DWIDTH*3)-1:0] WA_DATA_buf;
 reg [4:0] MUX_SEL;
 reg [1:0] WA_FSM_STATE;
 reg EXPD_ERR;
 wire [EPCS_DWIDTH-1:0] comma_p;
 wire [EPCS_DWIDTH-1:0] comma_n;
// reg [3:0] wait_cnt;
 reg wa_sel_st;
 reg [2:0] wa_sel_d;
 reg [2:0] wa_sel_d_mon;
 reg  count[0:EPCS_DWIDTH];
 reg  [11:0] count_max[0:9];
 wire  [KWIDTH-1:0] count_comb[0:9];
 
 reg[0:0] SYNC_STATE; 
 reg COMMA_FOUND; 
 reg[3:0] ERROR_CNT; 
 reg SYNC_LOST;
 reg COMMA_DETECT_ENABLE;
 reg WORD_SYNC_L;
 wire  [KWIDTH-1:0] ERROR;

/////////////////////////////////////////////////////////////////////////////////
//                                    WIRES                                    //
/////////////////////////////////////////////////////////////////////////////////
  wire [KWIDTH-1:0] det_pn;
  wire [KWIDTH-1:0] det_p;
  wire [KWIDTH-1:0] det_n;
  reg ALIGNED;
  wire [9:0] COUNT_HOT;
  wire CDE_int;
  wire WRD_SYNC_int;
  wire [KWIDTH-1:0] COMMA_DETECT;
 // wire [KWIDTH-1:0] comma_concat_p[0:9];
 // wire [KWIDTH-1:0] comma_concat_n[0:9];
  wire RST_CNT_N;
//  reg [9:0] comma_all;
  wire aresetn;
  wire sresetn;

  assign aresetn      = (SYNC_RESET==1) ? 1'b1 : RST_N;
  assign sresetn      = (SYNC_RESET==1) ? RST_N : 1'b1;
  assign RST_CNT_N    = (ALIGNED  && (WRD_SYNC_int &&  CDE_int)) ? 1'b0 : 1'b1;//(WA_FSM_STATE == WA_INIT) ? 1'b0 : 1'b1;
  assign COMMA_DETECT = COMMA_DETECT_reg[CD_DELAY-1] ? {KWIDTH{1'b1}} : {KWIDTH{1'b0}}; //COMMA_DETECT_int ? {KWIDTH{1'b1}} : {KWIDTH{1'b0}};
//  assign CDE_int      = (| CDE);
//  assign WRD_SYNC_int = (| WRD_SYNC);
  assign CDE_int      = COMMA_DETECT_ENABLE;
  assign WRD_SYNC_int = WORD_SYNC_L;
  assign det_pn       = det_p | det_n;
  assign comma_detect_done  = (|COUNT_HOT);
  assign block_comma_detect = (ALIGNED || (WA_FSM_STATE == WA_WAIT_0));
  
//////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////////
//                               COUNT HOT                                     //
/////////////////////////////////////////////////////////////////////////////////
for (ch=0; ch<10; ch=ch+1) begin: CH
    assign COUNT_HOT[ch] = (count_max[ch] > COMMAS_TO_DET-1) ? 1'b1 : 1'b0;
end

/////////////////////////////////////////////////////////////////////////////////
//                                    BUFFER                                   //
/////////////////////////////////////////////////////////////////////////////////
  always @(posedge CLK or negedge aresetn)
    begin
      if((!aresetn) || (!sresetn))
        begin
          buff_data <= {(EPCS_DWIDTH*7){1'b0}};
          COMMA_DETECT_reg  <= {CD_DELAY{1'b0}};
        end
      else
        begin
          buff_data <= {buff_data[(EPCS_DWIDTH*6)-1:0], DATA_IN};
          COMMA_DETECT_reg  <= {COMMA_DETECT_reg[CD_DELAY-2:0],comma_detect_done};
        end
    end

/////////////////////////////////////////////////////////////////////////////////
//    SHIFTED DATA EXPECTED ERROR GENERATION                                   //
/////////////////////////////////////////////////////////////////////////////////
  always @(posedge CLK or negedge aresetn)
    begin
      if((!aresetn) || (!sresetn)) begin
          EXPD_ERR <= 1'b0;
          wa_sel_d_mon <= 3'b0;
      end else begin
          if(wa_sel_d_mon != wa_sel_d) begin
              EXPD_ERR <= 1'b1;
              wa_sel_d_mon <= wa_sel_d;
          end else begin
              EXPD_ERR <= 1'b0;
              wa_sel_d_mon <= wa_sel_d_mon;
          end
      end
    end

/////////////////////////////////////////////////////////////////////////////////
//                                    DETECTOR                                 //
/////////////////////////////////////////////////////////////////////////////////

generate for (x=0; x<=EPCS_DWIDTH-1; x=x+1)
begin: gen_count_pn
    assign comma_p[x]  = block_comma_detect ? 1'b0 : (buff_data[9+x:(10-COMMA_WIDTH)+x] == COMMA_p_sel[COMMA_WIDTH-1:0]);
    assign comma_n[x]  = block_comma_detect ? 1'b0 : (buff_data[9+x:(10-COMMA_WIDTH)+x] == COMMA_n_sel[COMMA_WIDTH-1:0]);
    
    always @(posedge CLK or negedge aresetn)
    begin
      if((!aresetn) || (!sresetn) || (!RST_CNT_N)) begin
          count[x] <= 1'b0;
      end else begin
          count[x] <= comma_n[x] || comma_p[x];
      end
    end
end
endgenerate

generate for (gco_x=0; gco_x<10; gco_x=gco_x+1)
begin: gen_count_ones
  assign count_comb[gco_x] = (EPCS_DWIDTH == 80) ? {count[70+gco_x], count[60+gco_x], count[50+gco_x], count[40+gco_x], count[30+gco_x], count[20+gco_x] ,count[10+gco_x], count[0+gco_x]} :
                             (EPCS_DWIDTH == 40) ? {count[30+gco_x], count[20+gco_x] ,count[10+gco_x], count[0+gco_x]} :
                             (EPCS_DWIDTH == 20) ? {count[10+gco_x], count[0+gco_x]} : {7'b0, count[0+gco_x]};

      always @(posedge CLK or negedge aresetn)
        begin
          if((!aresetn) || (!sresetn) || (!RST_CNT_N)) begin
              count_max[gco_x] <= 12'b0;
          end 
          else if (!block_comma_detect) begin
            if(COMMAS_TO_DET == 1) begin
                if(| count_comb[gco_x]) begin
                    count_max[gco_x] <= 12'd1;
                end else begin
                    count_max[gco_x] <= 12'b0;
                end
            end else if(COMMAS_TO_DET == 2) begin
                if (EPCS_DWIDTH == 20) begin
                    casez(count_comb[gco_x])
                      2'b11: count_max[gco_x] <= 12'd2;
                      2'b10: count_max[gco_x] <= count_max[gco_x] + 12'd1;
                      2'b01: count_max[gco_x] <= 12'd1;
                      default: count_max[gco_x] <= 12'd0;
                    endcase
                end else if (EPCS_DWIDTH == 40) begin
                    casez(count_comb[gco_x])
                      4'bzz11: count_max[gco_x] <= 12'd2;
                      4'bz110: count_max[gco_x] <= 12'd2;
                      4'b1100: count_max[gco_x] <= 12'd2;
                      4'b1000: count_max[gco_x] <= count_max[gco_x] + 12'd1;
                      4'b0001: count_max[gco_x] <= 12'd1;
                      default: count_max[gco_x] <= 12'd0;
                    endcase
                end else if (EPCS_DWIDTH == 80) begin
                    casez(count_comb[gco_x])
                      8'bzzzzzz11: count_max[gco_x] <= 12'd2;
                      8'bzzzzz110: count_max[gco_x] <= 12'd2;
                      8'bzzzz1100: count_max[gco_x] <= 12'd2;
                      8'bzzz11000: count_max[gco_x] <= 12'd2;
                      8'bzz110000: count_max[gco_x] <= 12'd2;
                      8'bz1100000: count_max[gco_x] <= 12'd2;
                      8'b11000000: count_max[gco_x] <= 12'd2;
                      8'b00000001: count_max[gco_x] <= 12'd1;
                      8'b10000000: count_max[gco_x] <= count_max[gco_x] + 12'd1;
                      default: count_max[gco_x] <= 12'b0;
                    endcase
                end
            end else if(COMMAS_TO_DET == 3) begin
                if (EPCS_DWIDTH == 20) begin
                    casez(count_comb[gco_x])
                      2'b11: count_max[gco_x] <= count_max[gco_x] + 12'd2;
                      2'b10: count_max[gco_x] <= count_max[gco_x] + 12'd1;
                      2'b01: count_max[gco_x] <= 12'd1;
                      default: count_max[gco_x] <= 12'b0;
                    endcase
                end else if (EPCS_DWIDTH == 40) begin
                    casez(count_comb[gco_x])
                      4'bz111: count_max[gco_x] <= 12'd3;
                      4'b1110: count_max[gco_x] <= 12'd3;
                      4'b1100: count_max[gco_x] <= count_max[gco_x] + 12'd2;
                      4'b1000: count_max[gco_x] <= count_max[gco_x] + 12'd1;
                      4'b0001: count_max[gco_x] <= 12'd1;
                      4'b0011: count_max[gco_x] <= 12'd2;
                      default: count_max[gco_x] <= 12'b0;
                    endcase
                end else if (EPCS_DWIDTH == 80) begin
                    casez(count_comb[gco_x])
                      8'bzzzzz111: count_max[gco_x] <= 12'd3;
                      8'bzzzz1110: count_max[gco_x] <= 12'd3;
                      8'bzzz11100: count_max[gco_x] <= 12'd3;
                      8'bzz111000: count_max[gco_x] <= 12'd3;
                      8'bz1110000: count_max[gco_x] <= 12'd3;
                      8'b11100000: count_max[gco_x] <= 12'd3;
                      8'b10000000: count_max[gco_x] <= count_max[gco_x] + 12'd1;
                      8'b11000000: count_max[gco_x] <= count_max[gco_x] + 12'd2;
                      8'b00000001: count_max[gco_x] <= 12'd1;
                      8'b00000011: count_max[gco_x] <= 12'd2;
                      default: count_max[gco_x] <= 12'b0;
                    endcase
                end
            end else if(COMMAS_TO_DET == 4) begin
                if (EPCS_DWIDTH == 20) begin
                    casez(count_comb[gco_x])
                      2'b11: count_max[gco_x] <= count_max[gco_x] + 12'd2;
                      2'b10: count_max[gco_x] <= count_max[gco_x] + 12'd1;
                      2'b01: count_max[gco_x] <= 12'd1;
                      default: count_max[gco_x] <= 12'b0;
                    endcase
                end else if (EPCS_DWIDTH == 40) begin
                    casez(count_comb[gco_x])
                      4'b1111: count_max[gco_x] <= 12'd4;
                      4'b1110: count_max[gco_x] <= count_max[gco_x] + 12'd3;
                      4'b1100: count_max[gco_x] <= count_max[gco_x] + 12'd2;
                      4'b1000: count_max[gco_x] <= count_max[gco_x] + 12'd1;
                      4'b0001: count_max[gco_x] <= 12'd1;
                      4'b0011: count_max[gco_x] <= 12'd2;
                      4'b0111: count_max[gco_x] <= 12'd3;
                      default: count_max[gco_x] <= 12'b0;
                    endcase
                end else if (EPCS_DWIDTH == 80) begin
                    casez(count_comb[gco_x])
                      8'bzzzz1111: count_max[gco_x] <= 12'd4;
                      8'bzzz11110: count_max[gco_x] <= 12'd4;
                      8'bzz111100: count_max[gco_x] <= 12'd4;
                      8'bz1111000: count_max[gco_x] <= 12'd4;
                      8'b11110000: count_max[gco_x] <= 12'd4;
                      8'b10000000: count_max[gco_x] <= count_max[gco_x] + 12'd1;
                      8'b11000000: count_max[gco_x] <= count_max[gco_x] + 12'd2;
                      8'b11100000: count_max[gco_x] <= count_max[gco_x] + 12'd3;
                      8'b00000001: count_max[gco_x] <= 12'd1;
                      8'b00000011: count_max[gco_x] <= 12'd2;
                      8'b00000111: count_max[gco_x] <= 12'd3;
                      default: count_max[gco_x] <= 12'b0;
                    endcase
                end
            end else if(COMMAS_TO_DET == 5) begin
                if (EPCS_DWIDTH == 20) begin
                    casez(count_comb[gco_x])
                      2'b11: count_max[gco_x] <= count_max[gco_x] + 12'd2;
                      2'b10: count_max[gco_x] <= count_max[gco_x] + 12'd1;
                      2'b01: count_max[gco_x] <= 12'd1;
                      default: count_max[gco_x] <= 12'b0;
                    endcase
                end else if (EPCS_DWIDTH == 40) begin
                    casez(count_comb[gco_x])
                      4'b1111: count_max[gco_x] <= count_max[gco_x] + 12'd4;
                      4'b1110: count_max[gco_x] <= count_max[gco_x] + 12'd3;
                      4'b1100: count_max[gco_x] <= count_max[gco_x] + 12'd2;
                      4'b1000: count_max[gco_x] <= count_max[gco_x] + 12'd1;
                      4'b0001: count_max[gco_x] <= 12'd1;
                      4'b0011: count_max[gco_x] <= 12'd2;
                      4'b0111: count_max[gco_x] <= 12'd3;
                      default: count_max[gco_x] <= 12'b0;
                    endcase
                end else if (EPCS_DWIDTH == 80) begin
                    casez(count_comb[gco_x])
                      8'bzzz11111: count_max[gco_x] <= 12'd5;
                      8'bzz111110: count_max[gco_x] <= 12'd5;
                      8'bz1111100: count_max[gco_x] <= 12'd5;
                      8'b11111000: count_max[gco_x] <= 12'd5;
                      8'b10000000: count_max[gco_x] <= count_max[gco_x] + 12'd1;
                      8'b11000000: count_max[gco_x] <= count_max[gco_x] + 12'd2;
                      8'b11100000: count_max[gco_x] <= count_max[gco_x] + 12'd3;
                      8'b11110000: count_max[gco_x] <= count_max[gco_x] + 12'd4;
                      8'b00000001: count_max[gco_x] <= 12'd1;
                      8'b00000011: count_max[gco_x] <= 12'd2;
                      8'b00000111: count_max[gco_x] <= 12'd3;
                      8'b00001111: count_max[gco_x] <= 12'd4;
                      default: count_max[gco_x] <= 12'b0;
                    endcase
                end
            end else if(COMMAS_TO_DET == 6) begin
                if (EPCS_DWIDTH == 20) begin
                    casez(count_comb[gco_x])
                      2'b11: count_max[gco_x] <= count_max[gco_x] + 12'd2;
                      2'b10: count_max[gco_x] <= count_max[gco_x] + 12'd1;
                      2'b01: count_max[gco_x] <= 12'd1;
                      default: count_max[gco_x] <= 12'b0;
                    endcase
                end else if (EPCS_DWIDTH == 40) begin
                    casez(count_comb[gco_x])
                      4'b1111: count_max[gco_x] <= count_max[gco_x] + 12'd4;
                      4'b1110: count_max[gco_x] <= count_max[gco_x] + 12'd3;
                      4'b1100: count_max[gco_x] <= count_max[gco_x] + 12'd2;
                      4'b1000: count_max[gco_x] <= count_max[gco_x] + 12'd1;
                      4'b0001: count_max[gco_x] <= 12'd1;
                      4'b0011: count_max[gco_x] <= 12'd2;
                      4'b0111: count_max[gco_x] <= 12'd3;
                      default: count_max[gco_x] <= 12'b0;
                    endcase
                end else if (EPCS_DWIDTH == 80) begin
                    casez(count_comb[gco_x])
                      8'bzz111111: count_max[gco_x] <= 12'd6;
                      8'bz1111110: count_max[gco_x] <= 12'd6;
                      8'b11111100: count_max[gco_x] <= 12'd6;
                      8'b10000000: count_max[gco_x] <= count_max[gco_x] + 12'd1;
                      8'b11000000: count_max[gco_x] <= count_max[gco_x] + 12'd2;
                      8'b11100000: count_max[gco_x] <= count_max[gco_x] + 12'd3;
                      8'b11110000: count_max[gco_x] <= count_max[gco_x] + 12'd4;
                      8'b11111000: count_max[gco_x] <= count_max[gco_x] + 12'd5;
                      8'b00000001: count_max[gco_x] <= 12'd1;
                      8'b00000011: count_max[gco_x] <= 12'd2;
                      8'b00000111: count_max[gco_x] <= 12'd3;
                      8'b00001111: count_max[gco_x] <= 12'd4;
                      8'b00011111: count_max[gco_x] <= 12'd5;
                      default: count_max[gco_x] <= 12'b0;
                    endcase
                end
            end else if(COMMAS_TO_DET == 7) begin
                if (EPCS_DWIDTH == 20) begin
                    casez(count_comb[gco_x])
                      2'b11: count_max[gco_x] <= count_max[gco_x] + 12'd2;
                      2'b10: count_max[gco_x] <= count_max[gco_x] + 12'd1;
                      2'b01: count_max[gco_x] <= 12'd1;
                      default: count_max[gco_x] <= 12'b0;
                    endcase
                end else if (EPCS_DWIDTH == 40) begin
                    casez(count_comb[gco_x])
                      4'b1111: count_max[gco_x] <= count_max[gco_x] + 12'd4;
                      4'b1110: count_max[gco_x] <= count_max[gco_x] + 12'd3;
                      4'b1100: count_max[gco_x] <= count_max[gco_x] + 12'd2;
                      4'b1000: count_max[gco_x] <= count_max[gco_x] + 12'd1;
                      4'b0001: count_max[gco_x] <= 12'd1;
                      4'b0011: count_max[gco_x] <= 12'd2;
                      4'b0111: count_max[gco_x] <= 12'd3;
                      default: count_max[gco_x] <= 12'b0;
                    endcase
                end else if (EPCS_DWIDTH == 80) begin
                    casez(count_comb[gco_x])
                      8'bz1111111: count_max[gco_x] <= 12'd7;
                      8'b11111110: count_max[gco_x] <= 12'd7;
                      8'b10000000: count_max[gco_x] <= count_max[gco_x] + 12'd1;
                      8'b11000000: count_max[gco_x] <= count_max[gco_x] + 12'd2;
                      8'b11100000: count_max[gco_x] <= count_max[gco_x] + 12'd3;
                      8'b11110000: count_max[gco_x] <= count_max[gco_x] + 12'd4;
                      8'b11111000: count_max[gco_x] <= count_max[gco_x] + 12'd5;
                      8'b11111100: count_max[gco_x] <= count_max[gco_x] + 12'd6;
                      8'b00000001: count_max[gco_x] <= 12'd1;
                      8'b00000011: count_max[gco_x] <= 12'd2;
                      8'b00000111: count_max[gco_x] <= 12'd3;
                      8'b00001111: count_max[gco_x] <= 12'd4;
                      8'b00011111: count_max[gco_x] <= 12'd5;
                      8'b00111111: count_max[gco_x] <= 12'd6;
                      default: count_max[gco_x] <= 12'b0;
                    endcase
                end
            end else begin
                if (EPCS_DWIDTH == 20) begin
                    casez(count_comb[gco_x])
                      2'b10: count_max[gco_x] <= count_max[gco_x] + 12'd1;
                      2'b11: count_max[gco_x] <= count_max[gco_x] + 12'd2;
                      2'b01: count_max[gco_x] <= 12'd1;
                      default: count_max[gco_x] <= 12'b0;
                    endcase
                end else if (EPCS_DWIDTH == 40) begin
                    casez(count_comb[gco_x])
                      4'b1000: count_max[gco_x] <= count_max[gco_x] + 12'd1;
                      4'b1100: count_max[gco_x] <= count_max[gco_x] + 12'd2;
                      4'b1110: count_max[gco_x] <= count_max[gco_x] + 12'd3;
                      4'b1111: count_max[gco_x] <= count_max[gco_x] + 12'd4;
                      4'b0001: count_max[gco_x] <= 12'd1;
                      4'b0011: count_max[gco_x] <= 12'd2;
                      4'b0111: count_max[gco_x] <= 12'd3;
                      default: count_max[gco_x] <= 12'b0;
                    endcase
                end else if (EPCS_DWIDTH == 80) begin
                    casez(count_comb[gco_x])
                      8'b10000000: count_max[gco_x] <= count_max[gco_x] + 12'd1;
                      8'b11000000: count_max[gco_x] <= count_max[gco_x] + 12'd2;
                      8'b11100000: count_max[gco_x] <= count_max[gco_x] + 12'd3;
                      8'b11110000: count_max[gco_x] <= count_max[gco_x] + 12'd4;
                      8'b11111000: count_max[gco_x] <= count_max[gco_x] + 12'd5;
                      8'b11111100: count_max[gco_x] <= count_max[gco_x] + 12'd6;
                      8'b11111110: count_max[gco_x] <= count_max[gco_x] + 12'd7;
                      8'b11111111: count_max[gco_x] <= count_max[gco_x] + 12'd8;
                      8'b00000001: count_max[gco_x] <= 12'd1;
                      8'b00000011: count_max[gco_x] <= 12'd2;
                      8'b00000111: count_max[gco_x] <= 12'd3;
                      8'b00001111: count_max[gco_x] <= 12'd4;
                      8'b00011111: count_max[gco_x] <= 12'd5;
                      8'b00111111: count_max[gco_x] <= 12'd6;
                      8'b01111111: count_max[gco_x] <= 12'd7;
                      default: count_max[gco_x] <= 12'b0;
                    endcase
                end
            end
          end else begin
            count_max[gco_x] <= 12'b0;
          end
        end
end
endgenerate

/////////////////////////////////////////////////////////////////////////////////
//                                    DATA_OUT_SEL                             //
/////////////////////////////////////////////////////////////////////////////////

for (d=0; d<KWIDTH; d=d+1) begin: DET_0 
    assign det_p[d] = (WA_DATA_buf[EPCS_DWIDTH-((10*d)+1) :EPCS_DWIDTH-((10*d)+COMMA_WIDTH)]  == COMMA_p_sel[COMMA_WIDTH-1:0]); 
    assign det_n[d] = (WA_DATA_buf[EPCS_DWIDTH-((10*d)+1) :EPCS_DWIDTH-((10*d)+COMMA_WIDTH)]  == COMMA_n_sel[COMMA_WIDTH-1:0]); 
end

generate
if((EPCS_DWIDTH == 20) && (SHIFT_EN == 1))
begin
    always @(posedge CLK or negedge aresetn)
    begin
        if((!aresetn) || (!sresetn) || (!RST_CNT_N)) begin
            wa_sel_st <= 1'b0;
            wa_sel_d  <= 3'd0;
        end else begin
            case(wa_sel_st)
             1'b0:  begin
                        if(det_pn == {KWIDTH{1'b1}}) begin
                            wa_sel_st <= 1'b1;
                            wa_sel_d  <= 3'd0;
                        end else begin
                            wa_sel_st <= 1'b0;
                            case(det_pn)     
                                2'h1: wa_sel_d <= 3'd1;
                            default : wa_sel_d <= wa_sel_d;
                            endcase
                        end
                    end
             1'b1:  begin
                        if(det_pn == {KWIDTH{1'b1}}) begin
                            wa_sel_st <= 1'b1;
                        end else begin
                            casez(det_pn)     
                     /*2'h0*/2'b00: begin 
                                      wa_sel_d  <= 3'd0;
                                      wa_sel_st <= 1'b0; 
                                    end
                     /*2'h1*/2'b01: begin
                                      wa_sel_d  <= 3'd1;
                                      wa_sel_st <= 1'b0; 
                                    end
                     /*2'h3*/2'b1z: begin
                                      wa_sel_d  <= 3'd0;
                                      wa_sel_st <= 1'b1; 
                                    end
                           default: begin
                                      wa_sel_d  <= 3'b0;
                                      wa_sel_st <= 1'b1; 
                                    end
                            endcase
                        end
                    end
          default: begin
                     wa_sel_d  <= 3'b0;
                     wa_sel_st <= 1'b0; 
                   end
          endcase
        end
    end

    always @(posedge CLK or negedge aresetn)
    begin
        if((!aresetn) || (!sresetn)) begin
            WA_DATA <= {EPCS_DWIDTH{1'b0}};
        end else begin
            case(wa_sel_d)
                 3'd0: WA_DATA <= WA_DATA_buf[(EPCS_DWIDTH*2+0 )-1:EPCS_DWIDTH+0 ];   //19:0
                 3'd1: WA_DATA <= WA_DATA_buf[(EPCS_DWIDTH*2+10)-1:EPCS_DWIDTH+10];   //29:10
              default: WA_DATA <= WA_DATA_buf[(EPCS_DWIDTH*2+0 )-1:EPCS_DWIDTH+0 ];
            endcase
        end
    end
end
endgenerate

generate
if((EPCS_DWIDTH == 40) && (SHIFT_EN == 1))
begin
    always @(posedge CLK or negedge aresetn)
    begin
        if((!aresetn) || (!sresetn) || (!RST_CNT_N)) begin
            wa_sel_st   <= 1'b0;
            wa_sel_d    <= 3'd0;
        end else begin
                case(wa_sel_st)
                   1'b0 :   begin
                                if(det_pn == {KWIDTH{1'b1}}) begin
                                    wa_sel_st   <= 1'b1;
                                    wa_sel_d    <= 3'd0;
                                end else begin
                                    wa_sel_st   <= 1'b0;
                                    casez(det_pn)     
                                        /*4'h1*/4'b0001: wa_sel_d <= 3'd1;
                                        /*4'h3*/4'b001z: wa_sel_d <= 3'd2;
                                        /*4'h7*/4'b01zz: wa_sel_d <= 3'd3;
                                        default        : wa_sel_d <= wa_sel_d;
                                    endcase
                                end
                            end
                   1'b1:    begin
                                if(det_pn == {KWIDTH{1'b1}}) begin
                                    wa_sel_st <= 1'b1;
                                end else begin
                                casez(det_pn)     
                         /*4'h0*/4'b0000: begin
                                            wa_sel_d  <= 3'd0;
                                            wa_sel_st <= 1'b0; 
                                          end
                         /*4'h1*/4'b0001: begin
                                            wa_sel_d  <= 3'd1;
                                            wa_sel_st <= 1'b0; 
                                          end
                         /*4'h3*/4'b001z: begin
                                            wa_sel_d  <= 3'd2;
                                            wa_sel_st <= 1'b0; 
                                          end
                         /*4'h7*/4'b01zz: begin
                                            wa_sel_d  <= 3'd3;
                                            wa_sel_st <= 1'b0; 
                                          end
                         /*4'hF*/4'b1zzz: begin
                                            wa_sel_d  <= 3'd0;
                                            wa_sel_st <= 1'b1; 
                                          end
                                default:  begin
                                            wa_sel_d  <= 3'b0;
                                            wa_sel_st <= 1'b1; 
                                          end
                                endcase
                            end
                        end
               default: begin
                           wa_sel_d  <= 3'b0;
                           wa_sel_st <= 1'b0; 
                        end
            endcase
        end
    end 

    always @(posedge CLK or negedge aresetn)
    begin
        if((!aresetn) || (!sresetn)) begin
            WA_DATA <= {EPCS_DWIDTH{1'b0}};
        end else begin
            case(wa_sel_d)
                 3'd0: WA_DATA <= WA_DATA_buf[(EPCS_DWIDTH*2+0 )-1:EPCS_DWIDTH+0 ];  //39:0
                 3'd1: WA_DATA <= WA_DATA_buf[(EPCS_DWIDTH*2+30)-1:EPCS_DWIDTH+30];  //69:30
                 3'd2: WA_DATA <= WA_DATA_buf[(EPCS_DWIDTH*2+20)-1:EPCS_DWIDTH+20];  //59:20
                 3'd3: WA_DATA <= WA_DATA_buf[(EPCS_DWIDTH*2+10)-1:EPCS_DWIDTH+10];  //49:10
              default: WA_DATA <= WA_DATA_buf[(EPCS_DWIDTH*2+0 )-1:EPCS_DWIDTH+0 ];
            endcase
        end
    end
end
endgenerate

generate
if((EPCS_DWIDTH == 80) && (SHIFT_EN == 1))
begin
    always @(posedge CLK or negedge aresetn)
    begin
        if((!aresetn) || (!sresetn) || (!RST_CNT_N)) begin
            wa_sel_st   <= 1'b0;
            wa_sel_d    <= 3'd0;
        end else begin
            case(wa_sel_st)
              1'b0: begin
                        if(det_pn == {KWIDTH{1'b1}}) begin
                           wa_sel_st <= 1'b1;
                           wa_sel_d <= 3'd0;
                        end else begin
                           wa_sel_st <= 1'b0;
                           casez(det_pn)
                    /*8'h01*/8'b00000001: wa_sel_d <= 3'd1;
                    /*8'h03*/8'b0000001z: wa_sel_d <= 3'd2;
                    /*8'h07*/8'b000001zz: wa_sel_d <= 3'd3;
                    /*8'h0F*/8'b00001zzz: wa_sel_d <= 3'd4;
                    /*8'h1F*/8'b0001zzzz: wa_sel_d <= 3'd5;
                    /*8'h3F*/8'b001zzzzz: wa_sel_d <= 3'd6;
                    /*8'h7F*/8'b01zzzzzz: wa_sel_d <= 3'd7;
                             default    : wa_sel_d <= wa_sel_d;
                           endcase
                        end
                    end
              1'b1: begin
                        if(det_pn == {KWIDTH{1'b1}}) begin
                            wa_sel_st <= 1'b1;
                        end else begin
                            casez(det_pn)     
                     /*8'h00*/8'b00000000: begin
                                            wa_sel_d  <= 3'd0;
                                            wa_sel_st <= 1'b0; 
                                       end
                     /*8'h01*/8'b00000001: begin
                                            wa_sel_d  <= 3'd1;
                                            wa_sel_st <= 1'b0; 
                                       end
                     /*8'h03*/8'b0000001z: begin
                                            wa_sel_d  <= 3'd2;
                                            wa_sel_st <= 1'b0; 
                                       end
                     /*8'h07*/8'b000001zz: begin
                                            wa_sel_d  <= 3'd3;
                                            wa_sel_st <= 1'b0; 
                                       end
                     /*8'h0F*/8'b00001zzz: begin
                                            wa_sel_d  <= 3'd4;
                                            wa_sel_st <= 1'b0; 
                                       end
                     /*8'h1F*/8'b0001zzzz: begin
                                            wa_sel_d  <= 3'd5;
                                            wa_sel_st <= 1'b0; 
                                       end
                     /*8'h3F*/8'b001zzzzz: begin
                                            wa_sel_d  <= 3'd6;
                                            wa_sel_st <= 1'b0; 
                                       end
                     /*8'h7F*/8'b01zzzzzz: begin
                                            wa_sel_d  <= 3'd7;
                                            wa_sel_st <= 1'b0; 
                                       end
                     /*8'hFF*/8'b1zzzzzzz: begin
                                            wa_sel_d  <= 3'd0;
                                            wa_sel_st <= 1'b1; 
                                       end
                             default: begin
                                            wa_sel_d  <= 3'b0;
                                            wa_sel_st <= 1'b1; 
                                      end
                           endcase
                        end
                    end
            default: begin
                       wa_sel_d     <= 3'b0;
                       wa_sel_st <= 1'b0; 
                     end
            endcase
        end
    end 
 
    always @(posedge CLK or negedge aresetn)
    begin
        if((!aresetn) || (!sresetn)) begin
            WA_DATA <= {EPCS_DWIDTH{1'b0}};
        end else begin
            case(wa_sel_d)
                 3'd0: WA_DATA <= WA_DATA_buf[(EPCS_DWIDTH*2+0 )-1:EPCS_DWIDTH+0 ];  //79:0
                 3'd1: WA_DATA <= WA_DATA_buf[(EPCS_DWIDTH*2+70)-1:EPCS_DWIDTH+70];  //149:70
                 3'd2: WA_DATA <= WA_DATA_buf[(EPCS_DWIDTH*2+60)-1:EPCS_DWIDTH+60];  //139:60
                 3'd3: WA_DATA <= WA_DATA_buf[(EPCS_DWIDTH*2+50)-1:EPCS_DWIDTH+50];  //129:50
                 3'd4: WA_DATA <= WA_DATA_buf[(EPCS_DWIDTH*2+40)-1:EPCS_DWIDTH+40];  //119:40
                 3'd5: WA_DATA <= WA_DATA_buf[(EPCS_DWIDTH*2+30)-1:EPCS_DWIDTH+30];  //109:30
                 3'd6: WA_DATA <= WA_DATA_buf[(EPCS_DWIDTH*2+20)-1:EPCS_DWIDTH+20];  //99:20
                 3'd7: WA_DATA <= WA_DATA_buf[(EPCS_DWIDTH*2+10)-1:EPCS_DWIDTH+10];  //89:10
              default: WA_DATA <= WA_DATA_buf[(EPCS_DWIDTH*2+0 )-1:EPCS_DWIDTH+0 ];
            endcase
        end
    end
end
endgenerate

generate
if(SHIFT_EN == 0)
  begin
      always @(posedge CLK or negedge aresetn)
        begin
          if((!aresetn) || (!sresetn))
            begin
              WA_DATA <= {EPCS_DWIDTH{1'b0}};
            end
          else
            begin
              WA_DATA <= WA_DATA_buf[(EPCS_DWIDTH*WA_BUFF_INDEX)-1:EPCS_DWIDTH*(WA_BUFF_INDEX-1)];
            end
        end
end
endgenerate

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
//                        else if(wait_cnt == 4'hF)
//                          begin
//                            WA_FSM_STATE <= WA_SEL;
//                            wait_cnt <= 4'b0;
//                          end
                       else
                         begin
                           WA_FSM_STATE <= WA_WAIT_0;
//                           wait_cnt <= wait_cnt + 1'b1;
                           ALIGNED <= 1'b0;
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
          WA_DATA_buf <= {(EPCS_DWIDTH*3){1'b0}};
        end
      else
        begin
          case(MUX_SEL)
              5'd0 : begin
                       WA_DATA_buf <={WA_DATA_buf[EPCS_DWIDTH*2-1:0], buff_data[(2*EPCS_DWIDTH-1)+POS_NUM:EPCS_DWIDTH+0+POS_NUM]};
                     end
              5'd1 : begin
                       WA_DATA_buf <={WA_DATA_buf[EPCS_DWIDTH*2-1:0], buff_data[2*EPCS_DWIDTH+POS_NUM:EPCS_DWIDTH+1+POS_NUM]};
                     end
              5'd2 : begin
                       WA_DATA_buf <={WA_DATA_buf[EPCS_DWIDTH*2-1:0], buff_data[2*EPCS_DWIDTH+1+POS_NUM:EPCS_DWIDTH+2+POS_NUM]};
                     end
              5'd3 : begin
                       WA_DATA_buf <={WA_DATA_buf[EPCS_DWIDTH*2-1:0], buff_data[2*EPCS_DWIDTH+2+POS_NUM:EPCS_DWIDTH+3+POS_NUM]};
                     end
              5'd4 : begin
                       WA_DATA_buf <={WA_DATA_buf[EPCS_DWIDTH*2-1:0], buff_data[2*EPCS_DWIDTH+3+POS_NUM:EPCS_DWIDTH+4+POS_NUM]};
                     end
              5'd5 : begin
                       WA_DATA_buf <={WA_DATA_buf[EPCS_DWIDTH*2-1:0], buff_data[2*EPCS_DWIDTH+4+POS_NUM:EPCS_DWIDTH+5+POS_NUM]};
                     end
              5'd6 : begin
                       WA_DATA_buf <={WA_DATA_buf[EPCS_DWIDTH*2-1:0], buff_data[2*EPCS_DWIDTH+5+POS_NUM:EPCS_DWIDTH+6+POS_NUM]};
                     end
              5'd7 : begin
                       WA_DATA_buf <={WA_DATA_buf[EPCS_DWIDTH*2-1:0], buff_data[2*EPCS_DWIDTH+6+POS_NUM:EPCS_DWIDTH+7+POS_NUM]};
                     end
              5'd8 : begin
                       WA_DATA_buf <={WA_DATA_buf[EPCS_DWIDTH*2-1:0], buff_data[2*EPCS_DWIDTH+7+POS_NUM:EPCS_DWIDTH+8+POS_NUM]};
                     end
              5'd9 : begin
                       WA_DATA_buf <={WA_DATA_buf[EPCS_DWIDTH*2-1:0], buff_data[2*EPCS_DWIDTH+8+POS_NUM:EPCS_DWIDTH+9+POS_NUM]};
                     end
          5'b11111 : begin
                       WA_DATA_buf <= {(EPCS_DWIDTH*3){1'b0}};
                     end
           default : begin
                       WA_DATA_buf <= {(EPCS_DWIDTH*3){1'b0}};
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
                         if (SYNC_LOST)//(ERROR_CNT > TRIGGER-1)
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
        if((!aresetn) || (!sresetn)) begin
            ERROR_CNT  = 4'b0000;               //This ERROR_CNT assignment is kept blocking, please don't change it to non-blocking assignment type
            SYNC_LOST <= 1'b0;
        end else if ((SYNC_STATE == SYNC_2) && (ALIGNED == 1'b1)) begin
            for (i = 0; i < KWIDTH; i = i + 1)
            begin
                if (ERROR[i]) begin
                    ERROR_CNT  = ERROR_CNT + 1'b1;
                    if (ERROR_CNT > TRIGGER-1) begin
                        SYNC_LOST   <= 1'b1;
                    end
                end else begin
                    ERROR_CNT  = 4'b0000;
                end
            end
        end else begin
            ERROR_CNT   = 4'b0000;
            SYNC_LOST  <= 1'b0;
        end
    end

//  //Log of base 2
//   function integer CLogB2;
//    input [12:0] Depth;
//    integer i;
//    begin
//      i = Depth;
//      for(CLogB2 = 0; i > 0; CLogB2 = CLogB2 + 1)
//        begin
//          i = i >> 1;
//        end
//    end
//  endfunction
endmodule