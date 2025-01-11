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
// It performs debouncing on the push buttons using a 1kHz clock, and a 10-bit shift register
// When PB0 is pressed, it will stop/start the counter
module experiment5 (
		/////// board clocks                      ////////////
		input logic CLOCK_50_I,                   // 50 MHz clock

		/////// pushbuttons/switches              ////////////
		input logic[3:0] PUSH_BUTTON_N_I,           // pushbuttons
		input logic[17:0] SWITCH_I,               // toggle switches

		/////// 7 segment displays/LEDs           ////////////
		output logic[6:0] SEVEN_SEGMENT_N_O[7:0], // 8 seven segment displays		
		output logic[8:0] LED_GREEN_O             // 9 green LEDs
);

parameter	MAX_1kHz_div_count = 24999,
		MAX_1Hz_div_count = 24999999;

logic resetn;

logic [15:0] clock_1kHz_div_count;
logic clock_1kHz, clock_1kHz_buf;

logic [24:0] clock_1Hz_div_count;
logic clock_1Hz, clock_1Hz_buf;

logic [9:0] debounce_shift_reg [3:0];
logic [3:0] push_button_status, push_button_status_buf;
logic [3:0] led_green;

logic [3:0] value, value_1;
logic [6:0] value_7_segment0, value_7_segment1;

logic XNOR_LED7;
logic AND_LED6;
logic NAND_LED5;
logic OR_LED4;
logic LED3;
logic LED2;
logic LED1;
logic LED0;

logic stop_count;
logic up_count;

assign resetn = ~SWITCH_I[17];

