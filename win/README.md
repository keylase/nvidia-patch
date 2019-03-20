Nvidia drivers patch for Windows
================================

This patch removes restriction on maximum number of simultaneous NVENC video encoding sessions imposed by Nvidia to consumer-grade GPUs.

Requirements:

- Win10 x64
- NVENC-compatible GPU (https://developer.nvidia.com/video-encode-decode-gpu-support-matrix#Encoder)
- Nvidia driver. Patch available for versions in [table below](#version-table).

## Step-by-Step Guide

1. Download and install latest Nvidia driver supported by this patch.
2. Download latest [Win\_1337\_Apply\_Patch tool](https://github.com/Deltafox79/Win_1337_Apply_Patch/releases/latest).
3. Save appropriate patch from [Version Table](#version-table) using direct link to the patch (Right Click -> Save as...). Alternatively you may checkout repo using git or download it as ZIP archive and then locate corresponding .1337 patch file in `win` directory.
4. Apply patch to corresponding file in `%WINDIR%\system32\` with the Win\_1337\_Apply\_Patch tool. File name of patched object is specified in first line of .1337 patch.

E.g, for 64bit Windows 10 running driver version 417.35 use `win10_x64/417.35/nvcuvid.1337` against `C:\WINDOWS\system32\nvcuvid.dll`.

## Version Table

| Product series | Version | Patch | Driver link |
|----------------|---------|-------|----------------------|
| GeForce        | 417.35  | [Direct link](https://raw.githubusercontent.com/keylase/nvidia-patch/master/win/win10_x64/417.35/nvcuvid.1337) | [Direct link](https://international.download.nvidia.com/Windows/417.35/417.35-desktop-win10-64bit-international-whql-rp.exe) |
| GeForce        | 417.58  | [Direct link](https://raw.githubusercontent.com/keylase/nvidia-patch/master/win/win10_x64/417.58/nvcuvid.1337) | [Direct link](https://international.download.nvidia.com/Windows/417.58hf/417.58-desktop-notebook-win10-64bit-international-whql.hf.exe) |
| GeForce        | 417.71  | [Direct link](https://raw.githubusercontent.com/keylase/nvidia-patch/master/win/win10_x64/417.71/nvcuvid.1337) | [Direct link](https://international.download.nvidia.com/Windows/417.71/417.71-desktop-win10-64bit-international-whql.exe) |
| GeForce        | 418.81  | [Direct link](https://raw.githubusercontent.com/keylase/nvidia-patch/master/win/win10_x64/418.81/nvcuvid.1337) | [Direct link](https://international.download.nvidia.com/Windows/418.81/418.81-desktop-win10-64bit-international-whql.exe) |
| GeForce        | 418.91  | [Direct link](https://raw.githubusercontent.com/keylase/nvidia-patch/master/win/win10_x64/418.91/nvcuvid.1337) | [Direct link](https://international.download.nvidia.com/Windows/418.91/418.91-desktop-win10-64bit-international-whql.exe) |
| GeForce        | 419.17  | [Direct link](https://raw.githubusercontent.com/keylase/nvidia-patch/master/win/win10_x64/419.17/nvcuvid.1337) | [Direct link](https://international.download.nvidia.com/Windows/419.17/419.17-desktop-win10-64bit-international-whql.exe) |
| GeForce        | 419.35  | [Direct link](https://raw.githubusercontent.com/keylase/nvidia-patch/master/win/win10_x64/419.35/nvcuvid.1337) | [Direct link](https://international.download.nvidia.com/Windows/419.35/419.35-desktop-win10-64bit-international-whql.exe) |
| Quadro         | 412.16  | [Direct link](https://raw.githubusercontent.com/keylase/nvidia-patch/master/win/win10_x64/quadro_412.16/nvcuvid.1337) | [Direct link](https://international.download.nvidia.com/Windows/Quadro_Certified/412.16/412.16-quadro-desktop-notebook-win10-64bit-international-whql.exe) |
| Quadro         | 412.29  | [Direct link](https://raw.githubusercontent.com/keylase/nvidia-patch/master/win/win10_x64/quadro_412.29/nvcuvid.1337) | [Direct link](https://international.download.nvidia.com/Windows/Quadro_Certified/412.29/412.29-quadro-desktop-notebook-win10-64bit-international-whql.exe) |
| Quadro         | 416.78  | [Direct link](https://raw.githubusercontent.com/keylase/nvidia-patch/master/win/win10_x64/quadro_416.78/nvcuvid.1337) | [Direct link](https://international.download.nvidia.com/Windows/Quadro_Certified/416.78/416.78-quadro-desktop-notebook-win10-64bit-international-whql.exe) |
| Quadro         | 418.81  | [Direct link](https://raw.githubusercontent.com/keylase/nvidia-patch/master/win/win10_x64/quadro_418.81/nvcuvid.1337) | [Direct link](https://international.download.nvidia.com/Windows/Quadro_Certified/418.81/418.81-quadro-desktop-notebook-win10-64bit-international-whql.exe) |
| Quadro         | 419.17  | [Direct link](https://raw.githubusercontent.com/keylase/nvidia-patch/master/win/win10_x64/quadro_419.17/nvcuvid.1337) | [Direct link](https://international.download.nvidia.com/Windows/Quadro_Certified/419.17/419.17-quadro-desktop-notebook-win10-64bit-international-whql.exe) |
| Quadro         | 419.67  | [Direct link](https://raw.githubusercontent.com/keylase/nvidia-patch/master/win/win10_x64/quadro_419.67/nvcuvid.1337) | [Direct link](https://international.download.nvidia.com/Windows/Quadro_Certified/419.67/419.67-quadro-desktop-notebook-win10-64bit-international-whql.exe) |

## See also

* Genesis in [related issue](https://github.com/keylase/nvidia-patch/issues/9)

### D3D11 and 32-bit apps encoding sessions

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
