interface ctrl_unit_if(input logic clk);
  logic [6:0]    opcode;
  logic [2:0]    funct3;
  logic          funct7_5;
  logic          reg_we;
  logic          alu_src;
  logic          mem_we;
  logic [1:0]    wb_sel;
  logic          branch;
  logic          jal;
  logic          jalr;
  logic          auipc;
  logic [3:0]    alu_ctrl;

  clocking cb_drv @(posedge clk);
    default input #1step output #1;
    output opcode, funct3, funct7_5;
  endclocking

  clocking cb_mon @(posedge clk);
    default input #1step output #1;
    input opcode, funct3, funct7_5, reg_we, alu_src, mem_we, wb_sel, branch, jal, jalr, auipc, alu_ctrl;
  endclocking

  task automatic drive(uvm_lite_pkg::base_trans base_t);
    ctrl_unit_trans t;
    $cast(t, base_t);
    @(cb_drv);
    cb_drv.opcode <= t.opcode;
    cb_drv.funct3 <= t.funct3;
    cb_drv.funct7_5 <= t.funct7_5;
  endtask

  task automatic wait_sync();
    @(cb_mon);
  endtask

  task automatic sample(uvm_lite_pkg::base_trans base_t);
    ctrl_unit_trans t;
    $cast(t, base_t);
    @(cb_mon);
    t.opcode = cb_mon.opcode;
    t.funct3 = cb_mon.funct3;
    t.funct7_5 = cb_mon.funct7_5;
    t.reg_we = cb_mon.reg_we;
    t.alu_src = cb_mon.alu_src;
    t.mem_we = cb_mon.mem_we;
    t.wb_sel = cb_mon.wb_sel;
    t.branch = cb_mon.branch;
    t.jal = cb_mon.jal;
    t.jalr = cb_mon.jalr;
    t.auipc = cb_mon.auipc;
    t.alu_ctrl = cb_mon.alu_ctrl;
  endtask
endinterface
