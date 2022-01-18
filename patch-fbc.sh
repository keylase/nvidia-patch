#!/bin/bash
# halt on any error for safety and proper pipe handling
set -euo pipefail ; # <- this semicolon and comment make options apply
# even when script is corrupt by CRLF line terminators (issue #75)
# empty line must follow this comment for immediate fail with CRLF newlines

backup_path="/opt/nvidia/libnvidia-fbc-backup"
silent_flag=''
manual_driver_version=''
flatpak_flag=''
backup_suffix=''

print_usage() { printf '
SYNOPSIS
       patch-fbc.sh [-s] [-r|-h|-c VERSION|-l|-f]

DESCRIPTION
       The patch for Nvidia drivers to allow FBC on consumer devices

       -s             Silent mode (No output)
       -r             Rollback to original (Restore lib from backup)
       -h             Print this help message
       -c VERSION     Check if version VERSION supported by this patch.
                      Returns true exit code (0) if version is supported.
       -l             List supported driver versions
       -d VERSION     Use VERSION driver version when looking for libraries
                      instead of using nvidia-smi to detect it.
       -f             Enable support for Flatpak NVIDIA drivers.
'
}

# shellcheck disable=SC2209
opmode="patch"

while getopts 'rshc:ld:f' flag; do
    case "${flag}" in
        r) opmode="${opmode}rollback" ;;
        s) silent_flag='true' ;;
        h) opmode="${opmode}help" ;;
        c) opmode="${opmode}checkversion" ; checked_version="$OPTARG" ;;
        l) opmode="${opmode}listversions" ;;
        d) manual_driver_version="$OPTARG" ;;
        f) flatpak_flag='true' ;;
        *) echo "Incorrect option specified in command line" ; exit 2 ;;
    esac
done

if [[ $silent_flag ]]; then
    exec 1> /dev/null
fi

if [[ $flatpak_flag ]]; then
    backup_suffix='.flatpak'
    echo "WARNING: Flatpak flag enabled (-f), modifying ONLY the Flatpak driver."
fi

