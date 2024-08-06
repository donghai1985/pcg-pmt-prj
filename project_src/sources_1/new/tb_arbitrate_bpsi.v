
//~ `New testbench
`timescale  1ns / 1ps

module tb_arbitrate_bpsi;

// arbitrate_bpsi Parameters
parameter PERIOD         = 10                    ;
parameter TCQ            = 0.1                   ;
parameter MFPGA_VERSION  = "PCG1_TimingM_v1.1   ";

// arbitrate_bpsi Inputs
reg   clk_i                                = 0 ;
reg   rst_i                                = 0 ;
reg   readback_vld_i                       = 0 ;
reg   readback_last_i                      = 0 ;
reg   [32-1:0]  readback_data_i            = 'h00010002 ;
reg   raw_adc_cfg_i                        = 0 ;
reg   raw_adc_vld_i                        = 0 ;
reg   [16-1:0]  raw_adc_data_i             = 0 ;
reg   slave_tx_ack_i                       = 0 ;

// arbitrate_bpsi Outputs
wire  slave_tx_byte_num_en_o               ;
wire  [15:0]  slave_tx_byte_num_o          ;
wire  slave_tx_byte_en_o                   ;
wire  [ 7:0]  slave_tx_byte_o              ;


initial
begin
    forever #(PERIOD/2)  clk_i=~clk_i;
end

initial
begin
    rst_i  =  1;
    #(PERIOD*2);
    rst_i  =  0;
end

arbitrate_bpsi #(
    .TCQ           ( TCQ           ),
    .MFPGA_VERSION ( MFPGA_VERSION ))
 u_arbitrate_bpsi (
    .clk_i                   ( clk_i                            ),
    .rst_i                   ( rst_i                            ),
    .readback_vld_i          ( readback_vld_i                   ),
    .readback_last_i         ( readback_last_i                  ),
    .readback_data_i         ( readback_data_i         [32-1:0] ),
    .raw_adc_cfg_i           ( raw_adc_cfg_i                    ),
    .raw_adc_vld_i           ( raw_adc_vld_i                    ),
    .raw_adc_data_i          ( raw_adc_data_i          [16-1:0] ),
    .slave_tx_ack_i          ( slave_tx_ack_i                   ),

    .slave_tx_byte_num_en_o  ( slave_tx_byte_num_en_o           ),
    .slave_tx_byte_num_o     ( slave_tx_byte_num_o     [15:0]   ),
    .slave_tx_byte_en_o      ( slave_tx_byte_en_o               ),
    .slave_tx_byte_o         ( slave_tx_byte_o         [ 7:0]   )
);

always @(posedge clk_i) begin
    if(readback_vld_i)
        readback_data_i <= #TCQ readback_data_i + 'h00020002;
end

always @(posedge clk_i) begin
    if(raw_adc_vld_i)
        raw_adc_data_i <= #TCQ raw_adc_data_i + 'h0001;
end


initial
begin
    #1000;
    raw_adc_vld_i = 1;
    // readback_vld_i = 1;
    // #(PERIOD*255);
    // readback_last_i = 1;
    // #(PERIOD*1);
    // readback_last_i = 0;
    // readback_vld_i = 0;

    #1000;
    raw_adc_cfg_i = 1;
    #12000;
    $finish;
end

endmodule