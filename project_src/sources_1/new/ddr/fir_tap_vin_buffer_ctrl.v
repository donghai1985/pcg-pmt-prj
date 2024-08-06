`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: zas
// Engineer: songyuxin
// 
// Create Date: 2024/1/29
// Design Name: 
// Module Name: fir_tap_vin_buffer_ctrl
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


module fir_tap_vin_buffer_ctrl #(
    parameter                               TCQ               = 0.1 ,  
    parameter                               ADDR_WIDTH        = 30  ,
    parameter                               DATA_WIDTH        = 32  ,
    parameter                               MEM_DATA_BITS     = 256 ,
    parameter                               BURST_LEN         = 128
)(
    // clk & rst 
    input                                   ddr_clk_i               ,
    input                                   ddr_rst_i               ,

    input                                   fir_tap_vld_i           ,
    input       [32-1:0]                    fir_tap_data_i          ,
    input                                   fir_tap_wr_cmd_i        ,
    input       [32-1:0]                    fir_tap_wr_addr_i       ,

    output                                  ddr_fifo_full_o         ,
    output                                  ddr_wr_idle_o           ,

    output                                  wr_ddr_req_o            , // 存储器接口：写请求 在写的过程中持续为1  
    output      [ 8-1:0]                    wr_ddr_len_o            , // 存储器接口：写长度
    output      [ADDR_WIDTH-1:0]            wr_ddr_addr_o           , // 存储器接口：写首地址 
     
    input                                   ddr_fifo_rd_req_i       , // 存储器接口：写数据数据读指示 ddr FIFO读使能
    output      [MEM_DATA_BITS - 1:0]       wr_ddr_data_o           , // 存储器接口：写数据
    input                                   wr_ddr_finish_i           // 存储器接口：本次写完成 
);

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Parameter Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
localparam                      BURST_IDLE              = 3'd0;    
localparam                      BURST_FRAME_START       = 3'd1;    
localparam                      BURSTING                = 3'd2;
localparam                      BURST_END               = 3'd3;    
localparam                      BURST_FRAME_END         = 3'd4;    
localparam                      BURST_WAIT              = 3'd5;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Register Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
reg     [ 3-1:0]                burst_state             = BURST_IDLE;
reg     [ 3-1:0]                burst_state_next        = BURST_IDLE;

reg                             fir_tap_wr_cmd_d0       = 'd0;
reg                             fir_tap_wr_cmd_d1       = 'd0;
// reg                             last_burst_state        = 'd0;

reg     [16-1:0]                wr_burst_line           = 'd0;

reg                             wr_ddr_req              = 'd0;  
reg     [ 8-1:0]                wr_ddr_len              = 'd0;  
reg     [ADDR_WIDTH-1:0]        wr_ddr_addr             = 'd0;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Wire Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
wire                            frame_start         ;
wire                            frame_end           ;
wire                            frame_write_done    ;
wire                            fifo_clear_rd       ;

wire                            ddr_fifo_empty      ;
wire                            ddr_fifo_prog_empty ;


//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Instance Module
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
xpm_sync_fifo #(
    .ECC_MODE                   ( "no_ecc"                      ),
    .FIFO_MEMORY_TYPE           ( "block"                       ), // "auto" "block" "distributed"
    .READ_MODE                  ( "fwft"                        ),
    .FIFO_WRITE_DEPTH           ( 1024                          ),
    .PROG_FULL_THRESH           ( 1004                          ),
    .PROG_EMPTY_THRESH          ( BURST_LEN-1                   ),
    .WRITE_DATA_WIDTH           ( DATA_WIDTH                    ),
    .READ_DATA_WIDTH            ( MEM_DATA_BITS                 ),
    .USE_ADV_FEATURES           ( "0A02"                        )
)mem_vin_buffer_fifo_inst (
    .wr_clk_i                   ( ddr_clk_i                     ),
    .rst_i                      ( ddr_rst_i                     ), // synchronous to wr_clk
    .wr_en_i                    ( fir_tap_vld_i                 ),
    .wr_data_i                  ( fir_tap_data_i                ),
    .fifo_prog_full_o           ( ddr_fifo_full_o               ),

    .rd_en_i                    ( ddr_fifo_rd_req_i             ),
    .fifo_rd_data_o             ( wr_ddr_data_o                 ),
    .fifo_almost_empty_o        ( ddr_fifo_empty                ),
    .fifo_prog_empty_o          ( ddr_fifo_prog_empty           )
);
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Logic Design
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
always @(posedge ddr_clk_i) begin
    fir_tap_wr_cmd_d0 <= #TCQ fir_tap_wr_cmd_i;
    fir_tap_wr_cmd_d1 <= #TCQ fir_tap_wr_cmd_d0;
end
assign frame_start =  fir_tap_wr_cmd_d0 && ~fir_tap_wr_cmd_d1;  // posedge, FIFO cache
assign frame_end   = ~fir_tap_wr_cmd_d0 &&  fir_tap_wr_cmd_d1;  // negedge, start burst

// assign frame_write_done = last_burst_state;
assign fifo_clear_rd    = (burst_state == BURST_IDLE) && (~ddr_fifo_empty);

always@(posedge ddr_clk_i)
begin
    if(ddr_rst_i)
        burst_state <= #TCQ BURST_IDLE;
    else
        burst_state <= #TCQ burst_state_next;
end

always@(*)begin
    burst_state_next = burst_state;
    case(burst_state)
    
        BURST_IDLE:
                            if(frame_start)
                                burst_state_next = BURST_WAIT;

        BURST_WAIT:
                            if(~ddr_fifo_prog_empty)  
                                burst_state_next = BURST_FRAME_START;
                                        
        BURST_FRAME_START:
                            burst_state_next = BURSTING;
                                    
        BURSTING:
                            if(wr_ddr_finish_i) // 外部输入信号
                                burst_state_next = BURST_FRAME_END;
                                
        // BURST_END:
        //                     /*写操作完成时判断最后一次突发是否已经完全写入ddr，如果完成则进入空闲状态，等待下次突发*/
        //                     if(frame_write_done)
        //                         burst_state_next = BURST_FRAME_END;
        //                     else if(~ddr_fifo_prog_empty)
        //                         burst_state_next = BURSTING;
                                
        BURST_FRAME_END:
                            burst_state_next = BURST_IDLE;
                            
        default:
                            burst_state_next = BURST_IDLE;
    endcase
end

always@(posedge ddr_clk_i)begin
    wr_ddr_addr <= #TCQ {2'd0,2'd1,3'd0,wr_burst_line[15:0],7'd0};  // 通过burst line控制突发首地址
end

always @(posedge ddr_clk_i) begin
    if(burst_state_next == BURST_FRAME_START)begin
        wr_burst_line <= #TCQ fir_tap_wr_addr_i[15:0];
    end
    // else if(burst_state_next==BURST_END && burst_state==BURSTING)begin
    //     wr_burst_line <= #TCQ wr_burst_line + 1;
    // end
end

// always @(posedge ddr_clk_i) begin
//     if(frame_end)begin
//         last_burst_state <= #TCQ 'd1;
//     end
//     else if(burst_state==BURST_FRAME_END)begin
//         last_burst_state <= #TCQ 'd0;
//     end
// end

always@(posedge ddr_clk_i)begin
    if(burst_state_next == BURSTING && burst_state != BURSTING)begin
        wr_ddr_len <= #TCQ BURST_LEN;
    end
end

always@(posedge ddr_clk_i)begin
    if(burst_state_next == BURSTING && burst_state != BURSTING)
        wr_ddr_req <= #TCQ 1'b1;
    else if(wr_ddr_finish_i  || ddr_fifo_rd_req_i || burst_state == BURST_IDLE) // ddr 仲裁响应后拉低
        wr_ddr_req <= #TCQ 1'b0;
end

assign wr_burst_line_o          = wr_burst_line  ;
assign wr_ddr_req_o             = wr_ddr_req  ;
assign wr_ddr_len_o             = wr_ddr_len  ;
assign wr_ddr_addr_o            = wr_ddr_addr ;
assign ddr_wr_idle_o            = burst_state == BURST_IDLE;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


endmodule
