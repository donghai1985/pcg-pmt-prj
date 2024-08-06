`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/02/27 13:40:10
// Design Name: 
// Module Name: ad9265_top_if
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


module ad9265_top_if (
        input   wire        clk             ,
        input   wire        rst             ,

        //adc config
        output  wire        AD9265_SYNC     ,
        output  wire        AD9265_PDWN     ,
        output  wire        spi_clk         ,
        output  wire        spi_csn         ,
        inout   wire        spi_sdio        ,
        output  reg         init            ,
        //adc data
        input   wire        AD9265_DCO      ,
        input   wire [15:0] AD9265_DATA     ,
        input   wire        AD9265_OR       ,

        input   wire        adc_start       ,
        input   wire        adc_test        ,

        output  wire [15:0] adc_data        ,
        output  wire        adc_data_en     
);

assign		AD9265_SYNC		=	1'b0;
assign		AD9265_PDWN		=	1'b0;

reg 		data_in_en;
reg [23:0] 	data_in;

wire		spi_conf_ok;


reg [3:0] 	cnt;
reg [3:0] 	state;

parameter 	S_idle   		= 4'b0000;
parameter 	S_config 		= 4'b0001;
parameter 	S_over   		= 4'b0010;

parameter 	SPI_CF_REG     	= 24'h0000_18;
parameter 	PWR_MODE_REG   	= 24'h0008_80;
parameter 	OUT_MODE_REG   	= 24'h0014_00;
parameter 	VREF_CF_REG   	= 24'h0018_C0;
parameter 	TRANSFER_REG   	= 24'h00ff_01;

`ifdef SIMULATE
always @(posedge clk) begin
    if(rst)
        init <= 'd0;
    else 
        init <= 'd1; 
end
`else
always @(posedge clk)begin
	if(rst) begin
		cnt  <=	4'd0;
		init <=	1'b0;
		state <= S_idle;
		data_in  <=  'd0;
		data_in_en   <=  1'b0;
	end
	else if(init == 1'b0) begin
	    if(cnt==4'd5)begin
			  init <= 1'b1;
			  cnt  <= 4'd0;
		      state <= S_idle;
		      data_in  <=  'd0;
		      data_in_en   <=  1'b0;			  
		end
	    else begin
				init <= 1'b0;
				
	            case(state)
	            S_idle: begin
                    cnt	<=  cnt;
					case(cnt)
					  4'd0:
					    begin
						  data_in  <=  SPI_CF_REG;
						end
					  4'd1:
					    begin
						  data_in  <=  PWR_MODE_REG;
						end
					  4'd2:
					    begin
						  data_in  <=  OUT_MODE_REG;
						end
					  4'd3:
					    begin
						  data_in  <=  VREF_CF_REG;
						end
					  4'd4:
					    begin
						  data_in  <=  TRANSFER_REG;
						end
					  default:
					    begin
						  data_in  <=  'd0;
						end
				    endcase
                    data_in_en   <=  1'b1;
                    state      <= S_config;					
	            end
	            S_config: begin
				    data_in  <=  data_in;
				    data_in_en   <=  1'b0;
					cnt	   <=  cnt;
	            	if(spi_conf_ok) begin
	            		state  <=  S_over;
	            	end
	            	else begin
	            		state  <=  state;
	            	end
	            end
	            S_over: begin
				    data_in  <=  'd0;
				    data_in_en   <=  1'b0;				
	            	cnt	   <=  cnt + 4'd1;
	            	state <=  S_idle;
	            end
	            default: begin
				    data_in  <=  'd0;
				    data_in_en <=  1'b0;				
	                cnt	  <=  4'd0;
	                state <=  S_idle;
	            end
				endcase
		end
	end
	else begin
		cnt  <=	4'd0;
		state <= S_idle;
		data_in  <=  'd0;
		data_in_en   <=  1'b0;
	end
end
`endif //SIMULATE

ad9265_spi_if ad9265_spi_if_inst(
	.clk(clk),
	.rst_n(~rst),
	.data_in_en(data_in_en),
	.data_in(data_in),
	.spi_csn(spi_csn),
	.spi_clk(spi_clk),
    .spi_sdio(spi_sdio),
    .spi_conf_ok(spi_conf_ok)
);

reg	[15:0]	ad_test_data;

reg [3:0]	wr_state;

reg			adc_start_reg1  = 'd0;
reg			adc_start_reg2  = 'd0;
reg			adc_end_reg1    = 'd0;
reg			adc_end_reg2    = 'd0;

reg [16:0]  adc_data_dco    = 'd0;
reg         adc_data_en_dco = 'd0;

always @(posedge AD9265_DCO)
begin
    adc_start_reg1	<=	adc_start;
    adc_start_reg2	<=	adc_start_reg1;
end

// always @(posedge AD9265_DCO) begin
//     if(adc_start_reg2)begin
//         adc_data_en_dco <= ~adc_data_en_dco;
//     end
//     else begin
//         adc_data_en_dco <= 'd0;
//     end
// end
reg adc_data_en_dco_vld = 'd0;
always @(posedge AD9265_DCO) begin
    adc_data_en_dco_vld <= adc_start_reg2;
end

reg adc_test_d0 = 'd0;
always @(posedge AD9265_DCO) begin
    adc_test_d0 <= adc_test;
end

always @(posedge AD9265_DCO) begin
    if(adc_start_reg2)begin
        if(adc_test_d0)begin
            adc_data_dco <= adc_data_dco + 1;
        end
        else begin
            adc_data_dco <= AD9265_DATA;
        end
    end
    else begin
        adc_data_dco <= 'd0;
    end
end

reg init_sync = 'd0;
always @(posedge AD9265_DCO) begin
    init_sync <= init;
end

wire            full ;
wire            empty;
xpm_async_fifo #(
    .ECC_MODE                   ( "no_ecc"                      ),
    .FIFO_MEMORY_TYPE           ( "distributed"                 ), // "auto" "block" "distributed"
    .READ_MODE                  ( "std"                         ),
    .FIFO_WRITE_DEPTH           ( 16                            ),
    .WRITE_DATA_WIDTH           ( 16                            ),
    .READ_DATA_WIDTH            ( 16                            ),
    .RELATED_CLOCKS             ( 1                             ), // write clk same source of read clk
    .USE_ADV_FEATURES           ( "1808"                        )
)u_xpm_async_fifo (
    .wr_clk_i                   ( AD9265_DCO                    ),
    .rst_i                      ( ~init_sync                    ), // synchronous to wr_clk
    .wr_en_i                    ( adc_data_en_dco_vld           ),
    .wr_data_i                  ( adc_data_dco                  ),

    .rd_clk_i                   ( clk                           ),
    .rd_en_i                    ( ~empty                        ),
    .fifo_rd_vld_o              ( adc_data_en                   ),
    .fifo_rd_data_o             ( adc_data                      ),
    .fifo_empty_o               ( empty                         )
);
// always @(posedge clk) begin
//     adc_data_en <= ~empty;
// end
endmodule
	