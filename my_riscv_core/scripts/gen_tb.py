#!/usr/bin/env python3
import sys, os, re

def parse_vhdl_entity(filepath):
    with open(filepath, 'r') as f:
        text = re.sub(r'--.*', '', f.read())
    ent_match = re.search(r'entity\s+(\w+)\s+is', text, re.IGNORECASE)
    if not ent_match: sys.exit(f"Error: Entity not found in {filepath}")
    entity_name = ent_match.group(1)
    port_match = re.search(r'port\s*\((.*?)\)\s*;\s*end\s+(?:entity\s+)?' + entity_name, text, re.IGNORECASE | re.DOTALL)
    if not port_match: sys.exit(f"Error: Port block not found in {filepath}")
    ports = []
    for item in port_match.group(1).split(';'):
        item = item.strip()
        if not item: continue
        m = re.match(r'([\w\s,]+):\s*(in|out|inout)\s+(.+)', item, re.IGNORECASE | re.DOTALL)
        if not m: continue
        names = [n.strip() for n in m.group(1).split(',') if n.strip()]
        direction = m.group(2).lower()
        vec_m = re.search(r'\(\s*(\d+)\s+downto\s+(\d+)\s*\)', m.group(3), re.IGNORECASE)
        width = f"[{vec_m.group(1)}:{vec_m.group(2)}]" if vec_m else ""
        for name in names:
            ports.append({'name': name, 'dir': direction, 'width': width, 'is_clk': name.lower() in ('clk', 'clock')})
    return entity_name, ports

