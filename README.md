# LogoCar

## About

The LogoCar is an attempt at simulating a real life Logo "turtle". `"Logo is an educational programming language, designed in 1967 by Wally Feurzeig, Seymour Papert and Cynthia Solomon."` - from wikipedia. Our LogoCar features a CPU & Controller that generate waveforms from a series of machine code commands. You could call it a "Turtle CPU".

It features the following;
- A Vivado project with implementation of CPU and Controller, which take an input program, and generate output waves for two stepper motors and a servo. It assumes a Basys-3 board is used, a TowerPro SG90 servo, and two 28BYJ-48 stepper motors.
- A Python project that can assemble turtle commands into CPU machine code; which can be used to program the LogoCar by pasting the RAM initalization line into Vivado, and programming the board. The Python project also features an L-System compiler, that turns L-Systems into turtle commands, which can be then turned into machine code for the CPU.

# The car

Uses servo to put pen up or down. The motors can move forward, backward, turn left, and turn right. Turning is specified in `degrees`, and moving in a line is specified in `mm`. Programmed by copying a RAM initialization statement into the Vivado project, and then synthesizing, running an implementation, and generating a `.bin` file for the flash memory.

It requires an external battery pack, and uses the JA and JB ports.

# L-Systems

L-Systems in simple terms are just strings with interpretations. You start with an initial axiom (string), and have a set of production rules (string translation rules). You do one iteration, to generate a new string. After a number of iterations you get a very large string. These strings can be interpreted geometrically, to create complex patterns. 
The geometric interpration usually only requires four simple commands; `forward, backward, left and right`. In this sense L-Systems and Turtle are perfectly suited for each other, which is why an `L-System to Turtle Commands`-compiler is included in this project. You can try and copy any L-System you find online, compile it, paste it in the Vivado project, and program the LogoCar's Basys-3 board; even with it's large degree of imprecision, the LogoCar will draw something resembling the intended pattern.

`An L-system or Lindenmayer system is a parallel rewriting system and a type of formal grammar. An L-system consists of an alphabet of symbols that can be used to make strings, a collection of production rules that expand each symbol into some larger string of symbols, an initial "axiom" string from which to begin construction, and a mechanism for translating the generated strings into geometric structures.` - from wikipedia