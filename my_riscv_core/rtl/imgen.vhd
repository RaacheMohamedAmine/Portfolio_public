library ieee;
use ieee.std_logic_1164.all;

entity imgen is
  port (
    instr   : in  std_logic_vector(31 downto 0);
    imm_out : out std_logic_vector(31 downto 0)
  );
end entity imgen;

architecture rtl of imgen is
  signal opcode : std_logic_vector(6 downto 0);
begin
  opcode <= instr(6 downto 0);
  process(instr, opcode)
  begin
    case opcode is
      -- I-Type
      when "0010011" | "0000011" | "1100111" =>
        imm_out <= (31 downto 12 => instr(31)) & instr(31 downto 20);
      -- S-Type
      when "0100011" =>
        imm_out <= (31 downto 12 => instr(31)) & instr(31 downto 25) & instr(11 downto 7);
      -- B-Type
      when "1100011" =>
        imm_out <= (31 downto 13 => instr(31)) & instr(31) & instr(7) & instr(30 downto 25) & instr(11 downto 8) & '0';
      -- U-Type
      when "0110111" | "0010111" =>
        imm_out <= instr(31 downto 12) & x"000";
      -- J-Type
      when "1101111" =>
        imm_out <= (31 downto 21 => instr(31)) & instr(31) & instr(19 downto 12) & instr(20) & instr(30 downto 21) & '0';
      when others =>
        imm_out <= (others => '0');
    end case;
  end process;
end architecture rtl;
