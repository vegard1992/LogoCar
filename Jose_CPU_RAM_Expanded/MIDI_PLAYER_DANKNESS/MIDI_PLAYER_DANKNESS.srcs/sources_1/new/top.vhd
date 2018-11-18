----------------------------------------------------------------------------------
-- top level description
----------------------------------------------------------------------------------
library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top is
	port(
			clk, reset: in std_logic;
			snd: out std_logic
		);
end top;

architecture arch of top is
	constant ABW: integer := 16; -- address bus width
	constant DBW: integer := 8;  -- date bus width
	signal we:  std_logic; -- write enable for RAM
    signal ab:  std_logic_vector(ABW-1 downto 0); -- address bus for RAM
	signal db1: std_logic_vector(DBW-1 downto 0); -- top level data bus to connect CPU dbo to RAM dbi
	signal db2: std_logic_vector(DBW-1 downto 0); -- top level data bus to connect CPU dbi to RAM dbo
	
	signal sndi: std_logic;
	
component cpu
    port(
        clk, reset: in std_logic;
        we: out std_logic;
        cdbi: in std_logic_vector(7 downto 0); -- CPU input data bus
        cdbo: out std_logic_vector(7 downto 0); -- CPU output data bus
        ab:  out std_logic_vector(15 downto 0); -- CPU address bus
        snd: out std_logic
        );
end component;
        
component ram_async
    port(
      clk, reset, we: in std_logic;
      ab: in std_logic_vector(15 downto 0);
      rdbi: in std_logic_vector(7 downto 0); -- input data bus for RAM
      rdbo: out std_logic_vector(7 downto 0) -- output data bus for RAM
        );        
end component;

begin  
        
	  ctr_unit: cpu	
      port map ( clk => clk, reset => reset, we => we,
                 ab => ab, cdbi => db2, cdbo => db1,
                 snd => sndi
				);
					
      ram_unit: ram_async	
      port map( clk => clk, reset => reset, 
                ab => ab, we => we, 
				rdbi => db1, rdbo => db2
				);	  	

      snd <= sndi;		
      	
end  arch;
