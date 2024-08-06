`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: zas
// Engineer: songyuxin
// 
// Create Date: 2024/01/29
// Design Name: 
// Module Name: readback_vout_buffer
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


module readback_vout_buffer #(
    parameter                               TCQ               = 0.1 ,  
    parameter                               ADDR_WIDTH        = 30  ,
    parameter                               DATA_WIDTH        = 32  ,
    parameter                               MEM_DATA_BITS     = 256 ,
    parameter                               BURST_LEN         = 128
)(
    // clk & rst 
    input                                   ddr_clk_i               ,
    input                                   ddr_rst_i               ,
    input                                   sys_clk_i               ,

    // readback ddr
    input       [32-1:0]                    ddr_rd_addr_i           ,
    input                                   ddr_rd_en_i             ,
    output                                  readback_vld_o          ,
    output                                  readback_last_o         ,
    output      [32-1:0]                    readback_data_o         ,

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
reg                                 ddr_fifo_rd_en          = 'd0;

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Wire Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
wire                                ddr_fifo_almost_empty   ;
wire                                readback_almost_full    ;
wire                                readback_prog_full      ;
wire                                readback_full           ;
wire                                readback_empty          ;

wire                                ddr_fifo_rd_vld         ;
wire    [DATA_WIDTH-1:0]            ddr_fifo_rd_data        ;

wire                                burst_flag              ;
wire    [32-1:0]                    burst_line              ;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Instance Module
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
xpm_async_fifo #(
    .ECC_MODE                       ( "no_ecc"                      ),
    .FIFO_MEMORY_TYPE               ( "distributed"                 ), // "auto" "block" "distributed"
    .READ_MODE                      ( "std"                         ),
    .FIFO_WRITE_DEPTH               ( 16                            ),
    .WRITE_DATA_WIDTH               ( DATA_WIDTH                    ),
    .PROG_FULL_THRESH               ( 16-8                          ),
    .READ_DATA_WIDTH                ( DATA_WIDTH                    ),
    .RELATED_CLOCKS                 ( 1                             ), // write clk same source of read clk
    .USE_ADV_FEATURES               ( "1002"                        )
)laser_vout_buffer_fifo_inst ( 
    .wr_clk_i                       ( ddr_clk_i                     ),
    .rst_i                          ( ddr_rst_i                     ), // synchronous to wr_clk
    .wr_en_i                        ( ddr_fifo_rd_vld               ),
    .wr_data_i                      ( ddr_fifo_rd_data              ),
    .fifo_prog_full_o               ( readback_prog_full            ),

    .rd_clk_i                       ( sys_clk_i                     ),
    .rd_en_i                        ( ~readback_empty               ),
    .fifo_rd_vld_o                  ( readback_vld_o                ),
    .fifo_rd_data_o                 ( readback_data_o               ),
    .fifo_empty_o                   ( readback_empty                )
);

handshake #(
    .DATA_WIDTH                     ( 32                            )
)handshake_burst_line_inst(
    // clk & rst
    .src_clk_i                      ( sys_clk_i                     ),
    .src_rst_i                      ( 'd0                           ),
    .dest_clk_i                     ( ddr_clk_i                     ),
    .dest_rst_i                     ( ddr_rst_i                     ),
    
    .src_data_i                     ( ddr_rd_addr_i                 ),
    .src_vld_i                      ( ddr_rd_en_i                   ),
    .dest_data_o                    ( burst_line                    ),
    .dest_vld_o                     ( burst_flag                    )
);

readback_vout_buffer_ctrl #(
    .ADDR_WIDTH                     ( ADDR_WIDTH                    ),
    .DATA_WIDTH                     ( DATA_WIDTH                    ),
    .MEM_DATA_BITS                  ( MEM_DATA_BITS                 ),
    .BURST_LEN                      ( BURST_LEN                     )
)mem_vout_buffer_ctrl_inst(
    // clk & rst 
    .ddr_clk_i                      ( ddr_clk_i                     ),
    .ddr_rst_i                      ( ddr_rst_i                     ),

    .burst_flag_i                   ( burst_flag                    ),
    .burst_line_i                   ( burst_line                    ),

    .ddr_fifo_almost_empty_o        ( ddr_fifo_almost_empty         ),
    .ddr_fifo_rd_en_i               ( ddr_fifo_rd_en                ),
    .ddr_fifo_rd_vld_o              ( ddr_fifo_rd_vld               ),
    .ddr_fifo_rd_data_o             ( ddr_fifo_rd_data              ),

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
always @(posedge ddr_clk_i) ddr_fifo_rd_en   <= #TCQ ~ddr_fifo_almost_empty && ~readback_prog_full;

reg [8-1:0] readback_burst_cnt = 'd0;
always @(posedge sys_clk_i) begin
    if(readback_last_o)
        readback_burst_cnt <= #TCQ 'd0;
    else if(readback_vld_o)
        readback_burst_cnt <= #TCQ readback_burst_cnt + 1;
end

assign readback_last_o = (readback_burst_cnt == 'd255) && readback_vld_o;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


endmodule
