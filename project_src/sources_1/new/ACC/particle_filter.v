`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: zas
// Engineer: songyuxin
// 
// Create Date: 2023/12/27
// Design Name: PCG
// Module Name: particle_filter
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


module particle_filter #(
    parameter                       TCQ               = 0.1 ,
    parameter                       DATA_WIDTH        = 32  
)(
    // clk & rst 
    input                           clk_i                   ,
    input                           rst_i                   ,

    output  [14-1:0]                curr_track_para_addr_o  ,
    input   [16-1:0]                curr_track_para_data_i  ,

    input                           laser_start_i           ,
    input                           encode_zero_flag_i      ,
    input                           laser_vld_i             ,
    input   [DATA_WIDTH-1:0]        laser_data_i            ,
    input                           filter_acc_flag_i       ,
    input   [16-1:0]                laser_haze_data_i       ,

    input   [16-1:0]                filter_curr_thre_i      ,
    input   [16-1:0]                filter_cache_thre_i     ,
    input   [16-1:0]                lp_filter_curr_thre_i   ,
    input   [16-1:0]                lp_filter_cache_thre_i  ,

    output                          filter_vld_o            ,
    output  [16-1:0]                filter_data_o           ,
    output  [16-1:0]                filter_haze_hub_o       ,
    output                          filter_curr_result_o    ,
    output                          filter_cache_result_o   
);

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Register Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
reg         [14-1:0]                curr_track_para_addr    = 'd0;
reg         [6-1:0]                 down_sample_cnt         = 'd0;

reg                                 laser_fifo_vld_d        = 'd0;
reg         [16-1:0]                laser_fifo_data_d       = 'd0;
reg                                 filter_vld              = 'd0;
reg         [16-1:0]                filter_data             = 'd0;
reg         [16-1:0]                filter_haze_hub         = 'd0;
reg                                 filter_curr_result      = 'd0;
reg                                 filter_cache_result     = 'd0;

reg         [16-1:0]                filter_cache_len        = 'd0;
reg         [10-1:0]                laser_wr_addr           = 'd0;
reg                                 cache_bram_rd           = 'd0;
reg                                 cache_bram_vld          = 'd0;
reg                                 cache_filter_en         = 'd0;
reg                                 laser_cache_acc_flag    = 'd0;

reg                                 filter_acc_flag         = 'd0;
reg         [16-1:0]                laser_haze_data         = 'd0;

reg         [16-1:0]                laser_curr_data         = 'd0;
reg         [16-1:0]                laser_cache_data        = 'd0;

reg                                 curr_filter_en          = 'd0;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Wire Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
wire        [6-1:0]                 down_sample_rate    ;
wire        [10-1:0]                filter_cache_num    ;
wire                                down_sample_vld     ;

wire        [10-1:0]                laser_rd_addr       ;
wire        [33-1:0]                laser_rd_dout       ;

wire                                laser_fifo_vld      ;
wire        [16-1:0]                laser_fifo_data     ;
wire                                laser_fifo_empty    ;
wire                                laser_fifo_almost_empty;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Instance Module
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
xpm_sync_fifo #(
    .ECC_MODE                       ( "no_ecc"                          ),
    .FIFO_MEMORY_TYPE               ( "block"                           ),
    .READ_MODE                      ( "std"                             ),
    .FIFO_WRITE_DEPTH               ( 128                               ),
    .WRITE_DATA_WIDTH               ( 32                                ),
    .READ_DATA_WIDTH                ( 16                                ),
    .USE_ADV_FEATURES               ( "1800"                            )
)actu_laser_sync_fifo_inst (
    .wr_clk_i                       ( clk_i                             ),
    .rst_i                          ( rst_i                             ), // synchronous to wr_clk
    .wr_en_i                        ( laser_vld_i                       ),
    .wr_data_i                      ( laser_data_i                      ),

    .rd_en_i                        ( ~laser_fifo_empty                 ),
    .fifo_rd_vld_o                  ( laser_fifo_vld                    ),
    .fifo_rd_data_o                 ( laser_fifo_data                   ),
    .fifo_empty_o                   ( laser_fifo_empty                  )
);


filter_cache_bram pre_filter_cache_bram_inst (
    .clka                           ( clk_i                             ),  // input wire clka
    .wea                            ( laser_fifo_vld                    ),  // input wire [0 : 0] wea
    .addra                          ( laser_wr_addr                     ),  // input wire [9 : 0] addra
    .dina                           ( {filter_acc_flag,laser_haze_data[15:0],laser_fifo_data[15:0]} ),  // input wire [32 : 0] dina
    .clkb                           ( clk_i                             ),  // input wire clkb
    .addrb                          ( laser_rd_addr                     ),  // input wire [9 : 0] addrb
    .doutb                          ( laser_rd_dout                     )   // output wire [32 : 0] doutb
);
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Logic Design
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
// read curr track facula cache
always @(posedge clk_i) begin
    if(~laser_start_i)
        curr_track_para_addr <= #TCQ 'd0;
    else if(encode_zero_flag_i)
        curr_track_para_addr <= #TCQ curr_track_para_addr + 1;
end

assign down_sample_rate = curr_track_para_data_i[15:10];
assign filter_cache_num = curr_track_para_data_i[9:0];


assign down_sample_vld = (down_sample_cnt == down_sample_rate) && laser_fifo_vld;

always @(posedge clk_i) begin
    if(laser_start_i)begin
        if((down_sample_cnt == down_sample_rate) && laser_fifo_vld)
            down_sample_cnt <= #TCQ 'd0;
        else if(laser_fifo_vld)
            down_sample_cnt <= #TCQ down_sample_cnt + 1;
    end
    else 
        down_sample_cnt <= #TCQ 'd0;
end

always @(posedge clk_i) begin
    if(down_sample_vld)
        laser_wr_addr <= #TCQ laser_wr_addr + 1;
end

always @(posedge clk_i) begin
    cache_bram_rd   <= #TCQ down_sample_vld;
    cache_bram_vld  <= #TCQ cache_bram_rd;
    cache_filter_en <= #TCQ cache_bram_vld;
end

always @(posedge clk_i) filter_cache_len <= #TCQ 'd1023 - filter_cache_num;   // offset bram read delay
always @(posedge clk_i) filter_acc_flag  <= #TCQ filter_acc_flag_i;
always @(posedge clk_i) laser_haze_data  <= #TCQ laser_haze_data_i;

assign laser_rd_addr    = laser_wr_addr + filter_cache_len;

always @(posedge clk_i) begin
    curr_filter_en          <= #TCQ laser_fifo_vld;
    laser_curr_data         <= #TCQ laser_fifo_data - laser_haze_data_i;
    laser_cache_data        <= #TCQ laser_rd_dout[15:0] - laser_rd_dout[31:16];
    laser_cache_acc_flag    <= #TCQ laser_rd_dout[32];
end

always @(posedge clk_i) begin
    if(cache_filter_en)begin
        if(laser_cache_acc_flag)
            filter_cache_result <= #TCQ (laser_cache_data > lp_filter_cache_thre_i);
        else 
            filter_cache_result <= #TCQ (laser_cache_data > filter_cache_thre_i);
    end
end

always @(posedge clk_i) begin
    if(curr_filter_en)begin
        if(filter_acc_flag)
            filter_curr_result <= #TCQ (laser_curr_data > lp_filter_curr_thre_i);
        else 
            filter_curr_result <= #TCQ (laser_curr_data > filter_curr_thre_i);
    end
end

always @(posedge clk_i) begin
    laser_fifo_vld_d    <= #TCQ laser_fifo_vld;
    laser_fifo_data_d   <= #TCQ laser_fifo_data;
end

always @(posedge clk_i)begin
    filter_vld          <= #TCQ laser_fifo_vld_d ;
    filter_data         <= #TCQ laser_fifo_data_d;
    filter_haze_hub     <= #TCQ laser_curr_data;
end

assign curr_track_para_addr_o   = curr_track_para_addr;
assign filter_vld_o             = filter_vld ;
assign filter_data_o            = filter_data;
assign filter_haze_hub_o        = filter_haze_hub;
assign filter_curr_result_o     = filter_curr_result;
assign filter_cache_result_o    = filter_cache_result;

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


endmodule
