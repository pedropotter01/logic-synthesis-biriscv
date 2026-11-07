# =============================================================================
# biRISC-V Arithmetic Logic Unit (biriscv_alu) Logic Synthesis Script
# Frequency Sweep from 150 to 190 MHz (Isolated Synthesis: GSYNTH_ISO = 1)
# Cadence Genus Synthesis with Submodule Hierarchy Preservation & Op-by-Op STA
# =============================================================================

puts "=================================================================="
puts "  biRISC-V ALU (biriscv_alu) Isolated Logic Synthesis Sweep"
puts "  Frequency Range: 150 to 190 MHz | GSYNTH_ISO = 1"
puts "  Enhanced with Submodule Hierarchy & Per-Op Critical Path Analysis"
puts "=================================================================="

# -----------------------------------------------------------------------------
# 1. Environment and Variable Setup (with fallback defaults)
# -----------------------------------------------------------------------------
if {[info exists env(PROJECT_DIR)]} {
    set PROJECT_DIR $env(PROJECT_DIR)
} else {
    set PROJECT_DIR [file normalize [file join [file dirname [info script]] "../.."]]
}

if {[info exists env(TECH_DIR)]} {
    set TECH_DIR $env(TECH_DIR)
} else {
    set TECH_DIR "/home/tools/design_kits/cadence/GPDK045"
}

set HDL_NAME "biriscv_alu"
set DESIGNS  "biriscv_alu"

if {[info exists env(HDL_LANG)]} {
    set HDL_LANG $env(HDL_LANG)
} else {
    set HDL_LANG "v2001"
}

if {[info exists env(OP_CORNER)]} {
    set OP_CORNER $env(OP_CORNER)
} else {
    set OP_CORNER "WORST"
}

# Module isolation parameter (SYNTH_MODE_ISO / GSYNTH_ISO)
# SYNTH_MODE_ISO = 1 activates the register walls (g_synth_iso)
set GSYNTH_ISO 1
if {[info exists env(GSYNTH_ISO)]} {
    set GSYNTH_ISO $env(GSYNTH_ISO)
} elseif {[info exists env(SYNTH_MODE_ISO)]} {
    set GSYNTH_ISO $env(SYNTH_MODE_ISO)
}

# Hierarchy preservation control for timing analysis clarity:
# PRESERVE_HIERARCHY = 1 preserves u_shifter, u_adder, u_cmp, u_logic, u_mux
# so that timing reports clearly show submodules and stages instead of flat gate numbers.
set PRESERVE_HIERARCHY 1
if {[info exists env(PRESERVE_HIERARCHY)]} {
    set PRESERVE_HIERARCHY $env(PRESERVE_HIERARCHY)
}

set INTERCONNECT_MODE ple
set USE_VCD_POWER_ANALYSIS 1

# -----------------------------------------------------------------------------
# 2. Timing and SDC Constraints Variables Setup
# -----------------------------------------------------------------------------
set MAIN_CLOCK_NAME "clk_i"
set MAIN_RST_NAME   "rst_i"
set BEST_LIB_OPERATING_CONDITION  PVT_1P32V_0C
set WORST_LIB_OPERATING_CONDITION PVT_0P9V_125C

set clk_uncertainty 0.05 ;# ns
set clk_latency     0.10 ;# ns
set in_delay        0.30 ;# ns
set out_delay       0.30 ;# ns
set out_load        0.045 ;# pF
set slew_min_rise   0.146 ;# ns
set slew_min_fall   0.164 ;# ns
set slew_max_rise   0.264 ;# ns
set slew_max_fall   0.252 ;# ns

# Technology Library Lists (GPDK045)
set WORST_LIST     {slow_vdd1v0_basicCells.lib}
set BEST_LIST      {fast_vdd1v2_basicCells.lib}
set LEF_LIST       {gsclib045_tech.lef gsclib045_macro.lef}
set WORST_CAP_LIST ${TECH_DIR}/gpdk045_v_6_0/soce/gpdk045.basic.CapTbl
set QRC_LIST       ${TECH_DIR}/gpdk045_v_6_0/qrc/rcworst/qrcTechFile

