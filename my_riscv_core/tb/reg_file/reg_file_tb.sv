`timescale 1ns/1ps
import uvm_lite_pkg::*;

module reg_file_tb;
  logic clk = 0;
  always #5 clk = ~clk;

  reg_file_if vif(clk);

  reg_file dut (
    .clk(clk),
    .rst(vif.rst),
    .we(vif.we),
    .rs1_add(vif.rs1_add),
    .rs2_add(vif.rs2_add),
    .rd_add(vif.rd_add),
    .rd_data(vif.rd_data),
    .rs1_data(vif.rs1_data),
    .rs2_data(vif.rs2_data)
  );

  env #(reg_file_trans, virtual reg_file_if) e;

  initial begin
    $dumpfile("reg_file_dump.vcd");
    $dumpvars(0, reg_file_tb);
    vif.rst = 1'b1;
    vif.we = '0;
    vif.rs1_add = '0;
    vif.rs2_add = '0;
    vif.rd_add = '0;
    vif.rd_data = '0;
    #12;
    vif.rst = 1'b0;
    e = new(vif, 256);
    e.run();
    e.scb.report(reg_file_trans::get_cov());
    $finish;
  end
endmodule
