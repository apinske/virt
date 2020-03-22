#!/bin/bash

nasm boot.asm -f bin -o boot.bin
nasm kernel.asm -f bin -o kernel.bin
cat boot.bin kernel.bin >| boot.img
qemu-system-i386 -d in_asm boot.img

