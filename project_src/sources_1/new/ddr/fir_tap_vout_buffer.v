`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: zas
// Engineer: songyuxin
// 
// Create Date: 2024/01/29
// Design Name: 
// Module Name: fir_tap_vout_buffer
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


module fir_tap_vout_buffer #(
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

    input                                   track_para_en_i         ,
    input                                   laser_start_i           ,
    input                                   encode_zero_flag_i      ,
    input                                   fir_tap_rd_en_i         ,
    output                                  track_burst_end_o       ,
    output                                  fir_tap_ready_o         ,
    output                                  fir_tap_rd_vld_o        ,
    output      [32-1:0]                    fir_tap_rd_data_o       ,
    output      [16-1:0]                    fir_tap_burst_line_o    ,

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

reg                                 fir_tap_burst_flag      = 'd0;
reg     [16-1:0]                    fir_tap_burst_line      = 'd0;
reg                                 read_clear              = 'd0;
reg     [9-1:0]                     read_clear_cnt          = 'd0;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Wire Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
wire                                ddr_fifo_almost_empty   ;
wire                                fir_tap_almost_full     ;
wire                                fir_tap_prog_full       ;
wire                                fir_tap_full            ;
wire                                fir_tap_empty           ;
wire                                ddr_fifo_rd_vld         ;
wire    [DATA_WIDTH-1:0]            ddr_fifo_rd_data        ;

wire                                burst_flag              ;
wire    [16-1:0]                    burst_line              ;
wire                                burst_end               ;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Instance Module
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
xpm_async_fifo #(
    .ECC_MODE                       ( "no_ecc"                      ),
    .FIFO_MEMORY_TYPE               ( "distributed"                 ), // "auto" "block" "distributed"
    .READ_MODE                      ( "std"                         ),
    .FIFO_WRITE_DEPTH               ( 64                            ),
    .WRITE_DATA_WIDTH               ( DATA_WIDTH                    ),
    .PROG_FULL_THRESH               ( 64-8                          ),
    .READ_DATA_WIDTH                ( DATA_WIDTH                    ),
    .RELATED_CLOCKS                 ( 1                             ), // write clk same source of read clk
    .USE_ADV_FEATURES               ( "1002"                        )
)laser_vout_buffer_fifo_inst ( 
    .wr_clk_i                       ( ddr_clk_i                     ),
    .rst_i                          ( ddr_rst_i                     ), // synchronous to wr_clk
    .wr_en_i                        ( ddr_fifo_rd_vld               ),
    .wr_data_i                      ( ddr_fifo_rd_data              ),
    // .fifo_full_o                    ( fir_tap_full                  ),
    // .fifo_almost_full_o             ( fir_tap_almost_full           ),
    .fifo_prog_full_o               ( fir_tap_prog_full             ),

    .rd_clk_i                       ( sys_clk_i                     ),
    .rd_en_i                        ( fir_tap_rd_en_i || read_clear ),
    .fifo_rd_vld_o                  ( fir_tap_rd_vld_o              ),
    .fifo_rd_data_o                 ( fir_tap_rd_data_o             ),
    .fifo_empty_o                   ( fir_tap_empty                 )
);

handshake #(
    .DATA_WIDTH                     ( 16                            )
)handshake_burst_line_inst(
    // clk & rst
    .src_clk_i                      ( sys_clk_i                     ),
    .src_rst_i                      ( 'd0                           ),
    .dest_clk_i                     ( ddr_clk_i                     ),
    .dest_rst_i                     ( ddr_rst_i                     ),
    
    .src_data_i                     ( fir_tap_burst_line            ),
    .src_vld_i                      ( fir_tap_burst_flag            ),
    .dest_data_o                    ( burst_line                    ),
    .dest_vld_o                     ( burst_flag                    )
);

xpm_cdc_pulse #(
    .DEST_SYNC_FF(2),   // DECIMAL; range: 2-10
    .INIT_SYNC_FF(0),   // DECIMAL; 0=disable simulation init values, 1=enable simulation init values
    .REG_OUTPUT(1),     // DECIMAL; 0=disable registered output, 1=enable registered output
    .RST_USED(0),       // DECIMAL; 0=no reset, 1=implement reset
    .SIM_ASSERT_CHK(0)  // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
 )
 xpm_cdc_pulse_inst (
    .dest_pulse(track_burst_end_o), // 1-bit output: Outputs a pulse the size of one dest_clk period when a pulse
                             // transfer is correctly initiated on src_pulse input. This output is
                             // combinatorial unless REG_OUTPUT is set to 1.

    .dest_clk(sys_clk_i),     // 1-bit input: Destination clock.
    .dest_rst(0),     // 1-bit input: optional; required when RST_USED = 1
    .src_clk(ddr_clk_i),       // 1-bit input: Source clock.
    .src_pulse(burst_end),   // 1-bit input: Rising edge of this signal initiates a pulse transfer to the
                             // destination clock domain. The minimum gap between each pulse transfer must be
                             // at the minimum 2*(larger(src_clk period, dest_clk period)). This is measured
                             // between the falling edge of a src_pulse to the rising edge of the next
                             // src_pulse. This minimum gap will guarantee that each rising edge of src_pulse
                             // will generate a pulse the size of one dest_clk period in the destination
                             // clock domain. When RST_USED = 1, pulse transfers will not be guaranteed while
                             // src_rst and/or dest_rst are asserted.

    .src_rst(0)        // 1-bit input: optional; required when RST_USED = 1
 );

fir_tap_vout_buffer_ctrl #(
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
    .burst_end_o                    ( burst_end                     ),

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
always @(posedge ddr_clk_i) ddr_fifo_rd_en   <= #TCQ ~ddr_fifo_almost_empty && ~fir_tap_prog_full;

reg laser_start_d = 'd0;
reg track_para_en_d = 'd0;
always @(posedge sys_clk_i) begin
    laser_start_d   <= #TCQ laser_start_i;
    track_para_en_d <= #TCQ track_para_en_i;
end

always @(posedge sys_clk_i) begin
    if(track_para_en_i && ((~track_para_en_d) || (~laser_start_d && laser_start_i) || (encode_zero_flag_i)))
        fir_tap_burst_flag <= #TCQ 'd1;
    else
        fir_tap_burst_flag <= #TCQ 'd0;
end

always @(posedge sys_clk_i) begin
    if(~track_para_en_d)
        fir_tap_burst_line <= #TCQ 'd0;
    else if(fir_tap_burst_flag)
        fir_tap_burst_line <= #TCQ fir_tap_burst_line + 1;
end

// always @(posedge sys_clk_i) begin
//     if(read_clear)
//         read_clear_cnt <= #TCQ read_clear_cnt + 1;
//     else
//         read_clear_cnt <= #TCQ 'd0;
// end

always @(posedge sys_clk_i) begin
    if(laser_start_d && (~laser_start_i))
        read_clear <= #TCQ 'd1;
    else if(track_para_en_d && (~track_para_en_i))
        read_clear <= #TCQ 'd0;
end

assign fir_tap_ready_o = (~fir_tap_empty);
assign fir_tap_burst_line_o = fir_tap_burst_line;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


endmodule
