`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: songyuxin
// 
// Create Date: 2023/06/25
// Design Name: PCG
// Module Name: laser_out_aurora
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


module laser_out_aurora #(
    parameter                       TCQ               = 0.1 ,
    parameter                       DATA_WIDTH        = 32  
)(
    // clk & rst 
    input                           clk_i                   ,
    input                           rst_i                   ,
    input                           aurora_log_clk_i        ,

    input                           acc_defect_en_i         ,
    input   [16-1:0]                acc_defect_thre_i       ,
    input                           laser_start_i           ,
    input                           motor_zero_flag_i       ,
    input                           laser_vld_i             ,
    input   [2*DATA_WIDTH-1:0]      laser_data_i            ,  // low 32bit is laser actual data, high 32bit is pre laser data.

    input                           aurora_txen_i           ,
    output  [DATA_WIDTH-1:0]        aurora_txdata_o         ,
    output                          aurora_tx_emp_o         ,
    output  [11-1:0]                aurora_rd_data_count_o  
);

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Parameter Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>




//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Register Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
reg                             motor_first_cyc         = 'd0;
reg                             laser_out_vld           = 'd0;
reg     [DATA_WIDTH-1:0]        laser_out_data          = 'd0;

reg                             laser_single_actual_rd  = 'd0;
reg                             laser_single_actual_vld = 'd0;
reg                             laser_single_pre_rd     = 'd0;
reg                             laser_single_pre_vld    = 'd0;



//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Wire Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
wire                            laser_actual_vld    = laser_vld_i;
wire    [DATA_WIDTH-1:0]        laser_actual_data   = laser_data_i[32-1:0];
wire                            laser_pre_vld       = laser_vld_i;
wire    [DATA_WIDTH-1:0]        laser_pre_data      = laser_data_i[64-1:32];

wire                            laser_actual_full           ;
wire                            laser_actual_empty          ;
wire                            laser_pre_full              ;
wire                            laser_pre_empty             ;
wire    [16-1:0]                laser_single_actual_data    ;
wire    [16-1:0]                laser_single_pre_data       ;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Instance Module
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
ddr3_to_aurora_fifo ddr3_to_aurora_fifo_inst(
    .rst                    ( rst_i                     ),
    .wr_clk                 ( clk_i                     ),
    .rd_clk                 ( aurora_log_clk_i          ),
    .din                    ( laser_out_data            ),
    .wr_en                  ( laser_out_vld             ),
    .rd_en                  ( aurora_txen_i             ),
    .dout                   ( aurora_txdata_o           ),
    .full                   (                           ),
    .empty                  ( aurora_tx_emp_o           ),
    .rd_data_count          ( aurora_rd_data_count_o    ),
    .wr_rst_busy            ( wr_rst_busy               ),
    .rd_rst_busy            ( rd_rst_busy               )
);

laser_recover_fifo laser_actual_recover_fifo(
    .clk                    ( clk_i                     ),
    .srst                   ( rst_i                     ),
    .din                    ( laser_actual_data         ),
    .wr_en                  ( laser_actual_vld          ),
    .rd_en                  ( laser_single_actual_rd    ),
    .dout                   ( laser_single_actual_data  ),
    .full                   ( laser_actual_full         ),
    .empty                  ( laser_actual_empty        )
);

laser_recover_fifo laser_pre_recover_fifo(
    .clk                    ( clk_i                     ),
    .srst                   ( rst_i                     ),
    .din                    ( laser_pre_data            ),
    .wr_en                  ( laser_pre_vld             ),
    .rd_en                  ( laser_single_pre_rd       ),
    .dout                   ( laser_single_pre_data     ),
    .full                   ( laser_pre_full            ),
    .empty                  ( laser_pre_empty           )
);
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Logic Design
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
always @(posedge clk_i) laser_single_actual_rd  <= #TCQ ~laser_actual_empty; 
always @(posedge clk_i) laser_single_actual_vld <= #TCQ laser_single_actual_rd; // laser_single_actual_data
always @(posedge clk_i) laser_single_pre_rd     <= #TCQ ~laser_pre_empty;    
always @(posedge clk_i) laser_single_pre_vld    <= #TCQ laser_single_pre_rd;    // laser_single_pre_data 

reg laser_start_d = 'd0;
always @(posedge clk_i) laser_start_d <= #TCQ laser_start_i;
always @(posedge clk_i) begin
    if(rst_i)
        motor_first_cyc <= #TCQ 'd0;
    else if(laser_start_i && ~laser_start_d)
        motor_first_cyc <= #TCQ 'd1;
    else if(motor_zero_flag_i)
        motor_first_cyc <= #TCQ 'd0;
end

always @(posedge clk_i) begin
    if(rst_i)begin
        laser_out_vld  <= #TCQ 'd0;
    end
    if(motor_first_cyc)begin
        laser_out_vld  <= #TCQ laser_single_actual_vld;
        laser_out_data <= #TCQ {16'h55aa,laser_single_actual_data};
    end
    else begin
        laser_out_vld  <= #TCQ laser_single_actual_vld;
        laser_out_data <= #TCQ {16'haa55,laser_single_actual_data};
    end
end
// compute particle detect result
/* >>>>>>>>>>>>>>>>>>>>>>>>>>>>


计算激光数据的flag，可流水
wafer第一圈不参与运算，ACC默认为0
组合数据格式为：

bit[31:0]
31 , 30  , 29:28   , 27:24 , 23:20 , 15:0 \r
tb , ACC , Reserve , AFS   , GAIN  , laser_single_data \r





<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< */
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


endmodule
