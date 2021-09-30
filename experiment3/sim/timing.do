
# set up paths, top-level module, ...
set timing ../syn/simulation/modelsim/
set rtl ../rtl
set tb ../tb
set sim .
set top TB

onbreak {resume}

transcript on

if {[file exists lut_work]} {
	vdel -lib lut_work -all
}

vlib lut_work
vmap work lut_work

# compile the source files

if {[file exists experiment3_v.sdo]} {
	file delete experiment3_v.sdo
}
file copy $timing/experiment3_v.sdo .

if {[file exists experiment3.vo]} {
	file delete experiment3.vo
}
file copy $timing/experiment3.vo .

vlog -sv -work lut_work +define+DISABLE_DEFAULT_NET experiment3.vo

vlog -sv -work lut_work +define+DISABLE_DEFAULT_NET $tb/interface.sv
vlog -sv -work lut_work +define+DISABLE_DEFAULT_NET $tb/testbench.sv

# specify library for simulation

vsim -t 100ps -L cycloneive_ver -L altera_ver -lib lut_work $top

# Clear previous simulation
restart -f

# add signals to waveform
# activate waveform simulation
view wave

# format signal names in waveform
configure wave -signalnamewidth 1
configure wave -timeline 0
configure wave -timelineunits us

# add signals to waveform
add wave -divider -height 20 {board inputs/outputs}
add wave -bin UUT/CLOCK_50_I
add wave -hex UUT/SWITCH_I
add wave -bin UUT/VGA_CLOCK_O
add wave -bin UUT/VGA_HSYNC_O
add wave -bin UUT/VGA_VSYNC_O
add wave -hex UUT/VGA_RED_O
add wave -hex UUT/VGA_GREEN_O
add wave -hex UUT/VGA_BLUE_O

add wave -divider -height 20 {internal LUT signals (red)}
add wave {/UUT/\instance_of_red_lcell[1].red_buffer~combout }
add wave {/UUT/\instance_of_red_lcell[50].red_buffer~combout }
add wave {/UUT/\instance_of_red_lcell[99].red_buffer~combout }

add wave -divider -height 20 {internal LUT signals (green)}
add wave {/UUT/\instance_of_green_lcell[1].green_buffer~combout }
add wave {/UUT/\instance_of_green_lcell[50].green_buffer~combout }
add wave {/UUT/\instance_of_green_lcell[100].green_buffer~combout }
add wave {/UUT/\instance_of_green_lcell[150].green_buffer~combout }
add wave {/UUT/\instance_of_green_lcell[199].green_buffer~combout }

add wave -divider -height 20 {internal LUT signals (blue)}
add wave {/UUT/\instance_of_blue_lcell[1].blue_buffer~combout }
add wave {/UUT/\instance_of_blue_lcell[50].blue_buffer~combout }
add wave {/UUT/\instance_of_blue_lcell[100].blue_buffer~combout }
add wave {/UUT/\instance_of_blue_lcell[150].blue_buffer~combout }
add wave {/UUT/\instance_of_blue_lcell[200].blue_buffer~combout }
add wave {/UUT/\instance_of_blue_lcell[250].blue_buffer~combout }
add wave {/UUT/\instance_of_blue_lcell[299].blue_buffer~combout }

# run simulation
run 17ms

# print simulation statistics
simstats

