# activate waveform simulation
view wave

# format signal names in waveform
configure wave -signalnamewidth 1
configure wave -timeline 0
configure wave -timelineunits us

# add signals to waveform
add wave -divider -height 20 {board inputs/outputs}
add wave -bin UUT/CLOCK_50_I
add wave -hex UUT/SWITCH_I
add wave -bin UUT/VGA_CLOCK_O
add wave -bin UUT/VGA_HSYNC_O
add wave -bin UUT/VGA_VSYNC_O
add wave -hex UUT/VGA_RED_O
add wave -hex UUT/VGA_GREEN_O
add wave -hex UUT/VGA_BLUE_O

add wave -divider -height 20 {internal signals}
add wave -uns UUT/pixel_X_pos
add wave -uns UUT/pixel_Y_pos
add wave -uns UUT/object_on
add wave -hex UUT/VGA_red
add wave -hex UUT/VGA_green
add wave -hex UUT/VGA_blue

