`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/05/30
// Design Name: 
// Module Name: command_map
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
// `define FBC_OFF


module command_map #(
    parameter                   TCQ           = 0.1,
    parameter                   COMMAND_WIDTH = 16,
    parameter                   COMMAND_LENG  = 16

)(
    // clk & rst
    input   wire                clk_sys_i               ,
    input   wire                rst_i                   ,
    // ethernet interface for message data
    input   wire                slave_rx_data_vld_i     ,
    input   wire    [7:0]       slave_rx_data_i         ,

    // readback ddr
    output  wire    [32-1:0]    ddr_rd_addr_o           ,
    output  wire                ddr_rd_en_o             ,
    // write fir tap
    output  wire                fir_tap_wr_cmd_o        ,
    output  wire                fir_tap_wr_vld_o        ,
    output  wire    [32-1:0]    fir_tap_wr_data_o       ,

    output  wire                raw_adc_cfg_o           ,

    output  wire                debug_info
);


//////////////////////////////////////////////////////////////////////////////////
// *********** Define Parameter Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>






//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Register Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
reg     [16-1:0]                command_sel                 = 'd0;
reg                             command_state               = 'd0;
reg     [COMMAND_LENG-1:0]      command_addr                = 'd0;
reg     [32-1:0]                command_data                = 'd0;
reg                             slave_rx_data_vld_d         = 'd0;


reg     [32-1:0]                ddr_rd_addr                 = 'd0;
reg                             ddr_rd_en                   = 'd0;
reg                             fir_tap_wr_cmd              = 'd0;
reg     [32-1:0]                fir_tap_wr_addr             = 'd0;
reg                             fir_tap_wr_vld              = 'd0;
reg     [32-1:0]                fir_tap_wr_data             = 'd0;
reg                             fir_tap_wr_state            = 'd0;

reg                             raw_adc_cfg                 = 'd0;

reg     [32-1:0]                readback_reg                = 'd0;
reg                             readback_en                 = 'd0;
reg     [2-1:0]                 readback_cnt                = 'd2;
reg     [32-1:0]                register_data               = 'd0;
reg     [64-1:0]                readback_data               = 'd0;
reg                             readback_vld                = 'd0;

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Wire Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
wire                            slave_rx_start  ;
wire                            command_en      ;
wire    [COMMAND_WIDTH-1:0]     command         ;
wire                            command_data_vld;


//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Instance Module
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Logic Design
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
// check command and command data 
always @(posedge clk_sys_i) command_data        <= #TCQ {command_data[23:0],slave_rx_data_i[7:0]};
always @(posedge clk_sys_i) slave_rx_data_vld_d <= #TCQ slave_rx_data_vld_i;

assign slave_rx_start = ~slave_rx_data_vld_d && slave_rx_data_vld_i;

always @(posedge clk_sys_i) begin
    if(slave_rx_start || command_en)begin
        command_addr <= #TCQ 'd0;
    end
    else if(slave_rx_data_vld_d)begin
        command_addr <= #TCQ command_addr + 1;
    end
end

assign command_en   = (command_addr=='d1) && slave_rx_data_vld_d && (~command_state);
assign command      = command_data[15:0];

always @(posedge clk_sys_i) begin
    if(slave_rx_data_vld_i)begin
        if(command_en) 
            command_state <= #TCQ 'd1;
    end
    else begin
        command_state <= #TCQ 'd0;
    end
end

assign command_data_vld = (command_addr[1:0]=='b11) && command_state;

always @(posedge clk_sys_i) begin
    if(command_en)begin
        command_sel <= #TCQ command[15:0];
    end
end

// write FIR tap command
always @(posedge clk_sys_i) begin
    if(~command_state)
        fir_tap_wr_state <= #TCQ 'd0;
    else if(command_sel=='h1000 && command_data_vld)begin
        fir_tap_wr_state <= #TCQ 'd1;
    end
end

// always @(posedge clk_sys_i) begin
//     if((~fir_tap_wr_state) && (command_sel=='h1000) && command_data_vld)begin
//         // fir_tap_wr_cmd <= #TCQ 'd1;
//         fir_tap_wr_addr <= #TCQ command_data;
//     end
// end

always @(posedge clk_sys_i) begin
    if((command_sel=='h1000) && command_data_vld)begin
        fir_tap_wr_vld  <= #TCQ 'd1;
        fir_tap_wr_data <= #TCQ command_data;
    end
    else begin
        fir_tap_wr_vld  <= #TCQ 'd0;
    end
end

// readback DDR cmmand
always @(posedge clk_sys_i) begin
    if(command_sel=='h1001 && command_data_vld)begin
        ddr_rd_addr <= #TCQ command_data;
        ddr_rd_en   <= #TCQ 'd1;
    end
    else begin
        ddr_rd_en   <= #TCQ 'd0;
    end
end

// raw adc data up config
always @(posedge clk_sys_i) begin
    if((command_sel=='h1003) && command_data_vld)begin
        raw_adc_cfg <= #TCQ command_data[0];
    end
end

assign ddr_rd_addr_o            = ddr_rd_addr           ;
assign ddr_rd_en_o              = ddr_rd_en             ;
assign fir_tap_wr_cmd_o         = command_state && (command_sel=='h1000)      ;
assign fir_tap_wr_vld_o         = fir_tap_wr_vld        ;
assign fir_tap_wr_data_o        = fir_tap_wr_data       ;
assign raw_adc_cfg_o            = raw_adc_cfg           ;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

endmodule
