`timescale 1ns/1ps
import uvm_lite_pkg::*;

module pc_reg_tb;
  logic clk = 0;
  always #5 clk = ~clk;

  pc_reg_if vif(clk);

  pc_reg dut (
    .clk(clk),
    .rst(vif.rst),
    .pc_next(vif.pc_next),
    .pc(vif.pc)
  );

  env #(pc_reg_trans, virtual pc_reg_if) e;

  initial begin
    $dumpfile("pc_reg_dump.vcd");
    $dumpvars(0, pc_reg_tb);
    vif.rst = 1'b1;
    vif.pc_next = 32'd0;
    #12;
    vif.rst = 1'b0;
    e = new(vif, 200);
    e.run();
    e.scb.report(pc_reg_trans::get_cov());
    $finish;
  end
endmodule
