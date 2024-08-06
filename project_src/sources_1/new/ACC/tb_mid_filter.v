//~ `New testbench
`timescale  1ns / 1ps

module tb_mid_filter;

// mid_filter Parameters
parameter PERIOD      = 10 ;
parameter TCQ         = 0.1;
parameter DATA_WIDTH  = 16 ;

// mid_filter Inputs
reg   clk_i                                = 0 ;
reg   rst_i                                = 0 ;
reg   src_vld_i                            = 0 ;
reg   [DATA_WIDTH-1:0]  src_data_i         = 0 ;

// mid_filter Outputs
wire  mid_vld_o                            ;
wire  [DATA_WIDTH-1:0]  mid_data_o         ;


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

mid_filter #(
    .TCQ        ( TCQ        ),
    .DATA_WIDTH ( DATA_WIDTH ))
 u_mid_filter (
    .clk_i                   ( clk_i                        ),
    .rst_i                   ( rst_i                        ),
    .src_vld_i               ( src_vld_i                    ),
    .src_data_i              ( src_data_i  [DATA_WIDTH-1:0] ),

    .mid_vld_o               ( mid_vld_o                    ),
    .mid_data_o              ( mid_data_o  [DATA_WIDTH-1:0] )
);

reg [5-1:0] data_vld_cnt = 'd0;
always @(posedge clk_i) begin
    if(rst_i)
        data_vld_cnt <= 'd0;
    else 
        data_vld_cnt <= data_vld_cnt + 1;
end

reg[16-1:0] rand_r = 'd0;
always @(posedge clk_i) begin
    if(&data_vld_cnt)
        src_data_i <= {$random()} % 65535;
end  

always @(posedge clk_i) begin
    src_vld_i <= &data_vld_cnt;
end

initial
begin
    #10000;
    $finish;
end

endmodule