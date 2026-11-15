# Block Specification: Program Counter Register (`pc_reg`)

## 1. Functional Overview
The `pc_reg` block is a 32-bit synchronous state register that stores the current instruction fetch address (`pc`) and updates to `pc_next` (or resets to `0x00000000`) on every rising clock edge.

## 2. Interface Signal Specifications
| Signal Name | Direction | Width | Description |
| :--- | :---: | :---: | :--- |
| `clk` | IN | 1-bit | `std_logic` interface signal |
| `rst` | IN | 1-bit | `std_logic` interface signal |
| `pc_next` | IN | 32-bit | `std_logic_vector(31 downto 0)` interface signal |
| `pc` | OUT | 32-bit | `std_logic_vector(31 downto 0)` interface signal |

## 3. State Transition Table
| Clock Edge | `rst` | `pc_next` | Next `pc` Output | Operation |
| :---: | :---: | :---: | :---: | :--- |
| `posedge clk` | `1` | `XXXXXXXX` | `32'h00000000` | Reset vector initialization |
| `posedge clk` | `0` | `addr_in` | `addr_in` | Latch sequential or branch target address |
| Non-edge | `X` | `XXXXXXXX` | Hold previous `pc` | State retention |

## 4. Timing & Constraints
* **Logic Type:** 32-bit D-flip-flop bank with synchronous active-high reset.
* **Clock-to-Q & Setup:** Must meet `10.0 ns` cycle period timing in Sky130 standard cell synthesis.

## 5. Corner Cases & Verification Notes
* **Synchronous Reset Priority:** Asserting `rst = 1` overrides any value on `pc_next` at the rising clock edge and drives `pc` to `32'h00000000`.
* **Full 32-Bit Width:** The register stores all 32 bits cleanly without masking lower bits (alignment checks are handled by instruction fetch/branch logic).
