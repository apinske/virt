#!/bin/sh
if [ ! -f /usr/bin/podman ]; then
    mkdir /mnt/vdb/containers
    ln -s /mnt/vdb/containers /var/lib/containers
    mkdir /mnt/vdb/tmp
    rm -r /var/tmp
    ln -s /mnt/vdb/tmp /var/tmp
    apk add nftables podman
    echo "::respawn:/usr/bin/podman system service --time=0 unix:///var/run/docker.sock" >> /etc/inittab
    reboot
fi
