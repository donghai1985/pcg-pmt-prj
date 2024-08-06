`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: zas
// Engineer: songyuxin
// 
// Create Date: 2024/5/11
// Design Name: PCG
// Module Name: FIR_unit
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

module FIR_unit #(
    parameter                                   TCQ                 = 0.1   ,
    parameter                                   FIR_TAP_WIDTH       = 32    ,
    parameter                                   FIR_TAP_NUM         = 51    ,
    parameter                                   SAXI_DATA_WIDTH     = 16    ,
    parameter                                   MAXI_DATA_WIDTH     = FIR_TAP_WIDTH + SAXI_DATA_WIDTH
)(
    input                                       clk_i                   ,
    input                                       rst_i                   ,

    input                                       fir_tap_vld_i           ,
    input       [10-1:0]                        fir_tap_addr_i          ,
    input       [FIR_TAP_WIDTH-1:0]             fir_tap_data_i          ,
    input                                       ds_laser_lost_i         ,
    output                                      fir_ds_lost_o           ,

    input       [SAXI_DATA_WIDTH-1:0]           s_axis_fir_tdata_i      ,
    input                                       s_axis_fir_tvalid_i     ,
    input                                       m_axis_fir_tready_i     ,
    output                                      m_axis_fir_tvalid_o     ,
    output                                      s_axis_fir_tready_o     ,
    output      [MAXI_DATA_WIDTH-1:0]           m_axis_fir_tdata_o      
);
//////////////////////////////////////////////////////////////////////////////////
// *********** Define Parameter Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
localparam                      FIR_DOUT_WIDTH  = FIR_TAP_WIDTH + SAXI_DATA_WIDTH;
localparam                      STREAM_DELAY    = FIR_TAP_NUM/2-1;

genvar i,j;

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Register Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
reg     [FIR_TAP_WIDTH-1:0]     fir_tap_mem     [0:FIR_TAP_NUM-1];
reg     [SAXI_DATA_WIDTH-1:0]   buff_mem        [0:FIR_TAP_NUM-1];
(* use_dsp = "yes" *)reg     [FIR_DOUT_WIDTH-1:0]    mult_mem        [0:FIR_TAP_NUM-1];

reg     [FIR_DOUT_WIDTH-1:0]    mult_mem_temp   [0:FIR_TAP_NUM/2];
reg     [FIR_DOUT_WIDTH-1:0]    sum_mem_temp_d  [0:STREAM_DELAY-1][0:STREAM_DELAY-1];
reg     [FIR_DOUT_WIDTH-1:0]    sum_mem         [0:STREAM_DELAY];

reg     [3-1:0]                 enable_fir_d        = 'd0;
reg                             s_axis_fir_tready   = 'd0;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Wire Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
wire                            enable_fir;
wire                            enable_fir_delay;

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Instance Module
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
reg_delay #(
    .DATA_WIDTH         ( 2                                             ),
    .DELAY_NUM          ( STREAM_DELAY+2                                )
)reg_delay_inst(
    .clk_i              ( clk_i                                         ),
    .src_data_i         ( {enable_fir,ds_laser_lost_i && enable_fir}    ),
    .delay_data_o       ( {m_axis_fir_tvalid_o,fir_ds_lost_o}           )
);

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Logic Design
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
assign enable_fir = s_axis_fir_tvalid_i && s_axis_fir_tready;

// This loop controls tready & tvalid signals on AXI Stream interface 
always @ (posedge clk_i)begin
    if(rst_i || m_axis_fir_tready_i == 1'b0)begin
        s_axis_fir_tready <= #TCQ 1'b0;
    end
    else begin
        s_axis_fir_tready <= #TCQ 1'b1;
    end
end

// update tap parameter mem
always @(posedge clk_i) begin
    if(fir_tap_vld_i)
        fir_tap_mem[fir_tap_addr_i] <= #TCQ fir_tap_data_i;
end

generate
    for(i=0;i<FIR_TAP_NUM;i=i+1) begin
        if(i==0)begin: FIRST_BUFFER_REGISTER
            always @(posedge clk_i) begin
                if(rst_i || m_axis_fir_tready_i == 1'b0)
                    buff_mem[0] <= #TCQ 'd0;
                else if(enable_fir)
                    buff_mem[0] <= #TCQ s_axis_fir_tdata_i;
            end
        end
        else begin: OTHER_BUFFER_REGISTER 
            always @(posedge clk_i) begin
                if(rst_i || m_axis_fir_tready_i == 1'b0)
                    buff_mem[i] <= #TCQ 'd0;
                else if(enable_fir)
                    buff_mem[i] <= #TCQ buff_mem[i-1];
            end
        end
    end
endgenerate

generate
    for(i=0;i<FIR_TAP_NUM;i=i+1) begin: FIRST_MULT_REGISTER
        always @(posedge clk_i) begin
            if(enable_fir)
                mult_mem[i]    <= #TCQ fir_tap_mem[FIR_TAP_NUM-1 - i] * buff_mem[i];
        end
    end
endgenerate

generate
    for(i=0;i<FIR_TAP_NUM/2;i=i+1) begin: REDUCE_REGISTER
        always @(posedge clk_i) begin
            mult_mem_temp[i]    <= #TCQ mult_mem[i] + mult_mem[FIR_TAP_NUM-1-i];
        end
    end

    always @(posedge clk_i) begin
        mult_mem_temp[FIR_TAP_NUM/2] <= #TCQ mult_mem[FIR_TAP_NUM/2];
    end
endgenerate

generate
    for(i=0;i<STREAM_DELAY;i=i+1) begin: STREAM_DELAY_GENERATE
        for(j=0;j<i+1;j=j+1)begin
            if(j==0)begin
                always @(posedge clk_i) begin
                    sum_mem_temp_d[i][0]    <= #TCQ mult_mem_temp[i+2];
                end
            end
            else begin
                always @(posedge clk_i) begin
                    sum_mem_temp_d[i][j]    <= #TCQ sum_mem_temp_d[i][j-1];
                end
            end
        end
    end
endgenerate

generate
    for(i=0;i<STREAM_DELAY+1;i=i+1) begin: SUM_MEM_GENERATE
        if(i==0)begin
            always @(posedge clk_i) begin
                sum_mem[0] <= #TCQ mult_mem_temp[0] + mult_mem_temp[1];
            end
        end
        else begin
            always @(posedge clk_i) begin
                sum_mem[i] <= #TCQ sum_mem[i-1] + sum_mem_temp_d[i-1][i-1];
            end
        end
    end
endgenerate


assign m_axis_fir_tdata_o  = sum_mem[STREAM_DELAY];
assign s_axis_fir_tready_o = s_axis_fir_tready;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    
endmodule