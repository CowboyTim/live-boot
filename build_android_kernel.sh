#!/bin/bash

tmpscratchdir=/tmp
tmpdir=$(mktemp -d -p $tmpscratchdir modules_XXXXXX)
echo "tempdir to use $tmpdir"
mkdir -p $tmpdir

kernel_src_location="$1"
root_fs_file="$2"
if [ -z "$kernel_src_location" ]; then
    kernel_src_location=~/GT-I9100_samsung
fi
if [ -z "$root_fs_file" ]; then
    root_fs_file=~/data/squeeze.1355172793.squashfs.xz
fi

export CROSS_COMPILE=/usr/bin/arm-linux-gnueabi-
make_args="ARCH=arm INSTALL_MOD_PATH=$tmpdir -j10 "
here=$(readlink -f -- "${0%/*}")

for w in modules modules_install; do
    make $make_args $w
done
kernelversion=$(basename $(ls $tmpdir/lib/modules/))
bash $here/make_initrd_arm.sh \
    $root_fs_file \
    $tmpdir \
    && cp /var/tmp/initrd-$kernelversion.cpio.gz $kernel_src_location/initrd.cpio.gz

make $make_args zImage 
    
