# Usage:
#   vivado -mode batch -source vivado/run_synth.tcl
#   vivado -mode batch -source vivado/run_synth.tcl -tclargs my_project

if {[llength $argv] >= 1} {
    set project_name [lindex $argv 0]
} else {
    set project_name "cnn_accelerator_nexys_a7"
}

set script_dir [file normalize [file dirname [info script]]]
set repo_root [file normalize [file join $script_dir ".."]]
set project_dir [file normalize [file join $repo_root "vivado_build" $project_name]]
set project_file [file join $project_dir "${project_name}.xpr"]

if {![file exists $project_file]} {
    puts "Project file not found: $project_file"
    puts "Run vivado/create_project.tcl first."
    exit 1
}

open_project $project_file
reset_run synth_1
launch_runs synth_1 -jobs 10
wait_on_run synth_1

set synth_status [get_property STATUS [get_runs synth_1]]
puts "Synthesis status: $synth_status"

if {[string match "*ERROR*" $synth_status] || [string match "*Failed*" $synth_status]} {
    exit 1
}
