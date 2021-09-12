/*
Copyright by Nicola Nicolici
Department of Electrical and Computer Engineering
McMaster University
Ontario, Canada
*/

`timescale 1ns/100ps

interface board_intf();
  
	logic [17:0] switch;		// switches

	logic [6:0] seven_seg_n [7:0];	// 8 seven segment displays		
	logic [8:0] led_green;		// 9 green LEDs
	logic [17:0] led_red;		// 18 red LEDs
  
endinterface
