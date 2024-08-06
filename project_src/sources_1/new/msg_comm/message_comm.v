`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/05/18
// Design Name: 
// Module Name: message_comm
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


module message_comm(
    // clk & rst
    input    wire           phy_rx_clk          ,
    input    wire           clk                 ,
    input    wire           rst_n               ,
    // ethernet interface for message data
    input    wire           rec_pkt_done_i      ,
    input    wire           rec_en_i            ,
    input    wire    [7:0]  rec_data_i          ,
    input    wire           rec_byte_num_en_i   ,
    input    wire    [15:0] rec_byte_num_i      ,
    output   wire           comm_ack_o          ,
    // message rx info
    output   wire           rd_data_vld_o       ,
    output   wire    [7:0]  rd_data_o           ,
    // info
    output   wire           MSG_CLK             ,
    output   wire           MSG_TX_FSX          ,
    output   wire           MSG_TX              ,
    input    wire           MSG_RX_FSX          ,
    input    wire           MSG_RX              
);




message_comm_tx message_comm_tx_inst(
    .phy_rx_clk          ( phy_rx_clk           ),
    .clk                 ( clk                  ),
    .rst_n               ( rst_n                ),
    .rec_pkt_done_i      ( rec_pkt_done_i       ),
    .rec_en_i            ( rec_en_i             ),
    .rec_data_i          ( rec_data_i           ),
    .rec_byte_num_en_i   ( rec_byte_num_en_i    ),
    .rec_byte_num_i      ( rec_byte_num_i       ),
    .comm_ack_o          ( comm_ack_o           ),

    .MSG_CLK             ( MSG_CLK              ),
    .MSG_TX_FSX          ( MSG_TX_FSX           ),
    .MSG_TX              ( MSG_TX               )
);

message_comm_rx message_comm_rx_inst(
    .clk                 ( phy_rx_clk           ),
    // .rst_n               ( rst_n                ),
    .msg_rx_data_vld_o   ( rd_data_vld_o        ),
    .msg_rx_data_o       ( rd_data_o            ),
    .MSG_CLK             ( MSG_CLK              ),
    .MSG_RX_FSX          ( MSG_RX_FSX           ),
    .MSG_RX              ( MSG_RX               )
);

endmodule
