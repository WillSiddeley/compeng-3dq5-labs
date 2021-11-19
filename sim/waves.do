# activate waveform simulation

view wave

# format signal names in waveform

configure wave -signalnamewidth 1
configure wave -timeline 0
configure wave -timelineunits us

# add signals to waveform

add wave -divider -height 20 {Top-level signals}
add wave -bin UUT/CLOCK_50_I
add wave -bin UUT/resetn
add wave UUT/top_state
add wave UUT/bot_state
add wave -uns UUT/UART_timer

add wave -divider -height 10 {SRAM signals}
add wave -uns UUT/SRAM_address
add wave -uns UUT/SRAM_address_Y
add wave -uns UUT/SRAM_address_UV
add wave -uns UUT/SRAM_address_RGB
add wave -hex UUT/SRAM_write_data
add wave -bin UUT/SRAM_we_n
add wave -hex UUT/SRAM_read_data

add wave -divider -height 10 {VGA signals}
add wave -bin UUT/VGA_unit/VGA_HSYNC_O
add wave -bin UUT/VGA_unit/VGA_VSYNC_O
add wave -uns UUT/VGA_unit/pixel_X_pos
add wave -uns UUT/VGA_unit/pixel_Y_pos
add wave -hex UUT/VGA_unit/VGA_red
add wave -hex UUT/VGA_unit/VGA_green
add wave -hex UUT/VGA_unit/VGA_blue

add wave -divider -height 10 {Colors}
add wave -hex UUT/R_even
add wave -hex UUT/G_even
add wave -hex UUT/B_even
add wave -hex UUT/R_odd
add wave -hex UUT/G_odd
add wave -hex UUT/B_odd

add wave -divide -height 10 {Flags}
add wave -uns UUT/Milestone_1_finished
add wave -uns UUT/pixel_row_number
add wave -uns UUT/pixel_column_number
add wave -uns UUT/timesLeadOut

add wave -divider -height 10 {Registers}
add wave -hex UUT/Y
add wave -hex UUT/U_prime_even
add wave -hex UUT/U_prime_odd
add wave -hex UUT/V_prime_even
add wave -hex UUT/V_prime_odd

add wave -divider -height 10 {Buffers}
add wave -uns UUT/Y_buf
add wave -uns UUT/U_buf
add wave -uns UUT/V_buf
add wave -uns UUT/isUBuffered
add wave -uns UUT/isVBuffered
add wave -uns UUT/SRAM_read_data

add wave -divider -height 10 {Registers 2}
add wave -hex UUT/U_plus_5
add wave -hex UUT/U_plus_3
add wave -hex UUT/U_plus_1
add wave -hex UUT/U_minus_1
add wave -hex UUT/U_minus_3
add wave -hex UUT/U_minus_5
add wave -hex UUT/V_plus_5
add wave -hex UUT/V_plus_3
add wave -hex UUT/V_plus_1
add wave -hex UUT/V_minus_1
add wave -hex UUT/V_minus_3
add wave -hex UUT/V_minus_5

add wave -divider -height 10 {Multipliers}
add wave -uns UUT/Mult_op_1_1
add wave -uns UUT/Mult_op_1_2
add wave -uns UUT/Mult_op_2_1
add wave -uns UUT/Mult_op_2_2
add wave -dec UUT/Mult_result_1
add wave -dec UUT/Mult_result_2

add wave -divider -height 10 {Accumulators}
add wave -dec UUT/U_accumulator
add wave -dec UUT/V_accumulator
add wave -dec UUT/R_accumulator_even
add wave -dec UUT/G_accumulator_even
add wave -dec UUT/B_accumulator_even
add wave -dec UUT/R_accumulator_odd
add wave -dec UUT/G_accumulator_odd
add wave -dec UUT/B_accumulator_odd

