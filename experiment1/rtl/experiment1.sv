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
// It illustrates how boolean functions for SystemVerilog
// It uses switches and LEDs on the DE2 board as IOs
module experiment1 (
		/////// switches                          ////////////
		input logic[17:0] SWITCH_I,               // toggle switches

		/////// LEDs                              ////////////
		output logic[8:0] LED_GREEN_O,            // 9 green LEDs
		output logic[17:0] LED_RED_O              // 18 red LEDs
);

logic NOT;
logic AND2, OR2;
logic AND3, OR3;
logic NAND4, NOR4;
logic AND_OR, AND_XOR;

always_comb begin
	NOT = ~SWITCH_I[17];
end

always_comb begin
	AND2 = SWITCH_I[16] & SWITCH_I[15];
	OR2  = SWITCH_I[16] | SWITCH_I[15];
end

always_comb begin
	AND3 = &SWITCH_I[14:12];
	OR3  = |SWITCH_I[14:12];
end

always_comb begin
	NAND4 = 1'b0;	
	NOR4  = 1'b0;	
end

always_comb begin
	AND_OR = 1'b0;
	AND_XOR = 1'b0;
end

assign LED_RED_O = SWITCH_I;
assign LED_GREEN_O = {NOT, AND2, OR2, AND3, OR3, NAND4, NOR4, AND_OR, AND_XOR};
	
endmodule
