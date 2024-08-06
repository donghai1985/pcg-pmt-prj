`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/09/27 13:40:10
// Design Name: 
// Module Name: ad5592_config
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


module ad5592_config#(
	parameter	 ADC_IO_REG	=	16'b0010000000000000,
	parameter	 DAC_IO_REG	=	16'b0010100000000000
)
(
    clk,		//
    rst,
	
    spi_csn,
    spi_clk,
    spi_mosi,
    spi_miso,
	
	dac_config_en,
	dac_channel,
	dac_data,
	adc_config_en,
	adc_channel,
	
	spi_conf_ok,
	
	init,
	
	adc_data_en,
	adc_data
    );
	
input clk;
input rst;

output spi_csn;
output spi_clk;
output spi_mosi;
input spi_miso;	

input dac_config_en;
input [2:0] dac_channel;
input [11:0] dac_data;
input adc_config_en;
input [7:0] adc_channel;

output spi_conf_ok;

output reg init;

output reg adc_data_en;
output reg [11:0] adc_data;

reg [3:0] cnt;
reg [3:0] state;

parameter S_DAAD_idle   = 4'b0000;
parameter S_DAAD_config = 4'b0001;
parameter S_DAAD_over   = 4'b0010;


parameter COMM_CF_REG     = 16'b0001_1010_0011_0000;  //DAC ,ADC 增益 0V~2Vref   ADC缓冲器预充电
parameter RES_DOWN_REG    = 16'b0011_0000_0000_0000;  //下拉
parameter VREF_CF_REG     = 16'b0101_1010_0000_0000;  //使用内部基准电压


reg data_in_en;
reg [15:0] data_in;

wire [15:0] rd_data_out;

always @(posedge clk)begin
	if(rst) begin
		cnt  <=	4'd0;
		init <=	1'b0;
		state <= S_DAAD_idle;
		data_in  <=  16'd0;
		data_in_en   <=  1'b0;
		adc_data_en <= 1'b0;
		adc_data <= 12'd0;
	end
	else if(init == 1'b0) begin
	    if(cnt==4'd5)begin
			  init <= 1'b1;
			  cnt  <= 4'd0;
		      state <= S_DAAD_idle;
		      data_in  <=  16'd0;
		      data_in_en   <=  1'b0;
              adc_data_en <= 1'b0;
              adc_data <= 12'd0;			  
		end
	    else begin
                adc_data_en <= 1'b0;
                adc_data <= 12'd0;
				init <= 1'b0;
				
	            case(state)
	            S_DAAD_idle: begin
                    cnt	<=  cnt;
					case(cnt)
					  4'd0:
					    begin
						  data_in  <=  COMM_CF_REG;
						end
					  4'd1:
					    begin
						  data_in  <=  ADC_IO_REG;
						end
					  4'd2:
					    begin
						  data_in  <=  DAC_IO_REG;
						end
					  4'd3:
					    begin
						  data_in  <=  RES_DOWN_REG;
						end
					  4'd4:
					    begin
						  data_in  <=  VREF_CF_REG;
						end
					  default:
					    begin
						  data_in  <=  16'd0;
						end
				    endcase
                    data_in_en   <=  1'b1;
                    state      <= S_DAAD_config;					
	            end
	            S_DAAD_config: begin
				    data_in  <=  data_in;
				    data_in_en   <=  1'b0;
					cnt	   <=  cnt;
	            	if(spi_conf_ok) begin
	            		state  <=  S_DAAD_over;
	            	end
	            	else begin
	            		state  <=  state;
	            	end
	            end
	            S_DAAD_over: begin
				    data_in  <=  16'd0;
				    data_in_en   <=  1'b0;				
	            	cnt	   <=  cnt + 4'd1;
	            	state <=  S_DAAD_idle;
	            end
	            default: begin
				    data_in  <=  16'd0;
				    data_in_en <=  1'b0;				
	                cnt	  <=  4'd0;
	                state <=  S_DAAD_idle;
	            end
				endcase
				
			end
	end
	else begin
		case(state)
		S_DAAD_idle: begin
			cnt	  <=  4'd0;
			adc_data_en <= 1'b0;		
			adc_data <= 12'd0;	
			data_in_en <= 1'b0;
			data_in  <=   16'd0;
			if(adc_config_en)begin
				state <=  S_DAAD_config;
		    end
			else begin
				state <=  state;			 
		   end
		end
		S_DAAD_config: begin
			data_in_en <= 1'b0;
			data_in  <=   16'd0;
			cnt	  <=  4'd0;
			adc_data_en <= 1'b0;
			if(spi_conf_ok)begin
				state 	 <=  S_DAAD_over;
				adc_data <= rd_data_out[11:0];
			end
			else begin
				state 	 <=  state;
				adc_data <= 12'd0;
			end
		end
		S_DAAD_over: begin
			data_in_en <= 1'b0;
			data_in  <=   16'd0;
			cnt	  <=  4'd0;		
			state <=  S_DAAD_idle;
			adc_data_en <= 1'b1;
			adc_data <= adc_data;
		end
		default: begin
			data_in_en <= 1'b0;
			data_in    <= 16'd0;
			cnt	  	   <= 4'd0;		
			state 	   <= S_DAAD_idle;
			adc_data_en<= 1'b0;
			adc_data <= 12'd0;
		end
	endcase
	end
end

ad5592_spi_if ad5592_spi_if_inst(
	.clk(clk),
	.rst_n(~rst),
	.data_in_en(data_in_en),
	.data_in(data_in),
	.dac_config_en(dac_config_en),
	.dac_channel(dac_channel),
	.dac_data(dac_data),
	.adc_config_en(adc_config_en),
	.adc_channel(adc_channel),
	.spi_csn(spi_csn),
	.spi_clk(spi_clk),
    .spi_mosi(spi_mosi),
    .spi_miso(spi_miso),
    .spi_conf_ok(spi_conf_ok),
	.rd_data_out(rd_data_out)
);


endmodule
