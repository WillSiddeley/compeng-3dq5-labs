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
		switch = 18'h00000;
	end

	initial begin
		# 100;
		switch = 18'h00001;
		# 100;
		switch = 18'h00003;
		# 100;
		switch = 18'h00007;
		# 100;
	end

	always@(led_red) begin
		$display("%t: red leds = %b", $realtime, led_red);
    end

endmodule
