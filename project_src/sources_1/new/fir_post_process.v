`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: zas
// Engineer: songyuxin
// 
// Create Date: 2024/3/4
// Design Name: PCG
// Module Name: fir_post_process
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


module fir_post_process #(
    parameter                       TCQ               = 0.1 
)(
    // clk & rst 
    input                           clk_i                   ,
    input                           rst_i                   ,

    input                           laser_start_i           ,
    input                           fir_laser_zero_flag_i   ,
    input                           fir_acc_flag_i          ,
    input                           fir_laser_vld_i         ,
    input   [16-1:0]                fir_laser_data_i        ,
    input                           fir_post_para_en_i      ,
    input   [16-1:0]                circle_lose_num_i       ,
    input   [16-1:0]                track_align_num_i       ,

    output                          fir_post_zero_flag_o    ,
    output                          fir_post_acc_flag_o     ,
    output                          fir_post_pre_vld_o      ,
    output                          fir_post_vld_o          ,
    output  [16-1:0]                fir_post_data_o         
);

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Parameter Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Register Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
reg         [16-1:0]                circle_lose_num         = 'd0;
reg         [16-1:0]                track_align_num         = 'd0;
reg         [16-1:0]                circle_lose_cnt         = 'd1;
reg         [16-1:0]                track_align_cnt         = 'd0;

reg                                 fir_post_zero_flag_d    = 'd0;
reg                                 fir_post_acc_flag_d     = 'd0;
reg                                 circle_lose_flag        = 'd0;
reg                                 fir_ds_lost_d           = 'd0;
reg                                 fir_laser_vld_d      = 'd0;
reg         [16-1:0]                fir_post_data           = 'd0;

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Wire Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
wire                                pre_track_lose_finish   ;


//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Instance Module
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Logic Design
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
always @(posedge clk_i) begin
    if(~laser_start_i || fir_post_para_en_i)begin
        circle_lose_num <= #TCQ circle_lose_num_i;
        track_align_num <= #TCQ track_align_num_i;
    end
end

always @(posedge clk_i) begin
    if(~laser_start_i || pre_track_lose_finish || fir_post_para_en_i)
        circle_lose_cnt <= #TCQ 'd1;
    else if(fir_laser_vld_i)begin
        if(circle_lose_cnt == circle_lose_num)
            circle_lose_cnt <= #TCQ 'd1;
        else
            circle_lose_cnt <= #TCQ circle_lose_cnt + 1;
    end
end

always @(posedge clk_i) begin
    if(~laser_start_i || fir_post_para_en_i)
        track_align_cnt <= #TCQ 'd0;
    else if(fir_laser_vld_i && (circle_lose_cnt == circle_lose_num) && (~pre_track_lose_finish))begin
        track_align_cnt <= #TCQ track_align_cnt + 1;
    end
end

assign pre_track_lose_finish = track_align_cnt >= track_align_num;

always @(posedge clk_i) begin
    fir_laser_vld_d         <= #TCQ fir_laser_vld_i;
    circle_lose_flag        <= #TCQ fir_laser_vld_i && (circle_lose_cnt == circle_lose_num);
    fir_post_zero_flag_d    <= #TCQ fir_laser_zero_flag_i;
    fir_post_acc_flag_d     <= #TCQ fir_acc_flag_i;
    fir_post_data           <= #TCQ fir_laser_data_i ;
end


assign fir_post_zero_flag_o = fir_post_zero_flag_d;
assign fir_post_acc_flag_o  = fir_post_acc_flag_d;
assign fir_post_pre_vld_o   = fir_laser_vld_d && (!circle_lose_flag);
assign fir_post_vld_o       = fir_laser_vld_d;
assign fir_post_data_o      = fir_post_data;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


endmodule
