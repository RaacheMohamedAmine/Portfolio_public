library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity reg_file is
  port (
    clk      : in  std_logic;
    rst      : in  std_logic;
    we       : in  std_logic;
    rs1_add  : in  std_logic_vector(4 downto 0);
    rs2_add  : in  std_logic_vector(4 downto 0);
    rd_add   : in  std_logic_vector(4 downto 0);
    rd_data  : in  std_logic_vector(31 downto 0);
    rs1_data : out std_logic_vector(31 downto 0);
    rs2_data : out std_logic_vector(31 downto 0)
  );
end entity reg_file;

architecture rtl of reg_file is
  type typereg is array (0 to 31) of std_logic_vector(31 downto 0);
  signal regfile : typereg := (others => (others => '0'));
begin
  process(clk, rst)
  begin
    if rst = '1' then
      regfile <= (others => (others => '0'));
    elsif rising_edge(clk) then
      if we = '1' and rd_add /= "00000" then
        regfile(to_integer(unsigned(rd_add))) <= rd_data;
      end if;
    end if;
  end process;

  rs1_data <= (others => '0') when rs1_add = "00000" else regfile(to_integer(unsigned(rs1_add)));
  rs2_data <= (others => '0') when rs2_add = "00000" else regfile(to_integer(unsigned(rs2_add)));
end architecture rtl;
