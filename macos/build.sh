#!/bin/sh

#doctl compute droplet create --image ubuntu-20-04-x64 --size s-1vcpu-1gb --region fra1 --ssh-keys $(doctl compute ssh-key list --format ID --no-header) --wait playground

if [ ! -d mnt ]; then
   apt update
   apt install -y wget bc make clang llvm lld flex bison libelf-dev libncurses-dev libssl-dev
fi

if [ ! -d linux ]; then
    wget https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.10.12.tar.xz
    tar xf linux-5.10.12.tar.xz
    mv linux-5.10.12 linux
fi
cd linux
if [ ! "$ARCH" = "$(uname -m)" ]; then
    echo "cross compiling on $(uname -m) for $ARCH"
    export CROSS_COMPILE=$ARCH-pc-linux-gnu
else
    echo "compiling on and for $ARCH"
fi
if [ "$ARCH" = "aarch64" ]; then
    export ARCH=arm64
fi
cp ../config-linux-$ARCH .config
make CC=clang LLVM=1 LLVM_IAS=1 -j2 $*
cp .config ../config-linux-$ARCH
if [ "$ARCH" = "x86_64" ]; then
    cp arch/x86/boot/bzImage ../vmlinuz
else
    cp arch/arm64/boot/Image ../vmlinuz
fi
cd ..
