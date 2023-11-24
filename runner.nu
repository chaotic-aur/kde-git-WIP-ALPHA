#!/run/current-system/sw/bin/env -S nu -n --no-std-lib

use ~/work-kde-git/lib.nu *

export def main [
    --duration(-d)="8hr": string
    --chaoticlw(-l)=true: bool
    --clean_locks(-c)=false: bool # clean all locks
    --apps(-a)=true: bool # build kde apps
    --threads_kf6(-k)=1: number # number of threads
    --threads_extra(-e)=2: number # number of threads
    --threads_plasma(-p)=2: number # number of threads
    --threads_apps(-t)=3: number # number of threads
] {
    if ($chaoticlw) {chaotic lw}
    
    clean-locks -c $clean_locks 
    cd (work_folder)
    #while true {
        #./routine.nu group kf6-unstable -t $threads_kf6
        #./routine.nu group kf6 -t $threads_kf6
        #./routine.nu group extra -t $threads_extra
        #./routine.nu group plasma-unstable -t $threads_plasma
        #./routine.nu group plasma -t $threads_plasma
        ./routine.nu group pkgs_kf6.local -t $threads_kf6
        ./routine.nu group pkgs_others.local -t $threads_extra
        ./routine.nu group pkgs_plasma.local -t $threads_plasma
        if ($apps) {
		#./routine.nu group kde-applications -t $threads_apps
        	./routine.nu group pkgs_apps.local -t $threads_apps
	}
        sleep ($duration | into duration)
    #}
    
    exec /run/current-system/sw/bin/nu $"($env.CURRENT_FILE)" -c ($clean_locks | into string) -a ($apps | into string) -k $threads_kf6 -e $threads_extra -p $threads_plasma -t $threads_apps
}

def clean-locks [
    lock_folder="/tmp/alexjp/locks": string
    --clean_all(-c)=false: bool
] {

    if not ($lock_folder | path exists) {mkdir $lock_folder}

    if ($clean_all) {
        rm $"($lock_folder)/*.lock"
    } else {
        ls $"($lock_folder)/" | where type == dir and modified < ((date now) - 1day) | each {|l| rm $l.name}
    }
}
