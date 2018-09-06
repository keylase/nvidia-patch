# nvidia-patch


Requirements:
- ubuntu (< 18.04 for 375.39 nvidia driver or kernel < 4.15)
- nvenc-compatible gpu (https://developer.nvidia.com/video-encode-decode-gpu-support-matrix#Encoder)
- nvidia driver (patch availible for 375.39, 396.24, 396.26, 396.37)


Tested on Ubuntu 18.04 LTS (GNU/Linux 4.15.0-23-generic x86_64)

## step-by-step :

### Download driver
http://us.download.nvidia.com/XFree86/Linux-x86_64/375.39/NVIDIA-Linux-x86_64-375.39.run
http://us.download.nvidia.com/XFree86/Linux-x86_64/396.24/NVIDIA-Linux-x86_64-396.24.run

### Install driver 396.24
```bash
mkdir /opt/nvidia && cd /opt/nvidia
wget http://us.download.nvidia.com/XFree86/Linux-x86_64/396.24/NVIDIA-Linux-x86_64-396.24.run
chmod +x ./NVIDIA-Linux-x86_64-396.24.run
./NVIDIA-Linux-x86_64-396.24.run
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




