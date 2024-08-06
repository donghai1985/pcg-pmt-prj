`timescale  1ns / 1ps
`define AURORA_MOD
`define FIR_MOD
`define HAZE_MOD
// `define LOWPASS_MOD
`define DYNAMIC_LOWPASS_MOD
`define DOWN_SAMPLE_MOD

module tb_data_process;

// fir_ctrl Parameters
parameter                   TCQ                 = 0.1   ;
parameter                   PERIOD              = 10    ;
parameter                   DATA_WIDTH          = 32    ;
parameter                   ADDR_WIDTH          = 16    ;
parameter                   LOWPASS_PARA_NUM    = 1     ;
parameter                   FIR_TAP_NUM         = 51    ;
parameter                   DS_PARA_NUM         = 2     ;
parameter                   VERSION             = "PCG1_PMTM_v9.6      ";

// track parameter
reg                         track_para_en              = 0 ;
wire                        track_para_burst_end        ;
wire                        track_para_vld              ;
wire    [32-1:0]            track_para_data             ;
wire                        track_para_ready            ;
wire                        track_para_ren              ;

wire                        ds_para_en                  ;
wire    [32-1:0]            ds_para_h                   ;
wire    [32-1:0]            ds_para_l                   ;

wire                        lowpass_para_vld            ;
wire    [32-1:0]            lowpass_para_data           ;

wire                        fir_tap_vld                 ;
wire    [10-1:0]            fir_tap_addr                ;
wire    [32-1:0]            fir_tap_data                ;

// low power recover
wire                        lp_recover_acc_flag         ;
wire                        lp_recover_zero_flag        ;
wire    [16-1:0]            lp_recover_factor           ;
wire                        lp_recover_vld              ;
wire    [16-1:0]            lp_recover_data             ;

// low pass filter
wire                        lpf_acc_flag                ;
wire                        lpf_zero_flag               ;
wire                        lpf_laser_vld               ;
wire    [16-1:0]            lpf_laser_data              ;

// down sample generate
wire                        ds_acc_flag                 ;
wire                        ds_zero_flag                ;
wire                        ds_laser_vld                ;
wire    [16-1:0]            ds_laser_data               ;
wire                        ds_laser_lost               ;

// fir 
wire                        fir_ds_lost                 ;
wire                        fir_acc_flag                ;
wire                        fir_zero_flag               ;
wire                        fir_laser_vld               ;
wire    [16-1:0]            fir_laser_data              ;

// fir post processing, data flod
wire                        fir_post_zero_flag          ;
wire                        fir_post_acc_flag           ;
wire                        fir_post_vld                ;
wire    [32-1:0]            fir_post_data               ;



// haze
wire    [16-1:0]            laser_haze_data             ;

// ACC ctrl parameter
wire    [16-1:0]            circle_lose_num             ;
wire    [16-1:0]            circle_lose_num_delta       ;
wire    [16-1:0]            uniform_circle_num          ;

wire                        acc_track_para_wr           ;
wire    [16-1:0]            acc_track_para_addr         ;
wire    [16-1:0]            acc_track_para_data         ;

wire                        acc_defect_en               ;
wire    [16-1:0]            pre_acc_curr_thre           ;
wire    [16-1:0]            actu_acc_curr_thre          ;
wire    [16-1:0]            actu_acc_cache_thre         ;
wire    [16-1:0]            lp_pre_acc_curr_thre        ;
wire    [16-1:0]            lp_actu_acc_curr_thre       ;
wire    [16-1:0]            lp_actu_acc_cache_thre      ;

wire                        acc_cali_mode               ;
wire    [32-1:0]            acc_cali_low                ;
wire    [32-1:0]            acc_cali_high               ;
wire                        acc_cali_ctrl               ;
wire    [16-1:0]            acc_cali_delay_set          ;
wire    [16-1:0]            acc_flag_delay              ;
wire    [16-1:0]            acc_flag_hold               ;
wire    [16-1:0]            acc_ctrl_delay              ;
wire    [16-1:0]            acc_ctrl_hold               ;
wire                        filter_acc_ctrl             ;
wire                        aurora_upmode               ;

wire    [32-1:0]            dbg_acc_flag_cnt            ;


reg                         clk_100m                = 0;
reg                         rst_100m                = 1;
reg                         real_adc_start          = 0;
reg                         adc_data_en             = 0;
reg     [16-1:0]            adc_data                = 0;
reg                         filter_acc_flag         = 0;
reg                         wafer_zero_flag         = 0;
// fir tap setting
reg                         laser_fir_upmode        = 0;
reg                         laser_fir_en            = 0;

