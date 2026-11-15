# Block Specification: Top-Level Single-Cycle RV32I Core (`riscv_core`)

## 1. Functional Overview
The `riscv_core` entity is the top-level 32-bit RISC-V processor core integrating `pc_reg`, `ctrl_unit`, `imgen`, `reg_file`, and `alu` with branch condition resolution, target address adders, datapath multiplexers, and separate 32-bit Instruction and Data memory buses.

## 2. Interface Signal Specifications
| Signal Name | Direction | Width | Description |
| :--- | :---: | :---: | :--- |
| `clk` | IN | 1-bit | `std_logic` interface signal |
| `rst` | IN | 1-bit | `std_logic` interface signal |
| `imem_addr` | OUT | 32-bit | `std_logic_vector(31 downto 0)` interface signal |
| `imem_rdata` | IN | 32-bit | `std_logic_vector(31 downto 0)` interface signal |
| `dmem_addr` | OUT | 32-bit | `std_logic_vector(31 downto 0)` interface signal |
| `dmem_wdata` | OUT | 32-bit | `std_logic_vector(31 downto 0)` interface signal |
| `dmem_we` | OUT | 1-bit | `std_logic` interface signal |
| `dmem_rdata` | IN | 32-bit | `std_logic_vector(31 downto 0)` interface signal |

## 3. Datapath Multiplexing & Branch Resolution Matrix
| Datapath Stage | Control Signal | Multiplexer / Resolution Logic |
| :--- | :---: | :--- |
| **ALU Operand A** | `auipc` | `alu_in1 = (auipc == '1') ? pc_curr : rs1_data` |
| **ALU Operand B** | `alu_src` | `alu_in2 = (alu_src == '1') ? imm_ext : rs2_data` |
| **Branch Taken** | `branch`, `funct3` | `000` (BEQ): `alu_zero` / `001` (BNE): `not alu_zero` / `100/110` (BLT/BLTU): `alu_out[0]` / `101/111` (BGE/BGEU): `not alu_out[0]` |
| **Next PC (`pc_next`)** | `jalr`, `jal`, `branch_taken` | `jalr = '1'` -> `{alu_out[31:1], 1'b0}` / `(jal or branch_taken) = '1'` -> `pc_curr + imm_ext` / else `pc_curr + 4` |
| **Write-Back (`rd_data`)** | `wb_sel[1:0]` | `00`: `alu_out` / `01`: `dmem_rdata` / `10`: `pc_curr + 4` / `11`: `imm_ext` (`LUI`) |

## 4. Timing & Constraints
* **Single-Cycle Execution:** Instruction fetch, decode, register read, ALU execution, and next-PC calculation complete within one clock period, committing architectural state updates to `pc_reg` and `reg_file` on `posedge clk`.

## 5. Corner Cases & Verification Notes
* **`JALR` LSB Masking:** Per the RISC-V specification, the `JALR` target address clears bit 0 (`alu_out(31 downto 1) & '0'`) to ensure 2-byte alignment.
* **Signed vs. Unsigned Branches:** `BLT`/`BGE` leverage the ALU's signed `SLT` (`1000`) output bit `alu_out[0]`, whereas `BLTU`/`BGEU` use unsigned `SLTU` (`1001`).
