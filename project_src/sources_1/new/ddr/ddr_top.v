`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/06/20
// Design Name: songyuxin
// Module Name: ddr_top
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


module ddr_top (
    // clk & rst
    input                           clk_i                   , // sys clk
    input                           rst_i                   ,
    input                           clk_250m_i              , // ddr System clk input
    input                           clk_200m_i              , // ddr Reference clk input
    // input                           laser_rst_i             , // ddr init_calib_compiete and aurora_channel_up_done

    // laser write control
    input                           filter_acc_flag_i       ,
    input                           pre_track_mema_start_i  ,
    input                           pre_track_mema_vld_i    ,
    input      [32-1:0]             pre_track_mema_data_i   ,
    input                           pre_track_memb_start_i  ,
    input                           pre_track_memb_vld_i    ,
    input      [32-1:0]             pre_track_memb_data_i   ,

    // laser read control
    input                           pre_track_mema_rd_start_i   ,
    input                           pre_track_memb_rd_start_i   ,
    output                          pre_track_mema_ready_o      ,
    input                           pre_track_mema_rd_seq_i     ,
    output                          pre_track_mema_rd_vld_o     ,
    output      [64-1:0]            pre_track_mema_rd_data_o    ,
    output                          pre_track_memb_ready_o      ,
    input                           pre_track_memb_rd_seq_i     ,
    output                          pre_track_memb_rd_vld_o     ,
    output      [64-1:0]            pre_track_memb_rd_data_o    ,

    // fir tap control
    input                           laser_start_i           ,
    input                           track_para_en_i         ,
    input                           fir_tap_wr_cmd_i        ,
    input                           fir_tap_wr_vld_i        ,
    input       [32-1:0]            fir_tap_wr_data_i       ,
    input                           encode_zero_flag_i      ,
    input                           track_para_rd_en_i      ,
    output                          track_para_burst_end_o  ,
    output                          track_para_ready_o      ,
    output                          track_para_rd_vld_o     ,
    output      [32-1:0]            track_para_rd_data_o    ,
    output      [16-1:0]            fir_tap_burst_line_o    ,

    // acc dump
    input                           acc_trigger_latch_en_i  ,
    input       [256-1:0]           acc_trigger_latch_i     ,

    // readback ddr
    input       [32-1:0]            ddr_rd_addr_i           ,
    input                           ddr_rd_en_i             ,
    output                          readback_vld_o          ,
    output                          readback_last_o         ,
    output      [32-1:0]            readback_data_o         ,

    // ddr complete reset
    output                          init_calib_complete_o   ,
    // ddr interface
    inout       [31:0]              ddr3_dq                 ,
    inout       [3:0]               ddr3_dqs_n              ,
    inout       [3:0]               ddr3_dqs_p              ,
    output      [15:0]              ddr3_addr               ,
    output      [2:0]               ddr3_ba                 ,
    output                          ddr3_ras_n              ,
    output                          ddr3_cas_n              ,
    output                          ddr3_we_n               ,
    output                          ddr3_reset_n            ,
    output                          ddr3_ck_p               ,
    output                          ddr3_ck_n               ,
    output                          ddr3_cke                ,
    output                          ddr3_cs_n               ,
    output      [3:0]               ddr3_dm                 ,
    output                          ddr3_odt                
);


//////////////////////////////////////////////////////////////////////////////////
// *********** Define Parameter Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
localparam                          ADDR_WIDTH        = 30  ;
localparam                          DATA_WIDTH        = 32  ;
localparam                          MEM_DATA_BITS     = 256 ;
localparam                          BURST_LEN         = 64  ;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Register Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>


//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Wire Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
wire                                ddr_log_rst             ;

wire                                ch0_wr_ddr_req          ;
wire    [8-1:0]                     ch0_wr_ddr_len          ;
wire    [ADDR_WIDTH-1:0]            ch0_wr_ddr_addr         ;
wire                                ch0_wr_ddr_data_req     ;
wire    [MEM_DATA_BITS - 1:0]       ch0_wr_ddr_data         ;
wire                                ch0_wr_ddr_finish       ;

wire                                ch0_rd_ddr_req          ;
wire    [8-1:0]                     ch0_rd_ddr_len          ;
wire    [ADDR_WIDTH-1:0]            ch0_rd_ddr_addr         ;
wire                                ch0_rd_ddr_data_valid   ;
wire    [MEM_DATA_BITS - 1:0]       ch0_rd_ddr_data         ;
wire                                ch0_rd_ddr_finish       ;

wire                                ch1_wr_ddr_req          ;
wire    [8-1:0]                     ch1_wr_ddr_len          ;
wire    [ADDR_WIDTH-1:0]            ch1_wr_ddr_addr         ;
wire                                ch1_wr_ddr_data_req     ;
wire    [MEM_DATA_BITS - 1:0]       ch1_wr_ddr_data         ;
wire                                ch1_wr_ddr_finish       ;

wire                                ch1_rd_ddr_req          ;
wire    [8-1:0]                     ch1_rd_ddr_len          ;
wire    [ADDR_WIDTH-1:0]            ch1_rd_ddr_addr         ;
wire                                ch1_rd_ddr_data_valid   ;
wire    [MEM_DATA_BITS - 1:0]       ch1_rd_ddr_data         ;
wire                                ch1_rd_ddr_finish       ;

wire                                ch2_wr_ddr_req          ;
wire    [8-1:0]                     ch2_wr_ddr_len          ;
wire    [ADDR_WIDTH-1:0]            ch2_wr_ddr_addr         ;
wire                                ch2_wr_ddr_data_req     ;
wire    [MEM_DATA_BITS - 1:0]       ch2_wr_ddr_data         ;
wire                                ch2_wr_ddr_finish       ;

wire                                ch2_rd_ddr_req          ;
wire    [8-1:0]                     ch2_rd_ddr_len          ;
wire    [ADDR_WIDTH-1:0]            ch2_rd_ddr_addr         ;
wire                                ch2_rd_ddr_data_valid   ;
wire    [MEM_DATA_BITS - 1:0]       ch2_rd_ddr_data         ;
wire                                ch2_rd_ddr_finish       ;

wire                                ch3_wr_ddr_req          ;
wire    [8-1:0]                     ch3_wr_ddr_len          ;
wire    [ADDR_WIDTH-1:0]            ch3_wr_ddr_addr         ;
wire                                ch3_wr_ddr_data_req     ;
wire    [MEM_DATA_BITS - 1:0]       ch3_wr_ddr_data         ;
wire                                ch3_wr_ddr_finish       ;

wire                                ch3_rd_ddr_req          ;
wire    [8-1:0]                     ch3_rd_ddr_len          ;
wire    [ADDR_WIDTH-1:0]            ch3_rd_ddr_addr         ;
wire                                ch3_rd_ddr_data_valid   ;
wire    [MEM_DATA_BITS - 1:0]       ch3_rd_ddr_data         ;
wire                                ch3_rd_ddr_finish       ;

wire    [18-1:0]                    wr_burst_line_a         ;
wire    [18-1:0]                    rd_burst_line_a         ;
wire    [18-1:0]                    wr_burst_line_b         ;
wire    [18-1:0]                    rd_burst_line_b         ;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Instance Module
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
laser_vin_buffer #(
    .MEM_SEL_BIT                    ( 0                         ),  // mem a
    .ADDR_WIDTH                     ( ADDR_WIDTH                ),
    .DATA_WIDTH                     ( DATA_WIDTH                ),
    .MEM_DATA_BITS                  ( MEM_DATA_BITS             ),
    .BURST_LEN                      ( BURST_LEN                 )
)laser_vin_buffer_a_inst(
    // clk & rst
    .sys_clk_i                      ( clk_i                     ),
    .sys_rst_i                      ( rst_i                     ),
    .ddr_clk_i                      ( ui_clk                    ),
    .ddr_rst_i                      ( ddr_log_rst               ),

    .laser_start_i                  ( pre_track_mema_start_i    ),
    .pre_track_vld_i                ( pre_track_mema_vld_i      ),
    .pre_track_data_i               ( pre_track_mema_data_i     ),
    .filter_acc_flag_i              ( filter_acc_flag_i         ),

    .wr_burst_line_o                ( wr_burst_line_a           ),
    .rd_burst_line_i                ( rd_burst_line_a           ),

    .wr_ddr_req_o                   ( ch0_wr_ddr_req            ),
    .wr_ddr_len_o                   ( ch0_wr_ddr_len            ),
    .wr_ddr_addr_o                  ( ch0_wr_ddr_addr           ),
    .ddr_fifo_rd_req_i              ( ch0_wr_ddr_data_req       ),
    .wr_ddr_data_o                  ( ch0_wr_ddr_data           ),
    .wr_ddr_finish_i                ( ch0_wr_ddr_finish         ) 
);

laser_vin_buffer #(
    .MEM_SEL_BIT                    ( 1                         ),  // mem b
    .ADDR_WIDTH                     ( ADDR_WIDTH                ),
    .DATA_WIDTH                     ( DATA_WIDTH                ),
    .MEM_DATA_BITS                  ( MEM_DATA_BITS             ),
    .BURST_LEN                      ( BURST_LEN                 )
)laser_vin_buffer_b_inst(
    // clk & rst
    .sys_clk_i                      ( clk_i                     ),
    .sys_rst_i                      ( rst_i                     ),
    .ddr_clk_i                      ( ui_clk                    ),
    .ddr_rst_i                      ( ddr_log_rst               ),

    .laser_start_i                  ( pre_track_memb_start_i    ),
    .pre_track_vld_i                ( pre_track_memb_vld_i      ),
    .pre_track_data_i               ( pre_track_memb_data_i     ),
    .filter_acc_flag_i              ( filter_acc_flag_i         ),

    .wr_burst_line_o                ( wr_burst_line_b           ),
    .rd_burst_line_i                ( rd_burst_line_b           ),

    .wr_ddr_req_o                   ( ch3_wr_ddr_req            ),
    .wr_ddr_len_o                   ( ch3_wr_ddr_len            ),
    .wr_ddr_addr_o                  ( ch3_wr_ddr_addr           ),
    .ddr_fifo_rd_req_i              ( ch3_wr_ddr_data_req       ),
    .wr_ddr_data_o                  ( ch3_wr_ddr_data           ),
    .wr_ddr_finish_i                ( ch3_wr_ddr_finish         ) 
);


laser_vout_buffer #(
    .MEM_SEL_BIT                    ( 0                         ),  // mem a
    .ADDR_WIDTH                     ( ADDR_WIDTH                ),
    .DATA_WIDTH                     ( DATA_WIDTH                ),
    .MEM_DATA_BITS                  ( MEM_DATA_BITS             ),
    .BURST_LEN                      ( BURST_LEN                 )
)laser_vout_buffer_a_inst(
    // clk & rst 
    .sys_clk_i                      ( clk_i                     ),
    .ddr_clk_i                      ( ui_clk                    ),
    .ddr_rst_i                      ( ddr_log_rst               ),

    .laser_start_i                  ( pre_track_mema_rd_start_i ),
    .wr_burst_line_i                ( wr_burst_line_a           ),
    .rd_burst_line_o                ( rd_burst_line_a           ),
    .laser_fifo_ready_o             ( pre_track_mema_ready_o    ),
    .pre_laser_rd_seq_i             ( pre_track_mema_rd_seq_i   ),
    .pre_laser_rd_vld_o             ( pre_track_mema_rd_vld_o   ),
    .pre_laser_rd_data_o            ( pre_track_mema_rd_data_o  ),

    .rd_ddr_req_o                   ( ch0_rd_ddr_req            ),  
    .rd_ddr_len_o                   ( ch0_rd_ddr_len            ),
    .rd_ddr_addr_o                  ( ch0_rd_ddr_addr           ),
    .rd_ddr_data_valid_i            ( ch0_rd_ddr_data_valid     ),
    .rd_ddr_data_i                  ( ch0_rd_ddr_data           ),
    .rd_ddr_finish_i                ( ch0_rd_ddr_finish         ) 
    
);

laser_vout_buffer #(
    .MEM_SEL_BIT                    ( 1                         ),  // mem b
    .ADDR_WIDTH                     ( ADDR_WIDTH                ),
    .DATA_WIDTH                     ( DATA_WIDTH                ),
    .MEM_DATA_BITS                  ( MEM_DATA_BITS             ),
    .BURST_LEN                      ( BURST_LEN                 )
)laser_vout_buffer_b_inst(
    // clk & rst 
    .sys_clk_i                      ( clk_i                     ),
    .ddr_clk_i                      ( ui_clk                    ),
    .ddr_rst_i                      ( ddr_log_rst               ),

    .laser_start_i                  ( pre_track_memb_rd_start_i ),
    .wr_burst_line_i                ( wr_burst_line_b           ),
    .rd_burst_line_o                ( rd_burst_line_b           ),
    .laser_fifo_ready_o             ( pre_track_memb_ready_o    ),
    .pre_laser_rd_seq_i             ( pre_track_memb_rd_seq_i   ),
    .pre_laser_rd_vld_o             ( pre_track_memb_rd_vld_o   ),
    .pre_laser_rd_data_o            ( pre_track_memb_rd_data_o  ),

    .rd_ddr_req_o                   ( ch3_rd_ddr_req            ),  
    .rd_ddr_len_o                   ( ch3_rd_ddr_len            ),
    .rd_ddr_addr_o                  ( ch3_rd_ddr_addr           ),
    .rd_ddr_data_valid_i            ( ch3_rd_ddr_data_valid     ),
    .rd_ddr_data_i                  ( ch3_rd_ddr_data           ),
    .rd_ddr_finish_i                ( ch3_rd_ddr_finish         ) 
    
);

fir_tap_vin_buffer #(
    .ADDR_WIDTH                     ( ADDR_WIDTH                ),
    .DATA_WIDTH                     ( DATA_WIDTH                ),
    .MEM_DATA_BITS                  ( MEM_DATA_BITS             ),
    .BURST_LEN                      ( 16                        )   // 16*256 = 128*32
)fir_tap_vin_buffer_inst(
    // clk & rst
    .sys_clk_i                      ( clk_i                     ),
    .sys_rst_i                      ( rst_i                     ),
    .ddr_clk_i                      ( ui_clk                    ),
    .ddr_rst_i                      ( ddr_log_rst               ),

    .fir_tap_wr_cmd_i               ( fir_tap_wr_cmd_i          ),
    .fir_tap_wr_vld_i               ( fir_tap_wr_vld_i          ),
    .fir_tap_wr_data_i              ( fir_tap_wr_data_i         ),

    .wr_ddr_req_o                   ( ch1_wr_ddr_req            ),
    .wr_ddr_len_o                   ( ch1_wr_ddr_len            ),
    .wr_ddr_addr_o                  ( ch1_wr_ddr_addr           ),
    .ddr_fifo_rd_req_i              ( ch1_wr_ddr_data_req       ),
    .wr_ddr_data_o                  ( ch1_wr_ddr_data           ),
    .wr_ddr_finish_i                ( ch1_wr_ddr_finish         ) 
);

fir_tap_vout_buffer #(
    .ADDR_WIDTH                     ( ADDR_WIDTH                ),
    .DATA_WIDTH                     ( DATA_WIDTH                ),
    .MEM_DATA_BITS                  ( MEM_DATA_BITS             ),
    .BURST_LEN                      ( 16                        )   // 16*256 = 128*32
)fir_tap_vout_buffer_inst(
    // clk & rst 
    .ddr_clk_i                      ( ui_clk                    ),
    .ddr_rst_i                      ( ddr_log_rst               ),
    .sys_clk_i                      ( clk_i                     ),

    .track_para_en_i                ( track_para_en_i           ),
    .laser_start_i                  ( laser_start_i             ),
    .encode_zero_flag_i             ( encode_zero_flag_i        ),
    .fir_tap_rd_en_i                ( track_para_rd_en_i        ),
    .track_burst_end_o              ( track_para_burst_end_o    ),
    .fir_tap_ready_o                ( track_para_ready_o        ),
    .fir_tap_rd_vld_o               ( track_para_rd_vld_o       ),
    .fir_tap_rd_data_o              ( track_para_rd_data_o      ),
    .fir_tap_burst_line_o           ( fir_tap_burst_line_o      ),

    .rd_ddr_req_o                   ( ch1_rd_ddr_req            ),  
    .rd_ddr_len_o                   ( ch1_rd_ddr_len            ),
    .rd_ddr_addr_o                  ( ch1_rd_ddr_addr           ),
    .rd_ddr_data_valid_i            ( ch1_rd_ddr_data_valid     ),
    .rd_ddr_data_i                  ( ch1_rd_ddr_data           ),
    .rd_ddr_finish_i                ( ch1_rd_ddr_finish         ) 
);

acc_dump_vin_ctrl #(
    .ADDR_WIDTH                     ( ADDR_WIDTH                ),
    .DATA_WIDTH                     ( DATA_WIDTH                ),
    .MEM_DATA_BITS                  ( MEM_DATA_BITS             ),
    .BURST_LEN                      ( 32                        )    // 256*32/8=1024
)acc_dump_vin_ctrl_inst(
    // clk & rst
    .clk_i                          ( clk_i                     ),
    .rst_i                          ( rst_i                     ),
    .ddr_clk_i                      ( ui_clk                    ),
    .ddr_rst_i                      ( ddr_log_rst               ),

    .pmt_scan_en_i                  ( laser_start_i             ),
    .acc_trigger_latch_en_i         ( acc_trigger_latch_en_i    ),
    .acc_trigger_latch_i            ( acc_trigger_latch_i       ),

    .wr_ddr_req_o                   ( ch2_wr_ddr_req            ),
    .wr_ddr_len_o                   ( ch2_wr_ddr_len            ),
    .wr_ddr_addr_o                  ( ch2_wr_ddr_addr           ),
    .ddr_fifo_rd_req_i              ( ch2_wr_ddr_data_req       ),
    .wr_ddr_data_o                  ( ch2_wr_ddr_data           ),
    .wr_ddr_finish_i                ( ch2_wr_ddr_finish         ) 
);

readback_vout_buffer #(
    .ADDR_WIDTH                     ( ADDR_WIDTH                ),
    .DATA_WIDTH                     ( DATA_WIDTH                ),
    .MEM_DATA_BITS                  ( MEM_DATA_BITS             ),
    .BURST_LEN                      ( 32                        )
)readback_vout_buffer_inst(
    // clk & rst 
    .ddr_clk_i                      ( ui_clk                    ),
    .ddr_rst_i                      ( ddr_log_rst               ),
    .sys_clk_i                      ( clk_i                     ),

    // readback ddr
    .ddr_rd_addr_i                  ( ddr_rd_addr_i             ),
    .ddr_rd_en_i                    ( ddr_rd_en_i               ),
    .readback_vld_o                 ( readback_vld_o            ),
    .readback_last_o                ( readback_last_o           ),
    .readback_data_o                ( readback_data_o           ),

    .rd_ddr_req_o                   ( ch2_rd_ddr_req            ),  
    .rd_ddr_len_o                   ( ch2_rd_ddr_len            ),
    .rd_ddr_addr_o                  ( ch2_rd_ddr_addr           ),
    .rd_ddr_data_valid_i            ( ch2_rd_ddr_data_valid     ),
    .rd_ddr_data_i                  ( ch2_rd_ddr_data           ),
    .rd_ddr_finish_i                ( ch2_rd_ddr_finish         ) 
);

mem_ctrl#(
    .MEM_DATA_BITS                  ( MEM_DATA_BITS             ),
    .ADDR_WIDTH                     ( ADDR_WIDTH                )
)mem_ctrl_inst(
    // clk & rst
    .clk_i                          ( clk_i                     ), // sys clk
    .rst_i                          ( rst_i                     ),
    .clk_250m_i                     ( clk_250m_i                ), // ddr System clk input
    .clk_200m_i                     ( clk_200m_i                ), // ddr Reference clk input
    .ui_clk                         ( ui_clk                    ), // ddr PHY to memory controller clk.    312.5/4MHz
    // .laser_rst_i                    ( laser_rst_i               ),
    .ddr_log_rst_o                  ( ddr_log_rst               ),

    // write channel interface 
    .ch0_wr_ddr_req                 ( ch0_wr_ddr_req            ),
    .ch0_wr_ddr_len                 ( ch0_wr_ddr_len            ),
    .ch0_wr_ddr_addr                ( ch0_wr_ddr_addr           ),
    .ch0_wr_ddr_data_req            ( ch0_wr_ddr_data_req       ), 
    .ch0_wr_ddr_data                ( ch0_wr_ddr_data           ),
    .ch0_wr_ddr_finish              ( ch0_wr_ddr_finish         ),
    
    // read channel interface 
    .ch0_rd_ddr_req                 ( ch0_rd_ddr_req            ),
    .ch0_rd_ddr_len                 ( ch0_rd_ddr_len            ),
    .ch0_rd_ddr_addr                ( ch0_rd_ddr_addr           ),
    .ch0_rd_ddr_data_valid          ( ch0_rd_ddr_data_valid     ),
    .ch0_rd_ddr_data                ( ch0_rd_ddr_data           ),
    .ch0_rd_ddr_finish              ( ch0_rd_ddr_finish         ),
    
    // write channel interface 
    .ch1_wr_ddr_req                 ( ch1_wr_ddr_req            ),
    .ch1_wr_ddr_len                 ( ch1_wr_ddr_len            ),
    .ch1_wr_ddr_addr                ( ch1_wr_ddr_addr           ),
    .ch1_wr_ddr_data_req            ( ch1_wr_ddr_data_req       ), 
    .ch1_wr_ddr_data                ( ch1_wr_ddr_data           ),
    .ch1_wr_ddr_finish              ( ch1_wr_ddr_finish         ),

    .ch1_rd_ddr_req                 ( ch1_rd_ddr_req            ),
    .ch1_rd_ddr_len                 ( ch1_rd_ddr_len            ),
    .ch1_rd_ddr_addr                ( ch1_rd_ddr_addr           ),
    .ch1_rd_ddr_data_valid          ( ch1_rd_ddr_data_valid     ),
    .ch1_rd_ddr_data                ( ch1_rd_ddr_data           ),
    .ch1_rd_ddr_finish              ( ch1_rd_ddr_finish         ),

    // write channel interface 
    .ch2_wr_ddr_req                 ( ch2_wr_ddr_req            ),
    .ch2_wr_ddr_len                 ( ch2_wr_ddr_len            ),
    .ch2_wr_ddr_addr                ( ch2_wr_ddr_addr           ),
    .ch2_wr_ddr_data_req            ( ch2_wr_ddr_data_req       ), 
    .ch2_wr_ddr_data                ( ch2_wr_ddr_data           ),
    .ch2_wr_ddr_finish              ( ch2_wr_ddr_finish         ),
    
    .ch2_rd_ddr_req                 ( ch2_rd_ddr_req            ),
    .ch2_rd_ddr_len                 ( ch2_rd_ddr_len            ),
    .ch2_rd_ddr_addr                ( ch2_rd_ddr_addr           ),
    .ch2_rd_ddr_data_valid          ( ch2_rd_ddr_data_valid     ),
    .ch2_rd_ddr_data                ( ch2_rd_ddr_data           ),
    .ch2_rd_ddr_finish              ( ch2_rd_ddr_finish         ),
            
    // write channel interface 
    .ch3_wr_ddr_req                 ( ch3_wr_ddr_req            ),
    .ch3_wr_ddr_len                 ( ch3_wr_ddr_len            ),
    .ch3_wr_ddr_addr                ( ch3_wr_ddr_addr           ),
    .ch3_wr_ddr_data_req            ( ch3_wr_ddr_data_req       ), 
    .ch3_wr_ddr_data                ( ch3_wr_ddr_data           ),
    .ch3_wr_ddr_finish              ( ch3_wr_ddr_finish         ),

    // read channel interface 
    .ch3_rd_ddr_req                 ( ch3_rd_ddr_req            ),
    .ch3_rd_ddr_len                 ( ch3_rd_ddr_len            ),
    .ch3_rd_ddr_addr                ( ch3_rd_ddr_addr           ),
    .ch3_rd_ddr_data_valid          ( ch3_rd_ddr_data_valid     ),
    .ch3_rd_ddr_data                ( ch3_rd_ddr_data           ),
    .ch3_rd_ddr_finish              ( ch3_rd_ddr_finish         ),

    // DDR interface 
    .init_calib_complete_o          ( init_calib_complete_o     ),
    .ddr3_dq                        ( ddr3_dq                   ),
    .ddr3_dqs_n                     ( ddr3_dqs_n                ),
    .ddr3_dqs_p                     ( ddr3_dqs_p                ),
    .ddr3_addr                      ( ddr3_addr                 ),
    .ddr3_ba                        ( ddr3_ba                   ),
    .ddr3_ras_n                     ( ddr3_ras_n                ),
    .ddr3_cas_n                     ( ddr3_cas_n                ),
    .ddr3_we_n                      ( ddr3_we_n                 ),
    .ddr3_reset_n                   ( ddr3_reset_n              ),
    .ddr3_ck_p                      ( ddr3_ck_p                 ),
    .ddr3_ck_n                      ( ddr3_ck_n                 ),
    .ddr3_cke                       ( ddr3_cke                  ),
    .ddr3_cs_n                      ( ddr3_cs_n                 ),
    .ddr3_dm                        ( ddr3_dm                   ),
    .ddr3_odt                       ( ddr3_odt                  )
);

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


//////////////////////////////////////////////////////////////////////////////////
// *********** Logic Design
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>


//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


endmodule
