interface riscv_core_if(input logic clk);
  logic          rst;
  logic [31:0]   imem_addr;
  logic [31:0]   imem_rdata;
  logic [31:0]   dmem_addr;
  logic [31:0]   dmem_wdata;
  logic          dmem_we;
  logic [31:0]   dmem_rdata;

  clocking cb_drv @(posedge clk);
    default input #1step output #1;
    output rst, imem_rdata, dmem_rdata;
  endclocking

  clocking cb_mon @(posedge clk);
    default input #1step output #1;
    input rst, imem_addr, imem_rdata, dmem_addr, dmem_wdata, dmem_we, dmem_rdata;
  endclocking

  task automatic drive(uvm_lite_pkg::base_trans base_t);
    riscv_core_trans t;
    $cast(t, base_t);
    @(cb_drv);
    cb_drv.rst <= t.rst;
    cb_drv.imem_rdata <= t.imem_rdata;
    cb_drv.dmem_rdata <= t.dmem_rdata;
  endtask

  task automatic wait_sync();
    @(cb_mon);
  endtask

  task automatic sample(uvm_lite_pkg::base_trans base_t);
    riscv_core_trans t;
    $cast(t, base_t);
    @(cb_mon);
    t.rst = cb_mon.rst;
    t.imem_addr = cb_mon.imem_addr;
    t.imem_rdata = cb_mon.imem_rdata;
    t.dmem_addr = cb_mon.dmem_addr;
    t.dmem_wdata = cb_mon.dmem_wdata;
    t.dmem_we = cb_mon.dmem_we;
    t.dmem_rdata = cb_mon.dmem_rdata;
  endtask
endinterface
