`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: zas
// Engineer: songyuxin
// 
// Create Date: 2024/3/4
// Design Name: PCG
// Module Name: acc_flag_generate
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


module acc_flag_generate #(
    parameter                       TCQ               = 0.1 
)(
    // clk & rst 
    input                           clk_i                   ,
    input                           rst_i                   ,

    input                           laser_start_i           ,
    input                           second_track_en_i       ,
    input   [16-1:0]                detect_width_para_i     ,
    input                           filter_delay_vld_i      ,
    input                           filter_acc_flag_i       ,
    input                           filter_vld_i            ,
    input   [16-1:0]                filter_data_i           ,
    input   [16-1:0]                filter_haze_data_i      ,
    input   [16-1:0]                filter_haze_hub_i       ,
    input                           pre_filter_result_i     ,
    input                           filter_curr_result_i    ,
    input                           filter_cache_result_i   ,
    input   [3-1:0]                 particle_acc_bypass_i   ,
    input                           first_track_ctrl_i      ,

    input                           filter_en_i             ,
    output                          pre_widen_result_o      ,
    output                          curr_widen_result_o     ,
    output                          cache_widen_result_o    ,

    output                          filter_delay_vld_o      ,
    output                          filter_acc_flag_o       ,
    output                          filter_vld_o            ,
    output  [16-1:0]                filter_data_o           ,
    output  [16-1:0]                filter_haze_o           ,
    output  [16-1:0]                filter_haze_hub_o       ,
    output                          filter_acc_result_o     
);

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Parameter Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
genvar i;
localparam                          WIDEN_WID               = 10;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Register Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
reg                                 filter_vld              = 'd0;
reg         [16-1:0]                filter_data             = 'd0;
reg                                 filter_acc_result       = 'd0;

reg         [16-1:0]                detect_width_para       = 'd0;
reg         [16-1:0]                pre_detect_width_cnt    = 'd0;
reg         [16-1:0]                curr_detect_width_cnt   = 'd0;
reg         [16-1:0]                cache_detect_width_cnt  = 'd0;

reg                                 pre_widen_result        = 'd0;
reg                                 curr_widen_result       = 'd0;
reg                                 cache_widen_result      = 'd0;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Wire Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>


//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Instance Module
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
// reg_delay #(
//     .DATA_WIDTH             ( 17                            ),
//     .DELAY_NUM              ( WIDEN_WID                     )
// )reg_delay_inst(
//     .clk_i                  ( clk_i                         ),
//     .src_data_i             ( {filter_vld,filter_data}      ),
//     .delay_data_o           ( {filter_vld_o,filter_data_o}  )
// );

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Logic Design
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
// always @(posedge clk_i) begin
//     if((~pre_widen_result) && (~curr_widen_result) && (~filter_cache_result_i))
//         detect_width_para <= #TCQ detect_width_para_i;
// end 

// pre track detect result
always @(posedge clk_i) begin
    if(pre_filter_result_i)
        pre_detect_width_cnt <= #TCQ 'd0;
    else if(pre_widen_result && filter_vld_i)
        pre_detect_width_cnt <= #TCQ pre_detect_width_cnt + 1;
end

always @(posedge clk_i) begin
    if(~filter_en_i)
        pre_widen_result <= #TCQ 'd0;
    else if(pre_filter_result_i)
        pre_widen_result <= #TCQ 'd1;
    else if(pre_detect_width_cnt >= detect_width_para_i-1)
        pre_widen_result <= #TCQ 'd0;
end

// curr track detect result
always @(posedge clk_i) begin
    if(filter_curr_result_i)
        curr_detect_width_cnt <= #TCQ 'd0;
    else if(curr_widen_result && filter_vld_i)
        curr_detect_width_cnt <= #TCQ curr_detect_width_cnt + 1;
end

always @(posedge clk_i) begin
    if(~filter_en_i)
        curr_widen_result <= #TCQ 'd0;
    else if(filter_curr_result_i)
        curr_widen_result <= #TCQ 'd1;
    else if(curr_detect_width_cnt >= detect_width_para_i - 1)
        curr_widen_result <= #TCQ 'd0;
end

// curr cache track detect result
always @(posedge clk_i) begin
    if(filter_cache_result_i)
        cache_detect_width_cnt <= #TCQ 'd0;
    else if(cache_widen_result && filter_vld_i)
        cache_detect_width_cnt <= #TCQ cache_detect_width_cnt + 1;
end

always @(posedge clk_i) begin
    if(~filter_en_i)
        cache_widen_result <= #TCQ 'd0;
    else if(filter_cache_result_i)
        cache_widen_result <= #TCQ 'd1;
    else if(cache_detect_width_cnt >= detect_width_para_i - 1)
        cache_widen_result <= #TCQ 'd0;
end

// acc detect result
always @(posedge clk_i) begin
    if(~laser_start_i)
        filter_acc_result <= #TCQ 'd0;
    else begin
        if((~second_track_en_i) && first_track_ctrl_i)
            filter_acc_result <= #TCQ curr_widen_result;
        else if(filter_en_i)
            filter_acc_result <= #TCQ ((pre_widen_result || particle_acc_bypass_i[2])
                                     && (curr_widen_result  || particle_acc_bypass_i[1]) 
                                     && ((~cache_widen_result) || particle_acc_bypass_i[0]));
        else 
            filter_acc_result <= #TCQ 'd0;
    end
end

assign filter_delay_vld_o   = filter_delay_vld_i;
assign filter_acc_flag_o    = filter_acc_flag_i;
assign filter_vld_o         = filter_vld_i;
assign filter_data_o        = filter_data_i;
assign filter_haze_o        = filter_haze_data_i;
assign filter_haze_hub_o    = filter_haze_hub_i;
assign filter_acc_result_o  = filter_acc_result;

// debug code
assign pre_widen_result_o  = pre_widen_result;
assign curr_widen_result_o  = curr_widen_result;
assign cache_widen_result_o  = cache_widen_result;

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


endmodule
