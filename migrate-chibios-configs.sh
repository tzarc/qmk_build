#!/bin/bash

umask 022

set -eEuo pipefail
this_script="$(realpath "${BASH_SOURCE[0]}")"
script_dir="$(realpath "$(dirname "$this_script")")"
qmk_firmware_dir="$(realpath "$script_dir/qmk_firmware/")" # change this once moved to util
validation_output="$script_dir/validation-output"

source_branch="master"
branch_under_test="generated-chibios-conf-migrations"

export PATH=/home/nickb/gcc-arm/gcc-arm-none-eabi-8-2018-q4-major/bin:$PATH

[[ -d "$validation_output" ]] || mkdir -p "$validation_output"
echo -n >"$validation_output/upgrade.log"

fail_build() {
    touch "$validation_output/.failed"
}

is_failed() {
    if [[ -f "$validation_output/.failed" ]] ; then
        return 0
    fi
    return 1
}

clear_failure() {
    if [[ -f "$validation_output/.failed" ]] ; then
        rm -f "$validation_output/.failed"
    fi
}

pcmd() {
    echo -e "\e[38;5;203mExecuting:\e[38;5;131m $@\e[0m" >&2
    "$@"
}

append_log() {
    cat - | sed -r 's/\x1B\[[0-9;]*[JKmsu]//g' >> "$validation_output/upgrade.log"
}

hard_reset() {
    local repo_upstream=$1
    local repo_name=$2
    local repo_branch=${3:-master}
    pcmd git rebase --abort || true
    pcmd git merge --abort || true
    pcmd git clean -xfd
    pcmd git checkout -- .
    pcmd git reset --hard
    pcmd git remote set-url origin git@github.com:tzarc/$repo_name.git
    pcmd git remote set-url origin --push git@github.com:tzarc/$repo_name.git
    pcmd git remote set-url upstream https://github.com/$repo_upstream/$repo_name.git
    pcmd git remote set-url upstream --push git@github.com:tzarc/$repo_name.git
    pcmd git fetch --all --tags --prune
    pcmd git fetch upstream || true
    pcmd git checkout -f $repo_branch
    pcmd git reset --hard upstream/$repo_branch  \
        && pcmd git push origin $repo_branch --force-with-lease \
        || pcmd git reset --hard $repo_branch
}

preconfigure_branch() {
    pushd "$qmk_firmware_dir" >/dev/null 2>&1
    hard_reset qmk qmk_firmware $source_branch
    pcmd make git-submodule
    pcmd git branch -D $branch_under_test || true
    pcmd git checkout -b $branch_under_test
    popd >/dev/null 2>&1
}

build_single() {
    local build_target=$1
    local build_stage=$2
    local extraflags=${3:-}

    make distclean 2>&1 | append_log
    local binary_basename="$(make ${build_target}:default:dump_vars COMMAND_ENABLE=no SKIP_VERSION=yes SKIP_GIT=yes ${extraflags:-} | grep -P '^TARGET=' | cut -d'=' -f2)"
    make ${build_target}:default:dump_vars COMMAND_ENABLE=no SKIP_VERSION=yes SKIP_GIT=yes ${extraflags:-} 2>&1 > "${validation_output}/${binary_basename}_${build_stage}_vars.txt"
    { make -j$(nproc) ${build_target}:default COMMAND_ENABLE=no SKIP_VERSION=yes SKIP_GIT=yes ${extraflags:-} 2>&1 || true ; } | append_log
    cat ".build/obj_${binary_basename}/cflags.txt" | sed -e 's/ /\n/g' > "$validation_output/${binary_basename}_${build_stage}_cflags.txt"
    [[ ! -d "$validation_output/${binary_basename}_${build_stage}_build" ]] \
        || rm -rf "$validation_output/${binary_basename}_${build_stage}_build"
    mv ".build" "$validation_output/${binary_basename}_${build_stage}_build"
    find "$validation_output/${binary_basename}_${build_stage}_build" -name '*.lst' -exec sed -i 's#/tmp/cc......\.s#/tmp/ccTEMPFL.s#g' '{}' +
    arm-none-eabi-objdump -S "$validation_output/${binary_basename}_${build_stage}_build/${binary_basename}.elf" \
        > "$validation_output/${binary_basename}_${build_stage}_asm.txt"
    [[ -e "${binary_basename}.bin" ]] || { fail_build ; return 1 ; }
    sha1sum "${binary_basename}.bin" | awk '{print $1}'
}

