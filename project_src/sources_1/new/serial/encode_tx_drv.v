`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: zas
// Engineer: songyuxin
// 
// Create Date: 2023/12/05
// Design Name: PCG
// Module Name: encode_tx_drv
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
//
//
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module encode_tx_drv #(
    parameter                               TCQ             = 0.1   ,
    parameter                               DATA_WIDTH      = 16    ,
    parameter                               SERIAL_MODE     = 1     
)(
    // clk & rst
    input    wire                           clk_i                   ,
    input    wire                           rst_i                   ,
    input    wire                           clk_200m_i              ,

    // input    wire                           pmt_scan_en_i           ,
    input    wire   [32-1:0]                precise_encode_w_i      ,

    input    wire                           pmt_scan_cmd_sel_i      ,
    input    wire   [4-1:0]                 pmt_scan_cmd_i          ,
    output   wire                           pmt_start_en_o          ,
    output   wire                           pmt_start_test_en_o     ,

    // spi info
    output   wire                           SPI_MCLK                ,
    output   wire   [SERIAL_MODE-1:0]       SPI_MOSI                
);


//////////////////////////////////////////////////////////////////////////////////
// *********** Define Parameter Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
localparam  [DATA_WIDTH-1:0]        SYNC_WORD_ENCODE        = 'hECDE    ;
localparam  [DATA_WIDTH-1:0]        SYNC_WORD_SCAN_BEGIN    = 'h5A51    ;
localparam  [DATA_WIDTH-1:0]        SYNC_WORD_SCAN_TEST     = 'h5A53    ;
localparam  [DATA_WIDTH-1:0]        SYNC_WORD_SCAN_END      = 'h5A50    ;

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Register Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
reg                             tx_valid                = 'd0;
reg     [DATA_WIDTH-1:0]        tx_data                 = 'd0;

reg     [32-1:0]                encode_zero_latch       = 'd0;
reg                             encode_zero_flag_d      = 'd0;
reg                             encode_less_flag_d      = 'd0;
reg                             encode_zero_flag        = 'd0;

reg                             scan_state              = 'd0;
reg     [4-1:0]                 scan_state_d            = 'd0;

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Wire Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
wire                            tx_ready      ;

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Instance Module
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
serial_tx #(
    .DATA_WIDTH                 ( DATA_WIDTH                ),
    .SERIAL_MODE                ( SERIAL_MODE               )  // =1\2\4\8
)serial_tx_inst(
    // clk & rst
    .clk_i                      ( clk_i                     ),
    .rst_i                      ( rst_i                     ),
    .clk_200m_i                 ( clk_200m_i                ),

    .tx_valid_i                 ( tx_valid                  ),
    .tx_ready_o                 ( tx_ready                  ),
    .tx_data_i                  ( tx_data                   ),

    .TX_CLK                     ( SPI_MCLK                  ),
    .TX_DOUT                    ( SPI_MOSI                  )
);
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Logic Design
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
wire  encode_greater_flag   = precise_encode_w_i >= encode_zero_latch;
wire  encode_less_flag      = precise_encode_w_i <= encode_zero_latch;

always @(posedge clk_i) begin
    if(rst_i)
        scan_state <= #TCQ 'd0;
    else if(pmt_scan_cmd_sel_i && pmt_scan_cmd_i[0])
        scan_state <= #TCQ 'd1;
    else if(pmt_scan_cmd_sel_i && (~pmt_scan_cmd_i[0]))
        scan_state <= #TCQ 'd0;
end

always @(posedge clk_i) scan_state_d        <= #TCQ {scan_state_d[2:0],scan_state};
always @(posedge clk_i) encode_less_flag_d  <= #TCQ encode_less_flag;
always @(posedge clk_i) encode_zero_flag    <= #TCQ encode_less_flag_d && encode_greater_flag;
always @(posedge clk_i) encode_zero_flag_d  <= #TCQ encode_zero_flag;

always @(posedge clk_i) begin
    if(~scan_state_d[0] && scan_state)
        encode_zero_latch <= #TCQ precise_encode_w_i;
end

always @(posedge clk_i) begin
    if(~scan_state_d[0] && scan_state)begin
        if(pmt_scan_cmd_i[1])begin
            tx_valid <= #TCQ 'd1;
            tx_data  <= #TCQ SYNC_WORD_SCAN_TEST;
        end
        else begin
            tx_valid <= #TCQ 'd1;
            tx_data  <= #TCQ SYNC_WORD_SCAN_BEGIN;
        end
    end
    else if(scan_state_d[0] && (~scan_state))begin
            tx_valid <= #TCQ 'd1;
            tx_data  <= #TCQ SYNC_WORD_SCAN_END;
    end
    else if(encode_zero_flag && (~encode_zero_flag_d) && scan_state_d[3])begin
        tx_valid <= #TCQ 'd1;
        tx_data  <= #TCQ SYNC_WORD_ENCODE;
    end
    else if(tx_ready && tx_valid)
        tx_valid <= #TCQ 'd0;
end

assign pmt_start_en_o      = scan_state_d[0]     ;
assign pmt_start_test_en_o = scan_state_d[0] & pmt_scan_cmd_i[1];
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


endmodule
