-- Listing 11.3 + Jon's code 23.10.2018
-- RAM with one address bus, one data bus in (rdbi) and one data bus out (rdbo)
-- sync write, async read

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ram_async is
   generic(
      ADDR_WIDTH: integer:=16;
      DATA_WIDTH: integer:=8
   );
   port(
      clk: in std_logic;
      we: in std_logic;
      reset: in std_logic;
      ab: in std_logic_vector(ADDR_WIDTH-1 downto 0);
      rdbi: in std_logic_vector(DATA_WIDTH-1 downto 0);
      rdbo: out std_logic_vector(DATA_WIDTH-1 downto 0)
   );
end ram_async;

architecture arch of ram_async is
   type ram_type is array (0 to 2**ADDR_WIDTH-1)
        of std_logic_vector (DATA_WIDTH-1 downto 0);        

signal ram: ram_type := (0 => x"11", 1 => x"F0", 2 => x"D0", 3 => x"32", 4 => x"AA", 5 => x"5A", 6 => x"D0", 7 => x"32", 8 => x"AA", 9 => x"5A", 10 => x"D0", 11 => x"32", 12 => x"AA", 13 => x"5A", 14 => x"D0", 15 => x"32", 16 => x"55", 17 => x"5A", 18 => x"D0", 19 => x"32", 20 => x"55", 21 => x"5A", 22 => x"D0", 23 => x"32", 24 => x"55", 25 => x"5A", 26 => x"D0", 27 => x"32", others => x"FF");
				
begin	
process(clk, reset)
   begin
     if (reset = '1') then  

     elsif (clk'event and clk = '1') then
        if (we = '1') then
           ram(to_integer(unsigned(ab))) <= rdbi;
        end if;
     end if;
   end process;
   rdbo <= ram(to_integer(unsigned(ab)));
end arch;