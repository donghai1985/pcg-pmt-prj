//~ `New testbench
`timescale  1ns / 1ps

module tb_fir_low_pass;

// fir_low_pass Parameters
parameter PERIOD      = 10 ;
parameter TCQ         = 0.1;
parameter DATA_WIDTH  = 16 ;

// fir_low_pass Inputs
reg   clk_i                                = 0 ;
reg   rst_i                                = 0 ;
reg   laser_start_i                        = 0 ;
reg   [8-1:0]  fir_down_sample_num_i       = 0 ;
reg   laser_vld_i                          = 0 ;
reg   [DATA_WIDTH-1:0]  laser_data_i       = 0 ;

// fir_low_pass Outputs
wire  lp_laser_vld_o                      ;
wire  [DATA_WIDTH-1:0]  lp_laser_data_o   ;


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

fir_low_pass #(
    .TCQ        ( TCQ        ),
    .DATA_WIDTH ( DATA_WIDTH ))
 u_fir_low_pass (
    .clk_i                   ( clk_i                                   ),
    .rst_i                   ( rst_i                                   ),
    .laser_start_i           ( laser_start_i                           ),
    .fir_down_sample_num_i   ( fir_down_sample_num_i  [8-1:0]          ),
    .laser_vld_i             ( laser_vld_i                             ),
    .laser_data_i            ( laser_data_i           [DATA_WIDTH-1:0] ),

    .lp_laser_vld_o          ( lp_laser_vld_o                          ),
    .lp_laser_data_o         ( lp_laser_data_o       [DATA_WIDTH-1:0]  )
);

always @(posedge clk_i) begin
    if(laser_start_i)begin
        laser_vld_i  <= #TCQ 'd1;
        laser_data_i <= #TCQ laser_data_i + 1;
    end
end
initial
begin

    #1000;
    laser_start_i = 1;
    #10000;
    fir_down_sample_num_i = 1;
    #10000;
    fir_down_sample_num_i = 2;
    #10000;
    fir_down_sample_num_i = 3;
    #10000;
    fir_down_sample_num_i = 17;
    #10000;
    fir_down_sample_num_i = 18;
    #10000;
    fir_down_sample_num_i = 19;
    #10000;
    $finish;
end

endmodule