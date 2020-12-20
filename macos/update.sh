#!/bin/sh
ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ]; then
    scp macmini-ubuntu:~/simpleos_x86/macos/linux-5.9.13/arch/x86/boot/bzImage vmlinuz
    scp -C macmini-ubuntu:~/simpleos_x86/macos/vda.img vda.img
else
    scp ubuntu:~/simpleos/macos/linux-5.9.13/arch/arm64/boot/Image vmlinuz
    scp -C ubuntu:~/simpleos/macos/vda.img vda.img
fi
