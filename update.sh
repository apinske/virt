#!/bin/sh
ssh ubuntu tar czf - -C repos/virt vda.img vmlinuz | tar xzf -
