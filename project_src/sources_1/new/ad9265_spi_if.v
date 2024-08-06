`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    2023/02/27 14:40:10
// Design Name: 
// Module Name:    ad9265_spi_if 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module ad9265_spi_if(
    clk,		//
    rst_n,

    data_in_en,
	data_in,
	
    spi_csn,
    spi_clk,
    spi_sdio,
	
	spi_conf_ok
	
    );
	

input clk;
input rst_n;

input data_in_en;
input [23:0] data_in;

output reg spi_csn;
output reg spi_clk;
inout spi_sdio;	
	
output reg 	spi_conf_ok;

reg [2:0]	spi_counter;
reg [5:0]	spi_clk_cnt;

reg [3:0]	state;

reg			spi_mosi;
reg [23:0] 	conif_data;

assign		spi_sdio	= 	((state == 4'd1) || (state == 4'd2)) ? spi_mosi : 1'bz;

always @(posedge clk or negedge rst_n)begin
	if(rst_n == 1'b0) begin	
		spi_counter <= 'd0;
	end
	else if(spi_csn ==1'b1) begin
		spi_counter <= 'd0;
	end
	else begin
		spi_counter <= spi_counter + 1'd1;
	end
end


always @(posedge clk or negedge rst_n)begin
	if(rst_n == 1'b0) begin
		spi_csn		<=	1'b1;
		spi_clk		<=	1'b0;
		spi_mosi	<=	1'b0;

		state		<=	4'd0;
		
		spi_clk_cnt	<=	6'd0;
		conif_data  <=  'd0;

		spi_conf_ok	<=	1'b0;
	end
	else begin
	case(state)
	4'd0: begin
	    spi_clk		<=	1'b0;
		spi_clk_cnt	<=	6'd0;
		spi_conf_ok	<=	1'b0;
		
		if(data_in_en) begin
			state		<=	4'd1;
			spi_csn		<=	1'b0;
			conif_data	<=	{data_in[22:0],data_in[23]};
			spi_mosi	<=	data_in[23];
		end
		else begin
			state		<=	4'd0;
			spi_csn		<=	1'b1;
			conif_data	<=	'd0;
			spi_mosi	<=	1'b0;
		end
	end
	4'd1: begin
        spi_csn		<=	1'b0;	
	    spi_conf_ok	<=	1'b0;
		
		if(spi_counter == 3'd3) begin
			spi_clk		<=	1'b1;
			spi_clk_cnt	<=	spi_clk_cnt + 6'd1;
			spi_mosi	<=	spi_mosi;
			conif_data	<=	conif_data;
		end
		else if(spi_counter == 3'd7) begin
			spi_clk		<=	1'b0;
			spi_clk_cnt	<=	spi_clk_cnt;
			spi_mosi	<=	conif_data[23];
			conif_data	<=	{conif_data[22:0],conif_data[23]};
		end
		else begin
			spi_clk		<=	spi_clk;
			spi_clk_cnt	<=	spi_clk_cnt;
			spi_mosi	<=	spi_mosi;
			conif_data	<=	conif_data;
		end
		
		if((spi_clk_cnt == 6'd24)&&(spi_counter == 3'd7)) begin
			state		<=	4'd2;
		end
		else begin
			state		<=	state;
		end
	end
	4'd2: begin
	    spi_clk		<=	1'b0;
		spi_mosi	<=	spi_mosi;
		conif_data	<=	conif_data;
		spi_conf_ok	<=	1'b0;
		spi_clk_cnt	<=	6'd0;
		if(spi_counter == 3'd3) begin
			spi_csn		<=	1'b1;
			state		<=	4'd3;
		end
		else begin
			spi_csn		<=	spi_csn;
			state		<=	state;
		end
	end	
	4'd3: begin
		spi_clk		<=	1'b0;
        spi_mosi	<=	1'b0;
		spi_csn		<=	1'b1;
		conif_data	<=	'd0;
		if(spi_clk_cnt == 'd10) begin
			spi_clk_cnt	<=	6'd0;
			state		<=	4'd0;
			spi_conf_ok	<=	1'b1;
		end
		else begin
			spi_clk_cnt	<=	spi_clk_cnt + 6'd1;
			state		<=	state;
			spi_conf_ok	<=	1'b0;
		end
	end
	default: begin
		spi_csn		<=	1'b1;
		spi_clk		<=	1'b0;
		spi_mosi	<=	1'b0;
		state		<=	4'd0;
		spi_clk_cnt	<=	6'd0;
		conif_data  <=  'd0;
		spi_conf_ok	<=	1'b0;
	end
	endcase
	end

end



endmodule