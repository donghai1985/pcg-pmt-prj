`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: zas
// Engineer: songyuxin
// 
// Create Date: 2023/06/19
// Design Name: PCG
// Module Name: spi_reg_map
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


module spi_reg_map #(
    parameter                               TCQ        = 0.1,
    parameter                               DATA_WIDTH = 32 ,
    parameter                               ADDR_WIDTH = 16 ,
    parameter       [32*5-1:0]              pmt_mfpga_version = "PCG1_PMTM_v1.0      "
)(
    // clk & rst
    input   wire                            clk_i               ,
    input   wire                            rst_i               ,

    input   wire                            slave_wr_en_i       ,
    input   wire    [ADDR_WIDTH-1:0]        slave_addr_i        ,
    input   wire    [DATA_WIDTH-1:0]        slave_wr_data_i     ,
    input   wire                            slave_rd_en_i       ,
    output  wire                            slave_rd_vld_o      ,
    output  wire    [DATA_WIDTH-1:0]        slave_rd_data_o     ,

    output  wire    [32-1:0]                first_reg_o         ,
    // output  wire                            encode_update_o     ,
    // output  wire    [16-1:0]                encode_w_o          ,
    // output  wire    [16-1:0]                encode_x_o          ,
    // output  wire    [1-1:0]                 laser_adc_start_o   ,
    // output  wire    [1-1:0]                 laser_adc_stop_o    ,
    output  wire    [1-1:0]                 laser_adc_test_o    ,

    output  wire                            ad5592_1_dac_config_en_o    ,
    output  wire    [2:0]                   ad5592_1_dac_channel_o      ,
    output  wire    [11:0]                  ad5592_1_dac_data_o         ,
    output  wire                            ADC_offset_en_o             ,
    output  wire    [16-1:0]                ADC_offset_o                ,
    output                                  bst_vcc_en_o                ,

    output  wire    [16-1:0]                circle_lose_num_o           ,
    output  wire    [16-1:0]                circle_lose_num_delta_o     ,
    output  wire    [16-1:0]                uniform_circle_o            ,
    input   wire    [16-1:0]                detect_width_para_i         ,  // 2 * light spot, down sample adc
    output                                  pre_track_dbg_o             ,
    output  wire    [16-1:0]                light_spot_spacing_o        ,
    output  wire    [16-1:0]                check_window_o              ,
    output          [16-1:0]                haze_up_limit_o             ,

    output  wire                            acc_defect_en_o             ,
    output  wire    [16-1:0]                pre_acc_curr_thre_o         ,
    output  wire    [16-1:0]                actu_acc_curr_thre_o        ,
    output  wire    [16-1:0]                actu_acc_cache_thre_o       ,
    output  wire    [3-1:0]                 particle_acc_bypass_o       ,
    output                                  first_track_ctrl_o          ,

    output  wire    [16-1:0]                lp_recover_factor_o         ,
    output  wire                            acc_cali_mode_o             ,
    output  wire    [32-1:0]                acc_cali_low_o              ,
    output  wire    [32-1:0]                acc_cali_high_o             ,

    // output          [16-1:0]                acc_trig_delay_o            ,
    output          [16-1:0]                aom_ctrl_delay_o            ,
    output          [16-1:0]                aom_ctrl_hold_o             ,
    output          [16-1:0]                lp_recover_delay_o          ,
    output          [16-1:0]                lp_recover_hold_o           ,
    output          [16-1:0]                recover_edge_slot_time_o    ,
    output                                  aurora_upmode_o             ,
    output                                  laser_acc_flag_upmode_o     ,

    output                                  laser_fir_en_o              ,
    output                                  laser_fir_upmode_o          ,
    output                                  track_para_en_o             ,
    input           [32-1:0]                acc_trigger_num_i           ,
    input           [16-1:0]                track_para_burst_line_i     ,
    
    input           [32-1:0]                dbg_acc_flag_cnt_i          ,
    input           [32-1:0]                pre_widen_result_cnt_i      ,
    input           [32-1:0]                curr_widen_result_cnt_i     ,
    input           [32-1:0]                cache_widen_result_cnt_i    ,
    output  wire                            debug_info
);


//////////////////////////////////////////////////////////////////////////////////
// *********** Define Parameter Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>






//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Register Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
reg                                 slave_rd_vld_r          = 'd0;
reg     [DATA_WIDTH-1:0]            slave_rd_data_r         = 'd0;

(*dont_touch = "true"*)reg     [32-1:0]                    first_reg               = 'd0;
reg                                 encode_update           = 'd0;
reg     [32-1:0]                    encode_w                = 'd0;
reg     [32-1:0]                    encode_x                = 'd0;
reg     [8-1:0]                     laser_adc_start         = 'd0;
reg     [8-1:0]                     laser_adc_stop          = 'd0;

reg                                 set_pmt_hv_en           = 'd0;
reg     [32-1:0]                    SetPMTHV                = 'd0;
reg                                 ADC_offset_en           = 'd0;
reg     [32-1:0]                    ADC_offset              = 'd0;
reg                                 bst_vcc_en              = 'd1;
reg                                 pmt_test_en             = 'd0;

`ifdef SIMULATE
reg     [16-1:0]                    circle_lose_num         = 'd4285;
reg     [16-1:0]                    circle_lose_num_delta   = 'd875;
reg     [16-1:0]                    uniform_circle          = 'd313;
reg                                 pre_track_dbg           = 'd0;
reg     [16-1:0]                    light_spot_spacing      = 'd55;
reg     [16-1:0]                    check_window            = 'd1;
reg     [16-1:0]                    haze_up_limit           = 'd10000;

