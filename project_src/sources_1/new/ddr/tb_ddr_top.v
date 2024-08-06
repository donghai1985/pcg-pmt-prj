//~ `New testbench
`timescale  1ns / 1ps
`define SIMULATE
module tb_ddr_top;

// ddr_top Parameters
parameter PERIOD         = 10 ;


  localparam real TPROP_DQS          = 0.00;

                                       // Delay for DQS signal during Write Operation

  localparam real TPROP_DQS_RD       = 0.00;

                       // Delay for DQS signal during Read Operation

  localparam real TPROP_PCB_CTRL     = 0.1;

                       // Delay for Address and Ctrl signals

  localparam real TPROP_PCB_DATA     = 0.00;

                       // Delay for data signal during Write operation

  localparam real TPROP_PCB_DATA_RD  = 0.00;

                       // Delay for data signal during Read operation


   //***************************************************************************

   // The following parameters refer to width of various ports

   //***************************************************************************

   parameter COL_WIDTH             = 10;

                                     // # of memory Column Address bits.

   parameter CS_WIDTH              = 1;

                                     // # of unique CS outputs to memory.

   parameter DM_WIDTH              = 4;

                                     // # of DM (data mask)

   parameter DQ_WIDTH              = 32;

                                     // # of DQ (data)

   parameter DQS_WIDTH             = 4;

   parameter DQS_CNT_WIDTH         = 2;

                                     // = ceil(log2(DQS_WIDTH))

   parameter DRAM_WIDTH            = 8;

                                     // # of DQ per DQS

   parameter ECC                   = "OFF";

   parameter RANKS                 = 1;

                                     // # of Ranks.

   parameter ODT_WIDTH             = 1;

                                     // # of ODT outputs to memory.

   parameter ROW_WIDTH             = 16;

                                     // # of memory Row Address bits.

   parameter ADDR_WIDTH            = 30;

                                     // # = RANK_WIDTH + BANK_WIDTH

                                     //     + ROW_WIDTH + COL_WIDTH;

                                     // Chip Select is always tied to low for

                                     // single rank devices
  localparam MEMORY_WIDTH            = 16;
  localparam NUM_COMP                = DQ_WIDTH/MEMORY_WIDTH;
   parameter CA_MIRROR             = "OFF";
// ddr_top Inputs
reg                     clk_100m                   = 0 ;
reg                     clk_50m                 = 0 ;
reg                     pll_locked              = 0 ;
reg                     sys_rst_n               = 0 ;
reg                     clk_250m                = 0 ;
reg                     clk_200m                = 0 ;

// ddr_top Outputs

parameter                   VERSION             = "PCG1_PMTM_v8.2      ";

reg                     laser_vld_i             = 0 ;
reg     [16-1:0]        laser_data_i            = 0 ;
reg                     laser_start_i           = 0 ;
reg                     encode_zero_flag_i       = 0 ;
reg                         ddr3_init_done_r    = 'd0   ;
reg                         CHANNEL_UP_DONE_r   = 'd0   ;
reg                         laser_rst_r         = 'd1   ;
reg                         adc_end_r           = 'd0   ;
reg                         clear_buffer_r      = 'd0   ;
reg                         adc_end_sync        = 'd0   ;

wire                    rst_100m          ;
wire                    rst_200m          ;
wire                    pre_laser_rd_seq  ;
wire                    laser_fifo_ready  ;
wire    [64-1:0]        pre_laser_rd_data ;

reg                    aurora_log_clk = 0;
wire                    aurora_rxen;
wire    [31:0]          aurora_rxdata;
wire                    aurora_txen;
wire                    aurora_tx_emp;
wire    [31:0]          aurora_txdata;


wire                    eth_rec_pkt_done_sim        ;
wire                    eth_rec_en_sim              ;
wire [7:0]              eth_rec_data_sim            ;
wire                    eth_rec_byte_num_en_sim     ;
wire [15:0]             eth_rec_byte_num_sim        ;
  
wire                    FPGA_TO_SFPGA_RESERVE0      ;
wire                    FPGA_TO_SFPGA_RESERVE1      ;
wire                    FPGA_TO_SFPGA_RESERVE2      ;
wire                    FPGA_TO_SFPGA_RESERVE3      ;
wire                    FPGA_TO_SFPGA_RESERVE4      ;
wire                    rd_data_vld                 ;
wire [7:0]              rd_data                     ;

// udp slave
wire                    slave_tx_ack                ;
wire                    slave_tx_byte_en            ;
wire    [ 7:0]          slave_tx_byte               ;
wire                    slave_tx_byte_num_en        ;
wire    [15:0]          slave_tx_byte_num           ;
wire                    slave_rx_data_vld           ;
wire    [ 7:0]          slave_rx_data               ;

