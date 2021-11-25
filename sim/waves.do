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
add wave UUT/m2_state
add wave -uns UUT/UART_timer

add wave -divider -height 10 {SRAM signals}
add wave -uns UUT/SRAM_address
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

add wave -divider -height 10 {SRAM Signals}
add wave -uns UUT/SRAM_address
add wave -uns UUT/SRAM_read_data
add wave -uns UUT/SRAM_write_data
add wave -uns UUT/SRAM_we_n

add wave -divider -height 10 {RAM Signals}
add wave -uns UUT/RAM_address_a_0
add wave -uns UUT/RAM_address_b_0
add wave -uns UUT/RAM_address_a_1
add wave -uns UUT/RAM_address_b_1
add wave -uns UUT/RAM_address_a_2
add wave -hex UUT/RAM_read_data_a_0
add wave -hex UUT/RAM_read_data_b_0
add wave -hex UUT/RAM_read_data_a_1
add wave -hex UUT/RAM_read_data_b_1
add wave -hex UUT/RAM_read_data_a_2
add wave -hex UUT/RAM_write_data_a_0
add wave -hex UUT/RAM_write_data_b_0
add wave -hex UUT/RAM_write_data_a_1
add wave -hex UUT/RAM_write_data_b_1
add wave -hex UUT/RAM_write_data_a_2
add wave -hex UUT/RAM_write_data_b_2
add wave -uns UUT/RAM_we_n_a_0
add wave -uns UUT/RAM_we_n_b_0
add wave -uns UUT/RAM_we_n_b_2

add wave -divide -height 10 {Flags}
add wave -uns UUT/Milestone_2_finished
add wave -uns UUT/sampleCounterEnabled
add wave -uns UUT/isFinishedBlock
add wave -uns UUT/isTFilled
add wave -int UUT/S_prime_buf

add wave -divider -height 10 {Multipliers}
add wave -uns UUT/RAM_address_T
add wave -uns UUT/RAM_address_sample
add wave -uns UUT/RAM_address_C
add wave -uns UUT/calculationsPerformed
add wave -int UUT/Mult_op_3_1
add wave -int UUT/Mult_op_3_2
add wave -int UUT/Mult_result_3
add wave -int UUT/Mult_op_4_1
add wave -int UUT/Mult_op_4_2
add wave -int UUT/Mult_result_4
add wave -int UUT/Mult_op_5_1
add wave -int UUT/Mult_op_5_2
add wave -int UUT/Mult_result_5

add wave -divider -height 10 {Accumulators}
add wave -int UUT/colAccum_1
add wave -int UUT/colAccum_2
add wave -int UUT/colAccum_3

add wave -divider -height 10 {T Registers}
add wave -int UUT/T_buf_1
add wave -int UUT/T_buf_2
add wave -int UUT/T_buf_3

add wave -divider -height 10 {Sample Counter}
add wave -uns UUT/M2_SC
add wave -uns UUT/M2_row_address
add wave -uns UUT/M2_col_address
add wave -uns UUT/M2_row_index
add wave -uns UUT/M2_col_index
add wave -uns UUT/M2_address_generation
add wave -hex UUT/M2_address_generation
