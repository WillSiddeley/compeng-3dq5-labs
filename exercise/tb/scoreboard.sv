/*
Copyright by Nicola Nicolici
Department of Electrical and Computer Engineering
McMaster University
Ontario, Canada
*/

class scoreboard;
   
	mailbox mon2scb;
	logic [8:0] lcd_event;
	int lcd_line;
	int lcd_col;
	logic [7:0] lcd_code;
	string lcd_top_line    = "                ";
	string lcd_bottom_line = "                ";
	  
	function new(mailbox mon2scb);
		this.mon2scb = mon2scb;
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

	task main();
		forever begin
			mon2scb.get(lcd_event);
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
  
endclass
