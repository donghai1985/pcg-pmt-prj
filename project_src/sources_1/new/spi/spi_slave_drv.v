`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/06/13
// Design Name: songyuxin
// Module Name: spi_slave_drv
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


module spi_slave_drv #(
    parameter                               TCQ        = 0.1,
    parameter                               DUMMY_NUM  = 8  ,
    parameter                               DATA_WIDTH = 32 ,
    parameter                               ADDR_WIDTH = 16 ,
    parameter                               CMD_WIDTH  = 8  ,
    parameter                               SPI_MODE   = 2  
)(
    // clk & rst
    input    wire                           clk_i           , // 100MHz
    input    wire                           rst_i           ,

    output   wire                           slave_wr_en_o   , 
    output   wire   [ADDR_WIDTH-1:0]        slave_addr_o    ,
    output   wire   [DATA_WIDTH-1:0]        slave_wr_data_o ,

    output   wire                           slave_rd_en_o   ,
    input    wire                           slave_rd_vld_i  ,
    input    wire   [DATA_WIDTH-1:0]        slave_rd_data_i ,
    output   wire                           spi_slave_t_o   ,

    // spi info
    input    wire                           SPI_CLK         , //50MHz
    input    wire                           SPI_CSN         ,
    input    wire   [SPI_MODE-1:0]          SPI_MOSI        ,
    output   wire   [SPI_MODE-1:0]          SPI_MISO        
);


//////////////////////////////////////////////////////////////////////////////////
// *********** Define Parameter Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Register Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
reg     [ADDR_WIDTH-1:0]        slave_addr_r    = 'd0;
reg                             slave_wr_en_r   = 'd0;
reg     [DATA_WIDTH-1:0]        slave_wr_data_r = 'd0;

reg                             slave_mode      = 'd0;
reg                             slave_rd_seq    = 'd0;
reg     [CMD_WIDTH-1:0]         slave_rd_leng   = 'd0;
reg     [CMD_WIDTH-1:0]         slave_rd_cnt    = 'd0;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<



//////////////////////////////////////////////////////////////////////////////////
// *********** Define Wire Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
wire                            spi_en          ;
wire   [CMD_WIDTH-1:0]          spi_cmd         ;
wire   [ADDR_WIDTH-1:0]         spi_addr        ;
wire                            spi_wr_vld      ;
wire   [DATA_WIDTH-1:0]         spi_wr_data     ;
wire                            spi_rd_seq      ;
wire   [DATA_WIDTH-1:0]         spi_rd_data     ;

wire                            slave_fifo_full ;
wire                            slave_fifo_empty;


//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<





//////////////////////////////////////////////////////////////////////////////////
// *********** Instance Module
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
spi_slave #(
    .DUMMY_NUM                  ( DUMMY_NUM                     ),
    .DATA_WIDTH                 ( DATA_WIDTH                    ),
    .ADDR_WIDTH                 ( ADDR_WIDTH                    ),
    .CMD_WIDTH                  ( CMD_WIDTH                     ),
    .SPI_MODE                   ( SPI_MODE                      ))
 u_spi_slave (
    .clk_i                      ( clk_i                         ),
    .rst_i                      ( rst_i                         ),
    .spi_en_o                   ( spi_en                        ),
    .spi_cmd_o                  ( spi_cmd                       ),
    .spi_addr_o                 ( spi_addr                      ),
    .spi_wr_vld_o               ( spi_wr_vld                    ),
    .spi_wr_data_o              ( spi_wr_data                   ),
    .spi_rd_seq_o               ( spi_rd_seq                    ),
    .spi_rd_data_i              ( spi_rd_data                   ),
    .spi_slave_t_o              ( spi_slave_t_o                 ),

    .SPI_CLK                    ( SPI_CLK                       ),
    .SPI_CSN                    ( SPI_CSN                       ),
    .SPI_MOSI                   ( SPI_MOSI                      ),
    .SPI_MISO                   ( SPI_MISO                      )
);

slave_rd_fifo slave_rd_fifo_inst(
    .clk                        ( clk_i                         ),
    .srst                       ( rst_i                         ),
    .din                        ( slave_rd_data_i               ),
    .wr_en                      ( slave_rd_vld_i                ),
    .rd_en                      ( spi_rd_seq                    ),
    .dout                       ( spi_rd_data                   ),
    .full                       ( slave_fifo_full               ),
    .empty                      ( slave_fifo_empty              )
);

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


//////////////////////////////////////////////////////////////////////////////////
// *********** Logic Design
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
always @(posedge clk_i) begin
    if(spi_en)
        slave_mode <= #TCQ spi_cmd[CMD_WIDTH-1]; 
end

always @(posedge clk_i) begin
    if(spi_en)
        slave_addr_r <= #TCQ spi_addr;
    else if(~slave_mode && spi_wr_vld)begin
        slave_addr_r <= #TCQ slave_addr_r + 4;
    end
    else if(slave_mode && slave_rd_seq)begin
        slave_addr_r <= #TCQ slave_addr_r + 4;
    end
end

// read  register, fanin, use fifo for buffer
always @(posedge clk_i) begin
    if(spi_en)
        slave_rd_leng <= #TCQ {1'b0,spi_cmd[CMD_WIDTH-2:0]}; 
end

always @(posedge clk_i) begin
    if(spi_en && spi_cmd[CMD_WIDTH-1])
        slave_rd_cnt <= #TCQ 'd0;
    else if(slave_rd_cnt <= slave_rd_leng)
        slave_rd_cnt <= #TCQ slave_rd_cnt + 1;
end

always @(posedge clk_i) begin
    if(spi_en && spi_cmd[CMD_WIDTH-1])
        slave_rd_seq <= #TCQ 'd1;
    else if(slave_rd_cnt==slave_rd_leng)
        slave_rd_seq <= #TCQ 'd0;
end

assign slave_rd_en_o    = slave_rd_seq;
assign slave_wr_en_o    = spi_wr_vld  ;
assign slave_addr_o     = slave_addr_r;
assign slave_wr_data_o  = spi_wr_data ;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


endmodule
