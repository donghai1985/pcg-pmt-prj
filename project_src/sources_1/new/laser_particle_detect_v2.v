`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: songyuxin
// 
// Create Date: 2024/05/17
// Design Name: PCG
// Module Name: laser_particle_detect_v2
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
// `define DOWN_SAMPLE_MOD

module laser_particle_detect_v2 #(
    parameter                   TCQ               = 0.1 ,
    parameter                   DATA_WIDTH        = 32  
)(
    // clk & rst 
    input                       clk_i                       ,
    input                       rst_i                       ,
    
    // light spot spacing, unit lost clk
    input   [32-1:0]            detect_width_para_i         ,  // 2 * light spot, down sample adc
    // input   [16-1:0]            light_spot_spacing_i        ,  // first light spot, down sample adc

    // input                       ds_para_en_i                ,
    // input   [32-1:0]            ds_para_h_i                 ,
    // input   [32-1:0]            ds_para_l_i                 ,

    // acc threshold
    input                       acc_defect_en_i             ,
    input                       pre_track_result_i          ,
    input   [16-1:0]            actu_acc_curr_thre_i        ,
    input   [16-1:0]            actu_acc_cache_thre_i       ,
    input   [3-1:0]             particle_acc_bypass_i       ,
    input                       first_track_ctrl_i          ,

    // acc result
    // output                      filter_acc_delay_vld_o      ,
    output                      filter_acc_flag_o           ,
    output                      filter_acc_vld_o            ,
    output  [16-1:0]            filter_acc_data_o           ,
    output  [16-1:0]            filter_acc_haze_o           ,
    output  [16-1:0]            filter_acc_haze_hub_o       ,
    output                      filter_acc_result_o         ,
    output                      acc_pre_result_o            ,
    output                      acc_curr_result_o           ,
    input                       second_track_en_i           ,

    // current track data
    input                       laser_start_i               ,
    input                       encode_zero_flag_i          ,
    input                       laser_acc_flag_i            ,
    input                       laser_vld_i                 ,
    input   [16-1:0]            laser_data_i                ,
    input   [16-1:0]            laser_haze_data_i           ,

    // previous track data, from ddr
    input                       pre_laser_rd_ready_i        ,
    output                      pre_laser_rd_seq_o          ,
    input                       pre_laser_rd_vld_i          ,
    input   [64-1:0]            pre_laser_rd_data_i         ,

    // check
    output  [32-1:0]            pre_widen_result_cnt_o      ,
    output  [32-1:0]            curr_widen_result_cnt_o     ,
    output  [32-1:0]            cache_widen_result_cnt_o    ,
    output  [32-1:0]            dbg_acc_flag_cnt_o          
);

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Register Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
reg         [16-1:0]            acc_flag_delay              = 'd0;
reg         [16-1:0]            acc_ctrl_delay              = 'd0;

reg                             filter_acc_result_d         = 'd0;
reg                             laser_start_d               = 'd0;
reg         [32-1:0]            dbg_acc_flag_cnt            = 'd0;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Wire Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
wire                            pre_laser_vld                   ;
wire        [64-1:0]            pre_laser_data                  ;
wire                            actu_laser_vld                  ;
wire        [16-1:0]            actu_laser_data                 ;
// wire                            pre_laser_filter_vld            ;
// wire        [16-1:0]            pre_laser_filter_data           ;
wire                            actu_laser_delay_vld            ;
wire                            actu_laser_acc_flag             ;
wire                            actu_laser_filter_delay_vld     ;
wire                            actu_laser_filter_acc_flag      ;
wire                            actu_laser_filter_vld           ;
wire        [16-1:0]            actu_laser_filter_data          ;
wire        [16-1:0]            actu_laser_filter_haze          ;
wire        [16-1:0]            actu_laser_filter_haze_hub      ;
wire                            pre_laser_filter_curr_result    ;
wire                            actu_laser_filter_curr_result   ;
wire                            actu_laser_filter_cache_result  ;