puts "Project Directory   : ${PROJECT_DIR}"
puts "Tech Directory      : ${TECH_DIR}"
puts "Design / Top        : ${HDL_NAME}"
puts "Synthesis Corner    : ${OP_CORNER}"
puts "Isolation Mode      : GSYNTH_ISO = ${GSYNTH_ISO} (SYNTH_MODE_ISO = ${GSYNTH_ISO})"
puts "Preserve Hierarchy  : PRESERVE_HIERARCHY = ${PRESERVE_HIERARCHY}"

# -----------------------------------------------------------------------------
# 3. Load Common Infrastructure (Path and Tech)
# -----------------------------------------------------------------------------
source ${PROJECT_DIR}/synthesis/scripts/common/path.tcl
source ${SCRIPT_DIR}/common/tech.tcl

# -----------------------------------------------------------------------------
# 4. Frequency List Definition (150 to 190 MHz)
# -----------------------------------------------------------------------------
if {[info exists env(ALU_FREQ_LIST)] && [llength $env(ALU_FREQ_LIST)] > 0} {
    set freq_list $env(ALU_FREQ_LIST)
    puts "Using custom frequency list from ALU_FREQ_LIST: ${freq_list}"
} elseif {[info exists env(START_FREQ)] && [info exists env(STOP_FREQ)]} {
    set start_f $env(START_FREQ)
    set stop_f  $env(STOP_FREQ)
    set step_f  10
    if {[info exists env(STEP_FREQ)]} {
        set step_f $env(STEP_FREQ)
    }
    set freq_list [list]
    for {set f $start_f} {$f <= $stop_f} {incr f $step_f} {
        lappend freq_list $f
    }
    puts "Using frequency list generated from START/STOP/STEP: ${freq_list}"
} else {
    # Default frequency sweep: 150 to 190 MHz in 10 MHz increments
    set freq_list {150 160 170 180 190}
    puts "Using default frequency sweep list (150 to 190 MHz): ${freq_list}"
}

set total_runs [llength $freq_list]
puts "Total synthesis runs planned: ${total_runs}"

# -----------------------------------------------------------------------------
# 5. Initialize Output Files (CSV opened for live streaming)
# -----------------------------------------------------------------------------
set summary_rpt_file "${RPT_DIR}/biriscv_alu/biriscv_alu_freq_sweep_summary.rpt"
set summary_csv_file "${RPT_DIR}/biriscv_alu/biriscv_alu_freq_sweep_summary.csv"
file mkdir [file dirname $summary_rpt_file]

set fp_csv [open $summary_csv_file "w"]
puts $fp_csv "Frequency_MHz,Clock_Period_ns,Corner,GSYNTH_ISO,PRESERVE_HIERARCHY,Status,Slack_ps,Cell_Count,Area_um2,Total_Power_uW,Leakage_Power_uW,Dynamic_Power_uW"
flush $fp_csv

set summary_records [list]
set run_idx 0

