#!/bin/bash

set -euo pipefail

(( $# == 2 )) || {
    >&2 echo "Usage: $0 <version> <URL>"
    exit 2
}

MATCH_STR=feff85c04189c4
driver_version=$1
driver_url=$2
driver_file=NVIDIA-Linux-x86_64-$driver_version.run

download_driver() {
    wget -nv -c $driver_url -O $driver_file 1>&2
    chmod +x $driver_file
    >&2 echo "Successfully Downloaded Driver $driver_file"
}

extract_driver() {
    if [[ ! -e ${driver_file%".run"} ]]; then
        ./$driver_file -x
    fi
    >&2 echo "Successfully Extracted Driver $driver_file"
}

search_bytecode() {
    nvenc_file=${driver_file%".run"}/libnvidia-encode.so.$driver_version
    bytecode=$(xxd -c10000000 -ps $nvenc_file | grep -oP ".{0,6}$MATCH_STR")
    >&2 echo "Found bytecode $bytecode"
    echo $bytecode
}

get_patch_str() {
    bytecode=$1
    fixed=${bytecode:0:10}29${bytecode:(-8):8}
    bytecode=$(echo "$bytecode" | sed 's/../\\x&/g')
    fixed=$(echo "$fixed" | sed 's/../\\x&/g')
    echo "[\"$driver_version\"]='s/$bytecode/$fixed/g'"
}

mkdir -p temp
cd temp
download_driver
extract_driver
get_patch_str $(search_bytecode)
cd ..
