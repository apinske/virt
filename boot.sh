#!/bin/bash

CC="docker run --rm -it -v $PWD:/usr/src/app -w /usr/src/app gcc gcc"
LD="docker run --rm -it -v $PWD:/usr/src/app -w /usr/src/app gcc ld"

nasm boot.asm -f bin -o boot.bin
$CC -ffreestanding -o kernel.o -c kernel.c
$LD -o kernel.bin -Ttext 0x12000 --oformat binary kernel.o
cat boot.bin kernel.bin >| boot.img
qemu-system-i386 -d in_asm boot.img

