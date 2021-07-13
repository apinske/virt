#/bin/sh

if [ ! -d ./slash ]; then
  if [ ! -f slash.tar.gz ]; then
    curl -o slash.tar.gz https://dl-cdn.alpinelinux.org/alpine/v3.14/releases/$(uname -m)/alpine-minirootfs-3.14.0-$(uname -m).tar.gz
  fi
  mkdir slash && tar xf slash.tar.gz -C ./slash
fi

cc -o container container.c
./container
