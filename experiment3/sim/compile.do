
vlog -sv -work my_work +define+DISABLE_DEFAULT_NET $rtl/LCD_controller.sv
vlog -sv -work my_work +define+DISABLE_DEFAULT_NET $rtl/experiment3.sv

vlog -sv -work my_work +define+DISABLE_DEFAULT_NET $tb/interface.sv
vlog -sv -work my_work +define+DISABLE_DEFAULT_NET $tb/testbench.sv

