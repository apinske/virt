#!/bin/sh
if [ ! -f /usr/bin/podman ]; then
    mkdir /mnt/vdb/containers
    ln -s /mnt/vdb/containers /var/lib/containers
    apk add podman catatonit
    echo "::respawn:/usr/bin/podman system service --time=0 unix:///var/run/docker.sock" >> /etc/inittab
    reboot
fi
