# nvidia-patch

requirements:
- Ubuntu 17.10
- nvenc-compatible gpu
- kernel (<4.10.0)- 4.4.0-101-generic
- nvidia 378.13 driver

# step-by-step :

Download driver: https://yadi.sk/d/d87mf0y03WTbb5

chmod +x ./NVIDIA-Linux-x86_64-378.13.run

./NVIDIA-Linux-x86_64-378.13.run

# check driver:

nvidia-smi

mkdir ~/nvenc_backup

cd ~/nvenc_backup

cp /usr/lib/x86_64-linux-gnu/libnvidia-encode.so.378.13 ~/nvenc_backup/

wget https://raw.githubusercontent.com/keylase/nvidia-patch/master/patch.sh

chmod +x patch.sh

./patch.sh ~/nvenc_backup/libnvidia-encode.so.378.13 /usr/lib/x86_64-linux-gnu/libnvidia-encode.so.378.13

reboot
```

## See also

If you experience `CreateBitstreamBuffer failed: out of memory (10)`, then you have to lower buffers number used for every encoding session. If you are using `ffmpeg`, consider using this [patch](https://gist.github.com/Snawoot/70ae403716c698cb86ab015626d72bd4).




