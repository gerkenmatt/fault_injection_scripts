# Fault Injection Utility Functions 
# create some data
source [find "z_fault_injection/fault_utility.tcl"]

proc printStackSnapshot {file_fp} {
	set max_sp 0x20030000
	set current_sp [get_sp]
	set stack_size [expr $max_sp - $current_sp]
	array set stack_contents {}	

	if {[expr $stack_size > 0]} {
		mem2array stack_contents 8 $current_sp $stack_size
	}
	
	puts -nonewline $file_fp "        "	
	for {set count 0} {[expr $count < $stack_size]} {incr count} {
		puts -nonewline $file_fp "[format {%02x} $stack_contents($count)] "
	}

	puts $file_fp ""
}

proc printRegs {file_fp} {
	set num_regs 40	

	for {set count 0} {[expr $count < $num_regs]} {incr count} {
		puts -nonewline $file_fp [capture "reg $count"]
	}
}

proc takeMemorySample { outfile_fp } {
		
	puts -nonewline $outfile_fp "<SAMPLE desc="

	# save registers
	puts $outfile_fp "    <regs>"
	printRegs $outfile_fp
	puts $outfile_fp "    </regs>"

	# #save chosen heap data
	# printHeapData $sampleList_fp $outfile_fp
	
	# save stack data
	puts $outfile_fp "    <stack>"
	printStackSnapshot $outfile_fp
	puts $outfile_fp "    </stack>"

	puts $outfile_fp "</SAMPLE>"

}

set data "This is some test data.\n"
# pick a filename - if you don't include a path,
#  it will be saved in the current directory
set filename "z_fault_injection/test.txt"
# open the filename for writing
set fileId [open $filename "w"]
# send the data to the file -
#  omitting '-nonewline' will result in an extra newline
# at the end of the file
puts -nonewline $fileId $data

reset run
halt

takeMemorySample $fileId

set reg_data "[capture "reg 12"]"
echo "reg data: "$reg_data


# close the file, ensuring the data is written out before you continue
#  with processing.
close $fileId
