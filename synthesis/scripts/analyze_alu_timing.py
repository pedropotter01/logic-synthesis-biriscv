#!/usr/bin/env python3
"""
=============================================================================
biRISC-V ALU Timing and Critical Path Analyzer
Analyzes Genus synthesis timing reports and per-operation breakdown tables.
=============================================================================
"""

import sys
import os
import re
import argparse

def parse_timing_report(report_path):
    """
    Parses a Cadence Genus timing report file (*.rpt) and extracts:
    - Startpoint, Endpoint, Slack, Data Path Delay, Clock Period
    - Table of timing points with cell, delay, transition, and instance
    - Breakdown by functional unit / hierarchical submodule
    """
    if not os.path.exists(report_path):
        print(f"Error: Report file not found: {report_path}")
        return None

    with open(report_path, "r", encoding="utf-8", errors="ignore") as f:
        lines = f.readlines()

    info = {
        "startpoint": "N/A",
        "endpoint": "N/A",
        "slack": "N/A",
        "data_path": "N/A",
        "status": "UNKNOWN",
        "points": [],
        "submodule_delays": {},
        "total_cell_delay": 0.0,
        "total_net_delay": 0.0
    }

    in_table = False
    header_seen = False

    for line in lines:
        if "Startpoint:" in line:
            m = re.search(r"Startpoint:\s+\S+\s+(\S+)", line)
            if m:
                info["startpoint"] = m.group(1)
        elif "Endpoint:" in line:
            m = re.search(r"Endpoint:\s+\S+\s+(\S+)", line)
            if m:
                info["endpoint"] = m.group(1)
        elif "Slack:=" in line:
            m = re.search(r"Slack:=\s+([0-9\.\-]+)", line)
            if m:
                info["slack"] = float(m.group(1))
                info["status"] = "VIOLATED" if info["slack"] < 0 else "MET"
        elif "Data Path:-" in line:
            m = re.search(r"Data Path:-\s+([0-9\.\-]+)", line)
            if m:
                info["data_path"] = float(m.group(1))
        elif "Timing Point" in line and "Delay" in line:
            header_seen = True
            continue
        elif header_seen and line.strip().startswith("#---"):
            in_table = not in_table
            continue
        elif in_table:
            # Parse timing point row
            parts = line.split()
            if len(parts) >= 10:
                pt_name = parts[0]
                # Look for delay and cell name
                # Delay is typically before arrival
                try:
                    # Search for delay number (ps)
                    delay_match = re.search(r"\s+(\d+)\s+(\d+)\s+([-\(\)\w,\.]+)\s*$", line)
                    if delay_match:
                        cell_delay = float(delay_match.group(1))
                        arrival = float(delay_match.group(2))
                    else:
                        cell_delay = 0.0
                        arrival = 0.0
                except Exception:
                    cell_delay = 0.0
                    arrival = 0.0

                cell_type = "N/A"
                for p in parts:
                    if re.match(r"^[A-Z0-9_]+X\d+$", p) or p in ("(arrival)", "DFFRHQX1", "DFFRHQX2", "DFFRHQX4", "DFFRHQX8"):
                        cell_type = p
                        break

                info["points"].append({
                    "point": pt_name,
                    "cell": cell_type,
                    "delay": cell_delay,
                    "arrival": arrival,
                    "line": line.strip()
                })

                # Categorize into functional submodule
                submod = "Other/Top"
                if "u_shifter" in pt_name:
                    if "u_shifter_left" in pt_name:
                        submod = "u_shifter (Left Shift)"
                    elif "u_shifter_right" in pt_name:
                        submod = "u_shifter (Right Shift)"
                    else:
                        submod = "u_shifter"
                elif "u_adder" in pt_name:
                    submod = "u_adder (Adder/Sub)"
                elif "u_cmp" in pt_name:
                    submod = "u_cmp (Comparator)"
                elif "u_logic" in pt_name:
                    submod = "u_logic (Bitwise)"
                elif "u_mux" in pt_name:
                    submod = "u_mux (Output Mux)"
                elif "g_synth_iso" in pt_name or "iso_q" in pt_name:
                    submod = "ISO Registers Wall"

                info["submodule_delays"][submod] = info["submodule_delays"].get(submod, 0.0) + cell_delay
                info["total_cell_delay"] += cell_delay

    return info

