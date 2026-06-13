# RISC-V Pipelined Processor

A 5-stage pipelined **RISC-V (RV32I) processor** designed and implemented in Verilog, featuring hazard detection, data forwarding, and an optimized memory subsystem with a configurable write buffer. The project achieved a **73% reduction in pipeline stalls** through asynchronous write-back optimization.

## Features

* 5-stage RISC-V pipeline (IF, ID, EX, MEM, WB)
* Hazard Detection Unit (HDU)
* Data Forwarding Unit
* Direct-Mapped L1 Cache
* Configurable Write Buffer (0, 2, and 4 entries)
* FSM-Based Cache Controller
* FPGA Hardware Validation
* Automated Benchmarking Framework

## Results

| Configuration  | Stall Cycles | Latency Reduction |
| -------------- | -----------: | ----------------: |
| No Buffer      |       14,065 |                 — |
| 2-Entry Buffer |       10,784 |             23.3% |
| 4-Entry Buffer |        3,788 |         **73.1%** |

## Tech Stack

* Verilog HDL
* Xilinx Vivado
* RISC-V RV32I
* FPGA (Zybo Z7)

## Project Structure

```text
src/       # Verilog source files
docs/      # Project report
results/   # Simulation and hardware outputs
```

## Key Learnings

* Pipeline hazard resolution and forwarding
* Cache controller and memory subsystem design
* FIFO-based write buffer implementation
* FSM design and optimization
* Performance vs hardware-resource trade-offs

## Author

Aditya Singh
