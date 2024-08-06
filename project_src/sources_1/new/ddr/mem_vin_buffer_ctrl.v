`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/06/20
// Design Name: songyuxin
// Module Name: mem_vin_buffer_ctrl
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


module mem_vin_buffer_ctrl #(
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

    input       [DATA_WIDTH+32-1:0]         laser_data_i            ,
    input                                   laser_vld_i             ,
    input                                   laser_start_i           ,
    output                                  ddr_fifo_full_o         ,
    output      [18-1:0]                    wr_burst_line_o         ,
    input       [18-1:0]                    rd_burst_line_i         ,

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

reg                             laser_start_d0          = 'd0;
reg                             laser_start_d1          = 'd0;
reg                             last_burst_state        = 'd0;

reg     [6-1:0]                 fifo_clear_cnt          = 'd0;

reg                             mem_virtual_full        = 'd0;
reg     [18-1:0]                wr_burst_line           = 'd0;

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
wire                            fifo_reset          ;

wire                            ddr_fifo_empty      ;
wire                            ddr_fifo_prog_empty ;
wire                            fifo_clear_done     ;


//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Instance Module
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
xpm_sync_fifo #(
    .ECC_MODE                   ( "no_ecc"                      ),
    .FIFO_MEMORY_TYPE           ( "block"                       ),
    .READ_MODE                  ( "fwft"                        ),
    .FIFO_WRITE_DEPTH           ( 4096                          ),
    .PROG_FULL_THRESH           ( 4076                          ),
    .PROG_EMPTY_THRESH          ( BURST_LEN+1                   ),
    .WRITE_DATA_WIDTH           ( DATA_WIDTH+32                 ),
    .READ_DATA_WIDTH            ( MEM_DATA_BITS                 ),
    .USE_ADV_FEATURES           ( "0F0F"                        )
)mem_vin_buffer_fifo_inst (
    .wr_clk_i                   ( ddr_clk_i                     ),
    .rst_i                      ( ddr_rst_i || fifo_reset       ), // synchronous to wr_clk
    .wr_en_i                    ( laser_vld_i                   ),
    .wr_data_i                  ( laser_data_i                  ),
    .fifo_prog_full_o           ( ddr_fifo_full_o               ),

    .rd_en_i                    ( ddr_fifo_rd_req_i             ),
    .fifo_rd_data_o             ( wr_ddr_data_o                 ),
    .fifo_empty_o               ( ddr_fifo_empty                ),
    .fifo_prog_empty_o          ( ddr_fifo_prog_empty           )
);
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Logic Design
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
always @(posedge ddr_clk_i) begin
    laser_start_d0 <= #TCQ laser_start_i;
    laser_start_d1 <= #TCQ laser_start_d0;
end
assign frame_start =  laser_start_d0 && ~laser_start_d1;  // posedge, fsm statr
assign frame_end   = ~laser_start_d0 &&  laser_start_d1;  // negedge, fsm end

assign frame_write_done = last_burst_state;
// assign fifo_clear_rd    = (burst_state == BURST_IDLE) && (~ddr_fifo_empty);
assign fifo_reset = burst_state == BURST_FRAME_END;

always @(posedge ddr_clk_i) begin
    if(ddr_rst_i || frame_end)
        mem_virtual_full <= #TCQ 'd0;
    else if(mem_virtual_full && wr_burst_line != rd_burst_line_i)
        mem_virtual_full <= #TCQ 'd0;
    else if(~mem_virtual_full && ((wr_burst_line+1'd1)==rd_burst_line_i) && wr_ddr_finish_i)
        mem_virtual_full <= #TCQ 'd1;
end

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
                            /*如果FIFO有足够的数据则完成一次突发操作*/
                            if(~ddr_fifo_prog_empty)  
                                burst_state_next = BURST_FRAME_START;
                                        
        BURST_FRAME_START:
                            /*一次写操作开始*/
                            burst_state_next = BURSTING;
                                    
        BURSTING:
                            /*写DDR操作*/
                            if(wr_ddr_finish_i) //外部输入信号
                                burst_state_next = BURST_END;
                                
        BURST_END:
                            /*写操作完成时判断最后一次突发是否已经完全写入ddr，如果完成则进入空闲状态，等待下次突发*/
                            if(frame_write_done)begin
                                if(ddr_fifo_empty)
                                    burst_state_next = BURST_FRAME_END;
                                else
                                    burst_state_next = BURSTING;
                            end
                            else if(~ddr_fifo_prog_empty)
                                burst_state_next = BURSTING;
                                
        BURST_FRAME_END:
                            if(fifo_clear_done)
                                burst_state_next = BURST_IDLE;
                            
        default:
                            burst_state_next = BURST_IDLE;
    endcase
end

always @(posedge ddr_clk_i) begin
    if(burst_state==BURST_FRAME_END)
        fifo_clear_cnt <= #TCQ fifo_clear_cnt + 1;
    else 
        fifo_clear_cnt <= #TCQ 'd0;
end
assign fifo_clear_done = (&fifo_clear_cnt);

always@(posedge ddr_clk_i)begin
    wr_ddr_addr <= #TCQ {2'd0,MEM_SEL_BIT[0],wr_burst_line[17:0],9'd0};  // 通过burst line控制突发首地址
end

always @(posedge ddr_clk_i) begin
    if(burst_state_next == BURST_FRAME_START)begin
        wr_burst_line <= #TCQ 'd0;
    end
    else if(burst_state_next==BURST_END && burst_state==BURSTING)begin
        wr_burst_line <= #TCQ wr_burst_line + 1;
    end
end

always @(posedge ddr_clk_i) begin
    if(frame_end)begin
        last_burst_state <= #TCQ 'd1;
    end
    else if(burst_state==BURST_FRAME_END)begin
        last_burst_state <= #TCQ 'd0;
    end
end

always@(posedge ddr_clk_i)begin
    if(burst_state_next == BURSTING && burst_state != BURSTING)begin
        // if(last_burst_state)
        //     wr_ddr_len <= #TCQ last_burst_num;
        // else
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
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


endmodule
