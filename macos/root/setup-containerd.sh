#!/bin/sh

if [ ! -f /usr/local/bin/nerdctl ]; then
  wget -O- https://github.com/containerd/nerdctl/releases/download/v0.12.1/nerdctl-0.12.1-linux-arm64.tar.gz | tar xz -f- -C /usr/local/bin nerdctl
fi

apk add containerd cni-plugins

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

echo "::respawn:/usr/bin/containerd" >> /etc/inittab
reboot
