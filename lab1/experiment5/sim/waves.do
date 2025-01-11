# activate waveform simulation
view wave

# format signal names in waveform
configure wave -signalnamewidth 1
configure wave -timeline 0
configure wave -timelineunits us

# add signals to waveform
add wave -divider -height 20 {board inputs/outputs}
add wave -bin UUT/CLOCK_50_I
add wave -hex UUT/PUSH_BUTTON_N_I
add wave -hex UUT/SWITCH_I
add wave -hex UUT/SEVEN_SEGMENT_N_O
add wave -hex UUT/LED_GREEN_O

add wave -divider -height 20 {internal signals}
add wave -hex UUT/debounce_shift_reg
add wave -hex UUT/push_button_status_buf
add wave -bin UUT/stop_count
add wave -bin UUT/down_count
add wave -hex {UUT/counter[7:4]}
add wave -hex {UUT/counter[3:0]}

