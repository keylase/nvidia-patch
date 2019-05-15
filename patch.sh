#!/bin/bash
# halt on any error for safety and proper pipe handling
set -euo pipefail ; # <- this semicolon and comment make options apply
# even when script is corrupt by CRLF line terminators (issue #75)
# empty line must follow this comment for immediate fail with CRLF newlines

backup_path="/opt/nvidia/libnvidia-encode-backup"
silent_flag=''
rollback_flag=''

print_usage() { printf '
SYNOPSIS
       patch.sh [OPTION]...

DESCRIPTION
       The patch for Nvidia drivers to increase encoder sessions

       -s    Silent mode (No output)
       -r    Rollback to original (Restore lib from backup)
       -h    Print this help message

'
}

while getopts 'rsh' flag; do
  case "${flag}" in
    r) rollback_flag='true' ;;
    s) silent_flag='true' ;;
    *) print_usage
       exit 1 ;;
  esac
done

if [[ $silent_flag ]]; then
    exec 1> /dev/null
fi

declare -A patch_list=(
    ["375.39"]='s/\x85\xC0\x89\xC5\x75\x18/\x29\xC0\x89\xC5\x90\x90/g'
    ["390.77"]='s/\x85\xC0\x89\xC5\x75\x18/\x29\xC0\x89\xC5\x90\x90/g'
    ["390.87"]='s/\x85\xC0\x89\xC5\x75\x18/\x29\xC0\x89\xC5\x90\x90/g'
    ["396.24"]='s/\x85\xC0\x89\xC5\x0F\x85\x96\x00\x00\x00/\x29\xC0\x89\xC5\x90\x90\x90\x90\x90\x90/g'
    ["396.26"]='s/\x85\xC0\x89\xC5\x0F\x85\x96\x00\x00\x00/\x29\xC0\x89\xC5\x90\x90\x90\x90\x90\x90/g'
    ["396.37"]='s/\x85\xC0\x89\xC5\x0F\x85\x96\x00\x00\x00/\x29\xC0\x89\xC5\x90\x90\x90\x90\x90\x90/g' #added info from https://github.com/keylase/nvidia-patch/issues/6#issuecomment-406895356
    # break nvenc.c:236,layout asm,step-mode,step,break *0x00007fff89f9ba45
    # libnvidia-encode.so @ 0x15a45; test->sub, jne->nop-nop-nop-nop-nop-nop
    ["396.54"]='s/\x85\xC0\x89\xC5\x0F\x85\x96\x00\x00\x00/\x29\xC0\x89\xC5\x90\x90\x90\x90\x90\x90/g'
    ["410.48"]='s/\x85\xC0\x89\xC5\x0F\x85\x96\x00\x00\x00/\x29\xC0\x89\xC5\x90\x90\x90\x90\x90\x90/g'
    ["410.57"]='s/\x85\xC0\x89\xC5\x0F\x85\x96\x00\x00\x00/\x29\xC0\x89\xC5\x90\x90\x90\x90\x90\x90/g'
    ["410.73"]='s/\x85\xC0\x89\xC5\x0F\x85\x96\x00\x00\x00/\x29\xC0\x89\xC5\x90\x90\x90\x90\x90\x90/g'
    ["410.78"]='s/\x85\xC0\x89\xC5\x0F\x85\x96\x00\x00\x00/\x29\xC0\x89\xC5\x90\x90\x90\x90\x90\x90/g'
    ["410.79"]='s/\x85\xC0\x89\xC5\x0F\x85\x96\x00\x00\x00/\x29\xC0\x89\xC5\x90\x90\x90\x90\x90\x90/g'
    ["410.93"]='s/\x85\xC0\x89\xC5\x0F\x85\x96\x00\x00\x00/\x29\xC0\x89\xC5\x90\x90\x90\x90\x90\x90/g'
    ["410.104"]='s/\x85\xC0\x89\xC5\x0F\x85\x96\x00\x00\x00/\x29\xC0\x89\xC5\x90\x90\x90\x90\x90\x90/g'
    ["415.18"]='s/\x00\x00\x00\x84\xc0\x0f\x84\x40\xfd\xff\xff/\x00\x00\x00\x84\xc0\x90\x90\x90\x90\x90\x90/g'
    ["415.25"]='s/\x00\x00\x00\x84\xc0\x0f\x84\x40\xfd\xff\xff/\x00\x00\x00\x84\xc0\x90\x90\x90\x90\x90\x90/g'
    ["415.27"]='s/\x00\x00\x00\x84\xc0\x0f\x84\x40\xfd\xff\xff/\x00\x00\x00\x84\xc0\x90\x90\x90\x90\x90\x90/g'
    ["418.30"]='s/\x00\x00\x00\x84\xc0\x0f\x84\x40\xfd\xff\xff/\x00\x00\x00\x84\xc0\x90\x90\x90\x90\x90\x90/g'
    ["418.43"]='s/\x00\x00\x00\x84\xc0\x0f\x84\x40\xfd\xff\xff/\x00\x00\x00\x84\xc0\x90\x90\x90\x90\x90\x90/g'
    ["418.56"]='s/\x00\x00\x00\x84\xc0\x0f\x84\x40\xfd\xff\xff/\x00\x00\x00\x84\xc0\x90\x90\x90\x90\x90\x90/g'
    ["418.67"]='s/\x00\x00\x00\x84\xc0\x0f\x84\x40\xfd\xff\xff/\x00\x00\x00\x84\xc0\x90\x90\x90\x90\x90\x90/g'
    ["418.74"]='s/\x00\x00\x00\x84\xc0\x0f\x84\x0f\xfd\xff\xff/\x00\x00\x00\x84\xc0\x90\x90\x90\x90\x90\x90/g'
    ["430.09"]='s/\x00\x00\x00\x84\xc0\x0f\x84\x0f\xfd\xff\xff/\x00\x00\x00\x84\xc0\x90\x90\x90\x90\x90\x90/g'
    ["430.14"]='s/\x00\x00\x00\x84\xc0\x0f\x84\x0f\xfd\xff\xff/\x00\x00\x00\x84\xc0\x90\x90\x90\x90\x90\x90/g'
)

