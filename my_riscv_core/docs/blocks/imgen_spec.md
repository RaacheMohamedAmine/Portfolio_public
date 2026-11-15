# Block Specification: RV32I Immediate Generator (`imgen`)

## 1. Functional Overview
The `imgen` block is a combinational bit-scrambling and sign-extension unit that decodes the 7-bit opcode (`instr[6:0]`) of a 32-bit RV32I instruction word and produces the corresponding 32-bit sign-extended immediate operand (`imm_out`).

## 2. Interface Signal Specifications
| Signal Name | Direction | Width | Description |
| :--- | :---: | :---: | :--- |
| `instr` | IN | 32-bit | `std_logic_vector(31 downto 0)` interface signal |
| `imm_out` | OUT | 32-bit | `std_logic_vector(31 downto 0)` interface signal |

## 3. Instruction Format & Bit-Mapping Matrix
| Format | Opcode (`instr[6:0]`) | Instructions | 32-bit Sign-Extended Immediate Construction |
| :--- | :---: | :--- | :--- |
| **I-Type** | `0010011`, `0000011`, `1100111` | `ADDI`, `LW`, `JALR`, etc. | `{{20{instr[31]}}, instr[31:20]}` |
| **S-Type** | `0100011` | `SB`, `SH`, `SW` | `{{20{instr[31]}}, instr[31:25], instr[11:7]}` |
| **B-Type** | `1100011` | `BEQ`, `BNE`, `BLT`, `BGE` | `{{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0}` |
| **U-Type** | `0110111`, `0010111` | `LUI`, `AUIPC` | `{instr[31:12], 12'b0}` |
| **J-Type** | `1101111` | `JAL` | `{{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0}` |
| **Other** | All other opcodes | R-Type / Invalid | `32'h00000000` |

## 4. Timing & Constraints
* **Logic Type:** Purely combinational wire-routing and sign-replication logic (zero gate depth beyond opcode muxing).

## 5. Corner Cases & Verification Notes
* **Sign Bit Preservation:** Bit `instr[31]` always serves as the sign bit across all five immediate formats and is replicated across all upper bits.
* **Implicit LSB Zeroing:** B-Type (13-bit branch offset) and J-Type (21-bit jump offset) force bit `0` to `1'b0` to guarantee 2-byte halfword alignment.
