#!/bin/bash

backup_path="/opt/nvidia/libnvidia-encode-backup"
silent_flag=''
rollback_flag=''
driver_dir='/usr/lib/x86_64-linux-gnu'

print_usage() { printf '
SYNOPSIS
       patch.sh [OPTION]...

DESCRIPTION
       The patch for libnvidia-encode to increase encoder sessions

       -s    Silent mode (No output)
       -r    Rollback to original (Restore lib from backup)

'
}

while getopts 'rs' flag; do
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

test -d "$driver_dir" || driver_dir="/usr/lib64"  # ..centos
test -d "$driver_dir" || { echo "ERROR: cannot detect driver directory"; exit 1; }

declare -A patch_list=(
    ["375.39"]='s/\x85\xC0\x89\xC5\x75\x18/\x29\xC0\x89\xC5\x90\x90/g'
    ["396.24"]='s/\x85\xC0\x89\xC5\x0F\x85\x96\x00\x00\x00/\x29\xC0\x89\xC5\x90\x90\x90\x90\x90\x90/g'
    ["396.26"]='s/\x85\xC0\x89\xC5\x0F\x85\x96\x00\x00\x00/\x29\xC0\x89\xC5\x90\x90\x90\x90\x90\x90/g'
    ["396.37"]='s/\x85\xC0\x89\xC5\x0F\x85\x96\x00\x00\x00/\x29\xC0\x89\xC5\x90\x90\x90\x90\x90\x90/g' #added info from https://github.com/keylase/nvidia-patch/issues/6#issuecomment-406895356
    # break nvenc.c:236,layout asm,step-mode,step,break *0x00007fff89f9ba45
    # libnvidia-encode.so @ 0x15a45; test->sub, jne->nop-nop-nop-nop-nop-nop
    ["396.54"]='s/\x85\xC0\x89\xC5\x0F\x85\x96\x00\x00\x00/\x29\xC0\x89\xC5\x90\x90\x90\x90\x90\x90/g'
    ["410.48"]='s/\x85\xC0\x89\xC5\x0F\x85\x96\x00\x00\x00/\x29\xC0\x89\xC5\x90\x90\x90\x90\x90\x90/g'
)

driver_version=$(/usr/bin/nvidia-smi --query-gpu=driver_version --format=csv,noheader,nounits | head -n 1)
if [[ ! $? -eq 0 ]]; then
    echo 'Something went wrong. Check nvidia driver'
    exit 1;
fi

echo "Detected nvidia driver version: $driver_version"

patch=${patch_list[$driver_version]}

if [[ ! $patch ]]; then
    echo "Patch for this ($driver_version) nvidia driver not found." 1>&2
    echo "Available patches for: " 1>&2
    for drv in "${!patch_list[@]}"; do
        echo "$drv" 1>&2
    done
    exit 1;
fi

if [[ $rollback_flag ]]; then
    if [[ -f $backup_path/libnvidia-encode.so.$driver_version ]]; then
        cp -p $backup_path/libnvidia-encode.so.$driver_version \
           $driver_dir/libnvidia-encode.so.$driver_version
        echo "Restore from backup libnvidia-encode.so.$driver_version"
    else
        echo "Backup not found. Try to patch first."
        exit 1;
    fi
else
    if [[ ! -f $backup_path/libnvidia-encode.so.$driver_version ]]; then
        echo "Attention! Backup not found. Copy current libnvidia-encode to backup."
        mkdir -p $backup_path
        cp -p $driver_dir/libnvidia-encode.so.$driver_version \
           $backup_path/libnvidia-encode.so.$driver_version
    fi
    sha1sum $backup_path/libnvidia-encode.so.$driver_version
    sed "$patch" $backup_path/libnvidia-encode.so.$driver_version > \
      $driver_dir/libnvidia-encode.so.$driver_version
    sha1sum $driver_dir/libnvidia-encode.so.$driver_version
    ldconfig
    echo "Patched!"
fi
