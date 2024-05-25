#!/bin/sh

if [ ! -f /usr/local/bin/k3d ]; then
  wget -O /usr/local/bin/k3d https://github.com/k3d-io/k3d/releases/download/v5.6.3/k3d-linux-arm64
  chmod +x /usr/local/bin/k3d
fi

apk add kubectl
podman network create k3d
k3d cluster create --network k3d --k3s-arg --flannel-backend=host-gw@server:* --api-port 127.0.0.1:6443 --port 80:80/tcp@server:* --port 443:443/tcp@server:*
kubectl apply -f k8s-example.yaml
