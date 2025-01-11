/*
Copyright by Nicola Nicolici
Department of Electrical and Computer Engineering
McMaster University
Ontario, Canada
*/

`timescale 1ns/100ps

interface board_intf();
  
	logic clock;			// 50 MHz clock

	logic [17:0] switch;		// switches

	logic [8:0] led_green;		// 9 green LEDs
	logic [17:0] led_red;		// 18 red LEDs
  
endinterface
