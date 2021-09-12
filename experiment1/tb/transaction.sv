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

	int input_type;	
	int input_index;

	function new(int input_type, int input_index);
		super.new();
		this.input_type = input_type;
		this.input_index = input_index;
	endfunction

	static function board_event new_instance(string input_name, int input_index);
		if (input_name == "SW") new_instance = new(SW_TOGGLE, input_index);
	endfunction

	function string convert_input_type_to_name(int input_type);
		if (input_type == SW_TOGGLE) return "SW";
		return "";
	endfunction

	function string convert_input_type_to_end_of_message(int input_type);
		if (input_type == SW_TOGGLE) return "will be toggled";
		return "";
	endfunction
			
	function string event_message();
		return $sformatf("*** \t%s%1d %s\t***", 
				convert_input_type_to_name(input_type), 
				input_index, 
				convert_input_type_to_end_of_message(input_type));
	endfunction

	function int get_index();
		return input_index;
	endfunction

	function int is_switch_toggle();
		if (input_type == SW_TOGGLE) return 1;
		return 0;
	endfunction

endclass


