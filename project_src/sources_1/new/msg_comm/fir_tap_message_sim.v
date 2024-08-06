`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/01/30
// Design Name: 
// Module Name: fir_tap_message_sim
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
// `define CONFIG_FPGA_SIM

module fir_tap_message_sim #(
    parameter               TCQ             = 0.1,
    parameter               DATA_WIDTH      = 8  ,
    parameter               BYTE_NUM_WIDTH  = 16 
)(
    // clk & rst
    input    wire                         clk_i                 ,
    input    wire                         rst_i                 ,
    // ethernet interface for message data
    output   wire                         rec_pkt_done_o        ,
    output   wire                         rec_en_o              ,
    output   wire    [DATA_WIDTH-1:0]     rec_data_o            ,
    output   wire                         rec_byte_num_en_o     ,
    output   wire    [BYTE_NUM_WIDTH-1:0] rec_byte_num_o          
);


//////////////////////////////////////////////////////////////////////////////////
// *********** Define Parameter Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
localparam                  ST_IDLE         = 3'd0;
localparam                  ST_BYTE         = 3'd1;
localparam                  ST_UDP          = 3'd2;
localparam                  ST_FINISH       = 3'd3;
localparam                  ST_CFG_HEAD     = 3'd4;
localparam                  ST_CFG_LOAD     = 3'd5;
localparam                  ST_CFG_PKG_NUM  = 3'd6;
localparam                  ST_CFG_FINISH   = 3'd7;

localparam                  UDP_NUM         = 'd518;
localparam                  CFG_DATA_NUM    = 'd1024;
localparam                  CFG_PKG_NUM     = 'd14;

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Register Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

reg [ 3-1:0]                state           = ST_IDLE;
reg [ 3-1:0]                state_next      = ST_IDLE;


reg [32-1:0]                st_wait_cnt     = 'd0;
reg [32-1:0]                st_finish_wait_cnt  = 'd0;
reg [BYTE_NUM_WIDTH-1:0]    msg_data_count  = 'd0;
reg                         msg_data_en_r   = 'd0;
reg [DATA_WIDTH-1:0]        msg_data_r      = 'd0;

reg [16-1:0]                rec_cfg_pkg_num_r = 'd1;
reg [16-1:0]                cfg_data_count  = 'd0;

reg init_done = 'd0;
reg [32-1:0] fir_tap_pack = 'd0;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<



//////////////////////////////////////////////////////////////////////////////////
// *********** Define Wire Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>


//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<





//////////////////////////////////////////////////////////////////////////////////
// *********** Instance Module
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>


//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


//////////////////////////////////////////////////////////////////////////////////
// *********** Logic Design
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
always @(posedge clk_i) begin
    if(rst_i)
        st_wait_cnt <= #TCQ 'd0;
    else if(state==ST_IDLE)begin
        st_wait_cnt <= #TCQ st_wait_cnt + 1;
    end
    else begin
        st_wait_cnt <= #TCQ 'd0;
    end
end

always @(posedge clk_i) begin
    if(state==ST_FINISH)begin
        st_finish_wait_cnt <= #TCQ st_finish_wait_cnt + 1;
    end
    else begin
        st_finish_wait_cnt <= #TCQ 'd0;
    end
end

always @(posedge clk_i) begin
    if(rst_i)
        state <= #TCQ ST_IDLE;
    else 
        state <= #TCQ state_next;
end

always @(*) begin
    state_next = state;
    case(state)
    ST_IDLE:
        if(st_wait_cnt == 'd100 && fir_tap_pack <= 'd2)
        `ifdef CONFIG_FPGA_SIM
            state_next = ST_CFG_HEAD;
        `else
            state_next = ST_BYTE;
        `endif // CONFIG_FPGA_SIM
    ST_BYTE :
            state_next = ST_UDP;
    ST_UDP :
        if(msg_data_count==UDP_NUM-1)
            state_next = ST_FINISH;
    ST_FINISH :
        if(st_finish_wait_cnt=='d8400)
            state_next = ST_IDLE;
    
    ST_CFG_HEAD:
            state_next = ST_CFG_LOAD;
    ST_CFG_LOAD:
        if(cfg_data_count==CFG_DATA_NUM-1)begin
            if(rec_cfg_pkg_num_r <= CFG_PKG_NUM)
                state_next = ST_CFG_HEAD;
            else
                state_next = ST_CFG_FINISH;
        end
    // ST_CFG_PKG_NUM:
    //     if(rec_cfg_pkg_num_r==CFG_PKG_NUM)
    //         state_next = ST_CFG_FINISH ;
    //     else 
    //         state_next = ST_CFG_LOAD;
    ST_CFG_FINISH :
        if(~init_done)
            state_next = ST_IDLE;
    default:
            state_next = ST_IDLE;
    endcase
end


//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


endmodule
