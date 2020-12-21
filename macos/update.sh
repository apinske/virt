#!/bin/sh
ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ]; then
    scp macmini-ubuntu:~/simpleos_x86/macos/vmlinuz vmlinuz
    scp -C macmini-ubuntu:~/simpleos_x86/macos/vda.img vda.img
else
    scp ubuntu:~/simpleos/macos/vmlinuz vmlinuz
    scp -C ubuntu:~/simpleos/macos/vda.img vda.img
fi
