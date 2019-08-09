# nvidia-patch

![GitHub last commit](https://img.shields.io/github/last-commit/keylase/nvidia-patch.svg) ![Latest version](https://img.shields.io/badge/latest%20linux%20driver%20version-430.40-brightgreen.svg)

This patch removes restriction on maximum number of simultaneous NVENC video encoding sessions imposed by Nvidia to consumer-grade GPUs.

Main target operating system is **GNU/Linux**, but for **Windows** support see [**win**](win).

Requirements:
- x86\_64 system architecture
- GNU/Linux operating system
- nvenc-compatible gpu (https://developer.nvidia.com/video-encode-decode-gpu-support-matrix#Encoder)
- Nvidia driver. Patch available for: 
  - [375.39](https://download.nvidia.com/XFree86/Linux-x86_64/375.39/NVIDIA-Linux-x86_64-375.39.run)
  - [390.77](https://download.nvidia.com/XFree86/Linux-x86_64/390.77/NVIDIA-Linux-x86_64-390.77.run)
  - [390.87](https://download.nvidia.com/XFree86/Linux-x86_64/390.87/NVIDIA-Linux-x86_64-390.87.run)
  - [396.24](https://download.nvidia.com/XFree86/Linux-x86_64/396.24/NVIDIA-Linux-x86_64-396.24.run)
  - [396.26](https://international.download.nvidia.com/tesla/396.26/NVIDIA-Linux-x86_64-396.26.run)
  - [396.37](https://international.download.nvidia.com/tesla/396.37/NVIDIA-Linux-x86_64-396.37.run)
  - [396.54](https://download.nvidia.com/XFree86/Linux-x86_64/396.54/NVIDIA-Linux-x86_64-396.54.run)
  - 410.48
  - [410.57](https://download.nvidia.com/XFree86/Linux-x86_64/410.57/NVIDIA-Linux-x86_64-410.57.run)
  - [410.73](https://download.nvidia.com/XFree86/Linux-x86_64/410.73/NVIDIA-Linux-x86_64-410.73.run)
  - [410.78](https://download.nvidia.com/XFree86/Linux-x86_64/410.78/NVIDIA-Linux-x86_64-410.78.run)
  - [410.79](https://international.download.nvidia.com/tesla/410.79/NVIDIA-Linux-x86_64-410.79.run)
  - [410.93](https://download.nvidia.com/XFree86/Linux-x86_64/410.93/NVIDIA-Linux-x86_64-410.93.run)
  - [410.104](https://international.download.nvidia.com/XFree86/Linux-x86_64/410.104/NVIDIA-Linux-x86_64-410.104.run)
  - [415.18](https://download.nvidia.com/XFree86/Linux-x86_64/415.18/NVIDIA-Linux-x86_64-415.18.run)
  - [415.25](https://download.nvidia.com/XFree86/Linux-x86_64/415.25/NVIDIA-Linux-x86_64-415.25.run)
  - [415.27](https://download.nvidia.com/XFree86/Linux-x86_64/415.27/NVIDIA-Linux-x86_64-415.27.run)
  - [418.30](https://download.nvidia.com/XFree86/Linux-x86_64/418.30/NVIDIA-Linux-x86_64-418.30.run)
  - [418.43](https://download.nvidia.com/XFree86/Linux-x86_64/418.43/NVIDIA-Linux-x86_64-418.43.run)
  - [418.56](https://download.nvidia.com/XFree86/Linux-x86_64/418.56/NVIDIA-Linux-x86_64-418.56.run)
  - 418.67
  - [418.74](https://international.download.nvidia.com/XFree86/Linux-x86_64/418.74/NVIDIA-Linux-x86_64-418.74.run)
  - [430.09](https://international.download.nvidia.com/XFree86/Linux-x86_64/430.09/NVIDIA-Linux-x86_64-430.09.run)
  - [430.14](https://international.download.nvidia.com/XFree86/Linux-x86_64/430.14/NVIDIA-Linux-x86_64-430.14.run)
  - [430.26](https://international.download.nvidia.com/XFree86/Linux-x86_64/430.26/NVIDIA-Linux-x86_64-430.26.run)
  - [430.34](https://international.download.nvidia.com/XFree86/Linux-x86_64/430.34/NVIDIA-Linux-x86_64-430.34.run)
  - [430.40](https://international.download.nvidia.com/XFree86/Linux-x86_64/430.40/NVIDIA-Linux-x86_64-430.40.run)

## Synopsis

```
# bash ./patch.sh -h

SYNOPSIS
       patch.sh [OPTION]...

DESCRIPTION
       The patch for Nvidia drivers to increase encoder sessions

       -s    Silent mode (No output)
       -r    Rollback to original (Restore lib from backup)
       -h    Print this help message

```

## Step-by-Step guide

Examples are provided for driver version 430.40. All commands are runned as root.

### Download driver

[https://international.download.nvidia.com/XFree86/Linux-x86\_64/430.40/NVIDIA-Linux-x86\_64-430.40.run](https://international.download.nvidia.com/XFree86/Linux-x86_64/430.40/NVIDIA-Linux-x86_64-430.40.run)

### Install driver

Make sure you have kernel headers and compiler installed before running Nvidia driver installer. Kernel headers and compiler are required to build nvidia kernel module. Recommended way to do this is to install `dkms` package, if it is available in your distro. This way `dkms` package will pull all required dependencies to allow building kernel modules and kernel module builds will be automated in a reliable fashion.

```bash
mkdir /opt/nvidia && cd /opt/nvidia
wget https://international.download.nvidia.com/XFree86/Linux-x86_64/430.40/NVIDIA-Linux-x86_64-430.40.run
chmod +x ./NVIDIA-Linux-x86_64-430.40.run
./NVIDIA-Linux-x86_64-430.40.run
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
