`timescale 1ns / 100ps

// ********************************************************************
//  Microsemi Corporation Proprietary and Confidential
//  Copyright 2012 Microsemi Corporation.  All rights reserved.
//
// ANY USE OR REDISTRIBUTION IN PART OR IN WHOLE MUST BE HANDLED IN
// ACCORDANCE WITH THE MICROSEMI LICENSE AGREEMENT AND MUST BE APPROVED
// IN ADVANCE IN WRITING.
//
// Description: CorePCS IP core
//
// Revision Information:
// Date     Description
// Nov12    Revision 2.0
//
// Notes:
// best viewed with tabstops set to "4"

module testbench();
`include "../../../../coreparameters.v"

//Parameters  
 parameter K_WIDTH  = (EPCS_DWIDTH/10);      // 0 = 1 port, 1 = 2 port
 parameter NOC_20   = (PROG_COMMA_EN == 1) ? NO_OF_COMMAS : 10;
 parameter NOC_10   = (PROG_COMMA_EN == 1) ? NO_OF_COMMAS : 3;
//testbench parameters
 parameter DIV_VAL  = (EPCS_DWIDTH   == 10) ? 10 : 20;
 
//Reset 
 reg RESET_N;
 reg WA_RSTn;
 
//EPCS Control Signals
 reg EPCS_READY;
 wire EPCS_PWRDN;
 wire EPCS_TXOOB;

//EPCS Tx Channel
 reg EPCS_TxRSTn;
 wire EPCS_TxVAL;
 wire[EPCS_DWIDTH-1:0] EPCS_TxDATA;

//EPCS Rx Channel
 reg EPCS_RxRSTn;
 reg EPCS_RxVAL;
 wire [EPCS_DWIDTH-1:0] EPCS_RxDATA;
 reg [EPCS_DWIDTH-1:0] EPCS_RxDATA_reg;
 reg EPCS_RxIDLE;
 wire EPCS_RxERR;

//8B10B Encoder
 reg [ENDEC_DWIDTH-1:0] TX_DATA;
 reg [IO_SIZE:0] TX_K_CHAR;
 wire [IO_SIZE:0] INVALID_K;
   
//8B10B Decoder
 wire [ENDEC_DWIDTH-1:0] RX_DATA;
 wire [IO_SIZE:0] CODE_ERR_N;
 wire [IO_SIZE:0] RX_K_CHAR;
 wire [IO_SIZE:0] B_CERR;
 wire [IO_SIZE:0] RD_ERR;
 
 // Tx Disparity Control
 reg [IO_SIZE:0] FORCE_DISP;
 reg [IO_SIZE:0] DISP_SEL;   //0=RD-, 1=RD+
 
 // Word Aligner
 wire ALIGNED;
 
 
 
//testbench regs & wires
 integer i, j, x, y, sd, num;
 reg CLK_IN;
 reg [ENDEC_DWIDTH-1:0] mem_8B_rx [0:2095];
 reg [ENDEC_DWIDTH-1:0] mem_8B_tx [0:2095];
 reg [EPCS_DWIDTH-1:0] mem_10B_rx [0:2095];
 reg [EPCS_DWIDTH-1:0] mem_10B_tx [0:2095];
 reg [EPCS_DWIDTH*2:0] EPCS_TxDATA_buffer;
 reg [EPCS_DWIDTH-1:0] EXP_TX_ENC [0:10];
 reg [9:0] RD10 [0:10];
 reg [ENDEC_DWIDTH-1:0] EXP_RX_DATA [0:9];
 wire [15:0] comma_symbol_tx;
 wire [19:0] comma_symbol_rx_pn;
 wire [9:0]  comma_symbol_rx_n;
 wire [9:0]  comma_symbol_rx_p;
 
 assign comma_symbol_tx    = (COMMA_DETECT_SEL == 0) ? 16'hBCBC  : (COMMA_DETECT_SEL == 1) ? 16'h3C3C : (COMMA_DETECT_SEL == 3) ? 16'hFCFC : 16'hBCBC ;
 assign comma_symbol_rx_pn = (COMMA_DETECT_SEL == 0) ? 20'ha0d7c : (COMMA_DETECT_SEL == 1) ? 20'h60e7c: (COMMA_DETECT_SEL == 3) ? 20'he0c7c: 20'ha0d7c;
 assign comma_symbol_rx_p  = (COMMA_DETECT_SEL == 0) ? 10'h283   : (COMMA_DETECT_SEL == 1) ? 10'h183  : (COMMA_DETECT_SEL == 3) ? 10'h383  : 10'h283; 
 assign comma_symbol_rx_n  = (COMMA_DETECT_SEL == 0) ? 10'h17c   : (COMMA_DETECT_SEL == 1) ? 10'h27c  : (COMMA_DETECT_SEL == 3) ? 10'h07c  : 10'h17c; 
 assign EPCS_RxDATA        = (LANE_MODE == 2)        ? EPCS_TxDATA_buffer[EPCS_DWIDTH-1:0] : EPCS_RxDATA_reg; 

