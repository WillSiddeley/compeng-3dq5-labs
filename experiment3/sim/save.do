
if {[file exists $rtl/RAM.ver]} {
	file delete $rtl/RAM.ver
}
mem save -o RAM0.mem -f mti -data hex -addr dec -wordsperline 1 /TB/UUT/dual_port_RAM_inst/altsyncram_component/m_default/altsyncram_inst/mem_data

