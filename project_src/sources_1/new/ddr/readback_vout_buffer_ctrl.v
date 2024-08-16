`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: zas
// Engineer: songyuxin
// 
// Create Date: 2024/01/29
// Design Name: 
// Module Name: fir_tap_vout_buffer_ctrl
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


module readback_vout_buffer_ctrl #(
    parameter                               TCQ               = 0.1 ,  
    parameter                               ADDR_WIDTH        = 30  ,
    parameter                               DATA_WIDTH        = 32  ,
    parameter                               MEM_DATA_BITS     = 256 ,
    parameter                               BURST_LEN         = 128
)(
    // clk & rst 
    input                                   ddr_clk_i               ,
    input                                   ddr_rst_i               ,

    input                                   burst_flag_i            ,
    input       [32-1:0]                    burst_line_i            ,

    output                                  ddr_fifo_empty_o        ,
    output                                  ddr_fifo_almost_empty_o ,
    input                                   ddr_fifo_rd_en_i        ,
    output                                  ddr_fifo_rd_vld_o       ,
    output      [DATA_WIDTH-1:0]            ddr_fifo_rd_data_o      ,

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
localparam                      BURST_IDLE              = 3'd0;
localparam                      BURST_WAIT              = 3'd1;
localparam                      BURSTING                = 3'd2;
localparam                      BURST_END               = 3'd3;
localparam                      BURST_FRAME_END         = 3'd4;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Register Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
reg     [ 3-1:0]                burst_state             = BURST_IDLE;
reg     [ 3-1:0]                burst_state_next        = BURST_IDLE;

reg                             burst_flag_latch        = 'd0;
reg     [22-1:0]                burst_line              = 'd0;

reg                             rd_ddr_req              = 'd0;  
reg     [ 8-1:0]                rd_ddr_len              = 'd0;  
reg     [ADDR_WIDTH-1:0]        rd_ddr_addr             = 'd0;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Wire Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
wire                            ddr_fifo_full       ;
wire                            ddr_fifo_prog_full  ;


wire                            frame_reset         ;

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Instance Module
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
xpm_sync_fifo #(
    .ECC_MODE                   ( "no_ecc"                      ),
    .FIFO_MEMORY_TYPE           ( "block"                       ),
    .READ_MODE                  ( "std"                         ),
    .FIFO_WRITE_DEPTH           ( 256                           ),
    .PROG_FULL_THRESH           ( 128                           ),
    .WRITE_DATA_WIDTH           ( MEM_DATA_BITS                 ),
    .READ_DATA_WIDTH            ( DATA_WIDTH                    ),
    .USE_ADV_FEATURES           ( "1C06"                        )
)mem_vout_buffer_fifo_inst (
    .wr_clk_i                   ( ddr_clk_i                     ),
    .rst_i                      ( ddr_rst_i                     ), // synchronous to wr_clk
    .wr_en_i                    ( rd_ddr_data_valid_i           ),
    .wr_data_i                  ( rd_ddr_data_i                 ),
    .fifo_full_o                ( ddr_fifo_full                 ),
    .fifo_prog_full_o           ( ddr_fifo_prog_full            ),

    .rd_en_i                    ( ddr_fifo_rd_en_i              ),
    .fifo_rd_vld_o              ( ddr_fifo_rd_vld_o             ),
    .fifo_rd_data_o             ( ddr_fifo_rd_data_o            ),
    .fifo_empty_o               ( ddr_fifo_empty_o              ),
    .fifo_almost_empty_o        ( ddr_fifo_almost_empty_o       )
);

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Logic Design
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
// always @(posedge ddr_clk_i)begin
//     if(burst_flag_i)
//         burst_flag_latch <= #TCQ 'd1;
//     else if(burst_state==BURST_FRAME_END)
//         burst_flag_latch <= #TCQ 'd0;
// end 

always @(posedge ddr_clk_i) begin
    if(burst_flag_i && (burst_state==BURST_IDLE))begin
        burst_line      <= #TCQ burst_line_i[22-1:0];
    end
end

always@(posedge ddr_clk_i)begin
    if(ddr_rst_i)
        burst_state <= #TCQ BURST_IDLE;
    else
        burst_state <= #TCQ burst_state_next;
end

always@(*)begin
    burst_state_next = burst_state;
    case(burst_state)
        BURST_IDLE:
            if(burst_flag_i)
                burst_state_next = BURST_WAIT;
        BURST_WAIT:
            if(~ddr_fifo_prog_full)
                burst_state_next = BURSTING;
        BURSTING:
            if(rd_ddr_finish_i)
                burst_state_next = BURST_FRAME_END;
        // BURST_END:
        //     if(pre_laser_done)
        //         burst_state_next = BURST_FRAME_END;
        //     else if((~ddr_fifo_prog_full) && (~mem_virtual_empty)) // 判断fifo空间
        //         burst_state_next = BURSTING;
        BURST_FRAME_END:
                burst_state_next = BURST_IDLE;
        default:
            burst_state_next = BURST_IDLE;
    endcase
end

always@(posedge ddr_clk_i)begin
    rd_ddr_addr <= #TCQ {burst_line[21:0],8'd0};  // 通过burst line控制突发首地址
end

always@(posedge ddr_clk_i)begin
    if(burst_state_next == BURSTING && burst_state != BURSTING)begin
        rd_ddr_len <= #TCQ BURST_LEN;
    end
end

always@(posedge ddr_clk_i)begin
    if(burst_state_next == BURSTING && burst_state != BURSTING)
        rd_ddr_req <= #TCQ 1'b1;
    else if(rd_ddr_finish_i || rd_ddr_data_valid_i || burst_state == BURST_FRAME_END)
        rd_ddr_req <= #TCQ 1'b0;
end

assign rd_ddr_req_o             = rd_ddr_req  ;
assign rd_ddr_len_o             = rd_ddr_len  ;
assign rd_ddr_addr_o            = rd_ddr_addr ;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


endmodule
