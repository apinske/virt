#!/bin/sh

if [ ! -f /usr/local/bin/nerdctl ]; then
  VERSION=0.14.0
  ARCH=arm64
  if [ "$(uname -m)" = "x86_64" ]; then
    ARCH=amd64
  fi
  wget -O- https://github.com/containerd/nerdctl/releases/download/v$VERSION/nerdctl-$VERSION-linux-$ARCH.tar.gz | tar xz -f- -C /usr/local/bin nerdctl
fi

if [ "$(apk info | grep containerd)" = "containerd" ]; then
  exit 0
fi

mkdir /mnt/vdb/containerd
ln -s /mnt/vdb/containerd /var/lib/containerd

apk add containerd cni-plugins iptables ip6tables
echo "::respawn:/usr/bin/containerd 2>&1 | logger -t containerd" >> /etc/inittab
reboot
