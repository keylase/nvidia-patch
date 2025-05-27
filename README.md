NVENC and NvFBC patches for Nvidia drivers
==========================================

![GitHub last commit](https://img.shields.io/github/last-commit/keylase/nvidia-patch.svg) ![Latest version](https://img.shields.io/badge/latest%20linux%20driver%20version-575.51.02-brightgreen.svg)

[NVENC patch](patch.sh) removes restriction on maximum number of simultaneous NVENC video encoding sessions imposed by Nvidia to consumer-grade GPUs.

[NvFBC patch](patch-fbc.sh) allows to use NvFBC on consumer-grade GPUs. It should be applied same way as NVENC `patch.sh`, except you have to use `patch-fbc.sh` instead.

Main target operating system is **GNU/Linux**, but for **Windows** support see [**win** (clickable)](win).

---

If you like this project, best way to contribute is by sending PRs and fixing documentation.

If you want to donate, please send it to your favorite open source organizations, for example [FFmpeg](https://www.ffmpeg.org/donations.html), [VideoLAN](http://www.videolan.org/contribute.html#money)

---

## Requirements
- x86\_64 system architecture
- GNU/Linux operating system
- nvenc-compatible gpu (https://developer.nvidia.com/video-encode-decode-gpu-support-matrix#Encoder)
- Nvidia driver. Patch available for versions in version table below.

## Version Table

| Version | NVENC patch | NVFBC patch | Driver link |
| :---    |    :---:    |    :---:    |        ---: |
| 375.39 | YES | NO | [Driver link](https://download.nvidia.com/XFree86/Linux-x86_64/375.39/NVIDIA-Linux-x86_64-375.39.run) |
| 390.77 | YES | NO | [Driver link](https://download.nvidia.com/XFree86/Linux-x86_64/390.77/NVIDIA-Linux-x86_64-390.77.run) |
| 390.87 | YES | NO | [Driver link](https://download.nvidia.com/XFree86/Linux-x86_64/390.87/NVIDIA-Linux-x86_64-390.87.run) |
| 390.147 | YES | NO | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/390.147/NVIDIA-Linux-x86_64-390.147.run) |
| 396.24 | YES | NO | [Driver link](https://download.nvidia.com/XFree86/Linux-x86_64/396.24/NVIDIA-Linux-x86_64-396.24.run) |
| 396.26 | YES | NO | [Driver link](https://international.download.nvidia.com/tesla/396.26/NVIDIA-Linux-x86_64-396.26.run) |
| 396.37 | YES | NO | [Driver link](https://international.download.nvidia.com/tesla/396.37/NVIDIA-Linux-x86_64-396.37.run) |
| 396.54 | YES | NO | [Driver link](https://download.nvidia.com/XFree86/Linux-x86_64/396.54/NVIDIA-Linux-x86_64-396.54.run) |
| 410.48 | YES | NO |  |
| 410.57 | YES | NO | [Driver link](https://download.nvidia.com/XFree86/Linux-x86_64/410.57/NVIDIA-Linux-x86_64-410.57.run) |
| 410.73 | YES | NO | [Driver link](https://download.nvidia.com/XFree86/Linux-x86_64/410.73/NVIDIA-Linux-x86_64-410.73.run) |
| 410.78 | YES | NO | [Driver link](https://download.nvidia.com/XFree86/Linux-x86_64/410.78/NVIDIA-Linux-x86_64-410.78.run) |
| 410.79 | YES | NO | [Driver link](https://international.download.nvidia.com/tesla/410.79/NVIDIA-Linux-x86_64-410.79.run) |
| 410.93 | YES | NO | [Driver link](https://download.nvidia.com/XFree86/Linux-x86_64/410.93/NVIDIA-Linux-x86_64-410.93.run) |
| 410.104 | YES | NO | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/410.104/NVIDIA-Linux-x86_64-410.104.run) |
| 415.18 | YES | NO | [Driver link](https://download.nvidia.com/XFree86/Linux-x86_64/415.18/NVIDIA-Linux-x86_64-415.18.run) |
| 415.25 | YES | NO | [Driver link](https://download.nvidia.com/XFree86/Linux-x86_64/415.25/NVIDIA-Linux-x86_64-415.25.run) |
| 415.27 | YES | NO | [Driver link](https://download.nvidia.com/XFree86/Linux-x86_64/415.27/NVIDIA-Linux-x86_64-415.27.run) |
| 418.30 | YES | NO | [Driver link](https://download.nvidia.com/XFree86/Linux-x86_64/418.30/NVIDIA-Linux-x86_64-418.30.run) |
| 418.43 | YES | NO | [Driver link](https://download.nvidia.com/XFree86/Linux-x86_64/418.43/NVIDIA-Linux-x86_64-418.43.run) |
| 418.56 | YES | NO | [Driver link](https://download.nvidia.com/XFree86/Linux-x86_64/418.56/NVIDIA-Linux-x86_64-418.56.run) |
| 418.67 | YES | NO | [Driver link](https://international.download.nvidia.com/tesla/418.67/NVIDIA-Linux-x86_64-418.67.run) |
| 418.74 | YES | NO | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/418.74/NVIDIA-Linux-x86_64-418.74.run) |
| 418.87.00 | YES | NO | [Driver link](https://international.download.nvidia.com/tesla/418.87/NVIDIA-Linux-x86_64-418.87.00.run) |
| 418.87.01 | YES | NO | [Driver link](https://international.download.nvidia.com/tesla/418.87/NVIDIA-Linux-x86_64-418.87.01.run) |
| 418.88 | YES | NO | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/418.88/NVIDIA-Linux-x86_64-418.88.run) |
| 418.113 | YES | NO | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/418.113/NVIDIA-Linux-x86_64-418.113.run) |
| 430.09 | YES | NO | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/430.09/NVIDIA-Linux-x86_64-430.09.run) |
| 430.14 | YES | NO | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/430.14/NVIDIA-Linux-x86_64-430.14.run) |
| 430.26 | YES | NO | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/430.26/NVIDIA-Linux-x86_64-430.26.run) |
| 430.34 | YES | NO | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/430.34/NVIDIA-Linux-x86_64-430.34.run) |
| 430.40 | YES | NO | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/430.40/NVIDIA-Linux-x86_64-430.40.run) |
| 430.50 | YES | NO | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/430.50/NVIDIA-Linux-x86_64-430.50.run) |
| 430.64 | YES | NO | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/430.64/NVIDIA-Linux-x86_64-430.64.run) |
| 435.17 | YES | NO | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/435.17/NVIDIA-Linux-x86_64-435.17.run) |
| 435.21 | YES | NO | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/435.21/NVIDIA-Linux-x86_64-435.21.run) |
| 440.26 | YES | YES | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/440.26/NVIDIA-Linux-x86_64-440.26.run) |
| 440.31 | YES | YES | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/440.31/NVIDIA-Linux-x86_64-440.31.run) |
| 440.33.01 | YES | YES | [Driver link](https://international.download.nvidia.com/tesla/440.33.01/NVIDIA-Linux-x86_64-440.33.01.run) |
| 440.36 | YES | YES | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/440.36/NVIDIA-Linux-x86_64-440.36.run) |
| 440.43.01 | YES | YES |  |
| 440.44 | YES | YES | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/440.44/NVIDIA-Linux-x86_64-440.44.run) |
| 440.48.02 | YES | YES |  |
| 440.58.01 | YES | YES |  |
| 440.58.02 | YES | YES |  |
| 440.59 | YES | YES | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/440.59/NVIDIA-Linux-x86_64-440.59.run) |
| 440.64 | YES | YES | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/440.64/NVIDIA-Linux-x86_64-440.64.run) |
| 440.64.00 | YES | YES | [Driver link](https://international.download.nvidia.com/tesla/440.64.00/NVIDIA-Linux-x86_64-440.64.00.run) |
| 440.66.02 | YES | YES |  |
| 440.66.03 | YES | YES |  |
| 440.66.04 | YES | YES |  |
| 440.66.08 | YES | YES |  |
| 440.66.09 | YES | YES |  |
| 440.66.11 | YES | YES |  |
| 440.66.12 | YES | YES |  |
| 440.66.14 | YES | YES |  |
| 440.66.15 | YES | YES |  |
| 440.66.17 | YES | YES |  |
| 440.82 | YES | YES | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/440.82/NVIDIA-Linux-x86_64-440.82.run) |
| 440.95.01 | YES | YES | [Driver link](https://international.download.nvidia.com/tesla/440.95.01/NVIDIA-Linux-x86_64-440.95.01.run) |
| 440.100 | YES | YES | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/440.100/NVIDIA-Linux-x86_64-440.100.run) |
| 440.118.02 | YES | YES | [Driver link](https://international.download.nvidia.com/tesla/440.118.02/NVIDIA-Linux-x86_64-440.118.02.run) |
| 450.36.06 | YES | YES | [Driver link](https://developer.download.nvidia.com/compute/cuda/11.0.1/local_installers/cuda_11.0.1_450.36.06_linux.run) |
| 450.51 | YES | YES | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/450.51/NVIDIA-Linux-x86_64-450.51.run) |
| 450.51.05 | YES | YES | [Driver link](https://international.download.nvidia.com/tesla/450.51.05/NVIDIA-Linux-x86_64-450.51.05.run) |
| 450.51.06 | YES | YES | [Driver link](https://international.download.nvidia.com/tesla/450.51.06/NVIDIA-Linux-x86_64-450.51.06.run) |
| 450.56.01 | YES | YES |  |
| 450.56.02 | YES | YES |  |
| 450.56.06 | YES | YES |  |
| 450.56.11 | YES | YES |  |
| 450.57 | YES | YES | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/450.57/NVIDIA-Linux-x86_64-450.57.run) |
| 450.66 | YES | YES | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/450.66/NVIDIA-Linux-x86_64-450.66.run) |
| 450.80.02 | YES | YES | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/450.80.02/NVIDIA-Linux-x86_64-450.80.02.run) |
| 450.102.04 | YES | NO | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/450.102.04/NVIDIA-Linux-x86_64-450.102.04.run) |
| 455.22.04 | YES | NO |  |
| 455.23.04 | YES | YES | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/455.23.04/NVIDIA-Linux-x86_64-455.23.04.run) |
| 455.23.05 | YES | YES |  |
| 455.26.01 | YES | YES |  |
| 455.26.02 | YES | YES |  |
| 455.28 | YES | YES | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/455.28/NVIDIA-Linux-x86_64-455.28.run) |
| 455.32.00 | YES | YES |  |
| 455.38 | YES | YES | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/455.38/NVIDIA-Linux-x86_64-455.38.run) |
| 455.45.01 | YES | YES | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/455.45.01/NVIDIA-Linux-x86_64-455.45.01.run) |
| 455.46.01 | YES | YES |  |
| 455.46.02 | YES | YES |  |
| 455.46.04 | YES | YES |  |
| 455.50.02 | YES | YES |  |
| 455.50.03 | NO | YES |  |
| 455.50.04 | YES | YES |  |
| 455.50.05 | YES | YES |  |
| 455.50.07 | YES | YES |  |
| 455.50.10 | YES | YES |  |
| 460.27.04 | YES | YES | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/460.27.04/NVIDIA-Linux-x86_64-460.27.04.run) |
| 460.32.03 | YES | YES | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/460.32.03/NVIDIA-Linux-x86_64-460.32.03.run) |
| 460.39 | YES | YES | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/460.39/NVIDIA-Linux-x86_64-460.39.run) |
| 460.56 | YES | YES | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/460.56/NVIDIA-Linux-x86_64-460.56.run) |
| 460.67 | YES | YES | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/460.67/NVIDIA-Linux-x86_64-460.67.run) |
| 460.73.01 | YES | YES | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/460.73.01/NVIDIA-Linux-x86_64-460.73.01.run) |
| 460.80 | YES | YES | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/460.80/NVIDIA-Linux-x86_64-460.80.run) |
| 460.84 | YES | YES | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/460.84/NVIDIA-Linux-x86_64-460.84.run) |
| 460.91.03 | YES | YES | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/460.91.03/NVIDIA-Linux-x86_64-460.91.03.run) |
| 465.19.01 | YES | YES | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/465.19.01/NVIDIA-Linux-x86_64-465.19.01.run) |
| 465.24.02 | YES | YES | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/465.24.02/NVIDIA-Linux-x86_64-465.24.02.run) |
| 465.27 | YES | YES | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/465.27/NVIDIA-Linux-x86_64-465.27.run) |
| 465.31 | YES | YES | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/465.31/NVIDIA-Linux-x86_64-465.31.run) |
| 470.42.01 | YES | YES | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/470.42.01/NVIDIA-Linux-x86_64-470.42.01.run) |
| 470.57.02 | YES | YES | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/470.57.02/NVIDIA-Linux-x86_64-470.57.02.run) |
| 470.62.02 | YES | YES |  |
| 470.62.05 | YES | YES |  |
| 470.63.01 | YES | YES | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/470.63.01/NVIDIA-Linux-x86_64-470.63.01.run) |
| 470.74 | YES | YES | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/470.74/NVIDIA-Linux-x86_64-470.74.run) |
| 470.82.00 | YES | YES | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/470.82.00/NVIDIA-Linux-x86_64-470.82.00.run) |
| 470.82.01 | YES | YES | [Driver link](https://international.download.nvidia.com/tesla/470.82.01/NVIDIA-Linux-x86_64-470.82.01.run) |
| 470.86 | YES | YES | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/470.86/NVIDIA-Linux-x86_64-470.86.run) |
| 470.94 | YES | YES | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/470.94/NVIDIA-Linux-x86_64-470.94.run) |
| 470.103.01 | YES | YES | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/470.103.01/NVIDIA-Linux-x86_64-470.103.01.run) |
| 470.129.06 | YES | YES | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/470.129.06/NVIDIA-Linux-x86_64-470.129.06.run) |
| 470.141.03 | YES | YES | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/470.141.03/NVIDIA-Linux-x86_64-470.141.03.run) |
| 470.161.03 | YES | YES | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/470.161.03/NVIDIA-Linux-x86_64-470.161.03.run) |
| 470.182.03 | YES | YES | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/470.182.03/NVIDIA-Linux-x86_64-470.182.03.run) |
| 470.199.02 | YES | YES | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/470.199.02/NVIDIA-Linux-x86_64-470.199.02.run) |
| 470.223.02 | YES | YES | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/470.223.02/NVIDIA-Linux-x86_64-470.223.02.run) |
| 470.239.06 | YES | YES | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/470.239.06/NVIDIA-Linux-x86_64-470.239.06.run) |
| 470.256.02 | YES | YES | [Driver link](http://international.download.nvidia.com/XFree86/Linux-x86_64/470.256.02/NVIDIA-Linux-x86_64-470.256.02.run) |
| 495.29.05 | YES | YES | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/495.29.05/NVIDIA-Linux-x86_64-495.29.05.run) |
| 495.44 | YES | YES | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/495.44/NVIDIA-Linux-x86_64-495.44.run) |
| 495.46 | YES | YES | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/495.46/NVIDIA-Linux-x86_64-495.46.run) |
| 510.39.01 | YES | YES | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/510.39.01/NVIDIA-Linux-x86_64-510.39.01.run) |
| 510.47.03 | YES | YES | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/510.47.03/NVIDIA-Linux-x86_64-510.47.03.run) |
| 510.54 | YES | YES | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/510.54/NVIDIA-Linux-x86_64-510.54.run) |
| 510.60.02 | YES | YES | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/510.60.02/NVIDIA-Linux-x86_64-510.60.02.run) |
| 510.68.02 | YES | YES | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/510.68.02/NVIDIA-Linux-x86_64-510.68.02.run) |
| 510.73.05 | YES | YES | [Driver link](http://international.download.nvidia.com/XFree86/Linux-x86_64/510.73.05/NVIDIA-Linux-x86_64-510.73.05.run) |
| 510.73.08 | YES | YES | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/510.73.08/NVIDIA-Linux-x86_64-510.73.08.run) |
| 510.85.02 | YES | YES | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/510.85.02/NVIDIA-Linux-x86_64-510.85.02.run) |
| 510.108.03 | YES | YES | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/510.108.03/NVIDIA-Linux-x86_64-510.108.03.run) |
| 515.43.04 | YES | YES | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/515.43.04/NVIDIA-Linux-x86_64-515.43.04.run) |
| 515.48.07 | YES | YES | [Driver link](http://international.download.nvidia.com/XFree86/Linux-x86_64/515.48.07/NVIDIA-Linux-x86_64-515.48.07.run) |
| 515.57 | YES | YES | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/515.57/NVIDIA-Linux-x86_64-515.57.run) |
| 515.65.01 | YES | YES | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/515.65.01/NVIDIA-Linux-x86_64-515.65.01.run) |
| 515.76 | YES | YES | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/515.76/NVIDIA-Linux-x86_64-515.76.run) |
| 515.86.01 | YES | YES | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/515.86.01/NVIDIA-Linux-x86_64-515.86.01.run) |
| 515.105.01 | YES | YES | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/515.105.01/NVIDIA-Linux-x86_64-515.105.01.run) |
| 520.56.06 | YES | YES | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/520.56.06/NVIDIA-Linux-x86_64-520.56.06.run) |
| 520.61.05 | YES | YES | [Driver link](https://developer.download.nvidia.com/compute/cuda/11.8.0/local_installers/cuda_11.8.0_520.61.05_linux.run) |
| 525.60.11 | YES | YES | [Driver link](http://international.download.nvidia.com/XFree86/Linux-x86_64/525.60.11/NVIDIA-Linux-x86_64-525.60.11.run) |
| 525.60.13 | YES | YES |  |
| 525.78.01 | YES | YES | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/525.78.01/NVIDIA-Linux-x86_64-525.78.01.run) |
| 525.85.05 | YES | YES | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/525.85.05/NVIDIA-Linux-x86_64-525.85.05.run) |
| 525.85.12 | YES | YES |  |
| 525.89.02 | YES | YES | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/525.89.02/NVIDIA-Linux-x86_64-525.89.02.run) |
| 525.105.17 | YES | YES | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/525.105.17/NVIDIA-Linux-x86_64-525.105.17.run) |
| 525.116.03 | YES | YES | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/525.116.03/NVIDIA-Linux-x86_64-525.116.03.run) |
| 525.116.04 | YES | YES | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/525.116.04/NVIDIA-Linux-x86_64-525.116.04.run) |
| 525.125.06 | YES | YES | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/525.125.06/NVIDIA-Linux-x86_64-525.125.06.run) |
| 525.147.05 | YES | YES | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/525.147.05/NVIDIA-Linux-x86_64-525.147.05.run) |
| 530.30.02 | YES | YES | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/530.30.02/NVIDIA-Linux-x86_64-530.30.02.run) |
| 530.41.03 | YES | YES | [Driver link](http://international.download.nvidia.com/XFree86/Linux-x86_64/530.41.03/NVIDIA-Linux-x86_64-530.41.03.run) |
| 535.43.02 | YES | YES | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/535.43.02/NVIDIA-Linux-x86_64-535.43.02.run) |
| 535.43.25 | YES | YES | [Driver link](https://developer.nvidia.com/downloads/vulkan-beta-5354325-linux) |
| 535.54.03 | YES | YES | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/535.54.03/NVIDIA-Linux-x86_64-535.54.03.run) |
| 535.86.05 | YES | YES | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/535.86.05/NVIDIA-Linux-x86_64-535.86.05.run) |
| 535.86.10 | YES | YES |  |
| 535.98 | YES | YES | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/535.98/NVIDIA-Linux-x86_64-535.98.run) |
| 535.104.05 | YES | YES | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/535.104.05/NVIDIA-Linux-x86_64-535.104.05.run) |
| 535.104.12 | YES | YES | [Driver link](https://international.download.nvidia.com/tesla/535.104.12/NVIDIA-Linux-x86_64-535.104.12.run) |
| 535.113.01 | YES | YES | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/535.113.01/NVIDIA-Linux-x86_64-535.113.01.run) |
| 535.129.03 | YES | YES | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/535.129.03/NVIDIA-Linux-x86_64-535.129.03.run) |
| 535.146.02 | YES | YES | [Driver link](http://international.download.nvidia.com/XFree86/Linux-x86_64/535.146.02/NVIDIA-Linux-x86_64-535.146.02.run) |
| 535.154.05 | YES | YES | [Driver link](http://international.download.nvidia.com/XFree86/Linux-x86_64/535.154.05/NVIDIA-Linux-x86_64-535.154.05.run) |
| 535.161.07 | YES | YES | [Driver link](http://international.download.nvidia.com/XFree86/Linux-x86_64/535.161.07/NVIDIA-Linux-x86_64-535.161.07.run) |
| 535.161.08 | YES | YES |  |
| 535.171.04 | YES | YES | [Driver link](http://international.download.nvidia.com/XFree86/Linux-x86_64/535.171.04/NVIDIA-Linux-x86_64-535.171.04.run) |
| 535.183.01 | YES | YES | [Driver link](http://international.download.nvidia.com/XFree86/Linux-x86_64/535.183.01/NVIDIA-Linux-x86_64-535.183.01.run) |
| 535.183.06 | YES | YES | [Driver link](http://international.download.nvidia.com/tesla/535.183.06/NVIDIA-Linux-x86_64-535.183.06.run) |
| 535.216.01 | YES | YES | [Driver link](http://international.download.nvidia.com/XFree86/Linux-x86_64/535.216.01/NVIDIA-Linux-x86_64-535.216.01.run) |
| 535.230.02 | YES | YES | [Driver link](http://international.download.nvidia.com/XFree86/Linux-x86_64/535.230.02/NVIDIA-Linux-x86_64-535.230.02.run) |
| 535.247.01 | YES | YES | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/535.247.01/NVIDIA-Linux-x86_64-535.247.01.run) |
| 545.23.06 | YES | YES | [Driver link](http://international.download.nvidia.com/XFree86/Linux-x86_64/545.23.06/NVIDIA-Linux-x86_64-545.23.06.run) |
| 545.23.08 | YES | YES |  |
| 545.29.02 | YES | YES | [Driver link](http://international.download.nvidia.com/XFree86/Linux-x86_64/545.29.02/NVIDIA-Linux-x86_64-545.29.02.run) |
| 545.29.06 | YES | YES | [Driver link](http://international.download.nvidia.com/XFree86/Linux-x86_64/545.29.06/NVIDIA-Linux-x86_64-545.29.06.run) |
| 550.40.07 | YES | YES | [Driver link](http://international.download.nvidia.com/XFree86/Linux-x86_64/550.40.07/NVIDIA-Linux-x86_64-550.40.07.run) |
| 550.54.14 | YES | YES | [Driver link](http://international.download.nvidia.com/XFree86/Linux-x86_64/550.54.14/NVIDIA-Linux-x86_64-550.54.14.run) |
| 550.54.15 | YES | YES |  |
| 550.67 | YES | YES | [Driver link](http://international.download.nvidia.com/XFree86/Linux-x86_64/550.67/NVIDIA-Linux-x86_64-550.67.run) |
| 550.76 | YES | YES | [Driver link](http://international.download.nvidia.com/XFree86/Linux-x86_64/550.76/NVIDIA-Linux-x86_64-550.76.run) |
| 550.78 | YES | YES | [Driver link](http://international.download.nvidia.com/XFree86/Linux-x86_64/550.78/NVIDIA-Linux-x86_64-550.78.run) |
| 550.90.07 | YES | YES | [Driver link](http://international.download.nvidia.com/XFree86/Linux-x86_64/550.90.07/NVIDIA-Linux-x86_64-550.90.07.run) |
| 550.100 | YES | YES | [Driver link](http://international.download.nvidia.com/XFree86/Linux-x86_64/550.100/NVIDIA-Linux-x86_64-550.100.run) |
| 550.107.02 | YES | YES | [Driver link](http://international.download.nvidia.com/XFree86/Linux-x86_64/550.107.02/NVIDIA-Linux-x86_64-550.107.02.run) |
| 550.120 | YES | YES | [Driver link](http://international.download.nvidia.com/XFree86/Linux-x86_64/550.120/NVIDIA-Linux-x86_64-550.120.run) |
| 550.127.05 | YES | YES | [Driver link](http://international.download.nvidia.com/XFree86/Linux-x86_64/550.127.05/NVIDIA-Linux-x86_64-550.127.05.run) |
| 550.135 | YES | YES | [Driver link](http://international.download.nvidia.com/XFree86/Linux-x86_64/550.135/NVIDIA-Linux-x86_64-550.135.run) |
| 550.142 | YES | YES | [Driver link](http://international.download.nvidia.com/XFree86/Linux-x86_64/550.142/NVIDIA-Linux-x86_64-550.142.run) |
| 550.163.01 | YES | YES | [Driver link](http://international.download.nvidia.com/XFree86/Linux-x86_64/550.163.01/NVIDIA-Linux-x86_64-550.163.01.run) |
| 555.42.02 | YES | YES | [Driver link](http://international.download.nvidia.com/XFree86/Linux-x86_64/555.42.02/NVIDIA-Linux-x86_64-555.42.02.run) |
| 555.58 | YES | YES | [Driver link](http://international.download.nvidia.com/XFree86/Linux-x86_64/555.58/NVIDIA-Linux-x86_64-555.58.run) |
| 555.58.02 | YES | YES | [Driver link](http://international.download.nvidia.com/XFree86/Linux-x86_64/555.58.02/NVIDIA-Linux-x86_64-555.58.02.run) |
| 560.28.03 | YES | NO | [Driver link](http://international.download.nvidia.com/XFree86/Linux-x86_64/560.28.03/NVIDIA-Linux-x86_64-560.28.03.run) |
| 560.35.03 | YES | NO | [Driver link](http://international.download.nvidia.com/XFree86/Linux-x86_64/560.35.03/NVIDIA-Linux-x86_64-560.35.03.run) |
| 560.35.05 | YES | NO | [Driver link](https://developer.download.nvidia.com/compute/cuda/12.6.3/local_installers/cuda_12.6.3_560.35.05_linux.run) |
| 565.57.01 | YES | NO | [Driver link](http://international.download.nvidia.com/XFree86/Linux-x86_64/565.57.01/NVIDIA-Linux-x86_64-565.57.01.run) |
| 565.77 | YES | NO | [Driver link](http://international.download.nvidia.com/XFree86/Linux-x86_64/565.77/NVIDIA-Linux-x86_64-565.77.run) |
| 570.86.15 | YES | YES | [Driver link](http://international.download.nvidia.com/tesla/570.86.15/NVIDIA-Linux-x86_64-570.86.15.run) |
| 570.86.16 | YES | YES | [Driver link](http://international.download.nvidia.com/XFree86/Linux-x86_64/570.86.16/NVIDIA-Linux-x86_64-570.86.16.run) |
| 570.124.04 | YES | YES | [Driver link](http://international.download.nvidia.com/XFree86/Linux-x86_64/570.124.04/NVIDIA-Linux-x86_64-570.124.04.run) |
| 570.124.06 | YES | YES | [Driver link](https://developer.download.nvidia.com/compute/cuda/repos/debian12/x86_64/cuda-drivers-570_570.124.06-1_amd64.deb) |
| 570.133.07 | YES | YES | [Driver link](http://international.download.nvidia.com/XFree86/Linux-x86_64/570.133.07/NVIDIA-Linux-x86_64-570.133.07.run) |
| 570.133.20 | YES | YES | [Driver link](https://international.download.nvidia.com/tesla/570.133.20/NVIDIA-Linux-x86_64-570.133.20.run) |
| 570.144 | YES | YES | [Driver link](https://international.download.nvidia.com/XFree86/Linux-x86_64/570.144/NVIDIA-Linux-x86_64-570.144.run) |
| 570.153.02 | YES | YES | [Driver link](http://international.download.nvidia.com/XFree86/Linux-x86_64/570.153.02/NVIDIA-Linux-x86_64-570.153.02.run) |
| 575.51.02 | YES | YES | [Driver link](http://international.download.nvidia.com/XFree86/Linux-x86_64/575.51.02/NVIDIA-Linux-x86_64-575.51.02.run) |

## Synopsis

```
# bash ./patch.sh -h

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

```

```
# bash ./patch-fbc.sh -h

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

```

## Step-by-Step guide

Examples are provided for driver version 430.50. All commands are executed as root.

### Download and install driver

Skip this step if you already have installed driver with version supported by this patch.

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
You can also check if [ffmpeg can encode without limit](https://github.com/keylase/nvidia-patch/wiki/Verify-NVENC-patch), and check NVFBC via OBS.

### Patch driver

This patch performs backup of original file prior to making changes.

```bash
bash ./patch.sh
```

You're all set!

**Note:** Sometimes distribution installed drivers are not found by the patch script. In that case, please uninstall the nvidia driver using your distribution package manager, and install it using the steps [above](#download-and-install-driver).

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

## Flatpak support

If you use a Flatpak app that uses NVENC/NvFBC (e.g. OBS Studio, Kdenlive), it's recommended that you patch the NVIDIA drivers for Flatpak as well. To do so, just pass the `-f` parameter to either `patch.sh` or `patch-fbc.sh`, like so:

```bash
bash ./patch.sh -f
bash ./patch-fbc.sh -f
```

In case something goes wrong, you can restore the original Flatpak drivers by adding the `-r` paramater:

```
bash ./patch.sh -f -r
bash ./patch-fbc.sh -f -r
```

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
  * [Original post in Russian](https://web.archive.org/web/20201111201711/https://habr.com/en/post/262563/)
  * [3rd party English translation](https://web.archive.org/web/20190904221644/https://weekly-geekly.github.io/articles/262563/index.html)

If you experience `CreateBitstreamBuffer failed: out of memory (10)`, then you have to lower buffers number used for every encoding session. If you are using `ffmpeg`, see option `-surfaces` ("Number of concurrent surfaces") and try value near `-surfaces 8`.
