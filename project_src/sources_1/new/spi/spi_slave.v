`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/06/13
// Design Name: songyuxin
// Module Name: spi_slave
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
// assign MOSI = SPI_IO;
// assign SPI_IO = (~SPI_CSN == 'd0) ? MISO : 'bz;
//
//
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module spi_slave #(
    parameter                               TCQ        = 0.1,
    parameter                               DUMMY_NUM  = 8  ,
    parameter                               DATA_WIDTH = 32 ,
    parameter                               ADDR_WIDTH = 16 ,
    parameter                               CMD_WIDTH  = 8  ,
    parameter                               SPI_MODE   = 2  
)(
    // clk & rst
    input    wire                           clk_i           ,
    input    wire                           rst_i           ,

    output   wire                           spi_en_o        ,
    output   wire   [CMD_WIDTH-1:0]         spi_cmd_o       ,
    output   wire   [ADDR_WIDTH-1:0]        spi_addr_o      ,
    output   wire                           spi_wr_vld_o    , 
    output   wire   [DATA_WIDTH-1:0]        spi_wr_data_o   ,

    output   wire                           spi_rd_seq_o    ,
    input    wire   [DATA_WIDTH-1:0]        spi_rd_data_i   ,      // fwft
    output   wire                           spi_slave_t_o   ,
    // spi info
    input    wire                           SPI_CLK         ,
    input    wire                           SPI_CSN         ,
    input    wire   [SPI_MODE-1:0]          SPI_MOSI        ,
    output   wire   [SPI_MODE-1:0]          SPI_MISO        
);


//////////////////////////////////////////////////////////////////////////////////
// *********** Define Parameter Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
localparam                      ST_IDLE         = 3'd0;


localparam                      SPI_MODE_WIDTH  = 3 - $clog2(SPI_MODE);
localparam                      SPI_DATA_WIDTH  = $clog2(DATA_WIDTH) - $clog2(SPI_MODE);

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Register Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
reg                             spi_clk_d0          ;
reg                             spi_clk_d1          ;
reg                             spi_csn_d0          ;
reg                             spi_csn_d1          ;
reg     [SPI_MODE-1:0]          spi_mosi_d0         ;
reg     [SPI_MODE-1:0]          spi_mosi_d1         ;
reg                             spi_clk_pose_d0     ;
reg                             spi_clk_pose_d1     ;

reg     [DATA_WIDTH-1:0]        spi_data_temp   = 'd0;
reg     [DATA_WIDTH-1:0]        spi_data_r      = 'd0;
reg                             spi_data_r_vld  = 'd0;

reg     [CMD_WIDTH-1:0]         spi_cmd_r       = 'd0;
reg     [ADDR_WIDTH-1:0]        spi_addr_r      = 'd0;
reg     [DATA_WIDTH-1:0]        spi_wr_data     = 'd0;
reg                             spi_cmd_vld     = 'd0;
reg                             spi_data_vld    = 'd0;

reg     [16-1:0]                dummy_cnt       = 'd0;

reg     [SPI_MODE_WIDTH-1:0]    wr_bit_cnt      = {SPI_MODE_WIDTH{1'b1}};
reg     [CMD_WIDTH-1:0]         wr_byte_cnt     = 'd0;
reg     [CMD_WIDTH-1:0]         wr_byte_num     = 'd0;
reg     [CMD_WIDTH-1:0]         wr_byte_cnt_d   = 'd0;

reg                             spi_rd_seq_r    = 'd0;
reg     [SPI_MODE-1:0]          spi_miso_r      = 'd0;
reg     [SPI_DATA_WIDTH-1:0]    rd_bit_cnt      = 'd0;
reg     [CMD_WIDTH-1:0]         rd_data_cnt     = 'd0;
reg     [CMD_WIDTH-1:0]         rd_data_num     = 'd0;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Wire Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>




//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
wire                            spi_mode            ; // 0 write   1 read
wire                            spi_rd_done         ;


wire                            spi_clk_pose        ;
wire                            spi_clk_nege        ;



//////////////////////////////////////////////////////////////////////////////////
// *********** Instance Module
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>


//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


//////////////////////////////////////////////////////////////////////////////////
// *********** Logic Design
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
always @(posedge clk_i) begin   // 100MHz
    spi_clk_d0 <= #TCQ SPI_CLK;    // 50MHz
    spi_clk_d1 <= #TCQ spi_clk_d0;
end

assign spi_clk_nege = spi_clk_d1  && ~spi_clk_d0;
assign spi_clk_pose = ~spi_clk_d1 && spi_clk_d0;

always @(posedge clk_i) begin   
    spi_csn_d0 <= #TCQ SPI_CSN;   
    spi_csn_d1 <= #TCQ spi_csn_d0;
end

always @(posedge clk_i) begin       
    spi_mosi_d0 <= #TCQ SPI_MOSI;        
end

always @(posedge clk_i) begin   
    spi_clk_pose_d0 <= #TCQ spi_clk_pose;   
    spi_clk_pose_d1 <= #TCQ spi_clk_pose_d0;
end


// slave spi_wr logic
always @(posedge clk_i) begin
    if(~spi_csn_d0 && spi_clk_pose)
        spi_data_temp <= #TCQ {spi_data_temp[DATA_WIDTH-SPI_MODE-1:0],spi_mosi_d0};
end

always @(posedge clk_i) begin
    if(~spi_csn_d0 && spi_clk_pose)
        wr_bit_cnt <= #TCQ wr_bit_cnt + 1;
    else if(spi_csn_d0)
        wr_bit_cnt <= #TCQ {SPI_MODE_WIDTH{1'b1}};
end

always @(posedge clk_i) begin
    if(spi_csn_d0)
        wr_byte_cnt <= #TCQ 'd0;
    else if(&wr_bit_cnt && spi_clk_pose)
        wr_byte_cnt <= #TCQ wr_byte_cnt + 1;
end

always @(posedge clk_i) begin
    wr_byte_cnt_d  <= #TCQ wr_byte_cnt;
    spi_data_r_vld <= #TCQ (~spi_csn_d1 && (&wr_bit_cnt) && wr_byte_cnt);
    spi_data_r     <= #TCQ spi_data_temp;
end

always @(posedge clk_i) begin
    if(wr_byte_cnt_d=='d2)
        spi_addr_r  <= #TCQ spi_data_r[ADDR_WIDTH-1:0];
    else if(wr_byte_cnt_d=='d3)
        spi_cmd_r   <= #TCQ spi_data_r[CMD_WIDTH-1:0];
    else 
        spi_wr_data <= #TCQ spi_data_r[DATA_WIDTH-1:0];
end

always @(posedge clk_i) begin
    spi_cmd_vld  <= #TCQ spi_clk_pose_d1 && spi_data_r_vld && (wr_byte_cnt_d=='d3);
    spi_data_vld <= #TCQ spi_clk_pose_d1 && spi_data_r_vld && (wr_byte_cnt_d>3 && wr_byte_cnt_d[1:0]=='b11);
end


// slave spi rd logic
assign spi_mode     = spi_cmd_r[CMD_WIDTH-1];    // 0: spi write  1: spi read
assign spi_rd_done  = &rd_bit_cnt && (rd_data_cnt == rd_data_num) && spi_clk_pose;
// dummy clk count 
// read state 
always @(posedge clk_i) begin
    if(spi_rd_done)begin
        dummy_cnt <= #TCQ 'd0;
    end
    else if(spi_cmd_vld && spi_mode)begin
        dummy_cnt <= #TCQ 'd7;               // master  and csn delay
    end
    else if((dummy_cnt < DUMMY_NUM) && dummy_cnt)begin
        dummy_cnt <= #TCQ dummy_cnt + 1;     // use dummy_cnt control read state
    end
end

always @(posedge clk_i) begin
    if(spi_cmd_vld && spi_mode)begin
        rd_data_num <= #TCQ spi_cmd_r[6:0];
    end
end

always @(posedge clk_i) begin
    if(dummy_cnt==DUMMY_NUM)begin
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

// read data 
always @(posedge clk_i) begin
    if(dummy_cnt==DUMMY_NUM)begin
        if(spi_clk_nege && (&rd_bit_cnt))
            spi_rd_seq_r <= #TCQ 'd1;
        else 
            spi_rd_seq_r <= #TCQ 'd0;
    end
    else begin
        spi_rd_seq_r <= #TCQ 'd0;
    end
end

always @(posedge clk_i) begin
    if(dummy_cnt==DUMMY_NUM)begin
        spi_miso_r <= #TCQ spi_rd_data_i[(15-rd_bit_cnt)*SPI_MODE +: SPI_MODE];    // 大端对齐  
    end
end

 
assign spi_en_o      = spi_cmd_vld;
assign spi_cmd_o     = spi_cmd_r;
assign spi_addr_o    = spi_addr_r;
assign spi_wr_vld_o  = spi_data_vld;
assign spi_wr_data_o = spi_wr_data;
assign spi_rd_seq_o  = spi_rd_seq_r;
assign SPI_MISO      = spi_miso_r;
assign spi_slave_t_o = SPI_CSN;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


endmodule
