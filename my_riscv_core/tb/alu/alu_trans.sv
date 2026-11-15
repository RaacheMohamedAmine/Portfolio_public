import uvm_lite_pkg::*;

class alu_cov_collector;
  logic [3:0]  ctrl;
  logic        zero;
  logic [31:0] rs1, rs2, rd;

  covergroup alu_cg;
    option.per_instance = 1;
    cp_ctrl: coverpoint ctrl {
      bins add  = {4'b0000};
      bins sub  = {4'b0001};
      bins band = {4'b0010};
      bins bor  = {4'b0011};
      bins bxor = {4'b0100};
      bins sll  = {4'b0101};
      bins srl  = {4'b0110};
      bins sra  = {4'b0111};
      bins slt  = {4'b1000};
      bins sltu = {4'b1001};
    }
    cp_zero: coverpoint zero {
      bins non_zero = {1'b0};
      bins is_zero  = {1'b1};
    }
    cp_rs1_sign: coverpoint rs1[31] { bins pos = {1'b0}; bins neg = {1'b1}; }
    cp_rs2_sign: coverpoint rs2[31] { bins pos = {1'b0}; bins neg = {1'b1}; }
    cross_op_signs: cross cp_ctrl, cp_rs1_sign, cp_rs2_sign;
  endgroup

  function new(); alu_cg = new(); endfunction
  function void sample(logic [31:0] _rs1, logic [31:0] _rs2, logic [3:0] _ctrl, logic [31:0] _rd, logic _zero);
    this.rs1 = _rs1; this.rs2 = _rs2; this.ctrl = _ctrl; this.rd = _rd; this.zero = _zero;
    alu_cg.sample();
  endfunction
endclass

class alu_trans extends base_trans;
  rand logic [31:0] rs1, rs2;
  rand logic [3:0]  ctrl;
  logic [31:0]      rd, exp_rd;
  logic             zero, exp_zero;

  static int               tx_idx = 0;
  static alu_cov_collector cov_inst;

  function new(); if (cov_inst == null) cov_inst = new(); endfunction
  constraint valid_op { ctrl inside {[4'b0000:4'b1001]}; }

  function void post_randomize();
    int op_idx   = tx_idx % 10;
    int sign_idx = (tx_idx / 10) % 5;
    tx_idx++;
    ctrl = op_idx[3:0];
    case (sign_idx)
      0: begin rs1 = 32'h0000_0005; rs2 = 32'h0000_0005; end
      1: begin rs1 = {1'b0, rs1[30:0]}; rs2 = {1'b0, rs2[30:0]}; end
      2: begin rs1 = {1'b0, rs1[30:0]}; rs2 = {1'b1, rs2[30:0]}; end
      3: begin rs1 = {1'b1, rs1[30:0]}; rs2 = {1'b0, rs2[30:0]}; end
      4: begin rs1 = {1'b1, rs1[30:0]}; rs2 = {1'b1, rs2[30:0]}; end
    endcase
  endfunction

  virtual function base_trans copy();
    alu_trans t = new();
    t.rs1 = rs1; t.rs2 = rs2; t.ctrl = ctrl; t.rd = rd; t.zero = zero;
    return t;
  endfunction

  virtual function void sample_cov(); cov_inst.sample(rs1, rs2, ctrl, rd, zero); endfunction
  static function real get_cov(); return (cov_inst != null) ? cov_inst.alu_cg.get_inst_coverage() : 0.0; endfunction

  virtual function bit check();
    logic [4:0] shamt = rs2[4:0];
    case (ctrl)
      4'b0000: exp_rd = rs1 + rs2;
      4'b0001: exp_rd = rs1 - rs2;
      4'b0010: exp_rd = rs1 & rs2;
      4'b0011: exp_rd = rs1 | rs2;
      4'b0100: exp_rd = rs1 ^ rs2;
      4'b0101: exp_rd = rs1 << shamt;
      4'b0110: exp_rd = rs1 >> shamt;
      4'b0111: exp_rd = $signed(rs1) >>> shamt;
      4'b1000: exp_rd = ($signed(rs1) < $signed(rs2)) ? 32'd1 : 32'd0;
      4'b1001: exp_rd = (rs1 < rs2) ? 32'd1 : 32'd0;
      default: exp_rd = 32'd0;
    endcase
    exp_zero = (exp_rd == 32'd0);
    return ((rd === exp_rd) && (zero === exp_zero));
  endfunction

  virtual function void print_row(bit passed);
    $display(" [%s] | ctrl=%b | rs1=0x%08h | rs2=0x%08h | exp=0x%08h | got=0x%08h | z=%b",
             passed ? "PASS" : "FAIL", ctrl, rs1, rs2, exp_rd, rd, zero);
  endfunction
endclass
