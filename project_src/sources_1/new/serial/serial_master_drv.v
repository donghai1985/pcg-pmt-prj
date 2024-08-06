`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: zas
// Engineer: songyuxin
// 
// Create Date: 2023/7/06
// Design Name: PCG
// Module Name: serial_master_drv
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
//
//  byte 0~1 : 控制地址addr
//  byte 2 : PMT板选择，兼容同时控制，使用bit位独立选通，bit[0]=1表示选择PMT1，bit[1]=1选择PMT2，bit[2]=1选择PMT3。
//  byte 3 : 控制命令cmd，低8位有效，bit[7]:命令类型，0表示读寄存器，1表示写寄存器；bit[4:0]:数据长度n-1。
//  byte 4~n*4-1 : 写入数据data，四字节对齐，数据对齐间为小端模式，数据对齐内为大端模式。
//  举例：addr[15:0]=0x4000、cmd[7:0]=0b0000_0001、data[63:0]=0x01234567 89ABCDEF，
//  表示依次在地址0x4003~0x4000写入0x01234567、地址0x4007~0x4004写入0x89ABCDEF共8个字节的数据。
//
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module serial_master_drv #(
    parameter                               TCQ         = 0.1   ,
    parameter                               DATA_WIDTH  = 32    ,
    parameter                               ADDR_WIDTH  = 16    ,
    parameter                               CMD_WIDTH   = 8     ,
    parameter                               MASTER_SEL  = 1     ,
    parameter                               SERIAL_MODE = 1     
)(
    // clk & rst
    input    wire                           clk_i               ,
    input    wire                           rst_i               ,
    input    wire                           clk_200m_i          ,
    input    wire   [DATA_WIDTH-1:0]        master_wr_data_i    ,
    input    wire   [1:0]                   master_wr_vld_i     ,
    // output   wire                           pmt_start_en_o      ,
    // output   wire                           pmt_start_test_en_o ,
    output   wire                           pmt_master_cmd_parser_o,

    // output   wire                           rd_ack_timeout_rst_o,
    output   wire                           slave_ack_vld_o     ,
    output   wire                           slave_ack_last_o    ,
    output   wire   [DATA_WIDTH-1:0]        slave_ack_data_o    ,
    // spi info
//     input    wire                           PMT_SPI_SENABLE     , // slave in-place
//     output   wire                           PMT_SPI_MENABLE     , // master in-place
    output   wire                           SPI_MCLK            ,
    output   wire   [SERIAL_MODE-1:0]       SPI_MOSI            ,
    input    wire                           SPI_SCLK            ,
    input    wire   [SERIAL_MODE-1:0]       SPI_MISO            
);


//////////////////////////////////////////////////////////////////////////////////
// *********** Define Parameter Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
localparam                          TX_TIMEOUT_COUNT = 'd4999;   // 5000 * 10ns = 50us


//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Register Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
reg     [16-1:0]                timeout_cnt         = 'd0;
reg     [DATA_WIDTH-1:0]        master_wr_din       = 'd0;
reg                             master_wr_en        = 'd0;
reg                             tx_data_num_en      = 'd0;
reg     [6-1:0]                 tx_data_num         = 'd0;

reg                             command_parser      = 'd0;
reg     [CMD_WIDTH-1:0]         command_cnt         = 'd0;

reg                             pmt_start_en        = 'd0;
reg                             pmt_start_test_en   = 'd0;
reg                             pmt_start_check     = 'd0;

reg                             rx_valid_d          = 'd0;
reg     [DATA_WIDTH-1:0]        rx_data_d           = 'd0;
// reg                             slave_ack_vld       = 'd0;
// reg                             slave_ack_last      = 'd0;
// reg     [DATA_WIDTH-1:0]        slave_ack_data      = 'd0;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Wire Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
wire                            comm_timeout_rst    ;
wire                            tx_cmd_vld          ;
wire                            tx_ack              ;

wire                            rx_valid            ;
wire    [DATA_WIDTH-1:0]        rx_data             ; 
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Instance Module
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
serial_tx_v2 #(
    .DATA_WIDTH                 ( DATA_WIDTH                        ),
    .SERIAL_MODE                ( SERIAL_MODE                       )  // =1\2\4\8
)serial_tx_inst(
    // clk & rst
    .clk_i                      ( clk_i                             ),
    .rst_i                      ( rst_i || comm_timeout_rst         ),
    .clk_200m_i                 ( clk_200m_i                        ),

    .tx_data_num_en_i           ( tx_data_num_en                    ),
    .tx_data_num_i              ( tx_data_num                       ),
    .tx_valid_i                 ( master_wr_en && command_parser    ),
    .tx_data_i                  ( master_wr_din                     ),
    .tx_ack_o                   ( tx_ack                            ),

    // .TX_ENABLE                  ( PMT_SPI_MENABLE                   ),
    .TX_CLK                     ( SPI_MCLK                          ),
    .TX_DOUT                    ( SPI_MOSI                          )
);

serial_rx_v2 #(
    .DATA_WIDTH                 ( DATA_WIDTH                        ),
    .SERIAL_MODE                ( SERIAL_MODE                       )  // =1\2\4\8
)serial_rx_inst(
    // clk & rst
    .clk_i                      ( clk_i                             ),
    .rst_i                      ( rst_i || comm_timeout_rst         ),
    .clk_200m_i                 ( clk_200m_i                        ),
    .rx_valid_o                 ( rx_valid                          ),
    .rx_data_o                  ( rx_data                           ),

    // .RX_ENABLE                  ( PMT_SPI_SENABLE                   ),
    .RX_CLK                     ( SPI_SCLK                          ),
    .RX_DIN                     ( SPI_MISO                          )
);
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Logic Design
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
always @(posedge clk_i) master_wr_en  <= #TCQ master_wr_vld_i[1];
always @(posedge clk_i) master_wr_din <= #TCQ master_wr_data_i;

assign tx_cmd_vld = ~command_parser && (master_wr_vld_i=='b11) && master_wr_data_i[8+MASTER_SEL];

always @(posedge clk_i) begin
    if(rst_i || comm_timeout_rst)begin
        command_parser <= #TCQ 'd0; 
    end
    else if(tx_cmd_vld)begin
        command_parser  <= #TCQ 'd1;
    end
    else if(command_parser && tx_ack)begin
        command_parser <= #TCQ 'd0; 
    end
end

always @(posedge clk_i) begin
    if(tx_cmd_vld && (~master_wr_data_i[7]))begin
        tx_data_num_en  <= #TCQ 'd1;
        tx_data_num     <= #TCQ master_wr_data_i[4:0] + 1;
    end
    else if(tx_cmd_vld && master_wr_data_i[7])begin
        tx_data_num_en  <= #TCQ 'd1;
        tx_data_num     <= #TCQ 'd0;
    end
    else begin
        tx_data_num_en  <= #TCQ 'd0;
    end
end

// 
// rx, read back pack transmission
// 
always @(posedge clk_i) rx_valid_d  <= #TCQ rx_valid;
always @(posedge clk_i) rx_data_d   <= #TCQ rx_data;

// command timeout check
always @(posedge clk_i) begin
    if(~command_parser)begin
        timeout_cnt <= #TCQ 'd0;
    end
    else if(timeout_cnt == TX_TIMEOUT_COUNT)begin
        timeout_cnt <= #TCQ timeout_cnt;
    end
    else begin
        timeout_cnt <= #TCQ timeout_cnt + 1;
    end
end

// // >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> check pmt start signal
// always @(posedge clk_i) begin
//     if(tx_cmd_vld && (~master_wr_data_i[7]))
//         command_cnt <= #TCQ {CMD_WIDTH{1'd1}};
//     else if(command_parser && master_wr_en)
//         command_cnt <= #TCQ command_cnt + 1;
// end

// always @(posedge clk_i) begin
//     if(tx_cmd_vld && (~master_wr_data_i[7]))begin  // valid write cmd
//         if(master_wr_data_i[31:16] == 'h000c)
//             pmt_start_check <= #TCQ 'd1;
//     end
//     else if(~command_parser)begin
//         pmt_start_check <= #TCQ 'd0;
//     end
// end

// always @(posedge clk_i) begin
//     if(pmt_start_check && master_wr_en && command_cnt=='d0)begin
//         pmt_start_en        <= #TCQ master_wr_din[0];
//         pmt_start_test_en   <= #TCQ master_wr_din[1];
//     end
// end
// // <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
assign comm_timeout_rst = (timeout_cnt == TX_TIMEOUT_COUNT);


// assign pmt_start_en_o           = pmt_start_en;
// assign pmt_start_test_en_o      = pmt_start_test_en;

assign slave_ack_vld_o          = rx_valid_d;
assign slave_ack_last_o         = ~rx_valid && rx_valid_d;
assign slave_ack_data_o         = rx_data_d;
assign pmt_master_cmd_parser_o  = command_parser;


//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


endmodule
