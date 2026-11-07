#!/bin/bash
# =============================================================================
# biRISC-V NPC Parameter Sweep Launcher for Cadence Genus
# =============================================================================

set -e

# Default directories if not set in environment
export PROJECT_DIR="${PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
export TECH_DIR="${TECH_DIR:-/home/tools/design_kits/cadence/GPDK045}"
export HDL_LANG="${HDL_LANG:-v2001}"
export FREQ_MHZ="${FREQ_MHZ:-100}"
export OP_CORNER="${OP_CORNER:-WORST}"
export DESIGNS="biriscv_npc"
export HDL_NAME="biriscv_npc"

echo "=================================================================="
echo "  Starting biRISC-V NPC Synthesis Sweep"
echo "  PROJECT_DIR : ${PROJECT_DIR}"
echo "  TECH_DIR    : ${TECH_DIR}"
echo "  FREQ_MHZ    : ${FREQ_MHZ}"
echo "  OP_CORNER   : ${OP_CORNER}"
echo "=================================================================="

# Create work directory
mkdir -p "${PROJECT_DIR}/synthesis/work"
cd "${PROJECT_DIR}/synthesis/work"

# Launch Genus with the biriscv_npc parameter sweep script
genus -abort_on_error \
      -lic_startup Genus_Synthesis \
      -lic_startup_options Genus_Physical_Opt \
      -log genus_biriscv_npc_sweep \
      -overwrite \
      -files "${PROJECT_DIR}/synthesis/scripts/biriscv_npc.tcl"

echo "=================================================================="
echo "  Sweep Finished! Reports located at:"
echo "  ${PROJECT_DIR}/synthesis/reports/biriscv_npc/"
echo "=================================================================="
