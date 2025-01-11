/*
Copyright by Henry Ko and Nicola Nicolici
Department of Electrical and Computer Engineering
McMaster University
Ontario, Canada
*/

`timescale 1ns/100ps
`ifndef DISABLE_DEFAULT_NET
`default_nettype none
`endif

// This is the top module
// It divides the 50 MHz clock into a 1 Hz clock
// It then uses edge detection and pulse generation for incrementing a counter every second
module experiment4 (
		/////// board clocks                      ////////////
		input logic CLOCK_50_I,                   // 50 MHz clock

		/////// pushbuttons/switches              ////////////
		input logic[17:0] SWITCH_I,               // toggle switches

		/////// 7 segment displays/LEDs           ////////////
		output logic[6:0] SEVEN_SEGMENT_N_O[7:0], // 8 seven segment displays
		output logic[8:0] LED_GREEN_O,            // 9 green LEDs
		output logic[17:0] LED_RED_O              // 18 red LEDs
);

parameter	MAX_1Hz_div_count = 12499999;

logic resetn;
logic [24:0] clock_div_count;
logic one_sec_clock, one_sec_clock_buf;

logic count_enable;
logic [7:0] counter;

logic [6:0] value_7_segment0, value_7_segment1;

assign resetn = ~SWITCH_I[17];

// A counter for clock division
always_ff @ (posedge CLOCK_50_I or negedge resetn) begin
	if (resetn == 1'b0) begin
		clock_div_count <= 25'h0000000;
	end else begin
		if (clock_div_count < MAX_1Hz_div_count) begin
			clock_div_count <= clock_div_count + 25'd1;
		end else 
			clock_div_count <= 25'h0000000;		
	end
end

// The value of one_sec_clock flip-flop is inverted every time the counter is reset to zero
always_ff @ (posedge CLOCK_50_I or negedge resetn) begin
	if (resetn == 1'b0) begin
		one_sec_clock <= 1'b1;
	end else begin
		if (clock_div_count == 'd0) one_sec_clock <= ~one_sec_clock;
	end
end

// A buffer on one_sec_clock for edge detection
always_ff @ (posedge CLOCK_50_I or negedge resetn) begin
	if (resetn == 1'b0) begin
		one_sec_clock_buf <= 1'b1;	
	end else begin
		one_sec_clock_buf <= one_sec_clock;
	end
end

// Pulse generation, that generates one pulse every time a posedge is detected on one_sec_clock
assign count_enable = (one_sec_clock_buf == 1'b0 && one_sec_clock == 1'b1);

// A counter that increments every second
always_ff @ (posedge CLOCK_50_I or negedge resetn) begin
	if (resetn == 1'b0) begin
		counter <= 8'd0;
	end else begin
		if (count_enable == 1'b1) begin
			if (counter > 58) begin
				counter <= 8'd0;
			end else begin
				counter <= counter + 8'd1;
			end
		end
	end
end

// Instantiate modules for converting hex number to 7-bit value for the 7-segment display
convert_hex_to_seven_segment unit0 (
	.hex_value(counter[3:0]), 
	.converted_value(value_7_segment0)
);

convert_hex_to_seven_segment unit1 (
	.hex_value(counter[7:4]), 
	.converted_value(value_7_segment1)
);

assign	SEVEN_SEGMENT_N_O[0] = value_7_segment0,
		SEVEN_SEGMENT_N_O[1] = value_7_segment1,
		SEVEN_SEGMENT_N_O[2] = 7'h7f,
		SEVEN_SEGMENT_N_O[3] = 7'h7f,
		SEVEN_SEGMENT_N_O[4] = 7'h7f,
		SEVEN_SEGMENT_N_O[5] = 7'h7f,
		SEVEN_SEGMENT_N_O[6] = 7'h7f,
		SEVEN_SEGMENT_N_O[7] = 7'h7f;
		
assign LED_RED_O = SWITCH_I;
assign LED_GREEN_O = {1'b0, counter};
endmodule
