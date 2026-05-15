//////////////////////////////////////////////////////////////////////
// Created by SmartDesign Fri May 15 15:07:51 2026
// Version: 2025.2 2025.2.0.14
//////////////////////////////////////////////////////////////////////

`timescale 1ns / 100ps

//////////////////////////////////////////////////////////////////////
// Component Description (Tcl) 
//////////////////////////////////////////////////////////////////////
/*
# Exporting Component Description of COREABC_C0 to TCL
# Family: SmartFusion2
# Part Number: M2S150T-1FC1152I
# Create and Configure the core component COREABC_C0
create_and_configure_core -core_vlnv {Actel:DirectCore:COREABC:4.1.111} -component_name {COREABC_C0} -params {\
"ABCCODE:    APBWRT DAT 0 0xa028 0x10F
    APBWRT DAT 0 0x9198 0x30
    APBWRT DAT 0 0x9000 0x80
    APBWRT DAT 0 0x9004 0x20
    APBWRT DAT 0 0x9008 0xF8
    APBWRT DAT 0 0x900c 0x80
    APBWRT DAT 0 0x9014 0x29
    APBWRT DAT 0 0x9018 0x20
    APBWRT DAT 0 0x901c 0x51
    APBWRT DAT 0 0x9020 0x2F
    APBWRT DAT 0 0x9024 0x80
    APBWRT DAT 0 0x9028 0x15
    APBWRT DAT 0 0x9030 0x10
    APBWRT DAT 0 0x9034 0x38
    APBWRT DAT 0 0x903c 0x70
    APBWRT DAT 0 0x91d4 0x2
    APBWRT DAT 0 0x91d8 0x22
    APBWRT DAT 0 0x9198 0x0
    APBWRT DAT 0 0x9200 0x1
    APBWRT DAT 0 0xa028 0xF0F
    APBWRT DAT 0 0x2000 0x1
$WaitSdifRelease
    APBREAD 0 0x2004
    AND 0x02
    JUMP IF ZERO $WaitSdifRelease
    APBWRT DAT 0 0x2000 0x3
    HALT"  \
"ACT_CALIBRATIONDATA:true"  \
"APB_AWIDTH:16"  \
"APB_DWIDTH:32"  \
"APB_SDEPTH:2"  \
"APB_TIMEOUT_COUNT:80"  \
"CODEHEXDUMP:"  \
"CODEHEXDUMP2:"  \
"DEBUG:false"  \
"EN_ACM:false"  \
"EN_ADD:true"  \
"EN_ALURAM:false"  \
"EN_AND:true"  \
"EN_CALL:true"  \
"EN_DATAM:2"  \
"EN_INC:true"  \
"EN_INDIRECT:false"  \
"EN_INT:0"  \
"EN_IOREAD:true"  \
"EN_IOWRT:true"  \
"EN_MULT:0"  \
"EN_OR:true"  \
"EN_PUSH:true"  \
"EN_RAM:true"  \
"EN_RAM_ECC:false"  \
"EN_SHL:true"  \
"EN_SHR:true"  \
"EN_XOR:true"  \
"HI_REL:false"  \
"ICWIDTH:5"  \
"IFWIDTH:0"  \
"IIWIDTH:1"  \
"IMEM_APB_ACCESS:0"  \
"INITDATAWIDTH:9"  \
"INITWIDTH:11"  \
"INSMODE:0"  \
"INVALID_STACK_ACC:true"  \
"IOWIDTH:1"  \
"ISRADDR:1"  \
"MAX_NVMDWIDTH:32"  \
"STWIDTH:4"  \
"TESTMODE:0"  \
"UNIQ_STRING:COREABC_C0_COREABC_C0_0"  \
"UNIQ_STRING_LENGTH:23"  \
"VERILOGCODE:"  \
"VERILOGVARS:"  \
"ZRWIDTH:0"   }
# Exporting Component Description of COREABC_C0 to TCL done
*/

// COREABC_C0
module COREABC_C0(
    // Inputs
    IO_IN,
    NSYSRESET,
    PCLK,
    PRDATA_M,
    PREADY_M,
    PSLVERR_M,
    // Outputs
    IO_OUT,
    PADDR_M,
    PENABLE_M,
    PRESETN,
    PSEL_M,
    PWDATA_M,
    PWRITE_M
);

//--------------------------------------------------------------------
// Input
//--------------------------------------------------------------------
input  [0:0]  IO_IN;
input         NSYSRESET;
input         PCLK;
input  [31:0] PRDATA_M;
input         PREADY_M;
input         PSLVERR_M;
//--------------------------------------------------------------------
// Output
//--------------------------------------------------------------------
output [0:0]  IO_OUT;
output [19:0] PADDR_M;
output        PENABLE_M;
output        PRESETN;
output        PSEL_M;
output [31:0] PWDATA_M;
output        PWRITE_M;
//--------------------------------------------------------------------
// Nets
//--------------------------------------------------------------------
wire   [19:0] APB3Initiator_PADDR;
wire          APB3Initiator_PENABLE;
wire   [31:0] PRDATA_M;
wire          PREADY_M;
wire          APB3Initiator_PSELx;
wire          PSLVERR_M;
wire   [31:0] APB3Initiator_PWDATA;
wire          APB3Initiator_PWRITE;
wire   [0:0]  IO_IN;
wire   [0:0]  IO_OUT_net_0;
wire          NSYSRESET;
wire          PCLK;
wire          PRESETN_net_0;
wire          PRESETN_net_1;
wire   [0:0]  IO_OUT_net_1;
wire   [19:0] APB3Initiator_PADDR_net_0;
wire          APB3Initiator_PSELx_net_0;
wire          APB3Initiator_PENABLE_net_0;
wire          APB3Initiator_PWRITE_net_0;
wire   [31:0] APB3Initiator_PWDATA_net_0;
//--------------------------------------------------------------------
// TiedOff Nets
//--------------------------------------------------------------------
wire          GND_net;
wire          VCC_net;
wire   [10:0] INITADDR_const_net_0;
wire   [8:0]  INITDATA_const_net_0;
wire   [15:0] PADDR_S_const_net_0;
wire   [31:0] PWDATA_S_const_net_0;
//--------------------------------------------------------------------
// Constant assignments
//--------------------------------------------------------------------
assign GND_net              = 1'b0;
assign VCC_net              = 1'b1;
assign INITADDR_const_net_0 = 11'h000;
assign INITDATA_const_net_0 = 9'h000;
assign PADDR_S_const_net_0  = 16'h0000;
assign PWDATA_S_const_net_0 = 32'h00000000;
//--------------------------------------------------------------------
// Top level output port assignments
//--------------------------------------------------------------------
assign PRESETN_net_1               = PRESETN_net_0;
assign PRESETN                     = PRESETN_net_1;
assign IO_OUT_net_1[0]             = IO_OUT_net_0[0];
assign IO_OUT[0:0]                 = IO_OUT_net_1[0];
assign APB3Initiator_PADDR_net_0   = APB3Initiator_PADDR;
assign PADDR_M[19:0]               = APB3Initiator_PADDR_net_0;
assign APB3Initiator_PSELx_net_0   = APB3Initiator_PSELx;
assign PSEL_M                      = APB3Initiator_PSELx_net_0;
assign APB3Initiator_PENABLE_net_0 = APB3Initiator_PENABLE;
assign PENABLE_M                   = APB3Initiator_PENABLE_net_0;
assign APB3Initiator_PWRITE_net_0  = APB3Initiator_PWRITE;
assign PWRITE_M                    = APB3Initiator_PWRITE_net_0;
assign APB3Initiator_PWDATA_net_0  = APB3Initiator_PWDATA;
assign PWDATA_M[31:0]              = APB3Initiator_PWDATA_net_0;
//--------------------------------------------------------------------
// Component instances
//--------------------------------------------------------------------
//--------COREABC_C0_COREABC_C0_0_COREABC   -   Actel:DirectCore:COREABC:4.1.111
COREABC_C0_COREABC_C0_0_COREABC #( 
        .ACT_CALIBRATIONDATA ( 1 ),
        .APB_AWIDTH          ( 16 ),
        .APB_DWIDTH          ( 32 ),
        .APB_SDEPTH          ( 2 ),
        .APB_TIMEOUT_COUNT   ( 80 ),
        .DEBUG               ( 0 ),
        .EN_ACM              ( 0 ),
        .EN_ADD              ( 1 ),
        .EN_ALURAM           ( 0 ),
        .EN_AND              ( 1 ),
        .EN_CALL             ( 1 ),
        .EN_DATAM            ( 2 ),
        .EN_INC              ( 1 ),
        .EN_INDIRECT         ( 0 ),
        .EN_INT              ( 0 ),
        .EN_IOREAD           ( 1 ),
        .EN_IOWRT            ( 1 ),
        .EN_MULT             ( 0 ),
        .EN_OR               ( 1 ),
        .EN_PUSH             ( 1 ),
        .EN_RAM              ( 1 ),
        .EN_RAM_ECC          ( 0 ),
        .EN_SHL              ( 1 ),
        .EN_SHR              ( 1 ),
        .EN_XOR              ( 1 ),
        .FAMILY              ( 19 ),
        .HI_REL              ( 0 ),
        .ICWIDTH             ( 5 ),
        .IFWIDTH             ( 0 ),
        .IIWIDTH             ( 1 ),
        .IMEM_APB_ACCESS     ( 0 ),
        .INITDATAWIDTH       ( 9 ),
        .INITWIDTH           ( 11 ),
        .INSMODE             ( 0 ),
        .INVALID_STACK_ACC   ( 1 ),
        .IOWIDTH             ( 1 ),
        .ISRADDR             ( 1 ),
        .MAX_NVMDWIDTH       ( 32 ),
        .STWIDTH             ( 4 ),
        .TESTMODE            ( 0 ),
        .UNIQ_STRING_LENGTH  ( 23 ),
        .ZRWIDTH             ( 0 ) )
COREABC_C0_0(
        // Inputs
        .INITDATVAL      ( GND_net ), // tied to 1'b0 from definition
        .INITDONE        ( VCC_net ), // tied to 1'b1 from definition
        .INTREQ          ( GND_net ), // tied to 1'b0 from definition
        .NSYSRESET       ( NSYSRESET ),
        .PCLK            ( PCLK ),
        .PREADY_M        ( PREADY_M ),
        .PSLVERR_M       ( PSLVERR_M ),
        .PSEL_S          ( GND_net ), // tied to 1'b0 from definition
        .PENABLE_S       ( GND_net ), // tied to 1'b0 from definition
        .PWRITE_S        ( GND_net ), // tied to 1'b0 from definition
        .INITADDR        ( INITADDR_const_net_0 ), // tied to 11'h000 from definition
        .INITDATA        ( INITDATA_const_net_0 ), // tied to 9'h000 from definition
        .IO_IN           ( IO_IN ),
        .PRDATA_M        ( PRDATA_M ),
        .PADDR_S         ( PADDR_S_const_net_0 ), // tied to 16'h0000 from definition
        .PWDATA_S        ( PWDATA_S_const_net_0 ), // tied to 32'h00000000 from definition
        // Outputs
        .INTACT          (  ),
        .PRESETN         ( PRESETN_net_0 ),
        .PENABLE_M       ( APB3Initiator_PENABLE ),
        .PSEL_M          ( APB3Initiator_PSELx ),
        .PWRITE_M        ( APB3Initiator_PWRITE ),
        .PREADY_S        (  ),
        .PSLVERR_S       (  ),
        .FAULT_DET       (  ),
        .DB_DETECT       (  ),
        .SB_CORRECT      (  ),
        .DB_DETECT_IRAM  (  ),
        .SB_CORRECT_IRAM (  ),
        .IO_OUT          ( IO_OUT_net_0 ),
        .PADDR_M         ( APB3Initiator_PADDR ),
        .PWDATA_M        ( APB3Initiator_PWDATA ),
        .PRDATA_S        (  ) 
        );


endmodule