initial
begin
    forever #(PERIOD/2)  clk_100m=~clk_100m;
end

initial
begin
    rst_100m  =  1;
    #(PERIOD*2);
    rst_100m  =  0;
end


spi_reg_map #(
    .DATA_WIDTH                     ( DATA_WIDTH                        ),
    .ADDR_WIDTH                     ( ADDR_WIDTH                        ),
    .pmt_mfpga_version              ( VERSION                           )
)timing_command_map_inst(
    // clk & rst
    .clk_i                          ( clk_100m                          ),
    .rst_i                          ( rst_100m                          ),

    .slave_wr_en_i                  ( slave_wr_en                       ),
    .slave_addr_i                   ( slave_addr                        ),
    .slave_wr_data_i                ( slave_wr_data                     ),
    .slave_rd_en_i                  ( slave_rd_en                       ),
    .slave_rd_vld_o                 ( slave_rd_vld                      ),
    .slave_rd_data_o                ( slave_rd_data                     ),

    .laser_adc_test_o               ( adc_test_set                      ),
    .ad5592_1_dac_config_en_o       ( ad5592_1_dac_config_en            ),
    .ad5592_1_dac_channel_o         ( ad5592_1_dac_channel              ),
    .ad5592_1_dac_data_o            ( ad5592_1_dac_data                 ),
    .ADC_offset_en_o                ( ad5542_wr_data_en                 ),
    .ADC_offset_o                   ( ad5542_wr_data                    ),
    .bst_vcc_en_o                   ( bst_vcc_en                        ),

    .circle_lose_num_o              ( circle_lose_num                   ),
    .circle_lose_num_delta_o        ( circle_lose_num_delta             ),
    .uniform_circle_o               ( uniform_circle_num                ),

    .acc_defect_en_o                ( acc_defect_en                     ),
    .pre_acc_curr_thre_o            ( pre_acc_curr_thre                 ),
    .actu_acc_curr_thre_o           ( actu_acc_curr_thre                ),
    .actu_acc_cache_thre_o          ( actu_acc_cache_thre               ),
    .lp_pre_acc_curr_thre_o         ( lp_pre_acc_curr_thre              ),
    .lp_actu_acc_curr_thre_o        ( lp_actu_acc_curr_thre             ),
    .lp_actu_acc_cache_thre_o       ( lp_actu_acc_cache_thre            ),
    
    .lp_recover_factor_o            ( lp_recover_factor                 ),  // 8bit integer + 8bit decimal
    .acc_cali_mode_o                ( acc_cali_mode                     ),
    .acc_cali_low_o                 ( acc_cali_low                      ),
    .acc_cali_high_o                ( acc_cali_high                     ),
    .acc_cali_delay_set_o           ( acc_cali_delay_set                ),
    .acc_flag_delay_o               ( acc_flag_delay                    ),
    .acc_flag_hold_o                ( acc_flag_hold                     ),
    .acc_ctrl_delay_o               ( acc_ctrl_delay                    ),
    .acc_ctrl_hold_o                ( acc_ctrl_hold                     ),
    .aurora_upmode_o                ( aurora_upmode                     ),

    // .laser_fir_upmode_o             ( laser_fir_upmode                  ),
    // .laser_fir_en_o                 ( laser_fir_en                      ),
    // .track_para_en_o                ( track_para_en                     ),

    .dbg_acc_flag_cnt_i             ( dbg_acc_flag_cnt                  ),
    .debug_info                     (                                   )
);

acc_cali_ctrl acc_cali_ctrl_inst(
    // clk & rst 
    .clk_i                          ( clk_100m                          ),
    .rst_i                          ( rst_100m                          ),

    .laser_start_i                  ( real_adc_start                    ),
    .acc_cali_mode_i                ( acc_cali_mode                     ),
    .acc_cali_low_i                 ( acc_cali_low                      ),
    .acc_cali_high_i                ( acc_cali_high                     ),
    .acc_cali_ctrl_o                ( acc_cali_ctrl                     )
);

track_para_ctrl_sim track_para_ctrl_sim_inst(
    // clk & rst
    .clk_i                          ( clk_100m                          ),
    .rst_i                          ( rst_100m                          ),
    
    .laser_start_i                  ( real_adc_start                    ),
    .track_para_en_i                ( track_para_en                     ),
    .laser_zero_flag_i              ( wafer_zero_flag                   ),

    .track_para_burst_end_o         ( track_para_burst_end              ),
    .track_para_vld_o               ( track_para_vld                    ),
    .track_para_data_o              ( track_para_data                   ),
    .track_para_ren_i               ( track_para_ren                    )
    
);

