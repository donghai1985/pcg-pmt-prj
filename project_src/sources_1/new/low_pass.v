`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: zas
// Engineer: songyuxin
// 
// Create Date: 2024/5/8
// Design Name: PCG
// Module Name: low_pass
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

module low_pass #(
    parameter                                   TCQ                 = 0.1   ,
    parameter                                   LP_DEPTH            = 8     ,
    parameter                                   DATA_WIDTH          = 16    
)(
    input                                       clk_i                   ,
    input                                       rst_i                   ,

    input                                       laser_vld_i             ,
    input       [DATA_WIDTH-1:0]                laser_data_i            ,

    output                                      lp_laser_vld_o          ,
    output      [DATA_WIDTH-1:0]                lp_laser_data_o         
);
//////////////////////////////////////////////////////////////////////////////////
// *********** Define Parameter Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
localparam                                      LP_DEPTH_WID        = $clog2(LP_DEPTH);
genvar i;

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Register Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
reg     [DATA_WIDTH-1:0]                        buff_mem    [0:LP_DEPTH-2];
reg     [LP_DEPTH_WID+DATA_WIDTH-1:0]           sum_mem             = 'd0;

reg     [LP_DEPTH_WID-1:0]                      sum_cnt             = 'd0;
reg                                             laser_vld_d0        = 'd0;
reg                                             laser_vld_d1        = 'd0;
reg                                             laser_vld_d2        = 'd0;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Wire Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
wire                                            sum_en                  ;

wire                                            s_axis_divisor_tready   ;
wire                                            s_axis_dividend_tready  ;
wire                                            m_axis_dout_tvalid      ;
wire    [32-1:0]                                m_axis_dout_tdata       ;



//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Instance Module
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Logic Design
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
reg     [LP_DEPTH_WID-1:0]                      mem_wr_addr             = 'd0;

always @(posedge clk_i) begin
    if(rst_i)
        mem_wr_addr <= #TCQ 'd0;
    else if(laser_vld_i)begin
        if(mem_wr_addr == LP_DEPTH-2)
            mem_wr_addr <= #TCQ 'd0;
        else 
            mem_wr_addr <= #TCQ mem_wr_addr + 1;
    end
end

wire  [LP_DEPTH_WID-1:0]    mem_rd_addr = mem_wr_addr;

initial begin
    buff_mem[0] = #TCQ 'd0;
    buff_mem[1] = #TCQ 'd0;
    buff_mem[2] = #TCQ 'd0;
    buff_mem[3] = #TCQ 'd0;
    buff_mem[4] = #TCQ 'd0;
    buff_mem[5] = #TCQ 'd0;
    buff_mem[6] = #TCQ 'd0;
end

always @(posedge clk_i) begin
    if(laser_vld_i)
        buff_mem[mem_wr_addr] <= #TCQ laser_data_i;
end

always @(posedge clk_i) begin
    laser_vld_d0 <= #TCQ laser_vld_i;
    laser_vld_d1 <= #TCQ laser_vld_d0;
    laser_vld_d2 <= #TCQ laser_vld_d1;
end

always @(posedge clk_i) begin
    if(rst_i)
        sum_mem <= #TCQ 'd0;
    else if(laser_vld_i)
        sum_mem <= #TCQ sum_mem - buff_mem[mem_rd_addr] + laser_data_i;
end


reg [24-1:0]            low_pass_dividend = 'd0;
reg [8-1:0]             low_pass_divisor  = 'd0;
always @(posedge clk_i) begin
    low_pass_dividend <= #TCQ {{(24-LP_DEPTH_WID+DATA_WIDTH){1'b0}},sum_mem};
    low_pass_divisor  <= #TCQ LP_DEPTH;
end


low_pass_divider low_pass_divider_inst (
    .aclk                     ( clk_i                     ),  // input wire aclk
    .s_axis_divisor_tvalid    ( laser_vld_d1              ),  // input wire s_axis_divisor_tvalid
    // .s_axis_divisor_tready    ( s_axis_divisor_tready     ),  // output wire s_axis_divisor_tready
    .s_axis_divisor_tdata     ( low_pass_divisor          ),  // input wire [7 : 0] s_axis_divisor_tdata
    .s_axis_dividend_tvalid   ( laser_vld_d1              ),  // input wire s_axis_dividend_tvalid
    // .s_axis_dividend_tready   ( s_axis_dividend_tready    ),  // output wire s_axis_dividend_tready
    .s_axis_dividend_tdata    ( low_pass_dividend         ),  // input wire [23 : 0] s_axis_dividend_tdata
    .m_axis_dout_tvalid       ( m_axis_dout_tvalid        ),  // output wire m_axis_dout_tvalid
    .m_axis_dout_tdata        ( m_axis_dout_tdata         )   // output wire [31 : 0] m_axis_dout_tdata
);

assign lp_laser_vld_o  = m_axis_dout_tvalid;
assign lp_laser_data_o = m_axis_dout_tdata[23:8] ;

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    
endmodule