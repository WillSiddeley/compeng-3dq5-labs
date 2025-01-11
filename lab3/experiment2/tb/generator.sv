/*
Copyright by Nicola Nicolici
Department of Electrical and Computer Engineering
McMaster University
Ontario, Canada
*/

class generator;
  
	localparam DIRECT_TEST = 0;		// enable direct test (based on events in event file)
	localparam RANDOM_TEST = 1;		// enable random test (not supported yet)
	localparam LAST_DELAY = 1000000;	// delay in terms ns after last event

	string filename;
	int gen_type;
	mailbox gen2drv;
	event ended;

	function new(string filename, mailbox gen2drv);
		this.filename = filename;
		if (filename == "") this.gen_type = RANDOM_TEST;
		else this.gen_type = DIRECT_TEST;
		this.gen2drv = gen2drv;
 	endfunction
  
	task reset();
	begin
		board_event::initialize_ps2_code_to_key_map();
		board_event::initialize_ps2_key_to_code_map();
	end
	endtask

	task automatic parse_board_events(ref board_event event_queue[$]);
		string token;
		int file, rc;
		int line, col;
		string input_name;
		int input_index;
		int event_time;	
		int event_duration;
	begin
	
		file = $fopen(filename, "r");
		line = 1;
		rc = $fscanf(file, "%s", token);
		while (!$feof(file)) begin
			input_name = token.substr(0, 1);
			if ((input_name != "SW") && (input_name != "PB") && (input_name != "PS")) begin
				$display("Wrong board input %s in %s on line %2d ... exiting", token.substr(0, 1), filename, line);
				$stop;
			end
	
			if ((input_name == "SW") || (input_name == "PB")) begin
				col = 2;
				while ((token.substr(col, col) >= "0") && (token.substr(col, col) <= "9")) 
					col++;
				input_index = -1;
				if (col > 2)
					input_index = token.substr(2, col-1).atoi();
				if (((input_name == "SW") && ((input_index < 0) || (input_index > 17))) || 
				    ((input_name == "PB") && ((input_index < 0) || (input_index > 3)))) begin
					$display("Wrong board input %s in %s on line %2d ... exiting", token.substr(0, col-1), filename, line);
					$stop;
				end
			end else begin
				col = 2;
				while ((token.substr(col, col) >= "A") && (token.substr(col, col) <= "Z")) 
					col++;
				while ((token.substr(col, col) >= "0") && (token.substr(col, col) <= "9")) 
					col++;
				while ((token.substr(col, col) == "_") || (token.substr(col, col) == "!") ||
					(token.substr(col, col) == "(") || (token.substr(col, col) == ")")) 
					col++;
				if (col != 3) begin
					$write("In simulation we support only alphanumerical PS2 keys ('A' to 'Z' and '0' to '9') and");
					$display(" '_' for space, '(' for left shift, ')' for right shift and '!' for ENTER");
					$display("Wrong board input %s in %s on line %2d ... exiting", token.substr(0, col-1), filename, line);
					$stop;
				end

				input_index = board_event::ps2_key_to_code_map[token.substr(col-1, col-1)];
			end

			event_time = 0;
			rc = $fscanf(file, "%s", token);
			event_time = token.atoi();
			if (event_time <= 0) begin
				$display("Wrong event time %s in %s on line %2d ... exiting", token, filename, line);
				$stop;
			end
	
			if (input_name == "SW") begin
				event_duration = 0;	
			end else begin
				rc = $fscanf(file, "%s", token);
				event_duration = token.atoi();
				if (event_duration <= 0) begin
					$display("Wrong event duration %s in board_events.txt on line %2d ... exiting", token, line);
					$stop;
				end
			end
			event_queue.push_back(board_event::new_instance(
					.input_name(input_name), 
					.input_index(input_index), 
					.event_time(event_time),
					.event_duration(event_duration)));
			rc = $fscanf(file, "%s", token);
			line++;
		end 
		
		event_queue.sort(e) with (e.event_time);
	
		$display("Board events successfully parsed\n");
		foreach(event_queue[e]) begin
			$display("%s", event_queue[e].event_message());
		end
		$display("\nSimulation is ready to start\n");

		$fclose(file);
	end
	endtask

	task main();
		board_event trans_queue[$];
		board_event my_trans;
	begin
		if (gen_type == DIRECT_TEST)
			parse_board_events(trans_queue);
		while (trans_queue.size() > 0) begin
			my_trans = trans_queue.pop_front();
			#((my_trans.get_time() * 1us) - $time);
			gen2drv.put(my_trans);
		end
		#(LAST_DELAY);
 		// -> ended;
	end
	endtask
  
endclass
