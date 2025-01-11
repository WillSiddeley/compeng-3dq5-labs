set_location_assignment PIN_H5 -to PS2_DATA_I
set_location_assignment PIN_G6 -to PS2_CLOCK_I
set_global_assignment -name FMAX_REQUIREMENT "1 MHz" -section_id clock_ps2
set_instance_assignment -name CLOCK_SETTINGS clock_ps2 -to PS2_CLOCK_I


