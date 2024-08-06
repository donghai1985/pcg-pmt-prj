//~ `New testbench
`timescale  1ns / 1ps

module tb_task_test;


reg                     clk_100m                = 0 ;
reg                     clk_50m                 = 0 ;
reg                     sys_rst_n               = 0 ;
reg                     clk_200m                = 0 ;

reg                     rst_100m                = 0 ;

initial
begin
    forever #(10/2)  clk_100m=~clk_100m;
end

initial begin
    rst_100m = 1;
    #40;
    rst_100m = 0;
end


reg [32-1:0]    pmt_master_wr_data  = 'd0;
reg [2-1:0]     pmt_master_wr_vld   = 'd0;

task automatic register_ctrl(
    input   [16-1:0]    register_addr           ,
    input               register_cmd            ,
    input   [32-1:0]    register_data           ,
    output  [32-1:0]    pmt_master_wr_data      ,
    output  [2-1:0]     pmt_master_wr_vld      
);


begin
    #100;
    pmt_master_wr_vld   = 3;
    pmt_master_wr_data  = {register_addr[15:0],8'h01,register_cmd,7'h0};
    #10;
    pmt_master_wr_vld   = 1;
    pmt_master_wr_data  = register_data;
    #10;
    pmt_master_wr_vld = 5;
end

endtask

always @(posedge clk_100m) begin

    register_ctrl('h0014,1'b0,'h0000_0001,pmt_master_wr_data,pmt_master_wr_vld);
end
initial begin
    #1000;
    // register_ctrl('h0014,1'b0,'h0000_0001,pmt_master_wr_data,pmt_master_wr_vld);
    
    #1000;
    // register_ctrl(clk_100m,'h0014,1'b0,'h0000_0001,pmt_master_wr_data,pmt_master_wr_vld);


end

endmodule