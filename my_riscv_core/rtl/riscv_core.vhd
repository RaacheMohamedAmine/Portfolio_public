library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity riscv_core is
  port (
    clk        : in  std_logic;
    rst        : in  std_logic;
    imem_addr  : out std_logic_vector(31 downto 0);
    imem_rdata : in  std_logic_vector(31 downto 0);
    dmem_addr  : out std_logic_vector(31 downto 0);
    dmem_wdata : out std_logic_vector(31 downto 0);
    dmem_we    : out std_logic;
    dmem_rdata : in  std_logic_vector(31 downto 0)
  );
end entity riscv_core;

architecture rtl of riscv_core is
  signal pc_curr, pc_next, pc_plus4, pc_target : std_logic_vector(31 downto 0);
  signal imm_ext                               : std_logic_vector(31 downto 0);
  signal rs1_data, rs2_data, rd_data           : std_logic_vector(31 downto 0);
  signal alu_in1, alu_in2, alu_out             : std_logic_vector(31 downto 0);
  signal alu_zero                              : std_logic;

  signal reg_we, alu_src, mem_we               : std_logic;
  signal branch, jal, jalr, auipc              : std_logic;
  signal wb_sel                                : std_logic_vector(1 downto 0);
  signal alu_ctrl                              : std_logic_vector(3 downto 0);
  signal branch_taken                          : std_logic;
  signal funct3                                : std_logic_vector(2 downto 0);
begin
  funct3 <= imem_rdata(14 downto 12);

  -- 1. Program Counter Register
  u_pc_reg : entity work.pc_reg
    port map (
      clk     => clk,
      rst     => rst,
      pc_next => pc_next,
      pc      => pc_curr
    );

  imem_addr <= pc_curr;
  pc_plus4  <= std_logic_vector(unsigned(pc_curr) + 4);
  pc_target <= std_logic_vector(unsigned(pc_curr) + unsigned(imm_ext));

  -- 2. Control Unit
  u_ctrl_unit : entity work.ctrl_unit
    port map (
      opcode   => imem_rdata(6 downto 0),
      funct3   => funct3,
      funct7_5 => imem_rdata(30),
      reg_we   => reg_we,
      alu_src  => alu_src,
      mem_we   => mem_we,
      wb_sel   => wb_sel,
      branch   => branch,
      jal      => jal,
      jalr     => jalr,
      auipc    => auipc,
      alu_ctrl => alu_ctrl
    );

  -- 3. Immediate Generator
  u_imgen : entity work.imgen
    port map (
      instr   => imem_rdata,
      imm_out => imm_ext
    );

  -- 4. Register File
  u_reg_file : entity work.reg_file
    port map (
      clk      => clk,
      rst      => rst,
      we       => reg_we,
      rs1_add  => imem_rdata(19 downto 15),
      rs2_add  => imem_rdata(24 downto 20),
      rd_add   => imem_rdata(11 downto 7),
      rd_data  => rd_data,
      rs1_data => rs1_data,
      rs2_data => rs2_data
    );

  -- 5. ALU & Input Multiplexers
  alu_in1 <= pc_curr when auipc = '1' else rs1_data;
  alu_in2 <= imm_ext when alu_src = '1' else rs2_data;

  u_alu : entity work.alu
    port map (
      rs1  => alu_in1,
      rs2  => alu_in2,
      ctrl => alu_ctrl,
      rd   => alu_out,
      zero => alu_zero
    );

  -- 6. Branch Condition Resolution
  process(branch, funct3, alu_zero, alu_out)
  begin
    branch_taken <= '0';
    if branch = '1' then
      case funct3 is
        when "000" => branch_taken <= alu_zero;         -- BEQ
        when "001" => branch_taken <= not alu_zero;     -- BNE
        when "100" => branch_taken <= alu_out(0);       -- BLT
        when "101" => branch_taken <= not alu_out(0);   -- BGE
        when "110" => branch_taken <= alu_out(0);       -- BLTU
        when "111" => branch_taken <= not alu_out(0);   -- BGEU
        when others => branch_taken <= '0';
      end case;
    end if;
  end process;

  -- 7. Next PC Logic
  pc_next <= (alu_out(31 downto 1) & '0') when jalr = '1' else
             pc_target                    when (jal = '1' or branch_taken = '1') else
             pc_plus4;

  -- 8. Write-Back Multiplexer
  with wb_sel select
    rd_data <= alu_out    when "00",
               dmem_rdata when "01",
               pc_plus4   when "10",
               imm_ext    when "11",
               alu_out    when others;

  -- 9. Data Memory Outputs
  dmem_addr  <= alu_out;
  dmem_wdata <= rs2_data;
  dmem_we    <= mem_we;
end architecture rtl;
