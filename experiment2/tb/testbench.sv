/*
Copyright by Nicola Nicolici
Department of Electrical and Computer Engineering
McMaster University
Ontario, Canada
*/

`timescale 1ns/100ps
`default_nettype none

`include "board_test.sv"

module TB;
  
	// creatinng instance of interface to connect UUT and testcase
	board_intf i_intf();  
	board_test i_board_test(i_intf);

	//UUT instance
	experiment2 UUT(
		.CLOCK_50_I(i_intf.clock_50),
		.SWITCH_I(i_intf.switch),
		.SEVEN_SEGMENT_N_O(i_intf.seven_seg_n), 
		.LED_GREEN_O(i_intf.led_green),
		.LED_RED_O(i_intf.led_red),
		.PS2_DATA_I(i_intf.ps2_data),
		.PS2_CLOCK_I(i_intf.ps2_clock));

endmodule
