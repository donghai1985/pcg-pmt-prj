//~ `New testbench
`timescale  1ns / 1ps

module tb_laser_particle_detect;

// laser_particle_detect Parameters
parameter PERIOD      = 10 ;
parameter TCQ         = 0.1;
parameter DATA_WIDTH  = 32 ;

// laser_particle_detect Inputs
reg   clk_i                                = 0 ;
reg   rst_i                                = 0 ;
reg   aurora_log_clk_i                     = 0 ;
reg   laser_start_i                        = 0 ;
reg   motor_zero_flag_i                    = 0 ;
reg   laser_vld_i                          = 0 ;
reg   [DATA_WIDTH-1:0]  laser_data_i       = 0 ;
reg   ddr_vout_fifo_empty_i                = 0 ;
reg   [DATA_WIDTH-1:0]  pre_laser_rd_data_i = 0 ;
reg                         laser_rst_r         = 'd0   ;
reg                         adc_end_sync         = 'd0   ;
// laser_particle_detect Outputs
wire  pre_laser_rd_seq_o                   ;
wire  [DATA_WIDTH-1:0]  aurora_txdata_o    ;
wire  aurora_tx_emp_o                      ;
wire  [11-1:0]  aurora_rd_data_count_o     ;
wire  aurora_txen_i                        ;

wire    [31:0]              adc_data                    ;
wire                        adc_data_en                 ;

initial
begin
    forever #(PERIOD/2)  clk_i=~clk_i;
end

initial
begin
    forever #(8/2)  aurora_log_clk_i=~aurora_log_clk_i;
end

initial
begin
    rst_i  =  1;
    #(PERIOD*2);
    rst_i  =  0;
end

laser_particle_detect #(
    .TCQ        ( TCQ        ),
    .DATA_WIDTH ( DATA_WIDTH ))
 u_laser_particle_detect (
    .clk_i                   ( clk_i                                    ),
    .rst_i                   ( laser_rst_r                              ),
    .aurora_log_clk_i        ( aurora_log_clk_i                         ),
    .laser_start_i           ( laser_start_i                            ),
    .motor_zero_flag_i       ( motor_zero_flag_i                        ),
    .laser_vld_i             ( adc_data_en                              ),
    .laser_data_i            ( adc_data            [DATA_WIDTH-1:0] ),
    .ddr_vout_fifo_empty_i   ( ddr_vout_fifo_empty_i                    ),
    .pre_laser_rd_data_i     ( pre_laser_rd_data_i     [DATA_WIDTH-1:0] ),
    .aurora_txen_i           ( aurora_txen_i                            ),

    .pre_laser_rd_seq_o      ( pre_laser_rd_seq_o                       ),
    .aurora_txdata_o         ( aurora_txdata_o         [DATA_WIDTH-1:0] ),
    .aurora_tx_emp_o         ( aurora_tx_emp_o                          ),
    .aurora_rd_data_count_o  ( aurora_rd_data_count_o  [11-1:0]         )
);

ad9265_top_if ad9265_top_if_inst(
        .clk(clk_i),
        .rst(laser_rst_r),
      
        //adc config
        .AD9265_SYNC(AD9265_SYNC),
        .AD9265_PDWN(AD9265_PDWN),
        .spi_clk(AD9265_SCLK),
        .spi_csn(AD9265_CSB),
        .spi_sdio(AD9265_SDIO),
        .init(ad9265_init),
        //adc data
        .AD9265_DCO(clk_i), 
        .AD9265_DATA(AD9265_DATA),
        .AD9265_OR(AD9265_OR),

        .adc_start(laser_start_i),
        .adc_end(adc_end_sync),
        .adc_test('d1),
        .adc_data(adc_data),
        .adc_data_en(adc_data_en)

);

always @(posedge clk_i) 
begin
    if(rst_i) begin
        laser_rst_r  <= #TCQ 'd1;
    end
    else begin
        laser_rst_r  <= #TCQ adc_end_sync;
    end
end

// always @(posedge clk_i) begin
//     if(laser_start_i)
//         if(laser_data_i[15:0]=='d59999)
//             laser_data_i[15:0] <= 'd0;
//         else 
//             laser_data_i[15:0] <= laser_data_i[15:0] + 1;
//     else 
//         laser_data_i[15:0] <= 'd0; 
// end
// always @(posedge clk_i) begin
//     laser_data_i[31:16] <= laser_data_i[15:0];
// end

// always @(posedge clk_i) begin
//     if(laser_start_i)
//         laser_vld_i <= ~laser_vld_i;
//     else 
//         laser_vld_i <= 'd0;
// end

always @(posedge clk_i) begin
    if(rst_i)
        pre_laser_rd_data_i <= 'd0;
    else if(pre_laser_rd_seq_o)
        pre_laser_rd_data_i <= pre_laser_rd_data_i + 1;
end

aurora_8b10b_0_FRAME_GEN frame_gen_i
(
    // User Interface
    .aurora_txen(aurora_txen_i),
    .aurora_txdata(aurora_txdata_o),
    .aurora_rd_data_count(aurora_rd_data_count_o),
    
    .adc_start(laser_start_i),
    .adc_end(adc_end_sync),
    // System Interface
    .USER_CLK(aurora_log_clk_i),      
    .RESET(rst_i),
    .CHANNEL_UP('d1),
    .tx_tvalid  ( ),
    .tx_data    ( ),
    .tx_tkeep   ( ),
    .tx_tlast   ( ),
    .tx_tready  ( 'd1)
);


initial
begin
    #1000;
    laser_start_i = 1;
    $finish;
end

endmodule