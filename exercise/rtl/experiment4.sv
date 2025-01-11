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

module experiment4 (
		/////// board clocks                      ////////////
		input logic CLOCK_50_I,                   // 50 MHz clock

		/////// switches                          ////////////
		input logic[17:0] SWITCH_I,               // toggle switches

		/////// VGA interface                     ////////////
		output logic VGA_CLOCK_O,                 // VGA clock
		output logic VGA_HSYNC_O,                 // VGA H_SYNC
		output logic VGA_VSYNC_O,                 // VGA V_SYNC
		output logic VGA_BLANK_O,                 // VGA BLANK
		output logic VGA_SYNC_O,                  // VGA SYNC
		output logic[7:0] VGA_RED_O,              // VGA red
		output logic[7:0] VGA_GREEN_O,            // VGA green
		output logic[7:0] VGA_BLUE_O,              // VGA blue

		/////// PS2                               ////////////
		input logic PS2_DATA_I,                   // PS2 data
		input logic PS2_CLOCK_I                   // PS2 clock
);

`include "VGA_param.h"
parameter SCREEN_BORDER_OFFSET = 32;
parameter DEFAULT_MESSAGE_LINE = 280;
parameter SECOND_MESSAGE_LINE = 320;
parameter DEFAULT_MESSAGE_START_COL = 360;
parameter KEYBOARD_MESSAGE_LINE = 320;
parameter KEYBOARD_MESSAGE_START_COL = 360;

logic resetn, enable;

logic [7:0] VGA_red, VGA_green, VGA_blue;
logic [9:0] pixel_X_pos;
logic [9:0] pixel_Y_pos;

logic [5:0] data_reg [30:0];

logic [5:0] character_address;
logic [5:0] number_address_1;
logic [5:0] number_address_2;
logic rom_mux_output;

logic screen_border_on;

assign resetn = ~SWITCH_I[17];

logic [7:0] PS2_code, PS2_reg;
logic PS2_code_ready;

logic PS2_code_ready_buf;
logic PS2_make_code;

logic [5:0] char_to_add;

logic [4:0] num_A;
logic [4:0] num_B;
logic [4:0] num_C;
logic [4:0] num_D;
logic [4:0] num_E;
logic [4:0] num_F;

logic [5:0] max_letter;

logic [3:0] letter_BCD_A1;
logic [3:0] letter_BCD_A2;
logic [3:0] letter_BCD_B1;
logic [3:0] letter_BCD_B2;
logic [3:0] letter_BCD_C1;
logic [3:0] letter_BCD_C2;
logic [3:0] letter_BCD_D1;
logic [3:0] letter_BCD_D2;
logic [3:0] letter_BCD_E1;
logic [3:0] letter_BCD_E2;
logic [3:0] letter_BCD_F1;
logic [3:0] letter_BCD_F2;

logic [3:0] letter_BCD_1;
logic [3:0] letter_BCD_2;

// PS/2 controller
PS2_controller ps2_unit (
	.Clock_50(CLOCK_50_I),
	.Resetn(resetn),
	.PS2_clock(PS2_CLOCK_I),
	.PS2_data(PS2_DATA_I),
	.PS2_code(PS2_code),
	.PS2_code_ready(PS2_code_ready),
	.PS2_make_code(PS2_make_code)
);

// Putting the PS2 code into a register
always_ff @ (posedge CLOCK_50_I or negedge resetn) begin
	if (resetn == 1'b0) begin
	
		// Initialize variables to 0
		PS2_code_ready_buf <= 1'b0;
		PS2_reg <= 8'd0;
		char_to_add <= 6'o00;
		num_A <= 5'd0;
		num_B <= 5'd0;
		num_C <= 5'd0;
		num_D <= 5'd0;
		num_E <= 5'd0;
		num_F <= 5'd0;
		letter_BCD_A1 <= 4'b0;
		letter_BCD_A2 <= 4'b0;
		letter_BCD_B1 <= 4'b0;
		letter_BCD_B2 <= 4'b0;
		letter_BCD_C1 <= 4'b0;
		letter_BCD_C2 <= 4'b0;
		letter_BCD_D1 <= 4'b0;
		letter_BCD_D2 <= 4'b0;
		letter_BCD_E1 <= 4'b0;
		letter_BCD_E2 <= 4'b0;
		letter_BCD_F1 <= 4'b0;
		letter_BCD_F2 <= 4'b0;
		letter_BCD_1 <= 4'b0;
		letter_BCD_2 <= 4'b0;
		
		// Loop over the data register array and set all registers to 0
		begin : init
				
			integer i;
				
			for (i = 0; i <= 30; i=i+1)
				
				data_reg[i] <= 8'd0;
					
		end
		
	end else begin
	
		PS2_code_ready_buf <= PS2_code_ready;
		
		if (PS2_code_ready && ~PS2_code_ready_buf && PS2_make_code) begin
		
			// Scan code detected
			// PS2_reg <= PS2_code;
			
			// check if the pressed PS/2 key is an A
			if (PS2_code == 8'h1C) begin
			
				// Set the character to be added to the register as the octal code for A
				char_to_add = 6'o01; // A
				
				// Increment the A decimal counter
				num_A <= num_A + 1;
				
				// Increment the A BCD counter
				if (letter_BCD_A1 < 4'b1001) begin
				
					letter_BCD_A1 <= letter_BCD_A1 + 4'b1;
				
				// If the A BCD counter is a 9, reset it to a 0 and increment the BCD counter for the 1's place
				end else begin
				
					letter_BCD_A1 <= 4'b0;
				
					if (letter_BCD_A2 < 4'b1001) begin
					
						letter_BCD_A2 <= letter_BCD_A2 + 4'b1;
						
					end else begin
					
						letter_BCD_A2 <= 4'b0;
					end
				end
			// Repeat the above process for letters B, C, D, E, F
			end else begin
			
				if (PS2_code == 8'h32) begin
			
					char_to_add = 6'o02; // B
					
					num_B <= num_B + 1;
					
					if (letter_BCD_B1 < 4'b1001) begin
					
						letter_BCD_B1 <= letter_BCD_B1 + 4'b1;
					
					end else begin
					
						letter_BCD_B1 <= 4'b0;
					
						if (letter_BCD_B2 < 4'b1001) begin
						
							letter_BCD_B2 <= letter_BCD_B2 + 4'b1;
							
						end else begin
						
							letter_BCD_B2 <= 4'b0;
						end
					end
				end else begin
				
					if (PS2_code == 8'h21) begin
			
						char_to_add = 6'o03; // C
						
						num_C <= num_C + 1;
						
						if (letter_BCD_C1 < 4'b1001) begin
						
							letter_BCD_C1 <= letter_BCD_C1 + 4'b1;
						
						end else begin
						
							letter_BCD_C1 <= 4'b0;
						
							if (letter_BCD_C2 < 4'b1001) begin
							
								letter_BCD_C2 <= letter_BCD_C2 + 4'b1;
								
							end else begin
							
								letter_BCD_C2 <= 4'b0;
							end
						end
					end else begin
					
						if (PS2_code == 8'h23) begin
			
							char_to_add = 6'o04; // D
							
							num_D <= num_D + 1;
							
							if (letter_BCD_D1 < 4'b1001) begin
							
								letter_BCD_D1 <= letter_BCD_D1 + 4'b1;
							
							end else begin
							
								letter_BCD_D1 <= 4'b0;
							
								if (letter_BCD_D2 < 4'b1001) begin
								
									letter_BCD_D2 <= letter_BCD_D2 + 4'b1;
									
								end else begin
								
									letter_BCD_D2 <= 4'b0;
								end
							end
						end else begin
						
							if (PS2_code == 8'h24) begin
				
								char_to_add = 6'o05; // E
								
								num_E <= num_E + 1;
								
								if (letter_BCD_E1 < 4'b1001) begin
								
									letter_BCD_E1 <= letter_BCD_E1 + 4'b1;
								
								end else begin
								
									letter_BCD_E1 <= 4'b0;
								
									if (letter_BCD_E2 < 4'b1001) begin
									
										letter_BCD_E2 <= letter_BCD_E2 + 4'b1;
										
									end else begin
									
										letter_BCD_E2 <= 4'b0;
									end
								end
							end else begin
							
								if (PS2_code == 8'h2B) begin
					
									char_to_add = 6'o06; // F
									
									num_F <= num_F + 1;
									
									if (letter_BCD_F1 < 4'b1001) begin
									
										letter_BCD_F1 <= letter_BCD_F1 + 4'b1;
									
									end else begin
									
										letter_BCD_F1 <= 4'b0;
									
										if (letter_BCD_F2 < 4'b1001) begin
										
											letter_BCD_F2 <= letter_BCD_F2 + 4'b1;
											
										end else begin
										
											letter_BCD_F2 <= 4'b0;
										end
									end
								end else begin
								
									char_to_add = 6'o40; // Space
								
								end
							end
						end
					end
				end
			end
			
			// Shift the registers
			data_reg[30] <= data_reg[29];
			data_reg[29] <= data_reg[28];
			data_reg[28] <= data_reg[27];
			data_reg[27] <= data_reg[26];
			data_reg[26] <= data_reg[25];
			data_reg[25] <= data_reg[24];
			data_reg[24] <= data_reg[23];
			data_reg[23] <= data_reg[22];
			data_reg[22] <= data_reg[21];
			data_reg[21] <= data_reg[20];
			data_reg[20] <= data_reg[19];
			data_reg[19] <= data_reg[18];
			data_reg[18] <= data_reg[17];
			data_reg[17] <= data_reg[16];
			data_reg[16] <= data_reg[15];
			data_reg[15] <= data_reg[14];
			data_reg[14] <= data_reg[13];
			data_reg[13] <= data_reg[12];
			data_reg[12] <= data_reg[11];
			data_reg[11] <= data_reg[10];
			data_reg[10] <= data_reg[9];
			data_reg[9] <= data_reg[8];
			data_reg[8] <= data_reg[7];
			data_reg[7] <= data_reg[6];
			data_reg[6] <= data_reg[5];
			data_reg[5] <= data_reg[4];
			data_reg[4] <= data_reg[3];
			data_reg[3] <= data_reg[2];
			data_reg[2] <= data_reg[1];
			data_reg[1] <= data_reg[0];
			data_reg[0] <= char_to_add;
			
		end
	end
end

VGA_controller VGA_unit(
	.clock(CLOCK_50_I),
	.resetn(resetn),
	.enable(enable),

	.iRed(VGA_red),
	.iGreen(VGA_green),
	.iBlue(VGA_blue),
	.oCoord_X(pixel_X_pos),
	.oCoord_Y(pixel_Y_pos),
	
	// VGA Side
	.oVGA_R(VGA_RED_O),
	.oVGA_G(VGA_GREEN_O),
	.oVGA_B(VGA_BLUE_O),
	.oVGA_H_SYNC(VGA_HSYNC_O),
	.oVGA_V_SYNC(VGA_VSYNC_O),
	.oVGA_SYNC(VGA_SYNC_O),
	.oVGA_BLANK(VGA_BLANK_O)
);

logic [2:0] delay_X_pos;

always_ff @(posedge CLOCK_50_I or negedge resetn) begin
	if(!resetn) begin
		delay_X_pos[2:0] <= 3'd0;
	end else begin
		delay_X_pos[2:0] <= pixel_X_pos[2:0];
	end
end

// Character ROM
char_rom char_rom_unit (
	.Clock(CLOCK_50_I),
	.Character_address(character_address),
	.Font_row(pixel_Y_pos[2:0]),
	.Font_col(delay_X_pos[2:0]),
	.Rom_mux_output(rom_mux_output)
);

// this experiment is in the 800x600 @ 72 fps mode
assign enable = 1'b1;
assign VGA_CLOCK_O = ~CLOCK_50_I;

always_comb begin
	screen_border_on = 0;
	if (pixel_X_pos == SCREEN_BORDER_OFFSET || pixel_X_pos == H_SYNC_ACT-SCREEN_BORDER_OFFSET)
		if (pixel_Y_pos >= SCREEN_BORDER_OFFSET && pixel_Y_pos < V_SYNC_ACT-SCREEN_BORDER_OFFSET)
			screen_border_on = 1'b1;
	if (pixel_Y_pos == SCREEN_BORDER_OFFSET || pixel_Y_pos == V_SYNC_ACT-SCREEN_BORDER_OFFSET)
		if (pixel_X_pos >= SCREEN_BORDER_OFFSET && pixel_X_pos < H_SYNC_ACT-SCREEN_BORDER_OFFSET)
			screen_border_on = 1'b1;
end

// Display text
always_comb begin

	// Set variables to 0 temporarily
	character_address = 6'o40;
	number_address_1 = 6'o40;
	number_address_2 = 6'o40;
	
	// Case if no monitored keys have been pressed
	if ((num_A == 5'd0) && (num_B == 5'd0) && (num_C == 5'd0) && (num_D == 5'd0) && (num_E == 5'd0) && (num_F == 5'd0)) begin
	
		// NO MONITORED KEYS PRESSED
		max_letter <= 6'o40;
		number_address_1 = 6'o60;
		number_address_2 = 6'o60;
		
	end else begin
	
		// If A has the maximum number of times pressed
		if ((num_A >= num_B) && (num_A >= num_C) && (num_A >= num_D) && (num_A >= num_E) && (num_A >= num_F)) begin
	
			// Set max letter to the octal code for A
			max_letter <= 6'o01;
			
			// Associate number_address_1 and number_address_2 to the octal code corresponding to the previous BCD counter
			case (letter_BCD_A1)
				4'b0000: number_address_1 = 6'o60;
				4'b0001: number_address_1 = 6'o61;
				4'b0010: number_address_1 = 6'o62;
				4'b0011: number_address_1 = 6'o63;
				4'b0100: number_address_1 = 6'o64;
				4'b0101: number_address_1 = 6'o65;
				4'b0110: number_address_1 = 6'o66;
				4'b0111: number_address_1 = 6'o67;
				4'b1000: number_address_1 = 6'o70;
				4'b1001: number_address_1 = 6'o71;
			endcase
			
			case (letter_BCD_A2)
				4'b0000: number_address_2 = 6'o60;
				4'b0001: number_address_2 = 6'o61;
				4'b0010: number_address_2 = 6'o62;
				4'b0011: number_address_2 = 6'o63;
				4'b0100: number_address_2 = 6'o64;
				4'b0101: number_address_2 = 6'o65;
				4'b0110: number_address_2 = 6'o66;
				4'b0111: number_address_2 = 6'o67;
				4'b1000: number_address_2 = 6'o70;
				4'b1001: number_address_2 = 6'o71;
			endcase
		
		// Repeat for letters B, C, D, E and F
		end else begin
		
			if ((num_B >= num_A) && (num_B >= num_C) && (num_B >= num_D) && (num_B >= num_E) && (num_B >= num_F)) begin
	
				max_letter <= 6'o02;
				
				case (letter_BCD_B1)
					4'b0000: number_address_1 = 6'o60;
					4'b0001: number_address_1 = 6'o61;
					4'b0010: number_address_1 = 6'o62;
					4'b0011: number_address_1 = 6'o63;
					4'b0100: number_address_1 = 6'o64;
					4'b0101: number_address_1 = 6'o65;
					4'b0110: number_address_1 = 6'o66;
					4'b0111: number_address_1 = 6'o67;
					4'b1000: number_address_1 = 6'o70;
					4'b1001: number_address_1 = 6'o71;
				endcase
				
				case (letter_BCD_B2)
					4'b0000: number_address_2 = 6'o60;
					4'b0001: number_address_2 = 6'o61;
					4'b0010: number_address_2 = 6'o62;
					4'b0011: number_address_2 = 6'o63;
					4'b0100: number_address_2 = 6'o64;
					4'b0101: number_address_2 = 6'o65;
					4'b0110: number_address_2 = 6'o66;
					4'b0111: number_address_2 = 6'o67;
					4'b1000: number_address_2 = 6'o70;
					4'b1001: number_address_2 = 6'o71;
				endcase
			
			end else begin
			
				if ((num_C >= num_A) && (num_C >= num_B) && (num_C >= num_D) && (num_C >= num_E) && (num_C >= num_F)) begin
	
					max_letter <= 6'o03;
					
					case (letter_BCD_C1)
						4'b0000: number_address_1 = 6'o60;
						4'b0001: number_address_1 = 6'o61;
						4'b0010: number_address_1 = 6'o62;
						4'b0011: number_address_1 = 6'o63;
						4'b0100: number_address_1 = 6'o64;
						4'b0101: number_address_1 = 6'o65;
						4'b0110: number_address_1 = 6'o66;
						4'b0111: number_address_1 = 6'o67;
						4'b1000: number_address_1 = 6'o70;
						4'b1001: number_address_1 = 6'o71;
					endcase
					
					case (letter_BCD_C2)
						4'b0000: number_address_2 = 6'o60;
						4'b0001: number_address_2 = 6'o61;
						4'b0010: number_address_2 = 6'o62;
						4'b0011: number_address_2 = 6'o63;
						4'b0100: number_address_2 = 6'o64;
						4'b0101: number_address_2 = 6'o65;
						4'b0110: number_address_2 = 6'o66;
						4'b0111: number_address_2 = 6'o67;
						4'b1000: number_address_2 = 6'o70;
						4'b1001: number_address_2 = 6'o71;
					endcase
			
				end else begin
				
					if ((num_D >= num_A) && (num_D >= num_C) && (num_D >= num_B) && (num_D >= num_E) && (num_D >= num_F)) begin
	
						max_letter <= 6'o04;
						
						case (letter_BCD_D1)
							4'b0000: number_address_1 = 6'o60;
							4'b0001: number_address_1 = 6'o61;
							4'b0010: number_address_1 = 6'o62;
							4'b0011: number_address_1 = 6'o63;
							4'b0100: number_address_1 = 6'o64;
							4'b0101: number_address_1 = 6'o65;
							4'b0110: number_address_1 = 6'o66;
							4'b0111: number_address_1 = 6'o67;
							4'b1000: number_address_1 = 6'o70;
							4'b1001: number_address_1 = 6'o71;
						endcase
						
						case (letter_BCD_D2)
							4'b0000: number_address_2 = 6'o60;
							4'b0001: number_address_2 = 6'o61;
							4'b0010: number_address_2 = 6'o62;
							4'b0011: number_address_2 = 6'o63;
							4'b0100: number_address_2 = 6'o64;
							4'b0101: number_address_2 = 6'o65;
							4'b0110: number_address_2 = 6'o66;
							4'b0111: number_address_2 = 6'o67;
							4'b1000: number_address_2 = 6'o70;
							4'b1001: number_address_2 = 6'o71;
						endcase
			
					end else begin
					
						if ((num_E >= num_A) && (num_E >= num_C) && (num_E >= num_A) && (num_E >= num_B) && (num_E >= num_F)) begin
		
							max_letter <= 6'o05;
							
							case (letter_BCD_E1)
								4'b0000: number_address_1 = 6'o60;
								4'b0001: number_address_1 = 6'o61;
								4'b0010: number_address_1 = 6'o62;
								4'b0011: number_address_1 = 6'o63;
								4'b0100: number_address_1 = 6'o64;
								4'b0101: number_address_1 = 6'o65;
								4'b0110: number_address_1 = 6'o66;
								4'b0111: number_address_1 = 6'o67;
								4'b1000: number_address_1 = 6'o70;
								4'b1001: number_address_1 = 6'o71;
							endcase
							
							case (letter_BCD_E2)
								4'b0000: number_address_2 = 6'o60;
								4'b0001: number_address_2 = 6'o61;
								4'b0010: number_address_2 = 6'o62;
								4'b0011: number_address_2 = 6'o63;
								4'b0100: number_address_2 = 6'o64;
								4'b0101: number_address_2 = 6'o65;
								4'b0110: number_address_2 = 6'o66;
								4'b0111: number_address_2 = 6'o67;
								4'b1000: number_address_2 = 6'o70;
								4'b1001: number_address_2 = 6'o71;
							endcase
				
						end else begin
						
							max_letter <= 6'o06;
								
							case (letter_BCD_F1)
								4'b0000: number_address_1 = 6'o60;
								4'b0001: number_address_1 = 6'o61;
								4'b0010: number_address_1 = 6'o62;
								4'b0011: number_address_1 = 6'o63;
								4'b0100: number_address_1 = 6'o64;
								4'b0101: number_address_1 = 6'o65;
								4'b0110: number_address_1 = 6'o66;
								4'b0111: number_address_1 = 6'o67;
								4'b1000: number_address_1 = 6'o70;
								4'b1001: number_address_1 = 6'o71;
							endcase
							
							case (letter_BCD_F2)
								4'b0000: number_address_2 = 6'o60;
								4'b0001: number_address_2 = 6'o61;
								4'b0010: number_address_2 = 6'o62;
								4'b0011: number_address_2 = 6'o63;
								4'b0100: number_address_2 = 6'o64;
								4'b0101: number_address_2 = 6'o65;
								4'b0110: number_address_2 = 6'o66;
								4'b0111: number_address_2 = 6'o67;
								4'b1000: number_address_2 = 6'o70;
								4'b1001: number_address_2 = 6'o71;
							endcase
							
						end
					end
				end
			end
		end
	end
	
	if (pixel_Y_pos[9:3] == ((DEFAULT_MESSAGE_LINE) >> 3)) begin

		// CASE PS/2 MESSAGE
		case (pixel_X_pos[9:3])
			(DEFAULT_MESSAGE_START_COL >> 3) +  0: character_address = data_reg[30];
			(DEFAULT_MESSAGE_START_COL >> 3) +  1: character_address = data_reg[29];
			(DEFAULT_MESSAGE_START_COL >> 3) +  2: character_address = data_reg[28];
			(DEFAULT_MESSAGE_START_COL >> 3) +  3: character_address = data_reg[27];
			(DEFAULT_MESSAGE_START_COL >> 3) +  4: character_address = data_reg[26];
			(DEFAULT_MESSAGE_START_COL >> 3) +  5: character_address = data_reg[25];
			(DEFAULT_MESSAGE_START_COL >> 3) +  6: character_address = data_reg[24];
			(DEFAULT_MESSAGE_START_COL >> 3) +  7: character_address = data_reg[23];
			(DEFAULT_MESSAGE_START_COL >> 3) +  8: character_address = data_reg[22];
			(DEFAULT_MESSAGE_START_COL >> 3) +  9: character_address = data_reg[21];
			(DEFAULT_MESSAGE_START_COL >> 3) + 10: character_address = data_reg[20];
			(DEFAULT_MESSAGE_START_COL >> 3) + 11: character_address = data_reg[19];
			(DEFAULT_MESSAGE_START_COL >> 3) + 12: character_address = data_reg[18];
			(DEFAULT_MESSAGE_START_COL >> 3) + 13: character_address = data_reg[17];
			(DEFAULT_MESSAGE_START_COL >> 3) + 14: character_address = data_reg[16];
			(DEFAULT_MESSAGE_START_COL >> 3) + 15: character_address = data_reg[15];
			(DEFAULT_MESSAGE_START_COL >> 3) + 16: character_address = data_reg[14];
			(DEFAULT_MESSAGE_START_COL >> 3) + 17: character_address = data_reg[13];
			(DEFAULT_MESSAGE_START_COL >> 3) + 18: character_address = data_reg[12];
			(DEFAULT_MESSAGE_START_COL >> 3) + 19: character_address = data_reg[11];
			(DEFAULT_MESSAGE_START_COL >> 3) + 20: character_address = data_reg[10];
			(DEFAULT_MESSAGE_START_COL >> 3) + 21: character_address = data_reg[9];
			(DEFAULT_MESSAGE_START_COL >> 3) + 22: character_address = data_reg[8];
			(DEFAULT_MESSAGE_START_COL >> 3) + 23: character_address = data_reg[7];
			(DEFAULT_MESSAGE_START_COL >> 3) + 24: character_address = data_reg[6];
			(DEFAULT_MESSAGE_START_COL >> 3) + 25: character_address = data_reg[5];
			(DEFAULT_MESSAGE_START_COL >> 3) + 26: character_address = data_reg[4];
			(DEFAULT_MESSAGE_START_COL >> 3) + 27: character_address = data_reg[3];
			(DEFAULT_MESSAGE_START_COL >> 3) + 28: character_address = data_reg[2];
			(DEFAULT_MESSAGE_START_COL >> 3) + 29: character_address = data_reg[1];
			(DEFAULT_MESSAGE_START_COL >> 3) + 30: character_address = data_reg[0];
			default: character_address = 6'o40;
		endcase
		
	end else begin
	
		if (max_letter == 6'o40 && number_address_1 == 6'o60 && number_address_2 == 6'o60 && (pixel_Y_pos[9:3] == ((SECOND_MESSAGE_LINE) >> 3))) begin
		
			// CASE NO MONITORED KEYS PRESSED
			case (pixel_X_pos[9:3])
				(DEFAULT_MESSAGE_START_COL >> 3) +  0: character_address = 6'o16; // N
				(DEFAULT_MESSAGE_START_COL >> 3) +  1: character_address = 6'o17; // O
				(DEFAULT_MESSAGE_START_COL >> 3) +  2: character_address = 6'o40; // 
				(DEFAULT_MESSAGE_START_COL >> 3) +  3: character_address = 6'o15; // M
				(DEFAULT_MESSAGE_START_COL >> 3) +  4: character_address = 6'o17; // o
				(DEFAULT_MESSAGE_START_COL >> 3) +  5: character_address = 6'o16; // N
				(DEFAULT_MESSAGE_START_COL >> 3) +  6: character_address = 6'o11; // I
				(DEFAULT_MESSAGE_START_COL >> 3) +  7: character_address = 6'o24; // T
				(DEFAULT_MESSAGE_START_COL >> 3) +  8: character_address = 6'o17; // O
				(DEFAULT_MESSAGE_START_COL >> 3) +  9: character_address = 6'o22; // R
				(DEFAULT_MESSAGE_START_COL >> 3) + 10: character_address = 6'o05; // E
				(DEFAULT_MESSAGE_START_COL >> 3) + 11: character_address = 6'o04; // D
				(DEFAULT_MESSAGE_START_COL >> 3) + 12: character_address = 6'o40; // 
				(DEFAULT_MESSAGE_START_COL >> 3) + 13: character_address = 6'o13; // K
				(DEFAULT_MESSAGE_START_COL >> 3) + 14: character_address = 6'o05; // E
				(DEFAULT_MESSAGE_START_COL >> 3) + 15: character_address = 6'o31; // Y
				(DEFAULT_MESSAGE_START_COL >> 3) + 16: character_address = 6'o23; // S
				(DEFAULT_MESSAGE_START_COL >> 3) + 17: character_address = 6'o40; // 
				(DEFAULT_MESSAGE_START_COL >> 3) + 18: character_address = 6'o20; // P
				(DEFAULT_MESSAGE_START_COL >> 3) + 19: character_address = 6'o22; // R
				(DEFAULT_MESSAGE_START_COL >> 3) + 20: character_address = 6'o05; // E
				(DEFAULT_MESSAGE_START_COL >> 3) + 21: character_address = 6'o23; // S
				(DEFAULT_MESSAGE_START_COL >> 3) + 22: character_address = 6'o23; // S
				(DEFAULT_MESSAGE_START_COL >> 3) + 23: character_address = 6'o05; // E
				(DEFAULT_MESSAGE_START_COL >> 3) + 24: character_address = 6'o04; // D
				default: character_address = 6'o40;
			endcase
		
		end else begin
		
			if (number_address_2 == 6'o60 && (pixel_Y_pos[9:3] == ((SECOND_MESSAGE_LINE) >> 3))) begin
			
				// CASE PS/2 MESSAGE LESS THAN 9
				case (pixel_X_pos[9:3])
					(DEFAULT_MESSAGE_START_COL >> 3) +  0: character_address = 6'o13; // K
					(DEFAULT_MESSAGE_START_COL >> 3) +  1: character_address = 6'o05; // E
					(DEFAULT_MESSAGE_START_COL >> 3) +  2: character_address = 6'o31; // Y
					(DEFAULT_MESSAGE_START_COL >> 3) +  3: character_address = 6'o40; // 
					(DEFAULT_MESSAGE_START_COL >> 3) +  4: character_address = max_letter; // LETTER
					(DEFAULT_MESSAGE_START_COL >> 3) +  5: character_address = 6'o40; // 
					(DEFAULT_MESSAGE_START_COL >> 3) +  6: character_address = 6'o20; // P
					(DEFAULT_MESSAGE_START_COL >> 3) +  7: character_address = 6'o22; // R
					(DEFAULT_MESSAGE_START_COL >> 3) +  8: character_address = 6'o05; // E
					(DEFAULT_MESSAGE_START_COL >> 3) +  9: character_address = 6'o23; // S
					(DEFAULT_MESSAGE_START_COL >> 3) + 10: character_address = 6'o23; // S
					(DEFAULT_MESSAGE_START_COL >> 3) + 11: character_address = 6'o05; // E
					(DEFAULT_MESSAGE_START_COL >> 3) + 12: character_address = 6'o04; // D
					(DEFAULT_MESSAGE_START_COL >> 3) + 13: character_address = 6'o40; // 
					(DEFAULT_MESSAGE_START_COL >> 3) + 14: character_address = number_address_1; // NUMBER
					(DEFAULT_MESSAGE_START_COL >> 3) + 15: character_address = 6'o40; // 
					(DEFAULT_MESSAGE_START_COL >> 3) + 16: character_address = 6'o24; // T
					(DEFAULT_MESSAGE_START_COL >> 3) + 17: character_address = 6'o11; // I
					(DEFAULT_MESSAGE_START_COL >> 3) + 18: character_address = 6'o15; // M
					(DEFAULT_MESSAGE_START_COL >> 3) + 19: character_address = 6'o05; // E
					(DEFAULT_MESSAGE_START_COL >> 3) + 20: character_address = 6'o23; // S
					default: character_address = 6'o40;
				endcase
			
			end else begin
			
				if ((pixel_Y_pos[9:3] == ((SECOND_MESSAGE_LINE) >> 3))) begin
			
					// CASE PS/2 MESSAGE GREATER THAN 9
					case (pixel_X_pos[9:3])
						(DEFAULT_MESSAGE_START_COL >> 3) +  0: character_address = 6'o13; // K
						(DEFAULT_MESSAGE_START_COL >> 3) +  1: character_address = 6'o05; // E
						(DEFAULT_MESSAGE_START_COL >> 3) +  2: character_address = 6'o31; // Y
						(DEFAULT_MESSAGE_START_COL >> 3) +  3: character_address = 6'o40; // 
						(DEFAULT_MESSAGE_START_COL >> 3) +  4: character_address = max_letter; // LETTER
						(DEFAULT_MESSAGE_START_COL >> 3) +  5: character_address = 6'o40; // 
						(DEFAULT_MESSAGE_START_COL >> 3) +  6: character_address = 6'o20; // P
						(DEFAULT_MESSAGE_START_COL >> 3) +  7: character_address = 6'o22; // R
						(DEFAULT_MESSAGE_START_COL >> 3) +  8: character_address = 6'o05; // E
						(DEFAULT_MESSAGE_START_COL >> 3) +  9: character_address = 6'o23; // S
						(DEFAULT_MESSAGE_START_COL >> 3) + 10: character_address = 6'o23; // S
						(DEFAULT_MESSAGE_START_COL >> 3) + 11: character_address = 6'o05; // E
						(DEFAULT_MESSAGE_START_COL >> 3) + 12: character_address = 6'o04; // D
						(DEFAULT_MESSAGE_START_COL >> 3) + 13: character_address = 6'o40; //
						(DEFAULT_MESSAGE_START_COL >> 3) + 14: character_address = number_address_2; // NUMBER
						(DEFAULT_MESSAGE_START_COL >> 3) + 15: character_address = number_address_1; // NUMBER
						(DEFAULT_MESSAGE_START_COL >> 3) + 16: character_address = 6'o40; // 
						(DEFAULT_MESSAGE_START_COL >> 3) + 17: character_address = 6'o24; // T
						(DEFAULT_MESSAGE_START_COL >> 3) + 18: character_address = 6'o11; // I
						(DEFAULT_MESSAGE_START_COL >> 3) + 19: character_address = 6'o15; // M
						(DEFAULT_MESSAGE_START_COL >> 3) + 20: character_address = 6'o05; // E
						(DEFAULT_MESSAGE_START_COL >> 3) + 21: character_address = 6'o23; // S
						default: character_address = 6'o40;
					endcase
				end
			end
		end
	end
end

// RGB signals
always_comb begin
		VGA_red = 8'h00;
		VGA_green = 8'h00;
		VGA_blue = 8'h00;

		if (screen_border_on) begin
			// blue border
			VGA_blue = 8'hFF;
		end
		
		if (rom_mux_output) begin
			// yellow text
			VGA_red = 8'hFF;
			VGA_green = 8'hFF;
		end
end

endmodule
