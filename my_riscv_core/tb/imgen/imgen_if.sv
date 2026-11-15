interface imgen_if(input logic clk);
  logic [31:0]   instr;
  logic [31:0]   imm_out;

  clocking cb_drv @(posedge clk);
    default input #1step output #1;
    output instr;
  endclocking

  clocking cb_mon @(posedge clk);
    default input #1step output #1;
    input instr, imm_out;
  endclocking

  task automatic drive(uvm_lite_pkg::base_trans base_t);
    imgen_trans t;
    $cast(t, base_t);
    @(cb_drv);
    cb_drv.instr <= t.instr;
  endtask

  task automatic wait_sync();
    @(cb_mon);
  endtask

  task automatic sample(uvm_lite_pkg::base_trans base_t);
    imgen_trans t;
    $cast(t, base_t);
    @(cb_mon);
    t.instr = cb_mon.instr;
    t.imm_out = cb_mon.imm_out;
  endtask
endinterface
