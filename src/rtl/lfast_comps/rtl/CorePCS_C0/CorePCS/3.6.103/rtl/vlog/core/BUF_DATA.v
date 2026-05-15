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
// Nov12    Revision 2.0
//
// Notes:
// best viewed with tabstops set to "4"

module cpcs_buff_data(clk, rst_n, d_in, dout, k_in, kout, disp_sel_in, disp_sel_out, force_disp_in, force_disp_out);

parameter SYNC_RESET = 0;
parameter ENDEC_DWIDTH = 16;
parameter KWIDTH      = ENDEC_DWIDTH/8;    
 
input clk, rst_n; 
input [ENDEC_DWIDTH-1:0] d_in;
input [KWIDTH-1:0] disp_sel_in;
input [KWIDTH-1:0] force_disp_in;
input [KWIDTH-1:0] k_in;
output [(KWIDTH*2)-1:0] kout;
output [(KWIDTH*2)-1:0] disp_sel_out;
output [(KWIDTH*2)-1:0] force_disp_out;
output [(ENDEC_DWIDTH*2)-1:0] dout;
reg [(ENDEC_DWIDTH*2)-1:0] dout;
reg [(KWIDTH*2)-1:0] kout;
reg [(KWIDTH*2)-1:0] disp_sel_out;
reg [(KWIDTH*2)-1:0] force_disp_out;
wire aresetn;
wire sresetn; 
assign aresetn = (SYNC_RESET==1) ? 1'b1 : rst_n;
assign sresetn = (SYNC_RESET==1) ? rst_n : 1'b1;
 
always @(posedge clk or negedge aresetn)
  begin
    if((!aresetn) || (!sresetn))
	  begin
	    dout <= {ENDEC_DWIDTH/2{8'hBC}};
	  end
	else
	  begin
	    dout <= {dout[ENDEC_DWIDTH-1:0], d_in};
	  end
  end
  
always @(posedge clk or negedge aresetn)
  begin
    if((!aresetn) || (!sresetn))
	  begin
	    kout <= {KWIDTH*2{1'b1}};
	    disp_sel_out <= {KWIDTH*2{1'b0}};
	    force_disp_out <= {KWIDTH*2{1'b0}};
	  end
	else
	  begin
	    kout <= {kout[(KWIDTH*2)-1:0], k_in};
	    disp_sel_out <= {disp_sel_out[KWIDTH-1:0], disp_sel_in};
	    force_disp_out <= {force_disp_out[KWIDTH-1:0], force_disp_in};
	  end
  end
endmodule