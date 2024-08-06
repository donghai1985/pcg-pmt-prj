`timescale 1ns/1ps
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
/***********
xpm_async_fifo #(
    .ECC_MODE                   ( "no_ecc"                      ),
    .FIFO_MEMORY_TYPE           ( "block"                       ), // "auto" "block" "distributed"
    .READ_MODE                  ( "std"                         ),
    .FIFO_WRITE_DEPTH           ( 64                            ),
    .WRITE_DATA_WIDTH           ( 32                            ),
    .READ_DATA_WIDTH            ( 32                            ),
    .RELATED_CLOCKS             ( 1                             ), // write clk same source of read clk
    .USE_ADV_FEATURES           ( "1808"                        )
)u_xpm_async_fifo (
    .wr_clk_i                   ( wr_clk_i                      ),
    .rst_i                      ( rst_i                         ), // synchronous to wr_clk
    .wr_en_i                    ( wr_en_i                       ),
    .wr_data_i                  ( wr_data_i                     ),
    .fifo_full_o                ( fifo_full_o                   ),
    .fifo_almost_full_o         ( fifo_almost_full_o            ),
    .fifo_prog_full_o           ( fifo_prog_full_o              ),

    .rd_clk_i                   ( rd_clk_i                      ),
    .rd_en_i                    ( rd_en_i                       ),
    .fifo_rd_vld_o              ( fifo_rd_vld_o                 ),
    .fifo_rd_data_o             ( fifo_rd_data_o                ),
    .fifo_empty_o               ( fifo_empty_o                  ),
    .fifo_almost_empty_o        ( fifo_almost_empty_o           ),
    .fifo_prog_empty_o          ( fifo_prog_empty_o             )
);
************/
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
// 
// Setting USE_ADV_FEATURES[0] to 1 enables overflow flag; Default value of this bit is 0
// Setting USE_ADV_FEATURES[1] to 1 enables prog_full flag; Default value of this bit is 0
// Setting USE_ADV_FEATURES[2] to 1 enables wr_data_count; Default value of this bit is 0
// Setting USE_ADV_FEATURES[3] to 1 enables almost_full flag; Default value of this bit is 1
// Setting USE_ADV_FEATURES[4] to 1 enables wr_ack flag; Default value of this bit is 0
//
// Setting USE_ADV_FEATURES[8] to 1 enables underflow flag; Default value of this bit is 0
// Setting USE_ADV_FEATURES[9] to 1 enables prog_empty flag; Default value of this bit is 0
// Setting USE_ADV_FEATURES[10] to 1 enables rd_data_count; Default value of this bit is 0
// Setting USE_ADV_FEATURES[11] to 1 enables almost_empty flag; Default value of this bit is 1
// Setting USE_ADV_FEATURES[12] to 1 enables data_valid flag; Default value of this bit is 1
//
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////



module xpm_async_fifo#(
    parameter           ECC_MODE            = "no_ecc"  ,
    parameter           FIFO_MEMORY_TYPE    = "block"   , // "auto" "block" "distributed"
    parameter           FIFO_READ_LATENCY   = 1         , // Number of output register stages in the read data path.
    parameter           READ_MODE           = "std"     , // "std":READ_MODE_VAL==0; "fwft":READ_MODE_VAL==1   
    parameter           FIFO_WRITE_DEPTH    = 16        , // must be power of two, min 2**4
    parameter           FULL_RESET_VALUE    = 1         , // Sets full, almost_full and prog_full to FULL_RESET_VALUE during reset.
    parameter           PROG_EMPTY_THRESH   = 5         , // Min_Value = 3 + (READ_MODE_VAL*2); Max_Value = (FIFO_WRITE_DEPTH-3) - (READ_MODE_VAL*2)
    parameter           PROG_FULL_THRESH    = 11        , // Min_Value = 3 + (READ_MODE_VAL*2*(FIFO_WRITE_DEPTH/FIFO_READ_DEPTH))+CDC_SYNC_STAGES; Max_Value = (FIFO_WRITE_DEPTH-3) - (READ_MODE_VAL*2*(FIFO_WRITE_DEPTH/FIFO_READ_DEPTH))
    parameter           WRITE_DATA_WIDTH    = 32        , // Write and read width aspect ratio must be 1:1, 1:2, 1:4, 1:8, 8:1, 4:1 and 2:1
    parameter           READ_DATA_WIDTH     = 32        , // Write and read width aspect ratio must be 1:1, 1:2, 1:4, 1:8, 8:1, 4:1 and 2:1
    parameter           RELATED_CLOCKS      = 1         , // 0:wr_clk and rd_clk are different source. 1: wr_clk and rd_clk have the same source.
    parameter           USE_ADV_FEATURES    = "1808"    

)(
    input                                   wr_clk_i                ,
    input                                   rst_i                   , // synchronous to wr_clk
    input                                   wr_en_i                 ,
    input   [WRITE_DATA_WIDTH-1:0]          wr_data_i               ,
    output                                  fifo_full_o             ,
    output                                  fifo_almost_full_o      ,
    output                                  fifo_prog_full_o        ,

    input                                   rd_clk_i                ,
    input                                   rd_en_i                 ,
    output                                  fifo_rd_vld_o           ,
    output  [READ_DATA_WIDTH-1:0]           fifo_rd_data_o          ,
    output                                  fifo_empty_o            ,
    output                                  fifo_almost_empty_o     ,
    output                                  fifo_prog_empty_o       

);

localparam              FIFO_READ_DEPTH     = FIFO_WRITE_DEPTH*WRITE_DATA_WIDTH/READ_DATA_WIDTH;
localparam              RD_DATA_COUNT_WIDTH = $clog2(FIFO_READ_DEPTH) + 1;
localparam              WR_DATA_COUNT_WIDTH = $clog2(FIFO_WRITE_DEPTH) + 1;

wire    [WR_DATA_COUNT_WIDTH-1:0]           wr_data_count;
wire    [RD_DATA_COUNT_WIDTH-1:0]           rd_data_count;


generate 
    if(READ_MODE == "fwft") begin : fwft_async_fifo 
        xpm_fifo_async #(
            .CASCADE_HEIGHT(0),        // DECIMAL
            .CDC_SYNC_STAGES(2),       // DECIMAL
            .DOUT_RESET_VALUE("0"),    // String
            .ECC_MODE(ECC_MODE),       // String
            .FIFO_MEMORY_TYPE(FIFO_MEMORY_TYPE), // String
            .FIFO_READ_LATENCY(0),     // DECIMAL
            .FIFO_WRITE_DEPTH(FIFO_WRITE_DEPTH),   // DECIMAL
            .FULL_RESET_VALUE(FULL_RESET_VALUE),      // DECIMAL
            .PROG_EMPTY_THRESH(PROG_EMPTY_THRESH),    // DECIMAL
            .PROG_FULL_THRESH(PROG_FULL_THRESH),     // DECIMAL
            .RD_DATA_COUNT_WIDTH(RD_DATA_COUNT_WIDTH),   // DECIMAL
            .READ_DATA_WIDTH(READ_DATA_WIDTH),      // DECIMAL
            .READ_MODE(READ_MODE),         // String
            .RELATED_CLOCKS(RELATED_CLOCKS),        // DECIMAL
            .SIM_ASSERT_CHK(0),        // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
            .USE_ADV_FEATURES(USE_ADV_FEATURES), // String
            .WAKEUP_TIME(0),           // DECIMAL
            .WRITE_DATA_WIDTH(WRITE_DATA_WIDTH),     // DECIMAL
            .WR_DATA_COUNT_WIDTH(WR_DATA_COUNT_WIDTH)    // DECIMAL
         )
         xpm_fifo_async_inst (
            .almost_empty(fifo_almost_empty_o),   // 1-bit output: Almost Empty : When asserted, this signal indicates that
                                           // only one more read can be performed before the FIFO goes to empty.

            .almost_full(fifo_almost_full_o),     // 1-bit output: Almost Full: When asserted, this signal indicates that
                                           // only one more write can be performed before the FIFO is full.

            .data_valid(fifo_rd_vld_o),       // 1-bit output: Read Data Valid: When asserted, this signal indicates
                                           // that valid data is available on the output bus (dout).

            .dbiterr(dbiterr),             // 1-bit output: Double Bit Error: Indicates that the ECC decoder detected
                                           // a double-bit error and data in the FIFO core is corrupted.

            .dout(fifo_rd_data_o),                   // READ_DATA_WIDTH-bit output: Read Data: The output data bus is driven
                                           // when reading the FIFO.

            .empty(fifo_empty_o),                 // 1-bit output: Empty Flag: When asserted, this signal indicates that the
                                           // FIFO is empty. Read requests are ignored when the FIFO is empty,
                                           // initiating a read while empty is not destructive to the FIFO.

            .full(fifo_full_o),                   // 1-bit output: Full Flag: When asserted, this signal indicates that the
                                           // FIFO is full. Write requests are ignored when the FIFO is full,
                                           // initiating a write when the FIFO is full is not destructive to the
                                           // contents of the FIFO.

            .overflow(overflow),           // 1-bit output: Overflow: This signal indicates that a write request
                                           // (wren) during the prior clock cycle was rejected, because the FIFO is
                                           // full. Overflowing the FIFO is not destructive to the contents of the
                                           // FIFO.

            .prog_empty(fifo_prog_empty_o),       // 1-bit output: Programmable Empty: This signal is asserted when the
                                           // number of words in the FIFO is less than or equal to the programmable
                                           // empty threshold value. It is de-asserted when the number of words in
                                           // the FIFO exceeds the programmable empty threshold value.

            .prog_full(fifo_prog_full_o),         // 1-bit output: Programmable Full: This signal is asserted when the
                                           // number of words in the FIFO is greater than or equal to the
                                           // programmable full threshold value. It is de-asserted when the number of
                                           // words in the FIFO is less than the programmable full threshold value.

            .rd_data_count(rd_data_count), // RD_DATA_COUNT_WIDTH-bit output: Read Data Count: This bus indicates the
                                           // number of words read from the FIFO.

            .rd_rst_busy(rd_rst_busy),     // 1-bit output: Read Reset Busy: Active-High indicator that the FIFO read
                                           // domain is currently in a reset state.

            .sbiterr(sbiterr),             // 1-bit output: Single Bit Error: Indicates that the ECC decoder detected
                                           // and fixed a single-bit error.

            .underflow(underflow),         // 1-bit output: Underflow: Indicates that the read request (rd_en) during
                                           // the previous clock cycle was rejected because the FIFO is empty. Under
                                           // flowing the FIFO is not destructive to the FIFO.

            .wr_ack(wr_ack),               // 1-bit output: Write Acknowledge: This signal indicates that a write
                                           // request (wr_en) during the prior clock cycle is succeeded.

            .wr_data_count(wr_data_count), // WR_DATA_COUNT_WIDTH-bit output: Write Data Count: This bus indicates
                                           // the number of words written into the FIFO.

            .wr_rst_busy(wr_rst_busy),     // 1-bit output: Write Reset Busy: Active-High indicator that the FIFO
                                           // write domain is currently in a reset state.

            .din(wr_data_i),                     // WRITE_DATA_WIDTH-bit input: Write Data: The input data bus used when
                                           // writing the FIFO.

            .injectdbiterr(injectdbiterr), // 1-bit input: Double Bit Error Injection: Injects a double bit error if
                                           // the ECC feature is used on block RAMs or UltraRAM macros.

            .injectsbiterr(injectsbiterr), // 1-bit input: Single Bit Error Injection: Injects a single bit error if
                                           // the ECC feature is used on block RAMs or UltraRAM macros.

            .rd_clk(rd_clk_i),               // 1-bit input: Read clock: Used for read operation. rd_clk must be a free
                                           // running clock.

            .rd_en(rd_en_i),                 // 1-bit input: Read Enable: If the FIFO is not empty, asserting this
                                           // signal causes data (on dout) to be read from the FIFO. Must be held
                                           // active-low when rd_rst_busy is active high.

            .rst(rst_i),                     // 1-bit input: Reset: Must be synchronous to wr_clk. The clock(s) can be
                                           // unstable at the time of applying reset, but reset must be released only
                                           // after the clock(s) is/are stable.

            .sleep(sleep),                 // 1-bit input: Dynamic power saving: If sleep is High, the memory/fifo
                                           // block is in power saving mode.

            .wr_clk(wr_clk_i),               // 1-bit input: Write clock: Used for write operation. wr_clk must be a
                                           // free running clock.

            .wr_en(wr_en_i)                  // 1-bit input: Write Enable: If the FIFO is not full, asserting this
                                           // signal causes data (on din) to be written to the FIFO. Must be held
                                           // active-low when rst or wr_rst_busy is active high.

         );

    end
    else if(READ_MODE == "std") begin : std_async_fifo 
        xpm_fifo_async #(
            .CASCADE_HEIGHT(0),        // DECIMAL
            .CDC_SYNC_STAGES(2),       // DECIMAL
            .DOUT_RESET_VALUE("0"),    // String
            .ECC_MODE(ECC_MODE),       // String
            .FIFO_MEMORY_TYPE(FIFO_MEMORY_TYPE), // String
            .FIFO_READ_LATENCY(FIFO_READ_LATENCY),     // DECIMAL
            .FIFO_WRITE_DEPTH(FIFO_WRITE_DEPTH),   // DECIMAL
            .FULL_RESET_VALUE(FULL_RESET_VALUE),      // DECIMAL
            .PROG_EMPTY_THRESH(PROG_EMPTY_THRESH),    // DECIMAL
            .PROG_FULL_THRESH(PROG_FULL_THRESH),     // DECIMAL
            .RD_DATA_COUNT_WIDTH(RD_DATA_COUNT_WIDTH),   // DECIMAL
            .READ_DATA_WIDTH(READ_DATA_WIDTH),      // DECIMAL
            .READ_MODE(READ_MODE),         // String
            .RELATED_CLOCKS(RELATED_CLOCKS),        // DECIMAL
            .SIM_ASSERT_CHK(0),        // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
            .USE_ADV_FEATURES(USE_ADV_FEATURES), // String
            .WAKEUP_TIME(0),           // DECIMAL
            .WRITE_DATA_WIDTH(WRITE_DATA_WIDTH),     // DECIMAL
            .WR_DATA_COUNT_WIDTH(WR_DATA_COUNT_WIDTH)    // DECIMAL
         )
         xpm_fifo_async_inst (
            .almost_empty(fifo_almost_empty_o),   // 1-bit output: Almost Empty : When asserted, this signal indicates that
                                           // only one more read can be performed before the FIFO goes to empty.

            .almost_full(fifo_almost_full_o),     // 1-bit output: Almost Full: When asserted, this signal indicates that
                                           // only one more write can be performed before the FIFO is full.

            .data_valid(fifo_rd_vld_o),       // 1-bit output: Read Data Valid: When asserted, this signal indicates
                                           // that valid data is available on the output bus (dout).

            .dbiterr(dbiterr),             // 1-bit output: Double Bit Error: Indicates that the ECC decoder detected
                                           // a double-bit error and data in the FIFO core is corrupted.

            .dout(fifo_rd_data_o),                   // READ_DATA_WIDTH-bit output: Read Data: The output data bus is driven
                                           // when reading the FIFO.

            .empty(fifo_empty_o),                 // 1-bit output: Empty Flag: When asserted, this signal indicates that the
                                           // FIFO is empty. Read requests are ignored when the FIFO is empty,
                                           // initiating a read while empty is not destructive to the FIFO.

            .full(fifo_full_o),                   // 1-bit output: Full Flag: When asserted, this signal indicates that the
                                           // FIFO is full. Write requests are ignored when the FIFO is full,
                                           // initiating a write when the FIFO is full is not destructive to the
                                           // contents of the FIFO.

            .overflow(overflow),           // 1-bit output: Overflow: This signal indicates that a write request
                                           // (wren) during the prior clock cycle was rejected, because the FIFO is
                                           // full. Overflowing the FIFO is not destructive to the contents of the
                                           // FIFO.

            .prog_empty(fifo_prog_empty_o),       // 1-bit output: Programmable Empty: This signal is asserted when the
                                           // number of words in the FIFO is less than or equal to the programmable
                                           // empty threshold value. It is de-asserted when the number of words in
                                           // the FIFO exceeds the programmable empty threshold value.

            .prog_full(fifo_prog_full_o),         // 1-bit output: Programmable Full: This signal is asserted when the
                                           // number of words in the FIFO is greater than or equal to the
                                           // programmable full threshold value. It is de-asserted when the number of
                                           // words in the FIFO is less than the programmable full threshold value.

            .rd_data_count(rd_data_count), // RD_DATA_COUNT_WIDTH-bit output: Read Data Count: This bus indicates the
                                           // number of words read from the FIFO.

            .rd_rst_busy(rd_rst_busy),     // 1-bit output: Read Reset Busy: Active-High indicator that the FIFO read
                                           // domain is currently in a reset state.

            .sbiterr(sbiterr),             // 1-bit output: Single Bit Error: Indicates that the ECC decoder detected
                                           // and fixed a single-bit error.

            .underflow(underflow),         // 1-bit output: Underflow: Indicates that the read request (rd_en) during
                                           // the previous clock cycle was rejected because the FIFO is empty. Under
                                           // flowing the FIFO is not destructive to the FIFO.

            .wr_ack(wr_ack),               // 1-bit output: Write Acknowledge: This signal indicates that a write
                                           // request (wr_en) during the prior clock cycle is succeeded.

            .wr_data_count(wr_data_count), // WR_DATA_COUNT_WIDTH-bit output: Write Data Count: This bus indicates
                                           // the number of words written into the FIFO.

            .wr_rst_busy(wr_rst_busy),     // 1-bit output: Write Reset Busy: Active-High indicator that the FIFO
                                           // write domain is currently in a reset state.

            .din(wr_data_i),                     // WRITE_DATA_WIDTH-bit input: Write Data: The input data bus used when
                                           // writing the FIFO.

            .injectdbiterr(injectdbiterr), // 1-bit input: Double Bit Error Injection: Injects a double bit error if
                                           // the ECC feature is used on block RAMs or UltraRAM macros.

            .injectsbiterr(injectsbiterr), // 1-bit input: Single Bit Error Injection: Injects a single bit error if
                                           // the ECC feature is used on block RAMs or UltraRAM macros.

            .rd_clk(rd_clk_i),               // 1-bit input: Read clock: Used for read operation. rd_clk must be a free
                                           // running clock.

            .rd_en(rd_en_i),                 // 1-bit input: Read Enable: If the FIFO is not empty, asserting this
                                           // signal causes data (on dout) to be read from the FIFO. Must be held
                                           // active-low when rd_rst_busy is active high.

            .rst(rst_i),                     // 1-bit input: Reset: Must be synchronous to wr_clk. The clock(s) can be
                                           // unstable at the time of applying reset, but reset must be released only
                                           // after the clock(s) is/are stable.

            .sleep(sleep),                 // 1-bit input: Dynamic power saving: If sleep is High, the memory/fifo
                                           // block is in power saving mode.

            .wr_clk(wr_clk_i),               // 1-bit input: Write clock: Used for write operation. wr_clk must be a
                                           // free running clock.

            .wr_en(wr_en_i)                  // 1-bit input: Write Enable: If the FIFO is not full, asserting this
                                           // signal causes data (on din) to be written to the FIFO. Must be held
                                           // active-low when rst or wr_rst_busy is active high.

         );
    end
endgenerate

// `ifdef SIMULATE
// wire [32-1:0]   test_dout;
// wire            test_full;
// wire            test_almost_full;
// wire            test_empty;
// wire            test_almost_empty;
// wire  [3-1:0]   test_rd_data_count;
// wire  [3-1:0]   test_wr_data_count;
// wire            test_wr_rst_busy;
// wire            test_rd_rst_busy;
// fifo_generator_test your_instance_name (
//   .rst(rst_i),                      // input wire rst
//   .wr_clk(wr_clk_i),                // input wire wr_clk
//   .rd_clk(rd_clk_i),                // input wire rd_clk
//   .din(wr_data_i),                      // input wire [31 : 0] din
//   .wr_en(wr_en_i),                  // input wire wr_en
//   .rd_en(rd_en_i),                  // input wire rd_en
//   .dout(test_dout),                    // output wire [31 : 0] dout
//   .full(test_full),                    // output wire full
//   .almost_full(test_almost_full),      // output wire almost_full
//   .empty(test_empty),                  // output wire empty
//   .almost_empty(test_almost_empty),    // output wire almost_empty
//   .rd_data_count(test_rd_data_count),  // output wire [3 : 0] rd_data_count
//   .wr_data_count(test_wr_data_count),  // output wire [3 : 0] wr_data_count
//   .wr_rst_busy(test_wr_rst_busy),      // output wire wr_rst_busy
//   .rd_rst_busy(test_rd_rst_busy)      // output wire rd_rst_busy
// );
// `endif //SIMULATE
endmodule