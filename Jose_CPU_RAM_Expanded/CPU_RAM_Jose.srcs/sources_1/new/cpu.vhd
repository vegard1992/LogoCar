-- Basic CPU 

library	ieee;
use	ieee.std_logic_1164.all;
use	ieee.numeric_std.all;

entity	cpu is
    generic(
        ABW: integer := 16;
        DBW: integer := 8
    );
	port(
		clk, reset: in std_logic;
		we: out std_logic;
		ab:  out std_logic_vector(ABW-1 downto 0); -- address bus
		rdbi: in std_logic_vector(7 downto 0);  -- CPU-RAM input data bus 
		rdbo: out std_logic_vector(7 downto 0);  -- CPU-RAM output data bus
		 
		cri: in std_logic; -- CPU-Controller input control bus
		cio: out std_logic_vector(7 downto 0); -- CPU-Controller output control bus
		cdbo: out std_logic_vector(7 downto 0) -- CPU-Controller data bus
		);
end cpu;

-- IMPLEMENTED INSTRUCTIONS:
-- LDRM: Load from memory, into R
-- LDMR: Load from R, into memory
-- INCR: Increment R
-- JMPM: Jump to address M
-- HALT: Halt execution indefinitely
-- NOP: No operation
-- ISRZ: Is R zero
-- JRZ: Jump if R is zero

-- WFR: Wait for ready
-- SETAW: Set automatic wait
-- JRDY: Jump if ready
-- SMF: Step both motors forward
-- SMB: Step both motors backwards
-- SMTL: Step left motor forward, right motor backward
-- SMTR: Step right motor forward, left motor backward
-- TLA: Turn left by angle
-- TRA: Turn right by angle
-- PDN: Pen down
-- PUP: Pen up

architecture arch of cpu is
    constant mhz100: integer := 100 * 1000 * 1000;

    -- general instructions
	constant LDRM: unsigned := "10100000"; -- A0H	
	constant LDMR: unsigned := "10100001"; -- A1H 
	constant INCR: unsigned := "10110000"; -- B0H
	constant JMPM: unsigned := "11000000"; -- C0H
	
	constant ISRZ: unsigned := "10000000"; -- 80H
	constant JZ: unsigned := "01111111"; -- 7FH
	
	constant HALT: unsigned := "11111111"; -- FFH
	constant IWAIT: unsigned := "11011111"; -- DFH
	
	constant NOP: unsigned := "00000000"; -- 00H
	
    -- controller instructions
	constant WFR: unsigned := "00100010"; -- 22H
    constant SETAW: unsigned := "00010001"; -- 11H
    
	constant JRDY: unsigned := "10011001"; -- 99H
	
	-- stepper instruction
	constant SMF: unsigned := "11010000"; -- D0H
	constant SMB: unsigned := "00101111"; -- 2FH
	constant SMTL: unsigned := "10101010"; -- AAH
	constant SMTR: unsigned := "01010101"; -- 55H
	constant TLA: unsigned := "10100101"; -- A5H
	constant TRA: unsigned := "01011010"; -- 5AH
	constant steps_per_degree_per: unsigned := x"64"; -- 100
	constant hundredpercent: unsigned := x"64"; -- 100
	
	-- servo instructions
	constant PDN: unsigned := "11110000"; -- F0H
	constant PUP: unsigned := "11100000"; -- E0H
	
	
	type	state_type is (
		  all_0, all_1, all_2   -- common to all instructions
		 );
		 
	signal	state_reg:	state_type;
	
	signal	pc_reg: unsigned(ABW-1 downto 0);
	-- program counter
	signal instr_data_msb: unsigned(DBW-1 downto 0); -- used for 3 byte instructions, to store 2nd byte (1st data byte).
    signal waiter: unsigned(3 downto 0); -- used to wait in instructions, to align timing between cpu and controller
    
	signal	ir_reg: unsigned(DBW-1 downto 0);
	-- instruction register
	
	signal	r_reg: unsigned(DBW-1 downto 0);
	-- general-purpose register
	
	signal  f_reg: unsigned(DBW-1 downto 0); 
	-- f(0) is a control flag. if it is 1, the controller is ready.
	-- f(1) is the zero flag. it is set by ISRZ, when called: if R = 0, f(1) = 1, else f(1) = 0.
	-- f(2) is the automatic wait flag. if it is set to 1, then every provided controller instruction
	-- will halt execution of CPU until it finishes (the controller is again ready)
	
    signal cio_i: std_logic_vector(7 downto 0);
    signal cdbo_i: std_logic_vector(7 downto 0);
    
    signal wait_counter: unsigned(31 downto 0);
    signal wait_counter_next: unsigned(31 downto 0);

    constant wait_cycles: integer := (mhz100 / 2);

