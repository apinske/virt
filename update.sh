#!/bin/sh
ssh ubuntu tar czf - -C virt vda.img vmlinuz | tar xzf -
