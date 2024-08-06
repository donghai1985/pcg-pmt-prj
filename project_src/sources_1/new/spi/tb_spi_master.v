//~ `New testbench
`timescale  1ns / 1ps

module tb_spi_master;

// spi_master Parameters
parameter PERIOD      = 10 ;
parameter TCQ         = 0.1;
parameter DUMMY_NUM   = 8  ;
parameter DATA_WIDTH  = 32 ;
parameter ADDR_WIDTH  = 16 ;
parameter CMD_WIDTH   = 8  ;
parameter SPI_MODE    = 2  ;

// spi_master Inputs
reg   clk_i                                = 0 ;
reg   rst_i                                = 0 ;
reg   spi_en_i                             = 0 ;
reg   [CMD_WIDTH-1:0]  spi_cmd_i           = 0 ;
reg   [ADDR_WIDTH-1:0]  spi_addr_i         = 0 ;
reg   [DATA_WIDTH-1:0]  spi_wr_data_i      = 0 ;

// spi_master Outputs
wire  spi_wr_seq_o                         ;
wire  spi_rd_vld_o                         ;
wire  [DATA_WIDTH-1:0]  spi_rd_data_o      ;
wire  spi_busy_o                           ;
wire  SPI_CLK                              ;
wire  SPI_CSN                              ;
wire  [SPI_MODE-1:0]  SPI_MOSI             ;

// spi_slave_drv Outputs
wire                    slave_rd_vld       ;
wire  [DATA_WIDTH-1:0]  slave_rd_data      ;
wire                    slave_wr_en        ;
wire  [ADDR_WIDTH-1:0]  slave_addr         ;
wire  [DATA_WIDTH-1:0]  slave_wr_data      ;
wire                    slave_rd_en        ;
wire  [ADDR_WIDTH-1:0]  slave_rd_addr      ;
wire  [SPI_MODE-1:0]    SPI_MISO            ;

wire                slave_tx_ack            ;
wire                slave_tx_byte_en        ;
wire    [ 7:0]      slave_tx_byte           ;
wire                slave_tx_byte_num_en    ;
wire    [15:0]      slave_tx_byte_num       ;
wire                slave_rx_data_vld       ;
wire    [ 7:0]      slave_rx_data           ;
reg   [32-1:0]     pmt_master_spi_data    = 0 ;
reg                pmt_master_spi_vld     = 0 ;
wire                spi_slave_ack_vld       ;
wire                spi_slave_ack_last      ;
wire   [32-1:0]     spi_slave_ack_data      ;
initial
begin
    forever #(PERIOD/2)  clk_i=~clk_i;
end

initial
begin
    #(PERIOD*2) rst_i  =  1;
    #(PERIOD*2) rst_i  =  0;
end

// mfpga to mainPC message arbitrate 
arbitrate_bpsi arbitrate_bpsi_inst(
    .clk_i                          ( clk_i                         ),
    .rst_i                          ( rst_i                         ),

    .spi_slave_ack_vld_i            ( spi_slave_ack_vld             ),
    .spi_slave_ack_last_i           ( spi_slave_ack_last            ),
    .spi_slave_ack_data_i           ( spi_slave_ack_data            ),

    .slave_tx_ack_i                 ( slave_tx_ack                  ),
    .slave_tx_byte_en_o             ( slave_tx_byte_en              ),
    .slave_tx_byte_o                ( slave_tx_byte                 ),
    .slave_tx_byte_num_en_o         ( slave_tx_byte_num_en          ),
    .slave_tx_byte_num_o            ( slave_tx_byte_num             )
);

slave_comm slave_comm_inst(
    // clk & rst
    .clk_sys_i                      ( clk_i                         ),
    .rst_i                          ( rst_i                         ),
    // salve tx info
    .slave_tx_en_i                  ( slave_tx_byte_en              ),
    .slave_tx_data_i                ( slave_tx_byte                 ),
    .slave_tx_byte_num_en_i         ( slave_tx_byte_num_en          ),
    .slave_tx_byte_num_i            ( slave_tx_byte_num             ),
    .slave_tx_ack_o                 ( slave_tx_ack                  ),
    // slave rx info
    .rd_data_vld_o                  (        ),
    .rd_data_o                      (        ),
    // info
    .SLAVE_MSG_CLK                  (        ),
    .SLAVE_MSG_TX_FSX               (        ),
    .SLAVE_MSG_TX                   (        ),
    .SLAVE_MSG_RX_FSX               (        ),
    .SLAVE_MSG_RX                   (        )
);

spi_master_drv #(
    .DUMMY_NUM                      ( 8                             ),
    .DATA_WIDTH                     ( 32                            ),
    .ADDR_WIDTH                     ( 16                            ),
    .CMD_WIDTH                      ( 8                             ),
    .SPI_MODE                       ( 2                             )
)spi_master_drv_inst(
    // clk & rst
    .clk_i                          ( clk_i                         ),
    .rst_i                          ( rst_i                         ),
    .master_wr_data_i               ( pmt_master_spi_data           ),
    .master_wr_vld_i                ( pmt_master_spi_vld            ),

    .slave_ack_vld_o                ( spi_slave_ack_vld             ),
    .slave_ack_last_o               ( spi_slave_ack_last            ),
    .slave_ack_data_o               ( spi_slave_ack_data            ),
    // spi info
    .SPI_CLK                        ( SPI_CLK                   ),
    .SPI_CSN                        ( SPI_CSN                   ),
    .SPI_MOSI                       ( SPI_MOSI                  ),
    .SPI_MISO                       ( SPI_MISO                  )
);


spi_slave_drv #(
    .DATA_WIDTH ( DATA_WIDTH ),
    .ADDR_WIDTH ( ADDR_WIDTH ),
    .CMD_WIDTH  ( CMD_WIDTH  ),
    .SPI_MODE   ( SPI_MODE   ))
 u_spi_slave_drv (
    .clk_i                   ( clk_i                             ),
    .rst_i                   ( rst_i                             ),
    .slave_rd_vld_i          ( slave_rd_vld                      ),
    .slave_rd_data_i         ( slave_rd_data    [DATA_WIDTH-1:0] ),
    .SPI_CLK                 ( SPI_CLK                           ),
    .SPI_CSN                 ( SPI_CSN                           ),
    .SPI_MOSI                ( SPI_MOSI         [SPI_MODE-1:0]   ),

    .slave_wr_en_o           ( slave_wr_en                       ),
    .slave_addr_o            ( slave_addr       [ADDR_WIDTH-1:0] ),
    .slave_wr_data_o         ( slave_wr_data    [DATA_WIDTH-1:0] ),
    .slave_rd_en_o           ( slave_rd_en                       ),
    .SPI_MISO                ( SPI_MISO         [SPI_MODE-1:0]   )
);

spi_reg_map #(
    .DATA_WIDTH             ( DATA_WIDTH                        ),
    .ADDR_WIDTH             ( ADDR_WIDTH                        )
)spi_reg_map_inst(
    // clk & rst
    .clk_i                  ( clk_i                             ),
    .rst_i                  ( rst_i                             ),

    .slave_wr_en_i          ( slave_wr_en                       ), 
    .slave_addr_i           ( slave_addr                        ),
    .slave_wr_data_i        ( slave_wr_data                     ),
    .slave_rd_en_i          ( slave_rd_en                       ),
    .slave_rd_vld_o         ( slave_rd_vld                      ),
    .slave_rd_data_o        ( slave_rd_data                     ),

    .debug_info             (                                   )
);

reg [DATA_WIDTH-1:0] mem_master_sim [63:0];
reg [DATA_WIDTH-1:0] mem_slave_sim [63:0];
genvar i;

generate
    for (i = 0;i<64 ;i=i+1 ) begin
        always @(posedge clk_i ) begin
            if(rst_i)
                mem_master_sim[i] <= i;
        end
    end
endgenerate

reg spi_csn_d = 'd0;
reg [6-1:0] master_rd_addr = 'd0;
always @(posedge clk_i ) begin
    spi_csn_d <= SPI_CSN;
end

always @(posedge clk_i ) begin
    if(spi_csn_d && ~SPI_CSN)begin
        master_rd_addr <= 'd0;
    end
    else if(spi_wr_seq_o)begin
        master_rd_addr <= master_rd_addr + 1;
    end
end

always @(*) begin
    spi_wr_data_i <= mem_master_sim[master_rd_addr];
end

initial
begin
    #1000;
    pmt_master_spi_vld = 1;
    pmt_master_spi_data = 'h0000_00_04;
    #10;
    pmt_master_spi_data = 'h0000_0001;
    #10;
    pmt_master_spi_data = 'h0000_0004;
    #10;
    pmt_master_spi_data = 'h0000_0001;
    #10;
    pmt_master_spi_data = 'h0000_0002;
    #10;
    pmt_master_spi_data = 'h0000_0003;
    #10;
    pmt_master_spi_vld = 0;
    #5000;
    pmt_master_spi_vld = 1;
    pmt_master_spi_data = 'h0000_00_84;
    #10;
    pmt_master_spi_vld = 0;
    
    $finish;
end

endmodule