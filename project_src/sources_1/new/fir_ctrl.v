`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: zas
// Engineer: songyuxin
// 
// Create Date: 2024/1/17
// Design Name: PCG
// Module Name: fir_ctrl
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
// `define FAST_SIMULATE

module fir_ctrl #(
    parameter                                   TCQ                 = 0.1   ,
    parameter                                   FIR_TAP_WIDTH       = 32    ,
    parameter                                   DATA_WIDTH          = 16    
)(
    input                                       clk_i                   ,
    input                                       rst_i                   ,

    input                                       laser_fir_upmode_i      ,
    input                                       laser_fir_en_i          ,
    input                                       laser_start_i           ,
    
    input                                       fir_tap_para_vld_i      ,
    input       [32-1:0]                        fir_tap_para_data_i     ,
    input                                       fir_tap_ready_i         ,
    output                                      fir_tap_para_ren_o      ,

    input                                       zero_flag_i             ,
    input                                       acc_flag_i              ,
    input                                       laser_vld_i             ,
    input       [16-1:0]                        laser_data_i            ,

    output                                      fir_zero_flag_o         ,
    output                                      fir_acc_flag_o          ,
    output                                      fir_laser_vld_o         ,
    output      [16-1:0]                        fir_laser_data_o        
);
//////////////////////////////////////////////////////////////////////////////////
// *********** Define Parameter Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
`ifdef FAST_SIMULATE
localparam                          FIR_TAP_NUM                 = 7;
`else
localparam                          FIR_TAP_NUM                 = 51;
`endif // FAST_SIMULATE

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Register Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
reg                                 fir_tap_vld                 = 'd0;
reg     [10-1:0]                    fir_tap_addr                = 'd0;
reg     [32-1:0]                    fir_tap_data                = 'd0;
reg     [8-1:0]                     fir_down_sample_num         = 'd0;

reg     [10-1:0]                    fir_tap_addr_d0             = 'd0;
reg     [10-1:0]                    fir_tap_addr_d1             = 'd0;
reg     [10-1:0]                    fir_tap_addr_d2             = 'd0;

reg                                 fir_tap_para_ren            = 'd0;
reg     [8-1:0]                     fir_tap_para_rcnt           = 'd0;
reg                                 fir_tap_update              = 'd0;

reg                                 laser_vld_temp              = 'd0;
reg                                 laser_vld_temp_d            = 'd0;
reg     [DATA_WIDTH-1:0]            laser_data_temp             = 'd0;
reg                                 fir_result_vld              = 'd0;
reg                                 fir_result_vld_d            = 'd0;
reg     [DATA_WIDTH-1:0]            fir_result_data             = 'd0;

reg                                 fir_zero_flag               = 'd0;
reg                                 fir_acc_flag                = 'd0;
reg                                 fir_upmode_sel              = 'd0;
reg                                 fir_laser_vld               = 'd0; 
reg     [16-1:0]                    fir_laser_data              = 'd0;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Wire Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
wire                                m_axis_fir_tvalid       ;
wire    [16+32-1:0]                 m_axis_fir_tdata        ;

wire                                lp_laser_vld            ;
wire    [16-1:0]                    lp_laser_data           ;
wire                                fir_zero_flag_d         ;
wire                                fir_acc_flag_d          ;

wire    [16-1:0]                    laser_raw_data_d        ;
wire                                fir_tap_update_d        ;
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
    .fir_down_sample_num_i      ( fir_down_sample_num           ),
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

    .fir_tap_vld_i              ( fir_tap_vld                   ),
    .fir_tap_addr_i             ( fir_tap_addr_d2               ),
    .fir_tap_data_i             ( fir_tap_data                  ),
    .fir_down_sample_num_i      ( fir_down_sample_num           ),

    .s_axis_fir_tdata_i         ( lp_laser_data                 ),
    .s_axis_fir_tvalid_i        ( lp_laser_vld                  ),
    .m_axis_fir_tready_i        ( 1'b1                          ),
    .m_axis_fir_tvalid_o        ( m_axis_fir_tvalid             ),
    .m_axis_fir_tdata_o         ( m_axis_fir_tdata              )
);

reg_delay #(
    .DATA_WIDTH                 ( 1+1                           ),
    .DELAY_NUM                  ( FIR_TAP_NUM/2+FIR_TAP_NUM+26  )  // FIR + low pass
)reg_delay_inst(
    .clk_i                      ( clk_i                         ),
    .src_data_i                 ( {zero_flag_i,acc_flag_i}      ),
    .delay_data_o               ( {fir_zero_flag_d,fir_acc_flag_d}  )
);

reg_delay #(
    .DATA_WIDTH                 ( 17                            ),
    .DELAY_NUM                  ( FIR_TAP_NUM+26                )  // FIR + low pass
)data_delay_inst(
    .clk_i                      ( clk_i                         ),
    .src_data_i                 ( {fir_tap_update,laser_data_i}         ),
    .delay_data_o               ( {fir_tap_update_d,laser_raw_data_d}   )
);

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Logic Design
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
reg laser_start_d = 'd0;
always @(posedge clk_i) begin
    laser_start_d <= #TCQ laser_start_i;
end

always @(posedge clk_i) begin
    if(laser_fir_en_i && ((~laser_start_d && laser_start_i) || zero_flag_i))
        fir_tap_para_ren <= #TCQ'd1;
    else if(fir_tap_para_rcnt == 'd126)  // DDR BURST LEN = 16, 16*256 = 128*32
        fir_tap_para_ren <= #TCQ 'd0;
end

always @(posedge clk_i) begin
    if(~fir_tap_para_ren)
        fir_tap_para_rcnt <= #TCQ 'd0;
    else if(fir_tap_para_vld_i)
        fir_tap_para_rcnt <= #TCQ fir_tap_para_rcnt + 1;
end


always @(posedge clk_i) begin
    if(laser_fir_en_i && ((~laser_start_d && laser_start_i) || zero_flag_i))
        fir_tap_update <= #TCQ 'd1;
    else if((fir_tap_addr == FIR_TAP_NUM + 1) && fir_tap_para_vld_i && fir_tap_update) // first para = track addr; second para = down sample num
        fir_tap_update <= #TCQ 'd0;
end

always @(posedge clk_i) begin
    if(fir_tap_update && fir_tap_para_vld_i && (fir_tap_addr=='d1)) // first para = track addr
        fir_down_sample_num <= #TCQ fir_tap_para_data_i;
end

always @(posedge clk_i) begin
    if(fir_tap_update && fir_tap_para_vld_i && (fir_tap_addr > 'd1))begin // first para = track addr
        fir_tap_vld     <= #TCQ 'd1;
        fir_tap_data    <= #TCQ fir_tap_para_data_i;
    end
    else begin
        fir_tap_vld     <= #TCQ 'd0;
    end
end

always @(posedge clk_i) begin
    if(~fir_tap_update)
        fir_tap_addr <= #TCQ 'd0;
    else if(fir_tap_para_vld_i)
        fir_tap_addr <= #TCQ fir_tap_addr + 1;
end

always @(posedge clk_i)begin
    fir_tap_addr_d0 <= #TCQ fir_tap_addr;
    fir_tap_addr_d1 <= #TCQ fir_tap_addr_d0;
    fir_tap_addr_d2 <= #TCQ fir_tap_addr_d1;
end

assign fir_tap_para_ren_o   = fir_tap_para_ren;
assign fir_zero_flag_o      = fir_zero_flag ;
assign fir_acc_flag_o       = fir_acc_flag  ;
assign fir_laser_vld_o      = fir_laser_vld;
assign fir_laser_data_o     = fir_laser_data;

always @(posedge clk_i) begin
    if(laser_fir_en_i)begin
        fir_zero_flag <= #TCQ fir_zero_flag_d;
        fir_acc_flag  <= #TCQ fir_acc_flag_d;
    end
    else begin
        fir_zero_flag <= #TCQ zero_flag_i;
        fir_acc_flag  <= #TCQ acc_flag_i;
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
        // if(fir_tap_update_d)
        //     fir_laser_data <= #TCQ laser_raw_data_d;
        // else 
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

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    
endmodule