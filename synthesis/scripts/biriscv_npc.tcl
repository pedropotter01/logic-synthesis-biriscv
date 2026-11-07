# =============================================================================
# biRISC-V Next Program Counter (biriscv_npc) Logic Synthesis Script
# Full Multi-Dimensional Parameter Exploration (BTB x RAS x BHT Cartesian Grid)
# Cadence Genus Synthesis
# =============================================================================

puts "=================================================================="
puts "  biRISC-V NPC (biriscv_npc) Synthesis - Multi-Parameter Grid"
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

set HDL_NAME "biriscv_npc"
set DESIGNS  "biriscv_npc"

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

if {[info exists env(FREQ_MHZ)]} {
    set freq_mhz $env(FREQ_MHZ)
} else {
    set freq_mhz 100
}

set INTERCONNECT_MODE ple
set USE_VCD_POWER_ANALYSIS 1

# -----------------------------------------------------------------------------
# 2. Timing and SDC Constraints Variables
# -----------------------------------------------------------------------------
set MAIN_CLOCK_NAME "clk_i"
set MAIN_RST_NAME   "rst_i"
set BEST_LIB_OPERATING_CONDITION  PVT_1P32V_0C
set WORST_LIB_OPERATING_CONDITION PVT_0P9V_125C
set period_clk [format "%.2f" [expr 1000.0 / $freq_mhz]] ;# ns
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

puts "Project Directory : ${PROJECT_DIR}"
puts "Tech Directory    : ${TECH_DIR}"
puts "Design / Top      : ${HDL_NAME}"
puts "Synthesis Corner  : ${OP_CORNER}"
puts "Target Frequency  : ${freq_mhz} MHz (Period: ${period_clk} ns)"

# -----------------------------------------------------------------------------
# 3. Load Common Infrastructure (Path and Tech)
# -----------------------------------------------------------------------------
source ${PROJECT_DIR}/synthesis/scripts/common/path.tcl
source ${SCRIPT_DIR}/common/tech.tcl

# -----------------------------------------------------------------------------
# 4. Multi-Parameter Space Definition (Cartesian Grid)
# -----------------------------------------------------------------------------
# Fixed Parameters:
#   SUPPORT_BRANCH_PREDICTION = 1
#   RAS_ENABLE                = 1
#   GSHARE_ENABLE             = 1
#   BHT_ENABLE                = 1
#   SYNTH_MODE_ISO            = 1 (registers all I/Os for standalone synthesis)
#
# Swept Parameters:
#   NUM_BTB_ENTRIES   : 4, 8, 16, 32, 64, 128, 256
#   NUM_BTB_ENTRIES_W : 2, 3, 4,  5,  6,  7,   8
#
#   NUM_RAS_ENTRIES   : 2, 4, 8, 16, 32 (Starts from 2 to preserve valid Verilog bit-width)
#   NUM_RAS_ENTRIES_W : 1, 2, 3, 4,  5
#
#   NUM_BHT_ENTRIES   : 16, 32, 64, 128, 256, 512, 1024, 2048
#   NUM_BHT_ENTRIES_W : 4,  5,  6,  7,   8,   9,   10,   11

if {[info exists env(NUM_BTB_ENTRIES)] && [info exists env(NUM_BTB_ENTRIES_W)]} {
    set btb_configs [list [list $env(NUM_BTB_ENTRIES) $env(NUM_BTB_ENTRIES_W)]]
    puts "BTB override from environment: NUM_BTB_ENTRIES=$env(NUM_BTB_ENTRIES), NUM_BTB_ENTRIES_W=$env(NUM_BTB_ENTRIES_W)"
} else {
    set btb_configs {
        {4   2}
        {8   3}
        {16  4}
        {32  5}
        {64  6}
        {128 7}
        {256 8}
    }
}

if {[info exists env(NUM_RAS_ENTRIES)] && [info exists env(NUM_RAS_ENTRIES_W)]} {
    set ras_configs [list [list $env(NUM_RAS_ENTRIES) $env(NUM_RAS_ENTRIES_W)]]
    puts "RAS override from environment: NUM_RAS_ENTRIES=$env(NUM_RAS_ENTRIES), NUM_RAS_ENTRIES_W=$env(NUM_RAS_ENTRIES_W)"
} else {
    set ras_configs {
        {2  1}
        {4  2}
        {8  3}
        {16 4}
        {32 5}
    }
}

