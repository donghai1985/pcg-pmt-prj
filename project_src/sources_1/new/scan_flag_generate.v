`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: zas
// Engineer: songyuxin
// 
// Create Date: 2024/2/26
// Design Name: PCG
// Module Name: scan_flag_generate
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


module scan_flag_generate #(
    parameter           TCQ         = 0.1   
)(
    // clk & rst
    input   wire        clk_i               ,
    input   wire        rst_i               ,
    input   wire        aurora_clk_i        ,

    input   wire        adc_start_en_i      ,
    input   wire        adc_end_en_i        ,
    output  wire        aurora_adc_start_o  ,
    output  wire        real_pmt_scan_o        
);


//////////////////////////////////////////////////////////////////////////////////
// *********** Define Parameter Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>


//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Register Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
reg                     pmt_scan_en         = 'd0;

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Wire Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
wire                    adc_end_sync ;
wire                    vio_scan_start_flag ;
wire                    vio_scan_test_flag  ;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Instance Module
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

 xpm_cdc_single #(
    .DEST_SYNC_FF(2),   // DECIMAL; range: 2-10
    .INIT_SYNC_FF(0),   // DECIMAL; 0=disable simulation init values, 1=enable simulation init values
    .SIM_ASSERT_CHK(0), // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
    .SRC_INPUT_REG(0)   // DECIMAL; 0=do not register input, 1=register input
 )
 xpm_cdc_single_inst (
    .dest_out(aurora_adc_start_o), // 1-bit output: src_in synchronized to the destination clock domain. This output is
                         // registered.

    .dest_clk(aurora_clk_i), // 1-bit input: Clock signal for the destination clock domain.
    .src_clk(clk_i),   // 1-bit input: optional; required when SRC_INPUT_REG = 1
    .src_in(adc_start_en_i)      // 1-bit input: Input signal to be synchronized to dest_clk domain.
 );

 xpm_cdc_pulse #(
    .DEST_SYNC_FF(2),   // DECIMAL; range: 2-10
    .INIT_SYNC_FF(0),   // DECIMAL; 0=disable simulation init values, 1=enable simulation init values
    .REG_OUTPUT(0),     // DECIMAL; 0=disable registered output, 1=enable registered output
    .RST_USED(0),       // DECIMAL; 0=no reset, 1=implement reset
    .SIM_ASSERT_CHK(0)  // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
 )
 xpm_cdc_pulse_inst (
    .dest_pulse(adc_end_sync), // 1-bit output: Outputs a pulse the size of one dest_clk period when a pulse
                             // transfer is correctly initiated on src_pulse input. This output is
                             // combinatorial unless REG_OUTPUT is set to 1.

    .dest_clk(clk_i),     // 1-bit input: Destination clock.
    .dest_rst(0),     // 1-bit input: optional; required when RST_USED = 1
    .src_clk(aurora_clk_i),       // 1-bit input: Source clock.
    .src_pulse(adc_end_en_i),   // 1-bit input: Rising edge of this signal initiates a pulse transfer to the
                             // destination clock domain. The minimum gap between each pulse transfer must be
                             // at the minimum 2*(larger(src_clk period, dest_clk period)). This is measured
                             // between the falling edge of a src_pulse to the rising edge of the next
                             // src_pulse. This minimum gap will guarantee that each rising edge of src_pulse
                             // will generate a pulse the size of one dest_clk period in the destination
                             // clock domain. When RST_USED = 1, pulse transfers will not be guaranteed while
                             // src_rst and/or dest_rst are asserted.

    .src_rst(0)        // 1-bit input: optional; required when RST_USED = 1
 );

 
// vio_scan_dbg vio_scan_dbg_inst (
//     .clk(clk_i),                // input wire clk
//     .probe_out0(vio_scan_start_flag),  // output wire [0 : 0] probe_out0
//     .probe_out1(vio_scan_test_flag)  // output wire [0 : 0] probe_out1
// );
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Logic Design
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
always @(posedge clk_i) begin
    if(adc_start_en_i)
        pmt_scan_en <= #TCQ 'd1;
    else if(adc_end_sync)
        pmt_scan_en <= #TCQ 'd0;
end

assign real_pmt_scan_o = pmt_scan_en;


//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


endmodule
