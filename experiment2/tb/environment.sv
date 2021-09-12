/*
Copyright by Nicola Nicolici
Department of Electrical and Computer Engineering
McMaster University
Ontario, Canada
*/

`include "transaction.sv"
`include "generator.sv"
`include "driver.sv"
`include "monitor.sv"
`include "scoreboard.sv"

class environment;
  
	generator	gen;
	driver		drv;
	monitor		mon;
	scoreboard	scb;
  
	mailbox gen2drv;
	mailbox mon2scb;
  
	string filename;
	virtual board_intf virtual_intf;

	function new(string filename, virtual board_intf virtual_intf);

		this.virtual_intf = virtual_intf;
		this.filename = filename;

		gen2drv = new();
		mon2scb  = new();

		gen  = new(filename, gen2drv);
		drv = new(virtual_intf, gen2drv);
		mon  = new(virtual_intf, mon2scb);
		scb  = new(mon2scb);
		
	endfunction
  
	task pre_test();
		drv.reset();
	endtask
  
	task run_test();
		fork 
			gen.main();
			drv.main();
			mon.main();
			scb.main();
		join_any
	endtask

	task post_test();
		wait(gen.ended.triggered);
	endtask
  
	task run();
		pre_test();
		run_test();
		post_test();
		$stop;
	endtask
  
endclass

