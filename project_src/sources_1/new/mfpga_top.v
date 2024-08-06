`timescale 1ns / 1ns
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/09/23 17:00:14
// Design Name: 
// Module Name: mfpga_top
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
`define AURORA_MOD
`define FIR_MOD
`define HAZE_MOD
`define DYNAMIC_LOWPASS_MOD
// `define DOWN_SAMPLE_MOD

module mfpga_top(
		//sys io
		input	wire		FPGA_RESET, 
		input	wire		CLK_SEL,
		input	wire		USER_SMA_CLOCK,
		input	wire		FPGA_MASTER_CLOCK_P,
		input	wire		FPGA_MASTER_CLOCK_N,
		input	wire		TIMING_SYNC_REFCLK_P,
		input	wire		TIMING_SYNC_REFCLK_N,
		//sfp serdes
		input	wire		SFP_MGT_REFCLK_C_P, 
		input	wire		SFP_MGT_REFCLK_C_N, 
		input	wire 		FPGA_SFP1_RX_P, 
		input	wire 		FPGA_SFP1_RX_N,  
		output	wire 		FPGA_SFP1_TX_P, 
		output	wire 		FPGA_SFP1_TX_N, 
		//AD9265
		input	wire [15:0]	AD9265_DATA,
		input	wire		AD9265_DCO,
		input	wire		AD9265_OR,
		output	wire		AD9265_SYNC,
		output	wire		AD9265_PDWN,
		output	wire		AD9265_SCLK,
		output	wire		AD9265_CSB,
		inout	wire		AD9265_SDIO,
		//eeprom 
		// output	wire		EEPROM_CS_B, 
		// input	wire		EEPROM_SO, 
		// output	wire		EEPROM_SI, 
		// output	wire		EEPROM_WP_B, 
		// output	wire		EEPROM_SCK, 
		//tmp75
		// inout	wire		TMP75_IIC_SDA, 
		// output	wire		TMP75_IIC_SCL, 
		// input	wire		TMP75_ALERT, 
		//status io
		input	wire		DDR_POWER_GOOD, 
		input	wire		VCC3V3_PG, 
		input	wire		MGTAVTT_PG, 
		input	wire		VCC3V6_PG, 
		input	wire		VCC_3V_A_PG, 
		//power en
		output	wire		VCC12V_FAN_EN, 
		output	wire		TIMING_LVDS_EN,
		//SPI
        input   wire        TIMING_SPI_MCLK_P       ,  // timing_spi_2
        input   wire        TIMING_SPI_MCLK_N       ,  // timing_spi_2
        input   wire        TIMING_SPI_MOSI_P       ,  // timing_spi_2
        input   wire        TIMING_SPI_MOSI_N       ,  // timing_spi_2
        output  wire        TIMING_SPI_SCLK_P       ,  // timing_spi_2
        output  wire        TIMING_SPI_SCLK_N       ,  // timing_spi_2
        output  wire        TIMING_SPI_MISO_P       ,  // timing_spi_2
        output  wire        TIMING_SPI_MISO_N       ,  // timing_spi_2
        // ENCODE
        input   wire        ENCODE_MCLK_P           ,
        input   wire        ENCODE_MCLK_N           ,
        input   wire        ENCODE_MOSI_P           ,
        input   wire        ENCODE_MOSI_N           ,
        // ACC
        output  wire        ACC_SCLK_P              ,
        output  wire        ACC_SCLK_N              ,
        output  wire        ACC_MISO_P              ,
        output  wire        ACC_MISO_N              ,
        // AOM 固定电平
        input   wire        RF_ENABLE               ,
        input   wire        RF_FAULT                ,
		//sfp1 io
		input	wire		FPGA_SFP1_TX_FAULT, 
		output	wire		FPGA_SFP1_TX_DISABLE, 
		input	wire		FPGA_SFP1_MOD_DETECT, 
		input	wire		FPGA_SFP1_LOS, 
		output	wire		FPGA_SFP1_IIC_SCL, 
		inout	wire		FPGA_SFP1_IIC_SDA, 
		//sfp2 io
		input	wire		FPGA_SFP2_TX_FAULT, 
		output	wire		FPGA_SFP2_TX_DISABLE, 
		input	wire		FPGA_SFP2_MOD_DETECT, 
		input	wire		FPGA_SFP2_LOS, 
		output	wire		FPGA_SFP2_IIC_SCL, 
		inout	wire		FPGA_SFP2_IIC_SDA, 
		//ddr3
		inout	wire [31:0]	DDR3_A_D, 
		inout	wire [3:0] 	DDR3_A_DQS_P,
		inout	wire [3:0] 	DDR3_A_DQS_N,
		output	wire [3:0]	DDR3_A_DM,
		output	wire [15:0]	DDR3_A_ADD, 
		output	wire [2:0]	DDR3_A_BA,
		output	wire		DDR3_A_CKE, 
		output	wire		DDR3_A_WE_B, 
		output	wire		DDR3_A_RAS_B, 
		output	wire		DDR3_A_CAS_B, 
		output	wire		DDR3_A_S0_B, 
		output	wire		DDR3_A_ODT, 
		output	wire		DDR3_A_RESET_B,   
		output	wire		DDR3_A_CLK0_P, 
		output	wire		DDR3_A_CLK0_N,
		//fan
		input	wire		FAN_FG, 
		//ad5592
		output	wire		AD5592_1_SPI_CS_B, 
		output	wire		AD5592_1_SPI_CLK, 
		output	wire		AD5592_1_SPI_MOSI, 
		input	wire		AD5592_1_SPI_MISO, 
        // cdcm61001
        output  wire        FPGA_PLL_CLK_IN         ,
        output  wire        FPGA_PLL_PR0            ,
        output  wire        FPGA_PLL_PR1            ,
        output  wire        FPGA_PLL_OD0            ,
        output  wire        FPGA_PLL_OD1            ,
        output  wire        FPGA_PLL_OD2            ,
        output  wire        FPGA_PLL_CE             ,
        output  wire        FPGA_PLL_RST_N          ,
        // VCC12V
        output  wire        FPGA_VCC12V_BST_EN      ,
        // ad5542
        output  wire        FPGA_DAC_SPI_CS_N       ,
        output  wire        FPGA_DAC_SPI_SCLK       ,
        output  wire        FPGA_DAC_SPI_DIN        ,
        output  wire        FPGA_DAC_CLR_N          ,
		//
		input	wire		FPGA_TO_SFPGA_RESERVE0, 	//clk
		input	wire		FPGA_TO_SFPGA_RESERVE1, 	//fsr
		input	wire		FPGA_TO_SFPGA_RESERVE2, 	//rx
		output	wire		FPGA_TO_SFPGA_RESERVE3,		//fsx	
		output	wire		FPGA_TO_SFPGA_RESERVE4, 	//tx
		output	wire		FPGA_TO_SFPGA_RESERVE5, 	//reserved
		input	wire		FPGA_TO_SFPGA_RESERVE6, 	//reserved 
		input	wire		FPGA_TO_SFPGA_RESERVE7, 	//reserved 
		input	wire		FPGA_TO_SFPGA_RESERVE8, 	//reserved 
		input	wire		FPGA_TO_SFPGA_RESERVE9, 	//reserved
		//test io
		// output	wire		TP102,
		// output	wire		TP103,
		// output	wire		TP104,
		// output	wire		TP105,
		// output	wire		TP106,
		output	wire		TP112,
		output	wire		TP113,
		output	wire		TP114,
		output	wire		TP115
);

