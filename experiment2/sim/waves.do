# activate waveform simulation

view wave

# format signal names in waveform

configure wave -signalnamewidth 1
configure wave -timeline 0
configure wave -timelineunits us

# add signals to waveform

add wave -divider -height 20 {}
add wave -bin UUT/CLOCK_50_I
add wave -bin UUT/resetn
add wave -hex {UUT/PB_pushed[0]}
add wave -bin UUT/state

add wave -divider -height 10 {}
add wave -uns UUT/pixel_X_pos
add wave -uns UUT/pixel_Y_pos
add wave -hex UUT/VGA_red
add wave -hex UUT/VGA_green
add wave -hex UUT/VGA_blue

# add wave -divider -height 10 {}
# add wave -bin UUT/VGA_CLOCK_O
# add wave -hex UUT/VGA_RED_O
# add wave -hex UUT/VGA_GREEN_O
# add wave -hex UUT/VGA_BLUE_O

add wave -divider -height 10 {}
add wave -uns UUT/SRAM_address
# add wave -hex UUT/SRAM_write_data
add wave -bin UUT/SRAM_we_n
add wave -hex UUT/SRAM_read_data


