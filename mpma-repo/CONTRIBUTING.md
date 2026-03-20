# Contributing to MPMA

Thank you for your interest in contributing! This document outlines the process for reporting issues, submitting changes, and maintaining code quality.

## Reporting Issues

When filing a bug report, please include:
- A minimal reproduction: the exact RTL change or simulation input that triggers the problem
- Simulator version (`iverilog -V` or Vivado version)
- Expected vs. observed behavior
- Relevant waveform screenshots or console output

## Development Workflow

1. **Fork** the repository and create a feature branch from `main`:
   ```bash
   git checkout -b feature/my-improvement
   ```

2. **Make changes** to the RTL, testbench, or documentation.

3. **Run the simulation** to confirm nothing regresses:
   ```bash
   cd sim && ./run_sim.sh
   ```
   All four testbench scenarios must pass (no `ERROR` lines in output, simulation reaches `$finish` cleanly).

4. **Lint your Verilog** with Verilator (optional but recommended):
   ```bash
   verilator --lint-only -Wall rtl/*.v
   ```

5. **Commit** with a clear, descriptive message:
   ```
   scheduler: fix weighted credit underflow on simultaneous grant
   
   When all four ports were valid and weighted mode was active, the
   selected port could underflow its credit counter when weight < 16.
   Clamp credits at zero before the debit step.
   ```

6. **Open a pull request** against `main`. Describe what the change does and why.

## Code Style

- Indent with **4 spaces** (no tabs).
- Use `always @(posedge clk or negedge rst_n)` for sequential blocks.
- Use `always @(*)` for combinational blocks.
- Declare all signals before use; avoid implicit nets.
- Keep lines under 100 characters where possible.
- Add a brief comment above every `always` block explaining its purpose.

## Testing

Any non-trivial RTL change should be accompanied by either:
- A new testbench scenario added to `tb/tb_memory_system.v`, or
- A description in the PR of how the change was manually verified.

Changes to the scheduler arbitration logic, starvation prevention, or burst handling are especially sensitive and must include simulation evidence.

## Versioning

This project uses [Semantic Versioning](https://semver.org/):
- **MAJOR**: breaking interface change (port additions, parameter renames)
- **MINOR**: new feature, backward-compatible
- **PATCH**: bug fix, documentation update
