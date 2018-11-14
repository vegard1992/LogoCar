-- 

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
ENTITY top_tb IS
END top_tb;
 
ARCHITECTURE behavior OF top_tb IS 
 
    -- Component Declarations for the Units Under Test (UUT)
    COMPONENT top
    PORT(
         clk, reset: in std_logic;
         mtrr: out std_logic_vector(3 downto 0);
         mtrl: out std_logic_vector(3 downto 0);
         srv: out std_logic
        );
    END COMPONENT;

   --Inputs
   signal clk : std_logic := '0';
   signal reset : std_logic := '0';

 	--Outputs
    signal srv: std_logic;
    signal mtrr: std_logic_vector(3 downto 0);
    signal mtrl: std_logic_vector(3 downto 0);
       
   -- Clock period definitions
   constant clk_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: top PORT MAP (
          clk => clk,
          reset => reset,
          srv => srv,
          mtrl => mtrl,
          mtrr => mtrr
        );

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
        reset <= '1';
        wait for clk_period*2;
		reset <= '0';	
		wait for clk_period*500000000;

   end process;

END;