wire                            pre_widen_result                ;
wire                            curr_widen_result               ;
wire                            cache_widen_result              ;

// down sample generate
wire                            pre_ds_acc_flag                 ;
wire                            pre_ds_zero_flag                ;
wire                            pre_ds_laser_vld                ;
wire        [64-1:0]            pre_ds_laser_data               ;
wire                            pre_ds_laser_lost               ;
wire                            actu_ds_acc_flag                ;
wire                            actu_ds_zero_flag               ;
wire                            actu_ds_laser_vld               ;
wire        [16-1:0]            actu_ds_laser_data              ;
wire                            actu_ds_laser_lost              ;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Instance Module
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

`ifdef DOWN_SAMPLE_MOD

uniform_downsample #(
    .DATA_WIDTH                     ( 16                                )
)actu_uniform_downsample_inst(
    .clk_i                          ( clk_i                             ),
    .rst_i                          ( rst_i                             ),

    .ds_para_en_i                   ( ds_para_en_i                      ),
    .ds_para_h_i                    ( ds_para_h_i                       ),
    .ds_para_l_i                    ( ds_para_l_i                       ),

    .laser_start_i                  ( laser_start_i                     ),
    .acc_flag_i                     ( laser_acc_flag_i                  ),
    .laser_vld_i                    ( laser_vld_i                       ),
    .laser_data_i                   ( laser_data_i                      ),

    .ds_acc_flag_o                  ( actu_ds_acc_flag                  ),
    .ds_laser_vld_o                 ( actu_ds_laser_vld                 ),
    .ds_laser_data_o                ( actu_ds_laser_data                ),
    .ds_laser_lost_o                ( actu_ds_laser_lost                )
);
`else

// assign pre_ds_laser_lost = pre_laser_vld ;
// assign pre_ds_laser_data = pre_laser_data;
assign actu_ds_acc_flag   = laser_acc_flag_i;
assign actu_ds_laser_vld  = laser_vld_i;
assign actu_ds_laser_data = laser_data_i;
assign actu_ds_laser_lost = laser_vld_i;

