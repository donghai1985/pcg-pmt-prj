`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/09/27 8:40:10
// Design Name: 
// Module Name: eeprom
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


module eeprom(
    input wire			clk,
    input wire			rst,
    input wire[31: 0]	addr_data_w,
	input wire			addr_data_w_en,
	
	input wire[15:0]	addr_r,
	input wire			addr_r_en,
	output reg[7:0]		data_r,
	output reg			data_r_en,
						
    output reg			spi_cs,
    output reg			spi_sck,
    output reg			spi_dout,
    input wire			spi_din,
	output wire 		eeprom_wp_n,
	output wire 		eeprom_hold_n,
	output reg			spi_ok
	);
	

reg [4 :0]			state;
reg [5 :0]			clk_cnt;
reg	[39:0]			write_data_temp;
reg	[39:0]			write_data_temp2;
reg [23:0]			read_data_temp;

reg [3 :0]			spi_counter;

assign		eeprom_wp_n 	= 1'b1;
assign		eeprom_hold_n 	= 1'b1;

always @(posedge clk)begin
	if(rst == 1'b1) begin	
		spi_counter <= 'd0;
	end
	else if(spi_cs ==1'b1) begin
		spi_counter <= 'd0;
	end
	else if(spi_counter == 'd11) begin
		spi_counter <= 'd0;
	end
	else begin
		spi_counter <= spi_counter + 1'd1;
	end
end

always @(posedge clk)
begin
	if(rst == 1'b1) begin
		state	<=	5'd0;
	end
	else begin
	case(state)
	5'd0: begin
		if(addr_data_w_en == 1'b1)
			state	<=	5'd1;
		else if(addr_r_en == 1'b1)
			state	<=	5'd16;
		else
			state	<=	5'd0;
	end
	5'd1: begin
		state	<=	5'd2;
	end
	5'd2: begin
		if((clk_cnt == 6'd8) && (spi_counter == 'd11))
			state	<=	5'd3;
		else
			state	<=	state;
	end
	5'd3: begin
		if(spi_counter == 'd5) begin
			state		<=	5'd4;
		end
		else begin
			state		<=	state;
		end
	end
	5'd4: begin
		if(clk_cnt == 'd10) begin
			state		<=	5'd5;
		end
		else begin
			state		<=	state;
		end
	end
	5'd5: begin
		state	<=	5'd6;
	end
	5'd6: begin
		if((clk_cnt == 6'd40) && (spi_counter == 'd11))
			state	<=	5'd7;
		else
			state	<=	state;
	end
	5'd7: begin
		if(spi_counter == 'd5) begin
			state		<=	5'd8;
		end
		else begin
			state		<=	state;
		end
	end
	5'd8: begin
		if(clk_cnt == 'd10) begin
			state		<=	5'd0;
		end
		else begin
			state		<=	state;
		end
	end
	
	5'd16: begin
		state	<=	5'd17;
	end
	5'd17: begin
		if((clk_cnt == 6'd32) && (spi_counter == 'd11))
			state	<=	5'd18;
		else
			state	<=	state;
	end
	5'd18: begin
		if(spi_counter == 'd5) begin
			state		<=	5'd19;
		end
		else begin
			state		<=	state;
		end
	end
	5'd19: begin
		if(clk_cnt == 'd10) begin
			state		<=	5'd0;
		end
		else begin
			state		<=	state;
		end
	end
	default: begin
		state	<=	5'd0;
	end
	endcase
	end
end

always @(posedge clk)
begin
	if(rst == 1'b1) begin
		spi_cs				<=	1'b1;
		spi_dout			<=	1'b0;
		spi_ok				<=	1'b0;
		clk_cnt				<=	6'd0;
		write_data_temp		<=	40'h0;
		write_data_temp2	<=	40'h0;
		read_data_temp		<=	'h0;
		spi_sck				<=	1'b0;
		data_r				<=	8'h0;
		data_r_en			<=	1'b0;
	end
	else begin
	case(state)
	5'd0: begin
		spi_cs				<=	1'b1;
		spi_dout			<=	1'b0;
		spi_ok				<=	1'b0;
		clk_cnt				<=	6'd0;
		spi_sck				<=	1'b0;
		data_r				<=	8'h0;
		data_r_en			<=	1'b0;
		if(addr_data_w_en == 1'b1) begin
			write_data_temp		<=	{8'h06,32'h0};
			write_data_temp2	<=	{8'h02,addr_data_w};
			read_data_temp		<=	'h0;
		end
		else if(addr_r_en == 1'b1) begin
			write_data_temp		<=	40'h0;
			write_data_temp2	<=	40'h0;
			read_data_temp		<=	{8'h03,addr_r};
		end
		else begin
			write_data_temp		<=	40'h0;
			read_data_temp		<=	'h0;
		end
	end
	5'd1: begin
		spi_cs				<=	1'b0;
		spi_dout			<=	write_data_temp[39];
		spi_ok				<=	1'b0;
		clk_cnt				<=	6'd0;
		write_data_temp		<=	{write_data_temp[38:0],write_data_temp[39]};
		write_data_temp2	<=	write_data_temp2;
		read_data_temp		<=	'h0;
		spi_sck				<=	1'b0;
		data_r				<=	8'h0;
		data_r_en			<=	1'b0;
	end
	5'd2: begin
		spi_cs				<=	1'b0;
		spi_ok				<=	1'b0;
		read_data_temp		<=	'h0;
		data_r				<=	8'h0;
		data_r_en			<=	1'b0;
		write_data_temp2	<=	write_data_temp2;
		if(spi_counter == 'd11) begin
			spi_sck				<=	1'b0;
			spi_dout			<=	write_data_temp[39];
			write_data_temp		<=	{write_data_temp[38:0],write_data_temp[39]};
			clk_cnt				<=	clk_cnt;
		end
		else if(spi_counter == 'd5) begin
			spi_sck				<=	1'b1;
			spi_dout			<=	spi_dout;
			write_data_temp		<=	write_data_temp;
			clk_cnt				<=	clk_cnt + 6'd1;
		end
		else begin
			spi_sck				<=	spi_sck;
			spi_dout			<=	spi_dout;
			write_data_temp		<=	write_data_temp;
			clk_cnt				<=	clk_cnt;
		end
	end
	5'd3: begin
		spi_dout			<=	1'b0;
		spi_ok				<=	1'b0;
		clk_cnt				<=	6'd0;
		write_data_temp		<=	40'h0;
		write_data_temp2	<=	write_data_temp2;
		read_data_temp		<=	'h0;
		spi_sck				<=	1'b0;
		data_r				<=	8'h0;
		data_r_en			<=	1'b0;
		
		if(spi_counter == 'd5) begin
			spi_cs		<=	1'b1;
		end
		else begin
			spi_cs		<=	spi_cs;
		end
	end
	5'd4: begin
		spi_cs				<=	1'b1;
		spi_dout			<=	1'b0;
		spi_ok				<=	1'b0;
		write_data_temp		<=	40'h0;
		write_data_temp2	<=	write_data_temp2;
		read_data_temp		<=	'h0;
		spi_sck				<=	1'b0;
		data_r				<=	8'h0;
		data_r_en			<=	1'b0;
		
		if(clk_cnt == 'd10) begin
			clk_cnt		<=	6'd0;
		end
		else begin
			clk_cnt		<=	clk_cnt + 6'd1;
		end
	end
	5'd5: begin
		spi_cs				<=	1'b0;
		spi_dout			<=	write_data_temp2[39];
		spi_ok				<=	1'b0;
		clk_cnt				<=	6'd0;
		write_data_temp		<=	40'h0;
		write_data_temp2	<=	{write_data_temp2[38:0],write_data_temp2[39]};
		read_data_temp		<=	'h0;
		spi_sck				<=	1'b0;
		data_r				<=	8'h0;
		data_r_en			<=	1'b0;
	end
	5'd6: begin
		spi_cs				<=	1'b0;
		spi_ok				<=	1'b0;
		read_data_temp		<=	'h0;
		data_r				<=	8'h0;
		data_r_en			<=	1'b0;
		write_data_temp		<=	40'h0;
		if(spi_counter == 'd11) begin
			spi_sck				<=	1'b0;
			spi_dout			<=	write_data_temp2[39];
			write_data_temp2	<=	{write_data_temp2[38:0],write_data_temp2[39]};
			clk_cnt				<=	clk_cnt;
		end
		else if(spi_counter == 'd5) begin
			spi_sck				<=	1'b1;
			spi_dout			<=	spi_dout;
			write_data_temp2	<=	write_data_temp2;
			clk_cnt				<=	clk_cnt + 6'd1;
		end
		else begin
			spi_sck				<=	spi_sck;
			spi_dout			<=	spi_dout;
			write_data_temp2	<=	write_data_temp2;
			clk_cnt				<=	clk_cnt;
		end
	end
	5'd7: begin
		spi_dout			<=	1'b0;
		spi_ok				<=	1'b0;
		clk_cnt				<=	6'd0;
		write_data_temp		<=	40'h0;
		write_data_temp2	<=	40'h0;
		read_data_temp		<=	'h0;
		spi_sck				<=	1'b0;
		data_r				<=	8'h0;
		data_r_en			<=	1'b0;
		
		if(spi_counter == 'd5) begin
			spi_cs		<=	1'b1;
		end
		else begin
			spi_cs		<=	spi_cs;
		end
	end
	5'd8: begin
		spi_cs				<=	1'b1;
		spi_dout			<=	1'b0;
		
		write_data_temp		<=	40'h0;
		write_data_temp2	<=	40'h0;
		read_data_temp		<=	'h0;
		spi_sck				<=	1'b0;
		data_r				<=	8'h0;
		data_r_en			<=	1'b0;
		
		if(clk_cnt == 'd10) begin
			spi_ok		<=	1'b1;
			clk_cnt		<=	6'd0;
		end
		else begin
			spi_ok		<=	1'b0;
			clk_cnt		<=	clk_cnt + 6'd1;
		end
	end	
	
	5'd16: begin
		spi_cs				<=	1'b0;
		spi_dout			<=	read_data_temp[23];
		spi_ok				<=	1'b0;
		clk_cnt				<=	6'd0;
		write_data_temp		<=	40'h0;
		write_data_temp2	<=	40'h0;
		read_data_temp		<=	{read_data_temp[22:0],read_data_temp[23]};
		spi_sck				<=	1'b0;
		data_r				<=	8'h0;
		data_r_en			<=	1'b0;
	end
	5'd17: begin
		spi_cs				<=	1'b0;
		spi_ok				<=	1'b0;
		write_data_temp		<=	40'h0;
		write_data_temp2	<=	40'h0;
		if(spi_counter == 'd11) begin
			spi_sck				<=	1'b0;
			spi_dout			<=	read_data_temp[23];
			read_data_temp		<=	{read_data_temp[22:0],read_data_temp[23]};
			clk_cnt				<=	clk_cnt;
		end
		else if(spi_counter == 'd5) begin
			spi_sck				<=	1'b1;
			spi_dout			<=	spi_dout;
			read_data_temp		<=	read_data_temp;
			clk_cnt				<=	clk_cnt + 6'd1;
		end
		else begin
			spi_sck				<=	spi_sck;
			spi_dout			<=	spi_dout;
			read_data_temp		<=	read_data_temp;
			clk_cnt				<=	clk_cnt;
		end
		
		if((spi_counter == 'd5) && (clk_cnt >= 6'd23)) begin
			data_r				<=	{data_r[6:0],spi_din};
			data_r_en			<=	1'b0;
		end
		else begin
			data_r				<=	data_r;
			data_r_en			<=	1'b0;
		end
	end
	5'd18: begin
		spi_dout			<=	1'b0;
		spi_ok				<=	1'b0;
		clk_cnt				<=	6'd0;
		write_data_temp		<=	40'h0;
		write_data_temp2	<=	40'h0;
		read_data_temp		<=	'h0;
		spi_sck				<=	1'b0;
		data_r				<=	data_r;
		data_r_en			<=	1'b0;
		
		if(spi_counter == 'd5) begin
			spi_cs		<=	1'b1;
		end
		else begin
			spi_cs		<=	spi_cs;
		end
	end
	5'd19: begin
		spi_cs				<=	1'b1;
		spi_dout			<=	1'b0;
		write_data_temp		<=	40'h0;
		write_data_temp2	<=	40'h0;
		read_data_temp		<=	'h0;
		spi_sck				<=	1'b0;
		data_r				<=	data_r;
		data_r_en			<=	1'b1;
		
		if(clk_cnt == 'd10) begin
			spi_ok		<=	1'b1;
			clk_cnt		<=	6'd0;
		end
		else begin
			spi_ok		<=	1'b0;
			clk_cnt		<=	clk_cnt + 6'd1;
		end
	end
	default: begin
		spi_cs				<=	1'b1;
		spi_dout			<=	1'b0;
		spi_ok				<=	1'b0;
		clk_cnt				<=	6'd0;
		write_data_temp		<=	40'h0;
		write_data_temp2	<=	40'h0;
		read_data_temp		<=	'h0;
		spi_sck				<=	1'b0;
		data_r				<=	8'h0;
		data_r_en			<=	1'b0;
	end
	endcase
	end
end

    
endmodule
