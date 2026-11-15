import uvm_lite_pkg::*;

class pc_reg_cov_collector;
  logic        rst;
  logic [31:0] pc_next, pc;

  covergroup pc_reg_cg;
    option.per_instance = 1;
    cp_rst: coverpoint rst { bins inactive = {1'b0}; bins active = {1'b1}; }
    cp_pc_next: coverpoint pc_next {
      bins zero      = {32'h0000_0000};
      bins word_algn = {[32'h0000_0004 : 32'hFFFF_FFFC]} iff (pc_next[1:0] == 2'b00);
      bins unaligned = {[32'h0000_0001 : 32'hFFFF_FFFF]} iff (pc_next[1:0] != 2'b00);
      bins max_val   = {32'hFFFF_FFFF};
    }
    cp_pc_out: coverpoint pc { bins zero = {32'h0000_0000}; bins non_zero = {[32'h0000_0001 : 32'hFFFF_FFFF]}; }
    cross_rst_pc: cross cp_rst, cp_pc_out;
  endgroup

  function new(); pc_reg_cg = new(); endfunction
  function void sample(logic _rst, logic [31:0] _pc_next, logic [31:0] _pc);
    this.rst = _rst; this.pc_next = _pc_next; this.pc = _pc;
    pc_reg_cg.sample();
  endfunction
endclass

class pc_reg_trans extends base_trans;
  rand logic        rst;
  rand logic [31:0] pc_next;
  logic [31:0]      pc, exp_pc;

  static logic [31:0]         state_pc = 32'd0;
  static int                  tx_idx   = 0;
  static pc_reg_cov_collector cov_inst;

  function new(); if (cov_inst == null) cov_inst = new(); endfunction
  constraint rst_dist { rst dist { 1'b0 := 85, 1'b1 := 15 }; }

  function void post_randomize();
    int mode = tx_idx % 8;
    tx_idx++;
    case (mode)
      0: begin rst = 1'b1; pc_next = 32'h0000_0004; end
      1: begin rst = 1'b0; pc_next = 32'h0000_0000; end
      2: begin rst = 1'b0; pc_next = 32'h0000_0004; end
      3: begin rst = 1'b0; pc_next = 32'hFFFF_FFFF; end
      4: begin rst = 1'b0; pc_next = {pc_next[31:2], 2'b00}; end
      default: ;
    endcase
  endfunction

  virtual function base_trans copy();
    pc_reg_trans t = new(); t.rst = rst; t.pc_next = pc_next; t.pc = pc; return t;
  endfunction

  virtual function void sample_cov(); cov_inst.sample(rst, pc_next, pc); endfunction
  static function real get_cov(); return (cov_inst != null) ? cov_inst.pc_reg_cg.get_inst_coverage() : 0.0; endfunction

  virtual function bit check();
    exp_pc = state_pc;
    if (rst) state_pc = 32'd0;
    else     state_pc = pc_next;
    return (pc === exp_pc);
  endfunction

  virtual function void print_row(bit passed);
    $display(" [%s] | rst=%b | pc_next=0x%08h | exp_pc=0x%08h | got_pc=0x%08h",
             passed ? "PASS" : "FAIL", rst, pc_next, exp_pc, pc);
  endfunction
endclass
