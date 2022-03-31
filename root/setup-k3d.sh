#!/bin/sh

if [ ! -f /usr/local/bin/k3d ]; then
  VERSION=5.4.1
  ARCH=arm64
  if [ "$(uname -m)" = "x86_64" ]; then
    ARCH=amd64
  fi
  wget -O /usr/local/bin/k3d https://github.com/rancher/k3d/releases/download/v$VERSION/k3d-linux-$ARCH
  chmod +x /usr/local/bin/k3d
fi

k3d cluster create --network podman --k3s-arg --flannel-backend=none@server:*
