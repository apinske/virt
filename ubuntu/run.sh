#!/bin/sh
if [ ! -f vda.img ]; then
  wget -O- https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-arm64.tar.gz | tar xzf - jammy-server-cloudimg-arm64.img
  mv jammy-server-cloudimg-arm64.img vda.img
  truncate -s 64G vda.img
fi
if [ ! -f initrd ]; then
  wget -O initrd https://cloud-images.ubuntu.com/jammy/current/unpacked/jammy-server-cloudimg-arm64-initrd-generic
fi
if [ ! -f vmlinuz ]; then
  wget -O vmlinuz https://cloud-images.ubuntu.com/jammy/current/unpacked/jammy-server-cloudimg-arm64-vmlinuz-generic
  gunzip -f -S '' vmlinuz
fi
if [ ! -f vdc.iso ]; then
  mkdir cidata
  echo '#cloud-config\npassword: ubuntu\nchpasswd: { expire: False }\nssh_pwauth: True' > cidata/user-data
  echo '{"instance-id":"iid-local-01","local-hostname":"ubuntu"}' > cidata/meta-data
  hdiutil makehybrid -o vdc cidata -iso -joliet
  rm -rf cidata
fi
../virt/build/Release/virt -v
