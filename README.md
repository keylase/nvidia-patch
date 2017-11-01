# nvidia-patch

requirements:
- ubuntu 14.04
- nvenc-compatible gpu
- nvidia 375.39 driver

# install driver nvidia 375.39 :

Download driver: https://yadi.sk/d/yahf1Y-D3PJnzd

chmod +x ./NVIDIA-Linux-x86_64-375.39.run
./NVIDIA-Linux-x86_64-375.39.run

check driver:

nvidia-smi

mkdir ~/nvenc_backup

cd ~/nvenc_backup

cp /usr/lib/x86_64-linux-gnu/libnvidia-encode.so.375.39 ~/nvenc_backup/

wget https://raw.githubusercontent.com/keylase/nvidia-patch/master/patch.sh

chmod +x patch.sh

./patch.sh ~/nvenc_backup/libnvidia-encode.so.375.39 /usr/lib/x86_64-linux-gnu/libnvidia-encode.so.375.39

reboot





