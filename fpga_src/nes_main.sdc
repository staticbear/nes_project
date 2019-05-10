## Generated SDC file "nes_main.sdc"

## Copyright (C) 1991-2013 Altera Corporation
## Your use of Altera Corporation's design tools, logic functions 
## and other software and tools, and its AMPP partner logic 
## functions, and any output files from any of the foregoing 
## (including device programming or simulation files), and any 
## associated documentation or information are expressly subject 
## to the terms and conditions of the Altera Program License 
## Subscription Agreement, Altera MegaCore Function License 
## Agreement, or other applicable license agreement, including, 
## without limitation, that your use is for the sole purpose of 
## programming logic devices manufactured by Altera and sold by 
## Altera or its authorized distributors.  Please refer to the 
## applicable agreement for further details.


## VENDOR  "Altera"
## PROGRAM "Quartus II"
## VERSION "Version 13.1.0 Build 162 10/23/2013 SJ Full Version"

## DATE    "Fri Jan 08 04:31:05 2016"

##
## DEVICE  "5CSEMA5F31C6"
##


#**************************************************************
# Time Information
#**************************************************************

set_time_format -unit ns -decimal_places 3



#**************************************************************
# Create Clock
#**************************************************************

create_clock -name {ref_clk} -period 20.000 -waveform { 0.000 10.000 } [get_ports {ref_clk}]


#**************************************************************
# Create Generated Clock
#**************************************************************