genvar i;

parameter                   TCQ                 = 0.1   ;
parameter                   DATA_WIDTH          = 32    ;
parameter                   ADDR_WIDTH          = 16    ;
parameter                   LOWPASS_PARA_NUM    = 1     ;
parameter                   FIR_TAP_NUM         = 51    ;
parameter                   DS_PARA_NUM         = 2     ;
parameter                   VERSION             = "PCG_PMTM_v1.5.5     ";

// PMT spi slave
wire                        slave_wr_en                 ;
wire    [ADDR_WIDTH-1:0]    slave_addr                  ;
wire    [DATA_WIDTH-1:0]    slave_wr_data               ;
wire                        slave_rd_en                 ;
wire                        slave_rd_vld                ;
wire    [DATA_WIDTH-1:0]    slave_rd_data               ;
// udp slave
wire                        slave_tx_ack                ;
wire                        slave_tx_byte_en            ;
wire    [ 7:0]              slave_tx_byte               ;
wire                        slave_tx_byte_num_en        ;
wire    [15:0]              slave_tx_byte_num           ;
wire                        slave_rx_data_vld           ;
wire    [ 7:0]              slave_rx_data               ;
// readback ddr
wire    [32-1:0]            ddr_rd_addr                 ;
wire                        ddr_rd_en                   ;
wire                        readback_vld                ;
wire                        readback_last               ;
wire    [32-1:0]            readback_data               ;
// write fir tap to ddr
wire                        track_para_wr_cmd           ;
wire    [32-1:0]            track_para_wr_addr          ;
wire                        track_para_wr_vld           ;
wire    [32-1:0]            track_para_wr_data          ;

// track parameter
wire    [16-1:0]            track_para_burst_line       ;
wire                        track_para_en               ;
wire                        track_para_burst_end        ;
wire                        track_para_vld              ;
wire    [32-1:0]            track_para_data             ;
wire                        track_para_ready            ;
wire                        track_para_ren              ;
wire                        delay_zero_flag             ;

wire                        ds_para_en                  ;
wire    [32-1:0]            ds_para_h                   ;
wire    [32-1:0]            ds_para_l                   ;

wire                        lowpass_para_vld            ;
wire    [32-1:0]            lowpass_para_data           ;
wire    [16-1:0]            aom_ctrl_delay_abs          ;
wire    [16-1:0]            light_spot_para             ;
wire    [16-1:0]            detect_width_para           ;

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
wire                        fir_post_delay_vld          ;
wire                        fir_post_pre_vld            ;
wire                        fir_post_vld                ;
wire    [16-1:0]            fir_post_data               ;

// pingpang mem
wire                        pre_track_acc_flag          ;
wire                        pre_track_mema_start        ;
wire                        pre_track_mema_vld          ;
wire    [32-1:0]            pre_track_mema_data         ;
wire                        pre_track_memb_start        ;
wire                        pre_track_memb_vld          ;
wire    [32-1:0]            pre_track_memb_data         ;

wire                        pre_track_mema_rd_start     ;
wire                        pre_track_mema_ready        ;
wire                        pre_track_mema_rd_vld       ;
wire                        pre_track_mema_rd_seq       ;
wire    [64-1:0]            pre_track_mema_rd_data      ;
wire                        pre_track_memb_rd_start     ;
wire                        pre_track_memb_ready        ;
wire                        pre_track_memb_rd_vld       ;
wire                        pre_track_memb_rd_seq       ;
wire    [64-1:0]            pre_track_memb_rd_data      ;

// fir tap setting
wire                        laser_fir_upmode            ;
wire                        laser_fir_en                ;

// haze
wire    [16-1:0]            haze_up_limit               ;
wire    [16-1:0]            laser_haze_data             ;

// ACC ctrl parameter
wire                        fir_post_para_en            ;
wire    [16-1:0]            circle_lose_num             ;
wire    [16-1:0]            track_align_num             ;
wire    [16-1:0]            uniform_circle_num          ;
wire    [16-1:0]            acc_detect_width            ;
wire                        pre_track_dbg               ;
wire    [16-1:0]            light_spot_spacing          ;
wire    [16-1:0]            check_window                ;
wire                        pre_track_result            ;

// wire                        acc_track_para_wr           ;
// wire    [16-1:0]            acc_track_para_addr         ;
// wire    [16-1:0]            acc_track_para_data         ;

wire                        acc_defect_en               ;
wire    [16-1:0]            pre_acc_curr_thre           ;
wire    [16-1:0]            actu_acc_curr_thre          ;
wire    [16-1:0]            actu_acc_cache_thre         ;
wire    [3-1:0]             particle_acc_bypass         ;
wire                        first_track_ctrl            ;

wire                        filter_acc_delay_vld        ;
wire                        filter_acc_flag             ;
wire                        filter_acc_vld              ;
wire    [16-1:0]            filter_acc_data             ;
wire    [16-1:0]            filter_acc_haze             ;
wire    [16-1:0]            filter_acc_haze_hub         ;
wire                        filter_acc_result           ;

wire    [16-1:0]            acc_trig_delay              ;
wire    [16-1:0]            aom_ctrl_delay              ;
wire    [16-1:0]            aom_ctrl_hold               ;
wire    [16-1:0]            lp_recover_delay            ;
wire    [16-1:0]            lp_recover_hold             ;
wire    [16-1:0]            recover_edge_slot_time      ;

wire                        aom_ctrl_flag               ;
wire    [32-1:0]            acc_trigger_num             ;
wire                        recover_edge_flag           ;
wire                        lp_recover_flag             ;

wire                        acc_cali_mode               ;
wire    [32-1:0]            acc_cali_low                ;
wire    [32-1:0]            acc_cali_high               ;
wire                        acc_cali_ctrl               ;
wire                        aurora_upmode               ;
wire                        laser_acc_flag_upmode       ;
wire                        acc_pre_result              ;
wire                        acc_curr_result             ;
wire                        second_track_en             ;

wire    [32-1:0]            pre_widen_result_cnt        ;
wire    [32-1:0]            curr_widen_result_cnt       ;
wire    [32-1:0]            cache_widen_result_cnt      ;
wire    [32-1:0]            dbg_acc_flag_cnt            ;

wire                        FPGA_MASTER_CLOCK           ;
wire                        TIMING_SYNC_REFCLK          ;
wire						FPGA_MASTER_CLOCK_buf		;
wire                        clk_100m                    ;
wire                        clk_200m                    ;
wire                        clk_250m                    ;
wire                        clk_50m                     ;
wire                        clk_25m                     ;
wire                        pll_locked                  ;
wire                        rst_100m                    ;
wire                        gt_rst                      ;
wire                        aurora_rst		            ;

wire                        ddr3_init_done              ;
wire                        CHANNEL_UP_DONE             ;
// reg                         ddr3_init_done_d0   = 'd0   ;
// reg                         CHANNEL_UP_DONE_d0  = 'd0   ;
// reg                         ddr3_init_done_d1   = 'd0   ;
// reg                         CHANNEL_UP_DONE_d1  = 'd0   ;
// reg                         laser_rst_r         = 'd0   ;

