# activate waveform simulation
view wave

# format signal names in waveform
configure wave -signalnamewidth 1
configure wave -timeline 0
configure wave -timelineunits us

# add signals to waveform
add wave -divider -height 20 {board and internal signals}
add wave -bin UUT/CLOCK_50_I
add wave -bin UUT/resetn
add wave -bin {UUT/SWITCH_I[0]}

# add wave -divider -height 10 {}
# add wave -hex UUT/SRAM_DATA_IO
# add wave -hex UUT/SRAM_ADDRESS_O
# add wave -bin UUT/SRAM_UB_N_O
# add wave -bin UUT/SRAM_LB_N_O
# add wave -bin UUT/SRAM_WE_N_O
# add wave -bin UUT/SRAM_CE_N_O
# add wave -bin UUT/SRAM_OE_N_O

add wave -divider -height 10 {}
add wave UUT/BIST_unit/BIST_state
add wave -hex UUT/BIST_unit/BIST_address
add wave -hex UUT/BIST_unit/BIST_write_data
add wave -bin UUT/BIST_unit/BIST_we_n
add wave -hex UUT/BIST_unit/BIST_read_data
add wave -hex UUT/BIST_unit/BIST_expected_data
add wave -bin UUT/BIST_unit/BIST_finish
add wave -bin UUT/BIST_unit/BIST_mismatch

