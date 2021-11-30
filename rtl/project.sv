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

		// Board Clocks (50 MHz)
		input logic CLOCK_50_I,

		// Push Buttons / Switches
		input logic[3:0] PUSH_BUTTON_N_I,
		input logic[17:0] SWITCH_I,

		// 7 Segment Display / LEDs
		output logic[6:0] SEVEN_SEGMENT_N_O[7:0],
		output logic[8:0] LED_GREEN_O,

		// VGA Interface
		output logic VGA_CLOCK_O,
		output logic VGA_HSYNC_O,
		output logic VGA_VSYNC_O,
		output logic VGA_BLANK_O,
		output logic VGA_SYNC_O,
		output logic[7:0] VGA_RED_O,
		output logic[7:0] VGA_GREEN_O,
		output logic[7:0] VGA_BLUE_O,
		
		// SRAM Interface
		inout wire[15:0] SRAM_DATA_IO,
		output logic[19:0] SRAM_ADDRESS_O,
		output logic SRAM_UB_N_O,
		output logic SRAM_LB_N_O,
		output logic SRAM_WE_N_O,
		output logic SRAM_CE_N_O,
		output logic SRAM_OE_N_O,
		
		// UART
		input logic UART_RX_I,
		output logic UART_TX_O
);

///////////////////////////////////////////////////////
//                                                   //
//               MISCALANEOUS VARIABLES              //
//                                                   //
///////////////////////////////////////////////////////

// Reset Switch
logic resetn;

// Enumerated States
top_state_type top_state;
milestone_1_state_type m1_state;
milestone_2_state_type m2_state;

// For Push button
logic [3:0] PB_pushed;

// For VGA SRAM interface
logic VGA_enable;
logic [17:0] VGA_base_address;
logic [17:0] VGA_SRAM_address;

// For SRAM
logic [17:0] SRAM_address;
logic [15:0] SRAM_read_data, SRAM_write_data;
logic SRAM_ready, SRAM_we_n;

// For UART SRAM interface
logic UART_rx_enable;
logic UART_rx_initialize;
logic [17:0] UART_SRAM_address;
logic [15:0] UART_SRAM_write_data;
logic [25:0] UART_timer;
logic UART_SRAM_we_n;

// 7 Segment Display
logic [6:0] value_7_segment [7:0];

// For error detection in UART
logic Frame_error;

// For disabling UART transmit
assign UART_TX_O = 1'b1;

// Assign ResetN
assign resetn = ~SWITCH_I[17] && SRAM_ready;

///////////////////////////////////////////////////////
//                                                   //
//               MILESTONE 1 VARIABLES               //
//                                                   //
///////////////////////////////////////////////////////

// SRAM Related
logic [17:0] SRAM_address_M1, SRAM_address_Y, SRAM_address_UV, SRAM_address_RGB;
logic [15:0] SRAM_write_data_M1;
logic SRAM_we_n_M1;

// M1 Memory Offsets
logic [17:0] SRAM_RGB_offset, SRAM_Y_offset, SRAM_U_offset, SRAM_V_offset;

// RGB Registers
logic [7:0] R_even, R_odd, G_even, G_odd, B_even, B_odd;

// Buffers
logic [31:0] Y, Y_buf, U_buf, V_buf;

// Int (32 bits signed)
int U_prime_even, U_prime_odd;
int V_prime_even, V_prime_odd;

// Multiplier 1
logic [31:0] Mult_op_1_1, Mult_op_1_2, Mult_result_1;
logic [63:0] Mult_result_long_1;

// Multiplier 2
logic [31:0] Mult_op_2_1, Mult_op_2_2, Mult_result_2;
logic [63:0] Mult_result_long_2;

// Accumulators
int U_accumulator, V_accumulator;
int R_accumulator_even, G_accumulator_even, B_accumulator_even;
int R_accumulator_odd, G_accumulator_odd, B_accumulator_odd;

// Flags
logic isUBuffered, isVBuffered, Milestone_1_finished;
logic [15:0] pixel_row_number, pixel_column_number;
logic [3:0] timesLeadOut;

// Registers for CSC
logic [7:0] U_plus_5, U_plus_3, U_plus_1, U_minus_1, U_minus_3, U_minus_5;
logic [7:0] V_plus_5, V_plus_3, V_plus_1, V_minus_1, V_minus_3, V_minus_5;

///////////////////////////////////////////////////////
//                                                   //
//               MILESTONE 2 VARIABLES               //
//                                                   //
///////////////////////////////////////////////////////

// SRAM Related
logic [17:0] SRAM_address_M2, SRAM_address_write_M2;
logic [15:0] SRAM_write_data_M2;
logic SRAM_we_n_M2;

// M2 Memory Offsets
logic [17:0] SRAM_pre_IDCT_offset, SC_base_address;

// For RAM
logic [6:0] RAM_address_prev, RAM_address_sample, RAM_address_C, RAM_address_T;
logic [6:0] RAM_address_a_0, RAM_address_b_0;
logic [6:0] RAM_address_a_1, RAM_address_b_1;
logic [6:0] RAM_address_a_2, RAM_address_b_2;
logic [31:0] RAM_write_data_a_0, RAM_write_data_b_0;
logic [31:0] RAM_write_data_a_1, RAM_write_data_b_1;
logic [31:0] RAM_write_data_a_2, RAM_write_data_b_2;
logic signed [31:0] RAM_read_data_a_0, RAM_read_data_b_0;
logic signed [31:0] RAM_read_data_a_1, RAM_read_data_b_1;
logic signed [31:0] RAM_read_data_a_2, RAM_read_data_b_2;
logic RAM_we_n_a_0, RAM_we_n_b_0;
logic RAM_we_n_a_1, RAM_we_n_b_1;
logic RAM_we_n_a_2, RAM_we_n_b_2;

// M2 Address Generation
logic [17:0] M2_address_generation;
logic [5:0] M2_sample_counter, M2_SC;
logic [2:0] M2_row_address, M2_col_address;
logic [5:0] M2_row_index, M2_col_index;
logic [5:0] M2_row_write, M2_col_write;

// M2 Fetch S
logic [31:0] S_prime_0, S_prime_1;

// Multiplier 3
logic signed [31:0] Mult_op_3_1, Mult_op_3_2, Mult_result_3;
logic signed [63:0] Mult_result_long_3;

// Multiplier 4
logic signed [31:0] Mult_op_4_1, Mult_op_4_2, Mult_result_4;
logic signed [63:0] Mult_result_long_4;

// Multiplier 5
logic signed [31:0] Mult_op_5_1, Mult_op_5_2, Mult_result_5;
logic signed [63:0] Mult_result_long_5;

// M2 Accumulators
logic signed [31:0] colAccum_1, colAccum_2, colAccum_3;
logic signed [31:0] col_0_accum, col_1_accum, col_2_accum, col_3_accum;
logic signed [31:0] col_4_accum, col_5_accum, col_6_accum, col_7_accum;

// M2 Buffers
logic signed [15:0] S_prime_buf, CT_buf;
logic [15:0] S_buf_1, S_buf_2, S_buf_3, S_buf_4;
logic signed [31:0] T_buf_1, T_buf_2, T_buf_3, S_write_buf;

// Flags
logic [5:0] calculationsPerformed;
logic sampleCounterEnabled, isFinishedBlock, finBlockHold, isSPrimeBuffered, isTFilled, isSValueToWrite, isTValueToWrite, fetchedSPrime, isFinishedWritingSPrime, Milestone_2_finished;
logic isYBlockFinished, isUBlockFinished, isVBlockFinished, switchAddrGen;

///////////////////////////////////////////////////////
//                                                   //
//               MODULE INSTANTIATION                //
//                                                   //
///////////////////////////////////////////////////////

// Push Button unit
PB_controller PB_unit (
	.Clock_50(CLOCK_50_I),
	.Resetn(resetn),
	.PB_signal(PUSH_BUTTON_N_I),	
	.PB_pushed(PB_pushed)
);

// VGA Interface
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

// RAM0: Holds S', T and S
dual_port_0 RAM0 (
	.address_a(RAM_address_a_0),
	.address_b(RAM_address_b_0),
	.clock(CLOCK_50_I),
	.data_a(RAM_write_data_a_0),
	.data_b(RAM_write_data_b_0),
	.wren_a(RAM_we_n_a_0),
	.wren_b(RAM_we_n_b_0),
	.q_a(RAM_read_data_a_0),
	.q_b(RAM_read_data_b_0)
	);

// RAM1: Holds C
dual_port_1 RAM1 (
	.address_a(RAM_address_a_1),
	.address_b(RAM_address_b_1),
	.clock(CLOCK_50_I),
	.data_a(RAM_write_data_a_1),
	.data_b(RAM_write_data_b_1),
	.wren_a(RAM_we_n_a_1),
	.wren_b(RAM_we_n_b_1),
	.q_a(RAM_read_data_a_1),
	.q_b(RAM_read_data_b_1)
	);

// RAM2: Holds C Transpose
dual_port_2 RAM2 (
	.address_a(RAM_address_a_2),
	.address_b(RAM_address_b_2),
	.clock(CLOCK_50_I),
	.data_a(RAM_write_data_a_2),
	.data_b(RAM_write_data_b_2),
	.wren_a(RAM_we_n_a_2),
	.wren_b(RAM_we_n_b_2),
	.q_a(RAM_read_data_a_2),
	.q_b(RAM_read_data_b_2)
	);
	
sampleCounter SC (
	.clock(CLOCK_50_I),
	.resetn(~SWITCH_I[17]),
	.enabled(sampleCounterEnabled),
	.colIdx(M2_col_index),
	.rowIdx(M2_row_index),
	.isYFinished(switchAddrGen),
	.baseAddress(SC_base_address),
	.sampleCounter(M2_SC),
	.colAddress(M2_col_address),
	.rowAddress(M2_row_address),
	.addressGen(M2_address_generation),
	.isFinishedBlock(isFinishedBlock)
	);

// Assign SRAM Addresses and Offsets
assign SRAM_ADDRESS_O[19:18] = 2'b00;
assign SRAM_Y_offset = 18'd0;
assign SRAM_U_offset = 18'd38400;
assign SRAM_V_offset = 18'd57600;
assign SRAM_RGB_offset = 18'd146944;
assign SRAM_pre_IDCT_offset = 18'd76800;

// Multiplier 1
assign Mult_result_long_1 = Mult_op_1_1 * Mult_op_1_2;
assign Mult_result_1 = Mult_result_long_1[31:0];

// Multiplier 2
assign Mult_result_long_2 = Mult_op_2_1 * Mult_op_2_2;
assign Mult_result_2 = Mult_result_long_2[31:0];

// Multiplier 3
assign Mult_result_long_3 = Mult_op_3_1 * Mult_op_3_2;
assign Mult_result_3 = Mult_result_long_3[31:0];

// Multiplier 4
assign Mult_result_long_4 = Mult_op_4_1 * Mult_op_4_2;
assign Mult_result_4 = Mult_result_long_4[31:0];

// Multiplier 5
assign Mult_result_long_5 = Mult_op_5_1 * Mult_op_5_2;
assign Mult_result_5 = Mult_result_long_5[31:0];

