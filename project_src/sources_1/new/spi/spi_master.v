`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/06/12
// Design Name: songyuxin
// Module Name: spi_master
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
//                  |----------write---------||----read------|
//          __________    __    __    __    __    __    __    ___________
// SPI_CLK            \__/  \__/  \__/  \__/  \__/  \__/  \__/  
//          ________                           __________________________ 
// SPI_CSN          \_________________________/
//          __________ _____ _____ _____ _____ _____ _____ ______________
// MOSI     ____z_____X_____X_____X_____X_____X__z__X__z__X____z_________
//
//          __________________________________ _____ _____ ______________
// MISO     __________________________________X_____X_____X______________
// 
// 
// assign MISO = SPI_IO;
// assign SPI_IO = (SPI_CSN == 'd0) ? MOSI : 'bz;
//
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module spi_master #(
    parameter                               TCQ        = 0.1,
    parameter                               DUMMY_NUM  = 8  ,
    parameter                               DATA_WIDTH = 8  ,
    parameter                               ADDR_WIDTH = 16 ,
    parameter                               CMD_WIDTH  = 8  ,
    parameter                               SPI_MODE   = 2  
)(
    // clk & rst
    input    wire                           clk_i           ,
    input    wire                           rst_i           ,
    input    wire                           spi_en_i        ,
    input    wire   [CMD_WIDTH-1:0]         spi_cmd_i       ,
    input    wire   [ADDR_WIDTH-1:0]        spi_addr_i      ,
    input    wire   [DATA_WIDTH-1:0]        spi_wr_data_i   ,      // fwft
    output   wire                           spi_wr_seq_o    ,

    output   wire                           spi_rd_vld_o    ,
    output   wire   [DATA_WIDTH-1:0]        spi_rd_data_o   ,
    output   wire                           spi_busy_o      ,
    // spi info
    output   wire                           SPI_CLK         ,
    output   wire                           SPI_CSN         ,
    output   wire   [SPI_MODE-1:0]          SPI_MOSI        ,
    input    wire   [SPI_MODE-1:0]          SPI_MISO        
);


//////////////////////////////////////////////////////////////////////////////////
// *********** Define Parameter Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
localparam                      ST_IDLE         = 3'd0;
localparam                      ST_WAIT         = 3'd1;
localparam                      ST_WRITE        = 3'd2;
localparam                      ST_DUMMY        = 3'd3;
localparam                      ST_READ         = 3'd4;
localparam                      ST_FINISH       = 3'd5;

localparam                      SPI_MODE_WIDTH  = 3 - $clog2(SPI_MODE);
localparam                      SPI_DATA_WIDTH  = $clog2(DATA_WIDTH) - $clog2(SPI_MODE);

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Register Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
reg     [ 3-1:0]                state           = ST_IDLE;
reg     [ 3-1:0]                state_next      = ST_IDLE;

reg                             spi_en_r        = 'd0;
reg     [CMD_WIDTH-1:0]         spi_cmd_r       = 'd0;
reg     [ADDR_WIDTH-1:0]        spi_addr_r      = 'd0;

reg     [SPI_MODE_WIDTH-1:0]    wr_bit_cnt      = 'd0;
reg     [SPI_DATA_WIDTH-1:0]    wr_data_bit_cnt = 'd0;
reg     [CMD_WIDTH-1:0]         wr_byte_cnt     = 'd0;
reg     [CMD_WIDTH-1:0]         wr_byte_num     = 'd0;

reg     [16-1:0]                dummy_cnt       = 'd0;

reg     [SPI_DATA_WIDTH-1:0]    rd_bit_cnt      = 'd0;
reg     [CMD_WIDTH-1:0]         rd_data_cnt     = 'd0;
reg     [CMD_WIDTH-1:0]         rd_data_num     = 'd0;

reg                             spi_wr_seq_r    = 'd0;
reg                             spi_rd_vld_r    = 'd0;
reg     [DATA_WIDTH-1:0]        spi_rd_data_r   = 'd0;
reg                             spi_busy_r      = 'd0;

reg                             spi_csn_r       = 'd1;
reg     [SPI_MODE-1:0]          spi_mosi_r      = 'd0;
reg                             spi_clk_r       = 'd0;
reg                             spi_clk_r_d     = 'd0;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<



//////////////////////////////////////////////////////////////////////////////////
// *********** Define Wire Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
wire                            spi_mode            ;
wire                            spi_clk_pose        ;
wire                            spi_clk_nege        ;

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<





//////////////////////////////////////////////////////////////////////////////////
// *********** Instance Module
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>


//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


//////////////////////////////////////////////////////////////////////////////////
// *********** Logic Design
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
assign spi_mode = spi_cmd_r[7];    // 0: spi write  1: spi read

always @(posedge clk_i) begin
    if(rst_i)
        state <= #TCQ ST_IDLE;
    else 
        state <= #TCQ state_next;
end

always @(*) begin
    state_next = state;
    case (state)
        ST_IDLE : begin
            if(spi_en_r)
                state_next = ST_WAIT;
        end 
        ST_WAIT : begin
                state_next = ST_WRITE;
        end
        ST_WRITE : begin
            if(&wr_bit_cnt && (wr_byte_cnt==wr_byte_num) && spi_clk_pose)begin
                if(spi_mode)
                    state_next = ST_DUMMY;
                else 
                    state_next = ST_FINISH;
            end
        end
        ST_DUMMY : begin
            if(dummy_cnt==DUMMY_NUM-1)begin
                state_next = ST_READ;
            end
        end
        ST_READ : begin
            if(&rd_bit_cnt && (rd_data_cnt == rd_data_num) && spi_clk_pose)begin
                state_next = ST_FINISH;
            end
        end 
        ST_FINISH : begin
            state_next = ST_IDLE;
        end
        default: state_next = ST_IDLE;
    endcase
end

always @(posedge clk_i) begin
    if(state==ST_WAIT)begin
        if(~spi_mode)
            wr_byte_num <= #TCQ {spi_cmd_r[4:0],2'b00} + 'd4 + 'd2;  // +4 = least wr number.  +2 = +3-1= 2byte addr + 1byte cmd
        else 
            wr_byte_num <= #TCQ 2; // 2 = +3-1 = 2byte addr + 1byte cmd
    end
end

always @(posedge clk_i) begin
    if(state==ST_WAIT)begin
        if(spi_mode)
            rd_data_num <= #TCQ spi_cmd_r[4:0];
    end
end

always @(posedge clk_i) begin   // 100MHz
    if(state==ST_IDLE)
        spi_clk_r <= #TCQ 'd1;
    else 
        spi_clk_r <= #TCQ ~spi_clk_r;    // 50MHz
end

always @(posedge clk_i) begin
    spi_clk_r_d <= #TCQ spi_clk_r;
end

assign spi_clk_nege = spi_clk_r_d  && ~spi_clk_r;
assign spi_clk_pose = ~spi_clk_r_d && spi_clk_r;


always @(posedge clk_i) begin
    if(spi_en_i && state==ST_IDLE)begin
        spi_en_r    <= #TCQ 'd1;
        spi_cmd_r   <= #TCQ spi_cmd_i ;
        spi_addr_r  <= #TCQ spi_addr_i;
    end
    else begin
        spi_en_r    <= #TCQ 'd0;
    end
end

always @(posedge clk_i) begin
    if(state==ST_WRITE)begin
        if(&wr_bit_cnt && spi_clk_nege)begin
            wr_byte_cnt <= #TCQ wr_byte_cnt + 1;
            wr_bit_cnt  <= #TCQ 'd0;
        end
        else if(spi_clk_nege)begin
            wr_bit_cnt <= #TCQ wr_bit_cnt + 1;
        end 
    end 
    else begin
        wr_byte_cnt <= #TCQ 'd0;
        wr_bit_cnt  <= #TCQ 'd0;
    end
end

always @(posedge clk_i) begin
    if(state==ST_WRITE)begin
        if(&wr_data_bit_cnt && spi_clk_nege && wr_byte_cnt>'d2)begin
            wr_data_bit_cnt <= #TCQ 'd0;
        end
        else if(spi_clk_nege && wr_byte_cnt>'d2)begin
            wr_data_bit_cnt <= #TCQ wr_data_bit_cnt + 1;
        end
    end
    else begin
        wr_data_bit_cnt <= #TCQ 'd0;
    end
end

// dummy clk
always @(posedge clk_i) begin
    if(state==ST_DUMMY)
        dummy_cnt <= #TCQ dummy_cnt + 1;
    else 
        dummy_cnt <= #TCQ 'd0; 
end

always @(posedge clk_i) begin
    if(state==ST_READ)begin
        if(&rd_bit_cnt && spi_clk_pose)begin
            rd_data_cnt <= #TCQ rd_data_cnt + 1;
            rd_bit_cnt  <= #TCQ 'd0;
        end
        else if(spi_clk_pose)begin
            rd_bit_cnt <= #TCQ rd_bit_cnt + 1;
        end 
    end 
    else begin
        rd_data_cnt <= #TCQ 'd0;
        rd_bit_cnt  <= #TCQ 'd0;
    end
end

always @(posedge clk_i) begin
    if(state==ST_WRITE)begin
        if(spi_clk_pose && (&wr_data_bit_cnt) && wr_byte_cnt>='d3)  // four byte align, byte0/1/2 is cmd and addr.
            spi_wr_seq_r <= #TCQ 'd1;
        else 
            spi_wr_seq_r <= #TCQ 'd0;
    end
    else begin
        spi_wr_seq_r <= #TCQ 'd0;
    end
end

always @(posedge clk_i) begin
    if(state==ST_WRITE)begin
        if(wr_byte_cnt == 'd0)begin
            spi_mosi_r <= #TCQ spi_addr_r[8 + (3-wr_bit_cnt)*SPI_MODE +: SPI_MODE];
        end
        else if(wr_byte_cnt == 'd1)begin
            spi_mosi_r <= #TCQ spi_addr_r[(3-wr_bit_cnt)*SPI_MODE +: SPI_MODE];
        end
        else if(wr_byte_cnt == 'd2)begin
            spi_mosi_r <= #TCQ spi_cmd_r[(3-wr_bit_cnt)*SPI_MODE +: SPI_MODE];
        end
        else begin
            spi_mosi_r <= #TCQ spi_wr_data_i[('hf-wr_data_bit_cnt)*SPI_MODE +: SPI_MODE];    // 大端对齐 
        end
    end
end


always @(posedge clk_i) begin
    if(state==ST_READ)begin
        if(spi_clk_pose)
            spi_rd_data_r <= #TCQ {spi_rd_data_r[DATA_WIDTH-SPI_MODE-1 : 0],SPI_MISO};
    end
end

always @(posedge clk_i) begin
    if(state==ST_READ)
        spi_rd_vld_r <= #TCQ spi_clk_pose && (&rd_bit_cnt);
    else 
        spi_rd_vld_r <= #TCQ 'd0;
end

always @(posedge clk_i) begin
    if(state==ST_IDLE && spi_en_i)
        spi_busy_r <= #TCQ 'd1;
    else if(state==ST_FINISH)
        spi_busy_r <= #TCQ 'd0;
end

always @(posedge clk_i) begin
    if(state==ST_IDLE && state_next==ST_WAIT)
        spi_csn_r <= #TCQ 'd0;
    else if((state==ST_DUMMY && spi_clk_pose) || (state==ST_IDLE && state_next==ST_IDLE))
        spi_csn_r <= #TCQ 'd1;
end

assign spi_wr_seq_o     = spi_wr_seq_r;
assign spi_rd_vld_o     = spi_rd_vld_r;
assign spi_rd_data_o    = spi_rd_data_r;
assign spi_busy_o       = spi_busy_r;
assign SPI_CLK          = spi_clk_r;
assign SPI_CSN          = spi_csn_r;
assign SPI_MOSI         = spi_mosi_r;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


endmodule
