`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: zas
// Engineer: songyuxin
// 
// Create Date: 2023/12/27
// Design Name: PCG
// Module Name: particle_align
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


module pre_laser_align #(
    parameter                       TCQ               = 0.1 ,
    parameter                       DATA_WIDTH        = 32  
)(
    // clk & rst 
    input                           clk_i                       ,
    input                           rst_i                       ,

    input   [16-1:0]                circle_lose_num_i           ,  // align 需要丢点的起始间隔
    input   [16-1:0]                circle_lose_num_delta_i     ,  // align 匀线速度期间每圈丢点的差
    input   [16-1:0]                uniform_circle_i            ,  // 匀角速度运动的位置

    output  [14-1:0]                pre_track_para_addr_o       ,
    input   [16-1:0]                pre_track_para_data_i       ,

    input                           laser_start_i               ,
    input                           encode_zero_flag_i          ,
    input                           laser_vld_i                 ,
    input   [DATA_WIDTH-1:0]        laser_data_i                ,

    input                           pre_laser_rd_ready_i        ,
    output                          pre_laser_rd_seq_o          ,
    input   [DATA_WIDTH+32-1:0]     pre_laser_rd_data_i         ,

    output                          pre_laser_vld_o             ,
    output  [DATA_WIDTH+32-1:0]     pre_laser_data_o            ,
    output                          actu_laser_vld_o            ,
    output  [DATA_WIDTH-1:0]        actu_laser_data_o           
);

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Register Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
reg                                 pre_laser_flag          = 'd0;

reg         [16-1:0]                circle_lose_num         = 'd0;
reg         [16-1:0]                circle_lose_num_delta   = 'd0;
reg         [16-1:0]                uniform_circle_num      = 'd0;
reg         [16-1:0]                uniform_circle_cnt      = 'd0;
reg         [16-1:0]                circle_lose_cnt         = 'd0;

reg         [14-1:0]                pre_track_para_addr     = 'd0;
reg         [16-1:0]                facula_cache_d          = 'd0;
reg         [16-1:0]                first_cache_cnt         = 'd0;
reg                                 encode_zero_flag_d0     = 'd0;
reg                                 encode_zero_flag_d1     = 'd0;
reg         [16-1:0]                delta_facula_cache      = 'd0;
reg         [16-1:0]                delta_cache_sum         = 'd0;

reg                                 lose_flag               = 'd0;
reg                                 pre_laser_rd_seq        = 'd0;
reg                                 pre_laser_rd_seq_vld    = 'd0;
reg                                 pre_laser_rd_vld        = 'd0;

reg                                 actu_laser_vld_d0       = 'd0;
reg         [DATA_WIDTH-1:0]        actu_laser_data_d0      = 'd0;
reg                                 actu_laser_vld_d1       = 'd0;
reg         [DATA_WIDTH-1:0]        actu_laser_data_d1      = 'd0;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Wire Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
wire        [6-1:0]                 down_sample_rate    ;
wire        [10-1:0]                filter_cache_num    ;
wire        [16-1:0]                facula_cache        ;
wire                                facula_cache_flag   ;
wire                                pre_facula_rd       ;
wire                                uniform_flag        ;

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Logic Design
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
// read pre track facula cache
always @(posedge clk_i) begin
    if(~pre_laser_flag)
        pre_track_para_addr <= #TCQ 'd0;
    else if(encode_zero_flag_i)
        pre_track_para_addr <= #TCQ pre_track_para_addr + 1;
end

assign down_sample_rate = pre_track_para_data_i[15:10];
assign filter_cache_num = pre_track_para_data_i[9:0];

assign pre_facula_rd        = laser_start_i && (~pre_laser_flag) && (first_cache_cnt < facula_cache);
assign facula_cache         = down_sample_rate * filter_cache_num;
assign facula_cache_flag    = (|delta_cache_sum[15:1]);

// read pre track in advance, one facula data 
always @(posedge clk_i) begin
    if(~laser_start_i)
        first_cache_cnt <= #TCQ 'd0;
    else if(pre_laser_rd_ready_i && pre_facula_rd)
        first_cache_cnt <= #TCQ first_cache_cnt + 2;
end
 
always @(posedge clk_i) begin
    facula_cache_d      <= #TCQ facula_cache;
end

always @(posedge clk_i) begin
    encode_zero_flag_d0 <= #TCQ encode_zero_flag_i;
    encode_zero_flag_d1 <= #TCQ encode_zero_flag_d0;
end

always @(posedge clk_i) begin
    if(encode_zero_flag_d0)
        delta_facula_cache <= #TCQ facula_cache_d - facula_cache;
end

always @(posedge clk_i) begin
    if(~laser_start_i)
        delta_cache_sum <= #TCQ 'd0;
    else if(encode_zero_flag_d1)
        delta_cache_sum <= #TCQ delta_facula_cache + delta_cache_sum;
    else if(pre_laser_flag && facula_cache_flag && (~laser_vld_i) && (~lose_flag))
        delta_cache_sum <= #TCQ delta_cache_sum - 'd2;
end


assign uniform_flag = uniform_circle_cnt == uniform_circle_num;

always @(posedge clk_i) begin
    if(laser_start_i)begin
        if(encode_zero_flag_i)
            pre_laser_flag <= #TCQ 'd1;
    end
    else 
        pre_laser_flag <= #TCQ 'd0;
end

always @(posedge clk_i) begin
    if(~pre_laser_flag)
        circle_lose_num <= #TCQ circle_lose_num_i;
    else if(uniform_flag)
        circle_lose_num <= #TCQ 'd0;
    else if(encode_zero_flag_i)
        circle_lose_num <= #TCQ circle_lose_num - circle_lose_num_delta;
end

always @(posedge clk_i) begin
    if(~pre_laser_flag)begin
        circle_lose_num_delta <= #TCQ circle_lose_num_delta_i;
        uniform_circle_num    <= #TCQ uniform_circle_i       ;
    end
end

always @(posedge clk_i) begin
    if(pre_laser_flag)begin
        if(encode_zero_flag_i && (~uniform_flag))
            uniform_circle_cnt <= #TCQ uniform_circle_cnt + 1;
    end
    else 
        uniform_circle_cnt <= #TCQ 'd0;
end

always @(posedge clk_i) begin
    if(pre_laser_flag)begin
        if(circle_lose_cnt == circle_lose_num - 1)
            circle_lose_cnt <= #TCQ 'd0;
        else 
            circle_lose_cnt <= #TCQ circle_lose_cnt + 1;
    end
    else 
        circle_lose_cnt <= #TCQ 'd0;
end

always @(posedge clk_i) begin
    if(pre_laser_flag)begin
        if(circle_lose_num == 'd0)
            lose_flag <= #TCQ 'd0;
        else if(circle_lose_cnt == circle_lose_num - 1)
            lose_flag <= #TCQ 'd1;
        else if(lose_flag && (~laser_vld_i))
            lose_flag <= #TCQ 'd0;
    end
    else 
        lose_flag <= #TCQ 'd0;
end

always @(posedge clk_i) begin
    if(laser_start_i)begin
        if(~pre_laser_flag)begin
            if(pre_laser_rd_ready_i && pre_facula_rd)
                pre_laser_rd_seq <= #TCQ 'd1;
            else 
                pre_laser_rd_seq <= #TCQ 'd0;
        end
        else begin
            if(laser_vld_i)
                pre_laser_rd_seq <= #TCQ 'd1;
            else if(lose_flag)
                pre_laser_rd_seq <= #TCQ 'd1;
            else if(facula_cache_flag)
                pre_laser_rd_seq <= #TCQ 'd1;
            else 
                pre_laser_rd_seq <= #TCQ 'd0;
        end
    end
    else 
        pre_laser_rd_seq <= #TCQ 'd0;
end

always @(posedge clk_i) begin
    if(pre_laser_flag)begin
        if(laser_vld_i)
            pre_laser_rd_seq_vld <= #TCQ 'd1;
        else 
            pre_laser_rd_seq_vld <= #TCQ 'd0;
    end
    else 
        pre_laser_rd_seq_vld <= #TCQ 'd0;
end

always @(posedge clk_i) begin
    pre_laser_rd_vld <= #TCQ pre_laser_rd_seq_vld;
end

always @(posedge clk_i) begin
    actu_laser_vld_d0  <= #TCQ laser_vld_i ;
    actu_laser_data_d0 <= #TCQ laser_data_i;
    actu_laser_vld_d1  <= #TCQ actu_laser_vld_d0 ;
    actu_laser_data_d1 <= #TCQ actu_laser_data_d0;
end

assign pre_track_para_addr_o = pre_track_para_addr;
assign pre_laser_rd_seq_o    = pre_laser_rd_seq;
assign pre_laser_vld_o       = pre_laser_rd_vld;
assign pre_laser_data_o      = pre_laser_rd_data_i;
assign actu_laser_vld_o      = actu_laser_vld_d1;
assign actu_laser_data_o     = actu_laser_data_d1;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


endmodule
