Nvidia drivers patch for Windows
================================

![GitHub last commit](https://img.shields.io/github/last-commit/keylase/nvidia-patch.svg) ![Latest GeForce version](https://img.shields.io/badge/latest%20GeForce%20version-436.02-brightgreen.svg) ![Latest Quadro version](https://img.shields.io/badge/latest%20Quadro%20version-431.02-blue.svg)

This patch removes restriction on maximum number of simultaneous NVENC video encoding sessions imposed by Nvidia to consumer-grade GPUs.

Requirements:

- Any of following 64bit operating systems:
  - Windows 7
  - Windows 8
  - Windows 8.1
  - Windows 10
  - Windows Server 2008 R2
  - Windows Server 2012
  - Windows Server 2012 R2
  - Windows Server 2016
  - Windows Server 2019
- NVENC-compatible GPU (https://developer.nvidia.com/video-encode-decode-gpu-support-matrix#Encoder)
- Nvidia driver. Patch available for versions in [table below](#version-table).

## Step-by-Step Guide

1. Download and install latest Nvidia driver supported by this patch.
2. Download latest [Win\_1337\_Apply\_Patch tool](https://github.com/Deltafox79/Win_1337_Apply_Patch/releases/latest).
3. Save appropriate patch from [Version Table](#version-table) using direct link to the patch (Right Click -> Save as...). Alternatively you may checkout repo using git or download it as ZIP archive and then locate corresponding .1337 patch file in `win` directory.
4. Apply patch to corresponding file in `%WINDIR%\system32\` with the Win\_1337\_Apply\_Patch tool. File name of patched object is specified in first line of .1337 patch.

E.g, for 64bit Windows 10 running driver version 417.35 use `win10_x64/417.35/nvcuvid.1337` against `C:\WINDOWS\system32\nvcuvid.dll`.

## Version Table

### Windows 10 drivers


| Product series | Version | Patch | Driver link |
|----------------|---------|-------|----------------------|
| GeForce        | 417.35  | [Direct link](https://raw.githubusercontent.com/keylase/nvidia-patch/master/win/win10_x64/417.35/nvcuvid.1337) | [Direct link](https://international.download.nvidia.com/Windows/417.35/417.35-desktop-win10-64bit-international-whql-rp.exe) |
| GeForce        | 417.58  | [Direct link](https://raw.githubusercontent.com/keylase/nvidia-patch/master/win/win10_x64/417.58/nvcuvid.1337) | [Direct link](https://international.download.nvidia.com/Windows/417.58hf/417.58-desktop-notebook-win10-64bit-international-whql.hf.exe) |
| GeForce        | 417.71  | [Direct link](https://raw.githubusercontent.com/keylase/nvidia-patch/master/win/win10_x64/417.71/nvcuvid.1337) | [Direct link](https://international.download.nvidia.com/Windows/417.71/417.71-desktop-win10-64bit-international-whql.exe) |
| GeForce        | 418.81  | [Direct link](https://raw.githubusercontent.com/keylase/nvidia-patch/master/win/win10_x64/418.81/nvcuvid.1337) | [Direct link](https://international.download.nvidia.com/Windows/418.81/418.81-desktop-win10-64bit-international-whql.exe) |
| GeForce        | 418.91  | [Direct link](https://raw.githubusercontent.com/keylase/nvidia-patch/master/win/win10_x64/418.91/nvcuvid.1337) | [Direct link](https://international.download.nvidia.com/Windows/418.91/418.91-desktop-win10-64bit-international-whql.exe) |
| GeForce        | 419.17  | [Direct link](https://raw.githubusercontent.com/keylase/nvidia-patch/master/win/win10_x64/419.17/nvcuvid.1337) | [Direct link](https://international.download.nvidia.com/Windows/419.17/419.17-desktop-win10-64bit-international-whql.exe) |
| GeForce        | 419.35  | [Direct link](https://raw.githubusercontent.com/keylase/nvidia-patch/master/win/win10_x64/419.35/nvcuvid.1337) | [Direct link](https://international.download.nvidia.com/Windows/419.35/419.35-desktop-win10-64bit-international-whql.exe) |
| GeForce        | 419.67  | [Direct link](https://raw.githubusercontent.com/keylase/nvidia-patch/master/win/win10_x64/419.67/nvcuvid.1337) | [Direct link](https://international.download.nvidia.com/Windows/419.67/419.67-desktop-win10-64bit-international-whql.exe) |
| GeForce        | 419.67 CRD | [Direct link](https://raw.githubusercontent.com/keylase/nvidia-patch/master/win/win10_x64/crd_419.67/nvcuvid.1337) | [Direct link](https://international.download.nvidia.com/Windows/419.67/419.67-notebook-win10-64bit-international-crd-whql.exe) |
| GeForce        | 425.31  | [Direct link](https://raw.githubusercontent.com/keylase/nvidia-patch/master/win/win10_x64/425.31/nvcuvid.1337) | [Direct link](https://international.download.nvidia.com/Windows/425.31/425.31-desktop-win10-64bit-international-whql.exe) |
| GeForce        | 430.39  | [Direct link](https://raw.githubusercontent.com/keylase/nvidia-patch/master/win/win10_x64/430.39/nvcuvid.1337) | [Direct link](https://international.download.nvidia.com/Windows/430.39/430.39-desktop-win10-64bit-international-whql.exe) |
| GeForce        | 430.64  | [Direct link](https://raw.githubusercontent.com/keylase/nvidia-patch/master/win/win10_x64/430.64/nvcuvid.1337) | [Direct link](https://international.download.nvidia.com/Windows/430.64/430.64-desktop-win10-64bit-international-whql.exe) |
| GeForce        | 430.86  | [Direct link](https://raw.githubusercontent.com/keylase/nvidia-patch/master/win/win10_x64/430.86/nvcuvid.1337) | [Direct link](https://international.download.nvidia.com/Windows/430.86/430.86-desktop-win10-64bit-international-whql.exe) |
| GeForce        | 430.86 Studio Driver | [Direct link](https://raw.githubusercontent.com/keylase/nvidia-patch/master/win/win10_x64/nsd_430.86/nvcuvid.1337) | [Direct link](https://international-gfe.download.nvidia.com/Windows/430.86/430.86-desktop-win10-64bit-international-nsd-whql-g.exe) |
| GeForce        | 431.36  | [Direct link](https://raw.githubusercontent.com/keylase/nvidia-patch/master/win/win10_x64/431.36/nvcuvid.1337) | [Direct link](https://international.download.nvidia.com/Windows/431.36/431.36-desktop-win10-64bit-international-whql.exe) |
| GeForce        | 431.60  | [Direct link](https://raw.githubusercontent.com/keylase/nvidia-patch/master/win/win10_x64/431.60/nvcuvid.1337) | [Direct link](https://international.download.nvidia.com/Windows/431.60/431.60-desktop-win10-64bit-international-whql.exe) |
| GeForce        | 431.70 Studio Driver | [Direct link](https://raw.githubusercontent.com/keylase/nvidia-patch/master/win/win10_x64/nsd_431.70/nvcuvid.1337) | [Direct link](https://international.download.nvidia.com/Windows/431.70/431.70-notebook-win10-64bit-international-nsd-whql.exe) |
| GeForce        | 435.27  | [Direct link](https://raw.githubusercontent.com/keylase/nvidia-patch/master/win/win10_x64/435.27/nvcuvid.1337) | [Direct link (non-official)](https://github.com/CHEF-KOCH/nVidia-modded-Inf/releases/download/435.27/Nvidia.435.27.rar) |
| GeForce        | 436.02  | [Direct link](https://raw.githubusercontent.com/keylase/nvidia-patch/master/win/win10_x64/436.02/nvcuvid.1337) | [Direct link](https://international.download.nvidia.com/Windows/436.02/436.02-desktop-win10-64bit-international-whql.exe) |



| Product series | Version | Patch | Driver link |
|----------------|---------|-------|----------------------|
| Quadro         | 412.16  | [Direct link](https://raw.githubusercontent.com/keylase/nvidia-patch/master/win/win10_x64/quadro_412.16/nvcuvid.1337) | [Direct link](https://international.download.nvidia.com/Windows/Quadro_Certified/412.16/412.16-quadro-desktop-notebook-win10-64bit-international-whql.exe) |
| Quadro         | 412.29  | [Direct link](https://raw.githubusercontent.com/keylase/nvidia-patch/master/win/win10_x64/quadro_412.29/nvcuvid.1337) | [Direct link](https://international.download.nvidia.com/Windows/Quadro_Certified/412.29/412.29-quadro-desktop-notebook-win10-64bit-international-whql.exe) |
| Quadro         | 416.78  | [Direct link](https://raw.githubusercontent.com/keylase/nvidia-patch/master/win/win10_x64/quadro_416.78/nvcuvid.1337) | [Direct link](https://international.download.nvidia.com/Windows/Quadro_Certified/416.78/416.78-quadro-desktop-notebook-win10-64bit-international-whql.exe) |
| Quadro         | 418.81  | [Direct link](https://raw.githubusercontent.com/keylase/nvidia-patch/master/win/win10_x64/quadro_418.81/nvcuvid.1337) | [Direct link](https://international.download.nvidia.com/Windows/Quadro_Certified/418.81/418.81-quadro-desktop-notebook-win10-64bit-international-whql.exe) |
| Quadro         | 419.17  | [Direct link](https://raw.githubusercontent.com/keylase/nvidia-patch/master/win/win10_x64/quadro_419.17/nvcuvid.1337) | [Direct link](https://international.download.nvidia.com/Windows/Quadro_Certified/419.17/419.17-quadro-desktop-notebook-win10-64bit-international-whql.exe) |
| Quadro         | 419.67  | [Direct link](https://raw.githubusercontent.com/keylase/nvidia-patch/master/win/win10_x64/quadro_419.67/nvcuvid.1337) | [Direct link](https://international.download.nvidia.com/Windows/Quadro_Certified/419.67/419.67-quadro-desktop-notebook-win10-64bit-international-whql.exe) |
| Quadro         | 425.31  | [Direct link](https://raw.githubusercontent.com/keylase/nvidia-patch/master/win/win10_x64/quadro_425.31/nvcuvid.1337) | [Direct link](https://international.download.nvidia.com/Windows/Quadro_Certified/425.31/425.31-quadro-desktop-notebook-win10-64bit-international-whql.exe) |
| Quadro         | 430.39  | [Direct link](https://raw.githubusercontent.com/keylase/nvidia-patch/master/win/win10_x64/quadro_430.39/nvcuvid.1337) | [Direct link](https://international.download.nvidia.com/Windows/Quadro_Certified/430.39/430.39-quadro-desktop-notebook-win10-64bit-international-whql.exe) |
| Quadro         | 430.64  | [Direct link](https://raw.githubusercontent.com/keylase/nvidia-patch/master/win/win10_x64/quadro_430.64/nvcuvid.1337) | [Direct link](https://international.download.nvidia.com/Windows/Quadro_Certified/430.64/430.64-quadro-desktop-notebook-win10-64bit-international-whql.exe) |
| Quadro         | 430.86  | [Direct link](https://raw.githubusercontent.com/keylase/nvidia-patch/master/win/win10_x64/quadro_430.86/nvcuvid.1337) | [Direct link](https://international.download.nvidia.com/Windows/Quadro_Certified/430.86/430.86-quadro-desktop-notebook-win10-64bit-international-whql.exe) |
| Quadro         | 431.02  | [Direct link](https://raw.githubusercontent.com/keylase/nvidia-patch/master/win/win10_x64/quadro_431.02/nvcuvid.1337) | [Direct link](https://international.download.nvidia.com/Windows/Quadro_Certified/431.02/431.02-quadro-desktop-notebook-win10-64bit-international-whql.exe) |
| Quadro         | 431.70  | [Direct link](https://raw.githubusercontent.com/keylase/nvidia-patch/master/win/win10_x64/quadro_431.70/nvcuvid.1337) | [Direct link](https://international.download.nvidia.com/Windows/Quadro_Certified/431.70/431.70-quadro-desktop-notebook-win10-64bit-international-whql.exe) |


### Windows 7, Windows 8, Windows 8.1 drivers


| Product series | Version | Patch | Driver link |
|----------------|---------|-------|----------------------|
| GeForce        | 431.60  | [Direct link](https://raw.githubusercontent.com/keylase/nvidia-patch/master/win/win7_x64/431.60/nvcuvid.1337) | [Direct link](https://international.download.nvidia.com/Windows/431.60/431.60-desktop-win8-win7-64bit-international-whql.exe) |



| Product series | Version | Patch | Driver link |
|----------------|---------|-------|----------------------|
| Quadro         | 431.02  | [Direct link](https://raw.githubusercontent.com/keylase/nvidia-patch/master/win/win7_x64/quadro_431.02/nvcuvid.1337) | [Direct link](https://international.download.nvidia.com/Windows/Quadro_Certified/431.02/431.02-quadro-desktop-notebook-win8-win7-64bit-international-whql.exe) |
| Quadro         | 431.70  | [Direct link](https://raw.githubusercontent.com/keylase/nvidia-patch/master/win/win7_x64/quadro_431.70/nvcuvid.1337) | [Direct link](https://international.download.nvidia.com/Windows/Quadro_Certified/431.70/431.70-quadro-desktop-notebook-win8-win7-64bit-international-whql.exe) |


### Windows Server 2008R2, 2012, 2012R2 drivers


| Product series | Version | Patch | Driver link |
|----------------|---------|-------|----------------------|
| Quadro         | 430.64  | [Direct link](https://raw.githubusercontent.com/keylase/nvidia-patch/master/win/ws2012_x64/quadro_430.64/nvcuvid.1337) | [Direct link](https://international.download.nvidia.com/Windows/Quadro_Certified/430.64/430.64-quadro-winserv2008r2-2012-2012r2-64bit-international-whql.exe) |
| Quadro         | 430.86  | [Direct link](https://raw.githubusercontent.com/keylase/nvidia-patch/master/win/ws2012_x64/quadro_430.86/nvcuvid.1337) | [Direct link](https://international.download.nvidia.com/Windows/Quadro_Certified/430.86/430.86-quadro-winserv2008r2-2012-2012r2-64bit-international-whql.exe) |
| Quadro         | 431.02  | [Direct link](https://raw.githubusercontent.com/keylase/nvidia-patch/master/win/ws2012_x64/quadro_431.02/nvcuvid.1337) | [Direct link](https://international.download.nvidia.com/Windows/Quadro_Certified/431.02/431.02-quadro-winserv2008r2-2012-2012r2-64bit-international-whql.exe) |
| Quadro         | 431.70  | [Direct link](https://raw.githubusercontent.com/keylase/nvidia-patch/master/win/ws2012_x64/quadro_431.70/nvcuvid.1337) | [Direct link](https://international.download.nvidia.com/Windows/Quadro_Certified/431.70/431.70-quadro-winserv2008r2-2012-2012r2-64bit-international-whql.exe) |


### Windows Server 2016, 2019 drivers


| Product series | Version | Patch | Driver link |
|----------------|---------|-------|----------------------|
| Quadro         | 430.86  | [Direct link](https://raw.githubusercontent.com/keylase/nvidia-patch/master/win/ws2016_x64/quadro_430.86/nvcuvid.1337) | [Direct link](https://international.download.nvidia.com/Windows/Quadro_Certified/430.86/430.86-quadro-winserv-2016-2019-64bit-international-whql.exe) |
| Quadro         | 431.02  | [Direct link](https://raw.githubusercontent.com/keylase/nvidia-patch/master/win/ws2016_x64/quadro_431.02/nvcuvid.1337) | [Direct link](https://international.download.nvidia.com/Windows/Quadro_Certified/431.02/431.02-quadro-winserv-2016-2019-64bit-international-whql.exe) |
| Quadro         | 431.70  | [Direct link](https://raw.githubusercontent.com/keylase/nvidia-patch/master/win/ws2016_x64/quadro_431.70/nvcuvid.1337) | [Direct link](https://international.download.nvidia.com/Windows/Quadro_Certified/431.70/431.70-quadro-winserv-2016-2019-64bit-international-whql.exe) |


## See also

* Genesis in [related issue](https://github.com/keylase/nvidia-patch/issues/9)

### Plex Media Server, D3D11 and 32-bit apps encoding sessions

[Related issue](https://github.com/keylase/nvidia-patch/issues/53). Summary: this patch permanently removes limit only for CUDA NVENC sessions in 64bit apps. But once usage limit was exceeded, it persists for all kinds of apps until system reboot. So, for example, you may once open 10 sessions with 64bit version of `ffmpeg` and limit will get raised to 10 for all rest types of apps until reboot. You may follow these steps to achieve this automatically and have all limits raised (assuming patch above already applied):

#### Method 1 (recommended)

1. Download and run [latest release](https://github.com/jantenhove/NvencSessionLimitBump/releases) of [NvencSessionLimitBump](https://github.com/jantenhove/NvencSessionLimitBump).
2. (Optional) Add it to autostart programs.

By default this application raises limit to 32 encoding sessions. Credits to @jantenhove.

#### Method 2 (alternative)

1. Download 64bit FFmpeg for Windows: https://ffmpeg.zeranoe.com/builds/
2. Unpack it somewhere.
3. Get [`ffmpeg_null_10streams.cmd`](ffmpeg_null_10streams.cmd) from this repo.
4. Edit `ffmpeg_null_10streams.cmd` and set executable path to real location of your unpacked ffmpeg.
5. (Optional) Add `ffmpeg_null_10streams.cmd` to autostart programs.

**Bonus**: you may use [this AutoIt script](silent_bump.au3) from @wazerstar for silent startup of console applications bumping sessions.

Also you may use these methods to check if patch applied correctly and limit was raised. Use them when nothing works and you are in doubt.
