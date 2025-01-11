/*
Copyright by Nicola Nicolici
Department of Electrical and Computer Engineering
McMaster University
Ontario, Canada
*/

`timescale 1ns/100ps

interface board_intf();
  
	logic clock_50;			// 50 MHz clock

	logic [3:0] push_button_n;	// pushbuttons
	logic [17:0] switch;		// switches

	logic [6:0] seven_seg_n [7:0];	// 8 seven segment displays		
	logic [8:0] led_green;		// 9 green LEDs
	logic [17:0] led_red;		// 18 red LEDs

	logic ps2_clock;		// PS2 clock
	logic ps2_data;			// PS2 data
  
	logic lcd_power; 		// LCD power ON/OFF
	logic lcd_back_light;           // LCD back light ON/OFF
	logic lcd_read_write;           // LCD read/write select
	logic lcd_en;                   // LCD enable
	logic lcd_command;              // LCD command/data select
	logic [7:0] lcd_data;           // LCD data bus 8 bits

	// 50 MHz clock generation
	initial begin
		clock_50 = 1'b0;
	end

	always begin
		#10;
		clock_50 = ~clock_50;
	end
  
endinterface
