`timescale 1 ns / 100 ps
// ********************************************************************/
// Copyright 2008 Actel Corporation.  All rights reserved.
// IP Engineering
//
// ANY USE OR REDISTRIBUTION IN PART OR IN WHOLE MUST BE HANDLED IN
// ACCORDANCE WITH THE ACTEL LICENSE AGREEMENT AND MUST BE APPROVED
// IN ADVANCE IN WRITING.
//
// File:  iram512x9_rtl.vhd
//
// Description: Simple APB Bus Controller
//              Instruction RAM model
//
// Rev: 2.4   24Jan08 IPB  : Production Release
//
// SVN Revision Information:
// SVN $Revision: 46364 $
// SVN $Date: 2024-04-08 11:14:40 +0530 (Mon, 08 Apr 2024) $
//
// Notes:
//   Supports initialisation from interface and RAM file
//
//
// *********************************************************************/

module COREABC_C0_COREABC_C0_0_IRAM512X9 (RWCLK, RESET, RENABLE, RADDR, RD, INITADDR, WENABLE, INITDATA);

    parameter CID  = 0;
    parameter RID  = 0;
    parameter UNIQ_STRING_LENGTH = 10;

    input RWCLK;
    input RESET;
    input RENABLE;
    input[8:0] RADDR;
    output[8:0] RD;
    input[8:0] INITADDR;
    input WENABLE;
    input[8:0] INITDATA;

    reg[8:0] RD;

    localparam[1:(10)*8] CHARACTER = "0123456789";
    localparam[1:(UNIQ_STRING_LENGTH+11)*8] RAMFILE = {"COREABC_C0_COREABC_C0_0_RAM_", CHARACTER[RID*8+1:RID*8+8],CHARACTER[CID*8+1:CID*8+8], ".mem"};
    localparam[1:(UNIQ_STRING_LENGTH+11)*8] RAMFILE2 = {"COREABC_C0_COREABC_C0_0_RAM_", CHARACTER[((RID/10)%10)*8+1:((RID/10)%10)*8+8], CHARACTER[(RID%10)*8+1:(RID%10)*8+8],CHARACTER[CID*8+1:CID*8+8], ".mem"};
    localparam[1:(UNIQ_STRING_LENGTH+11)*8] RAMFILE3 = {"COREABC_C0_COREABC_C0_0_RAM_", CHARACTER[((RID/100)%10)*8+1:((RID/100)%10)*8+8], CHARACTER[((RID/100)%10)*8+1:((RID/100)%10)*8+8], CHARACTER[(RID%100)*8+1:(RID%100)*8+8],CHARACTER[CID*8+1:CID*8+8], ".mem"};

   	integer INITDONE;

    initial INITDONE =0;

    always @(posedge RWCLK)
    begin : xhdl_2
        reg[8:0] RAM[0:511] /* synthesis syn_ramstyle = lsram */;
        reg[8:0] iaddr;
       	integer i;

        // synthesis translate_off
        // RAM Initialisation
        if (INITDONE != 1234)
        begin
		if(RID>99)
		begin
        	 $display("Loading %s",RAMFILE3);
        	 $readmemb( RAMFILE3, RAM);
		end
		else if(RID>9)
		begin
        	 $display("Loading %s",RAMFILE2);
        	 $readmemb( RAMFILE2, RAM);
		end
		else begin
        	 $display("Loading %s",RAMFILE);
        	 $readmemb( RAMFILE, RAM);
		end
	      	 INITDONE = 1234;
        end
        // synthesis translate_on

        if (WENABLE==1'b1)
        begin
            iaddr = INITADDR;
            RAM[iaddr] = INITDATA;
        end

        iaddr = RADDR;
        RD <= RAM[iaddr] ;

    end

endmodule
