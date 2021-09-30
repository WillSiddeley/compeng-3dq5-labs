/*
Copyright by Nicola Nicolici
Department of Electrical and Computer Engineering
McMaster University
Ontario, Canada
*/

`include "interface.sv"
`include "environment.sv"

module board_test (board_intf i_intf);

	environment env;

	initial begin
		env = new("../data/board_events.txt", i_intf);
		env.run();
	end

endmodule


