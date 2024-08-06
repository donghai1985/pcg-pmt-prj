//~ `New testbench
`timescale  1ns / 1ps

module tb_haze_generate;

// haze_generate Parameters
parameter PERIOD         = 10 ;
parameter TCQ            = 0.1;
parameter DATA_WIDTH     = 16 ;

// haze_generate Inputs
reg   clk_i                                = 0 ;
reg   rst_i                                = 0 ;
reg   src_vld_i                          = 0 ;
reg   [32-1:0]  src_data_i       = 0 ;

// haze_generate Outputs
wire  haze_vld_o                           ;
wire  [DATA_WIDTH-1:0]  haze_data_o        ;


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

haze_generate #(
    .TCQ           ( TCQ           ),
    .DATA_WIDTH    ( DATA_WIDTH    ))
 u_haze_generate (
    .clk_i                   ( clk_i                            ),
    .rst_i                   ( rst_i                            ),
    .laser_vld_i             ( src_vld_i                        ),
    .laser_data_i            ( src_data_i                       ),

    .haze_vld_o              ( haze_vld_o                       ),
    .haze_data_o             ( haze_data_o   [DATA_WIDTH-1:0]   )
);

always @(posedge clk_i) begin
    if(rst_i)
        src_data_i <= 0;
    else
        src_data_i <= {$random()} % 10;
end  

always @(posedge clk_i) begin
    if(rst_i)
        src_vld_i <= 0;
    else
        src_vld_i <= ~src_vld_i;
end

initial
begin
    #10000;
    $finish;
end

endmodule