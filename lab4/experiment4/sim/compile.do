
vlog -sv -work my_work +define+DISABLE_DEFAULT_NET $rtl/SRAM_BIST.sv
vlog -sv -work my_work +define+DISABLE_DEFAULT_NET +define+SIMULATION $rtl/SRAM_controller.sv
vlog -sv -work my_work +define+DISABLE_DEFAULT_NET $rtl/experiment4.sv

vlog -sv -work my_work +define+DISABLE_DEFAULT_NET $tb/tb_SRAM_Emulator.sv
vlog -sv -work my_work +define+DISABLE_DEFAULT_NET $tb/testbench.sv

