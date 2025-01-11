# activate waveform simulation
view wave

# format signal names in waveform
configure wave -signalnamewidth 1
configure wave -timeline 0
configure wave -timelineunits us

# add signals to waveform
add wave -divider -height 20 {board inputs/outputs}
add wave -hex UUT/SWITCH_I
add wave -hex UUT/LED_RED_O
add wave -hex UUT/LED_GREEN_O
add wave -hex UUT/NOR4

