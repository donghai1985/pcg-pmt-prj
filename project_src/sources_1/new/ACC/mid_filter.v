`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: zas
// Engineer: songyuxin
// 
// Create Date: 2024/2/28
// Design Name: PCG
// Module Name: mid_filter
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

module mid_filter #(
    parameter                                   TCQ             = 0.1 ,
    parameter                                   DATA_WIDTH      = 16  
)(
    input                                       clk_i               ,
    input                                       rst_i               ,

    input                                       src_vld_i           ,
    input       [DATA_WIDTH-1:0]                src_data_i          ,

    output                                      mid_vld_o           ,
    output      [DATA_WIDTH-1:0]                mid_data_o          
);
//////////////////////////////////////////////////////////////////////////////////
// *********** Define Parameter Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
genvar i;


//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Register Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
reg     [DATA_WIDTH-1:0]        mem_data_seq [0:5-1];
reg     [4-1:0]                 mem_seq_rank [0:5-1];
reg     [4-1:0]                 mem_rank_seq [0:5-1];
reg                             src_vld_d0              = 'd0;
reg                             src_vld_d1              = 'd0;
reg                             src_vld_d2              = 'd0;
reg     [DATA_WIDTH-1:0]        src_data_d0             = 'd0;
reg     [DATA_WIDTH-1:0]        src_data_d1             = 'd0;
reg     [DATA_WIDTH-1:0]        src_data_d2             = 'd0;
reg     [5-1:0]                 compare_result          = 'd0;
reg     [4-1:0]                 insert_rank             = 'd0;
reg     [4-1:0]                 last_seq                = 'd0;
reg     [4-1:0]                 last_rank               = 'd0;
reg     [4-1:0]                 seq_rank_generate_cnt   = 'd0;
reg                             seq_rank_generate       = 'd0;
reg                             mid_vld                 = 'd0;
reg     [DATA_WIDTH-1:0]        mid_data                = 'd0;


//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Wire Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
wire    [4-1:0]                 mid_seq;

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Instance Module
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Logic Design
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
always @(posedge clk_i) begin
    src_vld_d0 <= #TCQ src_vld_i;
    src_vld_d1 <= #TCQ src_vld_d0;
    src_vld_d2 <= #TCQ src_vld_d1;
end

always @(posedge clk_i) begin
    src_data_d0 <= #TCQ src_data_i;
    src_data_d1 <= #TCQ src_data_d0;
    src_data_d2 <= #TCQ src_data_d1;
end

generate
    for(i=0;i<5;i=i+1)begin: COMPARE
        always @(posedge clk_i) begin
            if(src_vld_i)begin
                compare_result[i] <= #TCQ (src_data_i > mem_data_seq[i]);
            end
        end
    end
endgenerate

always @(posedge clk_i) begin
    insert_rank <= #TCQ (compare_result[0] + compare_result[1] + compare_result[2] + compare_result[3] + compare_result[4]);
end

always @(posedge clk_i) begin
    if(rst_i)
        last_seq <= #TCQ 'd0;
    else if(mid_vld)begin
        if(last_seq == 'd4)
            last_seq <= #TCQ 'd0;
        else 
            last_seq <= #TCQ last_seq + 1;
    end
end

always @(posedge clk_i) begin
    last_rank <= #TCQ mem_rank_seq[last_seq];
end

generate
    for(i=0;i<5;i=i+1)begin: RANK
        always @(posedge clk_i) begin
            if(rst_i)
                mem_rank_seq[i] <= #TCQ i;
            else if(src_vld_d1 && (last_rank >= insert_rank))begin
                if(mem_rank_seq[i]==last_rank)
                    mem_rank_seq[i] <= #TCQ insert_rank;
                else if(mem_rank_seq[i] < last_rank && mem_rank_seq[i] >= insert_rank)
                    mem_rank_seq[i] <= #TCQ mem_rank_seq[i] + 1;
                else 
                    mem_rank_seq[i] <= #TCQ mem_rank_seq[i];
            end
            else if(src_vld_d1)begin
                if(mem_rank_seq[i]==last_rank)
                    mem_rank_seq[i] <= #TCQ insert_rank - 1;
                else if(mem_rank_seq[i] > last_rank && mem_rank_seq[i] < insert_rank)
                    mem_rank_seq[i] <= #TCQ mem_rank_seq[i] - 1;
                else 
                    mem_rank_seq[i] <= #TCQ mem_rank_seq[i];
            end
        end

    end
endgenerate


generate
    for(i=0;i<5;i=i+1)begin: DATA_GENERATE
        always @(posedge clk_i) begin
            if(rst_i)
                mem_data_seq[i] <= #TCQ 'd0;
            else if(src_vld_d2 && last_seq==i)begin
                mem_data_seq[i] <= #TCQ src_data_d2;
            end
        end
    end
endgenerate


always @(posedge clk_i) begin
    if(src_vld_d2)
        seq_rank_generate <= #TCQ 'd1;
    else if(seq_rank_generate_cnt=='d5)
        seq_rank_generate <= #TCQ 'd0;
end

always @(posedge clk_i) begin
    if(seq_rank_generate)
        seq_rank_generate_cnt <= #TCQ seq_rank_generate_cnt + 1;
    else
        seq_rank_generate_cnt <= #TCQ 'd0;
end


always @(posedge clk_i) begin
    if(rst_i)begin
        mem_seq_rank[0] <= #TCQ 'd0;
        mem_seq_rank[1] <= #TCQ 'd1;
        mem_seq_rank[2] <= #TCQ 'd2;
        mem_seq_rank[3] <= #TCQ 'd3;
        mem_seq_rank[4] <= #TCQ 'd4;
    end
    else if(seq_rank_generate_cnt==0)begin
        case (mem_rank_seq[0])
            'd0:mem_seq_rank[0] <= #TCQ 'd0;
            'd1:mem_seq_rank[1] <= #TCQ 'd0;
            'd2:mem_seq_rank[2] <= #TCQ 'd0;
            'd3:mem_seq_rank[3] <= #TCQ 'd0;
            'd4:mem_seq_rank[4] <= #TCQ 'd0;
            default: /*default*/ ;
        endcase
    end
    else if(seq_rank_generate_cnt==1)begin
        case (mem_rank_seq[1])
            'd0:mem_seq_rank[0] <= #TCQ 'd1;
            'd1:mem_seq_rank[1] <= #TCQ 'd1;
            'd2:mem_seq_rank[2] <= #TCQ 'd1;
            'd3:mem_seq_rank[3] <= #TCQ 'd1;
            'd4:mem_seq_rank[4] <= #TCQ 'd1;
            default: /*default*/ ;
        endcase
    end
    else if(seq_rank_generate_cnt==2)begin
        case (mem_rank_seq[2])
            'd0:mem_seq_rank[0] <= #TCQ 'd2;
            'd1:mem_seq_rank[1] <= #TCQ 'd2;
            'd2:mem_seq_rank[2] <= #TCQ 'd2;
            'd3:mem_seq_rank[3] <= #TCQ 'd2;
            'd4:mem_seq_rank[4] <= #TCQ 'd2;
            default: /*default*/ ;
        endcase
    end
    else if(seq_rank_generate_cnt==3)begin
        case (mem_rank_seq[3])
            'd0:mem_seq_rank[0] <= #TCQ 'd3;
            'd1:mem_seq_rank[1] <= #TCQ 'd3;
            'd2:mem_seq_rank[2] <= #TCQ 'd3;
            'd3:mem_seq_rank[3] <= #TCQ 'd3;
            'd4:mem_seq_rank[4] <= #TCQ 'd3;
            default: /*default*/ ;
        endcase
    end
    else if(seq_rank_generate_cnt==4)begin
        case (mem_rank_seq[4])
            'd0:mem_seq_rank[0] <= #TCQ 'd4;
            'd1:mem_seq_rank[1] <= #TCQ 'd4;
            'd2:mem_seq_rank[2] <= #TCQ 'd4;
            'd3:mem_seq_rank[3] <= #TCQ 'd4;
            'd4:mem_seq_rank[4] <= #TCQ 'd4;
            default: /*default*/ ;
        endcase
    end
end

assign mid_seq = mem_seq_rank[2];

always @(posedge clk_i) begin
    mid_vld  <= #TCQ seq_rank_generate_cnt=='d5;
    mid_data <= #TCQ mem_data_seq[mid_seq];
end

assign mid_vld_o  = mid_vld;
assign mid_data_o = mid_data;

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    
endmodule