wire                        adc_start_sync              ;
wire                        adc_end_sync                ;
wire                        adc_test_sync               ;
// wire                        clear_buffer_sync           ;

wire                        TIMING_SPI_MCLK             ;
wire                        TIMING_SPI_MOSI             ;
wire                        TIMING_SPI_SCLK             ;
wire                        TIMING_SPI_MISO             ;

wire                        ENCODE_MCLK                 ;
wire                        ENCODE_MOSI                 ;

wire                        aurora_log_clk              ;
wire                        aurora_rxen                 ;
wire    [31:0]              aurora_rxdata               ;
wire                        aurora_txen                 ;
wire                        aurora_tx_emp               ;
wire    [10:0]              aurora_rd_data_count        ;
wire    [31:0]              aurora_txdata               ;

wire                        ad9265_init                 ;

wire                        ad5592_1_dac_config_en      ;
wire    [2:0]               ad5592_1_dac_channel        ;
wire    [11:0]              ad5592_1_dac_data           ;
wire                        ad5592_1_adc_config_en      ;
wire    [7:0]               ad5592_1_adc_channel        ;
wire                        ad5592_1_spi_conf_ok        ;
wire                        ad5592_1_init               ;
wire                        ad5592_1_adc_data_en        ;
wire    [11:0]              ad5592_1_adc_data           ;

wire                        temp_rd_en                  ;
wire                        temp_data_en                ;
wire    [11:0]              temp_data                   ;

wire                        eeprom_w_en                 ;
wire    [31:0]              eeprom_w_addr_data          ;
wire                        eeprom_r_addr_en            ;
wire    [15:0]              eeprom_r_addr               ;
wire                        eeprom_r_data_en            ;
wire    [7:0]               eeprom_r_data               ;
wire                        eeprom_spi_ok               ;

wire                        raw_adc_cfg                 ;
wire    [16-1:0]            adc_data                    ;
wire                        adc_data_en                 ;
wire                        adc_start                   ;
wire                        real_adc_start              ;
wire                        aurora_adc_end              ;
wire                        adc_test                    ;
wire                        adc_test_set                ;
wire                        laser_fifo_ready            ;
wire                        pre_laser_rd_seq            ;
wire                        pre_laser_rd_vld            ;
wire    [64-1:0]            pre_laser_rd_data           ;

wire                        encode_update               ;
wire    [16-1:0]            encode_w                    ;
wire    [16-1:0]            encode_x                    ;
wire                        wafer_zero_flag             ;
wire    [16-1:0]            precise_encode_w            ;
wire    [16-1:0]            precise_encode_x            ;

wire                        ad5542_wr_data_en           ;
wire                        ad5542_wr_data_end          ;
wire    [15:0]              ad5542_wr_data              ;
wire                        bst_vcc_en                  ;

// debug ila

assign  TP112                   =	CHANNEL_UP_DONE ;
assign  TP113                   =	ddr3_init_done  ;
assign  TP114                   =	pll_locked      ;
assign  TP115                   =	1'b0;//aurora_log_clk  ;

assign	TIMING_LVDS_EN			=	1'b1;
assign  VCC12V_FAN_EN           =	1'b0;
assign  FPGA_SFP1_TX_DISABLE    =	FPGA_SFP1_MOD_DETECT ? 1'b1 : 1'b0;
assign  FPGA_SFP1_IIC_SCL       =	1'b1;
assign  FPGA_SFP2_TX_DISABLE    =	FPGA_SFP2_MOD_DETECT ? 1'b1 : 1'b0;
assign  FPGA_SFP2_IIC_SCL       =	1'b1;
assign  FPGA_PLL_PR0            =   1'b0;      //PRO:PR1=00  PRESCALER DIVIDER:3 FEEDBACK DIVIDER:24
assign  FPGA_PLL_PR1            =   1'b0;
assign  FPGA_PLL_OD0            =   1'b1;      //OD0:OD2=101 OUTPUT DIVIDER:3   OUTPUT FREQ = 100M
assign  FPGA_PLL_OD1            =   1'b0;
assign  FPGA_PLL_OD2            =   1'b1;

assign  FPGA_PLL_CE             =   1'b1;
assign  FPGA_PLL_RST_N          =   rst_100m ? 1'b0 : 1'b1;

assign  FPGA_PLL_CLK_IN         =   clk_25m;

assign  FPGA_VCC12V_BST_EN      =   bst_vcc_en;  // 1'b1;
assign  FPGA_DAC_CLR_N          =   rst_100m ? 1'b0 : 1'b1;

// assign  RF_ENABLE               =   1'b0;
// assign  RF_FAULT                =   1'b0;

IBUFDS #(
    .DIFF_TERM("TRUE"),       // Differential Termination
    .IBUF_LOW_PWR("FALSE"),     // Low power="TRUE", Highest performance="FALSE" 
    .IOSTANDARD("DEFAULT")     // Specify the input I/O standard
 ) IBUFDS_inst1 (
    .O(FPGA_MASTER_CLOCK),  // Buffer output
    .I(FPGA_MASTER_CLOCK_P),  // Diff_p buffer input (connect directly to top-level port)
    .IB(FPGA_MASTER_CLOCK_N) // Diff_n buffer input (connect directly to top-level port)
 );

IBUFDS #(
    .DIFF_TERM("TRUE"),       // Differential Termination
    .IBUF_LOW_PWR("FALSE"),     // Low power="TRUE", Highest performance="FALSE" 
    .IOSTANDARD("DEFAULT")     // Specify the input I/O standard
 ) IBUFDS_inst2 (
    .O(TIMING_SYNC_REFCLK),  // Buffer output
    .I(TIMING_SYNC_REFCLK_P),  // Diff_p buffer input (connect directly to top-level port)
    .IB(TIMING_SYNC_REFCLK_N) // Diff_n buffer input (connect directly to top-level port)
 );

BUFGMUX #(
   )
   BUFGMUX_inst (
      .O(FPGA_MASTER_CLOCK_buf),	// 1-bit output: Clock output
      .I0(FPGA_MASTER_CLOCK), 		// 1-bit input: Clock input (S=0)
      .I1(TIMING_SYNC_REFCLK), 		// 1-bit input: Clock input (S=1)
      .S(CLK_SEL)    				// 1-bit input: Clock select
   );

pll pll_inst(
    .clk_out1   ( clk_100m          ), 
    .clk_out2   ( clk_200m          ),
    .clk_out3   ( clk_250m          ),
    .clk_out4   ( clk_50m           ),
    .clk_out5   ( clk_25m           ),
    .reset      ( FPGA_RESET        ), 
    .locked     ( pll_locked        ), 
    .clk_in1    ( FPGA_MASTER_CLOCK_buf )
);


IBUFDS #(
      .DIFF_TERM("TRUE"),  			// Differential Termination
      .IBUF_LOW_PWR("FALSE"),  		// Low power="TRUE", Highest performance="FALSE" 
      .IOSTANDARD("DEFAULT")  		// Specify the input I/O standard
   ) TIMING_SPI_MCLK_inst(
		.O(TIMING_SPI_MCLK),  		// Buffer output
		.I(TIMING_SPI_MCLK_P), 		// Diff_p buffer input (connect directly to top-level port)
		.IB(TIMING_SPI_MCLK_N)		// Diff_n buffer input (connect directly to top-level port)
);

