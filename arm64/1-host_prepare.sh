#!/bin/sh

HIVEMALL_REPOSITORY='https://github.com/amaya382/incubator-hivemall.git'
HIVEMALL_BRANCH='cross-compiling'

mkdir -p tmp
cd tmp

git clone -b ${HIVEMALL_BRANCH} ${HIVEMALL_REPOSITORY} hivemall
cd hivemall
make xgboost-native-linux-arm64

cd ..
wget http://cloud-images.ubuntu.com/xenial/current/xenial-server-cloudimg-arm64-uefi1.img
qemu-img resize xenial-server-cloudimg-arm64-uefi1.img +10G

sudo modprobe nbd max_part=63
sudo qemu-nbd -c /dev/nbd0 xenial-server-cloudimg-arm64-uefi1.img
mkdir mnt
sudo mount /dev/nbd0p1 mnt

sudo cp mnt/boot/vmlinuz-4.4.0-89-generic .
sudo cp mnt/boot/initrd.img-4.4.0-89-generic .
sudo chown ${USER}: *-generic

sudo umount mnt
sudo qemu-nbd -d /dev/nbd0

qemu-system-aarch64 -m 2048 -cpu cortex-a57 -nographic -machine virt \
 -kernel vmlinuz-4.4.0-89-generic \
 -append 'root=/dev/vda1 rw rootwait mem=2048M console=ttyS0 \
  console=ttyAMA0,38400n8 init=/usr/lib/cloud-init/uncloud-init \
  ds=nocloud ubuntu-pass=upass' \
 -drive if=none,id=image,file=xenial-server-cloudimg-arm64-uefi1.img \
 -initrd initrd.img-4.4.0-89-generic \
 -device virtio-blk-device,drive=image \
 -netdev user,id=user0 \
 -device virtio-net-device,netdev=user0 \
 -redir tcp:10022::22
