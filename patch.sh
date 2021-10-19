#!/bin/bash
# halt on any error for safety and proper pipe handling
set -euo pipefail ; # <- this semicolon and comment make options apply
# even when script is corrupt by CRLF line terminators (issue #75)
# empty line must follow this comment for immediate fail with CRLF newlines

backup_path="/opt/nvidia/libnvidia-encode-backup"
silent_flag=''
manual_driver_version=''
flatpak_flag=''
backup_suffix=''

print_usage() { printf '
SYNOPSIS
       patch.sh [-s] [-r|-h|-c VERSION|-l|-f]

DESCRIPTION
       The patch for Nvidia drivers to remove NVENC session limit

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
    ["418.87.00"]='s/\x00\x00\x00\x84\xc0\x0f\x84\x0f\xfd\xff\xff/\x00\x00\x00\x84\xc0\x90\x90\x90\x90\x90\x90/g'
    ["418.87.01"]='s/\x00\x00\x00\x84\xc0\x0f\x84\x0f\xfd\xff\xff/\x00\x00\x00\x84\xc0\x90\x90\x90\x90\x90\x90/g'
    ["418.88"]='s/\x00\x00\x00\x84\xc0\x0f\x84\x0f\xfd\xff\xff/\x00\x00\x00\x84\xc0\x90\x90\x90\x90\x90\x90/g'
    ["418.113"]='s/\x00\x00\x00\x84\xc0\x0f\x84\x0f\xfd\xff\xff/\x00\x00\x00\x84\xc0\x90\x90\x90\x90\x90\x90/g'
    ["430.09"]='s/\x00\x00\x00\x84\xc0\x0f\x84\x0f\xfd\xff\xff/\x00\x00\x00\x84\xc0\x90\x90\x90\x90\x90\x90/g'
    ["430.14"]='s/\x00\x00\x00\x84\xc0\x0f\x84\x0f\xfd\xff\xff/\x00\x00\x00\x84\xc0\x90\x90\x90\x90\x90\x90/g'
    ["430.26"]='s/\x00\x00\x00\x84\xc0\x0f\x84\x0f\xfd\xff\xff/\x00\x00\x00\x84\xc0\x90\x90\x90\x90\x90\x90/g'
    ["430.34"]='s/\x00\x00\x00\x84\xc0\x0f\x84\x0f\xfd\xff\xff/\x00\x00\x00\x84\xc0\x90\x90\x90\x90\x90\x90/g'
    ["430.40"]='s/\x00\x00\x00\x84\xc0\x0f\x84\x0f\xfd\xff\xff/\x00\x00\x00\x84\xc0\x90\x90\x90\x90\x90\x90/g'
    ["430.50"]='s/\x00\x00\x00\x84\xc0\x0f\x84\x0f\xfd\xff\xff/\x00\x00\x00\x84\xc0\x90\x90\x90\x90\x90\x90/g'
    ["430.64"]='s/\x00\x00\x00\x84\xc0\x0f\x84\x0f\xfd\xff\xff/\x00\x00\x00\x84\xc0\x90\x90\x90\x90\x90\x90/g'
    ["435.17"]='s/\x00\x00\x00\x84\xc0\x0f\x84\x0f\xfd\xff\xff/\x00\x00\x00\x84\xc0\x90\x90\x90\x90\x90\x90/g'
    ["435.21"]='s/\x00\x00\x00\x84\xc0\x0f\x84\x0f\xfd\xff\xff/\x00\x00\x00\x84\xc0\x90\x90\x90\x90\x90\x90/g'
    ["435.27.08"]='s/\x85\xc0\x41\x89\xc4\x75\x1f/\x31\xc0\x41\x89\xc4\x75\x1f/g'
    ["440.26"]='s/\x85\xc0\x41\x89\xc4\x75\x1f/\x31\xc0\x41\x89\xc4\x75\x1f/g'
    ["440.31"]='s/\x85\xc0\x41\x89\xc4\x75\x1f/\x31\xc0\x41\x89\xc4\x75\x1f/g'
    ["440.33.01"]='s/\x85\xc0\x41\x89\xc4\x75\x1f/\x31\xc0\x41\x89\xc4\x75\x1f/g'
    ["440.36"]='s/\x85\xc0\x41\x89\xc4\x75\x1f/\x31\xc0\x41\x89\xc4\x75\x1f/g'
    ["440.43.01"]='s/\x85\xc0\x41\x89\xc4\x75\x1f/\x31\xc0\x41\x89\xc4\x75\x1f/g'
    ["440.44"]='s/\x85\xc0\x41\x89\xc4\x75\x1f/\x31\xc0\x41\x89\xc4\x75\x1f/g'
    ["440.48.02"]='s/\x85\xc0\x41\x89\xc4\x75\x1f/\x31\xc0\x41\x89\xc4\x75\x1f/g'
    ["440.58.01"]='s/\x85\xc0\x41\x89\xc4\x75\x1f/\x31\xc0\x41\x89\xc4\x75\x1f/g'
    ["440.58.02"]='s/\x85\xc0\x41\x89\xc4\x75\x1f/\x31\xc0\x41\x89\xc4\x75\x1f/g'
    ["440.59"]='s/\x85\xc0\x41\x89\xc4\x75\x1f/\x31\xc0\x41\x89\xc4\x75\x1f/g'
    ["440.64"]='s/\x85\xc0\x41\x89\xc4\x75\x1f/\x31\xc0\x41\x89\xc4\x75\x1f/g'
    ["440.64.00"]='s/\x85\xc0\x41\x89\xc4\x75\x1f/\x31\xc0\x41\x89\xc4\x75\x1f/g'
    ["440.66.02"]='s/\x85\xc0\x41\x89\xc4\x75\x1f/\x31\xc0\x41\x89\xc4\x75\x1f/g'
    ["440.66.03"]='s/\x85\xc0\x41\x89\xc4\x75\x1f/\x31\xc0\x41\x89\xc4\x75\x1f/g'
    ["440.66.04"]='s/\x85\xc0\x41\x89\xc4\x75\x1f/\x31\xc0\x41\x89\xc4\x75\x1f/g'
    ["440.66.08"]='s/\x85\xc0\x41\x89\xc4\x75\x1f/\x31\xc0\x41\x89\xc4\x75\x1f/g'
    ["440.66.09"]='s/\x85\xc0\x41\x89\xc4\x75\x1f/\x31\xc0\x41\x89\xc4\x75\x1f/g'
    ["440.66.11"]='s/\x85\xc0\x41\x89\xc4\x75\x1f/\x31\xc0\x41\x89\xc4\x75\x1f/g'
    ["440.66.12"]='s/\x85\xc0\x41\x89\xc4\x75\x1f/\x31\xc0\x41\x89\xc4\x75\x1f/g'
    ["440.66.14"]='s/\x85\xc0\x41\x89\xc4\x75\x1f/\x31\xc0\x41\x89\xc4\x75\x1f/g'
    ["440.66.15"]='s/\x85\xc0\x41\x89\xc4\x75\x1f/\x31\xc0\x41\x89\xc4\x75\x1f/g'
    ["440.66.17"]='s/\x85\xc0\x41\x89\xc4\x75\x1f/\x31\xc0\x41\x89\xc4\x75\x1f/g'
    ["440.82"]='s/\x85\xc0\x41\x89\xc4\x75\x1f/\x31\xc0\x41\x89\xc4\x75\x1f/g'
    ["440.95.01"]='s/\x85\xc0\x41\x89\xc4\x75\x1f/\x31\xc0\x41\x89\xc4\x75\x1f/g'
    ["440.100"]='s/\x85\xc0\x41\x89\xc4\x75\x1f/\x31\xc0\x41\x89\xc4\x75\x1f/g'
    ["440.118.02"]='s/\x85\xc0\x41\x89\xc4\x75\x1f/\x31\xc0\x41\x89\xc4\x75\x1f/g'
    ["450.36.06"]='s/\x85\xc0\x41\x89\xc4\x75\x1f/\x31\xc0\x41\x89\xc4\x75\x1f/g'
    ["450.51"]='s/\x85\xc0\x41\x89\xc4\x75\x1f/\x31\xc0\x41\x89\xc4\x75\x1f/g'
    ["450.51.05"]='s/\x85\xc0\x41\x89\xc4\x75\x1f/\x31\xc0\x41\x89\xc4\x75\x1f/g'
    ["450.51.06"]='s/\x85\xc0\x41\x89\xc4\x75\x1f/\x31\xc0\x41\x89\xc4\x75\x1f/g'
    ["450.56.01"]='s/\x85\xc0\x41\x89\xc4\x75\x1f/\x31\xc0\x41\x89\xc4\x75\x1f/g'
    ["450.56.02"]='s/\x85\xc0\x41\x89\xc4\x75\x1f/\x31\xc0\x41\x89\xc4\x75\x1f/g'
    ["450.56.06"]='s/\x85\xc0\x41\x89\xc4\x75\x1f/\x31\xc0\x41\x89\xc4\x75\x1f/g'
    ["450.56.11"]='s/\x85\xc0\x41\x89\xc4\x75\x1f/\x31\xc0\x41\x89\xc4\x75\x1f/g'
    ["450.57"]='s/\x85\xc0\x41\x89\xc4\x75\x1f/\x31\xc0\x41\x89\xc4\x75\x1f/g'
    ["450.66"]='s/\x85\xc0\x41\x89\xc4\x75\x1f/\x31\xc0\x41\x89\xc4\x75\x1f/g'
    ["450.80.02"]='s/\x85\xc0\x41\x89\xc4\x75\x1f/\x31\xc0\x41\x89\xc4\x75\x1f/g'
    ["450.102.04"]='s/\x85\xc0\x41\x89\xc4\x75\x1f/\x31\xc0\x41\x89\xc4\x75\x1f/g'
    ["455.22.04"]='s/\x85\xc0\x41\x89\xc4\x75\x1f/\x31\xc0\x41\x89\xc4\x75\x1f/g'
    ["455.23.04"]='s/\x85\xc0\x41\x89\xc4\x75\x1f/\x31\xc0\x41\x89\xc4\x75\x1f/g'
    ["455.23.05"]='s/\x85\xc0\x41\x89\xc4\x75\x1f/\x31\xc0\x41\x89\xc4\x75\x1f/g'
    ["455.26.01"]='s/\x85\xc0\x41\x89\xc4\x75\x1f/\x31\xc0\x41\x89\xc4\x75\x1f/g'
    ["455.26.02"]='s/\x85\xc0\x41\x89\xc4\x75\x1f/\x31\xc0\x41\x89\xc4\x75\x1f/g'
    ["455.28"]='s/\x85\xc0\x41\x89\xc4\x75\x1f/\x31\xc0\x41\x89\xc4\x75\x1f/g'
    ["455.32.00"]='s/\x85\xc0\x41\x89\xc4\x75\x1f/\x31\xc0\x41\x89\xc4\x75\x1f/g'
    ["455.38"]='s/\x85\xc0\x41\x89\xc4\x75\x1f/\x31\xc0\x41\x89\xc4\x75\x1f/g'
    ["455.45.01"]='s/\x85\xc0\x41\x89\xc4\x75\x1f/\x31\xc0\x41\x89\xc4\x75\x1f/g'
    ["455.46.01"]='s/\x85\xc0\x41\x89\xc4\x75\x1f/\x31\xc0\x41\x89\xc4\x75\x1f/g'
    ["455.46.02"]='s/\x85\xc0\x41\x89\xc4\x75\x1f/\x31\xc0\x41\x89\xc4\x75\x1f/g'
    ["455.46.04"]='s/\x85\xc0\x41\x89\xc4\x75\x1f/\x31\xc0\x41\x89\xc4\x75\x1f/g'
    ["455.50.02"]='s/\x85\xc0\x41\x89\xc4\x75\x1f/\x31\xc0\x41\x89\xc4\x75\x1f/g'
    ["455.50.04"]='s/\x85\xc0\x41\x89\xc4\x75\x1f/\x31\xc0\x41\x89\xc4\x75\x1f/g'
    ["455.50.05"]='s/\x85\xc0\x41\x89\xc4\x75\x1f/\x31\xc0\x41\x89\xc4\x75\x1f/g'
    ["455.50.07"]='s/\x85\xc0\x41\x89\xc4\x75\x1f/\x31\xc0\x41\x89\xc4\x75\x1f/g'
    ["455.50.10"]='s/\x85\xc0\x41\x89\xc4\x75\x1f/\x31\xc0\x41\x89\xc4\x75\x1f/g'
    ["460.27.04"]='s/\x22\xff\xff\x85\xc0\x41\x89\xc4\x0f\x85/\x22\xff\xff\x31\xc0\x41\x89\xc4\x0f\x85/g'
    ["460.32.03"]='s/\x22\xff\xff\x85\xc0\x41\x89\xc4\x0f\x85/\x22\xff\xff\x31\xc0\x41\x89\xc4\x0f\x85/g'
    ["460.39"]='s/\x22\xff\xff\x85\xc0\x41\x89\xc4\x0f\x85/\x22\xff\xff\x31\xc0\x41\x89\xc4\x0f\x85/g'
    ["460.56"]='s/\x22\xff\xff\x85\xc0\x41\x89\xc4\x0f\x85/\x22\xff\xff\x31\xc0\x41\x89\xc4\x0f\x85/g'
    ["460.67"]='s/\x22\xff\xff\x85\xc0\x41\x89\xc4\x0f\x85/\x22\xff\xff\x31\xc0\x41\x89\xc4\x0f\x85/g'
    ["460.73.01"]='s/\x22\xff\xff\x85\xc0\x41\x89\xc4\x0f\x85/\x22\xff\xff\x31\xc0\x41\x89\xc4\x0f\x85/g'
    ["460.80"]='s/\x22\xff\xff\x85\xc0\x41\x89\xc4\x0f\x85/\x22\xff\xff\x31\xc0\x41\x89\xc4\x0f\x85/g'
    ["460.84"]='s/\x22\xff\xff\x85\xc0\x41\x89\xc4\x0f\x85/\x22\xff\xff\x31\xc0\x41\x89\xc4\x0f\x85/g'
    ["460.91.03"]='s/\x22\xff\xff\x85\xc0\x41\x89\xc4\x0f\x85/\x22\xff\xff\x31\xc0\x41\x89\xc4\x0f\x85/g'
    ["465.19.01"]='s/\xe8\xc5\x20\xff\xff\x85\xc0\x41\x89\xc4/\xe8\xc5\x20\xff\xff\x29\xc0\x41\x89\xc4/g'
    ["465.24.02"]='s/\xe8\xc5\x20\xff\xff\x85\xc0\x41\x89\xc4/\xe8\xc5\x20\xff\xff\x29\xc0\x41\x89\xc4/g'
    ["465.27"]='s/\xe8\xc5\x20\xff\xff\x85\xc0\x41\x89\xc4/\xe8\xc5\x20\xff\xff\x29\xc0\x41\x89\xc4/g'
    ["465.31"]='s/\xe8\xc5\x20\xff\xff\x85\xc0\x41\x89\xc4/\xe8\xc5\x20\xff\xff\x29\xc0\x41\x89\xc4/g'
    ["470.42.01"]='s/\xe8\x25\x1C\xff\xff\x85\xc0\x41\x89\xc4/\xe8\x25\x1C\xff\xff\x29\xc0\x41\x89\xc4/g'
    ["470.57.02"]='s/\xe8\x25\x1C\xff\xff\x85\xc0\x41\x89\xc4/\xe8\x25\x1C\xff\xff\x29\xc0\x41\x89\xc4/g'
    ["470.62.02"]='s/\xe8\x25\x1C\xff\xff\x85\xc0\x41\x89\xc4/\xe8\x25\x1C\xff\xff\x29\xc0\x41\x89\xc4/g'
    ["470.62.05"]='s/\xe8\x25\x1C\xff\xff\x85\xc0\x41\x89\xc4/\xe8\x25\x1C\xff\xff\x29\xc0\x41\x89\xc4/g'
    ["470.63.01"]='s/\xe8\x25\x1C\xff\xff\x85\xc0\x41\x89\xc4/\xe8\x25\x1C\xff\xff\x29\xc0\x41\x89\xc4/g'
    ["470.74"]='s/\xe8\x25\x1C\xff\xff\x85\xc0\x41\x89\xc4/\xe8\x25\x1C\xff\xff\x29\xc0\x41\x89\xc4/g'
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
    ["418.87.00"]='libnvcuvid.so'
    ["418.87.01"]='libnvcuvid.so'
    ["418.88"]='libnvcuvid.so'
    ["418.113"]='libnvcuvid.so'
    ["430.09"]='libnvcuvid.so'
    ["430.14"]='libnvcuvid.so'
    ["430.26"]='libnvcuvid.so'
    ["430.34"]='libnvcuvid.so'
    ["430.40"]='libnvcuvid.so'
    ["430.50"]='libnvcuvid.so'
    ["430.64"]='libnvcuvid.so'
    ["435.17"]='libnvcuvid.so'
    ["435.21"]='libnvcuvid.so'
    ["435.27.08"]='libnvidia-encode.so'
    ["440.26"]='libnvidia-encode.so'
    ["440.31"]='libnvidia-encode.so'
    ["440.33.01"]='libnvidia-encode.so'
    ["440.36"]='libnvidia-encode.so'
    ["440.43.01"]='libnvidia-encode.so'
    ["440.44"]='libnvidia-encode.so'
    ["440.48.02"]='libnvidia-encode.so'
    ["440.58.01"]='libnvidia-encode.so'
    ["440.58.02"]='libnvidia-encode.so'
    ["440.59"]='libnvidia-encode.so'
    ["440.64"]='libnvidia-encode.so'
    ["440.64.00"]='libnvidia-encode.so'
    ["440.66.02"]='libnvidia-encode.so'
    ["440.66.03"]='libnvidia-encode.so'
    ["440.66.04"]='libnvidia-encode.so'
    ["440.66.08"]='libnvidia-encode.so'
    ["440.66.09"]='libnvidia-encode.so'
    ["440.66.11"]='libnvidia-encode.so'
    ["440.66.12"]='libnvidia-encode.so'
    ["440.66.14"]='libnvidia-encode.so'
    ["440.66.15"]='libnvidia-encode.so'
    ["440.66.17"]='libnvidia-encode.so'
    ["440.82"]='libnvidia-encode.so'
    ["440.95.01"]='libnvidia-encode.so'
    ["440.100"]='libnvidia-encode.so'
    ["440.118.02"]='libnvidia-encode.so'
    ["450.36.06"]='libnvidia-encode.so'
    ["450.51"]='libnvidia-encode.so'
    ["450.51.05"]='libnvidia-encode.so'
    ["450.51.06"]='libnvidia-encode.so'
    ["450.56.01"]='libnvidia-encode.so'
    ["450.56.02"]='libnvidia-encode.so'
    ["450.56.06"]='libnvidia-encode.so'
    ["450.56.11"]='libnvidia-encode.so'
    ["450.57"]='libnvidia-encode.so'
    ["450.66"]='libnvidia-encode.so'
    ["450.80.02"]='libnvidia-encode.so'
    ["450.102.04"]='libnvidia-encode.so'
    ["455.22.04"]='libnvidia-encode.so'
    ["455.23.04"]='libnvidia-encode.so'
    ["455.23.05"]='libnvidia-encode.so'
    ["455.26.01"]='libnvidia-encode.so'
    ["455.26.02"]='libnvidia-encode.so'
    ["455.28"]='libnvidia-encode.so'
    ["455.32.00"]='libnvidia-encode.so'
    ["455.38"]='libnvidia-encode.so'
    ["455.45.01"]='libnvidia-encode.so'
    ["455.46.01"]='libnvidia-encode.so'
    ["455.46.02"]='libnvidia-encode.so'
    ["455.46.04"]='libnvidia-encode.so'
    ["455.50.02"]='libnvidia-encode.so'
    ["455.50.04"]='libnvidia-encode.so'
    ["455.50.05"]='libnvidia-encode.so'
    ["455.50.07"]='libnvidia-encode.so'
    ["455.50.10"]='libnvidia-encode.so'
    ["460.27.04"]='libnvidia-encode.so'
    ["460.32.03"]='libnvidia-encode.so'
    ["460.39"]='libnvidia-encode.so'
    ["460.56"]='libnvidia-encode.so'
    ["460.67"]='libnvidia-encode.so'
    ["460.73.01"]='libnvidia-encode.so'
    ["460.80"]='libnvidia-encode.so'
    ["460.84"]='libnvidia-encode.so'
    ["460.91.03"]='libnvidia-encode.so'
    ["465.19.01"]='libnvidia-encode.so'
    ["465.24.02"]='libnvidia-encode.so'
    ["465.27"]='libnvidia-encode.so'
    ["465.31"]='libnvidia-encode.so'
    ["470.42.01"]='libnvidia-encode.so'
    ["470.57.02"]='libnvidia-encode.so'
    ["470.62.02"]='libnvidia-encode.so'
    ["470.62.05"]='libnvidia-encode.so'
    ["470.63.01"]='libnvidia-encode.so'
    ["470.74"]='libnvidia-encode.so'
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