if {[info exists env(NUM_BHT_ENTRIES)] && [info exists env(NUM_BHT_ENTRIES_W)]} {
    set bht_configs [list [list $env(NUM_BHT_ENTRIES) $env(NUM_BHT_ENTRIES_W)]]
    puts "BHT override from environment: NUM_BHT_ENTRIES=$env(NUM_BHT_ENTRIES), NUM_BHT_ENTRIES_W=$env(NUM_BHT_ENTRIES_W)"
} else {
    set bht_configs {
        {16   4}
        {32   5}
        {64   6}
        {128  7}
        {256  8}
        {512  9}
        {1024 10}
        {2048 11}
    }
}

set total_runs [expr [llength $btb_configs] * [llength $ras_configs] * [llength $bht_configs]]
puts "\n=================================================================="
puts "  Cartesian Grid Size: [llength $btb_configs] BTB x [llength $ras_configs] RAS x [llength $bht_configs] BHT = ${total_runs} synthesis runs"
puts "==================================================================\n"

# -----------------------------------------------------------------------------
# 5. Initialize Output Files (CSV opened for live streaming)
# -----------------------------------------------------------------------------
set summary_rpt_file "${RPT_DIR}/biriscv_npc/biriscv_npc_param_sweep_summary.rpt"
set summary_csv_file "${RPT_DIR}/biriscv_npc/biriscv_npc_param_sweep_summary.csv"
file mkdir [file dirname $summary_rpt_file]

set fp_csv [open $summary_csv_file "w"]
puts $fp_csv "Config,NUM_BTB_ENTRIES,NUM_BTB_ENTRIES_W,NUM_RAS_ENTRIES,NUM_RAS_ENTRIES_W,NUM_BHT_ENTRIES,NUM_BHT_ENTRIES_W,Cell_Count,Area_um2,Slack,Total_Power,Leakage_Power,Dynamic_Power"
flush $fp_csv

set summary_records [list]
set run_idx 0

