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

module aurora_8b10b_0_FRAME_RX
(
    // User Interface
	output	reg			aurora_rxen,
	output	reg [31:0]	aurora_rxdata,
	
	output	reg			adc_start,
	output	reg			adc_end = 'd0,
	output	reg			adc_test,
	output	reg			clear_buffer,

    // System Interface
    input				USER_CLK,      
    input				RESET,
    input				CHANNEL_UP,
	
	input				rx_tvalid,
	input	[31:0]		rx_data,
	input	[3:0]		rx_tkeep,
	input				rx_tlast
);

//***************************Internal Register/Wire Declarations***************************

wire                dly_data_xfer;
reg     [4:0]       channel_up_cnt;

reg     [3:0]       rx_state;
reg     [15:0]      len_cnt;
reg     [15:0]      delay_cnt;
reg                 adc_end_pulse;

//*********************************Main Body of Code**********************************


always @ (posedge USER_CLK)
begin
	  if(RESET)
		  channel_up_cnt <= `DLY 5'd0;
	  else if(CHANNEL_UP)
			if(&channel_up_cnt)
				channel_up_cnt <= `DLY channel_up_cnt;
			else 
				channel_up_cnt <= `DLY channel_up_cnt + 1'b1;
	  else
			channel_up_cnt <= `DLY 5'd0;
end

assign dly_data_xfer = (&channel_up_cnt);

  //Generate RESET signal when Aurora channel is not ready
assign reset_c = RESET || !dly_data_xfer;

