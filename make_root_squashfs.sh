#!/bin/bash

here=$(readlink -f -- "${0%/*}") 

time nice -n 20 \
    mksquashfs /* \
        /var/tmp/root.squashfs.gzip.`date +%s` \
        -ef $here/exclude.squashfs \
        -processors 1 \
        -wildcards \
        -b 1048576 \
        -write-queue 32 \
        -fragment-queue 32 \
        -read-queue 32
