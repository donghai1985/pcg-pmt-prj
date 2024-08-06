`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: zas
// Engineer: songyuxin
// 
// Create Date: 2024/3/4
// Design Name: PCG
// Module Name: acc_time_ctrl
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


module acc_time_ctrl #(
    parameter                       TCQ               = 0.1 
)(
    // clk & rst 
    input                           clk_i                   ,
    input                           rst_i                   ,

    input                           filter_unit_flag_i      ,
    input                           filter_acc_result_i     ,

    input   [16-1:0]                acc_delay_i             ,
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
reg                                 acc_result_d0           = 'd0;
reg                                 acc_result_d1           = 'd0;

reg                                 acc_result_delay_en     = 'd0;
reg                                 acc_result_delay_en_d   = 'd0;
reg                                 acc_nege_delay_en       = 'd0;
reg                                 acc_nege_delay_en_d     = 'd0;
reg                                 acc_flag_delay_en       = 'd0;
reg                                 acc_flag_delay_en_d     = 'd0;

reg                                 acc_flag                = 'd0;
reg                                 acc_flag_d              = 'd0;

reg         [16-1:0]                acc_result_delay_cnt    = 'd0;
reg         [16-1:0]                acc_flag_delay_cnt      = 'd0;
reg         [16-1:0]                acc_nege_delay_cnt      = 'd0;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Wire Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
wire                                acc_result_pose             ;
wire                                acc_result_nege             ;

wire                                acc_result_delay_en_nege    ;
wire                                acc_nege_delay_en_nege      ;
wire                                acc_flag_delay_en_nege      ;

wire                                acc_flag_nege               ;

wire    [16-1:0]                    acc_delay_time              ;

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Instance Module
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>


//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Logic Design
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
assign acc_delay_time = (acc_delay_i=='d0)? 'd1 : acc_delay_i;

always @(posedge clk_i) begin
    acc_result_d0 <= #TCQ filter_acc_result_i;
    acc_result_d1 <= #TCQ acc_result_d0;
end

assign acc_result_pose = (~acc_result_d0) && (filter_acc_result_i);
assign acc_result_nege = (acc_result_d0)  && (~filter_acc_result_i);

always @(posedge clk_i) begin
    if(acc_result_delay_cnt == acc_delay_time)
        acc_result_delay_en <= #TCQ 'd0;
    else if(acc_result_pose)
        acc_result_delay_en <= #TCQ 'd1;
end

always @(posedge clk_i) begin
    if(acc_result_delay_en && (acc_result_delay_cnt < acc_delay_time) && filter_unit_flag_i)
        acc_result_delay_cnt <= #TCQ acc_result_delay_cnt + 1;
    else if(acc_flag_nege)
        acc_result_delay_cnt <= #TCQ 'd0;
end

always @(posedge clk_i) acc_result_delay_en_d <= #TCQ acc_result_delay_en;
assign acc_result_delay_en_nege = acc_result_delay_en_d && (~acc_result_delay_en);

always @(posedge clk_i) begin
    if(acc_result_nege)
        acc_nege_delay_en <= #TCQ 'd1;
    else if(acc_nege_delay_cnt == acc_delay_time)
        acc_nege_delay_en <= #TCQ 'd0;
end

always @(posedge clk_i) begin
    if(acc_result_nege)
        acc_nege_delay_cnt <= #TCQ 'd0;
    else if(acc_nege_delay_en && (acc_nege_delay_cnt < acc_delay_time) && filter_unit_flag_i)
        acc_nege_delay_cnt <= #TCQ acc_nege_delay_cnt + 1;
end

always @(posedge clk_i) acc_nege_delay_en_d <= #TCQ acc_nege_delay_en;
assign acc_nege_delay_en_nege = acc_nege_delay_en_d && (~acc_nege_delay_en);

always @(posedge clk_i) begin
    if(acc_nege_delay_en_nege)
        acc_flag_delay_en <= #TCQ 'd1;
    else if(acc_flag_delay_cnt == acc_hold_i)
        acc_flag_delay_en <= #TCQ 'd0;
end

always @(posedge clk_i) begin
    if(acc_nege_delay_en_nege)
        acc_flag_delay_cnt <= #TCQ 'd0;
    else if(acc_flag && (acc_result_d0 || acc_nege_delay_en))
        acc_flag_delay_cnt <= #TCQ 'd0;
    else if(acc_flag_delay_en && (acc_flag_delay_cnt < acc_hold_i) && filter_unit_flag_i)
        acc_flag_delay_cnt <= #TCQ acc_flag_delay_cnt + 1;
end

always @(posedge clk_i) acc_flag_delay_en_d <= #TCQ acc_flag_delay_en;
assign acc_flag_delay_en_nege = acc_flag_delay_en_d && (~acc_flag_delay_en);

always @(posedge clk_i) begin
    if(acc_result_delay_en_nege)
        acc_flag <= #TCQ 'd1;
    else if(acc_flag_delay_en_nege && (~acc_result_d0))
        acc_flag <= #TCQ 'd0;
end

always @(posedge clk_i) acc_flag_d <= #TCQ acc_flag;
assign acc_flag_nege = acc_flag_d && (~acc_flag);


assign filter_acc_flag_o = acc_flag;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


endmodule
