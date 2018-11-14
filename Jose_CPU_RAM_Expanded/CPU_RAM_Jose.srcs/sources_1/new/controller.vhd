----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/09/2018 03:41:56 AM
-- Design Name: 
-- Module Name: controller - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;


--   ## DESIGN ##
-- Operates independently of the CPU. Commands are sent from the CPU,
-- and the controller performs them. When a command is waiting to be
-- executed, a ready flag will be set to 0; thus the
-- CPU knows the unit is busy, and can hold it's following commands
-- until the Controller is ready. If the programmer does not control
-- the sending of commands, the unit will only execute the first command
-- and ignore all remaining commands:
-- This is due to the controller being busy executing its commands for
-- many many cycles. If the CPU sends one command each cycle, it would 
-- need in excess of 200K commands, to actually queue another. Because
-- the controller would be busy for ~200K cycles.
-- When a command is executing, or the controller is entirely idle,
-- the ready flag is set to 1, and a command can be queued.
--
-- The reason for this design, is because we want full control of the
-- waveforms generated. If there were no controller, and the CPU went
-- into a state of generating a waveform for the Left Servo Motor, then
-- no other waveforms could be generated; unless alterations were made to
-- accommodate parallel generation of waveforms, in IDLE states. 
-- This could cause unforeseen behaviour in external I/O units.
-- I figured
-- it were more logical to offload the control of external systems into
-- a controller module, rather than create a very complex CPU design.

-- Our system at any point in time can be described by the following:
-- UNINITIALISED:
-- The servo starts in a PUP (Pen Up) state, waveforms generated accordingly
-- Motors start in a state of not moving, waveforms generated accordingly;
-- internal motor stepper count signal is set to zero!
-- IDLE:
-- The servo waveform will be as such that it stays in its current state
-- Motors waveforms will be as such that they perform a motor step if the
-- internal motor stepper counter is not 0
-- QUEUED:
-- The current waveforms will finish generating, before the queued
-- signal starts generating
-- NEXT:
-- Servo:
-- The state of the servo will change to Pen Up or Pen Down, depending
-- on incoming instruction, the state will again be set to ready, and
-- waveforms will continue generating according to IDLE state, if no
-- new command is queued.
-- Motors:
-- Waveforms will be sent to the (either of the) motors, according to 
-- how many steps are specified by the data part of controller input
-- The ready flag will be set to 1, and once finished executing, 
-- the state will return to IDLE, if no other command is queued.
-- There are separate next states for servos and motors, because
-- their waveforms are not of equal length. If they were to be one
-- NEXT state, then the waveforms would have to be aligned. So
-- when both waveforms are finished generating, it could transition
-- into a NEXT state.
-- Instead I chose to have two NEXT states, one for the servo waveform,
-- and one for the motor waveforms.
-- It does however support a BOTH_NXT state, for the cases where the waveforms
-- do align.

entity controller is
    port(
      clk, reset: in std_logic;
    
      cii: in std_logic_vector(7 downto 0); -- instruction input
      cdbi: in std_logic_vector(7 downto 0); -- data input
      cro: out std_logic; -- output
      
      mtrl: out std_logic_vector(3 downto 0); -- motor left signal
      mtrr: out std_logic_vector(3 downto 0); -- motor right signal
      srv: out std_logic -- servo signal
    );
end;

architecture Behavioral of controller is

-- stepper instructions
constant SMF: unsigned := "11010000"; -- D0H
constant SMB: unsigned := "00101111"; -- 2FH
constant SMTL: unsigned := "10101010"; -- AAH
constant SMTR: unsigned := "01010101"; -- 55H
-- servo instructions
constant PDN: unsigned := "11110000";
constant PUP: unsigned := "11100000";

-- internal logic

-- states
type state_type is (
  IDLE, QUEUED, MTR_NXT, SRV_NXT, BOTH_NXT   -- common to all instructions
 );

-- cycle timings
constant SRV_DUTY_CYCLE: integer := 2000000;
constant SRV_MIN_POS_CYCLES: integer := SRV_DUTY_CYCLE/20;
constant SRV_MAX_POS_CYCLES: integer := SRV_DUTY_CYCLE/10;

constant MTR_DUTY_CYCLE: integer := 200000;
constant MTR_ON: integer := MTR_DUTY_CYCLE/4;

-- state
signal state: state_type;
signal state_prev: state_type;

signal instr_next: unsigned(7 downto 0);
signal instr_next_data: unsigned(7 downto 0);

-- counters
signal srv_clock_count: unsigned(31 downto 0);
signal srv_clock_count_next: unsigned(31 downto 0);

signal mtr_clock_count: unsigned(31 downto 0);
signal mtr_clock_count_next: unsigned(31 downto 0);

-- internal waveform states
type srv_state_type is (
 srvPUP, srvPDN
);
signal srv_state: srv_state_type; -- current servo position

signal mtr_ticks: unsigned(7 downto 0); -- motor ticks
type mtr_state_type is (
  mtrFWD, mtrBKW, mtrLFT, mtrRGT, mtrIDLE   -- common to all instructions
 );
signal mtr_state: mtr_state_type; -- idle, forward, left, right, backwards 
-- (more states possible; i.e. forward with ratio)

-- output signals
signal srv_i: std_logic;
signal mtrl_i: std_logic_vector(3 downto 0);
signal mtrr_i: std_logic_vector(3 downto 0);

-- ready signals
type ready_state_type is (
 READY, NOT_READY
);
signal readiness_state: ready_state_type;
constant c_ready: std_logic := '1';
constant c_not_ready: std_logic := '0';
signal readiness: std_logic;

