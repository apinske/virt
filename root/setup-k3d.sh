#!/bin/sh

if [ ! -f /usr/local/bin/k3d ]; then
  wget -O /usr/local/bin/k3d https://github.com/k3d-io/k3d/releases/download/v5.4.4/k3d-linux-arm64
  chmod +x /usr/local/bin/k3d
fi

k3d cluster create --network podman --k3s-arg --flannel-backend=none@server:*
