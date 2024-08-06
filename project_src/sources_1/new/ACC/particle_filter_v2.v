`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: zas
// Engineer: songyuxin
// 
// Create Date: 2024/5/17
// Design Name: PCG
// Module Name: particle_filter_v2
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


module particle_filter_v2 #(
    parameter                       TCQ               = 0.1 ,
    parameter                       DATA_WIDTH        = 32  
)(
    // clk & rst 
    input                           clk_i                   ,
    input                           rst_i                   ,

    input   [16-1:0]                light_spot_spacing_i    ,

    input                           laser_delay_vld_i       ,
    input                           laser_acc_flag_i        ,
    input                           laser_vld_i             ,
    input   [16-1:0]                laser_data_i            ,
    input   [16-1:0]                laser_haze_data_i       ,

    input   [16-1:0]                filter_curr_thre_i      ,
    input   [16-1:0]                filter_cache_thre_i     ,
    // input   [16-1:0]                lp_filter_curr_thre_i   ,
    // input   [16-1:0]                lp_filter_cache_thre_i  ,

    output                          filter_delay_vld_o      ,
    output                          filter_acc_flag_o       ,
    output                          filter_vld_o            ,
    output  [16-1:0]                filter_data_o           ,
    output  [16-1:0]                filter_haze_data_o      ,
    output  [16-1:0]                filter_haze_hub_o       ,
    output                          filter_curr_result_o    ,
    output                          filter_cache_result_o   
);

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Register Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
reg                                 laser_delay_vld_d       = 'd0;
reg                                 laser_vld_d             = 'd0;
reg         [16-1:0]                laser_data_d            = 'd0;
reg                                 filter_delay_vld        = 'd0;
reg                                 filter_vld              = 'd0;
reg         [16-1:0]                filter_data             = 'd0;
reg         [16-1:0]                filter_haze_hub         = 'd0;
reg                                 filter_curr_result      = 'd0;
reg                                 filter_cache_result     = 'd0;

reg         [11-1:0]                laser_wr_addr           = 'd0;
reg                                 cache_bram_rd           = 'd0;
reg                                 cache_bram_vld          = 'd0;
reg                                 cache_filter_en         = 'd0;
reg                                 laser_cache_acc_flag    = 'd0;

reg                                 laser_acc_flag_d        = 'd0;
reg                                 filter_acc_flag         = 'd0;
reg         [16-1:0]                laser_haze_data         = 'd0;

reg         [17-1:0]                laser_curr_data         = 'd0;
reg         [17-1:0]                laser_cache_data        = 'd0;

reg                                 curr_filter_en          = 'd0;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Wire Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
wire                                down_sample_vld     ;

wire        [11-1:0]                laser_rd_addr       ;
wire        [32-1:0]                laser_rd_dout       ;

wire                                laser_fifo_vld      ;
wire        [16-1:0]                laser_fifo_data     ;
wire                                laser_fifo_empty    ;
wire                                laser_fifo_almost_empty;

wire        [16-1:0]                laser_curr_data_abs ;
wire        [16-1:0]                laser_cache_data_abs;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Instance Module
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

filter_cache_bram pre_filter_cache_bram_inst (
    .clka                           ( clk_i                             ),  // input wire clka
    .wea                            ( laser_vld_i                       ),  // input wire [0 : 0] wea
    .addra                          ( laser_wr_addr                     ),  // input wire [10: 0] addra
    .dina                           ( {laser_haze_data[15:0],laser_data_i[15:0]} ),  // input wire [32 : 0] dina
    .clkb                           ( clk_i                             ),  // input wire clkb
    .addrb                          ( laser_rd_addr                     ),  // input wire [10: 0] addrb
    .doutb                          ( laser_rd_dout                     )   // output wire [32 : 0] doutb
);
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Logic Design
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

always @(posedge clk_i) begin
    if(laser_vld_i)
        laser_wr_addr <= #TCQ laser_wr_addr + 1;
end

always @(posedge clk_i) begin
    cache_bram_rd   <= #TCQ laser_vld_i;
    cache_bram_vld  <= #TCQ cache_bram_rd;
    cache_filter_en <= #TCQ cache_bram_vld;
end

always @(posedge clk_i) laser_haze_data  <= #TCQ laser_haze_data_i;

assign laser_rd_addr    = laser_wr_addr - light_spot_spacing_i[11-1:0];

always @(posedge clk_i) begin
    curr_filter_en          <= #TCQ laser_delay_vld_i;
    laser_curr_data         <= #TCQ laser_data_i - laser_haze_data_i;
    laser_cache_data        <= #TCQ laser_rd_dout[15:0] - laser_rd_dout[31:16];
    // laser_cache_acc_flag    <= #TCQ laser_rd_dout[32];
end

assign laser_curr_data_abs  = laser_curr_data[16]  ? 'd0 : laser_curr_data[15:0] ;
assign laser_cache_data_abs = laser_cache_data[16] ? 'd0 : laser_cache_data[15:0];

always @(posedge clk_i) begin
    if(cache_filter_en)begin
        // if(laser_cache_acc_flag)
        //     filter_cache_result <= #TCQ (laser_cache_data_abs > lp_filter_cache_thre_i);
        // else 
        filter_cache_result <= #TCQ (laser_cache_data_abs > filter_cache_thre_i);
    end
end

always @(posedge clk_i) begin
    if(curr_filter_en)begin
        filter_curr_result <= #TCQ (laser_curr_data_abs > filter_curr_thre_i);
    end
end

always @(posedge clk_i) begin
    laser_delay_vld_d <= #TCQ laser_delay_vld_i;
    laser_acc_flag_d  <= #TCQ laser_acc_flag_i;
    laser_vld_d    <= #TCQ laser_vld_i;
    laser_data_d   <= #TCQ laser_data_i;
end

always @(posedge clk_i)begin
    filter_delay_vld    <= #TCQ laser_delay_vld_d;
    filter_acc_flag     <= #TCQ laser_acc_flag_d;
    filter_vld          <= #TCQ laser_vld_d ;
    filter_data         <= #TCQ laser_data_d;
    filter_haze_hub     <= #TCQ laser_curr_data_abs;
end

assign filter_delay_vld_o       = filter_delay_vld;
assign filter_acc_flag_o        = filter_acc_flag;
assign filter_vld_o             = filter_vld ;
assign filter_data_o            = filter_data;
assign filter_haze_data_o       = laser_haze_data;
assign filter_haze_hub_o        = filter_haze_hub;
assign filter_curr_result_o     = filter_curr_result;
assign filter_cache_result_o    = filter_cache_result;

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


endmodule
