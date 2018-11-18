## This file is a general .xdc for the Basys3 rev B board
## To use it in a project:
## - uncomment the lines corresponding to used pins
## - rename the used ports (in each line, after get_ports) according to the top level signal names in the project

# Clock signal
#set_property PACKAGE_PIN W5 [get_ports CLK100MHZ]							
#	set_property IOSTANDARD LVCMOS33 [get_ports CLK100MHZ]
#	create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports CLK100MHZ]

set_property PACKAGE_PIN W5 [get_ports clk]							
    set_property IOSTANDARD LVCMOS33 [get_ports clk]

 

set_property PACKAGE_PIN U18 [get_ports reset]						
	set_property IOSTANDARD LVCMOS33 [get_ports reset]

##Pmod Header JA
##Sch name = JA1
set_property PACKAGE_PIN J1 [get_ports mtrl[0]]					
	set_property IOSTANDARD LVCMOS33 [get_ports {mtrl[0]}]
##Sch name = JA2
set_property PACKAGE_PIN L2 [get_ports {mtrl[1]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {mtrl[1]}]
##Sch name = JA3
set_property PACKAGE_PIN J2 [get_ports {mtrl[2]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {mtrl[2]}]
##Sch name = JA4
set_property PACKAGE_PIN G2 [get_ports {mtrl[3]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {mtrl[3]}]
##Sch name = JA7
set_property PACKAGE_PIN H1 [get_ports srv]					
	set_property IOSTANDARD LVCMOS33 [get_ports srv]
##Sch name = JA8
#set_property PACKAGE_PIN K2 [get_ports {JA[5]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JA[5]}]
##Sch name = JA9
#set_property PACKAGE_PIN H2 [get_ports {JA[6]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JA[6]}]
##Sch name = JA10
#set_property PACKAGE_PIN G3 [get_ports {JA[7]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JA[7]}]



##Pmod Header JB
##Sch name = JB1
set_property PACKAGE_PIN A14 [get_ports {mtrr[0]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {mtrr[0]}]
##Sch name = JB2
set_property PACKAGE_PIN A16 [get_ports {mtrr[1]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {mtrr[1]}]
##Sch name = JB3
set_property PACKAGE_PIN B15 [get_ports {mtrr[2]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {mtrr[2]}]
##Sch name = JB4
set_property PACKAGE_PIN B16 [get_ports {mtrr[3]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {mtrr[3]}]
##Sch name = JB7
#set_property PACKAGE_PIN A15 [get_ports {JB[4]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JB[4]}]
##Sch name = JB8
#set_property PACKAGE_PIN A17 [get_ports {JB[5]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JB[5]}]
##Sch name = JB9
#set_property PACKAGE_PIN C15 [get_ports {JB[6]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JB[6]}]
##Sch name = JB10 
#set_property PACKAGE_PIN C16 [get_ports {JB[7]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {JB[7]}]
 


