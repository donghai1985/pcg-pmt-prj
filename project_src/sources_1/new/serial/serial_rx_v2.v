`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: zas
// Engineer: songyuxin
// 
// Create Date: 2023/12/05
// Design Name: PCG
// Module Name: serial_rx_v2
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


module serial_rx_v2 #(
    parameter                               TCQ         = 0.1   ,
    parameter                               DATA_WIDTH  = 32    ,
    parameter                               SERIAL_MODE = 2       // =1\2\4\8
)(
    // clk & rst
    input   wire                            clk_i               ,
    input   wire                            rst_i               ,
    input   wire                            clk_200m_i          ,

    output  wire                            rx_valid_o          ,
    output  wire   [DATA_WIDTH-1:0]         rx_data_o           ,

    // spi info
    // input   wire                            RX_ENABLE           ,  // active low
    input   wire                            RX_CLK              ,
    input   wire   [SERIAL_MODE-1:0]        RX_DIN              
);


//////////////////////////////////////////////////////////////////////////////////
// *********** Define Parameter Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
localparam          SERIAL_NUM          = DATA_WIDTH/SERIAL_MODE;
localparam          SERIAL_CNT_WIDTH    = $clog2(SERIAL_NUM);
localparam          CRC_CNT_NUM         = DATA_WIDTH/8;
localparam          CRC_CNT_WIDTH       = $clog2(CRC_CNT_NUM);

localparam          TIMEOUT_BIT         = 3;
localparam          CLK_REF_NUM         = 3;  // 200M --> 50M

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
reg                                     rx_enable_d1        = 'd1;

reg     [8-1:0]                         timeout_cnt         = 'd0;  // max serial cycle is 128ns

reg     [6-1:0]                         mem_wr_addr         = 'd0;
reg     [6-1:0]                         mem_rd_addr         = 'd0;
reg                                     mem_rd_en           = 'd0;

reg     [6-1:0]                         rx_pack_num         = 'd0;
reg     [6-1:0]                         rx_pack_cnt         = 'd0;
reg                                     rx_pack_flag        = 'd0;

reg     [32-1:0]                        crc_new_data        = 'hffff_ffff;
reg                                     crc_vld             = 'd0;
reg     [CRC_CNT_WIDTH-1:0]             crc_cnt             = 'd0;
reg     [32-1:0]                        crc_result          = 'd0;
reg     [32-1:0]                        serial_data_temp_d  = 'd0;
reg                                     check_crc_en        = 'd0;
reg                                     check_crc_result    = 'd0;

reg     [DATA_WIDTH-1:0]                serial_data_temp    = 'd0;
reg     [SERIAL_CNT_WIDTH-1:0]          serial_cnt          = 'd0;
reg                                     serial_data_vld     = 'd0;

reg                                     mem_rd_vld          = 'd0;

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<



//////////////////////////////////////////////////////////////////////////////////
// *********** Define Wire Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
wire                                    clock_pose          ;
wire                                    clock_nege          ;

wire                                    mem_wr_en   = serial_data_vld;
wire    [32-1:0]                        mem_wr_data = serial_data_temp;
wire    [32-1:0]                        mem_dout            ;
wire                                    rx_pack_last        ;

wire                                    crc_rst             ;
wire    [8-1:0]                         crc_data            ;
wire                                    crc_out_vaild       ;
wire    [32-1:0]                        crc_out             ;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Instance Module
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
CRC32_D8 CRC32_D8_inst(
    .clk_i                      ( clk_200m_i            ),
    .rst_i                      ( crc_rst               ),
    .data_in_vaild              ( crc_vld               ),  // 输入数据有效 
    .data_in                    ( crc_data              ),  // 输入数据
    .CRC_out_vaild              ( crc_out_vaild         ),  // delay 1clk for data_in_vaild
    .CRC_out                    ( crc_out               )
);

rx_dist_mem rx_dist_mem_inst (
    .a                          ( mem_wr_addr           ),  // input wire [6 : 0] a
    .d                          ( mem_wr_data           ),  // input wire [31 : 0] d
    .dpra                       ( mem_rd_addr           ),  // input wire [6 : 0] dpra
    .clk                        ( clk_200m_i            ),  // input wire clk
    .we                         ( mem_wr_en             ),  // input wire we
    .qdpo_clk                   ( clk_i                 ),  // input wire qdpo_clk
    .qdpo                       ( mem_dout              )   // output wire [31 : 0] qdpo
);

xpm_cdc_pulse #(
    .DEST_SYNC_FF(2),   // DECIMAL; range: 2-10
    .INIT_SYNC_FF(0),   // DECIMAL; 0=disable simulation init values, 1=enable simulation init values
    .REG_OUTPUT(0),     // DECIMAL; 0=disable registered output, 1=enable registered output
    .RST_USED(0),       // DECIMAL; 0=no reset, 1=implement reset
    .SIM_ASSERT_CHK(0)  // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
 )
 xpm_cdc_pulse_inst (
    .dest_pulse(check_crc_result_sync), // 1-bit output: Outputs a pulse the size of one dest_clk period when a pulse
                             // transfer is correctly initiated on src_pulse input. This output is
                             // combinatorial unless REG_OUTPUT is set to 1.

    .dest_clk(clk_i),     // 1-bit input: Destination clock.
    .dest_rst(rst_i),     // 1-bit input: optional; required when RST_USED = 1
    .src_clk(clk_200m_i),       // 1-bit input: Source clock.
    .src_pulse(check_crc_result),   // 1-bit input: Rising edge of this signal initiates a pulse transfer to the
                             // destination clock domain. The minimum gap between each pulse transfer must be
                             // at the minimum 2*(larger(src_clk period, dest_clk period)). This is measured
                             // between the falling edge of a src_pulse to the rising edge of the next
                             // src_pulse. This minimum gap will guarantee that each rising edge of src_pulse
                             // will generate a pulse the size of one dest_clk period in the destination
                             // clock domain. When RST_USED = 1, pulse transfers will not be guaranteed while
                             // src_rst and/or dest_rst are asserted.

    .src_rst('d0)        // 1-bit input: optional; required when RST_USED = 1
 );
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


//////////////////////////////////////////////////////////////////////////////////
// *********** Logic Design
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
assign clock_nege   = clock_d1  && ~clock_d0;
assign clock_pose   = ~clock_d1 && clock_d0;

always @(posedge clk_200m_i) begin   // 100MHz
    clock_d0 <= #TCQ RX_CLK;    // 50MHz
    clock_d1 <= #TCQ clock_d0;
end

always @(posedge clk_200m_i) begin       
    rx_din_d0 <= #TCQ RX_DIN;
    rx_din_d1 <= #TCQ rx_din_d0;
end

always @(posedge clk_200m_i) begin   
    clock_pose_d0 <= #TCQ clock_pose;   
    clock_pose_d1 <= #TCQ clock_pose_d0;
end

always @(posedge clk_200m_i) begin
    if(clock_pose_d0)
        rx_enable_d1 <= #TCQ 'd1;
    else if(check_crc_result || timeout_cnt[TIMEOUT_BIT])
        rx_enable_d1 <= #TCQ 'd0;
end

// timeout check, filter jitter
always @(posedge clk_200m_i) begin
    if(rst_i)
        timeout_cnt <= #TCQ 'd0;
    else if(clock_pose)
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
    else if(clock_pose_d0 && rx_enable_d1)
        serial_data_temp <= #TCQ {serial_data_temp[DATA_WIDTH-SERIAL_MODE-1:0],rx_din_d1};  // 大端对齐
end

always @(posedge clk_200m_i) begin
    if(timeout_cnt[TIMEOUT_BIT] || rst_i)
        serial_cnt <= #TCQ 'd0;
    else if(clock_pose_d0 && rx_enable_d1)begin
        serial_cnt <= #TCQ serial_cnt + 1;
    end 
end

always @(posedge clk_200m_i) begin
    serial_data_vld <= #TCQ &serial_cnt && clock_pose_d0 && rx_enable_d1;
end

// generate mem_wr_addr
always @(posedge clk_200m_i) begin
    if(timeout_cnt[TIMEOUT_BIT] || rst_i)
        mem_wr_addr <= #TCQ 'd0;
    else if(serial_data_vld)
        mem_wr_addr <= #TCQ mem_wr_addr + 1;
end

// check command length
always @(posedge clk_200m_i) begin
    if(timeout_cnt[TIMEOUT_BIT] || rst_i)
        rx_pack_flag <= #TCQ 'd0;
    else if(~rx_pack_flag && serial_data_vld)
        rx_pack_flag <= #TCQ 'd1;
    else if(rx_pack_flag && serial_data_vld && (rx_pack_cnt==rx_pack_num))
        rx_pack_flag <= #TCQ 'd0;
end

always @(posedge clk_200m_i) begin
    if(~rx_pack_flag && serial_data_vld)begin
        if(serial_data_temp[15:12]==4'b1010)                    // 4'b1010 -> mask write/read flag, mark slave readback pack
            rx_pack_num <= #TCQ serial_data_temp[4:0] + 1;
        else if(serial_data_temp[7])
            rx_pack_num <= #TCQ 'd0;
        else
            rx_pack_num <= #TCQ serial_data_temp[4:0] + 1;
    end
end

always @(posedge clk_200m_i) begin
    if(~rx_pack_flag)
        rx_pack_cnt <= #TCQ 'd0;
    else if(serial_data_vld)
        rx_pack_cnt <= #TCQ rx_pack_cnt + 1;
end

// 
// >>>>>>>>>>>>>>>>>>>>>>>>>>>>>> check crc
// 
assign crc_rst      = timeout_cnt[TIMEOUT_BIT] || rst_i;
assign crc_data     = crc_new_data[DATA_WIDTH-1:(DATA_WIDTH-8)];
assign rx_pack_last = rx_pack_flag && serial_data_vld && (rx_pack_cnt==rx_pack_num);

always @(posedge clk_200m_i) begin
    if(serial_data_vld)
        crc_cnt <= #TCQ 'd0;
    else if(crc_cnt == CRC_CNT_NUM-1)
        crc_cnt <= #TCQ crc_cnt;
    else 
        crc_cnt <= #TCQ crc_cnt + 1;
end

always @(posedge clk_200m_i) begin
    if(serial_data_vld)
        crc_vld <= #TCQ 'd1;
    else if(crc_cnt == CRC_CNT_NUM-1)
        crc_vld <= #TCQ 'd0;
end

always @(posedge clk_200m_i) begin
    if(serial_data_vld)
        crc_new_data <= #TCQ serial_data_temp;
    else if(crc_vld)
        crc_new_data <= #TCQ {crc_new_data[DATA_WIDTH-8-1:0],8'd0};
end

always @(posedge clk_200m_i) begin
    if(rx_pack_last)
        crc_result <= #TCQ crc_out;
end

always @(posedge clk_200m_i) serial_data_temp_d <= #TCQ serial_data_temp;
always @(posedge clk_200m_i) check_crc_en       <= #TCQ rx_pack_last;
always @(posedge clk_200m_i) check_crc_result   <= #TCQ check_crc_en && (crc_result==serial_data_temp_d);

// read memory
always @(posedge clk_i) begin
    if(check_crc_result_sync)
        mem_rd_en <= #TCQ 'd1;
    else if(mem_rd_addr == rx_pack_num)
        mem_rd_en <= #TCQ 'd0;
end

always @(posedge clk_i) begin
    if(mem_rd_en)
        mem_rd_addr <= #TCQ mem_rd_addr + 1;
    else 
        mem_rd_addr <= #TCQ 'd0;
end

always @(posedge clk_i) mem_rd_vld <= #TCQ mem_rd_en;

assign rx_valid_o = mem_rd_vld;
assign rx_data_o  = mem_dout;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


endmodule
