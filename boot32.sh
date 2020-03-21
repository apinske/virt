#!/bin/bash

nasm boot32.asm -f bin -o boot32.img
qemu-system-i386 boot32.img

