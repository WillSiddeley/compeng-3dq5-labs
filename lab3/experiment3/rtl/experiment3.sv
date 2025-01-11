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

module experiment3 (
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

parameter TOP_LEFT_COLUMN = 300, TOP_LEFT_ROW = 220, OBJECT_SIZE = 40;
parameter RED_SIZE = 100, GREEN_SIZE = 200, BLUE_SIZE = 300;
parameter SINGLE_CC_CHAIN_SIZE = 25;

// combinational buffer line used to introduce additional delay
logic[RED_SIZE:0] red_buffer_line;
logic[BLUE_SIZE:0] blue_buffer_line;
logic[GREEN_SIZE:0] green_buffer_line;

logic resetn, enable;

// For VGA
logic [7:0] VGA_red, VGA_green, VGA_blue;
logic [9:0] pixel_X_pos;
logic [9:0] pixel_Y_pos;

logic object_on;

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

// Check if white square should be displayed or not
always_comb begin
	if (pixel_X_pos >= TOP_LEFT_COLUMN 
	 && pixel_X_pos < TOP_LEFT_COLUMN + OBJECT_SIZE
	 && pixel_Y_pos >= TOP_LEFT_ROW 
	 && pixel_Y_pos < TOP_LEFT_ROW + OBJECT_SIZE) 
		object_on = 1'b1;
	else 
		object_on = 1'b0;
end

// instantiate "lcell" module "RED_SIZE" times - creates a long combinational path 
// the lcell modules for Altera devices work as repeaters (i.e., output equals input)
// repeaters have no functional purpose, however they add to propagation delays

genvar i;
integer j;

assign red_buffer_line[0] = object_on;
generate
	for (i=0; i<RED_SIZE; i=i+1)
	begin: instance_of_red_lcell
		lcell red_buffer (.in(red_buffer_line[i]), .out(red_buffer_line[i+1])); 
	end
endgenerate

assign green_buffer_line[0] = object_on;
generate
	for (i=0; i<GREEN_SIZE; i=i+1)
	begin: instance_of_green_lcell
		lcell green_buffer (.in(green_buffer_line[i]), .out(green_buffer_line[i+1])); 
	end
endgenerate


assign blue_buffer_line[0] = object_on;
generate
	for (i=0; i<BLUE_SIZE; i=i+1)
	begin: instance_of_blue_lcell
		lcell blue_buffer (.in(blue_buffer_line[i]), .out(blue_buffer_line[i+1])); 
	end
endgenerate

/*
assign blue_buffer_line[0] = object_on;
generate
	for (i=0; i<BLUE_SIZE; i=i+1)
	begin: instance_of_blue_lcell
		if (((i+1) % SINGLE_CC_CHAIN_SIZE) != 0) 
			lcell blue_buffer (.in(blue_buffer_line[i]), .out(blue_buffer_line[i+1])); 
	end
endgenerate

always_ff @(posedge CLOCK_50_I or negedge resetn) begin
	if(!resetn) begin
		for (j=SINGLE_CC_CHAIN_SIZE; j<=BLUE_SIZE; j+=SINGLE_CC_CHAIN_SIZE)
			blue_buffer_line[j] <= 1'b0;
	end else begin
		for (j=SINGLE_CC_CHAIN_SIZE; j<=BLUE_SIZE; j+=SINGLE_CC_CHAIN_SIZE)
			blue_buffer_line[j] <= blue_buffer_line[j-1];
	end
end
*/

always_comb begin
	VGA_red = 8'h00;
	VGA_blue = 8'h00;
	VGA_green = 8'h00;
	if (red_buffer_line[RED_SIZE] == 1'b1)
		VGA_red = 8'hFF;
	if (green_buffer_line[GREEN_SIZE] == 1'b1)
		VGA_green = 8'hFF;
	if (blue_buffer_line[BLUE_SIZE] == 1'b1)
		VGA_blue = 8'hFF;
end

endmodule
