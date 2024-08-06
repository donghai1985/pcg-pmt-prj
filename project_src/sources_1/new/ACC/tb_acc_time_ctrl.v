//~ `New testbench
`timescale  1ns / 1ps

module tb_acc_time_ctrl;

// acc_time_ctrl Parameters
parameter PERIOD = 10 ;
parameter TCQ  = 0.1;

// acc_time_ctrl Inputs
reg   clk_i                                = 0 ;
reg   clk_200m_i                                = 0 ;
reg   rst_i                                = 0 ;
reg   filter_acc_result_i                  = 0 ;
reg   [32-1:0]  acc_result_delay_i         = 200 ;
reg   [32-1:0]  acc_flag_delay_i           = 100 ;

// acc_time_ctrl Outputs
wire  filter_acc_flag_o                    ;
wire acc_aom_flag;
wire SPI_MCLK    ;
wire SPI_MOSI    ;

wire                laser_aom_en                    ;
wire    [12-1:0]    laser_aom_voltage               ;

reg                 laser_control               = 'd1       ;   // 默认关光
reg                 laser_out_switch            = 'd0       ;   // 默认内控
reg     [12-1:0]    laser_analog_max            = 'd1638    ;   // 4095 = 5V
reg     [12-1:0]    laser_analog_min            = 'd0       ;
reg     [32-1:0]    laser_analog_pwm            = 'd100     ;   // 50% PWM
reg     [32-1:0]    laser_analog_cycle          = 'd200     ;   // 2000ns = 500kHz 
reg     [12-1:0]    laser_analog_uplimit        = 'd2866    ;   // 3.5V / 5 * 4095
reg     [12-1:0]    laser_analog_lowlimit       = 'd0       ;
reg                 laser_analog_mode_sel       = 'd0       ;   // 0: PWM  1: trigger
reg                 laser_analog_trigger        = 'd0       ;
reg                 acc_job_control             = 'd0       ;   // 1：屏蔽寄存器控制
reg                 acc_job_init_switch         = 'd1       ;   // acc job 默认切外控
reg                 acc_job_init_vol_trig       = 'd0       ;
reg     [12-1:0]    acc_job_init_vol            = 'd2457    ;   // 3V
reg     [12-1:0]    acc_aom_class0              = 'd0       ;   // 0    / 5 * 2**12 = 0
reg     [12-1:0]    acc_aom_class1              = 'd819     ;   // 1    / 5 * 2**12 = 819
reg     [12-1:0]    acc_aom_class2              = 'd1228    ;   // 1.5  / 5 * 2**12 = 1228
reg     [12-1:0]    acc_aom_class3              = 'd1638    ;   // 2    / 5 * 2**12 = 1638
reg     [12-1:0]    acc_aom_class4              = 'd2457    ;   // 3    / 5 * 2**12 = 2457
reg     [12-1:0]    acc_aom_class5              = 'd2866    ;   // 3.5  / 5 * 2**12 = 2866
reg     [12-1:0]    acc_aom_class6              = 'd3276    ;   // 4    / 5 * 2**12 = 3276
reg     [12-1:0]    acc_aom_class7              = 'd4095    ;   // 5    / 5 * 2**12 = 4095

initial
begin
    forever #(PERIOD/2)  clk_i=~clk_i;
end

initial
begin
    forever #(2.5)  clk_200m_i=~clk_200m_i;
end

initial
begin
    rst_i  =  1;
    #(PERIOD*2);
    rst_i  =  0;
end

acc_time_ctrl_v2 acc_flag_inst(
    // clk & rst 
    .clk_i                          ( clk_i                             ),
    .rst_i                          ( rst_i                             ),

    .filter_unit_flag_i             ( 1'b1                              ),
    .filter_acc_result_i            ( filter_acc_result_i               ),
    .acc_delay_i                    ( acc_result_delay_i                ),
    .acc_hold_i                     ( acc_flag_delay_i                  ),

    .filter_acc_flag_o              ( filter_acc_flag_o                 )
);
// acc_ctrl_tx_drv acc_ctrl_tx_drv_inst(
//     // clk & rst
//     .clk_i                          ( clk_i                             ),
//     .rst_i                          ( rst_i                             ),
//     .clk_200m_i                     ( clk_200m_i                        ),

//     .filter_acc_ctrl_i              ( filter_acc_flag_o                 ),

//     // spi info
//     .SPI_SCLK                       ( SPI_MCLK                          ),
//     .SPI_MISO                       ( SPI_MOSI                          )
// );

// acc_ctrl_rx_drv acc_ctrl_rx_drv_inst(
//     // clk & rst
//     .clk_i                          ( clk_i                             ),
//     .rst_i                          ( rst_i                             ),
//     .clk_200m_i                     ( clk_200m_i                        ),

//     .acc_aom_flag_o                 ( acc_aom_flag                      ),

//     // spi info
//     .SPI_SCLK                       ( SPI_MCLK                          ),
//     .SPI_MISO                       ( SPI_MOSI                          )
// );

// laser_aom_ctrl laser_aom_ctrl_inst(
//     .clk_i                          ( clk_i                      ),
//     .rst_i                          ( rst_i                      ),
//     .laser_control_i                ( laser_control                 ),
//     .laser_out_switch_i             ( laser_out_switch              ),
//     .laser_analog_max_i             ( laser_analog_max              ),
//     .laser_analog_min_i             ( laser_analog_min              ),
//     .laser_analog_pwm_i             ( laser_analog_pwm              ),
//     .laser_analog_cycle_i           ( laser_analog_cycle            ),
//     .laser_analog_uplimit_i         ( laser_analog_uplimit          ),
//     .laser_analog_lowlimit_i        ( laser_analog_lowlimit         ),
//     .laser_analog_mode_sel_i        ( laser_analog_mode_sel         ),
//     .laser_analog_trigger_i         ( laser_analog_trigger          ),

//     .acc_job_control_i              ( acc_job_control               ),
//     .acc_job_init_switch_i          ( acc_job_init_switch           ),
//     .acc_job_init_vol_trig_i        ( acc_job_init_vol_trig         ),
//     .acc_job_init_vol_i             ( acc_job_init_vol              ),
//     .acc_aom_flag_i                 ( acc_aom_flag                  ),
//     .acc_aom_class0_i               ( acc_aom_class0                ),
//     .acc_aom_class1_i               ( acc_aom_class1                ),
//     .acc_aom_class2_i               ( acc_aom_class2                ),
//     .acc_aom_class3_i               ( acc_aom_class3                ),
//     .acc_aom_class4_i               ( acc_aom_class4                ),
//     .acc_aom_class5_i               ( acc_aom_class5                ),
//     .acc_aom_class6_i               ( acc_aom_class6                ),
//     .acc_aom_class7_i               ( acc_aom_class7                ),

//     .LASER_CONTROL                  ( RF_Enable_LS                  ),
//     .LASER_OUT_SWITCH               ( RF_emission_LS                ),
//     .laser_aom_en_o                 ( laser_aom_en                  ),
//     .laser_aom_voltage_o            ( laser_aom_voltage             )
// );

// ad5445_config ad5445_config_inst(
//     .clk_i                          ( clk_i                      ),
//     .rst_i                          ( rst_i                      ),
//     .dac_out_en                     ( laser_aom_en                  ),
//     .dac_out                        ( laser_aom_voltage             ),

//     .rw_ctr                         ( AD5445_R_Wn                   ),
//     .cs_n                           ( AD5445_CSn                    ),
//     .d_bit                          ( AD5445_DB                     )
// );

initial
begin
    wait(~rst_i);
    #100;
    filter_acc_result_i = 1;
    #1200;
    filter_acc_result_i = 0;
    #2200;
    filter_acc_result_i = 1;
    #200;
    filter_acc_result_i = 0;
    #10000;
    $finish;
end

endmodule