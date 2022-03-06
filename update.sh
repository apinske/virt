#!/bin/sh
ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ]; then
    ssh srv2-ubuntu tar czf - -C virt_x86 vda.img vmlinuz | tar xzf -
else
    ssh ubuntu tar czf - -C virt vda.img vmlinuz | tar xzf -
fi