IBUFDS #(
      .DIFF_TERM("TRUE"),  			// Differential Termination
      .IBUF_LOW_PWR("FALSE"),  		// Low power="TRUE", Highest performance="FALSE" 
      .IOSTANDARD("DEFAULT")  		// Specify the input I/O standard
   ) TIMING_SPI_MOSI_inst(
		.O(TIMING_SPI_MOSI),  		// Buffer output
		.I(TIMING_SPI_MOSI_P), 		// Diff_p buffer input (connect directly to top-level port)
		.IB(TIMING_SPI_MOSI_N)		// Diff_n buffer input (connect directly to top-level port)
);

OBUFDS #(
      .IOSTANDARD("DEFAULT"), 		// Specify the output I/O standard
      .SLEW("SLOW")           		// Specify the output slew rate
   ) TIMING_SPI_SCLK_inst(
      .O(TIMING_SPI_SCLK_P),		// Diff_p output (connect directly to top-level port)
      .OB(TIMING_SPI_SCLK_N), 		// Diff_n output (connect directly to top-level port)
      .I(TIMING_SPI_SCLK)			// Buffer input
);

OBUFDS #(
      .IOSTANDARD("DEFAULT"), 		// Specify the output I/O standard
      .SLEW("SLOW")           		// Specify the output slew rate
   ) TIMING_SPI_MISO_inst(
      .O(TIMING_SPI_MISO_P),		// Diff_p output (connect directly to top-level port)
      .OB(TIMING_SPI_MISO_N), 		// Diff_n output (connect directly to top-level port)
      .I(TIMING_SPI_MISO)			// Buffer input
);

IBUFDS #(
        .DIFF_TERM("TRUE"),         // Differential Termination
        .IBUF_LOW_PWR("FALSE"),     // Low power="TRUE", Highest performance="FALSE" 
        .IOSTANDARD("DEFAULT")      // Specify the input I/O standard
   ) ENCODE_MCLK_inst(
        .O(ENCODE_MCLK),            // Buffer output
        .I(ENCODE_MCLK_P),          // Diff_p buffer input (connect directly to top-level port)
        .IB(ENCODE_MCLK_N)          // Diff_n buffer input (connect directly to top-level port)
);

IBUFDS #(
        .DIFF_TERM("TRUE"),         // Differential Termination
        .IBUF_LOW_PWR("FALSE"),     // Low power="TRUE", Highest performance="FALSE" 
        .IOSTANDARD("DEFAULT")      // Specify the input I/O standard
   ) ENCODE_MOSI_inst(
        .O(ENCODE_MOSI),            // Buffer output
        .I(ENCODE_MOSI_P),          // Diff_p buffer input (connect directly to top-level port)
        .IB(ENCODE_MOSI_N)          // Diff_n buffer input (connect directly to top-level port)
);

OBUFDS #(
    .IOSTANDARD("DEFAULT"),         // Specify the output I/O standard
    .SLEW("SLOW")                   // Specify the output slew rate
) ACC_MOSI_inst(
    .O(ACC_MISO_P),             // Diff_p output (connect directly to top-level port)
    .OB(ACC_MISO_N),            // Diff_n output (connect directly to top-level port)
    .I(ACC_SPI_MISO)                // Buffer input
);

OBUFDS #(
    .IOSTANDARD("DEFAULT"),         // Specify the output I/O standard
    .SLEW("SLOW")                   // Specify the output slew rate
) ACC_MCLK_inst(
    .O(ACC_SCLK_P),             // Diff_p output (connect directly to top-level port)
    .OB(ACC_SCLK_N),            // Diff_n output (connect directly to top-level port)
    .I(ACC_SPI_SCLK)                // Buffer input
);

reset_generate reset_generate(
    .nrst_i                         ( pll_locked                        ),

    .clk_100m                       ( clk_100m                          ),
    .rst_100m                       ( rst_100m                          ),
    .clk_50m                        ( clk_50m                           ),
    .gt_rst                         ( gt_rst                            ),
    .aurora_log_clk                 ( aurora_log_clk                    ),
    .aurora_rst                     ( aurora_rst                        )
);

serial_slave_drv #(
    .DATA_WIDTH                     ( DATA_WIDTH                        ),
    .ADDR_WIDTH                     ( ADDR_WIDTH                        ),
    .CMD_WIDTH                      ( 8                                 ),
    .SERIAL_MODE                    ( 1                                 )
)serial_slave_drv_inst(
    // clk & rst
    .clk_i                          ( clk_100m                          ),
    .rst_i                          ( rst_100m                          ),
    .clk_200m_i                     ( clk_200m                          ),

    .slave_wr_en_o                  ( slave_wr_en                       ), 
    .slave_addr_o                   ( slave_addr                        ),
    .slave_wr_data_o                ( slave_wr_data                     ),

    .slave_rd_en_o                  ( slave_rd_en                       ),
    .slave_rd_vld_i                 ( slave_rd_vld                      ),
    .slave_rd_data_i                ( slave_rd_data                     ),

    .SPI_MCLK                       ( TIMING_SPI_MCLK                   ),
    .SPI_MOSI                       ( TIMING_SPI_MOSI                   ),
    .SPI_SCLK                       ( TIMING_SPI_SCLK                   ),
    .SPI_MISO                       ( TIMING_SPI_MISO                   )
);

encode_rx_drv encode_rx_drv_inst(
    .clk_i                          ( clk_100m                          ),
    .rst_i                          ( rst_100m                          ),
    .clk_200m_i                     ( clk_200m                          ),

    .encode_zero_flag_o             ( wafer_zero_flag                   ),
    .scan_start_flag_o              ( adc_start                         ),
    .scan_tset_flag_o               ( adc_test                          ),

    // spi info
    .SPI_MCLK                       ( ENCODE_MCLK                       ),
    .SPI_MOSI                       ( ENCODE_MOSI                       )
);

acc_ctrl_tx_drv acc_ctrl_tx_drv_inst(
    // clk & rst
    .clk_i                          ( clk_100m                          ),
    .rst_i                          ( rst_100m                          ),
    .clk_200m_i                     ( clk_200m                          ),

    .filter_acc_ctrl_i              ( (aom_ctrl_flag || acc_cali_ctrl) && real_adc_start  ),

    // spi info
    .SPI_SCLK                       ( ACC_SPI_SCLK                      ),
    .SPI_MISO                       ( ACC_SPI_MISO                      )
);

