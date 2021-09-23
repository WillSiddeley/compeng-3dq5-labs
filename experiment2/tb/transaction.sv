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
	localparam PS2_KEY_PRESS = 2;

	int input_type;	
	int input_index;
	int event_time;	
	int event_duration;

	static int ps2_key_to_code_map[string];
	static string ps2_code_to_key_map[int];

	static function void initialize_ps2_key_to_code_map();
		ps2_key_to_code_map["1"] = 8'h16; ps2_key_to_code_map["Q"] = 8'h15; ps2_key_to_code_map["2"] = 8'h1E;
		ps2_key_to_code_map["W"] = 8'h1D; ps2_key_to_code_map["3"] = 8'h26; ps2_key_to_code_map["E"] = 8'h24;
		ps2_key_to_code_map["4"] = 8'h25; ps2_key_to_code_map["R"] = 8'h2D; ps2_key_to_code_map["5"] = 8'h2E; 
		ps2_key_to_code_map["T"] = 8'h2C; ps2_key_to_code_map["6"] = 8'h36; ps2_key_to_code_map["Y"] = 8'h35;
		ps2_key_to_code_map["7"] = 8'h3D; ps2_key_to_code_map["U"] = 8'h3C; ps2_key_to_code_map["8"] = 8'h3E;
		ps2_key_to_code_map["I"] = 8'h43; ps2_key_to_code_map["9"] = 8'h46; ps2_key_to_code_map["O"] = 8'h44;
		ps2_key_to_code_map["0"] = 8'h45; ps2_key_to_code_map["P"] = 8'h4D; ps2_key_to_code_map["A"] = 8'h1C;
		ps2_key_to_code_map["C"] = 8'h21; ps2_key_to_code_map["S"] = 8'h1B; ps2_key_to_code_map["V"] = 8'h2A;
		ps2_key_to_code_map["D"] = 8'h23; ps2_key_to_code_map["B"] = 8'h32; ps2_key_to_code_map["F"] = 8'h2B;
		ps2_key_to_code_map["N"] = 8'h31; ps2_key_to_code_map["G"] = 8'h34; ps2_key_to_code_map["M"] = 8'h3A; 
		ps2_key_to_code_map["H"] = 8'h33; ps2_key_to_code_map["J"] = 8'h3B; ps2_key_to_code_map["K"] = 8'h42;
		ps2_key_to_code_map["L"] = 8'h4B; ps2_key_to_code_map["Z"] = 8'h1A; ps2_key_to_code_map["X"] = 8'h22;
		ps2_key_to_code_map["_"] = 8'h29; ps2_key_to_code_map["("] = 8'h12; ps2_key_to_code_map[")"] = 8'h59;
		ps2_key_to_code_map["!"] = 8'h5A;
	endfunction;

	static function void initialize_ps2_code_to_key_map();
		ps2_code_to_key_map[8'h16] = "1"; ps2_code_to_key_map[8'h15] = "Q"; ps2_code_to_key_map[8'h1E] = "2";
		ps2_code_to_key_map[8'h1D] = "W"; ps2_code_to_key_map[8'h26] = "3"; ps2_code_to_key_map[8'h24] = "E";
		ps2_code_to_key_map[8'h25] = "4"; ps2_code_to_key_map[8'h2D] = "R"; ps2_code_to_key_map[8'h2E] = "5"; 
		ps2_code_to_key_map[8'h2C] = "T"; ps2_code_to_key_map[8'h36] = "6"; ps2_code_to_key_map[8'h35] = "Y";
		ps2_code_to_key_map[8'h3D] = "7"; ps2_code_to_key_map[8'h3C] = "U"; ps2_code_to_key_map[8'h3E] = "8";
		ps2_code_to_key_map[8'h43] = "I"; ps2_code_to_key_map[8'h46] = "9"; ps2_code_to_key_map[8'h44] = "O";
		ps2_code_to_key_map[8'h45] = "0"; ps2_code_to_key_map[8'h4D] = "P"; ps2_code_to_key_map[8'h1C] = "A";
		ps2_code_to_key_map[8'h21] = "C"; ps2_code_to_key_map[8'h1B] = "S"; ps2_code_to_key_map[8'h2A] = "V";
		ps2_code_to_key_map[8'h23] = "D"; ps2_code_to_key_map[8'h32] = "B"; ps2_code_to_key_map[8'h2B] = "F";
		ps2_code_to_key_map[8'h31] = "N"; ps2_code_to_key_map[8'h34] = "G"; ps2_code_to_key_map[8'h3A] = "M";
		ps2_code_to_key_map[8'h33] = "H"; ps2_code_to_key_map[8'h3B] = "J"; ps2_code_to_key_map[8'h42] = "K";
		ps2_code_to_key_map[8'h4B] = "L"; ps2_code_to_key_map[8'h1A] = "Z"; ps2_code_to_key_map[8'h22] = "X";
		ps2_code_to_key_map[8'h29] = "space"; ps2_code_to_key_map[8'h12] = "left shift"; ps2_code_to_key_map[8'h59] = "right shift";
		ps2_code_to_key_map[8'h5A] = "enter";
	endfunction;

	function new(int input_type, int input_index, int event_time, int event_duration);
		super.new();
		this.input_type = input_type;
		this.input_index = input_index;
		this.event_time = event_time;	
		this.event_duration = event_duration;	
	endfunction

	static function board_event new_instance(string input_name, int input_index, int event_time, int event_duration);
		if (input_name == "SW") new_instance = new(SW_TOGGLE, input_index, event_time, event_duration);
		if (input_name == "PB") new_instance = new(PB_PRESS, input_index, event_time, event_duration);
		if (input_name == "PS") new_instance = new(PS2_KEY_PRESS, input_index, event_time, event_duration);
	endfunction

	function string convert_input_type_to_name(int input_type);
		if (input_type == SW_TOGGLE) return "Switch ";
		if (input_type == PB_PRESS) return "Push-button ";
		if (input_type == PS2_KEY_PRESS) return "PS2 key ";
		return "";
	endfunction

	function string convert_input_index_to_string(int input_type, input_index);
		string str = "";
		if ((input_type == SW_TOGGLE) || (input_type == PB_PRESS)) str.itoa(input_index);
		if (input_type == PS2_KEY_PRESS) str = ps2_code_to_key_map[input_index];
		return str;
	endfunction

	function string convert_input_type_to_end_of_message(int input_type, duration);
		if (input_type == SW_TOGGLE) return "will be toggled";
		if (input_type == PB_PRESS) return $sformatf("will be pressed for %1d us", event_duration);
		if (input_type == PS2_KEY_PRESS) return $sformatf("will be pressed for %1d us", event_duration);
		return "";
	endfunction

	function string event_message();
		return $sformatf("*** At time %1d.00us: %s%s %s ***", 
				event_time, 
				convert_input_type_to_name(input_type), 
				convert_input_index_to_string(input_type, input_index), 
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

	function int is_ps2_key_press();
		if (input_type == PS2_KEY_PRESS) return 1;
		return 0;
	endfunction

endclass


