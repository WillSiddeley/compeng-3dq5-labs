/*
Copyright by Nicola Nicolici
Department of Electrical and Computer Engineering
McMaster University
Ontario, Canada
*/

class driver;
  
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
		repeat (2) @(negedge vif.clock_50);
		$display("\n*** Asserting the asynchronous reset ***");
		vif.switch[17] = 1'b1;
		repeat (3) @(negedge vif.clock_50);
		vif.switch[17] = 1'b0;		
		$display("*** Deasserting the asynchronous reset ***\n");
	end
	endtask

	task main();
		int next_index, next_release;
		board_event my_trans;
	begin
		forever begin
			gen2drv.get(my_trans);
			next_index = my_trans.get_index();
			if (my_trans.is_switch_toggle()) begin
				vif.switch[next_index] = ~vif.switch[next_index];
			end else if (my_trans.is_pb_press()) fork
				begin
					if (vif.push_button_n[next_index] == 1'b1) vif.push_button_n[next_index] = 1'b0;
					else $display("%t: Push button %1d is already pressed - it cannot be pressed again - event ignored", 
						$realtime, next_index);
				end
				begin
					next_release = next_index;
					#(my_trans.get_duration() * 1us);
					if (vif.push_button_n[next_release] == 1'b0) vif.push_button_n[next_release] = 1'b1;
					else $display("%t: Push button %1d is already released - it cannot be released again - event ignored",
						$realtime, next_release);
				end
			join_none
		end
	end
	endtask
  
endclass

