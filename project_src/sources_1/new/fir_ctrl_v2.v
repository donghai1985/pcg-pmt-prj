`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: zas
// Engineer: songyuxin
// 
// Create Date: 2024/5/11
// Design Name: PCG
// Module Name: fir_ctrl_v2
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
`define FIR_LP

module fir_ctrl_v2 #(
    parameter                                   TCQ                 = 0.1   ,
    parameter                                   FIR_TAP_WIDTH       = 32    ,
    parameter                                   FIR_TAP_NUM         = 51    ,
    parameter                                   DATA_WIDTH          = 16    
)(
    input                                       clk_i                   ,
    input                                       rst_i                   ,

    input                                       laser_start_i           ,
    input                                       laser_fir_upmode_i      ,
    input                                       laser_fir_en_i          ,
    
    input                                       fir_tap_vld_i           ,
    input       [10-1:0]                        fir_tap_addr_i          ,
    input       [FIR_TAP_WIDTH-1:0]             fir_tap_data_i          ,
    input       [32-1:0]                        fir_ds_num_i            ,

    input                                       acc_flag_i              ,
    input                                       zero_flag_i             ,
    input                                       laser_vld_i             ,
    input       [16-1:0]                        laser_data_i            ,

    output                                      fir_acc_flag_o          ,
    output                                      fir_zero_flag_o         ,
    output                                      fir_laser_vld_o         ,
    output      [16-1:0]                        fir_laser_data_o        
);
//////////////////////////////////////////////////////////////////////////////////
// *********** Define Parameter Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Register Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
reg                                 fir_zero_flag           = 'd0;
reg                                 fir_acc_flag            = 'd0;
reg                                 fir_upmode_sel          = 'd0;
reg                                 fir_laser_vld           = 'd0; 
reg     [16-1:0]                    fir_laser_data          = 'd0;

reg     [2-1:0]                     cache_bram_din          = 'd0;
reg     [14-1:0]                    cache_bram_waddr        = 'd0;
reg     [14-1:0]                    fir_cache_num           = 'd0;
reg                                 fir_acc_flag_d          = 'd0;
reg                                 fir_zero_flag_d         = 'd0;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Wire Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
wire                                m_axis_fir_tvalid       ;
wire    [16+32-1:0]                 m_axis_fir_tdata        ;

wire    [14-1:0]                    cache_bram_raddr        ;
wire    [2-1:0]                     cache_bram_dout         ;
wire                                lp_laser_vld            ;
wire    [16-1:0]                    lp_laser_data           ;

