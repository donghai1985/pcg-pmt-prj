`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: zas
// Engineer: songyuxin
// 
// Create Date: 2023/12/27
// Design Name: PCG
// Module Name: pre_laser_align_v2
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


module pre_laser_align_v2 #(
    parameter                       TCQ               = 0.1 ,
    parameter                       DATA_WIDTH        = 32  
)(
    // clk & rst 
    input                           clk_i                       ,
    input                           rst_i                       ,
    
    input   [16-1:0]                light_spot_spacing_i        ,
    input                           laser_start_i               ,
    input                           encode_zero_flag_i          ,
    input                           laser_delay_vld_i           ,
    input                           laser_acc_flag_i            ,
    input                           laser_vld_i                 ,
    input   [DATA_WIDTH-1:0]        laser_data_i                ,
    output                          second_track_en_o           ,

    input                           pre_laser_rd_ready_i        ,
    output                          pre_laser_rd_seq_o          ,
    input                           pre_laser_rd_vld_i          ,
    input   [64-1:0]                pre_laser_rd_data_i         ,

    output                          pre_laser_vld_o             ,
    output  [64-1:0]                pre_laser_data_o            ,
    output                          actu_laser_delay_vld_o      ,
    output                          laser_acc_flag_o            ,
    output                          actu_laser_vld_o            ,
    output  [DATA_WIDTH-1:0]        actu_laser_data_o           
);

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Register Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
reg                                 pre_laser_flag          = 'd0;

reg         [16-1:0]                first_cache_cnt         = 'd0;

reg                                 pre_laser_rd_seq        = 'd0;
reg                                 pre_laser_rd_seq_vld    = 'd0;
reg                                 pre_laser_rd_vld        = 'd0;

reg                                 laser_acc_flag_d0       = 'd0;
reg                                 laser_acc_flag_d1       = 'd0;
reg                                 actu_laser_delay_vld_d0 = 'd0;
reg                                 actu_laser_delay_vld_d1 = 'd0;
reg                                 actu_laser_vld_d0       = 'd0;
reg         [DATA_WIDTH-1:0]        actu_laser_data_d0      = 'd0;
reg                                 actu_laser_vld_d1       = 'd0;
reg         [DATA_WIDTH-1:0]        actu_laser_data_d1      = 'd0;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Wire Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
wire                                pre_facula_rd       ;

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Logic Design
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
// assign pre_facula_rd        = laser_start_i && (~pre_laser_flag) && (first_cache_cnt < light_spot_spacing_i);
assign pre_facula_rd        = 'd0;

always @(posedge clk_i) begin
    if(laser_start_i)begin
        if(encode_zero_flag_i)
            pre_laser_flag <= #TCQ 'd1;
    end
    else 
        pre_laser_flag <= #TCQ 'd0;
end

// read pre track in advance, one facula data 
always @(posedge clk_i) begin
    if(~laser_start_i)
        first_cache_cnt <= #TCQ 'd0;
    else if(pre_laser_rd_ready_i && pre_facula_rd && laser_vld_i)
        first_cache_cnt <= #TCQ first_cache_cnt + 1;
end

always @(posedge clk_i) begin
    if(~pre_laser_flag)begin
        if(pre_laser_rd_ready_i && pre_facula_rd && laser_vld_i)
            pre_laser_rd_seq <= #TCQ 'd1;
        else 
            pre_laser_rd_seq <= #TCQ 'd0;
    end
    else 
        pre_laser_rd_seq <= #TCQ laser_vld_i;
end

// always @(posedge clk_i) begin
//     if(pre_laser_flag && laser_vld_i)
//         pre_laser_rd_seq_vld <= #TCQ 'd1;
//     else 
//         pre_laser_rd_seq_vld <= #TCQ 'd0;
// end

// always @(posedge clk_i) begin
//     pre_laser_rd_vld <= #TCQ pre_laser_rd_seq_vld;
// end

always @(posedge clk_i) begin
    actu_laser_delay_vld_d0 <= #TCQ laser_delay_vld_i;
    actu_laser_delay_vld_d1 <= #TCQ actu_laser_delay_vld_d0;

    laser_acc_flag_d0   <= #TCQ laser_acc_flag_i;
    laser_acc_flag_d1   <= #TCQ laser_acc_flag_d0;

    actu_laser_vld_d0  <= #TCQ laser_vld_i ;
    actu_laser_vld_d1  <= #TCQ actu_laser_vld_d0 ;

    actu_laser_data_d0 <= #TCQ laser_data_i;
    actu_laser_data_d1 <= #TCQ actu_laser_data_d0;
end

assign pre_laser_rd_seq_o    = pre_laser_rd_seq;
assign pre_laser_vld_o       = pre_laser_rd_vld_i;
assign pre_laser_data_o      = pre_laser_rd_data_i;
assign actu_laser_delay_vld_o= actu_laser_delay_vld_d1;
assign laser_acc_flag_o      = laser_acc_flag_d1;
assign actu_laser_vld_o      = actu_laser_vld_d1;
assign actu_laser_data_o     = actu_laser_data_d1;
assign second_track_en_o     = pre_laser_flag;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


endmodule
