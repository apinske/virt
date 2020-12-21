#!/bin/sh

#doctl compute droplet create --image ubuntu-20-04-x64 --size s-1vcpu-1gb --region fra1 --ssh-keys $(doctl compute ssh-key list --format ID --no-header) --wait playground

if [ ! -d mnt ]; then
   # apt update
   sudo apt install make clang llvm lld flex bison libelf-dev libncurses-dev libssl-dev
fi

if [ ! -d linux-5.10.1 ]; then
    wget https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.10.1.tar.xz
    tar xf linux-5.10.1.tar.xz
fi
cd linux-5.10.1
cp ../config-linux-$ARCH .config
if [ "$ARCH" = "x86_64" ]; then
    unset ARCH
    make CC=clang LLVM=1 -j2
    cp arch/x86/boot/bzImage ../vmlinuz
    cp .config ../config-linux-x86_64
else
    make CC=clang LLVM=1 LLVM_IAS=1 -j2
    cp arch/arm64/boot/Image ../vmlinuz
    cp .config ../config-linux-arm64
fi
cd ..
