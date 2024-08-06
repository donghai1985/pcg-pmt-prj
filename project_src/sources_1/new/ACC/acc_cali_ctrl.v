`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: zas
// Engineer: songyuxin
// 
// Create Date: 2024/3/11
// Design Name: PCG
// Module Name: acc_cali_ctrl
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


module acc_cali_ctrl #(
    parameter                       TCQ               = 0.1 ,
    parameter                       DATA_WIDTH        = 16  
)(
    // clk & rst 
    input                           clk_i                   ,
    input                           rst_i                   ,

    input                           laser_start_i           ,
    input                           acc_cali_mode_i         ,
    input   [32-1:0]                acc_cali_low_i          ,
    input   [32-1:0]                acc_cali_high_i         ,

    output                          acc_cali_ctrl_o         
);

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Register Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
reg         [32-1:0]                cali_ctrl_low_cnt   = 'd0;
reg         [32-1:0]                cali_ctrl_high_cnt  = 'd0;
reg                                 cali_ctrl_flag      = 'd0;


//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Wire Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>




//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Instance Module
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Logic Design
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

always @(posedge clk_i) begin
    if(~laser_start_i)
        cali_ctrl_low_cnt <= #TCQ 'd0;
    else if(~cali_ctrl_flag)
        cali_ctrl_low_cnt <= #TCQ cali_ctrl_low_cnt + 1;
    else 
        cali_ctrl_low_cnt <= #TCQ 'd0;
end

always @(posedge clk_i) begin
    if(~laser_start_i)
        cali_ctrl_high_cnt <= #TCQ 'd0;
    else if(cali_ctrl_flag)
        cali_ctrl_high_cnt <= #TCQ cali_ctrl_high_cnt + 1;
    else 
        cali_ctrl_high_cnt <= #TCQ 'd0;
end


always @(posedge clk_i) begin
    if(acc_cali_mode_i)begin
        if(~laser_start_i)
            cali_ctrl_flag <= #TCQ 'd0;
        else if((cali_ctrl_low_cnt == acc_cali_low_i) && (~cali_ctrl_flag))
            cali_ctrl_flag <= #TCQ 'd1;
        else if((cali_ctrl_high_cnt == acc_cali_high_i) && (cali_ctrl_flag))
            cali_ctrl_flag <= #TCQ 'd0;
    end
    else 
        cali_ctrl_flag <= #TCQ 'd0;
end


assign acc_cali_ctrl_o = cali_ctrl_flag;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


endmodule