scan_flag_generate scan_flag_generate_inst(
    // clk & rst
    .clk_i                          ( clk_100m                          ),
    .rst_i                          ( rst_100m                          ),
    .aurora_clk_i                   ( aurora_log_clk                    ),

    .adc_start_en_i                 ( adc_start                         ),
    .adc_end_en_i                   ( aurora_adc_end                    ),
    .aurora_adc_start_o             ( adc_start_sync                    ),
    .real_pmt_scan_o                ( real_adc_start                    )   
);


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

    // .circle_lose_num_o              ( circle_lose_num                   ),
    // .circle_lose_num_delta_o        ( circle_lose_num_delta             ),
    // .uniform_circle_o               ( uniform_circle_num                ),
    .detect_width_para_i            ( detect_width_para                 ),
    .pre_track_dbg_o                ( pre_track_dbg                     ),
    .light_spot_spacing_o           ( light_spot_spacing                ),
    .check_window_o                 ( check_window                      ),
    .haze_up_limit_o                ( haze_up_limit                     ),

    .acc_defect_en_o                ( acc_defect_en                     ),
    .pre_acc_curr_thre_o            ( pre_acc_curr_thre                 ),
    .actu_acc_curr_thre_o           ( actu_acc_curr_thre                ),
    .actu_acc_cache_thre_o          ( actu_acc_cache_thre               ),
    .particle_acc_bypass_o          ( particle_acc_bypass               ),
    .first_track_ctrl_o             ( first_track_ctrl                  ),
    
    .lp_recover_factor_o            ( lp_recover_factor                 ),  // 8bit integer + 8bit decimal
    .acc_cali_mode_o                ( acc_cali_mode                     ),
    .acc_cali_low_o                 ( acc_cali_low                      ),
    .acc_cali_high_o                ( acc_cali_high                     ),
    // .acc_trig_delay_o               ( acc_trig_delay                    ),
    .aom_ctrl_delay_o               ( aom_ctrl_delay                    ),
    .aom_ctrl_hold_o                ( aom_ctrl_hold                     ),
    .lp_recover_delay_o             ( lp_recover_delay                  ),
    .lp_recover_hold_o              ( lp_recover_hold                   ),
    .recover_edge_slot_time_o       ( recover_edge_slot_time            ),
    .aurora_upmode_o                ( aurora_upmode                     ),
    .laser_acc_flag_upmode_o        ( laser_acc_flag_upmode             ),

    .laser_fir_upmode_o             ( laser_fir_upmode                  ),
    .laser_fir_en_o                 ( laser_fir_en                      ),
    .track_para_en_o                ( track_para_en                     ),
    .acc_trigger_num_i              ( acc_trigger_num                   ),
    .track_para_burst_line_i        ( track_para_burst_line             ),

    .dbg_acc_flag_cnt_i             ( dbg_acc_flag_cnt                  ),
    .pre_widen_result_cnt_i         ( pre_widen_result_cnt              ),
    .curr_widen_result_cnt_i        ( curr_widen_result_cnt             ),
    .cache_widen_result_cnt_i       ( cache_widen_result_cnt            ),
    .debug_info                     (                                   )
);

// mfpga to mainPC message arbitrate 
arbitrate_bpsi #(
    .MFPGA_VERSION                  ( VERSION                           )
) arbitrate_bpsi_inst(
    .clk_i                          ( clk_100m                          ),
    .rst_i                          ( rst_100m                          ),

    .readback_vld_i                 ( readback_vld                      ), // laser uart
    .readback_last_i                ( readback_last                     ), // laser uart
    .readback_data_i                ( readback_data                     ), // laser uart

    .raw_adc_cfg_i                  ( raw_adc_cfg                       ),
    .raw_adc_vld_i                  ( adc_data_en                       ),
    .raw_adc_data_i                 ( adc_data                          ),
        
 
    .slave_tx_ack_i                 ( slave_tx_ack                      ),
    .slave_tx_byte_en_o             ( slave_tx_byte_en                  ),
    .slave_tx_byte_o                ( slave_tx_byte                     ),
    .slave_tx_byte_num_en_o         ( slave_tx_byte_num_en              ),
    .slave_tx_byte_num_o            ( slave_tx_byte_num                 )

);


slave_comm slave_comm_inst(
    // clk & rst
    .clk_sys_i                      ( clk_100m                          ),
    .rst_i                          ( rst_100m                          ),
    // salve tx info
    .slave_tx_en_i                  ( slave_tx_byte_en                  ),
    .slave_tx_data_i                ( slave_tx_byte                     ),
    .slave_tx_byte_num_en_i         ( slave_tx_byte_num_en              ),
    .slave_tx_byte_num_i            ( slave_tx_byte_num                 ),
    .slave_tx_ack_o                 ( slave_tx_ack                      ),
    // slave rx info
    .rd_data_vld_o                  ( slave_rx_data_vld                 ),
    .rd_data_o                      ( slave_rx_data                     ),
    // info
    .SLAVE_MSG_CLK                  ( FPGA_TO_SFPGA_RESERVE0            ),
    .SLAVE_MSG_TX_FSX               ( FPGA_TO_SFPGA_RESERVE3            ),
    .SLAVE_MSG_TX                   ( FPGA_TO_SFPGA_RESERVE4            ),
    .SLAVE_MSG_RX_FSX               ( FPGA_TO_SFPGA_RESERVE1            ),
    .SLAVE_MSG_RX                   ( FPGA_TO_SFPGA_RESERVE2            )
);

`ifdef SIMULATE
fir_tap_map_sim fir_tap_map_sim_inst(
    // clk & rst
    .clk_i                          ( clk_100m                          ),
    .rst_i                          ( ~ddr3_init_done                   ),

    .fir_tap_wr_cmd_o               ( track_para_wr_cmd                 ),
    // .fir_tap_wr_addr_o              ( track_para_wr_addr                ),
    .fir_tap_wr_vld_o               ( track_para_wr_vld                 ),
    .fir_tap_wr_data_o              ( track_para_wr_data                )
);
`else
command_map command_map_inst(
    .clk_sys_i                      ( clk_100m                          ),
    .rst_i                          ( rst_100m                          ),
    .slave_rx_data_vld_i            ( slave_rx_data_vld                 ),
    .slave_rx_data_i                ( slave_rx_data                     ),

    .ddr_rd_addr_o                  ( ddr_rd_addr                       ),
    .ddr_rd_en_o                    ( ddr_rd_en                         ),
    .fir_tap_wr_cmd_o               ( track_para_wr_cmd                 ),
    // .fir_tap_wr_addr_o              ( track_para_wr_addr                ),
    .fir_tap_wr_vld_o               ( track_para_wr_vld                 ),
    .fir_tap_wr_data_o              ( track_para_wr_data                ),

    .raw_adc_cfg_o                  ( raw_adc_cfg                       ),

    .debug_info                     (                                   )
);
`endif //SIMULATE

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
    .delay_zero_flag_o              ( delay_zero_flag                   ),

    .ds_para_en_o                   ( ds_para_en                        ),
    .ds_para_h_o                    ( ds_para_h                         ),
    .ds_para_l_o                    ( ds_para_l                         ),
    .light_spot_para_o              ( light_spot_para                   ),
    .detect_width_para_o            ( detect_width_para                 ),
    .lowpass_para_vld_o             ( lowpass_para_vld                  ),
    .lowpass_para_data_o            ( lowpass_para_data                 ),
    .fir_post_para_en_o             ( fir_post_para_en                  ),
    .circle_lose_num_o              ( circle_lose_num                   ),
    .track_align_num_o              ( track_align_num                   ),
    
    .fir_tap_vld_o                  ( fir_tap_vld                       ),
    .fir_tap_addr_o                 ( fir_tap_addr                      ),
    .fir_tap_data_o                 ( fir_tap_data                      )
);

acc_lp_recover acc_lp_recover_inst(
    // clk & rst 
    .clk_i                          ( clk_100m                          ),
    .rst_i                          ( rst_100m                          ),

    .laser_vld_i                    ( adc_data_en                       ),
    .laser_data_i                   ( adc_data                          ),
    .recover_edge_flag_i            ( recover_edge_flag                 ),
    // .laser_haze_data_i              ( laser_haze_data                   ),
    .filter_acc_flag_i              ( lp_recover_flag                   ),
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
    .DELAY_NUM                      ( 26                                )
)lp_reg_delay_inst(
    .clk_i                          ( clk_100m                          ),
    .src_data_i                     ( {lp_recover_acc_flag,lp_recover_zero_flag}    ),
    .delay_data_o                   ( {lpf_acc_flag,lpf_zero_flag}                  )
);

`else

