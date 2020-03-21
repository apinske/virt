#!/bin/bash

nasm boot16.asm -f bin -o boot16.img
qemu-system-i386 -nographic boot16.img

