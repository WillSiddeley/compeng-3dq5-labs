/*
Copyright by Nicola Nicolici
Department of Electrical and Computer Engineering
McMaster University
Ontario, Canada
*/

class driver;

	// we assume that one PS2 clock is 4 pulses of the 50MHz clock
	localparam ps2_clock_period = 80;
 
	virtual board_intf vif;
	mailbox gen2drv;

	function new(virtual board_intf vif, mailbox gen2drv);
		this.vif = vif;
		this.gen2drv = gen2drv;
	endfunction

	task reset();
	begin
		vif.push_button_n[3:0] = 4'hf;
		vif.switch[17:0] = 18'd0;
		vif.ps2_data = 1'b1;
		vif.ps2_clock = 1'b1;
		repeat (2) @(negedge vif.clock_50);
		$display("\n*** Asserting the asynchronous reset ***");
		vif.switch[17] = 1'b1;
		repeat (3) @(negedge vif.clock_50);
		vif.switch[17] = 1'b0;		
		$display("*** Deasserting the asynchronous reset ***\n");
	end
	endtask

	task generate_ps2_start_bit();
	begin
		vif.ps2_data = 1'b0;
	end
	endtask

	task generate_ps2_data_bit(int ps2_index, int i);
		logic [7:0] ps2_code;
		logic parity;
	begin
		ps2_code = ps2_index;
		// wait for (i+1) ps2 bits (start + i data bits)
		#((i+1)*ps2_clock_period);
		vif.ps2_data = ps2_code[i];
	end
	endtask

	task generate_ps2_parity_bit(int ps2_index);
		logic [7:0] ps2_code;
		logic parity;
	begin
		ps2_code = ps2_index;
		parity = ~^ps2_code[7:0];
		// wait for 9 ps2 bits (start + 8 data)
		#(9*ps2_clock_period);
		vif.ps2_data = parity;
	end
	endtask

	task generate_ps2_stop_bit();
	begin
		// wait for 10 ps2 bits (start + 8 data + parity)
		#(10*ps2_clock_period);
		vif.ps2_data = 1'b1;
	end
	endtask

	task generate_ps2_clock();
		integer i;
	begin
		vif.ps2_clock = 1'b0;
		for (i=0; i<10; i=i+1) begin
			#(ps2_clock_period/2) vif.ps2_clock = 1'b1;
			#(ps2_clock_period/2) vif.ps2_clock = 1'b0;
		end
		#(ps2_clock_period/2) vif.ps2_clock = 1'b1;
	end
	endtask

	task generate_make_code(int ps2_index);
		integer i;
	fork
		generate_ps2_start_bit();
		generate_ps2_data_bit(ps2_index, 0);
		generate_ps2_data_bit(ps2_index, 1);
		generate_ps2_data_bit(ps2_index, 2);
		generate_ps2_data_bit(ps2_index, 3);
		generate_ps2_data_bit(ps2_index, 4);
		generate_ps2_data_bit(ps2_index, 5);
		generate_ps2_data_bit(ps2_index, 6);
		generate_ps2_data_bit(ps2_index, 7);
		generate_ps2_parity_bit(ps2_index);
		generate_ps2_stop_bit();
		generate_ps2_clock();
	join_none
	endtask

	task generate_break_code(int ps2_index,int press_duration);
	begin
		#(press_duration * 1us);
		generate_make_code(8'hF0);
		#(13*ps2_clock_period); // 11 pulses for F0 + 2 pulses delay
		generate_make_code(ps2_index);
	end
	endtask

	task main();
		board_event my_trans;
		semaphore  semPS2 = new(1);
		int input_index, pb_release_index;
		int ps2_index, press_duration;
		int queue_PS2_keys[$];
		int time_difference;
	begin
		forever begin
			gen2drv.get(my_trans);
			input_index = my_trans.get_index();
			if (my_trans.is_switch_toggle()) begin
				vif.switch[input_index] = ~vif.switch[input_index];
			end else if (my_trans.is_pb_press()) begin 
				fork
					begin
						if (vif.push_button_n[input_index] == 1'b1) vif.push_button_n[input_index] = 1'b0;
						else $display("%t: Push button %1d is already pressed - it cannot be pressed again - event ignored", 
							$realtime, input_index);
					end
					begin
						pb_release_index = input_index;
						#(my_trans.get_duration() * 1us);
						if (vif.push_button_n[pb_release_index] == 1'b0) vif.push_button_n[pb_release_index] = 1'b1;
						else $display("%t: Push button %1d is already released - it cannot be released again - event ignored",
							$realtime, pb_release_index);
					end
				join_none
			end else if (my_trans.is_ps2_key_press()) fork: implement_ps2_transaction
				begin
					ps2_index = input_index;
					press_duration = my_trans.get_duration();
					queue_PS2_keys.push_back($time);
					queue_PS2_keys.push_back(ps2_index);
					queue_PS2_keys.push_back(press_duration);
					semPS2.get(1);
					time_difference = $time - queue_PS2_keys.pop_front();
					ps2_index = queue_PS2_keys.pop_front();
					press_duration = queue_PS2_keys.pop_front();
					$display("%t: Starting to serialize PS/2 key %s (code 8'h%2h)", 
						$realtime, board_event::ps2_code_to_key_map[ps2_index], ps2_index);
					if (time_difference != 0)
						$display(" Event delayed by %1d us, due to overlap with previous PS/2 transaction", 
							time_difference/1000);
					fork
						generate_make_code(ps2_index);
						generate_break_code(ps2_index, press_duration);
						begin
							// press duration covers also the serialization of make code
							#(press_duration * 1us);
							// 2 * (11 ps2 clock pulses for each byte of break code + 2 pulse delay)
							#(2*13*ps2_clock_period); 
							semPS2.put(1);
						end
					join_none
				end
			join_none
		end
	end
	endtask
  
endclass

