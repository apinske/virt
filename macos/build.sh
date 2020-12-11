#!/bin/sh

#doctl compute droplet create --image ubuntu-20-04-x64 --size s-1vcpu-1gb --region fra1 --ssh-keys $(doctl compute ssh-key list --format ID --no-header) --wait playground

#wget https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.9.13.tar.xz

#wget https://dl-cdn.alpinelinux.org/alpine/v3.12/releases/x86_64/alpine-minirootfs-3.12.1-x86_64.tar.gz
dd if=/dev/zero of=vda.img bs=1M count=20
mkfs.ext4 vda.img 
mkdir mnt
mount -t ext4 -o loop vda.img mnt
cd mnt/
tar xzf ../alpine-minirootfs-3.12.1-x86_64.tar.gz 
cd ..
umount mnt

cp linux-5.9.13/.config config
cp linux-5.9.13/arch/x86/boot/bzImage vmlinuz
tar czf l.tgz vmlinuz config vda.img
