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
  
	parameter SIM_MAX_LCD_delay_count = 10;

	// creatinng instance of interface to connect UUT and testcase
	board_intf i_intf();  
	board_test i_board_test(i_intf);

	//UUT instance
	experiment4  #( 
		.MAX_LCD_delay_count(SIM_MAX_LCD_delay_count-1))
		UUT(
		.CLOCK_50_I(i_intf.clock_50),
		.SWITCH_I(i_intf.switch),
		.LED_GREEN_O(i_intf.led_green),
		.LED_RED_O(i_intf.led_red),
		.SEVEN_SEGMENT_N_O(i_intf.seven_seg_n),
		.PS2_DATA_I(i_intf.ps2_data),
		.PS2_CLOCK_I(i_intf.ps2_clock),
		.LCD_POWER_O(i_intf.lcd_power),
		.LCD_BACK_LIGHT_O(i_intf.lcd_back_light),
		.LCD_READ_WRITE_O(i_intf.lcd_read_write),
		.LCD_EN_O(i_intf.lcd_en),
		.LCD_COMMAND_DATA_O(i_intf.lcd_command),
		.LCD_DATA_IO(i_intf.lcd_data));

endmodule
