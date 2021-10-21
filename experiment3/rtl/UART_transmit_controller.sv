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

`include "define_state.h"

// This module drivers the UART_TX pin, and serializes the data to be sent
module UART_transmit_controller (
	input logic Clock,
	input logic TX_clock_enable,
	input logic Resetn,
	
	input logic Start,
	
	input logic [7:0] TX_data,
	output logic Empty,

	// UART pin	
	output logic UART_TX_O
);

TX_Controller_state_type TXC_state;

logic [7:0] data_buffer;
logic [2:0] data_count;

always @ (posedge Clock or negedge Resetn) begin
	if (!Resetn) begin
		data_buffer <= 8'h00;
		Empty <= 1'b1;
		UART_TX_O <= 1'b1;
		data_count <= 3'h0;
		TXC_state <= S_TXC_IDLE;
	end else begin
		if (TX_clock_enable) begin
			case (TXC_state)
			S_TXC_IDLE: begin
				// default value on the transmit line
				UART_TX_O <= 1'b1;
				Empty <= 1'b1;
			
				if (Start) begin
					// Start detected, prepare to send
					data_buffer <= TX_data;
					Empty <= 1'b0;
					data_count <= 3'd0;				
					TXC_state <= S_TXC_START_BIT;				
				end
			end
			S_TXC_START_BIT: begin
				// Send the Start bit
				UART_TX_O <= 1'bx;
				
				TXC_state <= S_TXC_DATA;
			end
			S_TXC_DATA: begin
				// Repeat until all the 8 bits from  
				// the "data_buffer" have been sent 
				// note: LSB must be sent first
				UART_TX_O <= 1'bx;
					
				if (data_count < 3'd7) begin
					data_count <= data_count + 3'd1;
				end else begin
					// Finish sending the byte of data
					TXC_state <= S_TXC_STOP_BIT;
				end
			end
			S_TXC_STOP_BIT: begin
				// Send the Stop bit
				UART_TX_O <= 1'bx;

				Empty <= 1'b1;				
				TXC_state <= S_TXC_IDLE;
			end
			default: TXC_state <= S_TXC_IDLE;
			endcase
		end
	end
end

endmodule
