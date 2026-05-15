///////////////////////////////////////////////////////////////////////////////////////////////////
// Company: MICROCHIP
//
// IP Core: COREPCS
//
//  Description  : CorePCS core
//
//  COPYRIGHT 2019 BY MICROCHIP
//  THE INFORMATION CONTAINED IN THIS DOCUMENT IS SUBJECT TO LICENSING RESTRICTIONS 
//  FROM MICROSEMI CORP.  IF YOU ARE NOT IN POSSESSION OF WRITTEN AUTHORIZATION FROM 
//  MICROSEMI FOR USE OF THIS FILE, THEN THE FILE SHOULD BE IMMEDIATELY DESTROYED AND 
//  NO BACK-UP OF THE FILE SHOULD BE MADE. 
//
//
/////////////////////////////////////////////////////////////////////////////////////////////////// 

module cpcs_reset_sync #
(
  parameter SYNC_RESET = 1
)
(
  input             EPCS_TxCLK,
  input             EPCS_RxCLK,
  input             EPCS_TxRSTn,
  input             EPCS_RxRSTn,
  input             RESET_N,
  input             WA_RSTn,
  input             EPCS_RxVAL,
  output reg        syncd_tx_rst_n,
  output reg        syncd_rx_rst_n,
  output reg        syncd_wa_rst_n  
)/* synthesis syn_preserve=1 syn_hier="fixed" */;

wire aresetn,sresetn; 
wire tx_rst_n;
wire rx_rst_n;
wire wa_rst_n;

assign aresetn  = (SYNC_RESET==1) ? 1'b1 : RESET_N;
assign sresetn  = (SYNC_RESET==1) ? RESET_N : 1'b1;

reg [2:0] tx_reset_n/*synthesis syn_noclockbuf=1 syn_preserve=1*/;
reg [2:0] rx_reset_n/*synthesis syn_noclockbuf=1 syn_preserve=1*/;
reg [2:0] epcs_rx_val/*synthesis syn_noclockbuf=1 syn_preserve=1*/;
reg [2:0] wa_reset_n/*synthesis syn_noclockbuf=1 syn_preserve=1*/;

generate 
    if(SYNC_RESET == 1)
    begin : CorePCS_GenBLK_Sync_Reset
        always @(posedge EPCS_TxCLK)
        begin
            tx_reset_n  <= {tx_reset_n[1:0], sresetn};
        end

        always @(posedge EPCS_RxCLK)
        begin
            rx_reset_n  <= {rx_reset_n[1:0], sresetn};
        end

        always @(posedge EPCS_RxCLK)
        begin
            epcs_rx_val <= {epcs_rx_val[1:0], EPCS_RxVAL};
        end

        always @(posedge EPCS_RxCLK)
        begin
            wa_reset_n  <= {wa_reset_n[1:0], WA_RSTn};
        end
    end
    else
    begin : CorePCS_GenBLK_Async_Reset
        always @(posedge EPCS_TxCLK or negedge aresetn)
        begin
            if(!aresetn)
            begin
                tx_reset_n  <= 3'b0;
            end
            else
            begin
                tx_reset_n  <= {tx_reset_n[1:0], 1'b1};
            end
        end

        always @(posedge EPCS_RxCLK or negedge aresetn)
        begin
            if(!aresetn)
            begin
                rx_reset_n  <= 3'b0;
            end
            else
            begin
                rx_reset_n  <= {rx_reset_n[1:0], 1'b1};
            end
        end

        always @(posedge EPCS_RxCLK or negedge EPCS_RxVAL)
        begin
            if(!EPCS_RxVAL)
            begin
                epcs_rx_val <= 3'b0;
            end
            else
            begin
                epcs_rx_val <= {epcs_rx_val[1:0], 1'b1};
            end
        end

        always @(posedge EPCS_RxCLK or negedge WA_RSTn)
        begin
            if(!WA_RSTn)
            begin
                wa_reset_n  <= 3'b0;
            end
            else
            begin
                wa_reset_n  <= {wa_reset_n[1:0], 1'b1};
            end
        end
    end
endgenerate

assign tx_rst_n = EPCS_TxRSTn & tx_reset_n[2];
assign rx_rst_n = EPCS_RxRSTn & rx_reset_n[2] & epcs_rx_val[2];
assign wa_rst_n = rx_rst_n    & wa_reset_n[2];

always @(posedge EPCS_TxCLK)
begin
    syncd_tx_rst_n <= tx_rst_n;
end

always @(posedge EPCS_RxCLK)
begin
    syncd_rx_rst_n <= rx_rst_n;
    syncd_wa_rst_n <= wa_rst_n;
end
endmodule 