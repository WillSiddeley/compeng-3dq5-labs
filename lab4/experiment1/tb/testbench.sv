/*
Copyright by Nicola Nicolici
Department of Electrical and Computer Engineering
McMaster University
Ontario, Canada
*/

`timescale 1ns/100ps
`default_nettype none

module TB;

	logic [17:0] switch;
	logic [6:0] seven_seg_n[7:0];
	logic [17:0] led_red;
	logic [8:0] led_green;

	//UUT instance
	experiment1 UUT(
		.SWITCH_I(switch),
		.SEVEN_SEGMENT_N_O(seven_seg_n),
		.LED_RED_O(led_red),
		.LED_GREEN_O(led_green));

	initial begin
        $timeformat(-6, 2, "us", 10);
		switch = 18'b000000000000000000;
	end

	initial begin
		# 100;
		switch = 18'b000000000000000001;
		# 100;
		switch = 18'b000000000000000011;
		# 100;
		switch = 18'b000000000000000111;
		# 100;
		switch = 18'b000000000000001000;
		# 100
		switch = 18'b000000000000001001;
	end

	always@(led_red) begin
		$display("%t: red leds = %b", $realtime, led_red);
   end
	
	always@(led_green) begin
		$display("%t: green leds = %b", $realtime, led_green);
	end
	
	always@(seven_seg_n[0]) begin
		$display("%t: seven segment display right = %b", $realtime, seven_seg_n[0]);
	end
	
	always@(seven_seg_n[7]) begin
		$display("%t: seven segment display left = %b", $realtime, seven_seg_n[7]);
	end

endmodule
