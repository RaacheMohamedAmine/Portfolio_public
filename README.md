# 32-Bit RISC-V Processor Core (

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
