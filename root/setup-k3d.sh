#!/bin/sh

if [ ! -f /usr/local/bin/k3d ]; then
  wget -O /usr/local/bin/k3d https://github.com/k3d-io/k3d/releases/download/v5.5.0/k3d-linux-arm64
  chmod +x /usr/local/bin/k3d
fi

if [ ! -f /usr/local/bin/kubectl ]; then
  # https://storage.googleapis.com/kubernetes-release/release/stable.txt
  wget -O /usr/local/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/v1.27.1/bin/linux/arm64/kubectl
  chmod +x /usr/local/bin/kubectl
fi

podman network create k3d
k3d cluster create --network k3d --k3s-arg --flannel-backend=host-gw@server:* --env IPTABLES_MODE=legacy@server:* --no-lb --api-port 127.0.0.1:6443
