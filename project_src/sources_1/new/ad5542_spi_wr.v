`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/05/23 15:29:35
// Design Name: 
// Module Name: ad5542_spi_wr
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


module ad5542_spi_wr(

input                clk,
input                rst,


input                wr_data_en,
input      [15:0]    wr_data,
output reg           wr_data_end,

output reg           spi_clk,
output reg           spi_cs_n,
output reg           spi_din
  
);

reg [1:0]            spi_counter;
reg [4:0]            spi_clk_cnt;
reg [15:0]           data_buff;
reg [3:0]            state;

always @(posedge clk or posedge rst)begin
    if(rst)
	    spi_counter <= 'd0;
	else if(spi_cs_n == 1'b1)
	    spi_counter <= 'd0;
	else
	    spi_counter <= spi_counter + 1'b1;
end


always @(posedge clk or posedge rst)begin
    if(rst)begin
	    spi_clk          <= 1'b1;
        spi_cs_n         <= 1'b1;
        spi_clk_cnt      <= 'd0;	
        state            <= 1'b0;
		data_buff        <= 'd0;
		wr_data_end      <= 1'b0;
	end
	else begin
	    case(state) 
		    4'd0: begin    
			    if(wr_data_en)begin
				    spi_cs_n        <= 1'b0;
					data_buff       <= wr_data;
					state           <= 4'd1;
				end                 
				else begin          
				    spi_cs_n        <= spi_cs_n;
					state           <= state;
					data_buff       <= data_buff;
				end		
			end	
			
			4'd1: begin
			    if(spi_counter == 1)begin
				    spi_clk         <= 1'b0;
					spi_clk_cnt     <= spi_clk_cnt;
					spi_din         <= data_buff[15];
					data_buff       <= {data_buff[14:0],data_buff[15]};
					
				end
				else if(spi_counter == 3)begin
				    spi_clk         <= 1'b1;
					spi_clk_cnt     <= spi_clk_cnt + 1'b1;
					data_buff       <= data_buff;		
					if(spi_clk_cnt == 'd15)begin
					    spi_clk_cnt <= 'd0;
						state       <= 4'd2;
					end
					else begin
					    state       <= state;
					end
				end
				else begin
				    spi_clk         <= spi_clk;
					spi_clk_cnt     <= spi_clk_cnt;
					data_buff       <= data_buff;
				end
			end
			
			4'd2: begin
			    if(spi_counter == 1)begin
				    spi_clk         <= 1'b0;
				    spi_cs_n        <= 1'b1;
					state           <= state;
					wr_data_end     <= wr_data_end;
				end
				else if(spi_clk_cnt == 2)begin
				    spi_clk         <= 1'b1;
					spi_cs_n        <= spi_cs_n;
					spi_clk_cnt     <= 'd0;
					state           <= 4'd3;
					wr_data_end     <= 1'b1;
				end
				else begin
				    spi_clk         <= spi_clk;
				    spi_cs_n        <= spi_cs_n;
					spi_clk_cnt     <= spi_clk_cnt + 1'b1;
					state           <= state;
					wr_data_end     <= wr_data_end;
				end
			end
			
			4'd3: begin
			    wr_data_end         <= 1'b0;
			    if(spi_clk_cnt == 3)begin
					spi_clk_cnt     <= 'd0;
					state           <= 'd0;
				end
				else begin
				    spi_clk_cnt     <= spi_clk_cnt + 1'b1;
					state           <= state;
				end 
			end
			
			default: begin
			   spi_clk          <= 1'b1;
               spi_cs_n         <= 1'b1;
               spi_clk_cnt      <= 'd0;	
               state            <= 1'b0;
		       data_buff        <= 'd0;
		       wr_data_end      <= 1'b0;
			end
		endcase	
	end
end


endmodule
