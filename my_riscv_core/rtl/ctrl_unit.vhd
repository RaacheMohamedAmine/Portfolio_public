library ieee;
use ieee.std_logic_1164.all;

entity ctrl_unit is
  port (
    opcode    : in  std_logic_vector(6 downto 0);
    funct3    : in  std_logic_vector(2 downto 0);
    funct7_5  : in  std_logic;
    reg_we    : out std_logic;
    alu_src   : out std_logic;
    mem_we    : out std_logic;
    wb_sel    : out std_logic_vector(1 downto 0); -- 00: ALU, 01: Mem, 10: PC+4, 11: Imm (LUI)
    branch    : out std_logic;
    jal       : out std_logic;
    jalr      : out std_logic;
    auipc     : out std_logic;
    alu_ctrl  : out std_logic_vector(3 downto 0)
  );
end entity ctrl_unit;

architecture rtl of ctrl_unit is
begin
  process(opcode, funct3, funct7_5)
  begin
    -- Default safe values (NOP)
    reg_we   <= '0';
    alu_src  <= '0';
    mem_we   <= '0';
    wb_sel   <= "00";
    branch   <= '0';
    jal      <= '0';
    jalr     <= '0';
    auipc    <= '0';
    alu_ctrl <= "0000";

    case opcode is
      -- R-Type (ADD, SUB, AND, OR, XOR, SLL, SRL, SRA, SLT, SLTU)
      when "0110011" =>
        reg_we  <= '1';
        alu_src <= '0';
        wb_sel  <= "00";
        case funct3 is
          when "000" => if funct7_5 = '1' then alu_ctrl <= "0001"; else alu_ctrl <= "0000"; end if;
          when "111" => alu_ctrl <= "0010"; -- AND
          when "110" => alu_ctrl <= "0011"; -- OR
          when "100" => alu_ctrl <= "0100"; -- XOR
          when "001" => alu_ctrl <= "0101"; -- SLL
          when "101" => if funct7_5 = '1' then alu_ctrl <= "0111"; else alu_ctrl <= "0110"; end if;
          when "010" => alu_ctrl <= "1000"; -- SLT
          when "011" => alu_ctrl <= "1001"; -- SLTU
          when others => alu_ctrl <= "0000";
        end case;

      -- I-Type ALU (ADDI, ANDI, ORI, XORI, SLLI, SRLI, SRAI, SLTI, SLTIU)
      when "0010011" =>
        reg_we  <= '1';
        alu_src <= '1';
        wb_sel  <= "00";
        case funct3 is
          when "000" => alu_ctrl <= "0000"; -- ADDI
          when "111" => alu_ctrl <= "0010"; -- ANDI
          when "110" => alu_ctrl <= "0011"; -- ORI
          when "100" => alu_ctrl <= "0100"; -- XORI
          when "001" => alu_ctrl <= "0101"; -- SLLI
          when "101" => if funct7_5 = '1' then alu_ctrl <= "0111"; else alu_ctrl <= "0110"; end if;
          when "010" => alu_ctrl <= "1000"; -- SLTI
          when "011" => alu_ctrl <= "1001"; -- SLTIU
          when others => alu_ctrl <= "0000";
        end case;

      -- Load (LW)
      when "0000011" =>
        reg_we   <= '1';
        alu_src  <= '1';
        wb_sel   <= "01";
        alu_ctrl <= "0000";

      -- Store (SW)
      when "0100011" =>
        mem_we   <= '1';
        alu_src  <= '1';
        alu_ctrl <= "0000";

      -- Branch (BEQ, BNE, BLT, BGE, BLTU, BGEU)
      when "1100011" =>
        branch  <= '1';
        alu_src <= '0';
        case funct3 is
          when "000" | "001" => alu_ctrl <= "0001"; -- SUB for BEQ/BNE
          when "100" | "101" => alu_ctrl <= "1000"; -- SLT for BLT/BGE
          when "110" | "111" => alu_ctrl <= "1001"; -- SLTU for BLTU/BGEU
          when others        => alu_ctrl <= "0001";
        end case;

      -- LUI
      when "0110111" =>
        reg_we <= '1';
        wb_sel <= "11";

      -- AUIPC
      when "0010111" =>
        reg_we   <= '1';
        alu_src  <= '1';
        auipc    <= '1';
        wb_sel   <= "00";
        alu_ctrl <= "0000";

      -- JAL
      when "1101111" =>
        reg_we <= '1';
        jal    <= '1';
        wb_sel <= "10";

      -- JALR
      when "1100111" =>
        reg_we   <= '1';
        alu_src  <= '1';
        jalr     <= '1';
        wb_sel   <= "10";
        alu_ctrl <= "0000";

      when others => null;
    end case;
  end process;
end architecture rtl;