// Clock division for 1kHz clock
always_ff @ (posedge CLOCK_50_I or negedge resetn) begin
	if (resetn == 1'b0) begin
		clock_1kHz_div_count <= 16'd0;
	end else begin
		if (clock_1kHz_div_count < MAX_1kHz_div_count) begin
			clock_1kHz_div_count <= clock_1kHz_div_count + 16'd1;
		end else 
			clock_1kHz_div_count <= 16'd0;
	end
end

always_ff @ (posedge CLOCK_50_I or negedge resetn) begin
	if (resetn == 1'b0) begin
		clock_1kHz <= 1'b1;
	end else begin
		if (clock_1kHz_div_count == 16'd0) 
			clock_1kHz <= ~clock_1kHz;
	end
end

always_ff @ (posedge CLOCK_50_I or negedge resetn) begin
	if (resetn == 1'b0) begin
		clock_1kHz_buf <= 1'b1;	
	end else begin
		clock_1kHz_buf <= clock_1kHz;
	end
end

// Clock division for 1Hz clock
always_ff @ (posedge CLOCK_50_I or negedge resetn) begin
	if (resetn == 1'b0) begin
		clock_1Hz_div_count <= 25'd0;
	end else begin
		if (clock_1Hz_div_count < MAX_1Hz_div_count) begin
			clock_1Hz_div_count <= clock_1Hz_div_count + 25'd1;
		end else 
			clock_1Hz_div_count <= 25'd0;		
	end
end

always_ff @ (posedge CLOCK_50_I or negedge resetn) begin
	if (resetn == 1'b0) begin
		clock_1Hz <= 1'b1;
	end else begin
		if (clock_1Hz_div_count == 25'd0) 
			clock_1Hz <= ~clock_1Hz;
	end
end

always_ff @ (posedge CLOCK_50_I or negedge resetn) begin
	if (resetn == 1'b0) begin
		clock_1Hz_buf <= 1'b1;	
	end else begin
		clock_1Hz_buf <= clock_1Hz;
	end
end

// Shift register for debouncing
always_ff @ (posedge CLOCK_50_I or negedge resetn) begin
	if (resetn == 1'b0) begin
		debounce_shift_reg[0] <= 10'd0;
		debounce_shift_reg[1] <= 10'd0;
		debounce_shift_reg[2] <= 10'd0;
		debounce_shift_reg[3] <= 10'd0;						
	end else begin
		if (clock_1kHz_buf == 1'b0 && clock_1kHz == 1'b1) begin
			debounce_shift_reg[0] <= {debounce_shift_reg[0][8:0], ~PUSH_BUTTON_N_I[0]};
			debounce_shift_reg[1] <= {debounce_shift_reg[1][8:0], ~PUSH_BUTTON_N_I[1]};
			debounce_shift_reg[2] <= {debounce_shift_reg[2][8:0], ~PUSH_BUTTON_N_I[2]};
			debounce_shift_reg[3] <= {debounce_shift_reg[3][8:0], ~PUSH_BUTTON_N_I[3]};
		end
	end
end

// push_button_status will contained the debounced signal
always_ff @ (posedge CLOCK_50_I or negedge resetn) begin
	if (resetn == 1'b0) begin
		push_button_status <= 4'h0;
		push_button_status_buf <= 4'h0;
	end else begin
		push_button_status_buf <= push_button_status;
		push_button_status[0] <= |debounce_shift_reg[0];
		push_button_status[1] <= |debounce_shift_reg[1];
		push_button_status[2] <= |debounce_shift_reg[2];
		push_button_status[3] <= |debounce_shift_reg[3];						
	end
end

// Push button status is checked here for controlling the counter
always_ff @ (posedge CLOCK_50_I or negedge resetn) begin
	if (resetn == 1'b0) begin
		led_green <= 4'h0;
		stop_count <= 1'b0;
		// When up_count is a 0 the count direction is up, when it is a 1 the count direction is down
		up_count <= 1'b0;
	end else begin
		if (push_button_status_buf[0] == 1'b0 && push_button_status[0] == 1'b1) begin
			led_green[0] <= ~led_green[0];		
			stop_count <= ~stop_count;
		end
		if (push_button_status_buf[1] == 1'b0 && push_button_status[1] == 1'b1) begin
			led_green[1] <= ~led_green[1];
			up_count <= 1'b0;
		end
		if (push_button_status_buf[2] == 1'b0 && push_button_status[2] == 1'b1) begin
			led_green[2] <= ~led_green[2];		
			up_count <= 1'b1;
		end
		if (push_button_status_buf[3] == 1'b0 && push_button_status[3] == 1'b1) 
			led_green[3] <= ~led_green[3];		
	end
end

// Counter is incremented here
always_ff @ (posedge CLOCK_50_I or negedge resetn) begin
	if (resetn == 1'b0) begin
		value <= 4'h0;
		value_1 <= 4'h0;
	end else begin
		if (clock_1Hz_buf == 1'b0 && clock_1Hz == 1'b1) begin
			if (stop_count == 1'b0) begin
				// UP COUNTER
				if (up_count == 1'b0) begin
					if (value < 4'h4) begin
						value <= value + 4'h1;
					end else begin
						value <= 4'h0;
						if (value_1 < 4'h4) begin
							value_1 <= value_1 + 4'h1;
						end else begin
							value_1 <= 4'h0;
						end
					end
				// DOWN COUNTER
				end else begin
					if (value > 4'h0) begin
						value <= value - 4'h1;
					end else begin
						value <= 4'h4;
						if (value_1 > 4'h0) begin
							value_1 <= value_1 - 4'h1;
						end else begin
							value_1 <= 4'h4;
						end
					end
				end
			end
		end
	end
end

always_comb begin

	XNOR_LED7 = ~^SWITCH_I[15:0];
	
	AND_LED6 = (&SWITCH_I[15:8]) & (~|SWITCH_I[7:0]);
	
	NAND_LED5 = ~&SWITCH_I[15:8];

	OR_LED4 = |SWITCH_I[7:0];
	
	// Priority encoder for switch 15
	
	if (SWITCH_I[15] == 1'b1) begin
		
		if (SWITCH_I[0] == 1'b1) begin
			LED3 = 1'b0;
			LED2 = 1'b0;
			LED1 = 1'b0;
			LED0 = 1'b0;
		end else begin
			if (SWITCH_I[1] == 1'b1) begin
				LED3 = 1'b0;
				LED2 = 1'b0;
				LED1 = 1'b0;
				LED0 = 1'b1;
			end else begin
				if (SWITCH_I[2] == 1'b1) begin
					LED3 = 1'b0;
					LED2 = 1'b0;
					LED1 = 1'b1;
					LED0 = 1'b0;
				end else begin
					if (SWITCH_I[3] == 1'b1) begin
						LED3 = 1'b0;
						LED2 = 1'b0;
						LED1 = 1'b1;
						LED0 = 1'b1;
					end else begin
						if (SWITCH_I[4] == 1'b1) begin
							LED3 = 1'b0;
							LED2 = 1'b1;
							LED1 = 1'b0;
							LED0 = 1'b0;
						end else begin
							if (SWITCH_I[5] == 1'b1) begin
								LED3 = 1'b0;
								LED2 = 1'b1;
								LED1 = 1'b0;
								LED0 = 1'b1;
							end else begin
								if (SWITCH_I[6] == 1'b1) begin
									LED3 = 1'b0;
									LED2 = 1'b1;
									LED1 = 1'b1;
									LED0 = 1'b0;
								end else begin
									if (SWITCH_I[7] == 1'b1) begin
										LED3 = 1'b0;
										LED2 = 1'b1;
										LED1 = 1'b1;
										LED0 = 1'b1;
									end else begin
										if (SWITCH_I[8] == 1'b1) begin
											LED3 = 1'b1;
											LED2 = 1'b0;
											LED1 = 1'b0;
											LED0 = 1'b0;
										end else begin
											if (SWITCH_I[9] == 1'b1) begin
												LED3 = 1'b1;
												LED2 = 1'b0;
												LED1 = 1'b0;
												LED0 = 1'b1;
											end else begin
												if (SWITCH_I[10] == 1'b1) begin
													LED3 = 1'b1;
													LED2 = 1'b0;
													LED1 = 1'b1;
													LED0 = 1'b0;
												end else begin
													if (SWITCH_I[11] == 1'b1) begin
														LED3 = 1'b1;
														LED2 = 1'b0;
														LED1 = 1'b1;
														LED0 = 1'b1;
													end else begin
														if (SWITCH_I[12] == 1'b1) begin
															LED3 = 1'b1;
															LED2 = 1'b1;
															LED1 = 1'b0;
															LED0 = 1'b0;
														end else begin
															if (SWITCH_I[13] == 1'b1) begin
																LED3 = 1'b1;
																LED2 = 1'b1;
																LED1 = 1'b0;
																LED0 = 1'b1;
															end else begin
																if (SWITCH_I[14] == 1'b1) begin
																	LED3 = 1'b1;
																	LED2 = 1'b1;
																	LED1 = 1'b1;
																	LED0 = 1'b0;
																end else begin
																	LED3 = 1'b1;
																	LED2 = 1'b1;
																	LED1 = 1'b1;
																	LED0 = 1'b1;
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
					end
				end
			end
		end
	end else begin
	
		if (SWITCH_I[0] == 1'b0) begin
			LED3 = 1'b0;
			LED2 = 1'b0;
			LED1 = 1'b0;
			LED0 = 1'b0;
		end else begin
			if (SWITCH_I[1] == 1'b0) begin
				LED3 = 1'b0;
				LED2 = 1'b0;
				LED1 = 1'b0;
				LED0 = 1'b1;
			end else begin
				if (SWITCH_I[2] == 1'b0) begin
					LED3 = 1'b0;
					LED2 = 1'b0;
					LED1 = 1'b1;
					LED0 = 1'b0;
				end else begin
					if (SWITCH_I[3] == 1'b0) begin
						LED3 = 1'b0;
						LED2 = 1'b0;
						LED1 = 1'b1;
						LED0 = 1'b1;
					end else begin
						if (SWITCH_I[4] == 1'b0) begin
							LED3 = 1'b0;
							LED2 = 1'b1;
							LED1 = 1'b0;
							LED0 = 1'b0;
						end else begin
							if (SWITCH_I[5] == 1'b0) begin
								LED3 = 1'b0;
								LED2 = 1'b1;
								LED1 = 1'b0;
								LED0 = 1'b1;
							end else begin
								if (SWITCH_I[6] == 1'b0) begin
									LED3 = 1'b0;
									LED2 = 1'b1;
									LED1 = 1'b1;
									LED0 = 1'b0;
								end else begin
									if (SWITCH_I[7] == 1'b0) begin
										LED3 = 1'b0;
										LED2 = 1'b1;
										LED1 = 1'b1;
										LED0 = 1'b1;
									end else begin
										if (SWITCH_I[8] == 1'b0) begin
											LED3 = 1'b1;
											LED2 = 1'b0;
											LED1 = 1'b0;
											LED0 = 1'b0;
										end else begin
											if (SWITCH_I[9] == 1'b0) begin
												LED3 = 1'b1;
												LED2 = 1'b0;
												LED1 = 1'b0;
												LED0 = 1'b1;
											end else begin
												if (SWITCH_I[10] == 1'b0) begin
													LED3 = 1'b1;
													LED2 = 1'b0;
													LED1 = 1'b1;
													LED0 = 1'b0;
												end else begin
													if (SWITCH_I[11] == 1'b0) begin
														LED3 = 1'b1;
														LED2 = 1'b0;
														LED1 = 1'b1;
														LED0 = 1'b1;
													end else begin
														if (SWITCH_I[12] == 1'b0) begin
															LED3 = 1'b1;
															LED2 = 1'b1;
															LED1 = 1'b0;
															LED0 = 1'b0;
														end else begin
															if (SWITCH_I[13] == 1'b0) begin
																LED3 = 1'b1;
																LED2 = 1'b1;
																LED1 = 1'b0;
																LED0 = 1'b1;
															end else begin
																if (SWITCH_I[14] == 1'b0) begin
																	LED3 = 1'b1;
																	LED2 = 1'b1;
																	LED1 = 1'b1;
																	LED0 = 1'b0;
																end else begin
																	LED3 = 1'b1;
																	LED2 = 1'b1;
																	LED1 = 1'b1;
																	LED0 = 1'b1;
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
					end
				end
			end
		end
	end
end


// Instantiate modules for converting hex number to 7-bit value for the 7-segment display
convert_hex_to_seven_segment unit0 (
	.hex_value(value), 
	.converted_value(value_7_segment0)
);

convert_hex_to_seven_segment unit1 (
	.hex_value(value_1), 
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

assign LED_GREEN_O = {1'b1, XNOR_LED7, AND_LED6, NAND_LED5, OR_LED4, LED3, LED2, LED1, LED0};

endmodule
