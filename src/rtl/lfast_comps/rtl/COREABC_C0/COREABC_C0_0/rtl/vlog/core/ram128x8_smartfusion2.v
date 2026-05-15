`timescale 1 ns / 100 ps
// ********************************************************************/
// Copyright 2012 Actel Corporation.  All rights reserved.
// IP Engineering
//
// ANY USE OR REDISTRIBUTION IN PART OR IN WHOLE MUST BE HANDLED IN
// ACCORDANCE WITH THE ACTEL LICENSE AGREEMENT AND MUST BE APPROVED
// IN ADVANCE IN WRITING.
//
// File:  ram128x8_smartfusion2.v
//
// Description: Simple APB Bus Controller
//              Low Level RAM Model (SmartFusion2 Family)
//
//
// SVN Revision Information:
// SVN $Revision: 46364 $
// SVN $Date: 2024-04-08 11:14:40 +0530 (Mon, 08 Apr 2024) $
//
// Notes:
//
// *********************************************************************/
module COREABC_C0_COREABC_C0_0_RAM128X8 (
    WD,
    RD,
    WADDR,
    RADDR,
    WEN,
    WCLK,
    RCLK,
    RESETN
    );

    input    [7:0]  WD;
    input    [6:0]  WADDR;
    input    [6:0]  RADDR;
    input           WEN;
    input           WCLK;
    input           RCLK;
    input           RESETN;
    output   [7:0]  RD;

    wire    [17:0]  DOUT_RAM_0;
    wire     [7:0]  RD;
    wire            VCC;
    wire            GND;

    assign RD = DOUT_RAM_0[7:0];

    VCC VCC_1_net(.Y(VCC));
    GND GND_1_net(.Y(GND));

    RAM64x18 U_RAM64x18 (
        .A_DOUT         (DOUT_RAM_0),
        .B_DOUT         (),
        .BUSY           (),
        .A_ADDR_CLK     (RCLK),
        .A_DOUT_CLK     (VCC),
        .A_ADDR_SRST_N  (VCC),
        .A_DOUT_SRST_N  (VCC),
        .A_ADDR_ARST_N  (RESETN),
        .A_DOUT_ARST_N  (VCC),
        .A_ADDR_EN      (VCC),
        .A_DOUT_EN      (VCC),
        .A_BLK          ({2'b11}),
        .A_ADDR         ({RADDR[6:0], 3'b0}),
        .B_ADDR_CLK     (VCC),
        .B_DOUT_CLK     (VCC),
        .B_ADDR_SRST_N  (VCC),
        .B_DOUT_SRST_N  (VCC),
        .B_ADDR_ARST_N  (VCC),
        .B_DOUT_ARST_N  (VCC),
        .B_ADDR_EN      (VCC),
        .B_DOUT_EN      (VCC),
        .B_BLK          ({2'b0}),
        .B_ADDR         ({10'b0}),
        .C_CLK          (WCLK),
        .C_ADDR         ({WADDR[6:0],3'b0}),
        .C_DIN          ({10'b0, WD[7:0]}),
        .C_WEN          (WEN),
        .C_BLK          ({2'b11}),
        .A_EN           (VCC),
        .A_ADDR_LAT     (GND),
        .A_DOUT_LAT     (VCC),
        .B_EN           (VCC),
        .B_ADDR_LAT     (GND),
        .B_DOUT_LAT     (VCC),
        .C_EN           (VCC),
        .A_WIDTH        ({3'b011}),
        .B_WIDTH        ({3'b011}),
        .C_WIDTH        ({3'b011}),
        .SII_LOCK       (GND)
    );
endmodule