assign lpf_acc_flag     = lp_recover_acc_flag;
assign lpf_zero_flag    = lp_recover_zero_flag;
assign lpf_laser_vld    = lp_recover_vld ;
assign lpf_laser_data   = lp_recover_data;
`endif // DYNAMIC_LOWPASS_MOD

`ifdef FIR_MOD
fir_ctrl_v2 #(
    .FIR_TAP_NUM                    ( 51                                )
)fir_ctrl_inst(
    .clk_i                          ( clk_100m                          ),
    .rst_i                          ( rst_100m                          ),

    .laser_start_i                  ( real_adc_start                    ),
    .laser_fir_upmode_i             ( laser_fir_upmode                  ),
    .laser_fir_en_i                 ( laser_fir_en                      ),

    .fir_tap_vld_i                  ( fir_tap_vld                       ),
    .fir_tap_addr_i                 ( fir_tap_addr                      ),
    .fir_tap_data_i                 ( fir_tap_data                      ),
    .fir_ds_num_i                   ( lowpass_para_data                 ),

    .acc_flag_i                     ( lpf_acc_flag                      ),
    .zero_flag_i                    ( lpf_zero_flag                     ),
    .laser_vld_i                    ( lpf_laser_vld                     ),
    .laser_data_i                   ( lpf_laser_data                    ),

    .fir_acc_flag_o                 ( fir_acc_flag                      ),
    .fir_zero_flag_o                ( fir_zero_flag                     ),
    .fir_laser_vld_o                ( fir_laser_vld                     ),
    .fir_laser_data_o               ( fir_laser_data                    )
);

`else
assign fir_acc_flag         = lpf_acc_flag  ;
assign fir_zero_flag        = lpf_zero_flag ;
assign fir_laser_vld        = lpf_laser_vld ;
assign fir_laser_data       = lpf_laser_data;
`endif // FIR_MOD

// data folding, for ACC align
fir_post_process fir_post_process_inst(
    // clk & rst 
    .clk_i                          ( clk_100m                          ),
    .rst_i                          ( rst_100m                          ),

    .laser_start_i                  ( real_adc_start                    ),
    .fir_acc_flag_i                 ( fir_acc_flag                      ),
    .fir_laser_zero_flag_i          ( fir_zero_flag                     ),
    .fir_laser_data_i               ( fir_laser_data                    ),
    .fir_laser_vld_i                ( fir_laser_vld                     ),

    .fir_post_para_en_i             ( fir_post_para_en                  ),
    .circle_lose_num_i              ( circle_lose_num                   ),
    .track_align_num_i              ( track_align_num                   ),

    .fir_post_zero_flag_o           ( fir_post_zero_flag                ),
    .fir_post_acc_flag_o            ( fir_post_acc_flag                 ),
    .fir_post_pre_vld_o             ( fir_post_pre_vld                  ),
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

    .laser_start_i                  ( real_adc_start                    ),
    .laser_vld_i                    ( adc_data_en /*fir_laser_vld*/     ),
    .laser_raw_data_i               ( adc_data                          ),
    .acc_flag_i                     ( fir_acc_flag                      ),
    .laser_data_i                   ( fir_laser_data                    ),
    .haze_up_limit_i                ( haze_up_limit                     ),

    .haze_data_o                    ( laser_haze_data                   )
);
`else
assign laser_haze_data = 'd0;

`endif // FIR_MOD

pre_track_pingpang #(
    .DATA_WIDTH                     ( 16                                )
)pre_track_pingpang_inst(
    .clk_i                          ( clk_100m                          ),
    .rst_i                          ( rst_100m                          ),

    .ds_para_en_i                   ( ds_para_en                        ),
    .ds_para_h_i                    ( ds_para_h                         ),
    .ds_para_l_i                    ( ds_para_l                         ),
    .pre_track_dbg_i                ( pre_track_dbg                     ),
    .aom_ctrl_delay_abs_i           ( aom_ctrl_delay_abs                ),
    .light_spot_para_i              ( light_spot_para                   ),
    .detect_width_para_i            ( detect_width_para                 ),
    .check_window_i                 ( check_window                      ),
    .pre_filter_thre_i              ( pre_acc_curr_thre                 ),

    .laser_start_i                  ( real_adc_start                    ),
    .laser_pre_vld_i                ( fir_post_pre_vld                  ),
    .laser_vld_i                    ( fir_post_vld                      ),
    .laser_data_i                   ( fir_post_data                     ),
    .encode_zero_flag_i             ( fir_post_zero_flag                ),
    .filter_acc_flag_i              ( fir_post_acc_flag                 ),
    .laser_haze_data_i              ( laser_haze_data                   ),

    .second_track_en_o              ( second_track_en                   ),
    .pre_track_result_o             ( pre_track_result                  ),

    // pingpang write
    .pre_track_acc_flag_o           ( pre_track_acc_flag                ),
    .pre_track_mema_start_o         ( pre_track_mema_start              ),
    .pre_track_mema_vld_o           ( pre_track_mema_vld                ),
    .pre_track_mema_data_o          ( pre_track_mema_data               ),
    .pre_track_memb_start_o         ( pre_track_memb_start              ),
    .pre_track_memb_vld_o           ( pre_track_memb_vld                ),
    .pre_track_memb_data_o          ( pre_track_memb_data               ),

    // pingpang read
    .pre_track_mema_rd_start_o      ( pre_track_mema_rd_start           ),
    .pre_track_mema_ready_i         ( pre_track_mema_ready              ),
    .pre_track_mema_rd_vld_i        ( pre_track_mema_rd_vld             ),
    .pre_track_mema_rd_seq_o        ( pre_track_mema_rd_seq             ),
    .pre_track_mema_rd_data_i       ( pre_track_mema_rd_data            ),
    .pre_track_memb_rd_start_o      ( pre_track_memb_rd_start           ),
    .pre_track_memb_ready_i         ( pre_track_memb_ready              ),
    .pre_track_memb_rd_vld_i        ( pre_track_memb_rd_vld             ),
    .pre_track_memb_rd_seq_o        ( pre_track_memb_rd_seq             ),
    .pre_track_memb_rd_data_i       ( pre_track_memb_rd_data            )
);