def generate_files(mod_name, entity_name, ports, tb_base_dir):
    out_dir = os.path.join(tb_base_dir, mod_name)
    os.makedirs(out_dir, exist_ok=True)
    has_clk = any(p['is_clk'] for p in ports)
    io_ports = [p for p in ports if not p['is_clk']]
    in_ports = [p for p in io_ports if p['dir'] == 'in']
    out_ports = [p for p in io_ports if p['dir'] == 'out']

    if_lines = [f"interface {mod_name}_if(input logic clk);"]
    for p in io_ports:
        w = f"{p['width']:<8}" if p['width'] else "        "
        if_lines.append(f"  logic {w} {p['name']};")
    if_lines += ["\n  clocking cb_drv @(posedge clk);", "    default input #1step output #1;"]
    if in_ports: if_lines.append("    output " + ", ".join(p['name'] for p in in_ports) + ";")
    if_lines += ["  endclocking", "\n  clocking cb_mon @(posedge clk);", "    default input #1step output #1;"]
    if io_ports: if_lines.append("    input " + ", ".join(p['name'] for p in io_ports) + ";")
    if_lines += ["  endclocking", f"\n  task automatic drive(uvm_lite_pkg::base_trans base_t);\n    {mod_name}_trans t;\n    $cast(t, base_t);\n    @(cb_drv);"]
    for p in in_ports: if_lines.append(f"    cb_drv.{p['name']} <= t.{p['name']};")
    sync_wait = "@(cb_mon);\n    @(cb_mon);" if has_clk else "@(cb_mon);"
    if_lines += ["  endtask", f"\n  task automatic wait_sync();\n    {sync_wait}\n  endtask", f"\n  task automatic sample(uvm_lite_pkg::base_trans base_t);\n    {mod_name}_trans t;\n    $cast(t, base_t);\n    @(cb_mon);"]
    for p in io_ports: if_lines.append(f"    t.{p['name']} = cb_mon.{p['name']};")
    if_lines.append("  endtask\nendinterface\n")
    with open(os.path.join(out_dir, f"{mod_name}_if.sv"), 'w') as f: f.write("\n".join(if_lines))

    cov_fields = "\n".join(f"  logic {p['width']:<8} {p['name']};" if p['width'] else f"  logic          {p['name']};" for p in io_ports)
    cov_points = "\n".join(f"    cp_{p['name']}: coverpoint {p['name']};" for p in io_ports)
    sample_args = ", ".join(f"logic {p['width']} _{p['name']}" if p['width'] else f"logic _{p['name']}" for p in io_ports)
    sample_assigns = "\n".join(f"    this.{p['name']} = _{p['name']};" for p in io_ports)
    sample_call_args = ", ".join(p['name'] for p in io_ports)
    rand_fields = "\n".join(f"  rand logic {p['width']:<8} {p['name']};" if p['width'] else f"  rand logic          {p['name']};" for p in in_ports)
    dut_out_fields = "\n".join(f"  logic {p['width']:<8} {p['name']};" if p['width'] else f"  logic          {p['name']};" for p in out_ports)
    exp_out_fields = "\n".join(f"  logic {p['width']:<8} exp_{p['name']};" if p['width'] else f"  logic          exp_{p['name']};" for p in out_ports)
    copy_lines = "\n".join(f"    t.{p['name']} = this.{p['name']};" for p in io_ports)
    exp_init_lines = "\n".join(f"    exp_{p['name']} = '0;" for p in out_ports)
    check_expr = " && ".join(f"({p['name']} === exp_{p['name']})" for p in out_ports) or "1'b1"
    fmt_str = " | ".join(f"{p['name']}=0x%0h" for p in io_ports)
    fmt_args = ", ".join(p['name'] for p in io_ports)

    with open(os.path.join(out_dir, f"{mod_name}_trans.sv"), 'w') as f:
        f.write(f"""import uvm_lite_pkg::*;
class {mod_name}_cov_collector;
{cov_fields}
  covergroup {mod_name}_cg;
    option.per_instance = 1;
{cov_points}
  endgroup
  function new(); {mod_name}_cg = new(); endfunction
  function void sample({sample_args});
{sample_assigns}
    {mod_name}_cg.sample();
  endfunction
endclass
class {mod_name}_trans extends base_trans;
{rand_fields}
{dut_out_fields}
{exp_out_fields}
  static int tx_idx = 0;
  static {mod_name}_cov_collector cov_inst;
  function new(); if (cov_inst == null) cov_inst = new(); endfunction
  function void post_randomize(); tx_idx++; endfunction
  virtual function base_trans copy();
    {mod_name}_trans t = new();
{copy_lines}
    return t;
  endfunction
  virtual function void sample_cov(); cov_inst.sample({sample_call_args}); endfunction
  static function real get_cov(); return (cov_inst != null) ? cov_inst.{mod_name}_cg.get_inst_coverage() : 0.0; endfunction
  virtual function bit check();
{exp_init_lines}
    return ({check_expr});
  endfunction
  virtual function void print_row(bit passed);
    $display(" [%s] | {fmt_str}", passed ? "PASS" : "FAIL", {fmt_args});
  endfunction
endclass
""")

    port_map_str = ",\n".join(f"    .{p['name']}(clk)" if p['is_clk'] else f"    .{p['name']}(vif.{p['name']})" for p in ports)
    init_inputs = "\n".join(f"    vif.{p['name']} = '0;" for p in in_ports)
    with open(os.path.join(out_dir, f"{mod_name}_tb.sv"), 'w') as f:
        f.write(f"""`timescale 1ns/1ps
import uvm_lite_pkg::*;
module {mod_name}_tb;
  logic clk = 0;
  always #5 clk = ~clk;
  {mod_name}_if vif(clk);
  {entity_name} dut (
{port_map_str}
  );
  env #({mod_name}_trans, virtual {mod_name}_if) e;
  initial begin
    $dumpfile("{mod_name}_dump.vcd");
    $dumpvars(0, {mod_name}_tb);
{init_inputs}
    e = new(vif, 256);
    e.run();
    e.scb.report({mod_name}_trans::get_cov());
    $finish;
  end
endmodule
""")

if __name__ == "__main__":
    mod = sys.argv[1]
    script_dir = os.path.dirname(os.path.abspath(__file__))
    vhd_path = os.path.join(script_dir, "..", "rtl", f"{mod}.vhd")
    ent, ports = parse_vhdl_entity(vhd_path)
    generate_files(mod, ent, ports, os.path.join(script_dir, "..", "tb"))
