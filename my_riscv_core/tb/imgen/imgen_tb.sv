`timescale 1ns/1ps
import uvm_lite_pkg::*;

module imgen_tb;
  logic clk = 0;
  always #5 clk = ~clk;

  imgen_if vif(clk);

  imgen dut (
    .instr(vif.instr),
    .imm_out(vif.imm_out)
  );

  env #(imgen_trans, virtual imgen_if) e;

  initial begin
    $dumpfile("imgen_dump.vcd");
    $dumpvars(0, imgen_tb);
    vif.instr = '0;
    e = new(vif, 256);
    e.run();
    e.scb.report(imgen_trans::get_cov());
    $finish;
  end
endmodule
