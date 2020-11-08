#!/bin/sh

CC="sudo docker run --rm -it -v $PWD:/usr/src/app -w /usr/src/app gcc gcc"

sudo rm hypervisor
$CC -o hypervisor hypervisor.c
./hypervisor
