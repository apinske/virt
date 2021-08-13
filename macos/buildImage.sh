#!/bin/sh
if [ ! -f alpine-minirootfs-3.14.1-$ARCH.tar.gz ]; then
    wget https://dl-cdn.alpinelinux.org/alpine/v3.14/releases/$ARCH/alpine-minirootfs-3.14.1-$ARCH.tar.gz
fi

umount mnt
dd if=/dev/zero of=vda.img bs=1M count=512
mkfs.ext4 vda.img
mkdir mnt
mount vda.img mnt
cd mnt
tar xf ../alpine-minirootfs-3.14.1-$ARCH.tar.gz
rm -rf etc/conf.d etc/logrotate.d etc/modprobe.d etc/modules-load.d etc/network etc/opt etc/sysctl.d lib/modules-load.d
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
