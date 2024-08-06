`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: songyuxin
// 
// Create Date: 2023/06/25
// Design Name: PCG
// Module Name: laser_particle_detect
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

module laser_particle_detect #(
    parameter                   TCQ               = 0.1 ,
    parameter                   DATA_WIDTH        = 32  
)(
    // clk & rst 
    input                       clk_i                       ,
    input                       rst_i                       ,
    input                       aurora_log_clk_i            ,

    // acc track parameter write
    input                       acc_track_para_wr_i         ,
    input   [16-1:0]            acc_track_para_addr_i       ,
    input   [16-1:0]            acc_track_para_data_i       ,

    // acc align
    input   [16-1:0]            circle_lose_num_i           ,
    input   [16-1:0]            circle_lose_num_delta_i     ,
    input   [16-1:0]            uniform_circle_i            ,

    // acc threshold
    input                       acc_defect_en_i             ,
    input   [16-1:0]            pre_acc_curr_thre_i         ,
    input   [16-1:0]            actu_acc_curr_thre_i        ,
    input   [16-1:0]            actu_acc_cache_thre_i       ,
    input   [16-1:0]            lp_pre_acc_curr_thre_i      ,
    input   [16-1:0]            lp_actu_acc_curr_thre_i     ,
    input   [16-1:0]            lp_actu_acc_cache_thre_i    ,

    // acc flag generate
    input   [16-1:0]            acc_cali_delay_set_i        ,
    input   [16-1:0]            acc_flag_delay_i            ,
    input   [16-1:0]            acc_flag_hold_i             ,
    output                      filter_acc_flag_o           ,
    input   [16-1:0]            acc_ctrl_delay_i            ,
    input   [16-1:0]            acc_ctrl_hold_i             ,
    output                      filter_acc_ctrl_o           ,

    // current track data
    input                       aurora_upmode_i             ,
    input                       acc_cali_mode_ctrl_i        ,
    input                       laser_start_i               ,
    input                       encode_zero_flag_i          ,
    input                       laser_acc_flag_i            ,
    input                       laser_vld_i                 ,
    input   [DATA_WIDTH-1:0]    laser_data_i                ,
    input   [16-1:0]            laser_haze_data_i           ,

    // previous track data, from ddr
    input                       pre_laser_rd_ready_i        ,
    output                      pre_laser_rd_seq_o          ,
    input   [DATA_WIDTH+32-1:0] pre_laser_rd_data_i         ,

    // aurora interface
    input                       aurora_txen_i               ,
    output  [DATA_WIDTH-1:0]    aurora_txdata_o             ,
    output                      aurora_tx_emp_o             ,
    output  [11-1:0]            aurora_rd_data_count_o      ,

    // check
    output  [32-1:0]            dbg_acc_flag_cnt_o          
);

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Register Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
reg         [16-1:0]            acc_flag_delay              = 'd0;
reg         [16-1:0]            acc_ctrl_delay              = 'd0;

reg         [2-1:0]             aurora_sel                  = 'd0;
reg         [16-1:0]            aurora_data                 = 'd0;
reg                             aurora_vld                  = 'd0;
reg                             laser_start_d               = 'd0;
reg                             aurora_fifo_rst             = 'd0;
reg         [4-1:0]             aurora_fifo_rst_cnt         = 'hf;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Wire Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
wire        [14-1:0]            pre_track_para_addr             ;
wire        [16-1:0]            pre_track_para_data             ;
wire        [14-1:0]            actu_track_para_addr            ;
wire        [16-1:0]            actu_track_para_data            ;

wire                            pre_laser_vld                   ;
wire        [64-1:0]            pre_laser_data                  ;
wire                            actu_laser_acc_flag             ;
wire                            actu_laser_vld                  ;
wire        [32-1:0]            actu_laser_data                 ;

// wire                            pre_laser_filter_vld            ;
// wire        [16-1:0]            pre_laser_filter_data           ;
wire                            actu_laser_filter_vld           ;
wire        [16-1:0]            actu_laser_filter_data          ;
wire        [16-1:0]            actu_laser_filter_haze_hub      ;
wire                            pre_laser_filter_curr_result    ;
wire                            actu_laser_filter_curr_result   ;
wire                            actu_laser_filter_cache_result  ;

wire                            filter_acc_vld                  ;
wire        [16-1:0]            filter_acc_data                 ;
wire        [16-1:0]            filter_acc_haze_hub             ;
wire                            filter_acc_result               ;

wire                            actu_out_vld                    ;
wire        [32-1:0]            actu_out_data                   ;


wire                            actu_acc_flag                   ;
wire        [6-1:0]             down_sample_rate                ;
wire        [10-1:0]            filter_cache_num                ;
wire        [16-1:0]            spot_space                      ;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Instance Module
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
`ifdef SIMULATE