// readback ddr
wire    [32-1:0]            ddr_rd_addr                 ;
wire                        ddr_rd_en                   ;
wire                        readback_vld                ;
wire                        readback_last               ;
wire    [32-1:0]            readback_data               ;
// write fir tap to ddr
wire                        fir_tap_wr_cmd              ;
wire    [32-1:0]            fir_tap_wr_addr             ;
wire                        fir_tap_wr_vld              ;
wire    [32-1:0]            fir_tap_wr_data             ;
// fir tap update
reg                         laser_fir_en = 'd0;
reg                         laser_fir_upmode = 'd0;
wire                        fir_tap_rd_vld              ;
wire    [32-1:0]            fir_tap_rd_data             ;
wire                        fir_tap_rd_en               ;
wire                        fir_tap_ready               ;
wire    [10-1:0]            laser_fir_tap_set           ;
// ACC ctrl parameter
wire    [16-1:0]            circle_lose_num             ;
wire    [16-1:0]            circle_lose_num_delta       ;
wire    [16-1:0]            uniform_circle_num          ;

wire                        acc_defect_en               ;
wire    [16-1:0]            pre_acc_curr_thre           ;
wire    [16-1:0]            actu_acc_curr_thre          ;
wire    [16-1:0]            actu_acc_cache_thre         ;
wire    [16-1:0]            lp_pre_acc_curr_thre        ;
wire    [16-1:0]            lp_actu_acc_curr_thre       ;
wire    [16-1:0]            lp_actu_acc_cache_thre      ;

wire                        acc_track_para_wr           ;
wire    [16-1:0]            acc_track_para_addr         ;
wire    [16-1:0]            acc_track_para_data         ;

wire    [32-1:0]            acc_result_delay            ;
wire    [32-1:0]            acc_flag_delay              ;
wire                        filter_acc_flag             ;
// lp recover

wire fir_acc_demo_flag;
wire lp_recover_acc_flag;
wire    [16-1:0]            lp_recover_factor           ;
wire                        lp_recover_vld              ;
wire    [16-1:0]            lp_recover_data             ;

wire                        acc_cali_mode               ;
wire    [32-1:0]            acc_cali_low                ;
wire    [32-1:0]            acc_cali_high               ;
wire                        acc_cali_ctrl               ;
wire    [16-1:0]            acc_cali_delay_set          ;
wire    [16-1:0]            acc_flag_hold               ;
wire    [16-1:0]            acc_ctrl_delay              ;
wire    [16-1:0]            acc_ctrl_hold               ;
wire                        filter_acc_ctrl             ;

wire                        fir_zero_flag               ;
wire                        fir_ctrl_vld                ;
wire    [32-1:0]            fir_ctrl_data               ;
wire                        fir_laser_zero_flag         ;
wire                        fir_laser_vld               ;
wire    [16-1:0]            fir_laser_data              ;
wire                        fir_post_vld                ;
wire    [32-1:0]            fir_post_data               ;
wire    [16-1:0]            laser_haze_data             ;

reg wafer_zero_flag = 'd0;

  wire                               ddr3_reset_n;

  wire [DQ_WIDTH-1:0]                ddr3_dq_fpga;

  wire [DQS_WIDTH-1:0]               ddr3_dqs_p_fpga;

  wire [DQS_WIDTH-1:0]               ddr3_dqs_n_fpga;

  wire [ROW_WIDTH-1:0]               ddr3_addr_fpga;

  wire [3-1:0]              ddr3_ba_fpga;

  wire                               ddr3_ras_n_fpga;

  wire                               ddr3_cas_n_fpga;

  wire                               ddr3_we_n_fpga;

  wire [1-1:0]               ddr3_cke_fpga;

  wire [1-1:0]                ddr3_ck_p_fpga;

  wire [1-1:0]                ddr3_ck_n_fpga;

    

  

  wire                               init_calib_complete;

//   wire                               tg_compare_error;

  wire [(CS_WIDTH*1)-1:0] ddr3_cs_n_fpga;

    

  wire [DM_WIDTH-1:0]                ddr3_dm_fpga;

    

  wire [ODT_WIDTH-1:0]               ddr3_odt_fpga;

    

  

  reg [(CS_WIDTH*1)-1:0] ddr3_cs_n_sdram_tmp;

    

  reg [DM_WIDTH-1:0]                 ddr3_dm_sdram_tmp;

    

  reg [ODT_WIDTH-1:0]                ddr3_odt_sdram_tmp;

    



  

  wire [DQ_WIDTH-1:0]                ddr3_dq_sdram;

  reg [ROW_WIDTH-1:0]                ddr3_addr_sdram [0:1];

  reg [3-1:0]               ddr3_ba_sdram [0:1];

  reg                                ddr3_ras_n_sdram;

  reg                                ddr3_cas_n_sdram;

  reg                                ddr3_we_n_sdram;

  wire [(CS_WIDTH*1)-1:0] ddr3_cs_n_sdram;

  wire [ODT_WIDTH-1:0]               ddr3_odt_sdram;

  reg [1-1:0]                ddr3_cke_sdram;

  wire [DM_WIDTH-1:0]                ddr3_dm_sdram;

  wire [DQS_WIDTH-1:0]               ddr3_dqs_p_sdram;

  wire [DQS_WIDTH-1:0]               ddr3_dqs_n_sdram;

  reg [1-1:0]                 ddr3_ck_p_sdram;

  reg [1-1:0]                 ddr3_ck_n_sdram;

