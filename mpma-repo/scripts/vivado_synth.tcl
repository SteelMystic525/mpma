# =============================================================================
# vivado_synth.tcl — Non-project Vivado synthesis & implementation script
# Usage:  vivado -mode batch -source scripts/vivado_synth.tcl
#
# Targets Artix-7 XC7A35TCPG236-1 (Basys3).
# Edit PART and BOARD below for other targets.
# =============================================================================

set PART      "xc7a35tcpg236-1"
set TOP       "memory_system_top"
set PROJ_NAME "mpma"
set OUT_DIR   "./vivado_out"

# Resolve paths relative to script location
set SCRIPT_DIR [file dirname [file normalize [info script]]]
set REPO_ROOT  [file dirname $SCRIPT_DIR]
set RTL_DIR    [file join $REPO_ROOT "rtl"]
set CONSTR_DIR [file join $REPO_ROOT "constraints"]

file mkdir $OUT_DIR

# -------------------------------------------------------------------------
# Source files
# -------------------------------------------------------------------------
set RTL_FILES [list \
    [file join $RTL_DIR "bram_ctrl.v"]            \
    [file join $RTL_DIR "config_registers.v"]     \
    [file join $RTL_DIR "performance_monitor.v"]  \
    [file join $RTL_DIR "port_if_enhanced.v"]     \
    [file join $RTL_DIR "scheduler_qos.v"]        \
    [file join $RTL_DIR "memory_system_top.v"]    \
]

set XDC_FILE [file join $CONSTR_DIR "timing.xdc"]

# -------------------------------------------------------------------------
# Read design
# -------------------------------------------------------------------------
puts "INFO: Reading RTL sources..."
foreach f $RTL_FILES {
    read_verilog -sv $f
}

read_xdc $XDC_FILE

# -------------------------------------------------------------------------
# Synthesis
# -------------------------------------------------------------------------
puts "INFO: Running synthesis..."
synth_design \
    -top    $TOP  \
    -part   $PART \
    -flatten_hierarchy rebuilt \
    -fsm_extraction auto

write_checkpoint -force [file join $OUT_DIR "post_synth.dcp"]

report_utilization  -file [file join $OUT_DIR "utilization_synth.rpt"]
report_timing_summary -file [file join $OUT_DIR "timing_synth.rpt"] -max_paths 10

# -------------------------------------------------------------------------
# Implementation
# -------------------------------------------------------------------------
puts "INFO: Running implementation (opt → place → route)..."
opt_design
place_design
phys_opt_design
route_design

write_checkpoint -force [file join $OUT_DIR "post_route.dcp"]

# -------------------------------------------------------------------------
# Reports
# -------------------------------------------------------------------------
puts "INFO: Writing reports..."
report_utilization      -file [file join $OUT_DIR "utilization_route.rpt"]
report_timing_summary   -file [file join $OUT_DIR "timing_route.rpt"] -max_paths 20 -warn_on_violation
report_power            -file [file join $OUT_DIR "power.rpt"]
report_drc              -file [file join $OUT_DIR "drc.rpt"]

# -------------------------------------------------------------------------
# Bitstream (comment out if only synthesis/implementation is needed)
# -------------------------------------------------------------------------
puts "INFO: Generating bitstream..."
write_bitstream -force [file join $OUT_DIR "${PROJ_NAME}.bit"]

puts "INFO: Done. Outputs written to: $OUT_DIR"
