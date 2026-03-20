# MPMA — Multi-Port Memory Arbiter with QoS

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Language: Verilog](https://img.shields.io/badge/Language-Verilog--2001-blue.svg)](rtl/)
[![Tool: Vivado](https://img.shields.io/badge/Tool-Vivado%202025.2-orange.svg)](https://www.xilinx.com/products/design-tools/vivado.html)
[![Status: Simulated](https://img.shields.io/badge/Status-Simulated%20%26%20Synthesized-green.svg)]()

A fully parameterized, FPGA-ready **4-port shared-memory arbiter** implemented in synthesizable Verilog. Supports three runtime-selectable arbitration policies, hardware QoS enforcement with starvation prevention, burst transactions, and a rich set of performance counters — all accessible through a memory-mapped configuration register file.

---

## Table of Contents

- [Features](#features)
- [Architecture](#architecture)
- [Module Hierarchy](#module-hierarchy)
- [Parameters](#parameters)
- [Register Map](#register-map)
- [Arbitration Modes](#arbitration-modes)
- [Directory Structure](#directory-structure)
- [Simulation](#simulation)
- [Synthesis (Vivado)](#synthesis-vivado)
- [Performance Metrics](#performance-metrics)
- [Design Notes](#design-notes)
- [License](#license)

---

## Features

| Feature | Description |
|---|---|
| **4 independent ports** | Each port has a FIFO request buffer (depth configurable via `FIFO_DEPTH`) |
| **3 arbitration modes** | Priority, Round-Robin, Weighted Fair Queuing — switchable at runtime |
| **Starvation prevention** | Automatic priority boosting after `STARVATION_THRESHOLD` wait cycles |
| **Burst transactions** | Up to 15-beat bursts; burst master holds the bus for full duration |
| **Performance monitoring** | Per-port transaction count, average latency, conflict count, stall cycles, memory utilization |
| **Memory-mapped config** | Register file at base address `0x300`; all counters software-readable |
| **Fully parameterized** | Address width, data width, port count, FIFO depth, priority width all via parameters |
| **Synthesizable** | Targets Xilinx 7-series / UltraScale; synthesized and simulated with Vivado 2025.2 |

---

## Architecture

```
                         ┌─────────────────────────────────────────────┐
                         │              memory_system_top               │
                         │                                              │
  Port 0 ──────────────► │  port_if_enhanced[0]  ──┐                   │
  Port 1 ──────────────► │  port_if_enhanced[1]  ──┤                   │
  Port 2 ──────────────► │  port_if_enhanced[2]  ──┤──► scheduler_qos ─┼──► bram_ctrl
  Port 3 ──────────────► │  port_if_enhanced[3]  ──┘         │         │
                         │                                    ▼         │
  Config Bus ───────────► │  config_registers ◄──── performance_monitor│
                         └─────────────────────────────────────────────┘
```

Each port interface buffers incoming requests in a FIFO and presents the head of the queue to the central scheduler. The scheduler selects one port per cycle according to the active arbitration policy, drives the BRAM controller, and returns responses to the winning port. The performance monitor observes all bus activity and computes live metrics fed back into the configuration register file.

---

## Module Hierarchy

```
memory_system_top
├── port_if_enhanced  × 4   (request FIFO + port handshaking)
├── scheduler_qos            (arbitration engine)
├── bram_ctrl                (single-port synchronous BRAM)
├── performance_monitor      (hardware performance counters)
└── config_registers         (memory-mapped register file)
```

### Module Descriptions

#### `memory_system_top`
Top-level integration wrapper. Exposes the 4-port user interface, configuration bus, and ties all submodules together. Instantiates all five submodules and wires the internal bus.

#### `port_if_enhanced`
Per-port request buffer. Implements an 8-deep circular FIFO (parameterizable) to decouple the upstream producer from the shared memory bus. Presents the FIFO head to the scheduler each cycle and advances the read pointer on acknowledgment. Also captures read-data responses and presents them to the user.

#### `scheduler_qos`
Core arbitration engine. Implements all three policies in combinational logic, then clocks the decision into registered BRAM control signals. Maintains starvation counters and priority-boosting logic. Handles burst locking: once a burst starts, the bus is held for the full beat count without re-arbitrating.

#### `bram_ctrl`
Single-port synchronous block RAM with registered read output (1-cycle read latency). Directly infers BRAM primitives in Xilinx tools.

#### `performance_monitor`
Tracks per-port transaction counts, cumulative latency (timestamp-based), conflict events, and stall cycles. Computes average latency and memory utilization as derived metrics updated every cycle.

#### `config_registers`
Memory-mapped register file sitting at base address `0x300`. Provides read/write access to arbiter configuration and read-only access to all performance counters.

---

## Parameters

| Parameter | Default | Description |
|---|---|---|
| `ADDR_W` | 10 | Address bus width (memory depth = 2^ADDR_W words) |
| `DATA_W` | 32 | Data bus width in bits |
| `NUM_PORTS` | 4 | Number of requestor ports |
| `FIFO_DEPTH` | 8 | Per-port request FIFO depth |
| `PRIORITY_W` | 2 | Priority field width (2-bit → 4 priority levels) |
| `STARVATION_THRESHOLD` | 30 | Wait cycles before automatic priority boost |

---

## Register Map

Base address: `0x300`. All registers are 32-bit wide.

| Offset | Name | R/W | Description |
|---|---|---|---|
| `0x00` | `ARBITER_MODE` | R/W | 0 = Priority, 1 = Round-Robin, 2 = Weighted |
| `0x04` | `PORT0_PRIORITY` | R/W | Static priority for port 0 (0–3) |
| `0x08` | `PORT1_PRIORITY` | R/W | Static priority for port 1 |
| `0x0C` | `PORT2_PRIORITY` | R/W | Static priority for port 2 |
| `0x10` | `PORT3_PRIORITY` | R/W | Static priority for port 3 |
| `0x14` | `PORT0_WEIGHT` | R/W | WFQ weight for port 0 (default 1) |
| `0x18` | `PORT1_WEIGHT` | R/W | WFQ weight for port 1 |
| `0x1C` | `PORT2_WEIGHT` | R/W | WFQ weight for port 2 |
| `0x20` | `PORT3_WEIGHT` | R/W | WFQ weight for port 3 |
| `0x24` | `RESET_COUNTERS` | W | Write 1 to reset all performance counters |
| `0x28` | `TOTAL_CYCLES` | R | Total clock cycles elapsed |
| `0x2C` | `ACTIVE_CYCLES` | R | Cycles where BRAM was active |
| `0x30` | `TX_COUNT_P0` | R | Completed transactions, port 0 |
| `0x34` | `TX_COUNT_P1` | R | Completed transactions, port 1 |
| `0x38` | `TX_COUNT_P2` | R | Completed transactions, port 2 |
| `0x3C` | `TX_COUNT_P3` | R | Completed transactions, port 3 |
| `0x40` | `AVG_LAT_P0` | R | Average latency (cycles), port 0 |
| `0x44` | `AVG_LAT_P1` | R | Average latency (cycles), port 1 |
| `0x48` | `AVG_LAT_P2` | R | Average latency (cycles), port 2 |
| `0x4C` | `AVG_LAT_P3` | R | Average latency (cycles), port 3 |
| `0x50` | `CONFLICT_P0` | R | Conflict count, port 0 |
| `0x54` | `CONFLICT_P1` | R | Conflict count, port 1 |
| `0x58` | `CONFLICT_P2` | R | Conflict count, port 2 |
| `0x5C` | `CONFLICT_P3` | R | Conflict count, port 3 |
| `0x60` | `STALL_P0` | R | Stall cycles, port 0 |
| `0x64` | `STALL_P1` | R | Stall cycles, port 1 |
| `0x68` | `STALL_P2` | R | Stall cycles, port 2 |
| `0x6C` | `STALL_P3` | R | Stall cycles, port 3 |
| `0x70` | `MEM_UTIL_PCT` | R | Memory utilization (%) |

---

## Arbitration Modes

### Mode 0 — Fixed Priority (`ARBITER_MODE = 2'b00`)

Each port has a 2-bit static priority set via `PORT{n}_PRIORITY`. Higher value wins. Starvation prevention automatically boosts a waiting port's effective priority to 3 (highest) after `STARVATION_THRESHOLD` consecutive denied cycles.

### Mode 1 — Round-Robin (`ARBITER_MODE = 2'b01`)

Strict rotating grant across all valid requestors. The last-granted port is tracked; the next valid port in the rotation wins.

### Mode 2 — Weighted Fair Queuing (`ARBITER_MODE = 2'b10`)

Each port accumulates credits every cycle equal to its configured weight. When a port is granted, it pays a fixed cost of 16 credits. The port with the highest accumulated credits wins. This naturally produces long-run bandwidth ratios proportional to the configured weights.

---

## Directory Structure

```
mpma/
├── rtl/                        # Synthesizable RTL sources
│   ├── memory_system_top.v     # Top-level integration
│   ├── scheduler_qos.v         # Arbitration engine (all 3 modes)
│   ├── port_if_enhanced.v      # Per-port FIFO + handshaking
│   ├── bram_ctrl.v             # Synchronous single-port BRAM
│   ├── performance_monitor.v   # Hardware performance counters
│   └── config_registers.v      # Memory-mapped register file
├── tb/
│   └── tb_memory_system.v      # Self-checking testbench (4 test scenarios)
├── constraints/
│   └── timing.xdc              # Timing constraints (100 MHz target)
├── sim/
│   └── run_sim.sh              # One-shot Icarus Verilog simulation script
├── scripts/
│   └── vivado_synth.tcl        # Non-project Vivado synthesis script
├── docs/
│   └── architecture.md         # Detailed architecture notes
└── README.md
```

---

## Simulation

### Icarus Verilog (open-source, quick start)

```bash
cd sim
chmod +x run_sim.sh
./run_sim.sh
```

This compiles all RTL and the testbench, runs simulation, and opens the VCD waveform in GTKWave (if installed).

### Vivado Simulator

1. Open Vivado 2025.2
2. Create or open the project (`mpma_v2.xpr` in the original archive)
3. Set `tb_memory_system` as the active simulation top
4. Run **Simulation → Run Behavioral Simulation**
5. Add signals of interest to the waveform viewer

### Testbench Scenarios

The testbench (`tb/tb_memory_system.v`) exercises four scenarios automatically:

| Test | Mode | Description | Expected Outcome |
|---|---|---|---|
| TEST 1 | Priority | P0=0, P1=1, P2=2, P3=3 | P3 captures majority of grants |
| TEST 2 | Round-Robin | All ports equal | ~equal transaction counts across all ports |
| TEST 3 | Weighted | Weights 8:4:2:1 | Bandwidth ratio ≈ 8:4:2:1 |
| TEST 4 | Round-Robin | 8-beat bursts | High memory utilization |

After each test, metrics are printed to the simulator console and verified against expected ranges.

---

## Synthesis (Vivado)

### Tcl Script (non-project mode)

```bash
vivado -mode batch -source scripts/vivado_synth.tcl
```

### Manual Steps

1. Open Vivado → **Create Project** → RTL Project
2. Add all files under `rtl/` as design sources
3. Add `tb/tb_memory_system.v` as simulation source
4. Add `constraints/timing.xdc` as a constraint
5. Set `memory_system_top` as the top module
6. Run **Synthesis** → **Implementation** → **Generate Bitstream**

### Resource Utilization (estimated, Artix-7 XC7A35T)

| Resource | Estimated Usage |
|---|---|
| LUTs | ~800–1200 |
| FFs | ~600–900 |
| BRAM 36K | 1 |
| DSPs | 0 |
| Fmax | >100 MHz |

Actual results will vary by target device and Vivado version.

---

## Performance Metrics

All metrics are available live through the register file. Below are representative results from the testbench:

**TEST 1 (Priority Arbitration, 200 tx/port):**
- Port 3 (priority 3) typically receives 60–70% of grants
- Ports 0–2 still complete all transactions due to starvation prevention
- Average latency increases with lower priority

**TEST 2 (Round-Robin, 200 tx/port):**
- Transaction counts within ±5% across all four ports
- Conflict counts are symmetric
- No starvation observed

**TEST 3 (Weighted 8:4:2:1, 200 tx/port):**
- Port 0 : Port 1 : Port 2 : Port 3 grant ratio converges to ~8:4:2:1 over 200+ transactions

**TEST 4 (8-beat bursts, round-robin):**
- Memory utilization typically 85–95%
- Burst locking visible as extended grants to a single port

---

## Design Notes

- **Reset polarity**: All modules use active-low asynchronous reset (`rst_n`).
- **BRAM read latency**: The BRAM controller has exactly 1 cycle read latency. The scheduler accounts for this by piping the response one cycle after the grant.
- **Burst addressing**: Burst addresses auto-increment from the base address provided in the first beat. The burst master holds the bus; other ports see `req_ready = 0` for the burst duration.
- **Weight credits**: In WFQ mode, credits accumulate every cycle even when a port has no pending requests. This can cause initial credit imbalance; in practice, under sustained load the ratios converge quickly.
- **FIFO depth**: The per-port FIFOs are currently unrolled (8 explicit registers) for tool compatibility. A generate-based implementation is straightforward for larger depths.

---

## License

MIT License — see [LICENSE](LICENSE) for details.