initial
  begin
    //Initialize Expected Encoded Data For Transmitter Only Test
    EXP_TX_ENC[0]  = {EPCS_DWIDTH/DIV_VAL{20'h8da36}}; EXP_TX_ENC[1] = {EPCS_DWIDTH/DIV_VAL{20'h29ca7}}; EXP_TX_ENC[2] = {EPCS_DWIDTH/DIV_VAL{20'h2d374}}; EXP_TX_ENC[3] = {EPCS_DWIDTH/DIV_VAL{20'h9364d}}; EXP_TX_ENC[4] = {EPCS_DWIDTH/DIV_VAL{20'h9925b}}; 
    EXP_TX_ENC[5]  = {EPCS_DWIDTH/DIV_VAL{20'haaaaa}}; EXP_TX_ENC[6] = {EPCS_DWIDTH/DIV_VAL{20'ha96a5}}; EXP_TX_ENC[7] = {EPCS_DWIDTH/DIV_VAL{20'h3532b}}; EXP_TX_ENC[8] = {EPCS_DWIDTH/DIV_VAL{20'h354d5}}; EXP_TX_ENC[9] = {EPCS_DWIDTH/DIV_VAL{20'h52576}};
    EXP_TX_ENC[10] = {EPCS_DWIDTH/DIV_VAL{20'h2e4b9}};

    RD10[0]  = 10'h236; RD10[1]  = 10'h0a7; RD10[2]  = 10'h374; RD10[3]  = 10'h24d; RD10[4]  = 10'h264; 
    RD10[5]  = 10'h2aa; RD10[6]  = 10'h2a5; RD10[7]  = 10'h32b; RD10[8]  = 10'h315; RD10[9]  = 10'h149;
    RD10[10] = 10'h0b9;

    //Initialize Expected Received Data For Receiver Only Test
    EXP_RX_DATA[0] = {EPCS_DWIDTH/DIV_VAL{16'hF0F0}}; EXP_RX_DATA[1] = {EPCS_DWIDTH/DIV_VAL{16'h0808}}; EXP_RX_DATA[2] = {EPCS_DWIDTH/DIV_VAL{16'h1414}}; EXP_RX_DATA[3] = {EPCS_DWIDTH/DIV_VAL{16'h2D2D}}; EXP_RX_DATA[4] = {EPCS_DWIDTH/DIV_VAL{16'h3B3B}};
    EXP_RX_DATA[5] = {EPCS_DWIDTH/DIV_VAL{16'h4A4A}}; EXP_RX_DATA[6] = {EPCS_DWIDTH/DIV_VAL{16'h4545}}; EXP_RX_DATA[7] = {EPCS_DWIDTH/DIV_VAL{16'h6464}}; EXP_RX_DATA[8] = {EPCS_DWIDTH/DIV_VAL{16'h7575}}; EXP_RX_DATA[9] = {EPCS_DWIDTH/DIV_VAL{16'hB0B0}};

    EPCS_TxDATA_buffer = 40'b0;
    RESET_N = 1'b0;
    WA_RSTn = 1'b0;
    EPCS_READY = 1'b1;
    EPCS_TxRSTn = 1'b0;
    CLK_IN = 1'b0;
    EPCS_RxRSTn = 1'b0;
    EPCS_RxVAL = 1'b1;
    EPCS_RxDATA_reg = {EPCS_DWIDTH{1'b0}};
    EPCS_RxIDLE = 1'b0;
    TX_DATA = {ENDEC_DWIDTH{1'b0}};
    TX_K_CHAR = {K_WIDTH{1'b0}};
    FORCE_DISP = {IO_SIZE+1{1'b0}};
    DISP_SEL = {IO_SIZE+1{1'b0}};
    sd = 0;
    i = 0;
    j = 0;
    x = 0;
    y = 0;
    num = 0;
    #50
    RESET_N = 1'b1;
    EPCS_TxRSTn = 1'b1;
    EPCS_RxRSTn = 1'b1;
    WA_RSTn = 1'b1;

    // Allow Sync Reset to complete
    repeat(4)@(posedge CLK_IN);

    if(LANE_MODE == 0)
      begin
        if(EPCS_DWIDTH >= 20)
          begin  
          //Transmit /K/ symbols for word alignment
            repeat(20)
              begin  
                TX_DATA = {EPCS_DWIDTH/DIV_VAL{comma_symbol_tx}};
                TX_K_CHAR = {K_WIDTH{1'b1}};
                @(posedge CLK_IN);
              end
            TX_K_CHAR = {K_WIDTH{1'b0}};  

          //Transmit Data
            TX_DATA = {EPCS_DWIDTH/DIV_VAL{16'hF0F0}}; @(posedge CLK_IN);
            TX_DATA = {EPCS_DWIDTH/DIV_VAL{16'h0808}}; @(posedge CLK_IN);
            TX_DATA = {EPCS_DWIDTH/DIV_VAL{16'h1414}}; @(posedge CLK_IN);
            TX_DATA = {EPCS_DWIDTH/DIV_VAL{16'h2D2D}}; @(posedge CLK_IN);
            TX_DATA = {EPCS_DWIDTH/DIV_VAL{16'h3B3B}}; @(posedge CLK_IN);
            TX_DATA = {EPCS_DWIDTH/DIV_VAL{16'h4A4A}}; @(posedge CLK_IN);
            TX_DATA = {EPCS_DWIDTH/DIV_VAL{16'h4545}}; @(posedge CLK_IN);
            TX_DATA = {EPCS_DWIDTH/DIV_VAL{16'h6464}}; @(posedge CLK_IN); 
            TX_DATA = {EPCS_DWIDTH/DIV_VAL{16'h7575}}; @(posedge CLK_IN);
            TX_DATA = {EPCS_DWIDTH/DIV_VAL{16'hB0B0}}; @(posedge CLK_IN);
            TX_DATA = {EPCS_DWIDTH/DIV_VAL{16'h0000}};

            repeat(15) @(posedge CLK_IN or negedge CLK_IN);
          //Compare Transmitted Symbol To Expected Transmitted Symbol
            $display("################################################");
            $display("###          START TX DATA COMPARE           ###");
            $display("################################################");
            while(x < 10)
              begin
                $display("%d - Expected Data : %h", x, EXP_TX_ENC[x]);
                $display("%d - Received Data : %h", x, mem_10B_tx[x]);
                if(mem_10B_tx[x] == EXP_TX_ENC[x])
                  begin
                    $display("Data Matched");
                    @(posedge CLK_IN or negedge CLK_IN);
                  end
                else
                  begin
                    $display("Data Mismatch - TEST FAILED");
                    $stop;
                    $finish;
                  end
                x = x + 1;
              end
            $display("################################################");
            $display("###      Compare Finished - TEST PASSED      ###");
            $display("################################################");
            $display("");
          end
        else
          begin
          //Transmit /K/ symbols for word alignment
            repeat(20)
              begin
                TX_DATA = comma_symbol_tx[7:0];
                TX_K_CHAR = 1'b1;
                @(posedge CLK_IN);
            end
            TX_K_CHAR = 1'b0;  
        
          //Transmit Data
            TX_DATA = 8'hF0; @(posedge CLK_IN);
            TX_DATA = 8'h08; @(posedge CLK_IN);
            TX_DATA = 8'h14; @(posedge CLK_IN);
            TX_DATA = 8'h2D; @(posedge CLK_IN);
            TX_DATA = 8'h3B; @(posedge CLK_IN);
            TX_DATA = 8'h4A; @(posedge CLK_IN);
            TX_DATA = 8'h45; @(posedge CLK_IN);
            TX_DATA = 8'h64; @(posedge CLK_IN);
            TX_DATA = 8'h75; @(posedge CLK_IN);
            TX_DATA = 8'hB0; @(posedge CLK_IN);
            TX_DATA = 8'h0;
            repeat(5) @(posedge CLK_IN or negedge CLK_IN);
          //Compare Transmitted Symbol To Expected Transmitted Symbol
            $display("################################################");
            $display("###          START TX DATA COMPARE           ###");
            $display("################################################");
            while(x < 10)
              begin
                $display("%d - Expected Data : %h", x, RD10[x]);
                $display("%d - Received Data : %h", x, mem_10B_tx[x]);
                if(mem_10B_tx[x] == RD10[x])
                  begin
                    $display("Data Matched");
                    @(posedge CLK_IN or negedge CLK_IN);
                  end
                else
                  begin
                    $display("Data Mismatch - TEST FAILED");
                    $stop;
                    $finish;
                  end
                x = x + 1;
              end
            $display("################################################");
            $display("###      Compare Finished - TEST PASSED      ###");
            $display("################################################");
            $display("");
          end
      end 
    else if(LANE_MODE == 1)
      begin
        if(EPCS_DWIDTH >= 20)
          begin  
          //Received /K/ symbols for word alignment
            repeat((NOC_20%2==0)? (NOC_20/2) :(NOC_20/2+1))
              begin  
                EPCS_RxDATA_reg = {EPCS_DWIDTH/DIV_VAL{comma_symbol_rx_pn}};
                @(posedge CLK_IN);
              end
          //Received Data
            EPCS_RxDATA_reg = {EPCS_DWIDTH/DIV_VAL{20'h8da36}}; @(posedge CLK_IN);
            EPCS_RxDATA_reg = {EPCS_DWIDTH/DIV_VAL{20'h29ca7}}; @(posedge CLK_IN);
            EPCS_RxDATA_reg = {EPCS_DWIDTH/DIV_VAL{20'h2d374}}; @(posedge CLK_IN);
            EPCS_RxDATA_reg = {EPCS_DWIDTH/DIV_VAL{20'h9364d}}; @(posedge CLK_IN);
            EPCS_RxDATA_reg = {EPCS_DWIDTH/DIV_VAL{20'h9925b}}; @(posedge CLK_IN);
            EPCS_RxDATA_reg = {EPCS_DWIDTH/DIV_VAL{20'haaaaa}}; @(posedge CLK_IN);
            EPCS_RxDATA_reg = {EPCS_DWIDTH/DIV_VAL{20'ha96a5}}; @(posedge CLK_IN);
            EPCS_RxDATA_reg = {EPCS_DWIDTH/DIV_VAL{20'h3532b}}; @(posedge CLK_IN);
            EPCS_RxDATA_reg = {EPCS_DWIDTH/DIV_VAL{20'h354d5}}; @(posedge CLK_IN);
            EPCS_RxDATA_reg = {EPCS_DWIDTH/DIV_VAL{20'h52576}}; @(posedge CLK_IN);
            EPCS_RxDATA_reg = {EPCS_DWIDTH/DIV_VAL{20'h2e4b9}}; 
            repeat(20) @(posedge CLK_IN);
          //Compare Received Data To Expected Received Data
            $display("################################################");
            $display("###          START RX DATA COMPARE           ###");
            $display("################################################");
            while(x < 10)
              begin
                $display("%d - Expected Data : %h", x, EXP_RX_DATA[x]);
                $display("%d - Received Data : %h", x, mem_8B_rx[x]);
                if(mem_8B_rx[x] == EXP_RX_DATA[x])
                  begin
                    $display("Data Matched");
                    @(posedge CLK_IN or negedge CLK_IN);
                  end
                else
                  begin
                    $display("Data Mismatch - TEST FAILED");
                    $stop;
                    $finish;
                  end
                x = x + 1;
              end
            $display("################################################");
            $display("###      Compare Finished - TEST PASSED      ###");
            $display("################################################");
          end
        else
          begin
          //Received /K/ symbols for word alignment
            repeat(NOC_10/2+1)
              begin  
                EPCS_RxDATA_reg = comma_symbol_rx_n[9:0];
                @(posedge CLK_IN);
                EPCS_RxDATA_reg = comma_symbol_rx_p[9:0];
                @(posedge CLK_IN);
              end

          //Received Data
            EPCS_RxDATA_reg = 10'h236; @(posedge CLK_IN);
            EPCS_RxDATA_reg = 10'h0a7; @(posedge CLK_IN);
            EPCS_RxDATA_reg = 10'h374; @(posedge CLK_IN);
            EPCS_RxDATA_reg = 10'h24d; @(posedge CLK_IN);
            EPCS_RxDATA_reg = 10'h264; @(posedge CLK_IN);
            EPCS_RxDATA_reg = 10'h2aa; @(posedge CLK_IN);
            EPCS_RxDATA_reg = 10'h2a5; @(posedge CLK_IN);
            EPCS_RxDATA_reg = 10'h32b; @(posedge CLK_IN);
            EPCS_RxDATA_reg = 10'h315; @(posedge CLK_IN);
            EPCS_RxDATA_reg = 10'h149; @(posedge CLK_IN);
            EPCS_RxDATA_reg = 10'h0b9;   //Can use this encoded data here because + and - are the same
            repeat(10) @(posedge CLK_IN);
          //Compare Received Data To Expected Received Data
            $display("################################################");
            $display("###          START RX DATA COMPARE           ###");
            $display("################################################");
            while(x < 10)
              begin
                $display("%d - Expected Data : %h", x, EXP_RX_DATA[x][7:0]);
                $display("%d - Received Data : %h", x, mem_8B_rx[x]);
                if(mem_8B_rx[x] == EXP_RX_DATA[x][7:0])
                  begin
                    $display("Data Matched");
                    @(posedge CLK_IN or negedge CLK_IN);
                  end
                else
                  begin
                    $display("Data Mismatch - TEST FAILED");
                    $stop;
                    $finish;
                  end
                x = x + 1;
              end
            $display("################################################");
            $display("###      Compare Finished - TEST PASSED      ###");
            $display("################################################");
          end     
      end 
    else if(LANE_MODE == 2)
      begin
        if(EPCS_DWIDTH >= 20)
          begin  
          //Transmit /K/ symbols for word alignment
            repeat((NOC_20%2==1)? (NOC_20/2+1) :(NOC_20/2))
              begin  
                TX_DATA   = {EPCS_DWIDTH/DIV_VAL{comma_symbol_tx}};
                TX_K_CHAR = {K_WIDTH{1'b1}};
                @(posedge CLK_IN);
              end
            TX_K_CHAR = {K_WIDTH{1'b0}};
            
          //Transmit Data
            TX_DATA = 20'd1;
            repeat(30)
              begin  
                TX_DATA = 1'h1 + {$random} % (20'hFFFFF - 1'h1) ;
                sd = sd + 1;
                @(posedge CLK_IN);
              end
          end
        else
          begin
          //Transmit /K/ symbols for word alignment
            repeat(NOC_10)
              begin
                TX_DATA = comma_symbol_tx[7:0];
                TX_K_CHAR = 1'b1;
                @(posedge CLK_IN);
              end
            TX_K_CHAR = {K_WIDTH{1'b0}};
          //Transmit Data
            TX_DATA = 20'd1;
            repeat(30)
              begin  
                //TX_DATA = TX_DATA + 1'b1;
                TX_DATA = 1'h1 + {$random} % (10'h3FF - 1'h1) ;
                sd = sd + 1;
                @(posedge CLK_IN);
              end
          end
        repeat(8) @(posedge CLK_IN);
        //Compare Received Data To Transmitted Data 
        $display("######################################");
        $display("###   START TX-2-RX DATA COMPARE   ###");
        $display("######################################");
        while(x < sd)
          begin
            $display("%d - Expected Data : %h", x, mem_8B_tx[x]);
            $display("%d - Received Data : %h", x, mem_8B_rx[x]);
            if(mem_8B_tx[x] == mem_8B_rx[x])
              begin
                $display("Data Matched");
                @(posedge CLK_IN or negedge CLK_IN);
              end
            else
              begin
                $display("Data Mismatch - TEST FAILED");
                $stop;
                $finish;
              end
            x = x + 1;
          end
        $display("################################################");
        $display("###      Compare Finished - TEST PASSED      ###");
        $display("################################################");
        $display("");
      end
    
    #1
    $stop;
    $finish;
  end

  always @(posedge CLK_IN)
    begin
	  if(LANE_MODE == 2)
	    begin 
          EPCS_TxDATA_buffer = {EPCS_TxDATA, EPCS_TxDATA_buffer[(EPCS_DWIDTH*2)-1:EPCS_DWIDTH]};
		end
	  else
	    begin
		  EPCS_TxDATA_buffer = {EPCS_RxDATA_reg, EPCS_TxDATA_buffer[(EPCS_DWIDTH*2)-1:EPCS_DWIDTH]};
		end
    end
 
always
  begin
    CLK_IN = #10 ~CLK_IN;
  end
 
always @(posedge CLK_IN)
  begin
    if(EPCS_DWIDTH >= 20)
      begin
        //Ignore zero and comma data transmitted
        if((TX_DATA != 0) && (TX_K_CHAR == {K_WIDTH{1'b0}}))
          begin
            mem_8B_tx[i] <= TX_DATA;
            i = i + 1;
          end
       end
    else
      begin
        //Ignore zero and comma data transmitted
        if((TX_DATA != 0) && (TX_K_CHAR == 1'b0))
          begin
            mem_8B_tx[i] <= TX_DATA;
            i = i + 1;
          end
      end
  end

always @(posedge CLK_IN)
  begin
    if(EPCS_DWIDTH >= 20)
      begin 
        //Ignore zero and comma encoding                                                                                                                                                               
        if((EPCS_TxDATA != {EPCS_DWIDTH/DIV_VAL{20'h60E7C}}) && (EPCS_TxDATA != {EPCS_DWIDTH/DIV_VAL{20'h9F183}}) && (EPCS_TxDATA != {EPCS_DWIDTH/DIV_VAL{20'hA0D7C}}) && (EPCS_TxDATA != {EPCS_DWIDTH/DIV_VAL{20'h5F283}}) && (EPCS_TxDATA != {EPCS_DWIDTH/DIV_VAL{20'h2f0bc}}))  
          begin 
            mem_10B_tx[y] <= EPCS_TxDATA;
            y = y + 1;
          end
      end
    else
      begin
        //Ignore zero and comma encoding
        if((EPCS_TxDATA != 10'h27c) && (EPCS_TxDATA != 10'h183) && (EPCS_TxDATA != 10'h17c) && (EPCS_TxDATA != 10'h283) && (EPCS_TxDATA != 10'h0bc))  
          begin
            mem_10B_tx[y] <= EPCS_TxDATA;
            y = y + 1;
          end            
      end  
  end

always @(posedge CLK_IN)
  begin
    if(EPCS_DWIDTH >= 20)
      begin
        //Ignore zero and comma data received
        if((RX_DATA != {ENDEC_DWIDTH{1'b0}}) && (RX_K_CHAR == 2'b0))
          begin
            mem_8B_rx[j] <= RX_DATA;
            j = j + 1;
          end
      end
    else
      begin
        //Ignore zero and comma data received
        if((RX_DATA != {ENDEC_DWIDTH{1'b0}}) && (RX_K_CHAR == 1'b0))
          begin
            mem_8B_rx[j] <= RX_DATA;
            j = j + 1;
          end
      end
  end  
CorePCS #( .LANE_MODE(LANE_MODE),
           .EPCS_DWIDTH(EPCS_DWIDTH),
           .ENDEC_DWIDTH(ENDEC_DWIDTH),
           .IO_SIZE(IO_SIZE),
		   .SHIFT_EN(1),
		   .NO_OF_COMMAS(NO_OF_COMMAS),
		   .PROG_COMMA_EN(PROG_COMMA_EN),
		   .COMMA_DETECT_SEL(COMMA_DETECT_SEL)
          ) u_corepcs ( .RESET_N(RESET_N),
		                .WA_RSTn(WA_RSTn),
                       //EPCS Control Signals
                        .EPCS_READY(EPCS_READY),
                        .EPCS_PWRDN(EPCS_PWRDN),
                        .EPCS_TXOOB(EPCS_TXOOB),
                       //EPCS Tx Channel
                        .EPCS_TxRSTn(EPCS_TxRSTn),
                        .EPCS_TxCLK(CLK_IN),
                        .EPCS_TxVAL(EPCS_TxVAL),
                        .EPCS_TxDATA(EPCS_TxDATA),
                       //EPCS Rx Channel
                        .EPCS_RxRSTn(EPCS_RxRSTn),
                        .EPCS_RxCLK(CLK_IN),
                        .EPCS_RxVAL(EPCS_RxVAL),
                        .EPCS_RxDATA(EPCS_RxDATA),
                        .EPCS_RxIDLE(EPCS_RxIDLE),
                        .EPCS_RxERR(EPCS_RxERR),
                       //8B10B Encoder
                        .TX_DATA(TX_DATA),
                        .TX_K_CHAR(TX_K_CHAR),
                        .INVALID_K(INVALID_K),
                       //8B10B Decoder
                        .RX_DATA(RX_DATA),
                        .CODE_ERR_N(CODE_ERR_N),
                        .RX_K_CHAR(RX_K_CHAR),
                        .B_CERR(B_CERR),
                        .RD_ERR(RD_ERR),
                       //Tx Disparity Control
                        .FORCE_DISP(FORCE_DISP),
                        .DISP_SEL(DISP_SEL),
					   //Word Aligner
					    .ALIGNED(ALIGNED)
);
   
endmodule
