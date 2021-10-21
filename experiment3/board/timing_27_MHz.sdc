# Constrain clock port CLOCK_27_I with a 37.037 ns requirement

# Constrain the register-to-register paths
create_clock -name clk_27 -period 37.037 [get_ports {CLOCK_27_I}]

# Use phase-locked loops (PLLs) instance parameters 
# for the generated clocks on the outputs of the PLL

derive_pll_clocks
derive_clock_uncertainty

# Constrain the input-to-register paths

set_input_delay -clock clk_27 -max 3 [all_inputs] -add_delay
set_input_delay -clock clk_27 -min 2 [all_inputs] -add_delay

set_multicycle_path -setup -from [all_inputs] 2 
set_multicycle_path -hold -from [all_inputs] 1

# Constrain the output-to-register paths

set_output_delay -clock clk_27 -max 3 [all_outputs] -add_delay
set_output_delay -clock clk_27 -min 2 [all_outputs] -add_delay

set_multicycle_path -setup -to [all_outputs] 2 
set_multicycle_path -hold -to [all_outputs] 1

# Specify the false paths on I/Os

set_false_path -from [all_inputs] -to clk_27
set_false_path -from clk_27 -to [all_outputs]

# Specify the false paths between 50 MHz and 27 MHz clocks

set_false_path -from clk_50 -to clk_27
set_false_path -from clk_27 -to clk_50


