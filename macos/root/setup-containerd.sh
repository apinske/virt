#!/bin/sh

if [ ! -f /usr/local/bin/nerdctl ]; then
  VERSION=0.12.1
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

mkdir -p /etc/cni/net.d/
cat >/etc/cni/net.d/10-mynet.conf <<EOF
{
  "cniVersion": "0.2.0",
  "name": "mynet",
  "type": "bridge",
  "bridge": "cni0",
  "isGateway": true,
  "ipMasq": true,
  "ipam": {
    "type": "host-local",
    "subnet": "10.22.0.0/16",
    "routes": [
      { "dst": "0.0.0.0/0" }
    ]
  }
}
EOF

cat >/etc/cni/net.d/99-loopback.conf <<EOF
{
  "cniVersion": "0.2.0",
  "name": "lo",
  "type": "loopback"
}
EOF

echo "::respawn:/usr/bin/containerd 2>&1 | logger -t containerd" >> /etc/inittab
reboot
