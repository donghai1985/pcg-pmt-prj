`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/05/22
// Design Name: 
// Module Name: reset_generate
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

module reset_generate(
    input       nrst_i          ,

    input       clk_100m        ,
    output reg  rst_100m        ,
    
    input       clk_200m        ,
    output reg  rst_200m        ,

    input       clk_50m             ,
    output reg  gt_rst          = 'd1,

    input       aurora_log_clk  ,
    output reg  aurora_rst      = 'd1,

    output reg  debug_info  
);

reg     [15:0]  rst_cnt = 'd0;
always @(posedge clk_100m) begin
    if(!nrst_i) begin
        rst_cnt     <= 'd0;
        rst_100m    <= 'd1;
    end
    `ifdef SIMULATE
    else if(rst_cnt == 'd10)begin
    `else
    else if(rst_cnt == 'd10000) begin        //100us
    `endif //SIMULATE
        rst_cnt     <= rst_cnt;
        rst_100m    <= 'd0;
    end
    else begin
        rst_100m    <= 'd1;
        rst_cnt     <= rst_cnt + 1'b1;
    end
end


reg     [7:0]  rst200m_cnt = 'd0;
always @(posedge clk_100m) begin
    if(!nrst_i) begin
        rst200m_cnt <= 'd0;
        rst_200m    <= 'd1;
    end
    else if(rst200m_cnt[7]) begin   
        rst200m_cnt <= rst200m_cnt;
        rst_200m    <= 'd0;
    end
    else begin
        rst_200m    <= 'd1;
        rst200m_cnt <= rst200m_cnt + 1'b1;
    end
end


reg [16:0]   gt_rst_cnt = 'd0;
always @(posedge clk_50m) begin
    if(!nrst_i) begin
        gt_rst      <= 'd1;
        gt_rst_cnt  <= 'd0;
    end
    else if(gt_rst_cnt[16]) begin
        gt_rst_cnt  <= gt_rst_cnt;
        gt_rst      <= 'd0;
    end
    else begin
        gt_rst      <= 'd1;
        gt_rst_cnt  <= gt_rst_cnt + 1'b1;
    end
end

reg [17:0]   aurora_rst_cnt = 'd0;
always @(posedge aurora_log_clk ) begin
    if(!nrst_i) begin
        aurora_rst_cnt  <= 'd0;
        aurora_rst      <= 'b1;
    end
    else if(aurora_rst_cnt[17]) begin
        aurora_rst_cnt  <= aurora_rst_cnt;
        aurora_rst      <= 'b0;
    end
    else begin
        aurora_rst_cnt  <= aurora_rst_cnt + 'd1;
        aurora_rst      <= 'b1;
    end
end


endmodule