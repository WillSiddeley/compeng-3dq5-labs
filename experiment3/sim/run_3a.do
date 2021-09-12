onbreak {resume}
transcript on

set PrefMain(saveLines) 50000
.main clear

if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

# load designs

# insert files specific to your design here

vlog -sv -work rtl_work +define+DISABLE_DEFAULT_NET ../rtl/experiment3a.sv
vlog -sv -work rtl_work +define+DISABLE_DEFAULT_NET ../tb/tb_experiment3a.sv

# specify library for simulation
vsim -t 100ps -L altera_mf_ver -lib rtl_work tb_experiment3a

# Clear previous simulation
restart -f

# format signal names in waveform
configure wave -signalnamewidth 1
configure wave -timeline 0
configure wave -timelineunits us

add wave /CLOCK
add wave /RESETN
add wave -radix unsigned /uut/BCD_COUNT_O

# run simulation
run 1us

destroy .structure
destroy .signals
destroy .source

# simstats
