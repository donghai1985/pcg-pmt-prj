`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    2022/09/27 13:40:10
// Design Name: 
// Module Name:    ad5592_spi_if 
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
module ad5592_spi_if(
    clk,		//
    rst_n,

    data_in_en,
	data_in,
	dac_config_en,
	dac_channel,
	dac_data,
	adc_config_en,
	adc_channel,
	
    spi_csn,
    spi_clk,
    spi_mosi,
    spi_miso,
	
	spi_conf_ok,
	rd_data_out
	
	
    );
	

input clk;
input rst_n;

input data_in_en;
input [15:0] data_in;
input dac_config_en;
input [2:0] dac_channel;
input [11:0] dac_data;
input adc_config_en;
input [7:0] adc_channel;

output reg spi_csn;
output reg spi_clk;
output reg spi_mosi;
input spi_miso;	
	
output reg 	spi_conf_ok;
output reg [15:0] rd_data_out;


reg [2:0]	spi_counter;
reg [5:0]	spi_clk_cnt;

reg [3:0]	state;

reg [15:0] conif_data;

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
		conif_data  <=  16'd0;

		spi_conf_ok	<=	1'b0;
		rd_data_out <=  16'd0;
	end
	else begin
	case(state)
	4'd0: begin
	    spi_clk		<=	1'b0;
		spi_clk_cnt	<=	6'd0;
        spi_mosi	<=	1'b0;
		spi_conf_ok	<=	1'b0;
		rd_data_out <=  rd_data_out;
		
		if(data_in_en) begin
			state		<=	4'd1;
			spi_csn		<=	1'b0;
			conif_data	<=	data_in;
		end
		else if(dac_config_en) begin
			state		<=	4'd1;
			spi_csn		<=	1'b0;
			conif_data	<=	{1'b1,dac_channel,dac_data};
		end
		else if(adc_config_en) begin
			state		<=	4'd4;
			spi_csn		<=	1'b0;
			conif_data	<=	{1'b0,4'b0010,1'b0,1'b0,1'b0,adc_channel};
		end
		else begin
			state		<=	4'd0;
			spi_csn		<=	1'b1;
			conif_data	<=	16'd0;
		end
	end
	4'd1: begin
        spi_csn		<=	1'b0;	
	    spi_conf_ok	<=	1'b0;
		rd_data_out <=  rd_data_out;
		
		if(spi_counter == 3'd3) begin
			spi_clk		<=	1'b1;
			spi_clk_cnt	<=	spi_clk_cnt + 6'd1;
			spi_mosi	<=	conif_data[15];
			conif_data	<=	{conif_data[14:0],conif_data[15]};
		end
		else if(spi_counter == 3'd7) begin
			spi_clk		<=	1'b0;
			spi_clk_cnt	<=	spi_clk_cnt;
			spi_mosi	<=	spi_mosi;
			conif_data	<=	conif_data;
		end
		else begin
			spi_clk		<=	spi_clk;
			spi_clk_cnt	<=	spi_clk_cnt;
			spi_mosi	<=	spi_mosi;
			conif_data	<=	conif_data;
		end
		
		if((spi_clk_cnt == 6'd16)&&(spi_counter == 3'd7)) begin
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
		rd_data_out <=  rd_data_out;
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
		rd_data_out <=  rd_data_out;
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
			spi_conf_ok	<=	spi_conf_ok;
		end
	end
	4'd4: begin
        spi_csn		<=	1'b0;	
	    spi_conf_ok	<=	1'b0;
		rd_data_out <=  rd_data_out;
		
		if(spi_counter == 3'd3) begin
			spi_clk		<=	1'b1;
			spi_clk_cnt	<=	spi_clk_cnt + 6'd1;
			spi_mosi	<=	conif_data[15];
			conif_data	<=	{conif_data[14:0],conif_data[15]};
		end
		else if(spi_counter == 3'd7) begin
			spi_clk		<=	1'b0;
			spi_clk_cnt	<=	spi_clk_cnt;
			spi_mosi	<=	spi_mosi;
			conif_data	<=	conif_data;
		end
		else begin
			spi_clk		<=	spi_clk;
			spi_clk_cnt	<=	spi_clk_cnt;
			spi_mosi	<=	spi_mosi;
			conif_data	<=	conif_data;
		end
		
		if((spi_clk_cnt == 6'd16)&&(spi_counter == 3'd7)) begin
			state		<=	4'd5;
		end
		else begin
			state		<=	state;
		end
	end
	
	4'd5: begin
	    spi_clk		<=	1'b0;
		spi_mosi	<=	spi_mosi;
		conif_data	<=	'd0;
		rd_data_out <=  rd_data_out;
		spi_conf_ok	<=	1'b0;
		spi_clk_cnt	<=	6'd0;
		if(spi_counter == 3'd3) begin
			spi_csn		<=	1'b1;
			state		<=	4'd6;
		end
		else begin
			spi_csn		<=	spi_csn;
			state		<=	state;
		end
	end	
	4'd6: begin
		spi_clk		<=	1'b0;
        spi_mosi	<=	1'b0;
		spi_conf_ok	<=	1'b0;
		rd_data_out <=  rd_data_out;
		if(spi_clk_cnt == 'd10) begin
			spi_clk_cnt	<=	6'd0;
			state		<=	4'd7;
			spi_csn		<=	1'b0;
			conif_data	<=	'd0;
		end
		else begin
			spi_clk_cnt	<=	spi_clk_cnt + 6'd1;
			state		<=	state;
			spi_csn		<=	1'b1;
			conif_data	<=	'd0;
		end
	end
	4'd7: begin
        spi_csn		<=	1'b0;	
	    spi_conf_ok	<=	1'b0;
		rd_data_out <=  rd_data_out;
		conif_data	<=	'd0;
		spi_mosi	<=	1'b0;
		if(spi_counter == 3'd3) begin
			spi_clk		<=	1'b1;
			spi_clk_cnt	<=	spi_clk_cnt + 6'd1;
		end
		else if(spi_counter == 3'd7) begin
			spi_clk		<=	1'b0;
			spi_clk_cnt	<=	spi_clk_cnt;
		end
		else begin
			spi_clk		<=	spi_clk;
			spi_clk_cnt	<=	spi_clk_cnt;
		end
		
		if((spi_clk_cnt == 6'd16)&&(spi_counter == 3'd7)) begin
			state		<=	4'd8;
		end
		else begin
			state		<=	state;
		end
	end
	4'd8: begin
	    spi_clk		<=	1'b0;
		spi_mosi	<=	spi_mosi;
		conif_data	<=	'd0;
		rd_data_out <=  rd_data_out;
		spi_conf_ok	<=	1'b0;
		spi_clk_cnt	<=	6'd0;
		if(spi_counter == 3'd3) begin
			spi_csn		<=	1'b1;
			state		<=	4'd9;
		end
		else begin
			spi_csn		<=	spi_csn;
			state		<=	state;
		end
	end	
	4'd9: begin
		spi_clk		<=	1'b0;
        spi_mosi	<=	1'b0;
		spi_conf_ok	<=	1'b0;
		rd_data_out <=  rd_data_out;
		conif_data	<=	'd0;
		if(spi_clk_cnt == 'd10) begin
			spi_clk_cnt	<=	6'd0;
			state		<=	4'd10;
			spi_csn		<=	1'b0;	
		end
		else begin
			spi_clk_cnt	<=	spi_clk_cnt + 6'd1;
			state		<=	state;
			spi_csn		<=	1'b1;
		end
	end
	4'd10: begin
        spi_csn		<=	1'b0;	
	    spi_conf_ok	<=	1'b0;
		rd_data_out <=  rd_data_out;
		spi_mosi	<=	1'b0;
		conif_data	<=	'd0;
		if(spi_counter == 3'd3) begin
			spi_clk		<=	1'b1;
			spi_clk_cnt	<=	spi_clk_cnt + 6'd1;
			rd_data_out <=  rd_data_out;
		end
		else if(spi_counter == 3'd7) begin
			spi_clk		<=	1'b0;
			spi_clk_cnt	<=	spi_clk_cnt;
			rd_data_out <=  {rd_data_out[14:0],spi_miso};
		end
		else begin
			spi_clk		<=	spi_clk;
			spi_clk_cnt	<=	spi_clk_cnt;
			rd_data_out <=  rd_data_out;
		end
		
		if((spi_clk_cnt == 6'd16)&&(spi_counter == 3'd7)) begin
			state		<=	4'd11;
		end
		else begin
			state		<=	state;
		end
	end
	4'd11: begin
	    spi_clk		<=	1'b0;
		spi_mosi	<=	spi_mosi;
		conif_data	<=	'd0;
		rd_data_out <=  rd_data_out;
		spi_conf_ok	<=	1'b0;
		spi_clk_cnt	<=	6'd0;
		if(spi_counter == 3'd3) begin
			spi_csn		<=	1'b1;
			state		<=	4'd12;
		end
		else begin
			spi_csn		<=	spi_csn;
			state		<=	state;
		end
	end	
	4'd12: begin
		spi_clk		<=	1'b0;
        spi_mosi	<=	1'b0;
		rd_data_out <=  rd_data_out;
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
			spi_conf_ok	<=	spi_conf_ok;
		end
	end
	default: begin
		spi_csn		<=	1'b1;
		spi_clk		<=	1'b0;
		spi_mosi	<=	1'b0;
		state		<=	4'd0;
		spi_clk_cnt	<=	6'd0;
		conif_data  <=  16'd0;
		spi_conf_ok	<=	1'b0;
		rd_data_out <= 16'd0;
	end
	endcase
	end

end



endmodule
