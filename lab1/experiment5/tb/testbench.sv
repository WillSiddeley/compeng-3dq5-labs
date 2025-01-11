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
  
	parameter SIM_PB_DEBOUNCED_SCALE_FACTOR_DIV_2 = 25;
	parameter SIM_BCD_COUNTER_SCALE_FACTOR_DIV_2 = 250;

	// creatinng instance of interface to connect UUT and testcase
	board_intf i_intf();  
	board_test i_board_test(i_intf);

	//UUT instance
	experiment5 #( 
		.MAX_1kHz_div_count(SIM_PB_DEBOUNCED_SCALE_FACTOR_DIV_2-1), 
		.MAX_1Hz_div_count(SIM_BCD_COUNTER_SCALE_FACTOR_DIV_2-1)) 
		UUT(
		.CLOCK_50_I(i_intf.clock_50),
		.PUSH_BUTTON_N_I(i_intf.push_button_n),
		.SWITCH_I(i_intf.switch),
		.SEVEN_SEGMENT_N_O(i_intf.seven_seg_n), 
		.LED_GREEN_O(i_intf.led_green));

/*
	//wave dump
	initial begin 
		$dumpfile("dump.vcd"); 
		$dumpvars;
	end
*/

endmodule
