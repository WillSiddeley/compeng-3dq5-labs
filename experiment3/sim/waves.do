# activate waveform simulation

view wave

# format signal names in waveform

configure wave -signalnamewidth 1
configure wave -timeline 0
configure wave -timelineunits us

# add signals to waveform

add wave -divider -height 20 {top-level I/Os}
add wave -bin UUT/CLOCK_50_I
add wave -bin UUT/Clock_57_6
add wave -bin UUT/resetn
add wave -bin {UUT/SWITCH_I[0]}
add wave -bin {UUT/SWITCH_I[1]}

add wave -divider -height 20 {top-level UART Rx FSM}
add wave UUT/RX_state
add wave -bin UUT/UART_we
add wave -uns UUT/UART_rx_address
add wave -hex UUT/UART_write_data
add wave -bin UUT/UART_rx_enable
add wave -bin UUT/UART_rx_done

add wave -divider -height 20 {UART receiver}
add wave -bin UUT/UART_RX/UART_RX_I
add wave UUT/UART_RX/RXC_state
add wave -uns UUT/UART_RX/clock_count
add wave -uns UUT/UART_RX/data_count
add wave -hex UUT/UART_RX/data_buffer
add wave -bin UUT/UART_RX/Frame_error
add wave -bin UUT/UART_RX/Overrun

add wave -divider -height 20 {top-level UART Tx FSM}
add wave UUT/TX_state
add wave -bin UUT/UART_tx_clock_enable
add wave -uns UUT/UART_tx_address 
add wave -hex UUT/UART_read_data
add wave -bin UUT/UART_tx_start
add wave -bin UUT/UART_tx_empty
add wave -bin UUT/UART_tx_done

add wave -divider -height 20 {UART transmitter}
add wave -bin UUT/UART_TX/UART_TX_O
add wave UUT/UART_TX/TXC_state
add wave -uns UUT/UART_TX/data_count
add wave -hex UUT/UART_TX/data_buffer

# add wave -divider -height 20 {testbench-only data}
# add wave -uns uart_rx_generate/rx_index
# add wave -hex uart_rx_generate/uart_rx_byte
# add wave -uns uart_tx_assemble/tx_index
# add wave -hex uart_tx_assemble/uart_tx_byte