declare -A patch_list=(
    ["435.27.08"]='s/\x85\xc0\x89\xc3\x0f\x85\x68\xfa\xff\xff/\x31\xc0\x89\xc3\x0f\x85\x68\xfa\xff\xff/'
    ["440.26"]='s/\x85\xc0\x89\xc3\x0f\x85\xa9\xfa\xff\xff/\x31\xc0\x89\xc3\x0f\x85\xa9\xfa\xff\xff/'
    ["440.31"]='s/\x85\xc0\x89\xc3\x0f\x85\xa9\xfa\xff\xff/\x31\xc0\x89\xc3\x0f\x85\xa9\xfa\xff\xff/'
    ["440.33.01"]='s/\x85\xc0\x89\xc3\x0f\x85\xa9\xfa\xff\xff/\x31\xc0\x89\xc3\x0f\x85\xa9\xfa\xff\xff/'
    ["440.36"]='s/\x85\xc0\x89\xc3\x0f\x85\xa9\xfa\xff\xff/\x31\xc0\x89\xc3\x0f\x85\xa9\xfa\xff\xff/'
    ["440.43.01"]='s/\x85\xc0\x89\xc3\x0f\x85\xa9\xfa\xff\xff/\x31\xc0\x89\xc3\x0f\x85\xa9\xfa\xff\xff/'
    ["440.44"]='s/\x85\xc0\x89\xc3\x0f\x85\xa9\xfa\xff\xff/\x31\xc0\x89\xc3\x0f\x85\xa9\xfa\xff\xff/'
    ["440.48.02"]='s/\x85\xc0\x89\xc3\x0f\x85\xa9\xfa\xff\xff/\x31\xc0\x89\xc3\x0f\x85\xa9\xfa\xff\xff/'
    ["440.58.01"]='s/\x85\xc0\x89\xc3\x0f\x85\xa9\xfa\xff\xff/\x31\xc0\x89\xc3\x0f\x85\xa9\xfa\xff\xff/'
    ["440.58.02"]='s/\x85\xc0\x89\xc3\x0f\x85\xa9\xfa\xff\xff/\x31\xc0\x89\xc3\x0f\x85\xa9\xfa\xff\xff/'
    ["440.59"]='s/\x85\xc0\x89\xc3\x0f\x85\xa9\xfa\xff\xff/\x31\xc0\x89\xc3\x0f\x85\xa9\xfa\xff\xff/'
    ["440.64"]='s/\x85\xc0\x89\xc3\x0f\x85\xa9\xfa\xff\xff/\x31\xc0\x89\xc3\x0f\x85\xa9\xfa\xff\xff/'
    ["440.64.00"]='s/\x85\xc0\x89\xc3\x0f\x85\xa9\xfa\xff\xff/\x31\xc0\x89\xc3\x0f\x85\xa9\xfa\xff\xff/'
    ["440.66.02"]='s/\x85\xc0\x89\xc3\x0f\x85\xa9\xfa\xff\xff/\x31\xc0\x89\xc3\x0f\x85\xa9\xfa\xff\xff/'
    ["440.66.03"]='s/\x85\xc0\x89\xc3\x0f\x85\xa9\xfa\xff\xff/\x31\xc0\x89\xc3\x0f\x85\xa9\xfa\xff\xff/'
    ["440.66.04"]='s/\x85\xc0\x89\xc3\x0f\x85\xa9\xfa\xff\xff/\x31\xc0\x89\xc3\x0f\x85\xa9\xfa\xff\xff/'
    ["440.66.08"]='s/\x85\xc0\x89\xc3\x0f\x85\xa9\xfa\xff\xff/\x31\xc0\x89\xc3\x0f\x85\xa9\xfa\xff\xff/'
    ["440.66.09"]='s/\x85\xc0\x89\xc3\x0f\x85\xa9\xfa\xff\xff/\x31\xc0\x89\xc3\x0f\x85\xa9\xfa\xff\xff/'
    ["440.66.11"]='s/\x85\xc0\x89\xc3\x0f\x85\xa9\xfa\xff\xff/\x31\xc0\x89\xc3\x0f\x85\xa9\xfa\xff\xff/'
    ["440.66.12"]='s/\x85\xc0\x89\xc3\x0f\x85\xa9\xfa\xff\xff/\x31\xc0\x89\xc3\x0f\x85\xa9\xfa\xff\xff/'
    ["440.66.14"]='s/\x85\xc0\x89\xc3\x0f\x85\xa9\xfa\xff\xff/\x31\xc0\x89\xc3\x0f\x85\xa9\xfa\xff\xff/'
    ["440.66.15"]='s/\x85\xc0\x89\xc3\x0f\x85\xa9\xfa\xff\xff/\x31\xc0\x89\xc3\x0f\x85\xa9\xfa\xff\xff/'
    ["440.66.17"]='s/\x85\xc0\x89\xc3\x0f\x85\xa9\xfa\xff\xff/\x31\xc0\x89\xc3\x0f\x85\xa9\xfa\xff\xff/'
    ["440.82"]='s/\x85\xc0\x89\xc3\x0f\x85\xa9\xfa\xff\xff/\x31\xc0\x89\xc3\x0f\x85\xa9\xfa\xff\xff/'
    ["440.95.01"]='s/\x85\xc0\x89\xc3\x0f\x85\xa9\xfa\xff\xff/\x31\xc0\x89\xc3\x0f\x85\xa9\xfa\xff\xff/'
    ["440.100"]='s/\x85\xc0\x89\xc3\x0f\x85\xa9\xfa\xff\xff/\x31\xc0\x89\xc3\x0f\x85\xa9\xfa\xff\xff/'
    ["440.118.02"]='s/\x85\xc0\x89\xc3\x0f\x85\xa9\xfa\xff\xff/\x31\xc0\x89\xc3\x0f\x85\xa9\xfa\xff\xff/'
    ["450.36.06"]='s/\x85\xc0\x89\xc3\x0f\x85\xa9\xfa\xff\xff/\x31\xc0\x89\xc3\x0f\x85\xa9\xfa\xff\xff/'
    ["450.51"]='s/\x85\xc0\x89\xc3\x0f\x85\xa9\xfa\xff\xff/\x31\xc0\x89\xc3\x0f\x85\xa9\xfa\xff\xff/'
    ["450.51.05"]='s/\x85\xc0\x89\xc3\x0f\x85\xa9\xfa\xff\xff/\x31\xc0\x89\xc3\x0f\x85\xa9\xfa\xff\xff/'
    ["450.51.06"]='s/\x85\xc0\x89\xc3\x0f\x85\xa9\xfa\xff\xff/\x31\xc0\x89\xc3\x0f\x85\xa9\xfa\xff\xff/'
    ["450.56.01"]='s/\x85\xc0\x89\xc3\x0f\x85\xa9\xfa\xff\xff/\x31\xc0\x89\xc3\x0f\x85\xa9\xfa\xff\xff/'
    ["450.56.02"]='s/\x85\xc0\x89\xc3\x0f\x85\xa9\xfa\xff\xff/\x31\xc0\x89\xc3\x0f\x85\xa9\xfa\xff\xff/'
    ["450.56.06"]='s/\x85\xc0\x89\xc3\x0f\x85\xa9\xfa\xff\xff/\x31\xc0\x89\xc3\x0f\x85\xa9\xfa\xff\xff/'
    ["450.56.11"]='s/\x85\xc0\x89\xc3\x0f\x85\xa9\xfa\xff\xff/\x31\xc0\x89\xc3\x0f\x85\xa9\xfa\xff\xff/'
    ["450.57"]='s/\x85\xc0\x89\xc3\x0f\x85\xa9\xfa\xff\xff/\x31\xc0\x89\xc3\x0f\x85\xa9\xfa\xff\xff/'
    ["450.66"]='s/\x85\xc0\x89\xc3\x0f\x85\xa9\xfa\xff\xff/\x31\xc0\x89\xc3\x0f\x85\xa9\xfa\xff\xff/'
    ["450.80.02"]='s/\x85\xc0\x89\xc3\x0f\x85\xa9\xfa\xff\xff/\x31\xc0\x89\xc3\x0f\x85\xa9\xfa\xff\xff/'
    ["455.23.04"]='s/\x83\xf8\x01\x0f\x84\x85/\x83\xf8\x69\x0f\x84\x85/'
    ["455.23.05"]='s/\x83\xf8\x01\x0f\x84\x85/\x83\xf8\x69\x0f\x84\x85/'
    ["455.26.01"]='s/\x83\xf8\x01\x0f\x84\x85/\x83\xf8\x69\x0f\x84\x85/'
    ["455.26.02"]='s/\x83\xf8\x01\x0f\x84\x85/\x83\xf8\x69\x0f\x84\x85/'
    ["455.28"]='s/\x83\xf8\x01\x0f\x84\x85/\x83\xf8\x69\x0f\x84\x85/'
    ["455.32.00"]='s/\x83\xf8\x01\x0f\x84\x85/\x83\xf8\x69\x0f\x84\x85/'
    ["455.38"]='s/\x83\xf8\x01\x0f\x84\x85/\x83\xf8\x69\x0f\x84\x85/'
    ["455.45.01"]='s/\x83\xf8\x01\x0f\x84\x85/\x83\xf8\x69\x0f\x84\x85/'
    ["455.46.01"]='s/\x83\xf8\x01\x0f\x84\x85/\x83\xf8\x69\x0f\x84\x85/'
    ["455.46.02"]='s/\x83\xf8\x01\x0f\x84\x83/\x83\xf8\x69\x0f\x84\x83/'
    ["455.46.04"]='s/\x83\xf8\x01\x0f\x84\x85/\x83\xf8\x69\x0f\x84\x85/'
    ["455.50.02"]='s/\x83\xf8\x01\x0f\x84\x85/\x83\xf8\x69\x0f\x84\x85/'
    ["455.50.03"]='s/\x83\xf8\x01\x0f\x84\x85/\x83\xf8\x69\x0f\x84\x85/'
    ["455.50.04"]='s/\x83\xf8\x01\x0f\x84\x85/\x83\xf8\x69\x0f\x84\x85/'
    ["455.50.05"]='s/\x83\xf8\x01\x0f\x84\x85/\x83\xf8\x69\x0f\x84\x85/'
    ["455.50.07"]='s/\x83\xf8\x01\x0f\x84\x85/\x83\xf8\x69\x0f\x84\x85/'
    ["455.50.10"]='s/\x83\xf8\x01\x0f\x84\x85/\x83\xf8\x69\x0f\x84\x85/'
    ["460.27.04"]='s/\x83\xfe\x01\x73\x08\x48/\x83\xfe\x00\x72\x08\x48/'
    ["460.32.03"]='s/\x83\xfe\x01\x73\x08\x48/\x83\xfe\x00\x72\x08\x48/'
    ["460.39"]='s/\x83\xfe\x01\x73\x08\x48/\x83\xfe\x00\x72\x08\x48/'
    ["460.56"]='s/\x83\xfe\x01\x73\x08\x48/\x83\xfe\x00\x72\x08\x48/'
    ["460.67"]='s/\x83\xfe\x01\x73\x08\x48/\x83\xfe\x00\x72\x08\x48/'
    ["460.73.01"]='s/\x83\xfe\x01\x73\x08\x48/\x83\xfe\x00\x72\x08\x48/'
    ["460.80"]='s/\x83\xfe\x01\x73\x08\x48/\x83\xfe\x00\x72\x08\x48/'
    ["460.84"]='s/\x83\xfe\x01\x73\x08\x48/\x83\xfe\x00\x72\x08\x48/'
    ["460.91.03"]='s/\x83\xfe\x01\x73\x08\x48/\x83\xfe\x00\x72\x08\x48/'
    ["465.19.01"]='s/\x83\xfe\x01\x73\x08\x48/\x83\xfe\x00\x72\x08\x48/'
    ["465.24.02"]='s/\x83\xfe\x01\x73\x08\x48/\x83\xfe\x00\x72\x08\x48/'
    ["465.27"]='s/\x83\xfe\x01\x73\x08\x48/\x83\xfe\x00\x72\x08\x48/'
    ["465.31"]='s/\x83\xfe\x01\x73\x08\x48/\x83\xfe\x00\x72\x08\x48/'
    ["470.42.01"]='s/\x83\xfe\x01\x73\x08\x48/\x83\xfe\x00\x72\x08\x48/'
    ["470.57.02"]='s/\x83\xfe\x01\x73\x08\x48/\x83\xfe\x00\x72\x08\x48/'
    ["470.62.02"]='s/\x83\xfe\x01\x73\x08\x48/\x83\xfe\x00\x72\x08\x48/'
    ["470.62.05"]='s/\x83\xfe\x01\x73\x08\x48/\x83\xfe\x00\x72\x08\x48/'
    ["470.63.01"]='s/\x83\xfe\x01\x73\x08\x48/\x83\xfe\x00\x72\x08\x48/'
    ["470.74"]='s/\x83\xfe\x01\x73\x08\x48/\x83\xfe\x00\x72\x08\x48/'
    ["470.82.00"]='s/\x83\xfe\x01\x73\x08\x48/\x83\xfe\x00\x72\x08\x48/'
    ["470.86"]='s/\x83\xfe\x01\x73\x08\x48/\x83\xfe\x00\x72\x08\x48/'
    ["470.94"]='s/\x83\xfe\x01\x73\x08\x48/\x83\xfe\x00\x72\x08\x48/'
    ["495.29.05"]='s/\x83\xfe\x01\x73\x08\x48/\x83\xfe\x00\x72\x08\x48/'
    ["495.44"]='s/\x83\xfe\x01\x73\x08\x48/\x83\xfe\x00\x72\x08\x48/'
    ["495.46"]='s/\x83\xfe\x01\x73\x08\x48/\x83\xfe\x00\x72\x08\x48/'
    ["510.39.01"]='s/\x83\xfe\x01\x73\x08\x48/\x83\xfe\x00\x72\x08\x48/'
)

