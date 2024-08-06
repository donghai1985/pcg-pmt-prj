`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: zas
// Engineer: songyuxin
// 
// Create Date: 2024/3/4
// Design Name: PCG
// Module Name: acc_lp_recover
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


module acc_lp_recover #(
    parameter                       TCQ               = 0.1 
)(
    // clk & rst 
    input                           clk_i                   ,
    input                           rst_i                   ,

    input                           laser_vld_i             ,
    input   [16-1:0]                laser_data_i            ,
    input                           recover_edge_flag_i     ,
    // input   [16-1:0]                laser_haze_data_i       ,
    input                           filter_acc_flag_i       ,
    input                           laser_zero_flag_i       ,

    input   [16-1:0]                lp_recover_factor_i     ,  // 8bit integer + 8bit decimal

    output                          lp_recover_acc_flag_o   ,
    output                          lp_recover_zero_flag_o  ,
    output                          lp_recover_vld_o        ,
    output  [16-1:0]                lp_recover_data_o       
);

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Parameter Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Register Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
reg                                 filter_acc_flag_d0      = 'd0; 
reg                                 filter_acc_flag_d1      = 'd0; 
reg                                 filter_acc_flag_d2      = 'd0;
reg                                 recover_edge_flag_d0    = 'd0; 
reg                                 recover_edge_flag_d1    = 'd0; 
reg                                 recover_edge_flag_d2    = 'd0;
reg                                 zero_flag_d0            = 'd0; 
reg                                 zero_flag_d1            = 'd0; 
reg                                 zero_flag_d2            = 'd0;
reg                                 laser_vld_d0            = 'd0; 
reg                                 laser_vld_d1            = 'd0; 
reg                                 laser_vld_d2            = 'd0;
reg         [16-1:0]                laser_data_d0           = 'd0;
reg         [16-1:0]                laser_data_d1           = 'd0;
reg         [16-1:0]                laser_data_d2           = 'd0;
reg         [32-1:0]                lp_recover_data_d0      = 'd0;
reg         [32-1:0]                lp_recover_data_d1      = 'd0;
reg         [32-1:0]                lp_recover_data_d2      = 'd0;

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Wire Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>


//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Instance Module
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Logic Design
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
always @(posedge clk_i) begin
    lp_recover_data_d0 <= #TCQ laser_data_i * lp_recover_factor_i;
    lp_recover_data_d1 <= #TCQ lp_recover_data_d0;
    lp_recover_data_d2 <= #TCQ lp_recover_data_d1;
end

always @(posedge clk_i) begin
    laser_data_d0 <= #TCQ laser_data_i;
    laser_data_d1 <= #TCQ laser_data_d0;
    laser_data_d2 <= #TCQ laser_data_d1;
end

always @(posedge clk_i) begin
    laser_vld_d0 <= #TCQ laser_vld_i;
    laser_vld_d1 <= #TCQ laser_vld_d0;
    laser_vld_d2 <= #TCQ laser_vld_d1;
end

always @(posedge clk_i) begin
    filter_acc_flag_d0 <= #TCQ filter_acc_flag_i;
    filter_acc_flag_d1 <= #TCQ filter_acc_flag_d0;
    filter_acc_flag_d2 <= #TCQ filter_acc_flag_d1;
end

always @(posedge clk_i) begin
    recover_edge_flag_d0 <= #TCQ recover_edge_flag_i;
    recover_edge_flag_d1 <= #TCQ recover_edge_flag_d0;
    recover_edge_flag_d2 <= #TCQ recover_edge_flag_d1;
end

always @(posedge clk_i) begin
    zero_flag_d0 <= #TCQ laser_zero_flag_i;
    zero_flag_d1 <= #TCQ zero_flag_d0;
    zero_flag_d2 <= #TCQ zero_flag_d1;
end

assign lp_recover_vld_o  = laser_vld_d2;
assign lp_recover_data_o = recover_edge_flag_d2 ? 16'd1 :
                           filter_acc_flag_d2   ? lp_recover_data_d2[24-1:8] : 
                                                  laser_data_d2;
assign lp_recover_acc_flag_o = filter_acc_flag_d2;
assign lp_recover_zero_flag_o = zero_flag_d2;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


endmodule
