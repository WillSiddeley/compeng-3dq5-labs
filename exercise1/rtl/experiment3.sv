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

enum logic [2:0] {
	S_READ,
	S_WRITE,
	S_LAST_READ,
	S_LAST_WRITE,
	S_IDLE
} state;

logic [8:0] address_ram0, address_ram0_shifted, address_ram1, address_ram1_shifted;
logic [7:0] write_data_a [1:0];
logic [7:0] write_data_b [1:0];
logic write_enable_a [1:0];
logic write_enable_b [1:0];
logic [7:0] read_data_a [1:0];
logic [7:0] read_data_b [1:0];

// RAM0 = W
dual_port_RAM0 RAM_inst0 (
	.address_a ( address_ram0 ),
	.address_b ( address_ram0_shifted ),
	.clock ( CLOCK_50_I ),
	.data_a ( write_data_a[0] ),
	.data_b ( write_data_b[0] ),
	.wren_a ( write_enable_a[0] ),
	.wren_b ( write_enable_b[0] ),
	.q_a ( read_data_a[0] ),
	.q_b ( read_data_b[0] )
	);

// RAM1 = X
dual_port_RAM1 RAM_inst1 (
	.address_a ( address_ram1 ),
	.address_b ( address_ram1_shifted ),
	.clock ( CLOCK_50_I ),
	.data_a ( write_data_a[1] ),
	.data_b ( write_data_b[1] ),
	.wren_a ( write_enable_a[1] ),
	.wren_b ( write_enable_b[1] ),
	.q_a ( read_data_a[1] ),
	.q_b ( read_data_b[1] )
	);

	// Y[i]
	assign write_data_a[0] = read_data_b[0] - read_data_a[1];
	
	// Y[i + 256]
	assign write_data_b[0] = read_data_a[0] - read_data_b[1];
	
	// Z[i]
	assign write_data_a[1] = read_data_a[0] + read_data_b[1];
	
	// Z[i + 256]
	assign write_data_b[1] = read_data_b[0] + read_data_a[1];
	

// FSM to control the read and write sequence
always_ff @ (posedge CLOCK_50_I or negedge resetn) begin
	if (resetn == 1'b0) begin
		address_ram0 <= 9'd0;
		address_ram1 <= 9'd0;
		address_ram0_shifted <= 9'd256;
		address_ram1_shifted <= 9'd256;
		write_enable_a[0] <= 1'b0;
		write_enable_a[1] <= 1'b0;
		write_enable_b[0] <= 1'b0;
		write_enable_b[1] <= 1'b0;
		state <= S_IDLE;
	end else begin
		case (state)
			S_IDLE: begin	
				// wait for switch[0] to be asserted
				if (SWITCH_I[0])
					state <= S_WRITE;
			end
			S_READ: begin
			
				// Prepare addresses to read
				address_ram0 <= address_ram0 + 9'd1;
				address_ram1 <= address_ram1 + 9'd1;
				address_ram0_shifted <= address_ram0_shifted + 9'd1;
				address_ram1_shifted <= address_ram0_shifted + 9'd1;
			
				// Disable write enable
				write_enable_a[0] <= 1'b0;
				write_enable_a[1] <= 1'b0;
				write_enable_b[0] <= 1'b0;
				write_enable_b[1] <= 1'b0;
			
				if (address_ram0 == 9'd254) begin
				
					state <= S_LAST_WRITE;
					
				end else begin
				
					state <= S_WRITE;
				
				end
			
			end
			S_WRITE: begin
			
				// Disable write enable
				write_enable_a[0] <= 1'b1;
				write_enable_a[1] <= 1'b1;
				write_enable_b[0] <= 1'b1;
				write_enable_b[1] <= 1'b1;
				
				state <= S_READ;
			
			end
			S_LAST_WRITE: begin	

				write_enable_a[0] <= 1'b1;
				write_enable_a[1] <= 1'b1;
				write_enable_b[0] <= 1'b1;
				write_enable_b[1] <= 1'b1;
				
				state <= S_LAST_READ;
				
			end
			S_LAST_READ: begin
			
				address_ram0 <= 9'd0;
				address_ram1 <= 9'd0;
				address_ram0_shifted <= 9'd256;
				address_ram1_shifted <= 9'd256;
				
				write_enable_a[0] <= 1'b0;
				write_enable_a[1] <= 1'b0;
				write_enable_b[0] <= 1'b0;
				write_enable_b[1] <= 1'b0;
			
				state <= S_IDLE;
			end
		endcase
	end
end

// dump some dummy values on the output green LEDs to constrain 
// the synthesis tools not to remove the circuit logic
assign LED_GREEN_O = {1'b0, {write_data_b[1] ^ write_data_b[0]}};

endmodule
