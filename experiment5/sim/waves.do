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
# add wave -hex UUT/SEVEN_SEGMENT_N_O
# add wave -hex UUT/LED_GREEN_O
# add wave -hex UUT/LED_RED_O
add wave -bin UUT/PS2_DATA_I
add wave -bin UUT/PS2_CLOCK_I

# the LCD signals make little sense 
# without studying the data-sheet
# add wave -hex UUT/LED_GREEN_O
# add wave -bin UUT/LCD_POWER_O
# add wave -bin UUT/LCD_BACK_LIGHT_O
# add wave -bin UUT/LCD_READ_WRITE_O
# add wave -bin UUT/LCD_EN_O
# add wave -bin UUT/LCD_COMMAND_DATA_O
# add wave -hex UUT/LCD_DATA_IO

add wave -divider -height 20 {internal signals}
add wave -hex UUT/data_counter
add wave -hex UUT/data_reg
add wave -hex UUT/PS2_code
add wave -hex UUT/PS2_code_ready
add wave -hex UUT/PS2_make_code

add wave -divider -height 20 {}
add wave -hex UUT/LCD_init_index
add wave -hex UUT/LCD_init_sequence
add wave -hex UUT/LCD_instruction
add wave -hex UUT/LCD_code
add wave -hex UUT/LCD_position
add wave -hex UUT/LCD_line
add wave -hex UUT/LCD_start
add wave -hex UUT/LCD_done