initial
begin
    forever #(PERIOD/2)  clk_100m=~clk_100m;
end
initial
begin
    forever #(20/2)  clk_50m=~clk_50m;
end

initial
begin
    forever #(2.5)  clk_200m=~clk_200m;
end

initial
begin
    forever #(2)  clk_250m  =~clk_250m  ;
end

initial
begin
    forever #(4)  aurora_log_clk  =~aurora_log_clk  ;
end


  //**************************************************************************//

  // Memory Models instantiations

  //**************************************************************************//

  always @( * ) begin

    ddr3_ck_p_sdram      <=  #(TPROP_PCB_CTRL) ddr3_ck_p_fpga;

    ddr3_ck_n_sdram      <=  #(TPROP_PCB_CTRL) ddr3_ck_n_fpga;

    ddr3_addr_sdram[0]   <=  #(TPROP_PCB_CTRL) ddr3_addr_fpga;

    ddr3_addr_sdram[1]   <=  #(TPROP_PCB_CTRL) ddr3_addr_fpga;

    ddr3_ba_sdram[0]     <=  #(TPROP_PCB_CTRL) ddr3_ba_fpga;

    ddr3_ba_sdram[1]     <=  #(TPROP_PCB_CTRL) ddr3_ba_fpga;

    ddr3_ras_n_sdram     <=  #(TPROP_PCB_CTRL) ddr3_ras_n_fpga;

    ddr3_cas_n_sdram     <=  #(TPROP_PCB_CTRL) ddr3_cas_n_fpga;

    ddr3_we_n_sdram      <=  #(TPROP_PCB_CTRL) ddr3_we_n_fpga;

    ddr3_cke_sdram       <=  #(TPROP_PCB_CTRL) ddr3_cke_fpga;

  end

    



  always @( * )

    ddr3_cs_n_sdram_tmp   <=  #(TPROP_PCB_CTRL) ddr3_cs_n_fpga;

  assign ddr3_cs_n_sdram =  ddr3_cs_n_sdram_tmp;

    



  always @( * )

    ddr3_dm_sdram_tmp <=  #(TPROP_PCB_DATA) ddr3_dm_fpga;//DM signal generation

  assign ddr3_dm_sdram = ddr3_dm_sdram_tmp;

    



  always @( * )

    ddr3_odt_sdram_tmp  <=  #(TPROP_PCB_CTRL) ddr3_odt_fpga;

  assign ddr3_odt_sdram =  ddr3_odt_sdram_tmp;


