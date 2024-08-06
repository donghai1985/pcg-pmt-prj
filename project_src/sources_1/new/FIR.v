`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: songyuxin
// 
// Create Date: 2023/6/8 
// Design Name:  
// Module Name: FIR
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

module FIR #(
    parameter                                   FIR_TAP_WIDTH   =   16,
    parameter                                   SAXI_DATA_WIDTH =   16,
    parameter                                   MAXI_DATA_WIDTH =   32,
    parameter                                   KEEP_WIDTH      =   4
)(
    input                                       clk_i               ,
    input                                       rst_i               ,
    input       signed  [SAXI_DATA_WIDTH-1:0]   s_axis_fir_tdata_i  , 
    input               [KEEP_WIDTH-1:0]        s_axis_fir_tkeep_i  ,
    input                                       s_axis_fir_tlast_i  ,
    input                                       s_axis_fir_tvalid_i ,
    input                                       m_axis_fir_tready_i ,
    output                                      m_axis_fir_tvalid_o ,
    output reg                                  s_axis_fir_tready_o  = 'd0,
    output reg                                  m_axis_fir_tlast_o   = 'd0,
    output reg          [KEEP_WIDTH-1:0]        m_axis_fir_tkeep_o   = 'hf,
    output wire signed  [MAXI_DATA_WIDTH-1:0]   m_axis_fir_tdata_o    // delay s_tdata_i 15 clk
);
//////////////////////////////////////////////////////////////////////////////////
// *********** Define Parameter Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
localparam                                      FIR_DOUT_WIDTH = FIR_TAP_WIDTH + SAXI_DATA_WIDTH;

// Taps for LPF running @ 1MSps 
localparam              [FIR_TAP_WIDTH-1:0]     tap0    = 'd10;  // twos(-0.0265 * 32768) = 0xFC9C
localparam              [FIR_TAP_WIDTH-1:0]     tap1    = 'd1 ;  // 0
localparam              [FIR_TAP_WIDTH-1:0]     tap2    = 'd20 ;  // 0.0441 * 32768 = 1445.0688 = 1445 = 0x05A5
localparam              [FIR_TAP_WIDTH-1:0]     tap3    = 'd3 ;  // 0
localparam              [FIR_TAP_WIDTH-1:0]     tap4    = 'd40 ;  // twos(-0.0934 * 32768) = 0xF40C
localparam              [FIR_TAP_WIDTH-1:0]     tap5    = 'd5 ;  // 0
localparam              [FIR_TAP_WIDTH-1:0]     tap6    = 'd6 ;  // 0.3139 * 32768 = 10285.8752 = 10285 = 0x282D
localparam              [FIR_TAP_WIDTH-1:0]     tap7    = 'd7 ;  // 0.5000 * 32768 = 16384 = 0x4000
localparam              [FIR_TAP_WIDTH-1:0]     tap8    = 'd8 ;  // 0.3139 * 32768 = 10285.8752 = 10285 = 0x282D
localparam              [FIR_TAP_WIDTH-1:0]     tap9    = 'd9 ;  // 0
localparam              [FIR_TAP_WIDTH-1:0]     tap10   = 'd10;  // twos(-0.0934 * 32768) = 0xF40C
localparam              [FIR_TAP_WIDTH-1:0]     tap11   = 'd11;  // 0
localparam              [FIR_TAP_WIDTH-1:0]     tap12   = 'd12;  // 0.0441 * 32768 = 1445.0688 = 1445 = 0x05A5
localparam              [FIR_TAP_WIDTH-1:0]     tap13   = 'd13;  // 0
localparam              [FIR_TAP_WIDTH-1:0]     tap14   = 'd14;  // twos(-0.0265 * 32768) = 0xFC9C


// localparam              [FIR_TAP_WIDTH-1:0]     tap0    = 'hFC9C;  // twos(-0.0265 * 32768) = 0xFC9C
// localparam              [FIR_TAP_WIDTH-1:0]     tap1    = 'h0000;  // 0
// localparam              [FIR_TAP_WIDTH-1:0]     tap2    = 'h05A5;  // 0.0441 * 32768 = 1445.0688 = 1445 = 0x05A5
// localparam              [FIR_TAP_WIDTH-1:0]     tap3    = 'h0000;  // 0
// localparam              [FIR_TAP_WIDTH-1:0]     tap4    = 'hF40C;  // twos(-0.0934 * 32768) = 0xF40C
// localparam              [FIR_TAP_WIDTH-1:0]     tap5    = 'h0000;  // 0
// localparam              [FIR_TAP_WIDTH-1:0]     tap6    = 'h282D;  // 0.3139 * 32768 = 10285.8752 = 10285 = 0x282D
// localparam              [FIR_TAP_WIDTH-1:0]     tap7    = 'h4000;  // 0.5000 * 32768 = 16384 = 0x4000
// localparam              [FIR_TAP_WIDTH-1:0]     tap8    = 'h282D;  // 0.3139 * 32768 = 10285.8752 = 10285 = 0x282D
// localparam              [FIR_TAP_WIDTH-1:0]     tap9    = 'h0000;  // 0
// localparam              [FIR_TAP_WIDTH-1:0]     tap10   = 'hF40C;  // twos(-0.0934 * 32768) = 0xF40C
// localparam              [FIR_TAP_WIDTH-1:0]     tap11   = 'h0000;  // 0
// localparam              [FIR_TAP_WIDTH-1:0]     tap12   = 'h05A5;  // 0.0441 * 32768 = 1445.0688 = 1445 = 0x05A5
// localparam              [FIR_TAP_WIDTH-1:0]     tap13   = 'h0000;  // 0
// localparam              [FIR_TAP_WIDTH-1:0]     tap14   = 'hFC9C;  // twos(-0.0265 * 32768) = 0xFC9C
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Register Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

// 15-tap FIR 
reg signed [SAXI_DATA_WIDTH-1:0] buff0, buff1, buff2, buff3, buff4, buff5, buff6, buff7, buff8, buff9, buff10, buff11, buff12, buff13, buff14;
(*use_dsp = "yes"*)reg signed [FIR_DOUT_WIDTH-1:0] acc0    = 'd0;
(*use_dsp = "yes"*)reg signed [FIR_DOUT_WIDTH-1:0] acc1    = 'd0;
(*use_dsp = "yes"*)reg signed [FIR_DOUT_WIDTH-1:0] acc2    = 'd0;
(*use_dsp = "yes"*)reg signed [FIR_DOUT_WIDTH-1:0] acc3    = 'd0;
(*use_dsp = "yes"*)reg signed [FIR_DOUT_WIDTH-1:0] acc4    = 'd0;
(*use_dsp = "yes"*)reg signed [FIR_DOUT_WIDTH-1:0] acc5    = 'd0;
(*use_dsp = "yes"*)reg signed [FIR_DOUT_WIDTH-1:0] acc6    = 'd0;
(*use_dsp = "yes"*)reg signed [FIR_DOUT_WIDTH-1:0] acc7    = 'd0;
(*use_dsp = "yes"*)reg signed [FIR_DOUT_WIDTH-1:0] acc8    = 'd0;
(*use_dsp = "yes"*)reg signed [FIR_DOUT_WIDTH-1:0] acc9    = 'd0;
(*use_dsp = "yes"*)reg signed [FIR_DOUT_WIDTH-1:0] acc10   = 'd0;
(*use_dsp = "yes"*)reg signed [FIR_DOUT_WIDTH-1:0] acc11   = 'd0;
(*use_dsp = "yes"*)reg signed [FIR_DOUT_WIDTH-1:0] acc12   = 'd0;
(*use_dsp = "yes"*)reg signed [FIR_DOUT_WIDTH-1:0] acc13   = 'd0;
(*use_dsp = "yes"*)reg signed [FIR_DOUT_WIDTH-1:0] acc14   = 'd0;

(*use_dsp = "yes"*)reg signed [FIR_DOUT_WIDTH-1:0] sum0  = 'd0;
(*use_dsp = "yes"*)reg signed [FIR_DOUT_WIDTH-1:0] sum1  = 'd0;
(*use_dsp = "yes"*)reg signed [FIR_DOUT_WIDTH-1:0] sum2  = 'd0;
(*use_dsp = "yes"*)reg signed [FIR_DOUT_WIDTH-1:0] sum3  = 'd0;
(*use_dsp = "yes"*)reg signed [FIR_DOUT_WIDTH-1:0] sum4  = 'd0;
(*use_dsp = "yes"*)reg signed [FIR_DOUT_WIDTH-1:0] sum5  = 'd0;
(*use_dsp = "yes"*)reg signed [FIR_DOUT_WIDTH-1:0] sum6  = 'd0;
(*use_dsp = "yes"*)reg signed [FIR_DOUT_WIDTH-1:0] sum7  = 'd0;
(*use_dsp = "yes"*)reg signed [FIR_DOUT_WIDTH-1:0] sum8  = 'd0;
(*use_dsp = "yes"*)reg signed [FIR_DOUT_WIDTH-1:0] sum9  = 'd0;
(*use_dsp = "yes"*)reg signed [FIR_DOUT_WIDTH-1:0] sum10 = 'd0;
(*use_dsp = "yes"*)reg signed [FIR_DOUT_WIDTH-1:0] sum11 = 'd0;
(*use_dsp = "yes"*)reg signed [FIR_DOUT_WIDTH-1:0] sum12 = 'd0;
(*use_dsp = "yes"*)reg signed [FIR_DOUT_WIDTH-1:0] sum13 = 'd0;
(*use_dsp = "yes"*)reg signed [FIR_DOUT_WIDTH-1:0] sum14 = 'd0;

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Wire Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
wire                            enable_fir;

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Instance Module
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
reg_delay #(
    .DATA_WIDTH         ( 1                         ),
    .DELAY_NUM          ( 15 + 8                    )
)reg_delay_inst(
    .clk_i              ( clk_i                     ),
    .src_data_i         ( enable_fir                ),
    .delay_data_o       ( m_axis_fir_tvalid_o       )
);



//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Logic Design
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
assign enable_fir = s_axis_fir_tvalid_i && s_axis_fir_tready_o;

// This loop controls tkeep signal on AXI Stream interface 
always @ (posedge clk_i)begin
    m_axis_fir_tkeep_o <= 'hf;
end
    
// This loop controls tlast signal on AXI Stream interface 
always @ (posedge clk_i)begin
    if (s_axis_fir_tlast_i == 1'b1)begin
        m_axis_fir_tlast_o <= 1'b1;
    end
    else begin
        m_axis_fir_tlast_o <= 1'b0;
    end
end

// This loop controls tready & tvalid signals on AXI Stream interface 
always @ (posedge clk_i)begin
    if(rst_i || m_axis_fir_tready_i == 1'b0)begin
        s_axis_fir_tready_o <= 1'b0;
    end
    else begin
        s_axis_fir_tready_o <= 1'b1;
    end
end

// Circular buffer  Multiply & Accumulate stages of FIR 
always @ (posedge clk_i)begin
    if (enable_fir)begin
        buff0 <= s_axis_fir_tdata_i;
        acc0 <= tap0 * buff0;
        buff1 <= buff0; 
        acc1 <= tap1 * buff1 ;  
        buff2 <= buff1; 
        acc2 <= tap2 * buff2;
        buff3 <= buff2; 
        acc3 <= tap3 * buff3;
        buff4 <= buff3; 
        acc4 <= tap4 * buff4;
             
    end
end

reg [16-1:0] acc0_d0 = 'd0;
reg [16-1:0] acc1_d0 = 'd0;
reg [16-1:0] acc1_d1 = 'd0;
reg [16-1:0] acc2_d0 = 'd0;
reg [16-1:0] acc2_d1 = 'd0;
reg [16-1:0] acc2_d2 = 'd0;
reg [16-1:0] acc3_d0 = 'd0;
reg [16-1:0] acc3_d1 = 'd0;
reg [16-1:0] acc3_d2 = 'd0;
reg [16-1:0] acc3_d3 = 'd0;
reg [16-1:0] acc4_d0 = 'd0;
reg [16-1:0] acc4_d1 = 'd0;
reg [16-1:0] acc4_d2 = 'd0;
reg [16-1:0] acc4_d3 = 'd0;
reg [16-1:0] acc4_d4 = 'd0;
always @(posedge clk_i) begin
    acc0_d0 <= acc0;
end
always @(posedge clk_i) begin
    acc1_d0 <= acc1;
    acc1_d1 <= acc1_d0;
end
always @(posedge clk_i) begin
    acc2_d0 <= acc2;
    acc2_d1 <= acc2_d0;
    acc2_d2 <= acc2_d1;
end
always @(posedge clk_i) begin
    acc3_d0 <= acc3;
    acc3_d1 <= acc3_d0;
    acc3_d2 <= acc3_d1;
    acc3_d3 <= acc3_d2;
end
always @(posedge clk_i) begin
    acc4_d0 <= acc4;
    acc4_d1 <= acc4_d0;
    acc4_d2 <= acc4_d1;
    acc4_d3 <= acc4_d2;
    acc4_d4 <= acc4_d3;
end

always @(posedge clk_i) begin
    sum0 <= acc0_d0;
    sum1 <= sum0 + acc1_d1;
    sum2 <= sum1 + acc2_d2;
    sum3 <= sum2 + acc3_d3;
    sum4 <= sum3 + acc4_d4;
end

assign m_axis_fir_tdata_o = sum4;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    
endmodule