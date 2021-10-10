#!/bin/sh
#apt install qemu-system-x86

/usr/lib/qemu/virtiofsd --socket-path=fs0 -o source=$PWD &

qemu-system-x86_64 \
      -nodefaults -nographic \
      -m 512M \
      -object memory-backend-file,id=mem,size=512M,mem-path=/dev/shm,share=on -numa node,memdev=mem \
      -chardev stdio,id=screen,mux=on,signal=off -device virtio-serial-pci -device virtconsole,chardev=screen -mon screen \
      -chardev socket,id=fs0,path=fs0 -device vhost-user-fs-pci,queue-size=1024,chardev=fs0,tag=fs0 \
      -blockdev driver=file,node-name=hd,filename=vda.img -device virtio-blk-pci,drive=hd \
      -netdev user,id=net,net=10.0.0.0/24 -device virtio-net-pci,netdev=net,mac=0A:00:00:00:00:03 \
      -kernel vmlinuz -append "console=hvc0 root=/dev/vda"
