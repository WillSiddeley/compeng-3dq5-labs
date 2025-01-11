# activate waveform simulation
view wave

# format signal names in waveform
configure wave -signalnamewidth 1
configure wave -timeline 0
configure wave -timelineunits us

# add signals to waveform
add wave -divider -height 20 {internal signals}
add wave -bin UUT/CLOCK_50_I
add wave -bin UUT/resetn
add wave -bin UUT/state
add wave -hex -unsigned UUT/address
add wave -divider -height 10 {}
add wave -bin {UUT/write_enable[0]}
add wave -decimal {UUT/read_data[0]}
add wave -decimal {UUT/write_data[0]}
add wave -divider -height 10 {}
add wave -bin {UUT/write_enable[1]}
add wave -decimal {UUT/read_data[1]}
add wave -decimal {UUT/write_data[1]}

