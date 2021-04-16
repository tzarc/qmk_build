#!/bin/bash

set -e

abs_path() { python -c "import os,sys; print(os.path.realpath(sys.argv[1]))" "$1" ; }

this_script=$(abs_path "${BASH_SOURCE[@]}")
script_dir=$(dirname "$this_script")
qmk_firmware=$(abs_path "$script_dir/qmk_firmware")
qmk_builddir="$qmk_firmware/.build"
temp_makefile="$qmk_builddir/parallel_kb_builds.mk"

unset NO_CI
[[ "$1" == "noci" ]] && NO_CI="noci"

export PATH=/usr/lib/ccache:$PATH
MAKEFLAGS="-j$(( $(nproc) * 2 + 1 )) --output-sync --no-print-directory"

declare -A all_keyboards=()

get_default_folder() {
	local rulesmk="$1"
	cat "$rulesmk" | sed -e 's@#.*@@g' | grep -E '^\s*DEFAULT_FOLDER\s*=' | cut -d'=' -f2 | xargs echo
}

determine_keyboards() {
	pushd "$qmk_firmware" >/dev/null 2>&1
	for kb in $(./util/list_keyboards.sh ${NO_CI:-}) ; do
		kbpath="$kb"
		while [[ -f "keyboards/$kbpath/rules.mk" ]] && get_default_folder "keyboards/$kbpath/rules.mk" >/dev/null 2>&1 ; do
			default_folder=$(get_default_folder "keyboards/$kbpath/rules.mk")
			if [[ -n "$default_folder" ]] && [[ "$default_folder" != "$kbpath" ]] ; then
				kbpath="$default_folder"
			else
				break
			fi
		done
		all_keyboards[$kbpath]=1
	done
	popd >/dev/null 2>&1
}

dump_keyboard_list() {
	for kb in ${!all_keyboards[@]} ; do
		echo $kb
	done | grep -v 'handwired/pytest' | sort | uniq
}

generate_makefile() {
	pushd "$qmk_firmware" >/dev/null 2>&1
	truncate -s 0 "$temp_makefile"
	for kb in $(dump_keyboard_list) ; do
		safe=$(echo $kb | sed -e 's@/@_@g')
		buildfile="$qmk_builddir/build.log.${safe}"
		failfile="$qmk_builddir/failed.log.${safe}"
		cat << EOF >> "$temp_makefile"
all: ${safe}_binary
${safe}_binary:
	@rm -f "$failfile" || true
	@printf '^^keyboard=${kb}\n^^safe=${safe}\n' >"$buildfile"
	+@\$(MAKE) -C "$qmk_firmware" -f "$qmk_firmware/build_keyboard.mk" KEYBOARD="$kb" KEYMAP="default" REQUIRE_PLATFORM_KEY= COLOR=true SILENT=false \\
		>>"$buildfile" 2>&1 \\
		|| cp "$buildfile" "$failfile"
	@{ grep '\[ERRORS\]' "$buildfile" >/dev/null 2>&1 && printf "Build %-64s \e[1;31m[ERRORS]\e[0m\n" "${kb}:default" ; } \\
		|| { grep '\[WARNINGS\]' "$buildfile" >/dev/null 2>&1 && printf "Build %-64s \e[1;33m[WARNINGS]\e[0m\n" "${kb}:default" ; } \\
		|| printf "Build %-64s \e[1;32m[OK]\e[0m\n" "${kb}:default"
	@rm -f "$buildfile" || true
EOF
	done
	popd >/dev/null 2>&1
}

run_build() {
	time make -k $MAKEFLAGS -f "$temp_makefile" -k all | tee "$qmk_builddir/build.log"
}

[[ -d "$qmk_builddir" ]] || mkdir -p "$qmk_builddir"
determine_keyboards
generate_makefile
run_build