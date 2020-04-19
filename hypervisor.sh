#!/bin/sh

nasm hypervisor.asm -f bin -o hypervisor.bin
clang -o hypervisor -framework Hypervisor hypervisor.c && ./hypervisor

