///////////////////////////////////////////////////////////////////////////////
// (c) Copyright 2008 Xilinx, Inc. All rights reserved.
//
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
//
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
//
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
//
//
///////////////////////////////////////////////////////////////////////////////
//
//  AURORA_EXAMPLE
//
//  Aurora Generator
//
//
//  Description: Sample Instantiation of a 1 4-byte lane module.
//               Only tests initialization in hardware.
//
//        
`timescale 1 ns / 1 ps
(* core_generation_info = "aurora_8b10b_0,aurora_8b10b_v11_1_11,{user_interface=AXI_4_Streaming,backchannel_mode=Sidebands,c_aurora_lanes=1,c_column_used=None,c_gt_clock_1=GTPQ2,c_gt_clock_2=None,c_gt_loc_1=X,c_gt_loc_10=X,c_gt_loc_11=X,c_gt_loc_12=X,c_gt_loc_13=X,c_gt_loc_14=X,c_gt_loc_15=X,c_gt_loc_16=X,c_gt_loc_17=X,c_gt_loc_18=X,c_gt_loc_19=X,c_gt_loc_2=X,c_gt_loc_20=X,c_gt_loc_21=X,c_gt_loc_22=X,c_gt_loc_23=X,c_gt_loc_24=X,c_gt_loc_25=X,c_gt_loc_26=X,c_gt_loc_27=X,c_gt_loc_28=X,c_gt_loc_29=X,c_gt_loc_3=X,c_gt_loc_30=X,c_gt_loc_31=X,c_gt_loc_32=X,c_gt_loc_33=X,c_gt_loc_34=X,c_gt_loc_35=X,c_gt_loc_36=X,c_gt_loc_37=X,c_gt_loc_38=X,c_gt_loc_39=X,c_gt_loc_4=X,c_gt_loc_40=X,c_gt_loc_41=X,c_gt_loc_42=X,c_gt_loc_43=X,c_gt_loc_44=X,c_gt_loc_45=X,c_gt_loc_46=X,c_gt_loc_47=X,c_gt_loc_48=X,c_gt_loc_5=X,c_gt_loc_6=X,c_gt_loc_7=X,c_gt_loc_8=X,c_gt_loc_9=1,c_lane_width=4,c_line_rate=50000,c_nfc=false,c_nfc_mode=IMM,c_refclk_frequency=100000,c_simplex=false,c_simplex_mode=TX,c_stream=false,c_ufc=false,flow_mode=None,interface_mode=Framing,dataflow_config=Duplex}" *)
(* DowngradeIPIdentifiedWarnings="yes" *)
module aurora_8b10b_0_exdes #
(
    parameter   USE_CORE_TRAFFIC     = 1,
    parameter   USE_CHIPSCOPE        = 0
)(
    // User I/O
    input               RESET,
    input               INIT_CLK_P,
    input               DRP_CLK_IN,
    input               GT_RESET_IN,
    output  reg         HARD_ERR,
    output  reg         SOFT_ERR,
    output  reg         FRAME_ERR,

    output              aurora_log_clk,
    output              aurora_rxen,
    output  [31:0]      aurora_rxdata,
    	 
    output              aurora_txen,
    input   [31:0]      aurora_txdata,	
    input   [10:0]      aurora_rd_data_count,

    input               adc_start_i,
    output              adc_end_o,

    output              CHANNEL_UP_DONE,
    // Clocks
	input               GTXQ0_P,
	input               GTXQ0_N,

    // GT Serial I/O
    input               RXP,
    input               RXN,
    output              TXP,
    output              TXN
);

//**************************External Register Declarations****************************
// reg                HARD_ERR;
// reg                SOFT_ERR;
// reg                FRAME_ERR;    
reg                 LANE_UP             ;
reg                 CHANNEL_UP          ;
//********************************Wire Declarations**********************************

    // Error Detection Interface
wire                hard_err_i          ;
wire                soft_err_i          ;
wire                frame_err_i         ;
    // Status
wire                channel_up_i        ;
wire                lane_up_i           ;
    // System Interface
wire                pll_not_locked_i    ;
wire                user_clk_i          ;
wire                tx_lock_i           ;
wire                link_reset_i        ;
wire                link_reset_ila      ;
wire                tx_resetdone_i      ;
wire                rx_resetdone_i      ;
wire                init_clk_i          ;
wire    [8:0]       daddr_in_i          ;
wire                dclk_in_i           ;
wire                den_in_i            ;
wire    [15:0]      di_in_i;            
wire                drdy_out_unused_i   ;
wire    [15:0]      drpdo_out_unused_i  ;
wire                dwe_in_i            ;

wire                system_reset_i      ;

wire                lane_up_i_i         ;
wire                tx_lock_i_i         ;

    // TX AXI PDU I/F wires
wire    [31:0]      tx_data_i           ;
wire                tx_tvalid_i         ;
wire                tx_tready_i         ;
wire    [3:0]       tx_tkeep_i          ;
wire                tx_tlast_i          ;

    // RX AXI PDU I/F wires
wire    [31:0]      rx_data_i           ;
wire                rx_tvalid_i         ;
wire    [3:0]       rx_tkeep_i          ;
wire                rx_tlast_i          ;

//*********************************Main Body of Code**********************************

assign  aurora_log_clk	= user_clk_i ;
assign  CHANNEL_UP_DONE = LANE_UP;

assign  daddr_in_i      = 9'h0;
assign  den_in_i        = 1'b0;
assign  di_in_i         = 16'h0;
assign  dwe_in_i        = 1'b0;

//____________________________Register User I/O___________________________________
// Register User Outputs from core.

always @(posedge user_clk_i)begin
    HARD_ERR        <=  hard_err_i;
    SOFT_ERR        <=  soft_err_i;
    FRAME_ERR       <=  frame_err_i;
    LANE_UP         <=  lane_up_i;
    CHANNEL_UP      <=  channel_up_i;
end

//___________________________Module Instantiations_________________________________

aurora_8b10b_0_support aurora_module_i(
    // AXI TX Interface
    .s_axi_tx_tdata             ( tx_data_i                 ),
    .s_axi_tx_tkeep             ( tx_tkeep_i                ),
    .s_axi_tx_tvalid            ( tx_tvalid_i               ),
    .s_axi_tx_tlast             ( tx_tlast_i                ),
    .s_axi_tx_tready            ( tx_tready_i               ),

    // AXI RX Interface
    .m_axi_rx_tdata             ( rx_data_i                 ),
    .m_axi_rx_tkeep             ( rx_tkeep_i                ),
    .m_axi_rx_tvalid            ( rx_tvalid_i               ),
    .m_axi_rx_tlast             ( rx_tlast_i                ),
    // V5 Serial I/O
    .rxp                        ( RXP                       ),
    .rxn                        ( RXN                       ),
    .txp                        ( TXP                       ),
    .txn                        ( TXN                       ),
    // GT Reference Clock Interface

    .gt_refclk1_p               ( GTXQ0_P                   ),
    .gt_refclk1_n               ( GTXQ0_N                   ),
    // Error Detection Interface
    .hard_err                   ( hard_err_i                ),
    .soft_err                   ( soft_err_i                ),
    .frame_err                  ( frame_err_i               ),


    // Status
    .channel_up                 ( channel_up_i              ),
    .lane_up                    ( lane_up_i                 ),
    // System Interface
    .user_clk_out               ( user_clk_i                ),
    .reset                      ( RESET                     ),
    .sys_reset_out              ( system_reset_i            ),
    .power_down                 ( 1'b0                      ),
    .loopback                   ( 3'b000                    ),
    .gt_reset                   ( GT_RESET_IN               ),
    .tx_lock                    ( tx_lock_i                 ),
    .pll_not_locked_out         ( pll_not_locked_i          ),
    .tx_resetdone_out           ( tx_resetdone_i            ),
    .rx_resetdone_out           ( rx_resetdone_i            ),
    .init_clk_p                 ( INIT_CLK_P                ),
    .init_clk_out               ( init_clk_i                ),
    .drpclk_in                  ( DRP_CLK_IN                ),
    .drpaddr_in                 ( daddr_in_i                ),
    .drpen_in                   ( den_in_i                  ),
    .drpdi_in                   ( di_in_i                   ),
    .drprdy_out                 ( drdy_out_unused_i         ),
    .drpdo_out                  ( drpdo_out_unused_i        ),
    .drpwe_in                   ( dwe_in_i                  ),

    .link_reset_out             ( link_reset_i              )
);

    //Connect a frame generator to the TX User interface
aurora_8b10b_0_FRAME_GEN frame_gen_i(
    // User Interface
    .aurora_txen                ( aurora_txen               ),	
    .aurora_txdata              ( aurora_txdata             ),	
    .aurora_rd_data_count       ( aurora_rd_data_count      ),
    .adc_start                  ( adc_start_i               ),
    .aurora_adc_end             ( adc_end_o                 ),

    // System Interface
    .USER_CLK                   ( user_clk_i                ),      
    .RESET                      ( system_reset_i            ),
    .CHANNEL_UP                 ( 'd1                       ),
    .tx_tvalid                  ( tx_tvalid_i               ),
    .tx_data                    ( tx_data_i                 ),
    .tx_tkeep                   ( tx_tkeep_i                ),
    .tx_tlast                   ( tx_tlast_i                ),
    .tx_tready                  ( tx_tready_i               )
);
    //_____________________________ RX AXI SHIM _______________________________


aurora_8b10b_0_FRAME_RX frame_rx_i(
     // User Interface
    .aurora_rxen                ( aurora_rxen               ),	
    .aurora_rxdata              ( aurora_rxdata             ),	

    // System Interface
    .USER_CLK                   ( user_clk_i                ),      
    .RESET                      ( system_reset_i            ),
    .CHANNEL_UP                 ( 'd1                       ),

    .rx_tvalid                  ( rx_tvalid_i               ),
    .rx_data                    ( rx_data_i                 ),
    .rx_tkeep                   ( rx_tkeep_i                ),
    .rx_tlast                   ( rx_tlast_i                )
);



endmodule
 
