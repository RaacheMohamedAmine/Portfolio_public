import uvm_lite_pkg::*;

class reg_file_cov_collector;
  logic        rst, we;
  logic [4:0]  rs1_add, rs2_add, rd_add;
  logic [31:0] rd_data;

  covergroup reg_file_cg;
    option.per_instance = 1;
    cp_rst: coverpoint rst { bins inactive = {1'b0}; bins active = {1'b1}; }
    cp_we:  coverpoint we  { bins read_only = {1'b0}; bins write_en = {1'b1}; }
    cp_rd_add:  coverpoint rd_add  { bins x0 = {5'd0}; bins lo = {[5'd1:5'd15]}; bins hi = {[5'd16:5'd31]}; }
    cp_rs1_add: coverpoint rs1_add { bins x0 = {5'd0}; bins lo = {[5'd1:5'd15]}; bins hi = {[5'd16:5'd31]}; }
    cp_rs2_add: coverpoint rs2_add { bins x0 = {5'd0}; bins lo = {[5'd1:5'd15]}; bins hi = {[5'd16:5'd31]}; }
    cp_raw_hazard: coverpoint (!rst && we && (rd_add != 5'd0) && ((rd_add == rs1_add) || (rd_add == rs2_add))) {
      bins no_hazard = {1'b0}; bins hazard = {1'b1};
    }
    cross_we_rd: cross cp_we, cp_rd_add;
  endgroup

  function new(); reg_file_cg = new(); endfunction
  function void sample(logic _rst, logic _we, logic [4:0] _r1, logic [4:0] _r2, logic [4:0] _rd, logic [31:0] _wdata);
    this.rst = _rst; this.we = _we; this.rs1_add = _r1; this.rs2_add = _r2; this.rd_add = _rd; this.rd_data = _wdata;
    reg_file_cg.sample();
  endfunction
endclass

class reg_file_trans extends base_trans;
  rand logic        rst, we;
  rand logic [4:0]  rs1_add, rs2_add, rd_add;
  rand logic [31:0] rd_data;
  logic [31:0]      rs1_data, rs2_data, exp_rs1_data, exp_rs2_data;

  static logic [31:0]           shadow_regs [0:31] = '{default: 32'd0};
  static int                    tx_idx = 0;
  static reg_file_cov_collector cov_inst;

  function new(); if (cov_inst == null) cov_inst = new(); endfunction
  constraint rst_dist { rst dist { 1'b0 := 90, 1'b1 := 10 }; }
  constraint we_dist  { we  dist { 1'b1 := 70, 1'b0 := 30 }; }

  function void post_randomize();
    int mode = tx_idx % 8;
    tx_idx++;
    case (mode)
      0: begin rst = 1'b0; we = 1'b1; rd_add = 5'd0; rd_data = 32'hDEAD_BEEF; rs1_add = 5'd0; end
      1: begin rst = 1'b0; we = 1'b0; rs1_add = 5'd0; rs2_add = 5'd0; end
      2: begin rst = 1'b0; we = 1'b1; rd_add = 5'd5; rs1_add = 5'd5; rs2_add = 5'd5; end
      3: begin rst = 1'b0; we = 1'b1; rd_add = 5'd31; rs1_add = 5'd31; end
      4: begin rst = 1'b1; we = 1'b0; end
      default: ;
    endcase
  endfunction

  virtual function base_trans copy();
    reg_file_trans t = new();
    t.rst = rst; t.we = we; t.rs1_add = rs1_add; t.rs2_add = rs2_add; t.rd_add = rd_add;
    t.rd_data = rd_data; t.rs1_data = rs1_data; t.rs2_data = rs2_data;
    return t;
  endfunction

  virtual function void sample_cov(); cov_inst.sample(rst, we, rs1_add, rs2_add, rd_add, rd_data); endfunction
  static function real get_cov(); return (cov_inst != null) ? cov_inst.reg_file_cg.get_inst_coverage() : 0.0; endfunction

  virtual function bit check();
    if (rst) for (int i = 0; i < 32; i++) shadow_regs[i] = 32'd0;
    exp_rs1_data = (rs1_add == 5'd0) ? 32'd0 : shadow_regs[rs1_add];
    exp_rs2_data = (rs2_add == 5'd0) ? 32'd0 : shadow_regs[rs2_add];
    if (!rst && we && (rd_add != 5'd0)) shadow_regs[rd_add] = rd_data;
    return ((rs1_data === exp_rs1_data) && (rs2_data === exp_rs2_data));
  endfunction

  virtual function void print_row(bit passed);
    $display(" [%s] | rst=%b we=%b | rd=x%02d(0x%08h) | rs1=x%02d(exp:0x%08h got:0x%08h) | rs2=x%02d(exp:0x%08h got:0x%08h)",
             passed ? "PASS" : "FAIL", rst, we, rd_add, rd_data,
             rs1_add, exp_rs1_data, rs1_data, rs2_add, exp_rs2_data, rs2_data);
  endfunction
endclass