# -----------------------------------------------------------------------------
# 6. Frequency Sweep Loop
# -----------------------------------------------------------------------------
foreach freq_mhz $freq_list {
    incr run_idx
    set period_clk [format "%.2f" [expr 1000.0 / $freq_mhz]] ;# ns

    puts "\n=================================================================="
    puts ">>> Progress: Run ${run_idx} / ${total_runs}"
    puts ">>> Target Frequency  : ${freq_mhz} MHz (Clock Period: ${period_clk} ns)"
    puts ">>> Corner            : ${OP_CORNER}"
    puts ">>> Isolation Mode    : GSYNTH_ISO = ${GSYNTH_ISO}"
    puts ">>> Preserve Hierarchy: ${PRESERVE_HIERARCHY}"
    puts "=================================================================="

    # Dedicated output directories per frequency and corner
    set RUN_RPT_DIR "${RPT_DIR}/biriscv_alu/${freq_mhz}_MHz/${OP_CORNER}"
    set RUN_DEV_DIR "${DEV_DIR}/biriscv_alu/${freq_mhz}_MHz/${OP_CORNER}"

    file mkdir $RUN_RPT_DIR
    file mkdir $RUN_DEV_DIR

    # -----------------------------------------------------------------
    # A. Read HDL source (biriscv_alu.v with biriscv_defs.v)
    # -----------------------------------------------------------------
    set_db init_hdl_search_path [list ${SRC_DIR} ${CORE_DIR}]
    read_hdl -language ${HDL_LANG} ${CORE_DIR}/biriscv_alu.v

    # -----------------------------------------------------------------
    # B. Elaborate Design with Isolation Parameter
    # SYNTH_MODE_ISO = 1 registers all I/Os (begin : g_synth_iso)
    # -----------------------------------------------------------------
    elaborate biriscv_alu -parameters [list $GSYNTH_ISO]

    set CUR_DESIGN [get_db current_design]
    set CUR_DESIGN_NAME [get_db $CUR_DESIGN .name]
    puts ">>> Active Elaborated Design: ${CUR_DESIGN_NAME}"

    check_design -unresolved $CUR_DESIGN
    check_library

    # -----------------------------------------------------------------
    # C. Apply SDC Constraints
    # -----------------------------------------------------------------
    read_sdc ${PROJECT_DIR}/synthesis/constraints/biriscv_alu.sdc
    report_timing -lint > ${RUN_RPT_DIR}/biriscv_alu_timing_lint.rpt

    # -----------------------------------------------------------------
    # D. Generic Synthesis & Optimization (Hierarchy Control)
    # -----------------------------------------------------------------
    if {$PRESERVE_HIERARCHY} {
        puts ">>> Hierarchy Preservation ENABLED: Preserving submodules for timing path visibility."
        set_db auto_ungroup none
        catch {
            foreach inst [get_db [get_db current_design] .hinsts] {
                set_db $inst .ungroup_ok false
            }
        }
    } else {
        puts ">>> Hierarchy Preservation DISABLED: Full auto_ungroup enabled."
        set_db auto_ungroup both
    }
    syn_generic $CUR_DESIGN

    # -----------------------------------------------------------------
    # E. Technology Mapping
    # -----------------------------------------------------------------
    syn_map $CUR_DESIGN

    # -----------------------------------------------------------------
    # F. Post-Mapping Optimization
    # -----------------------------------------------------------------
    set_max_fanout 10 [all_inputs]
    set_max_transition 0.15 $CUR_DESIGN
    syn_opt -incr

    # -----------------------------------------------------------------
    # G1. Standard Reports
    # -----------------------------------------------------------------
    report_design_rules    > ${RUN_RPT_DIR}/biriscv_alu_design_rules.rpt
    report_area -detail    > ${RUN_RPT_DIR}/biriscv_alu_area_detail.rpt
    report_area            > ${RUN_RPT_DIR}/biriscv_alu_area.rpt
    report_timing          > ${RUN_RPT_DIR}/biriscv_alu_timing.rpt
    report_gates           > ${RUN_RPT_DIR}/biriscv_alu_gates.rpt
    report_qor             > ${RUN_RPT_DIR}/biriscv_alu_qor.rpt
    report_power -unit uW  > ${RUN_RPT_DIR}/biriscv_alu_power.rpt
    report_hierarchy       > ${RUN_RPT_DIR}/biriscv_alu_hierarchy.rpt

    # -----------------------------------------------------------------
    # G2. Enhanced Multi-Path & Detailed Reports
    # -----------------------------------------------------------------
    # Top 20 distinct critical endpoints:
    catch {
        report_timing -max_paths 20 -nworst 1 > ${RUN_RPT_DIR}/biriscv_alu_timing_top20.rpt
    }
    # Detailed timing path report with fanout, load cap, transitions, cell delays, and hierarchy:
    catch {
        report_timing -fields {timing_point flags arc edge cell fanout load trans delay arrival instance location} \
                      -max_paths 5 > ${RUN_RPT_DIR}/biriscv_alu_timing_detailed.rpt
    }

    # -----------------------------------------------------------------
    # G3. Per-Operation Critical Path Analysis (set_case_analysis)
    # Evaluates the critical path and delay for EACH individual ALU operation
    # -----------------------------------------------------------------
    puts "\n>>> Running Per-Operation Critical Path Analysis (10 ALU Operations)..."

    # Identify the 4 alu_op selection pins/ports dynamically
    set op_pins [list]
    for {set b 0} {$b < 4} {incr b} {
        set p [get_pins -quiet -hier "*alu_op_i_iso_q*reg*\[${b}\]/Q*"]
        if {[llength $p] == 0} {
            set p [get_pins -quiet -hier "*alu_op_i_iso_q*_${b}_*/Q*"]
        }
        if {[llength $p] == 0} {
            set p [get_pins -quiet -hier "*alu_op_i*\[${b}\]/Q*"]
        }
        if {[llength $p] == 0} {
            set p [get_pins -quiet -hier "*alu_op_i_iso_q*\[${b}\]/*"]
        }
        if {[llength $p] == 0} {
            set p [get_ports -quiet "alu_op_i\[${b}\]"]
        }
        if {[llength $p] > 0} {
            lappend op_pins [lindex $p 0]
        }
    }

    set alu_ops {
        {"ALU_ADD"              "0100" "Addition (A + B)"}
        {"ALU_SUB"              "0110" "Subtraction (A - B)"}
        {"ALU_SHIFTL"           "0001" "Shift Left Logical (A << B\[4:0\])"}
        {"ALU_SHIFTR"           "0010" "Shift Right Logical (A >> B\[4:0\])"}
        {"ALU_SHIFTR_ARITH"     "0011" "Shift Right Arithmetic (A >>> B\[4:0\])"}
        {"ALU_LESS_THAN"        "1010" "Set Less Than Unsigned (A < B)"}
        {"ALU_LESS_THAN_SIGNED" "1011" "Set Less Than Signed (A < B)"}
        {"ALU_AND"              "0111" "Bitwise AND (A & B)"}
        {"ALU_OR"               "1000" "Bitwise OR (A | B)"}
        {"ALU_XOR"              "1001" "Bitwise XOR (A ^ B)"}
    }

    set op_records [list]
    set op_rpt_file "${RUN_RPT_DIR}/biriscv_alu_operations_timing.rpt"
    set op_csv_file "${RUN_RPT_DIR}/biriscv_alu_operations_timing.csv"

    if {[llength $op_pins] == 4} {
        set fp_op_csv [open $op_csv_file "w"]
        puts $fp_op_csv "Operation,Opcode,Description,Status,Slack_ps,Delay_ps,Startpoint,Endpoint"

        foreach op_info $alu_ops {
            set op_name [lindex $op_info 0]
            set op_code [lindex $op_info 1]
            set op_desc [lindex $op_info 2]

            # Constrain alu_op bits for this operation
            for {set b 0} {$b < 4} {incr b} {
                set bit_val [string index $op_code [expr {3 - $b}]]
                set pin [lindex $op_pins $b]
                catch { set_case_analysis $bit_val $pin }
            }

            # Generate dedicated timing report for this operation
            set op_detail_rpt "${RUN_RPT_DIR}/biriscv_alu_timing_${op_name}.rpt"
            catch {
                report_timing -fields {timing_point flags arc edge cell fanout load trans delay arrival instance location} \
                              -max_paths 1 > $op_detail_rpt
            }

            # Extract metrics
            set op_slack "N/A"
            set op_delay "N/A"
            set op_start "N/A"
            set op_end   "N/A"
            set op_stat  "MET"

            catch {
                set tpaths [get_db timing_paths -max_paths 1]
                if {[llength $tpaths] > 0} {
                    set tp [lindex $tpaths 0]
                    set op_slack [get_db $tp .slack]
                    set op_delay [get_db $tp .path_delay]
                    set op_start [get_db $tp .launching_point.name]
                    set op_end   [get_db $tp .capturing_point.name]
                }
            }

            # Fallback parsing of generated report if needed
            if {$op_slack eq "N/A" && [file exists $op_detail_rpt]} {
                set fp_in [open $op_detail_rpt "r"]
                while {[gets $fp_in line] >= 0} {
                    if {[regexp {Startpoint:\s+\S+\s+(\S+)} $line match sp]} {
                        set op_start $sp
                    } elseif {[regexp {Endpoint:\s+\S+\s+(\S+)} $line match ep]} {
                        set op_end $ep
                    } elseif {[regexp {Data Path:-\s+([0-9\.\-]+)} $line match dp]} {
                        set op_delay $dp
                    } elseif {[regexp {Slack:=\s+([0-9\.\-]+)} $line match sl]} {
                        set op_slack $sl
                    }
                }
                close $fp_in
            }

            if {$op_slack ne "N/A"} {
                if {[catch {if {$op_slack < 0} {set op_stat "VIOLATED"}}]} {
                    set op_stat "UNKNOWN"
                }
            }

            lappend op_records [list $op_name $op_code $op_desc $op_stat $op_slack $op_delay $op_start $op_end]
            puts $fp_op_csv "${op_name},${op_code},\"${op_desc}\",${op_stat},${op_slack},${op_delay},${op_start},${op_end}"
            flush $fp_op_csv

            # Remove case analysis for next opcode
            for {set b 0} {$b < 4} {incr b} {
                set pin [lindex $op_pins $b]
                catch { set_case_analysis -remove $pin }
                catch { reset_case_analysis $pin }
            }
        }
        close $fp_op_csv

        # Write formatted text table
        set fp_op_rpt [open $op_rpt_file "w"]
        puts $fp_op_rpt "========================================================================================================================"
        puts $fp_op_rpt "            biRISC-V ALU (biriscv_alu) Critical Path Analysis by Operation"
        puts $fp_op_rpt "            Frequency: ${freq_mhz} MHz | Period: ${period_clk} ns | Corner: ${OP_CORNER} | Hierarchy: ${PRESERVE_HIERARCHY}"
        puts $fp_op_rpt "========================================================================================================================"
        puts $fp_op_rpt [format "%-22s | %-6s | %-9s | %-11s | %-11s | %-32s -> %-32s" \
            "Operation" "Opcode" "Status" "Slack (ps)" "Delay (ps)" "Critical Startpoint" "Critical Endpoint"]
        puts $fp_op_rpt "------------------------------------------------------------------------------------------------------------------------"
        foreach rec $op_records {
            puts $fp_op_rpt [format "%-22s | %-6s | %-9s | %-11s | %-11s | %-32s -> %-32s" \
                [lindex $rec 0] [lindex $rec 1] [lindex $rec 3] [lindex $rec 4] [lindex $rec 5] [lindex $rec 6] [lindex $rec 7]]
        }
        puts $fp_op_rpt "========================================================================================================================"
        close $fp_op_rpt

        puts "\n>>> Per-Operation Critical Path Summary (${freq_mhz} MHz):"
        puts [format "%-22s | %-6s | %-9s | %-11s | %-11s" "Operation" "Opcode" "Status" "Slack (ps)" "Delay (ps)"]
        puts "------------------------------------------------------------------"
        foreach rec $op_records {
            puts [format "%-22s | %-6s | %-9s | %-11s | %-11s" \
                [lindex $rec 0] [lindex $rec 1] [lindex $rec 3] [lindex $rec 4] [lindex $rec 5]]
        }
        puts "------------------------------------------------------------------"
        puts "Detailed reports saved in: ${RUN_RPT_DIR}/"
    } else {
        puts ">>> WARNING: Could not find all 4 alu_op pins for case analysis (found [llength $op_pins])."
    }

    # -----------------------------------------------------------------
    # H. Write Mapped Netlist & SDF
    # -----------------------------------------------------------------
    if {[file exists ${SCRIPT_DIR}/common/sdf_width_wa.etf]} {
        catch { source ${SCRIPT_DIR}/common/sdf_width_wa.etf }
    }
    catch {
        write_sdf -edge check_edge -setuphold merge_always -nonegchecks -recrem merge_always \
                  -version 3.0 -design $CUR_DESIGN > ${RUN_DEV_DIR}/biriscv_alu.sdf
    }
    write_hdl $CUR_DESIGN > ${RUN_DEV_DIR}/biriscv_alu.v

    # -----------------------------------------------------------------
    # I. Metric Extraction & Real-Time Logging
    # -----------------------------------------------------------------
    set metric_area "N/A"
    set metric_cells "N/A"
    set metric_slack "N/A"
    set metric_pwr_total "N/A"
    set metric_pwr_leak "N/A"
    set metric_pwr_dyn "N/A"

    catch { set metric_area [get_db $CUR_DESIGN .area] }
    catch { set metric_cells [llength [get_db $CUR_DESIGN .insts]] }
    if {$metric_cells eq "N/A" || $metric_cells eq "0"} {
        catch { set metric_cells [get_db $CUR_DESIGN .num_leaf_instances] }
    }
    catch { set metric_slack [get_db $CUR_DESIGN .slack] }
    if {$metric_slack eq "N/A"} {
        catch { set metric_slack [get_db $CUR_DESIGN .wns] }
    }
    catch { set metric_pwr_total [get_db $CUR_DESIGN .power_total] }
    catch { set metric_pwr_leak  [get_db $CUR_DESIGN .power_leakage] }
    catch { set metric_pwr_dyn   [get_db $CUR_DESIGN .power_dynamic] }

    set timing_status "MET"
    if {$metric_slack ne "N/A"} {
        if {[catch {if {$metric_slack < 0} {set timing_status "VIOLATED"}}]} {
            set timing_status "UNKNOWN"
        }
    }

    lappend summary_records [list $freq_mhz $period_clk $OP_CORNER $GSYNTH_ISO $PRESERVE_HIERARCHY $timing_status $metric_slack $metric_cells $metric_area $metric_pwr_total $metric_pwr_leak $metric_pwr_dyn]

    # Live append to CSV so data is preserved even if interrupted
    puts $fp_csv "${freq_mhz},${period_clk},${OP_CORNER},${GSYNTH_ISO},${PRESERVE_HIERARCHY},${timing_status},${metric_slack},${metric_cells},${metric_area},${metric_pwr_total},${metric_pwr_leak},${metric_pwr_dyn}"
    flush $fp_csv

    puts ">>> Completed ${freq_mhz} MHz -> Status: ${timing_status} | Slack: ${metric_slack} | Area: ${metric_area} | Cells: ${metric_cells}"

    # -----------------------------------------------------------------
    # J. Database Cleanup for Next Iteration
    # -----------------------------------------------------------------
    delete_obj [get_db designs *]
    catch { read_hdl -unset }
}
close $fp_csv

