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
add wave -hex UUT/LED_RED_O
add wave -hex UUT/LED_GREEN_O
add wave -hex UUT/SEVEN_SEGMENT_N_O
add wave -bin UUT/PS2_DATA_I
add wave -bin UUT/PS2_CLOCK_I

add wave -divider -height 20 {internal signals}
add wave -hex UUT/PS2_code_ready
add wave -hex UUT/PS2_make_code
add wave -hex UUT/PS2_code
add wave -hex UUT/seven_segment_shift_reg
add wave -hex UUT/PS2_break_code


