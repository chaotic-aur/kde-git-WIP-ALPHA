#!/run/current-system/sw/bin/env -S nu -n --no-std-lib

use ~/work-kde-git/lib.nu *

export def main [
	group: string # package group: kf6, plasma, apps
	package: string # package to build
	--dryrun(-n)=false: bool # dry-run only
	--force(-f)=false: bool # force build package, even if already build
    --rebuild(-r)=false: bool # rebuild package if in same version
] {

	match $package {
		"breeze5" => { exit 9}
		"kirigami2" => { exit 9 }
		"kinit" => { exit 9 }
		"kemoticons" => { exit 9 }
		"kdeconnect" => { exit 9 }
		"kdevelop-python" => { exit 9 }
		"marble" => { exit 9 }
		"discover" => { exit 9 }
		"kjumpingcube" => { exit 9 }
		"kdevelop" => { exit 9 }
		"telepathy-kde-accounts-kcm" => { exit 9 }
		"telepathy-kde-approver" => { exit 9 }
		"telepathy-kde-common-internal" => { exit 9 }
		"kdevelop-php" => { exit 9 }
		"telepathy-kde-call-ui" => { exit 9 }
		"telepathy-kde-contact-list" => { exit 9 }
		"telepathy-kde-send-file" => { exit 9 }
		"telepathy-kde-desktop-applets" => { exit 9 }
		"telepathy-kde-contact-runner" => { exit 9 }
		"telepathy-kde-text-ui" => { exit 9 }
		"telepathy-kde-integration-module" => { exit 9 }
		"telepathy-kde-filetransfer-handler" => { exit 9 }
		"telepathy-kde-common-internals" => { exit 9 }
		"telepathy-kde-auth-handler" => { exit 9 }
	}

	let pkg_folder = (package_folder $group $package)	
	cd (group_folder $group)

	let package_exists = ($pkg_folder | path exists)
	
	if not $package_exists {
		print "invalid package"
		exit 1
	}

	if not ("/tmp/alexjp/locks" | path exists) {mkdir "/tmp/alexjp/locks"}
	let lock_file = ($"/tmp/alexjp/locks/($group)_($package).lock")
	if ($lock_file | path exists) {
		print $"LOCKFILE: ($package)"
		exit 10
	}

	touch $lock_file

	let group_folder_daily = ($"(daily_temp_folder)/($group)")
	if not ($group_folder_daily | path exists) {mkdir $group_folder_daily}

    let build_number = if (ls $group_folder_daily | find $package | length) > 0 { 
    try {
	if not (ls $"($group_folder_daily)/($package)*/*" | find ".log" | is-empty) {
            (grep -L "Finished making" $"($group_folder_daily)/($package)*/($package).log" | lines | length)
        } else {0}
    } catch {0}
    } else {0}

	if ($build_number > 3)  and ($force == false) {
		print $"Package ($package) has been tried ($build_number) already... quitting"
		exit_clean 8 $lock_file
	}

	if ((is_updated $group $package) == true) and ($rebuild == false) {
		print $"ALREADY BUILT: ($package)"
		exit_clean 2 $lock_file
	}
	
	let folder = build_folder $group $package
	if not ($folder | path exists) {
		mkdir $folder
	}

	let build_folder_pkg = $"($folder)/($package)"
	if ($build_folder_pkg | path exists) {
		rm -r $build_folder_pkg		
	}
	let build_folder_pkg_copy = $"($folder)/package"
	if ($build_folder_pkg_copy | path exists) {
		rm -r $build_folder_pkg_copy	
	}
	#print $package
	#print $build_folder_pkg

	#print (ls | find $package)
	#exit_clean 1 $lock_file

	^cp -r $package $build_folder_pkg
	^cp -r $package $build_folder_pkg_copy

	cd $folder
	#print $dryrun
	if ($dryrun) == true {
		print $"BUILDING: ($package)     command: chaotic mkd ($package)       folder: ($folder)"
		exit_clean 3 $lock_file
	}
	
	run-external "bash" "-c" $"chaotic mkd ($package)"
	let errors = chaotic-db-error-texts	
	if not (open $"($package).log" | find $errors.0 $errors.1 $errors.2 $errors.3 | is-empty ) {
		print $"(ansi red_bold)(ansi bl)ERROR: (ansi reset)(ansi red_bold)retrying after 30 seconds!!(ansi reset)"
	  sleep 10sec
	  ^cp -r $build_folder_pkg_copy $build_folder_pkg
		run-external "bash" "-c" $"chaotic mkd ($package)"
	}
	
	exit_clean 0 $lock_file
}

def exit_clean [code: number, lockfile: string] {
	if ($lockfile | path exists) {rm $lockfile}
	exit $code	
}
