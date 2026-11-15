`timescale 1ns/1ps

module riscv_fib_tb;
  logic        clk = 0;
  logic        rst = 1;
  logic [31:0] imem_addr, imem_rdata;
  logic [31:0] dmem_addr, dmem_wdata, dmem_rdata;
  logic        dmem_we;

  always #5 clk = ~clk;

  // Instantiate synthesized VHDL RV32I Core
  riscv_core dut (
    .clk        (clk),
    .rst        (rst),
    .imem_addr  (imem_addr),
    .imem_rdata (imem_rdata),
    .dmem_addr  (dmem_addr),
    .dmem_wdata (dmem_wdata),
    .dmem_we    (dmem_we),
    .dmem_rdata (dmem_rdata)
  );

  // Instruction ROM (64 words) & Data RAM (64 words)
  logic [31:0] imem [0:63];
  logic [31:0] dmem [0:63];

  assign imem_rdata = imem[imem_addr[7:2]];
  assign dmem_rdata = dmem[dmem_addr[7:2]];

  always_ff @(posedge clk) begin
    if (dmem_we) begin
      dmem[dmem_addr[7:2]] <= dmem_wdata;
      $display(" [Cycle %02d] | PC=0x%02h | MEM WRITE -> dmem[%02d] (0x%02h) = %0d (0x%08h)",
               $time/10, imem_addr[7:0], dmem_addr[7:2], dmem_addr[7:0], dmem_wdata, dmem_wdata);
    end
  end

  initial begin
    int expected [0:10] = '{0, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55};
    int pass_cnt = 0;

    $dumpfile("riscv_fib_dump.vcd");
    $dumpvars(0, riscv_fib_tb);

    for (int i = 0; i < 64; i++) begin
      imem[i] = 32'h00000013; // NOP (addi x0, x0, 0)
      dmem[i] = 32'h00000000;
    end

    // -------------------------------------------------------------------------
    // RV32I Machine Code Program: Compute Fibonacci F(0)..F(10) into Data RAM
    // -------------------------------------------------------------------------
    imem[0]  = 32'h00000093; // 0x00: addi x1, x0, 0      # F(0) = 0
    imem[1]  = 32'h00100113; // 0x04: addi x2, x0, 1      # F(1) = 1
    imem[2]  = 32'h00000213; // 0x08: addi x4, x0, 0      # ptr  = 0x00
    imem[3]  = 32'h00900293; // 0x0C: addi x5, x0, 9      # loop_cnt = 9
    imem[4]  = 32'h00122023; // 0x10: sw   x1, 0(x4)      # dmem[0] = 0
    imem[5]  = 32'h00222223; // 0x14: sw   x2, 4(x4)      # dmem[1] = 1
    imem[6]  = 32'h00820213; // 0x18: addi x4, x4, 8      # ptr  = 0x08
    // loop (0x1C):
    imem[7]  = 32'h002081b3; // 0x1C: add  x3, x1, x2     # x3 = x1 + x2
    imem[8]  = 32'h00322023; // 0x20: sw   x3, 0(x4)      # dmem[ptr/4] = x3
    imem[9]  = 32'h00010093; // 0x24: addi x1, x2, 0      # x1 = x2
    imem[10] = 32'h00018113; // 0x28: addi x2, x3, 0      # x2 = x3
    imem[11] = 32'h00420213; // 0x2C: addi x4, x4, 4      # ptr += 4
    imem[12] = 32'hfff28293; // 0x30: addi x5, x5, -1     # loop_cnt -= 1
    imem[13] = 32'hfe0294e3; // 0x34: bne  x5, x0, -24    # branch to 0x1C if x5 != 0
    // done (0x38):
    imem[14] = 32'h00022303; // 0x38: lw   x6, 0(x4)      # verify load: x6 = dmem[10] (55)
    imem[15] = 32'h0000006f; // 0x3C: jal  x0, 0          # halt (infinite loop)

    $display("==========================================================================================");
    $display(" STARTING RV32I FIBONACCI EXECUTION TRACE (F(0) .. F(10))");
    $display("==========================================================================================");

    // Release reset after 2 cycles and run for 80 cycles
    #20 rst = 0;
    #800;

    $display("==========================================================================================");
    $display(" VERIFYING DATA MEMORY CONTENTS (dmem[0] .. dmem[10])");
    $display("==========================================================================================");
    for (int i = 0; i <= 10; i++) begin
      if (dmem[i] === expected[i]) begin
        pass_cnt++;
        $display(" [PASS] | F(%02d) at dmem[%02d] (0x%02h) | Expected: %02d | Got: %02d",
                 i, i, i*4, expected[i], dmem[i]);
      end else begin
        $display(" [FAIL] | F(%02d) at dmem[%02d] (0x%02h) | Expected: %02d | Got: %02d",
                 i, i, i*4, expected[i], dmem[i]);
        $fatal(1, "Fibonacci memory check failed!");
      end
    end
    $display("==========================================================================================");
    $display(" FIBONACCI PROGRAM SUMMARY: %0d/11 Memory Words Verified | F(10) = %0d", pass_cnt, dmem[10]);
    $display(" WAVEFORM SAVED TO        : ../work/riscv_core/riscv_fib_dump.vcd");
    $display("==========================================================================================");
    $finish;
  end
endmodule
