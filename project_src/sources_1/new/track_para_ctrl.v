`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: zas
// Engineer: songyuxin
// 
// Create Date: 2024/5/10
// Design Name: PCG
// Module Name: track_para_ctrl
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
module track_para_ctrl #(
    parameter                                   TCQ                 = 0.1   ,
    parameter                                   PARA_DDR_ADDR       = 1     ,
    parameter                                   DS_PARA_NUM         = 2     ,
    parameter                                   LIGHT_SPOT_PARA_NUM = 1     ,
    parameter                                   TRACK_ALIGN_PARA    = 1     ,
    parameter                                   LOWPASS_PARA_NUM    = 1     ,
    parameter                                   FIR_TAP_NUM         = 51    
)(
    input                                       clk_i                   ,
    input                                       rst_i                   ,

    input                                       track_para_en_i         ,
    input                                       laser_start_i           ,
    input                                       laser_zero_flag_i       ,
    
    input                                       track_para_burst_end_i  ,
    input                                       track_para_vld_i        ,
    input       [32-1:0]                        track_para_data_i       ,
    output                                      track_para_ren_o        ,
    output                                      delay_zero_flag_o       ,
    
    output                                      ds_para_en_o            ,
    output      [32-1:0]                        ds_para_h_o             ,
    output      [32-1:0]                        ds_para_l_o             ,
    output      [16-1:0]                        light_spot_para_o       ,
    output      [16-1:0]                        detect_width_para_o     ,
    output                                      lowpass_para_vld_o      ,
    output      [32-1:0]                        lowpass_para_data_o     ,
    output                                      fir_post_para_en_o      ,
    output      [16-1:0]                        circle_lose_num_o       ,
    output      [16-1:0]                        track_align_num_o       ,

    output                                      fir_tap_vld_o           ,
    output      [10-1:0]                        fir_tap_addr_o          ,
    output      [32-1:0]                        fir_tap_data_o          
);
//////////////////////////////////////////////////////////////////////////////////
// *********** Define Parameter Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
localparam                          PARAMETER_NUM               = PARA_DDR_ADDR + DS_PARA_NUM + LIGHT_SPOT_PARA_NUM + TRACK_ALIGN_PARA + LOWPASS_PARA_NUM + FIR_TAP_NUM;

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Register Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
reg                                 track_para_en_d             = 'd0;
reg                                 fir_tap_vld                 = 'd0;
reg     [10-1:0]                    fir_tap_addr                = 'd0;
reg     [32-1:0]                    fir_tap_data                = 'd0;

reg                                 track_para_ren              = 'd0;
reg     [8-1:0]                     track_para_rcnt             = 'd0;
reg                                 track_para_update           = 'd0;

reg                                 ds_para_en                  = 'd0;
reg     [32-1:0]                    ds_para_h                   = 'd0;
reg     [32-1:0]                    ds_para_l                   = 'd0;

reg     [16-1:0]                    detect_width_para           = 'd0;
reg     [16-1:0]                    light_spot_para             = 'd0;
reg                                 lowpass_para_vld            = 'd0;
reg     [32-1:0]                    lowpass_para_data           = 'd0;
reg                                 fir_post_para_en            = 'd0;
reg     [16-1:0]                    circle_lose_num             = 'd0;
reg     [16-1:0]                    track_align_num             = 'd0;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Wire Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
wire                                track_para_en   ;

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Instance Module
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>


//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Logic Design
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
assign track_para_en = (track_para_burst_end_i && (~laser_start_i) && track_para_en_i) || laser_zero_flag_i;

always @(posedge clk_i) begin
    if(track_para_en)
        track_para_ren <= #TCQ'd1;
    else if(track_para_rcnt == 'd126)  // DDR BURST LEN = 16, 16*256 = 128*32
        track_para_ren <= #TCQ 'd0;
end

always @(posedge clk_i) begin
    if(~track_para_ren)
        track_para_rcnt <= #TCQ 'd0;
    else if(track_para_vld_i)
        track_para_rcnt <= #TCQ track_para_rcnt + 1;
end

always @(posedge clk_i) begin
    if(track_para_en)
        track_para_update <= #TCQ 'd1;
    else if((track_para_rcnt == PARAMETER_NUM) && track_para_vld_i && track_para_update)
        track_para_update <= #TCQ 'd0;
end

// down sample parameter
always @(posedge clk_i) begin
    if(track_para_update && track_para_vld_i && (track_para_rcnt=='d1))
        ds_para_h <= #TCQ track_para_data_i;
end

always @(posedge clk_i) begin
    if(track_para_update && track_para_vld_i && (track_para_rcnt=='d2))
        ds_para_l <= #TCQ track_para_data_i;
end

always @(posedge clk_i) begin
    ds_para_en <= #TCQ track_para_update && track_para_vld_i && (track_para_rcnt=='d2);
end

// light parameter
always @(posedge clk_i) begin
    if(track_para_update && track_para_vld_i && (track_para_rcnt == PARA_DDR_ADDR +  DS_PARA_NUM))begin
        light_spot_para   <= #TCQ track_para_data_i[31:16];
        detect_width_para <= #TCQ track_para_data_i[15:0];
    end
end

// track align parameter
always @(posedge clk_i) begin
    if(track_para_update && track_para_vld_i && (track_para_rcnt == PARA_DDR_ADDR +  DS_PARA_NUM + LIGHT_SPOT_PARA_NUM))begin
        fir_post_para_en <= #TCQ 'd1;
        circle_lose_num <= #TCQ track_para_data_i[31:16];
        track_align_num <= #TCQ track_para_data_i[15:0];
    end
    else 
        fir_post_para_en <= #TCQ 'd0;
end

// lowpass parameter
always @(posedge clk_i) begin
    if(track_para_update && track_para_vld_i && (track_para_rcnt == PARA_DDR_ADDR +  DS_PARA_NUM + LIGHT_SPOT_PARA_NUM + TRACK_ALIGN_PARA))begin
        lowpass_para_vld    <= #TCQ 'd1;
        lowpass_para_data   <= #TCQ track_para_data_i;
    end
    else begin
        lowpass_para_vld    <= #TCQ 'd0;
    end
end

// fir filter parameter
always @(posedge clk_i) begin
    if(track_para_update && track_para_vld_i && (track_para_rcnt >= ( PARA_DDR_ADDR + DS_PARA_NUM + LIGHT_SPOT_PARA_NUM + TRACK_ALIGN_PARA + LOWPASS_PARA_NUM)))begin
        fir_tap_vld     <= #TCQ 'd1;
        fir_tap_data    <= #TCQ track_para_data_i;
    end
    else begin
        fir_tap_vld     <= #TCQ 'd0;
    end
end

always @(posedge clk_i) begin
    if(~track_para_update)
        fir_tap_addr <= #TCQ 'd0;
    else if(fir_tap_vld)
        fir_tap_addr <= #TCQ fir_tap_addr + 1;
end

reg track_para_ren_d = 'd0;
always @(posedge clk_i) begin
    track_para_ren_d <= #TCQ track_para_ren;
end
assign track_para_ren_o     = track_para_ren;
assign delay_zero_flag_o    = track_para_ren_d && (~track_para_ren) && laser_start_i;

assign fir_tap_vld_o        = fir_tap_vld ; 
assign fir_tap_addr_o       = fir_tap_addr;
assign fir_tap_data_o       = fir_tap_data;

assign ds_para_en_o         = ds_para_en;
assign ds_para_h_o          = ds_para_h ;
assign ds_para_l_o          = ds_para_l ;

assign lowpass_para_vld_o   = lowpass_para_vld; 
assign lowpass_para_data_o  = lowpass_para_data; 
assign light_spot_para_o    = light_spot_para;
assign detect_width_para_o  = detect_width_para;
assign fir_post_para_en_o   = fir_post_para_en;
assign circle_lose_num_o    = circle_lose_num;
assign track_align_num_o    = track_align_num;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    
endmodule