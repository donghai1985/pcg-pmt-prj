`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: zas
// Engineer: songyuxin
// 
// Create Date: 2024/03/18
// Design Name: pcg
// Module Name: acc_demo_flag_trim
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
//                                               ______________________________
//  acc_demo_flag_i          ___________________|                              |___________________
// 
//                                               ______________________________
//  acc_demo_trim_ctrl_o     ___________________|                              |__________________
//
//                                                     _____________________________
//  acc_demo_trim_flag_o     _________________________|                             |_____________
//
//
//
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module acc_demo_flag_trim #(
    parameter                       TCQ         = 0.1 

)(
    // clk & rst
    input                           clk_i                       ,
    input                           rst_i                       ,

    input                           pmt_scan_en_i               ,
    output  [32-1:0]                acc_flag_phase_cnt_o        ,

    input                           acc_demo_flag_i             ,
    input   [16-1:0]                acc_demo_trim_time_pose_i   ,
    input   [16-1:0]                acc_demo_trim_time_nege_i   ,

    output                          acc_demo_trim_ctrl_o        ,
    output                          acc_demo_trim_flag_o        
);


//////////////////////////////////////////////////////////////////////////////////
// *********** Define Parameter Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
localparam                          ACC_DEMO_FLAG_DELAY     = 36;

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Register Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
reg                                 acc_demo_flag_d0        = 'd0;
reg     [16-1:0]                    acc_demo_trim_nege_cnt  = 'd0;
reg     [16-1:0]                    acc_demo_trim_pose_cnt  = 'd0;
reg     [6-1:0]                     acc_demo_trim_delay_cnt = 'd0;
reg                                 acc_demo_trim_ctrl      = 'd0;
reg                                 acc_demo_trim_flag      = 'd0;

reg                                 acc_demo_pose_delay     = 'd0;
reg                                 acc_demo_nege_delay     = 'd0;
reg                                 acc_demo_pose_delay_d   = 'd0;
reg                                 acc_demo_nege_delay_d   = 'd0;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Wire Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
wire                                acc_demo_flag_pose ;
wire                                acc_demo_flag_nege ;

wire                                acc_demo_pose_delay_nege;
wire                                acc_demo_nege_delay_nege;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Instance Module
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>


//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Logic Design
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
always @(posedge clk_i) acc_demo_flag_d0 <= #TCQ acc_demo_flag_i;
assign acc_demo_flag_pose = (~acc_demo_flag_d0) && acc_demo_flag_i;
assign acc_demo_flag_nege = acc_demo_flag_d0    && (~acc_demo_flag_i);

// always @(posedge clk_i) begin
//     if(acc_demo_flag_d0 && (~acc_demo_trim_flag))
//         acc_demo_trim_nege_cnt <= #TCQ acc_demo_trim_nege_cnt + 1;
//     else 
//         acc_demo_trim_nege_cnt <= #TCQ 'd0;
// end

// always @(posedge clk_i) begin
//     if((~acc_demo_flag_d0) && acc_demo_trim_flag)
//         acc_demo_trim_pose_cnt <= #TCQ acc_demo_trim_pose_cnt + 1;
//     else 
//         acc_demo_trim_pose_cnt <= #TCQ 'd0;
// end
always @(posedge clk_i) begin
    if(acc_demo_flag_pose)
        acc_demo_pose_delay <= #TCQ 'd1;
    else if((acc_demo_trim_pose_cnt == acc_demo_trim_time_nege_i) || (acc_demo_trim_nege_cnt==acc_demo_trim_time_pose_i)) 
        acc_demo_pose_delay <= #TCQ 'd0;
end

always @(posedge clk_i) begin
    if(acc_demo_pose_delay)
        acc_demo_trim_pose_cnt <= #TCQ acc_demo_trim_pose_cnt + 1;
    else 
        acc_demo_trim_pose_cnt <= #TCQ 'd0;
end

always @(posedge clk_i) begin
    if(acc_demo_flag_nege)
        acc_demo_nege_delay <= #TCQ 'd1;
    else if(acc_demo_trim_nege_cnt == acc_demo_trim_time_pose_i) 
        acc_demo_nege_delay <= #TCQ 'd0;
end

always @(posedge clk_i) begin
    if(acc_demo_nege_delay)
        acc_demo_trim_nege_cnt <= #TCQ acc_demo_trim_nege_cnt + 1;
    else 
        acc_demo_trim_nege_cnt <= #TCQ 'd0;
end
always @(posedge clk_i) acc_demo_pose_delay_d <= #TCQ acc_demo_pose_delay;
always @(posedge clk_i) acc_demo_nege_delay_d <= #TCQ acc_demo_nege_delay;
assign acc_demo_pose_delay_nege = (~acc_demo_pose_delay) && acc_demo_pose_delay_d;
assign acc_demo_nege_delay_nege = (~acc_demo_nege_delay) && acc_demo_nege_delay_d;

always @(posedge clk_i) begin
    if(acc_demo_nege_delay_nege)
        acc_demo_trim_flag <= #TCQ 'd0;
    else if(acc_demo_pose_delay_nege)
        acc_demo_trim_flag <= #TCQ 'd1;
end

assign acc_demo_trim_ctrl_o = acc_demo_flag_d0;
assign acc_demo_trim_flag_o = acc_demo_trim_flag;

// check acc flag ctrl and flag phase
reg          pmt_scan_en_d = 'd0;
reg [16-1:0] acc_ctrl_phase_cnt = 'd0;
reg [16-1:0] acc_flag_phase_cnt = 'd0;
reg          acc_demo_trim_ctrl_o_d = 'd0; 
reg          acc_demo_trim_flag_o_d = 'd0; 
always @(posedge clk_i) pmt_scan_en_d <= #TCQ pmt_scan_en_i;
always @(posedge clk_i) acc_demo_trim_ctrl_o_d <= #TCQ acc_demo_trim_ctrl_o;
always @(posedge clk_i) acc_demo_trim_flag_o_d <= #TCQ acc_demo_trim_flag_o;
always @(posedge clk_i) begin
    if(~pmt_scan_en_d && pmt_scan_en_i)
        acc_ctrl_phase_cnt <= #TCQ 'd0;
    else if(acc_demo_trim_ctrl_o_d && (~acc_demo_trim_ctrl_o) && (~acc_demo_trim_flag_o))
        acc_ctrl_phase_cnt <= #TCQ acc_ctrl_phase_cnt + 1;
end
always @(posedge clk_i) begin
    if(~pmt_scan_en_d && pmt_scan_en_i)
        acc_flag_phase_cnt <= #TCQ 'd0;
    else if((~acc_demo_trim_flag_o_d) && acc_demo_trim_flag_o && (~acc_demo_trim_ctrl_o))
        acc_flag_phase_cnt <= #TCQ acc_flag_phase_cnt + 1;
end

assign acc_flag_phase_cnt_o = {acc_ctrl_phase_cnt,acc_flag_phase_cnt};
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


endmodule
