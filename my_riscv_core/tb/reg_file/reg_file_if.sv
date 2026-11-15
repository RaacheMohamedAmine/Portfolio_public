interface reg_file_if(input logic clk);
  logic          rst;
  logic          we;
  logic [4:0]    rs1_add;
  logic [4:0]    rs2_add;
  logic [4:0]    rd_add;
  logic [31:0]   rd_data;
  logic [31:0]   rs1_data;
  logic [31:0]   rs2_data;

  clocking cb_drv @(posedge clk);
    default input #1step output #1;
    output rst, we, rs1_add, rs2_add, rd_add, rd_data;
  endclocking

  clocking cb_mon @(posedge clk);
    default input #1step output #1;
    input rst, we, rs1_add, rs2_add, rd_add, rd_data, rs1_data, rs2_data;
  endclocking

  task automatic drive(uvm_lite_pkg::base_trans base_t);
    reg_file_trans t;
    $cast(t, base_t);
    @(cb_drv);
    cb_drv.rst <= t.rst;
    cb_drv.we <= t.we;
    cb_drv.rs1_add <= t.rs1_add;
    cb_drv.rs2_add <= t.rs2_add;
    cb_drv.rd_add <= t.rd_add;
    cb_drv.rd_data <= t.rd_data;
  endtask

  task automatic wait_sync();
    @(cb_mon);
    @(cb_mon);
  endtask

  task automatic sample(uvm_lite_pkg::base_trans base_t);
    reg_file_trans t;
    $cast(t, base_t);
    @(cb_mon);
    t.rst = cb_mon.rst;
    t.we = cb_mon.we;
    t.rs1_add = cb_mon.rs1_add;
    t.rs2_add = cb_mon.rs2_add;
    t.rd_add = cb_mon.rd_add;
    t.rd_data = cb_mon.rd_data;
    t.rs1_data = cb_mon.rs1_data;
    t.rs2_data = cb_mon.rs2_data;
  endtask
endinterface