ddr_top u_ddr_top(
    .clk_i                          ( clk_100m                          ),
    .rst_i                          ( rst_100m                          ),
    .clk_250m_i                     ( clk_250m                          ),
    .clk_200m_i                     ( clk_200m                          ),

    // pre track data cache
    .filter_acc_flag_i              ( pre_track_acc_flag                ),
    .pre_track_mema_start_i         ( pre_track_mema_start              ),
    .pre_track_mema_vld_i           ( pre_track_mema_vld                ),
    .pre_track_mema_data_i          ( pre_track_mema_data               ),
    .pre_track_memb_start_i         ( pre_track_memb_start              ),
    .pre_track_memb_vld_i           ( pre_track_memb_vld                ),
    .pre_track_memb_data_i          ( pre_track_memb_data               ),
    
    // pre track data read
    .pre_track_mema_rd_start_i      ( pre_track_mema_rd_start           ),
    .pre_track_memb_rd_start_i      ( pre_track_memb_rd_start           ),
    .pre_track_mema_ready_o         ( pre_track_mema_ready              ),
    .pre_track_mema_rd_seq_i        ( pre_track_mema_rd_seq             ),
    .pre_track_mema_rd_vld_o        ( pre_track_mema_rd_vld             ),
    .pre_track_mema_rd_data_o       ( pre_track_mema_rd_data            ),
    .pre_track_memb_ready_o         ( pre_track_memb_ready              ),
    .pre_track_memb_rd_seq_i        ( pre_track_memb_rd_seq             ),
    .pre_track_memb_rd_vld_o        ( pre_track_memb_rd_vld             ),
    .pre_track_memb_rd_data_o       ( pre_track_memb_rd_data            ),

    // fir tap
    .fir_tap_wr_cmd_i               ( track_para_wr_cmd                 ),
    .fir_tap_wr_vld_i               ( track_para_wr_vld                 ),
    .fir_tap_wr_data_i              ( track_para_wr_data                ),

    .laser_start_i                  ( real_adc_start                    ),
    .encode_zero_flag_i             ( wafer_zero_flag                   ),
    .track_para_en_i                ( track_para_en                     ),
    .track_para_burst_end_o         ( track_para_burst_end              ),
    .track_para_rd_en_i             ( track_para_ren                    ),
    .track_para_ready_o             ( track_para_ready                  ),
    .track_para_rd_vld_o            ( track_para_vld                    ),
    .track_para_rd_data_o           ( track_para_data                   ),
    .fir_tap_burst_line_o           ( track_para_burst_line             ),

    // readback ddr
    .ddr_rd_addr_i                  ( ddr_rd_addr                       ),
    .ddr_rd_en_i                    ( ddr_rd_en                         ),
    .readback_vld_o                 ( readback_vld                      ),
    .readback_last_o                ( readback_last                     ),
    .readback_data_o                ( readback_data                     ),

    // ddr info
    .init_calib_complete_o          ( ddr3_init_done                    ),
    .ddr3_addr                      ( DDR3_A_ADD              [15:0]    ),
    .ddr3_ba                        ( DDR3_A_BA                [2:0]    ),
    .ddr3_ras_n                     ( DDR3_A_RAS_B                      ),
    .ddr3_cas_n                     ( DDR3_A_CAS_B                      ),
    .ddr3_we_n                      ( DDR3_A_WE_B                       ),
    .ddr3_reset_n                   ( DDR3_A_RESET_B                    ),
    .ddr3_ck_p                      ( DDR3_A_CLK0_P                     ),
    .ddr3_ck_n                      ( DDR3_A_CLK0_N                     ),
    .ddr3_cke                       ( DDR3_A_CKE                        ),
    .ddr3_cs_n                      ( DDR3_A_S0_B                       ),
    .ddr3_dm                        ( DDR3_A_DM                [3:0]    ),
    .ddr3_odt                       ( DDR3_A_ODT                        ),
    .ddr3_dq                        ( DDR3_A_D                [31:0]    ),
    .ddr3_dqs_n                     ( DDR3_A_DQS_N             [3:0]    ),
    .ddr3_dqs_p                     ( DDR3_A_DQS_P             [3:0]    )
);

laser_particle_detect_v2 laser_particle_detect_inst(
    // clk & rst 
    .clk_i                          ( clk_100m                          ),    
    .rst_i                          ( rst_100m                          ),

    .detect_width_para_i            ( detect_width_para                 ),
    .light_spot_spacing_i           ( light_spot_spacing                ),
    .ds_para_en_i                   ( ds_para_en                        ),
    .ds_para_h_i                    ( ds_para_h                         ),
    .ds_para_l_i                    ( ds_para_l                         ),
    // acc threshold
    .acc_defect_en_i                ( acc_defect_en && (~acc_cali_mode) ),
    .pre_track_result_i             ( pre_track_result                  ),
    .actu_acc_curr_thre_i           ( actu_acc_curr_thre                ),
    .actu_acc_cache_thre_i          ( actu_acc_cache_thre               ),
    .particle_acc_bypass_i          ( particle_acc_bypass               ),
    .first_track_ctrl_i             ( first_track_ctrl                  ),

    // acc flag generate
    .filter_acc_delay_vld_o         ( filter_acc_delay_vld              ),
    .filter_acc_flag_o              ( filter_acc_flag                   ),
    .filter_acc_vld_o               ( filter_acc_vld                    ),
    .filter_acc_data_o              ( filter_acc_data                   ),
    .filter_acc_haze_o              ( filter_acc_haze                   ),
    .filter_acc_haze_hub_o          ( filter_acc_haze_hub               ),
    .filter_acc_result_o            ( filter_acc_result                 ),
    .acc_pre_result_o               ( acc_pre_result                    ),
    .acc_curr_result_o              ( acc_curr_result                   ),
    .second_track_en_i              ( second_track_en                   ),

    // current track data
    .laser_start_i                  ( real_adc_start                    ),
    .encode_zero_flag_i             ( wafer_zero_flag                   ),
    .laser_acc_flag_i               ( fir_post_acc_flag                 ),
    .laser_vld_i                    ( fir_post_vld                      ),
    .laser_data_i                   ( fir_post_data                     ),
    .laser_haze_data_i              ( laser_haze_data                   ),

    // previous track data, from ddr
    .pre_laser_rd_ready_i           ( laser_fifo_ready                  ),
    .pre_laser_rd_seq_o             ( pre_laser_rd_seq                  ),
    .pre_laser_rd_vld_i             ( pre_laser_rd_vld                  ),
    .pre_laser_rd_data_i            ( pre_laser_rd_data                 ),
    
    .pre_widen_result_cnt_o         ( pre_widen_result_cnt              ),
    .curr_widen_result_cnt_o        ( curr_widen_result_cnt             ),
    .cache_widen_result_cnt_o       ( cache_widen_result_cnt            ),
    .dbg_acc_flag_cnt_o             ( dbg_acc_flag_cnt                  )
);

aom_flag_trim aom_flag_trim_inst(
    .clk_i                          ( clk_100m                          ),
    .rst_i                          ( rst_100m                          ),

    .laser_start_i                  ( real_adc_start                    ),
    .filter_unit_vld_i              ( adc_data_en                       ),
    .filter_acc_result_i            ( filter_acc_result                 ),
    .light_spot_para_i              ( light_spot_para                   ),
    .aom_ctrl_delay_i               ( aom_ctrl_delay                    ),
    .aom_ctrl_hold_i                ( aom_ctrl_hold                     ),
    .lp_recover_delay_i             ( lp_recover_delay                  ),
    .lp_recover_hold_i              ( lp_recover_hold                   ),
    .recover_edge_slot_time_i       ( recover_edge_slot_time            ),
    .aom_ctrl_delay_abs_o           ( aom_ctrl_delay_abs                ),

    .aom_ctrl_flag_o                ( aom_ctrl_flag                     ),
    .recover_edge_flag_o            ( recover_edge_flag                 ),
    .lp_recover_flag_o              ( lp_recover_flag                   )
);