declare -A object_list=(
    ["375.39"]='libnvidia-encode.so'
    ["390.77"]='libnvidia-encode.so'
    ["390.87"]='libnvidia-encode.so'
    ["396.24"]='libnvidia-encode.so'
    ["396.26"]='libnvidia-encode.so'
    ["396.37"]='libnvidia-encode.so'
    ["396.54"]='libnvidia-encode.so'
    ["410.48"]='libnvidia-encode.so'
    ["410.57"]='libnvidia-encode.so'
    ["410.73"]='libnvidia-encode.so'
    ["410.78"]='libnvidia-encode.so'
    ["410.79"]='libnvidia-encode.so'
    ["410.93"]='libnvidia-encode.so'
    ["410.104"]='libnvidia-encode.so'
    ["415.18"]='libnvcuvid.so'
    ["415.25"]='libnvcuvid.so'
    ["415.27"]='libnvcuvid.so'
    ["418.30"]='libnvcuvid.so'
    ["418.43"]='libnvcuvid.so'
    ["418.56"]='libnvcuvid.so'
    ["418.67"]='libnvcuvid.so'
    ["418.74"]='libnvcuvid.so'
    ["430.09"]='libnvcuvid.so'
    ["430.14"]='libnvcuvid.so'
)

NVIDIA_SMI="$(which nvidia-smi)"

if ! driver_version=$("$NVIDIA_SMI" --query-gpu=driver_version --format=csv,noheader,nounits | head -n 1) ; then
    echo 'Something went wrong. Check nvidia driver'
    exit 1;
fi

echo "Detected nvidia driver version: $driver_version"

if [[ ! "${patch_list[$driver_version]+isset}" || ! "${object_list[$driver_version]+isset}" ]]; then
    echo "Patch for this ($driver_version) nvidia driver not found." 1>&2
    echo "Available patches for: " 1>&2
    for drv in "${!patch_list[@]}"; do
        echo "$drv" 1>&2
    done
    exit 1;
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

if [[ $rollback_flag ]]; then
    if [[ -f "$backup_path/$object.$driver_version" ]]; then
        cp -p "$backup_path/$object.$driver_version" \
           "$driver_dir/$object.$driver_version"
        echo "Restore from backup $object.$driver_version"
    else
        echo "Backup not found. Try to patch first."
        exit 1;
    fi
else
    if [[ ! -f "$backup_path/$object.$driver_version" ]]; then
        echo "Attention! Backup not found. Copy current $object to backup."
        mkdir -p "$backup_path"
        cp -p "$driver_dir/$object.$driver_version" \
           "$backup_path/$object.$driver_version"
    fi
    sha1sum "$backup_path/$object.$driver_version"
    sed "$patch" "$backup_path/$object.$driver_version" > \
      "$driver_dir/$object.$driver_version"
    sha1sum "$driver_dir/$object.$driver_version"
    ldconfig
    echo "Patched!"
fi
