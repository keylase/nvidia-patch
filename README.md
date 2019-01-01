# nvidia-patch

This patch removes restriction on maximum number of simultaneous NVENC video encoding sessions imposed by Nvidia to consumer-grade GPUs.

Requirements:
- x86\_64 system architecture
- ubuntu (< 18.04 for 375.39 nvidia driver or kernel < 4.15). Also known to work on Debian and CentOS, but not tested widely.
- nvenc-compatible gpu (https://developer.nvidia.com/video-encode-decode-gpu-support-matrix#Encoder)
- Nvidia driver. Patch availible for: 
  - [375.39](https://download.nvidia.com/XFree86/Linux-x86_64/375.39/NVIDIA-Linux-x86_64-375.39.run)
  - [390.87](https://download.nvidia.com/XFree86/Linux-x86_64/390.87/NVIDIA-Linux-x86_64-390.87.run)
  - [396.24](https://download.nvidia.com/XFree86/Linux-x86_64/396.24/NVIDIA-Linux-x86_64-396.24.run)
  - [396.26](https://uk.download.nvidia.com/tesla/396.26/NVIDIA-Linux-x86_64-396.26.run)
  - [396.37](https://uk.download.nvidia.com/tesla/396.37/NVIDIA-Linux-x86_64-396.37.run)
  - [396.54](https://download.nvidia.com/XFree86/Linux-x86_64/396.54/NVIDIA-Linux-x86_64-396.54.run)
  - 410.48
  - [410.57](https://download.nvidia.com/XFree86/Linux-x86_64/410.57/NVIDIA-Linux-x86_64-410.57.run)
  - [410.73](https://download.nvidia.com/XFree86/Linux-x86_64/410.73/NVIDIA-Linux-x86_64-410.73.run)
  - [410.78](https://download.nvidia.com/XFree86/Linux-x86_64/410.78/NVIDIA-Linux-x86_64-410.78.run)
  - [410.79](https://uk.download.nvidia.com/tesla/410.79/NVIDIA-Linux-x86_64-410.79.run)


Tested on Ubuntu 18.04 LTS (GNU/Linux 4.15.0-23-generic x86\_64)

## step-by-step :

### Download driver
[https://download.nvidia.com/XFree86/Linux-x86\_64/410.78/NVIDIA-Linux-x86\_64-410.78.run](https://download.nvidia.com/XFree86/Linux-x86_64/410.78/NVIDIA-Linux-x86_64-410.78.run)

### Install driver (410.78)
```bash
mkdir /opt/nvidia && cd /opt/nvidia
wget https://download.nvidia.com/XFree86/Linux-x86_64/410.78/NVIDIA-Linux-x86_64-410.78.run
chmod +x ./NVIDIA-Linux-x86_64-410.78.run
./NVIDIA-Linux-x86_64-410.78.run
```

### Check driver
```bash
nvidia-smi
```

### Patch libnvidia-encode.so (with backup)
```bash
bash ./patch.sh
```

### Silent patch libnvidia-encode.so
```bash
bash ./patch.sh -s
```

### Rollback libnvidia-encode.so (restore from backup)
```bash
bash ./patch.sh -r
```

## See also

https://habr.com/post/262563/

If you experience `CreateBitstreamBuffer failed: out of memory (10)`, then you have to lower buffers number used for every encoding session. If you are using `ffmpeg`, consider using this [patch](https://gist.github.com/Snawoot/70ae403716c698cb86ab015626d72bd4).


