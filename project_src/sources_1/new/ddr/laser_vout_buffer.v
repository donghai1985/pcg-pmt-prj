`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/06/26
// Design Name: songyuxin
// Module Name: laser_vout_buffer
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


module laser_vout_buffer #(
    parameter                               TCQ               = 0.1 ,  
    parameter                               MEM_SEL_BIT       = 1   ,
    parameter                               ADDR_WIDTH        = 30  ,
    parameter                               DATA_WIDTH        = 32  ,
    parameter                               MEM_DATA_BITS     = 256 ,
    parameter                               BURST_LEN         = 128
)(
    // clk & rst 
    input                                   ddr_clk_i               ,
    input                                   ddr_rst_i               ,
    input                                   sys_clk_i               ,

    input                                   laser_start_i           ,
    input       [18-1:0]                    wr_burst_line_i         ,
    output      [18-1:0]                    rd_burst_line_o         ,
    output                                  laser_fifo_ready_o      ,
    input                                   pre_laser_rd_seq_i      ,
    output                                  pre_laser_rd_vld_o      ,
    output      [64-1:0]                    pre_laser_rd_data_o     ,

    output                                  rd_ddr_req_o            ,  
    output      [ 8-1:0]                    rd_ddr_len_o            ,
    output      [ADDR_WIDTH-1:0]            rd_ddr_addr_o           ,
    input                                   rd_ddr_data_valid_i     ,
    input       [MEM_DATA_BITS - 1:0]       rd_ddr_data_i           ,
    input                                   rd_ddr_finish_i          
    
);

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Parameter Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Register Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
reg                                 pre_laser_flag          = 'd0;
reg                                 ddr_fifo_rd_en          = 'd0;
// reg                                 laser_fifo_wr_en        = 'd0;
// reg                                 frame_header_d0         = 'd0;
// reg                                 frame_header_d1         = 'd0;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Wire Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
// wire                                frame_flag              ;
wire                                ddr_fifo_empty          ;
wire                                laser_fifo_almost_full  ;
wire                                laser_fifo_prog_full    ;
wire                                laser_fifo_full         ;
wire                                laser_fifo_empty        ;
wire                                ddr_fifo_rd_vld         ;
wire    [DATA_WIDTH+32-1:0]         ddr_fifo_rd_data        ;

wire                                ddr_fifo_clear          ;
wire                                ddr_fifo_clear_d        ;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Instance Module
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
xpm_async_fifo #(
    .ECC_MODE                       ( "no_ecc"                      ),
    .FIFO_MEMORY_TYPE               ( "block"                       ), // "auto" "block" "distributed"
    .READ_MODE                      ( "std"                         ),
    .FIFO_WRITE_DEPTH               ( 128                           ),
    .WRITE_DATA_WIDTH               ( DATA_WIDTH+32                 ),
    .PROG_FULL_THRESH               ( 128-8                         ),
    .READ_DATA_WIDTH                ( DATA_WIDTH+32                 ),
    .RELATED_CLOCKS                 ( 1                             ), // write clk same source of read clk
    .USE_ADV_FEATURES               ( "1002"                        )
)laser_vout_buffer_fifo_inst ( 
    .wr_clk_i                       ( ddr_clk_i                     ),
    .rst_i                          ( ddr_rst_i || ddr_fifo_clear_d ), // synchronous to wr_clk
    .wr_en_i                        ( ddr_fifo_rd_vld               ),
    .wr_data_i                      ( ddr_fifo_rd_data              ),
    .fifo_full_o                    ( laser_fifo_full               ),
    .fifo_prog_full_o               ( laser_fifo_prog_full          ),

    .rd_clk_i                       ( sys_clk_i                     ),
    .rd_en_i                        ( pre_laser_rd_seq_i            ),
    .fifo_rd_vld_o                  ( pre_laser_rd_vld_o            ),
    .fifo_rd_data_o                 ( pre_laser_rd_data_o           ),
    .fifo_empty_o                   ( laser_fifo_empty              )
);

reg_delay #(
    .DATA_WIDTH                     ( 1                             ),
    .DELAY_NUM                      ( 4                             )
)reg_delay_inst(
    .clk_i                          ( ddr_clk_i                     ),
    .src_data_i                     ( ddr_fifo_clear                ),
    .delay_data_o                   ( ddr_fifo_clear_d              )
);

mem_vout_buffer_ctrl #(
    .MEM_SEL_BIT                    ( MEM_SEL_BIT                   ),
    .ADDR_WIDTH                     ( ADDR_WIDTH                    ),
    .DATA_WIDTH                     ( DATA_WIDTH                    ),
    .MEM_DATA_BITS                  ( MEM_DATA_BITS                 ),
    .BURST_LEN                      ( BURST_LEN                     )
)mem_vout_buffer_ctrl_inst(
    // clk & rst 
    .ddr_clk_i                      ( ddr_clk_i                     ),
    .ddr_rst_i                      ( ddr_rst_i                     ),

    .laser_start_i                  ( laser_start_i                 ),
    .wr_burst_line_i                ( wr_burst_line_i               ),
    .rd_burst_line_o                ( rd_burst_line_o               ),
    .ddr_fifo_empty_o               ( ddr_fifo_empty                ),
    .ddr_fifo_rd_en_i               ( ddr_fifo_rd_en                ),
    .ddr_fifo_rd_vld_o              ( ddr_fifo_rd_vld               ),
    .ddr_fifo_rd_data_o             ( ddr_fifo_rd_data              ),
    .ddr_fifo_clear_o               ( ddr_fifo_clear                ),

    .rd_ddr_req_o                   ( rd_ddr_req_o                  ),  
    .rd_ddr_len_o                   ( rd_ddr_len_o                  ),
    .rd_ddr_addr_o                  ( rd_ddr_addr_o                 ),
    .rd_ddr_data_valid_i            ( rd_ddr_data_valid_i           ),
    .rd_ddr_data_i                  ( rd_ddr_data_i                 ),
    .rd_ddr_finish_i                ( rd_ddr_finish_i               ) 
);
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


//////////////////////////////////////////////////////////////////////////////////
// *********** Logic Design
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

always @(posedge ddr_clk_i) ddr_fifo_rd_en   <= #TCQ ~ddr_fifo_empty && ~laser_fifo_prog_full;

// always @(posedge sys_clk_i) begin
//     if(laser_start_i)begin
//         if(motor_zero_flag_i)
//             pre_laser_flag <= #TCQ 'd1;
//     end
//     else 
//         pre_laser_flag <= #TCQ 'd0;
// end

assign laser_fifo_ready_o = (~laser_fifo_empty);
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


endmodule
