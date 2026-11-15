library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alu is
  port (
    rs1  : in  std_logic_vector(31 downto 0);
    rs2  : in  std_logic_vector(31 downto 0);
    ctrl : in  std_logic_vector(3 downto 0);
    rd   : out std_logic_vector(31 downto 0);
    zero : out std_logic
  );
end entity alu;

architecture rtl of alu is
  signal res_s : std_logic_vector(31 downto 0);
begin
  process(rs1, rs2, ctrl)
    variable shamt : integer range 0 to 31;
  begin
    shamt := to_integer(unsigned(rs2(4 downto 0)));
    case ctrl is
      when "0000" => res_s <= std_logic_vector(signed(rs1) + signed(rs2));
      when "0001" => res_s <= std_logic_vector(signed(rs1) - signed(rs2));
      when "0010" => res_s <= rs1 and rs2;
      when "0011" => res_s <= rs1 or rs2;
      when "0100" => res_s <= rs1 xor rs2;
      when "0101" => res_s <= std_logic_vector(shift_left(unsigned(rs1), shamt));
      when "0110" => res_s <= std_logic_vector(shift_right(unsigned(rs1), shamt));
      when "0111" => res_s <= std_logic_vector(shift_right(signed(rs1), shamt));
      when "1000" =>
        if signed(rs1) < signed(rs2) then res_s <= x"00000001"; else res_s <= (others => '0'); end if;
      when "1001" =>
        if unsigned(rs1) < unsigned(rs2) then res_s <= x"00000001"; else res_s <= (others => '0'); end if;
      when others => res_s <= (others => '0');
    end case;
  end process;

  rd   <= res_s;
  zero <= '1' when res_s = x"00000000" else '0';
end architecture rtl;
