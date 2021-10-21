/*
Copyright by Nicola Nicolici
Department of Electrical and Computer Engineering
McMaster University
Ontario, Canada
*/

`timescale 1ns/100ps
`default_nettype none

`include "../rtl/define_state.h"
`include "../rtl/VGA_param.h"

// the top module of the testbench
module TB;

	logic clock_50;
	logic [17:0] switch;
	logic [3:0] push_button_n;

	wire [15:0] SRAM_data_io;
	logic [15:0] SRAM_write_data, SRAM_read_data;
	logic [19:0] SRAM_address;
	logic SRAM_UB_N, SRAM_LB_N, SRAM_WE_N, SRAM_CE_N, SRAM_OE_N;
	logic SRAM_resetn;
	logic RAM_filled;

	logic VGA_clock;
	logic VGA_Hsync;
	logic VGA_Vsync;
	logic VGA_blank;
	logic VGA_sync;
	logic [7:0] VGA_red;
	logic [7:0] VGA_green;
	logic [7:0] VGA_blue;

	logic [7:0] expected_red, expected_green, expected_blue;
	logic [2:0] color;
	logic [2:0] current_row, current_col;
	logic [9:0] VGA_row, VGA_col;
	logic VGA_en;
	int number_of_mismatches;

	// instantiate the unit under test
	experiment1 UUT (
		.CLOCK_50_I(clock_50),
		.SWITCH_I(switch),
		.PUSH_BUTTON_N_I(push_button_n),

		.VGA_CLOCK_O(VGA_clock),
		.VGA_HSYNC_O(VGA_Hsync),
		.VGA_VSYNC_O(VGA_Vsync),
		.VGA_BLANK_O(VGA_blank),
		.VGA_SYNC_O(VGA_sync),
		.VGA_RED_O(VGA_red),
		.VGA_GREEN_O(VGA_green),
		.VGA_BLUE_O(VGA_blue),

		.SRAM_DATA_IO(SRAM_data_io),
		.SRAM_ADDRESS_O(SRAM_address),
		.SRAM_UB_N_O(SRAM_UB_N),
		.SRAM_LB_N_O(SRAM_LB_N),
		.SRAM_WE_N_O(SRAM_WE_N),
		.SRAM_CE_N_O(SRAM_CE_N),
		.SRAM_OE_N_O(SRAM_OE_N)
	);

	// the emulator for the external SRAM during simulation
	tb_SRAM_Emulator SRAM_component (
		.Clock_50(clock_50),
		.Resetn(SRAM_resetn),

		.SRAM_data_io(SRAM_data_io),
		.SRAM_address(SRAM_address[17:0]),
		.SRAM_UB_N(SRAM_UB_N),
		.SRAM_LB_N(SRAM_LB_N),
		.SRAM_WE_N(SRAM_WE_N),
		.SRAM_CE_N(SRAM_CE_N),
		.SRAM_OE_N(SRAM_OE_N)
	);

	// 50 MHz clock generation
	always begin
		#10;
		clock_50 = ~clock_50;
	end

	initial begin
		$timeformat(-6, 2, "us", 10);
		clock_50 = 1'b0;
		switch[17:0] = 18'd0;
		push_button_n[3:0] = 4'hF;
		SRAM_resetn = 1'b1;
		RAM_filled = 1'b0;
		number_of_mismatches = 0;
		repeat (2) @(negedge clock_50);
		$display("\n*** Asserting the asynchronous reset ***");
		switch[17] = 1'b1;
		repeat (3) @(negedge clock_50);
		switch[17] = 1'b0;
		$display("*** Deasserting the asynchronous reset ***\n");
		@(negedge clock_50);
		// clear SRAM model
		SRAM_resetn = 1'b0;
		@(negedge clock_50);
		SRAM_resetn = 1'b1;
	end

	initial begin
		wait (SRAM_resetn === 1'b0);
		wait (SRAM_resetn === 1'b1);
		repeat (3) @ (posedge clock_50);

		// activate Push button 0
		$write("%t: start signal issued by pressing PB0\n\n", $realtime);
		push_button_n[0] = 1'b0;

		@ (posedge UUT.PB_pushed[0]);
		$write("%t: pulse generated for PB0\n\n", $realtime);
		push_button_n[0] = 1'b1;

		$write("%t: waiting for SRAM to be filled ...\n\n", $realtime);
		@ (posedge RAM_filled);

		$write("Simulating one frame for 640x480 @ 60 Hz ...\n\n");

		@(negedge VGA_Vsync);
		$write("\n%t: finish simulating one frame for 640x480 @ 60 Hz\n", $realtime);

		if (number_of_mismatches == 0) $write("No mismatches!\n\n");
		else $write("A total of %d mismatches!\n\n", number_of_mismatches);

		$stop;
	end

	// check if SRAM has been filled
	always @ (posedge clock_50) begin
		if (UUT.state == S_FINISH_FILL_SRAM) begin
			$write("SRAM is now filled\n\n");
			RAM_filled <= 1'b1;
		end
	end

	always @ (posedge clock_50) begin
		if (~VGA_Vsync) begin
			VGA_en <= 1'b0;
			VGA_row <= 10'h000;
			VGA_col <= 10'h000;
		end else begin
			VGA_en <= ~VGA_en;
			// in 640x480 @ 60 Hz mode, data is provided at every other clock cycle when using 50 MHz clock
			if (VGA_en) begin
				// delay pixel_X_pos and pixel_Y_pos to match the VGA controller
				VGA_row <= UUT.pixel_Y_pos;
				VGA_col <= UUT.pixel_X_pos;

				if (RAM_filled == 1'b1) begin
					if (VGA_row == VIEW_AREA_TOP && VGA_col == VIEW_AREA_LEFT) $write("Entering 320x240 display area ...\n\n");
					if (VGA_row == VIEW_AREA_BOTTOM && VGA_col == VIEW_AREA_RIGHT) $write("Leaving 320x240 display area ...\n\n");

					// in display area
					if ((VGA_row >= VIEW_AREA_TOP && VGA_row < VIEW_AREA_BOTTOM)
		 			 && (VGA_col >= VIEW_AREA_LEFT && VGA_col < VIEW_AREA_RIGHT)) begin

		 				// calculate expected data from the pixel counters

		 				// find row of rectangle
						current_row = (VGA_row - VIEW_AREA_TOP) / RECT_HEIGHT;

						// find col of rectangle
						current_col = (VGA_col - VIEW_AREA_LEFT) / RECT_WIDTH;

						// get color of the rectangle
						color = current_col + current_row;

						expected_red = {8{color[2]}};
						expected_green = {8{color[1]}};
						expected_blue = {8{color[0]}};

						if (VGA_red != expected_red) begin
							$write("Red   mismatch at pixel (%d, %d): expect=%x, got=%x\n",
								VGA_col, VGA_row, expected_red, VGA_red);
							number_of_mismatches++;
						end
						if (VGA_green != expected_green) begin
							$write("Green mismatch at pixel (%d, %d): expect=%x, got=%x\n",
								VGA_col, VGA_row, expected_green, VGA_green);
							number_of_mismatches++;
						end
						if (VGA_blue != expected_blue) begin
							$write("Blue  mismatch at pixel (%d, %d): expect=%x, got=%x\n",
								VGA_col, VGA_row, expected_blue, VGA_blue);
							number_of_mismatches++;
						end
					end
				end
			end
		end
	end

	// the code below is used to store one frame of video in a .ppm file
	// there is no need to change it

	task automatic open_frame_file(ref int frame_fd, int frame);
		static string frame_filename = "";
		static string str_tmp = "";
	begin
		str_tmp = $sformatf("%1d", frame);
		frame_filename = {"../data/frame", str_tmp, ".ppm"};
		frame_fd = $fopen (frame_filename, "wb");
		str_tmp = $sformatf("%1d %1d", H_SYNC_ACT, V_SYNC_ACT);
		$fwrite(frame_fd, "P6%c%s%c255%c", 8'h0A, str_tmp, 8'h0A, 8'h0A);
	end
	endtask

	task write_vga_frame();
		static int vga_row, vga_col;
		static logic buf_hsync = 0, buf_vsync = 0;
		static int frame = 0, frame_fd;
	begin
		// the VGA controller with PIPE_DELAY as a parameter
		// generates a short H_SYNC pulse after async reset;
		// this might "trick" the testbench into a wrong assumption
		// that a full H_SYNC cycle has passed (not an issue on board
		// because the monitor will ignore these type of short pulses)

		vga_row = -Y_START+1-(PIPE_DELAY?1:0);
		vga_col = -X_START;
		open_frame_file(frame_fd, frame);
		forever begin
			@(posedge VGA_clock);

			if ((vga_row >= 0) && (vga_row < V_SYNC_ACT))
				if ((vga_col >= 0) && (vga_col < H_SYNC_ACT)) begin
					$fwrite(frame_fd, "%c%c%c", VGA_red, VGA_green, VGA_blue);
			end

			vga_col = vga_col + 1;
			if (buf_hsync && !VGA_Hsync) begin
				vga_col = -X_START + 1;
				vga_row = vga_row + 1;
			end

			if (buf_vsync && !VGA_Vsync) begin
				vga_row = -Y_START+1;
				frame = frame + 1;
				$fclose(frame_fd);
				open_frame_file(frame_fd, frame);
			end

			buf_hsync <= VGA_Hsync;
			buf_vsync <= VGA_Vsync;
		end
	end
	endtask

	initial begin
		write_vga_frame();
	end

endmodule
