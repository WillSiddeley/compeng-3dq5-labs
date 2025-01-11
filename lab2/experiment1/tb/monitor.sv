/*
Copyright by Nicola Nicolici
Department of Electrical and Computer Engineering
McMaster University
Ontario, Canada
*/

class monitor;
  
	virtual board_intf vif;
	mailbox mon2scb;

	function new(virtual board_intf vif, mailbox mon2scb);
		this.vif = vif;
		this.mon2scb = mon2scb;
	endfunction
  
	function logic [4:0] convert_seven_segment_to_hex(input logic [7:0] seven_segment_value);
		logic [4:0] valid_hex_value;
		case(seven_segment_value)
			7'b1000000 : valid_hex_value = 5'h10;
			7'b1111001 : valid_hex_value = 5'h11;
			7'b0100100 : valid_hex_value = 5'h12;
			7'b0110000 : valid_hex_value = 5'h13;
			7'b0011001 : valid_hex_value = 5'h14;
			7'b0010010 : valid_hex_value = 5'h15;
			7'b0000010 : valid_hex_value = 5'h16;
			7'b1111000 : valid_hex_value = 5'h17;
			7'b0000000 : valid_hex_value = 5'h18;
			7'b0011000 : valid_hex_value = 5'h19;
			7'b0001000 : valid_hex_value = 5'h1a;
			7'b0000011 : valid_hex_value = 5'h1b;
			7'b1000110 : valid_hex_value = 5'h1c;
			7'b0100001 : valid_hex_value = 5'h1d;
			7'b0000110 : valid_hex_value = 5'h1e;
			7'b0001110 : valid_hex_value = 5'h1f;
			default: valid_hex_value = 5'h00;
		endcase
		return valid_hex_value;
	endfunction

	task monitor_green_leds();
		forever begin
			@(vif.led_green);
			$display("%t: led_green = %b", 
				$realtime, 
				vif.led_green);
		end
	endtask

	task monitor_seven_segment_display(int i);
		logic [4:0] valid_hex_value;
	begin
		forever begin
			@(vif.seven_seg_n[i]);
			valid_hex_value = convert_seven_segment_to_hex(vif.seven_seg_n[i]);
			if (valid_hex_value[4] == 1'b1)
				$display("%t: seven segment %1d = %b (displayed value = %h)", 
					$realtime, i, vif.seven_seg_n[i], valid_hex_value[3:0]);
			else
				$display("%t: seven segment %1d = %b (not lightened)", 
					$realtime, i, vif.seven_seg_n[i]);
		end
	end
	endtask

	task monitor_seven_segment_displays();
		fork
			monitor_seven_segment_display(0);
			monitor_seven_segment_display(1);
			monitor_seven_segment_display(2);
			monitor_seven_segment_display(3);
			monitor_seven_segment_display(4);
			monitor_seven_segment_display(5);
			monitor_seven_segment_display(6);
			monitor_seven_segment_display(7);
		join_any
	endtask

	task monitor_switches();
		forever begin
			@(vif.switch);
			$display("%t: switches = %b", 
				$realtime, 
				vif.switch);
		end
	endtask

	task monitor_push_buttons();
		forever begin
			@(vif.push_button_n);
			$display("%t: push buttons = %b", 
				$realtime, 
				vif.push_button_n);
		end
	endtask

	task main();
	begin
		$timeformat(-6, 2, "us", 10);
		fork 
			monitor_green_leds();
			monitor_seven_segment_displays();
			monitor_switches();
			monitor_push_buttons();
		join_any
	end
	endtask
  
endclass
