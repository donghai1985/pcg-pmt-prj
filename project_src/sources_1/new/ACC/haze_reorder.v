`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: zas
// Engineer: songyuxin
// 
// Create Date: 2024/2/28
// Design Name: PCG
// Module Name: haze_reorder
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

module haze_reorder #(
    parameter                                   TCQ             = 0.1 ,
    parameter                                   DATA_WIDTH      = 16  
)(
    input                                       clk_i               ,
    input                                       rst_i               ,

    input                                       src_vld_i           ,
    input       [DATA_WIDTH-1:0]                src_data_i          ,

    output                                      reorder_vld_o       ,
    output      [DATA_WIDTH-1:0]                reorder_rank0_o     ,
    output      [DATA_WIDTH-1:0]                reorder_rank1_o     ,
    output      [DATA_WIDTH-1:0]                reorder_rank2_o     ,
    output      [DATA_WIDTH-1:0]                reorder_rank3_o     ,
    output      [DATA_WIDTH-1:0]                reorder_rank4_o     ,
    output      [DATA_WIDTH-1:0]                reorder_rank5_o     ,
    output      [DATA_WIDTH-1:0]                reorder_rank6_o     ,
    output      [DATA_WIDTH-1:0]                reorder_rank7_o     
);
//////////////////////////////////////////////////////////////////////////////////
// *********** Define Parameter Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
genvar i;


//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Register Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
reg     [DATA_WIDTH-1:0]        mem_data_seq [0:15-1];
reg     [4-1:0]                 mem_seq_rank [0:15-1];
reg     [4-1:0]                 mem_rank_seq [0:15-1];
reg                             src_vld_d0              = 'd0;
reg                             src_vld_d1              = 'd0;
reg                             src_vld_d2              = 'd0;
reg     [DATA_WIDTH-1:0]        src_data_d0             = 'd0;
reg     [DATA_WIDTH-1:0]        src_data_d1             = 'd0;
reg     [DATA_WIDTH-1:0]        src_data_d2             = 'd0;
reg     [15-1:0]                compare_result          = 'd0;
reg     [4-1:0]                 insert_rank             = 'd0;
reg     [4-1:0]                 last_seq                = 'd0;
reg     [4-1:0]                 last_rank               = 'd0;
reg     [4-1:0]                 seq_rank_generate_cnt   = 'd0;
reg                             seq_rank_generate       = 'd0;

reg                             reorder_vld             = 'd0;  
reg     [DATA_WIDTH-1:0]        reorder_rank0           = 'd0;
reg     [DATA_WIDTH-1:0]        reorder_rank1           = 'd0;
reg     [DATA_WIDTH-1:0]        reorder_rank2           = 'd0;
reg     [DATA_WIDTH-1:0]        reorder_rank3           = 'd0;
reg     [DATA_WIDTH-1:0]        reorder_rank4           = 'd0;
reg     [DATA_WIDTH-1:0]        reorder_rank5           = 'd0;
reg     [DATA_WIDTH-1:0]        reorder_rank6           = 'd0;
reg     [DATA_WIDTH-1:0]        reorder_rank7           = 'd0;
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
    for(i=0;i<15;i=i+1)begin: COMPARE
        always @(posedge clk_i) begin
            if(src_vld_i)begin
                compare_result[i] <= #TCQ (src_data_i > mem_data_seq[i]);
            end
        end
    end
endgenerate

always @(posedge clk_i) begin
    insert_rank <= #TCQ (
                          compare_result[0]  + compare_result[1]  + compare_result[2]  + compare_result[3]  + compare_result[4]
                        + compare_result[5]  + compare_result[6]  + compare_result[7]  + compare_result[8]  + compare_result[9]
                        + compare_result[10] + compare_result[11] + compare_result[12] + compare_result[13] + compare_result[14]
                        );
end

always @(posedge clk_i) begin
    if(rst_i)
        last_seq <= #TCQ 'd0;
    else if(reorder_vld)begin
        if(last_seq == 'd14)
            last_seq <= #TCQ 'd0;
        else 
            last_seq <= #TCQ last_seq + 1;
    end
end

always @(posedge clk_i) begin
    last_rank <= #TCQ mem_rank_seq[last_seq];
end

generate
    for(i=0;i<15;i=i+1)begin: RANK
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
    for(i=0;i<15;i=i+1)begin: DATA_GENERATE
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
    else if(seq_rank_generate_cnt=='d15)
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
        mem_seq_rank[0 ] <= #TCQ 'd0 ;
        mem_seq_rank[1 ] <= #TCQ 'd1 ;
        mem_seq_rank[2 ] <= #TCQ 'd2 ;
        mem_seq_rank[3 ] <= #TCQ 'd3 ;
        mem_seq_rank[4 ] <= #TCQ 'd4 ;
        mem_seq_rank[5 ] <= #TCQ 'd5 ;
        mem_seq_rank[6 ] <= #TCQ 'd6 ;
        mem_seq_rank[7 ] <= #TCQ 'd7 ;
        mem_seq_rank[8 ] <= #TCQ 'd8 ;
        mem_seq_rank[9 ] <= #TCQ 'd9 ;
        mem_seq_rank[10] <= #TCQ 'd10;
        mem_seq_rank[11] <= #TCQ 'd11;
        mem_seq_rank[12] <= #TCQ 'd12;
        mem_seq_rank[13] <= #TCQ 'd13;
        mem_seq_rank[14] <= #TCQ 'd14;
    end
    else if(seq_rank_generate_cnt==0)begin
        case (mem_rank_seq[0])
            'd0 :mem_seq_rank[0 ] <= #TCQ 'd0;
            'd1 :mem_seq_rank[1 ] <= #TCQ 'd0;
            'd2 :mem_seq_rank[2 ] <= #TCQ 'd0;
            'd3 :mem_seq_rank[3 ] <= #TCQ 'd0;
            'd4 :mem_seq_rank[4 ] <= #TCQ 'd0;
            'd5 :mem_seq_rank[5 ] <= #TCQ 'd0;
            'd6 :mem_seq_rank[6 ] <= #TCQ 'd0;
            'd7 :mem_seq_rank[7 ] <= #TCQ 'd0;
            'd8 :mem_seq_rank[8 ] <= #TCQ 'd0;
            'd9 :mem_seq_rank[9 ] <= #TCQ 'd0;
            'd10:mem_seq_rank[10] <= #TCQ 'd0;
            'd11:mem_seq_rank[11] <= #TCQ 'd0;
            'd12:mem_seq_rank[12] <= #TCQ 'd0;
            'd13:mem_seq_rank[13] <= #TCQ 'd0;
            'd14:mem_seq_rank[14] <= #TCQ 'd0;
            default: /*default*/ ;
        endcase
    end
    else if(seq_rank_generate_cnt==1)begin
        case (mem_rank_seq[1])
            'd0 :mem_seq_rank[0 ] <= #TCQ 'd1;
            'd1 :mem_seq_rank[1 ] <= #TCQ 'd1;
            'd2 :mem_seq_rank[2 ] <= #TCQ 'd1;
            'd3 :mem_seq_rank[3 ] <= #TCQ 'd1;
            'd4 :mem_seq_rank[4 ] <= #TCQ 'd1;
            'd5 :mem_seq_rank[5 ] <= #TCQ 'd1;
            'd6 :mem_seq_rank[6 ] <= #TCQ 'd1;
            'd7 :mem_seq_rank[7 ] <= #TCQ 'd1;
            'd8 :mem_seq_rank[8 ] <= #TCQ 'd1;
            'd9 :mem_seq_rank[9 ] <= #TCQ 'd1;
            'd10:mem_seq_rank[10] <= #TCQ 'd1;
            'd11:mem_seq_rank[11] <= #TCQ 'd1;
            'd12:mem_seq_rank[12] <= #TCQ 'd1;
            'd13:mem_seq_rank[13] <= #TCQ 'd1;
            'd14:mem_seq_rank[14] <= #TCQ 'd1;
            default: /*default*/ ;
        endcase
    end
    else if(seq_rank_generate_cnt==2)begin
        case (mem_rank_seq[2])
            'd0 :mem_seq_rank[0 ] <= #TCQ 'd2;
            'd1 :mem_seq_rank[1 ] <= #TCQ 'd2;
            'd2 :mem_seq_rank[2 ] <= #TCQ 'd2;
            'd3 :mem_seq_rank[3 ] <= #TCQ 'd2;
            'd4 :mem_seq_rank[4 ] <= #TCQ 'd2;
            'd5 :mem_seq_rank[5 ] <= #TCQ 'd2;
            'd6 :mem_seq_rank[6 ] <= #TCQ 'd2;
            'd7 :mem_seq_rank[7 ] <= #TCQ 'd2;
            'd8 :mem_seq_rank[8 ] <= #TCQ 'd2;
            'd9 :mem_seq_rank[9 ] <= #TCQ 'd2;
            'd10:mem_seq_rank[10] <= #TCQ 'd2;
            'd11:mem_seq_rank[11] <= #TCQ 'd2;
            'd12:mem_seq_rank[12] <= #TCQ 'd2;
            'd13:mem_seq_rank[13] <= #TCQ 'd2;
            'd14:mem_seq_rank[14] <= #TCQ 'd2;
            default: /*default*/ ;
        endcase
    end
    else if(seq_rank_generate_cnt==3)begin
        case (mem_rank_seq[3])
            'd0 :mem_seq_rank[0 ] <= #TCQ 'd3;
            'd1 :mem_seq_rank[1 ] <= #TCQ 'd3;
            'd2 :mem_seq_rank[2 ] <= #TCQ 'd3;
            'd3 :mem_seq_rank[3 ] <= #TCQ 'd3;
            'd4 :mem_seq_rank[4 ] <= #TCQ 'd3;
            'd5 :mem_seq_rank[5 ] <= #TCQ 'd3;
            'd6 :mem_seq_rank[6 ] <= #TCQ 'd3;
            'd7 :mem_seq_rank[7 ] <= #TCQ 'd3;
            'd8 :mem_seq_rank[8 ] <= #TCQ 'd3;
            'd9 :mem_seq_rank[9 ] <= #TCQ 'd3;
            'd10:mem_seq_rank[10] <= #TCQ 'd3;
            'd11:mem_seq_rank[11] <= #TCQ 'd3;
            'd12:mem_seq_rank[12] <= #TCQ 'd3;
            'd13:mem_seq_rank[13] <= #TCQ 'd3;
            'd14:mem_seq_rank[14] <= #TCQ 'd3;
            default: /*default*/ ;
        endcase
    end
    else if(seq_rank_generate_cnt==4)begin
        case (mem_rank_seq[4])
            'd0 :mem_seq_rank[0 ] <= #TCQ 'd4;
            'd1 :mem_seq_rank[1 ] <= #TCQ 'd4;
            'd2 :mem_seq_rank[2 ] <= #TCQ 'd4;
            'd3 :mem_seq_rank[3 ] <= #TCQ 'd4;
            'd4 :mem_seq_rank[4 ] <= #TCQ 'd4;
            'd5 :mem_seq_rank[5 ] <= #TCQ 'd4;
            'd6 :mem_seq_rank[6 ] <= #TCQ 'd4;
            'd7 :mem_seq_rank[7 ] <= #TCQ 'd4;
            'd8 :mem_seq_rank[8 ] <= #TCQ 'd4;
            'd9 :mem_seq_rank[9 ] <= #TCQ 'd4;
            'd10:mem_seq_rank[10] <= #TCQ 'd4;
            'd11:mem_seq_rank[11] <= #TCQ 'd4;
            'd12:mem_seq_rank[12] <= #TCQ 'd4;
            'd13:mem_seq_rank[13] <= #TCQ 'd4;
            'd14:mem_seq_rank[14] <= #TCQ 'd4;
            default: /*default*/ ;
        endcase
    end
    else if(seq_rank_generate_cnt==5)begin
        case (mem_rank_seq[5])
            'd0 :mem_seq_rank[0 ] <= #TCQ 'd5;
            'd1 :mem_seq_rank[1 ] <= #TCQ 'd5;
            'd2 :mem_seq_rank[2 ] <= #TCQ 'd5;
            'd3 :mem_seq_rank[3 ] <= #TCQ 'd5;
            'd4 :mem_seq_rank[4 ] <= #TCQ 'd5;
            'd5 :mem_seq_rank[5 ] <= #TCQ 'd5;
            'd6 :mem_seq_rank[6 ] <= #TCQ 'd5;
            'd7 :mem_seq_rank[7 ] <= #TCQ 'd5;
            'd8 :mem_seq_rank[8 ] <= #TCQ 'd5;
            'd9 :mem_seq_rank[9 ] <= #TCQ 'd5;
            'd10:mem_seq_rank[10] <= #TCQ 'd5;
            'd11:mem_seq_rank[11] <= #TCQ 'd5;
            'd12:mem_seq_rank[12] <= #TCQ 'd5;
            'd13:mem_seq_rank[13] <= #TCQ 'd5;
            'd14:mem_seq_rank[14] <= #TCQ 'd5;
            default: /*default*/ ;
        endcase
    end
    else if(seq_rank_generate_cnt==6)begin
        case (mem_rank_seq[6])
            'd0 :mem_seq_rank[0 ] <= #TCQ 'd6;
            'd1 :mem_seq_rank[1 ] <= #TCQ 'd6;
            'd2 :mem_seq_rank[2 ] <= #TCQ 'd6;
            'd3 :mem_seq_rank[3 ] <= #TCQ 'd6;
            'd4 :mem_seq_rank[4 ] <= #TCQ 'd6;
            'd5 :mem_seq_rank[5 ] <= #TCQ 'd6;
            'd6 :mem_seq_rank[6 ] <= #TCQ 'd6;
            'd7 :mem_seq_rank[7 ] <= #TCQ 'd6;
            'd8 :mem_seq_rank[8 ] <= #TCQ 'd6;
            'd9 :mem_seq_rank[9 ] <= #TCQ 'd6;
            'd10:mem_seq_rank[10] <= #TCQ 'd6;
            'd11:mem_seq_rank[11] <= #TCQ 'd6;
            'd12:mem_seq_rank[12] <= #TCQ 'd6;
            'd13:mem_seq_rank[13] <= #TCQ 'd6;
            'd14:mem_seq_rank[14] <= #TCQ 'd6;
            default: /*default*/ ;
        endcase
    end
    else if(seq_rank_generate_cnt==7)begin
        case (mem_rank_seq[7])
            'd0 :mem_seq_rank[0 ] <= #TCQ 'd7;
            'd1 :mem_seq_rank[1 ] <= #TCQ 'd7;
            'd2 :mem_seq_rank[2 ] <= #TCQ 'd7;
            'd3 :mem_seq_rank[3 ] <= #TCQ 'd7;
            'd4 :mem_seq_rank[4 ] <= #TCQ 'd7;
            'd5 :mem_seq_rank[5 ] <= #TCQ 'd7;
            'd6 :mem_seq_rank[6 ] <= #TCQ 'd7;
            'd7 :mem_seq_rank[7 ] <= #TCQ 'd7;
            'd8 :mem_seq_rank[8 ] <= #TCQ 'd7;
            'd9 :mem_seq_rank[9 ] <= #TCQ 'd7;
            'd10:mem_seq_rank[10] <= #TCQ 'd7;
            'd11:mem_seq_rank[11] <= #TCQ 'd7;
            'd12:mem_seq_rank[12] <= #TCQ 'd7;
            'd13:mem_seq_rank[13] <= #TCQ 'd7;
            'd14:mem_seq_rank[14] <= #TCQ 'd7;
            default: /*default*/ ;
        endcase
    end
    else if(seq_rank_generate_cnt==8)begin
        case (mem_rank_seq[8])
            'd0 :mem_seq_rank[0 ] <= #TCQ 'd8;
            'd1 :mem_seq_rank[1 ] <= #TCQ 'd8;
            'd2 :mem_seq_rank[2 ] <= #TCQ 'd8;
            'd3 :mem_seq_rank[3 ] <= #TCQ 'd8;
            'd4 :mem_seq_rank[4 ] <= #TCQ 'd8;
            'd5 :mem_seq_rank[5 ] <= #TCQ 'd8;
            'd6 :mem_seq_rank[6 ] <= #TCQ 'd8;
            'd7 :mem_seq_rank[7 ] <= #TCQ 'd8;
            'd8 :mem_seq_rank[8 ] <= #TCQ 'd8;
            'd9 :mem_seq_rank[9 ] <= #TCQ 'd8;
            'd10:mem_seq_rank[10] <= #TCQ 'd8;
            'd11:mem_seq_rank[11] <= #TCQ 'd8;
            'd12:mem_seq_rank[12] <= #TCQ 'd8;
            'd13:mem_seq_rank[13] <= #TCQ 'd8;
            'd14:mem_seq_rank[14] <= #TCQ 'd8;
            default: /*default*/ ;
        endcase
    end
    else if(seq_rank_generate_cnt==9)begin
        case (mem_rank_seq[9])
            'd0 :mem_seq_rank[0 ] <= #TCQ 'd9;
            'd1 :mem_seq_rank[1 ] <= #TCQ 'd9;
            'd2 :mem_seq_rank[2 ] <= #TCQ 'd9;
            'd3 :mem_seq_rank[3 ] <= #TCQ 'd9;
            'd4 :mem_seq_rank[4 ] <= #TCQ 'd9;
            'd5 :mem_seq_rank[5 ] <= #TCQ 'd9;
            'd6 :mem_seq_rank[6 ] <= #TCQ 'd9;
            'd7 :mem_seq_rank[7 ] <= #TCQ 'd9;
            'd8 :mem_seq_rank[8 ] <= #TCQ 'd9;
            'd9 :mem_seq_rank[9 ] <= #TCQ 'd9;
            'd10:mem_seq_rank[10] <= #TCQ 'd9;
            'd11:mem_seq_rank[11] <= #TCQ 'd9;
            'd12:mem_seq_rank[12] <= #TCQ 'd9;
            'd13:mem_seq_rank[13] <= #TCQ 'd9;
            'd14:mem_seq_rank[14] <= #TCQ 'd9;
            default: /*default*/ ;
        endcase
    end
    else if(seq_rank_generate_cnt==10)begin
        case (mem_rank_seq[10])
            'd0 :mem_seq_rank[0 ] <= #TCQ 'd10;
            'd1 :mem_seq_rank[1 ] <= #TCQ 'd10;
            'd2 :mem_seq_rank[2 ] <= #TCQ 'd10;
            'd3 :mem_seq_rank[3 ] <= #TCQ 'd10;
            'd4 :mem_seq_rank[4 ] <= #TCQ 'd10;
            'd5 :mem_seq_rank[5 ] <= #TCQ 'd10;
            'd6 :mem_seq_rank[6 ] <= #TCQ 'd10;
            'd7 :mem_seq_rank[7 ] <= #TCQ 'd10;
            'd8 :mem_seq_rank[8 ] <= #TCQ 'd10;
            'd9 :mem_seq_rank[9 ] <= #TCQ 'd10;
            'd10:mem_seq_rank[10] <= #TCQ 'd10;
            'd11:mem_seq_rank[11] <= #TCQ 'd10;
            'd12:mem_seq_rank[12] <= #TCQ 'd10;
            'd13:mem_seq_rank[13] <= #TCQ 'd10;
            'd14:mem_seq_rank[14] <= #TCQ 'd10;
            default: /*default*/ ;
        endcase
    end
    else if(seq_rank_generate_cnt==11)begin
        case (mem_rank_seq[11])
            'd0 :mem_seq_rank[0 ] <= #TCQ 'd11;
            'd1 :mem_seq_rank[1 ] <= #TCQ 'd11;
            'd2 :mem_seq_rank[2 ] <= #TCQ 'd11;
            'd3 :mem_seq_rank[3 ] <= #TCQ 'd11;
            'd4 :mem_seq_rank[4 ] <= #TCQ 'd11;
            'd5 :mem_seq_rank[5 ] <= #TCQ 'd11;
            'd6 :mem_seq_rank[6 ] <= #TCQ 'd11;
            'd7 :mem_seq_rank[7 ] <= #TCQ 'd11;
            'd8 :mem_seq_rank[8 ] <= #TCQ 'd11;
            'd9 :mem_seq_rank[9 ] <= #TCQ 'd11;
            'd10:mem_seq_rank[10] <= #TCQ 'd11;
            'd11:mem_seq_rank[11] <= #TCQ 'd11;
            'd12:mem_seq_rank[12] <= #TCQ 'd11;
            'd13:mem_seq_rank[13] <= #TCQ 'd11;
            'd14:mem_seq_rank[14] <= #TCQ 'd11;
            default: /*default*/ ;
        endcase
    end
    else if(seq_rank_generate_cnt==12)begin
        case (mem_rank_seq[12])
            'd0 :mem_seq_rank[0 ] <= #TCQ 'd12;
            'd1 :mem_seq_rank[1 ] <= #TCQ 'd12;
            'd2 :mem_seq_rank[2 ] <= #TCQ 'd12;
            'd3 :mem_seq_rank[3 ] <= #TCQ 'd12;
            'd4 :mem_seq_rank[4 ] <= #TCQ 'd12;
            'd5 :mem_seq_rank[5 ] <= #TCQ 'd12;
            'd6 :mem_seq_rank[6 ] <= #TCQ 'd12;
            'd7 :mem_seq_rank[7 ] <= #TCQ 'd12;
            'd8 :mem_seq_rank[8 ] <= #TCQ 'd12;
            'd9 :mem_seq_rank[9 ] <= #TCQ 'd12;
            'd10:mem_seq_rank[10] <= #TCQ 'd12;
            'd11:mem_seq_rank[11] <= #TCQ 'd12;
            'd12:mem_seq_rank[12] <= #TCQ 'd12;
            'd13:mem_seq_rank[13] <= #TCQ 'd12;
            'd14:mem_seq_rank[14] <= #TCQ 'd12;
            default: /*default*/ ;
        endcase
    end
    else if(seq_rank_generate_cnt==13)begin
        case (mem_rank_seq[13])
            'd0 :mem_seq_rank[0 ] <= #TCQ 'd13;
            'd1 :mem_seq_rank[1 ] <= #TCQ 'd13;
            'd2 :mem_seq_rank[2 ] <= #TCQ 'd13;
            'd3 :mem_seq_rank[3 ] <= #TCQ 'd13;
            'd4 :mem_seq_rank[4 ] <= #TCQ 'd13;
            'd5 :mem_seq_rank[5 ] <= #TCQ 'd13;
            'd6 :mem_seq_rank[6 ] <= #TCQ 'd13;
            'd7 :mem_seq_rank[7 ] <= #TCQ 'd13;
            'd8 :mem_seq_rank[8 ] <= #TCQ 'd13;
            'd9 :mem_seq_rank[9 ] <= #TCQ 'd13;
            'd10:mem_seq_rank[10] <= #TCQ 'd13;
            'd11:mem_seq_rank[11] <= #TCQ 'd13;
            'd12:mem_seq_rank[12] <= #TCQ 'd13;
            'd13:mem_seq_rank[13] <= #TCQ 'd13;
            'd14:mem_seq_rank[14] <= #TCQ 'd13;
            default: /*default*/ ;
        endcase
    end
    else if(seq_rank_generate_cnt==14)begin
        case (mem_rank_seq[14])
            'd0 :mem_seq_rank[0 ] <= #TCQ 'd14;
            'd1 :mem_seq_rank[1 ] <= #TCQ 'd14;
            'd2 :mem_seq_rank[2 ] <= #TCQ 'd14;
            'd3 :mem_seq_rank[3 ] <= #TCQ 'd14;
            'd4 :mem_seq_rank[4 ] <= #TCQ 'd14;
            'd5 :mem_seq_rank[5 ] <= #TCQ 'd14;
            'd6 :mem_seq_rank[6 ] <= #TCQ 'd14;
            'd7 :mem_seq_rank[7 ] <= #TCQ 'd14;
            'd8 :mem_seq_rank[8 ] <= #TCQ 'd14;
            'd9 :mem_seq_rank[9 ] <= #TCQ 'd14;
            'd10:mem_seq_rank[10] <= #TCQ 'd14;
            'd11:mem_seq_rank[11] <= #TCQ 'd14;
            'd12:mem_seq_rank[12] <= #TCQ 'd14;
            'd13:mem_seq_rank[13] <= #TCQ 'd14;
            'd14:mem_seq_rank[14] <= #TCQ 'd14;
            default: /*default*/ ;
        endcase
    end
end

always @(posedge clk_i) begin
    reorder_vld    <= #TCQ seq_rank_generate_cnt=='d15;
    reorder_rank0  <= #TCQ mem_data_seq[mem_seq_rank[0]];
    reorder_rank1  <= #TCQ mem_data_seq[mem_seq_rank[1]];
    reorder_rank2  <= #TCQ mem_data_seq[mem_seq_rank[2]];
    reorder_rank3  <= #TCQ mem_data_seq[mem_seq_rank[3]];
    reorder_rank4  <= #TCQ mem_data_seq[mem_seq_rank[4]];
    reorder_rank5  <= #TCQ mem_data_seq[mem_seq_rank[5]];
    reorder_rank6  <= #TCQ mem_data_seq[mem_seq_rank[6]];
    reorder_rank7  <= #TCQ mem_data_seq[mem_seq_rank[7]];
end

assign reorder_vld_o    = reorder_vld  ;
assign reorder_rank0_o  = reorder_rank0;
assign reorder_rank1_o  = reorder_rank1;
assign reorder_rank2_o  = reorder_rank2;
assign reorder_rank3_o  = reorder_rank3;
assign reorder_rank4_o  = reorder_rank4;
assign reorder_rank5_o  = reorder_rank5;
assign reorder_rank6_o  = reorder_rank6;
assign reorder_rank7_o  = reorder_rank7;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    
endmodule