`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: zas
// Engineer: songyuxin
// 
// Create Date: 2023/7/06
// Design Name: PCG
// Module Name: serial_slave_drv
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


module serial_slave_drv #(
    parameter                               TCQ          = 0.1  ,
    parameter                               DATA_WIDTH   = 32   ,
    parameter                               ADDR_WIDTH   = 16   ,
    parameter                               CMD_WIDTH    = 8    ,
    parameter                               SERIAL_MODE  = 2    
)(
    // clk & rst
    input   wire                            clk_i               , // 100MHz
    input   wire                            rst_i               ,
    input   wire                            clk_200m_i          , // 200MHz

    output  wire                            slave_wr_en_o       , 
    output  wire    [ADDR_WIDTH-1:0]        slave_addr_o        ,
    output  wire    [DATA_WIDTH-1:0]        slave_wr_data_o     ,

    output  wire                            slave_rd_en_o       ,
    input   wire                            slave_rd_vld_i      ,
    input   wire    [DATA_WIDTH-1:0]        slave_rd_data_i     ,

    // spi info
    input   wire                            SPI_MCLK            ,
    input   wire    [SERIAL_MODE-1:0]       SPI_MOSI            ,
    output  wire                            SPI_SCLK            ,
    output  wire    [SERIAL_MODE-1:0]       SPI_MISO            
);


//////////////////////////////////////////////////////////////////////////////////
// *********** Define Parameter Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
localparam                      RD_ACK_TIMEOUT_COUNT = 'd4999;   // 5000 * 10ns = 50us

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Register Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
reg     [DATA_WIDTH-1:0]        master_wr_din       = 'd0;
reg                             master_wr_en        = 'd0;
reg                             tx_data_num_en      = 'd0;
reg     [6-1:0]                 tx_data_num         = 'd0;

reg                             command_parser      = 'd0;
reg     [CMD_WIDTH-1:0]         command_cnt         = 'd0;

reg                             spi_en              = 'd0;
reg     [CMD_WIDTH-1:0]         spi_cmd             = 'd0;
reg     [8-1:0]                 spi_sel             = 'd0;
reg     [ADDR_WIDTH-1:0]        spi_addr            = 'd0;

reg                             tx_valid            = 'd0;
reg                             tx_rd_ready_d       = 'd0;
reg                             tx_rd_en            = 'd0;

reg     [ADDR_WIDTH-1:0]        slave_addr_r        = 'd0;

reg                             slave_mode          = 'd0;
reg                             slave_rd_seq        = 'd0;
reg     [CMD_WIDTH-1:0]         slave_rd_leng       = 'd0;
reg     [CMD_WIDTH-1:0]         slave_rd_cnt        = 'd0;
reg     [16-1:0]                timeout_cnt         = 'd0;

reg                             rx_valid_d          = 'd0;
reg                             command_parser_d    = 'd0;
reg     [32-1:0]                rx_data_d           = 'd0;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Wire Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
wire                            tx_ack              ;
wire                            rx_valid            ;
wire    [DATA_WIDTH-1:0]        rx_data             ; 

wire                            slave_fifo_full     ;
wire                            slave_fifo_empty    ;
wire                            tx_rd_ready         ;

wire                            comm_timeout_rst    ;
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
    .tx_valid_i                 ( master_wr_en                      ),
    .tx_data_i                  ( master_wr_din                     ),
    .tx_ack_o                   ( tx_ack                            ),

    // .TX_ENABLE                  ( SPI_SENABLE                       ),
    .TX_CLK                     ( SPI_SCLK                          ),
    .TX_DOUT                    ( SPI_MISO                          )
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

    // .RX_ENABLE                  ( SPI_MENABLE                       ),
    .RX_CLK                     ( SPI_MCLK                          ),
    .RX_DIN                     ( SPI_MOSI                          )
);


//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


//////////////////////////////////////////////////////////////////////////////////
// *********** Logic Design
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
always @(posedge clk_i) begin
    if(comm_timeout_rst)begin
        command_parser <= #TCQ 'd0;
    end
    else if((~command_parser) && rx_valid && (|rx_data[10:8]))begin
        command_parser  <= #TCQ 'd1;
        spi_en          <= #TCQ 'd1;
        spi_cmd         <= #TCQ rx_data[7:0];
        spi_sel         <= #TCQ rx_data[15:8];
        spi_addr        <= #TCQ rx_data[31:16]; 
    end
    else if(command_parser && (tx_ack || (command_cnt==(spi_cmd[5:0] + 6'd1))))begin
        command_parser <= #TCQ 'd0; 
        spi_en         <= #TCQ 'd0;
    end
    else begin
        spi_en         <= #TCQ 'd0;
    end
end

always @(posedge clk_i) begin
    if((~command_parser) && rx_valid && (|rx_data[10:8]))
        command_cnt <= #TCQ 'd0;
    else if(command_parser && rx_valid )
        command_cnt <= #TCQ command_cnt + 1;
end

always @(posedge clk_i) begin
    if(spi_en)
        slave_mode <= #TCQ spi_cmd[CMD_WIDTH-1]; 
end

always @(posedge clk_i) begin
    if(spi_en)
        slave_addr_r <= #TCQ spi_addr;
    else if(~slave_mode && rx_valid && command_parser)begin
        slave_addr_r <= #TCQ slave_addr_r + 4;
    end
    else if(slave_mode && slave_rd_seq && command_parser)begin
        slave_addr_r <= #TCQ slave_addr_r + 4;
    end
end

// read  register, fanin, use fifo for buffer
// read cmd back to master
always @(posedge clk_i) begin
    if(spi_en && spi_cmd[CMD_WIDTH-1])begin   // read command
        master_wr_en    <= #TCQ 'd1;
        master_wr_din   <= #TCQ {spi_addr[15:0],4'b1010,spi_sel[3:0],spi_cmd[7:0]};   // 4'b1010 -> mask write/read flag, mark slave readback pack
    end
    else if(slave_rd_vld_i)begin
        master_wr_en    <= #TCQ 'd1;
        master_wr_din   <= #TCQ slave_rd_data_i;
    end
    else begin
        master_wr_en    <= #TCQ 'd0;
    end
end

always @(posedge clk_i) begin
    if(spi_en && spi_cmd[CMD_WIDTH-1])begin   // read command
        tx_data_num_en  <= #TCQ 'd1;
        tx_data_num     <= #TCQ spi_cmd[5:0] + 1;
    end
    else begin
        tx_data_num_en  <= #TCQ 'd0;
    end
end

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

always @(posedge clk_i) begin // 连续读取
    if(spi_en && spi_cmd[CMD_WIDTH-1])
        slave_rd_seq <= #TCQ 'd1;
    else if(slave_rd_cnt==slave_rd_leng)
        slave_rd_seq <= #TCQ 'd0;
end

// command timeout check
always @(posedge clk_i) begin
    if(~command_parser)begin
        timeout_cnt <= #TCQ 'd0;
    end
    else if(timeout_cnt == RD_ACK_TIMEOUT_COUNT)begin
        timeout_cnt <= #TCQ timeout_cnt;
    end
    else begin
        timeout_cnt <= #TCQ timeout_cnt + 1;
    end
end

// assign SPI_SENABLE  = slave_in_place;
assign comm_timeout_rst = (timeout_cnt == RD_ACK_TIMEOUT_COUNT);

always @(posedge clk_i) rx_valid_d <= #TCQ rx_valid;
always @(posedge clk_i) command_parser_d <= #TCQ command_parser;
always @(posedge clk_i) rx_data_d <= #TCQ rx_data;

assign slave_rd_en_o    = slave_rd_seq;
assign slave_wr_en_o    = rx_valid_d && command_parser_d;
assign slave_addr_o     = slave_addr_r;
assign slave_wr_data_o  = rx_data_d ;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


endmodule