track_para_ctrl #(
    .LOWPASS_PARA_NUM               ( 1                                 ),
    .FIR_TAP_NUM                    ( 51                                ),
    .DS_PARA_NUM                    ( 2                                 )
)track_para_ctrl_inst(
    .clk_i                          ( clk_100m                          ),
    .rst_i                          ( rst_100m                          ),

    .laser_start_i                  ( real_adc_start                    ),
    .track_para_en_i                ( track_para_en                     ),
    .laser_zero_flag_i              ( wafer_zero_flag                   ),
    
    .track_para_burst_end_i         ( track_para_burst_end              ),
    .track_para_vld_i               ( track_para_vld                    ),
    .track_para_data_i              ( track_para_data                   ),
    .track_para_ren_o               ( track_para_ren                    ),
    
    .fir_tap_vld_o                  ( fir_tap_vld                       ),
    .fir_tap_addr_o                 ( fir_tap_addr                      ),
    .fir_tap_data_o                 ( fir_tap_data                      ),

    .lowpass_para_vld_o             ( lowpass_para_vld                  ),
    .lowpass_para_data_o            ( lowpass_para_data                 ),

    .ds_para_en_o                   ( ds_para_en                        ),
    .ds_para_h_o                    ( ds_para_h                         ),
    .ds_para_l_o                    ( ds_para_l                         )
);

acc_lp_recover acc_lp_recover_inst(
    // clk & rst 
    .clk_i                          ( clk_100m                          ),
    .rst_i                          ( rst_100m                          ),

    .laser_vld_i                    ( adc_data_en                       ),
    .laser_data_i                   ( adc_data                          ),
    .filter_acc_flag_i              ( filter_acc_flag                   ),
    .laser_zero_flag_i              ( wafer_zero_flag                   ),

    .lp_recover_factor_i            ( lp_recover_factor                 ),  // 8bit integer + 8bit decimal

    .lp_recover_acc_flag_o          ( lp_recover_acc_flag               ),
    .lp_recover_zero_flag_o         ( lp_recover_zero_flag              ),
    .lp_recover_vld_o               ( lp_recover_vld                    ),
    .lp_recover_data_o              ( lp_recover_data                   )
);

`ifdef DYNAMIC_LOWPASS_MOD
dynamic_lowpass #(
    .DIS_MEM_DEPTH                  ( 32                                ),
    .DATA_WIDTH                     ( 16                                )
)dynamic_lowpass_inst (
    .clk_i                          ( clk_100m                          ),
    .rst_i                          ( rst_100m                          ),
    .laser_start_i                  ( real_adc_start                    ),
    .lowpass_para_data_i            ( lowpass_para_data                 ),
    .laser_vld_i                    ( lp_recover_vld                    ),
    .laser_data_i                   ( lp_recover_data                   ),

    .lp_laser_vld_o                 ( lpf_laser_vld                     ),
    .lp_laser_data_o                ( lpf_laser_data                    )
);

reg_delay #(
    .DATA_WIDTH                     ( 2                                 ),
    .DELAY_NUM                      ( 32                                )
)lp_reg_delay_inst(
    .clk_i                          ( clk_100m                          ),
    .src_data_i                     ( {lp_recover_acc_flag,lp_recover_zero_flag} ),
    .delay_data_o                   ( {lpf_acc_flag,lpf_zero_flag}      )
);

`else

assign lpf_acc_flag     = lp_recover_acc_flag;
assign lpf_zero_flag    = lp_recover_zero_flag;
assign lpf_laser_vld    = lp_recover_vld ;
assign lpf_laser_data   = lp_recover_data;
`endif // DYNAMIC_LOWPASS_MOD



`ifdef DOWN_SAMPLE_MOD

uniform_downsample uniform_downsample_inst(
    .clk_i                          ( clk_100m                          ),
    .rst_i                          ( rst_100m                          ),

    .ds_para_en_i                   ( ds_para_en                        ),
    .ds_para_h_i                    ( ds_para_h                         ),
    .ds_para_l_i                    ( ds_para_l                         ),

    .laser_start_i                  ( real_adc_start                    ),
    .acc_flag_i                     ( lpf_acc_flag                      ),
    .zero_flag_i                    ( lpf_zero_flag                     ),
    .laser_vld_i                    ( lpf_laser_vld                     ),
    .laser_data_i                   ( lpf_laser_data                    ),

    .ds_acc_flag_o                  ( ds_acc_flag                       ),
    .ds_zero_flag_o                 ( ds_zero_flag                      ),
    .ds_laser_vld_o                 ( ds_laser_vld                      ),
    .ds_laser_data_o                ( ds_laser_data                     ),
    .ds_laser_lost_o                ( ds_laser_lost                     )
);

