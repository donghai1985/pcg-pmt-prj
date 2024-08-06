`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: zas
// Engineer: songyuxin
// 
// Create Date: 2024/5/17
// Design Name: PCG
// Module Name: pre_particle_filter_v2
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


module pre_particle_filter_v2 #(
    parameter                       TCQ               = 0.1 ,
    parameter                       DATA_WIDTH        = 32  
)(
    // clk & rst 
    input                           clk_i                   ,
    input                           rst_i                   ,

    input                           pre_laser_vld_i         ,
    input   [64-1:0]                pre_laser_data_i        ,

    input   [16-1:0]                pre_filter_thre_i       ,
    // input   [16-1:0]                lp_pre_filter_thre_i    ,

    output                          pre_filter_vld_o        ,
    output  [16-1:0]                pre_filter_data_o       ,
    output  [16-1:0]                pre_filter_haze_hub_o   ,
    output                          pre_filter_result_o     
);

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Register Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
reg                                 filter_vld          = 'd0;
reg                                 filter_result       = 'd0;
reg         [16-1:0]                filter_data         = 'd0;
reg         [16-1:0]                filter_haze_hub     = 'd0;

reg                                 pre_laser_vld_d     = 'd0;
reg         [16-1:0]                pre_laser_data_d    = 'd0;

reg                                 pre_acc_flag        = 'd0;
reg         [17-1:0]                laser_pre_data      = 'd0;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Wire Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
wire        [16-1:0]                laser_pre_data_abs ;

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Instance Module
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Logic Design
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
always @(posedge clk_i) begin
    pre_laser_vld_d  <= #TCQ pre_laser_vld_i;
    pre_laser_data_d <= #TCQ pre_laser_data_i;
end

always @(posedge clk_i) begin
    if(pre_laser_vld_i)begin
        pre_acc_flag   <= #TCQ pre_laser_data_i[63];
        laser_pre_data <= #TCQ pre_laser_data_i[15:0] - pre_laser_data_i[31:16];
    end
end

assign laser_pre_data_abs = laser_pre_data[16] ? 'd0 : laser_pre_data[15:0];

always @(posedge clk_i) begin
    if(pre_laser_vld_d)begin
        // if(pre_acc_flag)
        //     filter_result <= #TCQ (laser_pre_data_abs > pre_filter_thre_i);
        // else 
        filter_result <= #TCQ (laser_pre_data_abs > pre_filter_thre_i);
    end
end

always @(posedge clk_i) begin
    filter_vld      <= #TCQ pre_laser_vld_d;
    filter_data     <= #TCQ pre_laser_data_d;
    filter_haze_hub <= #TCQ laser_pre_data;
end

assign pre_filter_vld_o     = filter_vld;
assign pre_filter_data_o    = filter_data;
assign pre_filter_haze_hub_o= filter_haze_hub;
assign pre_filter_result_o  = filter_result;

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


endmodule
