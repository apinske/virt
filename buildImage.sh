#!/bin/sh
if [ ! -f apk.static ]; then
    wget -O apk.static https://gitlab.alpinelinux.org/api/v4/projects/5/packages/generic/v2.14.10/aarch64/apk.static
    chmod +x apk.static
fi

umount mnt
dd if=/dev/zero of=vda.img bs=1M count=512
mkfs.ext4 vda.img
mkdir mnt
mount vda.img mnt
cd mnt
mkdir -p etc/apk
cp -r ../etc/apk etc
sudo ../apk.static add --root . --initdb alpine-baselayout busybox apk-tools
rm -rf etc/logrotate.d etc/modprobe.d etc/modules-load.d etc/network etc/opt etc/sysctl.d etc/udhcpc lib/modules-load.d
rm etc/modules etc/sysctl.conf etc/hostname etc/motd etc/issue etc/shadow
cp ../etc/passwd etc/passwd
cp ../etc/group etc/group
cp ../etc/hosts etc/hosts
cp ../etc/inittab etc/inittab
cp ../etc/fstab etc/fstab
cp -Tr ../etc/init.d etc/init.d
mkdir etc/dropbear mnt/virt
cp -Tr ../root root
cp ../usr/share/udhcpc/default.script usr/share/udhcpc/default.script
rm -rf lib/sysctl.d
rm -rf media opt srv
cd ..
umount mnt
