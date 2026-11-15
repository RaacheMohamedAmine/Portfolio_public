import uvm_lite_pkg::*;

class imgen_cov_collector;
  logic [6:0]  opcode;
  logic        sign_bit;
  logic [31:0] imm_out;

  covergroup imgen_cg;
    option.per_instance = 1;
    cp_format: coverpoint opcode {
      bins i_alu   = {7'b0010011};
      bins i_load  = {7'b0000011};
      bins i_jalr  = {7'b1100111};
      bins s_store = {7'b0100011};
      bins b_branch= {7'b1100011};
      bins u_lui   = {7'b0110111};
      bins u_auipc = {7'b0010111};
      bins j_jal   = {7'b1101111};
    }
    cp_sign: coverpoint sign_bit { bins positive = {1'b0}; bins negative = {1'b1}; }
    cp_imm_corners: coverpoint imm_out {
      bins zero     = {32'h0000_0000};
      bins all_ones = {32'hFFFF_FFFF};
      bins pos_vals = {[32'h0000_0001 : 32'h7FFF_FFFF]};
      bins neg_vals = {[32'h8000_0000 : 32'hFFFF_FFFE]};
    }
    cross_fmt_sign: cross cp_format, cp_sign;
  endgroup

  function new(); imgen_cg = new(); endfunction
  function void sample(logic [31:0] _instr, logic [31:0] _imm_out);
    this.opcode = _instr[6:0]; this.sign_bit = _instr[31]; this.imm_out = _imm_out;
    imgen_cg.sample();
  endfunction
endclass

class imgen_trans extends base_trans;
  rand logic [31:0] instr;
  logic [31:0]      imm_out, exp_imm_out;

  static int                 tx_idx = 0;
  static imgen_cov_collector cov_inst;

  function new(); if (cov_inst == null) cov_inst = new(); endfunction
  constraint valid_rv32i_opcode {
    instr[6:0] inside {7'b0010011, 7'b0000011, 7'b1100111, 7'b0100011, 7'b1100011, 7'b0110111, 7'b0010111, 7'b1101111};
  }

  function void post_randomize();
    int mode = tx_idx % 16;
    tx_idx++;
    case (mode)
      0:  instr = {1'b0, 31'h0000_0013};
      1:  instr = {12'hFFF, 13'd0, 7'b0010011};
      2:  instr = {12'h001, 13'd0, 7'b0000011};
      3:  instr = {1'b1, 31'h0000_0003};
      4:  instr = {1'b0, 31'h0000_0067};
      5:  instr = {1'b1, 31'h0000_0067};
      6:  instr = {1'b0, 31'h0000_0023};
      7:  instr = {1'b1, 31'h0000_0023};
      8:  instr = {1'b0, 31'h0000_0063};
      9:  instr = {1'b1, 31'h0000_0063};
      10: instr = {1'b0, 31'h0000_0037};
      11: instr = {1'b1, 31'h0000_0037};
      12: instr = {1'b0, 31'h0000_0017};
      13: instr = {1'b1, 31'h0000_0017};
      14: instr = {1'b0, 31'h0000_006F};
      15: instr = {1'b1, 31'h0000_006F};
    endcase
  endfunction

  virtual function base_trans copy();
    imgen_trans t = new(); t.instr = instr; t.imm_out = imm_out; return t;
  endfunction

  virtual function void sample_cov(); cov_inst.sample(instr, imm_out); endfunction
  static function real get_cov(); return (cov_inst != null) ? cov_inst.imgen_cg.get_inst_coverage() : 0.0; endfunction

  virtual function bit check();
    case (instr[6:0])
      7'b0010011, 7'b0000011, 7'b1100111: exp_imm_out = {{20{instr[31]}}, instr[31:20]};
      7'b0100011:                         exp_imm_out = {{20{instr[31]}}, instr[31:25], instr[11:7]};
      7'b1100011:                         exp_imm_out = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
      7'b0110111, 7'b0010111:             exp_imm_out = {instr[31:12], 12'b0};
      7'b1101111:                         exp_imm_out = {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};
      default:                            exp_imm_out = 32'd0;
    endcase
    return (imm_out === exp_imm_out);
  endfunction

  virtual function void print_row(bit passed);
    $display(" [%s] | instr=0x%08h | exp=0x%08h | got=0x%08h", passed ? "PASS" : "FAIL", instr, exp_imm_out, imm_out);
  endfunction
endclass