validate_build() {
    local build_target=$1
    local extraflags=${2:-}

    clear_failure
    pushd "$qmk_firmware_dir" >/dev/null 2>&1

    git clean -xfd >/dev/null 2>&1
    git checkout -- . >/dev/null 2>&1
    git checkout $source_branch >/dev/null 2>&1
    ./util/chibios_conf_updater.sh >/dev/null 2>&1
    disable_chconf_extras >/dev/null 2>&1

    # Run any pre-build function if it exists
    local prebuild_cmd="prebuild_$(echo $keyboard | tr '/' '_')"
    if type "$prebuild_cmd" >/dev/null 2>&1 ; then
        "$prebuild_cmd"
    fi

    local before="$(build_single "$build_target" before ${extraflags:-})"

    git clean -xfd >/dev/null 2>&1
    git checkout -- . >/dev/null 2>&1
    git checkout $branch_under_test >/dev/null 2>&1

    # Run any pre-build function if it exists
    local prebuild_cmd="prebuild_$(echo $keyboard | tr '/' '_')"
    if type "$prebuild_cmd" >/dev/null 2>&1 ; then
        "$prebuild_cmd"
    fi

    local after="$(build_single "$build_target" after ${extraflags:-})"

    if [[ "$before" == "$after" ]] ; then
        printf '\e[1;32m%50s - %s\e[0m\n' "$build_target" "$before"
        local binary_basename="$(make ${build_target}:default:dump_vars COMMAND_ENABLE=no SKIP_VERSION=yes SKIP_GIT=yes ${extraflags:-} | grep -P '^TARGET=' | cut -d'=' -f2)"
        rm -rf "$validation_output/"${binary_basename}*
    else
        printf '\e[1;31m%50s - %s != %s\e[0m\n' "$build_target" "$before" "$after"
        fail_build
    fi

    popd >/dev/null 2>&1
}

disable_chconf_extras() {
    for chconf in $(find "$script_dir/qmk_firmware/platforms" "$script_dir/qmk_firmware/keyboards" -name chconf.h) ; do
        cat "$chconf" \
            | sed \
                -e 's@#define CH_CFG_USE_OBJ_CACHES               TRUE@#define CH_CFG_USE_OBJ_CACHES               FALSE@g' \
                -e 's@#define CH_CFG_USE_DELEGATES                TRUE@#define CH_CFG_USE_DELEGATES                FALSE@g' \
                -e 's@#define CH_CFG_USE_JOBS                     TRUE@#define CH_CFG_USE_JOBS                     FALSE@g' \
            > "${chconf}.new"
        mv "${chconf}.new" "${chconf}"
    done
}

