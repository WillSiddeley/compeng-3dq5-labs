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

# the LCD signals make little sense 
# without studying the data-sheet
add wave -hex UUT/LED_GREEN_O
add wave -bin UUT/LCD_POWER_O
add wave -bin UUT/LCD_BACK_LIGHT_O
add wave -bin UUT/LCD_READ_WRITE_O
add wave -bin UUT/LCD_EN_O
add wave -bin UUT/LCD_COMMAND_DATA_O
add wave -hex UUT/LCD_DATA_IO

add wave -divider -height 20 {internal signals}
add wave -bin UUT/state
add wave -hex UUT/LCD_data_index
add wave -hex UUT/LCD_data_sequence
add wave -divider -height 20 {}
add wave -bin UUT/LCD_start
add wave -hex UUT/LCD_instruction
add wave -bin UUT/LCD_done

