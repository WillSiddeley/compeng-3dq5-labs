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

	wire [15:0] SRAM_data_io;
	logic [15:0] SRAM_write_data, SRAM_read_data;
	logic [19:0] SRAM_address;
	logic SRAM_UB_N, SRAM_LB_N, SRAM_WE_N, SRAM_CE_N, SRAM_OE_N;
	logic SRAM_resetn;

	// instantiate the unit under test
	experiment4 UUT (
		.CLOCK_50_I(clock_50),
		.SWITCH_I(switch),
		.LED_GREEN_O(led_green),

		.SRAM_DATA_IO(SRAM_data_io),
		.SRAM_ADDRESS_O(SRAM_address),
		.SRAM_UB_N_O(SRAM_UB_N),
		.SRAM_LB_N_O(SRAM_LB_N),
		.SRAM_WE_N_O(SRAM_WE_N),
		.SRAM_CE_N_O(SRAM_CE_N),
		.SRAM_OE_N_O(SRAM_OE_N)
	);

	// the emulator for the external SRAM during simulation
	tb_SRAM_Emulator SRAM_component (
		.Clock_50(clock_50),
		.Resetn(SRAM_resetn),

		.SRAM_data_io(SRAM_data_io),
		.SRAM_address(SRAM_address[17:0]),
		.SRAM_UB_N(SRAM_UB_N),
		.SRAM_LB_N(SRAM_LB_N),
		.SRAM_WE_N(SRAM_WE_N),
		.SRAM_CE_N(SRAM_CE_N),
		.SRAM_OE_N(SRAM_OE_N)
	);

	// 50 MHz clock generation
	always begin
		#10;
		clock_50 = ~clock_50;
	end

	initial begin
        $timeformat(-6, 2, "us", 10);
		clock_50 = 1'b0;
		switch[17:0] = 18'd0;
		SRAM_resetn = 1'b1;
		repeat (2) @(negedge clock_50);
		$display("\n*** Asserting the asynchronous reset ***");
		switch[17] = 1'b1;
		repeat (3) @(negedge clock_50);
		switch[17] = 1'b0;
		$display("*** Deasserting the asynchronous reset ***\n");
		@(negedge clock_50);
		// clear SRAM model
		SRAM_resetn = 1'b0;
		@(negedge clock_50);
		SRAM_resetn = 1'b1;
	end

	initial begin

		wait (SRAM_resetn === 1'b0);
		wait (SRAM_resetn === 1'b1);

		// switch[1] = 1'b1;	// Stuck at address
		// switch[2] = 1'b1;	// Stuck at write data
		// switch[3] = 1'b1;	// Stuck at write enable
		// switch[4] = 1'b1;	// Stuck at read data

		@ (posedge clock_50);
		@ (posedge clock_50);

		// Start the BIST
		switch[0] = 1'b1;
		@ (posedge clock_50);
		switch[0] = 1'b0;

		# 200;

		// run simulation until BIST is done
		@ (posedge UUT.BIST_finish);

		#20;
		$stop;
	end

endmodule


