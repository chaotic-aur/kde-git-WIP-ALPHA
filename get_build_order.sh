#!/usr/bin/env bash

# Usage: get_build_order.sh <pkg1> <pkg2> <pkg3> ...
# Prints the build order for the packages passed as arguments
# Assumes that the PKGBUILDs are stored in the directory of the package name

get_depends() {
    pkg="$1"
    pushd "$pkg" 1>/dev/null
    makepkg --printsrcinfo | grep -P "\tdepends = " | sed 's/\tdepends = //g' | sort | uniq
    popd 1>/dev/null
}

export -f get_depends

print_depend() {
    pkg="$1"
    DEPENDS=$(get_depends "$pkg")
    # print the dependencies in the correct order
    for dep in $DEPENDS; do
        echo "$dep $pkg"
    done
}
export -f print_depend

print_depends() {
    parallel -j $(nproc) print_depend ::: "$@"
}

FULL=$(print_depends "$@" | tsort)

# only print packages that appear in the list of packages passed as arguments
echo "$FULL" | grep -P "^($(echo "$@" | sed 's/ /|/g'))$"