def print_report_analysis(info, report_path):
    print("=" * 80)
    print(f"  ALU Timing Path Analysis: {os.path.basename(report_path)}")
    print("=" * 80)
    print(f"  Status        : {info['status']}")
    print(f"  Slack         : {info['slack']} ps")
    print(f"  Data Delay    : {info['data_path']} ps")
    print(f"  Startpoint    : {info['startpoint']}")
    print(f"  Endpoint      : {info['endpoint']}")
    print("-" * 80)
    print("  Delay Breakdown by Submodule / Logic Stage:")
    print("-" * 80)

    total_d = info["data_path"] if isinstance(info["data_path"], (int, float)) and info["data_path"] > 0 else info["total_cell_delay"]
    if total_d > 0:
        for submod, delay in sorted(info["submodule_delays"].items(), key=lambda x: x[1], reverse=True):
            pct = (delay / total_d) * 100.0
            bar = "#" * int(pct / 4)
            print(f"  {submod:<28} : {delay:>7.1f} ps ({pct:>5.1f}%) | {bar}")
    else:
        print("  No delay data extracted.")

    print("=" * 80)

def parse_operations_csv(csv_path):
    if not os.path.exists(csv_path):
        print(f"CSV file not found: {csv_path}")
        return

    print("=" * 105)
    print(f"  biRISC-V ALU Operations Timing Summary ({os.path.basename(csv_path)})")
    print("=" * 105)
    print(f"  {'Operation':<22} | {'Opcode':<6} | {'Status':<8} | {'Slack (ps)':<11} | {'Delay (ps)':<11} | {'Critical Endpoint':<30}")
    print("-" * 105)

    with open(csv_path, "r", encoding="utf-8") as f:
        lines = f.readlines()

    header = True
    rows = []
    for line in lines:
        line = line.strip()
        if not line or line.startswith("Frequency_MHz"):
            continue
        if header and "Operation" in line:
            header = False
            continue
        parts = [p.strip().strip('"') for p in line.split(",")]
        if len(parts) >= 8:
            op_name, op_code, op_desc, status, slack, delay, start_pt, end_pt = parts[:8]
            rows.append((op_name, op_code, status, slack, delay, end_pt))

    # Sort by slack (lowest / most critical first)
    def parse_slack(val):
        try: return float(val)
        except Exception: return 999999.0

    rows.sort(key=lambda r: parse_slack(r[3]))

    for r in rows:
        print(f"  {r[0]:<22} | {r[1]:<6} | {r[2]:<8} | {r[3]:<11} | {r[4]:<11} | {r[5]:<30}")

    print("=" * 105)

def main():
    parser = argparse.ArgumentParser(description="biRISC-V ALU Timing Report and Critical Path Analyzer")
    parser.add_argument("--report", "-r", help="Path to a Genus timing report (*.rpt)")
    parser.add_argument("--csv", "-c", help="Path to biriscv_alu_operations_timing.csv")
    args = parser.parse_args()

    if args.csv:
        parse_operations_csv(args.csv)
    elif args.report:
        info = parse_timing_report(args.report)
        if info:
            print_report_analysis(info, args.report)
    else:
        # Auto-discover recent reports
        search_dirs = [
            "biriscv-new/synthesis/reports",
            "synthesis/reports",
            "biriscv-new/synthesis/reports_versions"
        ]
        found_any = False
        for sdir in search_dirs:
            if os.path.exists(sdir):
                for root, _, files in os.walk(sdir):
                    for file in files:
                        if file.endswith("_timing.rpt") or file.endswith("_timing_detailed.rpt"):
                            rpt_p = os.path.join(root, file)
                            print(f"\nAnalyzing found report: {rpt_p}")
                            info = parse_timing_report(rpt_p)
                            if info and info["points"]:
                                print_report_analysis(info, rpt_p)
                                found_any = True
                        elif file == "biriscv_alu_operations_timing.csv":
                            csv_p = os.path.join(root, file)
                            parse_operations_csv(csv_p)
                            found_any = True
        if not found_any:
            print("Usage:")
            print("  python analyze_alu_timing.py --report <path_to_report.rpt>")
            print("  python analyze_alu_timing.py --csv <path_to_operations_timing.csv>")

if __name__ == "__main__":
    main()

