`timescale 1 ns/100 ps
// Version: 


module SERDESIF_120_0(
       APB_PRDATA,
       APB_PREADY,
       APB_PSLVERR,
       ATXCLKSTABLE,
       EPCS_READY,
       EPCS_RXCLK,
       EPCS_RXCLK_0,
       EPCS_RXCLK_1,
       EPCS_RXDATA,
       EPCS_RXIDLE,
       EPCS_RXRSTN,
       EPCS_RXVAL,
       EPCS_TXCLK,
       EPCS_TXCLK_0,
       EPCS_TXCLK_1,
       EPCS_TXRSTN,
       FATC_RESET_N,
       H2FCALIB0,
       H2FCALIB1,
       M_ARADDR,
       M_ARBURST,
       M_ARID,
       M_ARLEN,
       M_ARSIZE,
       M_ARVALID,
       M_AWADDR_HADDR,
       M_AWBURST_HTRANS,
       M_AWID,
       M_AWLEN_HBURST,
       M_AWSIZE_HSIZE,
       M_AWVALID_HWRITE,
       M_BREADY,
       M_RREADY,
       M_WDATA_HWDATA,
       M_WID,
       M_WLAST,
       M_WSTRB,
       M_WVALID,
       PCIE_SYSTEM_INT,
       PLL_LOCK_INT,
       PLL_LOCKLOST_INT,
       S_ARREADY,
       S_AWREADY,
       S_BID,
       S_BRESP_HRESP,
       S_BVALID,
       S_RDATA_HRDATA,
       S_RID,
       S_RLAST,
       S_RRESP,
       S_RVALID,
       S_WREADY_HREADYOUT,
       SPLL_LOCK,
       WAKE_N,
       XAUI_OUT_CLK,
       APB_CLK,
       APB_PADDR,
       APB_PENABLE,
       APB_PSEL,
       APB_PWDATA,
       APB_PWRITE,
       APB_RSTN,
       CLK_BASE,
       EPCS_PWRDN,
       EPCS_RSTN,
       EPCS_RXERR,
       EPCS_TXDATA,
       EPCS_TXOOB,
       EPCS_TXVAL,
       F2HCALIB0,
       F2HCALIB1,
       FAB_PLL_LOCK,
       FAB_REF_CLK,
       M_ARREADY,
       M_AWREADY,
       M_BID,
       M_BRESP_HRESP,
       M_BVALID,
       M_RDATA_HRDATA,
       M_RID,
       M_RLAST,
       M_RRESP,
       M_RVALID,
       M_WREADY_HREADY,
       PCIE_INTERRUPT,
       PERST_N,
       S_ARADDR,
       S_ARBURST,
       S_ARID,
       S_ARLEN,
       S_ARLOCK,
       S_ARSIZE,
       S_ARVALID,
       S_AWADDR_HADDR,
       S_AWBURST_HTRANS,
       S_AWID_HSEL,
       S_AWLEN_HBURST,
       S_AWLOCK,
       S_AWSIZE_HSIZE,
       S_AWVALID_HWRITE,
       S_BREADY_HREADY,
       S_RREADY,
       S_WDATA_HWDATA,
       S_WID,
       S_WLAST,
       S_WSTRB,
       S_WVALID,
       SERDESIF_CORE_RESET_N,
       SERDESIF_PHY_RESET_N,
       WAKE_REQ,
       XAUI_FB_CLK,
       RXD3_P,
       RXD2_P,
       RXD1_P,
       RXD0_P,
       RXD3_N,
       RXD2_N,
       RXD1_N,
       RXD0_N,
       TXD3_P,
       TXD2_P,
       TXD1_P,
       TXD0_P,
       TXD3_N,
       TXD2_N,
       TXD1_N,
       TXD0_N,
       REFCLK0,
       REFCLK1
    )
/* synthesis black_box

pragma attribute SERDESIF_120_0 ment_tsu0 APB_PADDR[10]->APB_CLK+-0.078
pragma attribute SERDESIF_120_0 ment_tsu1 APB_PADDR[11]->APB_CLK+-0.115
pragma attribute SERDESIF_120_0 ment_tsu2 APB_PADDR[12]->APB_CLK+1.791
pragma attribute SERDESIF_120_0 ment_tsu3 APB_PADDR[13]->APB_CLK+2.044
pragma attribute SERDESIF_120_0 ment_tsu4 APB_PADDR[2]->APB_CLK+2.405
pragma attribute SERDESIF_120_0 ment_tsu5 APB_PADDR[3]->APB_CLK+2.649
pragma attribute SERDESIF_120_0 ment_tsu6 APB_PADDR[4]->APB_CLK+2.877
pragma attribute SERDESIF_120_0 ment_tsu7 APB_PADDR[5]->APB_CLK+2.464
pragma attribute SERDESIF_120_0 ment_tsu8 APB_PADDR[6]->APB_CLK+2.057
pragma attribute SERDESIF_120_0 ment_tsu9 APB_PADDR[7]->APB_CLK+2.303
pragma attribute SERDESIF_120_0 ment_tsu10 APB_PADDR[8]->APB_CLK+2.037
pragma attribute SERDESIF_120_0 ment_tsu11 APB_PADDR[9]->APB_CLK+2.347
pragma attribute SERDESIF_120_0 ment_tsu12 APB_PENABLE->APB_CLK+0.484
pragma attribute SERDESIF_120_0 ment_tsu13 APB_PSEL->APB_CLK+2.000
pragma attribute SERDESIF_120_0 ment_tsu14 APB_PWDATA[0]->APB_CLK+1.274
pragma attribute SERDESIF_120_0 ment_tsu15 APB_PWDATA[10]->APB_CLK+0.123
pragma attribute SERDESIF_120_0 ment_tsu16 APB_PWDATA[11]->APB_CLK+0.016
pragma attribute SERDESIF_120_0 ment_tsu17 APB_PWDATA[12]->APB_CLK+-0.005
pragma attribute SERDESIF_120_0 ment_tsu18 APB_PWDATA[13]->APB_CLK+0.116
pragma attribute SERDESIF_120_0 ment_tsu19 APB_PWDATA[14]->APB_CLK+-0.045
pragma attribute SERDESIF_120_0 ment_tsu20 APB_PWDATA[15]->APB_CLK+-0.085
pragma attribute SERDESIF_120_0 ment_tsu21 APB_PWDATA[16]->APB_CLK+-0.022
pragma attribute SERDESIF_120_0 ment_tsu22 APB_PWDATA[17]->APB_CLK+0.033
pragma attribute SERDESIF_120_0 ment_tsu23 APB_PWDATA[18]->APB_CLK+0.063
pragma attribute SERDESIF_120_0 ment_tsu24 APB_PWDATA[19]->APB_CLK+-0.043
pragma attribute SERDESIF_120_0 ment_tsu25 APB_PWDATA[1]->APB_CLK+1.402
pragma attribute SERDESIF_120_0 ment_tsu26 APB_PWDATA[20]->APB_CLK+0.139
pragma attribute SERDESIF_120_0 ment_tsu27 APB_PWDATA[21]->APB_CLK+0.016
pragma attribute SERDESIF_120_0 ment_tsu28 APB_PWDATA[22]->APB_CLK+0.044
pragma attribute SERDESIF_120_0 ment_tsu29 APB_PWDATA[23]->APB_CLK+-0.023
pragma attribute SERDESIF_120_0 ment_tsu30 APB_PWDATA[24]->APB_CLK+-0.011
pragma attribute SERDESIF_120_0 ment_tsu31 APB_PWDATA[25]->APB_CLK+-0.041
pragma attribute SERDESIF_120_0 ment_tsu32 APB_PWDATA[26]->APB_CLK+-0.080
pragma attribute SERDESIF_120_0 ment_tsu33 APB_PWDATA[27]->APB_CLK+-0.098
pragma attribute SERDESIF_120_0 ment_tsu34 APB_PWDATA[28]->APB_CLK+0.345
pragma attribute SERDESIF_120_0 ment_tsu35 APB_PWDATA[29]->APB_CLK+0.013
pragma attribute SERDESIF_120_0 ment_tsu36 APB_PWDATA[2]->APB_CLK+1.877
pragma attribute SERDESIF_120_0 ment_tsu37 APB_PWDATA[30]->APB_CLK+0.078
pragma attribute SERDESIF_120_0 ment_tsu38 APB_PWDATA[31]->APB_CLK+0.007
pragma attribute SERDESIF_120_0 ment_tsu39 APB_PWDATA[3]->APB_CLK+0.936
pragma attribute SERDESIF_120_0 ment_tsu40 APB_PWDATA[4]->APB_CLK+1.344
pragma attribute SERDESIF_120_0 ment_tsu41 APB_PWDATA[5]->APB_CLK+0.723
pragma attribute SERDESIF_120_0 ment_tsu42 APB_PWDATA[6]->APB_CLK+1.011
pragma attribute SERDESIF_120_0 ment_tsu43 APB_PWDATA[7]->APB_CLK+1.138
pragma attribute SERDESIF_120_0 ment_tsu44 APB_PWDATA[8]->APB_CLK+-0.038
pragma attribute SERDESIF_120_0 ment_tsu45 APB_PWDATA[9]->APB_CLK+0.027
pragma attribute SERDESIF_120_0 ment_tsu46 APB_PWRITE->APB_CLK+1.599
pragma attribute SERDESIF_120_0 ment_tsu47 APB_RSTN->APB_CLK+0.415
pragma attribute SERDESIF_120_0 ment_tco0 APB_CLK->APB_PRDATA[0]+4.158
pragma attribute SERDESIF_120_0 ment_tco1 APB_CLK->APB_PRDATA[10]+3.831
pragma attribute SERDESIF_120_0 ment_tco2 APB_CLK->APB_PRDATA[11]+3.879
pragma attribute SERDESIF_120_0 ment_tco3 APB_CLK->APB_PRDATA[12]+3.818
pragma attribute SERDESIF_120_0 ment_tco4 APB_CLK->APB_PRDATA[13]+3.908
pragma attribute SERDESIF_120_0 ment_tco5 APB_CLK->APB_PRDATA[14]+3.837
pragma attribute SERDESIF_120_0 ment_tco6 APB_CLK->APB_PRDATA[15]+3.871
pragma attribute SERDESIF_120_0 ment_tco7 APB_CLK->APB_PRDATA[16]+3.839
pragma attribute SERDESIF_120_0 ment_tco8 APB_CLK->APB_PRDATA[17]+3.841
pragma attribute SERDESIF_120_0 ment_tco9 APB_CLK->APB_PRDATA[18]+3.814
pragma attribute SERDESIF_120_0 ment_tco10 APB_CLK->APB_PRDATA[19]+3.799
pragma attribute SERDESIF_120_0 ment_tco11 APB_CLK->APB_PRDATA[1]+4.212
pragma attribute SERDESIF_120_0 ment_tco12 APB_CLK->APB_PRDATA[20]+3.840
pragma attribute SERDESIF_120_0 ment_tco13 APB_CLK->APB_PRDATA[21]+3.831
pragma attribute SERDESIF_120_0 ment_tco14 APB_CLK->APB_PRDATA[22]+3.748
pragma attribute SERDESIF_120_0 ment_tco15 APB_CLK->APB_PRDATA[23]+3.808
pragma attribute SERDESIF_120_0 ment_tco16 APB_CLK->APB_PRDATA[24]+3.818
pragma attribute SERDESIF_120_0 ment_tco17 APB_CLK->APB_PRDATA[25]+3.719
pragma attribute SERDESIF_120_0 ment_tco18 APB_CLK->APB_PRDATA[26]+3.959
pragma attribute SERDESIF_120_0 ment_tco19 APB_CLK->APB_PRDATA[27]+3.832
pragma attribute SERDESIF_120_0 ment_tco20 APB_CLK->APB_PRDATA[28]+3.895
pragma attribute SERDESIF_120_0 ment_tco21 APB_CLK->APB_PRDATA[29]+3.843
pragma attribute SERDESIF_120_0 ment_tco22 APB_CLK->APB_PRDATA[2]+4.141
pragma attribute SERDESIF_120_0 ment_tco23 APB_CLK->APB_PRDATA[30]+3.898
pragma attribute SERDESIF_120_0 ment_tco24 APB_CLK->APB_PRDATA[31]+4.049
pragma attribute SERDESIF_120_0 ment_tco25 APB_CLK->APB_PRDATA[3]+4.008
pragma attribute SERDESIF_120_0 ment_tco26 APB_CLK->APB_PRDATA[4]+3.948
pragma attribute SERDESIF_120_0 ment_tco27 APB_CLK->APB_PRDATA[5]+4.099
pragma attribute SERDESIF_120_0 ment_tco28 APB_CLK->APB_PRDATA[6]+4.045
pragma attribute SERDESIF_120_0 ment_tco29 APB_CLK->APB_PRDATA[7]+3.962
pragma attribute SERDESIF_120_0 ment_tco30 APB_CLK->APB_PRDATA[8]+3.877
pragma attribute SERDESIF_120_0 ment_tco31 APB_CLK->APB_PRDATA[9]+3.885
pragma attribute SERDESIF_120_0 ment_tco32 APB_CLK->APB_PREADY+3.962
pragma attribute SERDESIF_120_0 ment_tco33 APB_CLK->PCIE_SYSTEM_INT+3.558
pragma attribute SERDESIF_120_0 ment_tco34 APB_CLK->PLL_LOCKLOST_INT+2.981
pragma attribute SERDESIF_120_0 ment_tco35 APB_CLK->PLL_LOCK_INT+3.014
pragma attribute SERDESIF_120_0 ment_tco36 FAB_REF_CLK->M_ARADDR[0]+3.085
pragma attribute SERDESIF_120_0 ment_tco37 FAB_REF_CLK->M_ARADDR[4]+3.322
*/
/* synthesis black_box black_box_pad ="RXD3_P,RXD2_P,RXD1_P,RXD0_P,RXD3_N,RXD2_N,RXD1_N,RXD0_N,TXD3_P,TXD2_P,TXD1_P,TXD0_P,TXD3_N,TXD2_N,TXD1_N,TXD0_N" */
 ;
output [31:0] APB_PRDATA;
output APB_PREADY;
output APB_PSLVERR;
output [1:0] ATXCLKSTABLE;
output [1:0] EPCS_READY;
output [1:0] EPCS_RXCLK;
output EPCS_RXCLK_0;
output EPCS_RXCLK_1;
output [39:0] EPCS_RXDATA;
output [1:0] EPCS_RXIDLE;
output [1:0] EPCS_RXRSTN;
output [1:0] EPCS_RXVAL;
output [1:0] EPCS_TXCLK;
output EPCS_TXCLK_0;
output EPCS_TXCLK_1;
output [1:0] EPCS_TXRSTN;
output FATC_RESET_N;
output H2FCALIB0;
output H2FCALIB1;
output [31:0] M_ARADDR;
output [1:0] M_ARBURST;
output [3:0] M_ARID;
output [3:0] M_ARLEN;
output [1:0] M_ARSIZE;
output M_ARVALID;
output [31:0] M_AWADDR_HADDR;
output [1:0] M_AWBURST_HTRANS;
output [3:0] M_AWID;
output [3:0] M_AWLEN_HBURST;
output [1:0] M_AWSIZE_HSIZE;
output M_AWVALID_HWRITE;
output M_BREADY;
output M_RREADY;
output [63:0] M_WDATA_HWDATA;
output [3:0] M_WID;
output M_WLAST;
output [7:0] M_WSTRB;
output M_WVALID;
output PCIE_SYSTEM_INT;
output PLL_LOCK_INT;
output PLL_LOCKLOST_INT;
output S_ARREADY;
output S_AWREADY;
output [3:0] S_BID;
output [1:0] S_BRESP_HRESP;
output S_BVALID;
output [63:0] S_RDATA_HRDATA;
output [3:0] S_RID;
output S_RLAST;
output [1:0] S_RRESP;
output S_RVALID;
output S_WREADY_HREADYOUT;
output SPLL_LOCK;
output WAKE_N;
output XAUI_OUT_CLK;
input  APB_CLK;
input  [13:2] APB_PADDR;
input  APB_PENABLE;
input  APB_PSEL;
input  [31:0] APB_PWDATA;
input  APB_PWRITE;
input  APB_RSTN;
input  CLK_BASE;
input  [1:0] EPCS_PWRDN;
input  [1:0] EPCS_RSTN;
input  [1:0] EPCS_RXERR;
input  [39:0] EPCS_TXDATA;
input  [1:0] EPCS_TXOOB;
input  [1:0] EPCS_TXVAL;
input  F2HCALIB0;
input  F2HCALIB1;
input  FAB_PLL_LOCK;
input  FAB_REF_CLK;
input  M_ARREADY;
input  M_AWREADY;
input  [3:0] M_BID;
input  [1:0] M_BRESP_HRESP;
input  M_BVALID;
input  [63:0] M_RDATA_HRDATA;
input  [3:0] M_RID;
input  M_RLAST;
input  [1:0] M_RRESP;
input  M_RVALID;
input  M_WREADY_HREADY;
input  [3:0] PCIE_INTERRUPT;
input  PERST_N;
input  [31:0] S_ARADDR;
input  [1:0] S_ARBURST;
input  [3:0] S_ARID;
input  [3:0] S_ARLEN;
input  [1:0] S_ARLOCK;
input  [1:0] S_ARSIZE;
input  S_ARVALID;
input  [31:0] S_AWADDR_HADDR;
input  [1:0] S_AWBURST_HTRANS;
input  [3:0] S_AWID_HSEL;
input  [3:0] S_AWLEN_HBURST;
input  [1:0] S_AWLOCK;
input  [1:0] S_AWSIZE_HSIZE;
input  S_AWVALID_HWRITE;
input  S_BREADY_HREADY;
input  S_RREADY;
input  [63:0] S_WDATA_HWDATA;
input  [3:0] S_WID;
input  S_WLAST;
input  [7:0] S_WSTRB;
input  S_WVALID;
input  SERDESIF_CORE_RESET_N;
input  SERDESIF_PHY_RESET_N;
input  WAKE_REQ;
input  XAUI_FB_CLK;
input  RXD3_P;
input  RXD2_P;
input  RXD1_P;
input  RXD0_P;
input  RXD3_N;
input  RXD2_N;
input  RXD1_N;
input  RXD0_N;
output TXD3_P;
output TXD2_P;
output TXD1_P;
output TXD0_P;
output TXD3_N;
output TXD2_N;
output TXD1_N;
output TXD0_N;
input  REFCLK0;
input  REFCLK1;
parameter INIT = 'h0;
parameter ACT_CONFIG = "";
parameter ACT_SIM = 0;

endmodule
