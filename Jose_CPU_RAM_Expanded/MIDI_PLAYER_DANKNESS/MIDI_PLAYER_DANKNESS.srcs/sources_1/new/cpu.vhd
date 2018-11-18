-- Basic CPU 

library	ieee;
use	ieee.std_logic_1164.all;
use	ieee.numeric_std.all;

entity	cpu is
	port(
		clk, reset: in std_logic;
		we: out std_logic;
		ab:  out std_logic_vector(15 downto 0); -- address bus
		cdbi: in std_logic_vector(7 downto 0);  -- CPU input data bus 
		cdbo: out std_logic_vector(7 downto 0);  -- CPU output data bus 
		snd: out std_logic
		);
end cpu;

architecture arch of cpu is
    constant ABW: integer:=16;
    constant DBW: integer:=8;
	constant LDRM: unsigned := "10100000"; -- A0H	
	constant INCR: unsigned := "10110000"; -- B0H
	constant JMPM: unsigned := "11000000"; -- C0H
	constant LDMR: unsigned := "10100001"; -- A1H  >> NEW FOR RAM...
	constant HALT: unsigned := "11111111"; -- FFH
	constant PFT: unsigned := "10101011"; -- ABH
	
	type	state_type is (
		  all_0, all_1, all_2, all_3, all_4, generate_wave   -- common to all instructions
		 );
	signal	state:	state_type;
	signal	pc_reg: unsigned(ABW-1 downto 0);
	signal	ir_reg: unsigned(DBW-1 downto 0);
	signal	r_reg: unsigned(DBW-1 downto 0);
	
	signal sndi: std_logic;
	signal hibyte: std_logic_vector(DBW-1 downto 0);
	signal lobyte: std_logic_vector(DBW-1 downto 0);
	signal timed25: unsigned(DBW-1 downto 0);
	
	signal freq: std_logic_vector(15 downto 0);
	
	signal clk_counter: unsigned(31 downto 0);
    signal clk_counter_next: unsigned(31 downto 0);
    
    constant mhz100: integer := 100000000;
    
	signal frq_counter: unsigned(31 downto 0);
    signal frq_counter_next: unsigned(31 downto 0);
    
	signal frq_switch_point: unsigned(31 downto 0);


begin
process(clk, reset)	-- next state + (Moore) outputs code section
begin
    if (reset = '1') then
		state <= all_0;
        pc_reg <= (others => '0');    -- reset address is all-0
        ir_reg <= (others => '1');     -- default opcode is HALT (all '1')
        r_reg  <= (others => '0');    -- initialize data register to 0

    elsif (clk'event and clk = '1') then
        we <= '0';
        
        clk_counter <= clk_counter_next;
        frq_counter <= frq_counter_next;
        
        case state is
            when all_0 => 					 
                ir_reg <= unsigned(cdbi);  
                pc_reg <= pc_reg+1;
                state <= all_1;
            when all_1 =>			
                if (ir_reg = LDRM) then	  
                    r_reg <= unsigned(cdbi);
                    pc_reg <= pc_reg+1;
                    state <= all_0;
                elsif (ir_reg = INCR) then
                    r_reg <= r_reg + 1;
                    state <= all_0;
                elsif (ir_reg = JMPM) then
                    pc_reg(7 downto 0) <= unsigned(cdbi);
                    state <= all_0;	
                elsif (ir_reg = LDMR) then
                    we <= '1';
                    pc_reg <= pc_reg+1;
                    state<= all_0;
                elsif (ir_reg = HALT) then
                    state <= all_1;
                    
                elsif (ir_reg = PFT) then
                    hibyte <= cdbi;
                    pc_reg <= pc_reg+1;
                    state <= all_2;
                else 
                    state <= all_0;
                end if;
                
           when all_2 =>
               if (ir_reg = PFT) then
                   lobyte <= cdbi;
                   pc_reg <= pc_reg+1;
                   state <= all_3;
               end if;
               
           when all_3 =>
               if (ir_reg = PFT) then
                   timed25 <= unsigned(cdbi);
                   freq <= hibyte & lobyte;
                   frq_counter <= (others => '0');
                   frq_switch_point <= (others => '0');
                   clk_counter <= (others => '0');
                   sndi <= '1';
                   pc_reg <= pc_reg+1;
                   state <= all_4;
               end if;
               
           when all_4 =>
               if (ir_reg = PFT) then
                   frq_switch_point <= unsigned(freq)*2000;
                   state <= generate_wave;
               end if;
                
           when generate_wave =>
               if (ir_reg = PFT) then
                   if (clk_counter / (mhz100/25) >= timed25) then
                       state <= all_0;
                   else
                       if (frq_counter = (mhz100/frq_switch_point)) then
                           sndi <= not sndi;
                           frq_counter <= (others => '0');
                       end if;
                   end if;
               end if;
                                                            -- Instruction RST 			
        end case; 
    end if;
end process;

clk_counter_next <= clk_counter + 1;
frq_counter_next <= frq_counter + 1;

ab <= std_logic_vector(pc_reg);
cdbo <= std_logic_vector(r_reg);
snd <= sndi;

end arch;
