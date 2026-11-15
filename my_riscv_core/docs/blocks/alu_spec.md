# Block Specification: Arithmetic Logic Unit (`alu`)

## 1. Functional Overview
The `alu` is a purely combinational execution unit that performs 32-bit signed/unsigned arithmetic, bitwise logic, barrel shifting, and magnitude comparisons selected by a 4-bit control opcode (`ctrl`), while asserting a real-time `zero` flag.

## 2. Interface Signal Specifications
| Signal Name | Direction | Width | Description |
| :--- | :---: | :---: | :--- |
| `rs1` | IN | 32-bit | `std_logic_vector(31 downto 0)` interface signal |
| `rs2` | IN | 32-bit | `std_logic_vector(31 downto 0)` interface signal |
| `ctrl` | IN | 4-bit | `std_logic_vector(3 downto 0)` interface signal |
| `rd` | OUT | 32-bit | `std_logic_vector(31 downto 0)` interface signal |
| `zero` | OUT | 1-bit | `std_logic` interface signal |

## 3. Operation Modes & Decoding Matrix
| `ctrl` Code | Mnemonic | Operation | RTL / Golden Formula |
| :---: | :---: | :--- | :--- |
| `0000` | `ADD` | Addition | `rd = signed(rs1) + signed(rs2)` |
| `0001` | `SUB` | Subtraction | `rd = signed(rs1) - signed(rs2)` |
| `0010` | `AND` | Bitwise AND | `rd = rs1 & rs2` |
| `0011` | `OR` | Bitwise OR | `rd = rs1 \| rs2` |
| `0100` | `XOR` | Bitwise XOR | `rd = rs1 ^ rs2` |
| `0101` | `SLL` | Shift Left Logical | `rd = rs1 << rs2[4:0]` |
| `0110` | `SRL` | Shift Right Logical | `rd = rs1 >> rs2[4:0]` |
| `0111` | `SRA` | Shift Right Arithmetic | `rd = $signed(rs1) >>> rs2[4:0]` |
| `1000` | `SLT` | Set Less Than (Signed) | `rd = ($signed(rs1) < $signed(rs2)) ? 32'd1 : 32'd0` |
| `1001` | `SLTU` | Set Less Than (Unsigned) | `rd = (rs1 < rs2) ? 32'd1 : 32'd0` |
| `1010`–`1111` | `DEFAULT` | Undefined / Reserved | `rd = 32'h00000000` |

## 4. Timing & Constraints
* **Logic Type:** 100% combinational (no clock or reset inputs).
* **Timing Budget:** Single-cycle propagation delay `< 10.0 ns` (including carry-chain adder and barrel shifter).

## 5. Corner Cases & Verification Notes
* **Shift Amount Masking:** Only the lower 5 bits (`rs2[4:0]`) are used for `SLL`, `SRL`, and `SRA` (0 to 31-bit shifts).
* **Signed vs. Unsigned Overflow:** Wrap-around two's-complement arithmetic is used for `ADD`/`SUB`; `SLT` and `SLTU` distinguish signed negative values (`bit[31] == 1`) from large unsigned integers.
