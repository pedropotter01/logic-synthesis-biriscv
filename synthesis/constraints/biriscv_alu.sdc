#-----------------------------------------------------------------------------
# SDC (Synopsys Design Constraints) for biRISC-V ALU (biriscv_alu)
# Target: GPDK045 (45nm)
# Mode: Standalone Synthesis with SYNTH_MODE_ISO = 1 (GSYNTH_ISO = 1)
#-----------------------------------------------------------------------------

set sdc_version 1.5
current_design [get_db current_design .name]

#################################################################################
## IDEAL NETS (Clock and Reset)
#################################################################################
if {[llength [get_ports -quiet ${MAIN_CLOCK_NAME}]] > 0} {
    set_ideal_net [get_ports ${MAIN_CLOCK_NAME}]
}
if {[info exists MAIN_RST_NAME] && [llength [get_ports -quiet ${MAIN_RST_NAME}]] > 0} {
    set_ideal_net [get_ports ${MAIN_RST_NAME}]
}

#################################################################################
## CLOCK DEFINITION
#################################################################################
# Top-level clock is clk_i
create_clock -name ${MAIN_CLOCK_NAME} -period ${period_clk} [get_ports ${MAIN_CLOCK_NAME}]
set_clock_uncertainty ${clk_uncertainty} [get_clocks ${MAIN_CLOCK_NAME}]
set_clock_latency ${clk_latency} [get_clocks ${MAIN_CLOCK_NAME}]

#################################################################################
## INPUT PINS (all inputs except clock and reset)
#################################################################################
set clock_reset_ports [list ${MAIN_CLOCK_NAME}]
if {[info exists MAIN_RST_NAME] && [llength [get_ports -quiet ${MAIN_RST_NAME}]] > 0} {
    lappend clock_reset_ports ${MAIN_RST_NAME}
}
set all_data_inputs [remove_from_collection [all_inputs] [get_ports -quiet $clock_reset_ports]]
if {[llength $all_data_inputs] > 0} {
    set_input_delay -clock [get_clocks ${MAIN_CLOCK_NAME}] ${in_delay} $all_data_inputs
    
    set_input_transition -rise -min ${slew_min_rise} $all_data_inputs
    set_input_transition -fall -min ${slew_min_fall} $all_data_inputs
    set_input_transition -rise -max ${slew_max_rise} $all_data_inputs
    set_input_transition -fall -max ${slew_max_fall} $all_data_inputs
}

#################################################################################
## OUTPUT PINS
#################################################################################
if {[llength [all_outputs]] > 0} {
    set_output_delay -clock [get_clocks ${MAIN_CLOCK_NAME}] ${out_delay} [all_outputs]
    set_load -pin_load ${out_load} [all_outputs]
}

#################################################################################
## DESIGN RULES
#################################################################################
set_max_fanout 16 [current_design]
set_max_transition 0.5 [current_design]

#################################################################################
## OPTIMIZATION GOAL
#################################################################################
set_max_area 0

puts "SDC constraints for ${HDL_NAME} loaded successfully"
puts "  Clock port  : ${MAIN_CLOCK_NAME}"
puts "  Clock period: ${period_clk} ns (${freq_mhz} MHz)"
puts "  Input delay : ${in_delay} ns"
puts "  Output delay: ${out_delay} ns"
