#!/bin/bash
# =============================================================================
# biRISC-V ALU Frequency Sweep Launcher for Cadence Genus (150 - 190 MHz)
# =============================================================================

set -e

# Default directories if not set in environment
export PROJECT_DIR="${PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
export TECH_DIR="${TECH_DIR:-/home/tools/design_kits/cadence/GPDK045}"
export HDL_LANG="${HDL_LANG:-v2001}"
export OP_CORNER="${OP_CORNER:-WORST}"
export DESIGNS="biriscv_alu"
export HDL_NAME="biriscv_alu"
export GSYNTH_ISO="${GSYNTH_ISO:-1}"
export PRESERVE_HIERARCHY="${PRESERVE_HIERARCHY:-1}"
export ALU_FREQ_LIST="${ALU_FREQ_LIST:-150 160 170 180 190}"

echo "=================================================================="
echo "  Starting biRISC-V ALU Synthesis Frequency Sweep (150 - 190 MHz)"
echo "  PROJECT_DIR        : ${PROJECT_DIR}"
echo "  TECH_DIR           : ${TECH_DIR}"
echo "  OP_CORNER          : ${OP_CORNER}"
echo "  GSYNTH_ISO         : ${GSYNTH_ISO}"
echo "  PRESERVE_HIERARCHY : ${PRESERVE_HIERARCHY}"
echo "  ALU_FREQ_LIST      : ${ALU_FREQ_LIST}"
echo "=================================================================="

# Create work directory
mkdir -p "${PROJECT_DIR}/synthesis/work"
cd "${PROJECT_DIR}/synthesis/work"

# Launch Genus with the biriscv_alu sweep script
genus -abort_on_error \
      -lic_startup Genus_Synthesis \
      -lic_startup_options Genus_Physical_Opt \
      -log genus_biriscv_alu_sweep \
      -overwrite \
      -files "${PROJECT_DIR}/synthesis/scripts/biriscv_alu.tcl"

echo "=================================================================="
echo "  ALU Sweep Finished! Reports located at:"
echo "  ${PROJECT_DIR}/synthesis/reports/biriscv_alu/"
echo "=================================================================="
