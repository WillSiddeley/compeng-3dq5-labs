
# load designs

vlog -sv -work my_work +define+DISABLE_DEFAULT_NET $rtl/VGA_controller.sv
vlog -sv -work my_work +define+DISABLE_DEFAULT_NET $rtl/PS2_controller.sv
vlog -sv -work my_work +define+DISABLE_DEFAULT_NET $rtl/char_rom.sv
vlog -sv -work my_work +define+DISABLE_DEFAULT_NET $rtl/char_gen_rom.v
vlog -sv -work my_work +define+DISABLE_DEFAULT_NET $rtl/experiment4.sv

vlog -sv -work my_work +define+DISABLE_DEFAULT_NET $tb/interface.sv
vlog -sv -work my_work +define+DISABLE_DEFAULT_NET $tb/testbench.sv


