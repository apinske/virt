#!/bin/sh

if [ ! -f /usr/local/bin/k3d ]; then
  wget -O /usr/local/bin/k3d https://github.com/k3d-io/k3d/releases/download/v5.7.3/k3d-linux-arm64
  chmod +x /usr/local/bin/k3d
fi

apk add kubectl
podman network create k3d
k3d cluster create --network k3d --k3s-arg --flannel-backend=host-gw@server:* --api-port 127.0.0.1:6443 --port 80:80/tcp@server:* --port 443:443/tcp@server:* --image docker.io/rancher/k3s:v1.30.2-k3s2 --k3s-arg "--kube-proxy-arg=--proxy-mode=nftables@server:*" --trace --k3s-arg "--kube-proxy-arg=--feature-gates=NFTablesProxyMode=true@server:*"
#k3d cluster create --network k3d --k3s-arg --flannel-backend=host-gw@server:* --kube-proxy-arg=--proxy-mode=nftables@server:* --env IPTABLES_MODE=nft@server:* --api-port 127.0.0.1:6443 --port 80:80/tcp@server:* --port 443:443/tcp@server:*
kubectl apply -f k8s-example.yaml
