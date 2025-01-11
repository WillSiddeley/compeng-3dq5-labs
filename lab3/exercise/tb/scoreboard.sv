/*
Copyright by Nicola Nicolici
Department of Electrical and Computer Engineering
McMaster University
Ontario, Canada
*/

class scoreboard;
   
	mailbox mon2lcd, mon2vga;
	logic [8:0] lcd_event;
	logic [23:0] vga_event;
	int lcd_line;
	int lcd_col;
	logic [7:0] lcd_code;
	string lcd_top_line    = "                ";
	string lcd_bottom_line = "                ";
	  
	function new(mailbox mon2lcd, mailbox mon2vga);
		this.mon2lcd = mon2lcd;
		this.mon2vga = mon2vga;
	endfunction
  
	task reset();
	endtask

	function string convert_lcd_code_to_command(int lcd_data);
	begin
		string str;
		str = "";
		case(lcd_data)
			8'h38 : str = "Set display to be 8 bit and 2 lines";
			8'h0C : str = "Set display";
			8'h01 : str = "Clear display";
			8'h06 : str = "Enter entry mode";
			8'h80 : str = "Move to beginning of top line";
			8'hC0 : str = "Move to beginning of bottom line";
		endcase
		return str;
	end
	endfunction

	task update_lcd();
		forever begin
			mon2lcd.get(lcd_event);
			lcd_code = lcd_event[7:0];
			if (lcd_event[8] == 1'b0) begin
				$display("%t: LCD command: %s", 
					$realtime, 
					convert_lcd_code_to_command(lcd_code));
				if (lcd_code == 8'h80) begin
					lcd_line = 0;
					lcd_col = 0;
				end else if (lcd_code == 8'hC0) begin
					lcd_line = 1;
					lcd_col = 0;
				end else if (lcd_code == 8'h01) begin
					lcd_top_line    = "                ";
					lcd_bottom_line = "                ";
				end
			end else begin
				if (lcd_col > 15) begin
					$display("%t: Write character %s to LCD line %d column %d (outside of display)", 
						$realtime, 
						board_event::lcd_code_to_key_map[lcd_code],
						lcd_line,
						lcd_col);
				end else begin
					if (lcd_line == 0) 
						lcd_top_line.putc(lcd_col, board_event::lcd_code_to_key_map[lcd_code].getc(0));
					else if (lcd_line == 1) 
						lcd_bottom_line.putc(lcd_col, board_event::lcd_code_to_key_map[lcd_code].getc(0));
					else
						$display("%t: Wrong LCD line %d (outside of display)", $realtime, lcd_line); 
					$display("%t: LCD top    line: %s", $realtime, lcd_top_line);
					$display("%t: LCD bottom line: %s", $realtime, lcd_bottom_line);
				end
				lcd_col++;
			end
		end
	endtask

	task open_frame_file(ref int ppm_fd, int frame);
		string ppm_filename = "";
		string str_tmp = "";
	begin
		str_tmp = $sformatf("%1d", frame);
		ppm_filename = {"../data/frame", str_tmp, ".ppm"};
		ppm_fd = $fopen (ppm_filename, "wb");
		str_tmp = $sformatf("%1d %1d", H_SYNC_ACT, V_SYNC_ACT);
		$fwrite(ppm_fd, "P6%c%s%c255%c", 8'h0A, str_tmp, 8'h0A, 8'h0A); 
	end
	endtask

	task report_colour_changes(int frame, int pixel_row, int pixel_col, 
				logic [7:0] new_red, logic [7:0] new_green, logic [7:0] new_blue);
		static logic [7:0] old_red = 0;
		static logic [7:0] old_green = 0;
		static logic [7:0] old_blue = 0;
	begin
		if ((old_red != new_red) || (old_green != new_green) || (old_blue != new_blue)) begin
			$display("%t: At pos (%2d,%4d,%4d) R/G/B changed to %2h/%2h/%2h)", 
				$realtime, frame, pixel_row, pixel_col,
				new_red, new_green, new_blue);
		end
		old_red = new_red;
		old_green = new_green;
		old_blue = new_blue;
	end
	endtask

	task update_vga();
		logic [7:0] red, green, blue;
		int frame;
		int pixel_col;
		int pixel_row;
		int ppm_fd;
	begin
		frame = 0;
		pixel_row = 0;
		pixel_col = 0;
		open_frame_file(ppm_fd, frame);		
		forever begin
			mon2vga.get(vga_event);

			red = vga_event[23:16];
			green = vga_event[15:8];
			blue = vga_event[7:0];

			// report_colour_changes(frame, pixel_row, pixel_col, red, green, blue);

			// write in the frame file in PPM format
			$fwrite(ppm_fd, "%c%c%c", red, green, blue);

			pixel_col = (pixel_col + 1) % H_SYNC_ACT;
			if (pixel_col == 0) begin
				pixel_row = (pixel_row + 1) % (V_SYNC_ACT);
				if (pixel_row == 0) begin
					frame = frame + 1;
					$fclose(ppm_fd);
					open_frame_file(ppm_fd, frame);	
				end
			end
		end
	end
	endtask

	task main();
	fork
		update_lcd();
		update_vga();
	join_none
	endtask
  
endclass