upgrade_one_keyboard() {
    local builds=()
    local before_hash=()
    local after_hash=()
    local keyboard
    local chibios_board
    local ignore_checksum_mismatch
    local force_upgrade
    local no_mcuconf
    local keep_output_files

    while [[ ! -z "${1:-}" ]] ; do
        case "${1:-}" in
            --force)
                force_upgrade=1
                ;;
            --no-mcuconf)
                no_mcuconf=1
                ;;
            --keyboard)
                shift
                keyboard="$1"
                ;;
            --chibios-board)
                shift
                chibios_board="$1"
                ;;
            --ignore-checksum)
                shift
                ignore_checksum_mismatch="$1"
                ;;
            --keep-output)
                keep_output_files=1
                ;;
            *)
                builds+=($1)
                ;;
        esac
        shift
    done

    if [[ "${#builds[@]}" -eq 0 ]] ; then
        builds+=($keyboard)
    fi

    pushd "$qmk_firmware_dir" >/dev/null 2>&1
    git checkout $branch_under_test >/dev/null 2>&1
    git clean -xfd >/dev/null 2>&1
    git reset --hard >/dev/null 2>&1
    git checkout -- . >/dev/null 2>&1

    disable_chconf_extras

    # Run any pre-migration function if it exists
    local premigrate_cmd="premigrate_$(echo $keyboard | tr '/' '_')"
    if type "$premigrate_cmd" >/dev/null 2>&1 ; then
        "$premigrate_cmd"
    fi

    if [[ -d "$qmk_firmware_dir/keyboards/$keyboard/boards" ]] ; then
        pushd "$qmk_firmware_dir" >/dev/null 2>&1
        git rm -rf keyboards/$keyboard/boards >/dev/null 2>&1
        popd >/dev/null 2>&1
    fi

    if [[ -f "keyboards/$keyboard/chconf.h" ]] && { [[ ! -z "${force_upgrade:-}" ]] || [[ -z "$(grep 'include_next' "keyboards/$keyboard/chconf.h" 2>/dev/null || true)" ]] ; } ; then
        echo "-------------------------------------------------------------------------" | append_log
        echo "-- $keyboard : migrating chconf.h" | append_log
        echo "-------------------------------------------------------------------------" | append_log
        local chconf_path="platforms/chibios/common/configs/chconf.h"
        [[ ! -f "platforms/chibios/$chibios_board/configs/chconf.h" ]] || chconf_path="platforms/chibios/$chibios_board/configs/chconf.h"
        ./bin/qmk chibios-confmigrate -o -d -i keyboards/$keyboard/chconf.h -r $chconf_path -f 2>&1 | append_log
    fi

    if [[ -f "keyboards/$keyboard/halconf.h" ]] && { [[ ! -z "${force_upgrade:-}" ]] || [[ -z "$(grep 'include_next' "keyboards/$keyboard/halconf.h" 2>/dev/null || true)" ]] ; } ; then
        echo "-------------------------------------------------------------------------" | append_log
        echo "-- $keyboard : migrating halconf.h" | append_log
        echo "-------------------------------------------------------------------------" | append_log
        local halconf_path="platforms/chibios/common/configs/halconf.h"
        [[ ! -f "platforms/chibios/$chibios_board/configs/halconf.h" ]] || halconf_path="platforms/chibios/$chibios_board/configs/halconf.h"
        ./bin/qmk chibios-confmigrate -o -d -i keyboards/$keyboard/halconf.h -r $halconf_path -f 2>&1 | append_log
    fi

    if [[ -z "${no_mcuconf:-}" ]] && [[ -f "keyboards/$keyboard/mcuconf.h" ]] && { [[ ! -z "${force_upgrade:-}" ]] || [[ -z "$(grep 'include_next' "keyboards/$keyboard/mcuconf.h" 2>/dev/null || true)" ]] ; } ; then
        echo "-------------------------------------------------------------------------" | append_log
        echo "-- $keyboard : migrating mcuconf.h" | append_log
        echo "-------------------------------------------------------------------------" | append_log
        ./bin/qmk chibios-confmigrate -o -d -i keyboards/$keyboard/mcuconf.h -r platforms/chibios/$chibios_board/configs/mcuconf.h -f 2>&1 | append_log
    fi

    # Fixup the 'BOARD = ...' line in rules.mk
    if [[ -e keyboards/$keyboard/rules.mk ]] ; then
        if [[ ! -z "$(grep -E '^BOARD\s*=' keyboards/$keyboard/rules.mk)" ]] ; then
            # Fixup existing BOARD variable
            sed -i "s@^BOARD\s*=\s*.*@BOARD = $chibios_board@g" keyboards/$keyboard/rules.mk
        else
            # Add new BOARD variable after MCU
            sed -i "/^MCU\s*=.*/a BOARD = $chibios_board" keyboards/$keyboard/rules.mk
        fi
    fi
    for build in ${builds[@]} ; do
        if [[ -e keyboards/$build/rules.mk ]] ; then
            sed -i "s@^BOARD\s*=\s*.*@BOARD = $chibios_board@g" keyboards/$build/rules.mk
        fi
    done

    # Run any post-migration function if it exists
    local postmigrate_cmd="postmigrate_$(echo $keyboard | tr '/' '_')"
    if type "$postmigrate_cmd" >/dev/null 2>&1 ; then
        "$postmigrate_cmd"
    fi

    local commit_message="ChibiOS conf upgrade for $keyboard"$'\n'""
    git add -A
    if git commit -qm "$commit_message" >/dev/null 2>&1 ; then
        for build in ${builds[@]} ; do
            output=$(validate_build $build)
            echo -e "$output"
            commit_message="${commit_message}"$'\n'"$(echo -e ${output} | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g")"
        done

        if is_failed && [[ -z "${ignore_checksum_mismatch:-}" ]] ; then
            echo "Failed... Press enter to continue"
            read dummy
            clear_failure
            git reset --hard ${branch_under_test}^
        else
            if [[ ! -z "${ignore_checksum_mismatch:-}" ]] ; then
                commit_message="${commit_message}"$'\n'""$'\n'"Checksum mismatch ignored:"$'\n'"${ignore_checksum_mismatch}"
            fi
            git commit --amend -qm "$commit_message" || true
        fi
    fi

    popd >/dev/null 2>&1
}

prebuild_geminate60() {
    pushd "$qmk_firmware_dir" >/dev/null 2>&1
    # Add new BOARD variable after MCU
    sed -i "/^MCU\s*=.*/a BOARD = $chibios_board" keyboards/$keyboard/rules.mk
    popd >/dev/null 2>&1
}

