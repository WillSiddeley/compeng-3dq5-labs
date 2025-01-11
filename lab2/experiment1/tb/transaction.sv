/*
Copyright by Nicola Nicolici
Department of Electrical and Computer Engineering
McMaster University
Ontario, Canada
*/

class transaction;
  
	static int next_trans_index;
	const int trans_index;

	function new;
		trans_index = next_trans_index++;
		// $display("New transaction %d", trans_index);
	endfunction

endclass

class board_event extends transaction;

	localparam SW_TOGGLE = 0;
	localparam PB_PRESS = 1;

	int input_type;	
	int input_index;
	int event_time;	
	int event_duration;	

	function new(int input_type, int input_index, int event_time, int event_duration);
		super.new();
		this.input_type = input_type;
		this.input_index = input_index;
		this.event_time = event_time;	
		this.event_duration = event_duration;	
	endfunction

	static function board_event new_instance(string input_name, int input_index, int event_time, int event_duration);
		if (input_name == "SW") new_instance = new(SW_TOGGLE, input_index, event_time, event_duration);
		else if (input_name == "PB") new_instance = new(PB_PRESS, input_index, event_time, event_duration);
	endfunction

	function string convert_input_type_to_name(int input_type);
		if (input_type == SW_TOGGLE) return "SW";
		if (input_type == PB_PRESS) return "PB";
		return "";
	endfunction

	function string convert_input_type_to_end_of_message(int input_type, duration);
		if (input_type == SW_TOGGLE) return "will be toggled";
		if (input_type == PB_PRESS) return $sformatf("will be pressed for %1d us", event_duration);
		return "";
	endfunction
			
	function string event_message();
		return $sformatf("*** @ %1d.00us\t%s%1d %s\t***", 
				event_time, 
				convert_input_type_to_name(input_type), 
				input_index, 
				convert_input_type_to_end_of_message(input_type, event_duration));
	endfunction

	function int get_time();
		return event_time;
	endfunction

	function int get_duration();
		return event_duration;
	endfunction

	function int get_index();
		return input_index;
	endfunction

	function int is_switch_toggle();
		if (input_type == SW_TOGGLE) return 1;
		return 0;
	endfunction

	function int is_pb_press();
		if (input_type == PB_PRESS) return 1;
		return 0;
	endfunction

endclass


