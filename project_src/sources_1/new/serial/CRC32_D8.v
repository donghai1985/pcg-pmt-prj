
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: zas
// Engineer: songyuxin
// 
// Create Date: 2023/11/20
// Design Name: PCG
// Module Name: CRC32_D8
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
//
//
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module CRC32_D8#(
    parameter       TCQ     = 0.1
)(
    input           clk_i           ,
    input           rst_i           ,
    input           data_in_vaild   ,  // 输入数据有效 
    input   [7:0]   data_in         ,  // 输入数据
    output          CRC_out_vaild   ,  // delay 1clk for data_in_vaild
    output  [31:0]  CRC_out         
);
    
wire    [7:0]   d;
wire    [31:0]  c;
reg     [31:0]  newcrc;

assign d = data_in;
assign c = CRC_out;

always @(posedge clk_i)begin
    if(rst_i)
        newcrc      <= #TCQ 32'hffff_ffff;
    else if (data_in_vaild)begin
        newcrc[0]   <= #TCQ d[6] ^ d[0] ^ c[24] ^ c[30];
        newcrc[1]   <= #TCQ d[7] ^ d[6] ^ d[1] ^ d[0] ^ c[24] ^ c[25] ^ c[30] ^ c[31];
        newcrc[2]   <= #TCQ d[7] ^ d[6] ^ d[2] ^ d[1] ^ d[0] ^ c[24] ^ c[25] ^ c[26] ^ c[30] ^ c[31];
        newcrc[3]   <= #TCQ d[7] ^ d[3] ^ d[2] ^ d[1] ^ c[25] ^ c[26] ^ c[27] ^ c[31];
        newcrc[4]   <= #TCQ d[6] ^ d[4] ^ d[3] ^ d[2] ^ d[0] ^ c[24] ^ c[26] ^ c[27] ^ c[28] ^ c[30];
        newcrc[5]   <= #TCQ d[7] ^ d[6] ^ d[5] ^ d[4] ^ d[3] ^ d[1] ^ d[0] ^ c[24] ^ c[25] ^ c[27] ^ c[28] ^ c[29] ^ c[30] ^ c[31];
        newcrc[6]   <= #TCQ d[7] ^ d[6] ^ d[5] ^ d[4] ^ d[2] ^ d[1] ^ c[25] ^ c[26] ^ c[28] ^ c[29] ^ c[30] ^ c[31];
        newcrc[7]   <= #TCQ d[7] ^ d[5] ^ d[3] ^ d[2] ^ d[0] ^ c[24] ^ c[26] ^ c[27] ^ c[29] ^ c[31];
        newcrc[8]   <= #TCQ d[4] ^ d[3] ^ d[1] ^ d[0] ^ c[0] ^ c[24] ^ c[25] ^ c[27] ^ c[28];
        newcrc[9]   <= #TCQ d[5] ^ d[4] ^ d[2] ^ d[1] ^ c[1] ^ c[25] ^ c[26] ^ c[28] ^ c[29];
        newcrc[10]  <= #TCQ d[5] ^ d[3] ^ d[2] ^ d[0] ^ c[2] ^ c[24] ^ c[26] ^ c[27] ^ c[29];
        newcrc[11]  <= #TCQ d[4] ^ d[3] ^ d[1] ^ d[0] ^ c[3] ^ c[24] ^ c[25] ^ c[27] ^ c[28];
        newcrc[12]  <= #TCQ d[6] ^ d[5] ^ d[4] ^ d[2] ^ d[1] ^ d[0] ^ c[4] ^ c[24] ^ c[25] ^ c[26] ^ c[28] ^ c[29] ^ c[30];
        newcrc[13]  <= #TCQ d[7] ^ d[6] ^ d[5] ^ d[3] ^ d[2] ^ d[1] ^ c[5] ^ c[25] ^ c[26] ^ c[27] ^ c[29] ^ c[30] ^ c[31];
        newcrc[14]  <= #TCQ d[7] ^ d[6] ^ d[4] ^ d[3] ^ d[2] ^ c[6] ^ c[26] ^ c[27] ^ c[28] ^ c[30] ^ c[31];
        newcrc[15]  <= #TCQ d[7] ^ d[5] ^ d[4] ^ d[3] ^ c[7] ^ c[27] ^ c[28] ^ c[29] ^ c[31];
        newcrc[16]  <= #TCQ d[5] ^ d[4] ^ d[0] ^ c[8] ^ c[24] ^ c[28] ^ c[29];
        newcrc[17]  <= #TCQ d[6] ^ d[5] ^ d[1] ^ c[9] ^ c[25] ^ c[29] ^ c[30];
        newcrc[18]  <= #TCQ d[7] ^ d[6] ^ d[2] ^ c[10] ^ c[26] ^ c[30] ^ c[31];
        newcrc[19]  <= #TCQ d[7] ^ d[3] ^ c[11] ^ c[27] ^ c[31];
        newcrc[20]  <= #TCQ d[4] ^ c[12] ^ c[28];
        newcrc[21]  <= #TCQ d[5] ^ c[13] ^ c[29];
        newcrc[22]  <= #TCQ d[0] ^ c[14] ^ c[24];
        newcrc[23]  <= #TCQ d[6] ^ d[1] ^ d[0] ^ c[15] ^ c[24] ^ c[25] ^ c[30];
        newcrc[24]  <= #TCQ d[7] ^ d[2] ^ d[1] ^ c[16] ^ c[25] ^ c[26] ^ c[31];
        newcrc[25]  <= #TCQ d[3] ^ d[2] ^ c[17] ^ c[26] ^ c[27];
        newcrc[26]  <= #TCQ d[6] ^ d[4] ^ d[3] ^ d[0] ^ c[18] ^ c[24] ^ c[27] ^ c[28] ^ c[30];
        newcrc[27]  <= #TCQ d[7] ^ d[5] ^ d[4] ^ d[1] ^ c[19] ^ c[25] ^ c[28] ^ c[29] ^ c[31];
        newcrc[28]  <= #TCQ d[6] ^ d[5] ^ d[2] ^ c[20] ^ c[26] ^ c[29] ^ c[30];
        newcrc[29]  <= #TCQ d[7] ^ d[6] ^ d[3] ^ c[21] ^ c[27] ^ c[30] ^ c[31];
        newcrc[30]  <= #TCQ d[7] ^ d[4] ^ c[22] ^ c[28] ^ c[31];
        newcrc[31]  <= #TCQ d[5] ^ c[23] ^ c[29];
    end
end

reg r_out_valid = 0; 

always @(posedge clk_i)begin //输入数据在一个时钟内完成CRC计算，下一个时钟输出；
    r_out_valid <= #TCQ data_in_vaild;
end

assign CRC_out_vaild = r_out_valid;
assign CRC_out       = newcrc ;

endmodule