declare -A object_list=(
    ["435.27.08"]='libnvidia-fbc.so'
    ["440.26"]='libnvidia-fbc.so'
    ["440.31"]='libnvidia-fbc.so'
    ["440.33.01"]='libnvidia-fbc.so'
    ["440.36"]='libnvidia-fbc.so'
    ["440.43.01"]='libnvidia-fbc.so'
    ["440.44"]='libnvidia-fbc.so'
    ["440.48.02"]='libnvidia-fbc.so'
    ["440.58.01"]='libnvidia-fbc.so'
    ["440.58.02"]='libnvidia-fbc.so'
    ["440.59"]='libnvidia-fbc.so'
    ["440.64"]='libnvidia-fbc.so'
    ["440.64.00"]='libnvidia-fbc.so'
    ["440.66.02"]='libnvidia-fbc.so'
    ["440.66.03"]='libnvidia-fbc.so'
    ["440.66.04"]='libnvidia-fbc.so'
    ["440.66.08"]='libnvidia-fbc.so'
    ["440.66.09"]='libnvidia-fbc.so'
    ["440.66.11"]='libnvidia-fbc.so'
    ["440.66.12"]='libnvidia-fbc.so'
    ["440.66.14"]='libnvidia-fbc.so'
    ["440.66.15"]='libnvidia-fbc.so'
    ["440.66.17"]='libnvidia-fbc.so'
    ["440.82"]='libnvidia-fbc.so'
    ["440.95.01"]='libnvidia-fbc.so'
    ["440.100"]='libnvidia-fbc.so'
    ["440.118.02"]='libnvidia-fbc.so'
    ["450.36.06"]='libnvidia-fbc.so'
    ["450.51"]='libnvidia-fbc.so'
    ["450.51.05"]='libnvidia-fbc.so'
    ["450.51.06"]='libnvidia-fbc.so'
    ["450.56.01"]='libnvidia-fbc.so'
    ["450.56.02"]='libnvidia-fbc.so'
    ["450.56.06"]='libnvidia-fbc.so'
    ["450.56.11"]='libnvidia-fbc.so'
    ["450.57"]='libnvidia-fbc.so'
    ["450.66"]='libnvidia-fbc.so'
    ["450.80.02"]='libnvidia-fbc.so'
    ["455.23.04"]='libnvidia-fbc.so'
    ["455.23.05"]='libnvidia-fbc.so'
    ["455.26.01"]='libnvidia-fbc.so'
    ["455.26.02"]='libnvidia-fbc.so'
    ["455.28"]='libnvidia-fbc.so'
    ["455.32.00"]='libnvidia-fbc.so'
    ["455.38"]='libnvidia-fbc.so'
    ["455.45.01"]='libnvidia-fbc.so'
    ["455.46.01"]='libnvidia-fbc.so'
    ["455.46.02"]='libnvidia-fbc.so'
    ["455.46.04"]='libnvidia-fbc.so'
    ["455.50.02"]='libnvidia-fbc.so'
    ["455.50.03"]='libnvidia-fbc.so'
    ["455.50.04"]='libnvidia-fbc.so'
    ["455.50.05"]='libnvidia-fbc.so'
    ["455.50.07"]='libnvidia-fbc.so'
    ["455.50.10"]='libnvidia-fbc.so'
    ["460.27.04"]='libnvidia-fbc.so'
    ["460.32.03"]='libnvidia-fbc.so'
    ["460.39"]='libnvidia-fbc.so'
    ["460.56"]='libnvidia-fbc.so'
    ["460.67"]='libnvidia-fbc.so'
    ["460.73.01"]='libnvidia-fbc.so'
    ["460.80"]='libnvidia-fbc.so'
    ["460.84"]='libnvidia-fbc.so'
    ["460.91.03"]='libnvidia-fbc.so'
    ["465.19.01"]='libnvidia-fbc.so'
    ["465.24.02"]='libnvidia-fbc.so'
    ["465.27"]='libnvidia-fbc.so'
    ["465.31"]='libnvidia-fbc.so'
    ["470.42.01"]='libnvidia-fbc.so'
    ["470.57.02"]='libnvidia-fbc.so'
    ["470.62.02"]='libnvidia-fbc.so'
    ["470.62.05"]='libnvidia-fbc.so'
    ["470.63.01"]='libnvidia-fbc.so'
    ["470.74"]='libnvidia-fbc.so'
    ["470.82.00"]='libnvidia-fbc.so'
    ["470.86"]='libnvidia-fbc.so'
    ["470.94"]='libnvidia-fbc.so'
    ["495.29.05"]='libnvidia-fbc.so'
    ["495.44"]='libnvidia-fbc.so'
    ["495.46"]='libnvidia-fbc.so'
    ["510.39.01"]='libnvidia-fbc.so'
)

