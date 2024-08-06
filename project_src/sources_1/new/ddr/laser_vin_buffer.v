`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/06/20
// Design Name: songyuxin
// Module Name: laser_vin_buffer
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


module laser_vin_buffer #(
    parameter                               TCQ               = 0.1 ,
    parameter                               MEM_SEL_BIT       = 1   ,
    parameter                               ADDR_WIDTH        = 30  ,
    parameter                               DATA_WIDTH        = 32  ,
    parameter                               MEM_DATA_BITS     = 256 ,
    parameter                               BURST_LEN         = 128 
)(
    // clk & rst
    input                                   sys_clk_i               ,
    input                                   sys_rst_i               ,
    input                                   ddr_clk_i               ,
    input                                   ddr_rst_i               ,

    input                                   laser_start_i           ,
    input                                   pre_track_vld_i         ,
    input       [32-1:0]                    pre_track_data_i        ,
    input                                   filter_acc_flag_i       ,

    output      [18-1:0]                    wr_burst_line_o         ,
    input       [18-1:0]                    rd_burst_line_i         ,

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
// reg                         laser_pre_vld       = 'd0;

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Wire Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
wire                        laser_pre_almost_full   ;
wire                        laser_pre_full          ;
wire                        laser_pre_empty         ;

wire                        laser_pre_rd_en         ;
wire                        laser_pre_vld           ;
wire    [DATA_WIDTH+32-1:0] laser_pre_dout          ;


//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Instance Module
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
xpm_async_fifo #(
    .ECC_MODE               ( "no_ecc"                      ),
    .FIFO_MEMORY_TYPE       ( "block"                       ),
    .READ_MODE              ( "std"                         ),
    .FIFO_WRITE_DEPTH       ( 512                           ),
    .WRITE_DATA_WIDTH       ( DATA_WIDTH + 32               ),
    .READ_DATA_WIDTH        ( DATA_WIDTH + 32               ),
    .RELATED_CLOCKS         ( 1                             ), // write clk same source of read clk
    .USE_ADV_FEATURES       ( "1800"                        )
)laser_vin_buffer_fifo_inst (
    .wr_clk_i               ( sys_clk_i                     ),
    .rst_i                  ( sys_rst_i                     ), // synchronous to wr_clk
    .wr_en_i                ( pre_track_vld_i               ),
    .wr_data_i              ( {filter_acc_flag_i,31'd0,pre_track_data_i}  ),
    .fifo_full_o            ( laser_pre_full                ),
    
    .rd_clk_i               ( ddr_clk_i                     ),
    .rd_en_i                ( laser_pre_rd_en               ),
    .fifo_rd_vld_o          ( laser_pre_vld                 ),
    .fifo_rd_data_o         ( laser_pre_dout                ),
    .fifo_empty_o           ( laser_pre_empty               )
);

mem_vin_buffer_ctrl #(
    .TCQ                    ( TCQ                           ),
    .MEM_SEL_BIT            ( MEM_SEL_BIT                   ),
    .ADDR_WIDTH             ( ADDR_WIDTH                    ),
    .DATA_WIDTH             ( DATA_WIDTH                    ),
    .MEM_DATA_BITS          ( MEM_DATA_BITS                 ),
    .BURST_LEN              ( BURST_LEN                     )
)mem_vin_buffer_ctrl_inst(
    // clk & rst
    .ddr_clk_i              ( ddr_clk_i                     ),
    .ddr_rst_i              ( ddr_rst_i                     ),

    .laser_data_i           ( laser_pre_dout                ),
    .laser_vld_i            ( laser_pre_vld                 ),
    .laser_start_i          ( laser_start_i                 ),
    .ddr_fifo_full_o        ( ddr_fifo_full                 ),
    .wr_burst_line_o        ( wr_burst_line_o               ),
    .rd_burst_line_i        ( rd_burst_line_i               ),

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
assign laser_pre_rd_en = ~ddr_fifo_full && ~laser_pre_empty;

// always @(posedge ddr_clk_i) begin
//     laser_pre_vld <= #TCQ laser_pre_rd_en;
// end

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


endmodule
