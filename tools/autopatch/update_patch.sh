#!/bin/bash

set -euo pipefail

print_usage() { printf '
SYNOPSIS
   update_patch.sh -f PATCH_FILE [-v VERSION [-o OLD_VERSION] | -b PATCHSTR | -h]

DESCRIPTION
    Update the patch for Nvidia NVENC or NVFBC drivers for a new version

    -f PATCH_FILE               The file (patch.sh/patch-fbc.sh) that should be updated
    -v VERSION                  Driver version (by default copies latest existing patch)
    -o OLD_VERSION              Copy patch string from this older driver version
    -b PATCHSTR                 Append PATCHSTR to the patch_list
    -h                          Print help
'
}

opmode="copy"

while getopts 'hf:v:o:b:' flag; do
    case "${flag}" in
        f) patch_file="$OPTARG" ;;
        v) new_version="$OPTARG" ;;
        o) old_version="$OPTARG" ;;
        b) opmode="new" ; patch_string="$OPTARG" ;;
        h) opmode="help" ;;
        *) echo "Incorrect option specified in command line" ; exit 2 ;;
    esac
done


get_last_line() {
    if [[ -v old_version ]]; then
        # Find old patch line
        last=$(grep -n "\s.*\[\"$old_version\"\]='.*/g\?'" $patch_file | tail -1)
    else
        # Find the latest patch line
        last=$(grep -n "\s.*\[\".*\"\]='.*/g\?'" $patch_file | tail -1)
    fi
    echo $last
}

get_last_line_number() {
    last=$1

    # Find the line number to insert at
    line=$(cut -d : -f 1 <<<"$last")
    line=$((line + 1))

    echo $line
}

copy_patch() {
    last=$(get_last_line)
    line=$(get_last_line_number $last)

    # Use the same bytecode, and escape it
    bytecode=$(cut -d = -f 2 <<<"$last")
    bytecode=$(printf '%s\n' "$bytecode" | sed -e 's/[]\/$*.^[]/\\&/g');

    # Insert bytecode
    sed -i "${line} i \ \ \ \ [\"${new_version}\"]=${bytecode}" $patch_file

    echo "Successfully inserted bytecode for $new_version"
}

apply_new_patch() {
    line=$(get_last_line_number $(get_last_line))

    # Escape the patch string
    bytecode=$(printf '%s\n' "$patch_string" | sed -e 's/[]\/$*.^[]/\\&/g');

    # Insert it at the end
    sed -i "${line} i \ \ \ \ ${bytecode}" $patch_file

    echo "Successfully inserted $patch_string"
}

case "${opmode}" in
    help) print_usage ; exit 2 ;;
    copy) copy_patch ;;
    new) apply_new_patch ;;
    *) echo "Incorrect combination of flags. Use option -h to get help."
       exit 2 ;;
esac