// Controlling the bi-directional BUS

  genvar dqwd;

  generate

    for (dqwd = 1;dqwd < DQ_WIDTH;dqwd = dqwd+1) begin : dq_delay

      WireDelay #

       (

        .Delay_g    (TPROP_PCB_DATA),

        .Delay_rd   (TPROP_PCB_DATA_RD),

        .ERR_INSERT ("OFF")

       )

      u_delay_dq

       (

        .A             (ddr3_dq_fpga[dqwd]),

        .B             (ddr3_dq_sdram[dqwd]),

        .reset         (sys_rst_n),

        .phy_init_done (init_calib_complete)

       );

    end

          WireDelay #

       (

        .Delay_g    (TPROP_PCB_DATA),

        .Delay_rd   (TPROP_PCB_DATA_RD),

        .ERR_INSERT ("OFF")

       )

      u_delay_dq_0

       (

        .A             (ddr3_dq_fpga[0]),

        .B             (ddr3_dq_sdram[0]),

        .reset         (sys_rst_n),

        .phy_init_done (init_calib_complete)

       );

  endgenerate



  genvar dqswd;

  generate

    for (dqswd = 0;dqswd < DQS_WIDTH;dqswd = dqswd+1) begin : dqs_delay

      WireDelay #

       (

        .Delay_g    (TPROP_DQS),

        .Delay_rd   (TPROP_DQS_RD),

        .ERR_INSERT ("OFF")

       )

      u_delay_dqs_p

       (

        .A             (ddr3_dqs_p_fpga[dqswd]),

        .B             (ddr3_dqs_p_sdram[dqswd]),

        .reset         (sys_rst_n),

        .phy_init_done (init_calib_complete)

       );



      WireDelay #

       (

        .Delay_g    (TPROP_DQS),

        .Delay_rd   (TPROP_DQS_RD),

        .ERR_INSERT ("OFF")

       )

      u_delay_dqs_n

       (

        .A             (ddr3_dqs_n_fpga[dqswd]),

        .B             (ddr3_dqs_n_sdram[dqswd]),

        .reset         (sys_rst_n),

        .phy_init_done (init_calib_complete)

       );

    end

  endgenerate




  //**************************************************************************//

  // Memory Models instantiations

  //**************************************************************************//



  genvar r,i;

  generate

    for (r = 0; r < CS_WIDTH; r = r + 1) begin: mem_rnk

      if(DQ_WIDTH/16) begin: mem

        for (i = 0; i < NUM_COMP; i = i + 1) begin: gen_mem

          ddr3_model u_comp_ddr3

            (

             .rst_n   (ddr3_reset_n),

             .ck      (ddr3_ck_p_sdram),

             .ck_n    (ddr3_ck_n_sdram),

             .cke     (ddr3_cke_sdram[r]),

             .cs_n    (ddr3_cs_n_sdram[r]),

             .ras_n   (ddr3_ras_n_sdram),

             .cas_n   (ddr3_cas_n_sdram),

             .we_n    (ddr3_we_n_sdram),

             .dm_tdqs (ddr3_dm_sdram[(2*(i+1)-1):(2*i)]),

             .ba      (ddr3_ba_sdram[r]),

             .addr    (ddr3_addr_sdram[r]),

             .dq      (ddr3_dq_sdram[16*(i+1)-1:16*(i)]),

             .dqs     (ddr3_dqs_p_sdram[(2*(i+1)-1):(2*i)]),

             .dqs_n   (ddr3_dqs_n_sdram[(2*(i+1)-1):(2*i)]),

             .tdqs_n  (),

             .odt     (ddr3_odt_sdram[r])

             );

        end

      end

      if (DQ_WIDTH%16) begin: gen_mem_extrabits

        ddr3_model u_comp_ddr3

          (

           .rst_n   (ddr3_reset_n),

           .ck      (ddr3_ck_p_sdram),

           .ck_n    (ddr3_ck_n_sdram),

           .cke     (ddr3_cke_sdram[r]),

           .cs_n    (ddr3_cs_n_sdram[r]),

           .ras_n   (ddr3_ras_n_sdram),

           .cas_n   (ddr3_cas_n_sdram),

           .we_n    (ddr3_we_n_sdram),

           .dm_tdqs ({ddr3_dm_sdram[DM_WIDTH-1],ddr3_dm_sdram[DM_WIDTH-1]}),

           .ba      (ddr3_ba_sdram[r]),

           .addr    (ddr3_addr_sdram[r]),

           .dq      ({ddr3_dq_sdram[DQ_WIDTH-1:(DQ_WIDTH-8)],

                      ddr3_dq_sdram[DQ_WIDTH-1:(DQ_WIDTH-8)]}),

           .dqs     ({ddr3_dqs_p_sdram[DQS_WIDTH-1],

                      ddr3_dqs_p_sdram[DQS_WIDTH-1]}),

           .dqs_n   ({ddr3_dqs_n_sdram[DQS_WIDTH-1],

                      ddr3_dqs_n_sdram[DQS_WIDTH-1]}),

           .tdqs_n  (),

           .odt     (ddr3_odt_sdram[r])

           );

      end

    end

  endgenerate

    
  //***************************************************************************

  // Reporting the test case status

  // Status reporting logic exists both in simulation test bench (sim_tb_top)

  // and sim.do file for ModelSim. Any update in simulation run time or time out

  // in this file need to be updated in sim.do file as well.

  //***************************************************************************

reg     SFP_MGT_REFCLK_C_P   = 1; 
reg     SFP_MGT_REFCLK_C_N   = 0; 
wire    FPGA_SFP1_RX_P      ; 
wire    FPGA_SFP1_RX_N      ;  
wire    FPGA_SFP1_TX_P      ; 
wire    FPGA_SFP1_TX_N      ; 

initial
begin
    forever #(10/2)  SFP_MGT_REFCLK_C_P = ~SFP_MGT_REFCLK_C_P;
end
initial
begin
    forever #(10/2)  SFP_MGT_REFCLK_C_N = ~SFP_MGT_REFCLK_C_N;
end

// `ifdef SIMULATE
// fir_tap_message_sim  udp_message_sim_inst(
//     .clk_i                          ( clk_100m                          ),
//     .rst_i                          ( laser_rst_r                       ),
//     .rec_pkt_done_o                 ( eth_rec_pkt_done_sim              ),
//     .rec_en_o                       ( eth_rec_en_sim                    ),
//     .rec_data_o                     ( eth_rec_data_sim                  ),
//     .rec_byte_num_en_o              ( eth_rec_byte_num_en_sim           ),
//     .rec_byte_num_o                 ( eth_rec_byte_num_sim              )
// );

// `endif //SIMULATE


// // message response communication
// message_comm message_comm_inst(
//     // clk & rst
//     .phy_rx_clk                     ( clk_100m                          ),
//     .clk                            ( clk_50m                           ),
//     .rst_n                          ( ~rst_100m                         ),
//     // ethernet interface for message data
//     .rec_pkt_done_i                 ( eth_rec_pkt_done_sim              ),
//     .rec_en_i                       ( eth_rec_en_sim                    ),
//     .rec_data_i                     ( eth_rec_data_sim                  ),
//     .rec_byte_num_en_i              ( eth_rec_byte_num_en_sim           ),
//     .rec_byte_num_i                 ( eth_rec_byte_num_sim              ),

