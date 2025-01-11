
if {[file exists $rtl/RAM0.ver]} {
	file delete $rtl/RAM0.ver
}
mem save -o RAM0.mem -f mti -data decimal -addr decimal -wordsperline 1 /TB/UUT/RAM_inst0/altsyncram_component/m_default/altsyncram_inst/mem_data

if {[file exists $rtl/RAM1.ver]} {
	file delete $rtl/RAM1.ver
}
mem save -o RAM1.mem -f mti -data decimal -addr decimal -wordsperline 1 /TB/UUT/RAM_inst1/altsyncram_component/m_default/altsyncram_inst/mem_data
