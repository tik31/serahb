`timescale 1 ns/100 ps
// Version: 2025.2 2025.2.0.14


module SERDES_IF_C0_SERDES_IF_C0_0_SERDES_IF(
       RXD0_P,
       RXD0_N,
       RXD1_P,
       RXD1_N,
       RXD2_P,
       RXD2_N,
       RXD3_P,
       RXD3_N,
       TXD0_P,
       TXD0_N,
       TXD1_P,
       TXD1_N,
       TXD2_P,
       TXD2_N,
       TXD3_P,
       TXD3_N,
       APB_S_PRDATA,
       APB_S_PREADY,
       APB_S_PSLVERR,
       APB_S_PADDR,
       APB_S_PENABLE,
       APB_S_PSEL,
       APB_S_PWDATA,
       APB_S_PWRITE,
       APB_S_PCLK,
       APB_S_PRESET_N,
       EPCS_FAB_REF_CLK,
       EPCS_0_READY,
       EPCS_0_TX_CLK_STABLE,
       EPCS_0_TX_CLK,
       EPCS_0_RX_CLK,
       EPCS_0_PWRDN,
       EPCS_0_TX_OOB,
       EPCS_0_TX_VAL,
       EPCS_0_RX_ERR,
       EPCS_0_RX_VAL,
       EPCS_0_RX_IDLE,
       EPCS_0_RESET_N,
       EPCS_0_TX_RESET_N,
       EPCS_0_RX_RESET_N,
       EPCS_0_RX_DATA,
       EPCS_0_TX_DATA
    );
input  RXD0_P;
input  RXD0_N;
input  RXD1_P;
input  RXD1_N;
input  RXD2_P;
input  RXD2_N;
input  RXD3_P;
input  RXD3_N;
output TXD0_P;
output TXD0_N;
output TXD1_P;
output TXD1_N;
output TXD2_P;
output TXD2_N;
output TXD3_P;
output TXD3_N;
output [31:0] APB_S_PRDATA;
output APB_S_PREADY;
output APB_S_PSLVERR;
input  [13:2] APB_S_PADDR;
input  APB_S_PENABLE;
input  APB_S_PSEL;
input  [31:0] APB_S_PWDATA;
input  APB_S_PWRITE;
input  APB_S_PCLK;
input  APB_S_PRESET_N;
input  EPCS_FAB_REF_CLK;
output EPCS_0_READY;
output EPCS_0_TX_CLK_STABLE;
output EPCS_0_TX_CLK;
output EPCS_0_RX_CLK;
input  EPCS_0_PWRDN;
input  EPCS_0_TX_OOB;
input  EPCS_0_TX_VAL;
input  EPCS_0_RX_ERR;
output EPCS_0_RX_VAL;
output EPCS_0_RX_IDLE;
input  EPCS_0_RESET_N;
output EPCS_0_TX_RESET_N;
output EPCS_0_RX_RESET_N;
output [9:0] EPCS_0_RX_DATA;
input  [9:0] EPCS_0_TX_DATA;

    wire gnd_net, vcc_net;
    
    VCC vcc_inst (.Y(vcc_net));
    GND gnd_inst (.Y(gnd_net));
    SERDESIF_120_0 #( .INIT(610'h0000000000000000000000000000000000000000000000000000000003781E0000000000000000000000000000000000000022787FFFA800000000007C3F9D64A0081FFFFFFFFFEFFFFFFFFFF)
        , .ACT_CONFIG("SERDESIF_0"), .ACT_SIM(2) )  SERDESIF_INST (
        .APB_PRDATA({APB_S_PRDATA[31], APB_S_PRDATA[30], 
        APB_S_PRDATA[29], APB_S_PRDATA[28], APB_S_PRDATA[27], 
        APB_S_PRDATA[26], APB_S_PRDATA[25], APB_S_PRDATA[24], 
        APB_S_PRDATA[23], APB_S_PRDATA[22], APB_S_PRDATA[21], 
        APB_S_PRDATA[20], APB_S_PRDATA[19], APB_S_PRDATA[18], 
        APB_S_PRDATA[17], APB_S_PRDATA[16], APB_S_PRDATA[15], 
        APB_S_PRDATA[14], APB_S_PRDATA[13], APB_S_PRDATA[12], 
        APB_S_PRDATA[11], APB_S_PRDATA[10], APB_S_PRDATA[9], 
        APB_S_PRDATA[8], APB_S_PRDATA[7], APB_S_PRDATA[6], 
        APB_S_PRDATA[5], APB_S_PRDATA[4], APB_S_PRDATA[3], 
        APB_S_PRDATA[2], APB_S_PRDATA[1], APB_S_PRDATA[0]}), 
        .APB_PREADY(APB_S_PREADY), .APB_PSLVERR(APB_S_PSLVERR), 
        .ATXCLKSTABLE({nc0, nc1}), .EPCS_READY({nc2, nc3}), 
        .EPCS_RXCLK({nc4, nc5}), .EPCS_RXCLK_0(EPCS_0_RX_CLK), 
        .EPCS_RXCLK_1(), .EPCS_RXDATA({nc6, nc7, nc8, nc9, nc10, nc11, 
        nc12, nc13, nc14, nc15, nc16, nc17, nc18, nc19, nc20, nc21, 
        nc22, nc23, nc24, nc25, nc26, nc27, nc28, nc29, nc30, nc31, 
        nc32, nc33, nc34, nc35, nc36, nc37, nc38, nc39, nc40, nc41, 
        nc42, nc43, nc44, nc45}), .EPCS_RXIDLE({nc46, nc47}), 
        .EPCS_RXRSTN({nc48, nc49}), .EPCS_RXVAL({nc50, nc51}), 
        .EPCS_TXCLK({nc52, nc53}), .EPCS_TXCLK_0(EPCS_0_TX_CLK), 
        .EPCS_TXCLK_1(), .EPCS_TXRSTN({nc54, nc55}), .FATC_RESET_N(), 
        .H2FCALIB0(), .H2FCALIB1(), .M_ARADDR({nc56, nc57, nc58, nc59, 
        nc60, nc61, nc62, nc63, nc64, nc65, nc66, nc67, nc68, nc69, 
        nc70, nc71, nc72, nc73, nc74, nc75, nc76, nc77, nc78, nc79, 
        nc80, nc81, nc82, nc83, EPCS_0_RX_IDLE, EPCS_0_READY, 
        EPCS_0_RX_VAL, EPCS_0_TX_CLK_STABLE}), .M_ARBURST({nc84, 
        EPCS_0_RX_RESET_N}), .M_ARID({nc85, nc86, nc87, nc88}), 
        .M_ARLEN({nc89, nc90, nc91, nc92}), .M_ARSIZE({nc93, nc94}), 
        .M_ARVALID(), .M_AWADDR_HADDR({nc95, nc96, nc97, nc98, nc99, 
        nc100, nc101, nc102, nc103, nc104, nc105, nc106, nc107, nc108, 
        nc109, nc110, nc111, nc112, nc113, nc114, nc115, nc116, nc117, 
        nc118, nc119, nc120, nc121, nc122, nc123, nc124, nc125, nc126})
        , .M_AWBURST_HTRANS({nc127, nc128}), .M_AWID({nc129, nc130, 
        nc131, nc132}), .M_AWLEN_HBURST({nc133, nc134, nc135, nc136}), 
        .M_AWSIZE_HSIZE({nc137, nc138}), .M_AWVALID_HWRITE(), 
        .M_BREADY(), .M_RREADY(), .M_WDATA_HWDATA({nc139, nc140, nc141, 
        nc142, nc143, nc144, nc145, nc146, nc147, nc148, nc149, nc150, 
        EPCS_0_RX_DATA[9], EPCS_0_RX_DATA[8], EPCS_0_RX_DATA[7], 
        EPCS_0_RX_DATA[6], EPCS_0_RX_DATA[5], EPCS_0_RX_DATA[4], 
        EPCS_0_RX_DATA[3], EPCS_0_RX_DATA[2], EPCS_0_RX_DATA[1], 
        EPCS_0_RX_DATA[0], nc151, nc152, nc153, nc154, nc155, nc156, 
        nc157, nc158, nc159, nc160, nc161, nc162, nc163, nc164, nc165, 
        nc166, nc167, nc168, nc169, nc170, nc171, nc172, nc173, nc174, 
        nc175, nc176, nc177, nc178, nc179, nc180, nc181, nc182, nc183, 
        nc184, nc185, nc186, nc187, nc188, nc189, nc190, nc191, nc192})
        , .M_WID({nc193, nc194, nc195, EPCS_0_TX_RESET_N}), .M_WLAST(), 
        .M_WSTRB({nc196, nc197, nc198, nc199, nc200, nc201, nc202, 
        nc203}), .M_WVALID(), .PCIE_SYSTEM_INT(), .PLL_LOCK_INT(), 
        .PLL_LOCKLOST_INT(), .S_ARREADY(), .S_AWREADY(), .S_BID({nc204, 
        nc205, nc206, nc207}), .S_BRESP_HRESP({nc208, nc209}), 
        .S_BVALID(), .S_RDATA_HRDATA({nc210, nc211, nc212, nc213, 
        nc214, nc215, nc216, nc217, nc218, nc219, nc220, nc221, nc222, 
        nc223, nc224, nc225, nc226, nc227, nc228, nc229, nc230, nc231, 
        nc232, nc233, nc234, nc235, nc236, nc237, nc238, nc239, nc240, 
        nc241, nc242, nc243, nc244, nc245, nc246, nc247, nc248, nc249, 
        nc250, nc251, nc252, nc253, nc254, nc255, nc256, nc257, nc258, 
        nc259, nc260, nc261, nc262, nc263, nc264, nc265, nc266, nc267, 
        nc268, nc269, nc270, nc271, nc272, nc273}), .S_RID({nc274, 
        nc275, nc276, nc277}), .S_RLAST(), .S_RRESP({nc278, nc279}), 
        .S_RVALID(), .S_WREADY_HREADYOUT(), .SPLL_LOCK(), .WAKE_N(), 
        .XAUI_OUT_CLK(), .APB_CLK(APB_S_PCLK), .APB_PADDR({
        APB_S_PADDR[13], APB_S_PADDR[12], APB_S_PADDR[11], 
        APB_S_PADDR[10], APB_S_PADDR[9], APB_S_PADDR[8], 
        APB_S_PADDR[7], APB_S_PADDR[6], APB_S_PADDR[5], APB_S_PADDR[4], 
        APB_S_PADDR[3], APB_S_PADDR[2]}), .APB_PENABLE(APB_S_PENABLE), 
        .APB_PSEL(APB_S_PSEL), .APB_PWDATA({APB_S_PWDATA[31], 
        APB_S_PWDATA[30], APB_S_PWDATA[29], APB_S_PWDATA[28], 
        APB_S_PWDATA[27], APB_S_PWDATA[26], APB_S_PWDATA[25], 
        APB_S_PWDATA[24], APB_S_PWDATA[23], APB_S_PWDATA[22], 
        APB_S_PWDATA[21], APB_S_PWDATA[20], APB_S_PWDATA[19], 
        APB_S_PWDATA[18], APB_S_PWDATA[17], APB_S_PWDATA[16], 
        APB_S_PWDATA[15], APB_S_PWDATA[14], APB_S_PWDATA[13], 
        APB_S_PWDATA[12], APB_S_PWDATA[11], APB_S_PWDATA[10], 
        APB_S_PWDATA[9], APB_S_PWDATA[8], APB_S_PWDATA[7], 
        APB_S_PWDATA[6], APB_S_PWDATA[5], APB_S_PWDATA[4], 
        APB_S_PWDATA[3], APB_S_PWDATA[2], APB_S_PWDATA[1], 
        APB_S_PWDATA[0]}), .APB_PWRITE(APB_S_PWRITE), .APB_RSTN(
        APB_S_PRESET_N), .CLK_BASE(vcc_net), .EPCS_PWRDN({vcc_net, 
        vcc_net}), .EPCS_RSTN({gnd_net, gnd_net}), .EPCS_RXERR({
        vcc_net, vcc_net}), .EPCS_TXDATA({gnd_net, gnd_net, gnd_net, 
        gnd_net, gnd_net, gnd_net, gnd_net, gnd_net, gnd_net, gnd_net, 
        gnd_net, gnd_net, gnd_net, gnd_net, gnd_net, gnd_net, gnd_net, 
        gnd_net, gnd_net, gnd_net, gnd_net, gnd_net, gnd_net, gnd_net, 
        gnd_net, gnd_net, gnd_net, gnd_net, gnd_net, gnd_net, gnd_net, 
        gnd_net, gnd_net, gnd_net, gnd_net, gnd_net, gnd_net, gnd_net, 
        gnd_net, gnd_net}), .EPCS_TXOOB({vcc_net, vcc_net}), 
        .EPCS_TXVAL({vcc_net, vcc_net}), .F2HCALIB0(vcc_net), 
        .F2HCALIB1(vcc_net), .FAB_PLL_LOCK(gnd_net), .FAB_REF_CLK(
        EPCS_FAB_REF_CLK), .M_ARREADY(gnd_net), .M_AWREADY(gnd_net), 
        .M_BID({vcc_net, vcc_net, vcc_net, EPCS_0_PWRDN}), 
        .M_BRESP_HRESP({gnd_net, gnd_net}), .M_BVALID(gnd_net), 
        .M_RDATA_HRDATA({gnd_net, gnd_net, gnd_net, gnd_net, gnd_net, 
        gnd_net, gnd_net, gnd_net, gnd_net, gnd_net, gnd_net, gnd_net, 
        gnd_net, gnd_net, gnd_net, gnd_net, gnd_net, gnd_net, gnd_net, 
        gnd_net, gnd_net, gnd_net, EPCS_0_TX_DATA[9], 
        EPCS_0_TX_DATA[8], EPCS_0_TX_DATA[7], EPCS_0_TX_DATA[6], 
        EPCS_0_TX_DATA[5], EPCS_0_TX_DATA[4], EPCS_0_TX_DATA[3], 
        EPCS_0_TX_DATA[2], EPCS_0_TX_DATA[1], EPCS_0_TX_DATA[0], 
        gnd_net, gnd_net, gnd_net, gnd_net, gnd_net, gnd_net, gnd_net, 
        gnd_net, gnd_net, gnd_net, gnd_net, gnd_net, gnd_net, gnd_net, 
        gnd_net, gnd_net, gnd_net, gnd_net, gnd_net, gnd_net, gnd_net, 
        gnd_net, gnd_net, gnd_net, gnd_net, gnd_net, gnd_net, gnd_net, 
        gnd_net, gnd_net, gnd_net, gnd_net}), .M_RID({gnd_net, gnd_net, 
        EPCS_0_TX_VAL, EPCS_0_TX_OOB}), .M_RLAST(gnd_net), .M_RRESP({
        gnd_net, EPCS_0_RX_ERR}), .M_RVALID(gnd_net), .M_WREADY_HREADY(
        gnd_net), .PCIE_INTERRUPT({gnd_net, gnd_net, gnd_net, gnd_net})
        , .PERST_N(gnd_net), .S_ARADDR({gnd_net, gnd_net, gnd_net, 
        gnd_net, gnd_net, gnd_net, gnd_net, gnd_net, gnd_net, gnd_net, 
        gnd_net, gnd_net, gnd_net, gnd_net, gnd_net, gnd_net, gnd_net, 
        gnd_net, gnd_net, gnd_net, gnd_net, gnd_net, gnd_net, gnd_net, 
        gnd_net, gnd_net, gnd_net, gnd_net, gnd_net, gnd_net, gnd_net, 
        gnd_net}), .S_ARBURST({gnd_net, gnd_net}), .S_ARID({gnd_net, 
        gnd_net, gnd_net, gnd_net}), .S_ARLEN({gnd_net, gnd_net, 
        gnd_net, gnd_net}), .S_ARLOCK({gnd_net, gnd_net}), .S_ARSIZE({
        gnd_net, gnd_net}), .S_ARVALID(gnd_net), .S_AWADDR_HADDR({
        gnd_net, gnd_net, gnd_net, gnd_net, gnd_net, gnd_net, gnd_net, 
        gnd_net, gnd_net, gnd_net, gnd_net, gnd_net, gnd_net, gnd_net, 
        gnd_net, gnd_net, gnd_net, gnd_net, gnd_net, gnd_net, gnd_net, 
        gnd_net, gnd_net, gnd_net, gnd_net, gnd_net, gnd_net, gnd_net, 
        gnd_net, gnd_net, gnd_net, gnd_net}), .S_AWBURST_HTRANS({
        gnd_net, gnd_net}), .S_AWID_HSEL({gnd_net, gnd_net, gnd_net, 
        gnd_net}), .S_AWLEN_HBURST({gnd_net, gnd_net, gnd_net, gnd_net})
        , .S_AWLOCK({gnd_net, gnd_net}), .S_AWSIZE_HSIZE({gnd_net, 
        gnd_net}), .S_AWVALID_HWRITE(gnd_net), .S_BREADY_HREADY(
        gnd_net), .S_RREADY(gnd_net), .S_WDATA_HWDATA({gnd_net, 
        gnd_net, gnd_net, gnd_net, gnd_net, gnd_net, gnd_net, gnd_net, 
        gnd_net, gnd_net, gnd_net, gnd_net, gnd_net, gnd_net, gnd_net, 
        gnd_net, gnd_net, gnd_net, gnd_net, gnd_net, gnd_net, gnd_net, 
        gnd_net, gnd_net, gnd_net, gnd_net, gnd_net, gnd_net, gnd_net, 
        gnd_net, gnd_net, gnd_net, gnd_net, gnd_net, gnd_net, gnd_net, 
        gnd_net, gnd_net, gnd_net, gnd_net, gnd_net, gnd_net, gnd_net, 
        gnd_net, gnd_net, gnd_net, gnd_net, gnd_net, gnd_net, gnd_net, 
        gnd_net, gnd_net, gnd_net, gnd_net, gnd_net, gnd_net, gnd_net, 
        gnd_net, gnd_net, gnd_net, gnd_net, gnd_net, gnd_net, gnd_net})
        , .S_WID({gnd_net, gnd_net, gnd_net, gnd_net}), .S_WLAST(
        gnd_net), .S_WSTRB({gnd_net, gnd_net, gnd_net, gnd_net, 
        gnd_net, gnd_net, gnd_net, gnd_net}), .S_WVALID(gnd_net), 
        .SERDESIF_CORE_RESET_N(EPCS_0_RESET_N), .SERDESIF_PHY_RESET_N(
        gnd_net), .WAKE_REQ(vcc_net), .XAUI_FB_CLK(vcc_net), .RXD3_P(
        RXD3_P), .RXD2_P(RXD2_P), .RXD1_P(RXD1_P), .RXD0_P(RXD0_P), 
        .RXD3_N(RXD3_N), .RXD2_N(RXD2_N), .RXD1_N(RXD1_N), .RXD0_N(
        RXD0_N), .TXD3_P(TXD3_P), .TXD2_P(TXD2_P), .TXD1_P(TXD1_P), 
        .TXD0_P(TXD0_P), .TXD3_N(TXD3_N), .TXD2_N(TXD2_N), .TXD1_N(
        TXD1_N), .TXD0_N(TXD0_N), .REFCLK0(vcc_net), .REFCLK1(vcc_net));
    
endmodule
