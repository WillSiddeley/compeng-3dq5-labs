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

module experiment1 (
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
		output logic[7:0] VGA_BLUE_O              // VGA blue
);

`include "VGA_param.h"

logic resetn, enable;

// For VGA
logic [7:0] VGA_red, VGA_green, VGA_blue;
logic [9:0] pixel_X_pos;
logic [9:0] pixel_Y_pos;

assign resetn = ~SWITCH_I[17];

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

// we emulate the 25 MHz clock by using a 50 MHz 
// AND
// updating the registers every other clock cycle

always_ff @(posedge CLOCK_50_I or negedge resetn) begin
	if(!resetn) begin
		enable <= 1'b0;
	end else begin
		enable <= ~enable;
	end
end
assign VGA_CLOCK_O = enable;


// for the video clock of 50 MHz:
// comment the always_ff block above 
// AND
// uncomment the two assign statements below
/*
assign enable = 1'b1;
assign VGA_CLOCK_O = ~CLOCK_50_I;
*/

// signal concatenation through replication:
// ~pixel_X_pos[i] is replicated 8 times to create a 8 bit signal 

assign VGA_red = SWITCH_I[0] ? {8{~pixel_Y_pos[8]}} : {8{~pixel_X_pos[8]}};
assign VGA_green = SWITCH_I[0] ? {8{~pixel_Y_pos[7]}} : {8{~pixel_X_pos[7]}};
assign VGA_blue = SWITCH_I[0] ? {8{~pixel_Y_pos[6]}} : {8{~pixel_X_pos[6]}}; 

endmodule
