`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: zas
// Engineer: songyuxin
// 
// Create Date: 2024/7/9
// Design Name: PCG
// Module Name: acc_time_ctrl_v2
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


module acc_time_ctrl_v2 #(
    parameter                       TCQ               = 0.1 
)(
    // clk & rst 
    input                           clk_i                   ,
    input                           rst_i                   ,

    input                           filter_unit_flag_i      ,
    input                           filter_acc_result_i     ,

    input   [18-1:0]                acc_delay_i             ,
    input   [16-1:0]                acc_hold_i              ,

    output                          filter_acc_flag_o       
);

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Parameter Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Register Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
reg                                 cache_bram_din          = 'd0;
reg         [18-1:0]                cache_bram_waddr        = 'd0;

reg                                 acc_flag                = 'd0;
reg                                 cache_result            = 'd0;
reg                                 hold_flag               = 'd0;
reg         [16-1:0]                hold_cnt                = 'd0;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Wire Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
wire        [18-1:0]                cache_bram_raddr            ;
wire                                cache_bram_dout             ;

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Instance Module
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
cache_bit_ram cache_bit_ram_inst (
    .clka                           ( clk_i                     ),  // input wire clka
    .wea                            ( filter_unit_flag_i        ),  // input wire [0 : 0] wea
    .addra                          ( cache_bram_waddr          ),  // input wire [17 : 0] addra
    .dina                           ( cache_bram_din            ),  // input wire [0 : 0] dina
    .clkb                           ( clk_i                     ),  // input wire clkb
    .addrb                          ( cache_bram_raddr          ),  // input wire [17 : 0] addrb
    .doutb                          ( cache_bram_dout           )   // output wire [0 : 0] doutb
);

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Logic Design
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
always @(posedge clk_i) begin
    if(rst_i)
        cache_bram_din <= #TCQ 'd0;
    else 
        cache_bram_din <= #TCQ filter_acc_result_i;
end

always @(posedge clk_i) begin
    if(rst_i)
        cache_bram_waddr <= #TCQ cache_bram_waddr + 'd1;
    else if(filter_unit_flag_i)
        cache_bram_waddr <= #TCQ cache_bram_waddr + 'd1;
end

assign cache_bram_raddr = cache_bram_waddr - acc_delay_i;

always @(posedge clk_i) begin
    if(rst_i)
        cache_result <= #TCQ 'd0;
    else 
        cache_result <= #TCQ cache_bram_dout;
end

always @(posedge clk_i) begin
    if((acc_hold_i == 'd0) || rst_i)
        hold_flag <= #TCQ 'd0;
    else if(cache_result && (~cache_bram_dout))
        hold_flag <= #TCQ 'd1;
    else if(hold_cnt == (acc_hold_i-1))
        hold_flag <= #TCQ 'd0;
end

always @(posedge clk_i) begin
    if(cache_result && (~cache_bram_dout))
        hold_cnt <= #TCQ 'd0;
    else if(hold_flag)
        hold_cnt <= #TCQ hold_cnt + 1;
end


assign filter_acc_flag_o = cache_result || hold_flag;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


endmodule