//     .comm_ack_o                     ( comm_ack                          ),
//     // message rx info
//     .rd_data_vld_o                  ( rd_data_vld                       ),
//     .rd_data_o                      ( rd_data                           ),
//     // info
//     .MSG_CLK                        ( FPGA_TO_SFPGA_RESERVE0            ),
//     .MSG_TX_FSX                     ( FPGA_TO_SFPGA_RESERVE1            ),
//     .MSG_TX                         ( FPGA_TO_SFPGA_RESERVE2            ),
//     .MSG_RX_FSX                     ( FPGA_TO_SFPGA_RESERVE3            ),
//     .MSG_RX                         ( FPGA_TO_SFPGA_RESERVE4            )
// );

// mfpga to mainPC message arbitrate 
arbitrate_bpsi #(
    .MFPGA_VERSION                  ( "PCG1_PMTM_v7.2      "        )
) arbitrate_bpsi_inst(
    .clk_i                          ( clk_100m                      ),
    .rst_i                          ( rst_100m                      ),

    .readback_vld_i                 ( readback_vld                  ),
    .readback_last_i                ( readback_last                 ),
    .readback_data_i                ( readback_data                 ),

    .slave_tx_ack_i                 ( slave_tx_ack                  ),
    .slave_tx_byte_en_o             ( slave_tx_byte_en              ),
    .slave_tx_byte_o                ( slave_tx_byte                 ),
    .slave_tx_byte_num_en_o         ( slave_tx_byte_num_en          ),
    .slave_tx_byte_num_o            ( slave_tx_byte_num             )
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


// command_map command_map_inst(
//     .clk_sys_i                      ( clk_100m                          ),
//     .rst_i                          ( rst_100m                          ),
//     .slave_rx_data_vld_i            ( slave_rx_data_vld                 ),
//     .slave_rx_data_i                ( slave_rx_data                     ),
    
//     .ddr_rd_addr_o                  ( ddr_rd_addr                       ),
//     .ddr_rd_en_o                    ( ddr_rd_en                         ),
//     // .fir_tap_wr_cmd_o               ( fir_tap_wr_cmd                    ),
//     // .fir_tap_wr_addr_o              ( fir_tap_wr_addr                   ),
//     // .fir_tap_wr_vld_o               ( fir_tap_wr_vld                    ),
//     // .fir_tap_wr_data_o              ( fir_tap_wr_data                   ),

//     // .acc_track_para_wr_o            ( acc_track_para_wr                 ),
//     // .acc_track_para_addr_o          ( acc_track_para_addr               ),
//     // .acc_track_para_data_o          ( acc_track_para_data               ),

//     .debug_info                     (                                   )
// );

`ifdef SIMULATE
fir_tap_map_sim fir_tap_map_sim_inst(
    // clk & rst
    .clk_i                          ( clk_100m                          ),
    .rst_i                          ( laser_rst_r                       ),

    // .acc_track_para_wr_o            ( acc_track_para_wr                 ),
    // .acc_track_para_addr_o          ( acc_track_para_addr               ),
    // .acc_track_para_data_o          ( acc_track_para_data               ),

    .fir_tap_wr_cmd_o               ( fir_tap_wr_cmd                    ),
    // .fir_tap_wr_addr_o              ( fir_tap_wr_addr                   ),
    .fir_tap_wr_vld_o               ( fir_tap_wr_vld                    ),
    .fir_tap_wr_data_o              ( fir_tap_wr_data                   )
);
`endif //SIMULATE

spi_reg_map #(
    .DATA_WIDTH                     ( 32                                ),
    .ADDR_WIDTH                     ( 16                                ),
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

    .debug_info                     (                                   )
);

acc_ctrl_tx_drv acc_ctrl_tx_drv_inst(
    // clk & rst
    .clk_i                          ( clk_100m                          ),
    .rst_i                          ( rst_100m                          ),
    .clk_200m_i                     ( clk_200m                          ),

    .filter_acc_ctrl_i              ( filter_acc_ctrl || acc_cali_ctrl  ),

    // spi info
    .SPI_SCLK                       ( ACC_SPI_SCLK                      ),
    .SPI_MISO                       ( ACC_SPI_MISO                      )
);


