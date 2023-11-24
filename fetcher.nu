#!/run/current-system/sw/bin/env -S nu -n --no-std-lib

use ~/work-kde-git/lib.nu *

# INFO: Main function, shows help
export def main [] {
	run-external $"($env.CURRENT_FILE)" "--help"
}

# fetch a single package
export def "main pkg" [
	group: string # package group: kf6, plasma, apps
	pkg: string # package to fetch
    --dirname(-d): string # pkg dirname in case of being different from pkg
	--offline(-o)=false: bool # offline operation
    --transform(-t)=true: bool # transform PKGBUILDs
	--overwrite(-w)=false: bool # only new packages
    --reponame(-r): string # reponame
    --branch(-b)="main": string # branch
] {

	let _group_folder = (group_folder $group)
	if not ($_group_folder | path exists) {mkdir $_group_folder}

    let _reponame = if ($reponame | is-empty) {$pkg} else {$reponame}
	cd ($_group_folder)
	print $"main pkg ($group) ($pkg) --transform ($transform) --overwrite ($overwrite) --offline ($offline) --reponame ($_reponame)"
    
    if ($overwrite == false) {
        if not ($"($group)/($pkg)" | path exists) {

            if ($offline == false) {
                if not ($"($pkg)/.git" | path exists) {
                    run-external "git" "clone" $"https://gitlab.archlinux.org/archlinux/packaging/packages/($_reponame)" "-b" $"($branch)" $"($pkg)"
                } else {
                    cd $pkg
                        run-external "git" "reset" "--hard"
                        run-external "git" "pull"
                        cd ..
                }
            }

            if ($transform) {
                match $pkg {
                    "kquickcharts" => {format_quickcharts},
                        "kirigami" => {format_kirigami},
                        "kconfigwidgets" => {format_kconfigwidgets},
                        "kdeclarative" => {format_kdeclarative},
                        "kcompletion" => {format_kcompletion},
                        _ => {format_pkg $pkg}
                }
            }
        }
    }
}

# fetch all packages in file list
export def "main list" [
	group: string # package group: kf6, plasma, apps
	file: string # file with list of packages
    --pkg(-p): string # single package
	--overwrite(-w)=false: bool # only new packages
	--offline(-o)=false: bool # offline operation
] {
    let pkgs = if ($pkg | is-empty) {open -r $file | from yaml} else {open -r $file | from yaml | where name == $"($pkg)"}
    $pkgs | each {|l| 
        let _name = ($l | get name)
        let _transform = if ("transform" in ($l | columns)) {$l | get "transform"} else {false}
        let _reponame = if ("reponame" in ($l | columns)) {$l | get "reponame"} else {$_name}
        let _branch = if ("branch" in ($l | columns)) {$l | get "branch"} else {"main"}
        main pkg $group $_name --offline $offline --transform $_transform --overwrite $overwrite --reponame $_reponame --branch $_branch
    }
}


def format_pkg [pkg: string] {
	cd $pkg
	
	sed -i 's,kf5,kf6,g' PKGBUILD
	sed -i 's,qt5,qt6,g' PKGBUILD
	sed -i 's,kirigami2,kirigami,g' PKGBUILD
	#sed -i 's,patch,#patch,g' PKGBUILD
	sed -i '/^prepare() {/,/}/s,^,#,g' PKGBUILD
	#sed -i 's,source=.*,source=(git+https://github.com/KDE/${pkgname}),g' PKGBUILD
	sed -i 's,makedepends=(,makedepends=(git ,g' PKGBUILD
	sed -i 's,cmake -B build -S $pkgname-$pkgver,cmake -B build -S $pkgname,g' PKGBUILD
	sed -i 's,qt6-x11extras,,g' PKGBUILD
	
	if (open PKGBUILD | find "cmake -B build -S $pkgname" | find "QT6" | is-empty) {
		sed -i 's,cmake -B build -S $pkgname,cmake -B build -S $pkgname -DBUILD_WITH_QT6=ON -DQT_MAJOR_VERSION=6,g' PKGBUILD
	} 
		
	if (open PKGBUILD | find "source" | find ")" | is-empty) {
		sed -i '/^source=(/,/)/s,^,#,g' PKGBUILD
	} else {
		sed -i 's,^source=,#source,g' PKGBUILD
	}

	if (open PKGBUILD | find "sha256sums" | find ")" | is-empty) {
		sed -i '/^sha256sums=(/,/)/s,^,#,g' PKGBUILD
	} else {
		sed -i 's,^sha256sums=,#sha256sums,g' PKGBUILD
	}
	
	echo "\nsha256sums=('SKIP')\n" | save -a PKGBUILD
	open ~/work-kde-git/pkgver | save -a PKGBUILD
	open ~/work-kde-git/source | save -a PKGBUILD
	
	if (open PKGBUILD | find "validpgpkeys" | find ")" | is-empty) {
		sed -i '/^validpgpkeys=(/,/)/s,^,#,g' PKGBUILD
	} else {
		sed -i 's,^validpgpkeys=,#validpgpkeys=,g' PKGBUILD
	}
	
}

def format_quickcharts [pkg="kquickcharts": string] {
	format_pkg $pkg 
	cd $pkg
	sed -i 's,^depends=(,depends=(qt6-shadertools ,g' PKGBUILD
}

def format_kirigami [pkg="kirigami": string] {
	format_pkg $pkg 
	cd $pkg
	sed -i 's,^depends=.*,depends=(qt6-declarative qt6-shadertools),g' PKGBUILD
	sed -i 's,pkgname=kirigami2,pkgname=kirigami,g' PKGBUILD
}

def format_kcompletion [pkg="kcompletion": string] {
	format_pkg $pkg 
	cd $pkg
	sed -i 's,^depends=(,depends=(kcodecs ,g' PKGBUILD
}

def format_kdeclarative [pkg="kdeclarative": string] {
	format_pkg $pkg 
	cd $pkg
	sed -i 's,^depends=(,depends=(qt6-shadertools ,g' PKGBUILD
}




