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

module char_rom (
	input logic Clock,
	input logic [5:0] Character_address,
	input logic [2:0] Font_row,
	input logic [2:0] Font_col,	
	
	output logic Rom_mux_output
);

logic [7:0] char_rom_data;

char_gen_rom	char_gen_rom_inst (
	.address ( {Character_address, Font_row} ),
	.clock ( Clock ),
	.q ( char_rom_data )
	);

assign Rom_mux_output = char_rom_data[~Font_col];

endmodule
