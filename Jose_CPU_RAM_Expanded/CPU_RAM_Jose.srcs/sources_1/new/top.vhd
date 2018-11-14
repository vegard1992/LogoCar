----------------------------------------------------------------------------------
-- top level description
----------------------------------------------------------------------------------
library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top is
	port(
			clk, reset: in std_logic;
			srv: out std_logic;
			mtrl: out std_logic_vector(3 downto 0);
			mtrr: out std_logic_vector(3 downto 0)
		);
end top;

architecture arch of top is
	constant ABW: integer := 16; -- address bus width
	constant DBW: integer := 8;  -- date bus width
	signal we:  std_logic; -- write enable for RAM
    signal ab:  std_logic_vector(ABW-1 downto 0); -- address bus for RAM
	signal db1: std_logic_vector(DBW-1 downto 0); -- top level data bus to connect CPU dbo to RAM dbi
	signal db2: std_logic_vector(DBW-1 downto 0); -- top level data bus to connect CPU dbi to RAM dbo
	
	signal c1: std_logic_vector(DBW-1 downto 0); -- connect CPU to controller: CPU instr out to Contr. instr in
	signal c2: std_logic_vector(DBW-1 downto 0); -- connect CPU to controller: CPU data out to Contr. data in
	signal c3: std_logic; -- connect CPU to controller: Contr. data out to CPU data in
	
	signal mtrri: std_logic_vector(3 downto 0);
	signal mtrli: std_logic_vector(3 downto 0);
	signal srvi: std_logic;
	
component cpu
    port(
        clk, reset: in std_logic;
        we: out std_logic;
        
        rdbi: in std_logic_vector(DBW-1 downto 0); -- CPU input data bus
        rdbo: out std_logic_vector(DBW-1 downto 0); -- CPU output data bus
        ab:  out std_logic_vector(ABW-1 downto 0); -- CPU address bus
        
		cri: in std_logic; -- CPU-Controller input control bus
        cio: out std_logic_vector(7 downto 0); -- CPU-Controller output control bus
		cdbo: out std_logic_vector(7 downto 0) -- CPU-Controller data bus

        );
end component;
        
component ram_async
    port(
      clk, reset, we: in std_logic;
      ab: in std_logic_vector(ABW-1 downto 0);
      rdbi: in std_logic_vector(DBW-1 downto 0); -- input data bus for RAM
      rdbo: out std_logic_vector(DBW-1 downto 0) -- output data bus for RAM
        );        
end component;

component controller
    port(
      clk, reset: in std_logic;
      
      cii: in std_logic_vector(7 downto 0); -- controller instruction input
      cdbi: in std_logic_vector(7 downto 0); -- controller data input
      cro: out std_logic; -- controller output

      mtrl: out std_logic_vector(3 downto 0);
      mtrr: out std_logic_vector(3 downto 0);
      srv: out std_logic
    );
end component;

begin  
        
	  cpu_unit: cpu	
      port map ( clk => clk, reset => reset, we => we,
                 ab => ab, rdbi => db2, rdbo => db1,
	             cio => c1, cdbo => c2, -- outputs 
                 cri => c3 -- inputs
				);
					
      ram_unit: ram_async	
      port map( clk => clk, reset => reset, 
                ab => ab, we => we, 
				rdbi => db1, rdbo => db2
				);	  	
				
	 ctrl_unit: controller
	 port map(clk => clk, reset => reset,

	          cro => c3, -- outputs
	          cii => c1, cdbi => c2, -- inputs
	          srv => srvi, mtrl => mtrli, mtrr => mtrri
	          );
	          
	 srv <= srvi;
	 mtrr <= mtrri;
	 mtrl <= mtrli;
	                 	
end  arch;

