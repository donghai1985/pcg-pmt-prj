`timescale 1ns / 1ps
/////////////////////////////////////////////////////////////////////////////////
// Company: zas
// Engineer: songyuxin
// 
// Create Date: 2024/5/8
// Design Name: PCG
// Module Name: uniform_downsample
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
/////////////////////////////////////////////////////////////////////////////////

module uniform_downsample #(
    parameter                                   TCQ                 = 0.1   ,
    parameter                                   DATA_WIDTH          = 16    
)(
    input                                       clk_i                   ,
    input                                       rst_i                   ,

    input                                       ds_para_en_i            ,
    input       [32-1:0]                        ds_para_h_i             ,
    input       [32-1:0]                        ds_para_l_i             ,

    input                                       laser_start_i           ,
    input                                       acc_flag_i              ,
    input                                       zero_flag_i             ,
    input                                       laser_vld_i             ,
    input       [DATA_WIDTH-1:0]                laser_data_i            ,

    output                                      ds_acc_flag_o           ,
    output                                      ds_zero_flag_o          ,
    output                                      ds_laser_vld_o          ,
    output      [DATA_WIDTH-1:0]                ds_laser_data_o         ,
    output                                      ds_laser_lost_o         
);
/////////////////////////////////////////////////////////////////////////////////
// *********** Define Parameter Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>



//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

/////////////////////////////////////////////////////////////////////////////////
// *********** Define Register Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
reg     [2-1:0]             ds_mode                     = 'd0;
reg     [14-1:0]            ds_mult_power               = 'd0;
reg     [16-1:0]            ds_lost_num                 = 'd0;
reg     [16-1:0]            ds_lost_num_add             = 'd0;
reg     [16-1:0]            ds_supp_mult_power          = 'd0;
reg     [16-1:0]            ds_complete_lost_num        = 'd0;

reg                         lost_mode_state             = 'd0;
reg     [17-1:0]            lost_cnt                    = 'd0;
reg     [16-1:0]            lost_seq_cnt                = 'd0;
reg                         supp_lost_mode              = 'd0;

reg                         data_lost_flag              = 'd0;
reg                         update_para_en_d0           = 'd0;
reg                         laser_start_d0              = 'd0;

reg     [16-1:0]            seq_complete_cnt            = 'd0;
reg     [16-1:0]            ds_supp_mult_power_cnt      = 'd0;

reg                         ds_zero_flag                = 'd0;
reg                         ds_acc_flag                 = 'd0;
reg                         ds_laser_vld                = 'd0;
reg     [DATA_WIDTH-1:0]    ds_laser_data               = 'd0;
reg                         ds_laser_lost               = 'd0;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

/////////////////////////////////////////////////////////////////////////////////
// *********** Define Wire Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
// wire    [2-1:0]             ds_mode                     ;
// wire    [14-1:0]            ds_mult_power               ;
// wire    [16-1:0]            ds_lost_num                 ;
// wire    [16-1:0]            ds_lost_num_add             ;
// wire    [16-1:0]            ds_supp_mult_power          ;
// wire    [16-1:0]            ds_complete_lost_num        ;

wire                        update_para_en              ;
wire    [16-1:0]            lost_num                    ;
wire    [16-1:0]            lost_seq_num                ;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

/////////////////////////////////////////////////////////////////////////////////
// *********** Instance Module
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
always @(posedge clk_i) begin
    if(ds_para_en_i)begin
        ds_mode              <= #TCQ ds_para_h_i[31:30];
        ds_mult_power        <= #TCQ ds_para_h_i[29:16];
        ds_lost_num          <= #TCQ (ds_mode == 2'b10) ? ds_para_h_i[15:0] : 'd1;
        ds_lost_num_add      <= #TCQ (ds_mode == 2'b01) ? ds_para_h_i[15:0] : 'd1;
        ds_supp_mult_power   <= #TCQ ds_para_l_i[31:16];
        ds_complete_lost_num <= #TCQ ds_para_l_i[15:0];
    end
end

always @(posedge clk_i) update_para_en_d0   <= #TCQ update_para_en;
always @(posedge clk_i) laser_start_d0      <= #TCQ laser_start_i;

assign lost_num     = lost_mode_state + ds_mult_power;
assign lost_seq_num = (~lost_mode_state) ? ds_lost_num : ds_lost_num_add;

always @(posedge clk_i) begin
    if(update_para_en)begin
        lost_mode_state <= #TCQ ds_mode[0];
    end
    else begin 
        if(ds_mode == 'b00)
            lost_mode_state <= #TCQ 'd0;
        else if(supp_lost_mode)
            lost_mode_state <= #TCQ ds_mode[0];
        else if((lost_seq_cnt == lost_seq_num) && (lost_cnt == lost_num) && laser_vld_i)
            lost_mode_state <= #TCQ ~lost_mode_state;
    end
end

always @(posedge clk_i) begin
    if(update_para_en)begin
        lost_cnt <= #TCQ 'd1;
    end
    else if(laser_vld_i)begin
        if(lost_cnt == lost_num)
            lost_cnt <= #TCQ 'd1;
        else if(~lost_cnt[16])
            lost_cnt <= #TCQ lost_cnt + 1;
    end
end

always @(posedge clk_i) begin
    if(update_para_en)begin
        lost_seq_cnt <= #TCQ 'd1;
    end
    else if((lost_cnt == lost_num) && laser_vld_i)begin
        if(lost_seq_cnt == lost_seq_num)
            lost_seq_cnt <= #TCQ 'd1;
        else 
            lost_seq_cnt <= #TCQ lost_seq_cnt + 1;
    end
end

always @(posedge clk_i) begin
    if(update_para_en)begin
        seq_complete_cnt <= #TCQ 'd1;
    end
    else if((lost_cnt == lost_num) && (lost_seq_cnt == lost_seq_num) && laser_vld_i)begin
        if(seq_complete_cnt == ds_complete_lost_num)
            seq_complete_cnt <= #TCQ seq_complete_cnt;
        else 
            seq_complete_cnt <= #TCQ seq_complete_cnt + 1;
    end
end

always @(posedge clk_i) begin
    if(update_para_en)
        supp_lost_mode <= #TCQ 'd0;
    else if((lost_cnt == lost_num) && (lost_seq_cnt == lost_seq_num) && (seq_complete_cnt == ds_complete_lost_num) && laser_vld_i)
        supp_lost_mode <= #TCQ 'd1;
end

always @(posedge clk_i) begin
    if(update_para_en)
        ds_supp_mult_power_cnt <= #TCQ 'd1;
    else if((lost_cnt == lost_num) && supp_lost_mode && laser_vld_i)
        ds_supp_mult_power_cnt <= #TCQ ds_supp_mult_power_cnt + 'd1;
end

assign update_para_en = (~laser_start_d0 && laser_start_i)
                        || ((lost_cnt == lost_num) && supp_lost_mode && (ds_supp_mult_power_cnt == ds_supp_mult_power) && laser_vld_i)
                        || ((ds_complete_lost_num == 0) && (lost_cnt == lost_num) && (~lost_mode_state) && laser_vld_i)
                        || ds_para_en_i;


assign ds_data_lost_flag = (lost_cnt == lost_num) && laser_vld_i;

always @(posedge clk_i) begin
    ds_acc_flag  <= #TCQ acc_flag_i ;
    ds_zero_flag <= #TCQ zero_flag_i;
    ds_laser_vld <= #TCQ laser_vld_i;
    ds_laser_data <= #TCQ laser_data_i; 
    ds_laser_lost <= #TCQ (~ds_data_lost_flag) && laser_vld_i;
end

assign ds_acc_flag_o    = ds_acc_flag;
assign ds_zero_flag_o   = ds_zero_flag;
assign ds_laser_vld_o   = ds_laser_vld;
assign ds_laser_data_o  = ds_laser_data;
assign ds_laser_lost_o  = ds_laser_lost;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    
endmodule