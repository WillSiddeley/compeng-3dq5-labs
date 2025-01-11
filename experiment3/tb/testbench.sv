/*
Copyright by Nicola Nicolici
Department of Electrical and Computer Engineering
McMaster University
Ontario, Canada
*/

`timescale 1ns/100ps
`default_nettype none

`include "../rtl/define_state.h"
`define FEOF 32'hFFFFFFFF

// the top module of the testbench
module TB;

	logic clock_50;			// 50 MHz clock
	logic clock_27;			// 27 MHz clock
	logic clock_57_6;		// 57.6 MHz clock

	logic [3:0] push_button_n;	// pushbuttons
	logic [17:0] switch;		// switches

	logic [6:0] seven_seg_n [7:0];	// 8 seven segment displays
	logic [8:0] led_green;		// 9 green LEDs

	logic uart_rx, uart_tx;		// UART receive/transmit
	logic td_resetn;		// enable the 27 MHz clock on the board
					// not used in simulation

	// instantiate the unit under test
	experiment3 UUT (
		.CLOCK_50_I(clock_50),
		.CLOCK_27_I(clock_27),
		.SWITCH_I(switch),
		.PUSH_BUTTON_N_I(push_button_n),
		.SEVEN_SEGMENT_N_O(seven_seg_n),
		.LED_GREEN_O(led_green),
		.UART_RX_I(uart_rx),
		.UART_TX_O(uart_tx),
		.TD_RESET_N(td_resetn)
	);

	// generate the 50 MHz clock
	initial begin
		clock_50 = 1'b0;
		forever begin
			#10;
			clock_50 = ~clock_50;
		end
	end

	// generate the 27 MHz clock
	initial begin
		// not used in simulation
		clock_27 = 1'b0;
		// the UART PLL gets bypassed in UART
		// with a 57.6 MHz clock generated like
		// in the initial block given below
	end

	// generate the 57.6 MHz clock
	initial begin
		clock_57_6 = 1'b0;
		forever begin
			#8.68;
			clock_57_6 = ~clock_57_6;
		end
	end

	initial begin
		$timeformat(-6, 2, "us", 10);
		switch[17:0] = 18'd0;
		push_button_n[3:0] = 4'hF;
		uart_rx = 1'b1;
		repeat (2) @(negedge clock_50);
		$display("\n*** Asserting the asynchronous reset ***");
		switch[17] = 1'b1;
		repeat (3) @(negedge clock_50);
		switch[17] = 1'b0;
		$display("*** Deasserting the asynchronous reset ***\n");
		@(negedge clock_50);
	end

	initial begin
		@(posedge switch[17]);
		@(negedge switch[17]);

		// we start transmission from host to UUT
		// 25 clock cycles after async reset
		repeat (25) @(posedge clock_50);
		switch[0] = 1'b1;
		repeat (10) @(posedge clock_50);
		switch[0] = 1'b0;
		uart_rx_generate();
	end

	initial begin
		@(posedge switch[17]);
		@(negedge switch[17]);

		// we start transmission from UUT to host
		// 5000 clock cycles after async reset
		// the extra time is needed to ensure
		// that the first byte was written to the DP-RAM
		repeat (5000) @(posedge clock_50);
		switch[1] = 1'b1;
		@(posedge UUT.UART_tx_clock_enable);
		repeat (10) @(posedge clock_50);
		switch[1] = 1'b0;
		uart_tx_assemble();
	end

	task uart_rx_generate;
		int src_fd, file_data;
		string src_filename;
		logic [7:0] uart_rx_byte;
		int inter_byte_delay, rx_index;
	begin
		src_filename = {"../data/512byte.txt"};
		src_fd = $fopen(src_filename, "rb");
		$display("%t: Start generating Rx data to UUT\n", $realtime);

		// read the first byte from the file
		file_data = $fgetc(src_fd);
		while (file_data != `FEOF) begin

			uart_rx_byte[7:0] = file_data & 8'hFF;
			$write("%t: start sending byte 8\'h%h to UUT\n", $realtime, uart_rx_byte);

			// generate the Start bit
			uart_rx = 1'b0;
			repeat (500) @(posedge clock_57_6);

			// 500 pulses at 57.6 MHz equal one pulse at 115.2 KHz
			for (rx_index=0; rx_index<8; rx_index++) begin
				// generate the each bit from the byte
				uart_rx = uart_rx_byte[rx_index];
				repeat (500) @(posedge clock_57_6);
			end

			// generate the Stop bit
			uart_rx = 1'b1;
			repeat (500) @(posedge clock_57_6);

			// randomize the delay between bytes
			inter_byte_delay = 20 + ($urandom % 80);
			repeat (inter_byte_delay) @(posedge clock_50);

			// read next byte from the file
			file_data = $fgetc(src_fd);
		end
	end
	endtask

	task uart_tx_assemble;
		int dst_fd, file_data;
		string dst_filename;
		logic [7:0] uart_tx_byte;
		int tx_index;
		int frame_error_count;
	begin
		frame_error_count = 0;
		dst_filename = {"../data/512byte.raw"};
		dst_fd = $fopen(dst_filename, "wb");
		$display("%t: Start receiving Tx data from UUT\n", $realtime);
		fork
			begin
				forever begin
					// we assume data is assembled at 115.2 KHz
					// detect start bit from UUT
					@(negedge uart_tx);
					// wait for one full 115.2 KHz pulse
					repeat (500) @(posedge clock_57_6);
					// start assembling a sequence of bits in a byte
					tx_index = 0;
					// wait for half of 115.2 KHz pulse to start sampling
					repeat (250) @(posedge clock_57_6);
					repeat (8) begin
						// sample received bit from UUT
						uart_tx_byte[tx_index++] = uart_tx;
						// delay for a full 115.2 KHz pulse
						repeat (500) @(posedge clock_57_6);
					end
					if (uart_tx != 1'b1) begin
						$display("%t: Frame error - Stop bit expected after byte %h",
							$realtime, uart_tx_byte);
						frame_error_count++;
					end else begin
						$display("%t: assembled byte 8\'h%h from UUT", $realtime, uart_tx_byte);
						$fwrite(dst_fd, "%c", uart_tx_byte);
					end
				end
			end
			begin
				@(posedge UUT.UART_tx_done);
				$display("%t: Finished receiving Tx data from UUT.\n", $realtime);
				if (frame_error_count == 0) $display("No frame errors!\n");
				else $display("There were %d frame errors.\n", frame_error_count);
				$fclose(dst_fd);

				// end simulation
				repeat (10) @(posedge clock_50);
				$stop;
			end
		join_none
	end
	endtask

endmodule
