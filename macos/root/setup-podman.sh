#!/bin/sh
if [ "$(apk info | grep podman)" = "podman" ]; then
    echo "export CONTAINER_HOST=tcp://$(ip -o addr show | awk '{ print $4 }' | cut -d'/' -f1):58080"
else
    apk add e2fsprogs
    mkfs.ext4 /dev/vdb
    mkdir /var/lib/containers
    echo -e "/dev/vdb\t/var/lib/containers\text4\tdefaults\t0 0" >> /etc/fstab
    mount -a
    echo "http://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories
    apk add podman
    echo "::respawn:/usr/bin/podman system service --time=0 tcp:0.0.0.0:58080" >> /etc/inittab
    reboot
fi
