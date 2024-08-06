//~ `New testbench
`timescale  1ns / 1ps

module tb_FIR;

// FIR Parameters
parameter PERIOD           = 10;
parameter FIR_TAP_WIDTH    = 16;
parameter SAXI_DATA_WIDTH  = 16;
parameter MAXI_DATA_WIDTH  = 32;
parameter KEEP_WIDTH       = 4 ;

// FIR Inputs
reg   clk_i                                = 0 ;
reg   rst_i                                = 1 ;
reg   [SAXI_DATA_WIDTH-1:0]  s_axis_fir_tdata_i = 0 ;
reg   [KEEP_WIDTH-1:0]  s_axis_fir_tkeep_i = 0 ;
reg   s_axis_fir_tlast_i                   = 0 ;
reg   s_axis_fir_tvalid_i                  = 0 ;
reg   m_axis_fir_tready_i                  = 0 ;

// FIR Outputs
wire  m_axis_fir_tvalid_o                  ;
wire  s_axis_fir_tready_o                  ;
wire  m_axis_fir_tlast_o                   ;
wire  [KEEP_WIDTH-1:0]  m_axis_fir_tkeep_o ;
wire  [MAXI_DATA_WIDTH-1:0]  m_axis_fir_tdata_o ;


initial
begin
    forever #(PERIOD/2)  clk_i=~clk_i;
end

initial
begin
    #(PERIOD*2) rst_i  =  0;
end

FIR #(
    .FIR_TAP_WIDTH   ( FIR_TAP_WIDTH   ),
    .SAXI_DATA_WIDTH ( SAXI_DATA_WIDTH ),
    .MAXI_DATA_WIDTH ( MAXI_DATA_WIDTH ),
    .KEEP_WIDTH      ( KEEP_WIDTH      ))
 u_FIR (
    .clk_i                   ( clk_i                                      ),
    .rst_i                   ( rst_i                                      ),
    .s_axis_fir_tdata_i      ( s_axis_fir_tdata_i   [SAXI_DATA_WIDTH-1:0] ),
    .s_axis_fir_tkeep_i      ( s_axis_fir_tkeep_i   [KEEP_WIDTH-1:0]      ),
    .s_axis_fir_tlast_i      ( s_axis_fir_tlast_i                         ),
    .s_axis_fir_tvalid_i     ( s_axis_fir_tvalid_i                        ),
    .m_axis_fir_tready_i     ( m_axis_fir_tready_i                        ),

    .m_axis_fir_tvalid_o     ( m_axis_fir_tvalid_o                        ),
    .s_axis_fir_tready_o     ( s_axis_fir_tready_o                        ),
    .m_axis_fir_tlast_o      ( m_axis_fir_tlast_o                         ),
    .m_axis_fir_tkeep_o      ( m_axis_fir_tkeep_o   [KEEP_WIDTH-1:0]      ),
    .m_axis_fir_tdata_o      ( m_axis_fir_tdata_o   [MAXI_DATA_WIDTH-1:0] )
);


always @(posedge clk_i) begin
    if(s_axis_fir_tready_o)begin
        s_axis_fir_tvalid_i <= 'd1;
        s_axis_fir_tdata_i <= s_axis_fir_tdata_i + 1;
    end
end

initial
begin
    m_axis_fir_tready_i = 1;
    $finish;
end

endmodule