`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: zas
// Engineer: songyuxin
// 
// Create Date: 2024/1/29
// Design Name: 
// Module Name: fir_tap_vin_buffer
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


module fir_tap_vin_buffer #(
    parameter                               TCQ               = 0.1 ,
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

    input                                   fir_tap_wr_cmd_i        ,
    input                                   fir_tap_wr_vld_i        ,
    input       [32-1:0]                    fir_tap_wr_data_i       ,

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
localparam                          TRACK_PARA_LINE     = 128;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Register Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
// reg                         fir_tap_vld       = 'd0;
reg                                 fir_tap_wr_cmd      = 'd0; 
reg     [32-1:0]                    fir_tap_wr_addr     = 'd0;
reg                                 fir_tap_wr_vld      = 'd0;
reg     [32-1:0]                    fir_tap_wr_data     = 'd0;
reg     [7-1:0]                     track_para_line_cnt = 'd0;
reg                                 ddr_wr_idle_d0      = 'd0;
reg                                 ddr_wr_idle_d1      = 'd0;

reg                                 track_addr_wr       = 'd0; 
reg     [32-1:0]                    track_addr_din      = 'd0;
reg                                 track_addr_rd_state = 'd0;

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Wire Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
wire                                fir_tap_almost_full     ;
wire                                fir_tap_full            ;
wire                                fir_tap_empty           ;

wire                                fir_tap_rd_en           ;
wire                                fir_tap_vld             ;
wire    [DATA_WIDTH-1:0]            fir_tap_dout            ;

wire                                ddr_wr_idle             ;
wire                                track_addr_rd           ; 
wire                                track_addr_vld          ;
wire    [32-1:0]                    track_addr_dout         ;
wire                                track_addr_empty        ;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Instance Module
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
xpm_async_fifo #(
    .ECC_MODE               ( "no_ecc"                      ),
    .FIFO_MEMORY_TYPE       ( "distributed"                 ), // "auto" "block" "distributed"
    .READ_MODE              ( "std"                         ),
    .FIFO_WRITE_DEPTH       ( 32                            ),
    .WRITE_DATA_WIDTH       ( DATA_WIDTH                    ),
    .READ_DATA_WIDTH        ( DATA_WIDTH                    ),
    .RELATED_CLOCKS         ( 1                             ), // write clk same source of read clk
    .USE_ADV_FEATURES       ( "1800"                        )
)fir_tap_buffer_fifo_inst (
    .wr_clk_i               ( sys_clk_i                     ),
    .rst_i                  ( sys_rst_i                     ), // synchronous to wr_clk
    .wr_en_i                ( fir_tap_wr_vld                ),
    .wr_data_i              ( fir_tap_wr_data               ),
    .fifo_full_o            ( fir_tap_full                  ),
    
    .rd_clk_i               ( ddr_clk_i                     ),
    .rd_en_i                ( fir_tap_rd_en                 ),
    .fifo_rd_vld_o          ( fir_tap_vld                   ),
    .fifo_rd_data_o         ( fir_tap_dout                  ),
    .fifo_empty_o           ( fir_tap_empty                 )
);

xpm_sync_fifo #(
    .ECC_MODE               ( "no_ecc"                      ),
    .FIFO_MEMORY_TYPE       ( "distributed"                 ), // "auto" "block" "distributed"
    .READ_MODE              ( "std"                         ),
    .FIFO_WRITE_DEPTH       ( 16                            ),
    .WRITE_DATA_WIDTH       ( 32                            ),
    .READ_DATA_WIDTH        ( 32                            ),
    .USE_ADV_FEATURES       ( "1000"                        )
)track_para_addr_fifo_inst (
    .wr_clk_i               ( sys_clk_i                     ),
    .rst_i                  ( sys_rst_i                     ), // synchronous to wr_clk
    .wr_en_i                ( track_addr_wr                 ),
    .wr_data_i              ( track_addr_din                ),

    .rd_en_i                ( track_addr_rd                 ),
    .fifo_rd_vld_o          ( track_addr_vld                ),
    .fifo_rd_data_o         ( track_addr_dout               ),
    .fifo_empty_o           ( track_addr_empty              )
);

fir_tap_vin_buffer_ctrl #(
    .TCQ                    ( TCQ                           ),  
    .ADDR_WIDTH             ( ADDR_WIDTH                    ),
    .DATA_WIDTH             ( DATA_WIDTH                    ),
    .MEM_DATA_BITS          ( MEM_DATA_BITS                 ),
    .BURST_LEN              ( BURST_LEN                     )
)mem_vin_buffer_ctrl_inst(
    // clk & rst
    .ddr_clk_i              ( ddr_clk_i                     ),
    .ddr_rst_i              ( ddr_rst_i                     ),

    .fir_tap_vld_i          ( fir_tap_vld                   ),
    .fir_tap_data_i         ( fir_tap_dout                  ),
    .fir_tap_wr_cmd_i       ( fir_tap_wr_cmd                ),
    .fir_tap_wr_addr_i      ( fir_tap_wr_addr               ),

    .ddr_fifo_full_o        ( ddr_fifo_full                 ),
    .ddr_wr_idle_o          ( ddr_wr_idle                   ),

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
assign fir_tap_rd_en = ~ddr_fifo_full && ~fir_tap_empty;

always @(posedge sys_clk_i) begin
    if(sys_rst_i || (~fir_tap_wr_cmd_i))
        track_para_line_cnt <= #TCQ 'd0;
    else if(fir_tap_wr_vld_i)
        track_para_line_cnt <= #TCQ track_para_line_cnt + 1;
end

always @(posedge sys_clk_i) begin
    fir_tap_wr_vld  <= #TCQ fir_tap_wr_vld_i;
    fir_tap_wr_data <= #TCQ fir_tap_wr_data_i;
end

always @(posedge sys_clk_i) begin
    track_addr_wr  <= #TCQ fir_tap_wr_vld_i && (track_para_line_cnt == 'd0);
    track_addr_din <= #TCQ fir_tap_wr_data_i;
end

always @(posedge sys_clk_i) begin
    ddr_wr_idle_d0 <= #TCQ ddr_wr_idle;
    ddr_wr_idle_d1 <= #TCQ ddr_wr_idle_d0;
end

always @(posedge sys_clk_i) begin
    if(sys_rst_i)
        fir_tap_wr_cmd <= #TCQ 'd0;
    else if((~fir_tap_wr_cmd) && (track_addr_vld))
        fir_tap_wr_cmd <= #TCQ 'd1;
    else if(~ddr_wr_idle_d1 && ddr_wr_idle_d0)
        fir_tap_wr_cmd <= #TCQ 'd0;
end

always @(posedge sys_clk_i) begin
    if(track_addr_vld)
        fir_tap_wr_addr <= #TCQ track_addr_dout;
end


always @(posedge sys_clk_i) begin
    if(sys_rst_i)
        track_addr_rd_state <= #TCQ 'd0;
    else if(track_addr_rd)
        track_addr_rd_state <= #TCQ 'd1;
    else if(~ddr_wr_idle_d1 && ddr_wr_idle_d0)
        track_addr_rd_state <= #TCQ 'd0;
end

assign track_addr_rd = (~track_addr_rd_state) && (~track_addr_empty);
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


endmodule
