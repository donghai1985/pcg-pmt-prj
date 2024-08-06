`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: zas
// Engineer: songyuxin
// 
// Create Date: 2023/7/06
// Design Name: PCG
// Module Name: serial_tx
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


module serial_tx #(
    parameter                               TCQ         = 0.1   ,
    parameter                               DATA_WIDTH  = 32    ,
    parameter                               SERIAL_MODE = 2       // =1\2\4\8
)(
    // clk & rst
    input   wire                            clk_i               ,
    input   wire                            rst_i               ,
    input   wire                            clk_200m_i          ,

    input   wire                            tx_valid_i          ,
    output  wire                            tx_ready_o          ,
    input   wire   [DATA_WIDTH-1:0]         tx_data_i           ,

    // spi info
    output  wire                            TX_CLK              ,
    output  wire   [SERIAL_MODE-1:0]        TX_DOUT              
);


//////////////////////////////////////////////////////////////////////////////////
// *********** Define Parameter Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
localparam          SERIAL_NUM          = DATA_WIDTH/SERIAL_MODE;
localparam          SERIAL_CNT_WIDTH    = $clog2(SERIAL_NUM);

localparam          CLK_REF_NUM         = 1;  // 200M --> 50M

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Register Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
reg                                     ready           = 'd1;
reg                                     tx_en           = 'd0;
reg     [2:0]                           colck_cnt       = 'd0;
reg                                     colck_r         = 'd0;
reg                                     colck_r_d       = 'd0;
reg     [SERIAL_CNT_WIDTH-1:0]          serial_cnt      = 'd0;
reg     [SERIAL_MODE-1:0]               tx_dout_r       = 'd0;

reg                                     tx_fifo_rd_en   = 'd0;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<



//////////////////////////////////////////////////////////////////////////////////
// *********** Define Wire Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
wire                                    colck_pose      ;
wire                                    colck_nege      ;

wire                                    tx_done         ;
// wire                                    tx_en           ;

wire    [DATA_WIDTH-1:0]                tx_fifo_dout        ;
wire                                    tx_fifo_almost_full ;
wire                                    tx_fifo_full        ;
wire                                    tx_fifo_empty       ;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<





//////////////////////////////////////////////////////////////////////////////////
// *********** Instance Module
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
xpm_async_fifo #(
    .ECC_MODE                   ( "no_ecc"                      ),
    .FIFO_MEMORY_TYPE           ( "distributed"                 ),
    .READ_MODE                  ( "std"                         ),
    .FIFO_WRITE_DEPTH           ( 32                            ),
    .WRITE_DATA_WIDTH           ( DATA_WIDTH                    ),
    .READ_DATA_WIDTH            ( DATA_WIDTH                    ),
    .RELATED_CLOCKS             ( 1                             ), // write clk same source of read clk
    .USE_ADV_FEATURES           ( "0008"                        )
)spi_async_fifo_inst (
    .wr_clk_i                   ( clk_i                         ),
    .rst_i                      ( rst_i                         ), // synchronous to wr_clk
    .wr_en_i                    ( tx_valid_i                    ),
    .wr_data_i                  ( tx_data_i                     ),
    .fifo_almost_full_o         ( tx_fifo_almost_full           ),

    .rd_clk_i                   ( clk_200m_i                    ),
    .rd_en_i                    ( ready && tx_fifo_rd_en        ),
    .fifo_rd_data_o             ( tx_fifo_dout                  ),
    .fifo_empty_o               ( tx_fifo_empty                 )
);
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


//////////////////////////////////////////////////////////////////////////////////
// *********** Logic Design
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
// reg tx_fifo_vld = 'd0;
// always @(posedge clk_200m_i) begin
//     tx_fifo_vld <= #TCQ ready && tx_fifo_rd_en;
// end


always @(posedge clk_200m_i) begin
    if(rst_i)
        tx_fifo_rd_en <= #TCQ 'd0;
    else if(~tx_fifo_empty && ready)
        tx_fifo_rd_en <= #TCQ 'd1;
    else 
        tx_fifo_rd_en <= #TCQ 'd0;
end


assign colck_nege   = colck_r_d  && ~colck_r;
assign colck_pose   = ~colck_r_d && colck_r;
assign tx_done      = &serial_cnt && colck_pose;
// assign tx_en        = ~ready;

always @(posedge clk_200m_i) begin
    if(rst_i)
        ready <= #TCQ 'd1;
    else if(ready && tx_fifo_rd_en)
        ready <= #TCQ 'd0;
    else if(tx_en && tx_done)
        ready <= #TCQ 'd1;
end

always @(posedge clk_200m_i) begin
    tx_en <= #TCQ ~ready;
end

always @(posedge clk_200m_i) begin
    if(tx_en)begin
        if(colck_cnt == CLK_REF_NUM)begin
            colck_cnt   <= #TCQ 'd0;
            colck_r     <= #TCQ ~colck_r;
        end
        else begin
            colck_cnt   <= #TCQ colck_cnt + 1;
            colck_r     <= #TCQ colck_r;
        end
    end
    else begin
        colck_cnt   <= #TCQ 'd0;
        colck_r     <= #TCQ 'd0;
    end
end

always @(posedge clk_200m_i) begin
    colck_r_d <= #TCQ colck_r;
end

always @(posedge clk_200m_i) begin
    if(tx_en)begin
        if(colck_pose)begin
            serial_cnt <= #TCQ serial_cnt + 1;
        end 
    end 
    else begin
        serial_cnt  <= #TCQ 'd0;
    end
end

always @(posedge clk_200m_i) begin
    if(tx_en)
        tx_dout_r <= #TCQ tx_fifo_dout[(SERIAL_NUM - 1 - serial_cnt)*SERIAL_MODE +: SERIAL_MODE];    // 大端对齐 
end

assign tx_ready_o = ~tx_fifo_almost_full;
assign TX_CLK     = colck_r;
assign TX_DOUT    = tx_dout_r;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


endmodule
