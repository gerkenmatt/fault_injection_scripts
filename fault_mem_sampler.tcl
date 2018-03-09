#Tcl script for fault injection that I have so far. 
source [find "z_fault_injection/fault_utility.tcl"]
source [find "z_fault_injection/xml_sampling_formater.tcl"]

proc flip_bit {data bitPos} {
	set newValue [expr 1 << $bitPos]
	# set newValue $data
	set newValue [expr $data ^ $newValue]
	return $newValue
}

proc get_pc {} {
    return [lindex [regexp -all -inline {\S+} [capture "reg pc"]] 2]
}

#compare two arrays: return 1 if they hold the same values
proc array_compare {arr1 arr2} {


    if {[array size arr1] != [array size arr2]} {
		echo "LLLLLLLLLLLLLLLLLLLLLLLLL"
        return 0
    }
	
    if {[array size arr1] == 0} {
        return 1
    }

    set keys(arr1) [lsort [array names arr1]]
    set keys(arr2) [lsort [array names arr2]]
    set keys(keys) $keys(arr1)

    if {![string equal $keys(arr1) $keys(arr2)]} {
        return 0
    }

    foreach key $keys(keys) {
        if {![string equal $arr1($key) $arr2($key)]} {
            return 0
        }
    }

    return 1
}

#param nInj: number of fault injection trials to run
proc fault_inject {nInj} {

	# set file_txt "FAULT INJECTION TEST"

	set filename "z_fault_injection/samples.txt"
	set outfile_fp [open $filename "w"]
	# puts  $outfile_fp $file_txt

	initXML $outfile_fp

	set sample_list_fp  [open "z_fault_injection/sampling_list.txt" r]

	set TIME_start [clock clicks ]

	set count 0

	#TODO: open sample_list file

	#define addresses of important mem locations
	#mem location of the period global variable
	set tim_period_addr 0x200000b0
	#TODO: set the timer configuration registers

	#descriptions for XML samples
	set golden_desc "golden"
	set inj_desc "injection"
	set seq_loss_desc "sequence_loss"


	#define wait times
	#how long to wait for first bp in main 
	set start_wait 10
	set golden_wait 100	
	set inject_wait 100
	#how long to wait for the result to be calculated
	set results_wait 100			
	
	
	#set breakpoints
	#where we will set the timer period,seed
	bp 0x08001222 2		
	#set injection breakpoint
	bp 0x080014be 2
	#where we capture the results matrix
	set results_bp 0x08001242
	bp $results_bp 2
	
	
	
	#open test vector files 
	set period_fp [open "z_fault_injection/vector_period.txt" r]
	set addr_fp [open "z_fault_injection/vector_addr.txt" r]
	set seed_fp [open "z_fault_injection/vector_seed.txt" r]
	set bit_fp  [open "z_fault_injection/vector_bit.txt" r]
	

    echo "Injecting $nInj Faults"
    halt

    #grab the golden sample
    reset run
	sleep $start_wait
	resume
	sleep $inject_wait
	resume
	sleep $results_wait
	halt

	#grab the golden sample
	takeGoldenSample $sample_list_fp $outfile_fp 


    while {$count < $nInj} {
    	#parse out the next test params
		if { [gets $period_fp data] >= 0 } {
			set tim_period [expr $data + 0] 	
			#echo $tim_period
		}
		if { [gets $addr_fp data] >= 0 } {
			set inj_addr [expr $data + 0] 	
			#echo $inj_addr
		}
		if { [gets $seed_fp data] >= 0 } {
			set seed_value [expr $data + 0] 
			#echo " "
			#echo "*******seed value: $seed_value"
		}
		if { [gets $bit_fp data] >= 0 } {
			set bit_num [expr $data + 0] 	
			#echo " "
			#echo "*******bit_num: $bit_num"
		}

		#SET THE TIMER PERIOD
		reset run
		sleep $start_wait
		mww $tim_period_addr $tim_period
		mem2array period_data_arr 32 $tim_period_addr 1 
		echo "          Period is now: $period_data_arr"
		resume
		sleep $inject_wait
		
		
		#INJECT FAULT
		echo " "
		echo "*****Injecting fault at $inj_addr with period $tim_period"
		#we should now be stopped in inject_fault() function
		#get byte of data from the injection address
		mem2array inj_data_arr 8 $inj_addr 1        
		echo "OLD DATA: $inj_data_arr(0)"
		#flip bit 
		set inj_data [flip_bit $inj_data_arr(0) $bit_num]   	
		#fault injected here, put fliped value back in mem
		#echo "INJ_DATA: $inj_data"
		mww $inj_addr $inj_data 8
		echo "FAULT INJECTED: resuming execution"
		resume
		sleep $results_wait
		halt

		set stopAddr [get_pc]
		#check for loss of sequence error
		if {[expr $stopAddr != $results_bp]} {
			 echo "Loss of Sequence"
			takeInjectionSample $sample_list_fp $outfile_fp $inj_addr $tim_period $seq_loss_desc 
			set count [expr {$count + 1}]
			 halt
			 continue
		}
		takeInjectionSample $sample_list_fp $outfile_fp $inj_addr $tim_period $inj_desc

		set count [expr {$count + 1}]

    }

	close $period_fp
	close $addr_fp
	close $seed_fp
	close $bit_fp
	
	set TIME_taken [expr [clock clicks] - $TIME_start]
	
    echo "Injecting complete"
	echo "Completed $nInj injections"
	set TIME_taken_sec [expr {$TIME_taken / 1000}]
	echo "Took $TIME_taken_sec ms to complete"

	completeXML $outfile_fp
	
	close $outfile_fp 
}

fault_inject 100



