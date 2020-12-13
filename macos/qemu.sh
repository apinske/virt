#!/bin/sh
#apt install qemu-system-x86

qemu-system-x86_64 \
      -nodefaults -nographic \
      -m 512M \
      -chardev stdio,id=screen,mux=on,signal=off -device virtio-serial-pci -device virtconsole,chardev=screen -mon screen \
      -blockdev driver=file,node-name=hd,filename=vda.img -device virtio-blk-pci,drive=hd \
      -netdev user,id=net,net=10.0.0.0/24 -device virtio-net-pci,netdev=net,mac=0A:00:00:00:00:03 \
      -kernel vmlinuz -append "console=hvc0 root=/dev/vda"