reg                                 acc_defect_en           = 'd1;
reg     [16-1:0]                    pre_acc_curr_thre       = 'd30000;
reg     [16-1:0]                    actu_acc_curr_thre      = 'd30000;
reg     [16-1:0]                    actu_acc_cache_thre     = 'd30000;
reg     [3-1:0]                     particle_acc_bypass     = 'd5;
reg                                 first_track_ctrl        = 'd1;

reg     [16-1:0]                    lp_recover_factor       = 'h100;  // 100.5 * 2^20
reg                                 acc_cali_mode           = 'd0;
reg     [32-1:0]                    acc_cali_low            = 'd600;
reg     [32-1:0]                    acc_cali_high           = 'd400;
reg     [16-1:0]                    acc_trig_delay          = 'd10;
reg     [16-1:0]                    aom_ctrl_delay          = 'd4;
reg     [16-1:0]                    aom_ctrl_hold           = 'd2;
reg     [16-1:0]                    lp_recover_delay        = 'd4;
reg     [16-1:0]                    lp_recover_hold         = 'd2;
reg     [16-1:0]                    recover_edge_slot_time  = 'd12;

reg                                 aurora_upmode           = 'd0;
reg                                 laser_acc_flag_upmode   = 'd0;
reg                                 laser_fir_upmode        = 'd0;
`else
reg     [16-1:0]                    circle_lose_num         = 'd0;
reg     [16-1:0]                    circle_lose_num_delta   = 'd0;
reg     [16-1:0]                    uniform_circle          = 'd0;
reg                                 pre_track_dbg           = 'd0;
reg     [16-1:0]                    light_spot_spacing      = 'd0;
reg     [16-1:0]                    check_window            = 'd0;
reg     [16-1:0]                    haze_up_limit           = 'd10000;

reg                                 acc_defect_en           = 'd0;
reg     [16-1:0]                    pre_acc_curr_thre       = 'd0;
reg     [16-1:0]                    actu_acc_curr_thre      = 'd0;
reg     [16-1:0]                    actu_acc_cache_thre     = 'd0;
reg     [3-1:0]                     particle_acc_bypass     = 'd0;
reg                                 first_track_ctrl        = 'd1;

reg     [16-1:0]                    lp_recover_factor       = 'h100;
reg                                 acc_cali_mode           = 'd0;
reg     [32-1:0]                    acc_cali_low            = 'd8000000; // 800ms
reg     [32-1:0]                    acc_cali_high           = 'd2000000; // 200ms
reg     [16-1:0]                    acc_trig_delay          = 'd0;
reg     [16-1:0]                    aom_ctrl_delay          = 'd0;
reg     [16-1:0]                    aom_ctrl_hold           = 'd0;
reg     [16-1:0]                    lp_recover_delay        = 'd0;
reg     [16-1:0]                    lp_recover_hold         = 'd0;
reg     [16-1:0]                    recover_edge_slot_time  = 'd0;

reg                                 aurora_upmode           = 'd0;
reg                                 laser_acc_flag_upmode   = 'd0;
reg                                 laser_fir_upmode        = 'd0;
`endif //SIMULATE