assign pre_track_para_data  = {2'd0,pre_track_para_addr[3:0],10'd716};
assign actu_track_para_data = {2'd0,actu_track_para_addr[3:0],10'd716};

`else
// track cnt 14bit + down sample num 5bit + cache cnt 10bit 
acc_parameter_bram pre_acc_parameter_bram (
    .clka                           ( clk_i                             ),  // input wire clka
    .wea                            ( acc_track_para_wr_i               ),  // input wire [0 : 0] wea
    .addra                          ( acc_track_para_addr_i[13 : 0]     ),  // input wire [13 : 0] addra
    .dina                           ( acc_track_para_data_i[15 : 0]     ),  // input wire [15 : 0] dina
    .clkb                           ( clk_i                             ),  // input wire clkb
    .addrb                          ( pre_track_para_addr               ),  // input wire [13 : 0] addrb
    .doutb                          ( pre_track_para_data               )   // output wire [15 : 0] doutb
);

acc_parameter_bram actu_acc_parameter_bram (
    .clka                           ( clk_i                             ),  // input wire clka
    .wea                            ( acc_track_para_wr_i               ),  // input wire [0 : 0] wea
    .addra                          ( acc_track_para_addr_i[13 : 0]     ),  // input wire [13 : 0] addra
    .dina                           ( acc_track_para_data_i[15 : 0]     ),  // input wire [15 : 0] dina
    .clkb                           ( clk_i                             ),  // input wire clkb
    .addrb                          ( actu_track_para_addr              ),  // input wire [13 : 0] addrb
    .doutb                          ( actu_track_para_data              )   // output wire [15 : 0] doutb
);

`endif //SIMULATE

reg_delay #(
    .DATA_WIDTH                     ( 1                                 ),
    .DELAY_NUM                      ( 7                                 )
)acc_demo_flag_inst(
    .clk_i                          ( clk_i                             ),
    .src_data_i                     ( laser_acc_flag_i                  ),
    .delay_data_o                   ( actu_acc_flag                     )
);

pre_laser_align #(
    .DATA_WIDTH                     ( 32                                ) 
)laser_align_inst(
    // clk & rst 
    .clk_i                          ( clk_i                             ),
    .rst_i                          ( rst_i                             ),

    .circle_lose_num_i              ( circle_lose_num_i                 ),
    .circle_lose_num_delta_i        ( circle_lose_num_delta_i           ),
    .uniform_circle_i               ( uniform_circle_i                  ),

    .pre_track_para_addr_o          ( pre_track_para_addr               ),
    .pre_track_para_data_i          ( pre_track_para_data               ),

    .laser_start_i                  ( laser_start_i                     ),
    .encode_zero_flag_i             ( encode_zero_flag_i                ),
    .laser_vld_i                    ( laser_vld_i                       ),
    .laser_data_i                   ( laser_data_i                      ),

    .pre_laser_rd_ready_i           ( pre_laser_rd_ready_i              ),
    .pre_laser_rd_seq_o             ( pre_laser_rd_seq_o                ),
    .pre_laser_rd_data_i            ( pre_laser_rd_data_i               ),

    .pre_laser_vld_o                ( pre_laser_vld                     ),
    .pre_laser_data_o               ( pre_laser_data                    ),
    .actu_laser_vld_o               ( actu_laser_vld                    ),
    .actu_laser_data_o              ( actu_laser_data                   )
);

