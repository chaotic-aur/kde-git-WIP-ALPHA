#!/usr/bin/env -S nu -n --no-std-lib

use lib.nu *


# INFO: Main function, shows help
export def main [] {
	run-external $"($env.CURRENT_FILE)" "--help"
}


# HACK: the way the param strings are done is nonsense, nushell has recently (2 or 3 versions ago) normalized the bool params issues

export def "main group" [
	group: string # package group: kf6, plasma, apps
	--fetch(-g)=false: bool # fetch and generate arch PKGBUILDS
	--dryrun(-n)=false: bool
	--force(-f)=false: bool
	--rebuild(-r)=false: bool
	--threads(-t)=1: number # number of threads to build at the same time
] {	
	cd (group_folder $group)
	
	let packages = (ls */PKGBUILD | each {|p| echo (dirname $p.name)})
	$packages | par-each -t $threads {|p|		
		if ($fetch == true) {/home/alexjp/work-kde-git/fetcher.nu pkg $group $p}
		let dryrun_string = (if ($dryrun) {"--dryrun=true"} else {"--dryrun=false"})
		let force_string = (if ($force) {"--force=true"} else {"--force=false"})
		let rebuild_string = (if ($rebuild) {"--rebuild=true"} else {"--rebuild=false"})

		run-external "/home/alexjp/work-kde-git/builder.nu" $group $p $dryrun_string $force_string $rebuild_string
	}

}

export def "main list" [
	group: string # package group: kf6, plasma, apps
	--fetch(-g)=false: bool # fetch and generate arch PKGBUILDS
	--dryrun(-n)=false: bool
	--force(-f)=false: bool
	--rebuild(-r)=false: bool
	--threads(-t)=1: number # number of threads to build at the same time
] {	
	cd (group_folder $group)
	
	let packages = (open list | lines)
	$packages | par-each -t $threads {|p|		
		if ($fetch == true) {/home/alexjp/work-kde-git/fetcher.nu pkg $group $p}
		let dryrun_string = (if ($dryrun) {"--dryrun=true"} else {"--dryrun=false"})
		let force_string = (if ($force) {"--force=true"} else {"--force=false"})
		let rebuild_string = (if ($rebuild) {"--rebuild=true"} else {"--rebuild=false"})

		run-external "/home/alexjp/work-kde-git/builder.nu" $group $p $dryrun_string $force_string $rebuild_string
	}

}



# HACK: This isnt really used currently, it was for an implementation that used yaml lists as package indexes

#export def "main list" [
#	group: string # package group: kf6, plasma, apps
#	file: string # list of packages
#	--fetch(-g)=false: bool # fetch and generate arch PKGBUILDS
#	--dryrun(-n)=false: bool
#	--force(-f)=false: bool
#	--threads(-t)=1: number # number of threads to build at the same time
#] {	
#	cd (group_folder $group)
#	
#	let pkgs = (open -r $file | from yaml)
#    $pkgs | par-each -t $threads {|l| 
#        let _disabled = if ("disabled" in ($l | columns)) {($l | get "disabled") == true} else {false}
#
#        if not ($_disabled) {
#        	let _name = ($l | get name)
#        	let _transform = if ("transform" in ($l | columns)) {$l | get "transform"} else {false}
#        	let _reponame = if ("reponame" in ($l | columns)) {$l | get "reponame"} else {$_name}
#        	let _branch = if ("branch" in ($l | columns)) {$l | get "branch"} else {"main"}
#			let dryrun_string = (if ($dryrun) {"--dryrun=true"} else {"--dryrun=false"})
#			let force_string = (if ($force) {"--force=true"} else {"--force=false"})
#
#        	run-external "/home/alexjp/work-kde-git/builder.nu" $group $_name $dryrun_string $force_string    
#        }
#    }
#
#
#}

