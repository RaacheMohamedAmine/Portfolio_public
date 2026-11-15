library ieee;
use ieee.std_logic_1164.all;

entity pc_reg is
  port (
    clk     : in  std_logic;
    rst     : in  std_logic;
    pc_next : in  std_logic_vector(31 downto 0);
    pc      : out std_logic_vector(31 downto 0)
  );
end entity pc_reg;

architecture rtl of pc_reg is
begin
  process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        pc <= (others => '0');
      else
        pc <= pc_next;
      end if;
    end if;
  end process;
end architecture rtl;