# -----------------------------------------------------------------------------
# 7. Write Formatted Summary Table Report
# -----------------------------------------------------------------------------
set fp_rpt [open $summary_rpt_file "w"]
puts $fp_rpt "========================================================================================================================"
puts $fp_rpt "                                biRISC-V ALU (biriscv_alu) Isolated Synthesis Frequency Sweep Summary"
puts $fp_rpt "                Mode: GSYNTH_ISO=${GSYNTH_ISO} | PRESERVE_HIERARCHY=${PRESERVE_HIERARCHY} | Corner: ${OP_CORNER}"
puts $fp_rpt "========================================================================================================================"
puts $fp_rpt [format "%-12s | %-12s | %-10s | %-12s | %-10s | %-15s | %-15s | %-15s" \
    "Freq (MHz)" "Period (ns)" "Status" "Slack" "Cells" "Area (um^2)" "Total Power(uW)" "Dynamic Pwr(uW)"]
puts $fp_rpt "------------------------------------------------------------------------------------------------------------------------"

foreach rec $summary_records {
    set c_freq  [lindex $rec 0]
    set c_per   [lindex $rec 1]
    set c_stat  [lindex $rec 5]
    set c_slack [lindex $rec 6]
    set c_cells [lindex $rec 7]
    set c_area  [lindex $rec 8]
    set c_tot_p [lindex $rec 9]
    set c_dyn_p [lindex $rec 11]

    puts $fp_rpt [format "%-12s | %-12s | %-10s | %-12s | %-10s | %-15s | %-15s | %-15s" \
        "${c_freq} MHz" "${c_per} ns" $c_stat $c_slack $c_cells $c_area $c_tot_p $c_dyn_p]
}
puts $fp_rpt "========================================================================================================================"
close $fp_rpt

puts "\n=================================================================="
puts "  biRISC-V ALU Frequency Sweep Synthesis Completed!"
puts "  Total Runs Executed : ${run_idx} of ${total_runs}"
puts "  Summary Report      : ${summary_rpt_file}"
puts "  Summary CSV         : ${summary_csv_file}"
puts "  Reports Directory   : ${RPT_DIR}/biriscv_alu/"
puts "  Deliverables Dir    : ${DEV_DIR}/biriscv_alu/"
puts "=================================================================="
