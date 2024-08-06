`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/03/11 8:40:10
// Design Name: 
// Module Name: timing_spi_if_test
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


module timing_spi_if_test(
		input	wire		clk,
		input	wire		rst,
		input	wire		clk_h,
		
		//spi if
		output	reg			spi_clk,
		output	reg			spi_csn,
		output	reg			spi_mosi,
		
		input	wire		to_spi_clk,
		input	wire		to_spi_csn,
		input	wire		to_spi_mosi

);

reg		[15:0]	tx_cnt;
reg				tx_en;
reg		[15:0]	tx_data;
reg		[15:0]	tx_data_temp;

reg		[3:0]	tx_state;
reg		[15:0]	tx_clk_cnt;
reg		[3:0]	spi_counter;

always @(posedge clk_h or posedge rst)begin
	if(rst) begin	
		spi_counter <= 'd0;
	end
	else if(spi_csn ==1'b1) begin
		spi_counter <= 'd0;
	end
	else if(spi_counter == 'd5)
		spi_counter <= 'd0;
	else begin
		spi_counter <= spi_counter + 1'd1;
	end
end


always	@(posedge clk_h or posedge rst)
begin
	if(rst) begin
		tx_cnt		<=	'd0;
		tx_en		<=	1'b0;
	end
	else if(tx_cnt == 'd29999) begin
		tx_cnt		<=	'd0;
		tx_en		<=	1'b1;
	end
	else begin
		tx_cnt		<=	tx_cnt + 'd1;
		tx_en		<=	1'b0;
	end
end

always	@(posedge clk_h or posedge rst)
begin
	if(rst) begin
		tx_state	<=	'd0;
	end
	else begin
		case(tx_state)
		4'd0: begin
			if(tx_en) begin
				tx_state	<=	'd1;
			end
			else begin
				tx_state	<=	'd0;
			end
		end
		4'd1: begin
			if((spi_counter == 'd5) && (tx_clk_cnt == 'd15)) begin
				tx_state	<=	'd2;
			end
			else begin
				tx_state	<=	'd1;
			end
		end
		4'd2: begin
			tx_state	<=	'd0;
		end
		default: begin
			tx_state	<=	'd0;
		end
		endcase
	end
end


always	@(posedge clk_h or posedge rst)
begin
	if(rst) begin
		spi_clk		<=	1'b0;
		spi_csn		<=	1'b1;
		spi_mosi	<=	1'b0;
		tx_data		<=	'd0;
		tx_data_temp<=	'd0;
		tx_clk_cnt	<=	'd0;
	end
	else begin
		case(tx_state)
		4'd0: begin
			spi_clk		<=	1'b0;
			tx_clk_cnt	<=	'd0;
			if(tx_en) begin
				spi_csn		<=	1'b0;
				spi_mosi	<=	tx_data_temp[15];
				tx_data		<=	16'h5678;//tx_data + 'd1;
				tx_data_temp<=	{tx_data_temp[14:0],tx_data_temp[15]};
			end
			else begin
				spi_csn		<=	1'b1;
				spi_mosi	<=	1'b0;
				tx_data_temp<=	tx_data;
				tx_data		<=	tx_data;
			end
		end
		4'd1: begin
			spi_csn		<=	1'b0;
			tx_data		<=	tx_data;
			if((spi_counter == 'd5) && (tx_clk_cnt == 'd15)) begin
				tx_clk_cnt	<=	'd0;
				spi_mosi	<=	1'd0;
				spi_clk		<=	1'b0;
				tx_data_temp<=	'd0;
			end
			else if(spi_counter == 'd5) begin
				tx_clk_cnt	<=	tx_clk_cnt + 'd1;
				spi_mosi	<=	tx_data_temp[15];
				spi_clk		<=	1'b0;
				tx_data_temp<=	{tx_data_temp[14:0],tx_data_temp[15]};
			end
			else if(spi_counter == 'd2)begin
				tx_clk_cnt	<=	tx_clk_cnt;
				spi_mosi	<=	spi_mosi;
				spi_clk		<=	1'b1;
				tx_data_temp<=	tx_data_temp;
			end
			else begin
				tx_clk_cnt	<=	tx_clk_cnt;
				spi_mosi	<=	spi_mosi;
				spi_clk		<=	spi_clk;
				tx_data_temp<=	tx_data_temp;
			end
		end
		4'd2: begin
			spi_clk		<=	1'b0;
			spi_csn		<=	1'b1;
			spi_mosi	<=	1'b0;
			tx_data_temp<=	'd0;
			tx_data		<=	tx_data;
			tx_clk_cnt	<=	'd0;
		end
		default: begin
			spi_clk		<=	1'b0;
			spi_csn		<=	1'b1;
			spi_mosi	<=	1'b0;
			tx_data_temp<=	'd0;
			tx_data		<=	'd0;
			tx_clk_cnt	<=	'd0;
		end
		endcase
	end
end

//////////////////////////////////////////

reg		[3:0]	rx_state;
reg		[15:0]	rx_clk_cnt;

reg				rx_en;
reg		[15:0]	rx_data;
reg				rx_en_temp;
reg		[15:0]	rx_data_temp;

reg				to_spi_clk_reg1;
reg				to_spi_clk_reg2;
wire			up_edge_to_spi_clk;

always	@(posedge clk_h or posedge rst)
begin
	if(rst) begin
		to_spi_clk_reg1	<=	1'b0;
		to_spi_clk_reg2	<=	1'b0;
	end
	else begin
		to_spi_clk_reg1	<=	to_spi_clk;
		to_spi_clk_reg2	<=	to_spi_clk_reg1;
	end
end
assign		up_edge_to_spi_clk		= 	to_spi_clk_reg1 && (~to_spi_clk_reg2);

always	@(posedge clk_h or posedge rst)
begin
	if(rst) begin
		rx_state	<=	'd0;
	end
	else begin
		case(rx_state)
		4'd0: begin
			if(~to_spi_csn) begin
				rx_state	<=	'd1;
			end
			else begin
				rx_state	<=	'd0;
			end
		end
		4'd1: begin
			if(to_spi_csn) begin
				rx_state	<=	'd0;
			end
			else if(up_edge_to_spi_clk && (rx_clk_cnt == 'd15))begin
				rx_state	<=	'd2;
			end
			else begin
				rx_state	<=	'd1;
			end
		end
		4'd2: begin
			if(to_spi_csn) begin
				rx_state	<=	'd3;
			end
			else begin
				rx_state	<=	'd2;
			end
		end
		4'd3: begin
			if(to_spi_csn) begin
				rx_state	<=	'd0;
			end
			else begin
				rx_state	<=	'd2;
			end
		end
		default: begin
			rx_state	<=	'd0;
		end
		endcase
	end
end


always	@(posedge clk_h or posedge rst)
begin
	if(rst) begin
		rx_data_temp<=	'd0;
		rx_en_temp	<=	1'b0;
		rx_clk_cnt	<=	'd0;
	end
	else begin
		case(rx_state)
		4'd0: begin
			rx_en_temp	<=	1'b0;
			rx_clk_cnt	<=	'd0;
			if(~to_spi_csn) begin
				rx_data_temp<=	'd0;
			end
			else begin
				rx_data_temp<=	rx_data_temp;
			end
		end
		4'd1: begin
			rx_en_temp	<=	1'b0;
			if(up_edge_to_spi_clk && (rx_clk_cnt == 'd15))begin
				rx_data_temp<=	{rx_data_temp[14:0],to_spi_mosi};
				rx_clk_cnt	<=	'd0;
			end
			else if(up_edge_to_spi_clk) begin
				rx_data_temp<=	{rx_data_temp[14:0],to_spi_mosi};
				rx_clk_cnt	<=	rx_clk_cnt + 'd1;
			end
			else begin
				rx_data_temp<=	rx_data_temp;
				rx_clk_cnt	<=	rx_clk_cnt;
			end
		end
		4'd2: begin
			rx_data_temp<=	rx_data_temp;
			rx_clk_cnt	<=	'd0;
			rx_en_temp	<=	1'b0;
		end
		4'd3: begin
			rx_data_temp<=	rx_data_temp;
			rx_clk_cnt	<=	'd0;
			if(to_spi_csn) begin
				rx_en_temp	<=	1'b1;
			end
			else begin
				rx_en_temp	<=	1'b0;
			end
		end
		default: begin
			rx_data_temp<=	'd0;
			rx_en_temp	<=	1'b0;
			rx_clk_cnt	<=	'd0;
		end
		endcase
	end
end

reg			rx_en_temp_exp;
reg			rx_en_temp_exp_flag;
reg [3:0]	rx_en_temp_exp_cnt;

always	@(posedge clk_h or posedge rst)
begin
	if(rst) begin
		rx_en_temp_exp		<=	1'b0;
		rx_en_temp_exp_flag	<=	1'b0;
		rx_en_temp_exp_cnt	<=	'd0;
	end
	else if(rx_en_temp_exp_cnt == 'd8) begin
		rx_en_temp_exp		<=	1'b0;
		rx_en_temp_exp_flag	<=	1'b0;
		rx_en_temp_exp_cnt	<=	'd0;
	end
	else if(rx_en_temp) begin
		rx_en_temp_exp		<=	1'b1;
		rx_en_temp_exp_flag	<=	1'b1;
		rx_en_temp_exp_cnt	<=	rx_en_temp_exp_cnt + 'd1;
	end
	else if(rx_en_temp_exp_flag) begin
		rx_en_temp_exp		<=	1'b1;
		rx_en_temp_exp_flag	<=	1'b1;
		rx_en_temp_exp_cnt	<=	rx_en_temp_exp_cnt + 'd1;
	end
	else begin
		rx_en_temp_exp		<=	1'b0;
		rx_en_temp_exp_flag	<=	1'b0;
		rx_en_temp_exp_cnt	<=	'd0;
	end
end

reg		rx_en_temp_exp_reg1;
reg		rx_en_temp_exp_reg2;

always	@(posedge clk or posedge rst)
begin
	if(rst) begin
		rx_en_temp_exp_reg1	<=	1'b0;
		rx_en_temp_exp_reg2	<=	1'b0;
	end
	else begin
		rx_en_temp_exp_reg1	<=	rx_en_temp_exp;
		rx_en_temp_exp_reg2	<=	rx_en_temp_exp_reg1;
	end
end	

always	@(posedge clk or posedge rst)
begin
	if(rst) begin
		rx_en	<=	1'b0;
		rx_data	<=	'd0;
	end
	else if(rx_en_temp_exp_reg1 && (~rx_en_temp_exp_reg2))begin
		rx_en	<=	1'b1;
		rx_data	<=	rx_data_temp;
	end
	else begin
		rx_en	<=	1'b0;
		rx_data	<=	rx_data;
	end
end



// ila_spi_test ila_spi_test_inst(
// 	.clk(clk),
// 	.probe0(rx_en),
// 	.probe1(rx_data)
// );

endmodule