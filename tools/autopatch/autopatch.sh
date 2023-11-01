#!/bin/bash

set -euo pipefail

(( $# == 2 )) || {
    >&2 echo "Usage: $0 <patch-file.sh> <new-version>"
    exit 2
}

patch_file=$1
new_version=$2

if [[ ! -e $patch_file ]]; then
    >&2 echo "Patch file $patch_file not found"
    exit 2
fi

# Find the latest patch line
latest=$(grep -n "\s.*\[\".*\"\]='.*/g\?'" $patch_file | tail -1)

# Find the line number to insert at
line=$(cut -d : -f 1 <<<"$latest")
line=$((line + 1))

# Use the same bytecode, and escape it
bytecode=$(cut -d = -f 2 <<<"$latest")
bytecode=$(printf '%s\n' "$bytecode" | sed -e 's/[]\/$*.^[]/\\&/g');

# Insert bytecode
sed -i "${line} i \ \ \ \ [\"${new_version}\"]=${bytecode}" $patch_file
