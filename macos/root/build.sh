#!/bin/sh
if [ ! -d build ]; then
    mkdir build
    podman run -d --name build --net host -v $PWD/build:/root/build docker.io/ubuntu:20.10 sleep infinity
    podman exec build sh -c 'apt update && apt install -y git && cd /root && git clone https://github.com/apinske/simpleos.git'
else
    podman start build
fi
ARCH=$(uname -m)
if [ "$ARCH" = "aarch64" ]; then
    ARCH=arm64
fi
podman exec -e ARCH=$ARCH build sh -c 'cd /root/simpleos/macos && ./build.sh && cp vmlinuz ../../build/vmlinuz'
podman stop build
