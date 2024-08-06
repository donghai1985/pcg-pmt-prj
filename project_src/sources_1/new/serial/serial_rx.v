`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: zas
// Engineer: songyuxin
// 
// Create Date: 2023/7/06
// Design Name: PCG
// Module Name: serial_rx
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// 
//
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module serial_rx #(
    parameter                               TCQ         = 0.1   ,
    parameter                               DATA_WIDTH  = 32    ,
    parameter                               SERIAL_MODE = 2       // =1\2\4\8
)(
    // clk & rst
    input   wire                            clk_i               ,
    input   wire                            rst_i               ,
    input   wire                            clk_200m_i          ,

    // input   wire                            rx_ready_i          ,
    output  wire                            rx_valid_o          ,
    output  wire   [DATA_WIDTH-1:0]         rx_data_o           ,

    // spi info
    input   wire                            RX_CLK              ,
    input   wire   [SERIAL_MODE-1:0]        RX_DIN              
);


//////////////////////////////////////////////////////////////////////////////////
// *********** Define Parameter Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
localparam          SERIAL_NUM          = DATA_WIDTH/SERIAL_MODE;
localparam          SERIAL_CNT_WIDTH    = $clog2(SERIAL_NUM);
localparam          TIMEOUT_BIT         = 4;
localparam          CLK_REF_NUM         = 1;  // 200M --> 50M

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Register Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
reg     [SERIAL_MODE-1:0]               rx_din_d0           ;
reg     [SERIAL_MODE-1:0]               rx_din_d1           ;
reg                                     clock_d0            ;
reg                                     clock_d1            ;
reg                                     clock_pose_d0       ;
reg                                     clock_pose_d1       ;

reg     [8-1:0]                         timeout_cnt         = 'd0;  // max serial cycle is 128ns

reg     [DATA_WIDTH-1:0]                serial_data_temp    = 'd0;
reg     [DATA_WIDTH-1:0]                serial_data_r       = 'd0;
reg     [SERIAL_CNT_WIDTH-1:0]          serial_cnt          = 'd0;
reg                                     serial_data_vld     = 'd0;



//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<



//////////////////////////////////////////////////////////////////////////////////
// *********** Define Wire Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
wire                                    colck_pose      ;
wire                                    colck_nege      ;

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Instance Module
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
handshake #(
    .TCQ                        ( TCQ                   ),
    .DATA_WIDTH                 ( DATA_WIDTH            )
)handshake_inst(
    // clk & rst
    .src_clk_i                  ( clk_200m_i            ),
    .src_rst_i                  ( 0                     ),
    .dest_clk_i                 ( clk_i                 ),
    .dest_rst_i                 ( rst_i                 ),
    
    .src_data_i                 ( serial_data_temp      ),
    .src_vld_i                  ( serial_data_vld       ),

    .dest_data_o                ( rx_data_o             ),
    .dest_vld_o                 ( rx_valid_o            )
);


//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


//////////////////////////////////////////////////////////////////////////////////
// *********** Logic Design
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
assign colck_nege   = clock_d1  && ~clock_d0;
assign colck_pose   = ~clock_d1 && clock_d0;

always @(posedge clk_200m_i) begin   // 100MHz
    clock_d0 <= #TCQ RX_CLK;    // 50MHz
    clock_d1 <= #TCQ clock_d0;
end

always @(posedge clk_200m_i) begin       
    rx_din_d0 <= #TCQ RX_DIN;
    rx_din_d1 <= #TCQ rx_din_d0;
end

always @(posedge clk_200m_i) begin   
    clock_pose_d0 <= #TCQ colck_pose;   
    clock_pose_d1 <= #TCQ clock_pose_d0;
end

// timeout check, filter jitter
always @(posedge clk_200m_i) begin
    if(rst_i)
        timeout_cnt <= #TCQ 'd0;
    else if(clock_d0)
        timeout_cnt <= #TCQ 'd0;
    else begin
        if(~timeout_cnt[TIMEOUT_BIT])
            timeout_cnt <= #TCQ timeout_cnt + 1;
        else 
            timeout_cnt <= #TCQ timeout_cnt;
    end
end

always @(posedge clk_200m_i) begin
    if(timeout_cnt[TIMEOUT_BIT] || rst_i)
        serial_data_temp <= #TCQ 'd0;
    else if(clock_pose_d0)
        serial_data_temp <= #TCQ {serial_data_temp[DATA_WIDTH-SERIAL_MODE-1:0],rx_din_d1};  // 大端对齐
end

always @(posedge clk_200m_i) begin
    if(timeout_cnt[TIMEOUT_BIT] || rst_i)
        serial_cnt <= #TCQ 'd0;
    else if(clock_pose_d0)begin
        serial_cnt <= #TCQ serial_cnt + 1;
    end 
end

always @(posedge clk_200m_i) begin
    serial_data_vld <= #TCQ &serial_cnt && clock_pose_d0;
    // serial_data_r   <= #TCQ serial_data_temp;
end

// assign rx_valid_o = serial_data_vld;
// assign rx_data_o  = serial_data_temp;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


endmodule
