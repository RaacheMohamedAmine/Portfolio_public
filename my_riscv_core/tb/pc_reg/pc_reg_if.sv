interface pc_reg_if(input logic clk);
  logic          rst;
  logic [31:0]   pc_next;
  logic [31:0]   pc;

  clocking cb_drv @(posedge clk);
    default input #1step output #1;
    output rst, pc_next;
  endclocking

  clocking cb_mon @(posedge clk);
    default input #1step output #1;
    input rst, pc_next, pc;
  endclocking

  task automatic drive(uvm_lite_pkg::base_trans base_t);
    pc_reg_trans t;
    $cast(t, base_t);
    @(cb_drv);
    cb_drv.rst <= t.rst;
    cb_drv.pc_next <= t.pc_next;
  endtask

  task automatic wait_sync();
    @(cb_mon);
    @(cb_mon);
  endtask

  task automatic sample(uvm_lite_pkg::base_trans base_t);
    pc_reg_trans t;
    $cast(t, base_t);
    @(cb_mon);
    t.rst = cb_mon.rst;
    t.pc_next = cb_mon.pc_next;
    t.pc = cb_mon.pc;
  endtask
endinterface
