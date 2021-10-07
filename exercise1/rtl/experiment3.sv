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

		/////// LEDs                              ////////////
		output logic[8:0] LED_GREEN_O             // 9 green LEDs
);

logic resetn;
assign resetn = ~SWITCH_I[17];

enum logic [1:0] {
	S_READ_WRITE,
	S_LAST_WRITE,
	S_IDLE
} state;

logic [8:0] read_address, write_address;
logic [7:0] write_data_a [1:0];
logic [7:0] write_data_b [1:0];
logic write_enable_a [1:0];
logic write_enable_b [1:0];
logic [7:0] read_data_a [1:0];
logic [7:0] read_data_b [1:0];

// instantiate RAM0
dual_port_RAM0 RAM_inst0 (
	.address_a ( read_address ),
	.address_b ( write_address ),
	.clock ( CLOCK_50_I ),
	.data_a ( write_data_a[0] ),
	.data_b ( write_data_b[0] ),
	.wren_a ( 1'b0 ),
	.wren_b ( write_enable_b[0] ),
	.q_a ( read_data_a[0] ),
	.q_b ( read_data_b[0] )
	);

// instantiate RAM1
dual_port_RAM1 RAM_inst1 (
	.address_a ( read_address ),
	.address_b ( write_address ),
	.clock ( CLOCK_50_I ),
	.data_a ( write_data_a[1] ),
	.data_b ( write_data_b[1] ),
	.wren_a ( write_enable_a[1] ),
	.wren_b ( write_enable_b[1] ),
	.q_a ( read_data_a[1] ),
	.q_b ( read_data_b[1] )
	);

// the top port is used only for reading for both memories
// hence we disable the write enable for the top port 
assign write_enable_a [0] = 1'b0;
assign write_enable_a [1] = 1'b0;
// since write enable is disabled for the top port we can 
// assign write data on the top port to some dummy values
assign write_data_a[0] = 8'd0;
assign write_data_a[1] = 8'd0;

// the adder for the write port of the first RAM
assign write_data_b[0] = read_data_a[0] + read_data_a[1];
// this is where the circuit is incomplete
// expand as requested for the write port of the RAM1
assign write_data_b[1] = 8'hff;
// note: this write enable must be registered
// and asserted ONLY when write data is valid
assign write_enable_b[1] = 1'b0;

// FSM to control the read and write sequence
always_ff @ (posedge CLOCK_50_I or negedge resetn) begin
	if (resetn == 1'b0) begin
		read_address <= 9'd0;
		write_address <= 9'd0;		
		write_enable_b[0] <= 1'b0;
		state <= S_IDLE;
	end else begin
		case (state)
			S_IDLE: begin	
				// wait for switch[0] to be asserted
				if (SWITCH_I[0])
					state <= S_READ_WRITE;
			end
			S_READ_WRITE: begin
				// prepare addresses to read/write 
				// for the next clock cycle (cc)
				read_address <= read_address + 9'd1;
				write_address <= read_address;
	
				// write enable will be asserted
				// as of the second cc in this state
				write_enable_b[0] <= 1'b1;
	
				// finished initiating reads
				if (read_address == 9'd511)
					state <= S_LAST_WRITE;
			end
			S_LAST_WRITE: begin	
				// in this state the last write completes
				// then the next cc we move back to S_IDLE
				read_address <= 9'd0;
				write_address <= 9'd0;		
				write_enable_b[0] <= 1'b0;
				state <= S_IDLE;
			end
		endcase
	end
end

// dump some dummy values on the output green LEDs to constrain 
// the synthesis tools not to remove the circuit logic
assign LED_GREEN_O = {1'b0, {write_data_b[1] ^ write_data_b[0]}};

endmodule
