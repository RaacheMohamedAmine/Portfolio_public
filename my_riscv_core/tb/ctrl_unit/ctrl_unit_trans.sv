import uvm_lite_pkg::*;

class ctrl_unit_cov_collector;
  logic [6:0] opcode;
  logic [2:0] funct3;
  logic       funct7_5;
  logic [3:0] alu_ctrl;

  covergroup ctrl_unit_cg;
    option.per_instance = 1;
    cp_opcode: coverpoint opcode {
      bins r_type = {7'b0110011};
      bins i_alu  = {7'b0010011};
      bins load   = {7'b0000011};
      bins store  = {7'b0100011};
      bins branch = {7'b1100011};
      bins lui    = {7'b0110111};
      bins auipc  = {7'b0010111};
      bins jal    = {7'b1101111};
      bins jalr   = {7'b1100111};
    }
    cp_funct3: coverpoint funct3;
    cp_f7:     coverpoint funct7_5;
    cp_aluctrl: coverpoint alu_ctrl {
      bins valid_ops[] = {[4'b0000:4'b1001]};
    }
  endgroup

  function new(); ctrl_unit_cg = new(); endfunction
  function void sample(logic [6:0] _op, logic [2:0] _f3, logic _f7, logic [3:0] _actrl);
    this.opcode = _op; this.funct3 = _f3; this.funct7_5 = _f7; this.alu_ctrl = _actrl;
    ctrl_unit_cg.sample();
  endfunction
endclass

class ctrl_unit_trans extends base_trans;
  rand logic [6:0] opcode;
  rand logic [2:0] funct3;
  rand logic       funct7_5;

  logic       reg_we, alu_src, mem_we, branch, jal, jalr, auipc;
  logic [1:0] wb_sel;
  logic [3:0] alu_ctrl;

  logic       exp_reg_we, exp_alu_src, exp_mem_we, exp_branch, exp_jal, exp_jalr, exp_auipc;
  logic [1:0] exp_wb_sel;
  logic [3:0] exp_alu_ctrl;

  static int                     tx_idx = 0;
  static ctrl_unit_cov_collector cov_inst;

  function new(); if (cov_inst == null) cov_inst = new(); endfunction

  function void post_randomize();
    logic [6:0] ops [0:8] = '{7'b0110011, 7'b0010011, 7'b0000011, 7'b0100011, 7'b1100011, 7'b0110111, 7'b0010111, 7'b1101111, 7'b1100111};
    opcode   = ops[tx_idx % 9];
    funct3   = (tx_idx / 9) % 8;
    funct7_5 = (tx_idx / 72) % 2;
    tx_idx++;
  endfunction

  virtual function base_trans copy();
    ctrl_unit_trans t = new();
    t.opcode = opcode; t.funct3 = funct3; t.funct7_5 = funct7_5;
    t.reg_we = reg_we; t.alu_src = alu_src; t.mem_we = mem_we; t.wb_sel = wb_sel;
    t.branch = branch; t.jal = jal; t.jalr = jalr; t.auipc = auipc; t.alu_ctrl = alu_ctrl;
    return t;
  endfunction

  virtual function void sample_cov(); cov_inst.sample(opcode, funct3, funct7_5, alu_ctrl); endfunction
  static function real get_cov(); return (cov_inst != null) ? cov_inst.ctrl_unit_cg.get_inst_coverage() : 0.0; endfunction

  virtual function bit check();
    exp_reg_we = 0; exp_alu_src = 0; exp_mem_we = 0; exp_wb_sel = 2'b00;
    exp_branch = 0; exp_jal = 0; exp_jalr = 0; exp_auipc = 0; exp_alu_ctrl = 4'b0000;

    case (opcode)
      7'b0110011: begin
        exp_reg_we = 1;
        case (funct3)
          3'b000: exp_alu_ctrl = funct7_5 ? 4'b0001 : 4'b0000;
          3'b111: exp_alu_ctrl = 4'b0010;
          3'b110: exp_alu_ctrl = 4'b0011;
          3'b100: exp_alu_ctrl = 4'b0100;
          3'b001: exp_alu_ctrl = 4'b0101;
          3'b101: exp_alu_ctrl = funct7_5 ? 4'b0111 : 4'b0110;
          3'b010: exp_alu_ctrl = 4'b1000;
          3'b011: exp_alu_ctrl = 4'b1001;
        endcase
      end
      7'b0010011: begin
        exp_reg_we = 1; exp_alu_src = 1;
        case (funct3)
          3'b000: exp_alu_ctrl = 4'b0000;
          3'b111: exp_alu_ctrl = 4'b0010;
          3'b110: exp_alu_ctrl = 4'b0011;
          3'b100: exp_alu_ctrl = 4'b0100;
          3'b001: exp_alu_ctrl = 4'b0101;
          3'b101: exp_alu_ctrl = funct7_5 ? 4'b0111 : 4'b0110;
          3'b010: exp_alu_ctrl = 4'b1000;
          3'b011: exp_alu_ctrl = 4'b1001;
        endcase
      end
      7'b0000011: begin exp_reg_we = 1; exp_alu_src = 1; exp_wb_sel = 2'b01; end
      7'b0100011: begin exp_mem_we = 1; exp_alu_src = 1; end
      7'b1100011: begin
        exp_branch = 1;
        case (funct3)
          3'b000, 3'b001: exp_alu_ctrl = 4'b0001;
          3'b100, 3'b101: exp_alu_ctrl = 4'b1000;
          3'b110, 3'b111: exp_alu_ctrl = 4'b1001;
          default:        exp_alu_ctrl = 4'b0001;
        endcase
      end
      7'b0110111: begin exp_reg_we = 1; exp_wb_sel = 2'b11; end
      7'b0010111: begin exp_reg_we = 1; exp_alu_src = 1; exp_auipc = 1; end
      7'b1101111: begin exp_reg_we = 1; exp_jal = 1; exp_wb_sel = 2'b10; end
      7'b1100111: begin exp_reg_we = 1; exp_alu_src = 1; exp_jalr = 1; exp_wb_sel = 2'b10; end
      default: ;
    endcase

    return (reg_we === exp_reg_we) && (alu_src === exp_alu_src) && (mem_we === exp_mem_we) &&
           (wb_sel === exp_wb_sel) && (branch === exp_branch) && (jal === exp_jal) &&
           (jalr === exp_jalr) && (auipc === exp_auipc) && (alu_ctrl === exp_alu_ctrl);
  endfunction

  virtual function void print_row(bit passed);
    $display(" [%s] | op=%b f3=%b f7=%b | we=%b src=%b mwe=%b wb=%b br=%b jal=%b jalr=%b actrl=%b",
             passed ? "PASS" : "FAIL", opcode, funct3, funct7_5, reg_we, alu_src, mem_we, wb_sel, branch, jal, jalr, alu_ctrl);
  endfunction
endclass