always @(posedge CLOCK_50_I or negedge resetn) begin

	// Initialize
	if (~resetn) begin
	
		// Set the top state to be S_IDLE
		top_state <= S_IDLE;
		
		// Initialize UART parameters
		UART_rx_initialize <= 1'b0;
		UART_rx_enable <= 1'b0;
		UART_timer <= 26'd0;
		
		// Initialize the SRAM address registers
		SRAM_address_Y <= 18'd0;
		SRAM_address_UV <= 18'd0;
		SRAM_address_RGB <= 18'd0;
		
		// Set M1 flag to 0
		Milestone_1_finished <= 1'd0;
		
		// Set M2 flag to 0
		Milestone_2_finished <= 1'd0;
		
		// Enable VGA
		VGA_enable <= 1'b1;
		
	end else begin

		// By default the UART timer (used for timeout detection) is incremented
		// it will be synchronously reset to 0 under a few conditions (see below)
		UART_timer <= UART_timer + 26'd1;

		case (top_state)
		
		S_IDLE: begin
		
			// Enable VGA
			VGA_enable <= 1'b1;
	
			// Start bit on the UART line is detected
			if (~UART_RX_I) begin
				
				// Set UART RX flag to 1
				UART_rx_initialize <= 1'b1;
				
				// Set UART timer to 0
				UART_timer <= 26'd0;
				
				// Disble VGA
				VGA_enable <= 1'b0;
				
				// Move to UART RX state
				top_state <= S_UART_RX;
				
			end
			
		end

		S_UART_RX: begin
		
			// The two signals below (UART_rx_initialize/enable)
			// are used by the UART to SRAM interface for 
			// synchronization purposes (no need to change)
			UART_rx_initialize <= 1'b0;
			UART_rx_enable <= 1'b0;
			
			if (UART_rx_initialize == 1'b1) begin
			
				UART_rx_enable <= 1'b1;
				
			end
			
			// UART timer resets itself every time two bytes have been received
			// by the UART receiver and a write in the external SRAM can be done
			if (~UART_SRAM_we_n) begin
			
				UART_timer <= 26'd0;
				
			end
			
			// Timeout for 1 sec on UART (detect if file transmission is finished)
			if (UART_timer == 26'd49999999) begin
				
				// If there is a timeout, move to S_MILESTONE_1, S_M1_IDLE
				
				top_state <= S_MILESTONE_2;
				m2_state <= S_M2_IDLE;
				
				UART_timer <= 26'd0;
				
			end
			
		end
		
		S_TRANSITION: begin
		
			if (Milestone_2_finished) begin
			
				top_state <= S_MILESTONE_1;
				m1_state <= S_M1_IDLE;
			
			end
		
		end
		
		S_MILESTONE_1: begin

			case (m1_state)
			
			S_M1_IDLE: begin
				
				if (Milestone_1_finished) begin
				
					// If Milestone_1_finished flag is 1 then move back to S_IDLE
					top_state <= S_IDLE;
					
				end else begin
				
					// Set pixel row flag to 0
					pixel_row_number <= 0;
		
					// Set buffer flags to 0
					isUBuffered <= 1'b0;
					isVBuffered <= 1'b0;
				
					// Move to first lead in state
					m1_state <= S_M1_LEAD_IN_0;
				
				end
				
			end
			
			S_M1_LEAD_IN_0: begin
			
				// Increment pixel row flag
				pixel_row_number <= pixel_row_number + 1;
				
				// Buffer data for the Y portion
				SRAM_address_M1 <= SRAM_Y_offset + SRAM_address_Y;
				
				// Increment the Y address
				SRAM_address_Y <= SRAM_address_Y + 1;
				
				// Set the write enable high (READING)
				SRAM_we_n_M1 <= 1'd1;
				
				// Set timesLeadOut flag to 0
				timesLeadOut <= 0;
					
				m1_state <= S_M1_LEAD_IN_1;
			
			end
			
			S_M1_LEAD_IN_1: begin
		
				// Buffer data for the U portion
				SRAM_address_M1 <= SRAM_U_offset + SRAM_address_UV;
				
				m1_state <= S_M1_LEAD_IN_2;
			
			end
			
			S_M1_LEAD_IN_2: begin
			
				// Buffer data for the V portion
				SRAM_address_M1 <= SRAM_V_offset + SRAM_address_UV;
				
				m1_state <= S_M1_LEAD_IN_3;
			
			end
			
			S_M1_LEAD_IN_3: begin
			
				// Buffer data for the U + 1 portion
				SRAM_address_M1 <= SRAM_U_offset + SRAM_address_UV + 1;
			
				// Retrieve the buffered Y data
				Y <= SRAM_read_data[15:8];
				Y_buf <= SRAM_read_data[7:0];
			
				m1_state <= S_M1_LEAD_IN_4;
		
			end
			
			S_M1_LEAD_IN_4: begin
			
				// Buffer data for the V + 1 portion
				SRAM_address_M1 <= SRAM_V_offset + SRAM_address_UV + 1;
				
				// Increment the UV address by 2 so the next value 
				// read in is not the one already in the register
				SRAM_address_UV <= SRAM_address_UV + 2;
				
				// Set the value of the shift registers to the buffered U data (U0U1)
				U_minus_5 <= SRAM_read_data[15:8];
				U_minus_3 <= SRAM_read_data[15:8];
				U_minus_1 <= SRAM_read_data[15:8];
				U_plus_1 <= SRAM_read_data[7:0];
			
				m1_state <= S_M1_LEAD_IN_5;
		
			end
			
			S_M1_LEAD_IN_5: begin
		
				// Set the value of the shift registers to the buffered V data (V0V1)
				V_minus_5 <= SRAM_read_data[15:8];
				V_minus_3 <= SRAM_read_data[15:8];
				V_minus_1 <= SRAM_read_data[15:8];
				V_plus_1 <= SRAM_read_data[7:0];
			
				m1_state <= S_M1_LEAD_IN_6;
			
			end
			
			S_M1_LEAD_IN_6: begin
		
				// Set the value of the shift registers to the buffered U data (U2U3)
				U_plus_3 <= SRAM_read_data[15:8];
				U_plus_5 <= SRAM_read_data[7:0];
				
				// Set pixel column flag to 3
				// The pixel column flag represents the subscript of the U_plus_5
				// register, for example, pixel_column_number = 3 when U_plus_5
				// is equal to U3
				pixel_column_number <= 3;
			
				m1_state <= S_M1_LEAD_IN_7;
			
			end
			
			S_M1_LEAD_IN_7: begin
			
				// Set the value of the shift registers to the buffered V data (V2V3)
				V_plus_3 <= SRAM_read_data[15:8];
				V_plus_5 <= SRAM_read_data[7:0];
				
				// Set the multipliers for the first calculation in upsampling
				Mult_op_1_1 <= 159;
				Mult_op_1_2 <= (U_minus_1 + U_plus_1);
				Mult_op_2_1 <= 159;
				Mult_op_2_2 <= (V_minus_1 + V_plus_1);
			
				m1_state <= S_M1_LEAD_IN_8;
			
			end
			
			S_M1_LEAD_IN_8: begin

				// Set the values of the accumulators to the result + 128
				U_accumulator <= Mult_result_1 + 128;
				V_accumulator <= Mult_result_2 + 128;
				
				// Set the multipliers for the second calculation in upsampling
				Mult_op_1_1 <= 52;
				Mult_op_1_2 <= (U_minus_3 + U_plus_3);
				Mult_op_2_1 <= 52;
				Mult_op_2_2 <= (V_minus_3 + V_plus_3);
				
				m1_state <= S_M1_LEAD_IN_9;
			
			end
			
			S_M1_LEAD_IN_9: begin
			
				// Decrement the accumulator value by the result since the previous multiplication was negative
				U_accumulator <= U_accumulator - Mult_result_1;
				V_accumulator <= V_accumulator - Mult_result_2;
				
				// Set the multipliers for the third calculation in upsampling
				Mult_op_1_1 <= 21;
				Mult_op_1_2 <= (U_minus_5 + U_plus_5);
				Mult_op_2_1 <= 21;
				Mult_op_2_2 <= (V_minus_5 + V_plus_5);
				
				m1_state <= S_M1_LEAD_IN_10;
			
			end
			
			S_M1_LEAD_IN_10: begin
				
				// Buffer data for the Y portion
				SRAM_address_M1 <= SRAM_Y_offset + SRAM_address_Y;
				
				// Increment the Y address
				SRAM_address_Y <= SRAM_address_Y + 1;
			
				// Increment the accumulator value by the result
				U_accumulator <= U_accumulator + Mult_result_1;
				V_accumulator <= V_accumulator + Mult_result_2;
				
				// First matrix multiplication calculation for Y
				if (Y < 16) begin
				
					// Case 1: Y - 16 is less than 0
					// Set the values of the multiplier so only positive multiplication occurs
					Mult_op_1_1 <= 76284;
					Mult_op_1_2 <= 16 - Y;
					
				end else begin
				
					// Case 2: Y - 16 is greater than 0
					// Set the values of the multiplier so only positive multiplication occurs
					Mult_op_1_1 <= 76284;
					Mult_op_1_2 <= Y - 16;
				
				end
				
				// First matrix multiplication calculation for Y_buf
				if (Y_buf < 16) begin
				
					// Case 3: Y_buf - 16 is less than 0
					// Set the values of the multiplier so only positive multiplication occurs
					Mult_op_2_1 <= 76284;
					Mult_op_2_2 <= 16 - Y_buf;
					
				end else begin
				
					// Case 4: Y_buf - 16 is greater than 0
					// Set the values of the multiplier so only positive multiplication occurs
					Mult_op_2_1 <= 76284;
					Mult_op_2_2 <= Y_buf - 16;
					
				end
				
				m1_state <= S_M1_LEAD_IN_11;
			
			end
			
			S_M1_LEAD_IN_11: begin
			
				// Buffer data for the U portion
				SRAM_address_M1 <= SRAM_U_offset + SRAM_address_UV;
			
				// Get even U and V prime
				U_prime_even <= U_minus_1;
				V_prime_even <= V_minus_1;
					
				// Scale by dividing by 256 or 2 ^ 8 bits	
				U_prime_odd <= U_accumulator >>> 8;
				V_prime_odd <= V_accumulator >>> 8;
				
				// Set initial values of RGB_even accumulators				
				if (Y < 16) begin
				
					// Case 1: Y - 16 is less than 0
					R_accumulator_even <= 0 - Mult_result_1;
					G_accumulator_even <= 0 - Mult_result_1;
					B_accumulator_even <= 0 - Mult_result_1;
					
				end else begin
				
					// Case 2: Y - 16 is greater than 0
					R_accumulator_even <= Mult_result_1;
					G_accumulator_even <= Mult_result_1;
					B_accumulator_even <= Mult_result_1;
					
				end
		
				// Set initial values of RGB_even accumulators
				if (Y_buf < 16) begin
				
					// Case 3: Y_buf - 16 is less than 0
					R_accumulator_odd <= 0 - Mult_result_2;
					G_accumulator_odd <= 0 - Mult_result_2;
					B_accumulator_odd <= 0 - Mult_result_2;
					
				end else begin
				
					// Case 4: Y_buf - 16 is greater than 0
					R_accumulator_odd <= Mult_result_2;
					G_accumulator_odd <= Mult_result_2;
					B_accumulator_odd <= Mult_result_2;
					
				end
				
				// Second matrix multiplication calculation for V_even		
				if (V_minus_1 < 128) begin
				
					// Case 1: V_even - 128 is less than 0
					Mult_op_1_1 <= 104595;
					Mult_op_1_2 <= 128 - V_minus_1;
				
				end else begin
				
					// Case 2: V_even - 128 is greater than 0
					Mult_op_1_1 <= 104595;
					Mult_op_1_2 <= V_minus_1 - 128;
				
				end
				
				// Second matrix multiplication calculation for V_odd
				if ((V_accumulator >>> 8) < 128) begin
				
					// Case 3: V_odd - 128 is less than 0
					Mult_op_2_1 <= 104595;
					Mult_op_2_2 <= 128 - (V_accumulator >>> 8);
				
				end else begin
				
					// Case 4: V_odd - 128 is greater than 0
					Mult_op_2_1 <= 104595;
					Mult_op_2_2 <= (V_accumulator >>> 8) - 128;
				
				end
				
				m1_state <= S_M1_LEAD_IN_12;
			
			end
			
			S_M1_LEAD_IN_12: begin
		
				// Buffer data for the V portion
				SRAM_address_M1 <= SRAM_V_offset + SRAM_address_UV;
				
				// Updating the values of the accumulators
				if (V_prime_even < 128) begin
				
					// Case 1: V_even - 128 is less than 0
					R_accumulator_even <= R_accumulator_even - Mult_result_1;
				
				end else begin
				
					// Case 2: V_even - 128 is greater than 0
					R_accumulator_even <= R_accumulator_even + Mult_result_1;
				
				end
				
				// Updating the values of the accumulators
				if (V_prime_odd < 128) begin
				
					// Case 3: V_odd - 128 is less than 0
					R_accumulator_odd <= R_accumulator_odd - Mult_result_2;
					
				end else begin
				
					// Case 4: V_odd - 128 is greater than 0
					R_accumulator_odd <= R_accumulator_odd + Mult_result_2;
					
				end
				
				// Third matrix multiplication calculation for U_even
				if (U_prime_even < 128) begin
				
					// Case 1: U_even - 128 is less than 0
					Mult_op_1_1 <= 25624;
					Mult_op_1_2 <= 128 - U_prime_even;
				
				end else begin
				
					// Case 2: U_even - 128 is greater than 0
					Mult_op_1_1 <= 25624;
					Mult_op_1_2 <= U_prime_even - 128;
				
				end
				
				// Third matrix multiplication calculation for U_odd
				if (U_prime_odd < 128) begin
				
					// Case 3: U_odd - 128 is less than 0
					Mult_op_2_1 <= 25624;
					Mult_op_2_2 <= 128 - U_prime_odd;
				
				end else begin
				
					// Case 4: U_odd - 128 is greater than 0
					Mult_op_2_1 <= 25624;
					Mult_op_2_2 <= U_prime_odd - 128;
				
				end
				
				m1_state <= S_M1_LEAD_IN_13;
			
			end
			
			S_M1_LEAD_IN_13: begin
		
				// Retrieve the buffered Y data
				Y <= SRAM_read_data[15:8];
				Y_buf <= SRAM_read_data[7:0];
				
				// Update the values of the accumulators
				if (U_prime_even < 128) begin
				
					// Case 1: U_even - 128 is less than 0
					// Since the previous calculation includes -25624,
					// if U_even < 128 then the result will be positive
					G_accumulator_even <= G_accumulator_even + Mult_result_1;
				
				end else begin
				
					// Case 2: U_even - 128 is greater than 0
					// Since the previous calculation includes -25624,
					// if U_even > 128 then the result will be negative
					G_accumulator_even <= G_accumulator_even - Mult_result_1;
				
				end
				
				// Update the values of the accumulators
				if (U_prime_odd < 128) begin
				
					// Case 3: U_odd - 128 is less than 0
					// Since the previous calculation includes -25624,
					// if U_odd < 128 then the result will be positive
					G_accumulator_odd <= G_accumulator_odd + Mult_result_2;
					
				end else begin
				
					// Case 4: U_odd - 128 is greater than 0
					// Since the previous calculation includes -25624,
					// if U_odd > 128 then the result will be negative
					G_accumulator_odd <= G_accumulator_odd - Mult_result_2;
				
				end
				
				// Fourth matrix multiplcation for the V_even
				if (V_prime_even < 128) begin
				
					// Case 1: V_even - 128 is less than 0
					Mult_op_1_1 <= 53281;
					Mult_op_1_2 <= 128 - V_prime_even;
				
				end else begin
				
					// Case 2: V_even - 128 is greater than 0
					Mult_op_1_1 <= 53281;
					Mult_op_1_2 <= V_prime_even - 128;
				
				end
				
				// Fourth matrix multiplcation for the V_even
				if (V_prime_odd < 128) begin
				
					// Case 3: V_odd - 128 is less than 0
					Mult_op_2_1 <= 53281;
					Mult_op_2_2 <= 128 - V_prime_odd;
					
				end else begin
				
					// Case 4: V_odd - 128 is greater than 0
					Mult_op_2_1 <= 53281;
					Mult_op_2_2 <= V_prime_odd - 128;
					
				end
				
				// Scale and clip R accumulators
				if (R_accumulator_even[31] == 1'b1) begin
				
					// If the sign bit is equal to 1, then the number is negative, so clip to 0
					R_even <= 0;
					
				end else begin
				
					// If bits 24 to 30 are all 0 then the number is less than 255
					if (R_accumulator_even[30:24] == 7'b0000000) begin
					
						// Take bits 16 to 23, which scales
						R_even <= R_accumulator_even[23:16];
						
					end else begin
					
						// Otherwise clip to 255
						R_even <= 255;
						
					end
					
				end
				
				if (R_accumulator_odd[31] == 1'b1) begin
				
					// If the sign bit is equal to 1, then the number is negative, so clip to 0
					R_odd <= 0;
					
				end else begin
				
					// If bits 24 to 30 are all 0 then the number is less than 255
					if (R_accumulator_odd[30:24] == 7'b0000000) begin
					
						// Take bits 16 to 23, which scales
						R_odd <= R_accumulator_odd[23:16];
						
					end else begin
					
						// Otherwise clip to 255
						R_odd <= 255;
						
					end
					
				end
				
				m1_state <= S_M1_LEAD_IN_14;
			
			end
			
			S_M1_LEAD_IN_14: begin
		
				// Shift the U registers down
				U_minus_5 <= U_minus_3;
				U_minus_3 <= U_minus_1;
				U_minus_1 <= U_plus_1;
				U_plus_1 <= U_plus_3;
				U_plus_3 <= U_plus_5;
				
				// Retrieve the buffered U data
				U_plus_5 <= SRAM_read_data[15:8];
				U_buf <= SRAM_read_data[7:0];
				
				// Set isUBuffered to 1 so we know we don't need to 
				// read new U values until 2 common case cycles
				isUBuffered = 1'd1;
				
				// Update the values of the accumulators				
				if (V_prime_even < 128) begin
				
					// Case 1: V_even - 128 is less than 0
					// Since the previous calculation includes -53281,
					// if V_even < 128 then the result will be positive
					G_accumulator_even <= G_accumulator_even + Mult_result_1;
					
				end else begin
				
					// Case 2: V_even - 128 is greater than 0
					// Since the previous calculation includes -53281,
					// if V_even < 128 then the result will be negative
					G_accumulator_even <= G_accumulator_even - Mult_result_1;
				
				end
				
				// Update the values of the accumulators
				if (V_prime_odd < 128) begin
				
					// Case 3: V_odd - 128 is less than 0
					// Since the previous calculation includes -53281,
					// if V_odd < 128 then the result will be positive
					G_accumulator_odd <= G_accumulator_odd + Mult_result_2;
				
				end else begin
				
					// Case 4: V_odd - 128 is greater than 0
					// Since the previous calculation includes -53281,
					// if V_odd > 128 then the result will be negative
					G_accumulator_odd <= G_accumulator_odd - Mult_result_2;
				
				end
				
				// Fifth matrix multiplcation for U_even			
				if (U_prime_even < 128) begin
				
					// Case 1: U_even - 128 is less than 0
					Mult_op_1_1 <= 132251;
					Mult_op_1_2 <= 128 - U_prime_even;
					
				end else begin
				
					// Case 2: U_even - 128 is greater than 0
					Mult_op_1_1 <= 132251;
					Mult_op_1_2 <= U_prime_even - 128;
				
				end
				
				// Fifth matrix multiplication for U_odd
				if (U_prime_odd < 128) begin
				
					// Case 3: U_odd - 128 is less than 0
					Mult_op_2_1 <= 132251;
					Mult_op_2_2 <= 128 - U_prime_odd;
					
				end else begin
				
					// Case 4: U_odd - 128 is greater than 0
					Mult_op_2_1 <= 132251;
					Mult_op_2_2 <= U_prime_odd - 128;
					
				end
				
				m1_state <= S_M1_LEAD_IN_15;
			
			end
			
			S_M1_LEAD_IN_15: begin
		
				// Shift the V registers down
				V_minus_5 <= V_minus_3;
				V_minus_3 <= V_minus_1;
				V_minus_1 <= V_plus_1;
				V_plus_1 <= V_plus_3;
				V_plus_3 <= V_plus_5;
				
				// Retrieve the buffered V data
				V_plus_5 <= SRAM_read_data[15:8];
				V_buf <= SRAM_read_data[7:0];
				
				// Set isVBuffered to 1 so we know we don't need to 
				// read new V values until 2 common case cycles
				isVBuffered = 1'd1;
				
				// Increment the UV address by 1
				SRAM_address_UV <= SRAM_address_UV + 1;
				
				// Increment pixel column number since the new subscript
				// on the last register has been increased by 1
				pixel_column_number <= pixel_column_number + 1;
				
				// Update the values of the accumulators
				if (U_prime_even < 128) begin
				
					// Case 1: U_even - 128 is less than 0
					B_accumulator_even <= B_accumulator_even - Mult_result_1;
					
				end else begin
			
					// Case 2: U_even - 128 is greater than 0	
					B_accumulator_even <= B_accumulator_even + Mult_result_1;
				
				end
				
				// Update the values of the accumulators
				if (U_prime_odd < 128) begin
				
					// Case 3: U_odd - 128 is less than 0
					B_accumulator_odd <= B_accumulator_odd - Mult_result_2;
					
				end else begin
				
					// Case 4: U_odd - 128 is greater than 0
					B_accumulator_odd <= B_accumulator_odd + Mult_result_2;
			
				end
				
				// Scale and clip G accumulators
				if (G_accumulator_even[31] == 1'b1) begin
				
					// If the sign bit is equal to 1, then the number is negative, so clip to 0
					G_even <= 0;
					
				end else begin
				
					// If bits 24 to 30 are all 0 then the number is less than 255
					if (G_accumulator_even[30:24] == 7'b0000000) begin
					
						// Take bits 16 to 23, which scales
						G_even <= G_accumulator_even[23:16];
						
					end else begin
					
						// Otherwise clip to 255
						G_even <= 255;
						
					end
					
				end
				
				if (G_accumulator_odd[31] == 1'b1) begin
				
					// If the sign bit is equal to 1, then the number is negative, so clip to 0
					G_odd <= 0;
					
				end else begin
				
					// If bits 24 to 30 are all 0 then the number is less than 255
					if (G_accumulator_odd[30:24] == 7'b0000000) begin
					
						// Take bits 16 to 23, which scales
						G_odd <= G_accumulator_odd[23:16];
						
					end else begin
					
						// Otherwise clip to 255
						G_odd <= 255;
						
					end
					
				end
				
				m1_state <= S_M1_LEAD_IN_16;
			
			end
			
			S_M1_LEAD_IN_16: begin
		
				// Scale and clip B accumulators
				if (B_accumulator_even[31] == 1'b1) begin
				
					// If the sign bit is equal to 1, then the number is negative, so clip to 0
					B_even <= 0;
					
				end else begin
				
					// If bits 24 to 30 are all 0 then the number is less than 255
					if (B_accumulator_even[30:24] == 7'b0000000) begin
					
						// Take bits 16 to 23, which scales
						B_even <= B_accumulator_even[23:16];
						
					end else begin
					
						// Otherwise clip to 255
						B_even <= 255;
						
					end
					
				end
				
				if (B_accumulator_odd[31] == 1'b1) begin
				
					// If the sign bit is equal to 1, then the number is negative, so clip to 0
					B_odd <= 0;
					
				end else begin
				
					// If bits 24 to 30 are all 0 then the number is less than 255
					if (B_accumulator_odd[30:24] == 7'b0000000) begin
					
						// Take bits 16 to 23, which scales
						B_odd <= B_accumulator_odd[23:16];
						
					end else begin
					
						// Otherwise clip to 255
						B_odd <= 255;
						
					end
					
				end
				
				m1_state <= S_M1_LEAD_IN_17;
			
			end
			
			S_M1_LEAD_IN_17: begin
			
				// Set the address to the current write address
				SRAM_address_M1 <= SRAM_RGB_offset + SRAM_address_RGB;
				
				// Increment RGB address every time we write
				SRAM_address_RGB <= SRAM_address_RGB + 1;
				
				// Write R_even and G_even
				SRAM_write_data_M1 <= {R_even, G_even};
					
				// Set write enable low (active low)
				SRAM_we_n_M1 <= 1'd0;
				
				// Set the multipliers for the first calculation in upsampling
				Mult_op_1_1 <= 159;
				Mult_op_1_2 <= (U_minus_1 + U_plus_1);
				Mult_op_2_1 <= 159;
				Mult_op_2_2 <= (V_minus_1 + V_plus_1);
				
				m1_state <= S_M1_CSC_US_CC_0;
				
			end
			
			///////////////////////// COMMON CASE STATES /////////////////////////
		
			// Current problems:
			
			//////////////////////////////////////////////////////////////////////
			
			S_M1_CSC_US_CC_0: begin
				
				// Set the address to the current write address
				SRAM_address_M1 <= SRAM_RGB_offset + SRAM_address_RGB;
				
				// Increment RGB address every time we write
				SRAM_address_RGB <= SRAM_address_RGB + 1;
				
				// Write B_even and R_odd
				SRAM_write_data_M1 <= {B_even, R_odd};
					
				// Set write enable low (active low)
				SRAM_we_n_M1 <= 1'd0;
					
				// Set the values of the accumulators to the result + 128
				U_accumulator <= Mult_result_1 + 128;
				V_accumulator <= Mult_result_2 + 128;
				
				// Set the multipliers for the second calculation in upsampling
				Mult_op_1_1 <= 52;
				Mult_op_1_2 <= (U_minus_3 + U_plus_3);
				Mult_op_2_1 <= 52;
				Mult_op_2_2 <= (V_minus_3 + V_plus_3);
				
				m1_state <= S_M1_CSC_US_CC_1;
				
			end
			
			S_M1_CSC_US_CC_1: begin
		
				// Set the address to the current write address
				SRAM_address_M1 <= SRAM_RGB_offset + SRAM_address_RGB;
				
				// Increment RGB address every time we write
				SRAM_address_RGB <= SRAM_address_RGB + 1;
				
				// Write G_odd and B_odd
				SRAM_write_data_M1 <= {G_odd, B_odd};
				
				// Set write enable low (active low)
				SRAM_we_n_M1 <= 1'd0;
				
				// Decrement the accumulator value by the result since the previous multiplication was negative
				U_accumulator <= U_accumulator - Mult_result_1;
				V_accumulator <= V_accumulator - Mult_result_2;
				
				// Set the multipliers for the third calculation in upsampling
				Mult_op_1_1 <= 21;
				Mult_op_1_2 <= (U_minus_5 + U_plus_5);
				Mult_op_2_1 <= 21;
				Mult_op_2_2 <= (V_minus_5 + V_plus_5);
				
				m1_state <= S_M1_CSC_US_CC_2;
			
			end
			
			S_M1_CSC_US_CC_2: begin
				
				// Buffer data for the Y portion
				SRAM_address_M1 <= SRAM_Y_offset + SRAM_address_Y;
				
				// Increment the Y address
				SRAM_address_Y <= SRAM_address_Y + 1;
				
				// Set write enable high (active low)
				SRAM_we_n_M1 <= 1'd1;
			
				// Increment the accumulator value by the result
				U_accumulator <= U_accumulator + Mult_result_1;
				V_accumulator <= V_accumulator + Mult_result_2;
				
				// First matrix multiplication calculation for Y				
				if (Y < 16) begin
				
					// Case 1: Y - 16 is less than 0
					// Set the values of the multiplier so only positive multiplication occurs
					Mult_op_1_1 <= 76284;
					Mult_op_1_2 <= 16 - Y;
					
				end else begin
				
					// Case 2: Y - 16 is greater than 0
					// Set the values of the multiplier so only positive multiplication occurs
					Mult_op_1_1 <= 76284;
					Mult_op_1_2 <= Y - 16;
				
				end
				
				// First matrix multiplication calculation for Y_buf
				if (Y_buf < 16) begin
				
					// Case 3: Y_buf - 16 is less than 0
					// Set the values of the multiplier so only positive multiplication occurs
					Mult_op_2_1 <= 76284;
					Mult_op_2_2 <= 16 - Y_buf;
					
				end else begin
				
					// Case 4: Y_buf - 16 is greater than 0
					// Set the values of the multiplier so only positive multiplication occurs
					Mult_op_2_1 <= 76284;
					Mult_op_2_2 <= Y_buf - 16;
					
				end
				
				// If the end of the row is reached then move to lead out states
				if (pixel_column_number == 159) begin
				
					m1_state <= S_M1_LEAD_OUT_0;
					
				end else begin
				
					m1_state <= S_M1_CSC_US_CC_3;
					
				end

			end
			
			S_M1_CSC_US_CC_3: begin
			
				if (~isUBuffered) begin
				
					// Only buffer data for the U portion if there is not already data buffered
					SRAM_address_M1 <= SRAM_U_offset + SRAM_address_UV;
			
				end
			
				// Get even U and V prime
				U_prime_even <= U_minus_1;
				V_prime_even <= V_minus_1;
					
				// Scale by dividing by 256 or 2 ^ 8 bits	
				U_prime_odd <= U_accumulator >>> 8;
				V_prime_odd <= V_accumulator >>> 8;
				
				// Set initial values of RGB accumulators
				
				// Y Accumulator
				
				// Case 1: Y - 16 is less than 0
				
				// Set initial values of RGB_even accumulators				
				if (Y < 16) begin
				
					// Case 1: Y - 16 is less than 0
					R_accumulator_even <= 0 - Mult_result_1;
					G_accumulator_even <= 0 - Mult_result_1;
					B_accumulator_even <= 0 - Mult_result_1;
					
				end else begin
				
					// Case 2: Y - 16 is greater than 0
					R_accumulator_even <= Mult_result_1;
					G_accumulator_even <= Mult_result_1;
					B_accumulator_even <= Mult_result_1;
					
				end
				
				// Set initial values of RGB_even accumulators
				if (Y_buf < 16) begin
				
					// Case 3: Y_buf - 16 is less than 0
					R_accumulator_odd <= 0 - Mult_result_2;
					G_accumulator_odd <= 0 - Mult_result_2;
					B_accumulator_odd <= 0 - Mult_result_2;
					
				end else begin
				
					// Case 4: Y_buf - 16 is greater than 0
					R_accumulator_odd <= Mult_result_2;
					G_accumulator_odd <= Mult_result_2;
					B_accumulator_odd <= Mult_result_2;
					
				end
				
				// Second matrix multiplication calculation for V_even		
				if (V_minus_1 < 128) begin
				
					// Case 1: V_even - 128 is less than 0
					Mult_op_1_1 <= 104595;
					Mult_op_1_2 <= 128 - V_minus_1;
				
				end else begin
				
					// Case 2: V_even - 128 is greater than 0
					Mult_op_1_1 <= 104595;
					Mult_op_1_2 <= V_minus_1 - 128;
				
				end
				
				// Second matrix multiplication calculation for V_odd
				if ((V_accumulator >>> 8) < 128) begin
				
					// Case 3: V_odd - 128 is less than 0
					Mult_op_2_1 <= 104595;
					Mult_op_2_2 <= 128 - (V_accumulator >>> 8);
				
				end else begin
				
					// Case 4: V_odd - 128 is greater than 0
					Mult_op_2_1 <= 104595;
					Mult_op_2_2 <= (V_accumulator >>> 8) - 128;
				
				end
				
				m1_state <= S_M1_CSC_US_CC_4;
			
			end
			
			S_M1_CSC_US_CC_4: begin
		
				if (~isVBuffered) begin
		
					// Only buffer data for the V portion if there is not already data buffered
					SRAM_address_M1 <= SRAM_V_offset + SRAM_address_UV;
				
				end
				
				// Updating the values of the accumulators
				if (V_prime_even < 128) begin
				
					// Case 1: V_even - 128 is less than 0
					R_accumulator_even <= R_accumulator_even - Mult_result_1;
				
				end else begin
				
					// Case 2: V_even - 128 is greater than 0
					R_accumulator_even <= R_accumulator_even + Mult_result_1;
				
				end
				
				// Updating the values of the accumulators
				if (V_prime_odd < 128) begin
				
					// Case 3: V_odd - 128 is less than 0
					R_accumulator_odd <= R_accumulator_odd - Mult_result_2;
					
				end else begin
				
					// Case 4: V_odd - 128 is greater than 0
					R_accumulator_odd <= R_accumulator_odd + Mult_result_2;
					
				end
				
				// Third matrix multiplication calculation for U_even
				if (U_prime_even < 128) begin
				
					// Case 1: U_even - 128 is less than 0
					Mult_op_1_1 <= 25624;
					Mult_op_1_2 <= 128 - U_prime_even;
				
				end else begin
				
					// Case 2: U_even - 128 is greater than 0
					Mult_op_1_1 <= 25624;
					Mult_op_1_2 <= U_prime_even - 128;
				
				end
				
				// Third matrix multiplication calculation for U_odd
				if (U_prime_odd < 128) begin
				
					// Case 3: U_odd - 128 is less than 0
					Mult_op_2_1 <= 25624;
					Mult_op_2_2 <= 128 - U_prime_odd;
				
				end else begin
				
					// Case 4: U_odd - 128 is greater than 0
					Mult_op_2_1 <= 25624;
					Mult_op_2_2 <= U_prime_odd - 128;
				
				end
				
				m1_state <= S_M1_CSC_US_CC_5;
			
			end
			
			S_M1_CSC_US_CC_5: begin
		
				// Retrieve the buffered Y data
				Y <= SRAM_read_data[15:8];
				Y_buf <= SRAM_read_data[7:0];
				
				// Update the values of the accumulators
				if (U_prime_even < 128) begin
				
					// Case 1: U_even - 128 is less than 0
					// Since the previous calculation includes -25624,
					// if U_even < 128 then the result will be positive
					G_accumulator_even <= G_accumulator_even + Mult_result_1;
				
				end else begin
				
					// Case 2: U_even - 128 is greater than 0
					// Since the previous calculation includes -25624,
					// if U_even > 128 then the result will be negative
					G_accumulator_even <= G_accumulator_even - Mult_result_1;
				
				end
				
				// Update the values of the accumulators
				if (U_prime_odd < 128) begin
				
					// Case 3: U_odd - 128 is less than 0
					// Since the previous calculation includes -25624,
					// if U_odd < 128 then the result will be positive
					G_accumulator_odd <= G_accumulator_odd + Mult_result_2;
					
				end else begin
				
					// Case 4: U_odd - 128 is greater than 0
					// Since the previous calculation includes -25624,
					// if U_odd > 128 then the result will be negative
					G_accumulator_odd <= G_accumulator_odd - Mult_result_2;
				
				end
				
				// Fourth matrix multiplcation for the V_even
				if (V_prime_even < 128) begin
				
					// Case 1: V_even - 128 is less than 0
					Mult_op_1_1 <= 53281;
					Mult_op_1_2 <= 128 - V_prime_even;
				
				end else begin
				
					// Case 2: V_even - 128 is greater than 0
					Mult_op_1_1 <= 53281;
					Mult_op_1_2 <= V_prime_even - 128;
				
				end
				
				// Fourth matrix multiplcation for the V_even
				if (V_prime_odd < 128) begin
				
					// Case 3: V_odd - 128 is less than 0
					Mult_op_2_1 <= 53281;
					Mult_op_2_2 <= 128 - V_prime_odd;
					
				end else begin
				
					// Case 4: V_odd - 128 is greater than 0
					Mult_op_2_1 <= 53281;
					Mult_op_2_2 <= V_prime_odd - 128;
					
				end
				
				// Scale and clip R accumulators
				if (R_accumulator_even[31] == 1'b1) begin
				
					// If the sign bit is equal to 1, then the number is negative, so clip to 0
					R_even <= 0;
					
				end else begin
				
					// If bits 24 to 30 are all 0 then the number is less than 255
					if (R_accumulator_even[30:24] == 7'b0000000) begin
					
						// Take bits 16 to 23, which scales
						R_even <= R_accumulator_even[23:16];
						
					end else begin
					
						// Otherwise clip to 255
						R_even <= 255;
						
					end
					
				end
				
				if (R_accumulator_odd[31] == 1'b1) begin
				
					// If the sign bit is equal to 1, then the number is negative, so clip to 0
					R_odd <= 0;
					
				end else begin
				
					// If bits 24 to 30 are all 0 then the number is less than 255
					if (R_accumulator_odd[30:24] == 7'b0000000) begin
					
						// Take bits 16 to 23, which scales
						R_odd <= R_accumulator_odd[23:16];
						
					end else begin
					
						// Otherwise clip to 255
						R_odd <= 255;
						
					end
					
				end
				
				m1_state <= S_M1_CSC_US_CC_6;
			
			end
			
			S_M1_CSC_US_CC_6: begin
		
				// Shift the U registers down
				U_minus_5 <= U_minus_3;
				U_minus_3 <= U_minus_1;
				U_minus_1 <= U_plus_1;
				U_plus_1 <= U_plus_3;
				U_plus_3 <= U_plus_5;
			
				if (~isUBuffered) begin
			
					// If U isn't buffered, read the current read_data and set the buffer to hold a value
					U_plus_5 <= SRAM_read_data[15:8];
					U_buf <= SRAM_read_data[7:0];
					
					// Set isUBuffered to its compliment
					isUBuffered = ~isUBuffered;
				
				end else begin
				
					// If there is a buffered value, set U_plus_5 to the buffered value
					U_plus_5 <= U_buf;
					
					// Set U_buf to 0 for clarity purposes (has no impact on calculations)
					U_buf <= 0;
					
					// Set isUBuffered to its compliment
					isUBuffered = ~isUBuffered;
				
				end
				
				// Update the values of the accumulators				
				if (V_prime_even < 128) begin
				
					// Case 1: V_even - 128 is less than 0
					// Since the previous calculation includes -53281,
					// if V_even < 128 then the result will be positive
					G_accumulator_even <= G_accumulator_even + Mult_result_1;
					
				end else begin
				
					// Case 2: V_even - 128 is greater than 0
					// Since the previous calculation includes -53281,
					// if V_even > 128 then the result will be negative
					G_accumulator_even <= G_accumulator_even - Mult_result_1;
				
				end
				
				// Update the values of the accumulators
				if (V_prime_odd < 128) begin
				
					// Case 3: V_odd - 128 is less than 0
					// Since the previous calculation includes -53281,
					// if V_odd < 128 then the result will be positive
					G_accumulator_odd <= G_accumulator_odd + Mult_result_2;
				
				end else begin
				
					// Case 4: V_odd - 128 is greater than 0
					// Since the previous calculation includes -53281,
					// if V_odd > 128 then the result will be negative
					G_accumulator_odd <= G_accumulator_odd - Mult_result_2;
				
				end
				
				// Fifth matrix multiplcation for U_even			
				if (U_prime_even < 128) begin
				
					// Case 1: U_even - 128 is less than 0
					Mult_op_1_1 <= 132251;
					Mult_op_1_2 <= 128 - U_prime_even;
					
				end else begin
				
					// Case 2: U_even - 128 is greater than 0
					Mult_op_1_1 <= 132251;
					Mult_op_1_2 <= U_prime_even - 128;
				
				end
				
				// Fifth matrix multiplication for U_odd
				if (U_prime_odd < 128) begin
				
					// Case 3: U_odd - 128 is less than 0
					Mult_op_2_1 <= 132251;
					Mult_op_2_2 <= 128 - U_prime_odd;
					
				end else begin
				
					// Case 4: U_odd - 128 is greater than 0
					Mult_op_2_1 <= 132251;
					Mult_op_2_2 <= U_prime_odd - 128;
					
				end
				
				m1_state <= S_M1_CSC_US_CC_7;
			
			end
			
			S_M1_CSC_US_CC_7: begin
		
				// Shift the V registers down
				V_minus_5 <= V_minus_3;
				V_minus_3 <= V_minus_1;
				V_minus_1 <= V_plus_1;
				V_plus_1 <= V_plus_3;
				V_plus_3 <= V_plus_5;
			
				if (~isVBuffered) begin
				
					// If V isn't buffered, read the current read_data and set the buffer to hold a value
					V_plus_5 <= SRAM_read_data[15:8];
					V_buf <= SRAM_read_data[7:0];
					
					// Set isVBuffered to its compliment
					isVBuffered = ~isVBuffered;
					
					// Increment the UV address
					SRAM_address_UV <= SRAM_address_UV + 1;
					
				end else begin
				
					// If there is a buffered value, set U_plus_5 to the buffered value
					V_plus_5 <= V_buf;
					
					// Set U_buf to 0 for clarity purposes (has no impact on calculations)
					V_buf <= 0;
					
					// Set isVBuffered to its compliment
					isVBuffered = ~isVBuffered;
				
				end
				
				// Increment pixel column number since the new subscript
				// on the last register has been increased by 1
				pixel_column_number <= pixel_column_number + 1;
				
				// Case 1: U_even - 128 is less than 0
			
				// Update the values of the accumulators
				if (U_prime_even < 128) begin
				
					// Case 1: U_even - 128 is less than 0
					B_accumulator_even <= B_accumulator_even - Mult_result_1;
					
				end else begin
			
					// Case 2: U_even - 128 is greater than 0	
					B_accumulator_even <= B_accumulator_even + Mult_result_1;
				
				end
				
				// Update the values of the accumulators
				if (U_prime_odd < 128) begin
				
					// Case 3: U_odd - 128 is less than 0
					B_accumulator_odd <= B_accumulator_odd - Mult_result_2;
					
				end else begin
				
					// Case 4: U_odd - 128 is greater than 0
					B_accumulator_odd <= B_accumulator_odd + Mult_result_2;
			
				end
				
				// Scale and clip G accumulators
				if (G_accumulator_even[31] == 1'b1) begin
				
					// If the sign bit is equal to 1, then the number is negative, so clip to 0
					G_even <= 0;
					
				end else begin
				
					// If bits 24 to 30 are all 0 then the number is less than 255
					if (G_accumulator_even[30:24] == 7'b0000000) begin
					
						// Take bits 16 to 23, which scales
						G_even <= G_accumulator_even[23:16];
						
					end else begin
					
						// Otherwise clip to 255
						G_even <= 255;
						
					end
					
				end
				
				if (G_accumulator_odd[31] == 1'b1) begin
				
					// If the sign bit is equal to 1, then the number is negative, so clip to 0
					G_odd <= 0;
					
				end else begin
				
					// If bits 24 to 30 are all 0 then the number is less than 255
					if (G_accumulator_odd[30:24] == 7'b0000000) begin
					
						// Take bits 16 to 23, which scales
						G_odd <= G_accumulator_odd[23:16];
						
					end else begin
					
						// Otherwise clip to 255
						G_odd <= 255;
						
					end
					
				end
				
				m1_state <= S_M1_CSC_US_CC_8;
			
			end
			
			S_M1_CSC_US_CC_8: begin
		
				// Set the address to the current write address
				SRAM_address_M1 <= SRAM_RGB_offset + SRAM_address_RGB;
					
				// Increment RGB address every time we write
				SRAM_address_RGB <= SRAM_address_RGB + 1;
					
				// Write R_even and G_even
				SRAM_write_data_M1 <= {R_even, G_even};
				
				// Set write enable low (active low)
				SRAM_we_n_M1 <= 1'd0;
					
				// Scale and clip B accumulators
				if (B_accumulator_even[31] == 1'b1) begin
				
					// If the sign bit is equal to 1, then the number is negative, so clip to 0
					B_even <= 0;
					
				end else begin
				
					// If bits 24 to 30 are all 0 then the number is less than 255
					if (B_accumulator_even[30:24] == 7'b0000000) begin
					
						// Take bits 16 to 23, which scales
						B_even <= B_accumulator_even[23:16];
						
					end else begin
					
						// Otherwise clip to 255
						B_even <= 255;
						
					end
					
				end
				
				if (B_accumulator_odd[31] == 1'b1) begin
				
					// If the sign bit is equal to 1, then the number is negative, so clip to 0
					B_odd <= 0;
					
				end else begin
				
					// If bits 24 to 30 are all 0 then the number is less than 255
					if (B_accumulator_odd[30:24] == 7'b0000000) begin
					
						// Take bits 16 to 23, which scales
						B_odd <= B_accumulator_odd[23:16];
						
					end else begin
					
						// Otherwise clip to 255
						B_odd <= 255;
						
					end
					
				end
			
				// Set the multipliers for the first calculation in upsampling
				Mult_op_1_1 <= 159;
				Mult_op_1_2 <= (U_minus_1 + U_plus_1);
				Mult_op_2_1 <= 159;
				Mult_op_2_2 <= (V_minus_1 + V_plus_1);
				
				m1_state <= S_M1_CSC_US_CC_0;
			
			end
			
			// LEAD OUT
			
			S_M1_LEAD_OUT_0: begin
			
				// Get even U and V prime
				U_prime_even <= U_minus_1;
				V_prime_even <= V_minus_1;
					
				// Scale by dividing by 256 or 2 ^ 8 bits	
				U_prime_odd <= U_accumulator >>> 8;
				V_prime_odd <= V_accumulator >>> 8;
				
				// Set initial values of RGB_even accumulators				
				if (Y < 16) begin
				
					// Case 1: Y - 16 is less than 0
					R_accumulator_even <= 0 - Mult_result_1;
					G_accumulator_even <= 0 - Mult_result_1;
					B_accumulator_even <= 0 - Mult_result_1;
					
				end else begin
				
					// Case 2: Y - 16 is greater than 0
					R_accumulator_even <= Mult_result_1;
					G_accumulator_even <= Mult_result_1;
					B_accumulator_even <= Mult_result_1;
					
				end
				
				// Set initial values of RGB_even accumulators
				if (Y_buf < 16) begin
				
					// Case 3: Y_buf - 16 is less than 0
					R_accumulator_odd <= 0 - Mult_result_2;
					G_accumulator_odd <= 0 - Mult_result_2;
					B_accumulator_odd <= 0 - Mult_result_2;
					
				end else begin
				
					// Case 4: Y_buf - 16 is greater than 0
					R_accumulator_odd <= Mult_result_2;
					G_accumulator_odd <= Mult_result_2;
					B_accumulator_odd <= Mult_result_2;
					
				end
				
				// Second matrix multiplication calculation for V_even		
				if (V_minus_1 < 128) begin
				
					// Case 1: V_even - 128 is less than 0
					Mult_op_1_1 <= 104595;
					Mult_op_1_2 <= 128 - V_minus_1;
				
				end else begin
				
					// Case 2: V_even - 128 is greater than 0
					Mult_op_1_1 <= 104595;
					Mult_op_1_2 <= V_minus_1 - 128;
				
				end
				
				// Second matrix multiplication calculation for V_odd
				if ((V_accumulator >>> 8) < 128) begin
				
					// Case 3: V_odd - 128 is less than 0
					Mult_op_2_1 <= 104595;
					Mult_op_2_2 <= 128 - (V_accumulator >>> 8);
				
				end else begin
				
					// Case 4: V_odd - 128 is greater than 0
					Mult_op_2_1 <= 104595;
					Mult_op_2_2 <= (V_accumulator >>> 8) - 128;
				
				end
				
				m1_state <= S_M1_LEAD_OUT_1;
			
			end
			
			S_M1_LEAD_OUT_1: begin
			
				// Updating the values of the accumulators
				if (V_prime_even < 128) begin
				
					// Case 1: V_even - 128 is less than 0
					R_accumulator_even <= R_accumulator_even - Mult_result_1;
				
				end else begin
				
					// Case 2: V_even - 128 is greater than 0
					R_accumulator_even <= R_accumulator_even + Mult_result_1;
				
				end
				
				// Updating the values of the accumulators
				if (V_prime_odd < 128) begin
				
					// Case 3: V_odd - 128 is less than 0
					R_accumulator_odd <= R_accumulator_odd - Mult_result_2;
					
				end else begin
				
					// Case 4: V_odd - 128 is greater than 0
					R_accumulator_odd <= R_accumulator_odd + Mult_result_2;
					
				end
				
				// Third matrix multiplication calculation for U_even
				if (U_prime_even < 128) begin
				
					// Case 1: U_even - 128 is less than 0
					Mult_op_1_1 <= 25624;
					Mult_op_1_2 <= 128 - U_prime_even;
				
				end else begin
				
					// Case 2: U_even - 128 is greater than 0
					Mult_op_1_1 <= 25624;
					Mult_op_1_2 <= U_prime_even - 128;
				
				end
				
				// Third matrix multiplication calculation for U_odd
				if (U_prime_odd < 128) begin
				
					// Case 3: U_odd - 128 is less than 0
					Mult_op_2_1 <= 25624;
					Mult_op_2_2 <= 128 - U_prime_odd;
				
				end else begin
				
					// Case 4: U_odd - 128 is greater than 0
					Mult_op_2_1 <= 25624;
					Mult_op_2_2 <= U_prime_odd - 128;
				
				end
				
				m1_state <= S_M1_LEAD_OUT_2;
			
			end
			
			S_M1_LEAD_OUT_2: begin
			
				// Retrieve the buffered Y data
				Y <= SRAM_read_data[15:8];
				Y_buf <= SRAM_read_data[7:0];
			
				// Update the values of the accumulators
				if (U_prime_even < 128) begin
				
					// Case 1: U_even - 128 is less than 0
					// Since the previous calculation includes -25624,
					// if U_even < 128 then the result will be positive
					G_accumulator_even <= G_accumulator_even + Mult_result_1;
				
				end else begin
				
					// Case 2: U_even - 128 is greater than 0
					// Since the previous calculation includes -25624,
					// if U_even > 128 then the result will be negative
					G_accumulator_even <= G_accumulator_even - Mult_result_1;
				
				end
				
				// Update the values of the accumulators
				if (U_prime_odd < 128) begin
				
					// Case 3: U_odd - 128 is less than 0
					// Since the previous calculation includes -25624,
					// if U_odd < 128 then the result will be positive
					G_accumulator_odd <= G_accumulator_odd + Mult_result_2;
					
				end else begin
				
					// Case 4: U_odd - 128 is greater than 0
					// Since the previous calculation includes -25624,
					// if U_odd > 128 then the result will be negative
					G_accumulator_odd <= G_accumulator_odd - Mult_result_2;
				
				end
				
				// Fourth matrix multiplcation for the V_even
				if (V_prime_even < 128) begin
				
					// Case 1: V_even - 128 is less than 0
					Mult_op_1_1 <= 53281;
					Mult_op_1_2 <= 128 - V_prime_even;
				
				end else begin
				
					// Case 2: V_even - 128 is greater than 0
					Mult_op_1_1 <= 53281;
					Mult_op_1_2 <= V_prime_even - 128;
				
				end
				
				// Fourth matrix multiplcation for the V_even
				if (V_prime_odd < 128) begin
				
					// Case 3: V_odd - 128 is less than 0
					Mult_op_2_1 <= 53281;
					Mult_op_2_2 <= 128 - V_prime_odd;
					
				end else begin
				
					// Case 4: V_odd - 128 is greater than 0
					Mult_op_2_1 <= 53281;
					Mult_op_2_2 <= V_prime_odd - 128;
					
				end
				
				// Scale and clip R accumulators
				if (R_accumulator_even[31] == 1'b1) begin
				
					// If the sign bit is equal to 1, then the number is negative, so clip to 0
					R_even <= 0;
					
				end else begin
				
					// If bits 24 to 30 are all 0 then the number is less than 255
					if (R_accumulator_even[30:24] == 7'b0000000) begin
					
						// Take bits 16 to 23, which scales
						R_even <= R_accumulator_even[23:16];
						
					end else begin
					
						// Otherwise clip to 255
						R_even <= 255;
						
					end
					
				end
				
				if (R_accumulator_odd[31] == 1'b1) begin
				
					// If the sign bit is equal to 1, then the number is negative, so clip to 0
					R_odd <= 0;
					
				end else begin
				
					// If bits 24 to 30 are all 0 then the number is less than 255
					if (R_accumulator_odd[30:24] == 7'b0000000) begin
					
						// Take bits 16 to 23, which scales
						R_odd <= R_accumulator_odd[23:16];
						
					end else begin
					
						// Otherwise clip to 255
						R_odd <= 255;
						
					end
					
				end
				
				m1_state <= S_M1_LEAD_OUT_3;
			
			end
			
			S_M1_LEAD_OUT_3: begin
			
				// Shift the U registers down
				U_minus_5 <= U_minus_3;
				U_minus_3 <= U_minus_1;
				U_minus_1 <= U_plus_1;
				U_plus_1 <= U_plus_3;
				U_plus_3 <= U_plus_5;
				
				// G Accumulators
			
				// Case 1: V_even - 128 is less than 0
				
				// Update the values of the accumulators				
				if (V_prime_even < 128) begin
				
					// Case 1: V_even - 128 is less than 0
					// Since the previous calculation includes -53281,
					// if V_even < 128 then the result will be positive
					G_accumulator_even <= G_accumulator_even + Mult_result_1;
					
				end else begin
				
					// Case 2: V_even - 128 is greater than 0
					// Since the previous calculation includes -53281,
					// if V_odd < 128 then the result will be negative
					G_accumulator_even <= G_accumulator_even - Mult_result_1;
				
				end
				
				// Update the values of the accumulators
				if (V_prime_odd < 128) begin
				
					// Case 3: V_odd - 128 is less than 0
					G_accumulator_odd <= G_accumulator_odd + Mult_result_2;
				
				end else begin
				
					// Case 4: V_odd - 128 is greater than 0
					G_accumulator_odd <= G_accumulator_odd - Mult_result_2;
				
				end
				
				// Fifth matrix multiplcation for U_even			
				if (U_prime_even < 128) begin
				
					// Case 1: U_even - 128 is less than 0
					Mult_op_1_1 <= 132251;
					Mult_op_1_2 <= 128 - U_prime_even;
					
				end else begin
				
					// Case 2: U_even - 128 is greater than 0
					Mult_op_1_1 <= 132251;
					Mult_op_1_2 <= U_prime_even - 128;
				
				end
				
				// Fifth matrix multiplication for U_odd
				if (U_prime_odd < 128) begin
				
					// Case 3: U_odd - 128 is less than 0
					Mult_op_2_1 <= 132251;
					Mult_op_2_2 <= 128 - U_prime_odd;
					
				end else begin
				
					// Case 4: U_odd - 128 is greater than 0
					Mult_op_2_1 <= 132251;
					Mult_op_2_2 <= U_prime_odd - 128;
					
				end
				
				m1_state <= S_M1_LEAD_OUT_4;
			
			end	
			
			S_M1_LEAD_OUT_4: begin
			
				// Shift the V registers down
				V_minus_5 <= V_minus_3;
				V_minus_3 <= V_minus_1;
				V_minus_1 <= V_plus_1;
				V_plus_1 <= V_plus_3;
				V_plus_3 <= V_plus_5;
				
				// Update the values of the accumulators
				if (U_prime_even < 128) begin
				
					// Case 1: U_even - 128 is less than 0
					B_accumulator_even <= B_accumulator_even - Mult_result_1;
					
				end else begin
			
					// Case 2: U_even - 128 is greater than 0	
					B_accumulator_even <= B_accumulator_even + Mult_result_1;
				
				end
				
				// Update the values of the accumulators
				if (U_prime_odd < 128) begin
				
					// Case 3: U_odd - 128 is less than 0
					B_accumulator_odd <= B_accumulator_odd - Mult_result_2;
					
				end else begin
				
					// Case 4: U_odd - 128 is greater than 0
					B_accumulator_odd <= B_accumulator_odd + Mult_result_2;
			
				end
				
				// Scale and clip G accumulators
				if (G_accumulator_even[31] == 1'b1) begin
				
					// If the sign bit is equal to 1, then the number is negative, so clip to 0
					G_even <= 0;
					
				end else begin
				
					// If bits 24 to 30 are all 0 then the number is less than 255
					if (G_accumulator_even[30:24] == 7'b0000000) begin
					
						// Take bits 16 to 23, which scales
						G_even <= G_accumulator_even[23:16];
						
					end else begin
					
						// Otherwise clip to 255
						G_even <= 255;
						
					end
					
				end
				
				if (G_accumulator_odd[31] == 1'b1) begin
				
					// If the sign bit is equal to 1, then the number is negative, so clip to 0
					G_odd <= 0;
					
				end else begin
				
					// If bits 24 to 30 are all 0 then the number is less than 255
					if (G_accumulator_odd[30:24] == 7'b0000000) begin
					
						// Take bits 16 to 23, which scales
						G_odd <= G_accumulator_odd[23:16];
						
					end else begin
					
						// Otherwise clip to 255
						G_odd <= 255;
						
					end
					
				end
				
				m1_state <= S_M1_LEAD_OUT_5;
			
			end
			
			S_M1_LEAD_OUT_5: begin
			
				// Set the address to the current write address
				SRAM_address_M1 <= SRAM_RGB_offset + SRAM_address_RGB;
			
				// Increment RGB address every time we write
				SRAM_address_RGB <= SRAM_address_RGB + 1;
				
				// Write R_even and G_even
				SRAM_write_data_M1 <= {R_even, G_even};
				
				// Set write enable low (active low)
				SRAM_we_n_M1 <= 1'd0;

				// Scale and clip B accumulators
				if (B_accumulator_even[31] == 1'b1) begin
				
					// If the sign bit is equal to 1, then the number is negative, so clip to 0
					B_even <= 0;
					
				end else begin
				
					// If bits 24 to 30 are all 0 then the number is less than 255
					if (B_accumulator_even[30:24] == 7'b0000000) begin
					
						// Take bits 16 to 23, which scales
						B_even <= B_accumulator_even[23:16];
						
					end else begin
					
						// Otherwise clip to 255
						B_even <= 255;
						
					end
					
				end
				
				if (B_accumulator_odd[31] == 1'b1) begin
				
					// If the sign bit is equal to 1, then the number is negative, so clip to 0
					B_odd <= 0;
					
				end else begin
				
					// If bits 24 to 30 are all 0 then the number is less than 255
					if (B_accumulator_odd[30:24] == 7'b0000000) begin
					
						// Take bits 16 to 23, which scales
						B_odd <= B_accumulator_odd[23:16];
						
					end else begin
					
						// Otherwise clip to 255
						B_odd <= 255;
						
					end
					
				end
				
				if (timesLeadOut == 3) begin
				
					// If timesLeadOut is 3 then we have done all calculations necessary and can skip them
					m1_state <= S_M1_LEAD_OUT_6;
				
				end else begin
				
					// If timesLeadOut is not 3, then set the multipliers for the first calculation in upsampling
					Mult_op_1_1 <= 159;
					Mult_op_1_2 <= (U_minus_1 + U_plus_1);
					Mult_op_2_1 <= 159;
					Mult_op_2_2 <= (V_minus_1 + V_plus_1);
					
					m1_state <= S_M1_LEAD_OUT_6;
				
				end
			
			end
			
			S_M1_LEAD_OUT_6: begin
			
				// Set the address to the current write address
				SRAM_address_M1 <= SRAM_RGB_offset + SRAM_address_RGB;
				
				// Increment RGB address every time we write
				SRAM_address_RGB <= SRAM_address_RGB + 1;
				
				// Write B_even and R_odd
				SRAM_write_data_M1 <= {B_even, R_odd};
				
				// Set write enable low (active low)
				SRAM_we_n_M1 <= 1'd0;
				
				if (timesLeadOut == 3) begin
					
					// If timesLeadOut is 3 then we have done all calculations necessary and can skip them
					m1_state <= S_M1_LEAD_OUT_7;
				
				end else begin
			
					// If timesLeadOut is not 3, then set the values of the accumulators to the result + 128
					U_accumulator <= Mult_result_1 + 128;
					V_accumulator <= Mult_result_2 + 128;
					
					// Set the multipliers for the second calculation in upsampling
					Mult_op_1_1 <= 52;
					Mult_op_1_2 <= (U_minus_3 + U_plus_3);
					Mult_op_2_1 <= 52;
					Mult_op_2_2 <= (V_minus_3 + V_plus_3);
					
					m1_state <= S_M1_LEAD_OUT_7;
				
				end
			
			end
			
			S_M1_LEAD_OUT_7: begin
			
				// Set the address to the current write address
				SRAM_address_M1 <= SRAM_RGB_offset + SRAM_address_RGB;
				
				// Increment RGB address every time we write
				SRAM_address_RGB <= SRAM_address_RGB + 1;
				
				// Write G_odd and B_odd
				SRAM_write_data_M1 <= {G_odd, B_odd};
				
				// Set write enable low (active low)
				SRAM_we_n_M1 <= 1'd0;
				
				// Increment timesLeadOut so that the lead out states are run for 3 cycles
				timesLeadOut <= timesLeadOut + 1;
				
				if (timesLeadOut == 3) begin
				
					// If timesLeadOut is 3 then we have done all calculations necessary and can skip them
					m1_state <= S_M1_LEAD_OUT_8;
				
				end else begin
				
					// If timesLeadOut is not 3, then decrement the accumulator value by the result since the previous multiplication was negative
					U_accumulator <= U_accumulator - Mult_result_1;
					V_accumulator <= V_accumulator - Mult_result_2;
					
					// Set the multipliers for the third calculation in upsampling
					Mult_op_1_1 <= 21;
					Mult_op_1_2 <= (U_minus_5 + U_plus_5);
					Mult_op_2_1 <= 21;
					Mult_op_2_2 <= (V_minus_5 + V_plus_5);
					
					m1_state <= S_M1_LEAD_OUT_8;
				
				end
			
			end
			
			S_M1_LEAD_OUT_8: begin
			
				// Set write enable high (active low)
				SRAM_we_n_M1 <= 1'd1;
			
				if (timesLeadOut == 4) begin
				
					// If timesLeadOut is 4 here, it means we are done with lead out states and can move to the next pixel row
					m1_state <= S_M1_LEAD_OUT_9;
				
				end else begin
				
					if (timesLeadOut != 3) begin
			
						// If timesLeadOut is 3 here, we do not need to buffer the next Y value
						SRAM_address_M1 <= SRAM_Y_offset + SRAM_address_Y;
					
						// Increment the Y address
						SRAM_address_Y <= SRAM_address_Y + 1;
					
					end
					
					// If timesLeadOut is not 4, then increment the accumulator value by the result
					U_accumulator <= U_accumulator + Mult_result_1;
					V_accumulator <= V_accumulator + Mult_result_2;
					
					// First matrix multiplication calculation for Y
					if (Y < 16) begin
					
						// Case 1: Y - 16 is less than 0
						// Set the values of the multiplier so only positive multiplication occurs
						Mult_op_1_1 <= 76284;
						Mult_op_1_2 <= 16 - Y;
						
					end else begin
					
						// Case 2: Y - 16 is greater than 0
						// Set the values of the multiplier so only positive multiplication occurs
						Mult_op_1_1 <= 76284;
						Mult_op_1_2 <= Y - 16;
					
					end
					
					// First matrix multiplication calculation for Y_buf
					if (Y_buf < 16) begin
					
						// Case 3: Y_buf - 16 is less than 0
						// Set the values of the multiplier so only positive multiplication occurs
						Mult_op_2_1 <= 76284;
						Mult_op_2_2 <= 16 - Y_buf;
						
					end else begin
					
						// Case 4: Y_buf - 16 is greater than 0
						// Set the values of the multiplier so only positive multiplication occurs
						Mult_op_2_1 <= 76284;
						Mult_op_2_2 <= Y_buf - 16;
						
					end
					
					m1_state <= S_M1_LEAD_OUT_0;
				
				end
				
			end
			
			S_M1_LEAD_OUT_9: begin
			
				// This is a dummy state that gives time for the last write to finish
				
				m1_state <= S_M1_LEAD_OUT_10;
			
			end
			
			S_M1_LEAD_OUT_10: begin
			
				if (pixel_row_number == 240) begin
			
					// If pixel row number is 240 then the entire picture is finished
					Milestone_1_finished <= 1'b1;
				
					// Move back to S_M1_IDLE with the Milestone_1_finished flag high
					m1_state <= S_M1_IDLE;
				
				end else begin
				
					// Otherwise move back to S_LEAD_IN_0 for the next row to be calculated
					m1_state <= S_M1_LEAD_IN_0;
				
				end
			
			end
		
		endcase
		
		end
		
		///////////////////////// MILESTONE 2 STATES /////////////////////////
		
			// Current problems:
			// 
			// 
			
			//////////////////////////////////////////////////////////////////////
		
		
		S_MILESTONE_2: begin
		
			case (m2_state)
			
				S_M2_IDLE: begin
				
					if (Milestone_2_finished) begin
					
						top_state <= S_TRANSITION;
				
					end else begin
						
						isYBlockFinished <= 0;
						isUBlockFinished <= 0;
						isVBlockFinished <= 0;
						
						switchAddrGen <= 0;
						
						SC_base_address <= 18'd76800;
						
						M2_row_write <= 0;
						M2_col_write <= 0;
						
						sampleCounterEnabled <= 1'd1;
						
						RAM_address_C <= 0;
						RAM_address_T <= 64;
						RAM_address_prev <= 0;
						RAM_address_sample <= 0;
						
						S_prime_buf <= 0;
						S_write_buf <= 0;
						
						isSPrimeBuffered <= 0;
						
						isTFilled <= 0;
						
						// Set write enable high (active low)
						SRAM_we_n_M2 <= 1'd1;
						
						M2_row_index <= 0;
						M2_col_index <= 0;
						
						calculationsPerformed <= 0;
						
						SRAM_address_write_M2 <= 0;
						
						isSValueToWrite <= 0;
						
						colAccum_1 <= 0;
						colAccum_2 <= 0;
						colAccum_3 <= 0;
						
						T_buf_1 <= 0;
						T_buf_2 <= 0;
						T_buf_3 <= 0;
						
						CT_buf <= 0;
						
						RAM_address_a_0 <= 0;
						RAM_address_b_0 <= 0;
						RAM_address_a_1 <= 0;
						RAM_address_b_1 <= 0;
						RAM_address_a_2 <= 0;
						RAM_address_b_2 <= 0;
						
						RAM_we_n_a_0 <= 1'd1;
						RAM_we_n_b_0 <= 1'd0;
						RAM_we_n_a_1 <= 1'd0;
						RAM_we_n_b_1 <= 1'd0;
						RAM_we_n_a_2 <= 1'd0;
						RAM_we_n_b_2 <= 1'd0;
					
						RAM_write_data_a_0 <= 0;
						RAM_write_data_b_0 <= 0;
						RAM_write_data_a_1 <= 0;
						RAM_write_data_b_1 <= 0;
						RAM_write_data_a_2 <= 0;
						RAM_write_data_b_2 <= 0;
					
						m2_state <= S_M2_LEAD_IN_0;
						
					end
				
				end
			
				S_M2_LEAD_IN_0: begin
				
					// Dummy state to give time for the address generator to get values
					
					m2_state <= S_M2_LEAD_IN_1;
					
				end
				
				S_M2_LEAD_IN_1: begin
				
					// Set the address to the pre-IDCT offset to get the next S'
					SRAM_address_M2 <= M2_address_generation;
					
					m2_state <= S_M2_LEAD_IN_2;
				
				end
				
				S_M2_LEAD_IN_2: begin
				
					// Set the address to the pre-IDCT offset to get the next S'
					SRAM_address_M2 <= M2_address_generation;
					
					m2_state <= S_M2_LEAD_IN_3;
				
				end
				
				S_M2_LEAD_IN_3: begin

					// Set the address to the pre-IDCT offset to get the next S'
					SRAM_address_M2 <= M2_address_generation;
				
					m2_state <= S_M2_LEAD_IN_4;
					
				end
				
				S_M2_LEAD_IN_4: begin
				
					// This is the main state for fetching the first block
					// This state loops until the address generator finishes
					// generating addresses to read from the current block
				
					// Set the address to the pre-IDCT offset to get the next S'
					SRAM_address_M2 <= M2_address_generation;
				
					if (isSPrimeBuffered == 1'd0) begin
					
						S_prime_buf <= SRAM_read_data;
						
						isSPrimeBuffered <= 1'd1;
						
					end else begin
					
						RAM_write_data_a_0 <= {S_prime_buf, SRAM_read_data};
						
						// Set RAM address to the correct write address
						RAM_address_a_0 <= RAM_address_prev;
					
						// Increment the RAM address offset
						RAM_address_prev <= RAM_address_prev + 1;
						
						isSPrimeBuffered <= 1'd0;
				
					end
				
					if (isFinishedBlock) begin
					
						sampleCounterEnabled <= 1'd0;
						
						M2_col_index <= M2_col_index + 1;
						
						//M2_row_index 
					
						m2_state <= S_M2_LEAD_IN_5;
						
					end else begin
					
						m2_state <= S_M2_LEAD_IN_4;
						
					end
				
				
				end
				
				S_M2_LEAD_IN_5: begin
				
					// Set the address to the pre-IDCT offset to get the next S'
					SRAM_address_M2 <= M2_address_generation;
				
					if (isSPrimeBuffered == 1'd0) begin
					
						S_prime_buf <= SRAM_read_data;
						
						isSPrimeBuffered <= 1'd1;
						
					end else begin
					
						RAM_write_data_a_0 <= {S_prime_buf, SRAM_read_data};
						
						// Set RAM address to the correct write address
						RAM_address_a_0 <= RAM_address_prev;
					
						// Increment the RAM address offset
						RAM_address_prev <= RAM_address_prev + 1;
						
						isSPrimeBuffered <= 1'd0;
				
					end
				
					m2_state <= S_M2_LEAD_IN_6;
				
				end
				
				S_M2_LEAD_IN_6: begin
				
					if (isSPrimeBuffered == 1'd0) begin
					
						S_prime_buf <= SRAM_read_data;
						
						isSPrimeBuffered <= 1'd1;
						
					end else begin
					
						RAM_write_data_a_0 <= {S_prime_buf, SRAM_read_data};
						
						// Set RAM address to the correct write address
						RAM_address_a_0 <= RAM_address_prev;
					
						// Increment the RAM address offset
						RAM_address_prev <= RAM_address_prev + 1;
						
						isSPrimeBuffered <= 1'd0;
				
					end
				
					m2_state <= S_M2_LEAD_IN_7;
				
				end
				
				S_M2_LEAD_IN_7: begin
				
					if (isSPrimeBuffered == 1'd0) begin
					
						S_prime_buf <= SRAM_read_data;
						
						isSPrimeBuffered <= 1'd1;
						
					end else begin
					
						RAM_write_data_a_0 <= {S_prime_buf, SRAM_read_data};
						
						// Set RAM address to the correct write address
						RAM_address_a_0 <= RAM_address_prev;
					
						// Increment the RAM address offset
						RAM_address_prev <= RAM_address_prev + 1;
						
						isSPrimeBuffered <= 1'd0;
				
					end
				
					m2_state <= S_M2_LEAD_IN_8;
				
				end
				
				S_M2_LEAD_IN_8: begin
				
					RAM_we_n_a_0 <= 1'd0;
					RAM_we_n_b_0 <= 1'd0;
				
					m2_state <= S_M2_LEAD_IN_9;
				
				end
				
				S_M2_LEAD_IN_9: begin
				
					m2_state <= S_M2_CC_0;
				
				end
				
				S_M2_CC_0: begin
				
					// The fetching of the first block is complete
					// Matrix multiplication can now begin
					
					// NOTE:
					// Since we are multiplying the first sample* of S'
					// with the first column of C, it is easier
					// to instead multiply the first row of S'
					// with the first row of C transpose
					
					isTValueToWrite <= 0;
					
					// Read the first S' value from RAM (NOTE: S' is PACKED)
					RAM_address_a_0 <= RAM_address_sample;
					
					// Read the first row of 3 C values from RAM (NOTE: C is PACKED)
					RAM_address_a_1 <= RAM_address_C;
					RAM_address_b_1 <= RAM_address_C + 1;
					
					// Increment the addresses
					RAM_address_C <= RAM_address_C + 4;
					
					// Set the RAM to read
					RAM_we_n_a_0 <= 0;
					RAM_we_n_b_0 <= 0;
					
					// Set the RAM to read
					RAM_we_n_a_1 <= 0;
					RAM_we_n_b_1 <= 0;
					
					// Set the RAM to read
					RAM_we_n_a_2 <= 0;
					RAM_we_n_b_2 <= 0;
					
					// Set the SRAM to read
					SRAM_we_n_M2 <= 1'b1;
					
					// We will reuse this register (setting to 0 for clarity)
					S_prime_buf <= 0;
					
					fetchedSPrime <= 0;
					
					if (isYBlockFinished && isUBlockFinished && isVBlockFinished) begin
						
						Milestone_2_finished <= 1;
						
						m2_state <= S_M2_IDLE;
						
					end else begin
						
						m2_state <= S_M2_CC_1;
						
					end
					
				end
				
				S_M2_CC_1: begin
				
					// Read the second row of 3 C values from RAM (NOTE: C is PACKED)
					RAM_address_a_1 <= RAM_address_C;
					RAM_address_b_1 <= RAM_address_C + 1;
					
					// Increment the addresses
					RAM_address_C <= RAM_address_C + 4;
					
					m2_state <= S_M2_CC_2;
				
				end
				
				S_M2_CC_2: begin
					
					// Update accumulators
					colAccum_1 <= 0;
					colAccum_2 <= 0;
					colAccum_3 <= 0;
					
					// Update buffers
					T_buf_1 <= colAccum_1 + Mult_result_3;
					T_buf_2 <= colAccum_2 + Mult_result_4;
					
					if (isTValueToWrite) begin
					
						// Write 2 of the 2 values to RAM2
						RAM_we_n_a_2 <= 1'b1;
						RAM_we_n_b_2 <= 1'b1;
						
						RAM_address_a_2 <= RAM_address_T;
						RAM_address_b_2 <= RAM_address_T + 1;
						
						RAM_write_data_a_2 <= (colAccum_1 + Mult_result_3) >>> 8;
						RAM_write_data_b_2 <= (colAccum_2 + Mult_result_4) >>> 8;
						
						// Write 1 of the 2 values to RAM0
						RAM_we_n_b_0 <= 1'b1;
						
						RAM_address_b_0 <= RAM_address_T;
						
						RAM_write_data_b_0 <= (colAccum_1 + Mult_result_3) >>> 8;
						
					end
					
					if (calculationsPerformed != 8) begin
					
						// Read the third row of 3 C values from RAM (NOTE: C is PACKED)
						RAM_address_a_1 <= RAM_address_C;
						RAM_address_b_1 <= RAM_address_C + 1;
						
						// Increment the addresses
						RAM_address_C <= RAM_address_C + 4;
						
						// Buffer S_prime other sample
						S_prime_buf <= RAM_read_data_a_0[15: 0];
						
						// Read the next sample
						RAM_address_a_0 <= RAM_address_sample + 1;
						
						// Increment sample counter
						RAM_address_sample <= RAM_address_sample + 1;
						
						if (RAM_read_data_a_0[31] == 1'b1) begin
						
							Mult_op_3_1 <= {{16{1'b1}}, RAM_read_data_a_0[31:16]};
						
							Mult_op_4_1 <= {{16{1'b1}}, RAM_read_data_a_0[31:16]};
							
							Mult_op_5_1 <= {{16{1'b1}}, RAM_read_data_a_0[31:16]};
						
						end else begin
						
							Mult_op_3_1 <= RAM_read_data_a_0[31:16];
						
							Mult_op_4_1 <= RAM_read_data_a_0[31:16];
							
							Mult_op_5_1 <= RAM_read_data_a_0[31:16];
							
						end
						
						Mult_op_3_2 <= (RAM_read_data_a_1[31] == 1'b1) ? {{16{1'b1}}, RAM_read_data_a_1[31:16]} : RAM_read_data_a_1[31:16];
					
						Mult_op_4_2 <= (RAM_read_data_a_1[15] == 1'b1) ? {{16{1'b1}}, RAM_read_data_a_1[15: 0]} : RAM_read_data_a_1[15: 0];
						
						Mult_op_5_2 <= (RAM_read_data_b_1[31] == 1'b1) ? {{16{1'b1}}, RAM_read_data_b_1[31:16]} : RAM_read_data_b_1[31:16];
					
					end
					
					m2_state <= S_M2_CC_3;
				
				end
				
				S_M2_CC_3: begin
				
					if (isTValueToWrite) begin
					
						// Write the last of the 3 values to RAM0
						RAM_we_n_b_0 <= 1'b1;
							
						RAM_address_b_0 <= RAM_address_T + 1;
							
						RAM_write_data_b_0 <= T_buf_2 >>> 8;
							
						RAM_address_T <= RAM_address_T + 2;
						
						isTValueToWrite <= 0;
					
					end
				
					if (calculationsPerformed != 8) begin
				
						// Update the accumulators
						colAccum_1 <= colAccum_1 + Mult_result_3;
						colAccum_2 <= colAccum_2 + Mult_result_4;
						colAccum_3 <= colAccum_3 + Mult_result_5;
					
						// Read the fourth row of 3 C values from RAM (NOTE: C is PACKED)
						RAM_address_a_1 <= RAM_address_C;
						RAM_address_b_1 <= RAM_address_C + 1;
						
						// Increment the addresses
						RAM_address_C <= RAM_address_C + 4;
						
						if (S_prime_buf[15] == 1'b1) begin
						
							Mult_op_3_1 <= {{16{1'b1}}, S_prime_buf};
						
							Mult_op_4_1 <= {{16{1'b1}}, S_prime_buf};
							
							Mult_op_5_1 <= {{16{1'b1}}, S_prime_buf};
						
						end else begin
						
							Mult_op_3_1 <= S_prime_buf;
						
							Mult_op_4_1 <= S_prime_buf;
							
							Mult_op_5_1 <= S_prime_buf;
						
						end
						
						Mult_op_3_2 <= (RAM_read_data_a_1[31] == 1'b1) ? {{16{1'b1}}, RAM_read_data_a_1[31:16]} : RAM_read_data_a_1[31:16];
					
						Mult_op_4_2 <= (RAM_read_data_a_1[15] == 1'b1) ? {{16{1'b1}}, RAM_read_data_a_1[15: 0]} : RAM_read_data_a_1[15: 0];
						
						Mult_op_5_2 <= (RAM_read_data_b_1[31] == 1'b1) ? {{16{1'b1}}, RAM_read_data_b_1[31:16]} : RAM_read_data_b_1[31:16];
						
						m2_state <= S_M2_CC_4;
						
					end else begin
								
						calculationsPerformed <= 0;
					
						RAM_address_sample <= 32;
						
						RAM_address_T <= 64;
						
						colAccum_1 <= 0;
						colAccum_2 <= 0;
						colAccum_3 <= 0;
						
						// Set the RAM to read
						RAM_we_n_a_0 <= 0;
						RAM_we_n_b_0 <= 0;
						
						// Set the RAM to read
						RAM_we_n_a_1 <= 0;
						RAM_we_n_b_1 <= 0;
						
						// Set the RAM to read
						RAM_we_n_a_2 <= 0;
						RAM_we_n_b_2 <= 0;
						
						m2_state <= S_M2_S_TRANSITION_0;
						
					end
				
				end
				
				S_M2_CC_4: begin
				
					// Update the accumulators
					colAccum_1 <= colAccum_1 + Mult_result_3;
					colAccum_2 <= colAccum_2 + Mult_result_4;
					colAccum_3 <= colAccum_3 + Mult_result_5;
				
					// Read the fifth row of 3 C values from RAM (NOTE: C is PACKED)
					RAM_address_a_1 <= RAM_address_C;
					RAM_address_b_1 <= RAM_address_C + 1;
					
					// Increment the addresses
					RAM_address_C <= RAM_address_C + 4;
					
					// Buffer S_prime other sample
					S_prime_buf <= RAM_read_data_a_0[15: 0];
					
					// Read the next sample
					RAM_address_a_0 <= RAM_address_sample + 1;
					
					// Increment sample counter
					RAM_address_sample <= RAM_address_sample + 1;
					
					if (RAM_read_data_a_0[31] == 1'b1) begin
					
						Mult_op_3_1 <= {{16{1'b1}}, RAM_read_data_a_0[31:16]};
					
						Mult_op_4_1 <= {{16{1'b1}}, RAM_read_data_a_0[31:16]};
						
						Mult_op_5_1 <= {{16{1'b1}}, RAM_read_data_a_0[31:16]};
					
					end else begin
					
						Mult_op_3_1 <= RAM_read_data_a_0[31:16];
					
						Mult_op_4_1 <= RAM_read_data_a_0[31:16];
						
						Mult_op_5_1 <= RAM_read_data_a_0[31:16];
						
					end
					
					Mult_op_3_2 <= (RAM_read_data_a_1[31] == 1'b1) ? {{16{1'b1}}, RAM_read_data_a_1[31:16]} : RAM_read_data_a_1[31:16];
				
					Mult_op_4_2 <= (RAM_read_data_a_1[15] == 1'b1) ? {{16{1'b1}}, RAM_read_data_a_1[15: 0]} : RAM_read_data_a_1[15: 0];
					
					Mult_op_5_2 <= (RAM_read_data_b_1[31] == 1'b1) ? {{16{1'b1}}, RAM_read_data_b_1[31:16]} : RAM_read_data_b_1[31:16];
					
					m2_state <= S_M2_CC_5;
				
				end
				
				S_M2_CC_5: begin
				
					// Update the accumulators
					colAccum_1 <= colAccum_1 + Mult_result_3;
					colAccum_2 <= colAccum_2 + Mult_result_4;
					colAccum_3 <= colAccum_3 + Mult_result_5;
				
					// Read the sixth row of 3 C values from RAM (NOTE: C is PACKED)
					RAM_address_a_1 <= RAM_address_C;
					RAM_address_b_1 <= RAM_address_C + 1;
					
					// Increment the addresses
					RAM_address_C <= RAM_address_C + 4;
					
					if (S_prime_buf[15] == 1'b1) begin
					
						Mult_op_3_1 <= {{16{1'b1}}, S_prime_buf};
					
						Mult_op_4_1 <= {{16{1'b1}}, S_prime_buf};
						
						Mult_op_5_1 <= {{16{1'b1}}, S_prime_buf};
					
					end else begin
					
						Mult_op_3_1 <= S_prime_buf;
					
						Mult_op_4_1 <= S_prime_buf;
						
						Mult_op_5_1 <= S_prime_buf;
					
					end
					
					Mult_op_3_2 <= (RAM_read_data_a_1[31] == 1'b1) ? {{16{1'b1}}, RAM_read_data_a_1[31:16]} : RAM_read_data_a_1[31:16];
				
					Mult_op_4_2 <= (RAM_read_data_a_1[15] == 1'b1) ? {{16{1'b1}}, RAM_read_data_a_1[15: 0]} : RAM_read_data_a_1[15: 0];
					
					Mult_op_5_2 <= (RAM_read_data_b_1[31] == 1'b1) ? {{16{1'b1}}, RAM_read_data_b_1[31:16]} : RAM_read_data_b_1[31:16];
					
					m2_state <= S_M2_CC_6;
				
				end
				
				S_M2_CC_6: begin
				
					// Update the accumulators
					colAccum_1 <= colAccum_1 + Mult_result_3;
					colAccum_2 <= colAccum_2 + Mult_result_4;
					colAccum_3 <= colAccum_3 + Mult_result_5;
				
					// Read the seventh row of 3 C values from RAM (NOTE: C is PACKED)
					RAM_address_a_1 <= RAM_address_C;
					RAM_address_b_1 <= RAM_address_C + 1;
					
					// Increment the addresses
					RAM_address_C <= RAM_address_C + 4;
					
					// Buffer S_prime other sample
					S_prime_buf <= RAM_read_data_a_0[15: 0];
					
					// Read the next sample
					RAM_address_a_0 <= RAM_address_sample + 1;
					
					// Increment sample counter
					RAM_address_sample <= RAM_address_sample + 1;
					
					if (RAM_read_data_a_0[31] == 1'b1) begin
					
						Mult_op_3_1 <= {{16{1'b1}}, RAM_read_data_a_0[31:16]};
					
						Mult_op_4_1 <= {{16{1'b1}}, RAM_read_data_a_0[31:16]};
						
						Mult_op_5_1 <= {{16{1'b1}}, RAM_read_data_a_0[31:16]};
					
					end else begin
					
						Mult_op_3_1 <= RAM_read_data_a_0[31:16];
					
						Mult_op_4_1 <= RAM_read_data_a_0[31:16];
						
						Mult_op_5_1 <= RAM_read_data_a_0[31:16];
						
					end
					
					Mult_op_3_2 <= (RAM_read_data_a_1[31] == 1'b1) ? {{16{1'b1}}, RAM_read_data_a_1[31:16]} : RAM_read_data_a_1[31:16];
				
					Mult_op_4_2 <= (RAM_read_data_a_1[15] == 1'b1) ? {{16{1'b1}}, RAM_read_data_a_1[15: 0]} : RAM_read_data_a_1[15: 0];
					
					Mult_op_5_2 <= (RAM_read_data_b_1[31] == 1'b1) ? {{16{1'b1}}, RAM_read_data_b_1[31:16]} : RAM_read_data_b_1[31:16];
					
					m2_state <= S_M2_CC_7;
				
				end
				
				S_M2_CC_7: begin
				
					// Update the accumulators
					colAccum_1 <= colAccum_1 + Mult_result_3;
					colAccum_2 <= colAccum_2 + Mult_result_4;
					colAccum_3 <= colAccum_3 + Mult_result_5;
				
					// Read the eighth row of 3 C values from RAM (NOTE: C is PACKED)
					RAM_address_a_1 <= RAM_address_C;
					RAM_address_b_1 <= RAM_address_C + 1;
					
					// Increment the addresses
					RAM_address_C <= 1;
					
					if (S_prime_buf[15] == 1'b1) begin
					
						Mult_op_3_1 <= {{16{1'b1}}, S_prime_buf};
					
						Mult_op_4_1 <= {{16{1'b1}}, S_prime_buf};
						
						Mult_op_5_1 <= {{16{1'b1}}, S_prime_buf};
					
					end else begin
					
						Mult_op_3_1 <= S_prime_buf;
					
						Mult_op_4_1 <= S_prime_buf;
						
						Mult_op_5_1 <= S_prime_buf;
					
					end
					
					Mult_op_3_2 <= (RAM_read_data_a_1[31] == 1'b1) ? {{16{1'b1}}, RAM_read_data_a_1[31:16]} : RAM_read_data_a_1[31:16];
				
					Mult_op_4_2 <= (RAM_read_data_a_1[15] == 1'b1) ? {{16{1'b1}}, RAM_read_data_a_1[15: 0]} : RAM_read_data_a_1[15: 0];
					
					Mult_op_5_2 <= (RAM_read_data_b_1[31] == 1'b1) ? {{16{1'b1}}, RAM_read_data_b_1[31:16]} : RAM_read_data_b_1[31:16];
					
					m2_state <= S_M2_CC_8;
				
				end
				
				S_M2_CC_8: begin
				
					// Update the accumulators
					colAccum_1 <= colAccum_1 + Mult_result_3;
					colAccum_2 <= colAccum_2 + Mult_result_4;
					colAccum_3 <= colAccum_3 + Mult_result_5;
				
					// Read the first row of 3 C values from RAM (NOTE: C is PACKED)
					RAM_address_a_1 <= RAM_address_C;
					RAM_address_b_1 <= RAM_address_C + 1;
					
					// Increment the addresses
					RAM_address_C <= RAM_address_C + 4;
					
					// Buffer S_prime other sample
					S_prime_buf <= RAM_read_data_a_0[15: 0];
					
					// Reset the sample counter since columns are finished
					RAM_address_a_0 <= RAM_address_sample - 3;
					RAM_address_sample <= RAM_address_sample - 3;
					
					if (RAM_read_data_a_0[31] == 1'b1) begin
					
						Mult_op_3_1 <= {{16{1'b1}}, RAM_read_data_a_0[31:16]};
					
						Mult_op_4_1 <= {{16{1'b1}}, RAM_read_data_a_0[31:16]};
						
						Mult_op_5_1 <= {{16{1'b1}}, RAM_read_data_a_0[31:16]};
					
					end else begin
					
						Mult_op_3_1 <= RAM_read_data_a_0[31:16];
					
						Mult_op_4_1 <= RAM_read_data_a_0[31:16];
						
						Mult_op_5_1 <= RAM_read_data_a_0[31:16];
						
					end
					
					Mult_op_3_2 <= (RAM_read_data_a_1[31] == 1'b1) ? {{16{1'b1}}, RAM_read_data_a_1[31:16]} : RAM_read_data_a_1[31:16];
				
					Mult_op_4_2 <= (RAM_read_data_a_1[15] == 1'b1) ? {{16{1'b1}}, RAM_read_data_a_1[15: 0]} : RAM_read_data_a_1[15: 0];
					
					Mult_op_5_2 <= (RAM_read_data_b_1[31] == 1'b1) ? {{16{1'b1}}, RAM_read_data_b_1[31:16]} : RAM_read_data_b_1[31:16];
					
					m2_state <= S_M2_CC_9;
				
				end
				
				S_M2_CC_9: begin
				
					// Update the accumulators
					colAccum_1 <= colAccum_1 + Mult_result_3;
					colAccum_2 <= colAccum_2 + Mult_result_4;
					colAccum_3 <= colAccum_3 + Mult_result_5;
					
					// Read the second row of 3 C values from RAM (NOTE: C is PACKED)
					RAM_address_a_1 <= RAM_address_C;
					RAM_address_b_1 <= RAM_address_C + 1;
					
					// Increment the addresses
					RAM_address_C <= RAM_address_C + 4;
					
					if (S_prime_buf[15] == 1'b1) begin
					
						Mult_op_3_1 <= {{16{1'b1}}, S_prime_buf};
					
						Mult_op_4_1 <= {{16{1'b1}}, S_prime_buf};
						
						Mult_op_5_1 <= {{16{1'b1}}, S_prime_buf};
					
					end else begin
					
						Mult_op_3_1 <= S_prime_buf;
					
						Mult_op_4_1 <= S_prime_buf;
						
						Mult_op_5_1 <= S_prime_buf;
					
					end
					
					Mult_op_3_2 <= (RAM_read_data_a_1[31] == 1'b1) ? {{16{1'b1}}, RAM_read_data_a_1[31:16]} : RAM_read_data_a_1[31:16];
				
					Mult_op_4_2 <= (RAM_read_data_a_1[15] == 1'b1) ? {{16{1'b1}}, RAM_read_data_a_1[15: 0]} : RAM_read_data_a_1[15: 0];
					
					Mult_op_5_2 <= (RAM_read_data_b_1[31] == 1'b1) ? {{16{1'b1}}, RAM_read_data_b_1[31:16]} : RAM_read_data_b_1[31:16];
				
					m2_state <= S_M2_CC_10;
				
				end
				
				S_M2_CC_10: begin
	
					// Update buffers
					T_buf_1 <= colAccum_1 + Mult_result_3;
					T_buf_2 <= colAccum_2 + Mult_result_4;
					T_buf_3 <= colAccum_3 + Mult_result_5;
	
					// Write 2 of the 3 values to RAM2
					RAM_we_n_a_2 <= 1'b1;
					RAM_we_n_b_2 <= 1'b1;
					
					RAM_address_a_2 <= RAM_address_T;
					RAM_address_b_2 <= RAM_address_T + 1;
					
					RAM_write_data_a_2 <= (colAccum_1 + Mult_result_3) >>> 8;
					RAM_write_data_b_2 <= (colAccum_2 + Mult_result_4) >>> 8;
					
					// Write 1 of the 3 values to RAM0
					RAM_we_n_b_0 <= 1'b1;
					
					RAM_address_b_0 <= RAM_address_T;
					
					RAM_write_data_b_0 <= (colAccum_1 + Mult_result_3) >>> 8;
	
					// Update the accumulators
					colAccum_1 <= 0;
					colAccum_2 <= 0;
					colAccum_3 <= 0;
					
					// Read the third row of 3 C values from RAM (NOTE: C is PACKED)
					RAM_address_a_1 <= RAM_address_C;
					RAM_address_b_1 <= RAM_address_C + 1;
					
					// Increment the addresses
					RAM_address_C <= RAM_address_C + 4;
					
					// Buffer S_prime other sample
					S_prime_buf <= RAM_read_data_a_0[15: 0];
					
					// Read the next sample
					RAM_address_a_0 <= RAM_address_sample + 1;
					
					// Increment sample counter
					RAM_address_sample <= RAM_address_sample + 1;
					
					if (RAM_read_data_a_0[31] == 1'b1) begin
					
						Mult_op_3_1 <= {{16{1'b1}}, RAM_read_data_a_0[31:16]};
					
						Mult_op_4_1 <= {{16{1'b1}}, RAM_read_data_a_0[31:16]};
						
						Mult_op_5_1 <= {{16{1'b1}}, RAM_read_data_a_0[31:16]};
					
					end else begin
					
						Mult_op_3_1 <= RAM_read_data_a_0[31:16];
					
						Mult_op_4_1 <= RAM_read_data_a_0[31:16];
						
						Mult_op_5_1 <= RAM_read_data_a_0[31:16];
						
					end
					
					Mult_op_3_2 <= (RAM_read_data_a_1[15] == 1'b1) ? {{16{1'b1}}, RAM_read_data_a_1[15: 0]} : RAM_read_data_a_1[15: 0];
				
					Mult_op_4_2 <= (RAM_read_data_b_1[31] == 1'b1) ? {{16{1'b1}}, RAM_read_data_b_1[31:16]} : RAM_read_data_b_1[31:16];
					
					Mult_op_5_2 <= (RAM_read_data_b_1[15] == 1'b1) ? {{16{1'b1}}, RAM_read_data_b_1[15: 0]} : RAM_read_data_b_1[15: 0];
	
					m2_state <= S_M2_CC_11;
	
				end
				
				S_M2_CC_11: begin
				
					// Write the last of the 3 values to RAM2
					RAM_we_n_a_2 <= 1'b1;
					RAM_we_n_b_2 <= 1'b1;
					
					RAM_address_a_2 <= RAM_address_T + 2;
					
					RAM_write_data_a_2 <= T_buf_3 >>> 8;
					
					// Write 1 of the 3 values to RAM0
					RAM_we_n_b_0 <= 1'b1;
					
					RAM_address_b_0 <= RAM_address_T + 1;
					
					RAM_write_data_b_0 <= T_buf_2 >>> 8;
				
					// Update the accumulators
					colAccum_1 <= colAccum_1 + Mult_result_3;
					colAccum_2 <= colAccum_2 + Mult_result_4;
					colAccum_3 <= colAccum_3 + Mult_result_5;
					
					// Read the fourth row of 3 C values from RAM (NOTE: C is PACKED)
					RAM_address_a_1 <= RAM_address_C;
					RAM_address_b_1 <= RAM_address_C + 1;
					
					// Increment the addresses
					RAM_address_C <= RAM_address_C + 4;
					
					if (S_prime_buf[15] == 1'b1) begin
					
						Mult_op_3_1 <= {{16{1'b1}}, S_prime_buf};
					
						Mult_op_4_1 <= {{16{1'b1}}, S_prime_buf};
						
						Mult_op_5_1 <= {{16{1'b1}}, S_prime_buf};
					
					end else begin
					
						Mult_op_3_1 <= S_prime_buf;
					
						Mult_op_4_1 <= S_prime_buf;
						
						Mult_op_5_1 <= S_prime_buf;
					
					end
					
					Mult_op_3_2 <= (RAM_read_data_a_1[15] == 1'b1) ? {{16{1'b1}}, RAM_read_data_a_1[15: 0]} : RAM_read_data_a_1[15: 0];
				
					Mult_op_4_2 <= (RAM_read_data_b_1[31] == 1'b1) ? {{16{1'b1}}, RAM_read_data_b_1[31:16]} : RAM_read_data_b_1[31:16];
					
					Mult_op_5_2 <= (RAM_read_data_b_1[15] == 1'b1) ? {{16{1'b1}}, RAM_read_data_b_1[15: 0]} : RAM_read_data_b_1[15: 0];
				
					m2_state <= S_M2_CC_12;
				
				end
				
				S_M2_CC_12: begin
				
					// Write the last of the 3 values to RAM0
					RAM_we_n_b_0 <= 1'b1;
					
					RAM_address_b_0 <= RAM_address_T + 2;
					
					RAM_write_data_b_0 <= T_buf_3 >>> 8;
					
					RAM_address_T <= RAM_address_T + 3;
				
					// Update the accumulators
					colAccum_1 <= colAccum_1 + Mult_result_3;
					colAccum_2 <= colAccum_2 + Mult_result_4;
					colAccum_3 <= colAccum_3 + Mult_result_5;
					
					// Read the fifth row of 3 C values from RAM (NOTE: C is PACKED)
					RAM_address_a_1 <= RAM_address_C;
					RAM_address_b_1 <= RAM_address_C + 1;
					
					// Increment the addresses
					RAM_address_C <= RAM_address_C + 4;
					
					// Buffer S_prime other sample
					S_prime_buf <= RAM_read_data_a_0[15: 0];
					
					// Read the next sample
					RAM_address_a_0 <= RAM_address_sample + 1;
					
					// Increment sample counter
					RAM_address_sample <= RAM_address_sample + 1;
					
					if (RAM_read_data_a_0[31] == 1'b1) begin
					
						Mult_op_3_1 <= {{16{1'b1}}, RAM_read_data_a_0[31:16]};
					
						Mult_op_4_1 <= {{16{1'b1}}, RAM_read_data_a_0[31:16]};
						
						Mult_op_5_1 <= {{16{1'b1}}, RAM_read_data_a_0[31:16]};
					
					end else begin
					
						Mult_op_3_1 <= RAM_read_data_a_0[31:16];
					
						Mult_op_4_1 <= RAM_read_data_a_0[31:16];
						
						Mult_op_5_1 <= RAM_read_data_a_0[31:16];
						
					end
					
					Mult_op_3_2 <= (RAM_read_data_a_1[15] == 1'b1) ? {{16{1'b1}}, RAM_read_data_a_1[15: 0]} : RAM_read_data_a_1[15: 0];
				
					Mult_op_4_2 <= (RAM_read_data_b_1[31] == 1'b1) ? {{16{1'b1}}, RAM_read_data_b_1[31:16]} : RAM_read_data_b_1[31:16];
					
					Mult_op_5_2 <= (RAM_read_data_b_1[15] == 1'b1) ? {{16{1'b1}}, RAM_read_data_b_1[15: 0]} : RAM_read_data_b_1[15: 0];
	
					m2_state <= S_M2_CC_13;
				
				end
				
				S_M2_CC_13: begin
				
					// Update the accumulators
					colAccum_1 <= colAccum_1 + Mult_result_3;
					colAccum_2 <= colAccum_2 + Mult_result_4;
					colAccum_3 <= colAccum_3 + Mult_result_5;
					
					// Read the sixth row of 3 C values from RAM (NOTE: C is PACKED)
					RAM_address_a_1 <= RAM_address_C;
					RAM_address_b_1 <= RAM_address_C + 1;
					
					// Increment the addresses
					RAM_address_C <= RAM_address_C + 4;
					
					if (S_prime_buf[15] == 1'b1) begin
					
						Mult_op_3_1 <= {{16{1'b1}}, S_prime_buf};
					
						Mult_op_4_1 <= {{16{1'b1}}, S_prime_buf};
						
						Mult_op_5_1 <= {{16{1'b1}}, S_prime_buf};
					
					end else begin
					
						Mult_op_3_1 <= S_prime_buf;
					
						Mult_op_4_1 <= S_prime_buf;
						
						Mult_op_5_1 <= S_prime_buf;
					
					end
					
					Mult_op_3_2 <= (RAM_read_data_a_1[15] == 1'b1) ? {{16{1'b1}}, RAM_read_data_a_1[15: 0]} : RAM_read_data_a_1[15: 0];
				
					Mult_op_4_2 <= (RAM_read_data_b_1[31] == 1'b1) ? {{16{1'b1}}, RAM_read_data_b_1[31:16]} : RAM_read_data_b_1[31:16];
					
					Mult_op_5_2 <= (RAM_read_data_b_1[15] == 1'b1) ? {{16{1'b1}}, RAM_read_data_b_1[15: 0]} : RAM_read_data_b_1[15: 0];
				
					m2_state <= S_M2_CC_14;
				
				end
				
				S_M2_CC_14: begin
				
					// Update the accumulators
					colAccum_1 <= colAccum_1 + Mult_result_3;
					colAccum_2 <= colAccum_2 + Mult_result_4;
					colAccum_3 <= colAccum_3 + Mult_result_5;
					
					// Read the seventh row of 3 C values from RAM (NOTE: C is PACKED)
					RAM_address_a_1 <= RAM_address_C;
					RAM_address_b_1 <= RAM_address_C + 1;
					
					// Increment the addresses
					RAM_address_C <= RAM_address_C + 4;
					
					// Buffer S_prime other sample
					S_prime_buf <= RAM_read_data_a_0[15: 0];
					
					// Read the next sample
					RAM_address_a_0 <= RAM_address_sample + 1;
					
					// Increment sample counter
					RAM_address_sample <= RAM_address_sample + 1;
					
					if (RAM_read_data_a_0[31] == 1'b1) begin
					
						Mult_op_3_1 <= {{16{1'b1}}, RAM_read_data_a_0[31:16]};
					
						Mult_op_4_1 <= {{16{1'b1}}, RAM_read_data_a_0[31:16]};
						
						Mult_op_5_1 <= {{16{1'b1}}, RAM_read_data_a_0[31:16]};
					
					end else begin
					
						Mult_op_3_1 <= RAM_read_data_a_0[31:16];
					
						Mult_op_4_1 <= RAM_read_data_a_0[31:16];
						
						Mult_op_5_1 <= RAM_read_data_a_0[31:16];
						
					end
					
					Mult_op_3_2 <= (RAM_read_data_a_1[15] == 1'b1) ? {{16{1'b1}}, RAM_read_data_a_1[15: 0]} : RAM_read_data_a_1[15: 0];
				
					Mult_op_4_2 <= (RAM_read_data_b_1[31] == 1'b1) ? {{16{1'b1}}, RAM_read_data_b_1[31:16]} : RAM_read_data_b_1[31:16];
					
					Mult_op_5_2 <= (RAM_read_data_b_1[15] == 1'b1) ? {{16{1'b1}}, RAM_read_data_b_1[15: 0]} : RAM_read_data_b_1[15: 0];
	
					m2_state <= S_M2_CC_15;
				
				end
				
				S_M2_CC_15: begin
				
					// Update the accumulators
					colAccum_1 <= colAccum_1 + Mult_result_3;
					colAccum_2 <= colAccum_2 + Mult_result_4;
					colAccum_3 <= colAccum_3 + Mult_result_5;
					
					// Read the eighth row of 3 C values from RAM (NOTE: C is PACKED)
					RAM_address_a_1 <= RAM_address_C;
					RAM_address_b_1 <= RAM_address_C + 1;
					
					// Increment the addresses
					RAM_address_C <= 3;
					
					if (S_prime_buf[15] == 1'b1) begin
					
						Mult_op_3_1 <= {{16{1'b1}}, S_prime_buf};
					
						Mult_op_4_1 <= {{16{1'b1}}, S_prime_buf};
						
						Mult_op_5_1 <= {{16{1'b1}}, S_prime_buf};
					
					end else begin
					
						Mult_op_3_1 <= S_prime_buf;
					
						Mult_op_4_1 <= S_prime_buf;
						
						Mult_op_5_1 <= S_prime_buf;
					
					end
					
					Mult_op_3_2 <= (RAM_read_data_a_1[15] == 1'b1) ? {{16{1'b1}}, RAM_read_data_a_1[15: 0]} : RAM_read_data_a_1[15: 0];
				
					Mult_op_4_2 <= (RAM_read_data_b_1[31] == 1'b1) ? {{16{1'b1}}, RAM_read_data_b_1[31:16]} : RAM_read_data_b_1[31:16];
					
					Mult_op_5_2 <= (RAM_read_data_b_1[15] == 1'b1) ? {{16{1'b1}}, RAM_read_data_b_1[15: 0]} : RAM_read_data_b_1[15: 0];
				
					m2_state <= S_M2_CC_16;
				
				end
				
				S_M2_CC_16: begin
				
					// Update the accumulators
					colAccum_1 <= colAccum_1 + Mult_result_3;
					colAccum_2 <= colAccum_2 + Mult_result_4;
					colAccum_3 <= colAccum_3 + Mult_result_5;
					
					// Read the first row of 2 C values from RAM (NOTE: C is PACKED)
					RAM_address_a_1 <= RAM_address_C;
					
					// Increment the addresses
					RAM_address_C <= RAM_address_C + 4;
					
					// Buffer S_prime other sample
					S_prime_buf <= RAM_read_data_a_0[15: 0];
					
					// Reset the sample counter since columns are finished
					RAM_address_a_0 <= RAM_address_sample - 3;
					RAM_address_sample <= RAM_address_sample - 3;
					
					if (RAM_read_data_a_0[31] == 1'b1) begin
					
						Mult_op_3_1 <= {{16{1'b1}}, RAM_read_data_a_0[31:16]};
					
						Mult_op_4_1 <= {{16{1'b1}}, RAM_read_data_a_0[31:16]};
						
						Mult_op_5_1 <= {{16{1'b1}}, RAM_read_data_a_0[31:16]};
					
					end else begin
					
						Mult_op_3_1 <= RAM_read_data_a_0[31:16];
					
						Mult_op_4_1 <= RAM_read_data_a_0[31:16];
						
						Mult_op_5_1 <= RAM_read_data_a_0[31:16];
						
					end
					
					Mult_op_3_2 <= (RAM_read_data_a_1[15] == 1'b1) ? {{16{1'b1}}, RAM_read_data_a_1[15: 0]} : RAM_read_data_a_1[15: 0];
				
					Mult_op_4_2 <= (RAM_read_data_b_1[31] == 1'b1) ? {{16{1'b1}}, RAM_read_data_b_1[31:16]} : RAM_read_data_b_1[31:16];
					
					Mult_op_5_2 <= (RAM_read_data_b_1[15] == 1'b1) ? {{16{1'b1}}, RAM_read_data_b_1[15: 0]} : RAM_read_data_b_1[15: 0];
	
					m2_state <= S_M2_CC_17;
				
				end
				
				S_M2_CC_17: begin
					
					// Update the accumulators
					colAccum_1 <= colAccum_1 + Mult_result_3;
					colAccum_2 <= colAccum_2 + Mult_result_4;
					colAccum_3 <= colAccum_3 + Mult_result_5;
					
					// Read the second row of 3 C values from RAM (NOTE: C is PACKED)
					RAM_address_a_1 <= RAM_address_C;
					RAM_address_b_1 <= RAM_address_C + 1;
					
					// Increment the addresses
					RAM_address_C <= RAM_address_C + 4;
					
					if (S_prime_buf[15] == 1'b1) begin
					
						Mult_op_3_1 <= {{16{1'b1}}, S_prime_buf};
					
						Mult_op_4_1 <= {{16{1'b1}}, S_prime_buf};
						
						Mult_op_5_1 <= {{16{1'b1}}, S_prime_buf};
					
					end else begin
					
						Mult_op_3_1 <= S_prime_buf;
					
						Mult_op_4_1 <= S_prime_buf;
						
						Mult_op_5_1 <= S_prime_buf;
					
					end
					
					Mult_op_3_2 <= (RAM_read_data_a_1[15] == 1'b1) ? {{16{1'b1}}, RAM_read_data_a_1[15: 0]} : RAM_read_data_a_1[15: 0];
				
					Mult_op_4_2 <= (RAM_read_data_b_1[31] == 1'b1) ? {{16{1'b1}}, RAM_read_data_b_1[31:16]} : RAM_read_data_b_1[31:16];
					
					Mult_op_5_2 <= (RAM_read_data_b_1[15] == 1'b1) ? {{16{1'b1}}, RAM_read_data_b_1[15: 0]} : RAM_read_data_b_1[15: 0];
				
					m2_state <= S_M2_CC_18;
				
				end
				
				S_M2_CC_18: begin
				
					// Update the accumulators
					colAccum_1 <= 0;
					colAccum_2 <= 0;
					colAccum_3 <= 0;
				
					// Update buffers
					T_buf_1 <= colAccum_1 + Mult_result_3;
					T_buf_2 <= colAccum_2 + Mult_result_4;
					T_buf_3 <= colAccum_3 + Mult_result_5;
	
					// Write 2 of the 3 values to RAM2
					RAM_we_n_a_2 <= 1'b1;
					RAM_we_n_b_2 <= 1'b1;
					
					RAM_address_a_2 <= RAM_address_T;
					RAM_address_b_2 <= RAM_address_T + 1;
					
					RAM_write_data_a_2 <= (colAccum_1 + Mult_result_3) >>> 8;
					RAM_write_data_b_2 <= (colAccum_2 + Mult_result_4) >>> 8;
					
					// Write 1 of the 3 values to RAM0
					RAM_we_n_b_0 <= 1'b1;
					
					RAM_address_b_0 <= RAM_address_T;
					
					RAM_write_data_b_0 <= (colAccum_1 + Mult_result_3) >>> 8;
					
					// Read the third row of 3 C values from RAM (NOTE: C is PACKED)
					RAM_address_a_1 <= RAM_address_C;
					
					// Increment the addresses
					RAM_address_C <= RAM_address_C + 4;
					
					// Buffer S_prime other sample
					S_prime_buf <= RAM_read_data_a_0[15: 0];
					
					// Read the next sample
					RAM_address_a_0 <= RAM_address_sample + 1;
					
					// Increment sample counter
					RAM_address_sample <= RAM_address_sample + 1;
					
					if (RAM_read_data_a_0[31] == 1'b1) begin
					
						Mult_op_3_1 <= {{16{1'b1}}, RAM_read_data_a_0[31:16]};
					
						Mult_op_4_1 <= {{16{1'b1}}, RAM_read_data_a_0[31:16]};
					
					end else begin
					
						Mult_op_3_1 <= RAM_read_data_a_0[31:16];
					
						Mult_op_4_1 <= RAM_read_data_a_0[31:16];
						
					end
					
					Mult_op_3_2 <= (RAM_read_data_a_1[31] == 1'b1) ? {{16{1'b1}}, RAM_read_data_a_1[31:16]} : RAM_read_data_a_1[31:16];
				
					Mult_op_4_2 <= (RAM_read_data_a_1[15] == 1'b1) ? {{16{1'b1}}, RAM_read_data_a_1[15:0]} : RAM_read_data_a_1[15:0];
	
					m2_state <= S_M2_CC_19;
				
				end
				
				S_M2_CC_19: begin
				
					// Write the last of the 3 values to RAM2
					RAM_we_n_a_2 <= 1'b1;
					RAM_we_n_b_2 <= 1'b1;
					
					RAM_address_a_2 <= RAM_address_T + 2;
					
					RAM_write_data_a_2 <= T_buf_3 >>> 8;
					
					// Write 1 of the 3 values to RAM0
					RAM_we_n_b_0 <= 1'b1;
					
					RAM_address_b_0 <= RAM_address_T + 1;
					
					RAM_write_data_b_0 <= T_buf_2 >>> 8;
				
					// Update the accumulators
					colAccum_1 <= colAccum_1 + Mult_result_3;
					colAccum_2 <= colAccum_2 + Mult_result_4;
			
					// Read the fourth row of 3 C values from RAM (NOTE: C is PACKED)
					RAM_address_a_1 <= RAM_address_C;
					
					// Increment the addresses
					RAM_address_C <= RAM_address_C + 4;
					
					if (S_prime_buf[15] == 1'b1) begin
					
						Mult_op_3_1 <= {{16{1'b1}}, S_prime_buf};
					
						Mult_op_4_1 <= {{16{1'b1}}, S_prime_buf};
					
					end else begin
					
						Mult_op_3_1 <= S_prime_buf;
					
						Mult_op_4_1 <= S_prime_buf;
						
						Mult_op_5_1 <= S_prime_buf;
					
					end
					
					Mult_op_3_2 <= (RAM_read_data_a_1[31] == 1'b1) ? {{16{1'b1}}, RAM_read_data_a_1[31:16]} : RAM_read_data_a_1[31:16];
				
					Mult_op_4_2 <= (RAM_read_data_a_1[15] == 1'b1) ? {{16{1'b1}}, RAM_read_data_a_1[15:0]} : RAM_read_data_a_1[15:0];
				
					m2_state <= S_M2_CC_20;
				
				end

				S_M2_CC_20: begin
				
					// Write the last of the 3 values to RAM0
					RAM_we_n_b_0 <= 1'b1;
					
					RAM_address_b_0 <= RAM_address_T + 2;
					
					RAM_write_data_b_0 <= T_buf_3 >>> 8;
					
					RAM_address_T <= RAM_address_T + 3;
				
					// Update the accumulators
					colAccum_1 <= colAccum_1 + Mult_result_3;
					colAccum_2 <= colAccum_2 + Mult_result_4;
					
					// Read the fifth row of 3 C values from RAM (NOTE: C is PACKED)
					RAM_address_a_1 <= RAM_address_C;
					
					// Increment the addresses
					RAM_address_C <= RAM_address_C + 4;
					
					// Buffer S_prime other sample
					S_prime_buf <= RAM_read_data_a_0[15: 0];
					
					// Read the next sample
					RAM_address_a_0 <= RAM_address_sample + 1;
					
					// Increment sample counter
					RAM_address_sample <= RAM_address_sample + 1;
					
					if (RAM_read_data_a_0[31] == 1'b1) begin
					
						Mult_op_3_1 <= {{16{1'b1}}, RAM_read_data_a_0[31:16]};
					
						Mult_op_4_1 <= {{16{1'b1}}, RAM_read_data_a_0[31:16]};
					
					end else begin
					
						Mult_op_3_1 <= RAM_read_data_a_0[31:16];
					
						Mult_op_4_1 <= RAM_read_data_a_0[31:16];
						
					end
					
					Mult_op_3_2 <= (RAM_read_data_a_1[31] == 1'b1) ? {{16{1'b1}}, RAM_read_data_a_1[31:16]} : RAM_read_data_a_1[31:16];
				
					Mult_op_4_2 <= (RAM_read_data_a_1[15] == 1'b1) ? {{16{1'b1}}, RAM_read_data_a_1[15:0]} : RAM_read_data_a_1[15:0];
	
					m2_state <= S_M2_CC_21;
				
				end
				
				S_M2_CC_21: begin
				
					// Update the accumulators
					colAccum_1 <= colAccum_1 + Mult_result_3;
					colAccum_2 <= colAccum_2 + Mult_result_4;
					
					// Read the sixth row of 3 C values from RAM (NOTE: C is PACKED)
					RAM_address_a_1 <= RAM_address_C;
					
					// Increment the addresses
					RAM_address_C <= RAM_address_C + 4;
					
					if (S_prime_buf[15] == 1'b1) begin
					
						Mult_op_3_1 <= {{16{1'b1}}, S_prime_buf};
					
						Mult_op_4_1 <= {{16{1'b1}}, S_prime_buf};
					
					end else begin
					
						Mult_op_3_1 <= S_prime_buf;
					
						Mult_op_4_1 <= S_prime_buf;
						
						Mult_op_5_1 <= S_prime_buf;
					
					end
					
					Mult_op_3_2 <= (RAM_read_data_a_1[31] == 1'b1) ? {{16{1'b1}}, RAM_read_data_a_1[31:16]} : RAM_read_data_a_1[31:16];
				
					Mult_op_4_2 <= (RAM_read_data_a_1[15] == 1'b1) ? {{16{1'b1}}, RAM_read_data_a_1[15:0]} : RAM_read_data_a_1[15:0];
				
					m2_state <= S_M2_CC_22;
				
				end
				
				S_M2_CC_22: begin
				
					// Update the accumulators
					colAccum_1 <= colAccum_1 + Mult_result_3;
					colAccum_2 <= colAccum_2 + Mult_result_4;
					
					// Read the seventh row of 3 C values from RAM (NOTE: C is PACKED)
					RAM_address_a_1 <= RAM_address_C;
					
					// Increment the addresses
					RAM_address_C <= RAM_address_C + 4;
					
					// Buffer S_prime other sample
					S_prime_buf <= RAM_read_data_a_0[15: 0];
					
					// Read the next sample
					RAM_address_a_0 <= RAM_address_sample + 1;
					
					// Increment sample counter
					RAM_address_sample <= RAM_address_sample + 1;
					
					if (RAM_read_data_a_0[31] == 1'b1) begin
					
						Mult_op_3_1 <= {{16{1'b1}}, RAM_read_data_a_0[31:16]};
					
						Mult_op_4_1 <= {{16{1'b1}}, RAM_read_data_a_0[31:16]};
					
					end else begin
					
						Mult_op_3_1 <= RAM_read_data_a_0[31:16];
					
						Mult_op_4_1 <= RAM_read_data_a_0[31:16];
						
					end
					
					Mult_op_3_2 <= (RAM_read_data_a_1[31] == 1'b1) ? {{16{1'b1}}, RAM_read_data_a_1[31:16]} : RAM_read_data_a_1[31:16];
				
					Mult_op_4_2 <= (RAM_read_data_a_1[15] == 1'b1) ? {{16{1'b1}}, RAM_read_data_a_1[15:0]} : RAM_read_data_a_1[15:0];
	
					m2_state <= S_M2_CC_23;
				
				end
				
				S_M2_CC_23: begin
				
					// Update the accumulators
					colAccum_1 <= colAccum_1 + Mult_result_3;
					colAccum_2 <= colAccum_2 + Mult_result_4;
					
					// Read the eighth row of 3 C values from RAM (NOTE: C is PACKED)
					RAM_address_a_1 <= RAM_address_C;
					
					// Increment the addresses
					RAM_address_C <= 0;
					
					if (S_prime_buf[15] == 1'b1) begin
					
						Mult_op_3_1 <= {{16{1'b1}}, S_prime_buf};
					
						Mult_op_4_1 <= {{16{1'b1}}, S_prime_buf};
					
					end else begin
					
						Mult_op_3_1 <= S_prime_buf;
					
						Mult_op_4_1 <= S_prime_buf;
						
						Mult_op_5_1 <= S_prime_buf;
					
					end
					
					Mult_op_3_2 <= (RAM_read_data_a_1[31] == 1'b1) ? {{16{1'b1}}, RAM_read_data_a_1[31:16]} : RAM_read_data_a_1[31:16];
				
					Mult_op_4_2 <= (RAM_read_data_a_1[15] == 1'b1) ? {{16{1'b1}}, RAM_read_data_a_1[15:0]} : RAM_read_data_a_1[15:0];
				
					m2_state <= S_M2_CC_24;
					
				end
				
				S_M2_CC_24: begin
				
					// Update the accumulators
					colAccum_1 <= colAccum_1 + Mult_result_3;
					colAccum_2 <= colAccum_2 + Mult_result_4;
					
					if (calculationsPerformed != 7) begin
					
						// Read the first row of 3 C values from RAM (NOTE: C is PACKED)
						RAM_address_a_1 <= RAM_address_C;
						RAM_address_b_1 <= RAM_address_C + 1;
						
						// Increment the addresses
						RAM_address_C <= RAM_address_C + 4;
						
						// Buffer S_prime other sample
						S_prime_buf <= RAM_read_data_a_0[15: 0];
						
						// Read the first S' value from RAM (NOTE: S' is PACKED)
						RAM_address_a_0 <= RAM_address_sample + 1;
						
						// Increment sample counter
						RAM_address_sample <= RAM_address_sample + 1;
						
					end
					
					if (RAM_read_data_a_0[31] == 1'b1) begin
					
						Mult_op_3_1 <= {{16{1'b1}}, RAM_read_data_a_0[31:16]};
					
						Mult_op_4_1 <= {{16{1'b1}}, RAM_read_data_a_0[31:16]};
					
					end else begin
					
						Mult_op_3_1 <= RAM_read_data_a_0[31:16];
					
						Mult_op_4_1 <= RAM_read_data_a_0[31:16];
						
					end
					
					Mult_op_3_2 <= (RAM_read_data_a_1[31] == 1'b1) ? {{16{1'b1}}, RAM_read_data_a_1[31:16]} : RAM_read_data_a_1[31:16];
				
					Mult_op_4_2 <= (RAM_read_data_a_1[15] == 1'b1) ? {{16{1'b1}}, RAM_read_data_a_1[15:0]} : RAM_read_data_a_1[15:0];
	
					m2_state <= S_M2_CC_25;
				
				end
				
				S_M2_CC_25: begin
				
					calculationsPerformed <= calculationsPerformed + 1;
					
					// Update the accumulators
					colAccum_1 <= colAccum_1 + Mult_result_3;
					colAccum_2 <= colAccum_2 + Mult_result_4;
				
					if (calculationsPerformed != 7) begin
				
						// Read the second row of 3 C values from RAM (NOTE: C is PACKED)
						RAM_address_a_1 <= RAM_address_C;
						RAM_address_b_1 <= RAM_address_C + 1;
						
						// Increment the addresses
						RAM_address_C <= RAM_address_C + 4;
						
					end
					
					if (S_prime_buf[15] == 1'b1) begin
					
						Mult_op_3_1 <= {{16{1'b1}}, S_prime_buf};
					
						Mult_op_4_1 <= {{16{1'b1}}, S_prime_buf};
					
					end else begin
					
						Mult_op_3_1 <= S_prime_buf;
					
						Mult_op_4_1 <= S_prime_buf;
						
						Mult_op_5_1 <= S_prime_buf;
					
					end
					
					Mult_op_3_2 <= (RAM_read_data_a_1[31] == 1'b1) ? {{16{1'b1}}, RAM_read_data_a_1[31:16]} : RAM_read_data_a_1[31:16];
				
					Mult_op_4_2 <= (RAM_read_data_a_1[15] == 1'b1) ? {{16{1'b1}}, RAM_read_data_a_1[15:0]} : RAM_read_data_a_1[15:0];
				
					isTValueToWrite <= 1;
				
					m2_state <= S_M2_CC_2;
				
				end
				
				S_M2_S_TRANSITION_0: begin
				
					// Update buffers
					T_buf_1 <= colAccum_1 + Mult_result_3;
					T_buf_2 <= colAccum_2 + Mult_result_4;
				
					// The computation of T is complete
					// Matrix multiplication can now begin for S
					
					// Read the first CT value from RAM (NOTE: S' is PACKED)
					RAM_address_a_1 <= RAM_address_sample;
					
					// Read the first row of 3 T values from RAM
					RAM_address_b_0 <= RAM_address_T;
					RAM_address_a_2 <= RAM_address_T + 1;
					RAM_address_b_2 <= RAM_address_T + 2;
					
					// Increment the addresses
					RAM_address_T <= RAM_address_T + 8;
					
					// Set the RAM to read
					RAM_we_n_a_0 <= 0;
					RAM_we_n_b_0 <= 0;
					
					// Set the RAM to read
					RAM_we_n_a_1 <= 0;
					RAM_we_n_b_1 <= 0;
					
					// Set the RAM to read
					RAM_we_n_a_2 <= 0;
					RAM_we_n_b_2 <= 0;
					
					// Set this to 0 for next S' read
					isSPrimeBuffered <= 1'b0;
					
					// Set the write address to 0
					RAM_address_prev <= 0;
					
					if (!isYBlockFinished) begin
					
						// Set the write address to the current block
						SRAM_address_write_M2 <= {M2_row_write, 9'b0} + {M2_row_write, 9'b0} + {M2_row_write, 8'b0} + {M2_col_write, 2'b0};
					
					end
					
					if (isYBlockFinished && !isUBlockFinished) begin
					
						// Set the write address to the current block
						SRAM_address_write_M2 <= 38400 + {M2_row_write, 9'b0} + {M2_row_write, 7'b0} + {M2_col_write, 2'b0};
					
					end
					
					if (isYBlockFinished && isUBlockFinished && !isVBlockFinished) begin
					
						// Set the write address to the current block
						SRAM_address_write_M2 <= 57600 + {M2_row_write, 9'b0} + {M2_row_write, 7'b0} + {M2_col_write, 2'b0};
					
					end
					
					m2_state <= S_M2_S_TRANSITION_1;
				
				end
				
				S_M2_S_TRANSITION_1: begin
				
					// Read the second row of 3 T values from RAM
					RAM_address_b_0 <= RAM_address_T;
					RAM_address_a_2 <= RAM_address_T + 1;
					RAM_address_b_2 <= RAM_address_T + 2;
					
					// Increment the addresses
					RAM_address_T <= RAM_address_T + 8;
					
					m2_state <= S_M2_CC_S_0;
				
				end
				
				S_M2_CC_S_0: begin
				
					// Read the third row of 3 T values from RAM
					RAM_address_b_0 <= RAM_address_T;
					RAM_address_a_2 <= RAM_address_T + 1;
					RAM_address_b_2 <= RAM_address_T + 2;
					
					// Increment the addresses
					RAM_address_T <= RAM_address_T + 8;
					
					// Buffer S_prime other sample
					CT_buf <= RAM_read_data_a_1[15: 0];
					
					// Read the next sample
					RAM_address_a_1 <= RAM_address_sample + 1;
					
					// Increment sample counter
					RAM_address_sample <= RAM_address_sample + 1;
					
					isFinishedWritingSPrime <= 0;
					
					finBlockHold <= 0;
					
					if (RAM_read_data_a_1[31] == 1'b1) begin
					
						Mult_op_3_1 <= {{16{1'b1}}, RAM_read_data_a_1[31:16]};
					
						Mult_op_4_1 <= {{16{1'b1}}, RAM_read_data_a_1[31:16]};
						
						Mult_op_5_1 <= {{16{1'b1}}, RAM_read_data_a_1[31:16]};
					
					end else begin
					
						Mult_op_3_1 <= RAM_read_data_a_1[31:16];
					
						Mult_op_4_1 <= RAM_read_data_a_1[31:16];
						
						Mult_op_5_1 <= RAM_read_data_a_1[31:16];
						
					end
					
					Mult_op_3_2 <= RAM_read_data_b_0;
				
					Mult_op_4_2 <= RAM_read_data_a_2;
					
					Mult_op_5_2 <= RAM_read_data_b_2;
					
					m2_state <= S_M2_CC_S_1;
				
				end
				
				S_M2_CC_S_1: begin
				
					if (isSValueToWrite) begin
					
						if (T_buf_1[31] == 1'b1) begin
					
							if (T_buf_2[31] == 1'b1) begin
							
								S_buf_4 <= {8'd0, 8'd0};
							
							end else begin
							
								if (T_buf_2[30:24] == 7'b0000000) begin
								
									S_buf_4 <= {8'd0, T_buf_2[23:16]};
							
								end else begin
								
									S_buf_4 <= {8'd0, 8'd255};
									
								end
							
							end
						
						end else begin
						
							if (T_buf_2[31] == 1'b1) begin
							
								if (T_buf_1[30:24] == 7'b0000000) begin
								
									S_buf_4 <= {T_buf_1[23:16], 8'd0};
							
								end else begin
								
									S_buf_4 <= {8'd255, 8'd0};
									
								end
							
							end else begin
							
								if (T_buf_1[30:24] == 7'b0000000) begin
								
									if (T_buf_2[30:24] == 7'b0000000) begin
									
										S_buf_4 <= {T_buf_1[23:16], T_buf_2[23:16]};
									
									end else begin
									
										S_buf_4 <= {T_buf_1[23:16], 8'd255};
									
									end
							
								end else begin
								
									if (T_buf_2[30:24] == 7'b0000000) begin
									
										S_buf_4 <= {8'd255, T_buf_2[23:16]};
									
									end else begin
									
										S_buf_4 <= {8'd255, 8'd255};
									
									end
									
								end
							
							end
						
						end
						
						SRAM_address_M2 <= SRAM_address_write_M2;
						
						SRAM_write_data_M2 <= S_buf_1;
					
						SRAM_we_n_M2 <= 1'b0;
						
					end
					
					if (calculationsPerformed != 8) begin
				
						// Update the accumulators
						colAccum_1 <= colAccum_1 + Mult_result_3;
						colAccum_2 <= colAccum_2 + Mult_result_4;
						colAccum_3 <= colAccum_3 + Mult_result_5;
					
						// Read the fourth row of 3 T values from RAM
						RAM_address_b_0 <= RAM_address_T;
						RAM_address_a_2 <= RAM_address_T + 1;
						RAM_address_b_2 <= RAM_address_T + 2;
						
						// Increment the addresses
						RAM_address_T <= RAM_address_T + 8;
						
						if (CT_buf[15] == 1'b1) begin
						
							Mult_op_3_1 <= {{16{1'b1}}, CT_buf};
						
							Mult_op_4_1 <= {{16{1'b1}}, CT_buf};
							
							Mult_op_5_1 <= {{16{1'b1}}, CT_buf};
						
						end else begin
						
							Mult_op_3_1 <= CT_buf;
						
							Mult_op_4_1 <= CT_buf;
							
							Mult_op_5_1 <= CT_buf;
						
						end
						
						Mult_op_3_2 <= RAM_read_data_b_0;
					
						Mult_op_4_2 <= RAM_read_data_a_2;
						
						Mult_op_5_2 <= RAM_read_data_b_2;
						
					end
					
					m2_state <= S_M2_CC_S_2;
				
				end
				
				S_M2_CC_S_2: begin
				
					if (isSValueToWrite) begin
					
						SRAM_address_M2 <= SRAM_address_write_M2 + 1;
						
						SRAM_write_data_M2 <= S_buf_2;
					
						SRAM_we_n_M2 <= 1'b0;
						
					end
					
					if (calculationsPerformed != 8) begin
				
						// Update the accumulators
						colAccum_1 <= colAccum_1 + Mult_result_3;
						colAccum_2 <= colAccum_2 + Mult_result_4;
						colAccum_3 <= colAccum_3 + Mult_result_5;
						
						// Read the fifth row of 3 T values from RAM
						RAM_address_b_0 <= RAM_address_T;
						RAM_address_a_2 <= RAM_address_T + 1;
						RAM_address_b_2 <= RAM_address_T + 2;
						
						// Increment the addresses
						RAM_address_T <= RAM_address_T + 8;
						
						// Buffer S_prime other sample
						CT_buf <= RAM_read_data_a_1[15: 0];
						
						// Read the next sample
						RAM_address_a_1 <= RAM_address_sample + 1;
						
						// Increment sample counter
						RAM_address_sample <= RAM_address_sample + 1;
						
						if (RAM_read_data_a_1[31] == 1'b1) begin
						
							Mult_op_3_1 <= {{16{1'b1}}, RAM_read_data_a_1[31:16]};
						
							Mult_op_4_1 <= {{16{1'b1}}, RAM_read_data_a_1[31:16]};
							
							Mult_op_5_1 <= {{16{1'b1}}, RAM_read_data_a_1[31:16]};
						
						end else begin
						
							Mult_op_3_1 <= RAM_read_data_a_1[31:16];
						
							Mult_op_4_1 <= RAM_read_data_a_1[31:16];
							
							Mult_op_5_1 <= RAM_read_data_a_1[31:16];
							
						end
						
						Mult_op_3_2 <= RAM_read_data_b_0;
					
						Mult_op_4_2 <= RAM_read_data_a_2;
						
						Mult_op_5_2 <= RAM_read_data_b_2;
					
					end
				
					m2_state <= S_M2_CC_S_3;
				
				end
				
				S_M2_CC_S_3: begin
				
					if (isSValueToWrite) begin
					
						SRAM_address_M2 <= SRAM_address_write_M2 + 2;
						
						SRAM_write_data_M2 <= S_buf_3;
					
						SRAM_we_n_M2 <= 1'b0;
						
					end
					
					if (calculationsPerformed != 8) begin
				
						// Update the accumulators
						colAccum_1 <= colAccum_1 + Mult_result_3;
						colAccum_2 <= colAccum_2 + Mult_result_4;
						colAccum_3 <= colAccum_3 + Mult_result_5;
					
						// Read the sixth row of 3 T values from RAM
						RAM_address_b_0 <= RAM_address_T;
						RAM_address_a_2 <= RAM_address_T + 1;
						RAM_address_b_2 <= RAM_address_T + 2;
						
						// Increment the addresses
						RAM_address_T <= RAM_address_T + 8;
						
						if (CT_buf[15] == 1'b1) begin
						
							Mult_op_3_1 <= {{16{1'b1}}, CT_buf};
						
							Mult_op_4_1 <= {{16{1'b1}}, CT_buf};
							
							Mult_op_5_1 <= {{16{1'b1}}, CT_buf};
						
						end else begin
						
							Mult_op_3_1 <= CT_buf;
						
							Mult_op_4_1 <= CT_buf;
							
							Mult_op_5_1 <= CT_buf;
						
						end
						
						Mult_op_3_2 <= RAM_read_data_b_0;
					
						Mult_op_4_2 <= RAM_read_data_a_2;
						
						Mult_op_5_2 <= RAM_read_data_b_2;
				
					end
				
					m2_state <= S_M2_CC_S_4;
				
				end
				
				S_M2_CC_S_4: begin
				
					if (isSValueToWrite) begin
					
						SRAM_address_M2 <= SRAM_address_write_M2 + 3;
						
						SRAM_write_data_M2 <= S_buf_4;
					
						SRAM_we_n_M2 <= 1'b0;
						
						isSValueToWrite <= 0;
						
						if (!isYBlockFinished) begin
						
							SRAM_address_write_M2 <= SRAM_address_write_M2 + 160;
						
						end else begin
						
							SRAM_address_write_M2 <= SRAM_address_write_M2 + 80;
						
						end
						
					end
					
					if (calculationsPerformed != 8) begin
				
						// Update the accumulators
						colAccum_1 <= colAccum_1 + Mult_result_3;
						colAccum_2 <= colAccum_2 + Mult_result_4;
						colAccum_3 <= colAccum_3 + Mult_result_5;
						
						// Read the seventh row of 3 T values from RAM
						RAM_address_b_0 <= RAM_address_T;
						RAM_address_a_2 <= RAM_address_T + 1;
						RAM_address_b_2 <= RAM_address_T + 2;
						
						// Increment the addresses
						RAM_address_T <= RAM_address_T + 8;
						
						// Buffer S_prime other sample
						CT_buf <= RAM_read_data_a_1[15: 0];
						
						// Read the next sample
						RAM_address_a_1 <= RAM_address_sample + 1;
						
						// Increment sample counter
						RAM_address_sample <= RAM_address_sample + 1;
						
						if (RAM_read_data_a_1[31] == 1'b1) begin
						
							Mult_op_3_1 <= {{16{1'b1}}, RAM_read_data_a_1[31:16]};
						
							Mult_op_4_1 <= {{16{1'b1}}, RAM_read_data_a_1[31:16]};
							
							Mult_op_5_1 <= {{16{1'b1}}, RAM_read_data_a_1[31:16]};
						
						end else begin
						
							Mult_op_3_1 <= RAM_read_data_a_1[31:16];
						
							Mult_op_4_1 <= RAM_read_data_a_1[31:16];
							
							Mult_op_5_1 <= RAM_read_data_a_1[31:16];
							
						end
						
						Mult_op_3_2 <= RAM_read_data_b_0;
					
						Mult_op_4_2 <= RAM_read_data_a_2;
						
						Mult_op_5_2 <= RAM_read_data_b_2;
						
						m2_state <= S_M2_CC_S_5;
						
					end else begin
					
						if (!isYBlockFinished) begin
						
							if (M2_col_index == 39) begin
							
								M2_col_index <= 0;
								
								if (M2_row_index == 29) begin
								
									M2_col_index <= 0;
									
									M2_row_index <= 0;
									
									switchAddrGen <= 1;
									
									SC_base_address <= 18'd153600;
									
								end else begin
								
									M2_row_index <= M2_row_index + 1;
									
								end
								
							end else begin
							
								M2_col_index <= M2_col_index + 1;
								
							end
						
						end else begin
						
							if (!isUBlockFinished) begin
						
								if (M2_col_index == 19) begin
								
									M2_col_index <= 0;
									
									if (M2_row_index == 29) begin
									
										M2_col_index <= 0;
										
										M2_row_index <= 0;
										
										SC_base_address <= 18'd192000;
									
									end else begin
									
										M2_row_index <= M2_row_index + 1;
										
									end
									
								end else begin
								
									M2_col_index <= M2_col_index + 1;
									
								end
								
							end else begin
							
								if (M2_col_index == 19) begin
								
									M2_col_index <= 0;
									
									if (M2_row_index == 29) begin
									
										M2_col_index <= 0;
										
										M2_row_index <= 0;
										
										SC_base_address <= 18'd76800;
									
									end else begin
									
										M2_row_index <= M2_row_index + 1;
										
									end
									
								end else begin
								
									M2_col_index <= M2_col_index + 1;
									
								end
							
							end
						
						end
						
						calculationsPerformed <= 0;
						
						RAM_address_T <= 64;
						
						RAM_address_C <= 0;
						
						RAM_address_sample <= 0;
						
						if (!isYBlockFinished) begin
						
							if (M2_col_write == 39) begin
						
								M2_col_write <= 0;
								
								if (M2_row_write == 29) begin
								
									M2_row_write <= 0;
									
									isYBlockFinished <= 1;
									
								end else begin
								
									M2_row_write <= M2_row_write + 1;
							
								end
								
							end else begin
							
								M2_col_write <= M2_col_write + 1;
							
							end
						
						end else begin
						
							if (!isUBlockFinished) begin
						
								if (M2_col_write == 19) begin
							
									M2_col_write <= 0;
									
									if (M2_row_write == 29) begin
									
										M2_row_write <= 0;
										
										isUBlockFinished <= 1;
										
									end else begin
									
										M2_row_write <= M2_row_write + 1;
								
									end
									
								end else begin
								
									M2_col_write <= M2_col_write + 1;
								
								end
								
							end else begin
							
								if (M2_col_write == 19) begin
							
									M2_col_write <= 0;
									
									if (M2_row_write == 29) begin
									
										M2_row_write <= 0;
										
										isVBlockFinished <= 1;
										
									end else begin
									
										M2_row_write <= M2_row_write + 1;
								
									end
									
								end else begin
								
									M2_col_write <= M2_col_write + 1;
								
								end
							
							end
						
						end
						
						m2_state <= S_M2_CC_0;
	
					end
				
				end
				
				S_M2_CC_S_5: begin
					
					if (!fetchedSPrime || isFinishedWritingSPrime == 0) begin
					
						sampleCounterEnabled <= 1;
					
					end
					
					SRAM_we_n_M2 <= 1'b1;
					
					// Update the accumulators
					colAccum_1 <= colAccum_1 + Mult_result_3;
					colAccum_2 <= colAccum_2 + Mult_result_4;
					colAccum_3 <= colAccum_3 + Mult_result_5;
				
					// Read the eighth row of 3 T values from RAM
					RAM_address_b_0 <= RAM_address_T;
					RAM_address_a_2 <= RAM_address_T + 1;
					RAM_address_b_2 <= RAM_address_T + 2;
					
					// Increment the addresses
					RAM_address_T <= 67;
					
					if (CT_buf[15] == 1'b1) begin
					
						Mult_op_3_1 <= {{16{1'b1}}, CT_buf};
					
						Mult_op_4_1 <= {{16{1'b1}}, CT_buf};
						
						Mult_op_5_1 <= {{16{1'b1}}, CT_buf};
					
					end else begin
					
						Mult_op_3_1 <= CT_buf;
					
						Mult_op_4_1 <= CT_buf;
						
						Mult_op_5_1 <= CT_buf;
					
					end
					
					Mult_op_3_2 <= RAM_read_data_b_0;
				
					Mult_op_4_2 <= RAM_read_data_a_2;
					
					Mult_op_5_2 <= RAM_read_data_b_2;
				
					m2_state <= S_M2_CC_S_6;
				
				end
				
				S_M2_CC_S_6: begin
					
					// Update the accumulators
					colAccum_1 <= colAccum_1 + Mult_result_3;
					colAccum_2 <= colAccum_2 + Mult_result_4;
					colAccum_3 <= colAccum_3 + Mult_result_5;
					
					// Read the first row of 3 T values from RAM
					RAM_address_b_0 <= RAM_address_T;
					RAM_address_a_2 <= RAM_address_T + 1;
					RAM_address_b_2 <= RAM_address_T + 2;
					
					// Increment the addresses
					RAM_address_T <= RAM_address_T + 8;
					
					// Buffer S_prime other sample
					CT_buf <= RAM_read_data_a_1[15: 0];
					
					// Read the next sample
					RAM_address_a_1 <= RAM_address_sample - 3;
					RAM_address_sample <= RAM_address_sample - 3;
					
					if (RAM_read_data_a_1[31] == 1'b1) begin
					
						Mult_op_3_1 <= {{16{1'b1}}, RAM_read_data_a_1[31:16]};
					
						Mult_op_4_1 <= {{16{1'b1}}, RAM_read_data_a_1[31:16]};
						
						Mult_op_5_1 <= {{16{1'b1}}, RAM_read_data_a_1[31:16]};
					
					end else begin
					
						Mult_op_3_1 <= RAM_read_data_a_1[31:16];
					
						Mult_op_4_1 <= RAM_read_data_a_1[31:16];
						
						Mult_op_5_1 <= RAM_read_data_a_1[31:16];
						
					end
					
					Mult_op_3_2 <= RAM_read_data_b_0;
				
					Mult_op_4_2 <= RAM_read_data_a_2;
					
					Mult_op_5_2 <= RAM_read_data_b_2;
				
					m2_state <= S_M2_CC_S_7;
				
				end
				
				S_M2_CC_S_7: begin
				
					if (!fetchedSPrime || isFinishedWritingSPrime == 0) begin
					
						// Set the address to the pre-IDCT offset to get the next S'
						SRAM_address_M2 <= M2_address_generation;
						
					end
				
					// Update the accumulators
					colAccum_1 <= colAccum_1 + Mult_result_3;
					colAccum_2 <= colAccum_2 + Mult_result_4;
					colAccum_3 <= colAccum_3 + Mult_result_5;
				
					// Read the second row of 3 T values from RAM
					RAM_address_b_0 <= RAM_address_T;
					RAM_address_a_2 <= RAM_address_T + 1;
					RAM_address_b_2 <= RAM_address_T + 2;
					
					// Increment the addresses
					RAM_address_T <= RAM_address_T + 8;
					
					if (CT_buf[15] == 1'b1) begin
					
						Mult_op_3_1 <= {{16{1'b1}}, CT_buf};
					
						Mult_op_4_1 <= {{16{1'b1}}, CT_buf};
						
						Mult_op_5_1 <= {{16{1'b1}}, CT_buf};
					
					end else begin
					
						Mult_op_3_1 <= CT_buf;
					
						Mult_op_4_1 <= CT_buf;
						
						Mult_op_5_1 <= CT_buf;
					
					end
					
					Mult_op_3_2 <= RAM_read_data_b_0;
				
					Mult_op_4_2 <= RAM_read_data_a_2;
					
					Mult_op_5_2 <= RAM_read_data_b_2;
				
					m2_state <= S_M2_CC_S_8;
				
				end
				
				S_M2_CC_S_8: begin
					
					if (!fetchedSPrime || isFinishedWritingSPrime == 0) begin
					
						// Set the address to the pre-IDCT offset to get the next S'
						SRAM_address_M2 <= M2_address_generation;
						
					end
					
					// Update buffers
					T_buf_1 <= colAccum_1 + Mult_result_3;
					T_buf_2 <= colAccum_2 + Mult_result_4;
					T_buf_3 <= colAccum_3 + Mult_result_5;
					
					S_write_buf <= colAccum_3 + Mult_result_5;
					
					// Update the accumulators
					colAccum_1 <= 0;
					colAccum_2 <= 0;
					colAccum_3 <= 0;
				
					// Read the third row of 3 T values from RAM
					RAM_address_b_0 <= RAM_address_T;
					RAM_address_a_2 <= RAM_address_T + 1;
					RAM_address_b_2 <= RAM_address_T + 2;
					
					// Increment the addresses
					RAM_address_T <= RAM_address_T + 8;
					
					// Buffer S_prime other sample
					CT_buf <= RAM_read_data_a_1[15: 0];
					
					// Read the next sample
					RAM_address_a_1 <= RAM_address_sample + 1;
					
					// Increment the addresses
					RAM_address_sample <= RAM_address_sample + 1;
					
					if (RAM_read_data_a_1[31] == 1'b1) begin
					
						Mult_op_3_1 <= {{16{1'b1}}, RAM_read_data_a_1[31:16]};
					
						Mult_op_4_1 <= {{16{1'b1}}, RAM_read_data_a_1[31:16]};
						
						Mult_op_5_1 <= {{16{1'b1}}, RAM_read_data_a_1[31:16]};
					
					end else begin
					
						Mult_op_3_1 <= RAM_read_data_a_1[31:16];
					
						Mult_op_4_1 <= RAM_read_data_a_1[31:16];
						
						Mult_op_5_1 <= RAM_read_data_a_1[31:16];
						
					end
					
					Mult_op_3_2 <= RAM_read_data_b_0;
				
					Mult_op_4_2 <= RAM_read_data_a_2;
					
					Mult_op_5_2 <= RAM_read_data_b_2;
				
					m2_state <= S_M2_CC_S_9;
				
				end
				
				S_M2_CC_S_9: begin
				
					if (!fetchedSPrime || isFinishedWritingSPrime == 0) begin
					
						// Set the address to the pre-IDCT offset to get the next S'
						SRAM_address_M2 <= M2_address_generation;
						
					end
				
					// CALC FINISHED
					if (T_buf_1[31] == 1'b1) begin
					
						if (T_buf_2[31] == 1'b1) begin
						
							S_buf_1 <= {8'd0, 8'd0};
						
						end else begin
						
							if (T_buf_2[30:24] == 7'b0000000) begin
							
								S_buf_1 <= {8'd0, T_buf_2[23:16]};
						
							end else begin
							
								S_buf_1 <= {8'd0, 8'd255};
								
							end
						
						end
					
					end else begin
					
						if (T_buf_2[31] == 1'b1) begin
						
							if (T_buf_1[30:24] == 7'b0000000) begin
							
								S_buf_1 <= {T_buf_1[23:16], 8'd0};
						
							end else begin
							
								S_buf_1 <= {8'd255, 8'd0};
								
							end
						
						end else begin
						
							if (T_buf_1[30:24] == 7'b0000000) begin
							
								if (T_buf_2[30:24] == 7'b0000000) begin
								
									S_buf_1 <= {T_buf_1[23:16], T_buf_2[23:16]};
								
								end else begin
								
									S_buf_1 <= {T_buf_1[23:16], 8'd255};
								
								end
						
							end else begin
							
								if (T_buf_2[30:24] == 7'b0000000) begin
								
									S_buf_1 <= {8'd255, T_buf_2[23:16]};
								
								end else begin
								
									S_buf_1 <= {8'd255, 8'd255};
								
								end
								
							end
						
						end
					
					end
					
					// Update the accumulators
					colAccum_1 <= colAccum_1 + Mult_result_3;
					colAccum_2 <= colAccum_2 + Mult_result_4;
					colAccum_3 <= colAccum_3 + Mult_result_5;
				
					// Read the fourth row of 3 T values from RAM
					RAM_address_b_0 <= RAM_address_T;
					RAM_address_a_2 <= RAM_address_T + 1;
					RAM_address_b_2 <= RAM_address_T + 2;
					
					// Increment the addresses
					RAM_address_T <= RAM_address_T + 8;
					
					if (CT_buf[15] == 1'b1) begin
					
						Mult_op_3_1 <= {{16{1'b1}}, CT_buf};
					
						Mult_op_4_1 <= {{16{1'b1}}, CT_buf};
						
						Mult_op_5_1 <= {{16{1'b1}}, CT_buf};
					
					end else begin
					
						Mult_op_3_1 <= CT_buf;
					
						Mult_op_4_1 <= CT_buf;
						
						Mult_op_5_1 <= CT_buf;
					
					end
					
					Mult_op_3_2 <= RAM_read_data_b_0;
				
					Mult_op_4_2 <= RAM_read_data_a_2;
					
					Mult_op_5_2 <= RAM_read_data_b_2;
				
					m2_state <= S_M2_CC_S_10;
				
				end
				
				S_M2_CC_S_10: begin
				
					if (!fetchedSPrime || isFinishedWritingSPrime == 0) begin
					
						// Set the address to the pre-IDCT offset to get the next S'
						SRAM_address_M2 <= M2_address_generation;
						
						if (isSPrimeBuffered == 1'd0) begin
					
							S_prime_buf <= SRAM_read_data;
							
							isSPrimeBuffered <= 1'd1;
							
						end else begin
						
							RAM_write_data_a_0 <= {S_prime_buf, SRAM_read_data};
							
							// Set RAM address to the correct write address
							RAM_address_a_0 <= RAM_address_prev;
						
							// Increment the RAM address offset
							RAM_address_prev <= RAM_address_prev + 1;
							
							// Set write enable to write
							RAM_we_n_a_0 <= 1;
							
							isSPrimeBuffered <= 1'd0;
					
						end
						
					end
					
					// Update the accumulators
					colAccum_1 <= colAccum_1 + Mult_result_3;
					colAccum_2 <= colAccum_2 + Mult_result_4;
					colAccum_3 <= colAccum_3 + Mult_result_5;
				
					// Read the fifth row of 3 T values from RAM
					RAM_address_b_0 <= RAM_address_T;
					RAM_address_a_2 <= RAM_address_T + 1;
					RAM_address_b_2 <= RAM_address_T + 2;
					
					// Increment the addresses
					RAM_address_T <= RAM_address_T + 8;
					
					// Buffer S_prime other sample
					CT_buf <= RAM_read_data_a_1[15: 0];
					
					// Read the next sample
					RAM_address_a_1 <= RAM_address_sample + 1;
					
					// Increment the addresses
					RAM_address_sample <= RAM_address_sample + 1;
					
					if (RAM_read_data_a_1[31] == 1'b1) begin
					
						Mult_op_3_1 <= {{16{1'b1}}, RAM_read_data_a_1[31:16]};
					
						Mult_op_4_1 <= {{16{1'b1}}, RAM_read_data_a_1[31:16]};
						
						Mult_op_5_1 <= {{16{1'b1}}, RAM_read_data_a_1[31:16]};
					
					end else begin
					
						Mult_op_3_1 <= RAM_read_data_a_1[31:16];
					
						Mult_op_4_1 <= RAM_read_data_a_1[31:16];
						
						Mult_op_5_1 <= RAM_read_data_a_1[31:16];
						
					end
					
					Mult_op_3_2 <= RAM_read_data_b_0;
				
					Mult_op_4_2 <= RAM_read_data_a_2;
					
					Mult_op_5_2 <= RAM_read_data_b_2;
				
					m2_state <= S_M2_CC_S_11;
				
				end
				
				S_M2_CC_S_11: begin
				
					if (!fetchedSPrime || isFinishedWritingSPrime == 0) begin
					
						// Set the address to the pre-IDCT offset to get the next S'
						SRAM_address_M2 <= M2_address_generation;
						
						if (isSPrimeBuffered == 1'd0) begin
					
							S_prime_buf <= SRAM_read_data;
							
							isSPrimeBuffered <= 1'd1;
							
						end else begin
						
							RAM_write_data_a_0 <= {S_prime_buf, SRAM_read_data};
							
							// Set RAM address to the correct write address
							RAM_address_a_0 <= RAM_address_prev;
						
							// Increment the RAM address offset
							RAM_address_prev <= RAM_address_prev + 1;
							
							// Set write enable to write
							RAM_we_n_a_0 <= 1;
							
							isSPrimeBuffered <= 1'd0;
					
						end
						
					end
				
					// Update the accumulators
					colAccum_1 <= colAccum_1 + Mult_result_3;
					colAccum_2 <= colAccum_2 + Mult_result_4;
					colAccum_3 <= colAccum_3 + Mult_result_5;
				
					// Read the sixth row of 3 T values from RAM
					RAM_address_b_0 <= RAM_address_T;
					RAM_address_a_2 <= RAM_address_T + 1;
					RAM_address_b_2 <= RAM_address_T + 2;
					
					// Increment the addresses
					RAM_address_T <= RAM_address_T + 8;
					
					if (CT_buf[15] == 1'b1) begin
					
						Mult_op_3_1 <= {{16{1'b1}}, CT_buf};
					
						Mult_op_4_1 <= {{16{1'b1}}, CT_buf};
						
						Mult_op_5_1 <= {{16{1'b1}}, CT_buf};
					
					end else begin
					
						Mult_op_3_1 <= CT_buf;
					
						Mult_op_4_1 <= CT_buf;
						
						Mult_op_5_1 <= CT_buf;
					
					end
					
					Mult_op_3_2 <= RAM_read_data_b_0;
				
					Mult_op_4_2 <= RAM_read_data_a_2;
					
					Mult_op_5_2 <= RAM_read_data_b_2;
				
					m2_state <= S_M2_CC_S_12;
				
				end
				
				S_M2_CC_S_12: begin
				
					if (!fetchedSPrime || isFinishedWritingSPrime == 0) begin
					
						// Set the address to the pre-IDCT offset to get the next S'
						SRAM_address_M2 <= M2_address_generation;
						
						if (isSPrimeBuffered == 1'd0) begin
					
							S_prime_buf <= SRAM_read_data;
							
							isSPrimeBuffered <= 1'd1;
							
						end else begin
						
							RAM_write_data_a_0 <= {S_prime_buf, SRAM_read_data};
							
							// Set RAM address to the correct write address
							RAM_address_a_0 <= RAM_address_prev;
						
							// Increment the RAM address offset
							RAM_address_prev <= RAM_address_prev + 1;
							
							// Set write enable to write
							RAM_we_n_a_0 <= 1;
							
							isSPrimeBuffered <= 1'd0;
					
						end
						
					end
				
					// Update the accumulators
					colAccum_1 <= colAccum_1 + Mult_result_3;
					colAccum_2 <= colAccum_2 + Mult_result_4;
					colAccum_3 <= colAccum_3 + Mult_result_5;
				
					// Read the seventh row of 3 T values from RAM
					RAM_address_b_0 <= RAM_address_T;
					RAM_address_a_2 <= RAM_address_T + 1;
					RAM_address_b_2 <= RAM_address_T + 2;
					
					// Increment the addresses
					RAM_address_T <= RAM_address_T + 8;
					
					// Buffer S_prime other sample
					CT_buf <= RAM_read_data_a_1[15: 0];
					
					// Read the next sample
					RAM_address_a_1 <= RAM_address_sample + 1;
					
					// Increment the addresses
					RAM_address_sample <= RAM_address_sample + 1;
					
					if (RAM_read_data_a_1[31] == 1'b1) begin
					
						Mult_op_3_1 <= {{16{1'b1}}, RAM_read_data_a_1[31:16]};
					
						Mult_op_4_1 <= {{16{1'b1}}, RAM_read_data_a_1[31:16]};
						
						Mult_op_5_1 <= {{16{1'b1}}, RAM_read_data_a_1[31:16]};
					
					end else begin
					
						Mult_op_3_1 <= RAM_read_data_a_1[31:16];
					
						Mult_op_4_1 <= RAM_read_data_a_1[31:16];
						
						Mult_op_5_1 <= RAM_read_data_a_1[31:16];
						
					end
					
					Mult_op_3_2 <= RAM_read_data_b_0;
				
					Mult_op_4_2 <= RAM_read_data_a_2;
					
					Mult_op_5_2 <= RAM_read_data_b_2;
				
					m2_state <= S_M2_CC_S_13;
				
				end
				
				S_M2_CC_S_13: begin
				
					if (!fetchedSPrime || isFinishedWritingSPrime == 0) begin
					
						// Set the address to the pre-IDCT offset to get the next S'
						SRAM_address_M2 <= M2_address_generation;
						
						if (isSPrimeBuffered == 1'd0) begin
					
							S_prime_buf <= SRAM_read_data;
							
							isSPrimeBuffered <= 1'd1;
							
						end else begin
						
							RAM_write_data_a_0 <= {S_prime_buf, SRAM_read_data};
							
							// Set RAM address to the correct write address
							RAM_address_a_0 <= RAM_address_prev;
						
							// Increment the RAM address offset
							RAM_address_prev <= RAM_address_prev + 1;
							
							// Set write enable to write
							RAM_we_n_a_0 <= 1;
							
							isSPrimeBuffered <= 1'd0;
					
						end
						
					end
				
					sampleCounterEnabled <= 0;
				
					// Update the accumulators
					colAccum_1 <= colAccum_1 + Mult_result_3;
					colAccum_2 <= colAccum_2 + Mult_result_4;
					colAccum_3 <= colAccum_3 + Mult_result_5;
				
					// Read the eighth row of 3 T values from RAM
					RAM_address_b_0 <= RAM_address_T;
					RAM_address_a_2 <= RAM_address_T + 1;
					RAM_address_b_2 <= RAM_address_T + 2;
					
					// Increment the addresses
					RAM_address_T <= 70;
					
					if (CT_buf[15] == 1'b1) begin
					
						Mult_op_3_1 <= {{16{1'b1}}, CT_buf};
					
						Mult_op_4_1 <= {{16{1'b1}}, CT_buf};
						
						Mult_op_5_1 <= {{16{1'b1}}, CT_buf};
					
					end else begin
					
						Mult_op_3_1 <= CT_buf;
					
						Mult_op_4_1 <= CT_buf;
						
						Mult_op_5_1 <= CT_buf;
					
					end
					
					Mult_op_3_2 <= RAM_read_data_b_0;
				
					Mult_op_4_2 <= RAM_read_data_a_2;
					
					Mult_op_5_2 <= RAM_read_data_b_2;
				
					m2_state <= S_M2_CC_S_14;
				
				end
				
				S_M2_CC_S_14: begin
					
					if (!fetchedSPrime || isFinishedWritingSPrime == 0) begin
					
						// Set the address to the pre-IDCT offset to get the next S'
						SRAM_address_M2 <= M2_address_generation;
					
						if (isSPrimeBuffered == 1'd0) begin
					
							S_prime_buf <= SRAM_read_data;
							
							isSPrimeBuffered <= 1'd1;
							
						end else begin
						
							RAM_write_data_a_0 <= {S_prime_buf, SRAM_read_data};
							
							// Set RAM address to the correct write address
							RAM_address_a_0 <= RAM_address_prev;
						
							// Increment the RAM address offset
							RAM_address_prev <= RAM_address_prev + 1;
							
							// Set write enable to write
							RAM_we_n_a_0 <= 1;
							
							isSPrimeBuffered <= 1'd0;
					
						end
						
					end
					
					if (isFinishedBlock) begin
				
						fetchedSPrime <= 1;
						
						finBlockHold <= 1;
						
						isFinishedWritingSPrime <= 0;
				
					end
				
					// Update the accumulators
					colAccum_1 <= colAccum_1 + Mult_result_3;
					colAccum_2 <= colAccum_2 + Mult_result_4;
					colAccum_3 <= colAccum_3 + Mult_result_5;
					
					// Read the first row of 2 T values from RAM
					RAM_address_b_0 <= RAM_address_T;
					RAM_address_a_2 <= RAM_address_T + 1;
					
					// Increment the addresses
					RAM_address_T <= RAM_address_T + 8;
					
					// Buffer S_prime other sample
					CT_buf <= RAM_read_data_a_1[15: 0];
					
					// Read the next sample
					RAM_address_a_1 <= RAM_address_sample - 3;
					RAM_address_sample <= RAM_address_sample - 3;
					
					if (RAM_read_data_a_1[31] == 1'b1) begin
					
						Mult_op_3_1 <= {{16{1'b1}}, RAM_read_data_a_1[31:16]};
					
						Mult_op_4_1 <= {{16{1'b1}}, RAM_read_data_a_1[31:16]};
						
						Mult_op_5_1 <= {{16{1'b1}}, RAM_read_data_a_1[31:16]};
					
					end else begin
					
						Mult_op_3_1 <= RAM_read_data_a_1[31:16];
					
						Mult_op_4_1 <= RAM_read_data_a_1[31:16];
						
						Mult_op_5_1 <= RAM_read_data_a_1[31:16];
						
					end
					
					Mult_op_3_2 <= RAM_read_data_b_0;
				
					Mult_op_4_2 <= RAM_read_data_a_2;
					
					Mult_op_5_2 <= RAM_read_data_b_2;
				
					m2_state <= S_M2_CC_S_15;
				
				end
				
				S_M2_CC_S_15: begin
				
					if (!fetchedSPrime || isFinishedWritingSPrime == 0) begin
					
						if (isSPrimeBuffered == 1'd0) begin
					
							S_prime_buf <= SRAM_read_data;
							
							isSPrimeBuffered <= 1'd1;
							
						end else begin
						
							RAM_write_data_a_0 <= {S_prime_buf, SRAM_read_data};
							
							// Set RAM address to the correct write address
							RAM_address_a_0 <= RAM_address_prev;
						
							// Increment the RAM address offset
							RAM_address_prev <= RAM_address_prev + 1;
							
							// Set write enable to write
							RAM_we_n_a_0 <= 1;
							
							isSPrimeBuffered <= 1'd0;
					
						end
						
					end
				
					// Update the accumulators
					colAccum_1 <= colAccum_1 + Mult_result_3;
					colAccum_2 <= colAccum_2 + Mult_result_4;
					colAccum_3 <= colAccum_3 + Mult_result_5;
				
					// Read the second row of 2 T values from RAM
					RAM_address_b_0 <= RAM_address_T;
					RAM_address_a_2 <= RAM_address_T + 1;
					
					// Increment the addresses
					RAM_address_T <= RAM_address_T + 8;
					
					if (CT_buf[15] == 1'b1) begin
					
						Mult_op_3_1 <= {{16{1'b1}}, CT_buf};
					
						Mult_op_4_1 <= {{16{1'b1}}, CT_buf};
						
						Mult_op_5_1 <= {{16{1'b1}}, CT_buf};
					
					end else begin
					
						Mult_op_3_1 <= CT_buf;
					
						Mult_op_4_1 <= CT_buf;
						
						Mult_op_5_1 <= CT_buf;
					
					end
					
					Mult_op_3_2 <= RAM_read_data_b_0;
				
					Mult_op_4_2 <= RAM_read_data_a_2;
					
					Mult_op_5_2 <= RAM_read_data_b_2;
				
					m2_state <= S_M2_CC_S_16;
				
				end
				
				S_M2_CC_S_16: begin
				
					if (!fetchedSPrime || isFinishedWritingSPrime == 0) begin
					
						if (isSPrimeBuffered == 1'd0) begin
					
							S_prime_buf <= SRAM_read_data;
							
							isSPrimeBuffered <= 1'd1;
							
						end else begin
						
							RAM_write_data_a_0 <= {S_prime_buf, SRAM_read_data};
							
							// Set RAM address to the correct write address
							RAM_address_a_0 <= RAM_address_prev;
						
							// Increment the RAM address offset
							RAM_address_prev <= RAM_address_prev + 1;
							
							// Set write enable to write
							RAM_we_n_a_0 <= 1;
							
							isSPrimeBuffered <= 1'd0;
					
						end
						
					end
				
					// Update buffers
					T_buf_1 <= colAccum_1 + Mult_result_3;
					T_buf_2 <= colAccum_2 + Mult_result_4;
					T_buf_3 <= colAccum_3 + Mult_result_5;
					
					// CALC FINISHED
					
					// Update the accumulators
					colAccum_1 <= 0;
					colAccum_2 <= 0;
					colAccum_3 <= 0;
				
					// Read the third row of 2 T values from RAM
					RAM_address_b_0 <= RAM_address_T;
					RAM_address_a_2 <= RAM_address_T + 1;
					
					// Increment the addresses
					RAM_address_T <= RAM_address_T + 8;
					
					// Buffer S_prime other sample
					CT_buf <= RAM_read_data_a_1[15: 0];
					
					// Read the next sample
					RAM_address_a_1 <= RAM_address_sample + 1;
					
					// Increment the addresses
					RAM_address_sample <= RAM_address_sample + 1;
					
					if (RAM_read_data_a_1[31] == 1'b1) begin
					
						Mult_op_3_1 <= {{16{1'b1}}, RAM_read_data_a_1[31:16]};
					
						Mult_op_4_1 <= {{16{1'b1}}, RAM_read_data_a_1[31:16]};
						
					end else begin
					
						Mult_op_3_1 <= RAM_read_data_a_1[31:16];
					
						Mult_op_4_1 <= RAM_read_data_a_1[31:16];
						
					end
					
					Mult_op_3_2 <= RAM_read_data_b_0;
				
					Mult_op_4_2 <= RAM_read_data_a_2;
					
					m2_state <= S_M2_CC_S_17;
				
				end
				
				S_M2_CC_S_17: begin
				
					if (!fetchedSPrime || isFinishedWritingSPrime == 0) begin
					
						if (isSPrimeBuffered == 1'd0) begin
					
							S_prime_buf <= SRAM_read_data;
							
							isSPrimeBuffered <= 1'd1;
							
						end else begin
						
							RAM_write_data_a_0 <= {S_prime_buf, SRAM_read_data};
							
							// Set RAM address to the correct write address
							RAM_address_a_0 <= RAM_address_prev;
						
							// Increment the RAM address offset
							RAM_address_prev <= RAM_address_prev + 1;
							
							// Set write enable to write
							RAM_we_n_a_0 <= 1;
							
							isSPrimeBuffered <= 1'd0;
					
						end
						
					end
					
					if (finBlockHold) begin
					
						isFinishedWritingSPrime <= 1;
						
					end
					
					sampleCounterEnabled <= 0;
				
					if (S_write_buf[31] == 1'b1) begin
					
						if (T_buf_1[31] == 1'b1) begin
						
							S_buf_2 <= {8'd0, 8'd0};
						
						end else begin
						
							if (T_buf_1[30:24] == 7'b0000000) begin
							
								S_buf_2 <= {8'd0, T_buf_1[23:16]};
						
							end else begin
							
								S_buf_2 <= {8'd0, 8'd255};
								
							end
						
						end
					
					end else begin
					
						if (T_buf_1[31] == 1'b1) begin
						
							if (S_write_buf[30:24] == 7'b0000000) begin
							
								S_buf_2 <= {S_write_buf[23:16], 8'd0};
						
							end else begin
							
								S_buf_2 <= {8'd255, 8'd0};
								
							end
						
						end else begin
						
							if (S_write_buf[30:24] == 7'b0000000) begin
							
								if (T_buf_1[30:24] == 7'b0000000) begin
								
									S_buf_2 <= {S_write_buf[23:16], T_buf_1[23:16]};
								
								end else begin
								
									S_buf_2 <= {S_write_buf[23:16], 8'd255};
								
								end
						
							end else begin
							
								if (T_buf_1[30:24] == 7'b0000000) begin
								
									S_buf_2 <= {8'd255, T_buf_1[23:16]};
								
								end else begin
								
									S_buf_2 <= {8'd255, 8'd255};
								
								end
								
							end
						
						end
					
					end
					
					// Update the accumulators
					colAccum_1 <= colAccum_1 + Mult_result_3;
					colAccum_2 <= colAccum_2 + Mult_result_4;
					colAccum_3 <= colAccum_3 + Mult_result_5;
				
					// Read the fourth row of 3 T values from RAM
					RAM_address_b_0 <= RAM_address_T;
					RAM_address_a_2 <= RAM_address_T + 1;
					RAM_address_b_2 <= RAM_address_T + 2;
					
					// Increment the addresses
					RAM_address_T <= RAM_address_T + 8;
					
					if (CT_buf[15] == 1'b1) begin
					
						Mult_op_3_1 <= {{16{1'b1}}, CT_buf};
					
						Mult_op_4_1 <= {{16{1'b1}}, CT_buf};
						
					end else begin
					
						Mult_op_3_1 <= CT_buf;
					
						Mult_op_4_1 <= CT_buf;
						
					end
					
					Mult_op_3_2 <= RAM_read_data_b_0;
				
					Mult_op_4_2 <= RAM_read_data_a_2;
					
					m2_state <= S_M2_CC_S_18;
				
				end
				
				S_M2_CC_S_18: begin
				
					// Set write enable to write
					RAM_we_n_a_0 <= 0;
				
					// CALC FINISHED
					if (T_buf_2[31] == 1'b1) begin
					
						if (T_buf_3[31] == 1'b1) begin
						
							S_buf_3 <= {8'd0, 8'd0};
						
						end else begin
						
							if (T_buf_3[30:24] == 7'b0000000) begin
							
								S_buf_3 <= {8'd0, T_buf_3[23:16]};
						
							end else begin
							
								S_buf_3 <= {8'd0, 8'd255};
								
							end
						
						end
					
					end else begin
					
						if (T_buf_3[31] == 1'b1) begin
						
							if (T_buf_2[30:24] == 7'b0000000) begin
							
								S_buf_3 <= {T_buf_2[23:16], 8'd0};
						
							end else begin
							
								S_buf_3 <= {8'd255, 8'd0};
								
							end
						
						end else begin
						
							if (T_buf_2[30:24] == 7'b0000000) begin
							
								if (T_buf_3[30:24] == 7'b0000000) begin
								
									S_buf_3 <= {T_buf_2[23:16], T_buf_3[23:16]};
								
								end else begin
								
									S_buf_3 <= {T_buf_2[23:16], 8'd255};
								
								end
						
							end else begin
							
								if (T_buf_3[30:24] == 7'b0000000) begin
								
									S_buf_3 <= {8'd255, T_buf_3[23:16]};
								
								end else begin
								
									S_buf_3 <= {8'd255, 8'd255};
								
								end
								
							end
						
						end
					
					end
				
					// Update the accumulators
					colAccum_1 <= colAccum_1 + Mult_result_3;
					colAccum_2 <= colAccum_2 + Mult_result_4;
					colAccum_3 <= colAccum_3 + Mult_result_5;
				
					// Read the fifth row of 2 T values from RAM
					RAM_address_b_0 <= RAM_address_T;
					RAM_address_a_2 <= RAM_address_T + 1;
					
					// Increment the addresses
					RAM_address_T <= RAM_address_T + 8;
					
					// Buffer S_prime other sample
					CT_buf <= RAM_read_data_a_1[15: 0];
					
					// Read the next sample
					RAM_address_a_1 <= RAM_address_sample + 1;
					
					// Increment the addresses
					RAM_address_sample <= RAM_address_sample + 1;
					
					if (RAM_read_data_a_1[31] == 1'b1) begin
					
						Mult_op_3_1 <= {{16{1'b1}}, RAM_read_data_a_1[31:16]};
					
						Mult_op_4_1 <= {{16{1'b1}}, RAM_read_data_a_1[31:16]};
						
					end else begin
					
						Mult_op_3_1 <= RAM_read_data_a_1[31:16];
					
						Mult_op_4_1 <= RAM_read_data_a_1[31:16];
						
					end
					
					Mult_op_3_2 <= RAM_read_data_b_0;
				
					Mult_op_4_2 <= RAM_read_data_a_2;
					
					m2_state <= S_M2_CC_S_19;
				
				end
				
				S_M2_CC_S_19: begin
				
					// Update the accumulators
					colAccum_1 <= colAccum_1 + Mult_result_3;
					colAccum_2 <= colAccum_2 + Mult_result_4;
					colAccum_3 <= colAccum_3 + Mult_result_5;
				
					// Read the sixth row of 3 T values from RAM
					RAM_address_b_0 <= RAM_address_T;
					RAM_address_a_2 <= RAM_address_T + 1;
					RAM_address_b_2 <= RAM_address_T + 2;
					
					// Increment the addresses
					RAM_address_T <= RAM_address_T + 8;
					
					if (CT_buf[15] == 1'b1) begin
					
						Mult_op_3_1 <= {{16{1'b1}}, CT_buf};
					
						Mult_op_4_1 <= {{16{1'b1}}, CT_buf};
						
					end else begin
					
						Mult_op_3_1 <= CT_buf;
					
						Mult_op_4_1 <= CT_buf;
						
					end
					
					Mult_op_3_2 <= RAM_read_data_b_0;
				
					Mult_op_4_2 <= RAM_read_data_a_2;
					
					m2_state <= S_M2_CC_S_20;
				
				end
				
				S_M2_CC_S_20: begin
				
					// Update the accumulators
					colAccum_1 <= colAccum_1 + Mult_result_3;
					colAccum_2 <= colAccum_2 + Mult_result_4;
					colAccum_3 <= colAccum_3 + Mult_result_5;
				
					// Read the seventh row of 2 T values from RAM
					RAM_address_b_0 <= RAM_address_T;
					RAM_address_a_2 <= RAM_address_T + 1;
					
					// Increment the addresses
					RAM_address_T <= RAM_address_T + 8;
					
					// Buffer S_prime other sample
					CT_buf <= RAM_read_data_a_1[15: 0];
					
					// Read the next sample
					RAM_address_a_1 <= RAM_address_sample + 1;
					
					// Increment the addresses
					RAM_address_sample <= RAM_address_sample + 1;
					
					if (RAM_read_data_a_1[31] == 1'b1) begin
					
						Mult_op_3_1 <= {{16{1'b1}}, RAM_read_data_a_1[31:16]};
					
						Mult_op_4_1 <= {{16{1'b1}}, RAM_read_data_a_1[31:16]};
						
					end else begin
					
						Mult_op_3_1 <= RAM_read_data_a_1[31:16];
					
						Mult_op_4_1 <= RAM_read_data_a_1[31:16];
						
					end
					
					Mult_op_3_2 <= RAM_read_data_b_0;
				
					Mult_op_4_2 <= RAM_read_data_a_2;
					
					m2_state <= S_M2_CC_S_21;
				
				end
				
				S_M2_CC_S_21: begin
	
					// Update the accumulators
					colAccum_1 <= colAccum_1 + Mult_result_3;
					colAccum_2 <= colAccum_2 + Mult_result_4;
					colAccum_3 <= colAccum_3 + Mult_result_5;
				
					// Read the eighth row of 3 T values from RAM
					RAM_address_b_0 <= RAM_address_T;
					RAM_address_a_2 <= RAM_address_T + 1;
					RAM_address_b_2 <= RAM_address_T + 2;
					
					// Increment the addresses
					RAM_address_T <= 64;
					
					if (CT_buf[15] == 1'b1) begin
					
						Mult_op_3_1 <= {{16{1'b1}}, CT_buf};
					
						Mult_op_4_1 <= {{16{1'b1}}, CT_buf};
						
					end else begin
					
						Mult_op_3_1 <= CT_buf;
					
						Mult_op_4_1 <= CT_buf;
						
					end
					
					Mult_op_3_2 <= RAM_read_data_b_0;
				
					Mult_op_4_2 <= RAM_read_data_a_2;
					
					m2_state <= S_M2_CC_S_22;
				
				end
				
				S_M2_CC_S_22: begin
				
					// Update the accumulators
					colAccum_1 <= colAccum_1 + Mult_result_3;
					colAccum_2 <= colAccum_2 + Mult_result_4;
					colAccum_3 <= colAccum_3 + Mult_result_5;
				
					if (calculationsPerformed != 7) begin
				
						// Read the first row of 3 T values from RAM
						RAM_address_b_0 <= RAM_address_T;
						RAM_address_a_2 <= RAM_address_T + 1;
						RAM_address_b_2 <= RAM_address_T + 2;
							
						// Increment the addresses
						RAM_address_T <= RAM_address_T + 8;
						
						// Read the next sample
						RAM_address_a_1 <= RAM_address_sample + 1;
						RAM_address_sample <= RAM_address_sample + 1;
					
					end
					
					// Buffer S_prime other sample
					CT_buf <= RAM_read_data_a_1[15: 0];
						
					if (RAM_read_data_a_1[31] == 1'b1) begin
						
						Mult_op_3_1 <= {{16{1'b1}}, RAM_read_data_a_1[31:16]};
						
						Mult_op_4_1 <= {{16{1'b1}}, RAM_read_data_a_1[31:16]};
							
					end else begin
						
						Mult_op_3_1 <= RAM_read_data_a_1[31:16];
						
						Mult_op_4_1 <= RAM_read_data_a_1[31:16];
							
					end
						
					Mult_op_3_2 <= RAM_read_data_b_0;
					
					Mult_op_4_2 <= RAM_read_data_a_2;
					
					m2_state <= S_M2_CC_S_23;
				
				end
				
				S_M2_CC_S_23: begin
				
					// Update the accumulators
					colAccum_1 <= colAccum_1 + Mult_result_3;
					colAccum_2 <= colAccum_2 + Mult_result_4;
					colAccum_3 <= colAccum_3 + Mult_result_5;
				
					if (calculationsPerformed != 7) begin
				
						// Read the second row of 3 T values from RAM
						RAM_address_b_0 <= RAM_address_T;
						RAM_address_a_2 <= RAM_address_T + 1;
						RAM_address_b_2 <= RAM_address_T + 2;
						
						// Increment the addresses
						RAM_address_T <= RAM_address_T + 8;
						
					end
						
					if (CT_buf[15] == 1'b1) begin
						
						Mult_op_3_1 <= {{16{1'b1}}, CT_buf};
						
						Mult_op_4_1 <= {{16{1'b1}}, CT_buf};
							
					end else begin
						
						Mult_op_3_1 <= CT_buf;
						
						Mult_op_4_1 <= CT_buf;
							
					end
						
					Mult_op_3_2 <= RAM_read_data_b_0;
					
					Mult_op_4_2 <= RAM_read_data_a_2;
						
					m2_state <= S_M2_CC_S_24;
					
				end
				
				S_M2_CC_S_24: begin
						
					calculationsPerformed <= calculationsPerformed + 1;
				
					// Update buffers
					T_buf_1 <= colAccum_1 + Mult_result_3;
					T_buf_2 <= colAccum_2 + Mult_result_4;
					T_buf_3 <= colAccum_3 + Mult_result_5;
					
					// CALC FINISHED
					
					// Update the accumulators
					colAccum_1 <= 0;
					colAccum_2 <= 0;
					colAccum_3 <= 0;
					
					isSValueToWrite <= 1'b1;
					
					if (calculationsPerformed != 7) begin
					
						// Read the third row of 3 T values from RAM
						RAM_address_b_0 <= RAM_address_T;
						RAM_address_a_2 <= RAM_address_T + 1;
						RAM_address_b_2 <= RAM_address_T + 2;
						
						// Increment the addresses
						RAM_address_T <= RAM_address_T + 8;
						
						// Buffer S_prime other sample
						CT_buf <= RAM_read_data_a_1[15: 0];
						
						// Read the next sample
						RAM_address_a_1 <= RAM_address_sample + 1;
						
						// Increment sample counter
						RAM_address_sample <= RAM_address_sample + 1;
						
						if (RAM_read_data_a_1[31] == 1'b1) begin
						
							Mult_op_3_1 <= {{16{1'b1}}, RAM_read_data_a_1[31:16]};
						
							Mult_op_4_1 <= {{16{1'b1}}, RAM_read_data_a_1[31:16]};
							
							Mult_op_5_1 <= {{16{1'b1}}, RAM_read_data_a_1[31:16]};
						
						end else begin
						
							Mult_op_3_1 <= RAM_read_data_a_1[31:16];
						
							Mult_op_4_1 <= RAM_read_data_a_1[31:16];
							
							Mult_op_5_1 <= RAM_read_data_a_1[31:16];
							
						end
						
						Mult_op_3_2 <= RAM_read_data_b_0;
					
						Mult_op_4_2 <= RAM_read_data_a_2;
						
						Mult_op_5_2 <= RAM_read_data_b_2;
						
						m2_state <= S_M2_CC_S_1;
					
					end else begin
					
						m2_state <= S_M2_CC_S_1;
						
					end
					
				end
				
			endcase
		
		end
		
		default: top_state <= S_IDLE;

		endcase
		
	end
	
end

// for this design we assume that the RGB data starts at location 0 in the external SRAM
// if the memory layout is different, this value should be adjusted 
// to match the starting address of the raw RGB data segment
assign VGA_base_address = 18'd146944;
		
// Give access to SRAM for UART and VGA at appropriate time

always_comb begin

	case (top_state)

	S_UART_RX: begin
	
		SRAM_address = UART_SRAM_address;
		
		SRAM_write_data = UART_SRAM_write_data;
		
		SRAM_we_n = UART_SRAM_we_n;
	
	end
	
	S_MILESTONE_1: begin
	
		SRAM_address = SRAM_address_M1;
		
		SRAM_write_data = SRAM_write_data_M1;
		
		SRAM_we_n = SRAM_we_n_M1;
	
	end
	
	S_MILESTONE_2: begin
	
		SRAM_address = SRAM_address_M2;
		
		SRAM_write_data = SRAM_write_data_M2;
		
		SRAM_we_n = SRAM_we_n_M2;
		
	end
	
	default: begin
	
		SRAM_address = VGA_SRAM_address;
		
		SRAM_write_data = 16'd0;
		
		SRAM_we_n = 1'b1;
	
	end
	
	endcase

end

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