create_generated_clock -name {syspll_new_0|syspll_new_inst|altera_pll_i|general[0].gpll~FRACTIONAL_PLL|vcoph[0]} -source [get_pins {syspll_new_0|syspll_new_inst|altera_pll_i|general[0].gpll~FRACTIONAL_PLL|refclkin}] -duty_cycle 50.000 -multiply_by 14 -master_clock {ref_clk} [get_pins {syspll_new_0|syspll_new_inst|altera_pll_i|general[0].gpll~FRACTIONAL_PLL|vcoph[0]}] 
create_generated_clock -name {syspll_new_0|syspll_new_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk} -source [get_pins {syspll_new_0|syspll_new_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|vco0ph[0]}] -duty_cycle 50.000 -multiply_by 1 -divide_by 7 -master_clock {syspll_new_0|syspll_new_inst|altera_pll_i|general[0].gpll~FRACTIONAL_PLL|vcoph[0]} [get_pins {syspll_new_0|syspll_new_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] 
create_generated_clock -name {syspll_new_0|syspll_new_inst|altera_pll_i|general[1].gpll~PLL_OUTPUT_COUNTER|divclk} -source [get_pins {syspll_new_0|syspll_new_inst|altera_pll_i|general[1].gpll~PLL_OUTPUT_COUNTER|vco0ph[0]}] -duty_cycle 50.000 -multiply_by 1 -divide_by 38 -master_clock {syspll_new_0|syspll_new_inst|altera_pll_i|general[0].gpll~FRACTIONAL_PLL|vcoph[0]} [get_pins {syspll_new_0|syspll_new_inst|altera_pll_i|general[1].gpll~PLL_OUTPUT_COUNTER|divclk}] 


#**************************************************************
# Set Clock Latency
#**************************************************************



#**************************************************************
# Set Clock Uncertainty
#**************************************************************

set_clock_uncertainty -rise_from [get_clocks {syspll_new_0|syspll_new_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -rise_to [get_clocks {syspll_new_0|syspll_new_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -setup 0.070  
set_clock_uncertainty -rise_from [get_clocks {syspll_new_0|syspll_new_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -rise_to [get_clocks {syspll_new_0|syspll_new_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -hold 0.060  
set_clock_uncertainty -rise_from [get_clocks {syspll_new_0|syspll_new_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -fall_to [get_clocks {syspll_new_0|syspll_new_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -setup 0.070  
set_clock_uncertainty -rise_from [get_clocks {syspll_new_0|syspll_new_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -fall_to [get_clocks {syspll_new_0|syspll_new_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -hold 0.060  
set_clock_uncertainty -fall_from [get_clocks {syspll_new_0|syspll_new_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -rise_to [get_clocks {syspll_new_0|syspll_new_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -setup 0.070  
set_clock_uncertainty -fall_from [get_clocks {syspll_new_0|syspll_new_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -rise_to [get_clocks {syspll_new_0|syspll_new_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -hold 0.060  
set_clock_uncertainty -fall_from [get_clocks {syspll_new_0|syspll_new_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -fall_to [get_clocks {syspll_new_0|syspll_new_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -setup 0.070  
set_clock_uncertainty -fall_from [get_clocks {syspll_new_0|syspll_new_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -fall_to [get_clocks {syspll_new_0|syspll_new_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -hold 0.060  
set_clock_uncertainty -rise_from [get_clocks {syspll_new_0|syspll_new_inst|altera_pll_i|general[0].gpll~FRACTIONAL_PLL|vcoph[0]}] -rise_to [get_clocks {syspll_new_0|syspll_new_inst|altera_pll_i|general[0].gpll~FRACTIONAL_PLL|vcoph[0]}] -setup 0.070  
set_clock_uncertainty -rise_from [get_clocks {syspll_new_0|syspll_new_inst|altera_pll_i|general[0].gpll~FRACTIONAL_PLL|vcoph[0]}] -rise_to [get_clocks {syspll_new_0|syspll_new_inst|altera_pll_i|general[0].gpll~FRACTIONAL_PLL|vcoph[0]}] -hold 0.060  
set_clock_uncertainty -rise_from [get_clocks {syspll_new_0|syspll_new_inst|altera_pll_i|general[0].gpll~FRACTIONAL_PLL|vcoph[0]}] -fall_to [get_clocks {syspll_new_0|syspll_new_inst|altera_pll_i|general[0].gpll~FRACTIONAL_PLL|vcoph[0]}] -setup 0.070  
set_clock_uncertainty -rise_from [get_clocks {syspll_new_0|syspll_new_inst|altera_pll_i|general[0].gpll~FRACTIONAL_PLL|vcoph[0]}] -fall_to [get_clocks {syspll_new_0|syspll_new_inst|altera_pll_i|general[0].gpll~FRACTIONAL_PLL|vcoph[0]}] -hold 0.060  
set_clock_uncertainty -rise_from [get_clocks {syspll_new_0|syspll_new_inst|altera_pll_i|general[0].gpll~FRACTIONAL_PLL|vcoph[0]}] -rise_to [get_clocks {syspll_new_0|syspll_new_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -setup 0.070  
set_clock_uncertainty -rise_from [get_clocks {syspll_new_0|syspll_new_inst|altera_pll_i|general[0].gpll~FRACTIONAL_PLL|vcoph[0]}] -rise_to [get_clocks {syspll_new_0|syspll_new_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -hold 0.060  
set_clock_uncertainty -rise_from [get_clocks {syspll_new_0|syspll_new_inst|altera_pll_i|general[0].gpll~FRACTIONAL_PLL|vcoph[0]}] -fall_to [get_clocks {syspll_new_0|syspll_new_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -setup 0.070  
set_clock_uncertainty -rise_from [get_clocks {syspll_new_0|syspll_new_inst|altera_pll_i|general[0].gpll~FRACTIONAL_PLL|vcoph[0]}] -fall_to [get_clocks {syspll_new_0|syspll_new_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -hold 0.060  
set_clock_uncertainty -fall_from [get_clocks {syspll_new_0|syspll_new_inst|altera_pll_i|general[0].gpll~FRACTIONAL_PLL|vcoph[0]}] -rise_to [get_clocks {syspll_new_0|syspll_new_inst|altera_pll_i|general[0].gpll~FRACTIONAL_PLL|vcoph[0]}] -setup 0.070  
set_clock_uncertainty -fall_from [get_clocks {syspll_new_0|syspll_new_inst|altera_pll_i|general[0].gpll~FRACTIONAL_PLL|vcoph[0]}] -rise_to [get_clocks {syspll_new_0|syspll_new_inst|altera_pll_i|general[0].gpll~FRACTIONAL_PLL|vcoph[0]}] -hold 0.060  
set_clock_uncertainty -fall_from [get_clocks {syspll_new_0|syspll_new_inst|altera_pll_i|general[0].gpll~FRACTIONAL_PLL|vcoph[0]}] -fall_to [get_clocks {syspll_new_0|syspll_new_inst|altera_pll_i|general[0].gpll~FRACTIONAL_PLL|vcoph[0]}] -setup 0.070  
set_clock_uncertainty -fall_from [get_clocks {syspll_new_0|syspll_new_inst|altera_pll_i|general[0].gpll~FRACTIONAL_PLL|vcoph[0]}] -fall_to [get_clocks {syspll_new_0|syspll_new_inst|altera_pll_i|general[0].gpll~FRACTIONAL_PLL|vcoph[0]}] -hold 0.060  
set_clock_uncertainty -fall_from [get_clocks {syspll_new_0|syspll_new_inst|altera_pll_i|general[0].gpll~FRACTIONAL_PLL|vcoph[0]}] -rise_to [get_clocks {syspll_new_0|syspll_new_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -setup 0.070  
set_clock_uncertainty -fall_from [get_clocks {syspll_new_0|syspll_new_inst|altera_pll_i|general[0].gpll~FRACTIONAL_PLL|vcoph[0]}] -rise_to [get_clocks {syspll_new_0|syspll_new_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -hold 0.060  
set_clock_uncertainty -fall_from [get_clocks {syspll_new_0|syspll_new_inst|altera_pll_i|general[0].gpll~FRACTIONAL_PLL|vcoph[0]}] -fall_to [get_clocks {syspll_new_0|syspll_new_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -setup 0.070  
set_clock_uncertainty -fall_from [get_clocks {syspll_new_0|syspll_new_inst|altera_pll_i|general[0].gpll~FRACTIONAL_PLL|vcoph[0]}] -fall_to [get_clocks {syspll_new_0|syspll_new_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -hold 0.060  
set_clock_uncertainty -rise_from [get_clocks {syspll_new_0|syspll_new_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -rise_to [get_clocks {syspll_new_0|syspll_new_inst|altera_pll_i|general[0].gpll~FRACTIONAL_PLL|vcoph[0]}] -setup 0.070  
set_clock_uncertainty -rise_from [get_clocks {syspll_new_0|syspll_new_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -rise_to [get_clocks {syspll_new_0|syspll_new_inst|altera_pll_i|general[0].gpll~FRACTIONAL_PLL|vcoph[0]}] -hold 0.060  
set_clock_uncertainty -rise_from [get_clocks {syspll_new_0|syspll_new_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -fall_to [get_clocks {syspll_new_0|syspll_new_inst|altera_pll_i|general[0].gpll~FRACTIONAL_PLL|vcoph[0]}] -setup 0.070  
set_clock_uncertainty -rise_from [get_clocks {syspll_new_0|syspll_new_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -fall_to [get_clocks {syspll_new_0|syspll_new_inst|altera_pll_i|general[0].gpll~FRACTIONAL_PLL|vcoph[0]}] -hold 0.060  
set_clock_uncertainty -fall_from [get_clocks {syspll_new_0|syspll_new_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -rise_to [get_clocks {syspll_new_0|syspll_new_inst|altera_pll_i|general[0].gpll~FRACTIONAL_PLL|vcoph[0]}] -setup 0.070  
set_clock_uncertainty -fall_from [get_clocks {syspll_new_0|syspll_new_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -rise_to [get_clocks {syspll_new_0|syspll_new_inst|altera_pll_i|general[0].gpll~FRACTIONAL_PLL|vcoph[0]}] -hold 0.060  
set_clock_uncertainty -fall_from [get_clocks {syspll_new_0|syspll_new_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -fall_to [get_clocks {syspll_new_0|syspll_new_inst|altera_pll_i|general[0].gpll~FRACTIONAL_PLL|vcoph[0]}] -setup 0.070  
set_clock_uncertainty -fall_from [get_clocks {syspll_new_0|syspll_new_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -fall_to [get_clocks {syspll_new_0|syspll_new_inst|altera_pll_i|general[0].gpll~FRACTIONAL_PLL|vcoph[0]}] -hold 0.060  


#**************************************************************
# Set Input Delay
#**************************************************************



#**************************************************************
# Set Output Delay
#**************************************************************



#**************************************************************
# Set Clock Groups
#**************************************************************

set_clock_groups -asynchronous -group [get_clocks {altera_reserved_tck}] 
set_clock_groups -asynchronous -group [get_clocks {altera_reserved_tck}] 


#**************************************************************
# Set False Path
#**************************************************************


set_false_path -from [get_keepers {*rdptr_g*}] -to [get_keepers {*ws_dgrp|dffpipe_tu8:dffpipe13|dffe14a*}]
set_false_path -from [get_keepers {*delayed_wrptr_g*}] -to [get_keepers {*rs_dgwp|dffpipe_su8:dffpipe10|dffe11a*}]


#**************************************************************
# Set Multicycle Path
#**************************************************************



#**************************************************************
# Set Maximum Delay
#**************************************************************



#**************************************************************
# Set Minimum Delay
#**************************************************************



#**************************************************************
# Set Input Transition
#**************************************************************

