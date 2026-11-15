interface alu_if(input logic clk);
  logic [31:0]   rs1;
  logic [31:0]   rs2;
  logic [3:0]    ctrl;
  logic [31:0]   rd;
  logic          zero;

  clocking cb_drv @(posedge clk);
    default input #1step output #1;
    output rs1, rs2, ctrl;
  endclocking

  clocking cb_mon @(posedge clk);
    default input #1step output #1;
    input rs1, rs2, ctrl, rd, zero;
  endclocking

  task automatic drive(uvm_lite_pkg::base_trans base_t);
    alu_trans t;
    $cast(t, base_t);
    @(cb_drv);
    cb_drv.rs1 <= t.rs1;
    cb_drv.rs2 <= t.rs2;
    cb_drv.ctrl <= t.ctrl;
  endtask

  task automatic wait_sync();
    @(cb_mon);
  endtask

  task automatic sample(uvm_lite_pkg::base_trans base_t);
    alu_trans t;
    $cast(t, base_t);
    @(cb_mon);
    t.rs1 = cb_mon.rs1;
    t.rs2 = cb_mon.rs2;
    t.ctrl = cb_mon.ctrl;
    t.rd = cb_mon.rd;
    t.zero = cb_mon.zero;
  endtask
endinterface
