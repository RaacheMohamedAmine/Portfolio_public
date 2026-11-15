# Block Specification: RV32I Control Unit (`ctrl_unit`)

## 1. Functional Overview
The `ctrl_unit` block is a purely combinational instruction decoder that inspects the 7-bit `opcode`, 3-bit `funct3`, and bit 30 (`funct7_5`) of the fetched instruction word to generate all datapath multiplexer selects, register/memory write enables, branch/jump flags, and the 4-bit ALU operation code (`alu_ctrl`).

## 2. Interface Signal Specifications
| Signal Name | Direction | Width | Description |
| :--- | :---: | :---: | :--- |
| `opcode` | IN | 7-bit | `std_logic_vector(6 downto 0)` interface signal |
| `funct3` | IN | 3-bit | `std_logic_vector(2 downto 0)` interface signal |
| `funct7_5` | IN | 1-bit | `std_logic` interface signal |
| `reg_we` | OUT | 1-bit | `std_logic` interface signal |
| `alu_src` | OUT | 1-bit | `std_logic` interface signal |
| `mem_we` | OUT | 1-bit | `std_logic` interface signal |
| `wb_sel` | OUT | 2-bit | `std_logic_vector(1 downto 0)` interface signal |
| `branch` | OUT | 1-bit | `std_logic` interface signal |
| `jal` | OUT | 1-bit | `std_logic` interface signal |
| `jalr` | OUT | 1-bit | `std_logic` interface signal |
| `auipc` | OUT | 1-bit | `std_logic` interface signal |
| `alu_ctrl` | OUT | 4-bit | `std_logic_vector(3 downto 0)` interface signal |

## 3. Main Opcode Decoding Truth Table
| Instruction Class | `opcode` | `reg_we` | `alu_src` | `mem_we` | `wb_sel` | `branch` | `jal` | `jalr` | `auipc` | `alu_ctrl` |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :--- |
| **R-Type** | `0110011` | `1` | `0` | `0` | `00` | `0` | `0` | `0` | `0` | Decoded via `funct3` / `funct7_5` |
| **I-Type ALU** | `0010011` | `1` | `1` | `0` | `00` | `0` | `0` | `0` | `0` | Decoded via `funct3` / `funct7_5` |
| **Load (`LW`)** | `0000011` | `1` | `1` | `0` | `01` | `0` | `0` | `0` | `0` | `0000` (`ADD`) |
| **Store (`SW`)** | `0100011` | `0` | `1` | `1` | `00` | `0` | `0` | `0` | `0` | `0000` (`ADD`) |
| **Branch (B-Type)** | `1100011` | `0` | `0` | `0` | `00` | `1` | `0` | `0` | `0` | `0001` (`SUB`) / `1000` (`SLT`) / `1001` (`SLTU`) |
| **LUI** | `0110111` | `1` | `0` | `0` | `11` | `0` | `0` | `0` | `0` | `0000` |
| **AUIPC** | `0010111` | `1` | `1` | `0` | `00` | `0` | `0` | `0` | `1` | `0000` (`ADD`) |
| **JAL** | `1101111` | `1` | `0` | `0` | `10` | `0` | `1` | `0` | `0` | `0000` |
| **JALR** | `1100111` | `1` | `1` | `0` | `10` | `0` | `0` | `1` | `0` | `0000` (`ADD`) |
| **Default / NOP** | `others` | `0` | `0` | `0` | `00` | `0` | `0` | `0` | `0` | `0000` |

## 4. Timing & Constraints
* **Logic Type:** Purely combinational lookup table (no clock or state storage).
* **Default Safe State:** All control outputs default to `'0'` prior to the `case opcode` evaluation to guarantee latch-free synthesis and safe NOP behavior on unknown opcodes.

## 5. Corner Cases & Verification Notes
* **`ADDI` vs. `SUB` Distinction:** In I-Type instructions (`opcode = 0010011`) with `funct3 = 000` (`ADDI`), bit 30 (`funct7_5`) is part of the 12-bit immediate and must **not** trigger subtraction (`alu_ctrl` remains `0000`), whereas `SRAI` (`funct3 = 101`) still inspects `funct7_5` to select arithmetic right shift (`0111`).
