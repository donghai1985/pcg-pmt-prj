`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: zas
// Engineer: songyuxin
// 
// Create Date: 2024/7/15
// Design Name: PCG
// Module Name: pre_track_pingpang
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

module pre_track_pingpang #(
    parameter                                   TCQ                 = 0.1   ,
    parameter                                   DATA_WIDTH          = 16    
)(
    input                                       clk_i                       ,
    input                                       rst_i                       ,

    input                                       ds_para_en_i                ,
    input       [32-1:0]                        ds_para_h_i                 ,
    input       [32-1:0]                        ds_para_l_i                 ,
    input                                       pre_track_dbg_i             ,
    // input       [32-1:0]                        aom_ctrl_delay_abs_i        ,
    input       [32-1:0]                        light_spot_para_i           ,
    // input       [16-1:0]                        detect_width_para_i         ,  // 2 * light spot, down sample adc
    input       [16-1:0]                        check_window_i              ,
    input       [16-1:0]                        pre_filter_thre_i           ,

    input                                       laser_start_i               ,
    input                                       laser_pre_vld_i             ,
    input                                       laser_vld_i                 ,
    input       [DATA_WIDTH-1:0]                laser_data_i                ,
    input                                       encode_zero_flag_i          ,
    input                                       filter_acc_flag_i           ,
    input       [DATA_WIDTH-1:0]                laser_haze_data_i           ,

    output                                      second_track_en_o           ,
    output                                      pre_track_result_o          ,

    // pingpang write
    output                                      pre_track_acc_flag_o        ,
    output                                      pre_track_mema_start_o      ,
    output                                      pre_track_mema_vld_o        ,
    output      [DATA_WIDTH*2-1:0]              pre_track_mema_data_o       ,
    output                                      pre_track_memb_start_o      ,
    output                                      pre_track_memb_vld_o        ,
    output      [DATA_WIDTH*2-1:0]              pre_track_memb_data_o       ,

    // pingpang read
    output                                      pre_track_mema_rd_start_o   ,
    input                                       pre_track_mema_ready_i      ,
    input                                       pre_track_mema_rd_vld_i     ,
    output                                      pre_track_mema_rd_seq_o     ,
    input       [64-1:0]                        pre_track_mema_rd_data_i    ,

    output                                      pre_track_memb_rd_start_o   ,
    input                                       pre_track_memb_ready_i      ,
    input                                       pre_track_memb_rd_vld_i     ,
    output                                      pre_track_memb_rd_seq_o     ,
    input       [64-1:0]                        pre_track_memb_rd_data_i    
);
//////////////////////////////////////////////////////////////////////////////////
// *********** Define Parameter Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>


//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Register Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
reg                                             wr_mem_sel              = 'd0;  // 0: write mema; 1: write memb
reg                                             wr_mem_sel_d0           = 'd0;
reg                                             wr_mem_sel_d1           = 'd0;
reg                                             wr_mem_sel_d2           = 'd0;
reg                                             wr_mem_sel_d3           = 'd0;
reg                                             filter_acc_flag_d0      = 'd0;
reg                                             filter_acc_flag_d1      = 'd0;

reg                                             pre_track_mema_vld      = 'd0;
reg             [DATA_WIDTH*2-1:0]              pre_track_mema_data     = 'd0;
reg                                             pre_track_memb_vld      = 'd0;
reg             [DATA_WIDTH*2-1:0]              pre_track_memb_data     = 'd0;

reg                                             pre_laser_rd_ready      = 'd0;
reg                                             pre_laser_rd_vld        = 'd0;
reg             [DATA_WIDTH*2-1:0]              pre_laser_rd_data       = 'd0;

reg                                             laser_start_d           = 'd0;
reg             [9-1:0]                         memb_buffer_clear_cnt   = 'h100;
reg             [9-1:0]                         mema_buffer_clear_cnt   = 'h100;

reg             [32-1:0]                        pre_cache_mema_cnt      = 'd0;
reg                                             pre_cache_mema_rd_seq   = 'd0;
reg             [32-1:0]                        pre_cache_memb_cnt      = 'd0;
reg                                             pre_cache_memb_rd_seq   = 'd0;

reg                                             pre_track_mema_rd_start = 'd0;
reg                                             pre_track_memb_rd_start = 'd0;
reg                                             pre_track_mema_rd_seq   = 'd0;
reg                                             pre_track_memb_rd_seq   = 'd0;
reg                                             pre_laser_flag          = 'd0;
reg             [32-1:0]                        pre_ds_para_h           = 'd0;
reg             [32-1:0]                        pre_ds_para_l           = 'd0;

reg                                             pre_mema_vld_d0         = 'd0;
reg                                             pre_mema_vld_d1         = 'd0;
reg                                             pre_ds_mema_vld_d0      = 'd0;
reg                                             pre_ds_mema_vld_d1      = 'd0;
reg                                             pre_mema_acc_flag       = 'd0;
reg             [17-1:0]                        pre_mema_data           = 'd0;
reg                                             pre_result_mema_flag    = 'd0;
reg             [16-1:0]                        pre_result_mema_sum     = 'd0;
reg                                             pre_mema_result         = 'd0;


reg                                             pre_memb_vld_d0         = 'd0;
reg                                             pre_memb_vld_d1         = 'd0;
reg                                             pre_ds_memb_vld_d0      = 'd0;
reg                                             pre_ds_memb_vld_d1      = 'd0;
reg                                             pre_memb_acc_flag       = 'd0;
reg             [17-1:0]                        pre_memb_data           = 'd0;
reg                                             pre_result_memb_flag    = 'd0;
reg             [16-1:0]                        pre_result_memb_sum     = 'd0;
reg                                             pre_memb_result         = 'd0;

reg             [16-1:0]                        pre_ds_mema_addr        = 'd0;
reg             [16-1:0]                        pre_ds_memb_addr        = 'd0;

reg                                             pre_track_result        = 'd0;

reg                                             pre_laser_acc_flag      = 'd0;
reg                                             pre_laser_data_vld      = 'd0;
reg             [17-1:0]                        pre_laser_data          = 'd0;
reg                                             pre_laser_result_vld    = 'd0;
reg                                             pre_laser_result        = 'd0;
reg             [18-1:0]                        pre_track_wr_addr       = 'd0;
reg             [18-1:0]                        pre_result_sum          = 'd0;
reg             [32-1:0]                        pre_track_result_cnt    = 'd0;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Wire Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
wire                                            pre_mema_vld                ;
wire                                            pre_ds_mema_vld             ;
wire            [64-1:0]                        pre_ds_mema_data            ;
wire                                            pre_mema_result_flag        ;
wire            [16-1:0]                        pre_mema_data_abs           ;

wire                                            pre_memb_vld                ;
wire                                            pre_ds_memb_vld             ;
wire            [64-1:0]                        pre_ds_memb_data            ;
wire                                            pre_memb_result_flag        ;
wire            [16-1:0]                        pre_memb_data_abs           ;

wire            [16-1:0]                        pre_ds_mema_rd_addr         ;
wire                                            pre_mema_cache_result       ;

wire            [16-1:0]                        pre_ds_memb_rd_addr         ;
wire                                            pre_memb_cache_result       ;

wire            [32-1:0]                        light_spot_spacing          ;
wire            [32-1:0]                        pre_track_check_window      ;

wire            [16-1:0]                        pre_laser_data_abs          ;
wire            [18-1:0]                        pre_track_rd_addr           ;
wire                                            pre_track_rd_result         ;

wire                                            pre_track_vld               ;
wire                                            pre_track_ds_result         ;
wire                                            pre_track_ds_result_vld     ;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Instance Module
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

// uniform_downsample #(
//     .DATA_WIDTH                     ( 1                                 )
// )pre_uniform_downsample_inst(
//     .clk_i                          ( clk_i                             ),
//     .rst_i                          ( rst_i                             ),

//     .ds_para_en_i                   ( ds_para_en_i                      ),
//     .ds_para_h_i                    ( pre_ds_para_h                     ),
//     .ds_para_l_i                    ( pre_ds_para_l                     ),

//     .laser_start_i                  ( laser_start_i                     ),
//     .laser_vld_i                    ( pre_laser_result_vld              ),
//     .laser_data_i                   ( pre_laser_result                  ),

//     .ds_laser_vld_o                 ( pre_track_vld                     ),
//     .ds_laser_data_o                ( pre_track_ds_result               ),
//     .ds_laser_lost_o                ( pre_track_ds_result_vld           )
// );

cache_bit_ram cache_bit_ramb_inst (
    .clka                           ( clk_i                             ),  // input wire clka
    .wea                            ( pre_laser_result_vld              ),  // input wire [0 : 0] wea
    .addra                          ( pre_track_wr_addr                 ),  // input wire [17 : 0] addra
    .dina                           ( pre_laser_result                  ),  // input wire [0 : 0] dina
    .clkb                           ( clk_i                             ),  // input wire clkb
    .addrb                          ( pre_track_rd_addr                 ),  // input wire [17 : 0] addrb
    .doutb                          ( pre_track_rd_result               )   // output wire [0 : 0] doutb
);
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Logic Design
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
// pingpang write to ddr
always @(posedge clk_i) begin
    if(~laser_start_i)
        wr_mem_sel <= #TCQ 'd0;
    else if(encode_zero_flag_i)
        wr_mem_sel <= #TCQ ~wr_mem_sel;
end

always @(posedge clk_i) begin
    wr_mem_sel_d0 <= #TCQ wr_mem_sel;
    wr_mem_sel_d1 <= #TCQ wr_mem_sel_d0;
    wr_mem_sel_d2 <= #TCQ wr_mem_sel_d1;
    wr_mem_sel_d3 <= #TCQ wr_mem_sel_d2;
end

always @(posedge clk_i) begin
    if(laser_start_i)begin
        pre_track_mema_vld <= #TCQ ~wr_mem_sel && laser_pre_vld_i;
        pre_track_memb_vld <= #TCQ wr_mem_sel && laser_pre_vld_i;
    end
    else begin
        pre_track_mema_vld <= #TCQ 'd0;
        pre_track_memb_vld <= #TCQ 'd0;
    end
end

always @(posedge clk_i) begin
    pre_track_mema_data <= #TCQ {laser_haze_data_i,laser_data_i};
    pre_track_memb_data <= #TCQ {laser_haze_data_i,laser_data_i};
end

always @(posedge clk_i) begin
    filter_acc_flag_d0 <= #TCQ filter_acc_flag_i;
    filter_acc_flag_d1 <= #TCQ filter_acc_flag_d0;
end

assign pre_track_acc_flag_o     = filter_acc_flag_d0;
assign pre_track_mema_start_o   = ~wr_mem_sel && laser_start_i;
assign pre_track_mema_vld_o     = pre_track_mema_vld ;
assign pre_track_mema_data_o    = pre_track_mema_data;
assign pre_track_memb_start_o   = wr_mem_sel && laser_start_i;
assign pre_track_memb_vld_o     = pre_track_memb_vld ;
assign pre_track_memb_data_o    = pre_track_memb_data;


// 数据密度平均参数更新
always @(posedge clk_i) begin
    if(ds_para_en_i)begin
        pre_ds_para_h  <= #TCQ ds_para_h_i ;
        pre_ds_para_l  <= #TCQ ds_para_l_i ;
    end
end

// rd start 增加预读取的时间，为 check window 增加余量
always @(posedge clk_i) begin
    laser_start_d <= #TCQ laser_start_i;
end

assign wr_mem_a2b = (~wr_mem_sel_d0) && wr_mem_sel;
assign wr_mem_b2a = (wr_mem_sel_d0) && (~wr_mem_sel);

always @(posedge clk_i) begin
    if(~laser_start_d && laser_start_i)
        mema_buffer_clear_cnt <= #TCQ 'd0;
    else if(wr_mem_b2a)
        mema_buffer_clear_cnt <= #TCQ 'd0;
    else if(~mema_buffer_clear_cnt[8])
        mema_buffer_clear_cnt <= #TCQ mema_buffer_clear_cnt + 1;
end

always @(posedge clk_i) begin
    if(~laser_start_d && laser_start_i)
        memb_buffer_clear_cnt <= #TCQ 'd0;
    else if(wr_mem_a2b)
        memb_buffer_clear_cnt <= #TCQ 'd0;
    else if(~memb_buffer_clear_cnt[8])
        memb_buffer_clear_cnt <= #TCQ memb_buffer_clear_cnt + 1;
end

always @(posedge clk_i) begin
    if(laser_start_d)begin
        if((~wr_mem_sel_d0) && (&mema_buffer_clear_cnt[7:0]))
            pre_track_mema_rd_start <= #TCQ 'd1;
        else if(wr_mem_b2a)
            pre_track_mema_rd_start <= #TCQ 'd0;
    end
    else
        pre_track_mema_rd_start <= #TCQ 'd0;
end

always @(posedge clk_i) begin
    if(laser_start_d)begin
        if((wr_mem_sel_d0) && (&memb_buffer_clear_cnt[7:0]))
            pre_track_memb_rd_start <= #TCQ 'd1;
        else if(wr_mem_a2b)
            pre_track_memb_rd_start <= #TCQ 'd0;
    end
    else
        pre_track_memb_rd_start <= #TCQ 'd0;
end

assign pre_track_mema_rd_start_o = pre_track_mema_rd_start;
assign pre_track_memb_rd_start_o = pre_track_memb_rd_start;

// pre track read seq
always @(posedge clk_i) begin
    if(laser_start_i)begin
        if(encode_zero_flag_i)
            pre_laser_flag <= #TCQ 'd1;
    end
    else 
        pre_laser_flag <= #TCQ 'd0;
end

assign pre_laser_rd_seq = laser_vld_i && pre_laser_flag;

// 读取提前量的主副光斑间隔数据
assign light_spot_spacing = pre_track_dbg_i ? 'd0 : (light_spot_para_i + light_spot_para_i[31:1]);
// assign light_spot_spacing = pre_track_dbg_i ? 'd0 : aom_ctrl_delay_abs_i;
always @(posedge clk_i) begin
    if(pre_track_mema_rd_start && pre_track_mema_ready_i)
        if(pre_cache_mema_cnt < light_spot_spacing)begin
            pre_cache_mema_rd_seq   <= #TCQ 'd1;
            pre_cache_mema_cnt      <= #TCQ pre_cache_mema_cnt + 1;
        end
        else begin
            pre_cache_mema_rd_seq   <= #TCQ 'd0;
            pre_cache_mema_cnt      <= #TCQ pre_cache_mema_cnt;
        end
    else begin
        pre_cache_mema_rd_seq   <= #TCQ 'd0;
        pre_cache_mema_cnt      <= #TCQ 'd0;
    end
end

always @(posedge clk_i) begin
    if(pre_track_memb_rd_start && pre_track_memb_ready_i)
        if(pre_cache_memb_cnt < light_spot_spacing)begin
            pre_cache_memb_rd_seq   <= #TCQ 'd1;
            pre_cache_memb_cnt      <= #TCQ pre_cache_memb_cnt + 1;
        end
        else begin
            pre_cache_memb_rd_seq   <= #TCQ 'd0;
            pre_cache_memb_cnt      <= #TCQ pre_cache_memb_cnt;
        end
    else begin
        pre_cache_memb_rd_seq   <= #TCQ 'd0;
        pre_cache_memb_cnt      <= #TCQ 'd0;
    end
end

always @(posedge clk_i) begin
    if(wr_mem_sel_d0)
        pre_track_mema_rd_seq <= #TCQ pre_laser_rd_seq;
    else
        pre_track_mema_rd_seq <= #TCQ pre_cache_mema_rd_seq;
end

always @(posedge clk_i) begin
    if(~wr_mem_sel_d0)
        pre_track_memb_rd_seq <= #TCQ pre_laser_rd_seq;
    else
        pre_track_memb_rd_seq <= #TCQ pre_cache_memb_rd_seq;
end

always @(posedge clk_i) begin
    if(wr_mem_sel_d2)begin
        pre_laser_rd_vld  <= #TCQ pre_track_mema_rd_vld_i;
        pre_laser_rd_data <= #TCQ pre_track_mema_rd_data_i;
    end
    else begin
        pre_laser_rd_vld  <= #TCQ pre_track_memb_rd_vld_i;
        pre_laser_rd_data <= #TCQ pre_track_memb_rd_data_i;
    end
end

assign pre_track_mema_rd_seq_o  = pre_track_mema_rd_seq;
assign pre_track_memb_rd_seq_o  = pre_track_memb_rd_seq;

`ifdef SIMULATE
reg [16-1:0] sim_laser_rd_data = 'd0;
reg [16-1:0] sim_laser_rd_data_delta = 'd0;
always @(posedge clk_i) begin
    sim_laser_rd_data       <= #TCQ pre_laser_rd_data[16-1:0];
    sim_laser_rd_data_delta <= #TCQ pre_laser_rd_data[16-1:0] - sim_laser_rd_data;
