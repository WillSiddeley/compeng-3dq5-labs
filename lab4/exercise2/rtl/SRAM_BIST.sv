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

enum logic [3:0] {
	S_IDLE,
	S_WRITE_EVEN_CYCLE,
	S_READ_EVEN_CYCLE,
	S_WRITE_ODD_CYCLE,
	S_READ_ODD_CYCLE,
	S_DELAY_1,
	S_DELAY_2,
	S_DELAY_3,
	S_DELAY_4,
	S_DELAY_5,
	S_DELAY_6,
	S_DELAY_7,
	S_DELAY_8
} BIST_state;

logic BIST_start_buf;
logic [15:0] BIST_expected_data_fw;
logic [15:0] BIST_expected_data_bw;

assign BIST_write_data[15:0] = BIST_address[15:0];

assign BIST_expected_data_fw[15:0] = BIST_address[15:0] - 16'd4;
assign BIST_expected_data_bw[15:0] = BIST_address[15:0] + 16'd4;

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
				BIST_address <= 18'd0;
				BIST_we_n <= 1'b0;
				BIST_mismatch <= 1'b0;
				BIST_finish <= 1'b0;
				BIST_state <= S_WRITE_EVEN_CYCLE;
			end else begin
				BIST_address <= 18'd0;
				BIST_we_n <= 1'b1;
				BIST_finish <= 1'b1;				
			end
		end
		
		S_DELAY_1: begin
			BIST_address <= 18'h3FFFC;
			BIST_state <= S_DELAY_2;
		end
		
		S_DELAY_2: begin
			BIST_address <= BIST_address - 18'd2;
			BIST_state <= S_READ_EVEN_CYCLE;
		end
		
		S_DELAY_3: begin
			BIST_address <= 18'h3FFFF;
			BIST_state <= S_DELAY_4;
		end
		
		S_DELAY_4: begin
			BIST_address <= BIST_address - 18'd2;
			BIST_state <= S_WRITE_ODD_CYCLE;
		end
		
		S_DELAY_5: begin
			BIST_address <= 18'd3;
			BIST_state <= S_DELAY_6;
		end
		
		S_DELAY_6: begin
			BIST_address <= BIST_address + 18'd2;
			BIST_state <= S_READ_ODD_CYCLE;
		end
		
		// 18'h3FFFF = 262,143
		
		S_WRITE_EVEN_CYCLE: begin
			BIST_address <= BIST_address + 18'd2;
			if (BIST_address == 18'h3FFFE) begin
				BIST_we_n <= 1'b1;
				BIST_address <= 18'h3FFFE;
				BIST_state <= S_DELAY_1;
			end
		end
		
		S_READ_EVEN_CYCLE: begin
			if (BIST_read_data != BIST_expected_data_bw) begin
				BIST_mismatch <= 1'b1;
			end
			
			BIST_address <= BIST_address - 18'd2;
			
			if (BIST_address == 18'h0) begin
				BIST_we_n <= 1'b0;
				BIST_address <= 18'h0;
				BIST_state <= S_DELAY_3;
			end
		end
		
		S_WRITE_ODD_CYCLE: begin
			BIST_address <= BIST_address - 18'd2;
			if (BIST_address == 18'd1) begin
				BIST_we_n <= 1'b1;
				BIST_address <= 18'd1;
				BIST_state <= S_DELAY_5;
			end
		end
	
		S_READ_ODD_CYCLE: begin
			if (BIST_read_data != BIST_expected_data_fw) begin
				BIST_mismatch <= 1'b1;
			end
			
			BIST_address <= BIST_address + 18'd2;
			
			if (BIST_address == 18'h3FFFF) begin
				BIST_we_n <= 1'b0;
				BIST_address <= 18'h1;
				BIST_state <= S_DELAY_7;
			end
		end
		
		S_DELAY_7: begin
		
			BIST_address <= BIST_address + 18'd2;
			
			if (BIST_read_data != BIST_expected_data_fw) begin
				BIST_mismatch <= 1'b1;
			end
			
			BIST_finish = 1'b1;
			BIST_state <= S_DELAY_8;
			
		end
		
		S_DELAY_8: begin
		
			if (BIST_read_data != BIST_expected_data_fw) begin
				BIST_mismatch <= 1'b1;
			end
			
			BIST_finish = 1'b1;
			BIST_state <= S_IDLE;
			
		end
		
		default: BIST_state <= S_IDLE;
		
		endcase
	end
end

endmodule