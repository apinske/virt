#!/bin/sh
apk add e2fsprogs
mkfs.ext4 /dev/vdb
mkdir /mnt/vdb
echo -e "/dev/vdb\t/mnt/vdb\text4\tdefaults\t0 0" >> /etc/fstab
mount -a
