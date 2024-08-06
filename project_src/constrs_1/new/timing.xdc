create_clock -period 10.000 -name FPGA_MASTER_CLOCK [get_ports FPGA_MASTER_CLOCK_P]
create_clock -period 10.000 -name TIMING_SYNC_REFCLK [get_ports TIMING_SYNC_REFCLK_P]
create_clock -period 10.000 -name AD9265_DCO [get_ports AD9265_DCO]
create_clock -period 6.400 -name SFP_MGT_REFCLK_C_P [get_ports SFP_MGT_REFCLK_C_P]
create_clock -period 20.000 -name FPGA_TO_SFPGA_RESERVE0 [get_ports FPGA_TO_SFPGA_RESERVE0]

set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets FPGA_TO_SFPGA_RESERVE0]

set_clock_groups -name async_clk_group -asynchronous -group [get_clocks -include_generated_clocks FPGA_MASTER_CLOCK] -group [get_clocks -include_generated_clocks TIMING_SYNC_REFCLK] -group [get_clocks AD9265_DCO] -group [get_clocks -include_generated_clocks SFP_MGT_REFCLK_C_P] -group [get_clocks FPGA_TO_SFPGA_RESERVE0]

set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins u_ddr_top/mem_ctrl_inst/ddr3_mig_inst/u_ddr3_mig_mig/u_ddr3_infrastructure/gen_mmcm.mmcm_i/CLKFBOUT] -filter {IS_GENERATED && MASTER_CLOCK == pll_clk3_out}] -group [get_clocks -of_objects [get_pins pll_inst/inst/mmcm_adv_inst/CLKOUT0] -filter {IS_GENERATED && MASTER_CLOCK == FPGA_MASTER_CLOCK}]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins pll_inst/inst/mmcm_adv_inst/CLKOUT0] -filter {IS_GENERATED && MASTER_CLOCK == FPGA_MASTER_CLOCK}] -group [get_clocks -of_objects [get_pins u_ddr_top/mem_ctrl_inst/ddr3_mig_inst/u_ddr3_mig_mig/u_ddr3_infrastructure/gen_mmcm.mmcm_i/CLKFBOUT] -filter {IS_GENERATED && MASTER_CLOCK == pll_clk3_out}]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins pll_inst/inst/mmcm_adv_inst/CLKOUT0] -filter {IS_GENERATED && MASTER_CLOCK == TIMING_SYNC_REFCLK}] -group [get_clocks -of_objects [get_pins u_ddr_top/mem_ctrl_inst/ddr3_mig_inst/u_ddr3_mig_mig/u_ddr3_infrastructure/gen_mmcm.mmcm_i/CLKFBOUT] -filter {IS_GENERATED && MASTER_CLOCK == pll_clk3_out_1}]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins u_ddr_top/mem_ctrl_inst/ddr3_mig_inst/u_ddr3_mig_mig/u_ddr3_infrastructure/gen_mmcm.mmcm_i/CLKFBOUT] -filter {IS_GENERATED && MASTER_CLOCK == pll_clk3_out_1}] -group [get_clocks -of_objects [get_pins pll_inst/inst/mmcm_adv_inst/CLKOUT0] -filter {IS_GENERATED && MASTER_CLOCK == TIMING_SYNC_REFCLK}]

# set_false_path -from [get_pins scan_flag_generate_inst/pmt_scan_en_reg/C] -to [get_pins laser_particle_detect_inst/laser_start_d1_reg/D]