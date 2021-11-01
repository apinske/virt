#!/bin/sh
if [ "$(apk info | grep podman)" = "podman" ]; then
    echo "export CONTAINER_HOST=tcp://$(ip -o addr show | awk '{ print $4 }' | cut -d'/' -f1):58080"
else
    mkdir /mnt/vdb/containers
    ln -s /mnt/vdb/containers /var/lib/containers
    apk add podman
    echo "::respawn:/usr/bin/podman system service --time=0 tcp:0.0.0.0:58080" >> /etc/inittab
    reboot
fi