reg                                 laser_fir_en            = 'd0;
reg                                 track_para_en           = 'd0;

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Wire Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>



//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Instance Module
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Logic Design
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
// write register
always @(posedge clk_i) begin
    if(slave_wr_en_i)begin
        case (slave_addr_i)
            16'h000c: first_reg                 <= #TCQ slave_wr_data_i;
            16'h0004: encode_w                  <= #TCQ slave_wr_data_i;
            16'h0008: encode_x                  <= #TCQ slave_wr_data_i;
            16'h0014: acc_defect_en             <= #TCQ slave_wr_data_i;
            16'h0018: ADC_offset                <= #TCQ slave_wr_data_i;
            16'h001c: SetPMTHV                  <= #TCQ slave_wr_data_i;
            16'h0020: bst_vcc_en                <= #TCQ slave_wr_data_i[0];
            16'h0024: pmt_test_en               <= #TCQ slave_wr_data_i[0];

            // 16'h0028: circle_lose_num           <= #TCQ slave_wr_data_i;
            16'h002c: pre_track_dbg             <= #TCQ slave_wr_data_i;
            16'h0034: light_spot_spacing        <= #TCQ slave_wr_data_i;
            
            16'h0038: pre_acc_curr_thre         <= #TCQ slave_wr_data_i;
            16'h003c: actu_acc_curr_thre        <= #TCQ slave_wr_data_i;
            16'h0040: actu_acc_cache_thre       <= #TCQ slave_wr_data_i;
            16'h0044: particle_acc_bypass       <= #TCQ slave_wr_data_i;
            16'h0048: first_track_ctrl          <= #TCQ slave_wr_data_i[0];
            // 16'h004c: lp_actu_acc_cache_thre    <= #TCQ slave_wr_data_i;

            16'h0050: lp_recover_factor         <= #TCQ slave_wr_data_i;
            16'h0054: acc_cali_mode             <= #TCQ slave_wr_data_i;
            16'h0058: acc_cali_low              <= #TCQ slave_wr_data_i;
            16'h005c: acc_cali_high             <= #TCQ slave_wr_data_i;

            16'h0060: check_window              <= #TCQ slave_wr_data_i;
            16'h0064: haze_up_limit             <= #TCQ slave_wr_data_i;
            16'h0068: aom_ctrl_delay            <= #TCQ slave_wr_data_i;
            16'h006c: aom_ctrl_hold             <= #TCQ slave_wr_data_i;
            16'h0070: lp_recover_delay          <= #TCQ slave_wr_data_i;
            16'h0074: lp_recover_hold           <= #TCQ slave_wr_data_i;
            16'h007c: recover_edge_slot_time    <= #TCQ slave_wr_data_i;

            16'h0100: laser_fir_en              <= #TCQ slave_wr_data_i[0];
            16'h0104: aurora_upmode             <= #TCQ slave_wr_data_i[0];
            16'h0108: laser_fir_upmode          <= #TCQ slave_wr_data_i[0];
            16'h010c: track_para_en             <= #TCQ slave_wr_data_i[0];
            16'h0110: laser_acc_flag_upmode     <= #TCQ slave_wr_data_i[0];
            
            default: /*default*/;
        endcase
    end