# -----------------------------------------------------------------------------
# 6. Multi-Parameter Exploration Loops
# -----------------------------------------------------------------------------
foreach btb_cfg $btb_configs {
    set num_btb   [lindex $btb_cfg 0]
    set num_btb_w [lindex $btb_cfg 1]

    foreach ras_cfg $ras_configs {
        set num_ras   [lindex $ras_cfg 0]
        set num_ras_w [lindex $ras_cfg 1]

        foreach bht_cfg $bht_configs {
            set num_bht   [lindex $bht_cfg 0]
            set num_bht_w [lindex $bht_cfg 1]
            incr run_idx

            set cfg_label "btb_${num_btb}_ras_${num_ras}_bht_${num_bht}"

            puts "\n=================================================================="
            puts ">>> Progress: ${run_idx} / ${total_runs} | Configuration: ${cfg_label}"
            puts ">>>   BTB : entries=${num_btb}, width=${num_btb_w}"
            puts ">>>   RAS : entries=${num_ras}, width=${num_ras_w}"
            puts ">>>   BHT : entries=${num_bht}, width=${num_bht_w}"
            puts ">>>   SYNTH_MODE_ISO = 1"
            puts "=================================================================="

            # Dedicated directories inside reports folder
            set RUN_RPT_DIR "${RPT_DIR}/biriscv_npc/${freq_mhz}_MHz/${OP_CORNER}/${cfg_label}"
            set RUN_DEV_DIR "${DEV_DIR}/biriscv_npc/${freq_mhz}_MHz/${OP_CORNER}/${cfg_label}"

            file mkdir $RUN_RPT_DIR
            file mkdir $RUN_DEV_DIR

            # Direct shortcut path under reports/biriscv_npc/
            file mkdir "${RPT_DIR}/biriscv_npc/${cfg_label}"

            # -----------------------------------------------------------------
            # A. Read HDL source (ONLY biriscv_npc.v as requested)
            # -----------------------------------------------------------------
            set_db init_hdl_search_path [list ${PROJECT_DIR}/src ${PROJECT_DIR}/src/core]
            read_hdl -language ${HDL_LANG} ${CORE_DIR}/biriscv_npc.v

            # -----------------------------------------------------------------
            # B. Elaborate Design with Parameters
            # In Genus, -parameters expects a positional list of parameter values
            # in the exact declaration order of the Verilog module:
            #   1.  SUPPORT_BRANCH_PREDICTION = 1
            #   2.  NUM_BTB_ENTRIES           = ${num_btb}
            #   3.  NUM_BTB_ENTRIES_W         = ${num_btb_w}
            #   4.  NUM_BHT_ENTRIES           = ${num_bht}
            #   5.  NUM_BHT_ENTRIES_W         = ${num_bht_w}
            #   6.  RAS_ENABLE                = 1
            #   7.  GSHARE_ENABLE             = 1
            #   8.  BHT_ENABLE                = 1
            #   9.  NUM_RAS_ENTRIES           = ${num_ras}
            #  10.  NUM_RAS_ENTRIES_W         = ${num_ras_w}
            #  11.  SYNTH_MODE_ISO            = 1
            # -----------------------------------------------------------------
            set param_values [list 1 ${num_btb} ${num_btb_w} ${num_bht} ${num_bht_w} 1 1 1 ${num_ras} ${num_ras_w} 1]
            elaborate biriscv_npc -parameters $param_values

            # Active elaborated design in Genus database
            set CUR_DESIGN [get_db current_design]
            set CUR_DESIGN_NAME [get_db $CUR_DESIGN .name]
            puts ">>> Active Elaborated Design: ${CUR_DESIGN_NAME}"

            check_design -unresolved $CUR_DESIGN
            check_library

            # -----------------------------------------------------------------
            # C. Apply SDC Constraints
            # -----------------------------------------------------------------
            read_sdc ${PROJECT_DIR}/synthesis/constraints/biriscv_npc.sdc
            report_timing -lint > ${RUN_RPT_DIR}/biriscv_npc_timing_lint.rpt

            # -----------------------------------------------------------------
            # D. Generic Synthesis & Optimization
            # -----------------------------------------------------------------
            set_db auto_ungroup both
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
            # G. Generate Reports in Dedicated Output Directory
            # -----------------------------------------------------------------
            report_design_rules    > ${RUN_RPT_DIR}/biriscv_npc_design_rules.rpt
            report_area -detail    > ${RUN_RPT_DIR}/biriscv_npc_area_detail.rpt
            report_area            > ${RUN_RPT_DIR}/biriscv_npc_area.rpt
            report_timing          > ${RUN_RPT_DIR}/biriscv_npc_timing.rpt
            report_gates           > ${RUN_RPT_DIR}/biriscv_npc_gates.rpt
            report_qor             > ${RUN_RPT_DIR}/biriscv_npc_qor.rpt
            report_power -unit uW  > ${RUN_RPT_DIR}/biriscv_npc_power.rpt
            report_hierarchy       > ${RUN_RPT_DIR}/biriscv_npc_hierarchy.rpt

            # Copy key reports to convenient flat shortcut directory
            catch { file copy -force ${RUN_RPT_DIR}/biriscv_npc_area.rpt        "${RPT_DIR}/biriscv_npc/${cfg_label}/" }
            catch { file copy -force ${RUN_RPT_DIR}/biriscv_npc_timing.rpt      "${RPT_DIR}/biriscv_npc/${cfg_label}/" }
            catch { file copy -force ${RUN_RPT_DIR}/biriscv_npc_power.rpt       "${RPT_DIR}/biriscv_npc/${cfg_label}/" }
            catch { file copy -force ${RUN_RPT_DIR}/biriscv_npc_qor.rpt         "${RPT_DIR}/biriscv_npc/${cfg_label}/" }
            catch { file copy -force ${RUN_RPT_DIR}/biriscv_npc_gates.rpt       "${RPT_DIR}/biriscv_npc/${cfg_label}/" }
            catch { file copy -force ${RUN_RPT_DIR}/biriscv_npc_area_detail.rpt "${RPT_DIR}/biriscv_npc/${cfg_label}/" }

            # -----------------------------------------------------------------
            # H. Write Mapped Netlist & SDF
            # -----------------------------------------------------------------
            if {[file exists ${SCRIPT_DIR}/common/sdf_width_wa.etf]} {
                catch { source ${SCRIPT_DIR}/common/sdf_width_wa.etf }
            }
            catch {
                write_sdf -edge check_edge -setuphold merge_always -nonegchecks -recrem merge_always \
                          -version 3.0 -design $CUR_DESIGN > ${RUN_DEV_DIR}/biriscv_npc.sdf
            }
            write_hdl $CUR_DESIGN > ${RUN_DEV_DIR}/biriscv_npc.v

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

            lappend summary_records [list $cfg_label $num_btb $num_btb_w $num_ras $num_ras_w $num_bht $num_bht_w $metric_cells $metric_area $metric_slack $metric_pwr_total $metric_pwr_leak $metric_pwr_dyn]

            # Live append to CSV so data is preserved in real time
            puts $fp_csv "${cfg_label},${num_btb},${num_btb_w},${num_ras},${num_ras_w},${num_bht},${num_bht_w},${metric_cells},${metric_area},${metric_slack},${metric_pwr_total},${metric_pwr_leak},${metric_pwr_dyn}"
            flush $fp_csv

            puts ">>> Completed ${cfg_label} -> Area: ${metric_area} um^2 | Cells: ${metric_cells} | Slack: ${metric_slack}"

            # -----------------------------------------------------------------
            # J. Database Cleanup for Next Iteration
            # -----------------------------------------------------------------
            delete_obj [get_db designs *]
            catch { read_hdl -unset }
        }
    }
}
close $fp_csv

