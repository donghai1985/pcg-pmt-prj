`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: zas
// Engineer: songyuxin
// 
// Create Date: 2023/08/25
// Design Name: PCG
// Module Name: FBC_vin_ctrl
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


module acc_dump_vin_ctrl #(
    parameter                               TCQ               = 0.1 ,
    parameter                               ADDR_WIDTH        = 30  ,
    parameter                               DATA_WIDTH        = 32  ,
    parameter                               MEM_DATA_BITS     = 256 ,
    parameter                               BURST_LEN         = 128 
)(
    // clk & rst
    input                                   clk_i                   ,
    input                                   rst_i                   ,
    input                                   ddr_clk_i               ,
    input                                   ddr_rst_i               ,

    input                                   pmt_scan_en_i           ,
    input                                   acc_trigger_latch_en_i  ,
    input       [256-1:0]                   acc_trigger_latch_i     ,

    output                                  wr_ddr_req_o            ,
    output      [ 8-1:0]                    wr_ddr_len_o            ,
    output      [ADDR_WIDTH-1:0]            wr_ddr_addr_o           ,
    input                                   ddr_fifo_rd_req_i       ,
    output      [MEM_DATA_BITS - 1:0]       wr_ddr_data_o           ,
    input                                   wr_ddr_finish_i          
);

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Parameter Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Register Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>


//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Wire Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
wire                        acc_trigger_full            ;
wire                        acc_trigger_empty           ;
wire                        ddr_fifo_almost_full        ;

wire                        acc_trigger_rd_en           ;
wire                        acc_trigger_vld             ;
wire    [256-1:0]           acc_trigger_dout            ;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Instance Module
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

FBC_vin_buffer_fifo acc_dump_vin_fifo_inst (
    .rst                    ( rst_i                         ),  // input wire rst
    .wr_clk                 ( clk_i                         ),  // input wire wr_clk
    .rd_clk                 ( ddr_clk_i                     ),  // input wire rd_clk
    .din                    ( acc_trigger_latch_i           ),  // input wire [255 : 0] din
    .wr_en                  ( acc_trigger_latch_en_i        ),  // input wire wr_en
    .rd_en                  ( acc_trigger_rd_en             ),  // input wire rd_en
    .dout                   ( acc_trigger_dout              ),  // output wire [255 : 0] dout
    .full                   ( acc_trigger_full              ),  // output wire full
    .empty                  ( acc_trigger_empty             ),  // output wire empty
    .valid                  ( acc_trigger_vld               )   // output wire valid
);

acc_dump_vin_buffer_ctrl #(
    .TCQ                    ( TCQ                           ),  
    .ADDR_WIDTH             ( ADDR_WIDTH                    ),
    .DATA_WIDTH             ( DATA_WIDTH                    ),
    .MEM_DATA_BITS          ( MEM_DATA_BITS                 ),
    .BURST_LEN              ( BURST_LEN                     )
)acc_dump_vin_buffer_ctrl_inst(
    // clk & rst
    .ddr_clk_i              ( ddr_clk_i                     ),
    .ddr_rst_i              ( ddr_rst_i                     ),

    .laser_start_i          ( pmt_scan_en_i                 ),
    .laser_vld_i            ( acc_trigger_vld               ),
    .laser_data_i           ( acc_trigger_dout              ),

    .wr_ddr_req_o           ( wr_ddr_req_o                  ), // 存储器接口：写请求 在写的过程中持续为1  
    .wr_ddr_len_o           ( wr_ddr_len_o                  ), // 存储器接口：写长度
    .wr_ddr_addr_o          ( wr_ddr_addr_o                 ), // 存储器接口：写首地址 
     
    .ddr_fifo_rd_req_i      ( ddr_fifo_rd_req_i             ), // 存储器接口：写数据数据读指示 ddr FIFO读使能
    .wr_ddr_data_o          ( wr_ddr_data_o                 ), // 存储器接口：写数据
    .wr_ddr_finish_i        ( wr_ddr_finish_i               )  // 存储器接口：本次写完成 
);
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


//////////////////////////////////////////////////////////////////////////////////
// *********** Logic Design
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

assign acc_trigger_rd_en = ~acc_trigger_empty;


//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


endmodule