acc_ctrl_rx_drv acc_ctrl_rx_drv_inst(
    // clk & rst
    .clk_i                          ( clk_100m                          ),
    .rst_i                          ( rst_100m                          ),
    .clk_200m_i                     ( clk_200m                          ),

    .acc_aom_flag_o                 ( acc_aom_flag                      ),

    // spi info
    .SPI_SCLK                       ( ACC_SPI_SCLK                      ),
    .SPI_MISO                       ( ACC_SPI_MISO                      )
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

acc_lp_recover acc_lp_recover_inst(
    // clk & rst 
    .clk_i                          ( clk_100m                          ),
    .rst_i                          ( rst_100m                          ),

    .laser_vld_i                    ( laser_vld_i                       ),
    .laser_data_i                   ( laser_data_i                      ),
    .filter_acc_flag_i              ( filter_acc_flag                   ),

    .lp_recover_factor_i            ( lp_recover_factor                 ),  // 8bit integer + 8bit decimal

    .lp_recover_acc_flag_o          ( lp_recover_acc_flag               ),
    .lp_recover_vld_o               ( lp_recover_vld                    ),
    .lp_recover_data_o              ( lp_recover_data                   )
);

fir_ctrl #(
    .FIR_TAP_WIDTH                  ( 32                                ),
    .DATA_WIDTH                     ( 32                                )
)fir_ctrl_inst (
    .clk_i                          ( clk_100m                          ),
    .rst_i                          ( rst_100m                          ),

    .laser_fir_upmode_i             ( laser_fir_upmode                  ),
    .laser_fir_en_i                 ( laser_fir_en                      ),
    .laser_start_i                  ( real_adc_start                    ),

    .fir_tap_para_vld_i             ( fir_tap_rd_vld                    ),
    .fir_tap_para_data_i            ( fir_tap_rd_data                   ),
    .fir_tap_para_ren_o             ( fir_tap_rd_en                     ),
    .fir_tap_ready_i                ( fir_tap_ready                     ),

    .encode_zero_flag_i             ( wafer_zero_flag                   ),
    .lp_recover_acc_flag_i          ( lp_recover_acc_flag               ),
    .laser_vld_i                    ( lp_recover_vld                    ),
    .laser_data_i                   ( lp_recover_data                   ),

    .fir_zero_flag_o                ( fir_zero_flag                     ),
    .fir_acc_flag_o                 ( fir_acc_demo_flag                 ),
    .fir_laser_vld_o                ( fir_laser_vld                     ),
    .fir_laser_data_o               ( fir_laser_data                    )
);

fir_post_process fir_post_process_inst(
    // clk & rst 
    .clk_i                          ( clk_100m                          ),
    .rst_i                          ( rst_100m                          ),

    .laser_start_i                  ( real_adc_start                    ),
    .fir_laser_vld_i                ( fir_laser_vld                     ),
    .fir_laser_data_i               ( fir_laser_data                    ),

    .fir_post_vld_o                 ( fir_post_vld                      ),
    .fir_post_data_o                ( fir_post_data                     )
);

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

ddr_top u_ddr_top (
    .clk_i                          ( clk_100m                          ),
    .rst_i                          ( rst_100m                          ),
    .clk_250m_i                     ( clk_250m                          ),
    .clk_200m_i                     ( clk_200m                          ),
    
    // laser cache
    .laser_start_i                  ( real_adc_start                    ),
    .laser_vld_i                    ( fir_post_vld                      ),
    .laser_data_i                   ( fir_post_data                     ),
    .filter_acc_flag_i              ( filter_acc_flag                   ),
    .laser_haze_data_i              ( laser_haze_data                   ),
    
    .pre_laser_rd_seq_i             ( pre_laser_rd_seq                  ),
    .laser_fifo_ready_o             ( laser_fifo_ready                  ),
    .pre_laser_rd_data_o            ( pre_laser_rd_data                 ),

    // fir tap
    .fir_tap_wr_cmd_i               ( fir_tap_wr_cmd                    ),
    // .fir_tap_wr_addr_i              ( fir_tap_wr_addr                   ),
    .fir_tap_wr_vld_i               ( fir_tap_wr_vld                    ),
    .fir_tap_wr_data_i              ( fir_tap_wr_data                   ),
    .laser_fir_en_i                 ( laser_fir_en                      ),
    .encode_zero_flag_i             ( fir_zero_flag                     ),
    .fir_tap_rd_en_i                ( fir_tap_rd_en                     ),
    .fir_tap_ready_o                ( fir_tap_ready                     ),
    .fir_tap_rd_vld_o               ( fir_tap_rd_vld                    ),
    .fir_tap_rd_data_o              ( fir_tap_rd_data                   ),

    // readback ddr
    .ddr_rd_addr_i                  ( ddr_rd_addr                       ),
    .ddr_rd_en_i                    ( ddr_rd_en                         ),
    .readback_vld_o                 ( readback_vld                      ),
    .readback_last_o                ( readback_last                     ),
    .readback_data_o                ( readback_data                     ),
    

    .init_calib_complete_o          ( init_calib_complete               ),
    .ddr3_addr                      ( ddr3_addr_fpga                    ),
    .ddr3_ba                        ( ddr3_ba_fpga                      ),
    .ddr3_ras_n                     ( ddr3_ras_n_fpga                   ),
    .ddr3_cas_n                     ( ddr3_cas_n_fpga                   ),
    .ddr3_we_n                      ( ddr3_we_n_fpga                    ),
    .ddr3_reset_n                   ( ddr3_reset_n                      ),
    .ddr3_ck_p                      ( ddr3_ck_p_fpga                    ),
    .ddr3_ck_n                      ( ddr3_ck_n_fpga                    ),
    .ddr3_cke                       ( ddr3_cke_fpga                     ),
    .ddr3_cs_n                      ( ddr3_cs_n_fpga                    ),
    .ddr3_dm                        ( ddr3_dm_fpga                      ),
    .ddr3_odt                       ( ddr3_odt_fpga                     ),

    .ddr3_dq                        ( ddr3_dq_fpga                      ),
    .ddr3_dqs_n                     ( ddr3_dqs_n_fpga                   ),
    .ddr3_dqs_p                     ( ddr3_dqs_p_fpga                   )
);

