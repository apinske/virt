#!/bin/sh

#doctl compute droplet create --image ubuntu-20-04-x64 --size s-1vcpu-1gb --region fra1 --ssh-keys $(doctl compute ssh-key list --format ID --no-header) --wait playground

apt update
apt install make gcc flex bison libelf-dev libncurses-dev
wget https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.9.13.tar.xz
tar xf linux-5.9.13.tar.xz
cp config linux-5.9.13/.config
cd linux-5.9.13
make
cd ..

wget https://busybox.net/downloads/busybox-1.32.0.tar.bz2
tar xf busybox-1.32.0.tar.bz2
cp config-busybox busybox-1.32.0/.config
cd busybox-1.32.0
make
cd ..

umount mnt
dd if=/dev/zero of=vda.img bs=1M count=20
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

cp linux-5.9.13/.config config
cp linux-5.9.13/arch/x86/boot/bzImage vmlinuz
tar czf l.tgz vmlinuz config vda.img
