#!/bin/bash

rm boot.bin
rm kernel.o
rm kernel.bin
rm boot.img
rm hypervisor

CC="docker run --rm -it -v $PWD:/usr/src/app -w /usr/src/app gcc gcc"
LD="docker run --rm -it -v $PWD:/usr/src/app -w /usr/src/app gcc ld"

nasm boot.asm -f bin -o boot.bin
$CC -ffreestanding -o kernel.o -c kernel.c
$LD -o kernel.bin -Ttext 0x12000 --oformat binary kernel.o
cat boot.bin kernel.bin >| boot.img

#qemu-system-i386 boot.img

clang -o hypervisor -framework Hypervisor hypervisor.c
codesign --sign - --entitlements hypervisor.entitlements hypervisor
./hypervisor
