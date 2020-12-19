#!/bin/sh

#doctl compute droplet create --image ubuntu-20-04-x64 --size s-1vcpu-1gb --region fra1 --ssh-keys $(doctl compute ssh-key list --format ID --no-header) --wait playground

if [ ! -d mnt ]; then
   # apt update
   apt install make clang llvm lld flex bison libelf-dev libncurses-dev libssl-dev
fi

if [ ! -d linux-5.9.13 ]; then
    wget https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.9.13.tar.xz
    tar xf linux-5.9.13.tar.xz
fi
cd linux-5.9.13
cp ../config-linux-$ARCH .config
if [ "$ARCH" = "x86_64" ]; then
    unset ARCH
    make CC=clang LLVM=1 -j2
    cp arch/x86/boot/bzImage ../vmlinuz
    cp .config ../config-linux-x86_64
    ARCH=x86_64
else
    make CC=clang LLVM=1 LLVM_IAS=1 -j2
    cp arch/arm64/boot/Image ../vmlinuz
    cp .config ../config-linux-arm64
    ARCH=aarch64
fi
cd ..

if [ ! -f alpine-minirootfs-3.12.3-$ARCH.tar.gz ]; then
    wget https://dl-cdn.alpinelinux.org/alpine/v3.12/releases/$ARCH/alpine-minirootfs-3.12.3-$ARCH.tar.gz
fi

umount mnt
dd if=/dev/zero of=vda.img bs=1M count=512
mkfs.ext4 vda.img
mkdir mnt
mount vda.img mnt
cd mnt
tar xf ../alpine-minirootfs-3.12.3-$ARCH.tar.gz
rm -rf etc/logrotate.d etc/modprobe.d etc/network
rm etc/modules etc/udhcpd.conf etc/sysctl.conf etc/hostname etc/motd etc/issue etc/shadow
cp ../etc/passwd etc/passwd
cp ../etc/group etc/group
cp ../etc/hosts etc/hosts
cp ../etc/inittab etc/inittab
cp ../etc/fstab etc/fstab
cp -Tr ../etc/init.d etc/init.d
mkdir etc/dropbear
cp -Tr ../root root
cp ../usr/share/udhcpc/default.script usr/share/udhcpc/default.script
rm -rf lib/sysctl.d
rm -rf media opt srv
cd ..
umount mnt
