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

		/////// LEDs                              ////////////
		output logic[8:0] LED_GREEN_O             // 9 green LEDs
);

logic resetn;
assign resetn = ~SWITCH_I[17];

enum logic [1:0] {
	S_READ,
	S_WRITE,
	S_IDLE
} state;

logic [8:0] address;
logic [7:0] write_data [1:0];
logic write_enable [1:0];
logic [7:0] read_data [1:0];

// instantiate RAM0
single_port_RAM0 RAM_inst0 (
	.address ( address ),
	.clock ( CLOCK_50_I ),
	.data ( write_data[0] ),
	.wren ( write_enable[0] ),
	.q ( read_data[0] )
	);

// instantiate RAM1
single_port_RAM1 RAM_inst1 (
	.address ( address ),
	.clock ( CLOCK_50_I ),
	.data ( write_data[1] ),
	.wren ( write_enable[1] ),
	.q ( read_data[1] )
	);

// the adder and substractor for the write port of the RAMs
assign write_data[0] = read_data[0] + read_data[1];
assign write_data[1] = read_data[0] - read_data[1];

// FSM to control the read and write sequence
always_ff @ (posedge CLOCK_50_I or negedge resetn) begin
	if (resetn == 1'b0) begin
		address <= 9'd0;
		write_enable[0] <= 1'b0;
		write_enable[1] <= 1'b0;		
		state <= S_IDLE;
	end else begin
		case (state)
			S_IDLE: begin	
				write_enable[0] <= 1'b0;
				write_enable[1] <= 1'b0;
				address <= 9'd0;
				// wait for switch[0] to be asserted
				if (SWITCH_I[0])
					state <= S_READ;
			end
			S_READ: begin
				// write data in next clock cycle (cc)
				write_enable[0] <= 1'b1;
				write_enable[1] <= 1'b1;							
				state <= S_WRITE;
			end
			S_WRITE: begin
				// prepare address to read for next cc
				write_enable[0] <= 1'b0;
				write_enable[1] <= 1'b0;			
		
				if (address < 9'd511) begin
					address <= address + 9'd1;	
					state <= S_READ;		
				end else begin
					// finish writing 512 addresses
					state <= S_IDLE;
				end
			end
		endcase
	end
end

// dump some dummy values on the output green LEDs to constrain 
// the synthesis tools not to remove the circuit logic
assign LED_GREEN_O = {1'b0, {write_data[1] ^ write_data[0]}};

endmodule