`else

assign ds_acc_flag   = lpf_acc_flag  ;
assign ds_zero_flag  = lpf_zero_flag ;
assign ds_laser_vld  = lpf_laser_vld ;
assign ds_laser_data = lpf_laser_data;
assign ds_laser_lost = 'd0;
`endif // DOWN_SAMPLE_MOD


`ifdef FIR_MOD
fir_ctrl_v2 #(
    .FIR_TAP_NUM                    ( 51                                )
)fir_ctrl_inst(
    .clk_i                          ( clk_100m                          ),
    .rst_i                          ( rst_100m                          ),

    .laser_fir_upmode_i             ( laser_fir_upmode                  ),
    .laser_fir_en_i                 ( laser_fir_en                      ),

    .fir_tap_vld_i                  ( fir_tap_vld                       ),
    .fir_tap_addr_i                 ( fir_tap_addr                      ),
    .fir_tap_data_i                 ( fir_tap_data                      ),

    .zero_flag_i                    ( ds_acc_flag                       ),
    .acc_flag_i                     ( ds_zero_flag                      ),
    .laser_vld_i                    ( ds_laser_vld                      ),
    .laser_data_i                   ( ds_laser_data                     ),
    .ds_laser_lost_i                ( ds_laser_lost                     ),

    .fir_ds_lost_o                  ( fir_ds_lost                       ),
    .fir_acc_flag_o                 ( fir_acc_flag                      ),
    .fir_zero_flag_o                ( fir_zero_flag                     ),
    .fir_laser_vld_o                ( fir_laser_vld                     ),
    .fir_laser_data_o               ( fir_laser_data                    )
);

`else
assign fir_ds_lost          = ds_laser_lost ;
assign fir_acc_flag         = ds_acc_flag   ;
assign fir_zero_flag        = ds_zero_flag  ;
assign fir_laser_vld        = ds_laser_vld  ;
assign fir_laser_data       = ds_laser_data ;
`endif // FIR_MOD

// data folding, for ACC align
fir_post_process fir_post_process_inst(
    // clk & rst 
    .clk_i                          ( clk_100m                          ),
    .rst_i                          ( rst_100m                          ),

    .laser_start_i                  ( real_adc_start                    ),
    .fir_laser_zero_flag_i          ( fir_zero_flag                     ),
    .fir_acc_flag_i                 ( fir_acc_flag                      ),
    .fir_laser_data_i               ( fir_laser_data                    ),
    .fir_ds_lost_i                  ( fir_ds_lost                       ),

    .circle_lose_num_i              ( circle_lose_num                   ),
    .circle_lose_num_delta_i        ( circle_lose_num_delta             ),

    .fir_post_zero_flag_o           ( fir_post_zero_flag                ),
    .fir_post_acc_flag_o            ( fir_post_acc_flag                 ),
    .fir_post_vld_o                 ( fir_post_vld                      ),
    .fir_post_data_o                ( fir_post_data                     )
);

`ifdef HAZE_MOD
// calculate haze
haze_generate #(
    .DATA_WIDTH                     ( 16                                ) 
)haze_generate_inst(
    // clk & rst 
    .clk_i                          ( clk_100m                          ),
    .rst_i                          ( rst_100m                          ),

    .laser_vld_i                    ( fir_laser_vld                     ),
    .laser_data_i                   ( fir_laser_data                    ),

    .haze_data_o                    ( laser_haze_data                   )
);
`else
assign laser_haze_data = 'd0;

`endif // HAZE_MOD


// testbench logic
always @(posedge clk_100m) begin
    if(real_adc_start)begin
        adc_data_en <= #TCQ 'd1;
        adc_data    <= #TCQ adc_data + 'd1;
    end
    else begin
        adc_data_en <= #TCQ 'd0;
        adc_data    <= #TCQ 'd0;
    end
end

initial
begin
    wait(~rst_100m);
    #(PERIOD*100);
    track_para_en = 1;
    laser_fir_en = 1;
    #10000;
    real_adc_start = 1;
    #1000000;
    wafer_zero_flag = 1;
    #10;
    wafer_zero_flag = 0;

    #500000;
    filter_acc_flag = 1;
    #100000;
    filter_acc_flag = 0;

    #400000;
    wafer_zero_flag = 1;
    #10;
    wafer_zero_flag = 0;
    #1000000;
    $finish;
end

endmodule