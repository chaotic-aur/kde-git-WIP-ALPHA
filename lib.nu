
export def work_folder [] nothing -> string {
	$"($env.HOME)/work-kde-git"
}

export def package_folder [group: string, pkg: string] [string, string] -> string {	
	$"($env.HOME)/work-kde-git/($group)/($pkg)"
}
export def group_folder [group: string] string -> string {	
	$"($env.HOME)/work-kde-git/($group)"
}

export def build_folder [group: string, pkg: string] {
	let timestamp = (date now | format date "%s")
	let date = (date now | format date "%Y-%m-%d_%H-%m-%S")
	#$"(daily_temp_folder)/($group)/($pkg).($timestamp)"
	$"(daily_temp_folder)/($group)/($pkg).($date)"
}
export def daily_temp_folder [] {
	let timestamp = (date now | format date "%s")
	let date = (date now | format date "%Y-%m-%d")
	$"/tmp/alexjp/kdegit/($date)"
}

export def is_updated [group: string, package: string] [string, string] -> string {
	cd (group_folder $group)
    let commit = (find_commit_from_package $package)
    if ($commit | is-empty) {
            is_updated_source $group $package
    } else {
            is_updated_commit $group $package
    }
}

export def is_updated_source [group: string, package: string] [string, string] -> string {
	cd (group_folder $group)

	#let url = (open $"($package)/PKGBUILD" | find "source=" | ansi strip | find "#source" --invert | str substring 12..-1 | str replace "${pkgname}" $package | get 0)
	let url = (find_source_from_package $package --keepbranch true)

  if not ($url | find ".tar." | is-empty) {return true}

	let upstream_commit = if ($url | $in =~ "#branch=") {
		let index = ($url | str index-of "#branch=")
		let branch = ($url | str substring ($index + 8)..)
		GIT_ASKPASS=echo git ls-remote ($url | str substring 0..$index) $branch | str substring 0..(version-commit-string-length)
	} else {
		GIT_ASKPASS=echo git ls-remote $url HEAD | str substring 0..(version-commit-string-length)
	}
	#print $upstream_commit
	
	let archive_folder = (open /etc/xdg/repoctl/config.toml | get repo | path dirname)
	#print $archive_folder	
	let pkgrel = (find_pkgrel_from_package $package)
	#let commit_pkgrel = $"($upstream_commit).($pkgrel)"
	#print $commit_pkgrel
	let built_packages = (ls $archive_folder | get name | find $package | find -v ".sig" | find $upstream_commit | ansi strip)
    #print $built_packages
		#print $upstream_commit
    let up_to_date = if ($built_packages | is-empty) {false} else {($built_packages | any {|p|
        #print $p
				#let index_end = ($p | str index-of "-1-")
				#let index_end = (($p | str index-of $upstream_commit) + (version-commit-string-length) + 2)
				let index_commit = ($p | str index-of $upstream_commit)
				#print $index_commit
				let index_end = (($p | str substring $index_commit.. | str index-of "-") + $index_commit + 2)
				#print $index_end
        let index_beg = ($index_end - 1)
        let rel = ($p | str substring $index_beg..$index_end)
				#print $"pkgrel: ($pkgrel) | pkg: ($rel)"
        try { (($rel | into int) >= ($pkgrel | into int)) }
    })}
	#print $"(ls ($archive_folder) | get name | find ($package) | find ($commit_pkgrel) | ansi strip)"
	#print $up_to_date
	#let result = (if ($built_packages | is-empty) {false} else {true})
	return $up_to_date
}


export def is_updated_commit [group: string, package: string] [string, string] -> string {
	cd (group_folder $group)
	let upstream_commit = ((find_commit_from_package $package) | str substring 0..(version-commit-string-length))

	let archive_folder = (open /etc/xdg/repoctl/config.toml | get repo | path dirname)
	#print $archive_folder	
	let pkgrel = (find_pkgrel_from_package $package)
	let commit_pkgrel = $"($upstream_commit).($pkgrel)"
	#print $commit_pkgrel
	let built_packages = (ls $archive_folder | get name | find $package | find -v ".sig" | find $upstream_commit | ansi strip)
	#print ($built_packages)

    let up_to_date = if ($built_packages | is-empty) {false} else {($built_packages | any {|p|
        #let index_end = ($p | str index-of "-1-")
				let index_commit = ($p | str index-of $upstream_commit)
				let index_end = (($p | str substring $index_commit.. | str index-of "-") + $index_commit + 2)
        let index_beg = ($index_end - 1)
        let rel = ($p | str substring $index_beg..$index_end)
				#print $"pkgrel: ($pkgrel) | pkg: ($rel)"
        try { (($rel | into int) >= ($pkgrel | into int)) }
    })}
	#print $"(ls ($archive_folder) | get name | find ($package) | find ($commit_pkgrel) | ansi strip)"
	#print $up_to_date
	#let result = (if ($built_packages | is-empty) {false} else {true})
	
	return $up_to_date
}


def version-commit-string-length [] {return 7}

def find_source_from_package [
    package: string
    --keepbranch=false: bool
] {
        let file = ($"($package)/PKGBUILD")
        let url = (open $file | find "source=" | ansi strip | find "#source" --invert)
        let url_0 = ($url | get 0)
        let index = ($url | str index-of "http") | get 0

        let index_end = match $url_0 {
             _ if ($url_0 | str contains "commit") => {$url_0 | str index-of "#commit"}
             _ if ($url_0 | str contains "branch") and ($keepbranch == false) => {$url_0 | str index-of "#branch"}
             _ => { -1 }
        }

        $url_0 | str substring $index..$index_end | str replace "${pkgname}" $package | str replace "$pkgname" $package
}
def find_commit_from_package [package: string] {
        let file = ($"($package)/PKGBUILD")
        let pattern = (open $file | find "_commit=" | ansi strip | find "#source" --invert)
	if ($pattern | is-empty) {return}

        let pattern_0 = ($pattern | get 0)
        let index = ((($pattern | str index-of "=") | get 0) + 1)

        $pattern_0 | str substring $index..
}


def find_pkgrel_from_package [package: string] {
        let file = ($"($package)/PKGBUILD")
        let rel = (open $file | find "pkgrel=" | ansi strip | find "#pkgrel" --invert)
        let rel_0 = ($rel | get 0)

        $rel_0 | str substring 7..
}

export def find_package_latest_commit_upstream [package: string] {

    let commit = (find_commit_from_package $package)
	if ($commit | is-empty) {return ""}

	let url = (find_source_from_package $package --keepbranch true)
    print $url

	let upstream_commit = if ($url | $in =~ "#branch=") {
		let index = ($url | str index-of "#branch=")
		let branch = ($url | str substring ($index + 8)..)
        ($url | str substring 0..$index)        
		GIT_ASKPASS=echo git ls-remote ($url | str substring 0..$index) $branch
	} else {
		GIT_ASKPASS=echo git ls-remote $url HEAD
	}
    return ($upstream_commit | str substring 0..41)
}

export def chaotic-db-error-texts [] {
	return ['error: failed to prepare transaction (invalid or corrupted database)' 'error: failed retrieving file' 'error: could not open file /var/lib/pacman/sync/']
}
