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

module experiment2 (
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

logic object_on_white, object_on_red, object_on_blue, object_on_green, object_on_yellow, object_on_cyan, object_on_magenta;

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

// we emulate the 25 MHz clock by using a 50 MHz AND
// updating the registers every other clock cycle
assign VGA_CLOCK_O = enable;
always_ff @(posedge CLOCK_50_I or negedge resetn) begin
	if(!resetn) begin
		enable <= 1'b0;
	end else begin
		enable <= ~enable;
	end
end

// if the column counter is between columns 300 and 339
// and line counter is between rows 220 and 259 (inclusive)
// assert the "object_on" signal
always_comb begin
	if (pixel_X_pos >= 10'd300 && pixel_X_pos < 10'd340
	 && pixel_Y_pos >= 10'd220 && pixel_Y_pos < 10'd260) 
		object_on_white = 1'b1;
	else 
		object_on_white = 1'b0;
		
	if (pixel_X_pos >= 10'd100 && pixel_X_pos < 10'd140
	 && pixel_Y_pos >= 10'd120 && pixel_Y_pos < 10'd160) 
		object_on_red = 1'b1;
	else 
		object_on_red = 1'b0;
		
	if (pixel_X_pos >= 10'd400 && pixel_X_pos < 10'd440
	 && pixel_Y_pos >= 10'd120 && pixel_Y_pos < 10'd160) 
		object_on_green = 1'b1;
	else 
		object_on_green = 1'b0;
		
	if (pixel_X_pos >= 10'd500 && pixel_X_pos < 10'd540
	 && pixel_Y_pos >= 10'd220 && pixel_Y_pos < 10'd260) 
		object_on_blue = 1'b1;
	else 
		object_on_blue = 1'b0;
		
	if (pixel_X_pos >= 10'd400 && pixel_X_pos < 10'd440
	 && pixel_Y_pos >= 10'd420 && pixel_Y_pos < 10'd460) 
		object_on_yellow = 1'b1;
	else 
		object_on_yellow = 1'b0;
		
	if (pixel_X_pos >= 10'd100 && pixel_X_pos < 10'd140
	 && pixel_Y_pos >= 10'd420 && pixel_Y_pos < 10'd460) 
		object_on_cyan = 1'b1;
	else 
		object_on_cyan = 1'b0;
		
	if (pixel_X_pos >= 10'd10 && pixel_X_pos < 10'd50
	 && pixel_Y_pos >= 10'd10 && pixel_Y_pos < 10'd50) 
		object_on_magenta = 1'b1;
	else 
		object_on_magenta = 1'b0;
		
		
end

// the background is black and a white square is 
// displayed only if the "object_on" signal is asserted
always_comb begin

	VGA_red = 8'h00;
	VGA_green = 8'h00;
	VGA_blue = 8'h00;
	
	if (object_on_white == 1'b1) begin
		VGA_red = 8'hFF;
		VGA_green = 8'hFF;
		VGA_blue = 8'hFF;
	end
	
	if (object_on_red == 1'b1) begin
		VGA_red = 8'hFF;
		VGA_green = 8'h00;
		VGA_blue = 8'h00;
	end
	
	if (object_on_green == 1'b1) begin
		VGA_red = 8'h00;
		VGA_green = 8'hFF;
		VGA_blue = 8'h00;
	end
	
	if (object_on_blue == 1'b1) begin
		VGA_red = 8'h00;
		VGA_green = 8'h00;
		VGA_blue = 8'hFF;
	end
	
	if (object_on_yellow == 1'b1) begin
		VGA_red = 8'hFF;
		VGA_green = 8'hFF;
		VGA_blue = 8'h00;
	end
	
	if (object_on_cyan == 1'b1) begin
		VGA_red = 8'h00;
		VGA_green = 8'hFF;
		VGA_blue = 8'hFF;
	end
	
	if (object_on_magenta == 1'b1) begin
		VGA_red = 8'hFF;
		VGA_green = 8'h00;
		VGA_blue = 8'hFF;
	end
	
end

endmodule
