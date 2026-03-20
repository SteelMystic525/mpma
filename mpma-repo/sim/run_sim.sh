#!/usr/bin/env bash
# =============================================================================
# run_sim.sh — Compile and simulate MPMA with Icarus Verilog
# Usage:  cd sim && ./run_sim.sh [--waves]
#
# Dependencies:
#   iverilog  (Icarus Verilog 11+)
#   vvp       (part of iverilog package)
#   gtkwave   (optional, for waveform viewing)
#
# Install on Ubuntu/Debian:
#   sudo apt-get install iverilog gtkwave
# Install on macOS (Homebrew):
#   brew install icarus-verilog gtkwave
# =============================================================================

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RTL_DIR="${REPO_ROOT}/rtl"
TB_DIR="${REPO_ROOT}/tb"
SIM_OUT="${REPO_ROOT}/sim/out"
VCD_FILE="${SIM_OUT}/memory_system.vcd"
WAVES=0

# Parse arguments
for arg in "$@"; do
  case "$arg" in
    --waves) WAVES=1 ;;
    -h|--help)
      echo "Usage: $0 [--waves]"
      echo "  --waves   Open GTKWave after simulation"
      exit 0
      ;;
  esac
done

mkdir -p "${SIM_OUT}"

echo "============================================"
echo "  MPMA — Icarus Verilog Simulation"
echo "============================================"
echo ""

# RTL source list (order matters for iverilog)
RTL_SOURCES=(
  "${RTL_DIR}/bram_ctrl.v"
  "${RTL_DIR}/config_registers.v"
  "${RTL_DIR}/performance_monitor.v"
  "${RTL_DIR}/port_if_enhanced.v"
  "${RTL_DIR}/scheduler_qos.v"
  "${RTL_DIR}/memory_system_top.v"
)

TB_SOURCE="${TB_DIR}/tb_memory_system.v"

echo "[1/3] Compiling RTL + testbench..."
iverilog -g2001 -Wall \
  -o "${SIM_OUT}/mpma_sim" \
  "${RTL_SOURCES[@]}" \
  "${TB_SOURCE}"

echo "[2/3] Running simulation..."
vvp "${SIM_OUT}/mpma_sim" | tee "${SIM_OUT}/sim_log.txt"

echo ""
echo "[3/3] Simulation complete."
echo "  Log:      ${SIM_OUT}/sim_log.txt"

if [ -f "${VCD_FILE}" ]; then
  echo "  Waveform: ${VCD_FILE}"
  if [ "${WAVES}" -eq 1 ]; then
    if command -v gtkwave &>/dev/null; then
      echo "  Opening GTKWave..."
      gtkwave "${VCD_FILE}" &
    else
      echo "  GTKWave not found. Install it to view waveforms."
    fi
  else
    echo "  Run with --waves to open GTKWave automatically."
  fi
fi

echo ""
echo "============================================"
