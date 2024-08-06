`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: zas
// Engineer: songyuxin
// 
// Create Date: 2024/5/29
// Design Name: PCG
// Module Name: aom_flag_trim
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


module aom_flag_trim #(
    parameter                       TCQ               = 0.1 
)(
    // clk & rst 
    input                           clk_i                   ,
    input                           rst_i                   ,

    input                           laser_start_i           ,
    input                           filter_unit_vld_i       ,
    input                           filter_acc_result_i     ,
    input                           second_track_en_i       ,
    input   [16-1:0]                light_spot_para_i       ,
    input   [16-1:0]                aom_ctrl_delay_i        ,
    input   [16-1:0]                aom_ctrl_hold_i         ,
    input   [16-1:0]                lp_recover_delay_i      ,
    input   [16-1:0]                lp_recover_hold_i       ,
    input   [16-1:0]                recover_edge_slot_time_i,
    output  [16-1:0]                aom_ctrl_delay_abs_o    ,

    output                          aom_ctrl_flag_o         ,
    output                          recover_edge_flag_o     ,
    output                          lp_recover_flag_o       
);

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Parameter Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Register Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
reg signed  [16-1:0]                aom_ctrl_delay      = 'd0;
reg         [16-1:0]                lp_recover_delay    = 'd0;
reg         [16-1:0]                recover_edge_cnt    = 'd0;
reg                                 recover_edge_flag   = 'd0;
reg                                 lp_recover_flag_d   = 'd0;

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Wire Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
wire                                lp_recover_flag         ;
wire        [16-1:0]                aom_ctrl_delay_abs      ;



//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Instance Module
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
acc_time_ctrl_v2 acc_ctrl_inst(
    .clk_i                          ( clk_i                             ),
    .rst_i                          ( ~laser_start_i                    ),

    .filter_unit_flag_i             ( filter_unit_vld_i                 ),
    .filter_acc_result_i            ( filter_acc_result_i               ),
    .acc_delay_i                    ( aom_ctrl_delay_abs                ),
    .acc_hold_i                     ( aom_ctrl_hold_i                   ),

    .filter_acc_flag_o              ( aom_ctrl_flag_o                   )
);

acc_time_ctrl_v2 lp_recover_inst(
    .clk_i                          ( clk_i                             ),
    .rst_i                          ( ~laser_start_i                    ),

    .filter_unit_flag_i             ( filter_unit_vld_i                 ),
    .filter_acc_result_i            ( filter_acc_result_i               ),
    .acc_delay_i                    ( lp_recover_delay                  ),
    .acc_hold_i                     ( lp_recover_hold_i                 ),

    .filter_acc_flag_o              ( lp_recover_flag                   )
);

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Logic Design
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

always @(posedge clk_i) begin
    if(aom_ctrl_delay_i[15])
        aom_ctrl_delay <= #TCQ light_spot_para_i - (~aom_ctrl_delay_i + 1);
    else 
        aom_ctrl_delay <= #TCQ light_spot_para_i + aom_ctrl_delay_i;
end

assign aom_ctrl_delay_abs = aom_ctrl_delay[15] ? 'd1 : aom_ctrl_delay;


always @(posedge clk_i) begin
    if(lp_recover_delay_i[15])
        lp_recover_delay <= #TCQ aom_ctrl_delay_abs - (~lp_recover_delay_i + 1);
    else 
        lp_recover_delay <= #TCQ aom_ctrl_delay_abs + lp_recover_delay_i;
end


always @(posedge clk_i) lp_recover_flag_d <= #TCQ lp_recover_flag;
always @(posedge clk_i) begin
    if(recover_edge_slot_time_i == 'd0)
        recover_edge_flag <= #TCQ 'd0;
    else if(lp_recover_flag_d ^ lp_recover_flag)
        recover_edge_flag <= #TCQ 'd1;
    else if((recover_edge_cnt == recover_edge_slot_time_i - 1))
        recover_edge_flag <= #TCQ 'd0;
end

always @(posedge clk_i) begin
    if(lp_recover_flag_d ^ lp_recover_flag)
        recover_edge_cnt <= #TCQ 'd0;
    else if(recover_edge_flag)
        recover_edge_cnt <= #TCQ recover_edge_cnt + 1;
end

assign lp_recover_flag_o   = lp_recover_flag_d;
assign recover_edge_flag_o = recover_edge_flag;
assign aom_ctrl_delay_abs_o= aom_ctrl_delay_abs;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


endmodule
