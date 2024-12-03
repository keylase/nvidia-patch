#!/bin/bash
# halt on any error for safety and proper pipe handling
set -euo pipefail ; # <- this semicolon and comment make options apply
# even when script is corrupt by CRLF line terminators (issue #75)
# empty line must follow this comment for immediate fail with CRLF newlines

# root check
if [ "$(id -u)" -ne 0 ]; then
  echo
  echo -e "Please run as root!"
  echo
  exit 1
fi


backup_path="/opt/nvidia/libnvidia-eglcore-backup"
silent_flag=''
manual_driver_version=''
flatpak_flag=''
backup_suffix=''

print_usage() { printf '
SYNOPSIS
       patch-vk.sh [-s] [-r|-h|-c VERSION|-l|-f]

DESCRIPTION
       The patch for Nvidia vulkan drivers to remove NVENC session limit

       -s             Silent mode (No output)
       -r             Rollback to original (Restore lib from backup)
       -h             Print this help message
       -c VERSION     Check if version VERSION supported by this patch.
                      Returns true exit code (0) if version is supported.
       -l             List supported driver versions
       -d VERSION     Use VERSION driver version when looking for libraries
                      instead of using nvidia-smi to detect it.
       -j             Output the patch list to stdout as JSON
'
}

# shellcheck disable=SC2209
opmode="patch"

while getopts 'rshjc:ld:' flag; do
    case "${flag}" in
        r) opmode="${opmode}rollback" ;;
        s) silent_flag='true' ;;
        h) opmode="${opmode}help" ;;
        c) opmode="${opmode}checkversion" ; checked_version="$OPTARG" ;;
        l) opmode="${opmode}listversions" ;;
        d) manual_driver_version="$OPTARG" ;;
        j) opmode="dump" ;;
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
    ["555.42.02"]='s/\x53\x89\xf3\x41\xb9\x04\x00\x00\x00\x48\x83\xec\x10/\x48\xc7\xc0\x01\x00\x00\x00\xc3\xc3\xc3\xc3\xc3\xc3/g'
    ["555.58"]='s/\x53\x89\xf3\x41\xb9\x04\x00\x00\x00\x48\x83\xec\x10/\x48\xc7\xc0\x01\x00\x00\x00\xc3\xc3\xc3\xc3\xc3\xc3/g'
    ["555.58.02"]='s/\x53\x89\xf3\x41\xb9\x04\x00\x00\x00\x48\x83\xec\x10/\x48\xc7\xc0\x01\x00\x00\x00\xc3\xc3\xc3\xc3\xc3\xc3/g'
    ["560.35.03"]='s/\x53\x89\xf3\x41\xb9\x04\x00\x00\x00\x48\x83\xec\x10/\x48\xc7\xc0\x01\x00\x00\x00\xc3\xc3\xc3\xc3\xc3\xc3/g'
    ["560.28.03"]='s/\x53\x89\xf3\x41\xb9\x04\x00\x00\x00\x48\x83\xec\x10/\x48\xc7\xc0\x01\x00\x00\x00\xc3\xc3\xc3\xc3\xc3\xc3/g'
    ["565.57.01"]='s/\x53\x89\xf3\x41\xb9\x04\x00\x00\x00\x48\x83\xec\x10/\x48\xc7\xc0\x01\x00\x00\x00\xc3\xc3\xc3\xc3\xc3\xc3/g'
)

check_version_supported () {
    local ver="$1"
    [[ "${patch_list[$ver]+isset}" ]]
}

# get_flatpak_driver_path () {
#     # Flatpak's package versioning replaces '.' by '-'
#     version="$(echo "$1" | tr '.' '-')"
#     # Attempts to patch system flatpak
#     if path=$(flatpak info --show-location "org.freedesktop.Platform.GL.nvidia-${version}" 2>/dev/null); then
#         echo "$path/files/lib"
#     # If it isn't found will login as the user that envoked sudo & patch this version
#     elif path=$(su -c - ${SUDO_USER} 'flatpak info --show-location "org.freedesktop.Platform.GL.nvidia-'${version}'"'); then
#         echo "$path/files/lib"
#     fi
# }

get_supported_versions () {
    for drv in "${!patch_list[@]}"; do
        echo "$drv"
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
    driver_maj_version=${driver_version%%.*}
    object='libnvidia-eglcore.so'
    echo $object

    # if [[ $flatpak_flag ]]; then
    #     driver_dir=$(get_flatpak_driver_path "$driver_version")
    #     if [ -z "$driver_dir" ]; then
    #         echo "ERROR: Flatpak package for driver $driver_version does not appear to be installed."
    #         echo "Try rebooting your computer and/or running 'flatpak update'."
    #         exit 1
    #     fi
    #     # return early because the code below is out of scope for the Flatpak driver
    #     return 0
    # fi

    declare -a driver_locations=(
        '/usr/lib/x86_64-linux-gnu'
        '/usr/lib/x86_64-linux-gnu/nvidia/current/'
        '/usr/lib/x86_64-linux-gnu/nvidia/tesla/'
        "/usr/lib/x86_64-linux-gnu/nvidia/tesla-${driver_version%%.*}/"
        '/usr/lib64'
        '/usr/lib'
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

ensure_bytes_are_valid () {
    driver_file="$driver_dir/$object.$driver_version"
    original_bytes=$(awk -F / '$2 { print $2 }' <<< "$patch")
    patched_bytes=$(awk -F / '$3 { print $3 }' <<< "$patch")
    if LC_ALL=C grep -qaP "$original_bytes" "$driver_file"; then
        printf "Bytes to patch: %s\n" "$original_bytes"
        return 0 # file is ready to be patched
    fi
    if LC_ALL=C grep -qaP "$patched_bytes" "$driver_file"; then
        echo "Warn: Bytes '$patched_bytes' already present in '$driver_file'."
        return 0 # file is likely patched already
    fi
    echo "Error: Could not find bytes '$original_bytes' to patch in '$driver_file'."
    exit 1
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
    ensure_bytes_are_valid
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

dump_patches () {
    for i in "${!patch_list[@]}"
    do
        echo "$i"
        echo "${patch_list[$i]}"
    done |
    jq --sort-keys -n -R 'reduce inputs as $i ({}; . + { ($i): (input|(tonumber? // .)) })'
}

case "${opmode}" in
    patch) patch ;;
    patchrollback) rollback ;;
    patchhelp) print_usage ; exit 2 ;;
    patchcheckversion) query_version_support ;;
    patchlistversions) list_supported_versions ;;
    dump) dump_patches ;;
    *) echo "Incorrect combination of flags. Use option -h to get help."
       exit 2 ;;
esac
