`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: zas
// Engineer: songyuxin
// 
// Create Date: 2024/3/6
// Design Name: PCG
// Module Name: acc_ctrl_tx_drv
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


module acc_ctrl_tx_drv #(
    parameter                               TCQ             = 0.1   ,
    parameter                               DATA_WIDTH      = 16    ,
    parameter                               SERIAL_MODE     = 1     
)(
    // clk & rst
    input    wire                           clk_i                   ,
    input    wire                           rst_i                   ,
    input    wire                           clk_200m_i              ,

    input    wire                           filter_acc_ctrl_i       ,

    // spi info
    output   wire                           SPI_SCLK                ,
    output   wire   [SERIAL_MODE-1:0]       SPI_MISO                
);


//////////////////////////////////////////////////////////////////////////////////
// *********** Define Parameter Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
localparam  [DATA_WIDTH-1:0]        ACC_NORMAL_CLASS0   = 'h5A50    ;
localparam  [DATA_WIDTH-1:0]        ACC_NORMAL_CLASS1   = 'h5A51    ;
localparam  [DATA_WIDTH-1:0]        ACC_NORMAL_CLASS2   = 'h5A52    ;
localparam  [DATA_WIDTH-1:0]        ACC_NORMAL_CLASS3   = 'h5A53    ;
localparam  [DATA_WIDTH-1:0]        ACC_NORMAL_CLASS4   = 'h5A54    ;
localparam  [DATA_WIDTH-1:0]        ACC_NORMAL_CLASS5   = 'h5A55    ;
localparam  [DATA_WIDTH-1:0]        ACC_NORMAL_CLASS6   = 'h5A56    ;
localparam  [DATA_WIDTH-1:0]        ACC_NORMAL_CLASS7   = 'h5A57    ;

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Register Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
reg                                 tx_valid                = 'd0;
reg         [DATA_WIDTH-1:0]        tx_data                 = 'd0;

reg                                 filter_acc_ctrl_d       = 'd0;

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Wire Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
wire                                tx_ready                    ;
wire                                filter_acc_ctrl_pose        ;
wire                                filter_acc_ctrl_nege        ;

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

    .TX_CLK                     ( SPI_SCLK                  ),
    .TX_DOUT                    ( SPI_MISO                  )
);
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Logic Design
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
always @(posedge clk_i) filter_acc_ctrl_d <= #TCQ filter_acc_ctrl_i;
assign filter_acc_ctrl_pose = (~filter_acc_ctrl_d) &&   filter_acc_ctrl_i;
assign filter_acc_ctrl_nege =   filter_acc_ctrl_d  && (~filter_acc_ctrl_i);


always @(posedge clk_i) begin
    if(filter_acc_ctrl_pose)begin
        tx_valid <= #TCQ 'd1;
        tx_data  <= #TCQ ACC_NORMAL_CLASS1;
    end
    else if(filter_acc_ctrl_nege)begin
        tx_valid <= #TCQ 'd1;
        tx_data  <= #TCQ ACC_NORMAL_CLASS0;
    end
    else if(tx_ready && tx_valid)
        tx_valid <= #TCQ 'd0;
end

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


endmodule
