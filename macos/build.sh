#!/bin/sh

#doctl compute droplet create --image ubuntu-20-04-x64 --size s-1vcpu-1gb --region fra1 --ssh-keys $(doctl compute ssh-key list --format ID --no-header) --wait playground

if [ ! -d mnt ]; then
   # apt update
   apt install make gcc clang llvm lld flex bison libelf-dev libncurses-dev libssl-dev
fi

if [ ! -d linux-5.9.13 ]; then
    wget https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.9.13.tar.xz
    tar xf linux-5.9.13.tar.xz
fi
cd linux-5.9.13
cp ../config-linux-$ARCH .config
if [ "$ARCH" == "x86_64" ]; then
    unset ARCH
fi
make CC=clang LLVM=1 LLVM_IAS=1 -j2
cd ..

if [ ! -d musl-1.2.1 ]; then
    wget https://musl.libc.org/releases/musl-1.2.1.tar.gz
    tar xf musl-1.2.1.tar.gz
fi
cd musl-1.2.1
./configure --prefix=$PWD/build --disable-static
make
make install
ln -s /usr/bin/ar build/bin/musl-ar
ln -s /usr/bin/strip build/bin/musl-strip
ln -s /usr/include/linux build/include/linux
ln -s /usr/include/asm-generic build/include/asm
ln -s /usr/include/asm-generic build/include/asm-generic
cd ..

if [ ! -d busybox-1.32.0 ]; then
    wget https://busybox.net/downloads/busybox-1.32.0.tar.bz2
    tar xf busybox-1.32.0.tar.bz2
fi
cd busybox-1.32.0
cp ../config-busybox .config
PATH=../musl-1.2.1/build/bin:$PATH make busybox
cd ..

if [ ! -f apk-tools-static-2.10.5-r1.apk ]; then
    wget https://dl-cdn.alpinelinux.org/alpine/v3.12/main/x86_64/apk-tools-static-2.10.5-r1.apk
fi

umount mnt
dd if=/dev/zero of=vda.img bs=1M count=512
mkfs.ext4 vda.img
mkdir mnt
mount vda.img mnt
cd mnt
mkdir -p bin dev etc home lib mnt proc root run sbin sys tmp usr usr/bin usr/sbin usr/lib var var/cache var/lib var/lock var/log var/tmp
ln -s /run var/run
cp -r ../etc/* etc/
cp -r ../usr/* usr/
cp ../musl-1.2.1/build/lib/libc.so lib/libc.so
ln -s libc.so lib/ld-musl-x86_64.so.1
cp ../busybox-1.32.0/busybox bin/busybox
for i in $(LD_LIBRARY_PATH=lib bin/busybox --list-full); do ln -s /bin/busybox $i; done
tar xf ../apk-tools-static-2.10.5-r1.apk sbin/apk.static
#sbin/apk.static --allow-untrusted --initdb --root . add alpine-base
cd ..
umount mnt

cp busybox-1.32.0/.config config-busybox
cp linux-5.9.13/arch/arm64/boot/Image vmlinuz
cp linux-5.9.13/arch/x86/boot/bzImage vmlinuz
cp linux-5.9.13/.config config-linux-$ARCH
