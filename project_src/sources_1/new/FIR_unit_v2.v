`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: zas
// Engineer: songyuxin
// 
// Create Date: 2024/1/22
// Design Name: PCG
// Module Name: FIR_unit_v2
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

module FIR_unit_v2 #(
    parameter                                   TCQ                 = 0.1   ,
    parameter                                   FIR_TAP_WIDTH       = 32    ,
    parameter                                   SAXI_DATA_WIDTH     = 16    ,
    parameter                                   MAXI_DATA_WIDTH     = FIR_TAP_WIDTH + SAXI_DATA_WIDTH
)(
    input                                       clk_i                   ,
    input                                       rst_i                   ,

    input                                       fir_tap_vld_i           ,
    input       [10-1:0]                        fir_tap_addr_i          ,
    input       [FIR_TAP_WIDTH-1:0]             fir_tap_data_i          ,
    input       [10-1:0]                        fir_tap_num_i           ,

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
localparam                      FIR_TAP_NUM     = 90;
localparam                      FIR_TAP_REPEAT  = 10;

genvar i,j;

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Register Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
reg     [FIR_TAP_WIDTH-1:0]     fir_tap_mem     [0:FIR_TAP_NUM-1];
reg     [SAXI_DATA_WIDTH-1:0]   buff_mem        [0:FIR_TAP_NUM*FIR_TAP_REPEAT-1];
reg     [FIR_DOUT_WIDTH-1:0]    sum_mem         [0:FIR_TAP_NUM*FIR_TAP_REPEAT-1];
reg     [FIR_DOUT_WIDTH-1:0]    sum_delay_mem   [0:FIR_TAP_NUM*FIR_TAP_REPEAT-1];

reg                             s_axis_fir_tready   = 'd0;
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
    .DATA_WIDTH         ( 1                             ),
    .DELAY_NUM          ( FIR_TAP_NUM*FIR_TAP_REPEAT+1  )
)reg_delay_inst(
    .clk_i              ( clk_i                         ),
    .src_data_i         ( enable_fir                    ),
    .delay_data_o       ( m_axis_fir_tvalid_o           )
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
generate
    for(i=0;i<FIR_TAP_NUM;i=i+1) begin: UPDATE_TAP_PARA
        always @(posedge clk_i) begin
            if(rst_i)
                fir_tap_mem[i] <= #TCQ 'd0;
            else if(fir_tap_vld_i && fir_tap_addr_i==i)
                fir_tap_mem[i] <= #TCQ fir_tap_data_i;
        end
    end
endgenerate

generate
    for(i=0;i<FIR_TAP_NUM*FIR_TAP_REPEAT;i=i+1) begin
        if(i==0)begin: FIRST_BUFFER_REGISTER
            always @(*) begin
                buff_mem[i] = #TCQ s_axis_fir_tdata_i;
            end
        end
        else begin: OTHER_BUFFER_REGISTER 
            always @(posedge clk_i) begin
                if(enable_fir)
                    buff_mem[i] <= #TCQ buff_mem[i-1];
            end
        end
    end
endgenerate

// always @(posedge clk_i) begin
//     if(enable_fir)begin
//         sum_mem[0]          <= #TCQ sum_delay_mem[0];

//         sum_mem[1]          <= #TCQ sum_delay_mem[1] + sum_mem[0];

//         sum_mem[2]          <= #TCQ sum_delay_mem[2] + sum_mem[1];

//         sum_mem[3]          <= #TCQ sum_delay_mem[3] + sum_mem[2];

//         sum_mem[4]          <= #TCQ sum_delay_mem[4] + sum_mem[3];

//         sum_mem[5]          <= #TCQ sum_delay_mem[5] + sum_mem[4];

//         sum_mem[6]          <= #TCQ sum_delay_mem[6] + sum_mem[5];

//         sum_mem[7]          <= #TCQ sum_delay_mem[7] + sum_mem[6];

//         sum_mem[8]          <= #TCQ sum_delay_mem[8] + sum_mem[7];

//         sum_mem[9]          <= #TCQ sum_delay_mem[9] + sum_mem[8];
//     end
// end

// always @(posedge clk_i) begin
//     if(enable_fir)begin
//         sum_delay_mem[0]    <= #TCQ fir_tap_mem[0] * buff_mem[0];

//         sum_delay_mem[1]    <= #TCQ sum_delay_mem[0];

//         sum_delay_mem[2]    <= #TCQ sum_delay_mem[1];

//         sum_delay_mem[3]    <= #TCQ sum_delay_mem[2];

//         sum_delay_mem[4]    <= #TCQ sum_delay_mem[3];

//         sum_delay_mem[5]    <= #TCQ fir_tap_mem[1] * buff_mem[5];

//         sum_delay_mem[6]    <= #TCQ sum_delay_mem[5];

//         sum_delay_mem[7]    <= #TCQ sum_delay_mem[6];

//         sum_delay_mem[8]    <= #TCQ sum_delay_mem[7];

//         sum_delay_mem[9]    <= #TCQ sum_delay_mem[8];
//     end
// end


generate
    for(i=0;i<FIR_TAP_NUM;i=i+1) begin
        for(j=0;j<FIR_TAP_REPEAT;j=j+1) begin
            if((i==0) && (j==0))begin: FIRST_SUM_REGISTER
                always @(posedge clk_i) begin
                    if(enable_fir)begin
                        (*use_dsp = "yes"*)sum_delay_mem[0]    <= #TCQ fir_tap_mem[0] * buff_mem[0];
                        sum_mem[0]          <= #TCQ sum_delay_mem[0];
                    end
                end
            end
            else if((i!=0) && (j==0))begin: MULT_SUM_REGISTER
                always @(posedge clk_i) begin
                    if(enable_fir)begin
                        (*use_dsp = "yes"*)sum_delay_mem[i*FIR_TAP_REPEAT + j]  <= #TCQ fir_tap_mem[i] * buff_mem[i*FIR_TAP_REPEAT];
                        sum_mem[i*FIR_TAP_REPEAT + j]        <= #TCQ sum_delay_mem[i*FIR_TAP_REPEAT + j] + sum_mem[i*FIR_TAP_REPEAT + j - 1];
                    end
                end
            end
            else begin: OTHER_SUM_REGISTER
                always @(posedge clk_i) begin
                    if(enable_fir)begin
                        sum_delay_mem[i*FIR_TAP_REPEAT + j]  <= #TCQ sum_delay_mem[i*FIR_TAP_REPEAT + j - 1];
                        sum_mem[i*FIR_TAP_REPEAT + j]        <= #TCQ sum_delay_mem[i*FIR_TAP_REPEAT + j] + sum_mem[i*FIR_TAP_REPEAT + j - 1];
                    end
                end
            end
        end
    end
endgenerate

wire [10-1:0] fir_tap_vld_num = fir_tap_num_i[10-1:0];
assign m_axis_fir_tdata_o  = sum_mem[fir_tap_vld_num];
assign s_axis_fir_tready_o = s_axis_fir_tready;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    
endmodule