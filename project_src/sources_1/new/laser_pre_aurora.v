`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: songyuxin
// 
// Create Date: 2024/05/17
// Design Name: PCG
// Module Name: laser_pre_aurora
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

module laser_pre_aurora #(
    parameter                   TCQ               = 0.1 
)(
    // clk & rst 
    input                       clk_i                       ,
    input                       rst_i                       ,
    input                       aurora_log_clk_i            ,

    // current track data
    input                       aurora_upmode_i             ,
    input                       laser_acc_flag_upmode_i     ,
    input                       acc_pre_result_i            ,
    input                       acc_curr_result_i           ,
    input                       laser_start_i               ,
    input                       laser_vld_i                 ,
    input                       laser_acc_flag_i            ,
    input   [16-1:0]            laser_data_i                ,
    input   [16-1:0]            laser_haze_data_i           ,
    input   [16-1:0]            laser_raw_data_i            ,
    input   [16-1:0]            laser_filter_acc_hub_i      ,

    // aurora interface
    input                       aurora_txen_i               ,
    output  [32-1:0]            aurora_txdata_o             ,
    output                      aurora_tx_emp_o             ,
    output  [11-1:0]            aurora_rd_data_count_o      
);

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Register Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
reg                             laser_start_d1              = 'd0;
reg                             aurora_tx_emp_d             = 'd0;
reg                             aurora_tx_clear_rd          = 'd0;

reg         [2-1:0]             aurora_sel                  = 'd0;
reg         [16-1:0]            aurora_data                 = 'd0;
reg                             aurora_vld                  = 'd0;
reg                             laser_start_d               = 'd0;
reg                             aurora_acc_flag             = 'd0;
reg                             aurora_acc_flag_dbg         = 'd0;
reg                             aurora_vld_dbg              = 'd0;
reg         [16-1:0]            aurora_data_dbg             = 'd0;
reg                             aurora_fifo_rst             = 'd0;
reg         [4-1:0]             aurora_fifo_rst_cnt         = 'hf;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Wire Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
wire        [16-1:0]            laser_raw_data                  ;
wire                            actu_out_vld                    ;
wire        [32-1:0]            actu_out_data                   ;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Instance Module
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
ddr3_to_aurora_fifo ddr3_to_aurora_fifo_inst(
    .rst                            ( rst_i || aurora_fifo_rst          ),
    .wr_clk                         ( clk_i                             ),
    .rd_clk                         ( aurora_log_clk_i                  ),
    .din                            ( actu_out_data                     ),
    .wr_en                          ( actu_out_vld                      ),
    .rd_en                          ( aurora_txen_i                     ),
    .dout                           ( aurora_txdata_o                   ),
    .empty                          ( aurora_tx_emp_o                   ),
    .rd_data_count                  ( aurora_rd_data_count_o            )
);

reg_delay #(
    .DATA_WIDTH                     ( 16                                ),
    .DELAY_NUM                      ( 110                               )
)reg_delay_inst(
    .clk_i                          ( clk_i                             ),
    .src_data_i                     ( laser_raw_data_i                  ),
    .delay_data_o                   ( laser_raw_data                    )
);
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Logic Design
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

always @(posedge clk_i) begin
    if(aurora_upmode_i && laser_start_i)begin
        if(aurora_sel=='d2 && laser_vld_i)
            aurora_sel <= #TCQ 'd0;
        else if(laser_vld_i)
            aurora_sel <= #TCQ aurora_sel + 1;
    end
    else 
        aurora_sel <= #TCQ 'd0;
end

always @(posedge clk_i) begin
    case(aurora_sel)
        'd0:aurora_data <= #TCQ laser_data_i;
        'd1:aurora_data <= #TCQ laser_haze_data_i;
        'd2:aurora_data <= #TCQ laser_filter_acc_hub_i;
        default:/*default*/;
    endcase
end

always @(posedge clk_i) begin
    aurora_vld <= #TCQ laser_vld_i && laser_start_i;
    aurora_acc_flag <= #TCQ laser_acc_flag_i;
end

always @(posedge clk_i) begin
    aurora_acc_flag_dbg <= #TCQ aurora_acc_flag;
end

always @(posedge clk_i) begin
    if(laser_acc_flag_upmode_i)begin
        aurora_vld_dbg  <= #TCQ aurora_vld;
        aurora_data_dbg <= #TCQ {aurora_data[15:2],acc_pre_result_i,acc_curr_result_i};
    end
    else begin
        aurora_vld_dbg  <= #TCQ aurora_vld;
        aurora_data_dbg <= #TCQ aurora_data;
    end

end

assign actu_out_vld  = aurora_vld_dbg;
assign actu_out_data = {aurora_acc_flag_dbg,15'h5a69,aurora_data_dbg[15:0]};


always @(posedge clk_i ) begin
    laser_start_d <= #TCQ laser_start_i;
end

always @(posedge clk_i) begin
    if(laser_start_d && (~laser_start_i))
        aurora_fifo_rst_cnt <= #TCQ 'd0;
    else if(~aurora_fifo_rst_cnt[3])
        aurora_fifo_rst_cnt <= #TCQ aurora_fifo_rst_cnt + 1;
end

always @(posedge clk_i) begin
    aurora_fifo_rst <= #TCQ (aurora_fifo_rst_cnt[3]==1'b0);
end

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


endmodule
