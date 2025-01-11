
`timescale 1ns/100ps
`ifndef DISABLE_DEFAULT_NET
`default_nettype none
`endif

module sampleCounter (

	input logic clock,
	
	input logic resetn,
	
	input logic enabled,
	
	input logic [17:0] baseAddress,
	
	input logic [5:0] colIdx,
	
	input logic [5:0] rowIdx,
	
	input logic isYFinished,
	
	output logic [5:0] sampleCounter,
	
	output logic [2:0] rowAddress,
	
	output logic [2:0] colAddress,
	
	output logic [17:0] addressGen,
	
	output logic isFinishedBlock

);

logic [2:0] rowAddr, colAddr;

logic [5:0] SC;

always @(posedge clock or negedge resetn) begin

	// Initialize
	if (~resetn) begin
		
		SC <= 0;
	
		rowAddr <= 0;
		
		colAddr <= 0;
		
		addressGen <= baseAddress;
		
		isFinishedBlock = 0;
	
	end else begin

		if (enabled) begin
			
			if (!isYFinished) begin
			
				if (SC == 63) begin
					
					SC <= 0;
							
					if(SC[2:0] == 7 && SC[5:3] == 7) begin
					
						isFinishedBlock <= 1;
						
					end else begin
					
						isFinishedBlock <= 0;
						
					end
							
				end else begin
						
					SC <= SC + 1;
							
				end
				
				sampleCounter <= SC;
				
				rowAddress <= SC[5:3];
				
				colAddress <= SC[2:0];
				
				addressGen <= baseAddress + (({rowIdx, 8'd0} + {rowIdx, 6'd0}) << 3) + ({SC[5:3], 8'd0} + {SC[5:3], 6'd0}) + (colIdx << 3) + SC[2:0];
			
			end else begin
			
				if (SC == 63) begin
					
					SC <= 0;
							
					if(SC[2:0] == 7 && SC[5:3] == 7) begin
					
						isFinishedBlock <= 1;
						
					end else begin
					
						isFinishedBlock <= 0;
						
					end
							
				end else begin
						
					SC <= SC + 1;
							
				end
				
				sampleCounter <= SC;
				
				rowAddress <= SC[5:3];
				
				colAddress <= SC[2:0];
				
				addressGen <= baseAddress + (({rowIdx, 7'd0} + {rowIdx, 5'd0}) << 3) + ({SC[5:3], 7'd0} + {SC[5:3], 5'd0}) + (colIdx << 3) + SC[2:0];
			
			end
			
			
		end
		
		if (isFinishedBlock) begin
		
			SC <= 0;
	
			rowAddr <= 0;
			
			colAddr <= 0;
			
			addressGen <= baseAddress;
			
			isFinishedBlock <= 0;
			
		end
			
	end
	
end

endmodule