wire    [16-1:0]                    laser_raw_data_d        ;
wire                                ds_laser_lost           ;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Instance Module
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
`ifdef FIR_LP
fir_low_pass #(
    .DATA_WIDTH                 ( 16                            )
)fir_low_pass_inst (
    .clk_i                      ( clk_i                         ),
    .rst_i                      ( rst_i                         ),
    .laser_start_i              ( laser_start_i                 ),
    .fir_down_sample_num_i      ( fir_ds_num_i[8-1:0]           ),
    .laser_vld_i                ( laser_vld_i                   ),
    .laser_data_i               ( laser_data_i                  ),

    .lp_laser_vld_o             ( lp_laser_vld                  ),
    .lp_laser_data_o            ( lp_laser_data                 )
);
`else
assign lp_laser_vld  = laser_vld_i ;
assign lp_laser_data = laser_data_i;
`endif // FIR_LP

FIR_unit_v3 #(
    .FIR_TAP_WIDTH              ( FIR_TAP_WIDTH                 ),
    .FIR_TAP_NUM                ( FIR_TAP_NUM                   ),
    .SAXI_DATA_WIDTH            ( 16                            )
)FIR_unit_inst(
    .clk_i                      ( clk_i                         ),
    .rst_i                      ( rst_i                         ),

    .fir_tap_vld_i              ( fir_tap_vld_i                 ),
    .fir_tap_addr_i             ( fir_tap_addr_i                ),
    .fir_tap_data_i             ( fir_tap_data_i                ),
    .fir_down_sample_num_i      ( fir_ds_num_i[8-1:0]           ),

    .s_axis_fir_tdata_i         ( lp_laser_data                 ),
    .s_axis_fir_tvalid_i        ( lp_laser_vld                  ),
    .m_axis_fir_tready_i        ( 1'b1                          ),
    .m_axis_fir_tvalid_o        ( m_axis_fir_tvalid             ),
    .m_axis_fir_tdata_o         ( m_axis_fir_tdata              )
);


fir_cache_bit_ram fir_cache_bit_ram_inst (
    .clka                       ( clk_i                         ),  // input wire clka
    .wea                        ( laser_fir_en_i                ),  // input wire [0 : 0] wea
    .addra                      ( cache_bram_waddr              ),  // input wire [14 : 0] addra
    .dina                       ( cache_bram_din                ),  // input wire [1 : 0] dina
    .clkb                       ( clk_i                         ),  // input wire clkb
    .addrb                      ( cache_bram_raddr              ),  // input wire [14 : 0] addrb
    .doutb                      ( cache_bram_dout               )   // output wire [1 : 0] doutb
);

reg_delay #(
    .DATA_WIDTH                 ( 16                            ),
    .DELAY_NUM                  ( FIR_TAP_NUM+27                )  // FIR + low pass
)data_delay_inst(
    .clk_i                      ( clk_i                         ),
    .src_data_i                 ( laser_data_i                  ),
    .delay_data_o               ( laser_raw_data_d              )
);
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Logic Design
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
always @(posedge clk_i) begin
    if(~laser_fir_en_i)
        cache_bram_din <= #TCQ 'd0;
    else 
        cache_bram_din <= #TCQ {acc_flag_i,zero_flag_i};
end

always @(posedge clk_i) begin
    if(~laser_fir_en_i)
        cache_bram_waddr <= #TCQ 'd0;
    else if(laser_vld_i)
        cache_bram_waddr <= #TCQ cache_bram_waddr + 'd1;
end

always @(posedge clk_i) begin
    fir_cache_num <= #TCQ (fir_ds_num_i[7:0] + 1) * 25 + 51 + 27;
end

assign cache_bram_raddr = cache_bram_waddr - fir_cache_num;

always @(posedge clk_i) begin
    fir_acc_flag_d <= #TCQ cache_bram_dout[1];
    fir_zero_flag_d <= #TCQ cache_bram_dout[0];
end

always @(posedge clk_i) begin
    if(laser_fir_en_i)begin
        fir_acc_flag  <= #TCQ fir_acc_flag_d;
    end
    else begin
        fir_acc_flag  <= #TCQ acc_flag_i;
    end
end

always @(posedge clk_i) begin
    if(laser_fir_en_i)begin
        fir_zero_flag  <= #TCQ fir_zero_flag_d;
    end
    else begin
        fir_zero_flag  <= #TCQ zero_flag_i;
    end
end

always @(posedge clk_i) begin
    if(laser_fir_en_i && laser_fir_upmode_i)begin
        if(m_axis_fir_tvalid)
            fir_upmode_sel <= #TCQ ~fir_upmode_sel;
    end
    else 
        fir_upmode_sel <= #TCQ 'd0;
end

always @(posedge clk_i) begin
    if(laser_fir_en_i)begin
        if(fir_upmode_sel)
            fir_laser_data <= #TCQ laser_raw_data_d;
        else 
            fir_laser_data <= #TCQ m_axis_fir_tdata[16+32-1:32];
    end
    else begin
        fir_laser_data <= #TCQ laser_data_i;
    end
end

always @(posedge clk_i) begin
    if(laser_fir_en_i)
        fir_laser_vld <= #TCQ m_axis_fir_tvalid;
    else
        fir_laser_vld <= #TCQ laser_vld_i;
end

assign fir_zero_flag_o      = fir_zero_flag;
assign fir_acc_flag_o       = fir_acc_flag ;
assign fir_laser_vld_o      = fir_laser_vld;
assign fir_laser_data_o     = fir_laser_data;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    
endmodule