end
`endif // SIMULATE


always @(posedge clk_i) begin
    if(pre_laser_rd_vld)begin
        pre_laser_acc_flag <= #TCQ pre_laser_rd_data[63];
        pre_laser_data     <= #TCQ pre_laser_rd_data[15:0] - pre_laser_rd_data[31:16];
    end
end

always @(posedge clk_i) pre_laser_data_vld <= #TCQ pre_laser_rd_vld;

assign pre_laser_data_abs = pre_laser_data[16] ? 'd0 : pre_laser_data[15:0];

always @(posedge clk_i) begin
    if(pre_laser_data_vld)begin
        pre_laser_result <= #TCQ (pre_laser_data_abs > pre_filter_thre_i);
    end
    else 
        pre_laser_result <= #TCQ 'd0;
end

always @(posedge clk_i) pre_laser_result_vld <= #TCQ pre_laser_data_vld;

wire [16-1:0] check_window_abs;
assign check_window_abs = check_window_i[15] ? ~check_window_i + 1 : check_window_i;

reg [16-1:0] check_window_supp = 'd0;
always @(posedge clk_i) begin
    check_window_supp <= #TCQ light_spot_para_i[31:4] * check_window_abs[4-1:0];
end

assign pre_track_check_window = pre_track_dbg_i ? 'd1 : 
                                (!check_window_i[15]) ? (light_spot_para_i - light_spot_para_i[31:2]) + check_window_supp :
                                                        (light_spot_para_i - light_spot_para_i[31:2]) - check_window_supp ;
// {1'b0,light_spot_spacing[15:1]} + check_window_i + 1 + detect_width_para_i;

always @(posedge clk_i) begin
    if(~laser_start_i)
        pre_track_wr_addr <= #TCQ 'd0;
    else if(pre_laser_result_vld)
        pre_track_wr_addr <= #TCQ pre_track_wr_addr + 1;
end

always @(posedge clk_i) begin
    if(~laser_start_i)
        pre_track_result_cnt <= #TCQ 'd0;
    else if(pre_laser_result_vld)begin
        if(pre_track_result_cnt < pre_track_check_window)
            pre_track_result_cnt <= #TCQ pre_track_result_cnt + 1;
    end
end

assign pre_result_flag = pre_track_result_cnt >= pre_track_check_window;

always @(posedge clk_i) begin
    if(~laser_start_i)
        pre_result_sum <= #TCQ 'd0;
    else if(pre_laser_result_vld)begin
        if(~pre_result_flag)
            pre_result_sum <= #TCQ pre_result_sum + pre_laser_result;
        else
            pre_result_sum <= #TCQ pre_result_sum + pre_laser_result - pre_track_rd_result;
    end
end

always @(posedge clk_i) begin
    pre_track_result  <= #TCQ |pre_result_sum;
end

assign pre_track_rd_addr = pre_track_wr_addr - pre_track_check_window;
assign pre_track_result_o = pre_track_result;
assign second_track_en_o  = pre_laser_flag;

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    
endmodule