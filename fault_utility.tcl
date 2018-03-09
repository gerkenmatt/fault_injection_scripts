# Fault Injection Utility Functions 

proc get_sp {} {
	return [lindex [regexp -all -inline {\S+} [capture "reg sp"]] 2]
}

proc get_pc {} {
	return [lindex [regexp -all -inline {\S+} [capture "reg pc"]] 2]
}

proc checkHardfault {} {
	set psr_reg [capture "reg xPSR"]
	set psr_reg [lindex $psr_reg 2]
	set psr_reg [expr $psr_reg & 3]

	#true if hard fault occured, false otherwise
	return [expr $psr_reg == 3]
}

proc get_stack_size {} {
	set max_sp 0x20030000
	set current_sp [get_sp]
	return [expr $max_sp - $current_sp]
}


