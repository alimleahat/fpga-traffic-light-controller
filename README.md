# FPGA Traffic Light Controller

**A structural Verilog controller with pedestrian requests, timed signal phases, and a two-digit countdown.**

Built as an ELEC2665 digital design coursework project for the **Terasic DE10-Lite / Intel MAX 10**, this design connects gate-level arithmetic, counters, control logic, and display decoding into a complete RTL system.

## At a glance

- **Four phases:** red → amber → green → amber, repeating automatically.
- **Pedestrian request:** an active-low button latches a request and extends red from 10 to 15 clock ticks; an LED indicates the pending request.
- **Live countdown:** two active-low seven-segment outputs display the remaining phase count.
- **Structural datapath:** one-bit full adders form a four-bit ripple-carry adder, reused for incrementing and subtraction.
- **Small footprint:** the archived Quartus fitter report records **67 logic elements and 33 registers**, with no block memory or PLLs.

The design divides a 50 MHz input into a 1 Hz clock. Normal phase lengths are **10 / 3 / 10 / 3 ticks**, and the displayed countdown runs to **1** before advancing. The initial phase after reset begins partway through the divided-clock period.

## Design

```mermaid
flowchart LR
    CLK[50 MHz clock] --> DIV[ClockDivider]
    DIV --> CORE[CoreLogic]
    BTN[Pedestrian button] --> CORE
    CORE <--> COUNT[CounterUnit]
    CORE -->|phase + count| DEC[Decoder]
    CORE --> LED[Request LED]
    DEC --> LIGHTS[Red / amber / green]
    DEC -->|countdown| SEG[SevenSegDisplay]
    SEG --> HEX[Two seven-segment digits]
```

`CoreLogic` carries the two-bit phase and a latched pedestrian request. `CounterUnit` counts upward until it matches the selected terminal value. `Decoder` selects the lamps and subtracts the elapsed count from the phase duration. `BinaryBCD` and `BCD7Seg` convert that result into decimal digits and segment patterns.

**Start reading:** [top-level wiring](rtl/MainCode.v) · [phase and request control](rtl/CoreLogic.v) · [structural counter](rtl/CounterUnit.v) · [automated regression](tb/regression_tb.sv)

## Run the simulations

Install Icarus Verilog (`iverilog` and `vvp`) and Python 3, then run:

```sh
python3 scripts/test.py
```

The runner elaborates the top-level design, runs every original waveform testbench, and executes an additional self-checking regression for arithmetic, decimal display conversion, phase sequencing, and pedestrian extension. GitHub Actions runs the same command on pushes and pull requests.

Original testbenches are preserved in `tb/legacy/`. They provide stimulus for waveform inspection; their completion alone does not establish correctness. In particular, the original divider and top-level tests are too short to observe a full 1 Hz period. The regression drives `CoreLogic` directly to check phase behavior quickly.

## Open in Quartus

1. Open `quartus/ELEC2665S2Project.qpf` in Quartus with MAX 10 device support.
2. Confirm the configured device, `10M50DAF484C6GES`, matches your hardware and installed device support.
3. Set board pin locations and I/O standards for the clock, active-low reset/button, lamps, request LED, and displays.
4. Add appropriate input and generated-clock timing constraints, compile, and review timing before programming.

The project metadata references Quartus 22.1; the archived successful fitter run used Quartus 17.1.1. This repository has not been rebuilt in Quartus during packaging.

## Engineering notes

This repository preserves the original RTL behavior. The [implementation notes](docs/implementation-notes.md) describe button sampling, boundary behavior, and practical improvements. The archived timing report contains negative slack, and the supplied project has no explicit pin assignments or SDC file; **timing closure and board-ready reproducibility remain future work**.

## Repository layout

```text
rtl/                 14 original design modules
tb/legacy/           14 original stimulus testbenches
tb/regression_tb.sv  Self-checking behavioral regression
quartus/             Project settings with portable source paths
scripts/test.py      Local and CI simulation runner
docs/                Implementation notes and archived build evidence
.github/workflows/   Automated simulation
```

## Project context

Developed for ELEC2665 coursework. The original module names and instructional comments are retained. Repository organization, documentation, and automated regression were added for portfolio presentation. No open-source license has been selected; existing notices are preserved.
