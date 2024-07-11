#!/bin/sh

if [ ! -d mnt ]; then
   sudo apt update
   sudo apt install -y make clang llvm lld flex bison libelf-dev libncurses-dev libssl-dev
fi

if [ ! -d linux ]; then
    #git clone --branch linux-6.6.y --depth 1 git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git
    wget -q -O linux.tar.xz https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-$(cat linux.version).tar.xz
    mkdir linux
    cd linux
    tar xf ../linux.tar.xz --strip-components=1
    cd ..
    rm linux.tar.xz
fi
cd linux
cp ../linux.config .config
if [ ! "aarch64" = "$(uname -m)" ]; then
    echo "cross compiling on $(uname -m)"
    export CROSS_COMPILE=aarch64-pc-linux-gnu
fi
ARCH=arm64 make CC=clang LLVM=1 LLVM_IAS=1 -j2 $*
cp .config ../linux.config
cp arch/arm64/boot/Image ../vmlinuz
cd ..
