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
// It utilizes a priority encoder to detect a 1 on the MSB for switches 17 downto 0
// It then displays the switch number onto the 7-segment display
module experiment2 (
		/////// switches                          ////////////
		input logic[17:0] SWITCH_I,               // toggle switches

		/////// 7 segment displays/LEDs           ////////////
		output logic[6:0] SEVEN_SEGMENT_N_O[7:0], // 8 seven segment displays
		output logic[8:0] LED_GREEN_O,            // 9 green LEDs
		output logic[17:0] LED_RED_O              // 18 red LEDs
);

logic [3:0] value;
logic [6:0] value_7_segment;

// Instantiate a module for converting hex number to 7-bit value for the 7-segment display
convert_hex_to_seven_segment unit0 (
	.hex_value(value), 
	.converted_value(value_7_segment)
);

// A priority encoder using if-else statement
always_comb begin
	if (SWITCH_I[9] == 1'b1) begin
		value = 4'd9;
	end else begin
		if (SWITCH_I[8] == 1'b1) begin
			value = 4'd8;
		end else begin
			if (SWITCH_I[7] == 1'b1) begin
				value = 4'd7;
			end else begin
				if (SWITCH_I[6] == 1'b1) begin
					value = 4'd6;
				end else begin
					if (SWITCH_I[5] == 1'b1) begin
						value = 4'd5;
					end else begin
						if (SWITCH_I[4] == 1'b1) begin
							value = 4'd4;
						end else begin
							if (SWITCH_I[3] == 1'b1) begin
								value = 4'd3;
							end else begin
								if (SWITCH_I[2] == 1'b1) begin
									value = 4'd2;
								end else begin
									if (SWITCH_I[1] == 1'b1) begin
										value = 4'd1;
									end else begin
										if (SWITCH_I[0] == 1'b1) begin
											value = 4'd0;
										end else begin
											value = 4'hF;
										end
									end
								end
							end
						end
					end
				end
			end
		end
	end
end

assign  SEVEN_SEGMENT_N_O[0] = value_7_segment,
        SEVEN_SEGMENT_N_O[1] = 7'h7f,
        SEVEN_SEGMENT_N_O[2] = 7'h7f,
        SEVEN_SEGMENT_N_O[3] = 7'h7f,
        SEVEN_SEGMENT_N_O[4] = 7'h7f,
        SEVEN_SEGMENT_N_O[5] = 7'h7f,
        SEVEN_SEGMENT_N_O[6] = 7'h7f,
        SEVEN_SEGMENT_N_O[7] = 7'h7f;

assign LED_RED_O = SWITCH_I;
assign LED_GREEN_O = {5'h00, value};
	
endmodule
