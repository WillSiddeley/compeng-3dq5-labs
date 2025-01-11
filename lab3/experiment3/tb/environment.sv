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
	mailbox mon2lcd;
	mailbox mon2vga;
  
	string filename;
	virtual board_intf virtual_intf;

	function new(string filename, virtual board_intf virtual_intf);

		this.virtual_intf = virtual_intf;
		this.filename = filename;

		gen2drv = new();
		mon2lcd  = new();
		mon2vga  = new();

		gen  = new(filename, gen2drv);
		drv = new(virtual_intf, gen2drv);
		mon  = new(virtual_intf, mon2lcd, mon2vga);
		scb  = new(mon2lcd, mon2vga);
		
	endfunction
  
	task pre_test();
		mon.reset();
		gen.reset();
		drv.reset();
		scb.reset();
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