pre_particle_filter #(
    .DATA_WIDTH                     ( 32                                ) 
)pre_particle_filter_inst(
    // clk & rst 
    .clk_i                          ( clk_i                             ),
    .rst_i                          ( rst_i                             ),

    .pre_laser_vld_i                ( pre_laser_vld                     ),
    .pre_laser_data_i               ( pre_laser_data                    ),

    .pre_filter_thre_i              ( pre_acc_curr_thre_i               ),
    .lp_pre_filter_thre_i           ( lp_pre_acc_curr_thre_i            ),

    // .pre_filter_vld_o               ( pre_laser_filter_vld              ),
    // .pre_filter_data_o              ( pre_laser_filter_data             ),
    // .pre_filter_haze_hub_o          ( pre_filter_haze_hub               ),
    .pre_filter_result_o            ( pre_laser_filter_curr_result      )
);

particle_filter #(
    .DATA_WIDTH                     ( 32                                ) 
)actu_particle_filter_inst(
    // clk & rst 
    .clk_i                          ( clk_i                             ),
    .rst_i                          ( rst_i                             ),

    .curr_track_para_addr_o         ( actu_track_para_addr              ),
    .curr_track_para_data_i         ( actu_track_para_data              ),

    .laser_start_i                  ( laser_start_i                     ),
    .encode_zero_flag_i             ( encode_zero_flag_i                ),
    .laser_vld_i                    ( actu_laser_vld                    ),
    .laser_data_i                   ( actu_laser_data                   ),
    .filter_acc_flag_i              ( filter_acc_flag_o                 ),
    .laser_haze_data_i              ( laser_haze_data_i                 ),

    .filter_curr_thre_i             ( actu_acc_curr_thre_i              ),
    .filter_cache_thre_i            ( actu_acc_cache_thre_i             ),
    .lp_filter_curr_thre_i          ( lp_actu_acc_curr_thre_i           ),
    .lp_filter_cache_thre_i         ( lp_actu_acc_cache_thre_i          ),

    .filter_vld_o                   ( actu_laser_filter_vld             ),
    .filter_data_o                  ( actu_laser_filter_data            ),
    .filter_haze_hub_o              ( actu_laser_filter_haze_hub        ),
    .filter_curr_result_o           ( actu_laser_filter_curr_result     ),
    .filter_cache_result_o          ( actu_laser_filter_cache_result    )
);

acc_flag_generate acc_flag_generate_inst(
    // clk & rst 
    .clk_i                          ( clk_i                             ),
    .rst_i                          ( rst_i                             ),

    .filter_vld_i                   ( actu_laser_filter_vld             ),
    .filter_data_i                  ( actu_laser_filter_data            ),
    .filter_haze_hub_i              ( actu_laser_filter_haze_hub        ),
    .pre_filter_result_i            ( pre_laser_filter_curr_result      ),
    .filter_curr_result_i           ( actu_laser_filter_curr_result     ),
    .filter_cache_result_i          ( actu_laser_filter_cache_result    ),

    .filter_en_i                    ( acc_defect_en_i                   ),

    .filter_vld_o                   ( filter_acc_vld                    ),
    .filter_data_o                  ( filter_acc_data                   ),
    .filter_haze_hub_o              ( filter_acc_haze_hub               ),
    .filter_acc_result_o            ( filter_acc_result                 )
);

