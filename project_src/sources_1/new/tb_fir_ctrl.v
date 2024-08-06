`timescale  1ns / 1ps

module tb_fir_ctrl;

// fir_ctrl Parameters
parameter PERIOD         = 10 ;
parameter TCQ            = 0.1;
parameter FIR_TAP_WIDTH  = 32 ;
parameter DATA_WIDTH     = 16 ;

// fir_ctrl Inputs
reg   clk_i                                = 0 ;
reg   rst_i                                = 0 ;
reg   fir_tap_vld_i                        = 0 ;
reg   [10-1:0]  fir_tap_addr_i             = 0 ;
reg   [FIR_TAP_WIDTH-1:0]  fir_tap_data_i  = 0 ;
// wire   [FIR_TAP_WIDTH-1:0]  fir_tap_data_i  ;
reg   [10-1:0]  fir_tap_num_i              = 0 ;
reg   laser_vld_i                          = 0 ;
reg   [DATA_WIDTH-1:0]  laser_data_i       = 0 ;

// fir_ctrl Outputs
wire  fir_laser_vld_o                      ;
wire  [DATA_WIDTH-1:0]  fir_laser_data_o   ;


reg                        fir_tap_rd_vld            = 0  ;
reg    [32-1:0]            fir_tap_rd_data          = 0   ;
wire                        fir_tap_rd_en               ;
reg                        fir_tap_ready            = 0   ;

initial
begin
    forever #(PERIOD/2)  clk_i=~clk_i;
end

initial
begin
    rst_i  =  1;
    #(PERIOD*2);
    rst_i  =  0;
end
reg real_adc_start = 0;

fir_ctrl #(
    .FIR_TAP_WIDTH                  ( 32                                ),
    .DATA_WIDTH                     ( 32                                )
)fir_ctrl_inst (
    .clk_i                          ( clk_i                             ),
    .rst_i                          ( rst_i                             ),

    .laser_fir_upmode_i             ( 0                  ),
    .laser_fir_en_i                 ( 1                      ),
    .laser_start_i                  ( real_adc_start                    ),

    .fir_tap_para_vld_i             ( fir_tap_rd_vld                    ),
    .fir_tap_para_data_i            ( fir_tap_rd_data                   ),
    .fir_tap_para_ren_o             ( fir_tap_rd_en                     ),
    .fir_tap_ready_i                ( fir_tap_ready                     ),

    .encode_zero_flag_i             ( wafer_zero_flag                   ),
    .lp_recover_acc_flag_i          ( lp_recover_acc_flag               ),
    .laser_vld_i                    ( laser_vld_i                       ),
    .laser_data_i                   ( laser_data_i                      ),

    .fir_zero_flag_o                ( fir_zero_flag                     ),
    .fir_acc_flag_o                 ( fir_acc_demo_flag                 ),
    .fir_laser_vld_o                ( fir_laser_vld                     ),
    .fir_laser_data_o               ( fir_laser_data                    )
);

reg [32-1:0] mem [0:127];
initial begin
    // $readmemh("D:/work/FIR/simulate.csv",mem);
    $readmemh("D:/work/FIR/20240416150925_transpose.csv",mem);
end

reg [7-1:0] fir_tap_rd_addr = 0;
always @(*) begin
    fir_tap_rd_data = mem[fir_tap_rd_addr];
end

always @(posedge clk_i) begin
    if(fir_tap_rd_en)begin
        fir_tap_rd_vld <= #TCQ 'd1;
    end
    else 
        fir_tap_rd_vld <= #TCQ 'd0;
end

always @(posedge clk_i) begin
    if(fir_tap_rd_vld)
        fir_tap_rd_addr <= #TCQ fir_tap_rd_addr + 1;
    
end

always @(posedge clk_i) begin
    if(fir_tap_vld_i)
        fir_tap_addr_i <= #TCQ fir_tap_addr_i + 1;
end

reg real_adc_start_d = 'd0;
always @(posedge clk_i) begin
    real_adc_start_d <= #TCQ real_adc_start;
end

always @(posedge clk_i) begin
    if(real_adc_start_d)begin
        laser_vld_i <= #TCQ 'd1;
        laser_data_i <= #TCQ laser_data_i + 1;
    end
    else 
        laser_vld_i <= #TCQ 'd0;
end


initial
begin
    wait(~rst_i);
    #(PERIOD*100);
    real_adc_start = 1;
    #(PERIOD*200);
    $finish;
end

endmodule