# System Specification (Cahier des Charges): RV32I Processor Core (`riscv_core`)

> **Architecture:** 32-Bit RISC-V Base Integer ISA (`RV32I`) | **HDL:** VHDL-2008 | **Verification:** SystemVerilog UVM-Lite (100% Coverage) + RV32I Fibonacci Program | **PDK:** SkyWater 130nm (`sky130A`)

---

## 1. Executive Summary
`my_riscv_core` is a complete 32-bit single-cycle RISC-V processor core written in synthesizable **VHDL-2008**. It implements the unprivileged **RV32I** base integer instruction set across a Harvard memory interface (`imem_*` and `dmem_*`), verified at both the leaf-block and full-processor levels using a custom **SystemVerilog UVM-Lite** verification environment and end-to-end machine-code execution.

---

## 2. Supported RV32I Instruction Set
| Format | Instruction Mnemonics | Opcode (`6:0`) | Functional Description |
| :--- | :--- | :---: | :--- |
| **R-Type** | `ADD`, `SUB`, `AND`, `OR`, `XOR`, `SLL`, `SRL`, `SRA`, `SLT`, `SLTU` | `0110011` | Register-to-register 32-bit arithmetic, bitwise logic, shifts, and comparisons |
| **I-Type (ALU)** | `ADDI`, `ANDI`, `ORI`, `XORI`, `SLLI`, `SRLI`, `SRAI`, `SLTI`, `SLTIU` | `0010011` | Register-immediate 32-bit operations with 12-bit sign-extended immediates |
| **I-Type (Load)** | `LW` | `0000011` | 32-bit word load from Data Memory (`rd = dmem[rs1 + imm_i]`) |
| **S-Type (Store)** | `SW` | `0100011` | 32-bit word store to Data Memory (`dmem[rs1 + imm_s] = rs2`) |
| **B-Type** | `BEQ`, `BNE`, `BLT`, `BGE`, `BLTU`, `BGEU` | `1100011` | Conditional PC-relative branches (`pc_next = pc + imm_b` if condition met) |
| **U-Type** | `LUI`, `AUIPC` | `0110111`, `0010111` | Load 20-bit upper immediate (`rd = imm_u` or `rd = pc + imm_u`) |
| **J-Type / JALR** | `JAL`, `JALR` | `1101111`, `1100111` | Unconditional jumps saving return address (`rd = pc + 4`) |

---

## 3. Microarchitecture Partitioning
| Module | Entity (`rtl/*.vhd`) | Logic Type | Primary Responsibility | Datasheet |
| :--- | :--- | :--- | :--- | :--- |
| **Top-Level Core** | `riscv_core` | Structural / RTL | Integrates datapath, control unit, branch logic, and memory buses | [`blocks/riscv_core_spec.md`](blocks/riscv_core_spec.md) |
| **Control Unit** | `ctrl_unit` | Combinational | Decodes `opcode`, `funct3`, `funct7[5]` into datapath control strobes | [`blocks/ctrl_unit_spec.md`](blocks/ctrl_unit_spec.md) |
| **Program Counter** | `pc_reg` | Sequential (`posedge clk`) | Holds 32-bit instruction address `pc`; synchronous active-high reset | [`blocks/pc_reg_spec.md`](blocks/pc_reg_spec.md) |
| **Immediate Generator** | `imgen` | Combinational | Extracts and sign-extends 32-bit immediates across I, S, B, U, J formats | [`blocks/imgen_spec.md`](blocks/imgen_spec.md) |
| **Register File** | `reg_file` | Sync Write / Async Read | 32 × 32-bit general-purpose register bank (`x0` hardwired to `0`) | [`blocks/reg_file_spec.md`](blocks/reg_file_spec.md) |
| **Arithmetic Logic Unit** | `alu` | Combinational | Executes 10 arithmetic, logical, shift, and comparison operations | [`blocks/alu_spec.md`](blocks/alu_spec.md) |

---

## 4. Target Physical Design Specifications (OpenLane Sky130)
| Parameter | Target Value | Notes |
| :--- | :--- | :--- |
| **Target Technology** | SkyWater 130nm (`sky130_fd_sc_hd`) | Open-source ASIC standard-cell library |
| **Clock Period (`CLOCK_PERIOD`)** | `20.0 ns` (`50 MHz` full core) / `10.0 ns` (`100 MHz` leaf) | Single rising-edge clock domain (`clk`) |
| **Die Area (`DIE_AREA`)** | `650 µm × 650 µm` | Configured in `openlane/config.json` |
| **Target Placement Density** | `45%` (`PL_TARGET_DENSITY = 0.45`) | Ensures routability and clean DRC/timing closure |

---

## Physical Implementation & Sky130 Sign-Off (`openlane/final_signoff/`)
Synthesized, placed, routed, and signed off on the **SkyWater 130nm (`sky130_fd_sc_hd`)** PDK via **OpenLane v1.0.2**:

| Metric | Achieved Result | Status |
| :--- | :--- | :---: |
| **Die Area / Core Area** | `0.4225 mm²` (`650 µm × 650 µm`) / `399,721 µm²` | **21.02% Utilization** |
| **Clock Period / Frequency** | `20.0 ns` (`50.0 MHz`) | **Target Met** |
| **Worst / Total Negative Slack (`WNS` / `TNS`)** | `0.0 ns` / `0.0 ns` | **0 Timing Violations** |
| **Netlist Complexity & Routing** | `8,607` nets \| `481,798 µm` wirelength \| `65,130` vias | **Routed** |
| **Magic DRC / Netgen LVS** | `0` DRC violations \| `8,607 / 8,607` nets matched | **DRC & LVS Clean** |
| **Final Silicon Layout** | [`riscv_core.gds`](my_riscv_core/openlane/final_signoff/riscv_core.gds) | **Streamed Out** |
