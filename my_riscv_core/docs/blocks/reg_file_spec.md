# Block Specification: General-Purpose Register File (`reg_file`)

## 1. Functional Overview
The `reg_file` implements the architectural 32 × 32-bit RV32I integer register bank (`x0`–`x31`) featuring two asynchronous combinational read ports (`rs1`, `rs2`) and one synchronous rising-edge write port (`rd`) with hardwired zero behavior on `x0`.

## 2. Interface Signal Specifications
| Signal Name | Direction | Width | Description |
| :--- | :---: | :---: | :--- |
| `clk` | IN | 1-bit | `std_logic` interface signal |
| `rst` | IN | 1-bit | `std_logic` interface signal |
| `we` | IN | 1-bit | `std_logic` interface signal |
| `rs1_add` | IN | 5-bit | `std_logic_vector(4 downto 0)` interface signal |
| `rs2_add` | IN | 5-bit | `std_logic_vector(4 downto 0)` interface signal |
| `rd_add` | IN | 5-bit | `std_logic_vector(4 downto 0)` interface signal |
| `rd_data` | IN | 32-bit | `std_logic_vector(31 downto 0)` interface signal |
| `rs1_data` | OUT | 32-bit | `std_logic_vector(31 downto 0)` interface signal |
| `rs2_data` | OUT | 32-bit | `std_logic_vector(31 downto 0)` interface signal |

## 3. Functional Behavior & Truth Table
| `rst` | `we` | `rd_add` | Synchronous Action (`posedge clk`) | Combinational Read (`rs1_data` / `rs2_data`) |
| :---: | :---: | :---: | :--- | :--- |
| `1` | `X` | `XXXXX` | `regs[0..31] <= 32'h00000000` | `32'h00000000` |
| `0` | `0` | `XXXXX` | Hold state (no write) | `(addr == 0) ? 32'd0 : regs[addr]` |
| `0` | `1` | `00000` | Ignored (`x0` remains `32'h00000000`) | `(addr == 0) ? 32'd0 : regs[addr]` |
| `0` | `1` | `00001`–`11111` | `regs[rd_add] <= rd_data` | `(addr == 0) ? 32'd0 : regs[addr]` |

## 4. Timing & Constraints
* **Read Path:** Asynchronous combinational read (`0`-cycle latency from address change to `rs1_data`/`rs2_data`).
* **Write Path:** Synchronous to `posedge clk` (`1`-cycle latency; new data becomes visible on the read ports after the rising clock edge).

## 5. Corner Cases & Verification Notes
* **Hardwired `x0` Protection:** Writing `0xDEAD_BEEF` to `rd_add = 5'd0` with `we = 1` must never alter `x0`; reading `x0` always returns `32'h00000000`.
* **Read-After-Write (RAW) Hazards:** Reading the same register index being written (`rd_add == rs1_add`) returns the pre-edge value during the active cycle and updates immediately following `posedge clk`.
