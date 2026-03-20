# =============================================================================
# MPMA — Multi-Port Memory Arbiter with QoS
# Timing Constraints
# Target: Artix-7 / XC7A35T (Basys3 / Nexys A7 compatible)
# Tool:   Vivado 2025.2
# =============================================================================

# -----------------------------------------------------------------------------
# Primary Clock — 100 MHz
# Adjust the -period value and port name to match your board's oscillator.
# Basys3 / Nexys A7: 100 MHz clock on W5 (sys_clk_p) or E3 (clk)
# -----------------------------------------------------------------------------
create_clock -name clk -period 10.000 [get_ports clk]

# -----------------------------------------------------------------------------
# Clock uncertainty / jitter (optional, recommended for conservative closure)
# -----------------------------------------------------------------------------
set_clock_uncertainty 0.200 [get_clocks clk]

# -----------------------------------------------------------------------------
# Input / Output delays
# These are illustrative values. Adjust to match your actual PCB/interface.
# -----------------------------------------------------------------------------

# All port inputs: assume 2 ns setup margin relative to clock edge
set_input_delay -clock clk -max 2.000 [get_ports {port*_en port*_wr port*_addr* \
    port*_wdata* port*_priority* port*_burst_len* \
    cfg_en cfg_wr cfg_addr* cfg_wdata* rst_n}]

set_input_delay -clock clk -min 0.500 [get_ports {port*_en port*_wr port*_addr* \
    port*_wdata* port*_priority* port*_burst_len* \
    cfg_en cfg_wr cfg_addr* cfg_wdata* rst_n}]

# All port outputs: assume 2 ns hold margin
set_output_delay -clock clk -max 2.000 [get_ports {port*_rdata* port*_ready cfg_rdata*}]
set_output_delay -clock clk -min -0.500 [get_ports {port*_rdata* port*_ready cfg_rdata*}]

# -----------------------------------------------------------------------------
# False paths
# Reset is asynchronous and does not need timing closure on the path itself.
# -----------------------------------------------------------------------------
set_false_path -from [get_ports rst_n]
