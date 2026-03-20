# Changelog

All notable changes to MPMA are documented here.  
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).  
Versioning follows [Semantic Versioning](https://semver.org/).

---

## [2.0.0] — 2026-02-04 (v2 — current)

### Added
- **Weighted Fair Queuing** arbitration mode (`ARBITER_MODE = 2'b10`) with per-port 4-bit weight registers and credit-based scheduling.
- **Burst transaction support**: up to 15-beat bursts with automatic address increment and bus-locking during the burst.
- **Performance monitor** (`performance_monitor.v`): hardware counters for transaction counts, cumulative latency, conflict events, stall cycles, and memory utilization.
- **Configuration register file** (`config_registers.v`): full memory-mapped access to all configuration and performance counter registers at base address `0x300`.
- **Starvation prevention**: per-port wait-cycle counters in the scheduler; automatic priority boost to maximum after `STARVATION_THRESHOLD` (default 30) consecutive denied cycles.
- Block Design (`mpma_bd1`) integrating all custom IPs for Vivado IP Integrator flow.
- Comprehensive self-checking testbench (`tb_memory_system.v`) with four test scenarios: priority, round-robin, weighted, and burst.

### Changed
- `scheduler.v` renamed to `scheduler_qos.v`; significant internal restructuring to support all three arbitration modes and burst locking.
- `port_if.v` renamed to `port_if_enhanced.v`; FIFO depth generalized via `FIFO_DEPTH` parameter; added burst-length field to the request FIFO.
- Top-level (`memory_system_top.v`) updated to wire performance monitor and config register file.

### Fixed
- Round-robin `rr_sel` logic now correctly handles the case where only the last-granted port has a pending request (work-conserving fallback).

---

## [1.0.0] — 2026-01-16 (v1 — initial)

### Added
- Basic 4-port memory arbiter with fixed-priority and round-robin modes.
- Simple port interface (`port_if.v`) with 8-deep request FIFO.
- Synchronous BRAM controller (`bram_ctrl.v`).
- Initial testbench with priority and round-robin test cases.
- Vivado 2025.2 project targeting Artix-7 XC7A35T.
