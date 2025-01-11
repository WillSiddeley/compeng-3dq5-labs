
# load designs

vlog -sv -work my_work +define+DISABLE_DEFAULT_NET $rtl/convert_hex_to_seven_segment.sv
vlog -sv -work my_work +define+DISABLE_DEFAULT_NET $rtl/LCD_controller.sv
vlog -sv -work my_work +define+DISABLE_DEFAULT_NET $rtl/PS2_controller.sv
vlog -sv -work my_work +define+DISABLE_DEFAULT_NET $rtl/PS2_to_LCD_ROM.v
vlog -sv -work my_work +define+DISABLE_DEFAULT_NET $rtl/experiment5.sv

vlog -sv -work my_work +define+DISABLE_DEFAULT_NET $tb/interface.sv
vlog -sv -work my_work +define+DISABLE_DEFAULT_NET $tb/testbench.sv

