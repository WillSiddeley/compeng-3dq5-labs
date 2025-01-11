
vlog -sv -work my_work +define+DISABLE_DEFAULT_NET $rtl/single_port_RAM0.v
vlog -sv -work my_work +define+DISABLE_DEFAULT_NET $rtl/single_port_RAM1.v
vlog -sv -work my_work +define+DISABLE_DEFAULT_NET $rtl/experiment2.sv

vlog -sv -work my_work +define+DISABLE_DEFAULT_NET $tb/testbench.sv

