/*
Copyright by Nicola Nicolici
Department of Electrical and Computer Engineering
McMaster University
Ontario, Canada
*/

`timescale 1ns/100ps
`default_nettype none

module TB;

	logic clock_50;
	logic [17:0] switch;
	logic [8:0] led_green;

	initial begin

		// set up default values and inputs
        $timeformat(-6, 2, "us", 10);
		clock_50 = 1'b0;
		switch[17:0] = 18'd0;

		// apply the asynchronous reset
		repeat (2) @(negedge clock_50);
		$display("\n*** Asserting the asynchronous reset ***");
		switch[17] = 1'b1;
		repeat (3) @(negedge clock_50);
		switch[17] = 1'b0;
		$display("*** Deasserting the asynchronous reset ***\n");

		// assert switch[0] to start computing
		switch[0] = 1'b1;
		repeat (3) @(posedge clock_50);
		switch[0] = 1'b0;

		// run simulation for another 21 us
		# 21000;
		$stop;
	end

	// 50 MHz clock generation
	always begin
		#10;
		clock_50 = ~clock_50;
	end

	//UUT instance
	experiment3 UUT(
		.CLOCK_50_I(clock_50),
		.SWITCH_I(switch),
		.LED_GREEN_O(led_green)
	);

endmodule
