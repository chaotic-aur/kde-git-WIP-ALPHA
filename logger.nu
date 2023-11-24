#!/run/current-system/sw/bin/env -S nu -n --no-std-lib

use ~/work-kde-git/lib.nu *

export def main [
] {
    run-external $"($env.CURRENT_FILE)" "--help"
}

# Show list of logs for packages that failed to build (general errors)
export def "main errors" [
    --filter: string
] {
    let error = '==> ERROR: A failure occurred in build().'
    engine (list-all --filter $filter | each {|l| grep $error -l -i $l} | lines)
}


# Show list of logs for packages that failed to build (database errors)
export def "main errors db" [
    --filter: string
] {
    let error = 'error: failed to prepare transaction (invalid or corrupted database)\|error: failed retrieving file'
    engine (list-all --filter $filter | each {|l| grep $error -l -i $l} | lines)
}


# Show list of logs for packages that failed to build (conflicts errors)
export def "main conflicts" [
] {
    engine (list_conflicts)
}

# Show list of all logs
export def "main all" [
    --filter: string
] {
    engine (list-all --filter $filter)
}




def engine [
    list: any # list of log files
] {
    if ($list | is-empty) {print "nothing to show!"; return}
    mut selected_file = ($list | input list -f 'Select which log to show')
    while not ($selected_file | is-empty) {
        hx $"(daily_temp_folder)/($selected_file)"
	    $selected_file = ($list | input list -f 'Select which log to show')
    }
    echo "Quitting"
}


def list_errors [] {
    cd $"(daily_temp_folder)"
	return (grep "==> ERROR: A failure occurred in build()." -i -l */*/*.log | lines)
}
def list_conflicts [] {
    cd $"(daily_temp_folder)"
	return (grep "error: failed to commit transaction (conflicting files)" -i -l */*/*.log | lines)
}
def list-all [
    --filter: string
] {
    cd $"(daily_temp_folder)"
	  let _list = (ls */*/*.log | sort-by -r modified | get name)
    if ($filter | is-empty) {return $_list} else {($_list | find $filter)}
}

