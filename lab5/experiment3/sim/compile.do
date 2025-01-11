vlog -sv -work my_work +define+DISABLE_DEFAULT_NET $rtl/dual_port_RAM.v  
vlog -sv -work my_work +define+DISABLE_DEFAULT_NET $rtl/convert_hex_to_seven_segment.sv  
vlog -sv -work my_work +define+DISABLE_DEFAULT_NET $rtl/UART_transmit_controller.sv
vlog -sv -work my_work +define+DISABLE_DEFAULT_NET +define+SIMULATION $rtl/UART_receive_controller.sv  
vlog -sv -work my_work +define+DISABLE_DEFAULT_NET +define+SIMULATION $rtl/experiment3.sv

vlog -sv -work my_work +define+DISABLE_DEFAULT_NET $tb/testbench.sv

