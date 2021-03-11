#!/bin/sh
ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ]; then
    ssh macmini-ubuntu tar czf - -C simpleos_x86/macos vda.img vmlinuz | tar xzf -
else
    ssh ubuntu tar czf - -C simpleos/macos vda.img vmlinuz | tar xzf -
fi
