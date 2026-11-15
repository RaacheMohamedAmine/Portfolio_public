TOP_MODULE   = riscv_core
TB_MODULE    = $(TOP_MODULE)_tb
MODULES      = alu reg_file imgen pc_reg ctrl_unit riscv_core

RTL_DIR      = ../rtl
TB_DIR       = ../tb
WORK_DIR     = ../work/$(TOP_MODULE)
OPENLANE_DIR = ../openlane

# Ordered RTL files so leaf modules compile before top-level riscv_core
RTL_FILES    = $(RTL_DIR)/alu.vhd \
               $(RTL_DIR)/reg_file.vhd \
               $(RTL_DIR)/imgen.vhd \
               $(RTL_DIR)/pc_reg.vhd \
               $(RTL_DIR)/ctrl_unit.vhd \
               $(RTL_DIR)/riscv_core.vhd

TRACE_FLAG   = $(if $(WAVE),--trace,)
VFLAGS       = --binary --quiet -j 0 -O1 -CFLAGS "-O0" --coverage $(TRACE_FLAG) \
               -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC -Wno-CASEOVERLAP \
               -Wno-DECLFILENAME -Wno-UNUSEDSIGNAL -Wno-UNDRIVEN \
               -Wno-TIMESCALEMOD -Wno-IMPORTSTAR

NETLIST      = $(WORK_DIR)/$(TOP_MODULE)_netlist.v
MIX_BIN      = $(WORK_DIR)/obj_dir/V$(TB_MODULE)
TB_SRCS      = $(TB_DIR)/uvm_core/uvm_lite_pkg.sv \
               $(TB_DIR)/$(TOP_MODULE)/$(TOP_MODULE)_trans.sv \
               $(TB_DIR)/$(TOP_MODULE)/$(TOP_MODULE)_if.sv \
               $(TB_DIR)/$(TOP_MODULE)/$(TB_MODULE).sv

$(NETLIST): $(RTL_FILES)
	@mkdir -p $(WORK_DIR)
	@cd $(WORK_DIR) && \
	ghdl -a --std=08 $(addprefix ../,$(RTL_FILES)) && \
	yosys -q -m ghdl -p "ghdl --std=08 $(TOP_MODULE); prep -top $(TOP_MODULE); write_verilog -noattr $(TOP_MODULE)_netlist.v"

$(MIX_BIN): $(NETLIST) $(TB_SRCS)
	@cd $(WORK_DIR) && \
	verilator $(VFLAGS) \
	  -I../$(TB_DIR)/$(TOP_MODULE) -I../$(TB_DIR)/uvm_core \
	  $(addprefix ../,$(TB_SRCS)) $(TOP_MODULE)_netlist.v --top-module $(TB_MODULE)

mix-sim: $(MIX_BIN)
	@cd $(WORK_DIR) && ./obj_dir/V$(TB_MODULE)

sim-all:
	@for m in $(MODULES); do \
	  echo ">>> VERIFYING $$m <<<"; \
	  $(MAKE) --no-print-directory TOP_MODULE=$$m mix-sim cov; \
	done

lint-vhdl:
	ghdl -s --std=08 $(RTL_FILES)

schematic-vhdl:
	@mkdir -p $(WORK_DIR)
	@cd $(WORK_DIR) && \
	ghdl -a --std=08 $(addprefix ../,$(RTL_FILES)) && \
	yosys -q -m ghdl -p "ghdl --std=08 $(TOP_MODULE); prep -top $(TOP_MODULE); show -colors 2 -width -format svg -prefix $(TOP_MODULE)_schematic $(TOP_MODULE)" && \
	echo "Schematic saved to: $(WORK_DIR)/$(TOP_MODULE)_schematic.svg"

cov:
	@cd $(WORK_DIR) && verilator_coverage --annotate cov_report coverage.dat

gds:
	cd $(OPENLANE_DIR) && \
	docker run --rm -v $(PWD)/..:/openlane/workspace -v ~/.ciel:/home/amine/.ciel -e PDK_ROOT=/home/amine/.ciel -e PDK=sky130A --user $$(id -u):$$(id -g) ghcr.io/the-openroad-project/openlane:ff5509f65b17bfa4068d5336495ab1718987ff69-amd64 sh -c "./flow.tcl -design /openlane/workspace/openlane -overwrite"

wave:
	gtkwave $(WORK_DIR)/$(TOP_MODULE)_dump.vcd &

clean:
	rm -rf $(WORK_DIR)/*

clean-all:
	rm -rf ../work/*

new-tb:
	@python3 gen_tb.py $(MOD)
	@sed -i 's/^TOP_MODULE[[:space:]]*=.*/TOP_MODULE   = $(MOD)/' Makefile

fib-sim: $(NETLIST)
	@cd $(WORK_DIR) && \
	verilator $(VFLAGS) --trace -Wno-IMPLICITSTATIC \
	  ../../tb/riscv_fib/riscv_fib_tb.sv riscv_core_netlist.v --top-module riscv_fib_tb && \
	./obj_dir/Vriscv_fib_tb

fib-wave:
	gtkwave ../work/riscv_core/riscv_fib_dump.vcd ../tb/riscv_fib/riscv_fib.gtkw 2>/dev/null &

push:
	@cd ~/ic_portfolio && git add -A && git commit -m "$(if $(MSG),$(MSG),Update RV32I core design and documentation)" && git push origin main

docs:
	@python3 gen_docs.py

# --- Layout Viewer (KLayout) ---
layout:
	@LYP=$$(find ~/.ciel/sky130A -name "*.lyp" 2>/dev/null | head -n 1); \
	GDS=$$(ls -t $(OPENLANE_DIR)/runs/*/results/final/gds/$(TOP_MODULE).gds $(OPENLANE_DIR)/final_signoff/$(TOP_MODULE).gds 2>/dev/null | head -n 1); \
	if [ -z "$$GDS" ]; then echo "No GDSII found for $(TOP_MODULE). Run 'make gds' first."; exit 1; fi; \
	if [ -n "$$LYP" ]; then QT_QPA_PLATFORM=wayland klayout -l "$$LYP" "$$GDS" 2>/dev/null & else QT_QPA_PLATFORM=wayland klayout "$$GDS" 2>/dev/null & fi