begin

process(clk, reset)	-- next state + (Moore) outputs code section
begin
	if (reset='1') then
        state_reg <= all_0;
        pc_reg <= (others => '0');    -- reset address is all-0
        ir_reg <= (others => '1');     -- default opcode is HALT (all '1')
        r_reg  <= (others => '0');    -- initialize data register to 0
        f_reg <= (others => '0');
        
        cio_i <= (others => '0');
        cdbo_i <= (others => '0');
        
        waiter <= (others => '0');
    
    elsif (clk'event and clk='1') then
        we <= '0';
        
        cio_i <= (others => '0');
        cdbo_i <= (others => '0');
        
        f_reg(0) <= cri;
        
        wait_counter <= wait_counter_next;
        
        case state_reg is
            when all_0 => 					 
                ir_reg <= unsigned(rdbi);  
                pc_reg <= pc_reg+1;
                state_reg <= all_1;
            when all_1 =>			
                if (ir_reg = NOP) then
                    state_reg <= all_0;
                elsif (ir_reg = LDRM) then	  
                    r_reg <= unsigned(rdbi);
                    pc_reg <= pc_reg+1;
                    state_reg <= all_0;
                elsif (ir_reg = INCR) then
                    r_reg <= r_reg + 1;
                    state_reg <= all_0;
                elsif (ir_reg = JMPM) then
                    instr_data_msb <= unsigned(rdbi);
                    pc_reg <= pc_reg+1;
                    state_reg <= all_2;
                elsif (ir_reg = LDMR) then
                    we <= '1';
                    pc_reg <= pc_reg+1;
                    state_reg <= all_0;
                elsif (ir_reg = HALT) then
                    state_reg <= all_1;
                elsif (ir_reg = IWAIT) then
                    wait_counter <= (others => '0');
                    state_reg <= all_2;
                    
                elsif (ir_reg = ISRZ) then
                    if (r_reg = 0) then
                        f_reg(1) <= '1';
                    else
                        f_reg(1) <= '0';
                    end if;
                    state_reg <= all_0;
               elsif (ir_reg = JZ) then
                   if (f_reg(1) = '1') then
                       instr_data_msb <= unsigned(rdbi);
                       pc_reg <= pc_reg+1;
                       state_reg <= all_2;
                   else
                       pc_reg<=pc_reg+1;
                       state_reg <= all_0;
                   end if;
                    
                -- jump instruction
                -- set pc to the instruction data signal, if ready flag is set
                elsif (ir_reg = JRDY) then
                    if (f_reg(0) = '1') then
                        instr_data_msb <= unsigned(rdbi);
                        pc_reg <= pc_reg+1;
                        state_reg <= all_2;
                    else
                        pc_reg<=pc_reg+1;
                        state_reg <= all_0;
                    end if;
                -- instructions to interact with controller
                -- there is no need to check if it's ready;
                -- by design it will ignore any incoming commands
                -- while it is not ready
                elsif (ir_reg = WFR) then
                    state_reg <= all_2;
                elsif (ir_reg = SETAW) then
                    f_reg(2) <= '1';
                    state_reg <= all_0;
                elsif (ir_reg = SMF) then 
                    cio_i <= std_logic_vector(SMF);
                    cdbo_i <= rdbi;
                    pc_reg <= pc_reg+1;
                    if (f_reg(2) = '0') then
                        state_reg <= all_0;
                    else
                        state_reg <= all_2;
                        ir_reg <= WFR;
                    end if;
                elsif (ir_reg = SMB) then 
                        cio_i <= std_logic_vector(SMB);
                        cdbo_i <= rdbi;
                        pc_reg <= pc_reg+1;
                        if (f_reg(2) = '0') then
                            state_reg <= all_0;
                        else
                            state_reg <= all_2;
                            ir_reg <= WFR;
                        end if;
                elsif (ir_reg = SMTL) then 
                    cio_i <= std_logic_vector(SMTL);
                    cdbo_i <= rdbi;
                    pc_reg <= pc_reg+1;
                    if (f_reg(2) = '0') then
                        state_reg <= all_0;
                    else
                        state_reg <= all_2;
                        ir_reg <= WFR;
                    end if;                
                elsif (ir_reg = SMTR) then 
                    cio_i <= std_logic_vector(SMTR);
                    cdbo_i <= rdbi;
                    pc_reg <= pc_reg+1;
                    if (f_reg(2) = '0') then
                        state_reg <= all_0;
                    else
                        state_reg <= all_2;
                        ir_reg <= WFR;
                    end if;  
                elsif (ir_reg = TLA) then 
                    cio_i <= std_logic_vector(SMTL);
                    cdbo_i(7 downto 0) <= rdbi(7 downto 0); -- dirty bit shift to mul by 2
                    pc_reg <= pc_reg+1;
                    if (f_reg(2) = '0') then
                        state_reg <= all_0;
                    else
                        state_reg <= all_2;
                        ir_reg <= WFR;
                    end if;                
                elsif (ir_reg = TRA) then 
                    cio_i <= std_logic_vector(SMTR);
                    cdbo_i(7 downto 0) <= rdbi(7 downto 0); --- dirty bit shift to mul by 2
                    pc_reg <= pc_reg+1;
                    if (f_reg(2) = '0') then
                        state_reg <= all_0;
                    else
                        state_reg <= all_2;
                        ir_reg <= WFR;
                    end if;  
                elsif (ir_reg = PDN) then
                    cio_i <= std_logic_vector(PDN);
                    if (f_reg(2) = '0') then
                        state_reg <= all_0;
                    else
                        state_reg <= all_2;
                        ir_reg <= WFR;
                    end if;                
                elsif (ir_reg = PUP) then
                    cio_i <= std_logic_vector(PUP);
                    if (f_reg(2) = '0') then
                        state_reg <= all_0;
                    else
                        state_reg <= all_2;
                        ir_reg <= WFR;
                    end if;                    
                else 
                    state_reg <= all_0;
                end if;
            when all_2 =>
                if (ir_reg = IWAIT) then
                    if (wait_counter = wait_cycles) then
                        state_reg <= all_0;
                    end if;
                elsif (ir_reg = JMPM) then
                    pc_reg <= instr_data_msb & unsigned(rdbi);
                    state_reg <= all_0;
                elsif (ir_reg = JRDY) then
                    pc_reg <= instr_data_msb & unsigned(rdbi);
                    state_reg <= all_0;
                elsif (ir_reg = JZ) then
                    pc_reg <= instr_data_msb & unsigned(rdbi);
                    state_reg <= all_0;
                elsif (ir_reg = WFR) then
                    if (f_reg(0) = '1' and waiter = 3) then
                        state_reg <= all_0;
                        waiter <= "0000";
                    else
                        if (not (waiter = 3)) then
                            waiter <= waiter + 1;
                        end if;
                    end if;                     
                end if;
         end case; 
     end if;
end process;

wait_counter_next <= wait_counter + 1;

ab <= std_logic_vector(pc_reg);
rdbo <= std_logic_vector(r_reg);

cio <= cio_i;
cdbo <= cdbo_i;

end arch;