laser_particle_detect #(
    .DATA_WIDTH                     ( 32                                ) 
)laser_particle_detect_inst(
    // clk & rst 
    .clk_i                          ( clk_100m                          ),    
    .rst_i                          ( rst_100m                          ),
    .aurora_log_clk_i               ( aurora_log_clk                    ),

    // acc track parameter write
    .acc_track_para_wr_i            ( acc_track_para_wr                 ),
    .acc_track_para_addr_i          ( acc_track_para_addr               ),
    .acc_track_para_data_i          ( acc_track_para_data               ),

    // acc align
    .circle_lose_num_i              ( circle_lose_num                   ),
    .circle_lose_num_delta_i        ( circle_lose_num_delta             ),
    .uniform_circle_i               ( uniform_circle_num                ),

    // acc threshold
    .acc_defect_en_i                ( acc_defect_en && (~acc_cali_mode) ),
    .pre_acc_curr_thre_i            ( pre_acc_curr_thre                 ),
    .actu_acc_curr_thre_i           ( actu_acc_curr_thre                ),
    .actu_acc_cache_thre_i          ( actu_acc_cache_thre               ),
    .lp_pre_acc_curr_thre_i         ( lp_pre_acc_curr_thre              ),
    .lp_actu_acc_curr_thre_i        ( lp_actu_acc_curr_thre             ),
    .lp_actu_acc_cache_thre_i       ( lp_actu_acc_cache_thre            ),

    // acc flag generate
    .acc_cali_delay_set_i           ( acc_cali_delay_set                ),
    .acc_flag_delay_i               ( acc_flag_delay                    ),
    .acc_flag_hold_i                ( acc_flag_hold                     ),
    .filter_acc_flag_o              ( filter_acc_flag                   ),
    .acc_ctrl_delay_i               ( acc_ctrl_delay                    ),
    .acc_ctrl_hold_i                ( acc_ctrl_hold                     ),
    .filter_acc_ctrl_o              ( filter_acc_ctrl                   ),

    // current track data
    .aurora_upmode_i                ( 0                     ),
    .acc_cali_mode_ctrl_i           ( acc_cali_ctrl && acc_cali_mode    ),
    .laser_start_i                  ( real_adc_start                    ),
    .encode_zero_flag_i             ( fir_zero_flag                     ),
    .laser_acc_flag_i               ( fir_acc_demo_flag                 ),
    .laser_vld_i                    ( fir_post_vld                      ),
    .laser_data_i                   ( fir_post_data                     ),
    .laser_haze_data_i              ( laser_haze_data                   ),

    // previous track data, from ddr
    .pre_laser_rd_ready_i           ( laser_fifo_ready                  ),
    .pre_laser_rd_seq_o             ( pre_laser_rd_seq                  ),
    .pre_laser_rd_data_i            ( pre_laser_rd_data                 ),

    // aurora interface
    .aurora_txen_i                  ( aurora_txen                       ),
    .aurora_txdata_o                ( aurora_txdata                     ),
    .aurora_tx_emp_o                ( aurora_tx_emp                     ),
    .aurora_rd_data_count_o         ( aurora_rd_data_count              )
);

assign CHANNEL_UP_DONE = 'd1;
reg aurora_txen_r = 'd0;
always @(posedge aurora_log_clk) begin
    if(~aurora_tx_emp)
        aurora_txen_r <= #TPROP_PCB_CTRL 'd1;
    else 
        aurora_txen_r <= #TPROP_PCB_CTRL 'd0;
end
assign aurora_txen = aurora_txen_r;
// aurora_8b10b_0_exdes  aurora_8b10b_exdes_inst_0(
//     .aurora_log_clk                 ( aurora_log_clk                    ),
//     .aurora_rxen                    ( aurora_rxen                       ),
//     .aurora_rxdata                  ( aurora_rxdata                     ),
//     .aurora_txen                    ( aurora_txen                       ),
//     .aurora_txdata                  ( aurora_txdata                     ),
//     .aurora_rd_data_count           ( aurora_rd_data_count              ),

//     // .adc_start                      ( adc_start                         ),
//     // .adc_end                        ( adc_end                           ),
//     // .adc_test                       ( adc_test                          ),
//     // .clear_buffer                   ( clear_buffer                      ),