acc_trigger_check acc_trigger_check_inst(
    .clk_i                          ( clk_100m                          ),
    .rst_i                          ( rst_100m                          ),

    .laser_start_i                  ( real_adc_start                    ),
    .aom_ctrl_flag_i                ( aom_ctrl_flag                     ),

    .acc_trigger_num_o              ( acc_trigger_num                   )
);

laser_pre_aurora laser_pre_aurora_inst(
    // clk & rst 
    .clk_i                          ( clk_100m                          ),    
    .rst_i                          ( rst_100m                          ),
    .aurora_log_clk_i               ( aurora_log_clk                    ),

    // current track data
    .aurora_upmode_i                ( aurora_upmode                     ),
    .laser_acc_flag_upmode_i        ( laser_acc_flag_upmode             ),

    .acc_pre_result_i               ( acc_pre_result                    ),
    .acc_curr_result_i              ( acc_curr_result                   ),
    .laser_start_i                  ( real_adc_start                    ),
    .laser_vld_i                    ( filter_acc_delay_vld              ),
    .laser_acc_flag_i               ( filter_acc_flag || acc_cali_ctrl  ),
    .laser_data_i                   ( filter_acc_data                   ),
    .laser_filter_acc_hub_i         ( filter_acc_haze_hub               ),
    .laser_haze_data_i              ( filter_acc_haze                   ),
    .laser_raw_data_i               ( adc_data                          ),

    // aurora interface
    .aurora_txen_i                  ( aurora_txen                       ),
    .aurora_txdata_o                ( aurora_txdata                     ),
    .aurora_tx_emp_o                ( aurora_tx_emp                     ),
    .aurora_rd_data_count_o         ( aurora_rd_data_count              )
);

aurora_8b10b_0_exdes  aurora_8b10b_exdes_inst_0(
    .aurora_log_clk                 ( aurora_log_clk                    ),
    .aurora_rxen                    ( aurora_rxen                       ),
    .aurora_rxdata                  ( aurora_rxdata                     ),
    .aurora_txen                    ( aurora_txen                       ),
    .aurora_txdata                  ( aurora_txdata                     ),
    .aurora_rd_data_count           ( aurora_rd_data_count              ),

    .adc_start_i                    ( adc_start_sync                    ),
    .adc_end_o                      ( aurora_adc_end                    ),

    .RESET                          ( aurora_rst                        ),
    .HARD_ERR                       (                                   ),
    .SOFT_ERR                       (                                   ),
    .FRAME_ERR                      (                                   ),
    .CHANNEL_UP_DONE                ( CHANNEL_UP_DONE                   ),
    .INIT_CLK_P                     ( clk_50m                           ),
    .DRP_CLK_IN                     ( clk_50m                           ),
    .GT_RESET_IN                    ( gt_rst                            ),

    .GTXQ0_P                        ( SFP_MGT_REFCLK_C_P                ),
    .GTXQ0_N                        ( SFP_MGT_REFCLK_C_N                ),
    .RXP                            ( FPGA_SFP1_RX_P                    ),
    .RXN                            ( FPGA_SFP1_RX_N                    ),
    .TXP                            ( FPGA_SFP1_TX_P                    ),
    .TXN                            ( FPGA_SFP1_TX_N                    )
);

ad9265_top_if ad9265_top_if_inst(
    .clk                            ( clk_100m                          ),
    .rst                            ( rst_100m                          ),

    //adc config
    .AD9265_SYNC                    ( AD9265_SYNC                       ),
    .AD9265_PDWN                    ( AD9265_PDWN                       ),
    .spi_clk                        ( AD9265_SCLK                       ),
    .spi_csn                        ( AD9265_CSB                        ),
    .spi_sdio                       ( AD9265_SDIO                       ),
    .init                           ( ad9265_init                       ),
    //adc data
    .AD9265_DCO                     ( AD9265_DCO                        ), 
    .AD9265_DATA                    ( AD9265_DATA                       ),
    .AD9265_OR                      ( AD9265_OR                         ),

    .adc_start                      ( real_adc_start                    ),
    .adc_test                       ( adc_test || adc_test_set          ),

    .adc_data                       ( adc_data                          ),
    .adc_data_en                    ( adc_data_en                       )

);

ad5592_config #(
    .ADC_IO_REG	(16'b0010000010010011), //ADC:IO0,IO1,IO4,IO7
    .DAC_IO_REG	(16'b0010100001101100)  //DAC:IO2,IO3,IO5,IO6
)ad5592_config_inst1(
    .clk                            ( clk_100m                          ),
    .rst                            ( rst_100m                          ),
    .dac_config_en                  ( ad5592_1_dac_config_en            ),
    .dac_channel                    ( ad5592_1_dac_channel              ),
    .dac_data                       ( ad5592_1_dac_data                 ),
    .adc_config_en                  ( ad5592_1_adc_config_en            ),
    .adc_channel                    ( ad5592_1_adc_channel              ),

    .spi_csn                        ( AD5592_1_SPI_CS_B                 ),
    .spi_clk                        ( AD5592_1_SPI_CLK                  ),
    .spi_mosi                       ( AD5592_1_SPI_MOSI                 ),
    .spi_miso                       ( AD5592_1_SPI_MISO                 ),
    .spi_conf_ok                    ( ad5592_1_spi_conf_ok              ),
    .init                           ( ad5592_1_init                     ),
    .adc_data_en                    ( ad5592_1_adc_data_en              ),
    .adc_data                       ( ad5592_1_adc_data                 )	
);


// TMP75 TMP75_inst(
// 		.clk(clk_100m),
// 		.rst(rst_100m),
// 		.TEMP_SCL(TMP75_IIC_SCL),
// 		.TEMP_SDA(TMP75_IIC_SDA),
		
// 		.TEMP_RD_en(temp_rd_en),
		
// 		.TEMP_DATA(temp_data),
// 		.TEMP_DATA_en(temp_data_en)
// );

// eeprom eeprom_inst(
// 		.clk(clk_100m),
// 		.rst(rst_100m),
// 		.addr_data_w(eeprom_w_addr_data),
// 		.addr_data_w_en(eeprom_w_en),
// 		.addr_r(eeprom_r_addr),
// 		.addr_r_en(eeprom_r_addr_en),
// 		.data_r(eeprom_r_data),
// 		.data_r_en(eeprom_r_data_en),
						
// 		.spi_cs(EEPROM_CS_B),
// 		.spi_sck(EEPROM_SCK),
// 		.spi_dout(EEPROM_SI),
// 		.spi_din(EEPROM_SO),
// 		.eeprom_wp_n(EEPROM_WP_B),
// 		.eeprom_hold_n(),
// 		.spi_ok(eeprom_spi_ok)
// );

ad5542_spi_wr ad5542_spi_wr_inst(
    .clk             ( clk_100m             ),
    .rst             ( rst_100m             ),
    .wr_data_en      ( ad5542_wr_data_en    ),
    .wr_data         ( ad5542_wr_data       ),
    .wr_data_end     ( ad5542_wr_data_end   ),
    .spi_clk         ( FPGA_DAC_SPI_SCLK    ),
    .spi_cs_n        ( FPGA_DAC_SPI_CS_N    ),
    .spi_din         ( FPGA_DAC_SPI_DIN     ) 
);
endmodule
