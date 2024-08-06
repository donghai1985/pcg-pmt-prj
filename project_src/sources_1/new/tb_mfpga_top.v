//~ `New testbench
`timescale  1ns / 1ps

module tb_pmt_mfpga_top;

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
reg                     clk_100m                = 0 ;
reg                     clk_50m                 = 0 ;
reg                     sys_rst_n               = 0 ;
reg                     clk_200m                = 0 ;

reg                     rst_100m                = 0 ;

wire    [16-1:0]        AD9265_DATA                 ;
wire                    AD9265_DCO                  ;

wire                    FPGA_RESET                  ;
wire                    CLK_SEL                     ;
wire                    USER_SMA_CLOCK              ;
wire                    FPGA_MASTER_CLOCK_P         ;
wire                    FPGA_MASTER_CLOCK_N         ;
wire                    TIMING_SYNC_REFCLK_P        ;
wire                    TIMING_SYNC_REFCLK_N        ;

// Timing simulate
wire                    PMT_SPI_MCLK                ;
wire                    PMT_SPI_MOSI                ;
wire                    PMT_SPI_SCLK                ;
wire                    PMT_SPI_MISO                ;

wire                    eth_rec_pkt_done_sim        ;
wire                    eth_rec_en_sim              ;
wire [7:0]              eth_rec_data_sim            ;
wire                    eth_rec_byte_num_en_sim     ;
wire [15:0]             eth_rec_byte_num_sim        ;
  

wire                    ENCODE_SPI_MCLK             ;
wire                    ENCODE_SPI_MOSI             ;

wire                    FPGA_TO_SFPGA_RESERVE0      ;
wire                    FPGA_TO_SFPGA_RESERVE1      ;
wire                    FPGA_TO_SFPGA_RESERVE2      ;
wire                    FPGA_TO_SFPGA_RESERVE3      ;
wire                    FPGA_TO_SFPGA_RESERVE4      ;
wire                    rd_data_vld                 ;
wire [7:0]              rd_data                     ;

wire                    TIMING_SPI_MCLK_P           ;
wire                    TIMING_SPI_MCLK_N           ;
wire                    TIMING_SPI_MOSI_P           ;
wire                    TIMING_SPI_MOSI_N           ;
wire                    TIMING_SPI_SCLK_P           ;
wire                    TIMING_SPI_SCLK_N           ;
wire                    TIMING_SPI_MISO_P           ;
wire                    TIMING_SPI_MISO_N           ;
wire                    ENCODE_MCLK_P               ;
wire                    ENCODE_MCLK_N               ;
wire                    ENCODE_MOSI_P               ;
wire                    ENCODE_MOSI_N               ;
wire                    ACC_SCLK_P                  ;
wire                    ACC_SCLK_N                  ;
wire                    ACC_MISO_P                  ;
wire                    ACC_MISO_N                  ;
wire                    acc_aom_flag                ;

wire                    ddr3_init_done              ;

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

initial begin
    sys_rst_n = 1'b0;
    #200
    sys_rst_n = 1'b1;
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

mfpga_top sim_mfpga_top_inst(
    //sys io
    .FPGA_RESET                     ( FPGA_RESET                        ), 
    .CLK_SEL                        ( CLK_SEL                           ),
    .USER_SMA_CLOCK                 ( USER_SMA_CLOCK                    ),
    .FPGA_MASTER_CLOCK_P            ( FPGA_MASTER_CLOCK_P               ),
    .FPGA_MASTER_CLOCK_N            ( FPGA_MASTER_CLOCK_N               ),
    .TIMING_SYNC_REFCLK_P           ( TIMING_SYNC_REFCLK_P              ),
    .TIMING_SYNC_REFCLK_N           ( TIMING_SYNC_REFCLK_N              ),
    //sfp serdes
    .SFP_MGT_REFCLK_C_P             ( SFP_MGT_REFCLK_C_P                ), 
    .SFP_MGT_REFCLK_C_N             ( SFP_MGT_REFCLK_C_N                ), 
    .FPGA_SFP1_RX_P                 ( FPGA_SFP1_RX_P                    ), 
    .FPGA_SFP1_RX_N                 ( FPGA_SFP1_RX_N                    ),  
    .FPGA_SFP1_TX_P                 ( FPGA_SFP1_TX_P                    ), 
    .FPGA_SFP1_TX_N                 ( FPGA_SFP1_TX_N                    ), 
    //AD9265
    .AD9265_DATA                    ( AD9265_DATA                       ),
    .AD9265_DCO                     ( AD9265_DCO                        ),
    .AD9265_OR                      ( AD9265_OR                         ),
    .AD9265_SYNC                    ( AD9265_SYNC                       ),
    .AD9265_PDWN                    ( AD9265_PDWN                       ),
    .AD9265_SCLK                    ( AD9265_SCLK                       ),
    .AD9265_CSB                     ( AD9265_CSB                        ),
    .AD9265_SDIO                    ( AD9265_SDIO                       ),
    //status io
    .DDR_POWER_GOOD                 ( DDR_POWER_GOOD                    ), 
    .VCC3V3_PG                      ( VCC3V3_PG                         ), 
    .MGTAVTT_PG                     ( MGTAVTT_PG                        ), 
    .VCC3V6_PG                      ( VCC3V6_PG                         ), 
    .VCC_3V_A_PG                    ( VCC_3V_A_PG                       ), 
    //power en
    .VCC12V_FAN_EN                  ( VCC12V_FAN_EN                     ), 
    .TIMING_LVDS_EN                 ( TIMING_LVDS_EN                    ),
    //SPI
    .TIMING_SPI_MCLK_P              ( TIMING_SPI_MCLK_P                 ),  // timing_spi_2
    .TIMING_SPI_MCLK_N              ( TIMING_SPI_MCLK_N                 ),  // timing_spi_2
    .TIMING_SPI_MOSI_P              ( TIMING_SPI_MOSI_P                 ),  // timing_spi_2
    .TIMING_SPI_MOSI_N              ( TIMING_SPI_MOSI_N                 ),  // timing_spi_2
    .TIMING_SPI_SCLK_P              ( TIMING_SPI_SCLK_P                 ),  // timing_spi_2
    .TIMING_SPI_SCLK_N              ( TIMING_SPI_SCLK_N                 ),  // timing_spi_2
    .TIMING_SPI_MISO_P              ( TIMING_SPI_MISO_P                 ),  // timing_spi_2
    .TIMING_SPI_MISO_N              ( TIMING_SPI_MISO_N                 ),  // timing_spi_2
    // ENCODE
    .ENCODE_MCLK_P                  ( ENCODE_MCLK_P                     ),
    .ENCODE_MCLK_N                  ( ENCODE_MCLK_N                     ),
    .ENCODE_MOSI_P                  ( ENCODE_MOSI_P                     ),
    .ENCODE_MOSI_N                  ( ENCODE_MOSI_N                     ),
    // ACC
    .ACC_SCLK_P                     ( ACC_SCLK_P                        ),
    .ACC_SCLK_N                     ( ACC_SCLK_N                        ),
    .ACC_MISO_P                     ( ACC_MISO_P                        ),
    .ACC_MISO_N                     ( ACC_MISO_N                        ),
    // AOM 固定电平
    .RF_ENABLE                      ( RF_ENABLE                         ),
    .RF_FAULT                       ( RF_FAULT                          ),
    //sfp1 io
    .FPGA_SFP1_TX_FAULT             ( FPGA_SFP1_TX_FAULT                ), 
    .FPGA_SFP1_TX_DISABLE           ( FPGA_SFP1_TX_DISABLE              ), 
    .FPGA_SFP1_MOD_DETECT           ( FPGA_SFP1_MOD_DETECT              ), 
    .FPGA_SFP1_LOS                  ( FPGA_SFP1_LOS                     ), 
    .FPGA_SFP1_IIC_SCL              ( FPGA_SFP1_IIC_SCL                 ), 
    .FPGA_SFP1_IIC_SDA              ( FPGA_SFP1_IIC_SDA                 ), 
    //sfp2 io
    .FPGA_SFP2_TX_FAULT             ( FPGA_SFP2_TX_FAULT                ), 
    .FPGA_SFP2_TX_DISABLE           ( FPGA_SFP2_TX_DISABLE              ), 
    .FPGA_SFP2_MOD_DETECT           ( FPGA_SFP2_MOD_DETECT              ), 
    .FPGA_SFP2_LOS                  ( FPGA_SFP2_LOS                     ), 
    .FPGA_SFP2_IIC_SCL              ( FPGA_SFP2_IIC_SCL                 ), 
    .FPGA_SFP2_IIC_SDA              ( FPGA_SFP2_IIC_SDA                 ), 
    //ddr3
    .DDR3_A_ADD                     ( ddr3_addr_fpga                    ),
    .DDR3_A_BA                      ( ddr3_ba_fpga                      ),
    .DDR3_A_RAS_B                   ( ddr3_ras_n_fpga                   ),
    .DDR3_A_CAS_B                   ( ddr3_cas_n_fpga                   ),
    .DDR3_A_WE_B                    ( ddr3_we_n_fpga                    ),
    .DDR3_A_RESET_B                 ( ddr3_reset_n                      ),
    .DDR3_A_CLK0_P                  ( ddr3_ck_p_fpga                    ),
    .DDR3_A_CLK0_N                  ( ddr3_ck_n_fpga                    ),
    .DDR3_A_CKE                     ( ddr3_cke_fpga                     ),
    .DDR3_A_S0_B                    ( ddr3_cs_n_fpga                    ),
    .DDR3_A_DM                      ( ddr3_dm_fpga                      ),
    .DDR3_A_ODT                     ( ddr3_odt_fpga                     ),

    .DDR3_A_D                       ( ddr3_dq_fpga                      ),
    .DDR3_A_DQS_N                   ( ddr3_dqs_n_fpga                   ),
    .DDR3_A_DQS_P                   ( ddr3_dqs_p_fpga                   ),

    //fan
    .FAN_FG                         ( FAN_FG                            ), 
    //ad5592
    .AD5592_1_SPI_CS_B              ( AD5592_1_SPI_CS_B                 ), 
    .AD5592_1_SPI_CLK               ( AD5592_1_SPI_CLK                  ), 
    .AD5592_1_SPI_MOSI              ( AD5592_1_SPI_MOSI                 ), 
    .AD5592_1_SPI_MISO              ( AD5592_1_SPI_MISO                 ), 
    // cdcm61001
    .FPGA_PLL_CLK_IN                ( FPGA_PLL_CLK_IN                   ),
    .FPGA_PLL_PR0                   ( FPGA_PLL_PR0                      ),
    .FPGA_PLL_PR1                   ( FPGA_PLL_PR1                      ),
    .FPGA_PLL_OD0                   ( FPGA_PLL_OD0                      ),
    .FPGA_PLL_OD1                   ( FPGA_PLL_OD1                      ),
    .FPGA_PLL_OD2                   ( FPGA_PLL_OD2                      ),
    .FPGA_PLL_CE                    ( FPGA_PLL_CE                       ),
    .FPGA_PLL_RST_N                 ( FPGA_PLL_RST_N                    ),
    // VCC12V
    .FPGA_VCC12V_BST_EN             ( FPGA_VCC12V_BST_EN                ),
    // ad5542
    .FPGA_DAC_SPI_CS_N              ( FPGA_DAC_SPI_CS_N                 ),
    .FPGA_DAC_SPI_SCLK              ( FPGA_DAC_SPI_SCLK                 ),
    .FPGA_DAC_SPI_DIN               ( FPGA_DAC_SPI_DIN                  ),
    .FPGA_DAC_CLR_N                 ( FPGA_DAC_CLR_N                    ),
    //
    .FPGA_TO_SFPGA_RESERVE0         ( FPGA_TO_SFPGA_RESERVE0            ),  //clk
    .FPGA_TO_SFPGA_RESERVE1         ( FPGA_TO_SFPGA_RESERVE1            ),  //fsr
    .FPGA_TO_SFPGA_RESERVE2         ( FPGA_TO_SFPGA_RESERVE2            ),  //rx
    .FPGA_TO_SFPGA_RESERVE3         ( FPGA_TO_SFPGA_RESERVE3            ),  //fsx
    .FPGA_TO_SFPGA_RESERVE4         ( FPGA_TO_SFPGA_RESERVE4            ),  //tx
    .FPGA_TO_SFPGA_RESERVE5         ( FPGA_TO_SFPGA_RESERVE5            ),  //reserved
    .FPGA_TO_SFPGA_RESERVE6         ( FPGA_TO_SFPGA_RESERVE6            ),  //reserved
    .FPGA_TO_SFPGA_RESERVE7         ( FPGA_TO_SFPGA_RESERVE7            ),  //reserved
    .FPGA_TO_SFPGA_RESERVE8         ( FPGA_TO_SFPGA_RESERVE8            ),  //reserved
    .FPGA_TO_SFPGA_RESERVE9         ( FPGA_TO_SFPGA_RESERVE9            ),  //reserved
    //test io
    .TP112                          ( TP112                             ),
    .TP113                          ( ddr3_init_done                    ),
    .TP114                          ( TP114                             ),
    .TP115                          ( TP115                             )
);

// message response communication
message_comm message_comm_inst(
    // clk & rst
    .phy_rx_clk                     ( clk_100m                          ),
    .clk                            ( clk_50m                           ),
    .rst_n                          ( ~rst_100m                         ),
    // ethernet interface for message data
    .rec_pkt_done_i                 ( eth_rec_pkt_done_sim              ),
    .rec_en_i                       ( eth_rec_en_sim                    ),
    .rec_data_i                     ( eth_rec_data_sim                  ),
    .rec_byte_num_en_i              ( eth_rec_byte_num_en_sim           ),
    .rec_byte_num_i                 ( eth_rec_byte_num_sim              ),

    .comm_ack_o                     ( comm_ack                          ),
    // message rx info
    .rd_data_vld_o                  ( rd_data_vld                       ),
    .rd_data_o                      ( rd_data                           ),
    // info
    .MSG_CLK                        ( FPGA_TO_SFPGA_RESERVE0            ),
    .MSG_TX_FSX                     ( FPGA_TO_SFPGA_RESERVE1            ),
    .MSG_TX                         ( FPGA_TO_SFPGA_RESERVE2            ),
    .MSG_RX_FSX                     ( FPGA_TO_SFPGA_RESERVE3            ),
    .MSG_RX                         ( FPGA_TO_SFPGA_RESERVE4            )
);


assign TIMING_SPI_MCLK_P = PMT_SPI_MCLK ;
assign TIMING_SPI_MCLK_N = ~PMT_SPI_MCLK;
assign TIMING_SPI_MOSI_P = PMT_SPI_MOSI ;
assign TIMING_SPI_MOSI_N = ~PMT_SPI_MOSI;



IBUFDS #(
    .DIFF_TERM("TRUE"),  			// Differential Termination
    .IBUF_LOW_PWR("FALSE"),  		// Low power="TRUE", Highest performance="FALSE" 
    .IOSTANDARD("DEFAULT")  		// Specify the input I/O standard
) TIMING_SPI_SCLK_inst(
    .O(PMT_SPI_SCLK),  		// Buffer output
    .I(TIMING_SPI_SCLK_P), 		// Diff_p buffer input (connect directly to top-level port)
    .IB(TIMING_SPI_SCLK_N)		// Diff_n buffer input (connect directly to top-level port)
);

IBUFDS #(
    .DIFF_TERM("TRUE"),  			// Differential Termination
    .IBUF_LOW_PWR("FALSE"),  		// Low power="TRUE", Highest performance="FALSE" 
    .IOSTANDARD("DEFAULT")  		// Specify the input I/O standard
) TIMING_SPI_MISO_inst(
    .O(PMT_SPI_MISO),  		// Buffer output
    .I(TIMING_SPI_MISO_P), 		// Diff_p buffer input (connect directly to top-level port)
    .IB(TIMING_SPI_MISO_N)		// Diff_n buffer input (connect directly to top-level port)
);

reg                 pmt_scan_en                     = 0 ;
reg     [16-1:0]    acc_demo_trim_time_pose         = 10;
reg     [16-1:0]    acc_demo_trim_time_nege         = 20;
wire                acc_demo_trim_ctrl              ;
wire                acc_demo_trim_flag              ;
wire    [32-1:0]    acc_flag_phase_cnt              ;


reg [32-1:0]    pmt_master_wr_data  = 'd0;
reg [2-1:0]     pmt_master_wr_vld   = 'd0;

reg             pmt_scan_cmd_sel    = 'd0;
reg [4-1:0]     pmt_scan_cmd        = 'd0;
serial_master_drv #(
    .DATA_WIDTH                     ( 32                            ),
    .ADDR_WIDTH                     ( 16                            ),
    .CMD_WIDTH                      ( 8                             ),
    .MASTER_SEL                     ( 0                             ),  // PMT1
    .SERIAL_MODE                    ( 1                             )
)serial_master_drv_inst(
    // clk & rst
    .clk_i                          ( clk_100m                      ),
    .rst_i                          ( rst_100m                      ),
    .clk_200m_i                     ( clk_200m                      ),
    .master_wr_data_i               ( pmt_master_wr_data            ),
    .master_wr_vld_i                ( pmt_master_wr_vld             ),
    .pmt_master_cmd_parser_o        ( pmt_master_cmd_parser         ),

    .slave_ack_vld_o                ( spi_slave_ack_vld             ),
    .slave_ack_last_o               ( spi_slave_ack_last            ),
    .slave_ack_data_o               ( spi_slave_ack_data            ),
    // spi info
    .SPI_MCLK                       ( PMT_SPI_MCLK                  ),
    .SPI_MOSI                       ( PMT_SPI_MOSI                  ),
    .SPI_SCLK                       ( PMT_SPI_SCLK                  ),
    .SPI_MISO                       ( PMT_SPI_MISO                  )
);

assign ENCODE_MCLK_P = ENCODE_SPI_MCLK;
assign ENCODE_MCLK_N = ~ENCODE_SPI_MCLK;
assign ENCODE_MOSI_P = ENCODE_SPI_MOSI;
assign ENCODE_MOSI_N = ~ENCODE_SPI_MOSI;

reg                         tx_valid                = 'd0;
reg         [16-1:0]        tx_data                 = 'd0;
localparam  [16-1:0]        SYNC_WORD_ENCODE        = 'hECDE    ;
localparam  [16-1:0]        SYNC_WORD_SCAN_BEGIN    = 'h5A51    ;
localparam  [16-1:0]        SYNC_WORD_SCAN_TEST     = 'h5A53    ;
localparam  [16-1:0]        SYNC_WORD_SCAN_END      = 'h5A50    ;

serial_tx #(
    .DATA_WIDTH                 ( 16                        ),
    .SERIAL_MODE                ( 1                         )  // =1\2\4\8
)serial_tx_inst(
    // clk & rst
    .clk_i                      ( clk_100m                  ),
    .rst_i                      ( rst_100m                  ),
    .clk_200m_i                 ( clk_200m                  ),

    .tx_valid_i                 ( tx_valid                  ),
    .tx_ready_o                 ( tx_ready                  ),
    .tx_data_i                  ( tx_data                   ),

    .TX_CLK                     ( ENCODE_SPI_MCLK           ),
    .TX_DOUT                    ( ENCODE_SPI_MOSI           )
);

reg laser_scan_start = 'd0;


initial begin
    rst_100m = 1;
    #40;
    rst_100m = 0;
end

reg signed [16-1:0] rand_data ;
always @(negedge clk_100m) begin
    rand_data <= $random % 20;
end

reg [16-1:0] src_data_mem_addr = 'd0;
reg [16-1:0] src_data_mem [0:47999];
initial begin
    $display("read csv file");
    $readmemh("D:/workspace/sim_absolute_path/sim/src_data_csv/20240531172025_sim_signal_data.csv",src_data_mem);
end

always @(negedge clk_100m) begin
    if(pmt_scan_en)
        src_data_mem_addr <= src_data_mem_addr + 1;
    else
        src_data_mem_addr <= 'd0;
end

assign AD9265_DATA = src_data_mem[src_data_mem_addr];
// assign AD9265_DATA = src_data_mem_addr;
assign AD9265_DCO = clk_100m;


assign FPGA_RESET           = 0;
assign CLK_SEL              = 0;
assign USER_SMA_CLOCK       = 0;
assign FPGA_MASTER_CLOCK_P  = clk_100m;
assign FPGA_MASTER_CLOCK_N  = ~clk_100m;
assign TIMING_SYNC_REFCLK_P = clk_100m;
assign TIMING_SYNC_REFCLK_N = ~clk_100m;

acc_ctrl_rx_drv acc_ctrl_rx_drv_inst(
    // clk & rst
    .clk_i                          ( clk_100m                      ),
    .rst_i                          ( rst_100m                      ),
    .clk_200m_i                     ( clk_200m                      ),

    .acc_aom_flag_o                 ( acc_aom_flag                  ),

    // spi info
    .SPI_SCLK                       ( ACC_SCLK_P                    ),
    .SPI_MISO                       ( ACC_MISO_P                    )
);


acc_demo_flag_trim acc_demo_flag_trim_inst(
    // clk & rst
    .clk_i                          ( clk_100m                      ),
    .rst_i                          ( rst_100m                      ),

    .pmt_scan_en_i                  ( pmt_scan_en                   ),
    .acc_flag_phase_cnt_o           ( acc_flag_phase_cnt            ),
    .acc_demo_flag_i                ( acc_aom_flag                  ),
    .acc_demo_trim_time_pose_i      ( acc_demo_trim_time_pose       ),
    .acc_demo_trim_time_nege_i      ( acc_demo_trim_time_nege       ),

    .acc_demo_trim_ctrl_o           ( acc_demo_trim_ctrl            ),
    .acc_demo_trim_flag_o           ( acc_demo_trim_flag            )
);

initial begin
    pmt_scan_en = 0;
    wait(ddr3_init_done);
    #1000;

    // wr h0100
    #10;
    pmt_master_wr_vld   = 3;
    pmt_master_wr_data  = {16'h0100,8'h01,8'h0};
    #10;
    pmt_master_wr_vld   = 2;
    pmt_master_wr_data  = 1;
    #10;
    pmt_master_wr_vld   = 0;
    #2500;

    // wr h010c
    #10;
    pmt_master_wr_vld   = 3;
    pmt_master_wr_data  = {16'h010c,8'h01,8'h0};
    #10;
    pmt_master_wr_vld   = 2;
    pmt_master_wr_data  = 1;
    #10;
    pmt_master_wr_vld   = 0;
    #5000;

    // Sacn start
    pmt_scan_en = 1;
    tx_valid    = 1;
    tx_data     = SYNC_WORD_SCAN_BEGIN;
    #10;
    tx_valid    = 0;

    #80000;    // track flag
    tx_valid    = 1;
    tx_data     = SYNC_WORD_ENCODE;
    #10;
    tx_valid    = 0;

    #79900;    // track flag
    tx_valid    = 1;
    tx_data     = SYNC_WORD_ENCODE;
    #10;
    tx_valid    = 0;

    #79800;    // track flag
    tx_valid    = 1;
    tx_data     = SYNC_WORD_ENCODE;
    #10;
    tx_valid    = 0;
    
    #79700;    // track flag
    tx_valid    = 1;
    tx_data     = SYNC_WORD_ENCODE;
    #10;
    tx_valid    = 0;
    #20000;

    $finish;
end

endmodule