postmigrate_chavdai40() {
    pushd "$qmk_firmware_dir" >/dev/null 2>&1
    popd >/dev/null 2>&1
}

upgrade_all_keyboards()  {
#    pushd "$qmk_firmware_dir" >/dev/null 2>&1
#    for kb in $(./util/list_keyboards.sh | sort) ; do
#        local vars=$(make ${kb}:default:dump_vars)
#        if [[ "$(echo "$vars" | grep '^PLATFORM_KEY=' | cut -d'=' -f2)" == "chibios" ]] ; then
#            local board=$(echo "$vars" | grep '^BOARD=' | cut -d'=' -f2)
#            upgrade_one_keyboard --keyboard $kb --chibios-board $board --no-mcuconf --force
#        fi
#    done
#    popd >/dev/null 2>&1

    upgrade_one_keyboard --keyboard boston --chibios-board GENERIC_STM32_F072XB

    #upgrade_one_keyboard --keyboard geminate60 --chibios-board QMK_PROTON_C
    #upgrade_one_keyboard --keyboard sowbug/68keys --chibios-board STM32_F103_STM32DUINO
    #upgrade_one_keyboard --keyboard sowbug/ansi_tkl --chibios-board STM32_F103_STM32DUINO
    #upgrade_one_keyboard --keyboard chavdai40 --chibios-board ST_NUCLEO32_F042K6 --no-mcuconf chavdai40/rev1 chavdai40/rev2
    #upgrade_one_keyboard --keyboard ergodox_stm32 --chibios-board ST_NUCLEO64_F103RB --no-mcuconf
    #upgrade_one_keyboard --keyboard jm60 --chibios-board ST_NUCLEO64_F103RB --no-mcuconf
    #upgrade_one_keyboard --keyboard matrix/m20add --chibios-board ST_NUCLEO64_F411RE --no-mcuconf
    #upgrade_one_keyboard --keyboard matrix/noah --chibios-board ST_NUCLEO64_F411RE --no-mcuconf
    :
}

leftover_chconf() {
    pushd "$qmk_firmware_dir" >/dev/null 2>&1
    for file in $(find keyboards/ -name 'chconf.h') ; do
        if [[ -z "$(grep include_next "$file")" ]] ; then
            echo $file | sed -e 's#keyboards/##g' -e 's#/chconf.h##g'
        fi
    done | sort | uniq
    popd >/dev/null 2>&1
}

leftover_halconf() {
    pushd "$qmk_firmware_dir" >/dev/null 2>&1
    for file in $(find keyboards/ -name 'halconf.h') ; do
        if [[ -z "$(grep include_next "$file")" ]] ; then
            echo $file | sed -e 's#keyboards/##g' -e 's#/halconf.h##g'
        fi
    done | sort | uniq
    popd >/dev/null 2>&1
}

leftover_mcuconf() {
    pushd "$qmk_firmware_dir" >/dev/null 2>&1
    for file in $(find keyboards/ -name 'mcuconf.h') ; do
        if [[ -z "$(grep include_next "$file")" ]] ; then
            echo $file | sed -e 's#keyboards/##g' -e 's#/mcuconf.h##g'
        fi
    done | sort | uniq
    popd >/dev/null 2>&1
}

leftover_boardh() {
    pushd "$qmk_firmware_dir" >/dev/null 2>&1
    for file in $(find keyboards/ -name 'board.h') ; do
        if [[ -z "$(grep include_next "$file")" ]] ; then
            echo $file | sed -e 's#keyboards/##g' -e 's#/boards/[^/]\+/board.h##g'
        fi
    done | sort | uniq
    popd >/dev/null 2>&1
}

leftover_boards() {
    { leftover_chconf ; leftover_halconf ; } | sort | uniq
    # { leftover_chconf ; leftover_halconf ; leftover_boardh ; } | sort | uniq
}

print_leftovers() {
    local leftovers=$(leftover_boards)
    local count=$(echo "$leftovers" | wc -l)
    if [[ -z "$leftovers" ]] ; then count=0 ; fi

    echo -e "\e[1;35m$(echo "$leftovers" | wc -l) boards outstanding:\e[0m"
    for leftover in $leftovers ; do
        pushd "$qmk_firmware_dir" >/dev/null 2>&1
        echo "$leftover: $(make $leftover:default:dump_vars | grep '^BOARD=')"
        popd >/dev/null 2>&1
    done
}

preconfigure_branch
upgrade_all_keyboards
print_leftovers
