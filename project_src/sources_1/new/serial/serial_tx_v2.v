`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: zas
// Engineer: songyuxin
// 
// Create Date: 2023/12/05
// Design Name: PCG
// Module Name: serial_tx_v2
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


module serial_tx_v2 #(
    parameter                               TCQ         = 0.1   ,
    parameter                               DATA_WIDTH  = 32    ,
    parameter                               SERIAL_MODE = 2     , // =1\2\4\8
    parameter                               CMD_NUM_WID = 6
)(
    // clk & rst
    input   wire                            clk_i               ,
    input   wire                            rst_i               ,
    input   wire                            clk_200m_i          ,

    input   wire                            tx_data_num_en_i    ,
    input   wire    [CMD_NUM_WID-1:0]       tx_data_num_i       ,
    input   wire                            tx_valid_i          ,
    input   wire    [DATA_WIDTH-1:0]        tx_data_i           ,
    output  wire                            tx_ack_o            ,

    // spi info
    // output  wire                            TX_ENABLE           ,  // active low
    output  wire                            TX_CLK              ,
    output  wire    [SERIAL_MODE-1:0]       TX_DOUT              
);


//////////////////////////////////////////////////////////////////////////////////
// *********** Define Parameter Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
localparam          ST_IDLE             = 3'd0;
localparam          ST_WAIT             = 3'd1;
localparam          ST_TX               = 3'd2;
localparam          ST_CRC              = 3'd3;
localparam          ST_FINISH           = 3'd4;

localparam          SERIAL_NUM          = DATA_WIDTH/SERIAL_MODE;
localparam          SERIAL_CNT_WIDTH    = $clog2(SERIAL_NUM);
localparam          CRC_CNT_NUM         = DATA_WIDTH/8;
localparam          CRC_CNT_WIDTH       = $clog2(CRC_CNT_NUM);

localparam          CLK_REF_NUM         = 2;  // 200M --> 50M
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Register Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
reg     [ 3-1:0]                        state           = ST_IDLE;
reg     [ 3-1:0]                        state_next      = ST_IDLE;
reg     [16-1:0]                        err_timeout_cnt = 'd0;

reg     [32-1:0]                        crc_new_data    = 'hffff_ffff;
reg                                     crc_vld         = 'd0;
reg     [CRC_CNT_WIDTH-1:0]             crc_cnt         = 'd0;

reg     [CMD_NUM_WID-1:0]               tx_data_num     = 'd0;
reg                                     tx_rd_ready     = 'd0;
reg                                     comm_tx_done    = 'd0;
reg                                     data_rd_last    = 'd0;
reg                                     data_rd_last_d  = 'd0;
reg                                     tx_data_en      = 'd0;

reg     [2:0]                           clock_cnt       = 'd0;
reg                                     clock_r         = 'd0;
reg                                     clock_r_d       = 'd0;
reg     [SERIAL_CNT_WIDTH-1:0]          serial_cnt      = 'd0;
reg                                     clock_pose_d    = 'd0;
reg                                     clock_nege_d    = 'd0;

reg                                     fifo_dout_vld   = 'd0;
reg     [DATA_WIDTH-1:0]                tx_data_temp    = 'd0;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<



//////////////////////////////////////////////////////////////////////////////////
// *********** Define Wire Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
wire                                    tx_data_num_en_sync ;
wire    [CMD_NUM_WID-1:0]               tx_data_num_sync    ;

wire                                    clock_pose          ;
wire                                    clock_nege          ;

wire                                    crc_rst             ;
wire    [8-1:0]                         crc_data            ;
wire                                    crc_out_vaild       ;
wire    [32-1:0]                        crc_out             ;
wire                                    tx_done             ;

wire                                    tx_rd_en            ;
wire    [DATA_WIDTH-1:0]                tx_fifo_dout        ;
wire                                    tx_fifo_full        ;
wire                                    tx_fifo_empty       ;
wire                                    tx_ack              ;
wire                                    tx_ack_sync         ;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<





//////////////////////////////////////////////////////////////////////////////////
// *********** Instance Module
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
xpm_cdc_pulse #(
   .DEST_SYNC_FF(2),   // DECIMAL; range: 2-10
   .INIT_SYNC_FF(0),   // DECIMAL; 0=disable simulation init values, 1=enable simulation init values
   .REG_OUTPUT(1),     // DECIMAL; 0=disable registered output, 1=enable registered output
   .RST_USED(0),       // DECIMAL; 0=no reset, 1=implement reset
   .SIM_ASSERT_CHK(0)  // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
)
xpm_cdc_pulse_inst (
   .dest_pulse(tx_ack_sync), // 1-bit output: Outputs a pulse the size of one dest_clk period when a pulse
                            // transfer is correctly initiated on src_pulse input. This output is
                            // combinatorial unless REG_OUTPUT is set to 1.

   .dest_clk(clk_i),     // 1-bit input: Destination clock.
   .dest_rst('d0),     // 1-bit input: optional; required when RST_USED = 1
   .src_clk(clk_200m_i),       // 1-bit input: Source clock.
   .src_pulse(tx_ack),   // 1-bit input: Rising edge of this signal initiates a pulse transfer to the
                            // destination clock domain. The minimum gap between each pulse transfer must be
                            // at the minimum 2*(larger(src_clk period, dest_clk period)). This is measured
                            // between the falling edge of a src_pulse to the rising edge of the next
                            // src_pulse. This minimum gap will guarantee that each rising edge of src_pulse
                            // will generate a pulse the size of one dest_clk period in the destination
                            // clock domain. When RST_USED = 1, pulse transfers will not be guaranteed while
                            // src_rst and/or dest_rst are asserted.

   .src_rst('d0)        // 1-bit input: optional; required when RST_USED = 1
);

master_wr_fifo master_wr_fifo_inst (
    .rst                    ( rst_i                         ),  // input wire rst
    .wr_clk                 ( clk_i                         ),  // input wire wr_clk
    .rd_clk                 ( clk_200m_i                    ),  // input wire rd_clk
    .din                    ( tx_data_i                     ),  // input wire [31 : 0] din
    .wr_en                  ( tx_valid_i                    ),  // input wire wr_en
    .rd_en                  ( tx_rd_en                      ),  // input wire rd_en
    .dout                   ( tx_fifo_dout                  ),  // output wire [31 : 0] dout
    .full                   ( tx_fifo_full                  ),  // output wire full
    .empty                  ( tx_fifo_empty                 )   // output wire empty
);

handshake #(
    .DATA_WIDTH             ( CMD_NUM_WID                   )
)handshake_inst(
    // clk & rst
    .src_clk_i              ( clk_i                         ),
    .src_rst_i              ( rst_i                         ),
    .dest_clk_i             ( clk_200m_i                    ),
    .dest_rst_i             ( 'd0                           ),
    
    .src_data_i             ( tx_data_num_i                 ),
    .src_vld_i              ( tx_data_num_en_i              ),

    .dest_data_o            ( tx_data_num_sync              ),
    .dest_vld_o             ( tx_data_num_en_sync           )
);

CRC32_D8 CRC32_D8_inst(
    .clk_i                  ( clk_200m_i                    ),
    .rst_i                  ( crc_rst                       ),
    .data_in_vaild          ( crc_vld                       ),  // 输入数据有效 
    .data_in                ( crc_data                      ),  // 输入数据
    .CRC_out_vaild          ( crc_out_vaild                 ),  // delay 1clk for data_in_vaild
    .CRC_out                ( crc_out                       )
);
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


//////////////////////////////////////////////////////////////////////////////////
// *********** Logic Design
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
always @(posedge clk_200m_i) begin
    if(state != ST_IDLE)begin
        if(clock_cnt == CLK_REF_NUM-1)begin
            clock_cnt   <= #TCQ 'd0;
            clock_r     <= #TCQ ~clock_r;
        end
        else begin
            clock_cnt   <= #TCQ clock_cnt + 1;
            clock_r     <= #TCQ clock_r;
        end
    end
    else begin
        clock_cnt   <= #TCQ 'd0;
        clock_r     <= #TCQ 'd0;
    end
end
always @(posedge clk_200m_i) clock_r_d <= #TCQ clock_r;

assign clock_nege   = clock_r_d  && ~clock_r;
assign clock_pose   = ~clock_r_d && clock_r;

always @(posedge clk_200m_i) clock_pose_d <= #TCQ clock_pose;
always @(posedge clk_200m_i) clock_nege_d <= #TCQ clock_nege;

always @(posedge clk_200m_i) begin
    if(rst_i)
        state <= #TCQ ST_IDLE;
    else 
        state <= #TCQ state_next;
end

always @(*) begin
    state_next = state;
    case(state)
        ST_IDLE : 
            if(tx_data_num_en_sync)
                state_next = ST_WAIT;
        ST_WAIT : 
            if(clock_pose)
                state_next = ST_TX;
        ST_TX :
            if(data_rd_last)
                state_next = ST_CRC;
        ST_CRC : 
            if(comm_tx_done)
                state_next = ST_FINISH;
        ST_FINISH :
                state_next = ST_IDLE;
        default:
                state_next = ST_IDLE;
    endcase
end

always @(posedge clk_200m_i) data_rd_last    <= #TCQ (state==ST_TX) && tx_done && (tx_data_num=='d0);
always @(posedge clk_200m_i) data_rd_last_d  <= #TCQ data_rd_last;
always @(posedge clk_200m_i) comm_tx_done    <= #TCQ (state==ST_CRC) && tx_done;

always @(posedge clk_200m_i) begin
    if(fifo_dout_vld || data_rd_last_d)
        tx_data_en <= #TCQ 'd1;
    else if(tx_done)
        tx_data_en <= #TCQ 'd0;
end

always @(posedge clk_200m_i) begin
    if(tx_data_en)begin
        if(clock_pose_d)
            serial_cnt <= #TCQ serial_cnt + 1;
    end
    else 
        serial_cnt <= #TCQ 'd0;
end

always @(posedge clk_200m_i) begin
    if(state_next == ST_IDLE)
        tx_rd_ready <= #TCQ 'd1;
    else begin
        if(tx_rd_en)
            tx_rd_ready <= #TCQ 'd0;
        else if(tx_done)
            tx_rd_ready <= #TCQ 'd1;
    end
end

assign tx_done  = tx_data_en && (&serial_cnt) && clock_nege_d;
assign tx_rd_en = ((state_next==ST_TX) && tx_rd_ready && (~data_rd_last)) || (err_timeout_cnt[7]);  // error clear
assign tx_ack   = state==ST_FINISH;

always @(posedge clk_200m_i) begin
    if(state==ST_IDLE && tx_data_num_en_sync) 
        tx_data_num <= #TCQ tx_data_num_sync;
    else if(state==ST_TX && tx_done)
        tx_data_num <= #TCQ tx_data_num - 1;
end

always @(posedge clk_200m_i) begin
    fifo_dout_vld <= #TCQ tx_rd_en;
end

assign crc_rst = state == ST_IDLE;

always @(posedge clk_200m_i) begin
    if(fifo_dout_vld)
        crc_cnt <= #TCQ 'd0;
    else if(crc_cnt == CRC_CNT_NUM-1)
        crc_cnt <= #TCQ crc_cnt;
    else 
        crc_cnt <= #TCQ crc_cnt + 1;
end

always @(posedge clk_200m_i) begin
    if(fifo_dout_vld)
        crc_vld <= #TCQ 'd1;
    else if(crc_cnt == CRC_CNT_NUM-1)
        crc_vld <= #TCQ 'd0;
end

always @(posedge clk_200m_i) begin
    if(fifo_dout_vld)
        crc_new_data <= #TCQ tx_fifo_dout;
    else if(crc_vld)
        crc_new_data <= #TCQ {crc_new_data[DATA_WIDTH-8-1:0],8'd0};
end

assign crc_data = crc_new_data[DATA_WIDTH-1:(DATA_WIDTH-8)];


always @(posedge clk_200m_i) begin
    if(fifo_dout_vld)begin
        tx_data_temp <= #TCQ tx_fifo_dout;
    end
    else if(data_rd_last)begin
        tx_data_temp <= #TCQ crc_out;
    end
end

// check fifo empty error
always @(posedge clk_200m_i) begin
    if(~tx_fifo_empty && (state == ST_IDLE))begin
        if(~err_timeout_cnt[7])
            err_timeout_cnt <= #TCQ err_timeout_cnt + 1;
    end
    else 
        err_timeout_cnt <= #TCQ 'd0;
end

assign tx_ack_o   = tx_ack_sync;
// assign TX_ENABLE  = ~tx_data_en;
assign TX_CLK     = clock_r;
assign TX_DOUT    = tx_data_temp[(SERIAL_NUM - 1 - serial_cnt)*SERIAL_MODE +: SERIAL_MODE];  // 大端对齐 
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


endmodule