# -----------------------------------------------------------------------------
# 7. Write Formatted Summary Table Report
# -----------------------------------------------------------------------------
set fp_rpt [open $summary_rpt_file "w"]
puts $fp_rpt "========================================================================================================================================================"
puts $fp_rpt "                                     biRISC-V NPC (biriscv_npc) Multi-Parameter Synthesis Grid Summary"
puts $fp_rpt "                                     Mode: SYNTH_MODE_ISO=1 | Corner: ${OP_CORNER} | Target Frequency: ${freq_mhz} MHz"
puts $fp_rpt "========================================================================================================================================================"
puts $fp_rpt [format "%-30s | %-6s | %-6s | %-6s | %-10s | %-15s | %-12s | %-15s | %-15s" \
    "Config" "BTB" "RAS" "BHT" "Cells" "Area (um^2)" "Slack" "Total Power" "Leakage Power"]
puts $fp_rpt "--------------------------------------------------------------------------------------------------------------------------------------------------------"

foreach rec $summary_records {
    set c_name  [lindex $rec 0]
    set c_btb   [lindex $rec 1]
    set c_ras   [lindex $rec 3]
    set c_bht   [lindex $rec 5]
    set c_cells [lindex $rec 7]
    set c_area  [lindex $rec 8]
    set c_slack [lindex $rec 9]
    set c_tot_p [lindex $rec 10]
    set c_lea_p [lindex $rec 11]

    puts $fp_rpt [format "%-30s | %-6s | %-6s | %-6s | %-10s | %-15s | %-12s | %-15s | %-15s" \
        $c_name $c_btb $c_ras $c_bht $c_cells $c_area $c_slack $c_tot_p $c_lea_p]
}
puts $fp_rpt "========================================================================================================================================================"
close $fp_rpt

puts "\n=================================================================="
puts "  biRISC-V NPC Multi-Parameter Grid Synthesis Completed!"
puts "  Total Runs Executed : ${run_idx} of ${total_runs}"
puts "  Summary Report      : ${summary_rpt_file}"
puts "  Summary CSV         : ${summary_csv_file}"
puts "  Reports Directory   : ${RPT_DIR}/biriscv_npc/${freq_mhz}_MHz/${OP_CORNER}/"
puts "=================================================================="
