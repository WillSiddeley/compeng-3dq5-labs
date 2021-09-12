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
  
	task monitor_green_leds();
		forever begin
			@(vif.led_green);
			$display("%t: led_green = %b", 
				$realtime, 
				vif.led_green);
		end
	endtask

	task monitor_red_leds();
		forever begin
			@(vif.led_red);
			$display("%t: led_red = %b", 
				$realtime, 
				vif.led_red);
		end
	endtask

	task monitor_switches();
		forever begin
			@(vif.switch);
			$display("%t: switches = %b", 
				$realtime, 
				vif.switch);
		end
	endtask

	task main();
	begin
		$timeformat(-6, 2, "us", 10);
		fork 
			monitor_green_leds();
			monitor_red_leds();
			monitor_switches();
		join_any
	end
	endtask
  
endclass
