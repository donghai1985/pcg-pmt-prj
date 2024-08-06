`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/06/13
// Design Name: songyuxin
// Module Name: pmt_communication_tx
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


module pmt_communication_tx #(
    parameter                               TCQ        = 0.1,
    parameter                               DATA_WIDTH = 16
)(
    // clk & rst
    input    wire                           clk_i           ,
    input    wire                           rst_i           ,

    input    wire                           tx_en_i         ,
    input    wire   [DATA_WIDTH-1:0]        tx_data_i       ,
    output   wire                           comm_busy_o     ,


    // info
    output   wire                           TX_CLK          ,
    output   wire                           TX_DATA         

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
reg                             tx_state        = 'd0;

reg                             tx_clk_r        = 'd0;
reg                             tx_clk_r_d      = 'd0;
reg                             tx_en_r         = 'd0;
reg     [DATA_WIDTH-1:0]        tx_data_r       = 'd0;
reg     [4-1:0]                 tx_cnt          = 'd0;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<



//////////////////////////////////////////////////////////////////////////////////
// *********** Define Wire Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
wire                            tx_clk_nege ;
wire                            tx_clk_pose ;



//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<





//////////////////////////////////////////////////////////////////////////////////
// *********** Instance Module
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>


//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


//////////////////////////////////////////////////////////////////////////////////
// *********** Logic Design
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
always @(posedge clk_i) begin   // 100MHz
    if(~tx_state)
        tx_clk_r <= #TCQ 'd1;
    else 
        tx_clk_r <= #TCQ ~tx_clk_r;    // 50MHz
end

always @(posedge clk_i) begin
    tx_clk_r_d <= #TCQ tx_clk_r;
end

assign tx_clk_nege = tx_clk_r_d  && ~tx_clk_r;
assign tx_clk_pose = ~tx_clk_r_d && tx_clk_r;

always @(posedge clk_i) begin
    if(tx_en_i && ~tx_state)begin
        tx_en_r    <= #TCQ 'd1;
    end
    else begin
        tx_en_r    <= #TCQ 'd0;
    end
end

always @(posedge clk_i) begin
    if(tx_en_r)
        tx_state <= #TCQ 'd1;
    else if(tx_cnt==DATA_WIDTH-1 && tx_clk_nege)
        tx_state <= #TCQ 'd0;
end

always @(posedge clk_i) begin
    if(tx_state)begin
        if(tx_clk_pose)
            tx_cnt <= #TCQ tx_cnt + 1;
    end
    else 
        tx_cnt <= #TCQ 'd0;
end

always @(posedge clk_i) begin
    if(tx_en_i && ~tx_state)
        tx_data_r <= #TCQ tx_data_i;
    else if(tx_clk_pose && tx_state)
        tx_data_r <= #TCQ {tx_data_r[DATA_WIDTH-2:0],1'b0};
end

assign comm_busy_o  = tx_state;
assign TX_CLK       = tx_clk_r;
assign TX_DATA      = tx_data_r[DATA_WIDTH-1];
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


endmodule
