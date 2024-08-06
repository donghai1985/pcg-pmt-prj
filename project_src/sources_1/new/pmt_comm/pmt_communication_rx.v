`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/06/13
// Design Name: songyuxin
// Module Name: pmt_communication_rx
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module pmt_communication_rx #(
    parameter                               DATA_WIDTH = 16
)(
    // clk & rst
    input    wire                           clk_i           ,
    input    wire                           rst_i           ,

    output   wire                           rx_en_o         ,
    output   wire   [DATA_WIDTH-1:0]        rx_data_o       ,

    // info
    input    wire                           RX_CLK          ,
    input    wire                           RX_DATA         

);


//////////////////////////////////////////////////////////////////////////////////
// *********** Define Parameter Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
// localparam                      ST_IDLE         = 3'd0;
// localparam                      ST_TX           = 3'd1;

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Register Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>


reg                             rx_clk_r        = 'd0;
reg                             rx_clk_r_d      = 'd0;
reg                             rx_vld_r        = 'd0;
reg                             rx_data_d       = 'd0;
reg     [DATA_WIDTH-1:0]        rx_data_r       = 'd0;
reg     [4-1:0]                 rx_cnt          = 'd0;
reg     [4-1:0]                 rx_state_cnt    = 'd0;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<



//////////////////////////////////////////////////////////////////////////////////
// *********** Define Wire Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
wire                            rx_clk_nege ;
wire                            rx_clk_pose ;

wire                            rx_state_err;

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<





//////////////////////////////////////////////////////////////////////////////////
// *********** Instance Module
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>


//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


//////////////////////////////////////////////////////////////////////////////////
// *********** Logic Design
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
always @(posedge clk_i) begin
    rx_clk_r <= RX_CLK;
    rx_clk_r_d <= rx_clk_r;
end

assign rx_clk_nege = ~rx_clk_r && rx_clk_r_d;
assign rx_clk_pose = rx_clk_r  && ~rx_clk_r_d;

always @(posedge clk_i) begin
    rx_data_d <= RX_DATA;
end

always @(posedge clk_i) begin
    if(rx_clk_pose)
        rx_data_r <= {rx_data_r[DATA_WIDTH-2:0],rx_data_d};
end

always @(posedge clk_i) begin
    if(rx_state_err)
        rx_cnt <= 'd0;
    else if(rx_clk_pose)begin
        if(rx_cnt==DATA_WIDTH-1)
            rx_cnt <= 'd0;
        else 
            rx_cnt <= rx_cnt + 1;
    end
end

always @(posedge clk_i) begin
    if(rx_clk_nege)
        rx_state_cnt <= 'd0;
    else if(rx_state_cnt==DATA_WIDTH-1)
        rx_state_cnt <= rx_state_cnt ;
    else 
        rx_state_cnt <= rx_state_cnt + 1;
end

assign rx_state_err = rx_state_cnt==DATA_WIDTH-2;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


endmodule
