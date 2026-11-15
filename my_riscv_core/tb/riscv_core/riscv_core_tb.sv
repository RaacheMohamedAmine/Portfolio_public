`timescale 1ns/1ps
import uvm_lite_pkg::*;
module riscv_core_tb;
  logic clk = 0;
  always #5 clk = ~clk;
  riscv_core_if vif(clk);
  riscv_core dut (
    .clk(clk),
    .rst(vif.rst),
    .imem_addr(vif.imem_addr),
    .imem_rdata(vif.imem_rdata),
    .dmem_addr(vif.dmem_addr),
    .dmem_wdata(vif.dmem_wdata),
    .dmem_we(vif.dmem_we),
    .dmem_rdata(vif.dmem_rdata)
  );
  env #(riscv_core_trans, virtual riscv_core_if) e;
  initial begin
    $dumpfile("riscv_core_dump.vcd");
    $dumpvars(0, riscv_core_tb);
    vif.rst = 1'b1;
    vif.imem_rdata = '0;
    vif.dmem_rdata = '0;
    e = new(vif, 256);
    e.run();
    e.scb.report(riscv_core_trans::get_cov());
    $finish;
  end
endmodule
