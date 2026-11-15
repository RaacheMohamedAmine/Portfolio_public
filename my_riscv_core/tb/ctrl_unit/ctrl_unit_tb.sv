`timescale 1ns/1ps
import uvm_lite_pkg::*;
module ctrl_unit_tb;
  logic clk = 0;
  always #5 clk = ~clk;
  ctrl_unit_if vif(clk);
  ctrl_unit dut (
    .opcode(vif.opcode),
    .funct3(vif.funct3),
    .funct7_5(vif.funct7_5),
    .reg_we(vif.reg_we),
    .alu_src(vif.alu_src),
    .mem_we(vif.mem_we),
    .wb_sel(vif.wb_sel),
    .branch(vif.branch),
    .jal(vif.jal),
    .jalr(vif.jalr),
    .auipc(vif.auipc),
    .alu_ctrl(vif.alu_ctrl)
  );
  env #(ctrl_unit_trans, virtual ctrl_unit_if) e;
  initial begin
    $dumpfile("ctrl_unit_dump.vcd");
    $dumpvars(0, ctrl_unit_tb);
    vif.opcode = '0;
    vif.funct3 = '0;
    vif.funct7_5 = '0;
    e = new(vif, 256);
    e.run();
    e.scb.report(ctrl_unit_trans::get_cov());
    $finish;
  end
endmodule
