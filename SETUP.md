# Comprehensive IC Design & Verification Environment Setup Guide

Production-ready open-source IC design, UVM-Lite verification, and Sky130 RTL-to-GDSII environment built on **WSL2 (Ubuntu)**.

---

## 1. System Infrastructure (WSL2 & Docker)
1. **Install WSL2 & Ubuntu:** `wsl --install -d Ubuntu` in PowerShell (Admin).
2. **Docker Desktop WSL Integration:** Enable your Ubuntu distro under **Settings > Resources > WSL Integration**.
3. **Docker Socket Permissions:**
```bash
sudo usermod -aG docker $USER && newgrp docker
```

## 2. Open-Source EDA Toolchain (OSS CAD Suite)
Provides nightly GHDL, Verilator, Yosys, and GTKWave binaries:
```bash
cd ~ && wget $(curl -s [https://api.github.com/repos/YosysHQ/oss-cad-suite-build/releases/latest](https://api.github.com/repos/YosysHQ/oss-cad-suite-build/releases/latest) | grep 'browser_download_url.*linux-x64.*\.tgz' | cut -d '"' -f 4)
tar -xf oss-cad-suite-linux-x64-*.tgz
echo 'export PATH="$HOME/oss-cad-suite/bin:$PATH"' >> ~/.bashrc && source ~/.bashrc
```

## 3. ASIC Physical Design Flow (OpenLane & Sky130A PDK)
```bash
git clone --depth 1 [https://github.com/The-OpenROAD-Project/OpenLane.git](https://github.com/The-OpenROAD-Project/OpenLane.git) ~/OpenLane
cd ~/OpenLane && make && make pdk
```

## 4. IDE & WSLg GUI Optimizations
* **VS Code + TerosHDL:** Set `"teroshdl.tools.yosys": "/home/amine/oss-cad-suite/bin/yosys"` and backend `yosys_ghdl`.
* **KLayout WSLg Wayland + Crosshair Fix:**
```bash
sudo apt-get install -y klayout qtwayland5 adwaita-icon-theme xcursor-themes
QT_QPA_PLATFORM=wayland klayout -l $(find ~/.ciel/sky130A -name '*.lyp' | head -n 1) <design.gds> &
```

## 5. Terminal Productivity Shortcuts (`~/.bashrc`)
```bash
ic() { cd ~/ic_portfolio/"$1"/scripts || echo 'Project not found!'; }
updocs() { cd ~/ic_portfolio/my_riscv_core/scripts && make docs; }
gpush() { cd ~/ic_portfolio && git add -A && git commit -m "${*:-Update IC portfolio}" && git push origin main; }
```

## 6. Universal Makefile Targets (`scripts/Makefile`)
* `make sim-vhdl` / `make sim-sv` — GHDL & Verilator simulations.
* `make mix-sim` — Mixed-language VHDL-to-Verilog synthesis + SystemVerilog UVM-Lite verification.
* `make schematic-vhdl` — Yosys vector SVG schematic export.
* `make docs` — Automated VHDL entity port parser & Markdown spec generator (`gen_docs.py`).
* `make gds` / `make layout` — OpenLane Sky130 RTL-to-GDSII flow & KLayout viewer.
