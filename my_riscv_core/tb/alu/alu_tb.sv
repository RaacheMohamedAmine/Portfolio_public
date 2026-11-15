`timescale 1ns/1ps
import uvm_lite_pkg::*;

module alu_tb;
  logic clk = 0;
  always #5 clk = ~clk;

  alu_if vif(clk);

  alu dut (
    .rs1(vif.rs1),
    .rs2(vif.rs2),
    .ctrl(vif.ctrl),
    .rd(vif.rd),
    .zero(vif.zero)
  );

  env #(alu_trans, virtual alu_if) e;

  initial begin
    $dumpfile("alu_dump.vcd");
    $dumpvars(0, alu_tb);
    vif.rs1 = '0;
    vif.rs2 = '0;
    vif.ctrl = '0;
    e = new(vif, 256);
    e.run();
    e.scb.report(alu_trans::get_cov());
    $finish;
  end
endmodule
