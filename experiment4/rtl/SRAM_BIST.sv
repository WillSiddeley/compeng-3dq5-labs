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

module SRAM_BIST (
	input logic Clock,
	input logic Resetn,
	input logic BIST_start,
	
	output logic [17:0] BIST_address,
	output logic [15:0] BIST_write_data,
	output logic BIST_we_n,
	input logic [15:0] BIST_read_data,
	
	output logic BIST_finish,
	output logic BIST_mismatch
);

enum logic [2:0] {
	S_IDLE,
	S_DELAY_1,
	S_DELAY_2,
	S_WRITE_CYCLE,
	S_READ_CYCLE,
	S_DELAY_3,
	S_DELAY_4
} BIST_state;

logic BIST_start_buf;
logic [15:0] BIST_expected_data;

assign BIST_write_data[15:0] = BIST_address[15:0];

assign BIST_expected_data[15:0] = BIST_address[15:0] - 16'd2;

always_ff @ (posedge Clock or negedge Resetn) begin
	if (Resetn == 1'b0) begin
		BIST_state <= S_IDLE;
		BIST_mismatch <= 1'b0;
		BIST_finish <= 1'b0;
		BIST_address <= 18'd0;
		BIST_we_n <= 1'b1;		
		BIST_start_buf <= 1'b0;
	end else begin
		BIST_start_buf <= BIST_start;
		
		case (BIST_state)
		S_IDLE: begin
			if (BIST_start & ~BIST_start_buf) begin
				// start the BIST engine
				BIST_address <= 18'd0;
				BIST_we_n <= 1'b0; // initiate first WRITE
				BIST_mismatch <= 1'b0;
				BIST_finish <= 1'b0;
				BIST_state <= S_WRITE_CYCLE;
			end else begin
				BIST_address <= 18'd0;
				BIST_we_n <= 1'b1;
				BIST_finish <= 1'b1;				
			end
		end
		// a couple of delay states to initiate the first WRITE and first READ
		S_DELAY_1: begin
			BIST_address <= BIST_address + 18'd1;  // initiate first READ (NOTE: registers updated NEXT clock cycle)
			BIST_state <= S_DELAY_2;
		end
		S_DELAY_2: begin
			BIST_address <= BIST_address + 18'd1;
			BIST_state <= S_READ_CYCLE;
		end
		S_WRITE_CYCLE: begin
			BIST_address <= BIST_address + 18'd1;
			if (BIST_address == 18'h3FFFF) begin
				BIST_we_n <= 1'b1;
				BIST_address <= 18'd0;
				BIST_state <= S_DELAY_1;
			end
		end
		S_READ_CYCLE: begin
			// complete the READ initiated two clock cycles earlier and perform comparison
			if (BIST_read_data != BIST_expected_data) 
				BIST_mismatch <= 1'b1;
			BIST_address <= BIST_address + 18'd1;
			if (BIST_address == 18'h3FFFF) begin
				// delay for checking the last address
				BIST_state <= S_DELAY_3;
			end
		end
		S_DELAY_3: begin
		
			BIST_address <= BIST_address + 18'd1;
		
			if (BIST_read_data != BIST_expected_data) begin
				BIST_mismatch <= 1'b1;
			end
			
			BIST_state <= S_DELAY_4;
			
		end
		S_DELAY_4: begin
		
			BIST_address <= BIST_address + 18'd1;
			
			if (BIST_read_data != BIST_expected_data) begin
				BIST_mismatch <= 1'b1;
			end
			
			// finish the whole SRAM
			BIST_state <= S_IDLE;
			BIST_finish <= 1'b1;	
			
		end
		default: BIST_state <= S_IDLE;
		endcase
	end
end

endmodule
