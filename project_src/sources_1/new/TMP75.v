`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    2022/09/27 8:00:14
// Design Name: 
// Module Name:    TMP75 
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

module TMP75(
		input wire	clk,		//输入时钟，100MHz
		input wire	rst,
		output wire TEMP_SCL,	//
		inout wire	TEMP_SDA,
		
		input wire TEMP_RD_en,
		
		output reg [11:0] TEMP_DATA,
		output reg	TEMP_DATA_en
    );


/*************分频部分，产生312.5kHz时钟****************/
reg [1:0] clk_state;
reg [8:0] cnt_delay;
reg [2:0] cnt;
always @(posedge clk) begin
	if(rst)
		cnt_delay <= 9'd0;
	else if(STATE == IDLE2)
		cnt_delay <= 9'd0;
	else if(cnt_delay == 9'd319)
		cnt_delay <= 9'd0;
	else
		cnt_delay <= cnt_delay + 1'b1;
end
always @(posedge clk) begin
	if(rst)
		cnt <= 3'd4;
	else if(STATE == IDLE2)
		cnt <= 3'd4;
	else begin
		case(cnt_delay)
			9'd79: 	cnt <= 3'd0;	//TEMP_SCL低电平中间采样点
			9'd159: cnt <= 3'd1;	//TEMP_SCL上升沿
			9'd239: cnt <= 3'd2;	//TEMP_SCL高电平中间采样点
			9'd319: cnt <= 3'd3;	//TEMP_SCL下降沿
			default:cnt <= 3'd4;
		endcase
	end
end

//将TEMP_SCL几个点进行宏定义
`define SCL_LOW (cnt == 3'd0)	
`define	SCL_POS	(cnt == 3'd1)	
`define	SCL_HIG	(cnt == 3'd2)	
`define	SCL_NEG	(cnt == 3'd3)	

reg TEMP_SCL_r;	//定义TEMP_SCL时钟脉冲，1为高电平，0为低电平

always @(posedge clk) begin
	if(rst)
		TEMP_SCL_r <= 1'b1;
	else if(STATE == IDLE2)
		TEMP_SCL_r <= 1'b1;
	else if(cnt == 3'd1)
		TEMP_SCL_r <= 1'b1;
	else if(cnt == 3'd3) 
		TEMP_SCL_r <= 1'b0;
	else
		TEMP_SCL_r <= TEMP_SCL_r;		
end

assign TEMP_SCL = TEMP_SCL_r;


/*************时序部分，对TMP75进行读写操作****************/
//将读/写地址进行宏定义
`define  WR_ADDR	8'b1001_0000	//写地址
`define  RD_ADDR	8'b1001_0001	//读地址
`define  POI_REG1	8'b0000_0000	//指针寄存器 选择温度寄存器（只读）

//状态定义
parameter IDLE		= 5'd0;
parameter START1	= 5'd1;
parameter ADDR1		= 5'd2;
parameter ACK1		= 5'd3;
parameter ADDR2		= 5'd4;
parameter ACK2		= 5'd5;
parameter STOP		= 5'd6;
parameter IDLE2		= 5'd7;
parameter START2	= 5'd8;
parameter ADDR3		= 5'd9;
parameter ACK4		= 5'd10;
parameter RD_DATA1	= 5'd11;
parameter ACK5		= 5'd12;
parameter RD_DATA2	= 5'd13;
parameter ACK6		= 5'd14;
parameter STOP2		= 5'd15;

reg [4:0] STATE;		//状态寄存器
reg [7:0] DATA_r;		//I2C上要传送的数据寄存器
reg SDA_r;				//输出数据寄存器
reg SDA_Link;			//SDA双向传输控制 高电平为输入，低电平为高阻
reg [11:0] ReadData;	//数据读出寄存器
reg [3:0] SDA_Num;		//数据移位计数

always @(posedge clk) begin
	if(rst) begin
		STATE <= IDLE;
		SDA_r <= 1'b1;
		SDA_Link <= 1'b0;
		ReadData <= 8'b0000_0000;
		SDA_Num <= 4'd0;
		TEMP_DATA <= 12'h0;
		TEMP_DATA_en <= 1'b0;
	end
	else begin
		case(STATE)
			IDLE:		begin
							SDA_Link <= 1'b1;		//数据线SDA设置为输出
							SDA_r <= 1'b1;
							STATE <= START1;
							DATA_r <= `WR_ADDR;
							TEMP_DATA_en <= 1'b0;
							TEMP_DATA <= 12'h0;
						end
			START1:	begin
							if(`SCL_HIG) begin
								SDA_Link <= 1'b1;
								SDA_r <= 1'b0;		//在SCL高电平期间将SDA拉低
								SDA_Num <= 4'd0;
								STATE <= ADDR1;
							end
							else
								STATE <= START1;
						end
			ADDR1:	begin
							if(`SCL_LOW) begin
								if(SDA_Num == 4'd8) begin
									SDA_Link <= 1'b0;	//数据线SDA设置为高阻
									SDA_r <= 1'b0;
									SDA_Num <= 4'd0;
									STATE <= ACK1;
								end
								else begin
									SDA_Num <= SDA_Num + 4'd1;
									STATE <= ADDR1;
									case(SDA_Num)		//串行传输数据，从高位开始传送
										4'd0 : SDA_r <= DATA_r[7];
										4'd1 : SDA_r <= DATA_r[6];
										4'd2 : SDA_r <= DATA_r[5];
										4'd3 : SDA_r <= DATA_r[4];
										4'd4 : SDA_r <= DATA_r[3];
										4'd5 : SDA_r <= DATA_r[2];
										4'd6 : SDA_r <= DATA_r[1];
										4'd7 : SDA_r <= DATA_r[0];
										default : ;
									endcase
								end
							end
							else
								STATE <= ADDR1;
						end
			ACK1:		begin
							if(`SCL_NEG) begin
								STATE <= ADDR2;
								DATA_r <= `POI_REG1;
							end
							else
								STATE <= ACK1;
						end
			ADDR2:	begin
							if(`SCL_LOW) begin
								if(SDA_Num == 4'd8) begin
									SDA_Link <= 1'b0;	//数据线SDA设置为高阻
									SDA_r <= 1'b0;
									SDA_Num <= 4'd0;
									STATE <= ACK2;
								end
								else begin
									SDA_Num <= SDA_Num + 4'd1;
									STATE <= ADDR2;
									SDA_Link <= 1'b1;	//输入输出口设置为output
									case(SDA_Num)		//串行传输数据，从高位开始传送
										4'd0 : SDA_r <= DATA_r[7];
										4'd1 : SDA_r <= DATA_r[6];
										4'd2 : SDA_r <= DATA_r[5];
										4'd3 : SDA_r <= DATA_r[4];
										4'd4 : SDA_r <= DATA_r[3];
										4'd5 : SDA_r <= DATA_r[2];
										4'd6 : SDA_r <= DATA_r[1];
										4'd7 : SDA_r <= DATA_r[0];
										default : ;
									endcase
								end
							end
							else
								STATE <= ADDR2;
						end
			ACK2:		begin
							if(`SCL_NEG) begin
								STATE <= STOP;
							end
							else
								STATE <= ACK2;
						end
			STOP:		begin
							if(`SCL_LOW) begin
								SDA_r <= 1'b0;
								SDA_Link <= 1'b1;
								STATE <= STOP;
							end
							else if(`SCL_HIG) begin
								SDA_r <= 1'b1;
								STATE <= IDLE2;
							end
							else
								STATE <= STOP;
						end
			IDLE2:		begin
							SDA_Link <= 1'b1;		//数据线SDA设置为输出
							SDA_r <= 1'b1;
							TEMP_DATA <= TEMP_DATA;
							TEMP_DATA_en <= 1'b0;
							if(TEMP_RD_en) begin
								STATE <= START2;
								DATA_r <= `RD_ADDR;
							end
							else begin
								STATE <= IDLE2;
								DATA_r <= 8'h0;
							end
						end
			START2:	begin
							if(`SCL_HIG) begin
								SDA_r <= 1'b0;		//在SCL高电平期间将SDA拉低
								SDA_Num <= 4'd0;
								STATE <= ADDR3;
							end
							else begin
								SDA_Link <= 1'b1;
								SDA_r <= 1'b1;	
								STATE <= START2;
							end
						end
			ADDR3:	begin
							if(`SCL_LOW) begin
								if(SDA_Num == 4'd8) begin
									SDA_Link <= 1'b0;	//数据线SDA设置为高阻
									SDA_r <= 1'b0;
									SDA_Num <= 4'd0;
									STATE <= ACK4;
								end
								else begin
									SDA_Num <= SDA_Num + 4'd1;
									STATE <= ADDR3;
									SDA_Link <= 1'b1;	//输入输出口设置为output
									case(SDA_Num)		//串行传输数据，从高位开始传送
										4'd0 : SDA_r <= DATA_r[7];
										4'd1 : SDA_r <= DATA_r[6];
										4'd2 : SDA_r <= DATA_r[5];
										4'd3 : SDA_r <= DATA_r[4];
										4'd4 : SDA_r <= DATA_r[3];
										4'd5 : SDA_r <= DATA_r[2];
										4'd6 : SDA_r <= DATA_r[1];
										4'd7 : SDA_r <= DATA_r[0];
										default : ;
									endcase
								end
							end
							else
								STATE <= ADDR3;
						end
			ACK4:		begin
							if(`SCL_NEG) begin
								STATE <= RD_DATA1;
								SDA_Link <= 1'b0;
							end
							else
								STATE <= ACK4;
						end
			RD_DATA1:	begin
								if(`SCL_HIG) begin
									SDA_Num <= SDA_Num + 4'd1;
									STATE <= RD_DATA1;
									case(SDA_Num)
										4'd0 : ReadData[11] <= TEMP_SDA;
										4'd1 : ReadData[10] <= TEMP_SDA;
										4'd2 : ReadData[9] <= TEMP_SDA;
										4'd3 : ReadData[8] <= TEMP_SDA;
										4'd4 : ReadData[7] <= TEMP_SDA;
										4'd5 : ReadData[6] <= TEMP_SDA;
										4'd6 : ReadData[5] <= TEMP_SDA;
										4'd7 : ReadData[4] <= TEMP_SDA;
										default : ;
									endcase
								end
								else if((`SCL_LOW) & (SDA_Num == 4'd8)) begin
									 SDA_Num <= 4'd0;
									 STATE <= ACK5;
									 SDA_Link <= 1'b1;
									 SDA_r <= 1'b0;
								end
								else
									STATE <= RD_DATA1;	
						end
			ACK5:		begin
							if(`SCL_NEG) begin
								STATE <= RD_DATA2;
								SDA_Link <= 1'b0;
							end
							else
								STATE <= ACK5;
						end
			RD_DATA2:	begin
								if(`SCL_HIG) begin
									SDA_Num <= SDA_Num + 4'd1;
									STATE <= RD_DATA2;
									case(SDA_Num)
										4'd0 : ReadData[3] <= TEMP_SDA;
										4'd1 : ReadData[2] <= TEMP_SDA;
										4'd2 : ReadData[1] <= TEMP_SDA;
										4'd3 : ReadData[0] <= TEMP_SDA;
										4'd4 : ;
										4'd5 : ;
										4'd6 : ;
										4'd7 : ;
										default : ;
									endcase
								end
								else if((`SCL_LOW) & (SDA_Num == 4'd8)) begin
									 SDA_Num <= 4'd0;
									 STATE <= ACK6;
									 SDA_Link <= 1'b1;
									 SDA_r <= 1'b0;
								end
								else
									STATE <= RD_DATA2;	
						end
			ACK6:		begin
							if(`SCL_NEG) begin
								STATE <= STOP2;
							end
							else
								STATE <= ACK6;
						end
			STOP2:		begin
							if(`SCL_LOW) begin
								SDA_r <= 1'b0;
								SDA_Link <= 1'b1;
								STATE <= STOP2;
							end
							else if(`SCL_HIG) begin
								SDA_r <= 1'b0;
								STATE <= IDLE2;
								TEMP_DATA <= ReadData;
								TEMP_DATA_en <= 1'b1;
							end
							else
								STATE <= STOP2;
						end
		endcase
	end
end

assign TEMP_SDA = SDA_Link ? SDA_r : 1'bz;	//使用变量SDA_Link的电平来控制输入输出信号SDA的状态，
													//SDA为输入信号时，让它处于高阻态；作为输出信号时，将其赋予SDA_r的值

endmodule
