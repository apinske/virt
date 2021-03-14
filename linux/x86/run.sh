#/bin/sh

if [ ! -d ./slash ]; then
  if [ ! -f slash.tar.gz ]; then
    curl -o slash.tar.gz https://dl-cdn.alpinelinux.org/alpine/v3.13/releases/x86_64/alpine-minirootfs-3.13.2-x86_64.tar.gz
  fi
  mkdir slash && tar xf slash.tar.gz -C ./slash
fi

cc -o container container.c
./container
