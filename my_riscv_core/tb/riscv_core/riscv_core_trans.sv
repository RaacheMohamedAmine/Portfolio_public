import uvm_lite_pkg::*;

class riscv_core_cov_collector;
  logic        rst, dmem_we;
  logic [6:0]  opcode;

  covergroup riscv_core_cg;
    option.per_instance = 1;
    cp_rst: coverpoint rst { bins inactive = {1'b0}; bins active = {1'b1}; }
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
    cp_dmem_we: coverpoint dmem_we { bins read = {1'b0}; bins write = {1'b1}; }
  endgroup

  function new(); riscv_core_cg = new(); endfunction
  function void sample(logic _rst, logic [6:0] _op, logic _mwe);
    this.rst = _rst; this.opcode = _op; this.dmem_we = _mwe;
    riscv_core_cg.sample();
  endfunction
endclass

class riscv_core_trans extends base_trans;
  rand logic        rst;
  rand logic [31:0] imem_rdata;
  rand logic [31:0] dmem_rdata;

  logic [31:0]      imem_addr, dmem_addr, dmem_wdata;
  logic             dmem_we;

  logic [31:0]      exp_imem_addr, exp_dmem_addr, exp_dmem_wdata;
  logic             exp_dmem_we;

  static logic [31:0]            arch_pc = 32'd0;
  static logic [31:0]            arch_regs [0:31] = '{default: 32'd0};
  static int                     tx_idx = 0;
  static riscv_core_cov_collector cov_inst;

  function new(); if (cov_inst == null) cov_inst = new(); endfunction

  function void post_randomize();
    logic [6:0]  ops [0:8] = '{7'b0010011, 7'b0110011, 7'b0000011, 7'b0100011, 7'b1100011, 7'b0110111, 7'b0010111, 7'b1101111, 7'b1100111};
    logic [6:0]  op  = ops[tx_idx % 9];
    logic [2:0]  f3  = (tx_idx / 9) % 8;
    logic [4:0]  rd  = (tx_idx % 31) + 1;
    logic [4:0]  rs1 = ((tx_idx + 3) % 32);
    logic [4:0]  rs2 = ((tx_idx + 7) % 32);
    logic [11:0] imm12 = tx_idx * 4;

    if (tx_idx < 4 || tx_idx == 50) rst = 1'b1;
    else                            rst = 1'b0;

    if (op == 7'b0110011 || op == 7'b0010011) begin
      imem_rdata = {1'b0, (tx_idx[0] ? 1'b1 : 1'b0), imm12[4:0], rs2, rs1, f3, rd, op};
    end else if (op == 7'b1100011) begin
      logic [2:0] bf3 [0:5] = '{3'b000, 3'b001, 3'b100, 3'b101, 3'b110, 3'b111};
      imem_rdata = {imm12[11:5], rs2, rs1, bf3[tx_idx % 6], imm12[4:1], 1'b0, op};
    end else begin
      imem_rdata = {imm12, rs1, 3'b000, rd, op};
    end
    tx_idx++;
  endfunction

  virtual function base_trans copy();
    riscv_core_trans t = new();
    t.rst = rst; t.imem_rdata = imem_rdata; t.dmem_rdata = dmem_rdata;
    t.imem_addr = imem_addr; t.dmem_addr = dmem_addr; t.dmem_wdata = dmem_wdata; t.dmem_we = dmem_we;
    return t;
  endfunction

  virtual function void sample_cov(); cov_inst.sample(rst, imem_rdata[6:0], dmem_we); endfunction
  static function real get_cov(); return (cov_inst != null) ? cov_inst.riscv_core_cg.get_inst_coverage() : 0.0; endfunction

  virtual function bit check();
    logic [6:0]  op  = imem_rdata[6:0];
    logic [2:0]  f3  = imem_rdata[14:12];
    logic        f7  = imem_rdata[30];
    logic [4:0]  rs1 = imem_rdata[19:15];
    logic [4:0]  rs2 = imem_rdata[24:20];
    logic [4:0]  rd  = imem_rdata[11:7];
    logic [31:0] r1_val, r2_val, imm_val, alu_in1, alu_in2, alu_res, wb_data, next_pc;
    logic        reg_we, alu_src, br, jal, jalr, auipc, zero, br_taken;
    logic [1:0]  wb_sel;
    logic [3:0]  actrl;

    // reg_file has an asynchronous reset: if rst is high right now, registers read as 0 immediately
    if (rst) begin
      for (int i = 0; i < 32; i++) arch_regs[i] = 32'd0;
    end

    r1_val = (rs1 == 5'd0) ? 32'd0 : arch_regs[rs1];
    r2_val = (rs2 == 5'd0) ? 32'd0 : arch_regs[rs2];

    case (op)
      7'b0010011, 7'b0000011, 7'b1100111: imm_val = {{20{imem_rdata[31]}}, imem_rdata[31:20]};
      7'b0100011:                         imm_val = {{20{imem_rdata[31]}}, imem_rdata[31:25], imem_rdata[11:7]};
      7'b1100011:                         imm_val = {{19{imem_rdata[31]}}, imem_rdata[31], imem_rdata[7], imem_rdata[30:25], imem_rdata[11:8], 1'b0};
      7'b0110111, 7'b0010111:             imm_val = {imem_rdata[31:12], 12'b0};
      7'b1101111:                         imm_val = {{11{imem_rdata[31]}}, imem_rdata[31], imem_rdata[19:12], imem_rdata[20], imem_rdata[30:21], 1'b0};
      default:                            imm_val = 32'd0;
    endcase

    reg_we = 0; alu_src = 0; exp_dmem_we = 0; wb_sel = 0; br = 0; jal = 0; jalr = 0; auipc = 0; actrl = 0;
    case (op)
      7'b0110011: begin
        reg_we = 1;
        case (f3)
          3'b000: actrl = f7 ? 4'b0001 : 4'b0000;
          3'b111: actrl = 4'b0010;
          3'b110: actrl = 4'b0011;
          3'b100: actrl = 4'b0100;
          3'b001: actrl = 4'b0101;
          3'b101: actrl = f7 ? 4'b0111 : 4'b0110;
          3'b010: actrl = 4'b1000;
          3'b011: actrl = 4'b1001;
        endcase
      end
      7'b0010011: begin
        reg_we = 1; alu_src = 1;
        case (f3)
          3'b000: actrl = 4'b0000;
          3'b111: actrl = 4'b0010;
          3'b110: actrl = 4'b0011;
          3'b100: actrl = 4'b0100;
          3'b001: actrl = 4'b0101;
          3'b101: actrl = f7 ? 4'b0111 : 4'b0110;
          3'b010: actrl = 4'b1000;
          3'b011: actrl = 4'b1001;
        endcase
      end
      7'b0000011: begin reg_we = 1; alu_src = 1; wb_sel = 2'b01; end
      7'b0100011: begin exp_dmem_we = 1; alu_src = 1; end
      7'b1100011: begin
        br = 1;
        case (f3)
          3'b000, 3'b001: actrl = 4'b0001;
          3'b100, 3'b101: actrl = 4'b1000;
          3'b110, 3'b111: actrl = 4'b1001;
          default:        actrl = 4'b0001;
        endcase
      end
      7'b0110111: begin reg_we = 1; wb_sel = 2'b11; end
      7'b0010111: begin reg_we = 1; alu_src = 1; auipc = 1; end
      7'b1101111: begin reg_we = 1; jal = 1; wb_sel = 2'b10; end
      7'b1100111: begin reg_we = 1; alu_src = 1; jalr = 1; wb_sel = 2'b10; end
      default: ;
    endcase

    alu_in1 = auipc ? arch_pc : r1_val;
    alu_in2 = alu_src ? imm_val : r2_val;

    case (actrl)
      4'b0000: alu_res = alu_in1 + alu_in2;
      4'b0001: alu_res = alu_in1 - alu_in2;
      4'b0010: alu_res = alu_in1 & alu_in2;
      4'b0011: alu_res = alu_in1 | alu_in2;
      4'b0100: alu_res = alu_in1 ^ alu_in2;
      4'b0101: alu_res = alu_in1 << alu_in2[4:0];
      4'b0110: alu_res = alu_in1 >> alu_in2[4:0];
      4'b0111: alu_res = $signed(alu_in1) >>> alu_in2[4:0];
      4'b1000: alu_res = ($signed(alu_in1) < $signed(alu_in2)) ? 32'd1 : 32'd0;
      4'b1001: alu_res = (alu_in1 < alu_in2) ? 32'd1 : 32'd0;
      default: alu_res = 32'd0;
    endcase
    zero = (alu_res == 32'd0);

    br_taken = 0;
    if (br) begin
      case (f3)
        3'b000: br_taken = zero;
        3'b001: br_taken = !zero;
        3'b100, 3'b110: br_taken = alu_res[0];
        3'b101, 3'b111: br_taken = !alu_res[0];
        default: br_taken = 0;
      endcase
    end

    exp_imem_addr  = arch_pc;
    exp_dmem_addr  = alu_res;
    exp_dmem_wdata = r2_val;

    next_pc = jalr ? {alu_res[31:1], 1'b0} : ((jal || br_taken) ? (arch_pc + imm_val) : (arch_pc + 32'd4));
    case (wb_sel)
      2'b00: wb_data = alu_res;
      2'b01: wb_data = dmem_rdata;
      2'b10: wb_data = arch_pc + 32'd4;
      2'b11: wb_data = imm_val;
    endcase

    // Synchronous state update for next rising clock edge
    if (rst) begin
      arch_pc = 32'd0;
    end else begin
      if (reg_we && (rd != 5'd0)) arch_regs[rd] = wb_data;
      arch_pc = next_pc;
    end

    return (imem_addr === exp_imem_addr) && (dmem_addr === exp_dmem_addr) &&
           (dmem_wdata === exp_dmem_wdata) && (dmem_we === exp_dmem_we);
  endfunction

  virtual function void print_row(bit passed);
    $display(" [%s] | rst=%b | pc=0x%08h (exp:0x%08h) | instr=0x%08h | daddr=0x%08h | mwe=%b",
             passed ? "PASS" : "FAIL", rst, imem_addr, exp_imem_addr, imem_rdata, dmem_addr, dmem_we);
  endfunction
endclass