end



// read register
always @(posedge clk_i) begin
    if(slave_rd_en_i)begin
        case (slave_addr_i)
            16'h000c: slave_rd_data_r <= #TCQ first_reg                 ;
            16'h0004: slave_rd_data_r <= #TCQ encode_w                  ;
            16'h0008: slave_rd_data_r <= #TCQ encode_x                  ;
            16'h0014: slave_rd_data_r <= #TCQ acc_defect_en             ;
            16'h0018: slave_rd_data_r <= #TCQ ADC_offset                ;
            16'h001c: slave_rd_data_r <= #TCQ SetPMTHV                  ;
            16'h0020: slave_rd_data_r <= #TCQ {31'd0,bst_vcc_en}        ;
            16'h0024: slave_rd_data_r <= #TCQ {31'd0,pmt_test_en}       ;

            // 16'h0028: slave_rd_data_r <= #TCQ circle_lose_num           ;
            16'h002c: slave_rd_data_r <= #TCQ pre_track_dbg             ;
            16'h0030: slave_rd_data_r <= #TCQ detect_width_para_i       ;
            16'h0034: slave_rd_data_r <= #TCQ light_spot_spacing        ;

            16'h0038: slave_rd_data_r <= #TCQ pre_acc_curr_thre         ;
            16'h003c: slave_rd_data_r <= #TCQ actu_acc_curr_thre        ;
            16'h0040: slave_rd_data_r <= #TCQ actu_acc_cache_thre       ;
            16'h0044: slave_rd_data_r <= #TCQ particle_acc_bypass       ;
            16'h0048: slave_rd_data_r <= #TCQ {31'd0,first_track_ctrl}  ;
            // 16'h004c: slave_rd_data_r <= #TCQ lp_actu_acc_cache_thre    ;

            16'h0050: slave_rd_data_r <= #TCQ lp_recover_factor         ;
            16'h0054: slave_rd_data_r <= #TCQ acc_cali_mode             ;
            16'h0058: slave_rd_data_r <= #TCQ acc_cali_low              ;
            16'h005c: slave_rd_data_r <= #TCQ acc_cali_high             ;

            16'h0060: slave_rd_data_r <= #TCQ check_window              ;
            16'h0064: slave_rd_data_r <= #TCQ haze_up_limit             ;
            16'h0068: slave_rd_data_r <= #TCQ aom_ctrl_delay            ;
            16'h006c: slave_rd_data_r <= #TCQ aom_ctrl_hold             ;
            16'h0070: slave_rd_data_r <= #TCQ lp_recover_delay          ;
            16'h0074: slave_rd_data_r <= #TCQ lp_recover_hold           ;
            16'h0078: slave_rd_data_r <= #TCQ acc_trigger_num_i         ;
            16'h007c: slave_rd_data_r <= #TCQ recover_edge_slot_time    ;
            16'h0080: slave_rd_data_r <= #TCQ track_para_burst_line_i   ;

            16'h0100: slave_rd_data_r <= #TCQ {31'd0,laser_fir_en}      ;
            16'h0104: slave_rd_data_r <= #TCQ {31'd0,aurora_upmode}     ;
            16'h0108: slave_rd_data_r <= #TCQ {31'd0,laser_fir_upmode}  ;
            16'h010c: slave_rd_data_r <= #TCQ {31'd0,track_para_en}     ;
            16'h0110: slave_rd_data_r <= #TCQ {31'd0,laser_acc_flag_upmode};

            16'h1000: slave_rd_data_r <= #TCQ pmt_mfpga_version[32*4 +: 32];
            16'h1004: slave_rd_data_r <= #TCQ pmt_mfpga_version[32*3 +: 32];
            16'h1008: slave_rd_data_r <= #TCQ pmt_mfpga_version[32*2 +: 32];
            16'h100c: slave_rd_data_r <= #TCQ pmt_mfpga_version[32*1 +: 32];
            16'h1010: slave_rd_data_r <= #TCQ pmt_mfpga_version[32*0 +: 32];

            16'h1100: slave_rd_data_r <= #TCQ dbg_acc_flag_cnt_i        ;
            16'h1104: slave_rd_data_r <= #TCQ pre_widen_result_cnt_i    ;
            16'h1108: slave_rd_data_r <= #TCQ curr_widen_result_cnt_i   ;
            16'h110c: slave_rd_data_r <= #TCQ cache_widen_result_cnt_i  ;
            
            default: slave_rd_data_r <= #TCQ 32'h00DEAD00;
        endcase
    end
