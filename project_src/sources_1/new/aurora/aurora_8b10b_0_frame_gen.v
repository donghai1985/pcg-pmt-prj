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

//
//  FRAME GEN
//
//
//
//  Description: This module is a pattern generator to test the Aurora
//               designs in hardware. It generates data and passes it
//               through the Aurora channel. If connected to a framing
//               interface, it generates frames of varying size and
//               separation. LFSR is used to generate the pseudo-random
//               data and lower bits of LFSR are connected to REM bus

`timescale 1 ns / 1 ps
`define DLY #1

module aurora_8b10b_0_FRAME_GEN
(
    // User Interface
    output                      aurora_txen             ,
    input           [31:0]      aurora_txdata           ,
    input           [10:0]      aurora_rd_data_count    ,
    
    input                       adc_start               ,
    output                      aurora_adc_end          ,

    // System Interface
    input                       USER_CLK                ,
    input                       RESET                   ,
    input                       CHANNEL_UP              ,
    
    output  reg                 tx_tvalid               ,
    output  reg     [31:0]      tx_data                 ,
    output  wire    [3:0]       tx_tkeep                ,
    output  reg                 tx_tlast                ,
    input                       tx_tready               
);


//***************************Internal Register/Wire Declarations***************************
parameter                       TCQ                 = 0.1       ;
localparam                      PACKAGE_LENG        = 'd1000    ;
localparam                      DELAY_CNT_WID       = 'd8       ;

localparam                      TX_IDLE             = 'd0       ;
localparam                      TX_PMT_START        = 'd1       ;
localparam                      TX_PMT_DATA         = 'd2       ;
localparam                      TX_PMT_END          = 'd3       ;
localparam                      TX_PCIE_WITE        = 'd4       ;
localparam                      TX_FINISH           = 'd5       ;
localparam                      TX_PMT_WITE         = 'd6       ;

wire                            reset_c                         ;
wire                            dly_data_xfer                   ;
wire                            eds_frame_pose                  ;
wire                            pmt_start_pose                  ;
wire                            wait_fbc_timeout                ;

reg     [4-1:0]                 tx_state            = TX_IDLE   ;
reg     [4-1:0]                 tx_state_next       = TX_IDLE   ;
reg     [4:0]                   channel_up_cnt      = 'd0       ;

reg     [15:0]                  len_cnt             = 'd0       ;
reg     [31:0]                  frame_cnt           = 'd0       ;
reg     [DELAY_CNT_WID-1:0]     pmt_tx_delay_cnt    = 'd0       ;

reg                             adc_start_d0        = 'd0       ;
reg                             adc_start_d1        = 'd0       ;
reg                             adc_start_d2        = 'd0       ;

//*********************************Main Body of Code**********************************
always @ (posedge USER_CLK)
begin
    if(RESET)
        channel_up_cnt <= #TCQ 5'd0;
    else if(CHANNEL_UP)
        if(&channel_up_cnt)
            channel_up_cnt <= #TCQ channel_up_cnt;
        else 
            channel_up_cnt <= #TCQ channel_up_cnt + 1'b1;
    else
        channel_up_cnt <= #TCQ 5'd0;
end

assign dly_data_xfer = (&channel_up_cnt);

  //Generate RESET signal when Aurora channel is not ready
assign reset_c = !dly_data_xfer;

//帧长为帧头32bit + 1023*32bit
//帧头格式为16'h55aa + 16bit指令码
    //______________________________ Transmit Data  __________________________________   
always @ (posedge USER_CLK)begin
    adc_start_d0    <= #TCQ adc_start;
    adc_start_d1    <= #TCQ adc_start_d0;
    adc_start_d2    <= #TCQ adc_start_d1;
end

always @(posedge USER_CLK) begin
    if(reset_c)
        tx_state <= #TCQ TX_IDLE;
    else 
        tx_state <= #TCQ tx_state_next;
end

always @(*) begin
    tx_state_next = tx_state;
    case (tx_state)
        TX_IDLE: begin
            if(adc_start_d2)
                tx_state_next = TX_PCIE_WITE;
        end 

        // TX_PMT_START: begin
        //     if(tx_tlast)
        //         tx_state_next = TX_PCIE_WITE;
        // end

        TX_PCIE_WITE: begin
            if(pmt_tx_delay_cnt[DELAY_CNT_WID-1])
                tx_state_next = TX_PMT_WITE;
        end

        TX_PMT_WITE: begin
            if(~adc_start_d2) 
                tx_state_next = TX_FINISH;
            else if(aurora_rd_data_count >= PACKAGE_LENG-1)
                tx_state_next = TX_PMT_DATA;
        end
        
        TX_PMT_DATA: begin
            if(tx_tlast)
                tx_state_next = TX_PMT_WITE;
        end

        // TX_PMT_END: begin
        //     if(tx_tlast)
        //         tx_state_next = TX_FINISH;
        // end
        
        TX_FINISH: begin
            // if(pmt_tx_delay_cnt[DELAY_CNT_WID-1])
                tx_state_next = TX_IDLE;
        end
        default:tx_state_next = TX_IDLE;
    endcase
end

always @(posedge USER_CLK) begin
    if(tx_state==TX_PCIE_WITE || tx_state==TX_FINISH)
        pmt_tx_delay_cnt <= #TCQ pmt_tx_delay_cnt + 1;
    else 
        pmt_tx_delay_cnt <= #TCQ 'd0;
end

// tx count
always @(posedge USER_CLK) begin
    if( tx_state==TX_PMT_START || tx_state==TX_PMT_DATA || tx_state==TX_PMT_END )begin
        if(tx_tlast)
            len_cnt <= #TCQ 'd0;
        else if(tx_tvalid)
            len_cnt <= #TCQ len_cnt + 1;
    end
    else begin
        len_cnt <= #TCQ 'd0;
    end
end

// tx valid
always @(*)begin
    if(tx_state==TX_PMT_START || tx_state==TX_PMT_DATA || tx_state==TX_PMT_END)
        tx_tvalid = tx_tready;
    else
        tx_tvalid = 1'b0;
end


always @(*)begin
    if((tx_state == TX_PMT_START)) begin
        if(len_cnt == 'd0) 
            tx_data = 32'h55aa_0001;
        else if(len_cnt == 'd1) 
            tx_data = 32'h0000_0001;    //PMT包开始
        else 
            tx_data = 'd0;
    end
    else if((tx_state == TX_PMT_DATA)) begin
        if(len_cnt == 'd0) 
            tx_data = 32'h55aa_0002;    
        else 
            tx_data = aurora_txdata;
    end
    else if((tx_state == TX_PMT_END)) begin
        if(len_cnt == 'd0)
            tx_data = 32'h55aa_0001;
        else if(len_cnt == 'd1)
            tx_data = 32'h0000_0000;    //PMT包结束
        else 
            tx_data = 'd0;
    end
    else begin
        tx_data = 'd0;
    end
end

// tx last
always @(*)begin
    if((tx_state == TX_PMT_START) && (len_cnt == 'd1))
        tx_tlast = tx_tready;
    else if((tx_state == TX_PMT_DATA) && (len_cnt == PACKAGE_LENG))
        tx_tlast = tx_tready;
    else if((tx_state == TX_PMT_END) && (len_cnt == 'd1))
        tx_tlast = tx_tready;
    else
        tx_tlast = 1'b0;
end   

assign  aurora_txen     = ((tx_state == TX_PMT_DATA) && (len_cnt >= 'd1)) ? tx_tvalid : 1'b0;
assign  tx_tkeep        = 4'b1111;
assign  aurora_adc_end  = tx_state==TX_FINISH;

endmodule
