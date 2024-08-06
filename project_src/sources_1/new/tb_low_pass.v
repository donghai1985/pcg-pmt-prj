//~ `New testbench
`timescale  1ns / 1ps

module tb_low_pass;

// low_pass Parameters
parameter PERIOD      = 10 ;
parameter TCQ         = 0.1;
parameter LP_DEPTH    = 8  ;
parameter DATA_WIDTH  = 16 ;

// low_pass Inputs
reg   clk_i                                = 0 ;
reg   rst_i                                = 0 ;
reg   laser_vld_i                          = 0 ;
reg   [DATA_WIDTH-1:0]  laser_data_i       = 0 ;

// low_pass Outputs
wire  lp_laser_vld_o                       ;
wire  [DATA_WIDTH-1:0]  lp_laser_data_o    ;


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

low_pass #(
    .TCQ        ( TCQ        ),
    .LP_DEPTH   ( LP_DEPTH   ),
    .DATA_WIDTH ( DATA_WIDTH ))
 u_low_pass (
    .clk_i                   ( clk_i                             ),
    .rst_i                   ( rst_i                             ),
    .laser_vld_i             ( laser_vld_i                       ),
    .laser_data_i            ( laser_data_i     [DATA_WIDTH-1:0] ),

    .lp_laser_vld_o          ( lp_laser_vld_o                    ),
    .lp_laser_data_o         ( lp_laser_data_o  [DATA_WIDTH-1:0] )
);

initial
begin

    $finish;
end

endmodule