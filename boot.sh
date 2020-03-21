#!/bin/bash

nasm boot.asm -f bin -o boot.img
qemu-system-i386 boot.img

