`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: zas
// Engineer: songyuxin
// 
// Create Date: 2024/2/28
// Design Name: PCG
// Module Name: haze_generate
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

module haze_generate #(
    parameter                                   TCQ                 = 0.1   ,
    parameter                                   DATA_WIDTH          = 16    
)(
    input                                       clk_i                   ,
    input                                       rst_i                   ,

    input                                       laser_start_i           ,
    input                                       laser_vld_i             ,
    input       [DATA_WIDTH-1:0]                laser_raw_data_i        ,
    input                                       acc_flag_i              ,
    input       [DATA_WIDTH-1:0]                laser_data_i            ,
    input       [DATA_WIDTH-1:0]                haze_up_limit_i         ,

    // output                                      haze_vld_o              ,
    output      [DATA_WIDTH-1:0]                haze_data_o             
);
//////////////////////////////////////////////////////////////////////////////////
// *********** Define Parameter Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>


//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Register Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

reg             [6-1:0]                         down_sample_cnt     = 'd0;
reg                                             reorder_vld_d0      = 'd0;
reg                                             reorder_vld_d1      = 'd0;
reg             [DATA_WIDTH+2 -1:0]             reorder_rank_sum0   = 'd0; 
reg             [DATA_WIDTH+2 -1:0]             reorder_rank_sum1   = 'd0;
reg             [DATA_WIDTH+3 -1:0]             reorder_rank_sum    = 'd0;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Wire Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

wire                                            mid_src_vld ;
wire            [DATA_WIDTH-1:0]                mid_src_data;
wire                                            sample_mid_vld ;
wire            [DATA_WIDTH-1:0]                sample_mid_data;

wire                                            reorder_vld ;
wire            [DATA_WIDTH-1:0]                reorder_rank0;
wire            [DATA_WIDTH-1:0]                reorder_rank1;
wire            [DATA_WIDTH-1:0]                reorder_rank2;
wire            [DATA_WIDTH-1:0]                reorder_rank3;
wire            [DATA_WIDTH-1:0]                reorder_rank4;
wire            [DATA_WIDTH-1:0]                reorder_rank5;
wire            [DATA_WIDTH-1:0]                reorder_rank6;
wire            [DATA_WIDTH-1:0]                reorder_rank7;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Instance Module
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
mid_filter #(
    .DATA_WIDTH             ( DATA_WIDTH                    )
)mid_filter_inst (
    .clk_i                  ( clk_i                         ),
    .rst_i                  ( rst_i                         ),
    .src_vld_i              ( mid_src_vld                   ),
    .src_data_i             ( mid_src_data                  ),

    .mid_vld_o              ( sample_mid_vld                ),
    .mid_data_o             ( sample_mid_data               )
);

haze_reorder #(
    .DATA_WIDTH             ( DATA_WIDTH                    )
)haze_reorder_inst(
    .clk_i                  ( clk_i                         ),
    .rst_i                  ( rst_i                         ),

    .src_vld_i              ( sample_mid_vld                ),
    .src_data_i             ( sample_mid_data               ),

    .reorder_vld_o          ( reorder_vld                   ),
    .reorder_rank0_o        ( reorder_rank0                 ),
    .reorder_rank1_o        ( reorder_rank1                 ),
    .reorder_rank2_o        ( reorder_rank2                 ),
    .reorder_rank3_o        ( reorder_rank3                 ),
    .reorder_rank4_o        ( reorder_rank4                 ),
    .reorder_rank5_o        ( reorder_rank5                 ),
    .reorder_rank6_o        ( reorder_rank6                 ),
    .reorder_rank7_o        ( reorder_rank7                 )
);

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Logic Design
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
wire haze_data_vld = (laser_data_i < haze_up_limit_i);
// 64clk down sample
always @(posedge clk_i) begin
    if(rst_i)
        down_sample_cnt <= #TCQ 'd0;
    else if(laser_vld_i && (~acc_flag_i) && haze_data_vld)
        down_sample_cnt <= #TCQ down_sample_cnt + 1;
end

assign mid_src_vld = (&down_sample_cnt) && laser_vld_i && (~acc_flag_i) && haze_data_vld;
assign mid_src_data = laser_data_i;


// Calculate the average value, output haze
always @(posedge clk_i) begin
    reorder_vld_d0 <= #TCQ reorder_vld;
    reorder_vld_d1 <= #TCQ reorder_vld_d0;
end

always @(posedge clk_i) begin
    reorder_rank_sum0 <= #TCQ reorder_rank0 + reorder_rank1 + reorder_rank2 + reorder_rank3 ;
    reorder_rank_sum1 <= #TCQ reorder_rank4 + reorder_rank5 + reorder_rank6 + reorder_rank7 ;
end 

always @(posedge clk_i) begin
    if(reorder_vld_d0)
        reorder_rank_sum  <= #TCQ reorder_rank_sum0 + reorder_rank_sum1;
end

// protect haze level when scan start 
reg haze_level_flag = 'd0;
reg [DATA_WIDTH-1:0] haze_delta_abs = 'd0;

always @(posedge clk_i) begin
    if(laser_raw_data_i > reorder_rank_sum[DATA_WIDTH+3 -1:3])
        haze_delta_abs <= #TCQ laser_raw_data_i - reorder_rank_sum[DATA_WIDTH+3 -1:3];
    else 
        haze_delta_abs <= #TCQ reorder_rank_sum[DATA_WIDTH+3 -1:3] - laser_raw_data_i;
end 

reg first_reorder_vld = 'd0;
always @(posedge clk_i) begin
    if(~laser_start_i)
        first_reorder_vld <= #TCQ 'd0;
    else if(reorder_vld_d0)
        first_reorder_vld <= #TCQ 'd1;
end

always @(posedge clk_i) begin
    if(~first_reorder_vld)
        haze_level_flag <= #TCQ 'd0;
    else if(haze_delta_abs < 16'd20)
        haze_level_flag <= #TCQ 'd1;
end

// assign haze_vld_o  = reorder_vld_d1;
reg [DATA_WIDTH-1:0] user_haze_data_d0 = 'd0;
reg [DATA_WIDTH-1:0] user_haze_data_d1 = 'd0;
always @(posedge clk_i) begin
    user_haze_data_d0 <= #TCQ reorder_rank_sum[DATA_WIDTH+3 -1:3];
    user_haze_data_d1 <= #TCQ user_haze_data_d0;
end

assign haze_data_o = haze_level_flag ? user_haze_data_d1 : laser_raw_data_i;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    
endmodule