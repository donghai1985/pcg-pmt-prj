`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: zas
// Engineer: songyuxin
// 
// Create Date: 2024/5/15
// Design Name: PCG
// Module Name: dynamic_lowpass
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

module dynamic_lowpass #(
    parameter                                   TCQ                 = 0.1   ,
    parameter                                   DIS_MEM_DEPTH       = 32    ,
    parameter                                   DATA_WIDTH          = 16    
)(
    input                                       clk_i                   ,
    input                                       rst_i                   ,

    input                                       laser_start_i           ,
    input       [32-1:0]                        lowpass_para_data_i     ,  // down sample para : 0~19

    input                                       laser_vld_i             ,
    input       [DATA_WIDTH-1:0]                laser_data_i            ,

    output                                      lp_laser_vld_o          ,
    output      [DATA_WIDTH-1:0]                lp_laser_data_o         
);
//////////////////////////////////////////////////////////////////////////////////
// *********** Define Parameter Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
localparam                                      DIS_MEM_DEPTH_WID  = $clog2(DIS_MEM_DEPTH);
genvar i;

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Register Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
reg     [DATA_WIDTH-1:0]                        buff_mem        [0:DIS_MEM_DEPTH-1];
reg     [DIS_MEM_DEPTH_WID+DATA_WIDTH-1:0]      sum_mem         [0:DIS_MEM_DEPTH-2];

reg                                             laser_vld_d0        = 'd0;
reg                                             laser_vld_d1        = 'd0;
reg                                             laser_vld_d2        = 'd0;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Wire Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
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
generate
    for(i=0;i<DIS_MEM_DEPTH;i=i+1) begin
        if(i==0)begin: FIRST_BUFFER_REGISTER
            always @(posedge clk_i) begin
                if(rst_i || (~laser_start_i))
                    buff_mem[i] = #TCQ 'd0;
                else if(laser_vld_i)
                    buff_mem[i] = #TCQ laser_data_i;
            end
        end
        else begin: OTHER_BUFFER_REGISTER
            always @(posedge clk_i) begin
                if(rst_i || (~laser_start_i))
                    buff_mem[i] = #TCQ 'd0;
                else if(laser_vld_i)
                    buff_mem[i] <= #TCQ buff_mem[i-1];
            end
        end
    end
endgenerate

always @(posedge clk_i) begin
    laser_vld_d0 <= #TCQ laser_vld_i;
    laser_vld_d1 <= #TCQ laser_vld_d0;
    laser_vld_d2 <= #TCQ laser_vld_d1;
end

generate
    for(i=0;i<DIS_MEM_DEPTH;i=i+1) begin
        if(i==0)begin: FIRST_MEM_REGISTER
            always @(posedge clk_i) begin
                if(rst_i || (~laser_start_i))
                    sum_mem[0] <= #TCQ 'd0;
                else if(laser_vld_d0)
                    sum_mem[0] <= #TCQ buff_mem[0];
            end
        end
        else begin: OTHER_MEM_REGISTER
            always @(posedge clk_i) begin
                if(rst_i || (~laser_start_i))
                    sum_mem[i] <= #TCQ 'd0;
                else if(laser_vld_d0)
                    sum_mem[i] <= #TCQ sum_mem[i] +  buff_mem[0] - buff_mem[i+1];
            end
        end
    end
endgenerate

reg [24-1:0]            low_pass_dividend = 'd0;
reg [8-1:0]             low_pass_divisor  = 'd0;
always @(posedge clk_i) begin
    low_pass_dividend <= #TCQ {{(24-DIS_MEM_DEPTH_WID+DATA_WIDTH){1'b0}},sum_mem[lowpass_para_data_i]};
    low_pass_divisor  <= #TCQ lowpass_para_data_i + 1;
end


low_pass_divider low_pass_divider_inst (
    .aclk                     ( clk_i                     ),  // input wire aclk
    .s_axis_divisor_tvalid    ( laser_vld_d2              ),  // input wire s_axis_divisor_tvalid
    // .s_axis_divisor_tready    ( s_axis_divisor_tready     ),  // output wire s_axis_divisor_tready
    .s_axis_divisor_tdata     ( low_pass_divisor          ),  // input wire [7 : 0] s_axis_divisor_tdata
    .s_axis_dividend_tvalid   ( laser_vld_d2              ),  // input wire s_axis_dividend_tvalid
    // .s_axis_dividend_tready   ( s_axis_dividend_tready    ),  // output wire s_axis_dividend_tready
    .s_axis_dividend_tdata    ( low_pass_dividend         ),  // input wire [23 : 0] s_axis_dividend_tdata
    .m_axis_dout_tvalid       ( m_axis_dout_tvalid        ),  // output wire m_axis_dout_tvalid
    .m_axis_dout_tdata        ( m_axis_dout_tdata         )   // output wire [31 : 0] m_axis_dout_tdata
);

assign lp_laser_vld_o  = m_axis_dout_tvalid;
assign lp_laser_data_o = m_axis_dout_tdata[23:8] ;

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    
endmodule