end

// use valid control delay, ability to align register with fifo output.
always @(posedge clk_i) begin
    slave_rd_vld_r <= #TCQ slave_rd_en_i;
end

always @(posedge clk_i) begin
    if(slave_wr_en_i && slave_addr_i=='h001c)
        set_pmt_hv_en <= #TCQ 'd1;
    else 
        set_pmt_hv_en <= #TCQ 'd0;
end

always @(posedge clk_i) begin
    if(slave_wr_en_i && slave_addr_i=='h0018)
        ADC_offset_en <= #TCQ 'd1;
    else 
        ADC_offset_en <= #TCQ 'd0;
end

assign slave_rd_vld_o           = slave_rd_vld_r            ;
assign slave_rd_data_o          = slave_rd_data_r           ;

assign first_reg_o              = first_reg                 ;
assign laser_adc_test_o         = pmt_test_en               ;
assign ad5592_1_dac_config_en_o = set_pmt_hv_en             ;
assign ad5592_1_dac_channel_o   = 3'd6                      ;
assign ad5592_1_dac_data_o      = SetPMTHV[11:0]            ;
assign ADC_offset_en_o          = ADC_offset_en             ;
assign ADC_offset_o             = ADC_offset[15:0]          ;
assign bst_vcc_en_o             = bst_vcc_en                ;

// assign circle_lose_num_o        = circle_lose_num           ;
// assign circle_lose_num_delta_o  = circle_lose_num_delta     ;
// assign uniform_circle_o         = uniform_circle            ;
assign pre_track_dbg_o          = pre_track_dbg             ;
assign light_spot_spacing_o     = light_spot_spacing        ;
assign check_window_o           = check_window              ;
assign haze_up_limit_o          = haze_up_limit             ;

assign acc_defect_en_o          = acc_defect_en             ;
assign pre_acc_curr_thre_o      = pre_acc_curr_thre         ;
assign actu_acc_curr_thre_o     = actu_acc_curr_thre        ;
assign actu_acc_cache_thre_o    = actu_acc_cache_thre       ;
assign particle_acc_bypass_o    = particle_acc_bypass       ;
assign first_track_ctrl_o       = first_track_ctrl          ;

assign lp_recover_factor_o      = lp_recover_factor         ;
assign acc_cali_mode_o          = acc_cali_mode             ;
assign acc_cali_low_o           = acc_cali_low              ;
assign acc_cali_high_o          = acc_cali_high             ;
// assign acc_trig_delay_o         = acc_trig_delay            ;
assign aom_ctrl_delay_o         = aom_ctrl_delay            ;
assign aom_ctrl_hold_o          = aom_ctrl_hold             ; 
assign lp_recover_delay_o       = lp_recover_delay          ;
assign lp_recover_hold_o        = lp_recover_hold           ;
assign recover_edge_slot_time_o = recover_edge_slot_time    ;
assign laser_fir_en_o           = laser_fir_en              ;
assign aurora_upmode_o          = aurora_upmode             ;
assign laser_acc_flag_upmode_o  = laser_acc_flag_upmode     ;
assign laser_fir_upmode_o       = laser_fir_upmode          ;
assign track_para_en_o          = track_para_en             ;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

endmodule
