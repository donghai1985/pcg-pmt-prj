`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: zas
// Engineer: songyuxin
// 
// Create Date: 2024/3/11
// Design Name: PCG
// Module Name: acc_ctrl_rx_drv
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
//
//
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module acc_ctrl_rx_drv #(
    parameter                               TCQ             = 0.1   ,
    parameter                               DATA_WIDTH      = 16    ,
    parameter                               SERIAL_MODE     = 1     
)(
    // clk & rst
    input   wire                            clk_i                   ,
    input   wire                            rst_i                   ,
    input   wire                            clk_200m_i              ,

    // input   wire    [12-1:0]                acc_aom_class0_i        ,
    // input   wire    [12-1:0]                acc_aom_class1_i        ,
    // input   wire    [12-1:0]                acc_aom_class2_i        ,
    // input   wire    [12-1:0]                acc_aom_class3_i        ,
    // input   wire    [12-1:0]                acc_aom_class4_i        ,
    // input   wire    [12-1:0]                acc_aom_class5_i        ,
    // input   wire    [12-1:0]                acc_aom_class6_i        ,
    // input   wire    [12-1:0]                acc_aom_class7_i        ,
    // output  wire                            acc_aom_flag_o          ,
    // output  wire    [12-1:0]                acc_aom_class_o         ,

    output  wire                            acc_aom_flag_o          ,

    // spi info
    input   wire                            SPI_SCLK                ,
    input   wire    [SERIAL_MODE-1:0]       SPI_MISO                
);


//////////////////////////////////////////////////////////////////////////////////
// *********** Define Parameter Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
localparam  [DATA_WIDTH-1:0]        ACC_NORMAL_CLASS0   = 'h5A50    ;
localparam  [DATA_WIDTH-1:0]        ACC_NORMAL_CLASS1   = 'h5A51    ;
localparam  [DATA_WIDTH-1:0]        ACC_NORMAL_CLASS2   = 'h5A52    ;
localparam  [DATA_WIDTH-1:0]        ACC_NORMAL_CLASS3   = 'h5A53    ;
localparam  [DATA_WIDTH-1:0]        ACC_NORMAL_CLASS4   = 'h5A54    ;
localparam  [DATA_WIDTH-1:0]        ACC_NORMAL_CLASS5   = 'h5A55    ;
localparam  [DATA_WIDTH-1:0]        ACC_NORMAL_CLASS6   = 'h5A56    ;
localparam  [DATA_WIDTH-1:0]        ACC_NORMAL_CLASS7   = 'h5A57    ;

// localparam  [12-1:0]                ACC_AOM_CLASS0      = 'd0       ;  // 0    / 5 * 2**12 = 0
// localparam  [12-1:0]                ACC_AOM_CLASS1      = 'd819     ;  // 1    / 5 * 2**12 = 819
// localparam  [12-1:0]                ACC_AOM_CLASS2      = 'd1228    ;  // 1.5  / 5 * 2**12 = 1228
// localparam  [12-1:0]                ACC_AOM_CLASS3      = 'd1638    ;  // 2    / 5 * 2**12 = 1638
// localparam  [12-1:0]                ACC_AOM_CLASS4      = 'd2457    ;  // 3    / 5 * 2**12 = 2457
// localparam  [12-1:0]                ACC_AOM_CLASS5      = 'd2866    ;  // 3.5  / 5 * 2**12 = 2866
// localparam  [12-1:0]                ACC_AOM_CLASS6      = 'd3276    ;  // 4    / 5 * 2**12 = 3276
// localparam  [12-1:0]                ACC_AOM_CLASS7      = 'd4095    ;  // 5    / 5 * 2**12 = 4095

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Register Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
reg                             acc_aom_flag        = 'd0;
reg     [12-1:0]                acc_aom_class       = 'd0;

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Wire Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
wire                            rx_valid            ;
wire    [DATA_WIDTH-1:0]        rx_data             ; 

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Instance Module
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
serial_rx #(
    .DATA_WIDTH                 ( DATA_WIDTH                ),
    .SERIAL_MODE                ( SERIAL_MODE               )  // =1\2\4\8
)serial_rx_inst(
    // clk & rst
    .clk_i                      ( clk_i                     ),
    .rst_i                      ( rst_i                     ),
    .clk_200m_i                 ( clk_200m_i                ),
    .rx_valid_o                 ( rx_valid                  ),
    .rx_data_o                  ( rx_data                   ),

    .RX_CLK                     ( SPI_SCLK                  ),
    .RX_DIN                     ( SPI_MISO                  )
);
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Logic Design
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
// always @(posedge clk_i)begin
//     if(rst_i)begin
//         acc_aom_flag    <= #TCQ 'd0;
//         acc_aom_class   <= #TCQ 'd0;
//     end
//     else if(rx_valid)begin
//         case (rx_data)
//             ACC_NORMAL_CLASS0:  begin 
//                                     acc_aom_flag    <= #TCQ 'd1; 
//                                     acc_aom_class   <= #TCQ acc_aom_class0_i; 
//                                 end
//             ACC_NORMAL_CLASS1:  begin 
//                                     acc_aom_flag    <= #TCQ 'd1; 
//                                     acc_aom_class   <= #TCQ acc_aom_class1_i; 
//                                 end
//             ACC_NORMAL_CLASS2:  begin 
//                                     acc_aom_flag    <= #TCQ 'd1; 
//                                     acc_aom_class   <= #TCQ acc_aom_class2_i; 
//                                 end
//             ACC_NORMAL_CLASS3:  begin 
//                                     acc_aom_flag    <= #TCQ 'd1; 
//                                     acc_aom_class   <= #TCQ acc_aom_class3_i; 
//                                 end
//             ACC_NORMAL_CLASS4:  begin 
//                                     acc_aom_flag    <= #TCQ 'd1; 
//                                     acc_aom_class   <= #TCQ acc_aom_class4_i; 
//                                 end
//             ACC_NORMAL_CLASS5:  begin 
//                                     acc_aom_flag    <= #TCQ 'd1; 
//                                     acc_aom_class   <= #TCQ acc_aom_class5_i; 
//                                 end
//             ACC_NORMAL_CLASS6:  begin 
//                                     acc_aom_flag    <= #TCQ 'd1; 
//                                     acc_aom_class   <= #TCQ acc_aom_class6_i; 
//                                 end
//             ACC_NORMAL_CLASS7:  begin 
//                                     acc_aom_flag    <= #TCQ 'd1; 
//                                     acc_aom_class   <= #TCQ acc_aom_class7_i; 
//                                 end
//             default: acc_aom_flag <= #TCQ 'd0;
//         endcase
//     end
//     else begin
//         acc_aom_flag    <= #TCQ 'd0;
//     end
// end


// assign acc_aom_flag_o    = acc_aom_flag; 
// assign acc_aom_class_o   = acc_aom_class;


always @(posedge clk_i) begin
    if(rx_valid && rx_data==ACC_NORMAL_CLASS1)
        acc_aom_flag <= #TCQ 'd1;
    else if(rx_valid && rx_data==ACC_NORMAL_CLASS0)
        acc_aom_flag <= #TCQ 'd0;
end

assign acc_aom_flag_o = acc_aom_flag;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


endmodule
