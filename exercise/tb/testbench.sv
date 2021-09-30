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
	experiment4 UUT (
		.CLOCK_50_I(i_intf.clock_50),
		.SWITCH_I(i_intf.switch),
		.VGA_CLOCK_O(i_intf.vga_clock),
		.VGA_HSYNC_O(i_intf.vga_hsync),
		.VGA_VSYNC_O(i_intf.vga_vsync),
		.VGA_BLANK_O(i_intf.vga_blank),
		.VGA_SYNC_O(i_intf.vga_sync),
		.VGA_RED_O(i_intf.vga_red),
		.VGA_GREEN_O(i_intf.vga_green),
		.VGA_BLUE_O(i_intf.vga_blue),
		.PS2_DATA_I(i_intf.ps2_data),
		.PS2_CLOCK_I(i_intf.ps2_clock)

);

endmodule
