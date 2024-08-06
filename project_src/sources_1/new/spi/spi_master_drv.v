`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: zas
// Engineer: songyuxin
// 
// Create Date: 2023/06/13
// Design Name: PCG
// Module Name: spi_master_drv
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
//
//  byte 0~1 : 控制地址addr
//  byte 2 : PMT板选择
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


module spi_master_drv #(
    parameter                               TCQ         = 0.1   ,
    parameter                               PMT_SEL     = 0     ,
    parameter                               DUMMY_NUM   = 8     ,
    parameter                               DATA_WIDTH  = 32    ,
    parameter                               ADDR_WIDTH  = 16    ,
    parameter                               CMD_WIDTH   = 8     ,
    parameter                               SPI_MODE    = 2     
)(
    // clk & rst
    input    wire                           clk_i               ,
    input    wire                           rst_i               ,
    input    wire   [DATA_WIDTH-1:0]        master_wr_data_i    ,
    input    wire                           master_wr_vld_i     ,

    output   wire                           slave_ack_vld_o     ,
    output   wire                           slave_ack_last_o    ,
    output   wire   [DATA_WIDTH-1:0]        slave_ack_data_o    ,
    // spi info
    output   wire                           SPI_CLK             ,
    output   wire                           SPI_CSN             ,
    output   wire   [SPI_MODE-1:0]          SPI_MOSI            ,
    input    wire   [SPI_MODE-1:0]          SPI_MISO            
);


//////////////////////////////////////////////////////////////////////////////////
// *********** Define Parameter Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>



//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Register Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
reg                             command_parser  = 'd0;
reg     [CMD_WIDTH-1:0]         command_cnt     = 'd0;

reg                             spi_en          = 'd0;
reg     [CMD_WIDTH-1:0]         spi_cmd         = 'd0;
reg     [ADDR_WIDTH-1:0]        spi_addr        = 'd0;

reg                             slave_ack_vld  = 'd0;
reg                             slave_ack_last = 'd0;
reg     [DATA_WIDTH-1:0]        slave_ack_data = 'd0;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Wire Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
wire                            master_fifo_full ;
wire                            master_fifo_empty;

wire                            spi_rd_vld ;
wire    [DATA_WIDTH-1:0]        spi_rd_data;
wire                            spi_busy   ;

wire    [DATA_WIDTH-1:0]        master_wr_data;
wire                            master_wr_seq ;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Instance Module
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
spi_master #(
    .DUMMY_NUM                  ( DUMMY_NUM                     ),
    .DATA_WIDTH                 ( DATA_WIDTH                    ),
    .ADDR_WIDTH                 ( ADDR_WIDTH                    ),
    .CMD_WIDTH                  ( CMD_WIDTH                     ),
    .SPI_MODE                   ( SPI_MODE                      )
)spi_master_inst(
    // clk & rst
    .clk_i                      ( clk_i                         ),
    .rst_i                      ( rst_i                         ),
    .spi_en_i                   ( spi_en                        ),
    .spi_cmd_i                  ( spi_cmd                       ),
    .spi_addr_i                 ( spi_addr                      ),
    .spi_wr_data_i              ( master_wr_data                ),      // fwft
    .spi_wr_seq_o               ( master_wr_seq                 ),

    .spi_rd_vld_o               ( spi_rd_vld                    ),
    .spi_rd_data_o              ( spi_rd_data                   ),
    .spi_busy_o                 ( spi_busy                      ),
    // spi info
    .SPI_CLK                    ( SPI_CLK                       ),
    .SPI_CSN                    ( SPI_CSN                       ),
    .SPI_MOSI                   ( SPI_MOSI                      ),
    .SPI_MISO                   ( SPI_MISO                      )
);

master_wr_fifo master_wr_fifo_inst(
    .clk                        ( clk_i                         ),
    .srst                       ( rst_i                         ),
    .din                        ( master_wr_data_i              ),
    .wr_en                      ( master_wr_vld_i && command_parser ),
    .rd_en                      ( master_wr_seq                 ),
    .dout                       ( master_wr_data                ),
    .full                       ( master_fifo_full              ),
    .empty                      ( master_fifo_empty             )
);

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Logic Design
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
always @(posedge clk_i) begin
    if(~command_parser && master_wr_vld_i && master_wr_data_i[15:8]==PMT_SEL)begin
        command_parser  <= #TCQ 'd1;
        spi_en          <= #TCQ 'd1;
        spi_cmd         <= #TCQ master_wr_data_i[7:0];
        spi_addr        <= #TCQ master_wr_data_i[31:16]; 
    end
    else if(command_parser && command_cnt==(spi_cmd[5:0] + 6'd1))begin
        command_parser <= #TCQ 'd0; 
        spi_en         <= #TCQ 'd0;
    end
    else begin
        spi_en         <= #TCQ 'd0;
    end
end

always @(posedge clk_i) begin
    if(~command_parser && master_wr_vld_i)
        command_cnt <= #TCQ 'd0;
    else if(command_parser && (master_wr_vld_i || spi_rd_vld))
        command_cnt <= #TCQ command_cnt + 1;
end

always @(posedge clk_i) begin
    if(~command_parser && master_wr_vld_i && ~master_wr_data_i[7])begin  // only rd cmd generate vld, include read result
        slave_ack_vld  <= #TCQ 'd1;
        slave_ack_data <= #TCQ master_wr_data_i;
    end
    else if(command_parser && spi_rd_vld)begin
        slave_ack_vld  <= #TCQ 'd1;
        slave_ack_data <= #TCQ spi_rd_data;
    end
    else begin
        slave_ack_vld <= #TCQ 'd0;
    end
end

always @(posedge clk_i) begin
    if(command_parser && spi_rd_vld && command_cnt==spi_cmd[5:0])
        slave_ack_last <= #TCQ 'd1;
    else 
        slave_ack_last <= #TCQ 'd0;
end

assign slave_ack_vld_o  = slave_ack_vld;
assign slave_ack_last_o = slave_ack_last;
assign slave_ack_data_o = slave_ack_data;

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


endmodule