begin
process(clk, reset)
begin
    if (reset = '1') then  
        srv_clock_count <= (others => '0');
        mtr_clock_count <= (others => '0');
          
        mtr_ticks <= (others => '0');
        srv_state <= srvPUP;
          
        readiness_state <= NOT_READY;
        readiness <= c_not_ready;
        
        state <= IDLE;
        state_prev <= state;
        
        mtr_state <= mtrIDLE;
        
        srv_i <= '0';
        mtrl_i <= (others => '0');
        mtrr_i <= (others => '0');
        
        instr_next <= (others => '0');
        instr_next_data <= (others => '0');
            
    elsif (clk'event and clk = '1') then
        srv_clock_count <= srv_clock_count_next;
        mtr_clock_count <= mtr_clock_count_next;
        readiness_state <= NOT_READY;
        
        -- idle/queued logic
        if (state = IDLE) then
              if (not ((cii) = "00000000")) then -- incoming signal from cpu
                  state <= QUEUED;
                  instr_next <= unsigned(cii);
                  instr_next_data <= unsigned(cdbi);
              else
                  readiness_state <= READY;
              end if;
        elsif (state = QUEUED) then

        end if;
        
        -- set readiness output
        if (readiness_state = READY) then
            readiness <= c_ready;
        else
            readiness <= c_not_ready;
        end if;    
        
        -- transition
        if (state = MTR_NXT or state = BOTH_NXT) then
              state <= state_prev;
              mtr_ticks <= (others => '0');
              if (instr_next = SMF) then
                  mtr_state <= mtrFWD;
                  mtr_ticks <= instr_next_data;
                  state <= IDLE;
                  instr_next <= (others => '0');
              elsif(instr_next = SMB) then
                  mtr_state <= mtrBKW;
                  mtr_ticks <= instr_next_data;
                  state <= IDLE;
                  instr_next <= (others => '0');
              elsif(instr_next = SMTL) then
                  mtr_state <= mtrLFT;
                  mtr_ticks <= instr_next_data;
                  state <= IDLE;
                  instr_next <= (others => '0');
              elsif(instr_next = SMTR) then
                  mtr_state <= mtrRGT;
                  mtr_ticks <= instr_next_data;
                  state <= IDLE;
                  instr_next <= (others => '0');
              else
                  mtr_state <= mtrIDLE;
              end if;
        end if;
        if (state = SRV_NXT or state = BOTH_NXT) then
              state <= state_prev;
              if (instr_next = PDN) then
                  srv_state <= srvPDN;
                  state <= IDLE;
                  instr_next <= (others => '0');
              elsif (instr_next = PUP) then
                  srv_state <= srvPUP;
                  state <= IDLE;
                  instr_next <= (others => '0');
              end if;
        end if;
    
        -- servo waveforms
        if (srv_state = srvPDN) then
            if (unsigned(srv_clock_count) < SRV_MIN_POS_CYCLES) then -- wave is '1' for 1ms when PDN
                srv_i <= '1';
            else
                srv_i <= '0';
            end if;
        elsif (srv_state = srvPUP) then
            if (unsigned(srv_clock_count) < SRV_MAX_POS_CYCLES) then -- wave is '1' for 2ms when PUP
                srv_i <= '1';
            else
                srv_i <= '0';
            end if;
        end if;
        
        -- motor waveforms; currently just a skeleton with example waveforms
        if (mtr_state = mtrIDLE) then
            mtrr_i <= (others => '0');
            mtrl_i <= (others => '0');
        elsif (mtr_state = mtrFWD) then
            if(mtr_clock_count < MTR_ON) then
                mtrr_i <= (others => '1');
                mtrl_i <= (others => '1');
            else
                mtrr_i <= (others => '0');
                mtrl_i <= (others => '0');
            end if;
        elsif (mtr_state = mtrBKW) then

        elsif (mtr_state = mtrLFT) then
            if(mtr_clock_count < MTR_ON) then
                mtrr_i <= (others => '0');
                mtrl_i <= (others => '1');
            else
                mtrr_i <= (others => '0');
                mtrl_i <= (others => '0');
            end if;        
        elsif (mtr_state = mtrRGT) then
            if(mtr_clock_count < MTR_ON) then
                mtrr_i <= (others => '1');
                mtrl_i <= (others => '0');
            else
                mtrr_i <= (others => '0');
                mtrl_i <= (others => '0');
            end if;
        end if;
        
        mtrr_i <= (others => '0');
        mtrl_i <= (others => '0');
        
        -- waveforms finished generating
        if ((srv_clock_count) = SRV_DUTY_CYCLE) then
            srv_clock_count <= (others => '0');
            state_prev <= state;
            state <= SRV_NXT;
        end if;
        
        if ((mtr_clock_count) = MTR_DUTY_CYCLE) then
            mtr_clock_count <= (others => '0');
            if (mtr_ticks > 0) then
                mtr_ticks <= mtr_ticks - 1;
            else
                state_prev <= state;
                if(state = SRV_NXT) then
                    state <= BOTH_NXT;
                else
                    state <= MTR_NXT;
                end if;
            end if;
        end if;    
end if;
end process;

srv_clock_count_next <= srv_clock_count + 1;
mtr_clock_count_next <= mtr_clock_count + 1;

cro <= readiness;

srv <= srv_i;
mtrl <= mtrl_i;
mtrr <= mtrr_i;

end Behavioral;
