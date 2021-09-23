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
// It illustrates a simple state machine for detecting 
// if a push button is pressed consecutively for 3 times
module experiment1 (
		/////// board clocks                      ////////////
		input logic CLOCK_50_I,                   // 50 MHz clock

		/////// pushbuttons/switches              ////////////
		input logic[3:0] PUSH_BUTTON_N_I,         // pushbuttons
		input logic[17:0] SWITCH_I,               // toggle switches

		/////// 7 segment displays/LEDs           ////////////
		output logic[6:0] SEVEN_SEGMENT_N_O[7:0], // 8 seven segment displays		
		output logic[8:0] LED_GREEN_O             // 9 green LEDs
);

parameter	MAX_1kHz_div_count = 24999;

logic resetn;

enum logic [2:0] {
	S_IDLE,
	S_PB0_ONCE,
	S_PB0_TWICE,
	S_PB0_DISPLAY,
	S_PB1_ONCE,
	S_PB1_TWICE,
	S_PB1_DISPLAY
} state;

logic [15:0] clock_1kHz_div_count;
logic clock_1kHz, clock_1kHz_buf;

logic [9:0] debounce_shift_reg [3:0];
logic [3:0] push_button_status, push_button_status_buf;
logic [3:0] PB_detected;

logic [2:0] counter;
logic [3:0] value;
logic [6:0] value_7_segment [1:0];

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

// Shift register for debouncing the push buttons
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

// OR gate for debouncing the push buttons
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

// Edge detection for push buttons
assign PB_detected = push_button_status & ~push_button_status_buf;

// FSM
always_ff @ (posedge CLOCK_50_I or negedge resetn) begin
	if (resetn == 1'b0) begin
		state <= S_IDLE;
	end else begin
		case (state)
		S_IDLE: begin
			if (PB_detected[0] == 1'b1) state <= S_PB0_ONCE;
			if (PB_detected[1] == 1'b1) state <= S_PB1_ONCE;
		end
		S_PB0_ONCE: begin
			if (PB_detected[0] == 1'b1) state <= S_PB0_TWICE;
			if (PB_detected[1] == 1'b1) state <= S_PB1_ONCE;
			else if (PB_detected[2] || PB_detected[3]) state <= S_IDLE;
		end
		S_PB0_TWICE: begin
			if (PB_detected[0] == 1'b1) state <= S_PB0_DISPLAY;
			if (PB_detected[1] == 1'b1) state <= S_PB1_ONCE;		
			else if (PB_detected[2] || PB_detected[3]) state <= S_IDLE;
		end
		S_PB0_DISPLAY: begin
			if (PB_detected[1] == 1'b1) state <= S_PB1_ONCE;
			else if (PB_detected[2] || PB_detected[3]) state <= S_IDLE;
		end
		S_PB1_ONCE: begin
			if (PB_detected[1] == 1'b1) state <= S_PB1_TWICE;
			if (PB_detected[0] == 1'b1) state <= S_PB0_ONCE;
			else if (PB_detected[2] || PB_detected[3]) state <= S_IDLE;
		end
		S_PB1_TWICE: begin
			if (PB_detected[1] == 1'b1) state <= S_PB1_DISPLAY;
			if (PB_detected[0] == 1'b1) state <= S_PB0_ONCE;
			else if (PB_detected[2] || PB_detected[3]) state <= S_IDLE;
		end
		S_PB1_DISPLAY: begin
			if (PB_detected[0] == 1'b1) state <= S_PB0_ONCE;
			else if (PB_detected[2] || PB_detected[3]) state <= S_IDLE;
		end
		endcase
	end
end

// Control value according to the state
always_comb begin
	case (state)
	S_PB0_DISPLAY: value = 4'd0;
	S_PB1_DISPLAY: value = 4'd1;
	default: value = 4'hf;
	endcase
end

// Control counter according to the state
always_comb begin
	case (state)
	S_PB0_ONCE: counter = 3'd1;
	S_PB0_TWICE: counter = 3'd2;
	S_PB0_DISPLAY: counter = 3'd3;
	S_PB1_ONCE: counter = 3'd4;
	S_PB1_TWICE: counter = 3'd5;
	S_PB1_DISPLAY: counter = 3'd6;
	default: counter = 3'd0;
	endcase
end

convert_hex_to_seven_segment unit0 (
	.hex_value(value), 
	.converted_value(value_7_segment[0])
);

convert_hex_to_seven_segment unit1 (
	.hex_value({2'b00, counter}), 
	.converted_value(value_7_segment[1])
);

assign	SEVEN_SEGMENT_N_O[0] = value_7_segment[0],
		SEVEN_SEGMENT_N_O[1] = 7'h7f,
		SEVEN_SEGMENT_N_O[2] = 7'h7f,
		SEVEN_SEGMENT_N_O[3] = 7'h7f,
		SEVEN_SEGMENT_N_O[4] = value_7_segment[1],
		SEVEN_SEGMENT_N_O[5] = 7'h7f,
		SEVEN_SEGMENT_N_O[6] = 7'h7f,
		SEVEN_SEGMENT_N_O[7] = 7'h7f;

assign LED_GREEN_O = {resetn, state, 2'd0,
						~PUSH_BUTTON_N_I[3], 
						~PUSH_BUTTON_N_I[2], 
						~PUSH_BUTTON_N_I[1], 
						~PUSH_BUTTON_N_I[0]};

endmodule
