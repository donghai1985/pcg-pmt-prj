`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/05/15
// Design Name: 
// Module Name: track_para_ctrl_sim
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
// `define CONFIG_FPGA_SIM

module track_para_ctrl_sim #(
    parameter                       TCQ             = 0.1
)(
    // clk & rst
    input                       clk_i                   ,
    input                       rst_i                   ,

    input                       laser_start_i           ,
    input                       track_para_en_i         ,
    input                       laser_zero_flag_i       ,

    output                      track_para_burst_end_o  ,
    output                      track_para_vld_o        ,
    output      [32-1:0]        track_para_data_o       ,
    input                       track_para_ren_i        
    
);


//////////////////////////////////////////////////////////////////////////////////
// *********** Define Parameter Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
localparam                  ST_IDLE         = 3'd0;
localparam                  ST_BYTE         = 3'd1;
localparam                  ST_UDP          = 3'd2;
localparam                  ST_FINISH       = 3'd3;
localparam                  ST_CFG_HEAD     = 3'd4;
localparam                  ST_CFG_LOAD     = 3'd5;
localparam                  ST_CFG_PKG_NUM  = 3'd6;
localparam                  ST_CFG_FINISH   = 3'd7;

localparam                  UDP_NUM         = 'd128;
localparam                  CFG_DATA_NUM    = 'd1024;
localparam                  CFG_PKG_NUM     = 'd14;

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Register Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

reg [ 3-1:0]                state               = ST_IDLE;
reg [ 3-1:0]                state_next          = ST_IDLE;

reg [32-1:0]                st_wait_cnt         = 'd0;
reg [32-1:0]                st_finish_wait_cnt  = 'd0;

reg [16-1:0]                msg_data_count      = 'd0;
reg                         msg_data_en_r       = 'd0;
reg [32-1:0]                msg_data_r          = 'd0;
reg [32-1:0]                fir_tap_pack        = 'd0;

reg [16-1:0]                rec_cfg_pkg_num_r   = 'd1;
reg [16-1:0]                cfg_data_count      = 'd0;

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
    if(rst_i)
        st_wait_cnt <= #TCQ 'd0;
    else if(state==ST_IDLE)begin
        st_wait_cnt <= #TCQ st_wait_cnt + 1;
    end
    else begin
        st_wait_cnt <= #TCQ 'd0;
    end
end

always @(posedge clk_i) begin
    if(state==ST_FINISH)begin
        st_finish_wait_cnt <= #TCQ st_finish_wait_cnt + 1;
    end
    else begin
        st_finish_wait_cnt <= #TCQ 'd0;
    end
end

reg track_para_en_d = 'd0;
reg laser_start_d   = 'd0;
always @(posedge clk_i) begin
    track_para_en_d <= #TCQ track_para_en_i;
    laser_start_d   <= #TCQ laser_start_i;
end

always @(posedge clk_i) begin
    if(rst_i)
        state <= #TCQ ST_IDLE;
    else 
        state <= #TCQ state_next;
end

always @(*) begin
    state_next = state;
    case(state)
    ST_IDLE:
        if(((~track_para_en_d) && track_para_en_i) || laser_zero_flag_i || ((~laser_start_d) && laser_start_i))
            state_next = ST_BYTE;
    ST_BYTE :
            state_next = ST_UDP;
    ST_UDP :
        if(msg_data_count==UDP_NUM-1)
            state_next = ST_FINISH;
    ST_FINISH :
        if(st_finish_wait_cnt=='d100)
            state_next = ST_IDLE;
    
    default:
            state_next = ST_IDLE;
    endcase
end

always @(posedge clk_i ) begin
    if(state==ST_UDP)
        msg_data_count <= #TCQ msg_data_count + 1;
    else 
        msg_data_count <= #TCQ 'd0;
end

reg [32-1:0] ds_para_h = 'h40020001;
reg [32-1:0] ds_para_l = 'h02e91582;

reg [32-1:0] mem [0:127];
initial begin
    $display("read csv file");
    $readmemh("D:/work/FIR/20240416150925_transpose.csv",mem);
end

always @(posedge clk_i) begin
    if(state==ST_UDP)begin
        // case(msg_data_count)
        // 'd0 : begin 
            msg_data_r      <= #TCQ mem[msg_data_count];
            msg_data_en_r   <= #TCQ 'd1;
        // end
        // default : begin
        //     msg_data_r      <= #TCQ 'h05050505;
        //     msg_data_en_r   <= #TCQ 'd1;
        // end
        // endcase
    end
    else 
        msg_data_en_r <= #TCQ 'd0;
end


// always @(posedge clk_i) begin
//     if(state==ST_FINISH && state_next==ST_IDLE && (fir_tap_pack < 128))
//         fir_tap_pack <= #TCQ fir_tap_pack + 1;
// end

// assign fir_tap_wr_cmd_o  = state==ST_UDP;
// assign fir_tap_wr_addr_o = fir_tap_pack;
assign fir_tap_wr_vld_o  = msg_data_en_r;
assign fir_tap_wr_data_o = msg_data_r;

xpm_sync_fifo #(
    .ECC_MODE                   ( "no_ecc"                      ),
    .FIFO_MEMORY_TYPE           ( "block"                       ), // "auto" "block" "distributed"
    .READ_MODE                  ( "std"                         ),
    .FIFO_WRITE_DEPTH           ( 128                           ),
    .WRITE_DATA_WIDTH           ( 32                            ),
    .READ_DATA_WIDTH            ( 32                            ),
    .USE_ADV_FEATURES           ( "1808"                        )
)u_xpm_sync_fifo (
    .wr_clk_i                   ( clk_i                         ),
    .rst_i                      ( rst_i                         ), // synchronous to wr_clk
    .wr_en_i                    ( msg_data_en_r                 ),
    .wr_data_i                  ( msg_data_r                    ),

    .rd_en_i                    ( track_para_ren_i              ),
    .fifo_rd_vld_o              ( track_para_vld_o              ),
    .fifo_rd_data_o             ( track_para_data_o             )
);

assign track_para_burst_end_o = (state_next == ST_IDLE) && (state == ST_FINISH);
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


endmodule
