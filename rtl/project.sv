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

`include "define_state.h"

// This is the top module (same as experiment4 from lab 5 - just module renamed to "project")
// It connects the UART, SRAM and VGA together.
// It gives access to the SRAM for UART and VGA
module project (
		/////// board clocks                      ////////////
		input logic CLOCK_50_I,                   // 50 MHz clock

		/////// pushbuttons/switches              ////////////
		input logic[3:0] PUSH_BUTTON_N_I,         // pushbuttons
		input logic[17:0] SWITCH_I,               // toggle switches

		/////// 7 segment displays/LEDs           ////////////
		output logic[6:0] SEVEN_SEGMENT_N_O[7:0], // 8 seven segment displays
		output logic[8:0] LED_GREEN_O,            // 9 green LEDs

		/////// VGA interface                     ////////////
		output logic VGA_CLOCK_O,                 // VGA clock
		output logic VGA_HSYNC_O,                 // VGA H_SYNC
		output logic VGA_VSYNC_O,                 // VGA V_SYNC
		output logic VGA_BLANK_O,                 // VGA BLANK
		output logic VGA_SYNC_O,                  // VGA SYNC
		output logic[7:0] VGA_RED_O,              // VGA red
		output logic[7:0] VGA_GREEN_O,            // VGA green
		output logic[7:0] VGA_BLUE_O,             // VGA blue
		
		/////// SRAM Interface                    ////////////
		inout wire[15:0] SRAM_DATA_IO,            // SRAM data bus 16 bits
		output logic[19:0] SRAM_ADDRESS_O,        // SRAM address bus 18 bits
		output logic SRAM_UB_N_O,                 // SRAM high-byte data mask 
		output logic SRAM_LB_N_O,                 // SRAM low-byte data mask 
		output logic SRAM_WE_N_O,                 // SRAM write enable
		output logic SRAM_CE_N_O,                 // SRAM chip enable
		output logic SRAM_OE_N_O,                 // SRAM output logic enable
		
		/////// UART                              ////////////
		input logic UART_RX_I,                    // UART receive signal
		output logic UART_TX_O                    // UART transmit signal
);
	
logic resetn;

top_state_type top_state;

// For Push button
logic [3:0] PB_pushed;

// For VGA SRAM interface
logic VGA_enable;
logic [17:0] VGA_base_address;
logic [17:0] VGA_SRAM_address;

// For SRAM
logic [17:0] SRAM_address, SRAM_address_prev, SRAM_address_RGB;
logic [15:0] SRAM_read_data, SRAM_write_data;
logic SRAM_ready, SRAM_we_n;

// Offsets for memory
logic [17:0] SRAM_Y_offset, SRAM_U_offset, SRAM_V_offset;
logic [17:0] SRAM_RGB_offset;

// RGB Registers
logic [7:0] R_even, R_odd, G_even, G_odd, B_even, B_odd;

// Buffers
logic [15:0] Y_buf, U_buf, V_buf, Y, U_prime_even, U_prime_odd, V_prime_even, V_prime_odd;

// Multiplier 1
logic [31:0] Mult_op_1_1, Mult_op_2_1, Mult_result_1;
logic [63:0] Mult_result_long_1;

// Multiplier 2
logic [31:0] Mult_op_1_2, Mult_op_2_2, Mult_result_2;
logic [63:0] Mult_result_long_2;

// Accumulation unit
logic [31:0] U_accumulator, V_accumulator;
logic [31:0] R_accumulator_even, G_accumulator_even, B_accumulator_even;
logic [31:0] R_accumulator_odd, G_accumulator_odd, B_accumulator_odd;

// Flags
logic isUBuffered, isVBuffered, fromLeadIn;

// Registers for CSC
logic [15:0] U_plus_5, U_plus_3, U_plus_1, U_minus_1, U_minus_3, U_minus_5;
logic [15:0] V_plus_5, V_plus_3, V_plus_1, V_minus_1, V_minus_3, V_minus_5;

// For UART SRAM interface
logic UART_rx_enable;
logic UART_rx_initialize;
logic [17:0] UART_SRAM_address;
logic [15:0] UART_SRAM_write_data;
logic UART_SRAM_we_n;
logic [25:0] UART_timer;

logic [6:0] value_7_segment [7:0];

// For error detection in UART
logic Frame_error;

// For disabling UART transmit
assign UART_TX_O = 1'b1;

assign resetn = ~SWITCH_I[17] && SRAM_ready;

// Push Button unit
PB_controller PB_unit (
	.Clock_50(CLOCK_50_I),
	.Resetn(resetn),
	.PB_signal(PUSH_BUTTON_N_I),	
	.PB_pushed(PB_pushed)
);

VGA_SRAM_interface VGA_unit (
	.Clock(CLOCK_50_I),
	.Resetn(resetn),
	.VGA_enable(VGA_enable),
   
	// For accessing SRAM
	.SRAM_base_address(VGA_base_address),
	.SRAM_address(VGA_SRAM_address),
	.SRAM_read_data(SRAM_read_data),
   
	// To VGA pins
	.VGA_CLOCK_O(VGA_CLOCK_O),
	.VGA_HSYNC_O(VGA_HSYNC_O),
	.VGA_VSYNC_O(VGA_VSYNC_O),
	.VGA_BLANK_O(VGA_BLANK_O),
	.VGA_SYNC_O(VGA_SYNC_O),
	.VGA_RED_O(VGA_RED_O),
	.VGA_GREEN_O(VGA_GREEN_O),
	.VGA_BLUE_O(VGA_BLUE_O)
);

// UART SRAM interface
UART_SRAM_interface UART_unit(
	.Clock(CLOCK_50_I),
	.Resetn(resetn), 
   
	.UART_RX_I(UART_RX_I),
	.Initialize(UART_rx_initialize),
	.Enable(UART_rx_enable),
   
	// For accessing SRAM
	.SRAM_address(UART_SRAM_address),
	.SRAM_write_data(UART_SRAM_write_data),
	.SRAM_we_n(UART_SRAM_we_n),
	.Frame_error(Frame_error)
);

// SRAM unit
SRAM_controller SRAM_unit (
	.Clock_50(CLOCK_50_I),
	.Resetn(~SWITCH_I[17]),
	.SRAM_address(SRAM_address),
	.SRAM_write_data(SRAM_write_data),
	.SRAM_we_n(SRAM_we_n),
	.SRAM_read_data(SRAM_read_data),		
	.SRAM_ready(SRAM_ready),
		
	// To the SRAM pins
	.SRAM_DATA_IO(SRAM_DATA_IO),
	.SRAM_ADDRESS_O(SRAM_ADDRESS_O[17:0]),
	.SRAM_UB_N_O(SRAM_UB_N_O),
	.SRAM_LB_N_O(SRAM_LB_N_O),
	.SRAM_WE_N_O(SRAM_WE_N_O),
	.SRAM_CE_N_O(SRAM_CE_N_O),
	.SRAM_OE_N_O(SRAM_OE_N_O)
);

assign SRAM_ADDRESS_O[19:18] = 2'b00;

assign SRAM_Y_offset = 18'd0;
assign SRAM_U_offset = 18'd38400;
assign SRAM_V_offset = 18'd57600;
assign SRAM_RGB_offset = 18'd146944;

// Multiplier 1
assign Mult_result_long_1 = Mult_op_1_1 * Mult_op_2_1;
assign Mult_result_1 = Mult_result_long_1[31:0];

// Multiplier 2
assign Mult_result_long_2 = Mult_op_1_2 * Mult_op_2_2;
assign Mult_result_2 = Mult_result_long_2[31:0];

always @(posedge CLOCK_50_I or negedge resetn) begin
	if (~resetn) begin
		top_state <= S_IDLE;
		
		UART_rx_initialize <= 1'b0;
		UART_rx_enable <= 1'b0;
		UART_timer <= 26'd0;
		
		SRAM_address_prev <= 18'd0;
		SRAM_address_RGB <= 18'd0;
		
		isUBuffered <= 1'b0;
		isVBuffered <= 1'b0;
		
		VGA_enable <= 1'b1;
	end else begin

		// By default the UART timer (used for timeout detection) is incremented
		// it will be synchronously reset to 0 under a few conditions (see below)
		UART_timer <= UART_timer + 26'd1;

		case (top_state)
		S_IDLE: begin
			VGA_enable <= 1'b1;  
			if (~UART_RX_I) begin
				// Start bit on the UART line is detected
				UART_rx_initialize <= 1'b1;
				UART_timer <= 26'd0;
				VGA_enable <= 1'b0;
				top_state <= S_UART_RX;
			end
		end

		S_UART_RX: begin
			// The two signals below (UART_rx_initialize/enable)
			// are used by the UART to SRAM interface for 
			// synchronization purposes (no need to change)
			UART_rx_initialize <= 1'b0;
			UART_rx_enable <= 1'b0;
			if (UART_rx_initialize == 1'b1) 
				UART_rx_enable <= 1'b1;

			// UART timer resets itself every time two bytes have been received
			// by the UART receiver and a write in the external SRAM can be done
			if (~UART_SRAM_we_n) 
				UART_timer <= 26'd0;

			// Timeout for 1 sec on UART (detect if file transmission is finished)
			if (UART_timer == 26'd49999999) begin
				VGA_SRAM_address <= SRAM_Y_offset + SRAM_address_prev;
				top_state <= S_LEAD_IN_0;
				UART_timer <= 26'd0;
			end
		end
		
		S_LEAD_IN_0: begin
		
			fromLeadIn <= 1'd1;
		
			VGA_SRAM_address <= SRAM_U_offset + SRAM_address_prev;
			
			top_state <= S_LEAD_IN_1;
		
		end
		
		S_LEAD_IN_1: begin
		
			VGA_SRAM_address <= SRAM_V_offset + SRAM_address_prev;
			
			SRAM_address_prev <= SRAM_address_prev + 1;
			
			top_state <= S_LEAD_IN_2;
		
		end
		
		S_LEAD_IN_2: begin
		
			VGA_SRAM_address <= SRAM_U_offset + SRAM_address_prev;
		
			top_state <= S_LEAD_IN_3;
		
		end
		
		S_LEAD_IN_3: begin
		
			VGA_SRAM_address <= SRAM_V_offset + SRAM_address_prev;
			
			Y <= SRAM_read_data[15:8];
			
			Y_buf <= SRAM_read_data[7:0];
		
			top_state <= S_LEAD_IN_4;
		
		end
		
		S_LEAD_IN_4: begin
		
			U_minus_5 <= SRAM_read_data[15:8];
			U_minus_3 <= SRAM_read_data[15:8];
			U_minus_1 <= SRAM_read_data[15:8];
			U_plus_1 <= SRAM_read_data[7:0];
		
			top_state <= S_LEAD_IN_5;
		
		end
		
		S_LEAD_IN_5: begin
		
			V_minus_5 <= SRAM_read_data[15:8];
			V_minus_3 <= SRAM_read_data[15:8];
			V_minus_1 <= SRAM_read_data[15:8];
			V_plus_1 <= SRAM_read_data[7:0];
		
			top_state <= S_LEAD_IN_6;
		
		end
		
		S_LEAD_IN_6: begin
		
			U_plus_3 <= SRAM_read_data[15:8];
			U_plus_5 <= SRAM_read_data[7:0];
		
			top_state <= S_LEAD_IN_7;
		
		end
		
		S_LEAD_IN_7: begin
		
			V_plus_3 <= SRAM_read_data[15:8];
			V_plus_5 <= SRAM_read_data[7:0];
			
			Mult_op_1_1 <= 159;
			
			Mult_op_1_2 <= (U_minus_1 + U_plus_1);
			
			Mult_op_2_1 <= 159;
			
			Mult_op_2_2 <= (V_minus_1 + V_plus_1);
		
			top_state <= S_CSC_US_CC_0;
		
		end
		
		///////////////////////// COMMON CASE STATES /////////////////////////
		
		// Current problems:
		// Read and write states are overlapping ?
		// Most states dont transition into the next state properly - No lead out
		// No clipping
		// Read in lead in is wrong
		// top_state variable is fucked
		// 
	
		
		S_CSC_US_CC_0: begin
		
			if (~fromLeadIn) begin
			
				VGA_SRAM_address <= SRAM_RGB_offset + SRAM_address_RGB;
				
				SRAM_address_RGB <= SRAM_address_RGB + 1;
			
				UART_SRAM_write_data <= {B_even, R_odd};
				
				UART_SRAM_we_n <= 1'd1;
				
			end
		
			U_accumulator <= Mult_result_1 + 128;
			
			V_accumulator <= Mult_result_2 + 128;
			
			Mult_op_1_1 <= 52;
			
			Mult_op_1_2 <= (U_minus_3 + U_plus_3);
			
			Mult_op_2_1 <= 52;
			
			Mult_op_2_2 <= (V_minus_3 + V_plus_3);
			
			top_state <= S_CSC_US_CC_1;
			
		end
		
		S_CSC_US_CC_1: begin
		
			if (~fromLeadIn) begin
			
				VGA_SRAM_address <= SRAM_RGB_offset + SRAM_address_RGB;
				
				SRAM_address_RGB <= SRAM_address_RGB + 1;
			
				UART_SRAM_write_data <= {G_odd, B_odd};
				
				UART_SRAM_we_n <= 1'd0;
				
			end else begin
			
				fromLeadIn <= 1'd0;
				
			end
			
			U_accumulator <= U_accumulator - Mult_result_1;
			
			V_accumulator <= V_accumulator - Mult_result_2;
			
			Mult_op_1_1 <= 21;
			
			Mult_op_1_2 <= (U_minus_5 + U_plus_5);
			
			Mult_op_2_1 <= 21;
			
			Mult_op_2_2 <= (V_minus_5 + V_plus_5);
			
			top_state <= S_CSC_US_CC_2;
		
		end
		
		S_CSC_US_CC_2: begin
				
			VGA_SRAM_address <= SRAM_Y_offset + SRAM_address_prev;
		
			U_accumulator <= U_accumulator + Mult_result_1;
			
			V_accumulator <= V_accumulator + Mult_result_2;
			
			Mult_op_1_1 <= 76284;
			
			Mult_op_1_2 <= Y - 16;
			
			Mult_op_2_1 <= 76284;
			
			Mult_op_2_2 <= Y_buf - 16;
			
			top_state <= S_CSC_US_CC_3;
		
		end
		
		S_CSC_US_CC_3: begin
		
			// forgot divide by 65536
		
			VGA_SRAM_address <= SRAM_U_offset + SRAM_address_prev;
		
			U_prime_even <= U_minus_1;
				
			V_prime_even <= V_minus_1;
				
			U_prime_odd <= U_accumulator;
				
			V_prime_odd <= V_accumulator;
				
			R_accumulator_even <= Mult_result_1;
			
			G_accumulator_even <= Mult_result_1;
			
			B_accumulator_even <= Mult_result_1;
			
			R_accumulator_odd <= Mult_result_2;
			
			G_accumulator_odd <= Mult_result_2;
			
			B_accumulator_odd <= Mult_result_2;
			
			Mult_op_1_1 <= 104595;
			
			Mult_op_1_2 <= V_prime_even - 128;
			
			Mult_op_2_1 <= 104595;
			
			Mult_op_2_2 <= V_prime_odd - 128;
			
			top_state <= S_CSC_US_CC_4;
		
		end
		
		S_CSC_US_CC_4: begin
		
			VGA_SRAM_address <= SRAM_V_offset + SRAM_address_prev;
		
			R_accumulator_even <= R_accumulator_even + Mult_result_1;
			
			R_accumulator_odd <= R_accumulator_odd + Mult_result_2;
			
			Mult_op_1_1 <= -25624;
			
			Mult_op_1_2 <= U_prime_even - 128;
			
			Mult_op_2_1 <= -25624;
			
			Mult_op_2_2 <= U_prime_odd - 128;
			
			top_state <= S_CSC_US_CC_5;
		
		end
		
		S_CSC_US_CC_5: begin
		
			Y <= SRAM_read_data[15:8];
			Y_buf <= SRAM_read_data[7:0];
		
			//VGA_SRAM_address <= SRAM_Y_offset + SRAM_address_prev;
		
			G_accumulator_even <= G_accumulator_even + Mult_result_1;
			
			G_accumulator_odd <= G_accumulator_odd + Mult_result_2;
			
			Mult_op_1_1 <= -53281;
			
			Mult_op_1_2 <= V_prime_even - 128;
			
			Mult_op_2_1 <= -53281;
			
			Mult_op_2_2 <= V_prime_odd - 128;
			
			R_even <= R_accumulator_even / 65536;
			
			R_odd <= R_accumulator_odd / 65536;
			
			top_state <= S_CSC_US_CC_6;
		
		end
		
		S_CSC_US_CC_6: begin
		
			U_minus_5 <= U_minus_3;
			U_minus_3 <= U_minus_1;
			U_minus_1 <= U_plus_1;
			U_plus_1 <= U_plus_3;
			U_plus_3 <= U_plus_5;
		
			if (~isUBuffered) begin
			
				U_plus_5 <= SRAM_read_data[15:8];
				U_buf <= SRAM_read_data[7:0];
				isUBuffered = ~isUBuffered;
			
			end else begin
			
				U_plus_5 <= U_buf;
				isUBuffered = ~isUBuffered;
			
			end
		
			G_accumulator_even <= R_accumulator_even + Mult_result_1;
			
			G_accumulator_odd <= R_accumulator_odd + Mult_result_2;
			
			Mult_op_1_1 <= 132251;
			
			Mult_op_1_2 <= U_prime_even - 128;
			
			Mult_op_2_1 <= 132251;
			
			Mult_op_2_2 <= U_prime_odd - 128;
			
			top_state <= S_CSC_US_CC_7;
		
		end
		
		S_CSC_US_CC_7: begin
		
			V_minus_5 <= V_minus_3;
			V_minus_3 <= V_minus_1;
			V_minus_1 <= V_plus_1;
			V_plus_1 <= V_plus_3;
			V_plus_3 <= V_plus_5;
		
			if (~isVBuffered) begin
			
				V_plus_5 <= SRAM_read_data[15:8];
				V_buf <= SRAM_read_data[7:0];
				isVBuffered = ~isVBuffered;
			
			end else begin
			
				V_plus_5 <= V_buf;
				isVBuffered = ~isVBuffered;
			
			end
		
			B_accumulator_even <= G_accumulator_even + Mult_result_1;
			
			B_accumulator_odd <= G_accumulator_odd + Mult_result_2;
			
			G_even <= G_accumulator_even / 65536;
			
			G_odd <= G_accumulator_odd / 65536;
			
			top_state <= S_CSC_US_CC_8;
		
		end
		
		S_CSC_US_CC_8: begin
		
			if (~fromLeadIn) begin
			
				VGA_SRAM_address <= SRAM_RGB_offset + SRAM_address_RGB;
				
				SRAM_address_RGB <= SRAM_address_RGB + 1;
				
				UART_SRAM_write_data <= {R_even, G_even};
				
				UART_SRAM_we_n <= 1'd1;
				
			end
		
			B_even <= B_accumulator_even / 65536;
			
			B_odd <= B_accumulator_odd / 65536;
			
			Mult_op_1_1 <= 159;
			
			Mult_op_1_2 <= (U_minus_1 + U_plus_1);
			
			Mult_op_2_1 <= 159;
			
			Mult_op_2_2 <= (V_minus_1 + V_plus_1);
			
			top_state <= S_CSC_US_CC_0;
		
		end

		default: top_state <= S_IDLE;

		endcase
	end
end

// for this design we assume that the RGB data starts at location 0 in the external SRAM
// if the memory layout is different, this value should be adjusted 
// to match the starting address of the raw RGB data segment
assign VGA_base_address = 18'd0;

// Give access to SRAM for UART and VGA at appropriate time
assign SRAM_address = (top_state == S_UART_RX) ? UART_SRAM_address : VGA_SRAM_address;

assign SRAM_write_data = (top_state == S_UART_RX) ? UART_SRAM_write_data : 16'd0;

assign SRAM_we_n = (top_state == S_UART_RX) ? UART_SRAM_we_n : 1'b1;

// 7 segment displays
convert_hex_to_seven_segment unit7 (
	.hex_value(SRAM_read_data[15:12]), 
	.converted_value(value_7_segment[7])
);

convert_hex_to_seven_segment unit6 (
	.hex_value(SRAM_read_data[11:8]), 
	.converted_value(value_7_segment[6])
);

convert_hex_to_seven_segment unit5 (
	.hex_value(SRAM_read_data[7:4]), 
	.converted_value(value_7_segment[5])
);

convert_hex_to_seven_segment unit4 (
	.hex_value(SRAM_read_data[3:0]), 
	.converted_value(value_7_segment[4])
);

convert_hex_to_seven_segment unit3 (
	.hex_value({2'b00, SRAM_address[17:16]}), 
	.converted_value(value_7_segment[3])
);

convert_hex_to_seven_segment unit2 (
	.hex_value(SRAM_address[15:12]), 
	.converted_value(value_7_segment[2])
);

convert_hex_to_seven_segment unit1 (
	.hex_value(SRAM_address[11:8]), 
	.converted_value(value_7_segment[1])
);

convert_hex_to_seven_segment unit0 (
	.hex_value(SRAM_address[7:4]), 
	.converted_value(value_7_segment[0])
);

assign   
   SEVEN_SEGMENT_N_O[0] = value_7_segment[0],
   SEVEN_SEGMENT_N_O[1] = value_7_segment[1],
   SEVEN_SEGMENT_N_O[2] = value_7_segment[2],
   SEVEN_SEGMENT_N_O[3] = value_7_segment[3],
   SEVEN_SEGMENT_N_O[4] = value_7_segment[4],
   SEVEN_SEGMENT_N_O[5] = value_7_segment[5],
   SEVEN_SEGMENT_N_O[6] = value_7_segment[6],
   SEVEN_SEGMENT_N_O[7] = value_7_segment[7];

assign LED_GREEN_O = {resetn, VGA_enable, ~SRAM_we_n, Frame_error, UART_rx_initialize, PB_pushed};

endmodule
