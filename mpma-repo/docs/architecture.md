# MPMA Architecture — Detailed Design Notes

## Overview

The Multi-Port Memory Arbiter (MPMA) provides a shared, single-port BRAM resource to four independent requestor ports. Because the BRAM has only one read/write port, at most one transaction can proceed per clock cycle. The arbiter's job is to decide, each cycle, which of the (potentially multiple) pending requestors wins access — while ensuring fairness, respecting QoS priorities, and preventing starvation.

---

## Data Path

### Request Path (Upstream → BRAM)

```
Port N (external)
    │  port_en, port_wr, port_addr, port_wdata, port_priority, port_burst_len
    ▼
port_if_enhanced[N]
    │  Circular FIFO (depth = FIFO_DEPTH)
    │  FIFO head → req_valid, req_wr, req_addr, req_wdata, req_priority, req_burst_len
    ▼
scheduler_qos
    │  Arbitration: selects one port per cycle
    │  bram_en, bram_wr, bram_addr, bram_wdata  (registered, 1-cycle pipeline)
    ▼
bram_ctrl
    │  Synchronous BRAM write or read
    │  bram_rdata (available next cycle)
    ▼
scheduler_qos  (response pipeline)
    │  resp_valid[N], resp_rdata[N]
    ▼
port_if_enhanced[N]
    │  Captures rdata on resp_valid
    ▼
Port N (external)  — port_rdata
```

### Timing Diagram (Single Read Transaction)

```
Cycle:        1       2       3       4
              ─────────────────────────────
port_en       1       0       0       0
req_valid     1       1       0       0
bram_en       0       1       0       0      ← registered in scheduler
bram_rdata    X       X      DATA     X      ← BRAM 1-cycle latency
resp_valid    0       0       1       0      ← bram_en delayed by 1
port_rdata    X       X      DATA    DATA    ← captured by port_if
req_ready     0       0       1       0      ← advances FIFO rd_ptr
```

---

## Scheduler — Arbitration Engine

### Priority Mode (mode = 2'b00)

The combinational `priority_sel` logic uses a waterfall comparator: port 0 wins if its (boosted) priority exceeds all others, then port 1 is tested against ports 2 and 3, and so on. This is a strict fixed-priority encoder with ties broken in favour of lower port numbers.

**Starvation prevention:** Each port that has a pending request but is not selected increments a 16-bit `wait_cycles_N` counter. When the counter exceeds `STARVATION_THRESHOLD` (default 30), the port's effective priority (`boosted_priority_N`) is forced to 2'b11 (maximum). The counter and boost reset as soon as the port wins a grant.

### Round-Robin Mode (mode = 2'b01)

A 2-bit `rr_last_grant` register tracks the port that won last cycle. The combinational `rr_sel` logic scans ports in order starting from `rr_last_grant + 1`, wrapping around, and selects the first port with a valid request. If no other port has a request, the same port is selected again (work-conserving).

### Weighted Fair Queuing Mode (mode = 2'b10)

Each port maintains an 8-bit credit accumulator (`weight_credits_N`). Every clock cycle, each port gains credits equal to its configured weight (`port_weight_N`, 4-bit, 1–15). When a port is granted access, it is debited a fixed cost of 16 credits. The combinational `weighted_sel` logic picks the port with the highest credits among those with a valid request. The credit mechanism is equivalent to a deficit round-robin, producing long-run bandwidth allocation proportional to the configured weights.

**Example:** Weights 8, 4, 2, 1. Under sustained load:
- Port 0 earns 8 credits/cycle, costs 16 per grant → granted every 2 cycles on average
- Port 1 earns 4 credits/cycle → granted every 4 cycles on average
- Ratio converges to 8:4:2:1 ✓

### Burst Locking

When the selected port's `req_burst_len > 0`, the scheduler enters burst mode:
- `in_burst` is asserted, `burst_master` captures the winning port
- `burst_addr` auto-increments each cycle
- The `sel` mux is overridden to always return `burst_master` regardless of the arbitration mode
- After `burst_count` cycles (= original `burst_len`), `in_burst` de-asserts and normal arbitration resumes

During a burst, `conflict_flag` is not suppressed — other ports will see their requests stalled, which is reflected in stall cycle counters.

---

## Port Interface — FIFO Design

Each `port_if_enhanced` instance contains a fixed-depth circular FIFO. The implementation uses explicitly named registers (`fifo_addr_0` … `fifo_addr_7`) rather than an array, for broad tool compatibility. The read and write pointers are one bit wider than the address (`PTR_WIDTH = log2(FIFO_DEPTH) + 1`) to distinguish full from empty:

- **Empty**: `wr_ptr == rd_ptr`
- **Full**: MSBs differ, lower bits equal

`port_ready` (the backpressure signal to the external port) is de-asserted when the FIFO is full, preventing request loss. The FIFO head is always presented to the scheduler as a registered output; the read pointer advances one cycle after `req_ready` is asserted by the scheduler.

---

## Performance Monitor

The performance monitor is a purely combinational observer (with registered outputs) wired into all major bus signals. It maintains the following per-port and global counters:

| Counter | Update Condition |
|---|---|
| `total_cycles` | Increments every clock |
| `active_cycles` | Increments when `granted_valid` is asserted |
| `transaction_count_N` | Increments when `resp_valid[N]` is asserted |
| `total_latency_N` | Accumulates (`current_cycle - request_timestamp_N`) on each `resp_valid[N]` |
| `conflict_count_N` | Increments when `conflict_flag[N]` is asserted (port N had a request AND was not selected when at least one other port also had a pending request) |
| `stall_cycles_N` | Increments when `req_valid[N]` is asserted but `req_accepted[N]` is not |
| `avg_latency_N` | Computed as `total_latency_N / transaction_count_N` (updated after each transaction) |
| `memory_utilization_percent` | Computed as `(active_cycles * 100) / total_cycles` |

Timestamp tracking: when a request first becomes valid at the FIFO head (`req_valid[N]` asserts and `request_pending_N` is not already set), the current `cycle_count` is stored as `request_timestamp_N`. On response (`resp_valid[N]`), the elapsed time is added to `total_latency_N`.

All counters can be reset synchronously by writing 1 to the `RESET_COUNTERS` register (`offset 0x24`). The reset pulse is self-clearing (the register resets to 0 the next cycle).

---

## Configuration Register File

The register file decodes accesses within the window `[BASE_ADDR, BASE_ADDR + 0x80)`. A simple offset comparison (`reg_addr - BASE_ADDR`) selects the target register. Read accesses are handled combinationally; write accesses are clocked.

The arbiter configuration outputs (`arbiter_mode`, `port_weight_N`, `port_priority_N`) drive the scheduler directly and take effect the cycle after the write completes.

Performance counter inputs are read-only registers mapped directly from the performance monitor outputs — no internal copy is maintained, keeping the logic minimal.

---

## Synthesis Considerations

### BRAM Inference

`bram_ctrl` uses a simple `always @(posedge clk)` block with a registered read. Xilinx Vivado will infer this as a RAMB18 or RAMB36 primitive depending on depth and width. For `ADDR_W=10`, `DATA_W=32` (1024 × 32-bit = 32 Kbits), a single RAMB36E1 is used.

### Critical Path

The longest combinational path is in `scheduler_qos`: the priority encoder (`priority_sel`) or weighted comparator (`weighted_sel`) → mux (`sel`) → BRAM address register. At 100 MHz (10 ns period) on Artix-7 speed grade -1, this is comfortably closed. At 150 MHz+ the weighted comparator chain may require retiming or pipelining.

### Area Scaling

The current design is hardcoded for 4 ports. Generalizing to `NUM_PORTS` ports would require generate blocks in `port_if_enhanced` (FIFO storage) and `scheduler_qos` (priority encoder, starvation counters, weight credits). The parameter `NUM_PORTS` is threaded through but not fully exercised — a parameterized rewrite is a natural next step.

---

## Known Limitations and Future Work

1. **Fixed port count**: The RTL is structurally parameterized for `NUM_PORTS=4` but not generalized. Adding generate-based loops would allow arbitrary port counts without code duplication.

2. **No write byte enables**: The current data bus is word-wide with no byte-enable strobes. Adding a `be` (byte enable) signal to the port interface and BRAM controller is straightforward.

3. **Single BRAM bank**: The design wraps a single synchronous BRAM. Extending to multiple banks (banked by address MSBs) would allow simultaneous access to different banks, significantly increasing throughput when ports access non-overlapping regions.

4. **AXI4-Lite wrapper**: Wrapping the configuration register file in an AXI4-Lite slave interface would enable integration with Zynq PS or any AXI interconnect, replacing the custom config bus.

5. **Formal verification**: The arbitration logic (especially starvation prevention) is a good candidate for bounded model checking with tools such as SymbiYosys / Yosys-smtbmc.
