# nvidia-patch

![GitHub last commit](https://img.shields.io/github/last-commit/keylase/nvidia-patch.svg) ![Latest version](https://img.shields.io/badge/latest%20linux%20driver%20version-440.66.08-brightgreen.svg)

This patch removes restriction on maximum number of simultaneous NVENC video encoding sessions imposed by Nvidia to consumer-grade GPUs.

Also there is available experimental NvFBC patch which allows to use NvFBC on consumer-grade GPUs. It should be applied same way as NVENC `patch.sh`, except you have to use `patch-fbc.sh` instead.

Main target operating system is **GNU/Linux**, but for **Windows** support see [**win**](win).

Requirements:
- x86\_64 system architecture
- GNU/Linux operating system
- nvenc-compatible gpu (https://developer.nvidia.com/video-encode-decode-gpu-support-matrix#Encoder)
- Nvidia driver. Patch available for versions in version table below.

## Version Table

| Version | NVENC patch | NVFBC patch | Driver link |
| :---    |    :---:    |    :---:    |        ---: |
| 375.39 | :heavy_check_mark: | :x: | [Driver link](https://download.nvidia.com/XFree86/Linux-x86_64/375.39/NVIDIA-Linux-x86_64-375.39.run) |
| 390.77 | :heavy_check_mark: | :x: | [Driver link](https://download.nvidia.com/XFree86/Linux-x86_64/390.77/NVIDIA-Linux-x86_64-390.77.run) |
| 390.87 | :heavy_check_mark: | :x: | [Driver link](https://download.nvidia.com/XFree86/Linux-x86_64/390.87/NVIDIA-Linux-x86_64-390.87.run) |
| 396.24 | :heavy_check_mark: | :x: | [Driver link](https://download.nvidia.com/XFree86/Linux-x86_64/396.24/NVIDIA-Linux-x86_64-396.24.run) |
| 396.26 | :heavy_check_mark: | :x: | [Driver link](https://international.download.nvidia.com/tesla/396.26/NVIDIA-Linux-x86_64-396.26.run) |
| 396.37 | :heavy_check_mark: | :x: | [Driver link](https://international.download.nvidia.com/tesla/396.37/NVIDIA-Linux-x86_64-396.37.run) |
| 396.54 | :heavy_check_mark: | :x: | [Driver link](https://download.nvidia.com/XFree86/Linux-x86_64/396.54/NVIDIA-Linux-x86_64-396.54.run) |
| 410.48 | :heavy_check_mark: | :x: |  |
| 410.57 | :heavy_check_mark: | :x: | [Driver link](https://download.nvidia.com/XFree86/Linux-x86_64/410.57/NVIDIA-Linux-x86_64-410.57.run) |
| 410.73 | :heavy_check_mark: | :x: | [Driver link](https://download.nvidia.com/XFree86/Linux-x86_64/410.73/NVIDIA-Linux-x86_64-410.73.run) |
| 410.78 | :heavy_check_mark: | :x: | [Driver link](https://download.nvidia.com/XFree86/Linux-x86_64/410.78/NVIDIA-Linux-x86_64-410.78.run) |
| 410.79 | :heavy_check_mark: | :x: | [Driver link](https://international.download.nvidia.com/tesla/410.79/NVIDIA-Linux-x86_64-410.79.run) |
| 410.93 | :heavy_check_mark: | :x: | [Driver link](https://download.nvidia.com/XFree86/Linux-x86_64/410.93/NVIDIA-Linux-x86_64-410.93.run) |
| 410.104 | :heavy_check_mark: | :x: | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/410.104/NVIDIA-Linux-x86_64-410.104.run) |
| 415.18 | :heavy_check_mark: | :x: | [Driver link](https://download.nvidia.com/XFree86/Linux-x86_64/415.18/NVIDIA-Linux-x86_64-415.18.run) |
| 415.25 | :heavy_check_mark: | :x: | [Driver link](https://download.nvidia.com/XFree86/Linux-x86_64/415.25/NVIDIA-Linux-x86_64-415.25.run) |
| 415.27 | :heavy_check_mark: | :x: | [Driver link](https://download.nvidia.com/XFree86/Linux-x86_64/415.27/NVIDIA-Linux-x86_64-415.27.run) |
| 418.30 | :heavy_check_mark: | :x: | [Driver link](https://download.nvidia.com/XFree86/Linux-x86_64/418.30/NVIDIA-Linux-x86_64-418.30.run) |
| 418.43 | :heavy_check_mark: | :x: | [Driver link](https://download.nvidia.com/XFree86/Linux-x86_64/418.43/NVIDIA-Linux-x86_64-418.43.run) |
| 418.56 | :heavy_check_mark: | :x: | [Driver link](https://download.nvidia.com/XFree86/Linux-x86_64/418.56/NVIDIA-Linux-x86_64-418.56.run) |
| 418.67 | :heavy_check_mark: | :x: | [Driver link](https://international.download.nvidia.com/tesla/418.67/NVIDIA-Linux-x86_64-418.67.run) |
| 418.74 | :heavy_check_mark: | :x: | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/418.74/NVIDIA-Linux-x86_64-418.74.run) |
| 418.87.00 | :heavy_check_mark: | :x: | [Driver link](https://international.download.nvidia.com/tesla/418.87/NVIDIA-Linux-x86_64-418.87.00.run) |
| 418.87.01 | :heavy_check_mark: | :x: | [Driver link](https://international.download.nvidia.com/tesla/418.87/NVIDIA-Linux-x86_64-418.87.01.run) |
| 418.88 | :heavy_check_mark: | :x: | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/418.88/NVIDIA-Linux-x86_64-418.88.run) |
| 430.09 | :heavy_check_mark: | :x: | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/430.09/NVIDIA-Linux-x86_64-430.09.run) |
| 430.14 | :heavy_check_mark: | :x: | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/430.14/NVIDIA-Linux-x86_64-430.14.run) |
| 430.26 | :heavy_check_mark: | :x: | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/430.26/NVIDIA-Linux-x86_64-430.26.run) |
| 430.34 | :heavy_check_mark: | :x: | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/430.34/NVIDIA-Linux-x86_64-430.34.run) |
| 430.40 | :heavy_check_mark: | :x: | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/430.40/NVIDIA-Linux-x86_64-430.40.run) |
| 430.50 | :heavy_check_mark: | :x: | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/430.50/NVIDIA-Linux-x86_64-430.50.run) |
| 430.64 | :heavy_check_mark: | :x: | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/430.64/NVIDIA-Linux-x86_64-430.64.run) |
| 435.17 | :heavy_check_mark: | :x: | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/435.17/NVIDIA-Linux-x86_64-435.17.run) |
| 435.21 | :heavy_check_mark: | :x: | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/435.21/NVIDIA-Linux-x86_64-435.21.run) |
| 435.27.08 | :heavy_check_mark: | :heavy_check_mark: |  |
| 440.26 | :heavy_check_mark: | :heavy_check_mark: | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/440.26/NVIDIA-Linux-x86_64-440.26.run) |
| 440.31 | :heavy_check_mark: | :heavy_check_mark: | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/440.31/NVIDIA-Linux-x86_64-440.31.run) |
| 440.33.01 | :heavy_check_mark: | :heavy_check_mark: | [Driver link](https://international.download.nvidia.com/tesla/440.33.01/NVIDIA-Linux-x86_64-440.33.01.run) |
| 440.36 | :heavy_check_mark: | :heavy_check_mark: | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/440.36/NVIDIA-Linux-x86_64-440.36.run) |
| 440.43.01 | :heavy_check_mark: | :heavy_check_mark: |  |
| 440.44 | :heavy_check_mark: | :heavy_check_mark: | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/440.44/NVIDIA-Linux-x86_64-440.44.run) |
| 440.48.02 | :heavy_check_mark: | :heavy_check_mark: |  |
| 440.58.01 | :heavy_check_mark: | :heavy_check_mark: |  |
| 440.58.02 | :heavy_check_mark: | :heavy_check_mark: |  |
| 440.59 | :heavy_check_mark: | :heavy_check_mark: | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/440.59/NVIDIA-Linux-x86_64-440.59.run) |
| 440.64 | :heavy_check_mark: | :heavy_check_mark: | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/440.64/NVIDIA-Linux-x86_64-440.64.run) |
| 440.64.00 | :heavy_check_mark: | :heavy_check_mark: | [Driver link](https://international.download.nvidia.com/tesla/440.64.00/NVIDIA-Linux-x86_64-440.64.00.run) |
| 440.66.02 | :heavy_check_mark: | :heavy_check_mark: |  |
| 440.66.03 | :heavy_check_mark: | :heavy_check_mark: |  |
| 440.66.04 | :heavy_check_mark: | :heavy_check_mark: |  |
| 440.66.08 | :heavy_check_mark: | :heavy_check_mark: |  |

## Synopsis

```
# bash ./patch.sh -h

SYNOPSIS
       patch.sh [-s] [-r|-h|-c VERSION|-l]

DESCRIPTION
       The patch for Nvidia drivers to remove NVENC session limit

       -s             Silent mode (No output)
       -r             Rollback to original (Restore lib from backup)
       -h             Print this help message
       -c VERSION     Check if version VERSION supported by this patch.
                      Returns true exit code (0) if version is supported.
       -l             List supported driver versions

```

## Step-by-Step guide

Examples are provided for driver version 430.50. All commands executed as root.

### Download and install driver

Skip this step if you already have installed driver with version supported by this patch (from distro packages, for example).

Make sure you have kernel headers and compiler installed before running Nvidia driver installer. Kernel headers and compiler are required to build nvidia kernel module. Recommended way to do this is to install `dkms` package, if it is available in your distro. This way `dkms` package will pull all required dependencies to allow building kernel modules and kernel module builds will be automated in a reliable fashion.

```bash
mkdir /opt/nvidia && cd /opt/nvidia
wget https://international.download.nvidia.com/XFree86/Linux-x86_64/430.50/NVIDIA-Linux-x86_64-430.50.run
chmod +x ./NVIDIA-Linux-x86_64-430.50.run
./NVIDIA-Linux-x86_64-430.50.run
```

### Check driver

```bash
nvidia-smi
```

Output should show no errors and details about your driver and GPU.

### Patch driver

This patch performs backup of original file prior to making changes.

```bash
bash ./patch.sh
```

You're all set!

## Rollback

If something got broken you may restore patched driver from backup:

```bash
bash ./patch.sh -r
```

## Docker support

It is possible to use this patch with nvidia-docker containers, even if host machine hasn't patched drivers. See `Dockerfile` for example.

Essentially all you need to do during build is:

* `COPY` the `patch.sh` and `docker-entrypoint.sh` files into your container.
* Make sure `docker-entrypoint.sh` is invoked on container start.

`docker-entrypoint.sh` script does on-the-fly patching by means of manipulating dynamic linker to workaround read-only mount of Nvidia runtime. Finally it passes original docker command to shell, like if entrypoint was not restricted by `ENTRYPOINT` directive. So `docker run --runtime=nvidia -it mycontainer echo 123` will print `123`. Also it can be just invoked from your entrypoint script, if you have any.

## Benchmarks

* [Plex Media Server: nVidia Hardware Transcoding Calculator for Plex Estimates](https://www.elpamsoft.com/?p=Plex-Hardware-Transcoding) - useful benchmark of achieved simultaneous transcodes with various stream quality and hardware with patched drivers.

## See also

* Plex Media Server: enable HW **decoding**: 
  * [GH Issue](https://github.com/keylase/nvidia-patch/issues/51)
  * PMS Forum:
    1. [https://forums.plex.tv/t/hardware-accelerated-decode-nvidia-for-linux/233510/158](https://forums.plex.tv/t/hardware-accelerated-decode-nvidia-for-linux/233510/158)
    2. [https://forums.plex.tv/t/hardware-accelerated-decode-nvidia-for-linux/233510/172](https://forums.plex.tv/t/hardware-accelerated-decode-nvidia-for-linux/233510/172)
* Unraid / Docker:
  * [GH Issue](https://github.com/keylase/nvidia-patch/issues/43)
  * Unraid Nvidia plugin:
    * [Repo](https://github.com/linuxserver/Unraid-Nvidia-Plugin)
    * [Forum page](https://forums.unraid.net/topic/77813-plugin-linuxserverio-unraid-nvidia/) ([archive link](https://web.archive.org/web/20190211145338/https://forums.unraid.net/topic/77813-plugin-linuxserverio-unraid-nvidia/))
* Original research behind this patch
  * [Original post in Russian](https://habr.com/post/262563/)
  * [3rd party English translation](https://weekly-geekly.github.io/articles/262563/index.html)

If you experience `CreateBitstreamBuffer failed: out of memory (10)`, then you have to lower buffers number used for every encoding session. If you are using `ffmpeg`, see option `-surfaces` ("Number of concurrent surfaces") and try value near `-surfaces 8`.
