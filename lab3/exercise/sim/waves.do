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

add wave -divider -height 20 {VGA signals}
add wave -uns UUT/pixel_X_pos
add wave -uns UUT/pixel_Y_pos
add wave -oct UUT/character_address
add wave -bin UUT/rom_mux_output
add wave -hex UUT/VGA_red
add wave -hex UUT/VGA_green
add wave -hex UUT/VGA_blue

add wave -divider -height 20 {PS2 signals}
add wave -hex UUT/PS2_code
add wave -hex UUT/PS2_reg
add wave -bin UUT/PS2_code_ready
add wave -bin UUT/PS2_code_ready_buf
add wave -bin UUT/PS2_make_code

add wave -oct UUT/char_to_add
add wave -hex UUT/data_reg
add wave -oct UUT/max_letter

add wave -divider -height 20 {Letter Counters}
add wave -hex UUT/num_A
add wave -hex UUT/num_B
add wave -hex UUT/num_C
add wave -hex UUT/num_D
add wave -hex UUT/num_E
add wave -hex UUT/num_F
add wave -oct UUT/number_address_1
add wave -oct UUT/number_address_2

add wave -divider -height 20 {Letter BCD Counters}
add wave -hex UUT/letter_BCD_A1
add wave -hex UUT/letter_BCD_A2
add wave -hex UUT/letter_BCD_B1
add wave -hex UUT/letter_BCD_B2
add wave -hex UUT/letter_BCD_C1
add wave -hex UUT/letter_BCD_C2
add wave -hex UUT/letter_BCD_D1
add wave -hex UUT/letter_BCD_D2
add wave -hex UUT/letter_BCD_E1
add wave -hex UUT/letter_BCD_E2
add wave -hex UUT/letter_BCD_F1
add wave -hex UUT/letter_BCD_F2