acc_time_ctrl acc_flag_inst(
    // clk & rst 
    .clk_i                          ( clk_i                             ),
    .rst_i                          ( rst_i                             ),

    .filter_acc_result_i            ( filter_acc_result                 ),
    .acc_delay_i                    ( acc_flag_delay                    ),
    .acc_hold_i                     ( acc_flag_hold_i                   ),

    .filter_acc_flag_o              ( filter_acc_flag_o                 )
);

acc_time_ctrl acc_ctrl_inst(
    // clk & rst 
    .clk_i                          ( clk_i                             ),
    .rst_i                          ( rst_i                             ),

    .filter_acc_result_i            ( filter_acc_result                 ),
    .acc_delay_i                    ( acc_ctrl_delay                    ),
    .acc_hold_i                     ( acc_ctrl_hold_i                   ),

    .filter_acc_flag_o              ( filter_acc_ctrl_o                 )
);

reg laser_start_d1      = 'd0;
reg aurora_tx_emp_d     = 'd0;
reg aurora_tx_clear_rd  = 'd0;
ddr3_to_aurora_fifo ddr3_to_aurora_fifo_inst(
    .rst                            ( rst_i || aurora_fifo_rst          ),
    .wr_clk                         ( clk_i                             ),
    .rd_clk                         ( aurora_log_clk_i                  ),
    .din                            ( actu_out_data                     ),
    .wr_en                          ( actu_out_vld                      ),
    .rd_en                          ( aurora_txen_i || aurora_tx_clear_rd),
    .dout                           ( aurora_txdata_o                   ),
    .empty                          ( aurora_tx_emp_o                   ),
    .rd_data_count                  ( aurora_rd_data_count_o            )
);

always @(posedge aurora_log_clk_i) begin
    laser_start_d1      <= laser_start_i;
    aurora_tx_emp_d     <= #TCQ aurora_tx_emp_o;
    aurora_tx_clear_rd  <= #TCQ (~aurora_tx_emp_d) && (~laser_start_d1);
end
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Logic Design
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
assign down_sample_rate = actu_track_para_data[15:10];
assign filter_cache_num = actu_track_para_data[9:0];
assign spot_space       = down_sample_rate * filter_cache_num;

always @(posedge clk_i) begin
    if(acc_flag_delay_i[15])
        acc_flag_delay <= #TCQ spot_space - (~acc_flag_delay_i + 1);
    else 
        acc_flag_delay <= #TCQ spot_space + acc_flag_delay_i;
end

always @(posedge clk_i) begin
    if(acc_ctrl_delay_i[15])
        acc_ctrl_delay <= #TCQ spot_space - acc_cali_delay_set_i - (~acc_ctrl_delay_i + 1);
    else 
        acc_ctrl_delay <= #TCQ spot_space - acc_cali_delay_set_i + acc_ctrl_delay_i;
end

always @(posedge clk_i) begin
    if(aurora_upmode_i)begin
        if(aurora_sel=='d1 && filter_acc_vld)
            aurora_sel <= #TCQ 'd0;
        else if(filter_acc_vld)
            aurora_sel <= #TCQ aurora_sel + 1;
    end
    else 
        aurora_sel <= #TCQ 'd0;
end

always @(posedge clk_i) begin
    case(aurora_sel)
        'd0:aurora_data <= #TCQ filter_acc_data;
        'd1:aurora_data <= #TCQ laser_haze_data_i;
        // 'd2:aurora_data <= #TCQ filter_acc_haze_hub;
        default:/*default*/;
    endcase
end

always @(posedge clk_i) begin
    aurora_vld <= #TCQ filter_acc_vld;
end

assign actu_out_vld  = aurora_vld;
assign actu_out_data = {(actu_acc_flag || acc_cali_mode_ctrl_i),15'h05aa,aurora_data[15:0]};


always @(posedge clk_i ) begin
    laser_start_d <= #TCQ laser_start_i;
end

always @(posedge clk_i ) begin
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
