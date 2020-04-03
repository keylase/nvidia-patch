#!/bin/bash
# halt on any error for safety and proper pipe handling
set -euo pipefail ; # <- this semicolon and comment make options apply
# even when script is corrupt by CRLF line terminators (issue #75)
# empty line must follow this comment for immediate fail with CRLF newlines

backup_path="/opt/nvidia/libnvidia-fbc-backup"
silent_flag=''

print_usage() { printf '
SYNOPSIS
       patch-fbc.sh [-s] [-r|-h|-c VERSION|-l]

DESCRIPTION
       The patch for Nvidia drivers to allow FBC on consumer devices

       -s             Silent mode (No output)
       -r             Rollback to original (Restore lib from backup)
       -h             Print this help message
       -c VERSION     Check if version VERSION supported by this patch.
                      Returns true exit code (0) if version is supported.
       -l             List supported driver versions

'
}

# shellcheck disable=SC2209
opmode="patch"

while getopts 'rshc:l' flag; do
    case "${flag}" in
        r) opmode="${opmode}rollback" ;;
        s) silent_flag='true' ;;
        h) opmode="${opmode}help" ;;
        c) opmode="${opmode}checkversion" ; checked_version="$OPTARG" ;;
        l) opmode="${opmode}listversions" ;;
        *) echo "Incorrect option specified in command line" ; exit 2 ;;
    esac
done

if [[ $silent_flag ]]; then
    exec 1> /dev/null
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
)

check_version_supported () {
    local ver="$1"
    [[ "${patch_list[$ver]+isset}" && "${object_list[$ver]+isset}" ]]
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

    if ! driver_version=$("$NVIDIA_SMI" --query-gpu=driver_version --format=csv,noheader,nounits | head -n 1) ; then
        echo 'Something went wrong. Check nvidia driver'
        exit 1
    fi

    echo "Detected nvidia driver version: $driver_version"

    if ! check_version_supported "$driver_version" ; then
        echo "Patch for this ($driver_version) nvidia driver not found."
        echo "Patch is available for versions: "
        get_supported_versions
        exit 1
    fi

    patch="${patch_list[$driver_version]}"
    object="${object_list[$driver_version]}"

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
    if [[ -f "$backup_path/$object.$driver_version" ]]; then
        cp -p "$backup_path/$object.$driver_version" \
           "$driver_dir/$object.$driver_version"
        echo "Restore from backup $object.$driver_version"
    else
        echo "Backup not found. Try to patch first."
        exit 1
    fi
}

patch () {
    patch_common
    if [[ -f "$backup_path/$object.$driver_version" ]]; then
        bkp_hash="$(sha1sum "$backup_path/$object.$driver_version" | cut -f1 -d\ )"
        drv_hash="$(sha1sum "$driver_dir/$object.$driver_version" | cut -f1 -d\ )"
        if [[ "$bkp_hash" != "$drv_hash" ]] ; then
            echo "Backup exists and driver file differ from backup. Skipping patch."
            return 0
        fi
    else
        echo "Attention! Backup not found. Copying current $object to backup."
        mkdir -p "$backup_path"
        cp -p "$driver_dir/$object.$driver_version" \
           "$backup_path/$object.$driver_version"
    fi
    sha1sum "$backup_path/$object.$driver_version"
    sed "$patch" "$backup_path/$object.$driver_version" > \
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
