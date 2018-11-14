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
   signal ram: ram_type := (others => x"FF");
begin
   process(clk, reset)
   begin
     if (reset = '1') then  
        -- PROGRAM:
        ram(0) <= x"11";
        ram(1) <= x"F0";
	    ram(2) <= x"D0";
        ram(3) <= x"05";
        ram(4) <= x"AA";
        ram(5) <= x"78";
        ram(6) <= x"D0";
        ram(7) <= x"05";
        ram(8) <= x"55";
        ram(9) <= x"78";
        ram(10) <= x"D0";
        ram(11) <= x"05";
        ram(12) <= x"55";
        ram(13) <= x"78";
        ram(14) <= x"D0";
        ram(15) <= x"05";
        ram(16) <= x"AA";
        ram(17) <= x"78";
        ram(18) <= x"D0";
        ram(19) <= x"05";
        ram(20) <= x"AA";
        ram(21) <= x"78";
        ram(22) <= x"D0";
        ram(23) <= x"05";
        ram(24) <= x"D0";
        ram(25) <= x"05";
        ram(26) <= x"55";
        ram(27) <= x"78";
        ram(28) <= x"D0";
        ram(29) <= x"05";
        ram(30) <= x"AA";
        ram(31) <= x"78";
        ram(32) <= x"D0";
        ram(33) <= x"05";
        ram(34) <= x"55";
        ram(35) <= x"78";
        ram(36) <= x"D0";
        ram(37) <= x"05";
        ram(38) <= x"55";
        ram(39) <= x"78";
        ram(40) <= x"D0";
        ram(41) <= x"05";
        ram(42) <= x"AA";
        ram(43) <= x"78";
        ram(44) <= x"D0";
        ram(45) <= x"05";
        ram(46) <= x"55";
        ram(47) <= x"78";
        ram(48) <= x"D0";
        ram(49) <= x"05";
        ram(50) <= x"D0";
        ram(51) <= x"05";
        ram(52) <= x"AA";
        ram(53) <= x"78";
        ram(54) <= x"D0";
        ram(55) <= x"05";
        ram(56) <= x"AA";
        ram(57) <= x"78";
        ram(58) <= x"D0";
        ram(59) <= x"05";
        ram(60) <= x"55";
        ram(61) <= x"78";
        ram(62) <= x"D0";
        ram(63) <= x"05";
        ram(64) <= x"55";
        ram(65) <= x"78";
        ram(66) <= x"D0";
        ram(67) <= x"05";
        ram(68) <= x"AA";
        ram(69) <= x"78";
        ram(70) <= x"D0";
        ram(71) <= x"05";
        ram(72) <= x"AA";
        ram(73) <= x"78";
        ram(74) <= x"D0";
        ram(75) <= x"05";
        ram(76) <= x"D0";
        ram(77) <= x"05";
        ram(78) <= x"D0";
        ram(79) <= x"05";
        ram(80) <= x"D0";
        ram(81) <= x"05";
        ram(82) <= x"AA";
        ram(83) <= x"78";
        ram(84) <= x"D0";
        ram(85) <= x"05";
        ram(86) <= x"D0";
        ram(87) <= x"05";
        ram(88) <= x"D0";
        ram(89) <= x"05";
        ram(90) <= x"D0";
        ram(91) <= x"05";
        
        -- all other positions contain the opcode of HLT
     elsif (clk'event and clk = '1') then
        if (we = '1') then
           ram(to_integer(unsigned(ab))) <= rdbi;
        end if;
     end if;
   end process;
   rdbo <= ram(to_integer(unsigned(ab)));
end arch;