check_version_supported () {
    local ver="$1"
    [[ "${patch_list[$ver]+isset}" && "${object_list[$ver]+isset}" ]]
}

get_flatpak_driver_path () {
    # Flatpak's package versioning replaces '.' by '-'
    version="$(echo "$1" | tr '.' '-')"
    if path=$(flatpak info --show-location "org.freedesktop.Platform.GL.nvidia-${version}" 2>/dev/null); then
        echo "$path/files/lib"
    fi
}

get_supported_versions () {
    for drv in "${!patch_list[@]}"; do
        [[ "${object_list[$drv]+isset}" ]] && echo "$drv"
    done | sort -t. -n
    return 0
}

patch_common () {
    NVIDIA_SMI="$(command -v nvidia-smi || true)"
    if [[ ! "$NVIDIA_SMI" ]] ; then
        echo 'nvidia-smi utility not found. Probably driver is not installed.'
        exit 1
    fi

    if [[ "$manual_driver_version" ]]; then
        driver_version="$manual_driver_version"

        echo "Using manually entered nvidia driver version: $driver_version"
    else
        cmd="$NVIDIA_SMI --query-gpu=driver_version --format=csv,noheader,nounits"
        driver_versions_list=$($cmd) || (
            ret_code=$?
            echo "Can not detect nvidia driver version."
            echo "CMD: \"$cmd\""
            echo "Result: \"$driver_versions_list\""
            echo "nvidia-smi retcode: $ret_code"
            exit 1
        )
        driver_version=$(echo "$driver_versions_list" | head -n 1)

        echo "Detected nvidia driver version: $driver_version"
    fi

    if ! check_version_supported "$driver_version" ; then
        echo "Patch for this ($driver_version) nvidia driver not found."
        echo "Patch is available for versions: "
        get_supported_versions
        exit 1
    fi

    patch="${patch_list[$driver_version]}"
    object="${object_list[$driver_version]}"

    if [[ $flatpak_flag ]]; then
        driver_dir=$(get_flatpak_driver_path "$driver_version")
        if [ -z "$driver_dir" ]; then
            echo "ERROR: Flatpak package for driver $driver_version does not appear to be installed."
            echo "Try rebooting your computer and/or running 'flatpak update'."
            exit 1
        fi
        # return early because the code below is out of scope for the Flatpak driver
        return 0
    fi

    declare -a driver_locations=(
        '/usr/lib/x86_64-linux-gnu'
        '/usr/lib/x86_64-linux-gnu/nvidia/current/'
        '/usr/lib64'
        "/usr/lib/nvidia-${driver_version%%.*}"
    )

    dir_found=''
    for driver_dir in "${driver_locations[@]}" ; do
        if [[ -e "$driver_dir/$object.$driver_version" ]]; then
            dir_found='true'
            break
        fi
    done

    [[ "$dir_found" ]] || { echo "ERROR: cannot detect driver directory"; exit 1; }

}

