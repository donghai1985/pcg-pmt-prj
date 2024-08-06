`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: zas
// Engineer: songyuxin
// 
// Create Date: 2024/01/31
// Design Name: 
// Module Name: laser_aom_ctrl
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


module laser_aom_ctrl #(
    parameter                       TCQ         = 0.1 

)(
    // clk & rst
    input                           clk_i                   ,
    input                           rst_i                   ,
    
    input                           laser_control_i         ,
    input                           laser_out_switch_i      ,
    input       [12-1:0]            laser_analog_max_i      ,
    input       [12-1:0]            laser_analog_min_i      ,
    input       [32-1:0]            laser_analog_pwm_i      ,
    input       [32-1:0]            laser_analog_cycle_i    ,
    input       [12-1:0]            laser_analog_uplimit_i  ,
    input       [12-1:0]            laser_analog_lowlimit_i ,
    input                           laser_analog_mode_sel_i ,
    input                           laser_analog_trigger_i  ,

    input                           acc_job_control_i       ,
    input                           acc_job_init_switch_i   ,
    input                           acc_job_init_vol_trig_i ,
    input       [12-1:0]            acc_job_init_vol_i      ,
    input                           acc_aom_flag_i          ,
    input       [12-1:0]            acc_aom_class0_i        ,
    input       [12-1:0]            acc_aom_class1_i        ,
    input       [12-1:0]            acc_aom_class2_i        ,
    input       [12-1:0]            acc_aom_class3_i        ,
    input       [12-1:0]            acc_aom_class4_i        ,
    input       [12-1:0]            acc_aom_class5_i        ,
    input       [12-1:0]            acc_aom_class6_i        ,
    input       [12-1:0]            acc_aom_class7_i        ,
    // input       [12-1:0]            acc_aom_class_i         ,

    // function safety, aom overload
    input       [12-1:0]            aom_overload_vol_thre_i ,
    input       [32-1:0]            aom_overload_timeout_i  ,
    
    // interface    
    output                          LASER_CONTROL           ,
    output                          LASER_OUT_SWITCH        ,
    output                          laser_aom_en_o          ,
    output      [12-1:0]            laser_aom_voltage_o     
);


//////////////////////////////////////////////////////////////////////////////////
// *********** Define Parameter Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
localparam                          ST_IDLE             = 'd0;
localparam                          ST_INTER_CTRL       = 'd1;
localparam                          ST_NEXT_EXTER       = 'd2;
localparam                          ST_EXTER_CTRL       = 'd3;
localparam                          ST_NEXT_INTER       = 'd4;
localparam                          ST_TRIGGER          = 'd5;


//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Define Register Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
reg             [3-1:0]             state                   = ST_IDLE;
reg             [3-1:0]             next_state              = ST_IDLE;

reg                                 laser_out_switch_d      = 'd0;
reg             [6-1:0]             aom_switch_wait_cnt     = 'd0;
reg                                 laser_aom_en            = 'd0;
reg             [12-1:0]            laser_aom_voltage       = 'd0;
reg             [32-1:0]            aom_pwm_cycle_cnt       = 'd0;
reg                                 aom_pwm_flag            = 'd1;
reg             [12-1:0]            laser_analog_max        = 'd0;
reg             [12-1:0]            laser_analog_min        = 'd0;
reg                                 aom_pwm_flag_d          = 'd0;
reg                                 laser_out_switch_r      = 'd0;

reg                                 acc_job_aom_en          = 'd0;
reg             [12-1:0]            acc_job_aom_voltage     = 'd0;
reg                                 acc_laser_out_switch    = 'd0;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<



//////////////////////////////////////////////////////////////////////////////////
// *********** Define Wire Signal
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
wire                                aom_switch_exter        ;
wire                                aom_switch_inter        ;
wire                                aom_switch_wait         ;
wire            [32-1:0]            laser_analog_low_time   ;
wire                                aom_pwm_pose            ; 
wire                                aom_pwm_nege            ; 
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<





//////////////////////////////////////////////////////////////////////////////////
// *********** Instance Module
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

//////////////////////////////////////////////////////////////////////////////////
// *********** Logic Design
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
always @(posedge clk_i) laser_out_switch_d <= #TCQ laser_out_switch_i;
assign aom_switch_exter = (~laser_out_switch_d) &&   laser_out_switch_i;
assign aom_switch_inter = laser_out_switch_d    && (~laser_out_switch_i);

always @(posedge clk_i) begin
    if(next_state==ST_NEXT_INTER || next_state==ST_NEXT_EXTER)
        aom_switch_wait_cnt <= #TCQ aom_switch_wait_cnt + 1;
    else 
        aom_switch_wait_cnt <= #TCQ 'd0;
end

assign aom_switch_wait = (&aom_switch_wait_cnt);

always @(posedge clk_i) begin
    if(rst_i)
        state <= #TCQ ST_IDLE;
    else 
        state <= #TCQ next_state;
end

always @(*) begin
    next_state = state;
    case (state)
        ST_IDLE: begin
            if(laser_out_switch_i)
                next_state = ST_EXTER_CTRL;
            else 
                next_state = ST_INTER_CTRL;
        end

        ST_INTER_CTRL: begin
            if(aom_switch_exter)
                next_state = ST_NEXT_EXTER;
        end

        ST_NEXT_EXTER: begin
            if(aom_switch_wait && (~laser_analog_mode_sel_i))
                next_state = ST_EXTER_CTRL;
            else if(aom_switch_wait && laser_analog_mode_sel_i)
                next_state = ST_TRIGGER;
        end
        
        ST_EXTER_CTRL: begin
            if(aom_switch_inter)
                next_state = ST_NEXT_INTER;
            else if(laser_analog_mode_sel_i)
                next_state = ST_TRIGGER;
        end

        ST_TRIGGER: begin
            if(aom_switch_inter)
                next_state = ST_NEXT_INTER;
            else if(~laser_analog_mode_sel_i)
                next_state = ST_EXTER_CTRL;
        end

        ST_NEXT_INTER: begin
            if(aom_switch_wait)
                next_state = ST_INTER_CTRL;
        end
        default:
                next_state = ST_IDLE;
    endcase
end

assign laser_analog_low_time = laser_analog_cycle_i - laser_analog_pwm_i;

always @(posedge clk_i) begin
    if(laser_analog_max_i >= laser_analog_uplimit_i)
        laser_analog_max <= #TCQ laser_analog_uplimit_i;
    else 
        laser_analog_max <= #TCQ laser_analog_max_i;
end

always @(posedge clk_i) begin
    if(laser_analog_min_i <= laser_analog_lowlimit_i)
        laser_analog_min <= #TCQ laser_analog_lowlimit_i;
    else 
        laser_analog_min <= #TCQ laser_analog_min_i;
end

always @(posedge clk_i) begin
    if(state==ST_EXTER_CTRL)begin
        if(aom_pwm_flag ^ aom_pwm_flag_d)
            aom_pwm_cycle_cnt <= #TCQ 'd1;
        else 
            aom_pwm_cycle_cnt <= #TCQ aom_pwm_cycle_cnt + 1;
    end
    else if(state==ST_TRIGGER)begin
        if(~aom_pwm_flag)
            aom_pwm_cycle_cnt <= #TCQ 'd1;
        else 
            aom_pwm_cycle_cnt <= #TCQ aom_pwm_cycle_cnt + 1;
    end
    else
        aom_pwm_cycle_cnt <= #TCQ 'd1;
end

always @(posedge clk_i) begin
    if(state==ST_IDLE)
        aom_pwm_flag <= #TCQ 'd1;
    else if(state==ST_NEXT_INTER)
        aom_pwm_flag <= #TCQ 'd1;
    else if(state==ST_EXTER_CTRL)begin
        if(aom_pwm_flag && (aom_pwm_cycle_cnt==laser_analog_pwm_i-1))
            aom_pwm_flag <= #TCQ 'd0;
        else if(~aom_pwm_flag && (aom_pwm_cycle_cnt==laser_analog_low_time-1))
            aom_pwm_flag <= #TCQ 'd1;
    end 
    else if(state==ST_TRIGGER)begin
        if(~aom_pwm_flag && laser_analog_trigger_i)
            aom_pwm_flag <= #TCQ 'd1;
        else if(aom_pwm_flag && (aom_pwm_cycle_cnt==laser_analog_pwm_i-1))
            aom_pwm_flag <= #TCQ 'd0;
    end
end

always @(posedge clk_i) aom_pwm_flag_d <= #TCQ aom_pwm_flag;
assign aom_pwm_pose = ~aom_pwm_flag_d && aom_pwm_flag;
assign aom_pwm_nege = aom_pwm_flag_d && (~aom_pwm_flag);

always @(posedge clk_i) begin
    if(state==ST_INTER_CTRL && aom_switch_exter)begin
        laser_aom_en        <= #TCQ 'd1;
        laser_aom_voltage   <= #TCQ laser_analog_max_i;
    end
    else if(state==ST_EXTER_CTRL || state==ST_TRIGGER || state==ST_NEXT_INTER)begin
        if(aom_pwm_pose)begin
            laser_aom_en        <= #TCQ 'd1;
            laser_aom_voltage   <= #TCQ laser_analog_max;
        end
        else if(aom_pwm_nege)begin
            laser_aom_en        <= #TCQ 'd1;
            laser_aom_voltage   <= #TCQ laser_analog_min;
        end
        else 
            laser_aom_en        <= #TCQ 'd0;
    end
    else begin
        laser_aom_en        <= #TCQ 'd0;
    end
end


always @(posedge clk_i) begin
    if(rst_i)
        laser_out_switch_r <= #TCQ laser_out_switch_i;
    else if(state==ST_EXTER_CTRL || state==ST_TRIGGER)
        laser_out_switch_r <= #TCQ 'd1;
    else if(state==ST_INTER_CTRL)
        laser_out_switch_r <= #TCQ 'd0;
end


// acc job control
reg     acc_job_control_d0 = 'd0;
reg     acc_aom_flag_d0 = 'd0;
always @(posedge clk_i) acc_job_control_d0 <= #TCQ acc_job_control_i;
always @(posedge clk_i) acc_aom_flag_d0 <= #TCQ acc_aom_flag_i;

wire acc_job_ctrl_pose = ~acc_job_control_d0 && acc_job_control_i;

always @(posedge clk_i) begin
    if(acc_job_ctrl_pose)begin
        acc_job_aom_en      <= #TCQ 'd1;
        acc_job_aom_voltage <= #TCQ acc_job_init_vol_i;
    end
    else if(acc_job_init_vol_trig_i)begin
        acc_job_aom_en      <= #TCQ 'd1;
        acc_job_aom_voltage <= #TCQ acc_job_init_vol_i;
    end
    else if(~acc_aom_flag_d0 && acc_aom_flag_i)begin
        acc_job_aom_en      <= #TCQ 'd1;
        acc_job_aom_voltage <= #TCQ acc_aom_class1_i;
    end
    else if(acc_aom_flag_d0 && (~acc_aom_flag_i))begin
        acc_job_aom_en      <= #TCQ 'd1;
        acc_job_aom_voltage <= #TCQ acc_job_init_vol_i;
    end
    else begin
        acc_job_aom_en      <= #TCQ 'd0;
    end
end


always @(posedge clk_i) begin
    if(acc_job_control_d0)
        acc_laser_out_switch <= #TCQ acc_aom_flag_d0;
    else 
        acc_laser_out_switch <= #TCQ laser_out_switch_r;
end

assign LASER_CONTROL        = laser_control_i       ;
assign LASER_OUT_SWITCH     = acc_job_control_d0 ? acc_laser_out_switch : laser_out_switch_r    ;
assign laser_aom_en_o       = acc_job_control_d0 ? acc_job_aom_en      : laser_aom_en          ;
assign laser_aom_voltage_o  = acc_job_control_d0 ? acc_job_aom_voltage : laser_aom_voltage     ;
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


endmodule
