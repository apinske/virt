#!/bin/sh

if [ ! -d mnt ]; then
   apt update
   apt install -y wget xz-utils patch bc make clang-11 llvm-11 lld-11 flex bison libelf-dev libncurses-dev libssl-dev
fi

if [ ! -d linux ]; then
    linux_version=$(cat linux.version)
    wget -O linux.tar.xz https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-$linux_version.tar.xz
    mkdir linux
    cd linux
    tar xf ../linux.tar.xz --strip-components=1
    cd ..
    rm linux.tar.xz
    patch -d linux -p1 < linux.patch
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