rollback () {
    patch_common
    if [[ -f "$backup_path/$object.$driver_version$backup_suffix" ]]; then
        cp -p "$backup_path/$object.$driver_version$backup_suffix" \
           "$driver_dir/$object.$driver_version"
        echo "Restore from backup $object.$driver_version$backup_suffix"
    else
        echo "Backup not found. Try to patch first."
        exit 1
    fi
}

patch () {
    patch_common
    if [[ -f "$backup_path/$object.$driver_version$backup_suffix" ]]; then
        bkp_hash="$(sha1sum "$backup_path/$object.$driver_version$backup_suffix" | cut -f1 -d\ )"
        drv_hash="$(sha1sum "$driver_dir/$object.$driver_version" | cut -f1 -d\ )"
        if [[ "$bkp_hash" != "$drv_hash" ]] ; then
            echo "Backup exists and driver file differ from backup. Skipping patch."
            return 0
        fi
    else
        echo "Attention! Backup not found. Copying current $object to backup."
        mkdir -p "$backup_path"
        cp -p "$driver_dir/$object.$driver_version" \
           "$backup_path/$object.$driver_version$backup_suffix"
    fi
    sha1sum "$backup_path/$object.$driver_version$backup_suffix"
    sed "$patch" "$backup_path/$object.$driver_version$backup_suffix" > \
      "${PATCH_OUTPUT_DIR-$driver_dir}/$object.$driver_version"
    sha1sum "${PATCH_OUTPUT_DIR-$driver_dir}/$object.$driver_version"
    ldconfig
    echo "Patched!"
}

query_version_support () {
    if check_version_supported "$checked_version" ; then
        echo "SUPPORTED"
        exit 0
    else
        echo "NOT SUPPORTED"
        exit 1
    fi
}

list_supported_versions () {
    get_supported_versions
}

case "${opmode}" in
    patch) patch ;;
    patchrollback) rollback ;;
    patchhelp) print_usage ; exit 2 ;;
    patchcheckversion) query_version_support ;;
    patchlistversions) list_supported_versions ;;
    *) echo "Incorrect combination of flags. Use option -h to get help."
       exit 2 ;;
esac