//     .RESET                          ( aurora_rst                        ),
//     .HARD_ERR                       (                                   ),
//     .SOFT_ERR                       (                                   ),
//     .FRAME_ERR                      (                                   ),
//     .CHANNEL_UP_DONE                ( CHANNEL_UP_DONE                   ),
//     .INIT_CLK_P                     ( clk_50m                           ),
//     .DRP_CLK_IN                     ( clk_50m                           ),
//     .GT_RESET_IN                    ( rst_100m                          ),
 
//     .GTPQ2_P                        ( SFP_MGT_REFCLK_C_P                ),
//     .GTPQ2_N                        ( SFP_MGT_REFCLK_C_N                ),
//     .RXP                            ( FPGA_SFP1_RX_P                    ),
//     .RXN                            ( FPGA_SFP1_RX_N                    ),
//     .TXP                            ( FPGA_SFP1_TX_P                    ),
//     .TXN                            ( FPGA_SFP1_TX_N                    )
// );

reset_generate reset_generate(
    .nrst_i                         ( pll_locked                        ),

    .clk_100m                       ( clk_100m                          ),
    .rst_100m                       ( rst_100m                          ),
    .clk_200m                       ( clk_200m                          ),
    .rst_200m                       ( rst_200m                          ),
    .clk_50m                        ( clk_50m                           ),
    .gt_rst                         ( gt_rst                            ),
    .aurora_log_clk                 ( aurora_log_clk                    ),
    .aurora_rst                     ( aurora_rst                        )
);

always @(posedge clk_100m) 
begin
    if(rst_100m) begin
        laser_rst_r         <= #(TPROP_PCB_CTRL) 'd1;
    end
    else begin
        CHANNEL_UP_DONE_r   <= #(TPROP_PCB_CTRL) 'd1;
        ddr3_init_done_r    <= #(TPROP_PCB_CTRL) init_calib_complete;
        laser_rst_r         <= #(TPROP_PCB_CTRL) ~ddr3_init_done_r || ~CHANNEL_UP_DONE_r;
    end
end

initial begin
    pll_locked = 0;
    #200 pll_locked = 1;
end

initial begin
    sys_rst_n = 1'b0;
    #200
    sys_rst_n = 1'b1;
end

always @(posedge clk_100m) begin
    if(~laser_rst_r)
        laser_fir_en <= #(10000) 'd1;
    else 
        laser_fir_en <= #(TPROP_PCB_CTRL) 'd0;
end

always @(posedge clk_100m) begin
    if(~laser_rst_r)
        laser_start_i <= #(20000) 'd1;
    else 
        laser_start_i <= #(TPROP_PCB_CTRL) 'd0;
end

reg aurora_adc_end = 0;
wire adc_start_sync;
scan_flag_generate scan_flag_generate_inst(
    // clk & rst
    .clk_i                          ( clk_100m                          ),
    .rst_i                          ( rst_100m                          ),
    .aurora_clk_i                   ( aurora_log_clk                    ),

    .adc_start_en_i                 ( laser_start_i                     ),
    .adc_end_en_i                   ( aurora_adc_end                    ),
    .aurora_adc_start_o             ( adc_start_sync                    ),
    .real_pmt_scan_o                ( real_adc_start                    )   
);

reg [32:0] laser_data_cnt = 'd0;
// reg        laser_vld_en = 'd0;
// always @(posedge clk_100m) begin
//     laser_vld_en <= #(TPROP_PCB_CTRL) ~laser_vld_en;
// end
always @(posedge clk_100m) begin
    if(real_adc_start)
        laser_data_cnt <= #(TPROP_PCB_CTRL) laser_data_cnt + 1;
    else if(~real_adc_start)
        laser_data_cnt <= #(TPROP_PCB_CTRL) 'd0;
end

always @(posedge clk_100m) begin
    if(~real_adc_start)begin
        laser_vld_i <= #(TPROP_PCB_CTRL) 'd0;
    end
    else begin
        laser_vld_i     <= #(TPROP_PCB_CTRL) 'd1;
        laser_data_i    <= #(TPROP_PCB_CTRL) laser_data_i + 1;
    end
end

always @(posedge clk_100m) begin
    // wafer_zero_flag <= #(TPROP_PCB_CTRL) 'd0;
    wafer_zero_flag <= #(TPROP_PCB_CTRL) laser_data_cnt[15:0]=='h1fff;
end


initial begin : Logging
    fork
        begin : calibration_done
            wait (init_calib_complete);

            $display("Calibration Done");
            #50000000.0;
            $display("TEST FAILED: DATA ERROR");
            disable calib_not_done;

            $finish;
        end



        begin : calib_not_done

            #1000000000.0;
            if (!init_calib_complete) begin
                $display("TEST FAILED: INITIALIZATION DID NOT COMPLETE");
            end

            disable calibration_done;

            $finish;
        end
    join
end



endmodule