always @(posedge USER_CLK)
begin
	if(reset_c) begin
		rx_state	<=	'd0;
	end
	// else if(~CHANNEL_UP) begin
	// 	rx_state	<=	'd0;
	// end
	else begin
		case(rx_state)
		4'd0: begin
			if(rx_tvalid) begin
				if(rx_tlast)
					rx_state	<=	'd0;
				else if((rx_data[31:16] == 16'h55aa) && (rx_data[15:0] == 16'h0001))
					rx_state	<=	'd1;
				else if((rx_data[31:16] == 16'h55aa) && (rx_data[15:0] == 16'h0002))
					rx_state	<=	'd3;
				else if((rx_data[31:16] == 16'h55aa) && (rx_data[15:0] == 16'h0003))
					rx_state	<=	'd4;
				else
					rx_state	<=	'd5;
			end
			else begin
				rx_state	<=	'd0;
			end
		end
		4'd1: begin
			if(rx_tvalid && rx_tlast) begin
				if((len_cnt == 'd0) && rx_data == 'd1) begin
					rx_state	<=	rx_state + 1'd1;
				end
				else begin
					rx_state	<=	'd0;
				end
			end
			else begin
				rx_state	<=	rx_state;
			end
		end
		4'd2: begin
			if(delay_cnt == 'd300) begin
				rx_state	<=	'd0;
			end
			else begin
				rx_state	<=	rx_state;
			end
		end
		4'd3: begin
			if(rx_tvalid && rx_tlast) begin
				rx_state	<=	'd0;
			end
			else begin
				rx_state	<=	rx_state;
			end
		end
		4'd4: begin
			if(rx_tvalid && rx_tlast) begin
				rx_state	<=	'd0;
			end
			else begin
				rx_state	<=	rx_state;
			end
		end
		
		4'd5: begin
			if(rx_tvalid && rx_tlast) begin
				rx_state	<=	'd0;
			end
			else begin
				rx_state	<=	rx_state;
			end
		end
		default: begin
			rx_state	<=	'd0;
		end
		endcase
	end
end
       

always @(posedge USER_CLK)
begin
	if(reset_c) begin
		len_cnt			<=	'd0;
		adc_start		<=	1'd0;
		adc_end_pulse	<=	1'd0;
		adc_test		<=	1'd0;
		clear_buffer	<=	1'b0;
		delay_cnt		<=	'd0;
	end
	// else if(~CHANNEL_UP) begin
	// 	len_cnt			<=	'd0;
	// 	adc_start		<=	1'd0;
	// 	adc_end_pulse	<=	1'd0;
	// 	adc_test		<=	1'd0;
	// 	clear_buffer	<=	1'b0;
	// 	delay_cnt		<=	'd0;
	// end
	else begin
		case(rx_state)
		4'd1: begin
			clear_buffer	<=	1'b0;
			delay_cnt		<=	'd0;
			if(rx_tvalid && rx_tlast) begin
				len_cnt		<=	'd0;
				adc_start	<=	1'b0;
			end
			else if(rx_tvalid) begin
				len_cnt			<=	len_cnt + 1'd1;
				adc_start		<=	1'b0;
			end
			else begin
				len_cnt		<=	len_cnt;
				adc_start	<=	adc_start;
			end
		end
		4'd2: begin
			len_cnt			<=	'd0;
			if(delay_cnt == 'd300) begin
				adc_start		<=	1'd1;
				clear_buffer	<=	1'b0;
				delay_cnt		<=	'd0;
			end
			else if(delay_cnt < 'd30) begin
				adc_start		<=	1'd0;
				clear_buffer	<=	1'b1;
				delay_cnt		<=	delay_cnt + 1'd1;
			end
			else begin
				adc_start		<=	1'd0;
				clear_buffer	<=	1'b0;
				delay_cnt		<=	delay_cnt + 1'd1;
			end
		end
		4'd3: begin
			clear_buffer	<=	1'b0;
			delay_cnt		<=	'd0;
			if(rx_tvalid && rx_tlast) begin
				len_cnt		<=	'd0;
				if((len_cnt == 'd0) && rx_data == 'd1) begin
					adc_end_pulse	<=	1'b1;
				end
				else begin
					adc_end_pulse	<=	1'b0;
				end
			end
			else if(rx_tvalid) begin
				len_cnt			<=	len_cnt + 1'd1;
				adc_end_pulse	<=	1'b0;
			end
			else begin
				len_cnt			<=	len_cnt;
				adc_end_pulse	<=	1'b0;
			end
		end
		4'd4: begin
			clear_buffer	<=	1'b0;
			delay_cnt		<=	'd0;
			if(rx_tvalid && rx_tlast) begin
				len_cnt		<=	'd0;
				if((len_cnt == 'd0) && rx_data == 'd1) begin
					adc_test	<=	1'b1;
				end
				else begin
					adc_test	<=	1'b0;
				end
			end
			else if(rx_tvalid) begin
				len_cnt		<=	len_cnt + 1'd1;
				adc_test	<=	1'b0;
			end
			else begin
				len_cnt		<=	len_cnt;
				adc_test	<=	adc_test;
			end
		end
		default: begin
			adc_start		<=	adc_start;
			adc_end_pulse	<=	1'd0;
			adc_test		<=	adc_test;
			clear_buffer	<=	1'b0;
			delay_cnt		<=	'd0;
		end
		endcase
	end
end

reg [7:0]	adc_end_exp_cnt;

always @(posedge USER_CLK)
begin
	if(reset_c) begin
		adc_end				<=	1'b0;
		adc_end_exp_cnt		<=	'd0;
	end
	else if(adc_end_pulse) begin
		adc_end				<=	1'b1;
		adc_end_exp_cnt		<=	'd0;
	end
	else if(adc_end_exp_cnt == 'd50) begin
		adc_end				<=	1'b0;
		adc_end_exp_cnt		<=	'd0;
	end
	else if(adc_end) begin
		adc_end				<=	1'b1;
		adc_end_exp_cnt		<=	adc_end_exp_cnt + 1'd1;
	end
	else begin
		adc_end				<=	1'b0;
		adc_end_exp_cnt		<=	'd0;
	end
end

// ila_aurora_rx	ila_aurora_rx_inst(
	// .clk(USER_CLK),
	// .probe0({CHANNEL_UP,rx_tvalid,rx_tlast,aurora_rxen,rx_error,rx_state,7'd0}),
	// .probe1(rx_data),
	// .probe2(frame_check_cnt),
	// .probe3(len_cnt)
// );

endmodule
