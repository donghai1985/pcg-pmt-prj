`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: zas
// Engineer: songyuxin
// 
// Create Date: 2024/3/3
// Design Name: PCG
// Module Name: pre_particle_filter
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


module pre_particle_filter #(
    parameter                       TCQ               = 0.1 ,
    parameter                       DATA_WIDTH        = 32  
)(
    // clk & rst 
    input                           clk_i                   ,
    input                           rst_i                   ,

    input                           pre_laser_vld_i         ,
    input   [DATA_WIDTH+32-1:0]     pre_laser_data_i        ,

    input   [16-1:0]                pre_filter_thre_i       ,
    input   [16-1:0]                lp_pre_filter_thre_i    ,

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

reg                                 pre_acc_flag        = 'd0;
reg         [16-1:0]                pre_haze_data       = 'd0;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Wire Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
wire        [16-1:0]                laser_pre_data      ;
wire                                laser_fifo_vld      ;
wire        [16-1:0]                laser_fifo_data     ;
wire                                laser_fifo_almost_empty;

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Instance Module
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
xpm_sync_fifo #(
    .ECC_MODE                       ( "no_ecc"                      ),
    .FIFO_MEMORY_TYPE               ( "block"                       ),
    .READ_MODE                      ( "std"                         ),
    .FIFO_WRITE_DEPTH               ( 128                           ),
    .WRITE_DATA_WIDTH               ( 32                            ),
    .READ_DATA_WIDTH                ( 16                            ),
    .USE_ADV_FEATURES               ( "1800"                        )
)actu_laser_sync_fifo_inst (
    .wr_clk_i                       ( clk_i                         ),
    .rst_i                          ( rst_i                         ), // synchronous to wr_clk
    .wr_en_i                        ( pre_laser_vld_i               ),
    .wr_data_i                      ( pre_laser_data_i[32-1:0]      ),

    .rd_en_i                        ( ~laser_fifo_almost_empty      ),
    .fifo_rd_vld_o                  ( laser_fifo_vld                ),
    .fifo_rd_data_o                 ( laser_fifo_data               ),
    .fifo_almost_empty_o            ( laser_fifo_almost_empty       )
);

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Logic Design
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
always @(posedge clk_i) begin
    if(pre_laser_vld_i)begin
        pre_acc_flag  <= #TCQ pre_laser_data_i[63];
        pre_haze_data <= #TCQ pre_laser_data_i[47:32];
    end
end

assign laser_pre_data = laser_fifo_data - pre_haze_data;

always @(posedge clk_i) begin
    if(laser_fifo_vld)begin
        if(pre_acc_flag)
            filter_result <= #TCQ (laser_pre_data > lp_pre_filter_thre_i);
        else 
            filter_result <= #TCQ (laser_pre_data > pre_filter_thre_i);
    end
end

always @(posedge clk_i) begin
    filter_vld      <= #TCQ laser_fifo_vld;
    filter_data     <= #TCQ laser_fifo_data;
    filter_haze_hub <= #TCQ laser_pre_data;
end

assign pre_filter_vld_o     = filter_vld;
assign pre_filter_data_o    = filter_data;
assign pre_filter_haze_hub_o= filter_haze_hub;
assign pre_filter_result_o  = filter_result;

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


endmodule
