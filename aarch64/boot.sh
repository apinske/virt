#!/bin/sh

#wget http://dl-cdn.alpinelinux.org/alpine/v3.12/releases/aarch64/alpine-virt-3.12.0-aarch64.iso
#qemu-img create hd.raw 1G
#qemu-system-aarch64 -nodefaults -nographic -machine virt -cpu host -accel kvm -m 1G -bios /usr/share/qemu-efi-aarch64/QEMU_EFI.fd -blockdev driver=file,node-name=cd,filename=alpine-virt-3.12.0-aarch64.iso -device virtio-blk-device,drive=cd -chardev stdio,id=screen,mux=on,signal=off -serial chardev:screen -monitor chardev:screen -netdev user,id=net,net=10.0.0.0/24 -device virtio-net-device,netdev=net -blockdev driver=file,node-name=hd,filename=hd.raw -device virtio-blk-device,drive=hd

CC="sudo docker run --rm -it -v $PWD:/usr/src/app -w /usr/src/app gcc gcc"

sudo rm hypervisor
$CC -o hypervisor hypervisor.c
./hypervisor

