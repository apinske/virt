#!/bin/sh

#doctl compute droplet create --image ubuntu-20-04-x64 --size s-1vcpu-1gb --region fra1 --ssh-keys $(doctl compute ssh-key list --format ID --no-header) --wait playground

if [ ! -d mnt ]; then
   # apt update
   apt install make gcc flex bison libelf-dev libncurses-dev
fi

if [ ! -d linux-5.9.13 ]; then
    wget https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.9.13.tar.xz
    tar xf linux-5.9.13.tar.xz
fi

cd linux-5.9.13
cp ../config-linux .config
make V=2
cd ..

if [ ! -d busybox-1.32.0 ]; then
    wget https://busybox.net/downloads/busybox-1.32.0.tar.bz2
    tar xf busybox-1.32.0.tar.bz2
fi
cd busybox-1.32.0
cp ../config-busybox .config
make busybox
cd ..

umount mnt
dd if=/dev/zero of=vda.img bs=1M count=10
mkfs.ext4 vda.img
mkdir mnt
mount vda.img mnt
cd mnt
mkdir -p bin dev etc home lib mnt opt proc root run sbin sys tmp usr usr/bin usr/sbin var var/log var/run
cp -r ../etc/* etc/
cp ../busybox-1.32.0/busybox bin/busybox
for i in $(bin/busybox --list-full); do ln -s /bin/busybox $i; done
cd ..
umount mnt

cp linux-5.9.13/.config config-linux
cp busybox-1.32.0/.config config-busybox
cp linux-5.9.13/arch/x86/boot/bzImage vmlinuz
tar czf l.tgz vmlinuz vda.img
