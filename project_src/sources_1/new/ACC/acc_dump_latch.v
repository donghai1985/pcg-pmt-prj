`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: zas
// Engineer: songyuxin
// 
// Create Date: 2024/08/13
// Design Name: pcg
// Module Name: acc_dump_latch
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
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

module acc_dump_latch #(
    parameter                       TCQ         = 0.1 

)(
    // clk & rst
    input                           clk_i                       ,
    input                           rst_i                       ,

    input                           pmt_scan_en_i               ,
    input                           acc_flag_i                  ,
    input   [32-1:0]                light_spot_para_i           ,
    input   [32-1:0]                detect_width_para_i         ,
    input                           laser_vld_i                 ,
    input   [16-1:0]                laser_data_i                ,
    input   [16-1:0]                laser_haze_data_i           ,

    output                          acc_trigger_latch_en_o      ,
    output  [256-1:0]               acc_trigger_latch_o         
);


//////////////////////////////////////////////////////////////////////////////////
// *********** Define Parameter Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Register Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
reg                                 acc_flag_d              = 'd0;
reg                                 acc_trigger_latch_en    = 'd0;

reg         [32-1:0]                acc_trigger_time        = 'd0;
reg         [32-1:0]                acc_trigger_time_latch  = 'd0;
reg         [32-1:0]                light_spot_para_latch   = 'd0;
reg         [32-1:0]                detect_width_para_latch = 'd0;
reg         [32-1:0]                acc_trigger_index       = 'd0;
reg         [16-1:0]                laser_data_max          = 'd0;
reg         [16-1:0]                haze_data_max           = 'd0;
reg         [32-1:0]                laser_max_index         = 'd0;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Wire Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
wire                                acc_flag_pose               ;
wire                                acc_flag_nege               ;

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Instance Module
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>


//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Logic Design
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
always @(posedge clk_i) acc_flag_d <= #TCQ acc_flag_i;
assign acc_flag_pose = (~acc_flag_d) && acc_flag_i;
assign acc_flag_nege = acc_flag_d && (~acc_flag_i);

always @(posedge clk_i) begin
    if(acc_flag_i)
        acc_trigger_time <= #TCQ acc_trigger_time + 1;
    else
        acc_trigger_time <= #TCQ 'd0;
end

always @(posedge clk_i) begin
    if(acc_flag_nege)
        acc_trigger_time_latch <= #TCQ acc_trigger_time;
end


always @(posedge clk_i) begin
    if(acc_flag_pose)
        light_spot_para_latch <= #TCQ light_spot_para_i;
end

always @(posedge clk_i) begin
    if(acc_flag_pose)
        detect_width_para_latch <= #TCQ detect_width_para_i;
end

always @(posedge clk_i) begin
    if(pmt_scan_en_i)begin
        if(acc_flag_pose)
            acc_trigger_index <= #TCQ acc_trigger_index + 1;
    end
    else 
        acc_trigger_index <= #TCQ 'd0;
end

always @(posedge clk_i) begin
    if(~acc_flag_d)
        laser_data_max <= #TCQ 'd0;
    else begin
        if(laser_vld_i && (laser_data_i>laser_data_max))
            laser_data_max <= #TCQ laser_data_i;
    end
end

always @(posedge clk_i) begin
    if(~acc_flag_d)
        laser_max_index <= #TCQ 'd0;
    else begin
        if(laser_vld_i && (laser_data_i>laser_data_max))
            laser_max_index <= #TCQ acc_trigger_time;
    end
end

always @(posedge clk_i) begin
    if(~acc_flag_d)
        haze_data_max <= #TCQ 'd0;
    else begin
        if(laser_vld_i && (laser_haze_data_i>haze_data_max))
            haze_data_max <= #TCQ laser_haze_data_i;
    end
end

always @(posedge clk_i) begin
    acc_trigger_latch_en <= #TCQ acc_flag_nege && pmt_scan_en_i;
end

assign acc_trigger_latch_en_o  = acc_trigger_latch_en;
// 
// assign acc_trigger_latch_o     = {
//                                      acc_trigger_index[32-1:0]
//                                     ,light_spot_para_latch[32-1:0]
//                                     ,detect_width_para_latch[32-1:0]
//                                     ,acc_trigger_time_latch[32-1:0]
//                                     ,laser_data_max[16-1:0]
//                                     ,haze_data_max[16-1:0]
//                                     ,laser_max_index[32-1:0]
//                                     ,64'd0
//                                     };
// 适配 readback 模块内的 xpm fifo 256bit -> 32bit 小端输出方式，高4字节在高位读写
assign acc_trigger_latch_o     = {
                                    64'd0
                                    ,laser_max_index[32-1:0]
                                    ,{laser_data_max[16-1:0],haze_data_max[16-1:0]}
                                    ,acc_trigger_time_latch[32-1:0]
                                    ,detect_width_para_latch[32-1:0]
                                    ,light_spot_para_latch[32-1:0]
                                    ,acc_trigger_index[32-1:0]
                                    };
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


endmodule