`endif // DOWN_SAMPLE_MOD

particle_filter_v2 actu_particle_filter_inst(
    // clk & rst 
    .clk_i                          ( clk_i                             ),
    .rst_i                          ( rst_i                             ),

    // .light_spot_spacing_i           ( light_spot_spacing_i              ),
    // .laser_delay_vld_i              ( actu_ds_laser_vld                 ),
    .laser_acc_flag_i               ( actu_ds_acc_flag                  ),
    .laser_vld_i                    ( actu_ds_laser_vld                 ),
    .laser_data_i                   ( actu_ds_laser_data[16-1:0]        ),
    .laser_haze_data_i              ( laser_haze_data_i                 ),

    .filter_curr_thre_i             ( actu_acc_curr_thre_i              ),
    // .filter_cache_thre_i            ( actu_acc_cache_thre_i             ),

    // .filter_delay_vld_o             ( actu_laser_filter_delay_vld       ),
    .filter_acc_flag_o              ( actu_laser_filter_acc_flag        ),
    .filter_vld_o                   ( actu_laser_filter_vld             ),
    .filter_data_o                  ( actu_laser_filter_data            ),
    .filter_haze_data_o             ( actu_laser_filter_haze            ),
    .filter_haze_hub_o              ( actu_laser_filter_haze_hub        ),
    .filter_curr_result_o           ( actu_laser_filter_curr_result     )
    // .filter_cache_result_o          ( actu_laser_filter_cache_result    )
);

acc_flag_generate acc_flag_generate_inst(
    // clk & rst 
    .clk_i                          ( clk_i                             ),
    .rst_i                          ( rst_i                             ),

    .laser_start_i                  ( laser_start_i                     ),
    .second_track_en_i              ( second_track_en_i                 ),
    .detect_width_para_i            ( detect_width_para_i               ),
    // .filter_delay_vld_i             ( actu_laser_filter_delay_vld       ),
    .filter_acc_flag_i              ( actu_laser_filter_acc_flag        ),
    .filter_vld_i                   ( actu_laser_filter_vld             ),
    .filter_data_i                  ( actu_laser_filter_data            ),
    .filter_haze_data_i             ( actu_laser_filter_haze            ),
    .filter_haze_hub_i              ( actu_laser_filter_haze_hub        ),
    .pre_filter_result_i            ( pre_track_result_i                ),
    .filter_curr_result_i           ( actu_laser_filter_curr_result     ),
    // .filter_cache_result_i          ( actu_laser_filter_cache_result    ),
    .particle_acc_bypass_i          ( particle_acc_bypass_i             ),
    .first_track_ctrl_i             ( first_track_ctrl_i                ),

    .filter_en_i                    ( acc_defect_en_i                   ),
    .pre_widen_result_o             ( pre_widen_result                  ),
    .curr_widen_result_o            ( curr_widen_result                 ),
    // .cache_widen_result_o           ( cache_widen_result                ),

    // .filter_delay_vld_o             ( filter_acc_delay_vld_o            ),
    .filter_acc_flag_o              ( filter_acc_flag_o                 ),
    .filter_vld_o                   ( filter_acc_vld_o                  ),
    .filter_data_o                  ( filter_acc_data_o                 ),
    .filter_haze_o                  ( filter_acc_haze_o                 ),
    .filter_haze_hub_o              ( filter_acc_haze_hub_o             ),
    .filter_acc_result_o            ( filter_acc_result_o               )
);

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Logic Design
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
always @(posedge clk_i) begin
    filter_acc_result_d <= #TCQ filter_acc_result_o;
    laser_start_d       <= #TCQ laser_start_i;
end

always @(posedge clk_i) begin
    if(~laser_start_d && laser_start_i)
        dbg_acc_flag_cnt <= #TCQ 'd0;
    else if(laser_start_i && (~filter_acc_result_d) && filter_acc_result_o)
        dbg_acc_flag_cnt <= #TCQ dbg_acc_flag_cnt + 1;
end

reg [32-1:0] pre_widen_result_cnt   = 'd0;
reg [32-1:0] curr_widen_result_cnt  = 'd0;
reg [32-1:0] cache_widen_result_cnt = 'd0;
reg pre_widen_result_d   = 'd0;
reg curr_widen_result_d  = 'd0;
reg cache_widen_result_d = 'd0;
always @(posedge clk_i) begin
    pre_widen_result_d      <= #TCQ pre_widen_result  ;
    curr_widen_result_d     <= #TCQ curr_widen_result ;
    // cache_widen_result_d    <= #TCQ cache_widen_result;
end

always @(posedge clk_i) begin
    if(~laser_start_d && laser_start_i)
        pre_widen_result_cnt <= #TCQ 'd0;
    else if(laser_start_i && (~pre_widen_result_d) && pre_widen_result)
        pre_widen_result_cnt <= #TCQ pre_widen_result_cnt + 1;
end

always @(posedge clk_i) begin
    if(~laser_start_d && laser_start_i)
        curr_widen_result_cnt <= #TCQ 'd0;
    else if(laser_start_i && (~curr_widen_result_d) && curr_widen_result)
        curr_widen_result_cnt <= #TCQ curr_widen_result_cnt + 1;
end

// always @(posedge clk_i) begin
//     if(~laser_start_d && laser_start_i)
//         cache_widen_result_cnt <= #TCQ 'd0;
//     else if(laser_start_i && (~cache_widen_result_d) && cache_widen_result)
//         cache_widen_result_cnt <= #TCQ cache_widen_result_cnt + 1;
// end

assign dbg_acc_flag_cnt_o       = dbg_acc_flag_cnt;
assign acc_pre_result_o         = pre_widen_result_d;
assign acc_curr_result_o        = curr_widen_result_d;
assign pre_widen_result_cnt_o   = pre_widen_result_cnt  ;
assign curr_widen_result_cnt_o  = curr_widen_result_cnt ;
assign cache_widen_result_cnt_o = cache_widen_result_cnt;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


endmodule
